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
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_event.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';

const String gettingStartedDismissButtonKey = 'getting_started_dismiss_button';

class _OnboardingCard {
  final String title;
  final String description;
  final IconData icon;
  final List<String> imagePaths;

  const _OnboardingCard({
    required this.title,
    required this.description,
    required this.icon,
    this.imagePaths = const [],
  });
}

const _cards = [
  _OnboardingCard(
    title: 'Welcome to Helium!',
    description:
        "We've preloaded your account with an example schedule so you can "
        'see Helium in action. Take your time exploring—click through '
        'to see what you can do.',
    icon: Icons.rocket_launch_outlined,
    imagePaths: ['assets/img/onboarding_welcome.png'],
  ),
  _OnboardingCard(
    title: 'Your Planner, your way',
    description:
        'Switch between time-based views and Todos. Click for details, '
        'drag to reschedule, filter, search, sort by priority—everything '
        'you need to stay on top of your schedule.',
    icon: Icons.calendar_month_outlined,
    imagePaths: [
      'assets/img/onboarding_planner.png',
      'assets/img/onboarding_todos.png',
    ],
  ),
  _OnboardingCard(
    title: 'Organized by class',
    description:
        'View Classes to see how your schedules, categories, and '
        'assignments connect. Track deadlines, class times, locations, '
        'and resources—all in one place.',
    icon: Icons.school_outlined,
    imagePaths: ['assets/img/onboarding_classes.png'],
  ),
  _OnboardingCard(
    title: 'Track your grades',
    description:
        'Check out Grades to see how your scores break down by class. '
        'Great for spotting trends giving you the clarity you need to '
        'know where to focus next and stay ahead.',
    icon: Icons.bar_chart_outlined,
    imagePaths: ['assets/img/onboarding_grades.png'],
  ),
  _OnboardingCard(
    title: 'Keep a Notebook',
    description:
        'Write rich notes linked directly to items in your planner. Or '
        'keep standalone notes for anything else. Lecture summaries, '
          'paper drafts, everything organized in one place.',
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
    imagePaths: ['assets/img/onboarding_sync.png'],
  ),
  _OnboardingCard(
    title: 'Available everywhere',
    description:
        'Helium works seamlessly across web, iOS, and Android. Your '
        'schedule stays in sync no matter which device you use, so your '
        'entire planner is always just one tap away.',
    icon: Icons.devices_outlined,
    imagePaths: ['assets/img/onboarding_everywhere.png'],
  ),
  _OnboardingCard(
    title: 'Ready when you are',
    description:
        "You'll see this dialog each time you open Helium or return "
        'after a break, so you can keep exploring. Once you clear the '
        'example data, it will go away.',
    icon: Icons.auto_delete_outlined,
    imagePaths: ['assets/img/onboarding_ready.png'],
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
  static const double _desktopWidth = 700.0;
  static const double _pageViewHeight = 420.0;
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          context.go(AppRoute.coursesScreen);
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
    Widget imageWidget = const SizedBox.shrink();
    if (card.imagePaths.isNotEmpty) {
      final isMobile = Responsive.isMobile(context);
      if (card.imagePaths.length > 1 && isMobile) {
        imageWidget = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: _CyclingImage(imagePaths: card.imagePaths),
        );
      } else if (card.imagePaths.length > 1) {
        imageWidget = Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < card.imagePaths.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: Image.asset(
                    card.imagePaths[i],
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ],
          ),
        );
      } else {
        imageWidget = Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Image.asset(card.imagePaths.first, fit: BoxFit.contain),
        );
      }
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
                      child: Text(
                        card.title,
                        style: AppStyles.pageTitle(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  card.description,
                  style: AppStyles.standardBodyText(context),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(hasScrollBody: false, child: imageWidget),
      ],
    );
  }

  Widget _buildNavigation(BuildContext context) {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == _cards.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: isFirst
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    icon: const Icon(Icons.chevron_left),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
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
                : IconButton(
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    icon: const Icon(Icons.chevron_right),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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

  const _CyclingImage({required this.imagePaths});

  @override
  State<_CyclingImage> createState() => _CyclingImageState();
}

class _CyclingImageState extends State<_CyclingImage> {
  static const _cycleDuration = Duration(milliseconds: 2500);
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
    return AnimatedSwitcher(
      duration: _fadeDuration,
      child: Image.asset(
        widget.imagePaths[_currentIndex],
        key: ValueKey(_currentIndex),
        fit: BoxFit.contain,
      ),
    );
  }
}

Future<void> showGettingStartedDialog(BuildContext parentContext) {
  return showDialog(
    context: parentContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return const _GettingStartedDialogWidget();
    },
  );
}
