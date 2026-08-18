// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:heliumapp/data/models/base_model.dart';

class ResourceGroupModel extends BaseTitledModel {
  ResourceGroupModel({
    required super.id,
    required super.title,
    required super.shownOnCalendar,
  });

  factory ResourceGroupModel.fromJson(Map<String, dynamic> json) {
    return ResourceGroupModel(
      id: json['id'],
      title: json['title'],
      shownOnCalendar: json['shown_on_calendar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'shown_on_calendar': shownOnCalendar};
  }
}
