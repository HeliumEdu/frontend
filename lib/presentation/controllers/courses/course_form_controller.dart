// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';
import 'package:heliumapp/utils/color_helpers.dart';

class CourseFormController extends BasicFormController {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final TextEditingController teacherNameController = TextEditingController();
  final TextEditingController teacherEmailController = TextEditingController();
  final TextEditingController creditsController = TextEditingController();
  final FocusNode urlFocusNode = FocusNode();
  Color selectedColor = HeliumColors.getRandomColor();
  bool isOnline = false;
  DateTime? startDate;
  DateTime? endDate;

  void dispose() {
    titleController.dispose();
    roomController.dispose();
    urlController.dispose();
    teacherNameController.dispose();
    teacherEmailController.dispose();
    creditsController.dispose();
    urlFocusNode.dispose();
  }
}
