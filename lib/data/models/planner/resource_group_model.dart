import 'package:heliumapp/data/models/base_model.dart';

class ResourceGroupModel extends BaseTitledModel {
  /// The raw `updated_at`, sent back as `If-Match` so a stale full edit is
  /// rejected instead of overwriting a change made elsewhere.
  final String? version;

  ResourceGroupModel({
    this.version,
    required super.id,
    required super.title,
    required super.shownOnCalendar,
  });

  factory ResourceGroupModel.fromJson(Map<String, dynamic> json) {
    return ResourceGroupModel(
      id: json['id'],
      version: json['updated_at'],
      title: json['title'],
      shownOnCalendar: json['shown_on_calendar'],
    );
  }
}
