// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/quill_helpers.dart';

void main() {
  group('tryParseNotesDocument', () {
    test('parses already-terminated content unchanged', () {
      final doc = tryParseNotesDocument({
        'ops': [
          {'insert': 'Hello\n'}
        ]
      });

      expect(doc, isNotNull);
      expect(doc!.toPlainText(), 'Hello\n');
    });

    test('repairs content that does not end in a newline', () {
      // An un-terminated delta parses into a child-less document that crashes
      // flutter_quill on tap; the repair appends the required trailing newline.
      final doc = tryParseNotesDocument({
        'ops': [
          {'insert': 'Hello'}
        ]
      });

      expect(doc, isNotNull);
      final lastInsert = doc!.toDelta().toList().last.data as String;
      expect(lastInsert.endsWith('\n'), isTrue);
      expect(doc.toPlainText(), 'Hello\n');
    });

    test('returns null for empty ops so the caller shows a placeholder', () {
      expect(tryParseNotesDocument({'ops': <dynamic>[]}), isNull);
    });

    test('returns null when notes is null', () {
      expect(tryParseNotesDocument(null), isNull);
    });
  });
}
