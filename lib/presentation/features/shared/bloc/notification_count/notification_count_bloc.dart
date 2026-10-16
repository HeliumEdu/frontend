import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/fcm_service.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/domain/repositories/reminder_repository.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/notification_count/notification_count_event.dart';
import 'package:heliumapp/presentation/features/shared/bloc/notification_count/notification_count_state.dart';
import 'package:heliumapp/utils/error_helpers.dart';
import 'package:heliumapp/utils/sort_helpers.dart';
import 'package:logging/logging.dart';

final _log = Logger('presentation.bloc');

class NotificationCountBloc
    extends Bloc<NotificationCountEvent, NotificationCountState> {
  static const int _pushType = 3;

  final ReminderRepository reminderRepository;
  final FcmService fcmService;

  /// Stops a refresh started under a previous session landing after a reset
  /// and repopulating the set with the signed-out user's reminders.
  int _generation = 0;

  NotificationCountBloc({
    required this.reminderRepository,
    required this.fcmService,
  }) : super(NotificationCountState(origin: EventOrigin.bloc)) {
    fcmService.addReminderReceivedListener(_onReminderReceived);
    fcmService.addReminderDismissedListener(_onReminderDismissed);

    on<RefreshNotificationCountEvent>(_onRefresh);
    on<SetActiveRemindersEvent>(_onSetActive);
    on<UpsertReminderEvent>(_onUpsert);
    on<RemoveReminderEvent>(_onRemove);
    on<RemoveRemindersWhereEvent>(_onRemoveWhere);
    on<ClearRemindersEvent>(_onClear);
    on<ResetNotificationCountEvent>(_onReset);
  }

  @override
  Future<void> close() {
    fcmService.removeReminderReceivedListener(_onReminderReceived);
    fcmService.removeReminderDismissedListener(_onReminderDismissed);
    return super.close();
  }

  void _onReminderReceived(ReminderModel reminder) =>
      add(UpsertReminderEvent(origin: EventOrigin.bloc, reminder: reminder));

  void _onReminderDismissed(int reminderId) =>
      add(RemoveReminderEvent(origin: EventOrigin.bloc, reminderId: reminderId));

  /// Both queries share one predicate, and `start_of_range__lte` excludes nulls,
  /// so the count can never include a row the screen would drop.
  Future<void> _onRefresh(
    RefreshNotificationCountEvent event,
    Emitter<NotificationCountState> emit,
  ) async {
    final generation = _generation;
    try {
      final total = await reminderRepository.getRemindersCount(
        sent: true,
        dismissed: false,
        type: _pushType,
        startOfRange: DateTime.now(),
      );

      if (generation != _generation) return;

      _setCount(total, event.origin, emit);
    } catch (e, s) {
      _log.warning('Failed to refresh notification count', e, s);
    }
  }

  /// A total that disagrees with the list means the list is stale, so it is
  /// dropped and the screen refetches on open.
  void _setCount(
    int total,
    EventOrigin origin,
    Emitter<NotificationCountState> emit,
  ) {
    if (state.hasLoaded && total != state.active.length) {
      emit(
        NotificationCountState(
          origin: origin,
          count: total,
          isStale: state.isStale,
        ),
      );
    } else if (total != state.count) {
      emit(
        NotificationCountState(
          origin: origin,
          active: state.active,
          count: total,
          hasLoaded: state.hasLoaded,
          isStale: state.isStale,
        ),
      );
    }
  }

  /// Reminders with no `startOfRange` can be neither ordered nor rendered and
  /// are dropped here, so the count matches the rows that will be shown.
  void _onSetActive(
    SetActiveRemindersEvent event,
    Emitter<NotificationCountState> emit,
  ) {
    final usable = <ReminderModel>[];
    for (final reminder in event.reminders) {
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
    _emitActive(emit, event.origin, usable, hasLoaded: true, isStale: false);
  }

  /// Keyed by id, so a redelivery cannot count the same reminder twice. With no
  /// list to key against there is nothing to dedupe by, and delivery is
  /// at-least-once, so the count is refetched rather than guessed at.
  void _onUpsert(
    UpsertReminderEvent event,
    Emitter<NotificationCountState> emit,
  ) {
    final reminder = event.reminder;
    if (reminder.startOfRange == null) return;

    if (!state.hasLoaded) {
      add(RefreshNotificationCountEvent(origin: event.origin));
      return;
    }

    final next = List<ReminderModel>.of(state.active)
      ..removeWhere((existing) => existing.id == reminder.id)
      ..add(reminder);

    Sort.byStartOfRange(next);
    _emitActive(emit, event.origin, next, hasLoaded: true, isStale: true);
  }

  void _onRemove(
    RemoveReminderEvent event,
    Emitter<NotificationCountState> emit,
  ) {
    if (!state.hasLoaded) {
      add(RefreshNotificationCountEvent(origin: event.origin));
      return;
    }
    _removeWhere(
      (reminder) => reminder.id == event.reminderId,
      event.origin,
      emit,
    );
  }

  void _onRemoveWhere(
    RemoveRemindersWhereEvent event,
    Emitter<NotificationCountState> emit,
  ) {
    if (!state.hasLoaded) return;
    _removeWhere(event.test, event.origin, emit);
  }

  void _removeWhere(
    bool Function(ReminderModel reminder) test,
    EventOrigin origin,
    Emitter<NotificationCountState> emit,
  ) {
    final next = List<ReminderModel>.of(state.active)..removeWhere(test);
    if (next.length != state.active.length) {
      _emitActive(
        emit,
        origin,
        next,
        hasLoaded: state.hasLoaded,
        isStale: state.isStale,
      );
    }
  }

  void _onClear(
    ClearRemindersEvent event,
    Emitter<NotificationCountState> emit,
  ) {
    _emitActive(emit, event.origin, const [], hasLoaded: true, isStale: false);
  }

  /// Drops the set back to never-loaded, so the next screen open refetches.
  void _onReset(
    ResetNotificationCountEvent event,
    Emitter<NotificationCountState> emit,
  ) {
    _generation++;
    emit(NotificationCountState(origin: event.origin));
  }

  void _emitActive(
    Emitter<NotificationCountState> emit,
    EventOrigin origin,
    List<ReminderModel> active, {
    required bool hasLoaded,
    required bool isStale,
  }) {
    emit(
      NotificationCountState(
        origin: origin,
        active: List<ReminderModel>.unmodifiable(active),
        count: active.length,
        hasLoaded: hasLoaded,
        isStale: isStale,
      ),
    );
  }
}
