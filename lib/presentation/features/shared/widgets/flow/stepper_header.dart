import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/presentation/ui/layout/shadow_container.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

typedef StepperHeaderStep = ({IconData icon, bool isEnabled, String? tooltip});

/// A horizontal stepper header widget that displays step icons with
/// connecting lines, supporting current step highlighting, disabled states,
/// and tap navigation.
class StepperHeader extends StatefulWidget {
  /// List of steps to display
  final List<StepperHeaderStep> steps;

  /// The currently active step index (0-based)
  final int currentStep;

  /// Callback when a step is tapped. If null, steps are not tappable.
  final ValueChanged<int>? onStepTapped;

  const StepperHeader({
    super.key,
    required this.steps,
    required this.currentStep,
    this.onStepTapped,
  });

  @override
  State<StepperHeader> createState() => _StepperHeaderState();
}

class _StepperHeaderState extends State<StepperHeader> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadowContainer(
        padding: Responsive.isNarrowMobile(context)
            ? const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: AppConstants.containerContentInset,
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // LayoutBuilder is already inside ShadowContainer's padding,
              // so constraints.maxWidth is the true available content width.
              final contentWidth = constraints.maxWidth;

              final isMobile = Responsive.isMobile(context);
              final circleSize = isMobile ? 44.0 : 48.0;
              final iconSize = isMobile ? 18.0 : 20.0;

              final totalCircleWidth = circleSize * widget.steps.length;
              final remainingWidth = contentWidth - totalCircleWidth;
              final lineLength = widget.steps.length > 1
                  ? math
                      .min(
                        56.0,
                        math.max(
                          0.0,
                          (remainingWidth / (widget.steps.length - 1)) - 8,
                        ),
                      )
                      .floorToDouble()
                  : 0.0;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    _buildStepRow(context, circleSize, iconSize, lineLength),
              );
            },
          ),
        ),
      ),
    );
  }

  List<StepperHeaderStep> get steps => widget.steps;
  int get currentStep => widget.currentStep;
  ValueChanged<int>? get onStepTapped => widget.onStepTapped;

  List<Widget> _buildStepRow(
    BuildContext context,
    double circleSize,
    double iconSize,
    double lineLength,
  ) {
    final List<Widget> widgets = [];

    for (int i = 0; i < steps.length; i++) {
      widgets.add(_buildStepCircle(context, i, circleSize, iconSize));

      if (i < steps.length - 1) {
        widgets.add(_buildConnectingLine(context, i, lineLength));
      }
    }

    return widgets;
  }

  Widget _buildStepCircle(
    BuildContext context,
    int index,
    double size,
    double iconSize,
  ) {
    final step = steps[index];
    final isActive = index == currentStep;
    final isCompleted = index < currentStep;
    final isEnabled = step.isEnabled;
    final isHovered = _hoveredIndex == index;

    // Determine colors based on state
    final Color backgroundColor;
    final Color borderColor;
    final Color iconColor;

    if (isActive) {
      // Current step: filled primary color (no hover effect)
      backgroundColor = context.colorScheme.primary;
      borderColor = context.colorScheme.primary;
      iconColor = context.colorScheme.surface;
    } else if (isCompleted && isEnabled) {
      // Completed step: light primary fill
      backgroundColor = isHovered
          ? context.colorScheme.primary.withValues(alpha: 0.25)
          : context.colorScheme.primary.withValues(alpha: 0.1);
      borderColor = isHovered
          ? context.colorScheme.primary.withValues(alpha: 0.8)
          : context.colorScheme.primary;
      iconColor = context.colorScheme.primary;
    } else if (isEnabled) {
      // Enabled but not active/completed: light primary fill
      backgroundColor = isHovered
          ? context.colorScheme.primary.withValues(alpha: 0.25)
          : context.colorScheme.primary.withValues(alpha: 0.1);
      borderColor = isHovered
          ? context.colorScheme.primary.withValues(alpha: 0.8)
          : context.colorScheme.primary;
      iconColor = context.colorScheme.primary;
    } else {
      // Disabled step
      backgroundColor = Theme.of(context).scaffoldBackgroundColor;
      borderColor = context.colorScheme.outline.withValues(alpha: 0.2);
      iconColor = context.colorScheme.primary.withValues(alpha: 0.3);
    }

    // SizedBox controls layout size and snaps immediately on resize.
    // AnimatedContainer inside handles only decoration (hover color transitions).
    final circle = SizedBox(
      width: size,
      height: size,
      child: AnimatedContainer(
        duration: MotionService().effectiveDuration(const Duration(milliseconds: 150)),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Center(
          child: Icon(step.icon, color: iconColor, size: iconSize),
        ),
      ),
    );

    // Wrap with tooltip and tap detection if enabled
    Widget result = circle;

    if (step.tooltip != null) {
      result = Tooltip(message: step.tooltip!, child: result);
    }

    if (onStepTapped != null && isEnabled) {
      result = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: GestureDetector(
          onTap: () {
            Feedback.forTap(context);
            onStepTapped!(index);
          },
          child: result,
        ),
      );
    }

    return result;
  }

  Widget _buildConnectingLine(BuildContext context, int index, double length) {
    // Line is "completed" if the next step is at or before current step
    final isCompleted = index < currentStep;
    final isActive = index == currentStep - 1;
    final nextStepEnabled =
        index + 1 < steps.length && steps[index + 1].isEnabled;

    final Color lineColor;
    if (isCompleted && nextStepEnabled) {
      lineColor = context.colorScheme.primary;
    } else if (isActive && nextStepEnabled) {
      lineColor = context.colorScheme.primary.withValues(alpha: 0.5);
    } else {
      lineColor = context.colorScheme.outline.withValues(alpha: 0.1);
    }

    return Container(
      width: length,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: lineColor,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
