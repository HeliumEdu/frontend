import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';

Uri? toUri(dynamic value) {
  if (value is String && value.isNotEmpty) return Uri.tryParse(value);
  return null;
}

double? toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// A grade-derived value, or null for the API's `-1` "not graded" sentinel.
double? toGradedDouble(dynamic value) {
  final number = toDouble(value);
  return number == null || number == -1 ? null : number;
}

int? toInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

List<IdOrEntity<T>> idOrEntityListFrom<T extends BaseModel>(
  List<dynamic> data,
  Function fromJson,
) {
  return data.map((item) => IdOrEntity<T>.from(item, fromJson)).toList();
}

IdOrEntity<T> idOrEntityFrom<T extends BaseModel>(
  dynamic data,
  Function fromJson,
) {
  return IdOrEntity<T>.from(data, fromJson);
}
