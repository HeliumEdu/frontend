// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

/// Base model that provides identity and equality based on ID.
/// All models with an ID field should extend this class.
abstract class BaseModel {
  final int id;

  BaseModel({required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Base model for entities that have a title and calendar visibility.
/// Extends BaseModel to inherit ID-based equality.
abstract class BaseTitledModel extends BaseModel {
  final String title;
  final bool? shownOnCalendar;

  BaseTitledModel({
    required super.id,
    required this.title,
    this.shownOnCalendar,
  });

  @override
  String toString() {
    return title;
  }
}
