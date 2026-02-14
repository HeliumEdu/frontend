// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/base_model.dart';

class MaterialModel extends BaseTitledModel {
  final int status;
  final int condition;
  final String website;
  final String? price;
  final String? details;
  final int materialGroup;
  final List<int> courses;

  MaterialModel({
    required super.id,
    required super.title,
    super.shownOnCalendar,
    required this.status,
    required this.condition,
    required this.website,
    this.price,
    this.details,
    required this.materialGroup,
    required this.courses,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'],
      title: json['title'],
      shownOnCalendar: json['shown_on_calendar'],
      status: json['status'],
      condition: json['condition'],
      website: json['website'],
      price: json['price'],
      details: json['details']?.toString().isEmpty == true
          ? null
          : json['details']?.toString(),
      materialGroup: json['material_group'],
      courses: json['courses'] != null ? List<int>.from(json['courses']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'condition': condition,
      'website': website,
      'price': price,
      'details': details,
      'material_group': materialGroup,
      'courses': courses,
    };
  }
}
