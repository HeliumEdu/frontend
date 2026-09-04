import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heliumapp/presentation/features/auth/controllers/credentials_form_controller.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';

class SignupFormController extends CredentialsFormController {
  // Field name constants - must match backend API field names
  static const String confirmPasswordField = 'confirm_password';
  static const String timeZoneField = 'time_zone';

  final TextEditingController confirmPasswordController =
      TextEditingController();
  String selectedTimeZone = 'UTC';

  Future<void> initializeTimeZones() async {
    final tz = (await FlutterTimezone.getLocalTimezone()).identifier;
    selectedTimeZone = HeliumDateTime.resolveTimeZone(tz);
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
    selectedTimeZone = 'UTC';
  }

  String? validateConfirmPassword(String? value) {
    return BasicFormController.validateConfirmPassword(
      passwordController.text,
      value,
    );
  }
}
