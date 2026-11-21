import 'package:flutter/services.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class NotePdfHelpers {
  NotePdfHelpers._();

  static Future<Uint8List> buildNotePdf(
    Delta delta,
    PdfPageFormat format,
  ) async {
    final [regular, bold, italic, boldItalic] = await Future.wait([
      for (final name in [
        'NotoSans-Regular',
        'NotoSans-Bold',
        'NotoSans-Italic',
        'NotoSans-BoldItalic',
      ])
        _loadFont(name),
    ]);

    final converter = PDFConverter(
      pageFormat: PDFPageFormat.all(
        width: format.width,
        height: format.height,
        margin: 2 * PDFPageFormat.cm,
      ),
      document: delta,
      fallbacks: [regular],
      // ignore: experimental_member_use
      listLeadingBuilder: _buildPdfCheckbox,
      themeData: pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        italic: italic,
        boldItalic: boldItalic,
      ),
      onRequestFontFamily: (_) => FontFamilyResponse(
        fontNormalV: regular,
        boldFontV: bold,
        italicFontV: italic,
        boldItalicFontV: boldItalic,
      ),
    );

    final document = await converter.createDocument();
    if (document == null) throw Exception('Failed to create PDF.');
    return document.save();
  }

  static Future<pw.Font> _loadFont(String name) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$name.ttf'));

  static pw.Widget? _buildPdfCheckbox(
    String type,
    int indentLevel,
    Object? extraArgs,
  ) {
    final isChecked = type == 'checked';
    final isUnchecked = type == 'unchecked';
    if (!isChecked && !isUnchecked) return null;

    const double size = 10;
    const double stroke = 1.0;
    return pw.Container(
      width: size,
      height: size,
      margin: const pw.EdgeInsets.only(top: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: stroke),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: isChecked
          ? pw.CustomPaint(
              size: const PdfPoint(size - stroke * 2, size - stroke * 2),
              painter: (canvas, size) {
                final w = size.x;
                final h = size.y;
                canvas
                  ..setLineWidth(1.5)
                  ..setLineCap(PdfLineCap.round)
                  ..setLineJoin(PdfLineJoin.round)
                  ..drawLine(w * 0.15, h * 0.50, w * 0.40, h * 0.20)
                  ..drawLine(w * 0.40, h * 0.20, w * 0.85, h * 0.80)
                  ..strokePath();
              },
            )
          : null,
    );
  }
}
