// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = TestConfig();
  // ignore: avoid_print
  print('Running smoke tests against: ${config.environment}');
  // ignore: avoid_print
  print('API host: ${config.projectApiHost}');

  group('Smoke Tests', () {
    testWidgets('app launches and shows login screen', (tester) async {
      await initializeTestApp(tester);

      // Verify the logo is displayed (match our logo asset, not package assets)
      final logoFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.startsWith('assets/img/logo'),
      );
      expect(logoFinder, findsOneWidget, reason: 'Logo should be displayed');

      // Verify the login form elements are displayed
      expect(
        find.text('Sign In'),
        findsOneWidget,
        reason: 'Sign In button should be displayed',
      );
      expect(
        find.widgetWithText(TextField, 'Email'),
        findsOneWidget,
        reason: 'Email field should be displayed',
      );
      expect(
        find.widgetWithText(TextField, 'Password'),
        findsOneWidget,
        reason: 'Password field should be displayed',
      );

      // Verify navigation options are present
      expect(
        find.text('Need an account?'),
        findsOneWidget,
        reason: 'Sign up link should be displayed',
      );
      expect(
        find.text('Forgot your password?'),
        findsOneWidget,
        reason: 'Forgot password link should be displayed',
      );

      // Verify OAuth options are present
      expect(
        find.text('Sign in with Google'),
        findsOneWidget,
        reason: 'Google sign in should be displayed',
      );
    });

    testWidgets('can navigate to signup screen', (tester) async {
      await initializeTestApp(tester);

      // Tap "Need an account?" link
      await tester.tap(find.text('Need an account?'));
      await tester.pumpAndSettle();

      // Verify we're on the signup screen
      expect(
        find.text('Create an Account'),
        findsOneWidget,
        reason: 'Should navigate to signup screen',
      );

      // Verify signup form elements are displayed
      expect(
        find.widgetWithText(TextField, 'Email'),
        findsOneWidget,
        reason: 'Email field should be displayed on signup',
      );
      expect(
        find.widgetWithText(TextField, 'Password'),
        findsOneWidget,
        reason: 'Password field should be displayed on signup',
      );
      expect(
        find.widgetWithText(TextField, 'Confirm password'),
        findsOneWidget,
        reason: 'Confirm password field should be displayed on signup',
      );
      expect(
        find.text('Sign Up'),
        findsOneWidget,
        reason: 'Sign Up button should be displayed',
      );

      // Verify terms checkbox is present
      expect(
        find.byType(CheckboxListTile),
        findsOneWidget,
        reason: 'Terms checkbox should be displayed',
      );

      // Verify back to login link
      expect(
        find.text('Back to login'),
        findsOneWidget,
        reason: 'Back to login link should be displayed',
      );
    });
  });
}
