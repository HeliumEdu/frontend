// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
// ignore: implementation_imports
import 'package:flutter_quill/src/l10n/generated/quill_localizations_en.dart';

class HeliumQuillLocalizations extends FlutterQuillLocalizationsEn {
  HeliumQuillLocalizations([super.locale = 'en']);

  @override
  String get pleaseEnterTheLinkURL => 'Link URL';

  @override
  String get pleaseEnterTextForYourLink => 'Link text';
}

class HeliumQuillLocalizationsDelegate
    extends LocalizationsDelegate<FlutterQuillLocalizations> {
  const HeliumQuillLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<FlutterQuillLocalizations> load(Locale locale) =>
      SynchronousFuture(HeliumQuillLocalizations(locale.toString()));

  @override
  bool shouldReload(covariant LocalizationsDelegate<FlutterQuillLocalizations> old) => false;
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

/// Converts checkbox list items in [delta] to plain paragraphs prefixed with
/// ☑ or ☐ so they render reliably in PDF output without requiring an
/// experimental iconsFont. The [list] block attribute is stripped so the PDF
/// renderer treats the line as a normal paragraph.
Delta resolveCheckboxesForPdf(Delta delta) {
  final ops = delta.toJson();
  final result = <Map<String, dynamic>>[];
  int paragraphStart = 0;

  for (final raw in ops) {
    final op = Map<String, dynamic>.from(raw as Map);
    final insert = op['insert'];
    final attrs = (op['attributes'] as Map?)?.cast<String, dynamic>();
    final list = attrs?['list'] as String?;

    if (insert == '\n' && (list == 'checked' || list == 'unchecked')) {
      final symbol = list == 'checked' ? '☑ ' : '☐ ';
      if (paragraphStart < result.length &&
          result[paragraphStart]['insert'] is String) {
        final first = Map<String, dynamic>.from(result[paragraphStart]);
        first['insert'] = symbol + (first['insert'] as String);
        result[paragraphStart] = first;
      } else {
        // Empty checkbox line; insert the symbol as its own op.
        result.insert(paragraphStart, {'insert': symbol.trim()});
      }
      final newAttrs = Map<String, dynamic>.from(attrs!)..remove('list');
      result.add({
        'insert': '\n',
        if (newAttrs.isNotEmpty) 'attributes': newAttrs,
      });
      paragraphStart = result.length;
    } else {
      result.add(op);
      if (insert == '\n') paragraphStart = result.length;
    }
  }

  return Delta.fromJson(result);
}

/// Returns true if [change] was triggered by the user (not programmatic),
/// indicating the document has been meaningfully edited.
bool isNoteEdited(DocChange change) => change.source == ChangeSource.local;

/// Builds a Quill Delta JSON map from a QuillController.
/// Returns null if the content is empty (only whitespace/newline).
Map<String, dynamic>? buildNotesDelta(QuillController controller) {
  final delta = controller.document.toDelta();
  final ops = delta.toJson();
  if (ops.isEmpty || (ops.length == 1 && ops[0]['insert'] == '\n')) {
    return null;
  }
  return {'ops': ops};
}
