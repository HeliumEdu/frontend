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

class LabelAndTextFormField extends StatefulWidget {
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
  final GlobalKey<FormFieldState<String>>? fieldKey;
  final Iterable<String>? autofillHints;
  final Widget? trailingIconButton;

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
    this.trailingIconButton,
  });

  @override
  State<LabelAndTextFormField> createState() => _LabelAndTextFormFieldState();
}

class _LabelAndTextFormFieldState extends State<LabelAndTextFormField> {
  // State
  bool _isTrailingButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null && widget.trailingIconButton != null) {
      widget.controller!.addListener(_onTextChanged);
      _onTextChanged();
    }
  }

  @override
  void dispose() {
    if (widget.controller != null && widget.trailingIconButton != null) {
      widget.controller!.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller!.text;
    final validationResult = widget.validator?.call(text);

    setState(() {
      _isTrailingButtonEnabled = text.isNotEmpty && validationResult == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) Text(widget.label!, style: context.formLabel),
        if (widget.label != null) const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: widget.enabled
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
              key: widget.fieldKey,
              initialValue: widget.initialValue,
              autofocus: widget.autofocus,
              controller: widget.controller,
              validator: widget.validator,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              obscureText: widget.obscureText,
              onChanged: widget.onChanged,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              autofillHints: widget.autofillHints,
              style: context.formText,
              onFieldSubmitted: widget.onFieldSubmitted,
              decoration: InputDecoration(
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      )
                    : null,
                contentPadding: EdgeInsets.only(
                  left: 12,
                  top: _horizontalPadding(),
                  bottom: _horizontalPadding(),
                ),
                hintText: widget.hintText,
                hintStyle: context.formHintStyle,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                suffixIcon: widget.suffixIcon,
                errorText: widget.errorText,
                errorStyle: context.formErrorStyle,
                errorMaxLines: 3,
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.trailingIconButton != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: formField),
          const SizedBox(width: 8),
          Padding(
            padding: EdgeInsets.only(top: widget.label != null ? 33 : 0),
            child: SizedBox(
              width: 48,
              height: 48,
              child: IgnorePointer(
                ignoring: !_isTrailingButtonEnabled,
                child: Opacity(
                  opacity: _isTrailingButtonEnabled ? 1.0 : 0.4,
                  child: widget.trailingIconButton,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return formField;
  }

  double _horizontalPadding() {
    if (widget.prefixIcon != null ||
        widget.suffixIcon != null ||
        widget.maxLines > 1) {
      return 15;
    } else {
      return 0;
    }
  }
}
