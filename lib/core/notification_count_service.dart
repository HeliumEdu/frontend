import 'package:flutter/foundation.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/data/repositories/reminder_repository_impl.dart';
import 'package:heliumapp/data/sources/reminder_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/reminder_repository.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:logging/logging.dart';

final _log = Logger('core.notification_count');

/// The active (sent, undismissed push) reminders behind the notification bell.
///
/// While [active] is loaded, [count] is its length. While it is not, [count] is
/// the server's total for the identical predicate the screen lists by — so the
/// badge always matches what opening the bell will show, without paying for the
/// full list on every resume.
class NotificationCountService {
  static const int _pushType = 3;

  final ValueNotifier<List<ReminderModel>> _active =
      ValueNotifier<List<ReminderModel>>(const []);

  final ValueNotifier<int> _count = ValueNotifier<int>(0);

  /// Ordered as the notification screen renders it.
  ValueListenable<List<ReminderModel>> get active => _active;

  /// Read-only: a count that can be written from outside is a count that can
  /// drift from the list.
  ValueListenable<int> get count => _count;

  final ReminderRepository _reminderRepository;

  bool _loaded = false;

  /// Set when the list holds a locally-added reminder rather than a server
  /// fetch, so the screen refetches and picks up its hydrated parent.
  bool _stale = false;

  /// Stops a [refresh] started under a previous session landing after [reset]
  /// and repopulating the set with the signed-out user's reminders.
  int _generation = 0;

  static NotificationCountService _instance =
      NotificationCountService._internal();

  factory NotificationCountService() => _instance;

  NotificationCountService._internal()
    : _reminderRepository = ReminderRepositoryImpl(
        remoteDataSource: ReminderRemoteDataSourceImpl(dioClient: DioClient()),
      ) {
    _deriveCountFromActive();
  }

  @visibleForTesting
  NotificationCountService.forTesting({
    required ReminderRepository reminderRepository,
  }) : _reminderRepository = reminderRepository {
    _deriveCountFromActive();
  }

  @visibleForTesting
  static void resetForTesting() {
    _instance = NotificationCountService._internal();
  }

  @visibleForTesting
  static void setInstanceForTesting(NotificationCountService instance) {
    _instance = instance;
  }

  void _deriveCountFromActive() {
    _count.value = _active.value.length;
    _active.addListener(() => _count.value = _active.value.length);
  }

  /// Whether [active] can be rendered without refetching. An empty set is a
  /// valid loaded state, so callers cannot infer this from the list itself.
  bool get isLoaded => _loaded && !_stale;

  /// Refreshes the badge with a count-only query rather than the list, which
  /// carries the screen's nested homework/course/category payload and its
  /// prefetches. Both queries share one predicate, and `start_of_range__lte`
  /// excludes nulls, so the count can never include a row the screen would drop.
  Future<void> refresh() async {
    final generation = _generation;
    try {
      final total = await _reminderRepository.getRemindersCount(
        sent: true,
        dismissed: false,
        type: _pushType,
        startOfRange: DateTime.now(),
      );

      if (generation != _generation) return;

      _setCount(total);
    } catch (e, s) {
      _log.warning('Failed to refresh notification count', e, s);
    }
  }

  /// A total that disagrees with the list means the list is stale, so it is
  /// dropped and the screen refetches on open.
  void _setCount(int total) {
    if (_loaded && total != _active.value.length) {
      _loaded = false;
      _active.value = const [];
    }
    _count.value = total;
  }

  /// Replaces the active set from an authoritative fetch. Reminders with no
  /// `startOfRange` can be neither ordered nor rendered and are dropped here, so
  /// [count] matches the rows that will be shown.
  void setActive(List<ReminderModel> reminders) {
    final usable = <ReminderModel>[];
    for (final reminder in reminders) {
      if (reminder.startOfRange == null) {
        ErrorHelpers.logAndReport(
          'Skipping reminder ${reminder.id} with null startOfRange',
          Exception('Reminder ${reminder.id} has null startOfRange'),
          StackTrace.current,
        );
        continue;
      }
      usable.add(reminder);
    }

    Sort.byStartOfRange(usable);
    _loaded = true;
    _stale = false;
    _active.value = List<ReminderModel>.unmodifiable(usable);
  }

  /// Adds a pushed reminder, or replaces the copy already held. Keyed by id, so
  /// a redelivery cannot count the same reminder twice.
  void upsert(ReminderModel reminder) {
    if (reminder.startOfRange == null) return;

    if (!_loaded) {
      _count.value++;
      return;
    }

    final next = List<ReminderModel>.of(_active.value)
      ..removeWhere((existing) => existing.id == reminder.id)
      ..add(reminder);

    Sort.byStartOfRange(next);
    _stale = true;
    _active.value = List<ReminderModel>.unmodifiable(next);
  }

  void removeWhere(bool Function(ReminderModel) test) {
    if (!_loaded) return;

    final next = List<ReminderModel>.of(_active.value)..removeWhere(test);
    if (next.length != _active.value.length) {
      _active.value = List<ReminderModel>.unmodifiable(next);
    }
  }

  void remove(int reminderId) {
    if (!_loaded) {
      if (_count.value > 0) _count.value--;
      return;
    }
    removeWhere((reminder) => reminder.id == reminderId);
  }

  /// Empties the set as a known-current state (dismiss-all).
  void clear() {
    _loaded = true;
    _stale = false;
    _active.value = const [];
  }

  /// Drops the set back to never-loaded, so the next screen open refetches.
  void reset() {
    _generation++;
    _loaded = false;
    _stale = false;
    _active.value = const [];
  }
}
