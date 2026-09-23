import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class ResourceModel extends BaseTitledModel {
  final int status;
  final int condition;
  final Uri? website;
  final String? price;
  final int resourceGroup;
  final List<int> courses;
  final List<int> notes;

  ResourceModel({
    required super.id,
    required super.title,
    super.shownOnCalendar,
    required this.status,
    required this.condition,
    this.website,
    this.price,
    required this.resourceGroup,
    required this.courses,
    required this.notes,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'],
      title: json['title'],
      shownOnCalendar: json['shown_on_calendar'],
      status: json['status'],
      condition: json['condition'],
      website: toUri(json['website']),
      price: json['price'],
      resourceGroup: json['resource_group'],
      courses: json['courses'] != null ? List<int>.from(json['courses']) : [],
      notes: json['notes'] != null ? List<int>.from(json['notes']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'condition': condition,
      'website': website?.toString() ?? '',
      'price': price,
      'resource_group': resourceGroup,
      'courses': courses,
    };
  }
}
