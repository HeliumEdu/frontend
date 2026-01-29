// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';

class HeliumConversion {
  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<IdOrEntity<T>> idOrEntityListFrom<T extends BaseModel>(
    List<dynamic> data,
    Function fromJson,
  ) {
    return data.map((item) => IdOrEntity<T>.from(item, fromJson)).toList();
  }

  static IdOrEntity<T> idOrEntityFrom<T extends BaseModel>(
    dynamic data,
    Function fromJson,
  ) {
    return IdOrEntity<T>.from(data, fromJson);
  }
}
