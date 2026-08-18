// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';

class CredentialsFormController extends BasicFormController {
  // Field name constants - must match backend API field names
  static const String emailField = 'email';
  static const String passwordField = 'password';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
