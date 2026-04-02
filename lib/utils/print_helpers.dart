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
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/theme_notifier.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/print_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ── Internal capture result ───────────────────────────────────────────────────

typedef _CaptureResult = ({ui.Image image, List<double> imageBoundaries});

// ── PDF page slicing (top-level so both dialog and tests can reach it) ────────

/// Slices [image] into page-height chunks and adds each as a [pw.Page].
/// [imageBoundaries] are image-pixel Y positions of safe row boundaries;
/// the slicer snaps each cut to the last boundary that fits a page.
Future<void> _sliceImageToPdf(
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
      final candidates = imageBoundaries
          .where((b) => b > startPx && b <= endPx)
          .toList()
        ..sort();

      if (candidates.isNotEmpty) {
        double snap = candidates.last;

        // If no boundaries follow snap, the next page would contain only a
        // footer. Back up one row so at least one row accompanies the footer.
        final hasLaterBoundary = imageBoundaries.any((b) => b > snap);
        if (!hasLaterBoundary && candidates.length > 1) {
          snap = candidates[candidates.length - 2];
        }

        endPx = snap;
      }
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
      ui.Rect.fromLTWH(
          0, startPx, image.width.toDouble(), sliceHeightPx.toDouble()),
      ui.Rect.fromLTWH(
          0, 0, image.width.toDouble(), sliceHeightPx.toDouble()),
      ui.Paint(),
    );
    final sliceImage = await recorder
        .endRecording()
        .toImage(image.width, sliceHeightPx);
    final sliceData =
        await sliceImage.toByteData(format: ui.ImageByteFormat.png);
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

// ── Public preview entry points ───────────────────────────────────────────────

/// Opens a full-screen PDF preview dialog from pre-built PDF bytes.
///
/// Use this for natively-generated PDFs (e.g. notebook export) that are built
/// directly with `pw` rather than via a screenshot capture. For screenshot-
/// based printing use [showPdfPreview] instead.
Future<void> showBuiltPdfPreview(
  BuildContext context, {
  required Future<Uint8List> pdfBytesFuture,
  String title = '',
  String? filename,
}) async {
  final pdfFilename =
      filename ?? (title.isNotEmpty ? '$title.pdf' : 'Helium_print.pdf');

  await showDialog(
    context: context,
    builder: (dialogContext) => _BuiltPdfPreviewDialog(
      pdfBytesFuture: pdfBytesFuture,
      title: title,
      pdfFilename: pdfFilename,
    ),
  );
}

class _BuiltPdfPreviewDialog extends StatefulWidget {
  final Future<Uint8List> pdfBytesFuture;
  final String title;
  final String pdfFilename;

  const _BuiltPdfPreviewDialog({
    required this.pdfBytesFuture,
    required this.title,
    required this.pdfFilename,
  });

  @override
  State<_BuiltPdfPreviewDialog> createState() => _BuiltPdfPreviewDialogState();
}

class _BuiltPdfPreviewDialogState extends State<_BuiltPdfPreviewDialog> {
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

/// Opens a full-screen PDF preview dialog.
///
/// [captureImage] is called once inside the dialog while its loading spinner
/// is shown. The resulting [ui.Image] is cached; subsequent user-driven format
/// or orientation changes re-slice the same image (fast, CPU-only) without a
/// new GPU readback.
Future<void> showPdfPreview(
  BuildContext context, {
  required captureImage,
  String title = '',
  String? filename,
}) async {
  final pdfFilename =
      filename ?? (title.isNotEmpty ? '$title.pdf' : 'print.pdf');

  await showDialog(
    context: context,
    builder: (dialogContext) => _PdfPreviewDialog(
      captureImage: captureImage,
      title: title,
      pdfFilename: pdfFilename,
    ),
  );
}

class _PdfPreviewDialog extends StatefulWidget {
  final Future<_CaptureResult> Function() captureImage;
  final String title;
  final String pdfFilename;

  const _PdfPreviewDialog({
    required this.captureImage,
    required this.title,
    required this.pdfFilename,
  });

  @override
  State<_PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<_PdfPreviewDialog> {
  _CaptureResult? _capture;

  /// Called by [PdfPreview] on first load and whenever the user changes format
  /// or orientation. Capture is performed once and cached; subsequent calls
  /// only re-slice, which is fast CPU-only work.
  Future<Uint8List> _buildPdf(PdfPageFormat baseFormat) async {
    _capture ??= await widget.captureImage();

    const double margin = PdfPageFormat.inch * PrintableArea.marginInches;
    final pdfPageFormat = PdfPageFormat(
      baseFormat.width,
      baseFormat.height,
      marginAll: margin,
    );

    final document = pw.Document();
    await _sliceImageToPdf(
      document,
      _capture!.image,
      pdfPageFormat,
      _capture!.imageBoundaries,
    );
    return document.save();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
          title: Text(widget.title.isNotEmpty ? widget.title : 'Preview'),
          actions: [
            IconButton(
              icon: Icon(Icons.share, color: context.colorScheme.primary),
              tooltip: 'Share',
              onPressed: () async {
                final bytes = await _buildPdf(PrintableArea.pageFormat);
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: widget.pdfFilename,
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.print, color: context.colorScheme.primary),
              tooltip: 'Print',
              onPressed: () async {
                await Printing.layoutPdf(
                  onLayout: (_) => _buildPdf(PrintableArea.pageFormat),
                  name: widget.title.isNotEmpty ? widget.title : 'Document',
                );
              },
            ),
          ],
        ),
        body: PdfPreview(
          build: _buildPdf,
          useActions: true,
          allowPrinting: false,
          allowSharing: false,
          canChangeOrientation: true,
          canChangePageFormat: true,
          canDebug: false,
          initialPageFormat: PrintableArea.pageFormat,
          pdfFileName: widget.pdfFilename,
        ),
      ),
    );
  }
}

// ── Page-break infrastructure ─────────────────────────────────────────────────

/// Provides page-break Y positions (in logical pixels, relative to the
/// [RenderBox] of the [PrintableArea]'s capture boundary) where it is safe
/// to slice the screenshot between pages.
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

/// A transparent wrapper that, when inside a [PrintableArea], registers its
/// bottom edge as a safe page-break boundary for PDF output.
///
/// Wrap cards or rows whose content should never be split across pages. The
/// PDF slicer will snap each page cut to the bottom of the nearest registered
/// boundary rather than cutting mid-widget.
class PrintPageBreak extends StatefulWidget {
  final Widget child;

  const PrintPageBreak({super.key, required this.child});

  @override
  State<PrintPageBreak> createState() => _PrintPageBreakState();
}

class _PrintPageBreakState extends State<PrintPageBreak> {
  final GlobalKey _key = GlobalKey();
  late final PdfPageBreakHintsProvider _provider;
  PrintableAreaScope? _scope;

  @override
  void initState() {
    super.initState();
    _provider = _hints;
    // Registration deferred to post-frame so PrintableAreaScope is fully built
    // when this widget is at the root of a PrintableArea's content tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scope = PrintableAreaScope.findIn(context);
      _scope?.registerHintsProvider(_provider);
    });
  }

  @override
  void dispose() {
    _scope?.unregisterHintsProvider(_provider);
    super.dispose();
  }

  List<double> _hints(RenderBox captureBox) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return [];
    final bottomLocal = captureBox.globalToLocal(
      box.localToGlobal(Offset(0, box.size.height)),
    );
    return [bottomLocal.dy];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(key: _key, child: widget.child);
  }
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

// ── Print visibility helpers ──────────────────────────────────────────────────

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

// ── PrintableArea ─────────────────────────────────────────────────────────────

/// Wraps a [header]/[body] pair in a [RepaintBoundary] and auto-registers a
/// print handler with [PrintService] for the duration the widget is in the tree.
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

  // ── PDF rendering configuration ────────────────────────────────────────────

  /// Pixel ratio used on web. CanvasKit rasterization is synchronous and
  /// scales quadratically; 1.5 is ~2.5× faster than 2.0 with negligible
  /// quality difference.
  static const double pixelRatioWeb = 1.5;

  /// Pixel ratio used on native platforms.
  static const double pixelRatioNative = 2.0;

  /// Page margin in inches, applied to all four sides.
  static const double marginInches = 0.5;

  /// Base page format. Letter rather than A4: A4 (11.69") is taller than
  /// Letter (11"), causing the OS to clip the bottom on US Letter printers.
  static const PdfPageFormat pageFormat = PdfPageFormat.letter;

  // ── Timing configuration ───────────────────────────────────────────────────

  /// How long to wait after switching to light mode before capturing.
  /// [AnimatedTheme] has a 200 ms crossfade; this must exceed that.
  static const Duration themeCrossfadeSettle = Duration(milliseconds: 250);

  /// Extra settle delay on web after triggering layout changes, to allow
  /// CanvasKit to finish rasterizing before the GPU readback.
  static const Duration canvasKitSettle = Duration(milliseconds: 50);

  // ───────────────────────────────────────────────────────────────────────────

  final WidgetBuilder header;
  final WidgetBuilder body;

  /// Retained for API compatibility; both modes now use the same
  /// [MainAxisSize]/[FlexFit]-switching layout, so this flag is a no-op.
  final bool flexColumn;

  /// Screen name included in the generated PDF filename:
  /// `Helium_<title>_<yyyy-MM-dd>.pdf`. Leave empty for a generic filename.
  final String title;

  const PrintableArea({
    super.key,
    required this.header,
    required this.body,
    this.flexColumn = false,
    this.title = '',
  });

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
    // unconstrains the OverflowBox; capturing switches layout/grid modes.
    // They must be consistent on the same frame before content settles.
    setState(() => _capturePending = true);
    PrintableArea.capturing.value = true;
    await WidgetsBinding.instance.endOfFrame;
    // Second frame: Syncfusion and OverflowBox layout changes can each trigger
    // a dependent layout pass, so a single frame isn't always enough to settle.
    await WidgetsBinding.instance.endOfFrame;

    // Force light mode and wait for AnimatedTheme crossfade to complete.
    if (wasDark) {
      await themeNotifier.setThemeMode(ThemeMode.light);
      await Future.delayed(PrintableArea.themeCrossfadeSettle);
    }

    if (!mounted) {
      PrintableArea.capturing.value = false;
      setState(() => _capturePending = false);
      if (wasDark) await themeNotifier.setThemeMode(originalMode);
      return;
    }

    try {
      final date = HeliumDateTime.formatDateForApi(DateTime.now());
      final title = widget.title.isNotEmpty ? widget.title : 'Print';
      await showPdfPreview(
        context,
        captureImage: _captureImage,
        title: title,
        filename: 'Helium_${title.toLowerCase()}_$date.pdf',
      );
    } finally {
      // Restore theme regardless of how the dialog exits.
      if (wasDark) await themeNotifier.setThemeMode(originalMode);
    }
  }

  /// Performs the GPU readback and collects page-break hints.
  ///
  /// Resets [PrintableArea.capturing] and [_capturePending] as soon as the
  /// image is in hand — the OverflowBox and PrintHidden overrides are no
  /// longer needed once [toImage] returns.
  Future<_CaptureResult> _captureImage() async {
    final boundary =
        _repaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('RepaintBoundary not available');

    // Yield a frame for PrintHidden/layout re-renders and the dialog spinner.
    await WidgetsBinding.instance.endOfFrame;
    if (kIsWeb) await Future.delayed(PrintableArea.canvasKitSettle);

    const double pixelRatio =
        kIsWeb ? PrintableArea.pixelRatioWeb : PrintableArea.pixelRatioNative;

    // Collect hints before the costly toImage() GPU readback;
    // convert logical px to image px by applying the pixel ratio.
    final logicalHints = <double>[
      for (final provider in _hintsProviders) ...provider(boundary),
    ];
    final imageBoundaries = logicalHints.map((y) => y * pixelRatio).toList()
      ..sort();

    final image = await boundary.toImage(pixelRatio: pixelRatio);

    // GPU readback is done — restore layout to normal immediately so the
    // screen behind the dialog returns to its interactive state.
    PrintableArea.capturing.value = false;
    if (mounted) setState(() => _capturePending = false);

    return (image: image, imageBoundaries: imageBoundaries);
  }

  Widget _buildChild(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PrintableArea.capturing,
      builder: (context, isCapturing, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: isCapturing ? MainAxisSize.min : MainAxisSize.max,
        children: [
          widget.header(context),
          Flexible(
            fit: isCapturing ? FlexFit.loose : FlexFit.tight,
            child: widget.body(context),
          ),
        ],
      ),
    );
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
          child: RepaintBoundary(key: _repaintKey, child: _buildChild(context)),
        ),
      ),
    );
  }
}
