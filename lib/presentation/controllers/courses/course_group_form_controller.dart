// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';

class CourseGroupFormController extends BasicFormController {
  final TextEditingController titleController = TextEditingController();
  bool shownOnCalendar = true;
  DateTime? startDate;
  DateTime? endDate;

  void dispose() {
    titleController.dispose();
  }
}
