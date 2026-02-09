// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class MaterialRequestModel {
  final String title;
  final int status;
  final int condition;
  final String website;
  final String price;
  final String details;
  final List<int> courses;
  final int materialGroup;

  MaterialRequestModel({
    required this.title,
    required this.status,
    required this.condition,
    required this.website,
    required this.price,
    required this.details,
    required this.courses,
    required this.materialGroup,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'status': status,
      'condition': condition,
      'website': website,
      'price': price,
      'details': details,
      'courses': courses,
      'material_group': materialGroup,
    };

    return data;
  }
}
