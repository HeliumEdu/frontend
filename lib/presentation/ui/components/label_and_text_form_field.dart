import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/platform_behavior.dart';
import 'package:heliumapp/utils/spell_check_helpers.dart';
import 'package:heliumapp/utils/tab_moves_focus_formatter.dart';

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
  final bool readOnly;
  final int maxLines;
  final ValueChanged<String>? onFieldSubmitted;
  final GlobalKey<FormFieldState<String>>? fieldKey;
  final Iterable<String>? autofillHints;
  final Widget? trailingIconButton;

  final bool? spellCheck;

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
    this.readOnly = false,
    this.maxLines = 1,
    this.spellCheck,
    this.onFieldSubmitted,
    this.fieldKey,
    this.autofillHints,
    this.trailingIconButton,
  });

  @override
  State<LabelAndTextFormField> createState() => _LabelAndTextFormFieldState();
}

class _LabelAndTextFormFieldState extends State<LabelAndTextFormField> {
  static const _trailingButtonSize = 48.0;
  static const _trailingButtonLabelOffset = 30.0;
  static const _verticalContentPaddingWithAffordance = 15.0;
  static const _iconConstraints = BoxConstraints(
    minWidth: kMinInteractiveDimension,
    minHeight: AppStyles.formFieldInnerHeight,
    maxHeight: AppStyles.formFieldInnerHeight,
  );
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

  Widget _buildTextFormField(BuildContext context) {
    final field = TextFormField(
      key: widget.fieldKey,
      initialValue: widget.initialValue,
      autofocus: widget.autofocus,
      controller: widget.controller,
      validator: widget.validator,
      focusNode: widget.focusNode,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      obscureText: widget.obscureText,
      spellCheckConfiguration: _spellCheckConfiguration,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      inputFormatters: [
        if (PlatformBehavior.typesTabAsText) const TabMovesFocusFormatter(),
        ...?widget.inputFormatters,
      ],
      autofillHints: widget.autofillHints,
      style: AppStyles.formText(context),
      textAlignVertical: TextAlignVertical.center,
      onFieldSubmitted: widget.onFieldSubmitted,
      scrollPadding: const EdgeInsets.all(
        20,
      ).copyWith(bottom: 20 + MediaQuery.viewInsetsOf(context).bottom),
      decoration: AppStyles.formFieldDecoration(context, readOnly: widget.readOnly).copyWith(
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: context.colorScheme.onSurface.withValues(
                  alpha: AppStyles.mutedIconAlpha,
                ),
              )
            : null,
        prefixIconConstraints: _iconConstraints,
        suffixIconConstraints: _iconConstraints,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppStyles.formFieldContentPadding,
          vertical: widget.maxLines > 1 ? _verticalContentPaddingWithAffordance : 0,
        ),
        hintText: widget.hintText,
        hintStyle: AppStyles.formHint(context),
        suffixIcon: widget.suffixIcon,
        errorText: widget.errorText,
      ),
    );
    return widget.label == null
        ? field
        : Semantics(label: widget.label, child: field);
  }

  @override
  Widget build(BuildContext context) {
    final formField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: Text(widget.label!, style: AppStyles.formLabel(context)),
          ),
        if (widget.label != null) const SizedBox(height: 9),
        _buildTextFormField(context),
      ],
    );

    if (widget.trailingIconButton != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: formField),
          const SizedBox(width: 8),
          Padding(
            padding: EdgeInsets.only(
              top: widget.label != null ? _trailingButtonLabelOffset : 0,
            ),
            child: SizedBox(
              width: _trailingButtonSize,
              height: _trailingButtonSize,
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

  SpellCheckConfiguration? get _spellCheckConfiguration {
    final enabled =
        widget.spellCheck ?? (widget.maxLines > 1 && !widget.obscureText);
    return enabled ? proseSpellCheck : null;
  }
}
