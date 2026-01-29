// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';

abstract class CalendarState {
  final String? message;

  CalendarState({this.message});
}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarError extends CalendarState {
  CalendarError({required super.message});
}

class CalendarScreenDataFetched extends CalendarState {
  final List<CourseModel> courses;
  final List<CategoryModel> categories;

  CalendarScreenDataFetched({
    super.message,
    required this.courses,
    required this.categories,
  });
}
