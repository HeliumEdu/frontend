import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_style.dart';

class HeliumElevatedButton extends StatefulWidget {
  static const _buttonBorderRadius = 6.0;
  static const _buttonMinHeight = 44.0;
  static const _buttonHorizontalPadding = 12.0;
  static const _iconSize = 16.0;
  static const _loadingIndicatorSize = 20.0;
  static const _loadingIndicatorStrokeWidth = 2.5;

  final String buttonText;
  final IconData? icon;
  final Color? iconColor;
  final Function onPressed;
  final bool isLoading;
  final bool enabled;
  final Color? backgroundColor;
  final bool fullWidth;
  final double? minHeight;
  final VisualDensity? visualDensity;

  const HeliumElevatedButton({
    super.key,
    required this.buttonText,
    this.icon,
    this.iconColor,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.backgroundColor,
    this.fullWidth = true,
    this.minHeight,
    this.visualDensity,
  });

  static ButtonStyle baseStyle(
    ColorScheme colorScheme, {
    Color? backgroundColor,
    double minimumWidth = double.infinity,
    double minimumHeight = _buttonMinHeight,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        backgroundColor ?? colorScheme.primary,
      ),
      foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
      minimumSize: WidgetStatePropertyAll(Size(minimumWidth, minimumHeight)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: _buttonHorizontalPadding),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonBorderRadius)),
      ),
    );
  }

  @override
  State<HeliumElevatedButton> createState() => _HeliumElevatedButtonState();
}

class _HeliumElevatedButtonState extends State<HeliumElevatedButton> {
  bool _pressInFlight = false;

  /// Only an async [HeliumElevatedButton.onPressed] is gated, where a dialog,
  /// picker or route stays in flight long enough for a second tap to duplicate it.
  void _handlePress() {
    if (_pressInFlight) {
      return;
    }

    final result = widget.onPressed();
    if (result is! Future<dynamic>) {
      return;
    }

    _pressInFlight = true;
    result.whenComplete(() => _pressInFlight = false);
  }

  @override
  Widget build(BuildContext context) {
    // When disabled, dim the icon to match the disabled label rather than leaving it the
    // enabled `onPrimary`, which is illegible on the dimmed background (notably in dark mode).
    final effectiveIconColor = widget.enabled
        ? (widget.iconColor ?? context.colorScheme.onPrimary)
        : context.colorScheme.onSurface.withValues(alpha: 0.38);
    final effectiveBg = !widget.isLoading && widget.enabled
        ? widget.backgroundColor ?? context.colorScheme.primary
        : context.colorScheme.onSurface.withValues(alpha: 0.12);

    return ElevatedButton.icon(
      onPressed: widget.isLoading || !widget.enabled ? null : _handlePress,
      icon: !widget.isLoading && widget.icon != null
          ? Icon(
              widget.icon,
              size: HeliumElevatedButton._iconSize,
              color: effectiveIconColor,
            )
          : null,
      style: HeliumElevatedButton.baseStyle(
        context.colorScheme,
        backgroundColor: effectiveBg,
        minimumWidth: widget.fullWidth ? double.infinity : 0,
        minimumHeight: widget.minHeight ?? HeliumElevatedButton._buttonMinHeight,
      ).copyWith(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: widget.visualDensity,
      ),
      label: widget.isLoading
          ? LoadingIndicator(
              size: HeliumElevatedButton._loadingIndicatorSize,
              strokeWidth: HeliumElevatedButton._loadingIndicatorStrokeWidth,
              expanded: false,
              color: context.colorScheme.onSurface.withValues(alpha: 0.38),
            )
          : Text(
              widget.buttonText,
              style: widget.enabled
                  ? AppStyles.buttonText(context)
                  : AppStyles.buttonText(context).copyWith(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                    ),
            ),
    );
  }
}
