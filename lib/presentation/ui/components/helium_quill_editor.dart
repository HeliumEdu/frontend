// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:heliumapp/utils/quill_html_sanitizers.dart';
import 'package:heliumapp/utils/quill_paste.dart';
import 'package:quill_native_bridge/quill_native_bridge.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

/// - **Web inbound**: intercepts the browser `paste` event (no clipboard-read
///   permission) and converts clipboard HTML via [HtmlToDelta].
/// - **Web outbound**: intercepts the browser `copy` event (no clipboard-write
///   permission) and writes both `text/html` and `text/plain` to the
///   clipboard so rich formatting survives paste into external apps.
/// - **Same-tab**: caches the copied [Delta] so an in-app copy/paste round-
///   trip preserves formatting even though Flutter web never calls
///   `clipboardSelection()`.
/// - **Mobile outbound**: overrides [CopySelectionTextIntent] to write HTML
///   to the native clipboard via [QuillNativeBridge].
///
/// The static Delta cache is shared across all [HeliumQuillEditor] instances
/// so a copy in one Helium editor can be pasted into another within the same
/// browser tab.
class HeliumQuillEditor extends StatefulWidget {
  final QuillController controller;

  /// If provided, this focus node is used for both the editor and clipboard
  /// focus detection. If omitted, an internal focus node is created.
  final FocusNode? focusNode;
  final QuillEditorConfig config;

  const HeliumQuillEditor({
    super.key,
    required this.controller,
    this.focusNode,
    this.config = const QuillEditorConfig(),
  });

  @override
  State<HeliumQuillEditor> createState() => _HeliumQuillEditorState();
}

class _HeliumQuillEditorState extends State<HeliumQuillEditor> {
  late final FocusNode _ownFocusNode;
  void Function()? _removeWebClipboardListeners;

  // Shared across all instances so a copy in one Helium editor can be
  // pasted in another within the same browser tab.
  static String _webCopiedPlainText = '';
  static Delta _webCopiedDelta = Delta();

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _ownFocusNode;

  @override
  void initState() {
    super.initState();
    _ownFocusNode = FocusNode();
    _removeWebClipboardListeners = registerQuillClipboardListeners(
      isEditorFocused: () => _effectiveFocusNode.hasFocus,
      onCopy: _captureWebCopy,
      onPaste: _handleWebPaste,
    );
  }

  @override
  void dispose() {
    _removeWebClipboardListeners?.call();
    _ownFocusNode.dispose();
    super.dispose();
  }

  ({String html, String plain})? _captureWebCopy() {
    final sel = widget.controller.selection;
    if (!sel.isValid || sel.isCollapsed) return null;
    final plain = widget.controller.document
        .getPlainText(sel.start, sel.end - sel.start);
    final delta =
        widget.controller.document.toDelta().slice(sel.start, sel.end);
    _webCopiedPlainText = plain;
    _webCopiedDelta = delta;
    return (html: _deltaToHtml(delta), plain: plain);
  }

  Future<void> _handleMobileCopy() async {
    final sel = widget.controller.selection;
    if (!sel.isValid || sel.isCollapsed) return;
    final plain = widget.controller.document
        .getPlainText(sel.start, sel.end - sel.start);
    final delta =
        widget.controller.document.toDelta().slice(sel.start, sel.end);
    final html = _deltaToHtml(delta);
    final bridge = QuillNativeBridge();
    if (await bridge.isSupported(QuillNativeBridgeFeature.copyHtmlToClipboard)) {
      await bridge.copyHtmlToClipboard(html);
    } else {
      await Clipboard.setData(ClipboardData(text: plain));
    }
  }

  void _handleWebPaste(String? html, String? plainText) {
    final sel = widget.controller.selection;
    final start = sel.start;
    final len = sel.end - sel.start;

    // Within-app copy: match against our own browser-copy cache. Flutter web
    // never calls clipboardSelection(), so Quill's static cache is always
    // empty; we maintain our own via the copy event listener.
    if (plainText != null &&
        plainText.trimRight() == _webCopiedPlainText.trimRight() &&
        _webCopiedPlainText.isNotEmpty &&
        _webCopiedDelta.isNotEmpty) {
      widget.controller.replaceText(
        start,
        len,
        _webCopiedDelta,
        TextSelection.collapsed(offset: sel.end),
      );
      return;
    }

    // Cross-tab or external HTML paste. Skip the result if it contains only
    // whitespace/newlines (e.g., complex layout HTML with no text content)
    // and fall through to plain text.
    if (html != null) {
      try {
        final raw = HtmlToDelta().convert(sanitizeClipboardHtml(html));
        // Strip non-text embed ops — Quill has no renderer for embed types from
        // external sources (e.g. Google Docs checkboxes), which causes a fatal
        // render assertion. Text ops and their inline/block attributes are kept.
        final safeOps =
            raw.toList().where((op) => op.isInsert && op.data is String).toList();
        final delta = safeOps.fold(Delta(), (d, op) => d..push(op));
        final hasText = delta.toList().any((op) =>
            op.isInsert &&
            op.data is String &&
            (op.data as String).trim().isNotEmpty);
        if (hasText) {
          widget.controller.replaceText(
            start,
            len,
            delta,
            TextSelection.collapsed(offset: sel.end),
          );
          return;
        }
      } catch (_) {
        // Conversion or insertion failed; fall through to plain text.
      }
    }

    // Plain text fallback.
    if (plainText != null) {
      widget.controller.replaceText(
        start,
        len,
        plainText,
        TextSelection.collapsed(offset: start + plainText.length),
      );
    }
  }

  String _deltaToHtml(Delta delta) {
    final ops = delta.toJson().cast<Map<String, dynamic>>();
    return QuillDeltaToHtmlConverter(
      ops,
      ConverterOptions(
        sanitizerOptions: OpAttributeSanitizerOptions(
          allow8DigitHexColors: true,
        ),
      ),
    ).convert();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        if (!kIsWeb)
          CopySelectionTextIntent: CallbackAction<CopySelectionTextIntent>(
            onInvoke: (_) => _handleMobileCopy(),
          ),
      },
      child: QuillEditor.basic(
        controller: widget.controller,
        focusNode: _effectiveFocusNode,
        config: widget.config,
      ),
    );
  }
}
