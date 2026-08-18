// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

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
