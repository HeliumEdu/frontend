// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';

class ChangeEmailFormController extends BasicFormController {
  final TextEditingController newEmailController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();

  void dispose() {
    newEmailController.dispose();
    oldPasswordController.dispose();
  }

  void clearForm() {
    newEmailController.clear();
    oldPasswordController.clear();
  }
}
