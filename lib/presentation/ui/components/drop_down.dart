import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/utils/app_style.dart';

class DropDown<T> extends StatelessWidget {
  static const _iconTextSpacing = 12.0;
  static const _trailingButtonSize = 48.0;
  static const _trailingButtonLabelOffset = 30.0;

  final String? label;
  final IconData? prefixIcon;
  final DropDownItem<T>? initialValue;
  final List<DropDownItem<T>> items;
  final void Function(DropDownItem<T>?)? onChanged;
  final String? Function(DropDownItem<T>?)? validator;
  final Widget? trailingIconButton;
  final String? helperText;

  const DropDown({
    super.key,
    this.label,
    this.prefixIcon,
    this.initialValue,
    required this.items,
    required this.onChanged,
    this.validator,
    this.trailingIconButton,
    this.helperText,
  });

  Widget _buildItemRow(
    BuildContext context,
    DropDownItem<T> item,
    Color iconColor,
  ) {
    final isDisabled = onChanged == null;
    final ownIconColor = item.iconColor;
    final itemIconColor = ownIconColor == null
        ? iconColor
        : isDisabled
        ? ownIconColor.withValues(alpha: ownIconColor.a * 0.4)
        : ownIconColor;
    return Row(
      children: [
        if (item.iconData != null) ...[
          Icon(item.iconData, color: itemIconColor),
          const SizedBox(width: _iconTextSpacing),
        ],
        Flexible(
          child: Text(
            item.label,
            style: isDisabled
                ? AppStyles.formText(context).copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.38),
                  )
                : AppStyles.formText(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = onChanged == null;
    final iconColor = isDisabled
        ? context.colorScheme.primary.withValues(alpha: 0.4)
        : context.colorScheme.primary;

    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) Text(label!, style: AppStyles.formLabel(context)),
        if (label != null) const SizedBox(height: 9),
        Semantics(
          label: label,
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: isDisabled
                  ? context.theme.scaffoldBackgroundColor
                  : context.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppStyles.formFieldBorderRadius),
            ),
            child: DropdownButtonFormField<DropDownItem<T>>(
            initialValue: initialValue,
            decoration: AppStyles.formFieldDecoration(context).copyWith(
              enabled: !isDisabled,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: iconColor)
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppStyles.formFieldContentPadding,
                vertical: prefixIcon != null ? AppStyles.formFieldContentPadding : 0,
              ),
            ),
            style: AppStyles.formText(context),
            dropdownColor: context.colorScheme.surface,
            icon: Icon(Icons.keyboard_arrow_down, color: iconColor),
            isExpanded: true,
            validator: validator,
            items: items.map((item) {
              if (item.isDivider) {
                return DropdownMenuItem<DropDownItem<T>>(
                  enabled: false,
                  value: item,
                  child: const Divider()
                );
              }
              final suffix = item.suffix;
              return DropdownMenuItem<DropDownItem<T>>(
                value: item,
                child: suffix == null
                    ? _buildItemRow(context, item, iconColor)
                    : Row(
                        children: [
                          Expanded(child: _buildItemRow(context, item, iconColor)),
                          const SizedBox(width: _iconTextSpacing),
                          Text(
                            suffix,
                            style: AppStyles.formText(context).copyWith(
                              color: context.colorScheme.onSurface.withValues(
                                alpha: isDisabled
                                    ? 0.38
                                    : AppStyles.increasedContrastAlpha(AppStyles.mutedTextAlpha),
                              ),
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: AppStyles.formFieldContentPadding),
            child: Text(
              helperText!,
              style: AppStyles.smallSecondaryText(context).copyWith(
                color: context.colorScheme.onSurface.withValues(
                  alpha: AppStyles.mutedTextAlpha,
                ),
              ),
            ),
          ),
        ],
      ],
    );

    if (trailingIconButton == null) return field;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: field),
        const SizedBox(width: 8),
        Padding(
          padding: EdgeInsets.only(
            top: label != null ? _trailingButtonLabelOffset : 0,
          ),
          child: SizedBox(
            width: _trailingButtonSize,
            height: _trailingButtonSize,
            child: trailingIconButton,
          ),
        ),
      ],
    );
  }
}
