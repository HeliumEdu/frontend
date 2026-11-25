import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/features/auth/controllers/credentials_form_controller.dart';
import 'package:heliumapp/presentation/features/shared/controllers/basic_form_controller.dart';
import 'package:heliumapp/utils/locale_helpers.dart';

class SignupFormController extends CredentialsFormController {
  // Field name constants - must match backend API field names
  static const String confirmPasswordField = 'confirm_password';

  final TextEditingController confirmPasswordController =
      TextEditingController();
  String timeZone = 'UTC';
  String language = HeliumLocale.fallback.languageCode;

  Future<void> detectLocale() async {
    final detected = await HeliumLocale.detect();
    timeZone = detected.timeZone;
    language = detected.language;
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
    timeZone = 'UTC';
    language = HeliumLocale.fallback.languageCode;
  }

  String? validateConfirmPassword(String? value) {
    return BasicFormController.validateConfirmPassword(
      passwordController.text,
      value,
    );
  }
}
