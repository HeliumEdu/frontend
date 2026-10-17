import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_state.dart';

/// The active (sent, undismissed push) reminders behind the notification bell.
///
/// While [active] is loaded, [count] is its length. While it is not, [count] is
/// the server's total for the identical predicate the screen lists by, so the
/// badge always matches what opening the bell will show, without paying for the
/// full list on every resume.
class NotificationCountState extends BaseState {
  /// Ordered as the notification screen renders it.
  final List<ReminderModel> active;
  final int count;
  final bool hasLoaded;

  /// Set when [active] holds a locally-added reminder rather than a server
  /// fetch, so the screen refetches and picks up its hydrated parent.
  final bool isStale;

  NotificationCountState({
    required super.origin,
    this.active = const [],
    this.count = 0,
    this.hasLoaded = false,
    this.isStale = false,
  });

  /// Whether [active] can be rendered without refetching. An empty set is a
  /// valid loaded state, so callers cannot infer this from the list itself.
  bool get isLoaded => hasLoaded && !isStale;
}
