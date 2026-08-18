// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';

class CourseGroupFormController extends BasicFormController {
  final TextEditingController titleController = TextEditingController();
  bool shownOnCalendar = true;
  DateTime? startDate;
  DateTime? endDate;

  void dispose() {
    titleController.dispose();
  }
}
