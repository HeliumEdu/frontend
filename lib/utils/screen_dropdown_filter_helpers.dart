import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';

/// Persists and restores the last-selected group/term id for the Courses,
/// Grades, and Resources dropdowns, gated by the same "Remember filter
/// selections" setting used by Planner and Notebook.
class ScreenDropdownFilterHelpers {
  ScreenDropdownFilterHelpers._();

  static void save(
    ScreensDropdownFilterPrefKey key,
    int groupId,
    UserSettingsModel settings,
  ) {
    if (!settings.rememberFilterState) return;

    PrefService().setInt(key.key, groupId);
  }

  static int? restore(
    ScreensDropdownFilterPrefKey key,
    UserSettingsModel settings,
  ) {
    if (!settings.rememberFilterState) return null;

    return PrefService().getInt(key.key);
  }
}
