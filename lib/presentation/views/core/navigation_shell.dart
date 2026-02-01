// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/views/calendar/calendar_screen.dart';
import 'package:heliumapp/presentation/views/courses/courses_screen.dart';
import 'package:heliumapp/presentation/views/grades/grades_screen.dart';
import 'package:heliumapp/presentation/views/materials/materials_screen.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

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
  calendar('Calendar', Icons.calendar_month, AppRoutes.calendarScreen),
  courses('Classes', Icons.school, AppRoutes.coursesScreen),
  materials('Materials', Icons.book, AppRoutes.materialsScreen),
  grades('Grades', Icons.bar_chart, AppRoutes.gradesScreen);

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
      case NavigationPage.calendar:
        return CalendarScreen();
      case NavigationPage.courses:
        return CoursesScreen();
      case NavigationPage.materials:
        return MaterialsScreen();
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

  @override
  void initState() {
    super.initState();
    // Pre-build all screens to cache them
    for (final page in NavigationPage.values) {
      _screenCache[page] = page.buildScreen();
    }
  }

  NavigationPage _getCurrentPage(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return NavigationPage.fromRoute(location) ?? NavigationPage.calendar;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Responsive.getDeviceTypeFromSize(
          constraints.biggest,
        );
        final useNavigationRail = deviceType == DeviceType.desktop;

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
                          label: Text(page.label),
                        ),
                      )
                      .toList(),
                ),
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Static PageHeader that doesn't animate
                      PageHeader(
                        title: currentPage.label,
                        screenType: ScreenType.page,
                      ),
                      // Only the content area animates
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
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
            ],
          ),
          bottomNavigationBar: useNavigationRail
              ? null
              : NavigationBar(
                  height: 70,
                  selectedIndex: currentPage.index,
                  onDestinationSelected: (index) =>
                      _onDestinationSelected(context, index),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
