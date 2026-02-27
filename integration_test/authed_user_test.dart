// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
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
      await startSuite('Authenticated User Tests');
      _log.info('Test email: $testEmail');

      final userExists = await apiHelper.userExists(testEmail);
      if (!userExists) {
        _log.warning('Test user does not exist. Run signup_user_test first.');
        canProceed = false;
      } else {
        _log.info('Test user exists, proceeding with tests');
        canProceed = true;
      }
    });

    tearDownAll(() async {
      await endSuite();
    });

    // namedTestWidgets('1. Top-level navigation works correctly', (tester) async {
    //   if (!canProceed) {
    //     _log.warning('Skipping: user does not exist');
    //     skipTest('user does not exist (run signup_user_test first)');
    //     return;
    //   }
    //
    //   await initializeTestApp(tester);
    //   final loggedIn = await loginAndNavigateToPlanner(
    //     tester,
    //     testEmail,
    //     testPassword,
    //   );
    //   expect(loggedIn, isTrue, reason: 'Should be logged in');
    //
    //   final classesTab = find.text('Classes');
    //   expect(classesTab, findsOneWidget, reason: 'Classes tab should exist');
    //   await tester.tap(classesTab);
    //   await tester.pumpAndSettle(const Duration(seconds: 3));
    //
    //   expectOnClassesScreen();
    //   _log.info('Successfully navigated to classes');
    //
    //   final resourcesTab = find.text('Resources');
    //   expect(
    //     resourcesTab,
    //     findsOneWidget,
    //     reason: 'Resources tab should exist',
    //   );
    //   await tester.tap(resourcesTab);
    //   await tester.pumpAndSettle(const Duration(seconds: 3));
    //
    //   expectOnResourcesScreen();
    //   _log.info('Successfully navigated to resources');
    //
    //   final gradesTab = find.text('Grades');
    //   expect(gradesTab, findsOneWidget, reason: 'Grades tab should exist');
    //   await tester.tap(gradesTab);
    //   await tester.pumpAndSettle(const Duration(seconds: 3));
    //
    //   expectOnGradesScreen();
    //   _log.info('Successfully navigated to grades');
    //
    //   final plannerTab = find.text('Planner');
    //   expect(plannerTab, findsOneWidget, reason: 'Planner tab should exist');
    //   await tester.tap(plannerTab);
    //   await tester.pumpAndSettle(const Duration(seconds: 3));
    //
    //   expectOnPlannerScreen();
    //   _log.info('Successfully navigated back to planner');
    // });
    //
    // namedTestWidgets('2. Calendar displays example schedule items', (
    //   tester,
    // ) async {
    //   if (!canProceed) {
    //     _log.warning('Skipping: user does not exist');
    //     skipTest('user does not exist (run signup_user_test first)');
    //     return;
    //   }
    //
    //   await initializeTestApp(tester);
    //   final loggedIn = await loginAndNavigateToPlanner(
    //     tester,
    //     testEmail,
    //     testPassword,
    //   );
    //   expect(loggedIn, isTrue, reason: 'Should be logged in');
    //
    //   final quizLoaded = await waitForWidget(
    //     tester,
    //     findRichTextContaining('Quiz 4'),
    //     timeout: const Duration(seconds: 15),
    //   );
    //   expect(quizLoaded, isTrue, reason: 'Quiz 4 should appear after loading');
    //
    //   expect(
    //     findRichTextContaining('Final Portfolio Writing Workshop'),
    //     findsOneWidget,
    //   );
    //   expect(
    //     findRichTextContaining('Intro to Psychology 🧠'),
    //     findsAtLeastNWidgets(12),
    //   );
    // });

    // namedTestWidgets('3. Settings opens correctly based on screen width', (
    //   tester,
    // ) async {
    //   if (!canProceed) {
    //     _log.warning('Skipping: user does not exist');
    //     skipTest('user does not exist (run signup_user_test first)');
    //     return;
    //   }
    //
    //   // Store original size to restore later
    //   final originalSize = tester.view.physicalSize;
    //   final originalDevicePixelRatio = tester.view.devicePixelRatio;
    //
    //   const nonMobileWidth = ResponsiveBreakpoints.mobile + 100;
    //   const mobileWidth = ResponsiveBreakpoints.mobile - 100;
    //   const testHeight = 800.0;
    //
    //   try {
    //     await initializeTestApp(tester);
    //     final loggedIn = await loginAndNavigateToPlanner(
    //       tester,
    //       testEmail,
    //       testPassword,
    //     );
    //     expect(loggedIn, isTrue, reason: 'Should be logged in');
    //
    //     // --- PART 1: Desktop/Tablet (wide) - Settings opens as dialog ---
    //     tester.view.physicalSize = const Size(nonMobileWidth, testHeight);
    //     tester.view.devicePixelRatio = 1.0;
    //     await tester.pumpAndSettle();
    //
    //     // 1. Click settings, wait for dialog to be shown
    //     _log.info('Opening settings dialog on desktop ...');
    //     var settingsButton = find.byIcon(Icons.settings_outlined);
    //     expect(settingsButton, findsOneWidget, reason: 'Settings button should exist');
    //     await tester.tap(settingsButton);
    //
    //     // Wait for close button to appear (dialog is open)
    //     final closeButton = find.byIcon(Icons.close);
    //     final dialogOpened = await waitForWidget(
    //       tester,
    //       closeButton,
    //       timeout: const Duration(seconds: 5),
    //     );
    //     expect(dialogOpened, isTrue, reason: 'Settings dialog should open');
    //
    //     // Verify browser title did NOT change (dialog mode)
    //     expectBrowserTitle('Planner');
    //     expectOnSettingsScreen(isDialog: true);
    //     _log.info('Settings dialog opened, browser title still Planner');
    //
    //     // 2. Click close button, wait until dialog is definitely closed
    //     await tester.tap(closeButton);
    //     final dialogClosed = await waitForWidgetToDisappear(
    //       tester,
    //       closeButton,
    //       timeout: const Duration(seconds: 5),
    //     );
    //     expect(dialogClosed, isTrue, reason: 'Settings dialog should close');
    //     _log.info('Settings dialog closed');
    //
    //     // 3. Assert that "Quiz 4" can be seen on desktop calendar
    //     expect(
    //       findRichTextContaining('Quiz 4'),
    //       findsWidgets,
    //       reason: 'Quiz 4 should be visible on desktop calendar',
    //     );
    //     _log.info('Quiz 4 visible on desktop');
    //
    //     // --- PART 2: Mobile (narrow) - Settings navigates to screen ---
    //     // 4. Resize screen to mobile
    //     _log.info('Resizing to mobile width ...');
    //     tester.view.physicalSize = const Size(mobileWidth, testHeight);
    //     tester.view.devicePixelRatio = 1.0;
    //     await tester.pumpAndSettle(const Duration(seconds: 2));
    //
    //     // 5. Assert that "Quiz 4" is no longer shown (calendar items shown as dots on mobile)
    //     expect(
    //       findRichTextContaining('Quiz 4'),
    //       findsNothing,
    //       reason: 'Quiz 4 should not be visible on mobile (shown as dots)',
    //     );
    //     _log.info('Quiz 4 not visible on mobile (as expected)');
    //
    //     // 6. Click settings, wait until new screen is shown (browser title should update)
    //     _log.info('Opening settings screen on mobile ...');
    //     settingsButton = find.byIcon(Icons.settings_outlined);
    //     expect(settingsButton, findsOneWidget, reason: 'Settings button should exist on mobile');
    //     await tester.tap(settingsButton);
    //
    //     // Wait for back button to appear (screen navigation complete)
    //     final backButton = find.byIcon(Icons.keyboard_arrow_left);
    //     final screenOpened = await waitForWidget(
    //       tester,
    //       backButton,
    //       timeout: const Duration(seconds: 5),
    //     );
    //     expect(screenOpened, isTrue, reason: 'Settings screen should open');
    //
    //     // Verify browser title changed to Settings (screen mode)
    //     expectBrowserTitle('Settings');
    //     expectOnSettingsScreen(isDialog: false);
    //     expect(find.byIcon(Icons.close), findsNothing, reason: 'Should not have dialog close button');
    //     _log.info('Settings screen opened, browser title is Settings');
    //
    //     // 7. Click back button, wait until we're back on the Planner screen
    //     await tester.tap(backButton);
    //     final backToPlanner = await waitForWidgetToDisappear(
    //       tester,
    //       backButton,
    //       timeout: const Duration(seconds: 5),
    //     );
    //     expect(backToPlanner, isTrue, reason: 'Should navigate back to Planner');
    //
    //     expectBrowserTitle('Planner');
    //     expectOnPlannerScreen(isMobile: true);
    //     _log.info('Back on Planner screen');
    //   } finally {
    //     // 8. Whether pass or fail, resize screen back to desktop size
    //     tester.view.physicalSize = originalSize;
    //     tester.view.devicePixelRatio = originalDevicePixelRatio;
    //     await tester.pumpAndSettle();
    //   }
    // });

    namedTestWidgets('4. Todos view filtering and checkbox toggle', (
      tester,
    ) async {
      if (!canProceed) {
        _log.warning('Skipping: user does not exist');
        skipTest('user does not exist (run signup_user_test first)');
        return;
      }

      // Ensure Homework 1 is marked completed (in case previous run failed)
      final homework1Setup = await apiHelper.findHomeworkByTitle('Homework 1');
      if (homework1Setup != null && !homework1Setup.completed) {
        _log.info('Resetting Homework 1 to completed state ...');
        final courseId = homework1Setup.course.id;
        final courses = await apiHelper.getCourses();
        final course = courses!.firstWhere((c) => c.id == courseId);
        await apiHelper.updateHomework(
          groupId: course.courseGroup,
          courseId: courseId,
          homeworkId: homework1Setup.id,
          request: HomeworkRequestModel(course: courseId, completed: true),
        );
      }

      await initializeTestApp(tester);
      final loggedIn = await loginAndNavigateToPlanner(
        tester,
        testEmail,
        testPassword,
      );
      expect(loggedIn, isTrue, reason: 'Should be logged in');

      // 1. Click "Change view" menu and switch to "Todos"
      _log.info('Switching to "Todos" view ...');
      final viewButton = find.byTooltip('Change view');
      expect(
        viewButton,
        findsOneWidget,
        reason: 'View button (Change view tooltip) should exist',
      );
      await tester.tap(viewButton);

      // Wait for menu to open
      final todosOption = find.text('Todos');
      final menuOpened = await waitForWidget(
        tester,
        todosOption,
        timeout: const Duration(seconds: 5),
      );
      expect(menuOpened, isTrue, reason: 'Todos option should be in view menu');
      await tester.tap(todosOption);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 2. Assert "Showing X to Y of 53" is shown (X and Y may vary, 53 is fixed)
      final showingTextFinder = find.textContaining(
        RegExp(r'Showing \d+ to \d+ of 53'),
      );
      expect(
        showingTextFinder,
        findsOneWidget,
        reason: 'Should show "Showing X to Y of 53"',
      );

      // 3. Tap filters, tap checkbox next to "Fundamentals"
      _log.info('Opening filter menu ...');
      final filterButton = find.byIcon(Icons.filter_alt);
      await tester.tap(filterButton);

      // Wait for filter menu to open (look for CheckboxListTile)
      final checkboxListTiles = find.byType(CheckboxListTile);
      final filterMenuOpened = await waitForWidget(
        tester,
        checkboxListTiles,
        timeout: const Duration(seconds: 5),
      );
      expect(filterMenuOpened, isTrue, reason: 'Filter menu should open');

      // In Todos view, the TYPES section should be hidden
      expect(
        find.ancestor(
          of: find.text('Assignments'),
          matching: find.byType(CheckboxListTile),
        ),
        findsNothing,
        reason: 'TYPES filters should be hidden in Todos view',
      );
      expect(
        find.ancestor(
          of: find.text('Events'),
          matching: find.byType(CheckboxListTile),
        ),
        findsNothing,
        reason: 'TYPES filters should be hidden in Todos view',
      );
      expect(
        find.ancestor(
          of: find.text('Class Schedules'),
          matching: find.byType(CheckboxListTile),
        ),
        findsNothing,
        reason: 'TYPES filters should be hidden in Todos view',
      );
      expect(
        find.ancestor(
          of: find.text('External Calendars'),
          matching: find.byType(CheckboxListTile),
        ),
        findsNothing,
        reason: 'TYPES filters should be hidden in Todos view',
      );

      // Find the CheckboxListTile containing "Fundamentals"
      final fundamentalsCheckbox = find.ancestor(
        of: find.textContaining('Fundamentals'),
        matching: find.byType(CheckboxListTile),
      );
      expect(
        fundamentalsCheckbox,
        findsOneWidget,
        reason: 'Fundamentals checkbox should be in filter menu',
      );
      await tester.tap(fundamentalsCheckbox);
      await tester.pumpAndSettle();

      // 3.1 Assert footer shows "Showing 1 to 10 of 20"
      expect(
        find.text('Showing 1 to 10 of 20'),
        findsOneWidget,
        reason:
            'After Fundamentals filter: should show "Showing 1 to 10 of 20"',
      );

      // 4. Still in filters, tap CheckboxListTile next to "Homework" category
      final homeworkCheckbox = find.ancestor(
        of: find.textContaining('Homework'),
        matching: find.byType(CheckboxListTile),
      );
      expect(
        homeworkCheckbox,
        findsOneWidget,
        reason: 'Homework category should be in filters',
      );
      await tester.tap(homeworkCheckbox);
      await tester.pumpAndSettle();

      // 4.1 Assert footer shows "Showing 1 to 7 of 7"
      expect(
        find.text('Showing 1 to 7 of 7'),
        findsOneWidget,
        reason: 'After Homework filter: should show "Showing 1 to 7 of 7"',
      );

      // 5. Close filters menu (tap outside), then tap search icon and enter "1"
      // Tap outside the filter menu to close it
      _log.info('Closing filter menu ...');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      _log.info('Opening search field ...');
      final searchButton = find.byIcon(Icons.search);
      await tester.tap(searchButton.first);

      // Wait for search field to appear (animation)
      final searchField = find.byType(TextField);
      final searchFieldAppeared = await waitForWidget(
        tester,
        searchField,
        timeout: const Duration(seconds: 5),
      );
      expect(searchFieldAppeared, isTrue, reason: 'Search field should appear');

      _log.info('Entering search term "1" ...');
      await enterTextInField(tester, searchField.last, '1');
      // Unfocus field to trigger search (search applies on focus loss or timer)
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 5.1 Assert footer shows "Showing 1 to 1 of 1"
      final showingText = find.text('Showing 1 to 1 of 1');
      final searchResultsShown = await waitForWidget(
        tester,
        showingText,
        timeout: const Duration(seconds: 5),
      );
      expect(
        searchResultsShown,
        isTrue,
        reason: 'After search "1": should show "Showing 1 to 1 of 1"',
      );

      // 6. Assert the row shows "Homework 1" with strikethrough, time, class, and grade
      // TodosTable uses SelectableText for title and due date
      final homework1Finder = find.byWidgetPredicate(
        (w) =>
            w is SelectableText &&
            w.data == 'Homework 1' &&
            w.style?.decoration == TextDecoration.lineThrough,
      );
      // Wait for the row to render with strikethrough styling
      final homework1Appeared = await waitForWidget(
        tester,
        homework1Finder,
        timeout: const Duration(seconds: 5),
      );
      expect(
        homework1Appeared,
        isTrue,
        reason: 'Homework 1 should have strikethrough (completed)',
      );

      // Due date format is "EEE, MMM d • h:mm a" (e.g., "Fri, Oct 10 • 11 AM")
      // User timezone is set to America/Chicago during registration
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is SelectableText && (w.data?.contains('11 AM') ?? false),
        ),
        findsOneWidget,
        reason: 'Row should show due date with 11 AM (Chicago timezone)',
      );

      // Class uses CourseTitleLabel which contains text
      expect(
        find.textContaining('Fundamentals'),
        findsWidgets,
        reason: 'Row should show "Fundamentals" class',
      );

      // Grade uses GradeLabel widget
      expect(
        find.text('80.00%'),
        findsOneWidget,
        reason: 'Row should show grade "80.00%"',
      );

      // 7. Tap the checkbox at the start of the row to uncheck it
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget, reason: 'Row should have a checkbox');
      await tester.tap(checkbox);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 7.1 Assert checkbox is unchecked, "Homework 1" no longer has strikethrough, grade disappears
      // Find the non-strikethrough text (uncompleted item) - TodosTable uses SelectableText
      final homework1NoStrikethrough = find.byWidgetPredicate(
        (w) =>
            w is SelectableText &&
            w.data == 'Homework 1' &&
            (w.style?.decoration == null ||
                w.style?.decoration == TextDecoration.none),
      );
      expect(
        homework1NoStrikethrough,
        findsOneWidget,
        reason:
            'Homework 1 should no longer have strikethrough after unchecking',
      );

      // Grade should disappear when uncompleted
      expect(
        find.text('80.00%'),
        findsNothing,
        reason: 'Grade should disappear after unchecking',
      );

      // Verify the edit dialog did NOT open (we should still be on Todos view)
      expect(
        find.text('Edit Assignment'),
        findsNothing,
        reason: 'Edit dialog should NOT open when clicking checkbox',
      );

      // Verify the completed state change was persisted to the backend API
      _log.info('Verifying homework completion state via API ...');
      final homework = await apiHelper.findHomeworkByTitle('Homework 1');
      expect(
        homework,
        isNotNull,
        reason: 'Homework 1 should exist in API response',
      );
      expect(
        homework!.completed,
        isFalse,
        reason:
            'Homework 1 should be marked incomplete in API after unchecking',
      );
      // Grade should still be present even though completed is now false
      expect(
        homework.currentGrade,
        equals('40/50'),
        reason: 'Grade should still be 40/50 even after unchecking completed',
      );
      _log.info(
        'API verification successful: homework marked incomplete, grade preserved',
      );
    });

    namedTestWidgets('5. Can edit homework item (CRUD operation)', (
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

      // Find "Quiz 4" to edit (calendar uses RichText, not Text)
      final homeworkItem = findRichTextContaining('Quiz 4');
      expect(homeworkItem, findsWidgets, reason: 'Quiz 4 should exist');

      // Tap on the homework item to open edit screen
      await tester.tap(homeworkItem.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify we're on the edit screen and store reference to the dialog
      final editDialogTitle = find.text('Edit Assignment');
      final editScreenFound = await waitForWidget(
        tester,
        editDialogTitle,
        timeout: const Duration(seconds: 10),
      );
      expect(editScreenFound, isTrue, reason: 'Should navigate to edit screen');
      expect(
        editDialogTitle,
        findsOneWidget,
        reason: 'Edit screen: "Edit Assignment" title should be shown',
      );
      expectBrowserTitle('Planner');

      // 1. Change title to "Quiz 4 (Edited)"
      // TextField content is in EditableText, not Text, so use a custom finder
      final titleField = find.byWidgetPredicate((widget) {
        if (widget is! TextField) return false;
        return widget.controller?.text == 'Quiz 4';
      });
      expect(
        titleField,
        findsOneWidget,
        reason: 'Title field should show "Quiz 4"',
      );
      await enterTextInField(tester, titleField, 'Quiz 4 (Edited)');

      // 2. Change time to 2pm - tap on the time field to open time picker
      _log.info('Opening time picker to change time to 2pm ...');
      final timeFields = find.byIcon(Icons.access_time);
      if (timeFields.evaluate().isNotEmpty) {
        await tester.tap(timeFields.first);
        await tester.pumpAndSettle();

        // In the time picker, enter 2:00 PM
        // Clear and enter new time in the input field
        final hourField = find.byType(TextField);
        if (hourField.evaluate().isNotEmpty) {
          _log.info('Time picker opened, entering time ...');
          // Time picker input mode - enter the time
          await tester.enterText(hourField.first, '2');
          await tester.pumpAndSettle();
          // Find minute field and enter 00
          if (hourField.evaluate().length > 1) {
            await tester.enterText(hourField.at(1), '00');
            await tester.pumpAndSettle();
          }
          // Tap PM if needed and confirm
          final pmButton = find.text('PM');
          if (pmButton.evaluate().isNotEmpty) {
            await tester.tap(pmButton);
            await tester.pumpAndSettle();
          }
          final okButton = find.text('OK');
          if (okButton.evaluate().isNotEmpty) {
            await tester.tap(okButton);
            await tester.pumpAndSettle();
            _log.info('Time picker closed');
          }
        } else {
          _log.warning('Time picker did not show text fields');
        }
      } else {
        _log.warning('Time field icon not found');
      }

      // 3. Scroll down to find the completed checkbox
      final scrollable = find.byType(SingleChildScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -200));
        await tester.pumpAndSettle();
      }

      // 4. Toggle "Completed" checkbox (this will make the grade field appear)
      // Find checkboxes - we need the one that's not All Day or Show End
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets, reason: 'Checkboxes should exist');
      // Tap the last checkbox which should be Completed
      await tester.tap(checkboxes.last);
      await tester.pumpAndSettle();

      // 5. Set a grade (grade field appears when completed is checked)
      final gradeField = find.widgetWithText(TextField, 'Grade');
      if (gradeField.evaluate().isNotEmpty) {
        await enterTextInField(tester, gradeField, '95/100');
        await tester.pumpAndSettle();
      }

      // Find and tap the Save button
      _log.info('Saving homework changes ...');
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

      // Verify the edit dialog has closed
      final dialogClosed = await waitForWidgetToDisappear(
        tester,
        editDialogTitle,
        timeout: const Duration(seconds: 10),
      );
      expect(
        dialogClosed,
        isTrue,
        reason: 'Edit dialog should close after save',
      );
      expect(
        editDialogTitle,
        findsNothing,
        reason: 'Edit Assignment title should no longer be visible',
      );
      expectOnPlannerScreen();

      // Verify changes were persisted to the backend API
      _log.info('Verifying homework update via API ...');
      final editedHomework = await apiHelper.findHomeworkByTitle('(Edited)');
      expect(
        editedHomework,
        isNotNull,
        reason: 'Should find homework with "(Edited)" in title',
      );

      _log.info('Edited homework: ${editedHomework!.title}');

      // Verify all our changes
      expect(
        editedHomework.title,
        equals('Quiz 4 (Edited)'),
        reason: 'Title should be "Quiz 4 (Edited)"',
      );
      // Verify time was changed to 2pm local (model already has DateTime)
      final startTimeLocal = editedHomework.start.toLocal();
      expect(
        startTimeLocal.hour,
        equals(14),
        reason: 'Start time hour should be 14 (2pm local)',
      );
      expect(
        startTimeLocal.minute,
        equals(0),
        reason: 'Start time minute should be 0',
      );
      expect(
        editedHomework.completed,
        isTrue,
        reason: 'Completed should be true',
      );
      expect(
        editedHomework.currentGrade,
        equals('95/100'),
        reason: 'Grade should be "95/100"',
      );

      _log.info('API verification successful: all homework changes persisted');
    });

    // namedTestWidgets('6. User can clear example schedule', (tester) async {
    //   if (!canProceed) {
    //     _log.warning('Skipping: user does not exist');
    //     skipTest('user does not exist (run signup_user_test first)');
    //     return;
    //   }
    //
    //   await initializeTestApp(tester);
    //   await ensureOnLoginScreen(tester);
    //
    //   // Log in - but DON'T dismiss the welcome dialog automatically
    //   await enterTextInField(
    //     tester,
    //     find.widgetWithText(TextField, 'Email'),
    //     testEmail,
    //   );
    //   await enterTextInField(
    //     tester,
    //     find.widgetWithText(TextField, 'Password'),
    //     testPassword,
    //   );
    //
    //   await tester.tap(find.text('Sign In'));
    //
    //   // Wait for the welcome dialog to appear
    //   final welcomeDialogFound = await waitForWidget(
    //     tester,
    //     find.text('Welcome to Helium!'),
    //     timeout: const Duration(seconds: 45),
    //   );
    //
    //   if (!welcomeDialogFound) {
    //     await initializeTestApp(tester);
    //     await ensureOnLoginScreen(tester);
    //
    //     await enterTextInField(
    //       tester,
    //       find.widgetWithText(TextField, 'Email'),
    //       testEmail,
    //     );
    //     await enterTextInField(
    //       tester,
    //       find.widgetWithText(TextField, 'Password'),
    //       testPassword,
    //     );
    //
    //     await tester.tap(find.text('Sign In'));
    //
    //     final retryWelcomeFound = await waitForWidget(
    //       tester,
    //       find.text('Welcome to Helium!'),
    //       timeout: const Duration(seconds: 45),
    //     );
    //
    //     if (!retryWelcomeFound) {
    //       skipTest(
    //         'Welcome dialog not available (example schedule may be cleared)',
    //       );
    //       return;
    //     }
    //   }
    //
    //   // Click "Clear Example Data" button
    //   final clearButton = find.text('Clear Example Data');
    //   expect(
    //     clearButton,
    //     findsOneWidget,
    //     reason: 'Clear Example Data button should exist',
    //   );
    //
    //   _log.info('Clicking Clear Example Data button ...');
    //   await tester.tap(clearButton);
    //
    //   // The delete operation is async - give it time to process
    //   // pumpAndSettle may return before the API call completes
    //   await tester.pump(const Duration(seconds: 2));
    //   await tester.pumpAndSettle(const Duration(seconds: 5));
    //
    //   // Check for error snackbar (indicates API failure)
    //   final errorSnackbar = find.textContaining('Failed to delete');
    //   if (errorSnackbar.evaluate().isNotEmpty) {
    //     _log.warning('Delete example schedule failed - API error');
    //     skipTest('Delete example schedule API failed');
    //     return;
    //   }
    //
    //   // Wait for navigation to Classes screen
    //   _log.info('Waiting for navigation to Classes screen ...');
    //   final classesScreenFound = await waitForRoute(
    //     tester,
    //     AppRoute.coursesScreen,
    //     browserTitle: 'Classes',
    //     timeout: const Duration(seconds: 45),
    //   );
    //   expect(
    //     classesScreenFound,
    //     isTrue,
    //     reason: 'Should navigate to Classes screen after clearing example data',
    //   );
    //
    //   _log.info('Reached Classes screen, verifying example data was cleared');
    //   await tester.pumpAndSettle(const Duration(seconds: 3));
    //
    //   // Assert the Classes screen is empty
    //   final hasFallSemester = find
    //       .textContaining('Fall Semester')
    //       .evaluate()
    //       .isNotEmpty;
    //   final hasProgramming = find
    //       .textContaining('Programming')
    //       .evaluate()
    //       .isNotEmpty;
    //   final hasWriting = find.textContaining('Writing').evaluate().isNotEmpty;
    //   final hasPsychology = find
    //       .textContaining('Psychology')
    //       .evaluate()
    //       .isNotEmpty;
    //
    //   expect(
    //     hasFallSemester,
    //     isFalse,
    //     reason: 'Fall Semester should be cleared',
    //   );
    //   expect(
    //     hasProgramming,
    //     isFalse,
    //     reason: 'Programming course should be cleared',
    //   );
    //   expect(hasWriting, isFalse, reason: 'Writing course should be cleared');
    //   expect(
    //     hasPsychology,
    //     isFalse,
    //     reason: 'Psychology course should be cleared',
    //   );
    //
    //   _log.info('Example data successfully cleared');
    // });
  });
}
