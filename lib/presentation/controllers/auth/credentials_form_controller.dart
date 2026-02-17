// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/controllers/core/basic_form_controller.dart';

class CredentialsFormController extends BasicFormController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;

  @mustCallSuper
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }

  @mustCallSuper
  void clearForm() {
    emailController.clear();
    passwordController.clear();
  }
}
