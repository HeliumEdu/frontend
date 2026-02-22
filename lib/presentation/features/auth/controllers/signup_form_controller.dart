// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heliumapp/presentation/features/auth/controllers/credentials_form_controller.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/utils/time_zone_constants.dart';

class SignupFormController extends CredentialsFormController {
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isConfirmPasswordVisible = false;
  bool agreeToTerms = false;
  String selectedTimeZone = 'Etc/UTC';

  Future<void> initializeTimeZones() async {
    final tz = (await FlutterTimezone.getLocalTimezone()).identifier;
    selectedTimeZone =
        TimeZoneConstants.all.contains(tz) ? tz : 'Etc/UTC';
  }

  @override
  void dispose() {
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  void clearForm() {
    super.clearForm();

    confirmPasswordController.clear();
    agreeToTerms = false;
    selectedTimeZone = 'Etc/UTC';
  }

  String? validateConfirmPassword(String? value) {
    return BasicFormController.validateConfirmPassword(
      passwordController.text,
      value,
    );
  }
}
