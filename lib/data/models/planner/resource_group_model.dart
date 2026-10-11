import 'package:heliumapp/data/models/base_model.dart';

class ResourceGroupModel extends BaseTitledModel {
  ResourceGroupModel({
    required super.id,
    required super.title,
    required super.shownOnCalendar,
    super.version,
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
