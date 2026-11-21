import 'dart:convert';
import 'dart:ui';

import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/note_pdf_helpers.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final platformDispatcher =
      TestWidgetsFlutterBinding.instance.platformDispatcher;

  tearDown(platformDispatcher.clearLocaleTestValue);

  group('PrintableArea.defaultPageFormat', () {
    test('starts on US Letter in a Letter region', () {
      // GIVEN
      platformDispatcher.localeTestValue = const Locale('en', 'US');

      // WHEN
      final format = PrintableArea.defaultPageFormat;

      // THEN
      expect(format, PdfPageFormat.letter);
    });

    test('starts on A4 outside the Letter regions', () {
      // GIVEN
      platformDispatcher.localeTestValue = const Locale('en', 'GB');

      // WHEN
      final format = PrintableArea.defaultPageFormat;

      // THEN
      expect(format, PdfPageFormat.a4);
    });

    test('starts on A4 when the locale names no region', () {
      // GIVEN
      platformDispatcher.localeTestValue = const Locale('en');

      // WHEN
      final format = PrintableArea.defaultPageFormat;

      // THEN
      expect(format, PdfPageFormat.a4);
    });
  });

  group('NotePdfHelpers.buildNotePdf', () {
    final delta = Delta()
      ..insert('Bold', {'bold': true})
      ..insert('\n');

    test('lays the note out on the paper it is given', () async {
      // WHEN
      final letter = await NotePdfHelpers.buildNotePdf(
        delta,
        PdfPageFormat.letter,
      );
      final a4 = await NotePdfHelpers.buildNotePdf(delta, PdfPageFormat.a4);

      // THEN
      expect(_mediaBox(letter), ['0', '0', '612', '792']);
      expect(_mediaBox(a4).map((value) => double.parse(value).round()), [
        0,
        0,
        595,
        842,
      ]);
    });
  });
}

List<String> _mediaBox(List<int> pdf) {
  final match = RegExp(
    r'/MediaBox\s*\[([^\]]*)\]',
  ).firstMatch(latin1.decode(pdf))!;
  return match.group(1)!.trim().split(RegExp(r'\s+'));
}
