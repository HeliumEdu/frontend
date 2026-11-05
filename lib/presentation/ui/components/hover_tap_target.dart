import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/ui/components/helium_icon_button.dart';

/// An icon, and any count beside it, that responds to hover the way an icon
/// button does: the app's icon button shape, at least an icon button's size,
/// tinted in [color]. The shape is painted around [child] without taking
/// layout space, so it fits wherever [child] fits. [hitPadding] widens the tap
/// target into space the caller can spare. [onTap] gets the target's own
/// context, to anchor a menu to it.
class HoverTapTarget extends StatefulWidget {
  final Widget child;
  final void Function(BuildContext anchorContext) onTap;
  final Color color;
  final String? tooltip;
  final EdgeInsets hitPadding;

  const HoverTapTarget({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
    this.tooltip,
    this.hitPadding = EdgeInsets.zero,
  });

  /// The height of an icon button, which the hover shape is at least.
  static double extentOf(BuildContext context) =>
      HeliumIconButton.defaultIconSize(context) +
      HeliumIconButton.padding.vertical;

  @override
  State<HoverTapTarget> createState() => _HoverTapTargetState();
}

class _HoverTapTargetState extends State<HoverTapTarget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final extent = HoverTapTarget.extentOf(context);
    final shape =
        Theme.of(context).iconButtonTheme.style?.shape?.resolve({}) ??
        const StadiumBorder();

    Widget target = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(context),
        child: Padding(
          padding: widget.hitPadding,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = math.max(
                      constraints.maxWidth + HeliumIconButton.padding.horizontal,
                      extent,
                    );
                    final height = math.max(
                      constraints.maxHeight + HeliumIconButton.padding.vertical,
                      extent,
                    );
                    return OverflowBox(
                      minWidth: width,
                      maxWidth: width,
                      minHeight: height,
                      maxHeight: height,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            shape: shape,
                            color: _isHovered
                                ? widget.color.withValues(alpha: 0.12)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              widget.child,
            ],
          ),
        ),
      ),
    );
    if (widget.tooltip != null) {
      target = Tooltip(message: widget.tooltip!, child: target);
    }
    return target;
  }
}
