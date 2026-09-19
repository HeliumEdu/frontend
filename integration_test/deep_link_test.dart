import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/presentation/features/notebook/views/note_add_screen.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_item_add_screen.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'helpers/api_helper.dart';
import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('deep_link_test');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = TestConfig();
  initializeTestLogging(
    environment: config.environment,
    apiHost: config.projectApiHost,
  );

  group('Deep Link Tests', () {
    final apiHelper = ApiHelper();
    bool canProceed = false;

    setUpAll(() async {
      await startSuite('Deep Link Tests');
      canProceed = await apiHelper.userExists(config.testEmail);
    });

    tearDownAll(() async {
      await endSuite();
    });

    Future<bool> loginForDeepLink(WidgetTester tester) async {
      if (!canProceed) {
        _log.warning('Skipping: user does not exist');
        skipTest('user does not exist (run signup_user_test first)');
        return false;
      }
      await initializeTestApp(tester);
      final loggedIn = await loginAndNavigateToPlanner(
        tester,
        config.testEmail,
        config.testPassword,
      );
      expect(loggedIn, isTrue, reason: 'Should be logged in');
      return true;
    }

    namedTestWidgets(
      '1. Assignment deep link opens the editor for that assignment',
      (tester) async {
        if (!await loginForDeepLink(tester)) return;

        final homework = await apiHelper.findHomeworkByTitle('Quiz 4');
        expect(
          homework,
          isNotNull,
          reason: 'Example schedule should contain Quiz 4',
        );

        final route =
            '${AppRoute.plannerScreen}/$plannerItemHomeworkPath/${homework!.id}/${plannerItemDialogSteps.first}';
        _log.info('Deep linking to $route ...');
        router.go(route);

        final reachedRoute = await waitForRoute(
          tester,
          route,
          browserTitle: 'Edit Assignment',
          timeout: config.apiTimeout,
        );
        expect(
          reachedRoute,
          isTrue,
          reason: 'Should land on $route with the editor open',
        );

        final titleShown = await waitForWidget(
          tester,
          find.descendant(
            of: find.byType(PlannerItemAddScreen),
            matching: find.text(homework.title),
          ),
          timeout: config.apiTimeout,
        );
        expect(
          titleShown,
          isTrue,
          reason: 'Editor should be populated with "${homework.title}"',
        );

        await closePageDialog(
          tester,
          shellPath: AppRoute.plannerScreen,
          shellTitle: 'Planner',
        );
      },
    );

    namedTestWidgets(
      '2. Class deep link with a step segment lands on that step',
      (tester) async {
        if (!await loginForDeepLink(tester)) return;

        final courses = await apiHelper.getCourses();
        expect(
          courses,
          isNotEmpty,
          reason: 'Example schedule should contain classes',
        );
        final course = courses!.first;

        final route = '${AppRoute.coursesScreen}/${course.id}/schedule';
        _log.info('Deep linking to $route ...');
        router.go(route);

        final reachedRoute = await waitForRoute(
          tester,
          route,
          browserTitle: 'Edit Class',
          timeout: config.apiTimeout,
        );
        expect(
          reachedRoute,
          isTrue,
          reason: 'Should land on $route with the editor open',
        );
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals(route),
          reason:
              'Route should keep the schedule step, not normalise to details',
        );

        final scheduleStepShown = await waitForWidget(
          tester,
          find.text('Schedules'),
          timeout: config.apiTimeout,
        );
        expect(
          scheduleStepShown,
          isTrue,
          reason: 'Schedules step should be the active step',
        );
        expect(
          find.text('Cancellations'),
          findsOneWidget,
          reason: 'Schedules step should show the Cancellations button',
        );

        await closePageDialog(
          tester,
          shellPath: AppRoute.coursesScreen,
          shellTitle: 'Classes',
        );
      },
    );

    namedTestWidgets(
      '3. New-note deep link with a linked assignment shows the link badge',
      (tester) async {
        if (!await loginForDeepLink(tester)) return;

        final homework = await apiHelper.findHomeworkByTitle('Quiz 4');
        expect(
          homework,
          isNotNull,
          reason: 'Example schedule should contain Quiz 4',
        );

        final route =
            '${AppRoute.notebookScreen}/new?${DeepLinkParam.linkHomeworkId}=${homework!.id}';
        _log.info('Deep linking to $route ...');
        router.go(route);

        final reachedRoute = await waitForRoute(
          tester,
          '${AppRoute.notebookScreen}/new',
          browserTitle: 'Add Note',
          timeout: config.apiTimeout,
        );
        expect(
          reachedRoute,
          isTrue,
          reason: 'Should land on the new-note editor',
        );

        final badgeShown = await waitForWidget(
          tester,
          find.descendant(
            of: find.byType(NoteAddScreen),
            matching: find.text(homework.title),
          ),
          timeout: config.apiTimeout,
        );
        expect(
          badgeShown,
          isTrue,
          reason: 'Linked-entity badge should show "${homework.title}"',
        );

        await closePageDialog(
          tester,
          shellPath: AppRoute.notebookScreen,
          shellTitle: 'Notebook',
        );
      },
    );

    namedTestWidgets(
      '4. Navigating away from an untouched linked note does not prompt to discard',
      (tester) async {
        if (!await loginForDeepLink(tester)) return;

        final homework = await apiHelper.findHomeworkByTitle('Quiz 4');
        expect(
          homework,
          isNotNull,
          reason: 'Example schedule should contain Quiz 4',
        );

        router.go(
          '${AppRoute.notebookScreen}/new?${DeepLinkParam.linkHomeworkId}=${homework!.id}',
        );
        final badgeShown = await waitForWidget(
          tester,
          find.descendant(
            of: find.byType(NoteAddScreen),
            matching: find.text(homework.title),
          ),
          timeout: config.apiTimeout,
        );
        expect(badgeShown, isTrue, reason: 'Linked note editor should open');

        _log.info('Navigating away via URL without editing ...');
        router.go(AppRoute.notebookScreen);
        final backOnNotebook = await waitForRoute(
          tester,
          AppRoute.notebookScreen,
          browserTitle: 'Notebook',
          timeout: const Duration(seconds: 5),
        );

        final promptShown = find.text('Unsaved Changes').evaluate().isNotEmpty;
        if (promptShown) {
          await tester.tap(find.text('Discard'));
          await tester.pumpAndSettle();
        }
        expect(
          promptShown,
          isFalse,
          reason:
              'An untouched new note has nothing to discard, so URL '
              'navigation should not prompt (parity with the header X)',
        );
        expect(
          backOnNotebook,
          isTrue,
          reason:
              'URL navigation should leave the untouched note and land on '
              '${AppRoute.notebookScreen}',
        );
      },
    );
  });
}
