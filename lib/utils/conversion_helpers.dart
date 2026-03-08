// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/data/models/base_model.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';

double? toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? toInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

List<IdOrEntity<T>> idOrEntityListFrom<T extends BaseModel>(
  List<dynamic> data,
  Function fromJson,
) {
  return data.map((item) => IdOrEntity<T>.from(item, fromJson)).toList();
}

IdOrEntity<T> idOrEntityFrom<T extends BaseModel>(
  dynamic data,
  Function fromJson,
) {
  return IdOrEntity<T>.from(data, fromJson);
}

/// Converts legacy HTML to a plain-text Quill [Document] by stripping tags and
/// decoding entities. HTML formatting (bold, italic, etc.) is not preserved —
/// users can re-apply it in the new editor after the first save migrates the
/// item to Notes. Used during the migration period while `comments`/`details`
/// fields still exist.
// TODO: Remove once `comments`/`details` are retired.
Document htmlToQuillDocument(String html) {
  final text = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  if (text.isEmpty) return Document();
  return Document.fromJson([
    {'insert': '$text\n'},
  ]);
}
