// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/core/motion_service.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

const String gettingStartedDismissButtonKey = 'getting_started_dismiss_button';

class _OnboardingCard {
  final String title;
  final String description;
  final IconData icon;
  final List<String> imagePaths;
  final bool stackedDevices;
  final String? overlayImagePath;

  const _OnboardingCard({
    required this.title,
    required this.description,
    required this.icon,
    this.imagePaths = const [],
    this.stackedDevices = false,
    this.overlayImagePath,
  });
}

const _cards = [
  _OnboardingCard(
    title: 'Welcome to Helium!',
    description:
        "We've preloaded your account with an example schedule so you can "
        'see Helium in action. Take your time exploring — click through '
        'to see what you can do.',
    icon: Icons.rocket_launch_outlined,
    imagePaths: ['assets/img/onboarding_month_view.png'],
  ),
  _OnboardingCard(
    title: 'One Planner, every view',
    description:
        'Switch between Month, Week, Day, Agenda, and Todos views. '
        'Open for details, drag to reschedule, filter, search, sort '
        'by priority — everything you need to stay on top of your '
        'schedule.',
    icon: Icons.calendar_month_outlined,
    imagePaths: [
      'assets/img/onboarding_week_view.png',
      'assets/img/onboarding_todos.png',
    ],
  ),
  _OnboardingCard(
    title: 'Organized by class',
    description:
        'View Classes to see how your schedules, categories, and '
        'assignments connect. Track deadlines, class times, locations, '
        'and Resources — all in one place.',
    icon: Icons.school_outlined,
    imagePaths: ['assets/img/onboarding_class_manager.png'],
  ),
  _OnboardingCard(
    title: 'Know your grades',
    description:
        'Visit Grades to see your scores by class, category, '
        'and term in real time. Know where to focus, what is '
        'piling up, and calculate what you need to score on the final.',
    icon: Icons.bar_chart_outlined,
    imagePaths: [
      'assets/img/onboarding_grades_dashboard.png',
      'assets/img/onboarding_grades_breakdown.png',
    ],
    overlayImagePath: 'assets/img/onboarding_grade_calculator_square.png',
  ),
  _OnboardingCard(
    title: 'Notes for anything',
    description:
        'Write notes linked to anything in your Planner — lecture '
        'summaries, paper drafts, whatever else. Format like a doc, search '
        'everything, '
        'and print when you need a hard copy.',
    icon: Icons.library_books,
    imagePaths: ['assets/img/onboarding_notebook.png'],
  ),
  _OnboardingCard(
    title: 'Sync with other calendars',
    description:
        'Use External Calendars to pull in events from Google, '
        'Apple, or other calendars. Enable Feeds to share your Helium '
        'schedule back to those other apps.',
    icon: Icons.sync_outlined,
    imagePaths: ['assets/img/onboarding_external_calendars.png'],
  ),
  _OnboardingCard(
    title: 'Available everywhere',
    description:
        'Native apps for iOS and Android, plus web in any modern '
        'browser. Your schedule and notes stay in sync no matter which '
        'device you use — always right there.',
    icon: Icons.devices_outlined,
    stackedDevices: true,
  ),
  _OnboardingCard(
    title: 'Ready when you are',
    description:
        "You'll see this welcome screen each time you open Helium or "
        'return after a break, so you can keep exploring. Once you '
        'clear the example data, it will go away.',
    icon: Icons.auto_delete_outlined,
    imagePaths: ['assets/img/onboarding_reminders.png'],
  ),
];

class _GettingStartedDialogWidget extends StatefulWidget {
  const _GettingStartedDialogWidget();

  @override
  State<_GettingStartedDialogWidget> createState() =>
      _GettingStartedDialogWidgetState();
}

class _GettingStartedDialogWidgetState
    extends State<_GettingStartedDialogWidget> {
  static const double _desktopWidth = 600.0;
  static const double _pageViewHeight = 465.0;
  static const double _pageViewHeightMobile = 390.0;
  static const double _dotSize = 8.0;
  static const double _activeDotSize = 10.0;

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final savedPage =
        PrefService().getInt(SettingsPrefKey.gettingStartedLastPage.key) ?? 0;
    _currentPage = savedPage.clamp(0, _cards.length - 1);
    _pageController = PageController(initialPage: _currentPage);
    router.routerDelegate.addListener(_dismissIfOverlayActive);
  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_dismissIfOverlayActive);
    _pageController.dispose();
    super.dispose();
  }

  /// Pops this dialog when the user opens a route-based overlay (settings,
  /// notifications, an entity editor). The promotional dialog yields to
  /// any deliberate navigation rather than being left stranded under it.
  void _dismissIfOverlayActive() {
    if (!mounted) return;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final onShellTab =
        NavigationPage.values.any((page) => page.route == path);
    if (!onShellTab) {
      Navigator.of(context).pop();
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    PrefService().setInt(SettingsPrefKey.gettingStartedLastPage.key, page);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final dialogWidth = isMobile
        ? MediaQuery.of(context).size.width * 0.95
        : _desktopWidth;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthScheduleDataRefreshed) {
          if (!context.mounted) return;

          final navigator = Navigator.maybeOf(context);
          if (navigator?.canPop() ?? false) {
            navigator!.pop();
          }

          if (!context.mounted) return;
          // Defer so SfCalendar's pending post-frame setState fires before
          // the branch swap disposes it.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.go(AppRoute.coursesScreen);
          });
        } else if (state is AuthError) {
          if (!context.mounted) return;
          SnackBarHelper.show(
            context,
            'Failed to delete example schedule: ${state.message}',
            type: SnackType.error,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Dialog(
            insetPadding: isMobile
                ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 24.0)
                : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: SizedBox(
                        height: isMobile
                            ? _pageViewHeightMobile
                            : _pageViewHeight,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: _cards.length,
                          itemBuilder: (context, index) =>
                              _buildCard(context, _cards[index]),
                        ),
                      ),
                    ),
                  ),
                  _buildNavigation(context),
                  _buildActions(context, isLoading),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, _OnboardingCard card) {
    // Images render blurry on web due to poor CanvasKit downscaling.
    // https://github.com/flutter/flutter/issues/135655
    Widget imageWidget = const SizedBox.shrink();
    if (card.stackedDevices) {
      imageWidget = const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: _StackedDevices(),
      );
    } else if (card.imagePaths.isNotEmpty) {
      imageWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: card.imagePaths.length > 1
            ? _CyclingImage(
                imagePaths: card.imagePaths,
                overlayImagePath: card.overlayImagePath,
              )
            : Image.asset(
                card.imagePaths.first,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        card.icon,
                        color: context.colorScheme.primary,
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SelectableText(
                        card.title,
                        style: AppStyles.pageTitle(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  card.description,
                  style: AppStyles.standardBodyText(context),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(alignment: Alignment.topCenter, child: imageWidget),
        ),
      ],
    );
  }

  Widget _buildNavigation(BuildContext context) {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == _cards.length - 1;
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: isFirst
                ? const SizedBox.shrink()
                : Semantics(
                    label: 'Previous',
                    button: true,
                    child: IconButton(
                      onPressed: () => MotionService().reduceMotion
                          ? _pageController.jumpToPage(_currentPage - 1)
                          : _pageController.previousPage(
                              duration: AppConstants.uiAnimationDuration,
                              curve: Curves.easeInOut,
                            ),
                      icon: const Icon(Icons.chevron_left),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_cards.length, (index) {
                final isActive = index == _currentPage;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Feedback.forTap(context);
                      if (MotionService().reduceMotion) {
                        _pageController.jumpToPage(index);
                      } else {
                        _pageController.animateToPage(
                          index,
                          duration: AppConstants.uiAnimationDuration,
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: MotionService().effectiveDuration(const Duration(milliseconds: 200)),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: isActive ? _activeDotSize : _dotSize,
                      height: isActive ? _activeDotSize : _dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurface.withValues(
                                alpha: 0.25,
                              ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            width: 40,
            child: isLast
                ? const SizedBox.shrink()
                : Semantics(
                    label: 'Next',
                    button: true,
                    child: IconButton(
                      onPressed: () => MotionService().reduceMotion
                          ? _pageController.jumpToPage(_currentPage + 1)
                          : _pageController.nextPage(
                              duration: AppConstants.uiAnimationDuration,
                              curve: Curves.easeInOut,
                            ),
                      icon: const Icon(Icons.chevron_right),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isLoading) {
    final isMobile = Responsive.isMobile(context);
    final buttonWidth = isMobile
        ? MediaQuery.of(context).size.width * 0.9 - 48
        : _desktopWidth - 48;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          SizedBox(
            width: buttonWidth,
            child: HeliumElevatedButton(
              buttonText: 'Clear Example Data',
              icon: Icons.delete_outline,
              isLoading: isLoading,
              enabled: !isLoading,
              backgroundColor: context.colorScheme.error,
              onPressed: () {
                context.read<AuthBloc>().add(DeleteExampleScheduleEvent());
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: buttonWidth,
            child: TextButton(
              key: const Key(gettingStartedDismissButtonKey),
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                "I'll explore first",
                style: AppStyles.standardBodyText(
                  context,
                ).copyWith(color: context.colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CyclingImage extends StatefulWidget {
  final List<String> imagePaths;
  final String? overlayImagePath;

  const _CyclingImage({required this.imagePaths, this.overlayImagePath});

  @override
  State<_CyclingImage> createState() => _CyclingImageState();
}

class _CyclingImageState extends State<_CyclingImage> {
  static const _cycleDuration = Duration(milliseconds: 3500);
  static const _fadeDuration = Duration(milliseconds: 600);

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_cycleDuration, (_) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.imagePaths.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedSwitcher(
          duration: MotionService().effectiveDuration(_fadeDuration),
          child: Image.asset(
            widget.imagePaths[_currentIndex],
            key: ValueKey(_currentIndex),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        if (widget.overlayImagePath != null)
          AnimatedOpacity(
            opacity: _currentIndex == 1 ? 1.0 : 0.0,
            duration: MotionService().effectiveDuration(_fadeDuration),
            child: FractionallySizedBox(
              widthFactor: 0.40,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 50,
                      spreadRadius: -12,
                      offset: const Offset(0, 25),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.overlayImagePath!,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StackedDevices extends StatelessWidget {
  const _StackedDevices();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1880 / 1000,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final dpr = MediaQuery.of(context).devicePixelRatio;
          int cache(double v) => (v * dpr * 2).round();
          return FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/img/frame_phone.png',
                  height: h,
                  cacheHeight: cache(h),
                  fit: BoxFit.fitHeight,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/img/frame_tablet.png',
                  height: h * 0.72,
                  cacheHeight: cache(h * 0.72),
                  fit: BoxFit.fitHeight,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/img/frame_laptop.png',
                  height: h * 0.56,
                  cacheHeight: cache(h * 0.56),
                  fit: BoxFit.fitHeight,
                  filterQuality: FilterQuality.high,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> showGettingStartedDialog(BuildContext parentContext) {
  return showDialog(
    context: parentContext,
    builder: (BuildContext dialogContext) {
      return const _GettingStartedDialogWidget();
    },
  );
}
