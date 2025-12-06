// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class ErrorResponseModel {
  final String message;
  final Map<String, dynamic>? fieldErrors;
  final int? statusCode;

  ErrorResponseModel({
    required this.message,
    this.fieldErrors,
    this.statusCode,
  });

  factory ErrorResponseModel.fromJson(
    Map<String, dynamic> json, {
    int? statusCode,
  }) {
    // Handle different error response formats
    String message = 'An error occurred';
    Map<String, dynamic>? fieldErrors;

    // Check for detail field (common in Django REST Framework)
    if (json.containsKey('detail')) {
      message = json['detail'].toString();
    }
    // Check for message field
    else if (json.containsKey('message')) {
      message = json['message'].toString();
    }
    // Check for error field
    else if (json.containsKey('error')) {
      message = json['error'].toString();
    }
    // Handle field-specific errors
    else {
      fieldErrors = Map<String, dynamic>.from(json);
      // Create a user-friendly message from field errors
      if (fieldErrors.isNotEmpty) {
        final firstError = fieldErrors.entries.first;
        final errorValue = firstError.value;
        if (errorValue is List && errorValue.isNotEmpty) {
          message = '${firstError.key}: ${errorValue.first}';
        } else {
          message = '${firstError.key}: $errorValue';
        }
      }
    }

    return ErrorResponseModel(
      message: message,
      fieldErrors: fieldErrors,
      statusCode: statusCode,
    );
  }

  // Get user-friendly error message
  String getUserMessage() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      final messages = <String>[];
      fieldErrors!.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          // For single error messages, just show the message without field name
          if (fieldErrors!.length == 1) {
            messages.add(value.join(', '));
          } else {
            // For multiple fields, include the field name
            final fieldName = _formatFieldName(key);
            messages.add('$fieldName: ${value.join(", ")}');
          }
        } else {
          if (fieldErrors!.length == 1) {
            messages.add(value.toString());
          } else {
            final fieldName = _formatFieldName(key);
            messages.add('$fieldName: $value');
          }
        }
      });
      return messages.join('\n');
    }
    return message;
  }

  // Format field names to be more user-friendly
  String _formatFieldName(String fieldName) {
    // Handle common field names
    final Map<String, String> fieldMapping = {
      'password': 'Password',
      'email': 'Email',
      'username': 'Username',
      'old_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_password': 'Confirm Password',
    };

    return fieldMapping[fieldName] ?? fieldName;
  }

  @override
  String toString() => message;
}
