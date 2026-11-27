import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';

/// Schedule-template presets, mirroring the backend `enums.SCHEDULE_TEMPLATES`
/// (WEEKLY = 0 is the non-rotating default). Custom is a frontend-only sentinel.
class ScheduleTemplate {
  ScheduleTemplate._();

  static const int abDay = 1;
  static const int sixDayCycle = 2;
  static const int eightDayCycle = 3;
  static const int weekAb = 4;
  static const int sevenDayCycle = 5;
  static const int tenDayCycle = 6;

  /// UI-only sentinel: a Custom rotation sends raw fields with no `template`.
  static const int custom = -1;

  /// UX cap for a Custom day cycle: generous headroom over real cycles while
  /// keeping the editor's day rows bounded.
  static const int maxCycleLength = 20;

  /// Cycle length per day-cycle preset, to render the right number of day rows.
  static const Map<int, int> presetCycleLength = {
    abDay: 2,
    sixDayCycle: 6,
    sevenDayCycle: 7,
    eightDayCycle: 8,
    tenDayCycle: 10,
  };

  static bool isDayCyclePreset(int template) =>
      presetCycleLength.containsKey(template);

  /// A short label for a rotating schedule ("6-Day Cycle", "Week A"), or null
  /// for a plain weekly one.
  static String? labelFor(CourseScheduleModel schedule) {
    if (schedule.isDayCycle) {
      switch (schedule.template) {
        case abDay:
          return LocaleNotifier().localizations.scheduleTemplateAbDay;
        case sixDayCycle:
          return LocaleNotifier().localizations.scheduleTemplateSixDayCycle;
        case sevenDayCycle:
          return LocaleNotifier().localizations.scheduleTemplateSevenDayCycle;
        case eightDayCycle:
          return LocaleNotifier().localizations.scheduleTemplateEightDayCycle;
        case tenDayCycle:
          return LocaleNotifier().localizations.scheduleTemplateTenDayCycle;
        default:
          return LocaleNotifier().localizations.scheduleTemplateCustomCycle(schedule.cycleLength!);
      }
    }
    if (schedule.isWeekBased) {
      final offset = schedule.weekOffset ?? 0;
      return offset == 0 ? LocaleNotifier().localizations.scheduleWeekA : LocaleNotifier().localizations.scheduleWeekB;
    }
    return null;
  }

  /// Items for the "Rotating" template dropdown. Custom is intentionally absent:
  /// it is never offered for a new schedule. [customItem] is injected into the
  /// dropdown only when editing a schedule that already carries a raw custom
  /// rotation (created via the API or an import).
  static List<DropDownItem<int>> get items => [
        DropDownItem(id: abDay, value: abDay, label: LocaleNotifier().localizations.scheduleTemplateAbDay),
        DropDownItem(id: sixDayCycle, value: sixDayCycle, label: LocaleNotifier().localizations.scheduleTemplateSixDayCycle),
        DropDownItem(
          id: sevenDayCycle,
          value: sevenDayCycle,
          label: LocaleNotifier().localizations.scheduleTemplateSevenDayCycle,
        ),
        DropDownItem(
          id: eightDayCycle,
          value: eightDayCycle,
          label: LocaleNotifier().localizations.scheduleTemplateEightDayCycle,
        ),
        DropDownItem(
          id: tenDayCycle,
          value: tenDayCycle,
          label: LocaleNotifier().localizations.scheduleTemplateTenDayCycle,
        ),
        DropDownItem(id: weekAb, value: weekAb, label: LocaleNotifier().localizations.scheduleTemplateWeekAb),
      ];

  /// Dropdown item for a cycle whose length isn't one of the presets, shown by
  /// its length (e.g. "3-Day Cycle"). Injected only when editing such a schedule
  /// (created via the API or an import); never offered when creating a new one.
  static DropDownItem<int> customCycleItem(int cycleLength) =>
      DropDownItem(id: custom, value: custom, label: LocaleNotifier().localizations.scheduleTemplateCustomCycle(cycleLength));
}
