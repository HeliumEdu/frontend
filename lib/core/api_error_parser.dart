// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

/// Parsed API error containing field-specific and general errors
class ParsedApiError {
  /// Map of field names to their error messages
  final Map<String, List<String>> fieldErrors;

  /// General errors that aren't associated with a specific field
  final List<String> generalErrors;

  /// User-friendly display message (cleaned up)
  final String displayMessage;

  const ParsedApiError({
    required this.fieldErrors,
    required this.generalErrors,
    required this.displayMessage,
  });

  bool get hasFieldErrors => fieldErrors.isNotEmpty;

  bool get hasErrors => fieldErrors.isNotEmpty || generalErrors.isNotEmpty;

  /// Get the first error for a specific field, or null if none.
  String? getFieldError(String fieldName) {
    final errors = fieldErrors[fieldName];
    return (errors?.isNotEmpty ?? false) ? errors!.first : null;
  }
}

/// Utility class for parsing API error responses into structured errors.
class ApiErrorParser {
  // Pattern to match "field_name: error message" format from API
  static final _fieldPrefixPattern = RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*): (.+)$');

  /// Parses a raw API error response into a structured [ParsedApiError].
  ///
  /// The [responseData] can be:
  /// - A Map with field names as keys and error messages as values
  /// - A List of error strings
  /// - A String error message
  ///
  /// The [rawMessage] is the pre-formatted error message (e.g., "email: error\npassword: error")
  static ParsedApiError parse(dynamic responseData, [String? rawMessage]) {
    final fieldErrors = <String, List<String>>{};
    final generalErrors = <String>[];
    final displayMessages = <String>[];

    if (responseData is Map<String, dynamic>) {
      _parseMap(responseData, fieldErrors, generalErrors, displayMessages);
    } else if (responseData is List) {
      _parseList(responseData, fieldErrors, generalErrors, displayMessages);
    } else if (responseData is String) {
      _parseRawMessage(responseData, fieldErrors, generalErrors, displayMessages);
    } else if (rawMessage != null) {
      // Fall back to parsing the raw message if responseData is unusable
      _parseRawMessage(rawMessage, fieldErrors, generalErrors, displayMessages);
    }

    // If nothing was parsed, use the raw message as a general error
    if (fieldErrors.isEmpty && generalErrors.isEmpty && rawMessage != null) {
      generalErrors.add(rawMessage);
      displayMessages.add(rawMessage);
    }

    return ParsedApiError(
      fieldErrors: fieldErrors,
      generalErrors: generalErrors,
      displayMessage: displayMessages.join('\n'),
    );
  }

  /// Parses a pre-formatted error string (e.g., "field: message\nfield2: message2")
  /// into a structured [ParsedApiError].
  static ParsedApiError parseFromMessage(String message) {
    final fieldErrors = <String, List<String>>{};
    final generalErrors = <String>[];
    final displayMessages = <String>[];

    _parseRawMessage(message, fieldErrors, generalErrors, displayMessages);

    return ParsedApiError(
      fieldErrors: fieldErrors,
      generalErrors: generalErrors,
      displayMessage: displayMessages.join('\n'),
    );
  }

  static void _parseMap(
    Map<String, dynamic> data,
    Map<String, List<String>> fieldErrors,
    List<String> generalErrors,
    List<String> displayMessages,
  ) {
    data.forEach((key, value) {
      if (value is List) {
        final messages = value.map((v) => v.toString()).toList();
        fieldErrors[key] = messages;
        displayMessages.addAll(messages);
      } else if (value is String) {
        fieldErrors[key] = [value];
        displayMessages.add(value);
      } else {
        final message = value.toString();
        fieldErrors[key] = [message];
        displayMessages.add(message);
      }
    });
  }

  static void _parseList(
    List<dynamic> data,
    Map<String, List<String>> fieldErrors,
    List<String> generalErrors,
    List<String> displayMessages,
  ) {
    for (final item in data) {
      final message = item.toString();
      final match = _fieldPrefixPattern.firstMatch(message);
      if (match != null) {
        final field = match.group(1)!;
        final errorMsg = match.group(2)!;
        fieldErrors.putIfAbsent(field, () => []).add(errorMsg);
        displayMessages.add(errorMsg);
      } else {
        generalErrors.add(message);
        displayMessages.add(message);
      }
    }
  }

  static void _parseRawMessage(
    String message,
    Map<String, List<String>> fieldErrors,
    List<String> generalErrors,
    List<String> displayMessages,
  ) {
    final lines = message.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final match = _fieldPrefixPattern.firstMatch(line.trim());
      if (match != null) {
        final field = match.group(1)!;
        final errorMsg = match.group(2)!;
        fieldErrors.putIfAbsent(field, () => []).add(errorMsg);
        displayMessages.add(errorMsg);
      } else {
        generalErrors.add(line.trim());
        displayMessages.add(line.trim());
      }
    }
  }
}
