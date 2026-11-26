import 'package:flutter/material.dart';
import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';

class ReminderConstants {
  static const List<String> offsetTypes = ['Minutes', 'Hours', 'Days', 'Weeks'];

  /// The dropdown item for a reminder type (backend enum value).
  static DropDownItem<String> itemForType(int type) =>
      typeItems.firstWhere((t) => t.id == type);

  /// The reminder type (backend enum value) for its dropdown [value].
  static int typeForValue(String value) =>
      typeItems.firstWhere((t) => t.value == value).id;

  static List<DropDownItem<String>> get typeItems => [
    DropDownItem(
      id: 1,
      value: 'Email',
      label: LocaleNotifier().localizations.reminderTypeEmail,
      iconData: Icons.mail_outline,
    ),
    DropDownItem(
      id: 3,
      value: 'Push',
      label: LocaleNotifier().localizations.reminderTypePush,
      iconData: Icons.phone_android_outlined,
    ),
  ];

  static List<DropDownItem<String>> get offsetTypeItems {
    final l10n = LocaleNotifier().localizations;
    final labels = [
      l10n.reminderOffsetUnitMinutes,
      l10n.reminderOffsetUnitHours,
      l10n.reminderOffsetUnitDays,
      l10n.reminderOffsetUnitWeeks,
    ];
    return [
      for (final (index, offsetType) in offsetTypes.indexed)
        DropDownItem(id: index, value: offsetType, label: labels[index]),
    ];
  }
}
