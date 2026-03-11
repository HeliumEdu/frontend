// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';

class ChangeEmailFormController extends BasicFormController {
  final TextEditingController newEmailController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  bool isPasswordVisible = false;

  void dispose() {
    newEmailController.dispose();
    oldPasswordController.dispose();
  }

  void clearForm() {
    newEmailController.clear();
    oldPasswordController.clear();
  }
}
