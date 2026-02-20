// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/whats_new_service.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/provider_helpers.dart';
import 'package:heliumapp/presentation/features/planner/bloc/external_calendar_bloc.dart';
import 'package:heliumapp/presentation/core/dialogs/getting_started_dialog.dart';
import 'package:heliumapp/presentation/core/dialogs/whats_new_dialog.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_screen.dart';
import 'package:heliumapp/presentation/features/courses/views/courses_screen.dart';
import 'package:heliumapp/presentation/features/grades/views/grades_screen.dart';
import 'package:heliumapp/presentation/features/resources/views/resources_screen.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/presentation/ui/components/settings_button.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

/// Notifier for screens to share their inheritable providers with NavigationShell.
class InheritableProvidersNotifier extends ChangeNotifier {
  List<BlocProvider>? _providers;

  List<BlocProvider>? get providers => _providers;

  void setProviders(List<BlocProvider>? providers) {
    _providers = providers;
    notifyListeners();
  }
}

/// InheritedWidget to share the InheritableProvidersNotifier with child screens.
class InheritableProvidersScope extends InheritedWidget {
  final InheritableProvidersNotifier notifier;

  const InheritableProvidersScope({
    super.key,
    required this.notifier,
    required super.child,
  });

  static InheritableProvidersNotifier? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritableProvidersScope>()
        ?.notifier;
  }

  @override
  bool updateShouldNotify(InheritableProvidersScope oldWidget) =>
      notifier != oldWidget.notifier;
}

/// InheritedWidget to tell child screens to hide their header.
class NavigationShellProvider extends InheritedWidget {
  const NavigationShellProvider({super.key, required super.child});

  static bool of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<NavigationShellProvider>() !=
        null;
  }

  @override
  bool updateShouldNotify(NavigationShellProvider oldWidget) => false;
}

enum NavigationPage {
  planner('Planner', Icons.calendar_month, AppRoute.plannerScreen),
  courses('Classes', Icons.school, AppRoute.coursesScreen),
  resources('Resources', Icons.book, AppRoute.resourcesScreen),
  grades('Grades', Icons.bar_chart, AppRoute.gradesScreen);

  final String label;
  final IconData icon;
  final String route;

  const NavigationPage(this.label, this.icon, this.route);

  static NavigationPage? fromRoute(String route) {
    try {
      return NavigationPage.values.firstWhere((page) => page.route == route);
    } catch (e) {
      return null;
    }
  }

  Widget buildScreen() {
    switch (this) {
      case NavigationPage.planner:
        return PlannerScreen();
      case NavigationPage.courses:
        return CoursesScreen();
      case NavigationPage.resources:
        return ResourcesScreen();
      case NavigationPage.grades:
        return GradesScreen();
    }
  }
}

/// Shell widget for main tab navigation using go_router.
class NavigationShell extends StatefulWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  // Cache screen widgets to prevent recreation on every build/resize
  final Map<NavigationPage, Widget> _screenCache = {};
  final InheritableProvidersNotifier _inheritableProvidersNotifier =
      InheritableProvidersNotifier();
  final ProviderHelpers _providerHelpers = ProviderHelpers();
  bool _isLoggingOut = false;
  bool _isShowingGettingStarted = false;

  @override
  void initState() {
    super.initState();
    // Pre-build all screens to cache them
    for (final page in NavigationPage.values) {
      _screenCache[page] = page.buildScreen();
    }

    DioClient().cacheService.addInactivityResumeListener(_onInactivityResume);
    _checkDialogs();
  }

  @override
  void dispose() {
    DioClient().cacheService.removeInactivityResumeListener(
      _onInactivityResume,
    );
    _inheritableProvidersNotifier.dispose();
    super.dispose();
  }

  void _onInactivityResume() {
    _checkGettingStartedDialog();
  }

  Future<void> _checkGettingStartedDialog() async {
    if (_isShowingGettingStarted) return;

    final settings = await DioClient().getSettings();
    final showGettingStarted =
        settings?.showGettingStarted ??
        FallbackConstants.defaultShowGettingStarted;

    if (!mounted || !showGettingStarted) return;

    _isShowingGettingStarted = true;
    await showGettingStartedDialog(context: context);
    _isShowingGettingStarted = false;
  }

  Future<void> _checkDialogs() async {
    final settings = await DioClient().getSettings();
    final showGettingStarted =
        settings?.showGettingStarted ??
        FallbackConstants.defaultShowGettingStarted;
    final showWhatsNew = await WhatsNewService().shouldShowWhatsNew();

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (showGettingStarted) {
        _isShowingGettingStarted = true;
        await showGettingStartedDialog(context: context);
        _isShowingGettingStarted = false;
        if (!mounted) return;
      }

      if (showWhatsNew) {
        await showWhatsNewDialog(context: context);
      }
    });
  }

  NavigationPage _getCurrentPage(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return NavigationPage.fromRoute(location) ?? NavigationPage.planner;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    final newPage = NavigationPage.values[index];
    final currentPage = _getCurrentPage(context);
    if (newPage != currentPage) {
      context.go(newPage.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _getCurrentPage(context);

    return BlocProvider<ExternalCalendarBloc>(
      create: _providerHelpers.createExternalCalendarBloc(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedOut) {
            context.go(AppRoute.loginScreen);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useNavigationRail = !Responsive.isMobile(context);

            return Scaffold(
              body: Row(
                children: [
                  if (useNavigationRail)
                    NavigationRail(
                      minWidth: 56,
                      selectedIndex: currentPage.index,
                      onDestinationSelected: (index) =>
                          _onDestinationSelected(context, index),
                      labelType: NavigationRailLabelType.all,
                      destinations: NavigationPage.values
                          .map(
                            (page) => NavigationRailDestination(
                              icon: Icon(
                                page.icon,
                                color: context.colorScheme.primary,
                              ),
                              label: Text(
                                page.label,
                                style: AppStyles.smallSecondaryText(context),
                              ),
                            ),
                          )
                          .toList(),
                      trailing: _buildTrailing(context, constraints.maxHeight),
                      trailingAtBottom: true,
                    ),
                  Expanded(
                    child: SafeArea(
                      bottom: false,
                      child: InheritableProvidersScope(
                        notifier: _inheritableProvidersNotifier,
                        child: Column(
                          children: [
                            // Static PageHeader that doesn't animate
                            ListenableBuilder(
                              listenable: _inheritableProvidersNotifier,
                              builder: (context, _) => PageHeader(
                                title: currentPage.label,
                                screenType: ScreenType.page,
                                inheritableProviders:
                                    _inheritableProvidersNotifier.providers,
                                showLogout:
                                    kIsWeb && !Responsive.isTouchDevice(context),
                                onLogoutConfirmed: () {
                                  setState(() {
                                    _isLoggingOut = true;
                                  });
                                },
                              ),
                            ),
                            // Only the content area animates
                            Expanded(
                              child: _isLoggingOut
                                  ? const LoadingIndicator()
                                  : AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      switchInCurve: Curves.easeInOut,
                                      switchOutCurve: Curves.easeInOut,
                                      transitionBuilder: (child, animation) {
                                        // Vertical slide for NavigationRail
                                        // Horizontal slide for NavigationBar
                                        if (useNavigationRail) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0, 0.1),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          );
                                        } else {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.1, 0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          );
                                        }
                                      },
                                      child: KeyedSubtree(
                                        key: ValueKey(currentPage),
                                        child: NavigationShellProvider(
                                          child:
                                              _screenCache[currentPage] ??
                                              currentPage.buildScreen(),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: useNavigationRail
                  ? null
                  : NavigationBar(
                      height: 60,
                      selectedIndex: currentPage.index,
                      onDestinationSelected: (index) =>
                          _onDestinationSelected(context, index),
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysShow,
                      labelTextStyle: WidgetStateProperty.all(
                        AppStyles.smallSecondaryText(context),
                      ),
                      destinations: NavigationPage.values
                          .map(
                            (page) => NavigationDestination(
                              icon: Icon(
                                page.icon,
                                color: context.colorScheme.primary,
                              ),
                              label: page.label,
                              tooltip: '',
                            ),
                          )
                          .toList(),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context, double availableHeight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!Responsive.isTouchDevice(context) &&
              availableHeight > AppConstants.minHeightForTrailingNav) ...[
            _buildAppStoreButton(
              context: context,
              icon: Icons.apple,
              tooltip: 'Download on the App Store',
              url: AppConstants.iosUrl,
            ),
            const SizedBox(height: 8),
            _buildAppStoreButton(
              context: context,
              icon: Icons.android,
              tooltip: 'Get it on Google Play',
              url: AppConstants.androidUrl,
            ),
          ],
          const SizedBox(width: 40, child: Divider()),
          const SettingsButton(compact: false),
        ],
      ),
    );
  }

  Widget _buildAppStoreButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required String url,
  }) {
    return IconButton(
      onPressed: () {
        launchUrl(Uri.parse(url));
      },
      icon: Icon(icon, color: context.colorScheme.primary),
      tooltip: tooltip,
    );
  }
}

/// Content widget for shell routes - displays the appropriate screen.
class NavigationShellContent extends StatelessWidget {
  final NavigationPage page;

  const NavigationShellContent({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    // The actual content is handled by NavigationShell's AnimatedSwitcher
    // This widget is just a marker for go_router
    return const SizedBox.shrink();
  }
}
