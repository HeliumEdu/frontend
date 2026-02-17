// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/presentation/features/shared/widgets/flow/stepper_header.dart';

export 'package:heliumapp/data/models/auth/user_model.dart'
    show UserSettingsModel;
export 'package:heliumapp/presentation/core/views/base_page_screen_state.dart'
    show showScreenAsDialog;
export 'package:heliumapp/presentation/ui/layout/page_header.dart'
    show ScreenType;

class MultiStepDefinition {
  final IconData icon;
  final String? tooltip;
  final Widget Function(BuildContext context) builder;

  final ScreenType stepScreenType;

  const MultiStepDefinition({
    required this.icon,
    this.tooltip,
    required this.builder,
    this.stepScreenType = ScreenType.entityPage,
  });
}

abstract class MultiStepContainer extends StatefulWidget {
  final bool isEdit;
  final bool isNew;
  final int initialStep;

  const MultiStepContainer({
    super.key,
    required this.isEdit,
    required this.isNew,
    this.initialStep = 0,
  });
}

abstract class MultiStepContainerState<T extends MultiStepContainer>
    extends BasePageScreenState<T>
    with TickerProviderStateMixin {
  List<MultiStepDefinition> get steps;

  List<BlocProvider>? get providers => null;

  @override
  ScreenType get screenType => steps[_currentStep].stepScreenType;

  int get currentStep => _currentStep;

  bool get enableNextSteps => false;

  // State
  late int _currentStep;
  int _previousStep = 0;

  void navigateToStep(int step) {
    if (step < 0 || step >= steps.length) return;
    if (!mounted) return;

    setState(() {
      _previousStep = _currentStep;
      _currentStep = step;
    });
  }

  void onStepRequested(int step) {
    if (step == _currentStep) return;
    navigateToStep(step);
  }

  @override
  void initState() {
    super.initState();

    _currentStep = widget.initialStep;
    _previousStep = widget.initialStep;
  }

  @override
  Future<UserSettingsModel?> loadSettings() {
    return super.loadSettings().then((settings) {
      if (!mounted) return settings;
      setState(() {
        isLoading = false;
      });
      return settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = super.build(context);

    final providersList = providers;
    if (providersList != null && providersList.isNotEmpty) {
      content = MultiBlocProvider(providers: providersList, child: content);
    }

    return content;
  }

  @override
  Widget buildHeaderArea(BuildContext context) {
    if (steps.length <= 1) {
      return const SizedBox.shrink();
    }
    return _buildStepperHeader(context);
  }

  @override
  Widget buildMainArea(BuildContext context) {
    final isForward = _currentStep > _previousStep;

    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: Offset(isForward ? 1.0 : -1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentStep),
          child: steps[_currentStep].builder(context),
        ),
      ),
    );
  }

  Widget _buildStepperHeader(BuildContext context) {
    return StepperHeader(
      steps: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        // First step is always enabled, subsequent steps wait until save
        final isEnabled = index == 0 || enableNextSteps;
        return (icon: step.icon, isEnabled: isEnabled, tooltip: step.tooltip);
      }).toList(),
      currentStep: _currentStep,
      onStepTapped: onStepRequested,
    );
  }
}
