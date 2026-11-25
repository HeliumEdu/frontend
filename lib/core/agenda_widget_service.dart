import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/core/log_service.dart';
import 'package:heliumapp/core/sentry_service.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_group_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:heliumapp/data/repositories/category_repository_impl.dart';
import 'package:heliumapp/data/repositories/course_repository_impl.dart';
import 'package:heliumapp/data/repositories/homework_repository_impl.dart';
import 'package:heliumapp/data/sources/category_remote_data_source.dart';
import 'package:heliumapp/data/sources/course_remote_data_source.dart';
import 'package:heliumapp/data/sources/homework_remote_data_source.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/color_helpers.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:home_widget/home_widget.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart' as tz;

final _log = Logger('core.agenda_widget');

/// Keeps the home and lock screen Agenda widget's snapshot current. The widget only draws what the app writes here;
/// it never calls the API itself.
class AgendaWidgetService {
  static const appGroupId = 'group.com.heliumedu.heliumapp';
  static const _urlScheme = 'heliumwidget';
  static const _snapshotKey = 'agenda_snapshot';
  static const _changedKey = 'agenda_widget_changed';
  static const _iosName = 'HeliumAgendaWidget';
  static const _androidName = 'com.heliumedu.heliumapp.widget.AgendaWidgetReceiver';
  static const _refreshDelay = Duration(seconds: 2);
  static const _windowDays = 7;
  static const _maxOverdue = 3;
  static const _maxAfterToday = 20;

  Timer? _refreshTimer;

  static final AgendaWidgetService _instance = AgendaWidgetService._internal();

  factory AgendaWidgetService() => _instance;

  AgendaWidgetService._internal();

  static bool get _isSupported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<void> init() async {
    if (!_isSupported) return;

    await HomeWidget.setAppGroupId(appGroupId);
    await HomeWidget.registerInteractivityCallback(agendaWidgetInteraction);
    await HomeWidget.saveWidgetData<bool>(_changedKey, false);
    DioClient().cacheService.addQuickResumeListener(_onResume);
    AppLifecycleListener(onHide: _refreshNowIfPending);
  }

  void scheduleRefresh() {
    if (!_isSupported) return;

    _refreshTimer?.cancel();
    _refreshTimer = Timer(_refreshDelay, () => unawaited(refresh()));
  }

  Future<void> refresh() async {
    if (!_isSupported) return;

    final dioClient = DioClient();
    try {
      if (!await dioClient.isAuthenticated()) return;

      final settings = await dioClient.getSettings();
      if (settings == null || settings.setupState != SetupState.complete) return;

      final now = DateTime.now();
      final today = HeliumDateTime.midnightIn(now, settings.timeZone);
      final courseRepository = CourseRepositoryImpl(remoteDataSource: CourseRemoteDataSourceImpl(dioClient: dioClient));
      final from = _olderOverdueFrom(
        await courseRepository.getCourseGroups(shownOnCalendar: true),
        HeliumDateTime.addDays(today, -_windowDays),
        settings.timeZone,
      );
      final to = HeliumDateTime.addDays(today, _windowDays + 1);

      final results = await Future.wait([
        HomeworkRepositoryImpl(remoteDataSource: HomeworkRemoteDataSourceImpl(dioClient: dioClient))
            .getHomeworks(from: from, to: to, shownOnCalendar: true),
        courseRepository.getCourses(shownOnCalendar: true),
        if (settings.colorByCategory)
          CategoryRepositoryImpl(remoteDataSource: CategoryRemoteDataSourceImpl(dioClient: dioClient))
              .getCategories(shownOnCalendar: true),
      ]);

      final snapshot = buildSnapshot(
        homeworks: results[0] as List<HomeworkModel>,
        courses: results[1] as List<CourseModel>,
        categories: settings.colorByCategory ? results[2] as List<CategoryModel> : const [],
        settings: settings,
        now: now,
      );
      if (!await dioClient.isAuthenticated()) return;
      await _writeSnapshot(snapshot);
      if ((await HomeWidget.getInstalledWidgets()).isNotEmpty) {
        unawaited(
          AnalyticsService().setUserProperty(name: 'uses_agenda_widget', value: 'true'),
        );
      }
    } on HeliumException catch (e, s) {
      _log.warning('Agenda widget refresh failed', e, s);
    }
  }

  /// Signs the widget out.
  Future<void> clear() async {
    if (!_isSupported) return;

    _refreshTimer?.cancel();
    await _writeSnapshot({
      'version': 1,
      'signedIn': false,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'timeZone': 'UTC',
      'olderOverdueCount': 0,
      'days': const {},
      'items': const [],
    });
  }

  @visibleForTesting
  static Map<String, dynamic> buildSnapshot({
    required List<HomeworkModel> homeworks,
    required List<CourseModel> courses,
    required List<CategoryModel> categories,
    required UserSettingsModel settings,
    required DateTime now,
  }) {
    final timeZone = settings.timeZone;
    final agenda = PlannerHelper.agendaItems(
      homeworks: homeworks,
      timeZone: timeZone,
      now: now,
      daysBack: _windowDays,
      daysAhead: _windowDays,
    );
    final today = HeliumDateTime.midnightIn(now, timeZone);
    final tomorrow = HeliumDateTime.addDays(today, 1);
    final overdue = <HomeworkModel>[];
    final dueToday = <HomeworkModel>[];
    final afterToday = <HomeworkModel>[];
    for (final item in agenda.items) {
      if (PlannerHelper.isOverdue(completed: item.completed, start: item.start, now: now)) {
        overdue.add(item);
      } else if (item.start.isBefore(tomorrow)) {
        dueToday.add(item);
      } else {
        afterToday.add(item);
      }
    }
    final shownOverdue = overdue.skip(max(0, overdue.length - _maxOverdue)).toList();
    final olderOverdueCount = agenda.olderOverdueCount + overdue.length - shownOverdue.length;
    final items = [...shownOverdue, ...dueToday, ...afterToday.take(_maxAfterToday)];
    final coursesById = {for (final course in courses) course.id: course};
    final categoriesById = {for (final category in categories) category.id: category};

    return {
      'version': 1,
      'signedIn': true,
      'generatedAt': now.toUtc().toIso8601String(),
      'timeZone': timeZone.name,
      'olderOverdueCount': olderOverdueCount,
      'days': _days(today),
      'items': [
        for (final item in items) _itemJson(item, coursesById, categoriesById, settings),
      ],
    };
  }

  /// The start of the Todos window (the user's visible terms), or [overdueFrom] when that is earlier or there are
  /// none.
  static DateTime _olderOverdueFrom(
    List<CourseGroupModel> courseGroups,
    DateTime overdueFrom,
    tz.Location timeZone,
  ) {
    final window = PlannerHelper.courseGroupDateWindow(courseGroups);
    if (window == null) return overdueFrom;
    final (windowFrom, _) = HeliumDateTime.dayRangeIn(window.from, window.to, timeZone);
    return windowFrom.isBefore(overdueFrom) ? windowFrom : overdueFrom;
  }

  /// Each day's names, formatted the way the app formats them, for the widgets to label by day without formatting
  /// dates themselves: from the oldest overdue day through two weeks out, so a stale snapshot still names today.
  static Map<String, Map<String, String>> _days(tz.TZDateTime today) => {
        for (var offset = -_windowDays; offset <= _windowDays * 2; offset++)
          HeliumDateTime.formatDateForApi(HeliumDateTime.addDays(today, offset)): {
            'weekday': HeliumDateTime.formatDayName(HeliumDateTime.addDays(today, offset)),
            'date': HeliumDateTime.formatDateForTodos(HeliumDateTime.addDays(today, offset)),
          },
      };

  static Map<String, dynamic> _itemJson(
    HomeworkModel item,
    Map<int, CourseModel> coursesById,
    Map<int, CategoryModel> categoriesById,
    UserSettingsModel settings,
  ) {
    final localStart = tz.TZDateTime.from(item.start, settings.timeZone);
    final repeating = PlannerHelper.isRepeatingItem(item);
    final course = coursesById[item.course.id];

    return {
      'key': repeating ? 'homework:${item.id}:${item.start.toUtc().toIso8601String()}' : 'homework:${item.id}',
      'id': item.id,
      'courseGroupId': item.courseGroup,
      'courseId': item.course.id,
      'title': item.title,
      'start': item.start.toUtc().toIso8601String(),
      'end': item.end.toUtc().toIso8601String(),
      'allDay': item.allDay,
      'day': HeliumDateTime.formatDateForApi(localStart),
      'timeLabel': item.allDay ? 'All day' : HeliumDateTime.formatTime(localStart),
      'className': course?.title,
      'color': HeliumColors.colorToHex(
        PlannerHelper.itemColor(item, settings, course: course, category: categoriesById[item.category.id]),
      ),
      'completed': item.completed,
      'repeating': repeating,
      'url': '$_urlScheme://open${reminderEntityRoute(homeworkId: item.id)!}',
    };
  }

  void _refreshNowIfPending() {
    if (_refreshTimer?.isActive != true) return;
    _refreshTimer!.cancel();
    unawaited(refresh());
  }

  Future<void> _onResume() async {
    scheduleRefresh();
    if (await HomeWidget.getWidgetData<bool>(_changedKey) != true) return;

    await HomeWidget.saveWidgetData<bool>(_changedKey, false);
    await DioClient().cacheService.reloadAfterExternalChange();
  }
}

final _widgetTaps = <String, int>{};
final _completingOccurrences = <String>{};

/// Saves a widget checkbox tap from a background engine, the way the Planner's own checkbox does: the widget has
/// already drawn and stored the new state, so rapid taps on one assignment settle into a single save of the latest
/// state, and a failed save puts the box back unless a newer tap followed. A repeating occurrence completes once and
/// can't be unchecked.
@pragma('vm:entry-point')
Future<void> agendaWidgetInteraction(Uri? uri) async {
  if (uri == null || uri.host != 'complete') return;

  final key = uri.queryParameters['key'];
  final completed = uri.queryParameters['completed'] == 'true';
  if (key == null) return;

  WidgetsFlutterBinding.ensureInitialized();
  LogService().init();
  await SentryService().runInBackground(() => _completeFromWidget(key, completed));
}

Future<void> _completeFromWidget(String key, bool completed) async {
  tz_data.initializeTimeZones();
  await HomeWidget.setAppGroupId(AgendaWidgetService.appGroupId);
  await PrefService().init();
  if (!await DioClient().isAuthenticated()) return;

  final item = await _storedItem(key);
  if (item == null) return;

  if (item['repeating'] == true) {
    if (!completed || !_completingOccurrences.add(key)) return;
    try {
      await _saveCompletion(item, true);
    } on HeliumException catch (e, s) {
      _log.warning('Widget completion of homework ${item['id']} occurrence failed', e, s);
      await _setStoredCompleted(key, false);
    } finally {
      _completingOccurrences.remove(key);
    }
    return;
  }

  final tap = _widgetTaps.update(key, (taps) => taps + 1, ifAbsent: () => 1);
  await Future<void>.delayed(AppConstants.completionToggleDebounce);
  if (_widgetTaps[key] != tap) return;

  final latest = await _storedItem(key);
  if (latest == null) return;
  final latestCompleted = latest['completed'] as bool;
  try {
    await _saveCompletion(latest, latestCompleted);
  } on HeliumException catch (e, s) {
    _log.warning('Widget completion of homework ${latest['id']} failed', e, s);
    if (_widgetTaps[key] == tap) await _setStoredCompleted(key, !latestCompleted);
  } finally {
    if (_widgetTaps[key] == tap) _widgetTaps.remove(key);
  }
}

Future<void> _saveCompletion(Map<String, dynamic> item, bool completed) async {
  final occurrenceStart = item['repeating'] == true ? DateTime.parse(item['start'] as String) : null;
  await HomeworkRepositoryImpl(remoteDataSource: HomeworkRemoteDataSourceImpl(dioClient: DioClient())).updateHomework(
    groupId: item['courseGroupId'] as int,
    courseId: item['courseId'] as int,
    homeworkId: item['id'] as int,
    request: HomeworkRequestModel(completed: completed),
    occurrenceStart: occurrenceStart,
    onlyThisOccurrence: occurrenceStart != null,
  );
  await HomeWidget.saveWidgetData<bool>(AgendaWidgetService._changedKey, true);
  _log.info('Homework ${item['id']} completion set to $completed from the widget');
}

Future<Map<String, dynamic>?> _storedItem(String key) async {
  final snapshotJson = await HomeWidget.getWidgetData<String>(AgendaWidgetService._snapshotKey);
  return snapshotJson == null ? null : _snapshotItem(jsonDecode(snapshotJson) as Map<String, dynamic>, key);
}

Future<void> _setStoredCompleted(String key, bool completed) async {
  final snapshotJson = await HomeWidget.getWidgetData<String>(AgendaWidgetService._snapshotKey);
  if (snapshotJson == null) return;
  final snapshot = jsonDecode(snapshotJson) as Map<String, dynamic>;
  _snapshotItem(snapshot, key)?['completed'] = completed;
  await _writeSnapshot(snapshot);
}

Map<String, dynamic>? _snapshotItem(Map<String, dynamic> snapshot, String key) {
  for (final item in (snapshot['items'] as List<dynamic>).cast<Map<String, dynamic>>()) {
    if (item['key'] == key) return item;
  }
  return null;
}

Future<void> _writeSnapshot(Map<String, dynamic> snapshot) async {
  await HomeWidget.saveWidgetData<String>(AgendaWidgetService._snapshotKey, jsonEncode(snapshot));
  await HomeWidget.updateWidget(
    iOSName: AgendaWidgetService._iosName,
    qualifiedAndroidName: AgendaWidgetService._androidName,
  );
}
