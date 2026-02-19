// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

final _log = Logger('presentation.views');

/// Provider to indicate that a screen is being displayed as a dialog.
class DialogModeProvider extends InheritedWidget {
  final double? width;
  final double? height;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  const DialogModeProvider({
    super.key,
    required super.child,
    this.width,
    this.height,
    this.scaffoldMessengerKey,
  });

  static DialogModeProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DialogModeProvider>();
  }

  static bool isDialogMode(BuildContext context) {
    return maybeOf(context) != null;
  }

  @override
  bool updateShouldNotify(DialogModeProvider oldWidget) {
    return width != oldWidget.width || height != oldWidget.height;
  }
}

/// Shows any widget using [BasePageScreenState] as a dialog with standard
/// dialog chrome.
void showScreenAsDialog(
  BuildContext context, {
  required Widget child,
  RouteArgs? extra,
  double width = 500,
  double? height,
  AlignmentGeometry alignment = Alignment.center,
  EdgeInsets insetPadding = const EdgeInsets.all(16),
  bool? barrierDismissible,
}) {
  // Create a key for this dialog's ScaffoldMessenger
  final dialogMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Capture the initial route to detect browser navigation
  final initialLocation = router.routerDelegate.currentConfiguration.uri
      .toString();

  showDialog(
    context: context,
    barrierDismissible:
        barrierDismissible ?? !Responsive.isTouchDevice(context),
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      final screenHeight = MediaQuery.of(dialogContext).size.height;
      final effectiveHeight = height ?? screenHeight - 32;

      Widget dialogContent = DialogModeProvider(
        width: width,
        height: effectiveHeight,
        scaffoldMessengerKey: dialogMessengerKey,
        child: child,
      );

      final providers = extra?.toProviders();
      if (providers != null && providers.isNotEmpty) {
        _log.info(
          'Using ${providers.length} inherited provider(s): '
          '${providers.map((p) => p.runtimeType).join(', ')}',
        );
        dialogContent = MultiBlocProvider(
          providers: providers,
          child: dialogContent,
        );
      }

      return _DialogRouteListener(
        initialLocation: initialLocation,
        child: Dialog(
          alignment: alignment,
          insetPadding: insetPadding,
          child: SizedBox(
            width: width,
            height: effectiveHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              // ScaffoldMessenger to ensure SnackBar is shown properly in dialogs
              child: ScaffoldMessenger(
                key: dialogMessengerKey,
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: dialogContent,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Listens to router changes and closes the dialog when browser navigation
/// (back/forward) causes a route change. Can be eliminated if we transition
/// to go_router's dialog navigation in the future.
class _DialogRouteListener extends StatefulWidget {
  final String initialLocation;
  final Widget child;

  const _DialogRouteListener({
    required this.initialLocation,
    required this.child,
  });

  @override
  State<_DialogRouteListener> createState() => _DialogRouteListenerState();
}

class _DialogRouteListenerState extends State<_DialogRouteListener> {
  VoidCallback? _routeListener;
  late final Uri _initialUri;

  @override
  void initState() {
    super.initState();
    _initialUri = Uri.parse(widget.initialLocation);
    _routeListener = _onRouteChanged;
    router.routerDelegate.addListener(_routeListener!);
  }

  @override
  void dispose() {
    if (_routeListener != null) {
      router.routerDelegate.removeListener(_routeListener!);
    }
    super.dispose();
  }

  void _onRouteChanged() {
    final currentUri = router.routerDelegate.currentConfiguration.uri;

    // Ignore query-only URL changes (for example: clearing ?dialog=... after
    // opening a desktop dialog). Close only when the route path changes.
    if (currentUri.path != _initialUri.path && mounted) {
      _log.info(
        'Browser navigation detected, closing dialog: '
        '${widget.initialLocation} --> ${currentUri.toString()}',
      );
      // Defer pop() to avoid calling it while Navigator is locked during
      // GoRouter's route change notification.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

abstract class BasePageScreenState<T extends StatefulWidget> extends State<T> {
  final DioClient dioClient = DioClient();

  bool get isAuthenticatedScreen => true;

  @mustBeOverridden
  String get screenTitle;

  IconData? get icon => null;

  ScreenType get screenType => ScreenType.page;

  Function get cancelAction =>
      () => Navigator.of(context).pop();

  Function? get saveAction => null;

  bool get showLogout => false;

  VoidCallback? get actionButtonCallback => null;

  bool get showActionButton => false;

  List<BlocProvider>? get inheritableProviders => null;

  // State
  UserSettingsModel? userSettings;
  bool settingsLoaded = false;
  bool isLoading = false;
  bool isSubmitting = false;

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    if (isAuthenticatedScreen) {
      setState(() {
        isLoading = true;
      });

      loadSettings();
    }
  }

  @override
  @protected
  @mustCallSuper
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Register inheritable providers with NavigationShell if we're inside one
    final notifier = InheritableProvidersScope.of(context);
    if (notifier != null) {
      // Use post-frame callback to avoid updating during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        notifier.setProviders(inheritableProviders);
      });
    }
  }

  @mustCallSuper
  Future<UserSettingsModel?> loadSettings() {
    return dioClient
        .getSettings()
        .then((settings) {
          if (!mounted) return settings;
          setState(() {
            userSettings = settings;
            if (userSettings != null) {
              settingsLoaded = true;
            }
          });
          return settings;
        })
        .catchError((error) {
          throw error;
        });
  }

  @override
  Widget build(BuildContext context) {
    final listeners = buildListeners(context);
    if (listeners.isNotEmpty) {
      return MultiBlocListener(
        listeners: listeners,
        child: buildScaffold(context),
      );
    } else {
      return buildScaffold(context);
    }
  }

  List<BlocListener<dynamic, dynamic>> buildListeners(BuildContext context) {
    return [];
  }

  Widget buildScaffold(BuildContext context) {
    // Check if we're inside a NavigationShell (which has its own Scaffold)
    final bool hasNavigationShell = NavigationShellProvider.of(context);

    // Check if we're being displayed as a dialog
    final bool isDialogMode = DialogModeProvider.isDialogMode(context);

    // Build the main content
    final Widget content = Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 0),
      child: Column(
        children: [
          // Show loading until settings are loaded for authenticated screens
          if (isLoading || (isAuthenticatedScreen && !settingsLoaded))
            const LoadingIndicator()
          else ...[
            buildHeaderArea(context),

            buildMainArea(context),
          ],
        ],
      ),
    );

    // When displayed as a dialog, wrap as such
    if (isDialogMode) {
      return Material(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            buildDialogHeader(context),
            Expanded(child: content),
          ],
        ),
      );
    }

    // When inside NavigationScaffold, don't wrap in another Scaffold
    // The NavigationScaffold already provides the Scaffold with navigation
    if (hasNavigationShell) {
      return Title(
        title: '$screenTitle | ${AppConstants.appName}',
        color: context.colorScheme.primary,
        child: Stack(
          children: [
            content,
            if (showActionButton && actionButtonCallback != null)
              Positioned(
                right: 16,
                bottom: 16,
                child: buildFloatingActionButton(),
              ),
          ],
        ),
      );
    }

    // When NOT inside NavigationScaffold (sub-pages), use full Scaffold
    return Title(
      title: '$screenTitle | ${AppConstants.appName}',
      color: context.colorScheme.primary,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildPageHeader(),
              Expanded(child: content),
            ],
          ),
        ),
        floatingActionButton: showActionButton && actionButtonCallback != null
            ? buildFloatingActionButton()
            : null,
      ),
    );
  }

  Widget buildPageHeader() {
    return PageHeader(
      title: screenTitle,
      icon: icon,
      screenType: screenType,
      isLoading: isSubmitting,
      cancelAction: cancelAction,
      saveAction: saveAction,
      showLogout: showLogout,
      inheritableProviders: inheritableProviders,
    );
  }

  Widget buildHeaderArea(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget buildMainArea(BuildContext context);

  Widget buildDialogHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: context.colorScheme.primary),
            const SizedBox(width: 12),
          ],
          Text(screenTitle, style: AppStyles.pageTitle(context)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: context.colorScheme.secondary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (screenType == ScreenType.entityPage) ...[
            const SizedBox(width: 8),
            if (isSubmitting)
              const LoadingIndicator(
                size: 20,
                strokeWidth: 2.5,
                expanded: false,
              )
            else
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => saveAction?.call(),
                color: context.colorScheme.primary,
              ),
          ],
        ],
      ),
    );
  }

  Widget buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.small(
        shape: const CircleBorder(),
        onPressed: actionButtonCallback!,
        backgroundColor: context.colorScheme.primary,
        elevation: 0,
        child: Icon(
          Icons.add,
          color: context.colorScheme.onPrimary,
          size: Responsive.getIconSize(
            context,
            mobile: 20,
            tablet: 22,
            desktop: 24,
          ),
        ),
      ),
    );
  }

  void showSnackBar(
    BuildContext context,
    String message, {
    int seconds = 2,
    bool isError = false,
    bool clearSnackBar = true,
    SnackBarAction? action,
    bool useRootMessenger = false,
  }) {
    SnackBarHelper.show(
      context,
      message,
      seconds: seconds,
      isError: isError,
      clearSnackBar: clearSnackBar,
      action: action,
      useRootMessenger: useRootMessenger,
    );
  }
}
