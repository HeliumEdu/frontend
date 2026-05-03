// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_screen.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'helpers/api_helper.dart';
import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('external_calendar_test');

// Team-hosted ICS feed; contents are stable across runs and anchor the
// Oct 15 2023 timed-event assertion below.
const _testCalendarTitle = 'Helium Test Calendar';
const _testCalendarUrl =
    'https://calendar.google.com/calendar/ical/86c55b7d91f8d4c22ca722fe22ee19779774863c6e31b6b23346e475c44a23ad%40group.calendar.google.com/public/basic.ics';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = TestConfig();
  initializeTestLogging(
    environment: config.environment,
    apiHost: config.projectApiHost,
  );

  group('External Calendar Tests', () {
    final testEmail = config.testEmail;
    final testPassword = config.testPassword;
    final apiHelper = ApiHelper();

    bool canProceed = false;
    int? externalCalendarId;

    setUpAll(() async {
      await startSuite('External Calendar Tests');
      _log.info('Test email: $testEmail');

      final userExists = await apiHelper.userExists(testEmail);
      if (!userExists) {
        _log.warning('Test user does not exist. Run signup_user_test first.');
        canProceed = false;
        return;
      }
      canProceed = true;

      _log.info('Creating $_testCalendarTitle via API ...');
      externalCalendarId = await apiHelper.createExternalCalendar(
        title: _testCalendarTitle,
        url: _testCalendarUrl,
      );
      expect(
        externalCalendarId,
        isNotNull,
        reason: 'External calendar should be created',
      );
    });

    tearDownAll(() async {
      if (externalCalendarId != null) {
        _log.info('Deleting external calendar #$externalCalendarId ...');
        await apiHelper.deleteExternalCalendar(externalCalendarId!);
      }
      await endSuite();
    });

    namedTestWidgets(
      '1. External calendar events render and are filterable by Type',
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

        _log.info('Navigating to test calendar month (2023-10-15) ...');
        router.go(
          '${AppRoute.plannerScreen}?${DeepLinkParam.date}=2023-10-15',
        );
        await tester.pumpAndSettle();

        // External-calendar items render in the parent calendar's color
        // without the hub icon (icon only appears in the tooltip), so match
        // by title.
        const knownEventTitle = 'Some Timed Event at 9am CT Inside DST';
        final externalEvent = findRichTextContaining(knownEventTitle);

        _log.info('Waiting for external calendar event to render ...');
        final eventAppeared = await waitForWidget(
          tester,
          externalEvent,
          timeout: config.apiTimeout,
        );
        expect(
          eventAppeared,
          isTrue,
          reason:
              'External calendar event "$knownEventTitle" should render after '
              'the calendar is added',
        );

        _log.info('Filtering to Assignments only ...');
        final filterButton = find.byKey(
          const Key(PlannerScreen.filterButtonKey),
        );
        await tester.tap(filterButton);
        await waitForWidget(
          tester,
          find.byType(CheckboxListTile),
          timeout: const Duration(seconds: 5),
        );

        final assignmentsTile = find.ancestor(
          of: find.text(PlannerFilterType.assignments.value),
          matching: find.byType(CheckboxListTile),
        );
        await tester.ensureVisible(assignmentsTile);
        await tester.pumpAndSettle();
        await tester.tap(assignmentsTile);
        await tester.pumpAndSettle();

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(
          externalEvent,
          findsNothing,
          reason:
              'External calendar event should disappear after filtering to '
              'Assignments only',
        );
      },
    );
  });
}
