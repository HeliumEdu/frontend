// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/presentation/ui/components/settings_button.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'helpers/api_helper.dart';
import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('logout_test');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = TestConfig();
  initializeTestLogging(
    environment: config.environment,
    apiHost: config.projectApiHost,
  );

  group('Logout Test', () {
    final testEmail = config.testEmail;
    final testPassword = config.testPassword;
    final apiHelper = ApiHelper();

    bool canProceed = false;

    setUpAll(() async {
      await startSuite('Logout Test');
      _log.info('Test email: $testEmail');

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

    namedTestWidgets('1. User can logout and tokens are cleared', (
      tester,
    ) async {
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

      _log.info('Scrolling to Logout ...');
      final logoutItem = find.text('Logout');
      await scrollUntilVisible(tester, logoutItem);
      expect(logoutItem, findsWidgets, reason: 'Logout item should exist');
      await tester.tap(logoutItem.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      _log.info('Waiting for logout confirmation dialog ...');
      final dialog = find.byType(AlertDialog);
      expect(
        dialog,
        findsOneWidget,
        reason: 'Logout confirmation dialog should be open',
      );

      // The row label, dialog title, and confirm button all read "Logout".
      // Scope to the dialog so we tap the confirm button, not the title text.
      final confirmButton = find.descendant(
        of: dialog,
        matching: find.text('Logout'),
      );
      expect(
        confirmButton,
        findsWidgets,
        reason: 'Logout confirm button should be in dialog',
      );
      _log.info('Confirming logout ...');
      await tester.tap(confirmButton.last);

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
        reason: 'Should be redirected to login after logout',
      );

      // PrefService is a singleton; the test process reads the same secure
      // storage the production logout path writes. If anyone removes
      // dioClient.clearStorage() from the logout flow, these fail loudly.
      _log.info('Verifying tokens were cleared from secure storage ...');
      final accessToken = await PrefService().getSecure('access_token');
      final refreshToken = await PrefService().getSecure('refresh_token');
      expect(
        accessToken,
        isNull,
        reason: 'access_token should be cleared after logout',
      );
      expect(
        refreshToken,
        isNull,
        reason: 'refresh_token should be cleared after logout',
      );
      _log.info('Logout cleared tokens from secure storage');
    });
  });
}
