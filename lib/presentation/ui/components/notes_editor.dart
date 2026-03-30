// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/dialogs/color_picker_dialog.dart';
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
  ) async {
    final key = isBackground ? 'background' : 'color';
    final stored = controller.getSelectionStyle().attributes[key]?.value as String?;

    Color initial = Colors.black;
    if (stored != null) {
      // Quill stores as #AARRGGBB — strip # and parse
      final hex = stored.startsWith('#') ? stored.substring(1) : stored;
      final padded = hex.length == 6 ? 'ff$hex' : hex;
      initial = Color(int.tryParse(padded, radix: 16) ?? 0xFF000000);
    }

    await showColorPickerDialog(
      parentContext: context,
      initialColor: initial,
      onSelected: (color) {
        final a = (color.a * 255).round().toRadixString(16).padLeft(2, '0');
        final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
        final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
        final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
        final hex = '#$a$r$g$b'.toUpperCase();
        controller.formatSelection(
          isBackground ? BackgroundAttribute(hex) : ColorAttribute(hex),
        );
      },
    );
  }

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
    final useCompact = Responsive.useCompactLayout(context);

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
                  size: 16,
                  color: context.colorScheme.primary,
                ),
                label: Text(
                  'Open in Notebook',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colorScheme.primary,
                  ),
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: QuillSimpleToolbar(
                    controller: widget.controller,
                  config: QuillSimpleToolbarConfig(
                    toolbarRunSpacing: 0,
                    showFontFamily: !useCompact,
                    showDividers: !useCompact,
                    showStrikeThrough: !useCompact,
                    showRedo: !useCompact,
                    showQuote: !useCompact,
                    showFontSize: false,
                    showSuperscript: false,
                    showSubscript: false,
                    showHeaderStyle: false,
                    showInlineCode: false,
                    showCodeBlock: false,
                    showDirection: false,
                    showSearchButton: false,
                    showClearFormat: !useCompact,
                    showBackgroundColorButton: false,
                    showColorButton: !useCompact,
                    showIndent: !useCompact,
                    buttonOptions: QuillSimpleToolbarButtonOptions(
                      base: QuillToolbarBaseButtonOptions(
                        iconTheme: QuillIconTheme(
                          iconButtonSelectedData: IconButtonData(
                            style: ButtonStyle(
                              tapTargetSize: useCompact
                                  ? MaterialTapTargetSize.shrinkWrap
                                  : null,
                              backgroundColor: WidgetStatePropertyAll(
                                context.colorScheme.primary,
                              ),
                              foregroundColor: WidgetStatePropertyAll(
                                context.colorScheme.onPrimary,
                              ),
                              overlayColor: WidgetStatePropertyAll(
                                context.colorScheme.onPrimary.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                          ),
                          iconButtonUnselectedData: IconButtonData(
                            color: context.colorScheme.onSurface,
                            style: useCompact
                                ? const ButtonStyle(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      color: QuillToolbarColorButtonOptions(
                        customOnPressedCallback: (ctrl, isBackground) =>
                            NotesEditor.showColorPicker(context, ctrl, isBackground),
                      ),
                    ),
                  ),
                  ),
                ),
                const Divider(height: 1),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 125,
                    maxHeight: 300,
                  ),
                  child: QuillEditor.basic(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    config: QuillEditorConfig(
                      padding: const EdgeInsets.all(12),
                      autoFocus: false,
                      customStyles: NotesEditor.buildDefaultStyles(context),
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
