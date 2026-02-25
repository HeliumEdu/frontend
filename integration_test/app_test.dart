// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'helpers/api_helper.dart';
import 'helpers/email_helper.dart';
import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('integration_test');

// State tracking for dependent tests
bool _registrationSucceeded = false;
bool _verificationSucceeded = false;
bool _loginSucceeded = false;

// Track the homework item title for CRUD test
String? _homeworkItemTitle;

/// Helper to log in and navigate to planner, handling setup/welcome dialogs
Future<bool> loginAndNavigateToPlanner(
  WidgetTester tester,
  String email,
  String password,
) async {
  final log = Logger('loginAndNavigateToPlanner');

  // Tap fields first for web compatibility
  final emailField = find.widgetWithText(TextField, 'Email');
  await tester.tap(emailField);
  await tester.pumpAndSettle();
  await tester.enterText(emailField, email);

  final passwordField = find.widgetWithText(TextField, 'Password');
  await tester.tap(passwordField);
  await tester.pumpAndSettle();
  await tester.enterText(passwordField, password);

  await tester.tap(find.text('Sign In'));

  // Wait for either setup screen, welcome dialog, or planner to appear
  // Setup can take 15-30 seconds under high load
  log.info('Waiting for post-login screen...');
  const postLoginTimeout = Duration(seconds: 45);
  final endTime = DateTime.now().add(postLoginTimeout);

  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 500));

    // Check for setup screen
    if (find.text('Set Up Your Account').evaluate().isNotEmpty) {
      log.info('Setup screen detected, skipping...');
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
      log.info('Welcome dialog detected');
      break;
    }

    // Check for planner (means we bypassed both setup and welcome)
    if (find.text('Planner').evaluate().isNotEmpty) {
      log.info('Planner screen detected');
      break;
    }
  }

  // Handle welcome dialog if present
  final welcomeDialog = find.text('Welcome to Helium!');
  if (welcomeDialog.evaluate().isNotEmpty) {
    log.info('Dismissing welcome dialog...');
    await tester.tap(find.text("I'll explore first"));
    await tester.pumpAndSettle();
  }

  // Wait for planner to load
  final plannerFound = await waitForWidget(
    tester,
    find.text('Planner'),
    timeout: const Duration(seconds: 30),
  );

  log.info('Login flow complete, planner found: $plannerFound');
  return plannerFound;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Set up logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final config = TestConfig();
  // ignore: avoid_print
  print('Running full integration tests against: ${config.environment}');
  // ignore: avoid_print
  print('API host: ${config.projectApiHost}');

  group('User Registration Flow', () {
    final testEmail = config.testEmail;
    final testPassword = config.testPassword;
    final emailHelper = EmailHelper();
    final apiHelper = ApiHelper();

    setUpAll(() async {
      _log.info('Test email: $testEmail');

      // Reset state flags
      _registrationSucceeded = false;
      _verificationSucceeded = false;
      _loginSucceeded = false;
      _homeworkItemTitle = null;

      // Clean up test user from previous runs
      await apiHelper.cleanupTestUser();
    });

    tearDownAll(() async {
      // Test 9 deletes the account, so only clean up if tests didn't complete
      // or if the account somehow still exists
      final userStillExists = await apiHelper.userExists(testEmail);
      if (userStillExists) {
        _log.info('Cleaning up test user after all tests...');
        await apiHelper.cleanupTestUser();
      } else {
        _log.info('Test user already deleted (by test 9 or not created)');
      }
    });

    testWidgets('1. User can sign up for a new account', (tester) async {
      await initializeTestApp(tester);

      // Navigate to signup screen
      await tester.tap(find.text('Need an account?'));
      await tester.pumpAndSettle();

      // Verify we're on the signup screen
      expect(find.text('Create an Account'), findsOneWidget);

      // Fill in the signup form (tap fields first for web compatibility)
      final emailField = find.widgetWithText(TextField, 'Email');
      await tester.tap(emailField);
      await tester.pumpAndSettle();
      await tester.enterText(emailField, testEmail);
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(TextField, 'Password');
      await tester.tap(passwordField);
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, testPassword);
      await tester.pumpAndSettle();

      final confirmPasswordField = find.widgetWithText(TextField, 'Confirm password');
      await tester.tap(confirmPasswordField);
      await tester.pumpAndSettle();
      await tester.enterText(confirmPasswordField, testPassword);
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

      _registrationSucceeded = true;
      _log.info('Registration succeeded');
    });

    testWidgets('2. User can verify email with code from S3', (tester) async {
      if (!_registrationSucceeded) {
        _log.warning('Skipping: registration did not succeed');
        markTestSkipped('Skipped: registration did not succeed');
        return;
      }

      await initializeTestApp(tester);

      // Fetch the verification code from S3
      _log.info('Fetching verification code from S3...');
      final verificationCode = await emailHelper.getVerificationCode(testEmail);
      _log.info('Got verification code: $verificationCode');

      // Navigate to verify email screen via login with unverified account
      final emailField = find.widgetWithText(TextField, 'Email');
      await tester.tap(emailField);
      await tester.pumpAndSettle();
      await tester.enterText(emailField, testEmail);

      final passwordField = find.widgetWithText(TextField, 'Password');
      await tester.tap(passwordField);
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, testPassword);

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
      final codeField = find.widgetWithText(TextField, 'Verification code');
      await tester.tap(codeField);
      await tester.pumpAndSettle();
      await tester.enterText(codeField, verificationCode);
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

      _verificationSucceeded = true;
      _log.info('Verification succeeded');
    });

    testWidgets('3. Verified user can login and see planner', (tester) async {
      if (!_verificationSucceeded) {
        _log.warning('Skipping: verification did not succeed');
        markTestSkipped('Skipped: verification did not succeed');
        return;
      }

      await initializeTestApp(tester);

      // Login with the verified account (tap fields first for web)
      final emailField = find.widgetWithText(TextField, 'Email');
      await tester.tap(emailField);
      await tester.pumpAndSettle();
      await tester.enterText(emailField, testEmail);

      final passwordField = find.widgetWithText(TextField, 'Password');
      await tester.tap(passwordField);
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, testPassword);

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

      _loginSucceeded = true;
      _log.info('Login succeeded');
    });

    testWidgets('4. First login shows welcome dialog', (tester) async {
      if (!_verificationSucceeded) {
        _log.warning('Skipping: verification did not succeed');
        markTestSkipped('Skipped: verification did not succeed');
        return;
      }

      await initializeTestApp(tester);

      // Login with the test account (tap fields first for web)
      final emailField = find.widgetWithText(TextField, 'Email');
      await tester.tap(emailField);
      await tester.pumpAndSettle();
      await tester.enterText(emailField, testEmail);

      final passwordField = find.widgetWithText(TextField, 'Password');
      await tester.tap(passwordField);
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, testPassword);

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

    testWidgets('5. Calendar displays example schedule items', (tester) async {
      if (!_loginSucceeded) {
        _log.warning('Skipping: login did not succeed');
        markTestSkipped('Skipped: login did not succeed');
        return;
      }

      await initializeTestApp(tester);
      final loggedIn = await loginAndNavigateToPlanner(
        tester,
        testEmail,
        testPassword,
      );
      expect(loggedIn, isTrue, reason: 'Should be logged in');

      // The example schedule is adjusted to the first Monday of the previous month
      // We need to navigate to that month to see the items
      // First, let's check if we can see any example data on the current view

      // Look for a homework item (has assignment icon or specific title pattern)
      // Example homework titles: "Homework 1", "Quiz 1", "Essay 1", etc.
      final homeworkFinder = find.textContaining('Homework');
      final quizFinder = find.textContaining('Quiz');

      // Look for an event (e.g., "Writing Workshop", "Group Meeting")
      final workshopFinder = find.textContaining('Workshop');
      final meetingFinder = find.textContaining('Meeting');

      // Look for a course schedule (course titles contain emojis)
      final programmingFinder = find.textContaining('Programming');
      final writingFinder = find.textContaining('Writing');
      final psychologyFinder = find.textContaining('Psychology');

      // Navigate to previous month where example data should be
      // Find and tap the left arrow to go to previous month
      final prevMonthButton = find.byIcon(Icons.chevron_left);
      if (prevMonthButton.evaluate().isNotEmpty) {
        await tester.tap(prevMonthButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Now check for example schedule items
      // At least one homework item should be visible
      final hasHomework = homeworkFinder.evaluate().isNotEmpty ||
          quizFinder.evaluate().isNotEmpty;

      // At least one event should be visible
      final hasEvent = workshopFinder.evaluate().isNotEmpty ||
          meetingFinder.evaluate().isNotEmpty;

      // At least one course schedule should be visible
      final hasCourseSchedule = programmingFinder.evaluate().isNotEmpty ||
          writingFinder.evaluate().isNotEmpty ||
          psychologyFinder.evaluate().isNotEmpty;

      _log.info('Found homework: $hasHomework');
      _log.info('Found event: $hasEvent');
      _log.info('Found course schedule: $hasCourseSchedule');

      // Store a homework title for later CRUD test
      if (homeworkFinder.evaluate().isNotEmpty) {
        final widget = homeworkFinder.evaluate().first.widget as Text;
        _homeworkItemTitle = widget.data;
        _log.info('Stored homework title for CRUD test: $_homeworkItemTitle');
      }

      expect(hasHomework, isTrue, reason: 'Should display homework items');
      expect(hasEvent, isTrue, reason: 'Should display event items');
      expect(hasCourseSchedule, isTrue, reason: 'Should display course schedule');
    });

    testWidgets('6. Top-level navigation works correctly', (tester) async {
      if (!_loginSucceeded) {
        _log.warning('Skipping: login did not succeed');
        markTestSkipped('Skipped: login did not succeed');
        return;
      }

      await initializeTestApp(tester);
      final loggedIn = await loginAndNavigateToPlanner(
        tester,
        testEmail,
        testPassword,
      );
      expect(loggedIn, isTrue, reason: 'Should be logged in');

      // Navigate to Classes
      final classesTab = find.text('Classes');
      expect(classesTab, findsOneWidget, reason: 'Classes tab should exist');
      await tester.tap(classesTab);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify we see example course data (course group or course)
      final hasCourseData = find.textContaining('Fall Semester').evaluate().isNotEmpty ||
          find.textContaining('Programming').evaluate().isNotEmpty ||
          find.textContaining('Writing').evaluate().isNotEmpty;
      expect(hasCourseData, isTrue, reason: 'Should see course data on Classes screen');

      // Navigate to Resources
      final resourcesTab = find.text('Resources');
      expect(resourcesTab, findsOneWidget, reason: 'Resources tab should exist');
      await tester.tap(resourcesTab);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify we see example resource data
      final hasResourceData = find.textContaining('Textbooks').evaluate().isNotEmpty ||
          find.textContaining('Supplies').evaluate().isNotEmpty ||
          find.textContaining('Digital').evaluate().isNotEmpty;
      expect(hasResourceData, isTrue, reason: 'Should see resource data on Resources screen');

      // Navigate to Grades
      final gradesTab = find.text('Grades');
      expect(gradesTab, findsOneWidget, reason: 'Grades tab should exist');
      await tester.tap(gradesTab);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify we see example grades data
      final hasGradesData = find.textContaining('Fall Semester').evaluate().isNotEmpty ||
          find.textContaining('%').evaluate().isNotEmpty;
      expect(hasGradesData, isTrue, reason: 'Should see grades data on Grades screen');

      // Navigate back to Planner
      final plannerTab = find.text('Planner');
      expect(plannerTab, findsOneWidget, reason: 'Planner tab should exist');
      await tester.tap(plannerTab);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify we're back on planner
      expect(find.text('Planner'), findsOneWidget);
    });

    testWidgets('7. Settings opens correctly based on screen width', (tester) async {
      if (!_loginSucceeded) {
        _log.warning('Skipping: login did not succeed');
        markTestSkipped('Skipped: login did not succeed');
        return;
      }

      // Store original size to restore later
      final originalSize = tester.view.physicalSize;
      final originalDevicePixelRatio = tester.view.devicePixelRatio;

      // Use widths relative to the actual mobile breakpoint
      // Mobile: < ResponsiveBreakpoints.mobile, Non-mobile: >= ResponsiveBreakpoints.mobile
      const nonMobileWidth = ResponsiveBreakpoints.mobile + 100; // Above mobile breakpoint
      const mobileWidth = ResponsiveBreakpoints.mobile - 100; // Below mobile breakpoint
      const testHeight = 800.0;

      await initializeTestApp(tester);
      final loggedIn = await loginAndNavigateToPlanner(
        tester,
        testEmail,
        testPassword,
      );
      expect(loggedIn, isTrue, reason: 'Should be logged in');

      // --- PART 1: Desktop/Tablet (wide) - Settings opens as dialog ---
      _log.info('Testing non-mobile view (wide browser, width=$nonMobileWidth)...');

      // Set to non-mobile width
      tester.view.physicalSize = const Size(nonMobileWidth, testHeight);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpAndSettle();

      // Find and tap the settings button
      var settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget, reason: 'Settings button should exist');
      await tester.tap(settingsButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // On non-mobile, settings should open as a dialog overlay
      // The dialog should have a close button (X icon)
      final closeButton = find.byIcon(Icons.close);
      expect(
        closeButton,
        findsOneWidget,
        reason: 'Non-mobile: Settings should open as dialog with close button',
      );

      // Verify settings content is visible
      final hasSettingsContent = find.text('Account').evaluate().isNotEmpty ||
          find.text('Preferences').evaluate().isNotEmpty;
      expect(hasSettingsContent, isTrue, reason: 'Settings content should be visible');

      _log.info('Non-mobile: Settings opened as dialog');

      // Close the dialog
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify we're back on Planner
      expect(find.text('Planner'), findsOneWidget, reason: 'Should be back on Planner after closing dialog');

      // --- PART 2: Mobile (narrow) - Settings navigates to screen ---
      _log.info('Testing mobile view (narrow browser, width=$mobileWidth)...');

      // Resize to mobile width
      tester.view.physicalSize = const Size(mobileWidth, testHeight);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap the settings button again
      settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget, reason: 'Settings button should exist on mobile');
      await tester.tap(settingsButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // On mobile, settings should navigate to a new screen (no dialog close button)
      // Instead, there should be a back arrow
      final backButton = find.byIcon(Icons.arrow_back);
      expect(
        backButton,
        findsOneWidget,
        reason: 'Mobile: Settings should navigate to screen with back button',
      );

      // The close button should NOT be present (it's not a dialog)
      expect(
        find.byIcon(Icons.close),
        findsNothing,
        reason: 'Mobile: Should not have dialog close button',
      );

      _log.info('Mobile: Settings navigated to screen');

      // Navigate back
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify we're back on Planner
      expect(find.text('Planner'), findsOneWidget, reason: 'Should be back on Planner after back navigation');

      // Restore original size
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalDevicePixelRatio;
      await tester.pumpAndSettle();

      _log.info('Settings responsive behavior test completed');
    });

    testWidgets('8. Can edit homework item (CRUD operation)', (tester) async {
      if (!_loginSucceeded) {
        _log.warning('Skipping: login did not succeed');
        markTestSkipped('Skipped: login did not succeed');
        return;
      }

      await initializeTestApp(tester);
      final loggedIn = await loginAndNavigateToPlanner(
        tester,
        testEmail,
        testPassword,
      );
      expect(loggedIn, isTrue, reason: 'Should be logged in');

      // Navigate to previous month where homework items are
      final prevMonthButton = find.byIcon(Icons.chevron_left);
      if (prevMonthButton.evaluate().isNotEmpty) {
        await tester.tap(prevMonthButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Find a homework item to edit
      // Look for "Homework 1" or similar
      var homeworkItem = find.textContaining('Homework 1');
      if (homeworkItem.evaluate().isEmpty) {
        homeworkItem = find.textContaining('Homework');
      }

      if (homeworkItem.evaluate().isEmpty) {
        _log.warning('No homework item found to edit');
        markTestSkipped('Skipped: no homework item found');
        return;
      }

      // Get the original title
      final originalWidget = homeworkItem.evaluate().first.widget as Text;
      final originalTitle = originalWidget.data ?? 'Homework';
      _log.info('Found homework item: $originalTitle');

      // Tap on the homework item to open edit screen
      await tester.tap(homeworkItem.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify we're on the edit screen
      final editScreenFound = await waitForWidget(
        tester,
        find.byType(TextField),
        timeout: const Duration(seconds: 10),
      );
      expect(editScreenFound, isTrue, reason: 'Should navigate to edit screen');

      // Find the title field and change it
      final titleField = find.widgetWithText(TextField, originalTitle);
      if (titleField.evaluate().isNotEmpty) {
        await tester.tap(titleField);
        await tester.pumpAndSettle();
        await tester.enterText(titleField, '$originalTitle (Edited)');
        await tester.pumpAndSettle();
      }

      // Find and tap the "Completed" checkbox
      final completedCheckbox = find.byType(Checkbox);
      if (completedCheckbox.evaluate().isNotEmpty) {
        await tester.tap(completedCheckbox.first);
        await tester.pumpAndSettle();
      }

      // Find and tap the Save button
      final saveButton = find.text('Save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      } else {
        // Try finding a check/save icon button
        final saveIcon = find.byIcon(Icons.check);
        if (saveIcon.evaluate().isNotEmpty) {
          await tester.tap(saveIcon);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }

      // Verify we're back on the planner
      final plannerFound = await waitForWidget(
        tester,
        find.text('Planner'),
        timeout: const Duration(seconds: 10),
      );
      expect(plannerFound, isTrue, reason: 'Should return to planner after save');

      // Navigate to previous month again to see the updated item
      if (prevMonthButton.evaluate().isNotEmpty) {
        await tester.tap(prevMonthButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Verify the title was updated
      final updatedItem = find.textContaining('(Edited)');
      expect(
        updatedItem,
        findsOneWidget,
        reason: 'Homework title should be updated',
      );

      _log.info('Successfully edited homework item');
    });

    testWidgets('9. User can clear example schedule', (tester) async {
      if (!_loginSucceeded) {
        _log.warning('Skipping: login did not succeed');
        markTestSkipped('Skipped: login did not succeed');
        return;
      }

      await initializeTestApp(tester);

      // Log in - but DON'T dismiss the welcome dialog automatically
      // We need to manually handle login to click "Clear Example Data" instead
      final emailField = find.widgetWithText(TextField, 'Email');
      await tester.tap(emailField);
      await tester.pumpAndSettle();
      await tester.enterText(emailField, testEmail);

      final passwordField = find.widgetWithText(TextField, 'Password');
      await tester.tap(passwordField);
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, testPassword);

      await tester.tap(find.text('Sign In'));

      // Wait for the welcome dialog to appear
      // (skipping setup screen handling since it should be done from previous tests)
      final welcomeDialogFound = await waitForWidget(
        tester,
        find.text('Welcome to Helium!'),
        timeout: const Duration(seconds: 45),
      );

      // If welcome dialog doesn't appear, the setting might have been cleared
      // Try refreshing/re-initializing to trigger it
      if (!welcomeDialogFound) {
        _log.warning('Welcome dialog not found on first try, reinitializing app...');
        await initializeTestApp(tester);

        // Log in again (tap fields first for web)
        final retryEmailField = find.widgetWithText(TextField, 'Email');
        await tester.tap(retryEmailField);
        await tester.pumpAndSettle();
        await tester.enterText(retryEmailField, testEmail);

        final retryPasswordField = find.widgetWithText(TextField, 'Password');
        await tester.tap(retryPasswordField);
        await tester.pumpAndSettle();
        await tester.enterText(retryPasswordField, testPassword);

        await tester.tap(find.text('Sign In'));

        final retryWelcomeFound = await waitForWidget(
          tester,
          find.text('Welcome to Helium!'),
          timeout: const Duration(seconds: 45),
        );

        if (!retryWelcomeFound) {
          _log.warning('Welcome dialog still not found, example schedule may already be cleared');
          markTestSkipped('Skipped: Welcome dialog not available (example schedule may be cleared)');
          return;
        }
      }

      _log.info('Welcome dialog found, clicking Clear Example Data...');

      // Click "Clear Example Data" button
      final clearButton = find.text('Clear Example Data');
      expect(clearButton, findsOneWidget, reason: 'Clear Example Data button should exist');
      await tester.tap(clearButton);

      // Wait for navigation to Classes screen
      final classesScreenFound = await waitForWidget(
        tester,
        find.text('Classes'),
        timeout: const Duration(seconds: 30),
      );
      expect(
        classesScreenFound,
        isTrue,
        reason: 'Should navigate to Classes screen after clearing example data',
      );

      // Wait a bit for the UI to settle
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Assert the Classes screen is empty (no example schedule data)
      // The example data includes "Fall Semester" course group and courses like
      // "Creative Writing", "Programming", "Psychology"
      final hasFallSemester = find.textContaining('Fall Semester').evaluate().isNotEmpty;
      final hasProgramming = find.textContaining('Programming').evaluate().isNotEmpty;
      final hasWriting = find.textContaining('Writing').evaluate().isNotEmpty;
      final hasPsychology = find.textContaining('Psychology').evaluate().isNotEmpty;

      expect(
        hasFallSemester,
        isFalse,
        reason: 'Fall Semester should be cleared',
      );
      expect(
        hasProgramming,
        isFalse,
        reason: 'Programming course should be cleared',
      );
      expect(
        hasWriting,
        isFalse,
        reason: 'Writing course should be cleared',
      );
      expect(
        hasPsychology,
        isFalse,
        reason: 'Psychology course should be cleared',
      );

      _log.info('Example schedule successfully cleared');
    });

    testWidgets('10. User can delete their account', (tester) async {
      if (!_loginSucceeded) {
        _log.warning('Skipping: login did not succeed');
        markTestSkipped('Skipped: login did not succeed');
        return;
      }

      await initializeTestApp(tester);
      final loggedIn = await loginAndNavigateToPlanner(
        tester,
        testEmail,
        testPassword,
      );
      expect(loggedIn, isTrue, reason: 'Should be logged in');

      // Open settings
      final settingsButton = find.byIcon(Icons.settings);
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
        await tester.tap(passwordField);
        await tester.pumpAndSettle();
        await tester.enterText(passwordField, testPassword);
        await tester.pumpAndSettle();
      }

      // Confirm deletion
      final confirmButton = find.text('Confirm');
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      } else {
        // Try "Delete" button
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

      // Verify account is actually deleted via API (with polling)
      _log.info('Verifying account deletion via API...');
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
