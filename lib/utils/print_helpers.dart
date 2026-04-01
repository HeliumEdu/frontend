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
typedef PdfPdfPageBreakHintsProvider = List<double> Function(RenderBox captureBox);

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

  // Stored once so register/unregister use the same closure identity.
  // Dart method tear-offs are not referentially identical across evaluations,
  // so storing the reference is required for removeWhere(identical) to work.
  late final PrintHandler _registeredHandler;

  // When true, child is rendered with unconstrained height so that content
  // taller than the viewport (e.g. a paginated data grid) renders fully before
  // the screenshot is taken.
  bool _capturePending = false;

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

    // Unconstrain height so bounded children (e.g. Expanded grids) render at
    // their full natural height before the screenshot is taken.
    // Both flags must flip synchronously before any endOfFrame await —
    // _capturePending expands OverflowBox while capturing triggers
    // Column/grid layout changes, and they must be consistent on the same frame.
    setState(() => _capturePending = true);
    PrintableArea.capturing.value = true;
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    // Force light mode so the PDF doesn't render with dark colors.
    // AnimatedTheme (inside MaterialApp) has a 200ms crossfade; wait long
    // enough for it to fully complete before taking the screenshot.
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

      // Yield a frame so PrintHidden widgets and layout changes re-render
      // before the screenshot. Also lets the loading spinner paint first.
      await WidgetsBinding.instance.endOfFrame;
      if (kIsWeb) await Future.delayed(const Duration(milliseconds: 50));

      // Lower pixel ratio on web — CanvasKit rasterization is synchronous and
      // scales quadratically; 1.5 is ~2.5× faster than 2.0.
      const double pixelRatio = kIsWeb ? 1.5 : 2.0;

      // Collect row-boundary hints while the render tree is stable (before
      // the costly toImage() GPU readback). Each provider returns logical-pixel
      // Y positions; convert to image pixels by applying the pixel ratio.
      final logicalHints = <double>[
        for (final provider in _hintsProviders) ...provider(boundary),
      ];
      final imageBoundaries = logicalHints.map((y) => y * pixelRatio).toList()
        ..sort();

      final image = await boundary.toImage(pixelRatio: pixelRatio);

      // 0.5-inch margins on all sides. Letter is used rather than A4 because
      // A4 (11.69") is taller than Letter (11"), causing the OS to clip ~0.69"
      // from the bottom when printing on US Letter paper — eating almost all
      // of any bottom margin buffer.
      const double margin = PdfPageFormat.inch * 0.5;

      // Use US Letter in the orientation that best fits the content.
      final bool isLandscape = image.width > image.height;
      final PdfPageFormat baseFormat =
          isLandscape ? PdfPageFormat.letter.landscape : PdfPageFormat.letter;
      final pdfPageFormat = PdfPageFormat(
        baseFormat.width,
        baseFormat.height,
        marginAll: margin,
      );

      // Scale image to fit the content width (page minus margins).
      final double contentWidthPt = pdfPageFormat.availableWidth;
      final double contentHeightPt = pdfPageFormat.availableHeight;
      final double scale = contentWidthPt / image.width;

      // Maximum image pixels that fit in one page's content area.
      final double pdfPageHeightPx = contentHeightPt / scale;

      final document = pw.Document();
      double startPx = 0;
      int pdfPageIndex = 0;

      while (startPx < image.height) {
        double endPx =
            (startPx + pdfPageHeightPx).clamp(0.0, image.height.toDouble());

        // Snap the page break to the last row boundary that fits within this
        // page so we never cut through a row. Skip snapping on the final page
        // (endPx == image.height) since nothing follows it.
        if (imageBoundaries.isNotEmpty && endPx < image.height) {
          final snapped = imageBoundaries
              .where((b) => b > startPx && b <= endPx)
              .fold<double>(0, (prev, b) => b > prev ? b : prev);
          if (snapped > startPx) endPx = snapped;
        }

        final int sliceHeightPx = (endPx - startPx).ceil();
        if (sliceHeightPx <= 0) break;

        // Crop this page's slice from the full screenshot.
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(
          recorder,
          ui.Rect.fromLTWH(
              0, 0, image.width.toDouble(), sliceHeightPx.toDouble()),
        );
        canvas.drawImageRect(
          image,
          ui.Rect.fromLTWH(
              0, startPx, image.width.toDouble(), sliceHeightPx.toDouble()),
          ui.Rect.fromLTWH(
              0, 0, image.width.toDouble(), sliceHeightPx.toDouble()),
          ui.Paint(),
        );
        final picture = recorder.endRecording();
        final sliceImage = await picture.toImage(image.width, sliceHeightPx);
        final sliceData =
            await sliceImage.toByteData(format: ui.ImageByteFormat.png);
        if (sliceData == null) throw Exception('Failed to encode page $pdfPageIndex');
        // Yield a frame after each blocking PNG encode so the loading spinner
        // can animate between pages rather than freezing for the full duration.
        await WidgetsBinding.instance.endOfFrame;

        final slicePngBytes = sliceData.buffer.asUint8List();
        final sliceHeightPt = sliceHeightPx * scale;

        document.addPage(
          pw.Page(
            pageFormat: pdfPageFormat,
            build: (ctx) => pw.Align(
              alignment: pw.Alignment.topLeft,
              child: pw.Image(
                pw.MemoryImage(slicePngBytes),
                width: contentWidthPt,
                height: sliceHeightPt,
                fit: pw.BoxFit.fill,
              ),
            ),
          ),
        );

        startPx = endPx;
        pdfPageIndex++;
      }

      return document.save();
    } finally {
      PrintableArea.capturing.value = false;
      if (wasDark) await themeNotifier.setThemeMode(originalMode);
      if (mounted) setState(() => _capturePending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // OverflowBox is always present to keep RepaintBoundary at a stable tree
    // position — changing the structure around a GlobalKey element during layout
    // (e.g. inside SfDataGrid's LayoutBuilder) causes element lifecycle failures.
    // maxHeight: null passes through parent constraints (no-op); double.infinity
    // unconstrain the boundary so toImage() captures full natural content height.
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
