// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heliumapp/presentation/forms/auth/credentials_form_controller.dart';
import 'package:heliumapp/presentation/forms/core/basic_form_controller.dart';

class RegisterFormController extends CredentialsFormController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isConfirmPasswordVisible = false;
  bool agreeToTerms = false;
  String selectedTimezone = 'Etc/UTC';

  Future<void> initializeTimezones() async {
    selectedTimezone = (await FlutterTimezone.getLocalTimezone()).identifier;
  }

  @override
  void dispose() {
    emailController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  void clearForm() {
    super.clearForm();

    emailController.clear();
    confirmPasswordController.clear();
    agreeToTerms = false;
    selectedTimezone = 'Etc/UTC';
  }

  String? validateConfirmPassword(String? value) {
    return BasicFormController.validateConfirmPassword(
      passwordController.text,
      value,
    );
  }
}
