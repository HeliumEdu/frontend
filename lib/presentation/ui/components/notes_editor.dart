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

class NotesEditor extends StatelessWidget {
  final QuillController controller;
  final VoidCallback? onOpenInNotes;

  const NotesEditor({
    super.key,
    required this.controller,
    this.onOpenInNotes,
  });

  /// Builds theme-aware default styles for Quill editors.
  ///
  /// Flutter Quill has hardcoded light-mode colors for several styles
  /// (strikethrough, underline, inline code, code blocks, quotes).
  /// This method overrides them with theme-appropriate colors.
  static DefaultStyles buildDefaultStyles(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return DefaultStyles(
      strikeThrough: TextStyle(
        decoration: TextDecoration.lineThrough,
        decorationColor: onSurface,
      ),
      underline: TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: onSurface,
      ),
      inlineCode: InlineCodeStyle(
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        radius: const Radius.circular(3),
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.primary.withValues(alpha: 0.8),
        ),
      ),
      quote: DefaultTextBlockStyle(
        TextStyle(color: onSurface.withValues(alpha: 0.6)),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(6, 0),
        const VerticalSpacing(6, 2),
        BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 4,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
          ),
        ),
      ),
      code: DefaultTextBlockStyle(
        TextStyle(
          color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
          fontFamily: theme.platform == TargetPlatform.iOS ? 'Menlo' : 'Roboto Mono',
          fontSize: 13,
          height: 1.15,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(6, 0),
        VerticalSpacing.zero,
        BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(2),
        ),
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Notes', style: AppStyles.formLabel(context)),
            const Spacer(),
            if (onOpenInNotes != null)
              TextButton.icon(
                onPressed: onOpenInNotes,
                icon: Icon(
                  Icons.open_in_new,
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
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuillSimpleToolbar(
                  controller: controller,
                  config: QuillSimpleToolbarConfig(
                    showFontSize: false,
                    showSuperscript: false,
                    showSubscript: false,
                    showHeaderStyle: false,
                    showInlineCode: false,
                    showCodeBlock: false,
                    showDirection: false,
                    showSearchButton: false,
                    showBackgroundColorButton: false,
                    buttonOptions: QuillSimpleToolbarButtonOptions(
                      base: QuillToolbarBaseButtonOptions(
                        iconTheme: QuillIconTheme(
                          iconButtonSelectedData: IconButtonData(
                            style: ButtonStyle(
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
                          ),
                        ),
                      ),
                      color: QuillToolbarColorButtonOptions(
                        customOnPressedCallback: (ctrl, isBackground) =>
                            showColorPicker(context, ctrl, isBackground),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 200,
                    maxHeight: 350,
                  ),
                  child: QuillEditor.basic(
                    controller: controller,
                    config: QuillEditorConfig(
                      padding: const EdgeInsets.all(12),
                      customStyles: buildDefaultStyles(context),
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
