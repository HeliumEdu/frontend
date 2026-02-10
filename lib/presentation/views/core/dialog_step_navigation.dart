// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/views/core/base_page_screen_state.dart';

/// Generic InheritedWidget that provides step navigation callback for multi-step
/// flows in dialog mode.
class DialogStepNavigator extends InheritedWidget {
  final void Function(int step) onNavigate;

  const DialogStepNavigator({
    super.key,
    required this.onNavigate,
    required super.child,
  });

  static DialogStepNavigator? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DialogStepNavigator>();
  }

  @override
  bool updateShouldNotify(DialogStepNavigator oldWidget) {
    return onNavigate != oldWidget.onNavigate;
  }
}

/// Generic helper function to navigate to a step when in dialog mode.
/// Returns true if navigation was handled (dialog mode), false otherwise.
///
/// Usage in step screens when advancing:
/// ```dart
/// if (!navigateStepInDialog(context, nextStepIndex)) {
///   // Fall back to router navigation
///   context.pushReplacement(route, extra: args);
/// }
/// ```
bool navigateStepInDialog(BuildContext context, int stepIndex) {
  final navigator = DialogStepNavigator.maybeOf(context);
  if (navigator != null) {
    navigator.onNavigate(stepIndex);
    return true;
  }
  return false;
}

/// Base class for stepper containers that manage multi-step flows in dialog mode.
///
/// When displayed as a dialog, the container handles step navigation internally
/// by swapping screens. When not in dialog mode, each screen handles its own
/// navigation using GoRouter.
///
/// Subclasses must implement [buildStepWidget] to return the appropriate widget
/// for each step index.
abstract class DialogStepperContainer extends StatefulWidget {
  final int initialStep;

  const DialogStepperContainer({
    super.key,
    this.initialStep = 0,
  });

  @override
  State<DialogStepperContainer> createState() => _DialogStepperContainerState();

  /// Build the widget for the given step index.
  /// This method should use the step enum's buildWidget method.
  Widget buildStepWidget(BuildContext context, int stepIndex);
}

class _DialogStepperContainerState extends State<DialogStepperContainer> {
  // State
  late int _currentStep;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
  }

  void _navigateToStep(int step) {
    if (mounted) {
      setState(() {
        _currentStep = step;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only manage steps internally when in dialog mode
    final isDialogMode = DialogModeProvider.isDialogMode(context);

    final currentStepWidget = widget.buildStepWidget(context, _currentStep);

    if (!isDialogMode) {
      // In normal mode, just show the current step
      return currentStepWidget;
    }

    // In dialog mode, wrap with navigator that provides step navigation callback
    return DialogStepNavigator(
      onNavigate: _navigateToStep,
      child: currentStepWidget,
    );
  }
}
