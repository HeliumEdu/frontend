// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/label_and_text_form_field.dart';

class HeliumPasswordField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool autofocus;

  const HeliumPasswordField({
    super.key,
    this.label,
    this.hintText,
    this.prefixIcon = Icons.lock_outline,
    required this.controller,
    this.validator,
    this.onFieldSubmitted,
    this.autofillHints,
    this.autofocus = false,
  });

  @override
  State<HeliumPasswordField> createState() => _HeliumPasswordFieldState();
}

class _HeliumPasswordFieldState extends State<HeliumPasswordField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return LabelAndTextFormField(
      label: widget.label,
      hintText: widget.hintText ?? '',
      prefixIcon: widget.prefixIcon,
      controller: widget.controller,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      obscureText: !_isVisible,
      autofocus: widget.autofocus,
      autofillHints: widget.autofillHints,
      suffixIcon: ExcludeFocus(
        excluding: true,
        child: Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: IconButton(
            onPressed: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
            icon: Icon(
              _isVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
