// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/presentation/views/core/navigation_shell.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:nested/nested.dart';

final _log = Logger('presentation.views');

/// Provider to indicate that a screen is being displayed as a dialog.
class DialogModeProvider extends InheritedWidget {
  final double? width;
  final double? height;

  const DialogModeProvider({
    super.key,
    required super.child,
    this.width,
    this.height,
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
///
/// Pass [providers] to share existing Blocs with the dialog, ensuring state
/// changes in the dialog are reflected in the parent screen:
/// ```dart
/// showScreenAsDialog(
///   context,
///   child: MyScreen(),
///   providers: [
///     BlocProvider<MyBloc>.value(value: existingBloc),
///   ],
/// );
/// ```
void showScreenAsDialog(
  BuildContext context, {
  required Widget child,
  List<SingleChildWidget>? providers,
  double width = 500,
  double? height,
  AlignmentGeometry alignment = Alignment.center,
  EdgeInsets insetPadding = const EdgeInsets.all(16),
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      final screenHeight = MediaQuery.of(dialogContext).size.height;
      final effectiveHeight = height ?? screenHeight - 32;

      Widget dialogContent = DialogModeProvider(
        width: width,
        height: effectiveHeight,
        child: SizedBox(width: width, height: effectiveHeight, child: child),
      );

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

      return Dialog(
        alignment: alignment,
        insetPadding: insetPadding,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: dialogContent,
        ),
      );
    },
  );
}

abstract class BasePageScreenState<T extends StatefulWidget> extends State<T> {
  final DioClient dioClient = DioClient();

  bool get isAuthenticatedScreen => true;

  @mustBeOverridden
  String get screenTitle;

  IconData? get icon => null;

  ScreenType get screenType => ScreenType.page;

  Function get cancelAction =>
      () => {context.pop()};

  Function? get saveAction => null;

  bool get showLogout => false;

  VoidCallback? get actionButtonCallback => null;

  bool get showActionButton => false;

  List<SingleChildWidget>? get inheritableProviders => null;

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
        if (mounted) {
          notifier.setProviders(inheritableProviders);
        }
      });
    }
  }

  @mustCallSuper
  Future<UserSettingsModel?> loadSettings() {
    return dioClient
        .getSettings()
        .then((settings) {
          if (mounted) {
            setState(() {
              userSettings = settings;
              if (userSettings != null) {
                settingsLoaded = true;
              }
            });
          }

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
      return Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
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

  @mustBeOverridden
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
          if (saveAction != null) ...[
            if (isSubmitting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => saveAction!(),
                tooltip: 'Save',
                color: context.colorScheme.primary,
              ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
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
  }) {
    if (!context.mounted) return;
    // TODO: Show snackbar in parent context when in dialog mode
    if (DialogModeProvider.isDialogMode(context)) return;
    if (clearSnackBar) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(
          message,
          style: AppStyles.standardBodyText(
            context,
          ).copyWith(color: context.colorScheme.onPrimary),
        ),
        backgroundColor: isError
            ? context.colorScheme.error
            : context.semanticColors.success,
        duration: Duration(seconds: seconds),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
