// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class CategoryRequestModel {
  final String title;
  final String weight;
  final String color;

  CategoryRequestModel({
    required this.title,
    required this.weight,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {'title': title, 'weight': weight, 'color': color};
  }

  factory CategoryRequestModel.fromJson(Map<String, dynamic> json) {
    return CategoryRequestModel(
      title: json['title'] ?? '',
      weight: json['weight'] ?? '0',
      color: json['color'] ?? '#cabdbf',
    );
  }
}
