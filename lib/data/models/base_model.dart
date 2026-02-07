// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

abstract class BaseModel {
  final int id;
  final String title;
  final bool? shownOnCalendar;

  BaseModel({required this.id, required this.title, this.shownOnCalendar});

  @override
  String toString() {
    return title;
  }
}
