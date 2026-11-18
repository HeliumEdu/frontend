import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';

class HeliumSearchField extends StatelessWidget {
  static const _height = 40.0;
  static const _buttonConstraints = BoxConstraints.tightFor(
    width: _height,
    height: _height - 2 * AppStyles.formFieldBorderWidth,
  );
  static const _cornerRadius = Radius.circular(AppStyles.formFieldBorderRadius);

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final TapRegionCallback? onTapOutside;
  final Widget? prefixIcon;
  final Widget? trailing;

  const HeliumSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onChanged,
    this.onSubmitted,
    this.onTapOutside,
    this.prefixIcon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTapOutside: onTapOutside,
        style: AppStyles.formText(context),
        textAlignVertical: TextAlignVertical.center,
        decoration: AppStyles.formFieldDecoration(context).copyWith(
          hintText: 'Search ...',
          hintStyle: AppStyles.formHint(context),
          isDense: true,
          prefixIcon:
              prefixIcon ??
              Icon(
                Icons.search,
                color: context.colorScheme.onSurface.withValues(alpha: AppStyles.mutedIconAlpha),
              ),
          suffixIconConstraints: BoxConstraints(
            minWidth: _buttonConstraints.maxWidth,
            minHeight: _buttonConstraints.maxHeight,
            maxHeight: _buttonConstraints.maxHeight,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(end: AppStyles.formFieldBorderWidth),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: _buildSuffixButtons,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuffixButtons(BuildContext context, TextEditingValue value, Widget? _) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value.text.isNotEmpty)
          HeliumSearchFieldButton(
            // Keyed so removing it never hands its element to [trailing].
            key: const ValueKey('search_clear'),
            icon: Icons.close,
            tooltip: 'Clear',
            borderRadius: BorderRadiusDirectional.horizontal(
              start: _cornerRadius,
              end: trailing == null ? _cornerRadius : Radius.zero,
            ),
            onPressed: _clear,
          ),
        ?trailing,
      ],
    );
  }

  void _clear() {
    controller.clear();
    onChanged('');
  }
}

/// A button that sits flush inside [HeliumSearchField]'s outline, after its
/// clear button; only the corners on the field's edge are rounded.
class HeliumSearchFieldButton extends StatelessWidget {
  static const _trailingBorderRadius = BorderRadiusDirectional.horizontal(
    end: HeliumSearchField._cornerRadius,
  );

  final IconData icon;
  final String tooltip;
  final BorderRadiusGeometry borderRadius;
  final VoidCallback onPressed;
  final bool? isSelected;

  const HeliumSearchFieldButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.borderRadius = _trailingBorderRadius,
    required this.onPressed,
    this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = isSelected ?? false;
    return IconButton(
      onPressed: onPressed,
      isSelected: isSelected,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      constraints: HeliumSearchField._buttonConstraints,
      style: IconButton.styleFrom(
        backgroundColor: isActive ? context.colorScheme.primary : null,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      icon: Icon(
        icon,
        size: 20,
        color: isActive
            ? context.colorScheme.onPrimary
            : context.colorScheme.onSurface.withValues(alpha: AppStyles.mutedIconAlpha),
      ),
      tooltip: tooltip,
    );
  }
}
