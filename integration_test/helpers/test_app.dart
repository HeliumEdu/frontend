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

bool _initialized = false;
bool _loggingInitialized = false;

/// Log level for integration tests.
/// - info: Only test names and pass/fail results (default)
/// - fine: Also includes app service logs
enum TestLogLevel { info, fine }

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
  const logLevelStr = String.fromEnvironment('TEST_LOG_LEVEL', defaultValue: 'info');
  _testLogLevel = logLevelStr == 'fine' ? TestLogLevel.fine : TestLogLevel.info;

  // Send init info to driver
  _sendLog(<String, dynamic>{
    'type': 'init',
    'environment': environment,
    'apiHost': apiHost,
    'logLevel': _testLogLevel.name,
  });

  // Configure app logging based on level
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    final formatted = LogFormatter.format(record);

    // Send to driver for terminal output if fine level enabled
    if (_testLogLevel == TestLogLevel.fine) {
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
/// - At info level: reports test name and pass/fail
/// - At fine level: also includes app service logs
@isTest
void namedTestWidgets(
  String description,
  Future<void> Function(WidgetTester) callback,
) {
  testWidgets(description, (tester) async {
    // Report test start
    await _sendLog(<String, dynamic>{
      'type': 'testStart',
      'test': description,
    });

    // ignore: avoid_print
    print('\n========================================');
    // ignore: avoid_print
    print('RUNNING: $description');
    // ignore: avoid_print
    print('========================================\n');

    try {
      await callback(tester);

      // Report success
      await _sendLog(<String, dynamic>{
        'type': 'testPass',
        'test': description,
      });
    } catch (e, stack) {
      // ignore: avoid_print
      print('\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      // ignore: avoid_print
      print('TEST FAILED: $description');
      // ignore: avoid_print
      print('ERROR: $e');
      // ignore: avoid_print
      print('STACK: $stack');
      // ignore: avoid_print
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');

      // Report failure with error details
      await _sendLog(<String, dynamic>{
        'type': 'testFail',
        'test': description,
        'error': e.toString(),
        'stack': stack.toString(),
      });

      // Pause to allow reading the error when running with visible browser
      const postTestDelay = int.fromEnvironment('POST_TEST_DELAY', defaultValue: 0);
      if (postTestDelay > 0) {
        await Future.delayed(const Duration(seconds: postTestDelay));
      }
      rethrow;
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
  await waitForWidget(
    tester,
    find.text('Sign In'),
    timeout: const Duration(seconds: 10),
  );

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

  await tester.tap(find.text('Sign In'));

  // Wait for either setup screen, welcome dialog, or planner to appear
  // Setup can take 15-30 seconds under high load
  const postLoginTimeout = Duration(seconds: 45);
  final endTime = DateTime.now().add(postLoginTimeout);

  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 500));

    // Check for setup screen
    if (find.text('Set Up Your Account').evaluate().isNotEmpty) {
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
      break;
    }

    // Check for planner (means we bypassed both setup and welcome)
    if (find.text('Planner').evaluate().isNotEmpty) {
      break;
    }
  }

  // Handle getting started dialog if present ("Welcome to Helium!")
  final gettingStartedDialog = find.text('Welcome to Helium!');
  if (gettingStartedDialog.evaluate().isNotEmpty) {
    await tester.tap(find.text("I'll explore first"));
    await tester.pumpAndSettle();
  }

  // Handle what's new dialog if present ("Welcome to the new Helium!")
  final whatsNewDialog = find.text('Welcome to the new Helium!');
  if (whatsNewDialog.evaluate().isNotEmpty) {
    await tester.tap(find.text('Dive In!'));
    await tester.pumpAndSettle();
  }

  // Wait for planner to load
  final plannerFound = await waitForWidget(
    tester,
    find.text('Planner'),
    timeout: const Duration(seconds: 30),
  );

  return plannerFound;
}
