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

  /// Get the first error for a specific field, or null if none
  String? getFieldError(String fieldName) {
    final errors = fieldErrors[fieldName];
    return (errors?.isNotEmpty ?? false) ? errors!.first : null;
  }
}

/// Utility class for parsing API error responses into structured errors
class ApiErrorParser {
  // Pattern to match "field_name: error message" format from API
  static final _fieldPrefixPattern = RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*): (.+)$');

  /// Parses a raw API error response into a structured [ParsedApiError].
  ///
  /// The [responseData] can be:
  /// - A Map with field names as keys and error messages as values
  /// - A List of error messages
  /// - A String error message
  ///
  /// Field and list messages are `{"message", "code"}` objects, and a
  /// `{"detail"}` body carries its `code` alongside; plain strings come from a
  /// platform that predates error codes.
  static ParsedApiError parse(dynamic responseData) {
    final fieldErrors = <String, List<String>>{};
    final generalErrors = <String>[];
    final displayMessages = <String>[];

    if (responseData is Map<String, dynamic>) {
      _parseMap(responseData, fieldErrors, displayMessages);
    } else if (responseData is List) {
      _parseList(responseData, fieldErrors, generalErrors, displayMessages);
    } else if (responseData is String) {
      _parseRawMessage(responseData, fieldErrors, generalErrors, displayMessages);
    }

    return ParsedApiError(
      fieldErrors: fieldErrors,
      generalErrors: generalErrors,
      displayMessage: displayMessages.join('\n'),
    );
  }

  static void _parseMap(
    Map<String, dynamic> data,
    Map<String, List<String>> fieldErrors,
    List<String> displayMessages,
  ) {
    data.forEach((key, value) {
      if (key == 'code' && data.containsKey('detail')) return;

      final message = value is String ? value : _messageOf(value);
      if (value is List) {
        final messages = value.expand<String>(_flatten).toList();
        fieldErrors[key] = messages;
        displayMessages.addAll(messages);
      } else if (message != null) {
        fieldErrors[key] = [message];
        displayMessages.add(message);
      } else {
        final messages = _flatten(value, key);
        fieldErrors[key] = messages;
        displayMessages.addAll(messages);
      }
    });
  }

  /// Flattens nested DRF errors (`{"courses": {"1": {"start_date": [...]}}}`)
  /// into lines; without this they reach the user as a raw Dart map.
  static List<String> _flatten(dynamic value, [String prefix = '']) {
    final message = _messageOf(value);
    if (message != null) {
      return [prefix.isEmpty ? message : '$prefix: $message'];
    }

    if (value is Map) {
      final lines = <String>[];
      value.forEach((key, nested) {
        final label = prefix.isEmpty ? '$key' : '$prefix $key';
        lines.addAll(_flatten(nested, label));
      });
      return lines;
    }

    if (value is List) {
      return value.expand((v) => _flatten(v, prefix)).toList();
    }

    return [prefix.isEmpty ? '$value' : '$prefix: $value'];
  }

  static void _parseList(
    List<dynamic> data,
    Map<String, List<String>> fieldErrors,
    List<String> generalErrors,
    List<String> displayMessages,
  ) {
    for (final item in data) {
      final message = _messageOf(item) ?? item;
      if (message is Map<String, dynamic>) {
        _parseMap(message, fieldErrors, displayMessages);
      } else if (message is String) {
        final match = _fieldPrefixPattern.firstMatch(message.trim());
        if (match != null) {
          final field = match.group(1)!;
          final errorMsg = match.group(2)!;
          fieldErrors.putIfAbsent(field, () => []).add(errorMsg);
          displayMessages.add(errorMsg);
        } else {
          generalErrors.add(message.trim());
          displayMessages.add(message.trim());
        }
      } else {
        generalErrors.add(message.toString());
        displayMessages.add(message.toString());
      }
    }
  }

  static String? _messageOf(dynamic value) =>
      value is Map && value.length == 2 && value['message'] is String && value.containsKey('code')
          ? value['message'] as String
          : null;

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
