// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_route.dart';
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

      // Open settings (wait for button to be visible after navigation shell loads)
      final settingsButton = find.byIcon(Icons.settings_outlined);
      final settingsFound = await waitForWidget(tester, settingsButton, timeout: const Duration(seconds: 10));
      expect(settingsFound, isTrue, reason: 'Settings button should be visible');
      await tester.tap(settingsButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap "Danger Zone"
      final dangerZone = find.text('Danger Zone');
      await scrollUntilVisible(tester, dangerZone);
      expect(dangerZone, findsOneWidget, reason: 'Danger Zone should exist');
      await tester.tap(dangerZone);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap "Delete Account"
      final deleteAccount = find.text('Delete Account');
      expect(deleteAccount, findsOneWidget, reason: 'Delete Account should exist');
      await tester.tap(deleteAccount);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Enter password in the confirmation dialog
      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget, reason: 'Delete confirmation dialog should be open');
      final passwordField = find.descendant(
        of: dialog,
        matching: find.byType(TextField),
      );
      expect(passwordField, findsOneWidget, reason: 'Password field should be in dialog');
      await enterTextInField(tester, passwordField, testPassword);

      // Confirm deletion
      final deleteButton = find.descendant(
        of: dialog,
        matching: find.text('Delete'),
      );
      expect(deleteButton, findsOneWidget, reason: 'Delete button should be in dialog');
      await tester.tap(deleteButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final loginScreenFound = await waitForRoute(
        tester,
        AppRoute.loginScreen,
        browserTitle: 'Login',
        timeout: const Duration(seconds: 30),
      );
      expect(loginScreenFound, isTrue, reason: 'Should be redirected to login after account deletion');

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
