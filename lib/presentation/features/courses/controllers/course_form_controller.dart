// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
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
