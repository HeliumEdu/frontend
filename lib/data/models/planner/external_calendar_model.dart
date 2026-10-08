import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';

class ExternalCalendarModel extends BaseTitledModel {
  final Uri url;
  final Color color;

  /// The raw `updated_at`, sent back as `If-Match` so a stale full edit is
  /// rejected instead of overwriting a change made elsewhere.
  final String? version;

  ExternalCalendarModel({
    this.version,
    required super.id,
    required super.title,
    required super.shownOnCalendar,
    required this.url,
    required this.color,
  });

  factory ExternalCalendarModel.fromJson(Map<String, dynamic> json) {
    return ExternalCalendarModel(
      id: json['id'],
      version: json['updated_at'],
      title: json['title'],
      url: Uri.parse(json['url']),
      color: HeliumColors.hexToColor(json['color']),
      shownOnCalendar: json['shown_on_calendar'],
    );
  }
}
