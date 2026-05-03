// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'helpers/api_helper.dart';
import 'helpers/planner_count_helper.dart';
import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('tooltip_test');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = TestConfig();
  initializeTestLogging(
    environment: config.environment,
    apiHost: config.projectApiHost,
  );

  group('Tooltip Tests', () {
    final testEmail = config.testEmail;
    final testPassword = config.testPassword;
    final apiHelper = ApiHelper();

    bool canProceed = false;

    setUpAll(() async {
      await startSuite('Tooltip Tests');
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

    namedTestWidgets(
      '1. Calendar item tooltips show correct content',
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

        // The Tooltip widget wraps each calendar item; its richMessage is
        // built once by _buildPlannerItemTooltipMessage and is the same data
        // the user would see on hover. Inspecting it directly avoids the
        // hover-gesture timing complexity while still verifying real content.
        Tooltip tooltipFor(Finder itemFinder) {
          final wrappers = find
              .ancestor(of: itemFinder, matching: find.byType(Tooltip))
              .evaluate();
          expect(
            wrappers,
            isNotEmpty,
            reason:
                'Calendar item should be wrapped in a Tooltip — check that '
                'isTouchDevice is false and showPlannerTooltips is enabled',
          );
          return wrappers.first.widget as Tooltip;
        }

        // ---- Assignment tooltip (Quiz 3) ----
        _log.info('Verifying assignment tooltip ...');
        final quiz3Finder = findRichTextContaining('Quiz 3');
        final quiz3Visible = await waitForWidget(
          tester,
          quiz3Finder,
          timeout: config.apiTimeout,
        );
        expect(quiz3Visible, isTrue, reason: 'Quiz 3 should be visible');

        final quiz3Tooltip = tooltipFor(quiz3Finder.first);
        final quiz3Text = (quiz3Tooltip.richMessage as TextSpan).toPlainText();
        expect(quiz3Text, contains('Quiz 3'));

        // Both Programming and Psychology have a Quiz 3; whichever is on the
        // current month is what we hover. Identify which course this is from
        // the tooltip content, then validate the rest against snapshot data.
        final quiz3Course = snap.courses.firstWhere(
          (c) => quiz3Text.contains(c.title),
          orElse: () => throw StateError(
            'Quiz 3 tooltip should mention a course title from snapshot',
          ),
        );
        final quiz3Homework = snap.homework.firstWhere(
          (h) => h.title == 'Quiz 3' && h.course.id == quiz3Course.id,
        );
        final quiz3Category = snap.categoriesById[quiz3Homework.category.id]!;
        expect(
          quiz3Text,
          contains(quiz3Category.title),
          reason: 'Assignment tooltip should include the category title',
        );
        if (GradeHelper.parseGrade(quiz3Homework.currentGrade) != null) {
          expect(
            quiz3Text,
            contains(GradeHelper.gradeForDisplay(quiz3Homework.currentGrade)),
            reason: 'Assignment tooltip should include the formatted grade',
          );
        }

        // ---- Event tooltip ----
        _log.info('Verifying event tooltip ...');
        const eventTitle = 'Final Portfolio Writing Workshop';
        final eventFinder = findRichTextContaining(eventTitle);
        final eventVisible = await waitForWidget(
          tester,
          eventFinder,
          timeout: config.apiTimeout,
        );
        expect(
          eventVisible,
          isTrue,
          reason: 'Event "$eventTitle" should be visible',
        );

        final eventTooltip = tooltipFor(eventFinder.first);
        final eventText = (eventTooltip.richMessage as TextSpan).toPlainText();
        expect(eventText, contains(eventTitle));
        expect(
          eventText,
          contains('Source: Events'),
          reason: 'Event tooltip should include the Events source label',
        );
        for (final c in snap.courses) {
          expect(
            eventText,
            isNot(contains(c.title)),
            reason: 'Event tooltip should not mention course "${c.title}"',
          );
        }

        // ---- Class tooltip ----
        _log.info('Verifying class tooltip ...');
        const psychTitle = 'Intro to Psychology 🧠';
        final psychFinder = findRichTextContaining(psychTitle);
        final psychVisible = await waitForWidget(
          tester,
          psychFinder,
          timeout: config.apiTimeout,
        );
        expect(
          psychVisible,
          isTrue,
          reason: 'Class "$psychTitle" should be visible',
        );

        final psychTooltip = tooltipFor(psychFinder.first);
        final psychText = (psychTooltip.richMessage as TextSpan).toPlainText();
        expect(psychText, contains(psychTitle));
        for (final cat in snap.categoriesById.values) {
          expect(
            psychText,
            isNot(contains(cat.title)),
            reason: 'Class tooltip should not mention category "${cat.title}"',
          );
        }
      },
    );
  });
}
