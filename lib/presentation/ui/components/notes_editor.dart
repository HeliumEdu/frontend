// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_quill_editor.dart';
import 'package:heliumapp/presentation/ui/components/helium_quill_toolbar.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class NotesEditor extends StatefulWidget {
  final QuillController controller;
  final FocusNode? focusNode;
  final VoidCallback? onOpenInNotes;

  const NotesEditor({
    super.key,
    required this.controller,
    this.focusNode,
    this.onOpenInNotes,
  });

  /// Builds theme-aware default styles for Quill editors.
  ///
  /// Flutter Quill's default strikethrough/underline styles don't set
  /// decorationColor, causing black decorations in dark mode.
  static DefaultStyles buildDefaultStyles(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return DefaultStyles(
      strikeThrough: TextStyle(
        decoration: TextDecoration.lineThrough,
        decorationColor: onSurface,
      ),
      underline: TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: onSurface,
      ),
    );
  }

  static Future<void> showColorPicker(
    BuildContext context,
    QuillController controller,
    bool isBackground,
  ) =>
      HeliumQuillToolbar.showColorPicker(context, controller, isBackground);

  @override
  State<NotesEditor> createState() => _NotesEditorState();
}

class _NotesEditorState extends State<NotesEditor> with WidgetsBindingObserver {
  final _editorKey = GlobalKey();
  bool _pendingScrollOnKeyboard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant NotesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      widget.focusNode?.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!_pendingScrollOnKeyboard || !mounted) return;

    final viewInsets = WidgetsBinding
        .instance.platformDispatcher.views.first.viewInsets.bottom;

    // Keyboard starting to appear - wait for animation to complete
    if (viewInsets > 0) {
      _pendingScrollOnKeyboard = false;
      // Keyboard animation is ~250-300ms; wait for it to finish
      Future.delayed(const Duration(milliseconds: 150), _scrollToEditor);
    }
  }

  void _scrollToEditor() {
    if (!mounted) return;
    // Defer scroll until after the keyboard-triggered layout pass so the
    // editor's final position is known before calling ensureVisible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _editorKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onFocusChange() {
    if (widget.focusNode?.hasFocus ?? false) {
      final viewInsets = WidgetsBinding
          .instance.platformDispatcher.views.first.viewInsets.bottom;

      // If keyboard is already visible, scroll immediately
      if (viewInsets > 0) {
        _scrollToEditor();
      } else {
        // Wait for keyboard to appear via didChangeMetrics
        _pendingScrollOnKeyboard = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = Responsive.useCompactLayout(context);

    return Column(
      key: _editorKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Notes', style: AppStyles.formLabel(context)),
            const Spacer(),
            if (widget.onOpenInNotes != null)
              TextButton.icon(
                onPressed: widget.onOpenInNotes,
                icon: Icon(
                  Icons.library_books,
                  size: 16.0,
                  color: context.colorScheme.primary,
                ),
                label: Text(
                  'Open in Notebook',
                  style: AppStyles.smallSecondaryText(context).copyWith(color: context.colorScheme.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeliumQuillToolbar(
                  controller: widget.controller,
                  config: QuillSimpleToolbarConfig(
                    toolbarRunSpacing: 0,
                    toolbarSectionSpacing: 8,
                    showFontFamily: !isCompact,
                    showDividers: !isCompact,
                    showStrikeThrough: !isCompact,
                    showRedo: !isCompact,
                    showQuote: !isCompact,
                    showUnderLineButton: !isCompact,
                    showFontSize: false,
                    showSuperscript: false,
                    showSubscript: false,
                    showHeaderStyle: false,
                    showInlineCode: false,
                    showCodeBlock: false,
                    showDirection: false,
                    showSearchButton: false,
                    showClearFormat: !isCompact,
                    showBackgroundColorButton: false,
                    showColorButton: !isCompact,
                    showIndent: !isCompact,
                    buttonOptions: () {
                      final opts = HeliumQuillToolbar.defaultButtonOptions(context);
                      return QuillSimpleToolbarButtonOptions(
                        base: opts.base,
                        color: opts.color,
                      );
                    }(),
                  ),
                ),
                const Divider(height: 1),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 125.0,
                    maxHeight: 300.0,
                  ),
                  child: HeliumQuillEditor(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    config: QuillEditorConfig(
                      padding: const EdgeInsets.all(12.0),
                      autoFocus: false,
                      customStyles: NotesEditor.buildDefaultStyles(context),
                      customShortcuts: const <ShortcutActivator, Intent>{
                        SingleActivator(LogicalKeyboardKey.keyF, control: true):
                            DoNothingIntent(),
                        SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                            DoNothingIntent(),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
