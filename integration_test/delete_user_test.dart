// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/presentation/features/settings/views/settings_screen.dart';
import 'package:heliumapp/presentation/ui/components/settings_button.dart';
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
      await startSuite('Delete User Test');
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

    tearDownAll(() async {
      await endSuite();
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
      _log.info('Waiting for settings button ...');
      final settingsButton = find.byKey(const Key(SettingsButton.buttonKey));
      final settingsFound = await waitForWidget(
        tester,
        settingsButton,
        timeout: config.apiTimeout,
      );
      expect(
        settingsFound,
        isTrue,
        reason: 'Settings button should be visible',
      );
      _log.info('Tapping settings button ...');
      await tester.tap(settingsButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap "Danger Zone"
      _log.info('Scrolling to Danger Zone ...');
      final dangerZone = find.text('Danger Zone');
      await scrollUntilVisible(tester, dangerZone);
      expect(dangerZone, findsOneWidget, reason: 'Danger Zone should exist');
      await tester.tap(dangerZone);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap "Delete Account"
      _log.info('Tapping Delete Account ...');
      final deleteAccount = find.text('Delete Account');
      expect(
        deleteAccount,
        findsOneWidget,
        reason: 'Delete Account should exist',
      );
      await tester.tap(deleteAccount);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Enter password in the confirmation dialog
      _log.info('Entering password in confirmation dialog ...');
      final dialog = find.byType(AlertDialog);
      expect(
        dialog,
        findsOneWidget,
        reason: 'Delete confirmation dialog should be open',
      );
      final passwordField = find.byKey(const Key(SettingsScreen.deleteAccountPasswordField));
      expect(
        passwordField,
        findsOneWidget,
        reason: 'Password field should be in dialog',
      );
      await enterTextInField(tester, passwordField, testPassword);

      // Confirm deletion
      _log.info('Confirming account deletion ...');
      final deleteButton = find.descendant(
        of: dialog,
        matching: find.text('Delete'),
      );
      expect(
        deleteButton,
        findsOneWidget,
        reason: 'Delete button should be in dialog',
      );
      await tester.tap(deleteButton);

      _log.info(
        'Waiting for redirect to login (timeout: ${config.apiTimeout.inSeconds}s) ...',
      );
      final loginScreenFound = await waitForRoute(
        tester,
        AppRoute.loginScreen,
        browserTitle: 'Login',
        timeout: config.apiTimeout,
      );
      expect(
        loginScreenFound,
        isTrue,
        reason: 'Should be redirected to login after account deletion',
      );

      // Verify account is actually deleted via API (with polling). Drop any
      // cached access token first — userExists for the test email reuses
      // getAccessToken's cache, which would otherwise keep returning the
      // pre-deletion token and report "still exists" forever.
      _log.info('Verifying account deletion via API ...');
      apiHelper.invalidateAccessToken();
      var accountDeleted = false;
      const maxAttempts = 36; // 3 minutes with 5-second intervals
      for (var i = 0; i < maxAttempts && !accountDeleted; i++) {
        await Future.delayed(const Duration(seconds: 5));
        apiHelper.invalidateAccessToken();
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
