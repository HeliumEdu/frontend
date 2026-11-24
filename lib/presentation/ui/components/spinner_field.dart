import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/format_helpers.dart';
import 'package:heliumapp/utils/platform_behavior.dart';
import 'package:heliumapp/utils/tab_moves_focus_formatter.dart';

class SpinnerField extends StatelessWidget {
  static const _arrowSize = 22.0;
  static const _arrowsWidth = 32.0;
  static const _arrowsConstraints = BoxConstraints.tightFor(
    width: _arrowsWidth + AppStyles.formFieldBorderWidth,
    height: AppStyles.formFieldInnerHeight,
  );

  final String? label;
  final String? description;
  final TextEditingController controller;
  final double minValue;
  final double? maxValue;
  final double step;
  final bool allowDecimal;
  final ValueChanged<String>? onChanged;
  final double? maxSpinnerWidth;
  final Widget? trailing;

  const SpinnerField({
    super.key,
    this.label,
    this.description,
    required this.controller,
    this.minValue = 0,
    this.maxValue,
    this.step = 1,
    this.allowDecimal = false,
    this.onChanged,
    this.maxSpinnerWidth,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          ExcludeSemantics(
            child: Text(label!, style: AppStyles.formLabel(context)),
          ),
        if (description != null)
          Text(description!, style: AppStyles.smallSecondaryText(context)),
        if (label != null || description != null)
          SizedBox(height: description != null || trailing != null ? 8 : 9),
        if (trailing == null)
          _buildSpinnerRow(context)
        else
          Row(
            children: [
              SizedBox(width: maxSpinnerWidth, child: _buildField(context)),
              const SizedBox(width: 8),
              Expanded(child: trailing!),
            ],
          ),
      ],
    );
  }

  Widget _buildSpinnerRow(BuildContext context) {
    final field = _buildField(context);
    if (maxSpinnerWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxSpinnerWidth!),
        child: field,
      );
    }
    return field;
  }

  Widget _buildField(BuildContext context) {
    return Semantics(
      label: label,
      child: Focus(
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _increment();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _decrement();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextFormField(
          controller: controller,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          inputFormatters: [
            if (PlatformBehavior.typesTabAsText) const TabMovesFocusFormatter(),
            if (allowDecimal)
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          style: AppStyles.formText(context),
          onChanged: _onTextChanged,
          decoration: AppStyles.formFieldDecoration(context).copyWith(
            suffixIcon: _buildArrows(context),
            suffixIconConstraints: _arrowsConstraints,
          ),
        ),
      ),
    );
  }

  Widget _buildArrows(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppStyles.formFieldBorderWidth),
      child: ClipRRect(
        borderRadius: const BorderRadiusDirectional.horizontal(
          end: Radius.circular(AppStyles.formFieldBorderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Each arrow fills half the field height so the pair is gap-free
            // and comfortably tappable without enlarging the icons.
            Expanded(
              child: IconButton(
                onPressed: () => _increment(),
                icon: const Icon(Icons.arrow_drop_up, semanticLabel: 'Increase value'),
                iconSize: _arrowSize,
                color: context.colorScheme.primary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => _decrement(),
                icon: const Icon(Icons.arrow_drop_down, semanticLabel: 'Decrease value'),
                iconSize: _arrowSize,
                color: context.colorScheme.primary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTextChanged(String value) {
    if (value.isEmpty) {
      controller.text = _formatValue(minValue);
      onChanged?.call(value);
    } else if (maxValue != null && (HeliumNumber.parse(value) ?? minValue) > maxValue!) {
      final capped = _formatValue(maxValue!);
      controller.value = TextEditingValue(
        text: capped,
        selection: TextSelection.collapsed(offset: capped.length),
      );
      onChanged?.call(capped);
    } else {
      onChanged?.call(value);
    }
  }

  void _increment() {
    final currentValue = HeliumNumber.parse(controller.text) ?? minValue;
    final newValue = currentValue + step;
    if (maxValue == null || newValue <= maxValue!) {
      controller.text = _formatValue(newValue);
      onChanged?.call(controller.text);
    }
  }

  void _decrement() {
    final currentValue = HeliumNumber.parse(controller.text) ?? minValue;
    final newValue = currentValue - step;
    if (newValue >= minValue) {
      controller.text = _formatValue(newValue);
      onChanged?.call(controller.text);
    }
  }

  String _formatValue(double value) {
    if (allowDecimal) {
      return HeliumNumber.format(value, trimZeros: true);
    } else {
      return value.toInt().toString();
    }
  }
}
