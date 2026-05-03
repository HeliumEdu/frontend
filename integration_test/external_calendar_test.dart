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
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'helpers/api_helper.dart';
import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('external_calendar_test');

// Hard-coded Helium Test Calendar — same URL the legacy cluster-tests used.
// Hosted by the team so its contents are stable across runs.
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

        // The Helium Test Calendar's events live in October 2023. Land on
        // that month via the new ?date= deep link.
        _log.info('Navigating to test calendar month (2023-10-15) ...');
        router.go(
          '${AppRoute.plannerScreen}?${DeepLinkParam.date}=2023-10-15',
        );
        await tester.pumpAndSettle();

        // External calendar events render with the hub icon (per
        // AppConstants.externalCalendarIcon). On the planner page, the hub
        // icon is unique to calendar-item rendering — neither the nav shell
        // nor the default toolbar uses it — so a count of hub icons is a
        // reliable proxy for "external events visible". The filter sheet
        // also uses the hub icon, but only while the sheet is open.
        final hubIcon = find.byIcon(AppConstants.externalCalendarIcon);

        _log.info('Waiting for external calendar events to render ...');
        final eventsAppeared = await waitForWidget(
          tester,
          hubIcon,
          timeout: config.apiTimeout,
        );
        expect(
          eventsAppeared,
          isTrue,
          reason:
              'At least one external calendar event should render after the '
              'calendar is added',
        );
        _log.info(
          'External events visible: ${hubIcon.evaluate().length} hub icons',
        );

        // Apply Assignments-only Type filter — mirrors the legacy assertion
        // of "filter to homework, external item disappears".
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

        // Close filter menu so its own hub icon (External Calendars filter
        // tile) is no longer in the tree, and so we're observing the
        // calendar-item count.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        final hubsAfterFilter = hubIcon.evaluate().length;
        expect(
          hubsAfterFilter,
          equals(0),
          reason:
              'No external calendar events should render after filtering to '
              'Assignments only — found $hubsAfterFilter',
        );
      },
    );
  });
}
