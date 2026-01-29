// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:logging/logging.dart';

final log = Logger('HeliumLogger');

class IdOrEntity<T extends BaseModel> {
  final int id;
  final T? entity;

  IdOrEntity({required this.id, this.entity});

  factory IdOrEntity.from(dynamic data, Function fromJson) {
    try {
      if (data is String) {
        data = int.tryParse(data);
      }
    } catch (_) {}

    if (data is int) return IdOrEntity(id: data);
    try {
      if (data is Map<String, dynamic>) {
        return IdOrEntity(id: data['id'], entity: fromJson(data));
      }
    } catch (e, s) {
      log.severe('An unknown error occurred', e, s);
    }

    throw HeliumException(
      message:
          'Unknown data format, or given clazz does not implement fromJson',
    );
  }

  @override
  bool operator ==(Object other) {
    if (id == other) return true;
    if (other is IdOrEntity) return id == other.id;

    return false;
  }

  @override
  int get hashCode => Object.hash(id, entity);
}
