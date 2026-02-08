// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/base_model.dart';

class MaterialGroupModel extends BaseTitledModel {
  MaterialGroupModel({
    required super.id,
    required super.title,
    required super.shownOnCalendar,
  });

  factory MaterialGroupModel.fromJson(Map<String, dynamic> json) {
    return MaterialGroupModel(
      id: json['id'],
      title: json['title'],
      shownOnCalendar: json['shown_on_calendar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'shown_on_calendar': shownOnCalendar};
  }
}
