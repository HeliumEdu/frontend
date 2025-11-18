import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:helium_student_flutter/presentation/bloc/bottombarBloc/bottom_bar_event.dart';
import 'package:helium_student_flutter/presentation/bloc/bottombarBloc/bottom_bar_state.dart';
import 'package:helium_student_flutter/presentation/views/classesScreen/classes_screen.dart';
import 'package:helium_student_flutter/presentation/views/gradeScreen/grades_screen.dart';
import 'package:helium_student_flutter/presentation/views/homeScreen/home_screen.dart';
import 'package:helium_student_flutter/presentation/views/materialScreen/material_screen.dart';

class BottomNavigationBloc
    extends Bloc<BottomNavigationEvent, BottomNavigationState> {
  final List<Widget> widgetList = [
    HomeScreen(),
    ClassesScreen(),
    MaterialScreen(),
    GradesScreen(),
  ];

  BottomNavigationBloc() : super(const BottomNavigationState()) {
    on<NavigationTabChanged>(_onNavigationTabChanged);
  }

  void _onNavigationTabChanged(
    NavigationTabChanged event,
    Emitter<BottomNavigationState> emit,
  ) {
    if (event.tabIndex >= 0 && event.tabIndex < widgetList.length) {
      emit(state.copyWith(selectedIndex: event.tabIndex));
    }
  }
}
