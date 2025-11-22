// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class MaterialModel {
  final int id;
  final String title;
  final int? status;
  final int? condition;
  final String? website;
  final String? price;
  final String? details;
  final int materialGroup;
  final List<int>? courses;

  MaterialModel({
    required this.id,
    required this.title,
    this.status,
    this.condition,
    this.website,
    this.price,
    this.details,
    required this.materialGroup,
    this.courses,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    // Helper to convert price to string (can be int or string from API)
    String? parsePrice(dynamic value) {
      if (value == null || value == '') return null;
      if (value is String) return value;
      if (value is num) return '\$$value';
      return value.toString();
    }

    return MaterialModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      status: json['status'],
      condition: json['condition'],
      website: json['website']?.toString().isEmpty == true
          ? null
          : json['website']?.toString(),
      price: parsePrice(json['price']),
      details: json['details']?.toString().isEmpty == true
          ? null
          : json['details']?.toString(),
      materialGroup: json['material_group'] ?? 0,
      courses: json['courses'] != null ? List<int>.from(json['courses']) : null,
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

  // Helper getters for status and condition display
  String get statusDisplay {
    const statusMap = {
      0: 'Owned',
      1: 'Rented',
      2: 'Ordered',
      3: 'Shipped',
      4: 'Needed',
      5: 'Returned',
      6: 'To Sell',
      7: 'Digital',
    };
    return statusMap[status] ?? 'Unknown';
  }

  String get conditionDisplay {
    const conditionMap = {
      0: 'Brand New',
      1: 'Refurbished',
      2: 'Used - Like New',
      3: 'Used - Very Good',
      4: 'Used - Good',
      5: 'Used - Acceptable',
      6: 'Used - Poor',
      7: 'Broken',
      8: 'Digital',
    };
    return conditionMap[condition] ?? 'Unknown';
  }
}
