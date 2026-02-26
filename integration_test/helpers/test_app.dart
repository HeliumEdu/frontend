// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
// ignore: implementation_imports
import 'package:test_api/src/backend/invoker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/log_formatter.dart';
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

final _log = Logger('test_app_helper');

bool _initialized = false;
bool _loggingInitialized = false;
String _currentTestDisplayName = '';

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

/// Initialize logging for integration tests.
/// Safe to call multiple times - only sets up the listener once.
void initializeTestLogging({required String environment, required String apiHost}) {
  if (_loggingInitialized) return;
  _loggingInitialized = true;

  // Parse log level from environment
  const logLevelStr = String.fromEnvironment('INTEGRATION_LOG_LEVEL', defaultValue: 'info');
  _testLogLevel = switch (logLevelStr) {
    'finer' => TestLogLevel.finer,
    'fine' => TestLogLevel.fine,
    _ => TestLogLevel.info,
  };

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
      'type': 'log',
      'message': '\x1B[91mTEST EXCEPTION:\x1B[0m ${details.exceptionAsString()}',
    });
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
    final formatted = LogFormatter.format(record);
    final loggerName = record.loggerName;

    // Determine if this is a test logger (integration test files and helpers)
    final isTestLogger = loggerName.endsWith('_test') || loggerName.endsWith('_helper');

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
      _sendLog(<String, dynamic>{
        'type': 'log',
        'message': formatted,
      });
    }

    // Always print to browser console for DevTools debugging
    // ignore: avoid_print
    print(formatted);
  });
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
    // Build display name with group prefix from test framework
    final groups = Invoker.current?.liveTest.groups ?? [];
    final groupName = groups.length > 1 ? groups.last.name : '';
    final displayName = groupName.isNotEmpty
        ? '$groupName: $description'
        : description;

    // Store for use by reportTestException hook
    _currentTestDisplayName = displayName;

    // Report test start
    await _sendLog(<String, dynamic>{
      'type': 'testStart',
      'test': displayName,
    });

    // ignore: avoid_print
    print('\n========================================');
    // ignore: avoid_print
    print('RUNNING: $displayName');
    // ignore: avoid_print
    print('========================================\n');

    // Run the test callback - failures are handled by reportTestException hook
    await callback(tester);

    // If we get here, the test passed
    await _sendLog(<String, dynamic>{
      'type': 'testPass',
      'test': displayName,
    });
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
    final editableTextState = tester.state<EditableTextState>(editableTextFinder);
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
    _log.info('Already on login screen');
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

/// Helper to log in and navigate to planner, handling setup/welcome dialogs
Future<bool> loginAndNavigateToPlanner(
  WidgetTester tester,
  String email,
  String password,
) async {
  // First ensure we're on the login screen
  await ensureOnLoginScreen(tester);

  // Use helper for web-compatible text entry
  await enterTextInField(tester, find.widgetWithText(TextField, 'Email'), email);
  await enterTextInField(tester, find.widgetWithText(TextField, 'Password'), password);

  _log.info('Submitting login ...');
  await tester.tap(find.text('Sign In'));

  // Wait for either setup screen, welcome dialog, or planner to appear
  // Setup can take 15-30 seconds under high load
  const postLoginTimeout = Duration(seconds: 45);
  final endTime = DateTime.now().add(postLoginTimeout);

  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 500));

    // Check for setup screen
    if (find.text('Set Up Your Account').evaluate().isNotEmpty) {
      _log.info('Setup screen detected, skipping ...');
      final skipButton = find.text('Skip');
      final continueButton = find.text('Continue');

      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
      } else if (continueButton.evaluate().isNotEmpty) {
        await tester.tap(continueButton);
      }
      await tester.pumpAndSettle(const Duration(seconds: 10));
      break;
    }

    // Check for welcome dialog (means we bypassed setup)
    if (find.text('Welcome to Helium!').evaluate().isNotEmpty) {
      _log.info('Welcome dialog detected (bypassed setup)');
      break;
    }

    // Check for planner (means we bypassed both setup and welcome)
    if (find.text('Planner').evaluate().isNotEmpty) {
      _log.info('Planner detected (bypassed setup and welcome)');
      break;
    }
  }

  // Handle getting started dialog if present ("Welcome to Helium!")
  final gettingStartedDialog = find.text('Welcome to Helium!');
  if (gettingStartedDialog.evaluate().isNotEmpty) {
    _log.info('Dismissing getting started dialog ...');
    await tester.tap(find.text("I'll explore first"));
    await tester.pumpAndSettle();
  }

  // Handle what's new dialog if present ("Welcome to the new Helium!")
  final whatsNewDialog = find.text('Welcome to the new Helium!');
  if (whatsNewDialog.evaluate().isNotEmpty) {
    _log.info('Dismissing what\'s new dialog ...');
    await tester.tap(find.text('Dive In!'));
    await tester.pumpAndSettle();
  }

  // Wait for planner to load
  final plannerFound = await waitForWidget(
    tester,
    find.text('Planner'),
    timeout: const Duration(seconds: 30),
  );

  if (plannerFound) {
    _log.info('Successfully navigated to planner');
  } else {
    _log.warning('Failed to navigate to planner within timeout');
  }

  return plannerFound;
}

/// Get the current browser document title.
String getBrowserTitle() {
  return web.document.title;
}

/// Verify the browser title contains the expected page name.
/// The app uses format: "PageName | Helium"
void expectBrowserTitle(String expectedPageName) {
  final title = getBrowserTitle();
  expect(
    title.contains(expectedPageName),
    isTrue,
    reason: 'Browser title should contain "$expectedPageName", but was "$title"',
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
/// Verifies: "Today" button, Filter icon, Search icon, and FAB are shown.
void expectOnPlannerScreen() {
  expect(find.text('Today'), findsOneWidget, reason: 'Planner: Today button should be shown');
  expect(find.byIcon(Icons.filter_alt), findsOneWidget, reason: 'Planner: Filter icon should be shown');
  expect(find.byIcon(Icons.search), findsWidgets, reason: 'Planner: Search icon should be shown');
  expect(find.byType(FloatingActionButton), findsOneWidget, reason: 'Planner: FAB should be shown');
  expect(find.text('Planner'), findsNWidgets(2), reason: 'Planner: Title or menu button not found');
  expectBrowserTitle('Planner');
}

/// Assert we're on the Classes screen.
/// Verifies: FAB is shown, 3 course cards with expected titles (titles end with emojis).
void expectOnClassesScreen() {
  expect(find.byType(FloatingActionButton), findsOneWidget, reason: 'Classes: FAB should be shown');
  expect(find.byType(Card), findsNWidgets(3), reason: 'Classes: Should show 3 course cards');
  expect(find.text('Fall Semester'), findsOneWidget, reason: 'Classes: Fall Semester group should be shown');
  expect(find.textContaining('Creative Writing'), findsOneWidget, reason: 'Classes: Creative Writing course should be shown');
  expect(find.textContaining('Fundamentals'), findsOneWidget, reason: 'Classes: Fundamentals course should be shown');
  expect(find.textContaining('Intro to Psych'), findsOneWidget, reason: 'Classes: Intro to Psych course should be shown');
  expect(find.text('Classes'), findsNWidgets(2), reason: 'Classes: Title or menu button not found');
  expectBrowserTitle('Classes');
}

/// Assert we're on the Resources screen.
/// Verifies: FAB is shown, 1 resource card with expected title.
void expectOnResourcesScreen() {
  expect(find.byType(FloatingActionButton), findsOneWidget, reason: 'Resources: FAB should be shown');
  expect(find.byType(Card), findsOneWidget, reason: 'Resources: Should show 1 resource card');
  expect(find.text('Textbooks'), findsOneWidget, reason: 'Resources: Google Workspace should be shown');
  expect(find.text('Google Workspace'), findsOneWidget, reason: 'Resources: Google Workspace should be shown');
  expect(find.text('Resources'), findsNWidgets(2), reason: 'Resources: Title or menu button not found');
  expectBrowserTitle('Resources');
}

/// Assert we're on the Grades screen.
/// Verifies: "Grade Trend" text shown, FAB NOT shown, 4 summary widgets at top,
/// "28" below "Pending Impact", 3 course grade cards.
void expectOnGradesScreen() {
  expect(find.text('Grade Trend'), findsOneWidget, reason: 'Grades: Grade Trend text should be shown');
  expect(find.byType(FloatingActionButton), findsNothing, reason: 'Grades: FAB should NOT be shown');
  // Check for 4 summary widgets at top (Overall, Trend, Pending Impact, Target)
  expect(find.text('Overall'), findsOneWidget, reason: 'Grades: Overall summary should be shown');
  expect(find.text('Trend'), findsOneWidget, reason: 'Grades: Trend summary should be shown');
  expect(find.text('Pending Impact'), findsOneWidget, reason: 'Grades: Pending Impact summary should be shown');
  expect(find.text('Target'), findsOneWidget, reason: 'Grades: Target summary should be shown');
  // Check for the pending impact count
  expect(find.text('28'), findsOneWidget, reason: 'Grades: Pending Impact should show 28');
  // Check for 3 course grade cards (same titles as Classes screen, titles end with emojis)
  expect(find.byType(Card), findsNWidgets(3), reason: 'Grades: Should show 3 course grade cards');
  expect(find.textContaining('Creative Writing'), findsOneWidget, reason: 'Grades: Creative Writing grade card should be shown');
  expect(find.textContaining('Fundamentals'), findsOneWidget, reason: 'Grades: Fundamentals grade card should be shown');
  expect(find.textContaining('Intro to Psych'), findsOneWidget, reason: 'Grades: Intro to Psych grade card should be shown');
  expect(find.text('Grades'), findsNWidgets(2), reason: 'Grades: Title or menu button not found');
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
  if (isDialog) {
    // Dialog mode: FAB from underlying Planner is still visible, title stays on Planner
    expect(find.byType(FloatingActionButton), findsOneWidget, reason: 'Settings dialog: FAB should be shown (from Planner)');
    expectBrowserTitle('Planner');
  } else {
    // Mobile screen mode: no FAB, "Settings" title shown in page header (not browser title)
    expect(find.byType(FloatingActionButton), findsNothing, reason: 'Settings screen: FAB should NOT be shown');
    expect(find.text('Settings'), findsOneWidget, reason: 'Settings screen: Settings title should be shown in page header');
    expectBrowserTitle('Planner');
  }
}

/// Assert we're on the Login screen.
/// Verifies: browser title is "Login".
void expectOnLoginScreen() {
  expect(find.text('Sign In'), findsOneWidget, reason: 'Login: Sign In button should be shown');
  expect(find.widgetWithText(TextField, 'Email'), findsOneWidget, reason: 'Login: Email field should be shown');
  expect(find.widgetWithText(TextField, 'Password'), findsOneWidget, reason: 'Login: Password field should be shown');
  expectBrowserTitle('Login');
}
