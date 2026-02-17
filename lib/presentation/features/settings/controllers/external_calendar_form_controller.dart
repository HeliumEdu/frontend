// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

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
