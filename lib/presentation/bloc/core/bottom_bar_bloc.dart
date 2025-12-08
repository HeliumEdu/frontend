// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/bloc/core/bottom_bar_event.dart';
import 'package:heliumapp/presentation/bloc/core/bottom_bar_state.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_screen.dart';
import 'package:heliumapp/presentation/views/courses/courses_screen.dart';
import 'package:heliumapp/presentation/views/grades/grades_screen.dart';
import 'package:heliumapp/presentation/views/materials/materials_screen.dart';

class BottomNavigationBloc
    extends Bloc<BottomNavigationEvent, BottomNavigationState> {
  final List<Widget> screensList = [
    CalendarScreen(),
    ClassesScreen(),
    MaterialsScreen(),
    GradesScreen(),
  ];

  BottomNavigationBloc() : super(BottomNavigationState()) {
    on<NavigationTabChanged>(_onNavigationTabChanged);
  }

  void _onNavigationTabChanged(
    NavigationTabChanged event,
    Emitter<BottomNavigationState> emit,
  ) {
    if (event.tabIndex >= 0 && event.tabIndex < screensList.length) {
      emit(state.copyWith(selectedIndex: event.tabIndex));
    }
  }
}
