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
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell_title_stub.dart'
    if (dart.library.js_interop) 'package:heliumapp/presentation/navigation/shell/navigation_shell_title_web.dart'
    as title_helper;
import 'package:heliumapp/presentation/ui/feedback/error_card.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/snack_bar_helpers.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

export 'package:heliumapp/utils/snack_bar_helpers.dart' show SnackType;

final _log = Logger('presentation.views');

/// Provider to indicate that a screen is being displayed as a dialog.
class DialogModeProvider extends InheritedWidget {
  final double? width;
  final double? height;
  final bool isFullScreen;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  const DialogModeProvider({
    super.key,
    required super.child,
    this.width,
    this.height,
    this.isFullScreen = false,
    this.scaffoldMessengerKey,
  });

  static DialogModeProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DialogModeProvider>();
  }

  static bool isDialogMode(BuildContext context) {
    return maybeOf(context) != null;
  }

  static bool isFullScreenMode(BuildContext context) {
    return maybeOf(context)?.isFullScreen ?? false;
  }

  @override
  bool updateShouldNotify(DialogModeProvider oldWidget) {
    return width != oldWidget.width ||
        height != oldWidget.height ||
        isFullScreen != oldWidget.isFullScreen;
  }
}

/// Shows any widget using [BasePageScreenState] as a dialog.
///
/// Returns a [Future] that completes when dismissed — chain
/// `.then((_) => clearRouteQueryParams(basePath))` to clear URL params.
Future<void> showScreenAsDialog(
  BuildContext context, {
  required Widget child,
  double width = 500,
  double? height,
  AlignmentGeometry alignment = Alignment.center,
  EdgeInsets insetPadding = const EdgeInsets.all(16),
  bool? barrierDismissible,
}) {
  final dialogMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final initialLocation = router.routerDelegate.currentConfiguration.uri
      .toString();

  final isFullScreen = insetPadding == EdgeInsets.zero;

  return showDialog(
    context: context,
    useSafeArea: !isFullScreen,
    barrierDismissible:
        barrierDismissible ?? !Responsive.isTouchDevice(context),
    barrierColor: isFullScreen ? Colors.transparent : Colors.black54,
    builder: (dialogContext) {
      final mediaQuery = MediaQuery.of(dialogContext);
      final screenWidth = mediaQuery.size.width;
      final screenHeight = mediaQuery.size.height;
      final keyboardHeight = mediaQuery.viewInsets.bottom;
      // For full-screen dialogs, subtract keyboard height so content remains visible
      final effectiveHeight = height ??
          (isFullScreen ? screenHeight - keyboardHeight : screenHeight - 32);
      // Use screen width when infinity is passed (full-screen mobile dialogs)
      final effectiveWidth = width.isFinite ? width : screenWidth;

      final Widget dialogContent = DialogModeProvider(
        width: effectiveWidth,
        height: effectiveHeight,
        isFullScreen: isFullScreen,
        scaffoldMessengerKey: dialogMessengerKey,
        child: child,
      );

      return _DialogRouteListener(
        initialLocation: initialLocation,
        child: Dialog(
          alignment: alignment,
          insetPadding: insetPadding,
          backgroundColor: isFullScreen
              ? Theme.of(dialogContext).colorScheme.surface
              : null,
          elevation: isFullScreen ? 0 : null,
          shape: isFullScreen
              ? const RoundedRectangleBorder(borderRadius: BorderRadius.zero)
              : null,
          child: SizedBox(
            width: effectiveWidth,
            height: effectiveHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isFullScreen ? 0 : 16),
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
  late Uri _initialUri;

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

    // If params were added after dialog opened, update our reference.
    // This handles the case where the dialog is shown before the URL is
    // updated with entity params (e.g., showScreenAsDialog called, then
    // router.replace adds ?id=123).
    if (currentUri.path == _initialUri.path &&
        _initialUri.queryParameters.isEmpty &&
        currentUri.queryParameters.isNotEmpty) {
      _initialUri = currentUri;
      return;
    }

    // Close on path change (e.g., navigated to different tab)
    if (currentUri.path != _initialUri.path && mounted) {
      _log.info(
        'Browser navigation detected, closing dialog: '
        '${widget.initialLocation} --> ${currentUri.toString()}',
      );
      _deferredPop();
      return;
    }

    // Close when query params are cleared (e.g., browser back from ?id=123 to /)
    // but not on param updates within the dialog (e.g., id=new → id=123)
    if (_initialUri.queryParameters.isNotEmpty &&
        currentUri.queryParameters.isEmpty &&
        mounted) {
      _log.info(
        'Browser back detected (params cleared), closing dialog: '
        '${widget.initialLocation} --> ${currentUri.toString()}',
      );
      _deferredPop();
    }
  }

  void _deferredPop() {
    // Defer pop() to avoid calling it while Navigator is locked during
    // GoRouter's route change notification.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
    });
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

  Function get cancelAction => () {
    if (!mounted) return;
    Navigator.of(context).pop();
  };

  Function? get saveAction => null;

  VoidCallback? get actionButtonCallback => null;

  bool get showActionButton => false;

  List<BlocProvider>? get inheritableProviders => null;

  EdgeInsets get scaffoldInsets => const EdgeInsets.only(
    left: 12,
    right: 12,
    top: 8,
    bottom: 0,
  );

  UserSettingsModel? userSettings;
  bool settingsLoaded = false;
  bool settingsError = false;
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

    final notifier = InheritableProvidersScope.of(context);
    if (notifier != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        notifier.setProviders(inheritableProviders);
      });
    }

    // Register dependency so build() fires when isCurrent changes (push/pop)
    if (!NavigationShellProvider.of(context)) {
      ModalRoute.of(context);
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
              settingsError = false;
            } else {
              settingsError = true;
            }
          });
          return settings;
        })
        .catchError((error) {
          if (mounted) {
            setState(() {
              settingsError = true;
            });
          }
          throw error;
        });
  }

  @override
  Widget build(BuildContext context) {
    // postFrameCallback ensures the foreground route's title wins
    if (!NavigationShellProvider.of(context) && screenTitle.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          title_helper.setTitle('$screenTitle | ${AppConstants.appName}');
        }
      });
    }

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
    final bool hasNavigationShell = NavigationShellProvider.of(context);
    final bool isDialogMode = DialogModeProvider.isDialogMode(context);

    final Widget content = Padding(
      padding: scaffoldInsets,
      child: Column(
        children: [
          if (settingsError)
            ErrorCard(
              message: 'An unknown error occurred',
              source: 'settings',
              onReload: () {
                setState(() {
                  settingsError = false;
                  isLoading = true;
                });
                loadSettings().whenComplete(() {
                  if (mounted) {
                    setState(() {
                      isLoading = false;
                    });
                  }
                });
              },
            )
          else if (isLoading || (isAuthenticatedScreen && !settingsLoaded))
            const LoadingIndicator()
          else ...[
            buildHeaderArea(context),

            buildMainArea(context),
          ],
        ],
      ),
    );

    if (isDialogMode) {
      final isFullScreen = DialogModeProvider.isFullScreenMode(context);
      return Material(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(isFullScreen ? 0 : 16),
        child: SafeArea(
          top: isFullScreen,
          bottom: isFullScreen,
          left: false,
          right: false,
          child: Column(
            children: [
              buildPageHeader(),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }

    if (hasNavigationShell) {
      return Stack(
        children: [
          content,
          if (showActionButton && actionButtonCallback != null)
            Positioned(
              right: 16,
              bottom: 16,
              child: buildFloatingActionButton(),
            ),
        ],
      );
    }

    return Scaffold(
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
      inheritableProviders: inheritableProviders,
    );
  }

  Widget buildHeaderArea(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget buildMainArea(BuildContext context);

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
        heroTag: null,
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
    SnackType type = SnackType.success,
    bool clearSnackBar = true,
    SnackBarAction? action,
    bool useRootMessenger = false,
  }) {
    SnackBarHelper.show(
      context,
      message,
      seconds: seconds,
      type: type,
      clearSnackBar: clearSnackBar,
      action: action,
      useRootMessenger: useRootMessenger,
    );
  }
}
