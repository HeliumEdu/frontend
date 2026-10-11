import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/presentation/features/notebook/views/note_add_screen.dart';
import 'package:heliumapp/presentation/features/planner/controllers/planner_item_form_controller.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_item_add_screen.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'helpers/api_helper.dart';
import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('concurrency_test');

const _conflictTitle = 'Changed on Another Device';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = TestConfig();
  initializeTestLogging(
    environment: config.environment,
    apiHost: config.projectApiHost,
  );

  group('Concurrency Tests', () {
    final apiHelper = ApiHelper();
    bool canProceed = false;

    setUpAll(() async {
      await startSuite('Concurrency Tests');
      canProceed = await apiHelper.userExists(config.testEmail);
    });

    tearDownAll(() async {
      await endSuite();
    });

    Future<bool> login(WidgetTester tester) async {
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
      '1. Saving an assignment changed on another device prompts, and both choices resolve it',
      (tester) async {
        if (!await login(tester)) return;

        final homework = await apiHelper.findHomeworkByTitle('Quiz 4');
        expect(homework, isNotNull, reason: 'A kept Quiz 4 should exist');
        final originalTitle = homework!.title;

        Future<void> changeElsewhere(int priority) async {
          final changed = await apiHelper.updateHomework(
            groupId: homework.courseGroup,
            courseId: homework.course.id,
            homeworkId: homework.id,
            request: HomeworkRequestModel(priority: priority),
          );
          expect(changed, isTrue, reason: 'The other device\'s change should save');
        }

        Future<void> openEditor() async {
          router.go(
            '${AppRoute.plannerScreen}/$plannerItemHomeworkPath/${homework.id}/${plannerItemDialogSteps.first}',
          );
          final opened = await waitForWidget(
            tester,
            find.byKey(const Key(PlannerItemFormController.titleField)),
            timeout: config.apiTimeout,
          );
          expect(opened, isTrue, reason: 'The assignment editor should open');
        }

        Future<void> saveWithTitle(String title) async {
          await enterTextInField(
            tester,
            find.byKey(const Key(PlannerItemFormController.titleField)),
            title,
          );
          await tester.tap(find.byKey(const Key(PageHeader.saveButtonKey)));
          await tester.pumpAndSettle();
          final prompted = await waitForWidget(
            tester,
            find.text(_conflictTitle),
            timeout: config.apiTimeout,
          );
          expect(
            prompted,
            isTrue,
            reason: 'A stale save should ask how to resolve it',
          );
        }

        _log.info('Load Latest discards this device\'s edit ...');
        await openEditor();
        await changeElsewhere(10);
        await saveWithTitle('$originalTitle (stale)');
        await tester.tap(find.text('Load Latest'));
        await tester.pumpAndSettle();
        final reloaded = await waitForWidget(
          tester,
          find.descendant(
            of: find.byKey(const Key(PlannerItemFormController.titleField)),
            matching: find.text(originalTitle),
          ),
          timeout: config.apiTimeout,
        );
        expect(
          reloaded,
          isTrue,
          reason: 'Load Latest should refill the form with the saved title',
        );

        _log.info('Overwrite saves this device\'s edit ...');
        await changeElsewhere(90);
        await saveWithTitle('$originalTitle (mine)');
        await tester.tap(find.text('Overwrite'));
        await tester.pumpAndSettle();
        final closed = await waitForWidgetToDisappear(
          tester,
          find.byType(PlannerItemAddScreen),
          timeout: config.apiTimeout,
        );
        expect(closed, isTrue, reason: 'The editor should close after saving');
        final saved = await apiHelper.findHomeworkByTitle('$originalTitle (mine)');
        expect(saved, isNotNull, reason: 'Overwrite should save this device\'s title');

        await apiHelper.updateHomework(
          groupId: homework.courseGroup,
          courseId: homework.course.id,
          homeworkId: homework.id,
          request: HomeworkRequestModel(title: originalTitle),
        );
      },
    );

    namedTestWidgets(
      '2. A note changed on another device keeps this device\'s text as a copy on Load Latest',
      (tester) async {
        if (!await login(tester)) return;

        final note = await apiHelper.createNote(
          NoteRequestModel(
            title: 'Concurrency Note',
            content: {
              'ops': [
                {'insert': 'Original\n'},
              ],
            },
          ),
        );
        expect(note, isNotNull, reason: 'The note should be created');

        router.go('${AppRoute.notebookScreen}/${note!.id}');
        final titleField = find
            .descendant(
              of: find.byType(NoteAddScreen),
              matching: find.byType(TextField),
            )
            .first;
        final opened = await waitForWidget(
          tester,
          find.descendant(
            of: find.byType(NoteAddScreen),
            matching: find.text('Concurrency Note'),
          ),
          timeout: config.apiTimeout,
        );
        expect(opened, isTrue, reason: 'The note editor should open');

        // The other device saves first, then this one edits right away: well
        // inside the 30s auto-pull interval, so the editor still holds the
        // version it opened with when its autosave runs.
        _log.info('Another device saves, then this one edits ...');
        final changed = await apiHelper.updateNote(
          note.id,
          NoteRequestModel(title: 'Concurrency Note (theirs)'),
        );
        expect(changed, isTrue, reason: 'The other device\'s change should save');
        await enterTextInField(tester, titleField, 'Concurrency Note (mine)');

        final prompted = await waitForWidget(
          tester,
          find.text(_conflictTitle),
          timeout: config.apiTimeout,
        );
        expect(prompted, isTrue, reason: 'The stale autosave should prompt');

        await tester.tap(find.text('Load Latest'));
        await tester.pumpAndSettle();
        final loaded = await waitForWidget(
          tester,
          find.descendant(
            of: find.byType(NoteAddScreen),
            matching: find.text('Concurrency Note (theirs)'),
          ),
          timeout: config.apiTimeout,
        );
        expect(loaded, isTrue, reason: 'The editor should show the other version');

        final notes = (await apiHelper.getNotes())!;
        final copies = notes.where(
          (n) => n.title == 'Concurrency Note (mine) (copy from this device)',
        );
        expect(
          copies,
          hasLength(1),
          reason: 'This device\'s text should be kept as a separate note',
        );

        await closePageDialog(
          tester,
          shellPath: AppRoute.notebookScreen,
          shellTitle: 'Notebook',
        );
        await apiHelper.deleteNote(note.id);
        await apiHelper.deleteNote(copies.single.id);
      },
    );
  });
}
