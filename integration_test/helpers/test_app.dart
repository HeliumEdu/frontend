// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/log_formatter.dart';
import 'package:heliumapp/core/log_service.dart';
import 'package:heliumapp/data/repositories/auth_repository_impl.dart';
import 'package:heliumapp/data/sources/auth_remote_data_source.dart';
import 'package:heliumapp/helium_app.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/planneritem_bloc.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/provider_helpers.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:web/web.dart' as web;

final _log = Logger('test_app_helper');

bool _initialized = false;
bool _loggingInitialized = false;
String _currentTestDisplayName = '';
bool _currentTestSkipped = false;
String? _currentTestSkipReason;

// Suite tracking
String _currentSuiteName = '';

/// Log level for integration tests.
/// - info: Only test names and pass/fail results (default)
/// - fine: For debugging tests - prints/logs from test files will be present
/// - finer: For debugging the app - app-level logger logs are let through
enum TestLogLevel { info, fine, finer }

/// Current log level for integration tests.
TestLogLevel _testLogLevel = TestLogLevel.info;

/// Port for the real-time logging server (must match driver).
const _logServerPort = 4445;

/// Get the current test log level.
TestLogLevel get testLogLevel => _testLogLevel;

/// Send a log message to the driver's log server for real-time output.
Future<void> _sendLog(Map<String, dynamic> data) async {
  try {
    final response = await http.post(
      Uri.parse('http://localhost:$_logServerPort/log'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      // ignore: avoid_print
      print('Warning: Log server returned ${response.statusCode}');
    }
  } catch (e) {
    // ignore: avoid_print
    print('Warning: Could not reach log server: $e');
  }
}

/// Start a test suite. Call this in setUpAll().
Future<void> startSuite(String name) async {
  // End previous suite if any
  if (_currentSuiteName.isNotEmpty) {
    await endSuite();
  }
  _currentSuiteName = name;
  await _sendLog(<String, dynamic>{'type': 'suiteStart', 'suite': name});
}

/// End the current test suite. Called automatically when a new suite starts,
/// or can be called explicitly in tearDownAll().
Future<void> endSuite() async {
  if (_currentSuiteName.isEmpty) return;
  await _sendLog(<String, dynamic>{
    'type': 'suiteEnd',
    'suite': _currentSuiteName,
  });
  _currentSuiteName = '';
}

/// Initialize logging for integration tests.
/// Safe to call multiple times - only sets up the listener once.
void initializeTestLogging({
  required String environment,
  required String apiHost,
}) {
  if (_loggingInitialized) return;
  _loggingInitialized = true;

  // Parse log level from environment
  const logLevelStr = String.fromEnvironment(
    'INTEGRATION_LOG_LEVEL',
    defaultValue: 'info',
  );
  _testLogLevel = switch (logLevelStr) {
    'finer' => TestLogLevel.finer,
    'fine' => TestLogLevel.fine,
    _ => TestLogLevel.info,
  };

  // Initialize app logging (LOG_LEVEL can be set via dart-define)
  // Must be called before reading Logger.root.level below
  LogService().init();

  // Send init info to driver
  // Only include appLogLevel when finer is enabled (showing app logs)
  _sendLog(<String, dynamic>{
    'type': 'init',
    'environment': environment,
    'apiHost': apiHost,
    'logLevel': _testLogLevel.name,
    if (_testLogLevel == TestLogLevel.finer)
      'appLogLevel': Logger.root.level.name.toLowerCase(),
  });

  // Hook into the test framework's exception reporter to capture test failures
  final originalReporter = reportTestException;
  reportTestException = (FlutterErrorDetails details, String testDescription) {
    // Use our tracked display name which includes the group prefix
    final displayName = _currentTestDisplayName.isNotEmpty
        ? _currentTestDisplayName
        : testDescription;

    // Send failure log to driver
    _sendLog(<String, dynamic>{
      'type': 'testFail',
      'test': displayName,
      'error': details.exceptionAsString(),
      'stack': details.stack?.toString() ?? '',
    });

    // Call original reporter to maintain framework behavior
    originalReporter(details, testDescription);
  };

  // Configure log forwarding to driver based on integration log level
  // Note: App log level is controlled by LOG_LEVEL env var via LogService
  Logger.root.onRecord.listen((record) {
    // Only show TEST/APP prefix when app logs are enabled (finer level)
    final includePrefix = _testLogLevel == TestLogLevel.finer;
    final formatted = LogFormatter.format(
      record,
      includeSourcePrefix: includePrefix,
    );
    final loggerName = record.loggerName;

    // Determine if this is a test logger (integration test files and helpers)
    final isTestLogger =
        loggerName.endsWith('_test') || loggerName.endsWith('_helper');

    // Send to driver for terminal output based on log level:
    // - info: no logs sent
    // - fine: only test logs (for debugging tests themselves)
    // - finer: all logs including app logs (for debugging the app)
    final shouldSendToDriver = switch (_testLogLevel) {
      TestLogLevel.info => false,
      TestLogLevel.fine => isTestLogger,
      TestLogLevel.finer => true,
    };

    if (shouldSendToDriver) {
      _sendLog(<String, dynamic>{'type': 'log', 'message': formatted});
    }

    // Always print to browser console for DevTools debugging
    // ignore: avoid_print
    print(formatted);
  });
}

/// Mark the current test as skipped with a reason.
/// Call this and then return early from the test.
void skipTest(String reason) {
  _currentTestSkipped = true;
  _currentTestSkipReason = reason;
  markTestSkipped(reason);
}

/// Wrapper around testWidgets that reports test results to the driver.
/// - At info level: reports test name and pass/fail only
/// - At fine level: also includes logs from test files (for debugging tests)
/// - At finer level: also includes app-level logs (for debugging the app)
///
/// Note: Test failures are reported via reportTestException hook in initializeTestLogging.
@isTest
void namedTestWidgets(
  String description,
  Future<void> Function(WidgetTester) callback,
) {
  testWidgets(description, (tester) async {
    // Reset skip state for this test
    _currentTestSkipped = false;
    _currentTestSkipReason = null;

    // Store for use by reportTestException hook
    _currentTestDisplayName = description;

    // Report test start
    await _sendLog(<String, dynamic>{'type': 'testStart', 'test': description});

    // Run the test callback - failures are handled by reportTestException hook
    await callback(tester);

    // Check if the test was skipped
    if (_currentTestSkipped) {
      await _sendLog(<String, dynamic>{
        'type': 'testSkip',
        'test': description,
        'reason': _currentTestSkipReason,
      });
    } else {
      // If we get here and not skipped, the test passed
      await _sendLog(<String, dynamic>{
        'type': 'testPass',
        'test': description,
      });
    }
  });
}

Future<void> initializeTestApp(WidgetTester tester) async {
  if (!_initialized) {
    GoogleFonts.config.allowRuntimeFetching = false;
    tz.initializeTimeZones();

    // Analytics is disabled via ANALYTICS_ENABLED=false dart-define
    await PrefService().init();
    initializeRouter();
    _initialized = true;
  }

  // Clear any stored auth state between tests
  await DioClient().clearStorage();

  final dioClient = DioClient();
  final providerHelpers = ProviderHelpers();

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(
            authRepository: AuthRepositoryImpl(
              remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dioClient),
            ),
            dioClient: dioClient,
          ),
        ),
        BlocProvider<ExternalCalendarBloc>(
          create: providerHelpers.createExternalCalendarBloc(),
        ),
        BlocProvider<PlannerItemBloc>(
          create: providerHelpers.createPlannerItemBloc(),
        ),
      ],
      child: const HeliumApp(),
    ),
  );

  // Wait for the app to settle
  await tester.pumpAndSettle();
}

/// Helper to enter text into a field.
/// On web, we need to directly update the EditableText state since
/// enterText doesn't work reliably with web-server driver.
Future<void> enterTextInField(
  WidgetTester tester,
  Finder fieldFinder,
  String text,
) async {
  // Wait for any pending animations/rebuilds
  await tester.pumpAndSettle();

  // Tap to focus the field
  await tester.tap(fieldFinder);
  await tester.pumpAndSettle();

  // Find the EditableText within the TextField and update its value directly
  final editableTextFinder = find.descendant(
    of: fieldFinder,
    matching: find.byType(EditableText),
  );

  if (editableTextFinder.evaluate().isNotEmpty) {
    final editableTextState = tester.state<EditableTextState>(
      editableTextFinder,
    );
    editableTextState.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
    await tester.pumpAndSettle();
  } else {
    // Fallback to standard enterText
    await tester.enterText(fieldFinder, text);
    await tester.pumpAndSettle();
  }
}

/// Helper to enter text into a field by hint text.
/// On web, fields must be tapped to focus before enterText works.
Future<void> enterTextByHint(
  WidgetTester tester,
  String hintText,
  String text,
) async {
  final field = find.widgetWithText(TextField, hintText);
  await enterTextInField(tester, field, text);
}

/// Helper to tap a button by text
Future<void> tapButtonByText(WidgetTester tester, String buttonText) async {
  final button = find.text(buttonText);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

/// Helper to wait until navigation reaches a specific route.
/// [routePath] - The route path to wait for (e.g., '/planner')
/// [browserTitle] - Optional browser title to also verify
/// [timeout] - How long to wait before giving up
/// Returns true if the route was reached, false if timeout.
Future<bool> waitForRoute(
  WidgetTester tester,
  String routePath, {
  String? browserTitle,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final endTime = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));

    // Check current route using GoRouter
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    if (currentPath == routePath || currentPath.startsWith('$routePath/')) {
      // Also verify browser title if provided
      if (browserTitle != null && !getBrowserTitle().contains(browserTitle)) {
        continue;
      }
      await tester.pumpAndSettle();
      return true;
    }
  }
  return false;
}

/// Finder for RichText widgets containing the given text.
/// Use this for calendar items which render as RichText with inline icons.
Finder findRichTextContaining(String text) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is RichText && widget.text.toPlainText().contains(text),
    description: 'RichText containing "$text"',
  );
}

/// Helper to wait for a widget to appear with timeout
Future<bool> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return true;
    }
  }
  return false;
}

/// Helper to scroll until a widget becomes visible.
/// Useful for finding elements that may be off-screen in a scrollable area.
/// [finder] - The widget to find
/// [delta] - Scroll amount per step (positive = down, negative = up). Default 200.
/// [scrollableFinder] - Optional finder for the scrollable. Defaults to last Scrollable.
/// [maxScrolls] - Maximum scroll attempts before giving up. Default 50.
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  double delta = 200.0,
  Finder? scrollableFinder,
  int maxScrolls = 50,
}) async {
  await tester.pumpAndSettle();

  final scrollable = scrollableFinder ?? find.byType(Scrollable).last;

  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: scrollable,
    maxScrolls: maxScrolls,
  );
  // Ensure widget is fully visible, not just partially
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Helper to wait for a widget to disappear with timeout.
/// Returns true if the widget disappeared, false if timeout was reached.
Future<bool> waitForWidgetToDisappear(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) {
      return true;
    }
  }
  return false;
}

/// Helper to ensure we're on the login screen.
/// On web, URL persists between tests, so we may start on any screen.
/// After initializeTestApp clears storage, authenticated routes redirect to login.
Future<void> ensureOnLoginScreen(WidgetTester tester) async {
  // Wait for the app to settle and redirect to login if needed
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Check if we're already on login screen
  if (find.text('Sign In').evaluate().isNotEmpty &&
      find.widgetWithText(TextField, 'Email').evaluate().isNotEmpty) {
    return;
  }

  // Wait for redirect to login (authenticated routes should redirect after storage cleared)
  _log.info('Waiting for redirect to login screen ...');
  final found = await waitForWidget(
    tester,
    find.text('Sign In'),
    timeout: const Duration(seconds: 10),
  );

  if (!found) {
    _log.warning('Login screen not found within timeout');
  }

  await tester.pumpAndSettle();
}

/// Dismisses the "Getting Started" dialog if present.
/// This dialog appears on first login and after browser hard refresh.
/// Returns true if the dialog was found and dismissed, false otherwise.
Future<bool> dismissGettingStartedDialog(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final dialogFinder = find.text('Welcome to Helium!');

  // Wait for dialog to appear (it may take a moment after navigation)
  final appeared = await waitForWidget(tester, dialogFinder, timeout: timeout);
  if (!appeared) {
    return false;
  }

  _log.info('Dismissing Getting Started dialog ...');
  await tester.tap(find.text("I'll explore first"));
  await tester.pumpAndSettle();

  // Wait for dialog to fully close before proceeding
  final closed = await waitForWidgetToDisappear(
    tester,
    dialogFinder,
    timeout: const Duration(seconds: 5),
  );

  if (!closed) {
    _log.warning('Getting Started dialog did not close within timeout');
  }

  return true;
}

/// Dismisses the "What's New" dialog if present.
/// This dialog appears once after the Getting Started dialog (stored in prefs).
/// Returns true if the dialog was found and dismissed, false otherwise.
Future<bool> dismissWhatsNewDialog(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final dialogFinder = find.text("What's New?");

  // Wait for dialog to appear (it may take a moment after Getting Started closes)
  final appeared = await waitForWidget(tester, dialogFinder, timeout: timeout);
  if (!appeared) {
    return false;
  }

  _log.info('Dismissing What\'s New dialog ...');
  await tester.tap(find.text('Dive In!'));
  await tester.pumpAndSettle();

  // Wait for dialog to fully close before proceeding
  final closed = await waitForWidgetToDisappear(
    tester,
    dialogFinder,
    timeout: const Duration(seconds: 5),
  );

  if (!closed) {
    _log.warning('What\'s New dialog did not close within timeout');
  }

  return true;
}

/// Helper to log in and navigate to planner, handling dialogs.
/// [expectWhatsNew] - if true, asserts What's New appears (first login after signup).
///                    if false (default), asserts What's New does NOT appear.
/// Returns true if planner was reached and is ready for interaction.
Future<bool> loginAndNavigateToPlanner(
  WidgetTester tester,
  String email,
  String password, {
  bool expectWhatsNew = false,
}) async {
  // Ensure we're on the login screen
  await ensureOnLoginScreen(tester);

  // Enter credentials
  await enterTextInField(
    tester,
    find.widgetWithText(TextField, 'Email'),
    email,
  );
  await enterTextInField(
    tester,
    find.widgetWithText(TextField, 'Password'),
    password,
  );

  _log.info('Submitting login ...');
  await tester.tap(find.text('Sign In'));

  // Wait for planner route
  final reachedPlanner = await waitForRoute(
    tester,
    AppRoute.plannerScreen,
    browserTitle: 'Planner',
    timeout: const Duration(seconds: 30),
  );

  if (!reachedPlanner) {
    _log.warning('Failed to reach planner after login');
    return false;
  }

  // Dismiss Getting Started dialog if present (shown after login and browser refresh)
  await dismissGettingStartedDialog(tester);

  // Handle What's New dialog based on expectation
  final whatsNewAppeared = await dismissWhatsNewDialog(tester);
  if (expectWhatsNew && !whatsNewAppeared) {
    throw Exception(
      "What's New dialog should appear on first login after signup",
    );
  } else if (!expectWhatsNew && whatsNewAppeared) {
    throw Exception(
      "What's New dialog should not appear - it only appears once after signup",
    );
  }

  // Extra settle to ensure navigation shell is fully rendered
  await tester.pumpAndSettle();
  _log.info('Successfully navigated to planner');

  return true;
}

/// Get the current browser document title.
String getBrowserTitle() {
  return web.document.title;
}

/// Wait for the browser title to contain the expected page name.
/// Returns true if the title matched within the timeout, false otherwise.
/// Use this when the title may update asynchronously (e.g., after navigation
/// or when a screen resolves its title dynamically).
Future<bool> waitForBrowserTitle(
  WidgetTester tester,
  String expectedPageName, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (getBrowserTitle().contains(expectedPageName)) {
      return true;
    }
  }
  return false;
}

/// Verify the browser title contains the expected page name.
/// The app uses format: "PageName | Helium"
void expectBrowserTitle(String expectedPageName) {
  final title = getBrowserTitle();
  expect(
    title.contains(expectedPageName),
    isTrue,
    reason:
        'Browser title should contain "$expectedPageName", but was "$title"',
  );
}

/// Verify the browser title matches exactly.
void expectBrowserTitleExact(String expectedTitle) {
  final title = getBrowserTitle();
  expect(
    title,
    equals(expectedTitle),
    reason: 'Browser title should be "$expectedTitle", but was "$title"',
  );
}

/// Assert we're on the Planner screen.
/// Verifies: Today button (icon), Filter/Menu icon, Search icon, and FAB are shown.
/// [isMobile] - when true, expects menu_open icon instead of filter_alt and search icons.
void expectOnPlannerScreen({bool isMobile = false}) {
  // Use icon instead of text - text is hidden on mobile
  expect(
    find.byIcon(Icons.calendar_today),
    findsOneWidget,
    reason: 'Planner: Today button (calendar_today icon) should be shown',
  );
  if (isMobile) {
    // On mobile, filter and search are hidden behind the menu
    expect(
      find.byIcon(Icons.menu_open),
      findsOneWidget,
      reason: 'Planner: Menu icon should be shown on mobile',
    );
  } else {
    // On desktop, filter and search icons are visible
    expect(
      find.byIcon(Icons.filter_alt),
      findsOneWidget,
      reason: 'Planner: Filter icon should be shown on desktop',
    );
    expect(
      find.byIcon(Icons.search),
      findsWidgets,
      reason: 'Planner: Search icon should be shown on desktop',
    );
  }
  expect(
    find.byType(FloatingActionButton),
    findsOneWidget,
    reason: 'Planner: FAB should be shown',
  );
  expect(
    find.text('Planner'),
    findsNWidgets(2),
    reason: 'Planner: Title or menu button not found',
  );
  expectBrowserTitle('Planner');
}

/// Assert we're on the Classes screen.
/// Verifies: FAB is shown, 3 course cards with expected titles (titles end with emojis).
void expectOnClassesScreen() {
  expect(
    find.byType(FloatingActionButton),
    findsOneWidget,
    reason: 'Classes: FAB should be shown',
  );
  expect(
    find.byType(Card),
    findsNWidgets(3),
    reason: 'Classes: Should show 3 course cards',
  );
  expect(
    find.text('Fall Semester'),
    findsOneWidget,
    reason: 'Classes: Fall Semester group should be shown',
  );
  expect(
    find.text('Creative Writing ✍️'),
    findsOneWidget,
    reason: 'Classes: Creative Writing ✍️ course should be shown',
  );
  expect(
    find.text('Fundamentals of Programming 💻'),
    findsOneWidget,
    reason: 'Classes: Fundamentals of Programming 💻 course should be shown',
  );
  expect(
    find.text('Intro to Psychology 🧠'),
    findsOneWidget,
    reason: 'Classes: Intro to Psychology 🧠 course should be shown',
  );
  expect(
    find.text('Classes'),
    findsNWidgets(2),
    reason: 'Classes: Title or menu button not found',
  );
  expectBrowserTitle('Classes');
}

/// Assert we're on the Resources screen.
/// Verifies: FAB is shown, 1 resource card with expected title.
void expectOnResourcesScreen() {
  expect(
    find.byType(FloatingActionButton),
    findsOneWidget,
    reason: 'Resources: FAB should be shown',
  );
  expect(
    find.byType(Card),
    findsOneWidget,
    reason: 'Resources: Should show 1 resource card',
  );
  expect(
    find.text('Digital Tools'),
    findsOneWidget,
    reason: 'Resources: Digital Tools group should be shown',
  );
  expect(
    find.text('Google Workspace (Docs, Drive)'),
    findsOneWidget,
    reason: 'Resources: Google Workspace (Docs, Drive) resource should be shown',
  );
  expect(
    find.text('Resources'),
    findsNWidgets(2),
    reason: 'Resources: Title or menu button not found',
  );
  expectBrowserTitle('Resources');
}

/// Assert we're on the Grades screen.
/// Verifies: "Grade Trend" text shown, FAB NOT shown, 4 summary widgets at top,
/// "28" below "Pending Impact", 3 course grade cards.
void expectOnGradesScreen() {
  expect(
    find.byType(FloatingActionButton),
    findsNothing,
    reason: 'Grades: FAB should NOT be shown',
  );
  expect(
    find.text('Overall Grade'),
    findsNWidgets(2),
    reason: 'Grades: Overall Grade should be shown in summary, and as series in trend graph',
  );
  expect(
    find.text('All classes passing!'),
    findsOneWidget,
    reason: 'Grades: At-Risk text did not match expectation',
  );
  expect(
    find.text('Pending Impact'),
    findsOneWidget,
    reason: 'Grades: Pending Impact summary should be shown',
  );
  // Find the Pending Impact value (should be > 0)
  final pendingImpactCard = find.ancestor(
    of: find.text('Pending Impact'),
    matching: find.byType(Card),
  );
  final pendingValue = find.descendant(
    of: pendingImpactCard.first,
    matching: find.byWidgetPredicate(
      (w) => w is Text && int.tryParse(w.data ?? '') != null,
    ),
  );
  expect(
    pendingValue,
    findsOneWidget,
    reason: 'Grades: Pending Impact should show a numeric value',
  );
  final valueWidget = pendingValue.evaluate().first.widget as Text;
  final value = int.tryParse(valueWidget.data ?? '0') ?? 0;
  expect(
    value > 0,
    isTrue,
    reason: 'Grades: Pending Impact should be greater than 0',
  );
  expect(
    find.text('Grade Trend'),
    findsOneWidget,
    reason: 'Grades: Grade Trend text should be shown',
  );
  // Check for 4 summary cards (no GlobalKey) and 3 course grade cards (with GlobalKey)
  expect(
    find.byWidgetPredicate(
      (widget) => widget is Card && widget.key is! GlobalKey,
    ),
    findsNWidgets(4),
    reason: 'Grades: Should show 4 summary cards',
  );
  expect(
    find.byWidgetPredicate(
      (widget) => widget is Card && widget.key is GlobalKey,
    ),
    findsNWidgets(3),
    reason: 'Grades: Should show 3 course grade cards',
  );
  expect(
    find.text('Creative Writing ✍️'),
    findsNWidgets(2),
    reason: 'Grades: Creative Writing ✍️ grade card should be shown, and time series filter',
  );
  expect(
    find.text('Fundamentals of Programming 💻'),
    findsNWidgets(2),
    reason: 'Grades: Fundamentals of Programming 💻 grade card should be shown, and time series filter',
  );
  expect(
    find.text('Intro to Psychology 🧠'),
    findsNWidgets(2),
    reason: 'Grades: Intro to Psychology 🧠 grade card should be shown, and time series filter',
  );
  expect(
    find.text('Grades'),
    findsNWidgets(2),
    reason: 'Grades: Title or menu button not found',
  );
  expectBrowserTitle('Grades');
}

/// Assert we're on the Settings screen/dialog.
/// Verifies: volunteer_activism icon, "Support Helium" text, and "Change Password" button.
/// For dialog mode: FAB IS shown (from underlying Planner), browser title stays "Planner".
/// For mobile screen mode: FAB NOT shown, "Settings" shown in page header (browser title unchanged).
void expectOnSettingsScreen({required bool isDialog}) {
  expect(
    find.byIcon(Icons.volunteer_activism),
    findsWidgets,
    reason: 'Settings: giving icon should be shown',
  );
  expect(
    find.text('Support Helium'),
    findsOneWidget,
    reason: 'Settings: "Support Helium" text should be shown',
  );
  expect(
    find.text('Change Password'),
    findsOneWidget,
    reason: 'Settings: "Change Password" button should be shown',
  );
  // Browser title updates to Settings in both dialog and screen mode
  expectBrowserTitle('Settings');
  if (isDialog) {
    // Dialog mode: close (X) button in dialog header, no back button
    expect(
      find.byIcon(Icons.close),
      findsOneWidget,
      reason: 'Settings dialog: close button should be shown',
    );
    expect(
      find.byIcon(Icons.keyboard_arrow_left),
      findsNothing,
      reason: 'Settings dialog: back button should not be shown',
    );
  } else {
    // Screen mode: "Settings" title in page header, back button, no close button
    expect(
      find.text('Settings'),
      findsOneWidget,
      reason: 'Settings screen: Settings title should be shown in page header',
    );
    expect(
      find.byIcon(Icons.keyboard_arrow_left),
      findsOneWidget,
      reason: 'Settings screen: back button should be shown',
    );
    expect(
      find.byIcon(Icons.close),
      findsNothing,
      reason: 'Settings screen: dialog close button should not be shown',
    );
  }
}

/// Assert we're on the Login screen.
/// Verifies: browser title is "Login".
void expectOnLoginScreen() {
  expect(
    find.text('Sign In'),
    findsOneWidget,
    reason: 'Login: Sign In button should be shown',
  );
  expect(
    find.widgetWithText(TextField, 'Email'),
    findsOneWidget,
    reason: 'Login: Email field should be shown',
  );
  expect(
    find.widgetWithText(TextField, 'Password'),
    findsOneWidget,
    reason: 'Login: Password field should be shown',
  );
  expectBrowserTitle('Login');
}
