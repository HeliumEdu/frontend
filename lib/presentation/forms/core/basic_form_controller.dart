// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';

class BasicFormController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Map of field names to their GlobalKeys for scroll-to-error functionality.
  /// Fields are registered in order, so iteration preserves form field order.
  final Map<String, GlobalKey<FormFieldState<String>>> _fieldKeys =
      <String, GlobalKey<FormFieldState<String>>>{};

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
      return true;
    }

    // Find first invalid field and scroll to it
    for (final entry in _fieldKeys.entries) {
      final fieldState = entry.value.currentState;
      if (fieldState != null && fieldState.hasError) {
        final context = entry.value.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );
        }
        break;
      }
    }

    return false;
  }

  static String? validateRequiredField(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
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
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length >= 30) {
      return 'Username must be less than 30 characters';
    }
    final usernameRegExp = RegExp(r'^[A-Za-z0-9+\-_.]+$');
    if (!usernameRegExp.hasMatch(value)) {
      return 'Username can only include letters, numbers, or +-_.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  static String? validateConfirmPassword(String value1, String? value2) {
    if (value2 == null || value2.isEmpty) {
      return 'Re-enter the password';
    }
    if (value2 != value1) {
      return 'The passwords do not match';
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
      return 'Enter a valid URL';
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
