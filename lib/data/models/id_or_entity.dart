import 'package:heliumapp/data/models/base_model.dart';

class IdOrEntity<T extends BaseModel> {
  final int id;
  final T? entity;

  IdOrEntity({required this.id, this.entity});

  factory IdOrEntity.from(dynamic data, Function fromJson) {
    dynamic value = data;
    if (value is String) {
      value = int.tryParse(value);
    }

    if (value is int) return IdOrEntity(id: value);
    if (data is Map<String, dynamic>) {
      return IdOrEntity(id: data['id'], entity: fromJson(data));
    }

    throw ArgumentError.value(data, 'data', 'Expected an id or a JSON object');
  }

  @override
  bool operator ==(Object other) {
    if (id == other) return true;
    if (other is IdOrEntity) return id == other.id;

    return false;
  }

  @override
  int get hashCode => Object.hash(id, entity);

  IdOrEntity<T> copyWith({T? entity}) {
    return IdOrEntity<T>(
      id: entity?.id ?? id,
      entity: entity ?? this.entity,
    );
  }
}
