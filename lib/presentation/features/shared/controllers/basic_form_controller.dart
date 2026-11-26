import 'package:flutter/material.dart';
import 'package:heliumapp/config/locale_notifier.dart';
import 'package:heliumapp/presentation/ui/layout/reveal_on_mount.dart';

class BasicFormController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isChanged = false;

  /// True only when an actual user input fired markChanged. Distinct from
  /// [isChanged], which is also set during init (so save flows know to
  /// commit fresh entities). Use [isUserDirty] to drive UX like the
  /// unsaved-changes prompt that should fire only on real user edits.
  bool isUserDirty = false;

  /// Map of field names to their GlobalKeys for scroll-to-error functionality.
  /// Fields are registered in order, so iteration preserves form field order.
  final Map<String, GlobalKey<FormFieldState<String>>> _fieldKeys =
      <String, GlobalKey<FormFieldState<String>>>{};

  void markChanged({bool userInitiated = true}) {
    isChanged = true;
    if (userInitiated) isUserDirty = true;
  }

  /// Register and return a GlobalKey for a form field.
  /// Call this for each field that has a validator to enable scroll-to-error.
  GlobalKey<FormFieldState<String>> getFieldKey(String fieldName) {
    _fieldKeys.putIfAbsent(
      fieldName,
      () => GlobalKey<FormFieldState<String>>(),
    );
    return _fieldKeys[fieldName]!;
  }

  /// Validates the form and scrolls to the first invalid field if validation fails.
  /// Returns true if valid, false otherwise.
  bool validateAndScrollToError() {
    if (formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();
      return true;
    }

    // Find first invalid field and scroll to it
    for (final entry in _fieldKeys.entries) {
      final fieldState = entry.value.currentState;
      if (fieldState != null && fieldState.hasError) {
        final context = entry.value.currentContext;
        if (context != null) {
          RevealOnMount.ensureVisible(context, alignment: 0.1);
        }
        break;
      }
    }

    return false;
  }

  static String? validateRequiredField(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleNotifier().localizations.formRequiredFieldError;
    }
    return null;
  }

  static String? validateRequiredUrl(String? value) {
    final required = validateRequiredField(value);
    if (required != null) {
      return required;
    }
    return validateUrl(value);
  }

  static String? validateRequiredEmail(String? value) {
    final required = validateRequiredField(value);
    if (required != null) {
      return required;
    }
    return validateEmail(value);
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegExp.hasMatch(value)) {
      return LocaleNotifier().localizations.formInvalidEmailError;
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleNotifier().localizations.formRequiredFieldError;
    }
    if (value.length < 8) {
      return LocaleNotifier().localizations.formPasswordTooShortError;
    }
    return null;
  }

  static String? validateConfirmPassword(String value1, String? value2) {
    if (value2 == null || value2.isEmpty) {
      return LocaleNotifier().localizations.formConfirmPasswordRequiredError;
    }
    if (value2 != value1) {
      return LocaleNotifier().localizations.formPasswordsMismatchError;
    }
    return null;
  }

  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final urlPattern = RegExp(
      r'(http|https)://[\w-]+(\.[\w-]+)*\.[\w-]{2,}([\w.,@?^=%&:/~+#-]*[\w@?^=%&;/~+#-])?',
    );

    if (!urlPattern.hasMatch(value)) {
      return LocaleNotifier().localizations.formInvalidUrlError;
    }

    return null;
  }

  static String cleanUrl(String? value) {
    if (value == null || value.isEmpty) {
      return value ?? '';
    }

    // Already valid, return as-is
    if (validateUrl(value) == null) {
      return value;
    }

    // Try adding https://
    final withHttps = 'https://$value';
    if (validateUrl(withHttps) == null) {
      return withHttps;
    }

    // Couldn't fix it, return original (validation will show error)
    return value;
  }
}
