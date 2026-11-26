// AUTO-GENERATED — DO NOT EDIT.
// Written from platform/helium/common/enums.py by:
//   platform/bin/sync-shared-constants.py

import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/utils/dropdown_extensions.dart';

class ResourceConstants {
  static const int statusDigital = 7;

  static const int conditionDigital = 8;

  static List<String> get statusLabels {
    final l10n = LocaleNotifier().localizations;
    return [
      l10n.resourceStatusOwned,
      l10n.resourceStatusRented,
      l10n.resourceStatusOrdered,
      l10n.resourceStatusShipped,
      l10n.resourceStatusNeeded,
      l10n.resourceStatusReceived,
      l10n.resourceStatusToSell,
      l10n.resourceStatusDigital,
    ];
  }

  static List<DropDownItem<String>> get statusItems => statusLabels.toDropDownItems();

  static List<String> get conditionLabels {
    final l10n = LocaleNotifier().localizations;
    return [
      l10n.resourceConditionBrandNew,
      l10n.resourceConditionRefurbished,
      l10n.resourceConditionUsedLikeNew,
      l10n.resourceConditionUsedVeryGood,
      l10n.resourceConditionUsedGood,
      l10n.resourceConditionUsedAcceptable,
      l10n.resourceConditionUsedPoor,
      l10n.resourceConditionBroken,
      l10n.resourceConditionDigital,
    ];
  }

  static List<DropDownItem<String>> get conditionItems => conditionLabels.toDropDownItems();
}
