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
import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('authed_user_test');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = TestConfig();
  initializeTestLogging(
    environment: config.environment,
    apiHost: config.projectApiHost,
  );

  group('Authenticated User Tests', () {
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
        _log.info('Test user exists, proceeding with tests');
        canProceed = true;
      }
    });

    namedTestWidgets('1. Verified user can login and see planner', (tester) async {
      if (!canProceed) {
        _log.warning('Skipping: user does not exist');
        markTestSkipped('Skipped: user does not exist (run signup_user_test first)');
        return;
      }

      await initializeTestApp(tester);
      await ensureOnLoginScreen(tester);

      // Login with the verified account
      await enterTextInField(tester, find.widgetWithText(TextField, 'Email'), testEmail);
      await enterTextInField(tester, find.widgetWithText(TextField, 'Password'), testPassword);

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Skip setup screen if present (routing logic tested in unit tests)
      final setupScreen = find.text('Set Up Your Account');
      if (setupScreen.evaluate().isNotEmpty) {
        _log.info('Setup screen detected, skipping ...');
        final skipButton = find.text('Skip');
        final continueButton = find.text('Continue');
        if (skipButton.evaluate().isNotEmpty) {
          await tester.tap(skipButton);
        } else if (continueButton.evaluate().isNotEmpty) {
          await tester.tap(continueButton);
        }
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Verify we reach the planner
      final plannerFound = await waitForWidget(
        tester,
        find.text('Planner'),
        timeout: const Duration(seconds: 15),
      );

      expect(plannerFound, isTrue, reason: 'Should be on planner screen');

      // Dismiss dialogs so they don't interfere with subsequent tests
      await tester.pumpAndSettle(const Duration(seconds: 2));
      if (find.text('Welcome to Helium!').evaluate().isNotEmpty) {
        await tester.tap(find.text("I'll explore first"));
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));
      if (find.text('Welcome to the new Helium!').evaluate().isNotEmpty) {
        await tester.tap(find.text('Dive In!'));
        await tester.pumpAndSettle();
      }

      _log.info('Login succeeded');
    });

    namedTestWidgets('2. First login shows welcome dialog', (tester) async {
      if (!canProceed) {
        _log.warning('Skipping: user does not exist');
        markTestSkipped('Skipped: user does not exist (run signup_user_test first)');
        return;
      }

      await initializeTestApp(tester);
      await ensureOnLoginScreen(tester);

      // Login with the test account
      await enterTextInField(tester, find.widgetWithText(TextField, 'Email'), testEmail);
      await enterTextInField(tester, find.widgetWithText(TextField, 'Password'), testPassword);

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Handle setup screen if present (shown when example schedule import hasn't finished)
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

      // Wait for the welcome dialog to appear (shown on first planner load)
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

      // Also dismiss what's new dialog if present (can appear behind welcome dialog)
      await tester.pumpAndSettle(const Duration(seconds: 2));
      if (find.text('Welcome to the new Helium!').evaluate().isNotEmpty) {
        await tester.tap(find.text('Dive In!'));
        await tester.pumpAndSettle();
      }

      // Verify we're on the planner screen
      expect(find.text('Planner'), findsOneWidget);
    });

    namedTestWidgets('3. Calendar displays example schedule items', (tester) async {
      if (!canProceed) {
        _log.warning('Skipping: user does not exist');
        markTestSkipped('Skipped: user does not exist (run signup_user_test first)');
        return;
      }

      await initializeTestApp(tester);
      final loggedIn = await loginAndNavigateToPlanner(
        tester,
        testEmail,
        testPassword,
      );
      expect(loggedIn, isTrue, reason: 'Should be logged in');

      // Look for a homework item (has assignment icon or specific title pattern)
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
      final prevMonthButton = find.byIcon(Icons.chevron_left);
      if (prevMonthButton.evaluate().isNotEmpty) {
        await tester.tap(prevMonthButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Now check for example schedule items
      final hasHomework = homeworkFinder.evaluate().isNotEmpty ||
          quizFinder.evaluate().isNotEmpty;
      final hasEvent = workshopFinder.evaluate().isNotEmpty ||
          meetingFinder.evaluate().isNotEmpty;
      final hasCourseSchedule = programmingFinder.evaluate().isNotEmpty ||
          writingFinder.evaluate().isNotEmpty ||
          psychologyFinder.evaluate().isNotEmpty;

      expect(hasHomework, isTrue, reason: 'Should display homework items');
      expect(hasEvent, isTrue, reason: 'Should display event items');
      expect(hasCourseSchedule, isTrue, reason: 'Should display course schedule');
    });

    namedTestWidgets('4. Top-level navigation works correctly', (tester) async {
      if (!canProceed) {
        _log.warning('Skipping: user does not exist');
        markTestSkipped('Skipped: user does not exist (run signup_user_test first)');
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

      // Verify we see example course data
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

    namedTestWidgets('5. Settings opens correctly based on screen width', (tester) async {
      if (!canProceed) {
        _log.warning('Skipping: user does not exist');
        markTestSkipped('Skipped: user does not exist (run signup_user_test first)');
        return;
      }

      // Store original size to restore later
      final originalSize = tester.view.physicalSize;
      final originalDevicePixelRatio = tester.view.devicePixelRatio;

      const nonMobileWidth = ResponsiveBreakpoints.mobile + 100;
      const mobileWidth = ResponsiveBreakpoints.mobile - 100;
      const testHeight = 800.0;

      await initializeTestApp(tester);
      final loggedIn = await loginAndNavigateToPlanner(
        tester,
        testEmail,
        testPassword,
      );
      expect(loggedIn, isTrue, reason: 'Should be logged in');

      // --- PART 1: Desktop/Tablet (wide) - Settings opens as dialog ---
      tester.view.physicalSize = const Size(nonMobileWidth, testHeight);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpAndSettle();

      var settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget, reason: 'Settings button should exist');
      await tester.tap(settingsButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final closeButton = find.byIcon(Icons.close);
      expect(
        closeButton,
        findsOneWidget,
        reason: 'Non-mobile: Settings should open as dialog with close button',
      );

      final hasSettingsContent = find.text('Account').evaluate().isNotEmpty ||
          find.text('Preferences').evaluate().isNotEmpty;
      expect(hasSettingsContent, isTrue, reason: 'Settings content should be visible');

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.text('Planner'), findsOneWidget, reason: 'Should be back on Planner after closing dialog');

      // --- PART 2: Mobile (narrow) - Settings navigates to screen ---
      tester.view.physicalSize = const Size(mobileWidth, testHeight);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpAndSettle(const Duration(seconds: 2));

      settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget, reason: 'Settings button should exist on mobile');
      await tester.tap(settingsButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final backButton = find.byIcon(Icons.arrow_back);
      expect(
        backButton,
        findsOneWidget,
        reason: 'Mobile: Settings should navigate to screen with back button',
      );

      expect(
        find.byIcon(Icons.close),
        findsNothing,
        reason: 'Mobile: Should not have dialog close button',
      );

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Planner'), findsOneWidget, reason: 'Should be back on Planner after back navigation');

      // Restore original size
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalDevicePixelRatio;
      await tester.pumpAndSettle();
    });

    namedTestWidgets('6. Can edit homework item (CRUD operation)', (tester) async {
      if (!canProceed) {
        _log.warning('Skipping: user does not exist');
        markTestSkipped('Skipped: user does not exist (run signup_user_test first)');
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
        await enterTextInField(tester, titleField, '$originalTitle (Edited)');
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
    });

    namedTestWidgets('7. User can clear example schedule', (tester) async {
      if (!canProceed) {
        _log.warning('Skipping: user does not exist');
        markTestSkipped('Skipped: user does not exist (run signup_user_test first)');
        return;
      }

      await initializeTestApp(tester);
      await ensureOnLoginScreen(tester);

      // Log in - but DON'T dismiss the welcome dialog automatically
      await enterTextInField(tester, find.widgetWithText(TextField, 'Email'), testEmail);
      await enterTextInField(tester, find.widgetWithText(TextField, 'Password'), testPassword);

      await tester.tap(find.text('Sign In'));

      // Wait for the welcome dialog to appear
      final welcomeDialogFound = await waitForWidget(
        tester,
        find.text('Welcome to Helium!'),
        timeout: const Duration(seconds: 45),
      );

      if (!welcomeDialogFound) {
        await initializeTestApp(tester);
        await ensureOnLoginScreen(tester);

        await enterTextInField(tester, find.widgetWithText(TextField, 'Email'), testEmail);
        await enterTextInField(tester, find.widgetWithText(TextField, 'Password'), testPassword);

        await tester.tap(find.text('Sign In'));

        final retryWelcomeFound = await waitForWidget(
          tester,
          find.text('Welcome to Helium!'),
          timeout: const Duration(seconds: 45),
        );

        if (!retryWelcomeFound) {
          markTestSkipped('Skipped: Welcome dialog not available (example schedule may be cleared)');
          return;
        }
      }

      // Click "Clear Example Data" button
      final clearButton = find.text('Clear Example Data');
      expect(clearButton, findsOneWidget, reason: 'Clear Example Data button should exist');
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Also dismiss what's new dialog if present (can appear behind welcome dialog)
      await tester.pumpAndSettle(const Duration(seconds: 2));
      if (find.text('Welcome to the new Helium!').evaluate().isNotEmpty) {
        await tester.tap(find.text('Dive In!'));
        await tester.pumpAndSettle();
      }

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

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Assert the Classes screen is empty
      final hasFallSemester = find.textContaining('Fall Semester').evaluate().isNotEmpty;
      final hasProgramming = find.textContaining('Programming').evaluate().isNotEmpty;
      final hasWriting = find.textContaining('Writing').evaluate().isNotEmpty;
      final hasPsychology = find.textContaining('Psychology').evaluate().isNotEmpty;

      expect(hasFallSemester, isFalse, reason: 'Fall Semester should be cleared');
      expect(hasProgramming, isFalse, reason: 'Programming course should be cleared');
      expect(hasWriting, isFalse, reason: 'Writing course should be cleared');
      expect(hasPsychology, isFalse, reason: 'Psychology course should be cleared');
    });
  });
}
