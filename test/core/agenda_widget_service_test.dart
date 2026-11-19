import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/agenda_widget_service.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../helpers/planner_helper.dart';
import '../mocks/mock_models.dart';

void main() {
  tz_data.initializeTimeZones();

  final now = DateTime.utc(2026, 11, 18, 12);

  HomeworkModel givenHomework(int id, String start, {bool allDay = false, String? rule, int category = 1}) {
    final end = DateTime.parse(start).add(const Duration(hours: 1)).toUtc().toIso8601String();
    return HomeworkModel.fromJson(givenHomeworkJson(
        id: id, title: 'Homework $id', start: start, end: end, allDay: allDay, recurrenceRule: rule,
        category: category));
  }

  Map<String, dynamic> buildAt({
    List<HomeworkModel> homeworks = const [],
    bool colorByCategory = false,
  }) {
    return AgendaWidgetService.buildSnapshot(
      homeworks: homeworks,
      courses: [MockModels.createCourse(id: 1, title: 'Calculus', color: const Color(0xFF4986E7))],
      categories: [MockModels.createCategory(id: 1, color: const Color(0xFFE21D55))],
      settings: MockModels.createUserSettings(
        timeZone: 'Europe/Amsterdam',
        eventsColor: const Color(0xFF4CAF50),
        colorByCategory: colorByCategory,
      ),
      now: now,
    );
  }

  List<Map<String, dynamic>> itemsOf(Map<String, dynamic> snapshot) =>
      (snapshot['items'] as List).cast<Map<String, dynamic>>();

  group('AgendaWidgetService.buildSnapshot', () {
    test('describes a signed-in snapshot in the user zone', () {
      // WHEN
      final snapshot = buildAt(homeworks: [givenHomework(1, '2026-11-20T15:00:00Z')]);

      // THEN
      expect(snapshot['version'], 1);
      expect(snapshot['signedIn'], isTrue);
      expect(snapshot['timeZone'], 'Europe/Amsterdam');
      expect(snapshot['generatedAt'], '2026-11-18T12:00:00.000Z');
    });

    test('writes an assignment with its class, color, labels and deep link', () {
      // WHEN
      final item = itemsOf(buildAt(homeworks: [givenHomework(12, '2026-11-20T15:00:00Z')])).single;

      // THEN
      expect(item['key'], 'homework:12');
      expect(item['courseGroupId'], 1);
      expect(item['courseId'], 1);
      expect(item['className'], 'Calculus');
      expect(item['color'], '#4986e7');
      expect(item['day'], '2026-11-20');
      expect(item['timeLabel'], '4 PM', reason: '15:00 UTC is 4 PM in Amsterdam');
      expect(item['repeating'], isFalse);
      expect(item['url'], 'heliumwidget://open/planner/assignment/12/details');
    });

    test('uses the category color when the user colors by category', () {
      // WHEN
      final item = itemsOf(buildAt(homeworks: [givenHomework(12, '2026-11-20T15:00:00Z')], colorByCategory: true)).single;

      // THEN
      expect(item['color'], '#e21d55');
    });

    test('labels an all-day assignment and days beyond the week', () {
      // WHEN
      final items = itemsOf(buildAt(homeworks: [
        givenHomework(1, '2026-11-18T23:00:00Z', allDay: true),
        givenHomework(2, '2026-11-25T15:00:00Z'),
      ]));

      // THEN
      expect(items[0]['timeLabel'], 'All day');
      expect(items[0]['day'], '2026-11-19', reason: 'midnight Nov 19 in Amsterdam');
      expect(items[1]['day'], '2026-11-25');
    });

    test('names every day the widgets may label, in the app\'s formats', () {
      // WHEN
      final days = buildAt()['days'] as Map<String, dynamic>;

      // THEN
      expect(days.keys.first, '2026-11-11', reason: 'the oldest overdue day');
      expect(days.keys.last, '2026-12-02', reason: 'two weeks out, so a stale snapshot still names today');
      expect(days['2026-11-18'], {'weekday': 'Wednesday', 'date': 'Wed, Nov 18'});
      expect(days['2026-11-20'], {'weekday': 'Friday', 'date': 'Fri, Nov 20'});
    });

    test('keys each repeating occurrence by its start', () {
      // WHEN
      final items = itemsOf(buildAt(homeworks: [givenHomework(3, '2026-11-16T15:00:00Z', rule: 'FREQ=WEEKLY;BYDAY=MO')]));

      // THEN
      expect(items.map((item) => item['key']), [
        'homework:3:2026-11-16T15:00:00.000Z',
        'homework:3:2026-11-23T15:00:00.000Z',
      ], reason: 'Nov 30 is past the next 7 days');
      expect(items.every((item) => item['repeating'] == true), isTrue);
    });

    test('keeps the 3 most recent overdue, all of today and 20 more, counting the rest as older', () {
      // WHEN
      final snapshot = buildAt(homeworks: [
        for (var i = 0; i < 8; i++) givenHomework(i + 1, '2026-11-1${i + 1}T08:00:00Z'),
        for (var i = 8; i < 33; i++) givenHomework(i + 1, '2026-11-18T20:00:00Z'),
        for (var i = 33; i < 58; i++) givenHomework(i + 1, '2026-11-20T15:00:00Z'),
      ]);

      // THEN
      final items = itemsOf(snapshot);
      expect(items.where((item) => item['day'].compareTo('2026-11-18') < 0).map((item) => item['id']), [6, 7],
          reason: 'the 3 most recent overdue in due order; Nov 18 at 9 AM is the third');
      expect(items.where((item) => item['day'] == '2026-11-18').length, 26, reason: 'everything due today stays');
      expect(items.where((item) => item['day'] == '2026-11-20').length, 20);
      expect(snapshot['olderOverdueCount'], 5);
    });
  });
}
