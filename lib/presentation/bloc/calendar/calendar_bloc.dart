// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/domain/repositories/category_repository.dart';
import 'package:heliumapp/domain/repositories/course_repository.dart';
import 'package:heliumapp/presentation/bloc/calendar/calendar_event.dart';
import 'package:heliumapp/presentation/bloc/calendar/calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CourseRepository courseRepository;
  final CategoryRepository categoryRepository;

  CalendarBloc({
    required this.courseRepository,
    required this.categoryRepository,
  }) : super(CalendarInitial()) {
    on<FetchCalendarScreenDataEvent>(_onFetchCalendarScreenDataEvent);
  }

  Future<void> _onFetchCalendarScreenDataEvent(
    FetchCalendarScreenDataEvent event,
    Emitter<CalendarState> emit,
  ) async {
    emit(CalendarLoading());
    try {
      final courses = await courseRepository.getCourses(shownOnCalendar: true);
      final categories = await categoryRepository.getCategories();

      emit(CalendarScreenDataFetched(courses: courses, categories: categories));
    } on HeliumException catch (e) {
      emit(CalendarError(message: e.message));
    } catch (e) {
      emit(CalendarError(message: 'An unexpected error occurred: $e'));
    }
  }
}
