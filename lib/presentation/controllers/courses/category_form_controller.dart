// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';
import 'package:heliumapp/utils/color_helpers.dart';

class CategoryFormController extends BasicFormController {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  Color selectedColor = HeliumColors.getRandomColor();

  void dispose() {
    titleController.dispose();
    weightController.dispose();
  }
}
