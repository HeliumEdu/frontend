// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';

class LabelAndTextFormField extends StatelessWidget {
  final String? label;
  final String hintText;
  final IconData? prefixIcon;

  final String? initialValue;
  final bool autofocus;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onFieldSubmitted;

  /// Optional key for the TextFormField, used for scroll-to-error functionality.
  final GlobalKey<FormFieldState<String>>? fieldKey;

  /// Autofill hints for password managers (e.g., AutofillHints.username).
  final Iterable<String>? autofillHints;

  const LabelAndTextFormField({
    super.key,
    this.label,
    this.prefixIcon,
    this.initialValue,
    this.autofocus = false,
    this.controller,
    this.validator,
    this.hintText = '',
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.onChanged,
    this.focusNode,
    this.enabled = true,
    this.maxLines = 1,
    this.onFieldSubmitted,
    this.fieldKey,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) Text(label!, style: context.formLabel),
        if (label != null) const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: enabled
                ? context.colorScheme.surface
                : context.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha: 0.2),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TextFormField(
            key: fieldKey,
            initialValue: initialValue,
            autofocus: autofocus,
            controller: controller,
            validator: validator,
            focusNode: focusNode,
            enabled: enabled,
            maxLines: maxLines,
            obscureText: obscureText,
            onChanged: onChanged,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            autofillHints: autofillHints,
            style: context.formText,
            onFieldSubmitted: onFieldSubmitted,
            decoration: InputDecoration(
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                    )
                  : null,
              contentPadding: EdgeInsets.only(
                left: 12,
                top: _horizontalPadding(),
                bottom: _horizontalPadding(),
              ),
              hintText: hintText,
              hintStyle: context.formHintStyle,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              suffixIcon: suffixIcon,
              errorText: errorText,
              errorStyle: context.formErrorStyle,
              errorMaxLines: 3,
            ),
          ),
          ),
        ),
      ],
    );
  }

  double _horizontalPadding() {
    if (prefixIcon != null || suffixIcon != null || maxLines > 1) {
      return 15;
    } else {
      return 0;
    }
  }
}
