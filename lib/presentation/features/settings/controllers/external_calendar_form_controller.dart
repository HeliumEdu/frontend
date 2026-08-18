// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/utils/color_helpers.dart';

class ExternalCalendarFormController extends BasicFormController {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  Color selectedColor = HeliumColors.getRandomColor();
  bool shownOnCalendar = true;

  void dispose() {
    titleController.dispose();
    urlController.dispose();
  }
}
