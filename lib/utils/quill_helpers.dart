// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

/// Extracts plain text from a Quill Delta JSON map.
/// Returns empty string if notes is null or malformed.
String extractNotesPlainText(Map<String, dynamic>? notes) {
  if (notes == null) return '';
  final ops = notes['ops'];
  if (ops is! List) return '';

  final buffer = StringBuffer();
  for (final op in ops) {
    if (op is Map && op['insert'] is String) {
      buffer.write(op['insert']);
    }
  }
  return buffer.toString();
}

/// Checks if a Quill Delta JSON map represents empty content.
/// Returns true if notes is null, has no ops, or only contains a newline.
bool isNotesEmpty(Map<String, dynamic>? notes) {
  if (notes == null) return true;
  final ops = notes['ops'];
  if (ops is! List || ops.isEmpty) return true;
  if (ops.length == 1 && ops[0]['insert'] == '\n') return true;
  return false;
}
