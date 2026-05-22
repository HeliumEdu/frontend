// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/whats_new_service.dart';
import 'package:heliumapp/presentation/core/dialogs/getting_started_dialog.dart';
import 'package:heliumapp/presentation/core/dialogs/whats_new_dialog.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:heliumapp/presentation/features/auth/bloc/auth_state.dart';
import 'package:heliumapp/presentation/features/courses/views/courses_screen.dart';
import 'package:heliumapp/presentation/features/grades/views/grades_screen.dart';
import 'package:heliumapp/presentation/features/notebook/views/notebook_screen.dart';
import 'package:heliumapp/presentation/features/planner/views/planner_screen.dart';
import 'package:heliumapp/presentation/features/resources/views/resources_screen.dart';
// Conditional import for web platform
import 'package:heliumapp/presentation/navigation/shell/navigation_shell_title_stub.dart'
    if (dart.library.js_interop) 'package:heliumapp/presentation/navigation/shell/navigation_shell_title_web.dart'
    as title_helper;
import 'package:heliumapp/presentation/ui/components/settings_button.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/utils/app_assets.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';
import 'package:heliumapp/utils/url_helpers.dart';

final _log = Logger('presentation.navigation');

/// Notifier for screens to share their inheritable providers with NavigationShell
class InheritableProvidersNotifier extends ChangeNotifier {
  List<BlocProvider>? _providers;

  List<BlocProvider>? get providers => _providers;

  void setProviders(List<BlocProvider>? providers) {
    _providers = providers;
    notifyListeners();
  }
}

/// InheritedWidget to share the InheritableProvidersNotifier with child screens
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

/// InheritedWidget to tell child screens to hide their header
class NavigationShellProvider extends InheritedWidget {
  const NavigationShellProvider({
    super.key,
    required this.label,
    required super.child,
  });

  final String label;

  static bool of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<NavigationShellProvider>() !=
        null;
  }

  static String? currentLabel(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NavigationShellProvider>()
        ?.label;
  }

  @override
  bool updateShouldNotify(NavigationShellProvider oldWidget) =>
      label != oldWidget.label;
}

/// Exposes the live [StatefulNavigationShell] so descendants can compute the
/// current branch's root path (e.g. `/notebook`) on demand.
///
/// `router.routerDelegate.currentConfiguration.uri.path` is unreliable for
/// this — `StatefulShellRoute.indexedStack` does not always reflect the
/// active branch's location in the router's top-level URI, so the URI-based
/// read can lag behind the actually-selected branch. `currentIndex` on the
/// shell is a live getter and always reflects the active branch.
class BranchPathScope extends InheritedWidget {
  const BranchPathScope({
    super.key,
    required this.navigationShell,
    required super.child,
  });

  final StatefulNavigationShell navigationShell;

  static String of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BranchPathScope>();
    assert(
      scope != null,
      'BranchPathScope.of() called outside of NavigationShell',
    );
    if (scope == null) return AppRoute.plannerScreen;
    final index = scope.navigationShell.currentIndex;
    return NavigationPage.values[index].route;
  }

  @override
  bool updateShouldNotify(BranchPathScope oldWidget) =>
      navigationShell != oldWidget.navigationShell;
}

enum NavigationPage {
  planner('Planner', Icons.calendar_month, AppRoute.plannerScreen),
  notes('Notebook', Icons.library_books, AppRoute.notebookScreen),
  courses('Classes', Icons.school, AppRoute.coursesScreen),
  resources('Resources', Icons.book, AppRoute.resourcesScreen),
  grades('Grades', Icons.bar_chart, AppRoute.gradesScreen);

  final String label;
  final IconData icon;
  final String route;

  const NavigationPage(this.label, this.icon, this.route);

  String get navKeyName => 'nav_tab_$name';

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
      case NavigationPage.notes:
        return const NotebookScreen();
      case NavigationPage.courses:
        return const CoursesScreen();
      case NavigationPage.resources:
        return const ResourcesScreen();
      case NavigationPage.grades:
        return const GradesScreen();
    }
  }
}

/// Shell widget for main tab navigation using go_router's StatefulShellRoute.
class NavigationShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationShell({super.key, required this.navigationShell});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  final InheritableProvidersNotifier _inheritableProvidersNotifier =
      InheritableProvidersNotifier();
  bool _isShowingGettingStarted = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();

    DioClient().cacheService.addInactivityResumeListener(_checkGettingStartedDialog);
    _checkDialogs();
  }

  @override
  void dispose() {
    DioClient().cacheService.removeInactivityResumeListener(
      _checkGettingStartedDialog,
    );
    _inheritableProvidersNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = NavigationPage.values[widget.navigationShell.currentIndex];

    final globalLocation = router.routerDelegate.currentConfiguration.uri.path;
    final isShellTab = NavigationPage.values.any(
      (p) => p.route == globalLocation,
    );
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
    if (isShellTab && isCurrentRoute) {
      _updateBrowserTitle(currentPage);
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut) {
          _isLoggingOut = true;
          // Pop any open dialogs before navigating to login
          Navigator.of(
            context,
            rootNavigator: true,
          ).popUntil((route) => route.isFirst);
          context.go(AppRoute.loginScreen);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useNavigationRail = !Responsive.isMobile(context);

          return BranchPathScope(
            navigationShell: widget.navigationShell,
            child: Scaffold(
            body: Row(
              children: [
                if (useNavigationRail)
                  NavigationRail(
                    minWidth: 56,
                    selectedIndex: currentPage.index,
                    onDestinationSelected: (index) =>
                        _onDestinationSelected(context, index),
                    labelType: NavigationRailLabelType.all,
                    leading: _buildLeading(context),
                    destinations: NavigationPage.values
                        .map(
                          (page) => NavigationRailDestination(
                            icon: Icon(
                              page.icon,
                              color: context.colorScheme.primary,
                            ),
                            label: Text(
                              page.label,
                              key: Key(page.navKeyName),
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
                          ListenableBuilder(
                            listenable: _inheritableProvidersNotifier,
                            builder: (context, _) => PageHeader(
                              title: currentPage.label,
                              icon: currentPage.icon,
                              screenType: ScreenType.page,
                              inheritableProviders:
                                  _inheritableProvidersNotifier.providers,
                            ),
                          ),
                          Expanded(
                            child: NavigationShellProvider(
                              label: currentPage.label,
                              child: widget.navigationShell,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: (useNavigationRail || !isShellTab)
                ? null
                : TooltipVisibility(
                    visible: false,
                    child: NavigationBar(
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
                                key: Key(page.navKeyName),
                                color: context.colorScheme.primary,
                              ),
                              label: page.label,
                            ),
                          )
                          .toList(),
                    ),
                  ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkGettingStartedDialog() async {
    if (_isShowingGettingStarted || !mounted || _isLoggingOut) return;

    try {
      final settings = await DioClient().getSettings();
      final showGettingStarted =
          settings?.showGettingStarted ??
          FallbackConstants.defaultShowGettingStarted;

      if (!mounted || !showGettingStarted) return;
      await _showGettingStartedDialogSafely();
    } catch (e) {
      _log.warning('Failed to check getting started dialog state: $e');
    }
  }

  Future<void> _checkDialogs() async {
    bool showGettingStarted = FallbackConstants.defaultShowGettingStarted;
    bool showWhatsNew = false;

    try {
      final settings = await DioClient().getSettings();
      showGettingStarted =
          settings?.showGettingStarted ??
          FallbackConstants.defaultShowGettingStarted;
      showWhatsNew = await WhatsNewService().shouldShowWhatsNew();
    } catch (e) {
      _log.warning('Failed to prepare startup dialogs: $e');
    }

    if (!mounted) return;

    // Defer dialog presentation to post-frame so the widget tree is stable
    // after the async settings fetch; showing a dialog mid-frame would crash
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Double-check we're still authenticated before showing dialogs
      if (!mounted || _isLoggingOut || !await DioClient().isAuthenticated()) {
        return;
      }

      // Skip startup dialogs whenever the user lands on anything other than
      // a bare shell tab — covers path-based dialog routes (e.g.
      // /planner/settings, /classes/25/details, /planner/homework/5/details)
      // and remaining query-param deep links on the shell screens.
      final uri = router.routerDelegate.currentConfiguration.uri;
      final onShellTab =
          NavigationPage.values.any((p) => p.route == uri.path);
      final params = uri.queryParameters;
      final hasDeepLinkParams = params.containsKey(DeepLinkParam.id);
      if (!onShellTab || hasDeepLinkParams) return;

      if (showGettingStarted) {
        // Re-check from the server: the value captured above may be stale if
        // the app was backgrounded between the initial fetch and this callback.
        await _checkGettingStartedDialog();
        if (!mounted || _isLoggingOut) return;
      }

      if (showWhatsNew) {
        if (!await DioClient().isAuthenticated() || !mounted) return;
        try {
          await showWhatsNewDialog(context);
        } catch (e) {
          _log.warning('Failed to show What\'s New dialog: $e');
        }
      }
    });
  }

  Future<void> _showGettingStartedDialogSafely() async {
    if (_isShowingGettingStarted || !mounted || _isLoggingOut) return;

    _isShowingGettingStarted = true;
    try {
      await showGettingStartedDialog(context);
    } catch (e) {
      _log.warning('Failed to show getting started dialog: $e');
    } finally {
      _isShowingGettingStarted = false;
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  /// Updates the browser title directly via DOM when navigating within the
  /// shell. This avoids using a Title widget which would compete with pushed
  /// routes like Settings/Notifications for control of the browser title.
  void _updateBrowserTitle(NavigationPage page) {
    title_helper.setTitle('${page.label} | ${AppConstants.appName}');
  }

  Widget _buildLeading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset(AppAssets.iconImagePath, width: 32, height: 32),
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context, double availableHeight) {
    final inheritableProviders = _inheritableProvidersNotifier.providers;
    final settingsButton =
        inheritableProviders != null && inheritableProviders.isNotEmpty
        ? MultiBlocProvider(
            providers: inheritableProviders,
            child: const SettingsButton(compact: false),
          )
        : const SettingsButton(compact: false);

    final bottomPadding = Responsive.isPhoneLandscape(context) ? 0.0 : 16.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
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
            const SizedBox(height: 4),
            const SizedBox(width: 32, child: Divider()),
            const SizedBox(height: 4),
            _buildAppStoreButton(
              context: context,
              icon: Icons.volunteer_activism,
              tooltip: 'Keep Helium Free',
              url: AppConstants.patreonUrl,
            ),
            if (!PageHeader.showSettingsInHeader(context))
              const SizedBox(width: 40, child: Divider()),
          ],
          if (!PageHeader.showSettingsInHeader(context)) ...[settingsButton],
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
      onPressed: () => UrlHelpers.launchWebUrl(url),
      icon: Icon(icon, color: context.colorScheme.primary),
      tooltip: tooltip,
    );
  }
}

