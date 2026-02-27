// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'helpers/api_helper.dart';
import 'helpers/email_helper.dart';
import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('signup_user_test');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = TestConfig();
  initializeTestLogging(
    environment: config.environment,
    apiHost: config.projectApiHost,
  );

  group('User Signup Flow', () {
    final testEmail = config.testEmail;
    final testPassword = config.testPassword;
    final emailHelper = EmailHelper();
    final apiHelper = ApiHelper();

    // State tracking for dependent tests within this suite
    bool registrationSucceeded = false;

    setUpAll(() async {
      _log.info('Test email: $testEmail');

      // Clean up test user from previous runs
      await apiHelper.cleanupTestUser();
    });

    namedTestWidgets('1. User can sign up for a new account', (tester) async {
      await initializeTestApp(tester);

      // Navigate to signup screen
      await tester.tap(find.text('Need an account?'));
      await tester.pumpAndSettle();

      // Verify we're on the signup screen
      expect(find.text('Create an Account'), findsOneWidget);
      expectBrowserTitle('Create an Account');

      // Fill in the signup form using helper for web compatibility
      await enterTextInField(
        tester,
        find.widgetWithText(TextField, 'Email'),
        testEmail,
      );

      await enterTextInField(
        tester,
        find.widgetWithText(TextField, 'Password'),
        testPassword,
      );

      await enterTextInField(
        tester,
        find.widgetWithText(TextField, 'Confirm password'),
        testPassword,
      );

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
      expectBrowserTitle('Verify Email');

      registrationSucceeded = true;
      _log.info('Registration succeeded');

      // Should pre-populate Verify screen with email from query params
      final emailField = find.widgetWithText(TextField, 'Email');
      expect(emailField, findsOneWidget, reason: 'Email field should exist');
      final emailEditableText = find.descendant(
        of: emailField,
        matching: find.byType(EditableText),
      );
      final emailValue = (tester.widget<EditableText>(
        emailEditableText,
      )).controller.text;
      expect(
        emailValue,
        equals(testEmail),
        reason:
            'Email field should be pre-populated with username from query params',
      );
    });

    namedTestWidgets('2. User can verify email with code from S3', (
      tester,
    ) async {
      if (!registrationSucceeded) {
        skipTest('registration did not succeed');
        return;
      }

      await initializeTestApp(tester);

      // Wait for the app to settle and redirect to verify if needed
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Check if we're already on verify screen (from previous test)
      if (find.text('Verify Email').evaluate().isEmpty) {
        router.go(AppRoute.verifyEmailScreen);
        await tester.pumpAndSettle();
      }

      // Fetch the verification code from S3
      final verificationCode = await emailHelper.getVerificationCode(testEmail);

      // Enter verification code
      await enterTextInField(
        tester,
        find.widgetWithText(TextField, 'Verification code'),
        verificationCode,
      );

      // Submit verification
      await tester.tap(find.text('Verify & Login'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verification succeeded if we're no longer on the verify screen
      final stillOnVerify =
          find.text('Verify Email').evaluate().isNotEmpty &&
          find
              .widgetWithText(TextField, 'Verification code')
              .evaluate()
              .isNotEmpty;
      expect(
        stillOnVerify,
        isFalse,
        reason: 'Should have left verify screen after successful verification',
      );

      // Wait for navigation to planner (handles setup screen redirect automatically)
      final reachedPlanner = await waitForRoute(
        tester,
        '/planner',
        browserTitle: 'Planner',
        timeout: const Duration(seconds: 30),
      );
      expect(reachedPlanner, isTrue, reason: 'Should reach planner after verification');
    });
  });
}
