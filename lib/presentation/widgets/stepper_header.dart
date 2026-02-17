// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';
import 'package:heliumapp/presentation/widgets/shadow_container.dart';

typedef StepperHeaderStep = ({IconData icon, bool isEnabled, String? tooltip});

/// A horizontal stepper header widget that displays step icons with
/// connecting lines, supporting current step highlighting, disabled states,
/// and tap navigation.
class StepperHeader extends StatefulWidget {
  /// List of steps to display.
  final List<StepperHeaderStep> steps;

  /// The currently active step index (0-based).
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
    final dialogProvider = DialogModeProvider.maybeOf(context);

    // Use dialog width if available, otherwise use screen width
    final availableWidth =
        dialogProvider?.width ?? MediaQuery.sizeOf(context).width;

    // Account for container padding (8 from ShadowContainer, 12 from outer padding on each side)
    final contentWidth = availableWidth - 40;

    // Calculate sizes based on available width
    // We need to fit: steps.length circles + (steps.length - 1) lines + margins
    // Minimum line length: 16px, margin per line: 8px (4 on each side)
    final minLineTotal = (widget.steps.length - 1) * 24.0; // 16 + 8 margin
    final availableForCircles = contentWidth - minLineTotal;

    // Calculate circle size to fit, but cap between 36 and 48
    final maxCircleSize = availableForCircles / widget.steps.length;
    final circleSize = maxCircleSize.clamp(36.0, 48.0);
    final iconSize = (circleSize * 0.42).clamp(16.0, 22.0);

    // Calculate line length with remaining space, but cap to avoid excessive stretching
    final totalCircleWidth = circleSize * widget.steps.length;
    final remainingWidth = contentWidth - totalCircleWidth;
    final lineLength = widget.steps.length > 1
        ? math.min(
            56.0,
            math.max(16.0, (remainingWidth / (widget.steps.length - 1)) - 8),
          )
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadowContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: _buildStepRow(context, circleSize, iconSize, lineLength),
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
      // Add step circle
      widgets.add(_buildStepCircle(context, i, circleSize, iconSize));

      // Add connecting line after each step except the last
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

    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: Icon(step.icon, color: iconColor, size: iconSize),
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
          onTap: () => onStepTapped!(index),
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
