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
import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('delete_user_test');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = TestConfig();
  initializeTestLogging(
    environment: config.environment,
    apiHost: config.projectApiHost,
  );

  group('Delete User Test', () {
    final testEmail = config.testEmail;
    final testPassword = config.testPassword;
    final apiHelper = ApiHelper();

    // Track if preconditions are met
    bool canProceed = false;

    setUpAll(() async {
      _log.info('Test email: $testEmail');

      // Check if user can login (requires signup_user_test to have run first)
      final userExists = await apiHelper.userExists(testEmail);
      if (!userExists) {
        _log.warning('Test user does not exist. Run signup_user_test first.');
        canProceed = false;
      } else {
        _log.info('Test user exists, proceeding with test');
        canProceed = true;
      }
    });

    namedTestWidgets('1. User can delete their account', (tester) async {
      if (!canProceed) {
        _log.warning('Skipping: user does not exist');
        skipTest('user does not exist (run signup_user_test first)');
        return;
      }

      await initializeTestApp(tester);
      final loggedIn = await loginAndNavigateToPlanner(
        tester,
        testEmail,
        testPassword,
      );
      expect(loggedIn, isTrue, reason: 'Should be logged in');
      expectBrowserTitle('Planner');

      // Open settings
      final settingsButton = find.byIcon(Icons.settings_outlined);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap "Danger Zone"
      final dangerZone = find.text('Danger Zone');
      expect(dangerZone, findsOneWidget, reason: 'Danger Zone should exist');
      await tester.tap(dangerZone);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap "Delete Account"
      final deleteAccount = find.text('Delete Account');
      expect(deleteAccount, findsOneWidget, reason: 'Delete Account should exist');
      await tester.tap(deleteAccount);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Enter password in the confirmation dialog
      final passwordField = find.widgetWithText(TextField, 'Password');
      if (passwordField.evaluate().isNotEmpty) {
        await enterTextInField(tester, passwordField, testPassword);
      }

      // Confirm deletion
      final confirmButton = find.text('Confirm');
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      } else {
        final deleteButton = find.text('Delete');
        if (deleteButton.evaluate().isNotEmpty) {
          await tester.tap(deleteButton);
          await tester.pumpAndSettle(const Duration(seconds: 5));
        }
      }

      // Verify we're redirected to login screen
      final loginScreenFound = await waitForWidget(
        tester,
        find.text('Sign In'),
        timeout: const Duration(seconds: 30),
      );
      expect(
        loginScreenFound,
        isTrue,
        reason: 'Should be redirected to login after account deletion',
      );
      expectBrowserTitle('Login');

      // Verify account is actually deleted via API (with polling)
      _log.info('Verifying account deletion via API ...');
      var accountDeleted = false;
      const maxAttempts = 36; // 3 minutes with 5-second intervals
      for (var i = 0; i < maxAttempts && !accountDeleted; i++) {
        await Future.delayed(const Duration(seconds: 5));
        accountDeleted = !(await apiHelper.userExists(testEmail));
        if (!accountDeleted) {
          _log.info('Account still exists, waiting... (${i + 1}/$maxAttempts)');
        }
      }

      expect(
        accountDeleted,
        isTrue,
        reason: 'Account should be deleted from backend',
      );
      _log.info('Account successfully deleted');
    });
  });
}
