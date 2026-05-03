// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/presentation/features/auth/controllers/credentials_form_controller.dart';
import 'package:heliumapp/presentation/features/auth/views/login_screen.dart';
import 'package:heliumapp/presentation/features/planner/controllers/planner_item_form_controller.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_screen.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell.dart';
import 'package:heliumapp/presentation/ui/components/settings_button.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';
import 'package:timezone/standalone.dart' as tz;

import 'helpers/api_helper.dart';
import 'helpers/planner_count_helper.dart';
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

      // Ensure Homework 1 is marked completed (in case previous run failed)
      final homework1Setup = await apiHelper.findHomeworkByTitle('Homework 1');
      if (homework1Setup != null && !homework1Setup.completed) {
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

      var quiz4Setup = await apiHelper.findHomeworkByTitle('Quiz 4 (Edited)');
      quiz4Setup ??= await apiHelper.findHomeworkByTitle('Quiz 4');
      if (quiz4Setup != null) {
        final courseId = quiz4Setup.course.id;
        final courses = await apiHelper.getCourses();
        final course = courses!.firstWhere((c) => c.id == courseId);

        final startUtc = DateTime.utc(
          quiz4Setup.start.year,
          quiz4Setup.start.month,
          quiz4Setup.start.day,
          18,
          0,
        );
        final endUtc = startUtc.add(const Duration(minutes: 30));

        await apiHelper.updateHomework(
          groupId: course.courseGroup,
          courseId: courseId,
          homeworkId: quiz4Setup.id,
          request: HomeworkRequestModel(
            course: courseId,
            title: 'Quiz 4',
            start: startUtc.toIso8601String(),
            end: endUtc.toIso8601String(),
            completed: false,
            currentGrade: '-1/100',
          ),
        );
      }
    });

    tearDownAll(() async {
      await endSuite();
    });

    namedTestWidgets('1. Top-level navigation works correctly', (tester) async {
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

      final classesTab = find.byKey(Key(NavigationPage.courses.navKeyName));
      expect(classesTab, findsOneWidget, reason: 'Classes tab should exist');
      await tester.tap(classesTab);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expectOnClassesScreen();
      _log.info('Successfully navigated to classes');

      final resourcesTab = find.byKey(
        Key(NavigationPage.resources.navKeyName),
      );
      expect(
        resourcesTab,
        findsOneWidget,
        reason: 'Resources tab should exist',
      );
      await tester.tap(resourcesTab);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await expectOnResourcesScreen(tester);
      _log.info('Successfully navigated to resources');

      final gradesTab = find.byKey(Key(NavigationPage.grades.navKeyName));
      expect(gradesTab, findsOneWidget, reason: 'Grades tab should exist');
      await tester.tap(gradesTab);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expectOnGradesScreen();
      _log.info('Successfully navigated to grades');

      final plannerTab = find.byKey(Key(NavigationPage.planner.navKeyName));
      expect(plannerTab, findsOneWidget, reason: 'Planner tab should exist');
      await tester.tap(plannerTab);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expectOnPlannerScreen();
      _log.info('Successfully navigated back to planner');
    });

    namedTestWidgets('2. Calendar displays example schedule items', (
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

      // Align the calendar with the user's configured timezone (America/Chicago).
      // The CI device runs UTC, which can differ at month boundaries, causing items
      // anchored to Chicago time to land in a month the UTC calendar doesn't show.
      await navigateCalendarToUserTimezone(tester, 'America/Chicago');

      final quizLoaded = await waitForWidget(
        tester,
        findRichTextContaining('Quiz 4'),
        timeout: config.apiTimeout,
      );
      expect(quizLoaded, isTrue, reason: 'Quiz 4 should appear after loading');

      final portfolioLoaded = await waitForWidget(
        tester,
        findRichTextContaining('Final Portfolio Writing Workshop'),
        timeout: config.apiTimeout,
      );
      expect(
        portfolioLoaded,
        isTrue,
        reason: 'Final Portfolio Writing Workshop should appear after loading',
      );
      expect(
        findRichTextContaining('Intro to Psychology 🧠'),
        findsAtLeastNWidgets(12),
      );
    });

    namedTestWidgets('3. Settings opens correctly based on screen width', (
      tester,
    ) async {
      if (!canProceed) {
        _log.warning('Skipping: user does not exist');
        skipTest('user does not exist (run signup_user_test first)');
        return;
      }

      // Store original size to restore later
      final originalSize = tester.view.physicalSize;
      final originalDevicePixelRatio = tester.view.devicePixelRatio;

      const nonMobileWidth = ResponsiveBreakpoints.mobile + 100;
      const mobileWidth = ResponsiveBreakpoints.mobile - 100;
      const testHeight = 800.0;

      try {
        await initializeTestApp(tester);
        final loggedIn = await loginAndNavigateToPlanner(
          tester,
          testEmail,
          testPassword,
        );
        expect(loggedIn, isTrue, reason: 'Should be logged in');

        // Align the calendar with the user's configured timezone (America/Chicago).
        // The CI device runs UTC, which can differ at month boundaries, causing items
        // anchored to Chicago time to land in a month the UTC calendar doesn't show.
        await navigateCalendarToUserTimezone(tester, 'America/Chicago');

        // --- PART 1: Desktop/Tablet (wide) - Settings opens as dialog ---
        tester.view.physicalSize = const Size(nonMobileWidth, testHeight);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpAndSettle();

        // 1. Click settings, wait for dialog to be shown
        _log.info('Opening settings dialog on desktop ...');
        var settingsButton = find.byKey(const Key(SettingsButton.buttonKey));
        expect(
          settingsButton,
          findsOneWidget,
          reason: 'Settings button should exist',
        );
        await tester.tap(settingsButton);

        // Wait for close button to appear (dialog shell is open)
        final closeButton = find.byIcon(Icons.close);
        final dialogOpened = await waitForWidget(
          tester,
          closeButton,
          timeout: const Duration(seconds: 5),
        );
        expect(dialogOpened, isTrue, reason: 'Settings dialog should open');

        // Wait for settings body to load (AuthBloc fetches profile async; body
        // shows LoadingIndicator until AuthProfileFetched, so the close button
        // may appear before "Keep Helium Free" is in the tree).
        final bodyLoaded = await waitForWidget(
          tester,
          find.text('Change Password'),
          timeout: const Duration(seconds: 5),
        );
        expect(bodyLoaded, isTrue, reason: 'Settings body should finish loading');

        // Verify browser title did NOT change (dialog mode)
        expectOnSettingsScreen(isDialog: true);
        _log.info('Settings dialog opened, browser title still Planner');

        // 2. Click close button, wait until dialog is definitely closed
        await tester.tap(closeButton);
        final dialogClosed = await waitForWidgetToDisappear(
          tester,
          closeButton,
          timeout: const Duration(seconds: 5),
        );
        expect(dialogClosed, isTrue, reason: 'Settings dialog should close');
        _log.info('Settings dialog closed');

        expectBrowserTitle('Planner');

        // 3. Assert that "Quiz 4" can be seen on desktop calendar
        final quiz4Visible = await waitForWidget(
          tester,
          findRichTextContaining('Quiz 4'),
          timeout: config.apiTimeout,
        );
        expect(
          quiz4Visible,
          isTrue,
          reason: 'Quiz 4 should be visible on desktop calendar',
        );
        _log.info('Quiz 4 visible on desktop');

        // --- PART 2: Mobile (narrow) - Settings navigates to screen ---
        // 4. Resize screen to mobile
        _log.info('Resizing to mobile width ...');
        tester.view.physicalSize = const Size(mobileWidth, testHeight);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 5. Assert that "Quiz 4" is no longer shown (calendar items shown as dots on mobile)
        expect(
          findRichTextContaining('Quiz 4'),
          findsNothing,
          reason: 'Quiz 4 should not be visible on mobile (shown as dots)',
        );
        _log.info('Quiz 4 hides on mobile, dots shown instead');

        // 6. Click settings, wait until new screen is shown (browser title should update)
        _log.info('Opening settings screen on mobile ...');
        settingsButton = find.byKey(const Key(SettingsButton.buttonKey));
        expect(
          settingsButton,
          findsOneWidget,
          reason: 'Settings button should exist on mobile',
        );
        await tester.tap(settingsButton);

        // Wait for close button to appear (full-screen dialog shell is open)
        final screenOpened = await waitForWidget(
          tester,
          closeButton,
          timeout: const Duration(seconds: 5),
        );
        expect(screenOpened, isTrue, reason: 'Settings screen should open');

        // Wait for settings body to load (same AuthBloc race as desktop path above)
        final mobileBodyLoaded = await waitForWidget(
          tester,
          find.text('Change Password'),
          timeout: const Duration(seconds: 5),
        );
        expect(
          mobileBodyLoaded,
          isTrue,
          reason: 'Settings body should finish loading on mobile',
        );

        // Verify browser title changed to Settings (full-screen dialog mode)
        expectOnSettingsScreen(isDialog: true);
        _log.info('Settings full-screen dialog opened, browser title is Settings');

        // 7. Click close button, wait until we're back on the Planner screen.
        // Use waitForRoute with browserTitle so we confirm both the route and
        // the browser title have settled before resizing back to desktop.
        await tester.tap(closeButton);
        final backToPlanner = await waitForRoute(
          tester,
          AppRoute.plannerScreen,
          browserTitle: 'Planner',
          timeout: const Duration(seconds: 5),
        );
        expect(
          backToPlanner,
          isTrue,
          reason: 'Should navigate back to Planner',
        );

        expectOnPlannerScreen(isMobile: true);
        _log.info('Back on Planner screen');
      } finally {
        // 8. Whether pass or fail, resize screen back to desktop size
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalDevicePixelRatio;
        await tester.pumpAndSettle();
      }
    });

    namedTestWidgets('4. Todos view filtering and checkbox toggle', (
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

      // Snapshot the user's planner state once; every "of N" assertion below
      // is computed from this snapshot via PlannerCountHelper, so the totals
      // stay correct if example_schedule.json ever changes.
      final counts = PlannerCountHelper(apiHelper);
      final snap = await counts.snapshot();
      final fundamentals = snap.courses.firstWhere(
        (c) => c.title.contains('Fundamentals'),
        orElse: () => throw StateError(
          'Fundamentals course not found in snapshot — example schedule may have changed',
        ),
      );
      const homeworkCategoryTitle = 'Homework 👨🏽‍💻';
      const todosPageSize = 10;

      // 1. Click "Change view" menu and switch to "Todos"
      _log.info('Switching to "Todos" view ...');
      final viewButton = find.byKey(
        const Key(PlannerScreen.viewSwitcherButtonKey),
      );
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
      await tester.pumpAndSettle();
      await takeScreenshot('todos_view_initial_state');

      // 2. Wait for Todos view to initialize and assert "Showing X to Y of N"
      // (X and Y may vary mid-load, N is the helper-computed total).
      // TodosTable._initializeData expands the data window via a network call;
      // on CI this may take several seconds.
      final totalExpected = counts.expectedCount(
        snapshot: snap,
        view: PlannerView.todos,
      );
      final showingTextFinder = find.textContaining(
        RegExp(r'Showing \d+ to \d+ of ' + totalExpected.toString() + r'\b'),
      );
      final todosInitialized = await waitForWidget(
        tester,
        showingTextFinder,
        timeout: config.apiTimeout,
      );
      expect(
        todosInitialized,
        isTrue,
        reason:
            'Should show "Showing X to Y of $totalExpected" after Todos view initializes',
      );

      // 3. Tap filters, tap checkbox next to "Fundamentals"
      _log.info('Opening filter menu ...');
      final filterButton = find.byKey(
        const Key(PlannerScreen.filterButtonKey),
      );
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
        reason: 'Assignments filter should be hidden in Todos view',
      );
      expect(
        find.ancestor(
          of: find.text('Events'),
          matching: find.byType(CheckboxListTile),
        ),
        findsNothing,
        reason: 'Events filter should be hidden in Todos view',
      );
      expect(
        find.ancestor(
          of: find.text('Class Schedules'),
          matching: find.byType(CheckboxListTile),
        ),
        findsNothing,
        reason: 'Class Schedules filter should be hidden in Todos view',
      );
      expect(
        find.ancestor(
          of: find.text('External Calendars'),
          matching: find.byType(CheckboxListTile),
        ),
        findsNothing,
        reason: 'External Calendars filter should be hidden in Todos view',
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

      // 3.1 Assert footer shows "Showing 1 to {pageSize} of N" for Fundamentals
      final fundExpected = counts.expectedCount(
        snapshot: snap,
        view: PlannerView.todos,
        selectedCourseIds: {fundamentals.id},
      );
      final fundUpper = fundExpected < todosPageSize ? fundExpected : todosPageSize;
      expect(
        find.text('Showing 1 to $fundUpper of $fundExpected'),
        findsOneWidget,
        reason:
            'After Fundamentals filter: should show "Showing 1 to $fundUpper of $fundExpected"',
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

      // 4.1 Assert footer shows "Showing 1 to N of N" for Fundamentals+Homework
      final funHwExpected = counts.expectedCount(
        snapshot: snap,
        view: PlannerView.todos,
        selectedCourseIds: {fundamentals.id},
        filterCategories: const [homeworkCategoryTitle],
      );
      final funHwUpper = funHwExpected < todosPageSize
          ? funHwExpected
          : todosPageSize;
      expect(
        find.text('Showing 1 to $funHwUpper of $funHwExpected'),
        findsOneWidget,
        reason:
            'After Homework filter: should show "Showing 1 to $funHwUpper of $funHwExpected"',
      );

      // 5. Close filters menu (tap outside), then tap search icon and enter "1"
      // Tap outside the filter menu to close it
      _log.info('Closing filter menu ...');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // On desktop the search field is always visible inline; on smaller
      // viewports it's behind a button that must be tapped first.
      _log.info('Opening search field ...');
      final searchButton = find.byKey(
        const Key(PlannerScreen.searchButtonKey),
      );
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
      }

      // Wait for search field to appear (animation on non-desktop, immediate
      // on desktop where it's already inline)
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

      // 5.1 Assert footer shows "Showing 1 to N of N" for search "1" combined
      // with the still-active Fundamentals + Homework filters above.
      final searchExpected = counts.expectedCount(
        snapshot: snap,
        view: PlannerView.todos,
        selectedCourseIds: {fundamentals.id},
        filterCategories: const [homeworkCategoryTitle],
        searchQuery: '1',
      );
      final searchUpper = searchExpected < todosPageSize
          ? searchExpected
          : todosPageSize;
      final showingText = find.text(
        'Showing 1 to $searchUpper of $searchExpected',
      );
      final searchResultsShown = await waitForWidget(
        tester,
        showingText,
        timeout: const Duration(seconds: 5),
      );
      expect(
        searchResultsShown,
        isTrue,
        reason:
            'After search "1": should show "Showing 1 to $searchUpper of $searchExpected"',
      );

      // 6. Assert the row shows "Homework 1" with strikethrough, time, class, and grade
      // TodosTable uses SelectableText for title and due
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

      // Due format is "EEE, MMM d • h:mm a" (e.g., "Fri, Oct 10 • 11 AM")
      // User timezone is set to America/Chicago during registration
      expect(
        find.byWidgetPredicate(
          (w) => w is SelectableText && (w.data?.contains('11 AM') ?? false),
        ),
        findsOneWidget,
        reason: 'Row should show due with 11 AM (Chicago timezone)',
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
      // Wait to ensure it doesn't open after a delay
      final editDialogOpened = await waitForWidget(
        tester,
        find.text('Edit Assignment'),
        timeout: const Duration(seconds: 10),
      );
      expect(
        editDialogOpened,
        isFalse,
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
    });

    namedTestWidgets('5. Month view edit assignment and checkbox toggle', (
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

      // Align the calendar with the user's configured timezone (America/Chicago).
      // The CI device runs UTC, which can differ at month boundaries, causing items
      // anchored to Chicago time to land in a month the UTC calendar doesn't show.
      await navigateCalendarToUserTimezone(tester, 'America/Chicago');

      // Wait for Quiz 4 to load in the correct month, then tap to edit
      final quizVisible = await waitForWidget(
        tester,
        findRichTextContaining('Quiz 4'),
        timeout: config.apiTimeout,
      );
      expect(quizVisible, isTrue, reason: 'Quiz 4 should be visible after navigating to user timezone month');

      // Tap on the homework item to open edit screen
      await tester.tap(findRichTextContaining('Quiz 4').first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify we're on the edit screen and store reference to the dialog
      final editDialogTitle = find.text('Edit Assignment');
      final editScreenFound = await waitForWidget(
        tester,
        editDialogTitle,
        timeout: config.apiTimeout,
      );
      expect(editScreenFound, isTrue, reason: 'Should navigate to edit screen');
      expect(
        editDialogTitle,
        findsOneWidget,
        reason: 'Edit screen: "Edit Assignment" title should be shown',
      );
      // Browser title updates asynchronously once the screen resolves its type
      final titleUpdated = await waitForBrowserTitle(
        tester,
        'Edit Assignment',
        timeout: const Duration(seconds: 5),
      );
      expect(
        titleUpdated,
        isTrue,
        reason: 'Browser title should update to "Edit Assignment | Helium"',
      );
      _log.info('Edit Assignment dialog opened ...');

      // 1. Change title to "Quiz 4 (Edited)"
      final titleField = find.byKey(const Key(PlannerItemFormController.titleField));
      // Wait for the title field to load
      final titleFieldFound = await waitForWidget(
        tester,
        titleField,
        timeout: const Duration(seconds: 5),
      );
      expect(
        titleFieldFound,
        isTrue,
        reason: 'Title field should be present',
      );
      await enterTextInField(tester, titleField, 'Quiz 4 (Edited)');

      // 2. Change time to 2pm - tap on the time field to open time picker
      _log.info('Change time to 2pm ...');
      final timeFields = find.byIcon(Icons.access_time);
      expect(
        timeFields,
        findsWidgets,
        reason: 'Time field icon should be present',
      );

      await tester.tap(timeFields.first);
      await tester.pumpAndSettle();

      // Switch to dial mode to tap on clock face
      final switchToDial = find.byTooltip('Switch to dial picker mode');
      if (switchToDial.evaluate().isNotEmpty) {
        await tester.tap(switchToDial);
        await tester.pumpAndSettle();
      }

      // Find the dial and tap at 2 o'clock position
      final dialFinder = find.byWidgetPredicate(
        (Widget w) => '${w.runtimeType}' == '_Dial',
      );
      final center = tester.getCenter(dialFinder);
      final topRight = tester.getTopRight(dialFinder);
      final radius = topRight.dx - center.dx;

      // 2 o'clock = 60 degrees from 12 (top), in radians: (60 - 90) * pi / 180
      const hour2Angle = (60 - 90) * 3.14159 / 180;
      final tapAt = Offset(
        center.dx + radius * 0.7 * cos(hour2Angle),
        center.dy + radius * 0.7 * sin(hour2Angle),
      );
      await tester.tapAt(tapAt);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();

      // 3. Scroll to and tap the Complete checkbox
      final completeCheckbox = find.byKey(const Key(PlannerItemFormController.completeField));
      await scrollUntilVisible(tester, completeCheckbox);
      await tester.tap(completeCheckbox);
      await tester.pumpAndSettle();
      _log.info('Tapped complete checkbox');

      // 5. Set a grade (grade field appears when completed is checked)
      final gradeField = find.byKey(const Key(PlannerItemFormController.gradeField));
      if (gradeField.evaluate().isNotEmpty) {
        await enterTextInField(tester, gradeField, '95/100');
        await tester.pumpAndSettle();
        _log.info('Entered grade: 95/100');
      }

      // Find and tap the Save button
      _log.info('Saving homework changes ...');
      final saveButton = find.byKey(const Key(PageHeader.saveButtonKey));
      expect(
        saveButton,
        findsOneWidget,
        reason: 'Header save button should be present',
      );
      await tester.tap(saveButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify the edit dialog has closed
      final dialogClosed = await waitForWidgetToDisappear(
        tester,
        editDialogTitle,
        timeout: config.apiTimeout,
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

      // Wait for updated item to appear in calendar
      final updatedItem = findRichTextContaining('Quiz 4 (Edited)');
      final itemAppeared = await waitForWidget(
        tester,
        updatedItem,
        timeout: config.apiTimeout,
      );
      expect(
        itemAppeared,
        isTrue,
        reason: 'Calendar should show homework with updated title',
      );
      _log.info('UI shows updated homework title');

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
      // Verify time was changed to 2pm Chicago time
      // Convert expected 2pm Chicago to UTC using the homework's actual date
      final chicago = tz.getLocation('America/Chicago');
      final expected2pmChicago = tz.TZDateTime(
        chicago,
        editedHomework.start.year,
        editedHomework.start.month,
        editedHomework.start.day,
        14, // 2pm
        0,
      );
      expect(
        editedHomework.start.toUtc().hour,
        equals(expected2pmChicago.toUtc().hour),
        reason:
            'Start time should be 2pm Chicago (${expected2pmChicago.toUtc().hour}:00 UTC)',
      );
      expect(
        editedHomework.start.minute,
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

      // 6. Tap the checkbox on the calendar item to uncheck it
      _log.info('Tapping checkbox in month view ...');

      // Find the edited homework item
      final editedItemOnCalendar = findRichTextContaining('Quiz 4 (Edited)');
      expect(
        editedItemOnCalendar,
        findsWidgets,
        reason: 'Should find edited item',
      );

      // Find the KeyedSubtree ancestor (each calendar item is keyed
      // ValueKey('planner_item_<type>_<id>'); we only need the ancestor
      // here, not the key itself, so the format is irrelevant)
      final itemContainer = find
          .ancestor(
            of: editedItemOnCalendar.first,
            matching: find.byType(KeyedSubtree),
          )
          .first;

      // Find the completion checkbox within that specific item container.
      // The checkbox is keyed with a ValueKey<String> prefixed by
      // PlannerScreen.plannerItemCheckboxKeyPrefix + the homework id.
      final checkbox = find.descendant(
        of: itemContainer,
        matching: find.byWidgetPredicate((widget) {
          final key = widget.key;
          return key is ValueKey<String> &&
              key.value.startsWith(PlannerScreen.plannerItemCheckboxKeyPrefix);
        }),
      );
      expect(
        checkbox,
        findsOneWidget,
        reason: 'Should find checkbox in item container',
      );

      await tester.tap(checkbox);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      _log.info('Tapped checkbox to uncheck');

      final editDialogOpenedAgain = await waitForWidget(
        tester,
        find.text('Edit Assignment'),
        timeout: const Duration(seconds: 5),
      );
      expect(
        editDialogOpenedAgain,
        isFalse,
        reason: 'Edit dialog should NOT open when clicking checkbox',
      );

      // 7. Wait for UI to update after checkbox toggle
      await tester.pumpAndSettle(const Duration(seconds: 2));
      _log.info('Checkbox toggled, verifying state via API ...');

      // 8. Verify via API that completed is now false
      _log.info('Verifying unchecked state via API ...');
      final uncheckedHomework = await apiHelper.findHomeworkByTitle(
        'Quiz 4 (Edited)',
      );
      expect(
        uncheckedHomework,
        isNotNull,
        reason: 'Should find homework via API',
      );
      expect(
        uncheckedHomework!.completed,
        isFalse,
        reason: 'Homework should be marked incomplete after unchecking',
      );
      // Grade should still be present
      expect(
        uncheckedHomework.currentGrade,
        equals('95/100'),
        reason: 'Grade should still be 95/100 after unchecking',
      );
    });

    namedTestWidgets(
      '6. Calendar month view filter shows all courses and unique categories',
      (tester) async {
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
        await navigateCalendarToUserTimezone(tester, 'America/Chicago');

        final counts = PlannerCountHelper(apiHelper);
        final snap = await counts.snapshot();
        final courseTitles = snap.courses.map((c) => c.title).toList();
        final uniqueCategoryTitles = snap.categoriesById.values
            .map((c) => c.title)
            .toSet();

        _log.info('Opening filter menu ...');
        final filterButton = find.byKey(
          const Key(PlannerScreen.filterButtonKey),
        );
        await tester.tap(filterButton);
        final filterMenuOpened = await waitForWidget(
          tester,
          find.byType(CheckboxListTile),
          timeout: const Duration(seconds: 5),
        );
        expect(filterMenuOpened, isTrue, reason: 'Filter menu should open');

        for (final title in courseTitles) {
          expect(
            find.ancestor(
              of: find.text(title),
              matching: find.byType(CheckboxListTile),
            ),
            findsOneWidget,
            reason: 'Filter menu CLASSES section should list course "$title"',
          );
        }

        for (final title in uniqueCategoryTitles) {
          expect(
            find.ancestor(
              of: find.text(title),
              matching: find.byType(CheckboxListTile),
            ),
            findsOneWidget,
            reason:
                'Filter menu CATEGORIES section should list category "$title"',
          );
        }
      },
    );

    namedTestWidgets(
      '7. Todos view filter coverage',
      (tester) async {
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

        final counts = PlannerCountHelper(apiHelper);
        final snap = await counts.snapshot();
        final creativeWriting = snap.courses.firstWhere(
          (c) => c.title.contains('Creative Writing'),
          orElse: () => throw StateError(
            'Creative Writing course missing from snapshot',
          ),
        );
        const projectCategory = 'Project 🔨';
        const quizCategory = 'Quiz 💡';
        const completeStatus = 'Complete';

        // Switch to Todos view
        _log.info('Switching to Todos view ...');
        await tester.tap(find.byKey(const Key(PlannerScreen.viewSwitcherButtonKey)));
        final todosOption = find.text('Todos');
        final menuOpened = await waitForWidget(
          tester,
          todosOption,
          timeout: const Duration(seconds: 5),
        );
        expect(menuOpened, isTrue, reason: 'Todos option should appear');
        await tester.tap(todosOption);
        await tester.pumpAndSettle();

        // Wait for initial Todos render before applying filters
        final initialPagination = find.textContaining(
          RegExp(r'Showing \d+ to \d+ of \d+'),
        );
        final todosReady = await waitForWidget(
          tester,
          initialPagination,
          timeout: config.apiTimeout,
        );
        expect(todosReady, isTrue, reason: 'Todos view should initialize');

        // Pagination footer rendered by HeliumPager:
        // "[Showing ]<start> to <end> of <total>" — the "Showing " prefix is
        // desktop-only (helium_pager.dart::_buildItemsCountText).
        final paginationRegex = RegExp(r'^(?:Showing )?\d+ to \d+ of \d+$');
        Future<void> expectPaginationOf(int expected, String reason) async {
          // Filters debounce + dispatch through compute(); give the data
          // source a few extra cycles to settle the appointment list before
          // asserting against the rendered footer.
          await tester.pumpAndSettle(const Duration(milliseconds: 500));

          final paginationFinder = find.byWidgetPredicate(
            (w) =>
                w is Text &&
                w.data != null &&
                paginationRegex.hasMatch(w.data!),
          );
          expect(
            paginationFinder,
            findsWidgets,
            reason: '$reason — no pagination text found',
          );
          final actualText =
              (paginationFinder.evaluate().first.widget as Text).data ?? '';
          final match = RegExp(r'of (\d+)$').firstMatch(actualText);
          final actual = match != null ? int.parse(match.group(1)!) : -1;
          expect(
            actual,
            equals(expected),
            reason:
                '$reason — UI shows "$actualText" (total=$actual) but helper computed total=$expected',
          );
        }

        Finder filterTileFor(String text) => find.ancestor(
          of: find.text(text),
          matching: find.byType(CheckboxListTile),
        );

        final filterButton = find.byKey(
          const Key(PlannerScreen.filterButtonKey),
        );
        // "Clear All" is unique to the open filter sheet — its presence is a
        // reliable proxy for "menu is currently open".
        final clearAllButton = find.text('Clear All');

        Future<void> ensureFilterMenuOpen() async {
          if (clearAllButton.evaluate().isNotEmpty) return;
          await tester.tap(filterButton);
          await waitForWidget(
            tester,
            clearAllButton,
            timeout: const Duration(seconds: 5),
          );
        }

        Future<void> closeFilterMenu() async {
          if (clearAllButton.evaluate().isEmpty) return;
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();
        }

        // Apply a clean filter combination. Force-close the menu first so the
        // popup's StatefulBuilder fully remounts on reopen — guards against
        // any stale checkbox state surviving Clear All. Then clear filters,
        // then tap each requested tile. The filter sheet's contents live in a
        // SingleChildScrollView, so tiles in lower sections (e.g. CATEGORIES)
        // can be off-screen — ensureVisible scrolls them in before tapping
        // so the tap doesn't pass through to the underlying todos table.
        Future<void> applyFilters({
          Set<String> tileLabels = const {},
        }) async {
          await closeFilterMenu();
          await ensureFilterMenuOpen();
          await tester.tap(clearAllButton);
          await tester.pumpAndSettle();
          for (final label in tileLabels) {
            final tile = filterTileFor(label);
            await tester.ensureVisible(tile);
            await tester.pumpAndSettle();
            await tester.tap(tile);
            await tester.pumpAndSettle();
          }
        }

        // 7a — Complete status only
        _log.info('Filter: Complete only ...');
        await applyFilters(tileLabels: {completeStatus});
        await expectPaginationOf(
          counts.expectedCount(
            snapshot: snap,
            view: PlannerView.todos,
            filterStatuses: const {completeStatus},
          ),
          'Complete filter only',
        );

        // 7b — Project category only
        _log.info('Filter: Project only ...');
        await applyFilters(tileLabels: {projectCategory});
        await expectPaginationOf(
          counts.expectedCount(
            snapshot: snap,
            view: PlannerView.todos,
            filterCategories: const [projectCategory],
          ),
          'Project category filter only',
        );

        // 7c — Quiz category only
        _log.info('Filter: Quiz only ...');
        await applyFilters(tileLabels: {quizCategory});
        await expectPaginationOf(
          counts.expectedCount(
            snapshot: snap,
            view: PlannerView.todos,
            filterCategories: const [quizCategory],
          ),
          'Quiz category filter only',
        );

        // 7d — Search "study" (no menu interaction)
        _log.info('Filter: search "study" ...');
        await applyFilters();
        await closeFilterMenu();

        final searchButton = find.byKey(
          const Key(PlannerScreen.searchButtonKey),
        );
        if (searchButton.evaluate().isNotEmpty) {
          await tester.tap(searchButton);
        }
        final searchField = find.byType(TextField);
        await waitForWidget(
          tester,
          searchField,
          timeout: const Duration(seconds: 5),
        );
        await enterTextInField(tester, searchField.last, 'study');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await expectPaginationOf(
          counts.expectedCount(
            snapshot: snap,
            view: PlannerView.todos,
            searchQuery: 'study',
          ),
          'Search "study"',
        );
        // Clear search before next scenario
        await enterTextInField(tester, searchField.last, '');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // 7e — Single course (Creative Writing) only
        _log.info('Filter: Creative Writing course only ...');
        await applyFilters(tileLabels: {creativeWriting.title});
        await expectPaginationOf(
          counts.expectedCount(
            snapshot: snap,
            view: PlannerView.todos,
            selectedCourseIds: {creativeWriting.id},
          ),
          'Creative Writing course filter only',
        );

        // 7f — Creative Writing + Complete
        _log.info('Filter: Creative Writing + Complete ...');
        await applyFilters(
          tileLabels: {creativeWriting.title, completeStatus},
        );
        await expectPaginationOf(
          counts.expectedCount(
            snapshot: snap,
            view: PlannerView.todos,
            selectedCourseIds: {creativeWriting.id},
            filterStatuses: const {completeStatus},
          ),
          'Creative Writing + Complete',
        );
      },
    );

    namedTestWidgets(
      '8. Agenda view filters affect visible items',
      (tester) async {
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
        await navigateCalendarToUserTimezone(tester, 'America/Chicago');

        final counts = PlannerCountHelper(apiHelper);
        final snap = await counts.snapshot();

        final creativeWriting = snap.courses.firstWhere(
          (c) => c.title.contains('Creative Writing'),
          orElse: () =>
              throw StateError('Creative Writing course missing from snapshot'),
        );
        const quizCategory = 'Quiz 💡';
        const completeStatus = 'Complete';
        // The category filter matches by title — multiple courses can share
        // a category title (e.g., Programming and Psychology both have
        // "Quiz 💡"). Match the same way here so the expected sets align.
        final quizCategoryIds = snap.categoriesById.values
            .where((c) => c.title == quizCategory)
            .map((c) => c.id)
            .toSet();
        final assignmentsType = PlannerFilterType.assignments.value;
        final eventsType = PlannerFilterType.events.value;
        final classSchedulesType = PlannerFilterType.classSchedules.value;

        // Snapshot-derived id sets used for presence/absence assertions.
        // Each appointment renders with a key of `planner_item_<type>_<id>`
        // (planner_screen.dart) — the type prefix is required because each
        // model (homework / event / schedule) has its own backend PK
        // sequence, so a homework with id=5 and an event with id=5 would
        // otherwise share the same key and confuse visibility checks.
        //
        // Class-schedule appointments use generated event ids of
        // `schedule.id * 100 + slotIndex` (course_schedule_builder_source
        // .dart::_generateEventId). Our example schedules have a single
        // time-slot group per schedule, so slotIndex=0.
        String hwKey(int id) => 'homework_$id';
        String eventKey(int id) => 'event_$id';
        String classKey(int scheduleId) => 'courseSchedule_${scheduleId * 100}';

        final allHomeworkKeys = snap.homework.map((h) => hwKey(h.id)).toList();
        final completedHomeworkKeys = snap.homework
            .where((h) => h.completed)
            .map((h) => hwKey(h.id))
            .toList();
        final incompleteHomeworkKeys = snap.homework
            .where((h) => !h.completed)
            .map((h) => hwKey(h.id))
            .toList();
        final quizHomeworkKeys = snap.homework
            .where((h) => quizCategoryIds.contains(h.category.id))
            .map((h) => hwKey(h.id))
            .toList();
        final nonQuizHomeworkKeys = snap.homework
            .where((h) => !quizCategoryIds.contains(h.category.id))
            .map((h) => hwKey(h.id))
            .toList();
        final cwHomeworkKeys = snap.homework
            .where((h) => h.course.id == creativeWriting.id)
            .map((h) => hwKey(h.id))
            .toList();
        final nonCwHomeworkKeys = snap.homework
            .where((h) => h.course.id != creativeWriting.id)
            .map((h) => hwKey(h.id))
            .toList();
        final allEventKeys = snap.events.map((e) => eventKey(e.id)).toList();
        final allClassEventKeys = snap.schedules
            .map((s) => classKey(s.id))
            .toList();
        final cwClassEventKeys = snap.schedules
            .where((s) => s.course == creativeWriting.id)
            .map((s) => classKey(s.id))
            .toList();
        final nonCwClassEventKeys = snap.schedules
            .where((s) => s.course != creativeWriting.id)
            .map((s) => classKey(s.id))
            .toList();
        bool searchMatch(String s, String q) =>
            s.toLowerCase().contains(q.toLowerCase());
        const searchQuery = 'Workshop';
        final searchMatchKeys = [
          ...snap.homework
              .where((h) => searchMatch(h.title, searchQuery))
              .map((h) => hwKey(h.id)),
          ...snap.events
              .where((e) => searchMatch(e.title, searchQuery))
              .map((e) => eventKey(e.id)),
        ];

        _log.info('Switching to Agenda view ...');
        await tester.tap(
          find.byKey(const Key(PlannerScreen.viewSwitcherButtonKey)),
        );
        final agendaOption = find.text('Agenda');
        final agendaMenuOpened = await waitForWidget(
          tester,
          agendaOption,
          timeout: const Duration(seconds: 5),
        );
        expect(
          agendaMenuOpened,
          isTrue,
          reason: 'Agenda option should appear in view menu',
        );
        await tester.tap(agendaOption);
        await tester.pumpAndSettle();

        // Filter primitives (mirror Test 7's mechanic).
        Finder filterTileFor(String text) => find.ancestor(
          of: find.text(text),
          matching: find.byType(CheckboxListTile),
        );
        final filterButton = find.byKey(
          const Key(PlannerScreen.filterButtonKey),
        );
        final clearAllButton = find.text('Clear All');

        Future<void> ensureFilterMenuOpen() async {
          if (clearAllButton.evaluate().isNotEmpty) return;
          await tester.tap(filterButton);
          await waitForWidget(
            tester,
            clearAllButton,
            timeout: const Duration(seconds: 5),
          );
        }

        Future<void> closeFilterMenu() async {
          if (clearAllButton.evaluate().isEmpty) return;
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();
        }

        // Force-close + reopen so the popup's StatefulBuilder remounts
        // (same hygiene as Test 7).
        Future<void> applyFilters({
          Set<String> tileLabels = const {},
        }) async {
          await closeFilterMenu();
          await ensureFilterMenuOpen();
          await tester.tap(clearAllButton);
          await tester.pumpAndSettle();
          for (final label in tileLabels) {
            final tile = filterTileFor(label);
            await tester.ensureVisible(tile);
            await tester.pumpAndSettle();
            await tester.tap(tile);
            await tester.pumpAndSettle();
          }
          await closeFilterMenu();
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }

        // Each rendered calendar item is a KeyedSubtree keyed
        // `planner_item_<type>_<id>` (planner_screen.dart). Callers pass the
        // `<type>_<id>` suffix; this helper combines it with the prefix.
        bool isItemVisible(String suffix) =>
            find.byKey(ValueKey('planner_item_$suffix')).evaluate().isNotEmpty;
        bool anyVisible(Iterable<String> keys) => keys.any(isItemVisible);
        List<String> visibleSubset(Iterable<String> keys) =>
            keys.where(isItemVisible).toList();

        // Poll the rendered tree until the visibility predicates hold.
        // Filter changes cross a 16ms debounce + compute() isolate boundary
        // before notifyListeners + SfCalendar repaint, so on slower CI
        // machines the assertion can fire before the new filtered set has
        // reached the tree even after pumpAndSettle.
        Future<void> expectVisibility({
          List<String> shouldBeVisible = const [],
          List<String> shouldNotBeVisible = const [],
          required String reason,
          Duration timeout = const Duration(seconds: 5),
        }) async {
          final deadline = DateTime.now().add(timeout);
          while (DateTime.now().isBefore(deadline)) {
            final missingExpected =
                shouldBeVisible.isNotEmpty && !anyVisible(shouldBeVisible);
            final extraStillVisible = shouldNotBeVisible.isNotEmpty &&
                anyVisible(shouldNotBeVisible);
            if (!missingExpected && !extraStillVisible) return;
            await tester.pump(const Duration(milliseconds: 100));
          }
          // Re-run the same checks one last time so a failure produces the
          // matcher's standard error output. Include the offending IDs so CI
          // logs reveal whether the filter never landed, only partially
          // landed, or some other category leaked through. Capture a
          // screenshot so the actual rendered state at the moment of failure
          // is preserved in the integration-screenshots artifact.
          final slug = reason
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
              .replaceAll(RegExp(r'^_|_$'), '');
          if (shouldBeVisible.isNotEmpty &&
              !anyVisible(shouldBeVisible)) {
            await takeScreenshot('expectVisibility_missing_$slug');
            final missing = shouldBeVisible.where((k) => !isItemVisible(k));
            expect(
              anyVisible(shouldBeVisible),
              isTrue,
              reason:
                  '$reason — expected at least one to render; '
                  'missing all of $shouldBeVisible (none visible). '
                  'Sample missing: ${missing.take(5).toList()}',
            );
          }
          if (shouldNotBeVisible.isNotEmpty) {
            final stillVisible = visibleSubset(shouldNotBeVisible);
            if (stillVisible.isNotEmpty) {
              await takeScreenshot('expectVisibility_leak_$slug');
            }
            expect(
              stillVisible,
              isEmpty,
              reason:
                  '$reason — expected none to render, but these are '
                  'still visible: $stillVisible',
            );
          }
        }

        // 5a — No filter: at least one item of each type is rendered.
        _log.info('Filter: none ...');
        await applyFilters();
        await expectVisibility(
          shouldBeVisible: [
            ...allHomeworkKeys,
            ...allEventKeys,
            ...allClassEventKeys,
          ],
          reason: 'No filter',
        );

        // 5b — Events only: events visible, homework + classes hidden.
        _log.info('Filter: Events only ...');
        await applyFilters(tileLabels: {eventsType});
        await expectVisibility(
          shouldBeVisible: allEventKeys,
          shouldNotBeVisible: [...allHomeworkKeys, ...allClassEventKeys],
          reason: 'Events type only',
        );

        // 5c — Assignments only: homework visible, events + classes hidden.
        _log.info('Filter: Assignments only ...');
        await applyFilters(tileLabels: {assignmentsType});
        await expectVisibility(
          shouldBeVisible: allHomeworkKeys,
          shouldNotBeVisible: [...allEventKeys, ...allClassEventKeys],
          reason: 'Assignments type only',
        );

        // 5d — Class Schedules only: classes visible, homework + events hidden.
        _log.info('Filter: Class Schedules only ...');
        await applyFilters(tileLabels: {classSchedulesType});
        await expectVisibility(
          shouldBeVisible: allClassEventKeys,
          shouldNotBeVisible: [...allHomeworkKeys, ...allEventKeys],
          reason: 'Class Schedules type only',
        );

        // 5e — Assignments + Complete: completed homework visible,
        // incomplete homework hidden.
        _log.info('Filter: Assignments + Complete ...');
        await applyFilters(tileLabels: {assignmentsType, completeStatus});
        await expectVisibility(
          shouldBeVisible: completedHomeworkKeys,
          shouldNotBeVisible: incompleteHomeworkKeys,
          reason: 'Assignments + Complete',
        );

        // 5f — Assignments + Quiz category: only Quiz-category homework.
        _log.info('Filter: Assignments + Quiz category ...');
        await applyFilters(tileLabels: {assignmentsType, quizCategory});
        await expectVisibility(
          shouldBeVisible: quizHomeworkKeys,
          shouldNotBeVisible: nonQuizHomeworkKeys,
          reason: 'Assignments + Quiz category',
        );

        // 5g — Search "Workshop": only items whose title contains the term.
        _log.info('Filter: search "$searchQuery" ...');
        await applyFilters();
        final searchButton = find.byKey(
          const Key(PlannerScreen.searchButtonKey),
        );
        if (searchButton.evaluate().isNotEmpty) {
          await tester.tap(searchButton);
        }
        final searchField = find.byType(TextField);
        await waitForWidget(
          tester,
          searchField,
          timeout: const Duration(seconds: 5),
        );
        await enterTextInField(tester, searchField.last, searchQuery);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        await expectVisibility(
          shouldBeVisible: searchMatchKeys,
          // Items not matching the search shouldn't render. Quiz 4 is a safe
          // canary — its title doesn't contain the search query.
          shouldNotBeVisible: snap.homework
              .where((h) => !searchMatch(h.title, searchQuery))
              .map((h) => hwKey(h.id))
              .toList(),
          reason: 'Search "$searchQuery"',
        );
        // Clear search before remaining scenarios.
        await enterTextInField(tester, searchField.last, '');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // 5h — Course excluded (Creative Writing): tap the OTHER courses so
        // the filter restricts to "all but Creative Writing".
        _log.info('Filter: exclude Creative Writing ...');
        await applyFilters(
          tileLabels: snap.courses
              .where((c) => c.id != creativeWriting.id)
              .map((c) => c.title)
              .toSet(),
        );
        await expectVisibility(
          shouldBeVisible: nonCwHomeworkKeys,
          shouldNotBeVisible: cwHomeworkKeys,
          reason: 'Exclude Creative Writing course',
        );

        // 5i — Exclude CW + Type=Class Schedules: only Programming/Psych
        // class schedules render.
        _log.info('Filter: exclude Creative Writing + Class Schedules ...');
        await applyFilters(
          tileLabels: {
            ...snap.courses
                .where((c) => c.id != creativeWriting.id)
                .map((c) => c.title),
            classSchedulesType,
          },
        );
        await expectVisibility(
          shouldBeVisible: nonCwClassEventKeys,
          shouldNotBeVisible: [
            ...cwClassEventKeys,
            ...allHomeworkKeys,
            ...allEventKeys,
          ],
          reason: 'Exclude Creative Writing + Class Schedules',
        );
      },
    );

    namedTestWidgets('9. User can clear example schedule', (tester) async {
      if (!canProceed) {
        _log.warning('Skipping: user does not exist');
        skipTest('user does not exist (run signup_user_test first)');
        return;
      }

      await initializeTestApp(tester);
      await ensureOnLoginScreen(tester);

      // Log in - but DON'T dismiss the welcome dialog automatically
      await enterTextInField(
        tester,
        find.byKey(const Key(CredentialsFormController.emailField)),
        testEmail,
      );
      await enterTextInField(
        tester,
        find.byKey(const Key(CredentialsFormController.passwordField)),
        testPassword,
      );

      await tester.tap(find.byKey(const Key(LoginScreen.signInButtonKey)));

      // Wait for the welcome dialog to appear
      final welcomeDialogFound = await waitForWidget(
        tester,
        find.text('Welcome to Helium!'),
        timeout: const Duration(seconds: 45),
      );

      if (!welcomeDialogFound) {
        await initializeTestApp(tester);
        await ensureOnLoginScreen(tester);

        await enterTextInField(
          tester,
          find.byKey(const Key(CredentialsFormController.emailField)),
          testEmail,
        );
        await enterTextInField(
          tester,
          find.byKey(const Key(CredentialsFormController.passwordField)),
          testPassword,
        );

        await tester.tap(find.byKey(const Key(LoginScreen.signInButtonKey)));

        final retryWelcomeFound = await waitForWidget(
          tester,
          find.text('Welcome to Helium!'),
          timeout: const Duration(seconds: 45),
        );

        if (!retryWelcomeFound) {
          skipTest(
            'Welcome dialog not available (example schedule may be cleared)',
          );
          return;
        }
      }

      // Click "Clear Example Data" button
      final clearButton = find.text('Clear Example Data');
      expect(
        clearButton,
        findsOneWidget,
        reason: 'Clear Example Data button should exist',
      );

      _log.info('Clicking Clear Example Data button ...');
      await tester.tap(clearButton);

      // The delete API is synchronous - data is cleared when it returns.
      // Just let the UI settle after the operation completes.
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Wait for navigation to Classes screen
      _log.info('Waiting for navigation to Classes screen ...');
      final classesScreenFound = await waitForRoute(
        tester,
        AppRoute.coursesScreen,
        browserTitle: 'Classes',
        timeout: const Duration(seconds: 45),
      );
      expect(
        classesScreenFound,
        isTrue,
        reason: 'Should navigate to Classes screen after clearing example data',
      );

      _log.info(
        'Reached Classes screen, verifying example data was cleared ...',
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Assert the Classes screen is empty
      final hasFallSemester = find
          .textContaining('Fall Semester')
          .evaluate()
          .isNotEmpty;
      final hasProgramming = find
          .textContaining('Programming')
          .evaluate()
          .isNotEmpty;
      final hasWriting = find.textContaining('Writing').evaluate().isNotEmpty;
      final hasPsychology = find
          .textContaining('Psychology')
          .evaluate()
          .isNotEmpty;

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
      expect(hasWriting, isFalse, reason: 'Writing course should be cleared');
      expect(
        hasPsychology,
        isFalse,
        reason: 'Psychology course should be cleared',
      );

      _log.info('... example data successfully cleared');
    });
  });
}
