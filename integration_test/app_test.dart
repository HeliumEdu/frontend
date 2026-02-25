// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'helpers/api_helper.dart';
import 'helpers/email_helper.dart';
import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('integration_test');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Set up logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final config = TestConfig();
  // ignore: avoid_print
  print('Running integration tests against: ${config.environment}');
  // ignore: avoid_print
  print('API host: ${config.projectApiHost}');

  group('Smoke Tests', () {
    testWidgets('app launches and shows login screen', (tester) async {
      await initializeTestApp(tester);

      // Verify the login screen is displayed
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });
  });

  group('User Registration Flow', () {
    final testEmail = config.testEmail;
    final testPassword = config.testPassword;
    final emailHelper = EmailHelper();
    final apiHelper = ApiHelper();

    setUpAll(() async {
      _log.info('Test email: $testEmail');

      // Clean up test user from previous runs
      await apiHelper.cleanupTestUser();
    });

    testWidgets('1. User can sign up for a new account', (tester) async {
      await initializeTestApp(tester);

      // Navigate to signup screen
      await tester.tap(find.text('Need an account?'));
      await tester.pumpAndSettle();

      // Verify we're on the signup screen
      expect(find.text('Create an Account'), findsOneWidget);

      // Fill in the signup form
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        testEmail,
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        testPassword,
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm password'),
        testPassword,
      );
      await tester.pumpAndSettle();

      // Agree to terms - find and tap the checkbox
      final checkbox = find.byType(CheckboxListTile);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Submit the form
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should navigate to verify email screen
      final verifyScreenFound = await waitForWidget(
        tester,
        find.text('Verify Email'),
        timeout: const Duration(seconds: 15),
      );
      expect(
        verifyScreenFound,
        isTrue,
        reason: 'Should navigate to verify email screen',
      );
    });

    testWidgets('2. User can verify email with code from S3', (tester) async {
      await initializeTestApp(tester);

      // Fetch the verification code from S3
      _log.info('Fetching verification code from S3...');
      final verificationCode = await emailHelper.getVerificationCode(testEmail);
      _log.info('Got verification code: $verificationCode');

      // Navigate to verify email screen via login with unverified account
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        testEmail,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        testPassword,
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Either: shows snackbar with "Resend Email" OR navigates to verify screen
      // Check if we're on verify screen
      var onVerifyScreen = find.text('Verify Email').evaluate().isNotEmpty;

      if (!onVerifyScreen) {
        // Look for "Resend Email" button in snackbar and tap it
        final resendButton = find.text('Resend Email');
        if (resendButton.evaluate().isNotEmpty) {
          await tester.tap(resendButton);
          await tester.pumpAndSettle(const Duration(seconds: 5));
          onVerifyScreen = find.text('Verify Email').evaluate().isNotEmpty;
        }
      }

      expect(onVerifyScreen, isTrue, reason: 'Should be on verify email screen');

      // Email field should be pre-filled, enter verification code
      await tester.enterText(
        find.widgetWithText(TextField, 'Verification code'),
        verificationCode,
      );
      await tester.pumpAndSettle();

      // Submit verification
      await tester.tap(find.text('Verify & Login'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Should navigate to setup account screen after verification
      final setupScreenFound = await waitForWidget(
        tester,
        find.text('Set Up Your Account'),
        timeout: const Duration(seconds: 15),
      );
      expect(
        setupScreenFound,
        isTrue,
        reason: 'Should navigate to setup screen after verification',
      );
    });

    testWidgets('3. Verified user can login and see planner', (tester) async {
      await initializeTestApp(tester);

      // Login with the verified account
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        testEmail,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        testPassword,
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Should navigate to setup screen (first login after verify)
      // or planner if setup was somehow already done
      final setupScreen = find.text('Set Up Your Account');
      if (setupScreen.evaluate().isNotEmpty) {
        _log.info('On setup screen, completing setup...');

        // Look for the "Continue" button to skip setup
        final skipButton = find.text('Skip');
        final continueButton = find.text('Continue');

        if (skipButton.evaluate().isNotEmpty) {
          await tester.tap(skipButton);
        } else if (continueButton.evaluate().isNotEmpty) {
          await tester.tap(continueButton);
        }
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Now verify we're on the planner screen
      final plannerFound = await waitForWidget(
        tester,
        find.text('Planner'),
        timeout: const Duration(seconds: 15),
      );

      expect(plannerFound, isTrue, reason: 'Should be on planner screen');
    });

    testWidgets('4. First login shows welcome dialog', (tester) async {
      await initializeTestApp(tester);

      // Login with the test account
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        testEmail,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        testPassword,
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Handle setup screen if present
      final setupScreen = find.text('Set Up Your Account');
      if (setupScreen.evaluate().isNotEmpty) {
        final skipButton = find.text('Skip');
        final continueButton = find.text('Continue');

        if (skipButton.evaluate().isNotEmpty) {
          await tester.tap(skipButton);
        } else if (continueButton.evaluate().isNotEmpty) {
          await tester.tap(continueButton);
        }
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Wait for the welcome dialog to appear (on first planner load)
      final welcomeDialogFound = await waitForWidget(
        tester,
        find.text('Welcome to Helium!'),
        timeout: const Duration(seconds: 15),
      );

      if (welcomeDialogFound) {
        // Verify dialog content
        expect(
          find.text("I'll explore first"),
          findsOneWidget,
          reason: 'Should have explore button',
        );
        expect(
          find.text('Clear Example Data'),
          findsOneWidget,
          reason: 'Should have clear data button',
        );

        // Dismiss the dialog
        await tester.tap(find.text("I'll explore first"));
        await tester.pumpAndSettle();
      }

      // Verify we're on the planner screen
      expect(find.text('Planner'), findsOneWidget);
    });

  });
}
