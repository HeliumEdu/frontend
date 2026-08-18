import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/presentation/features/planner/constants/reminder_constants.dart';

extension PluralExtension on num {
  String plural(String singularWord, [String? pluralWord]) {
    return this != 1
        ? (pluralWord ?? '${singularWord}s')
        : singularWord;
  }
}

extension BytesFormatting on int {
  int get inMegabytes => this ~/ (1024 * 1024);
}

String reminderOffset(ReminderModel reminder) {
  final plural = ReminderConstants.offsetTypes[reminder.offsetType].toLowerCase();
  final singular = plural.substring(0, plural.length - 1);
  return '${reminder.offset} ${reminder.offset.plural(singular)}';
}
