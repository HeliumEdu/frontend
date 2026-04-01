// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:heliumapp/config/theme_notifier.dart';
import 'package:heliumapp/utils/print_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Opens a full-screen PDF preview dialog immediately, showing a loading
/// spinner while [pdfBytesFuture] resolves. Once the bytes are ready the
/// spinner is replaced by a [PdfPreview], with print and share actions in the
/// app bar.
Future<void> showPdfPreview(
  BuildContext context, {
  required Future<Uint8List> pdfBytesFuture,
  String title = '',
  String? filename,
}) async {
  final pdfFilename =
      filename ?? (title.isNotEmpty ? '$title.pdf' : 'print.pdf');

  await showDialog(
    context: context,
    builder: (dialogContext) => _PdfPreviewDialog(
      pdfBytesFuture: pdfBytesFuture,
      title: title,
      pdfFilename: pdfFilename,
    ),
  );
}

class _PdfPreviewDialog extends StatefulWidget {
  final Future<Uint8List> pdfBytesFuture;
  final String title;
  final String pdfFilename;

  const _PdfPreviewDialog({
    required this.pdfBytesFuture,
    required this.title,
    required this.pdfFilename,
  });

  @override
  State<_PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<_PdfPreviewDialog> {
  Uint8List? _pdfBytes;
  Object? _error;

  @override
  void initState() {
    super.initState();
    widget.pdfBytesFuture.then((bytes) {
      if (mounted) setState(() => _pdfBytes = bytes);
    }).catchError((Object error) {
      if (mounted) setState(() => _error = error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasBytes = _pdfBytes != null;
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
          title: Text(widget.title.isNotEmpty ? widget.title : 'Preview'),
          actions: hasBytes
              ? [
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share',
                    onPressed: () async {
                      await Printing.sharePdf(
                        bytes: _pdfBytes!,
                        filename: widget.pdfFilename,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.print),
                    tooltip: 'Print',
                    onPressed: () async {
                      await Printing.layoutPdf(
                        onLayout: (_) async => _pdfBytes!,
                        name: widget.title.isNotEmpty
                            ? widget.title
                            : 'Document',
                      );
                    },
                  ),
                ]
              : null,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return const Center(child: Text('Failed to generate PDF.'));
    }
    if (_pdfBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PdfPreview(
      build: (format) async => _pdfBytes!,
      useActions: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
    );
  }
}

/// A widget that hides its child during a [PrintableArea] capture.
///
/// Wrap any button or interactive element that should be excluded from the
/// printed output. Reacts to [PrintableArea.capturing] — no additional wiring
/// required.
class PrintHidden extends StatelessWidget {
  final Widget child;

  const PrintHidden({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PrintableArea.capturing,
      builder: (context, isCapturing, _) =>
          isCapturing ? const SizedBox.shrink() : child,
    );
  }
}

/// Wraps [child] in a [RepaintBoundary] and auto-registers a print handler
/// with [PrintService] for the duration the widget is in the tree.
///
/// On supported platforms (web and desktop), Cmd+P / Ctrl+P triggers an
/// immediate PDF preview dialog. The capture renders at the current viewport
/// width — size the browser/window as desired before printing. Dark mode is
/// suppressed during capture so the PDF renders with a light background.
///
/// On mobile this widget is a transparent passthrough; print is not registered.
///
/// Wrap any element that should be excluded from the printed output with
/// [PrintHidden] — it will hide itself automatically during capture.
class PrintableArea extends StatefulWidget {
  /// Notifier that is `true` for the duration of a screenshot capture.
  /// [PrintHidden] listens to this; other widgets can too for custom behavior.
  static final ValueNotifier<bool> capturing = ValueNotifier(false);

  final Widget child;

  const PrintableArea({super.key, required this.child});

  @override
  State<PrintableArea> createState() => _PrintableAreaState();
}

class _PrintableAreaState extends State<PrintableArea> {
  final GlobalKey _repaintKey = GlobalKey();

  // Stored once so register/unregister use the same closure identity.
  // Dart method tear-offs are not referentially identical across evaluations,
  // so storing the reference is required for removeWhere(identical) to work.
  late final PrintHandler _registeredHandler;

  static bool get _isSupported =>
      kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_isSupported) {
      _registeredHandler = _printArea;
      PrintService().register(_registeredHandler);
    }
  }

  @override
  void dispose() {
    if (_isSupported) PrintService().unregister(_registeredHandler);
    super.dispose();
  }

  Future<void> _printArea() async {
    final themeNotifier = ThemeNotifier();
    final originalMode = themeNotifier.themeMode;
    final wasDark = themeNotifier.isDarkMode;

    // Force light mode so the PDF doesn't render with dark colors.
    if (wasDark) {
      await themeNotifier.setThemeMode(ThemeMode.light);
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
    }

    if (!mounted) {
      if (wasDark) await themeNotifier.setThemeMode(originalMode);
      return;
    }

    final pdfBytesFuture = _captureAndBuildPdf(
      themeNotifier: themeNotifier,
      originalMode: originalMode,
      wasDark: wasDark,
    );

    await showPdfPreview(context, pdfBytesFuture: pdfBytesFuture);
  }

  Future<Uint8List> _captureAndBuildPdf({
    required ThemeNotifier themeNotifier,
    required ThemeMode originalMode,
    required bool wasDark,
  }) async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('RepaintBoundary not available');

      // Hide PrintHidden widgets and yield a frame so they re-render before
      // the screenshot. The same yield lets the loading spinner paint first.
      PrintableArea.capturing.value = true;
      await WidgetsBinding.instance.endOfFrame;
      if (kIsWeb) await Future.delayed(const Duration(milliseconds: 50));

      // Lower pixel ratio on web — CanvasKit rasterization is synchronous and
      // scales quadratically; 1.5 is ~2.5× faster than 2.0.
      const double pixelRatio = kIsWeb ? 1.5 : 2.0;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode screenshot');

      final pngBytes = byteData.buffer.asUint8List();
      final pdfImage = pw.MemoryImage(pngBytes);

      // Use standard A4 (no margins) in the orientation that best fits the
      // content so the OS print dialog and PdfPreview agree on page size.
      // PdfPageFormat.a4 has 2cm built-in margins that would shrink the content
      // area; zeroing them ensures the image fills the full page.
      final bool isLandscape = image.width > image.height;
      final PdfPageFormat baseFormat =
          isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
      final pageFormat = PdfPageFormat(
        baseFormat.width,
        baseFormat.height,
        marginAll: 0,
      );

      final document = pw.Document();
      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (ctx) => pw.Image(pdfImage, fit: pw.BoxFit.contain),
        ),
      );

      return document.save();
    } finally {
      PrintableArea.capturing.value = false;
      if (wasDark) await themeNotifier.setThemeMode(originalMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(key: _repaintKey, child: widget.child);
  }
}
