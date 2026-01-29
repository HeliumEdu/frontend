// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/utils/color_helpers.dart';

class ExternalCalendarModel extends BaseModel {
  final String url;
  final Color color;

  ExternalCalendarModel({
    required super.id,
    required super.title,
    required super.shownOnCalendar,
    required this.url,
    required this.color,
  });

  factory ExternalCalendarModel.fromJson(Map<String, dynamic> json) {
    return ExternalCalendarModel(
      id: json['id'],
      title: json['title'],
      url: json['url'],
      color: HeliumColors.hexToColor(json['color']),
      shownOnCalendar: json['shown_on_calendar'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'url': url,
      'color': color,
      'shown_on_calendar': shownOnCalendar,
    };

    return data;
  }
}
