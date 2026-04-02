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

/// Provides page-break Y positions (in logical pixels, relative to the
/// [RenderBox] of the [PrintableArea]'s capture boundary) where it is safe
/// to slice the screenshot between pages. Each value marks the gap between
/// two rows, so the slicer never cuts through a row.
typedef PdfPageBreakHintsProvider = List<double> Function(RenderBox captureBox);

/// Computes page-break Y positions for a fixed-row-height [SfDataGrid].
///
/// Returns logical-pixel Y positions (relative to [captureBox]) after each
/// data row, so the PDF slicer avoids cutting through a row. [gridKey] must
/// be attached to the container wrapping the grid. [headerRowHeight] and
/// [rowHeight] default to the SfDataGrid defaults used throughout the app.
List<double> dataGridPdfPageBreakHints(
  RenderBox captureBox,
  GlobalKey gridKey, {
  double headerRowHeight = 40,
  double rowHeight = 50,
}) {
  final gridBox = gridKey.currentContext?.findRenderObject() as RenderBox?;
  if (gridBox == null || !gridBox.hasSize) return [];
  final gridTop =
      captureBox.globalToLocal(gridBox.localToGlobal(Offset.zero)).dy;
  final gridHeight = gridBox.size.height;
  final boundaries = <double>[];
  double y = gridTop + headerRowHeight + rowHeight;
  while (y <= gridTop + gridHeight) {
    boundaries.add(y);
    y += rowHeight;
  }
  return boundaries;
}

/// Exposes [PrintableArea]'s page-break hint registration to descendants.
///
/// Data-grid widgets that want row-aware page breaking call
/// [registerHintsProvider] in [State.initState] and
/// [unregisterHintsProvider] in [State.dispose].
class PrintableAreaScope extends InheritedWidget {
  final void Function(PdfPageBreakHintsProvider) _register;
  final void Function(PdfPageBreakHintsProvider) _unregister;

  const PrintableAreaScope._({
    required super.child,
    required void Function(PdfPageBreakHintsProvider) register,
    required void Function(PdfPageBreakHintsProvider) unregister,
  })  : _register = register,
        _unregister = unregister;

  /// Returns the nearest [PrintableAreaScope] without establishing a rebuild
  /// dependency — suitable for one-time registration in [State.initState].
  static PrintableAreaScope? findIn(BuildContext context) =>
      context.findAncestorWidgetOfExactType<PrintableAreaScope>();

  void registerHintsProvider(PdfPageBreakHintsProvider provider) =>
      _register(provider);

  void unregisterHintsProvider(PdfPageBreakHintsProvider provider) =>
      _unregister(provider);

  @override
  bool updateShouldNotify(PrintableAreaScope oldWidget) => false;
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

/// A [PrintableArea] that lays out a [header] above a [body] in a [Column]
/// whose [MainAxisSize] and the body's [FlexFit] switch automatically during
/// a capture.
///
/// During normal rendering the column fills its parent ([MainAxisSize.max],
/// [FlexFit.tight]); during a screenshot capture it shrinks to content
/// ([MainAxisSize.min], [FlexFit.loose]) so the full height is captured.
class PrintableFlexColumn extends StatelessWidget {
  final WidgetBuilder header;
  final WidgetBuilder body;

  const PrintableFlexColumn({
    super.key,
    required this.header,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return PrintableArea(
      child: ValueListenableBuilder<bool>(
        valueListenable: PrintableArea.capturing,
        builder: (context, isCapturing, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: isCapturing ? MainAxisSize.min : MainAxisSize.max,
          children: [
            header(context),
            Flexible(
              fit: isCapturing ? FlexFit.loose : FlexFit.tight,
              child: body(context),
            ),
          ],
        ),
      ),
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
  final List<PdfPageBreakHintsProvider> _hintsProviders = [];

  void _registerHintsProvider(PdfPageBreakHintsProvider p) =>
      _hintsProviders.add(p);

  void _unregisterHintsProvider(PdfPageBreakHintsProvider p) =>
      _hintsProviders.removeWhere((e) => identical(e, p));

  // Stored once — Dart method tear-offs aren't referentially identical across
  // evaluations, so identity-based unregister requires a stable reference.
  late final PrintHandler _registeredHandler;

  bool _capturePending = false;

  @override
  void initState() {
    super.initState();
    if (PrintService.isSupported) {
      _registeredHandler = _printArea;
      PrintService().register(_registeredHandler);
    }
  }

  @override
  void dispose() {
    if (PrintService.isSupported) PrintService().unregister(_registeredHandler);
    super.dispose();
  }

  Future<void> _printArea() async {
    final themeNotifier = ThemeNotifier();
    final originalMode = themeNotifier.themeMode;
    final wasDark = themeNotifier.isDarkMode;

    // Both flags must flip before any endOfFrame await — _capturePending
    // unconstrain the OverflowBox; capturing switches layout/grid modes.
    // They must be consistent on the same frame before content settles.
    setState(() => _capturePending = true);
    PrintableArea.capturing.value = true;
    await WidgetsBinding.instance.endOfFrame;
    // Second frame: Syncfusion and OverflowBox layout changes can each trigger
    // a dependent layout pass, so a single frame isn't always enough to settle.
    await WidgetsBinding.instance.endOfFrame;

    // Force light mode. AnimatedTheme has a 200ms crossfade; 250ms ensures it completes.
    if (wasDark) {
      await themeNotifier.setThemeMode(ThemeMode.light);
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (!mounted) {
      PrintableArea.capturing.value = false;
      setState(() => _capturePending = false);
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

      // Yield a frame for PrintHidden/layout re-renders and loading spinner.
      await WidgetsBinding.instance.endOfFrame;
      // CanvasKit rasterization is synchronous and scales quadratically;
      // 1.5 is ~2.5× faster than 2.0 with negligible quality difference on web.
      if (kIsWeb) await Future.delayed(const Duration(milliseconds: 50));

      const double pixelRatio = kIsWeb ? 1.5 : 2.0;

      // Collect hints before the costly toImage() GPU readback;
      // convert logical px to image px by applying the pixel ratio.
      final logicalHints = <double>[
        for (final provider in _hintsProviders) ...provider(boundary),
      ];
      final imageBoundaries = logicalHints.map((y) => y * pixelRatio).toList()
        ..sort();

      final image = await boundary.toImage(pixelRatio: pixelRatio);

      // 0.5-inch margins. Letter rather than A4: A4 (11.69") is taller than
      // Letter (11"), causing the OS to clip the bottom on US Letter printers.
      const double margin = PdfPageFormat.inch * 0.5;
      final bool isLandscape = image.width > image.height;
      final PdfPageFormat baseFormat =
          isLandscape ? PdfPageFormat.letter.landscape : PdfPageFormat.letter;
      final pdfPageFormat = PdfPageFormat(
        baseFormat.width,
        baseFormat.height,
        marginAll: margin,
      );

      final document = pw.Document();
      await _buildPdfPages(document, image, pdfPageFormat, imageBoundaries);
      return document.save();
    } finally {
      PrintableArea.capturing.value = false;
      if (wasDark) await themeNotifier.setThemeMode(originalMode);
      if (mounted) setState(() => _capturePending = false);
    }
  }

  /// Slices [image] into page-height chunks and adds each as a [pw.Page] to
  /// [document]. [imageBoundaries] are image-pixel Y positions of safe row
  /// boundaries; the slicer snaps to the last one that fits each page so it
  /// never cuts through a data-grid row.
  Future<void> _buildPdfPages(
    pw.Document document,
    ui.Image image,
    PdfPageFormat pdfPageFormat,
    List<double> imageBoundaries,
  ) async {
    final double contentWidthPt = pdfPageFormat.availableWidth;
    final double contentHeightPt = pdfPageFormat.availableHeight;
    final double scale = contentWidthPt / image.width;
    final double pdfPageHeightPx = contentHeightPt / scale;

    double startPx = 0;
    int pageIndex = 0;

    while (startPx < image.height) {
      double endPx =
          (startPx + pdfPageHeightPx).clamp(0.0, image.height.toDouble());

      // Snap to the last row boundary within this page (skip on final page).
      if (imageBoundaries.isNotEmpty && endPx < image.height) {
        final snapped = imageBoundaries
            .where((b) => b > startPx && b <= endPx)
            .fold<double>(0, (prev, b) => b > prev ? b : prev);
        if (snapped > startPx) endPx = snapped;
      }

      final int sliceHeightPx = (endPx - startPx).ceil();
      if (sliceHeightPx <= 0) break;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        ui.Rect.fromLTWH(0, 0, image.width.toDouble(), sliceHeightPx.toDouble()),
      );
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, startPx, image.width.toDouble(), sliceHeightPx.toDouble()),
        ui.Rect.fromLTWH(0, 0, image.width.toDouble(), sliceHeightPx.toDouble()),
        ui.Paint(),
      );
      final sliceImage = await recorder.endRecording().toImage(image.width, sliceHeightPx);
      final sliceData = await sliceImage.toByteData(format: ui.ImageByteFormat.png);
      if (sliceData == null) throw Exception('Failed to encode page $pageIndex');
      // Yield between pages so the loading spinner can animate.
      await WidgetsBinding.instance.endOfFrame;

      document.addPage(
        pw.Page(
          pageFormat: pdfPageFormat,
          build: (ctx) => pw.Align(
            alignment: pw.Alignment.topLeft,
            child: pw.Image(
              pw.MemoryImage(sliceData.buffer.asUint8List()),
              width: contentWidthPt,
              height: sliceHeightPx * scale,
              fit: pw.BoxFit.fill,
            ),
          ),
        ),
      );

      startPx = endPx;
      pageIndex++;
    }
  }

  @override
  Widget build(BuildContext context) {
    // OverflowBox is always present — removing it during capture would change
    // the GlobalKey element's tree position, causing lifecycle failures in
    // SfDataGrid. maxHeight: null = no-op; double.infinity = unconstrained.
    return PrintableAreaScope._(
      register: _registerHintsProvider,
      unregister: _unregisterHintsProvider,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxHeight: _capturePending ? double.infinity : null,
          child: RepaintBoundary(key: _repaintKey, child: widget.child),
        ),
      ),
    );
  }
}
