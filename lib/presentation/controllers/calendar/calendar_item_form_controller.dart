// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';

class CalendarItemFormController extends BasicFormController {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();
  final gradeFocusNode = FocusNode();
  int? selectedCourse;
  int? selectedCategory;
  List<int> selectedResources = [];
  bool isAllDay = false;
  bool isCompleted = false;
  bool showEndDateTime = false;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 12, minute: 50);
  double priorityValue = 50.0;
  String initialNotes = '';

  CalendarItemFormController() {
    gradeFocusNode.addListener(_onGradeFocusChange);
  }

  void dispose() {
    titleController.dispose();
    gradeController.dispose();
    gradeFocusNode.dispose();
  }

  void _onGradeFocusChange() {
    if (!gradeFocusNode.hasFocus) {
      var value = gradeController.text.trim();
      if (value != '') {
        if (value.contains('/') && value.endsWith('%')) {
          // If a ratio and a percentage exist, drop the percentage
          value = value.substring(0, value.length - 1);
        } else if (!value.contains('/')) {
          // If the value ends with a percentage, drop it
          if (value.endsWith('%')) {
            value = value.substring(0, value.length - 1);
          }
          // Similarly, if the value didn't end with a percentage, clarify it's out of 100
          value += '/100';
        }

        final split = value.split('/');
        // Ensure there is no division by 0
        if (double.tryParse(split[0]) == 0 && double.tryParse(split[1]) == 0) {
          value = '0/100';
        } else if (double.tryParse(split[1]) == 0) {
          value = '';
        }

        gradeController.text = value;
      }
    }
  }
}
