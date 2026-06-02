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

/// Consumers build their own [QuillSimpleToolbarConfig] (controlling which
/// buttons are shown, custom buttons, etc.) and call
/// [HeliumQuillToolbar.defaultButtonOptions] to inject the shared icon theme
/// and color picker callbacks rather than duplicating them.
class HeliumQuillToolbar extends StatelessWidget {
  final QuillController controller;
  final QuillSimpleToolbarConfig config;

  const HeliumQuillToolbar({
    super.key,
    required this.controller,
    required this.config,
  });

  /// Shared button options applied to all Helium Quill toolbars: themed icon
  /// buttons and a color/background-color picker using [ColorPickerDialog].
  /// Pass the result as [QuillSimpleToolbarConfig.buttonOptions].
  static QuillSimpleToolbarButtonOptions defaultButtonOptions(
    BuildContext context,
  ) {
    return QuillSimpleToolbarButtonOptions(
      base: QuillToolbarBaseButtonOptions(
        iconTheme: QuillIconTheme(
          iconButtonSelectedData: IconButtonData(
            style: ButtonStyle(
              backgroundColor:
                  WidgetStatePropertyAll(context.colorScheme.primary),
              foregroundColor:
                  WidgetStatePropertyAll(context.colorScheme.onPrimary),
              overlayColor: WidgetStatePropertyAll(
                context.colorScheme.onPrimary.withValues(alpha: 0.1),
              ),
              minimumSize: const WidgetStatePropertyAll(Size.zero),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          iconButtonUnselectedData: IconButtonData(
            style: ButtonStyle(
              backgroundColor:
                  const WidgetStatePropertyAll(Colors.transparent),
              foregroundColor:
                  WidgetStatePropertyAll(context.colorScheme.onSurface),
              minimumSize: const WidgetStatePropertyAll(Size.zero),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
      color: QuillToolbarColorButtonOptions(
        customOnPressedCallback: (ctrl, isBackground) =>
            showColorPicker(context, ctrl, isBackground),
      ),
      backgroundColor: QuillToolbarColorButtonOptions(
        customOnPressedCallback: (ctrl, isBackground) =>
            showColorPicker(context, ctrl, isBackground),
      ),
    );
  }

  /// Shows the Helium color picker dialog and applies the chosen color as a
  /// Quill foreground or background attribute on the current selection.
  static Future<void> showColorPicker(
    BuildContext context,
    QuillController controller,
    bool isBackground,
  ) async {
    final key = isBackground ? 'background' : 'color';
    final stored =
        controller.getSelectionStyle().attributes[key]?.value as String?;

    Color initial = Colors.black;
    if (stored != null) {
      // Quill stores colors as #AARRGGBB; strip # and parse
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: QuillSimpleToolbar(
        controller: controller,
        config: config,
      ),
    );
  }
}
