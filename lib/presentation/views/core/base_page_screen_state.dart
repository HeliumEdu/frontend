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
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:heliumapp/presentation/views/core/navigation_shell.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/page_header.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:meta/meta.dart';

abstract class BasePageScreenState<T extends StatefulWidget> extends State<T> {
  final DioClient dioClient = DioClient();

  bool get isAuthenticatedScreen => true;

  @mustBeOverridden
  String get screenTitle;

  ScreenType get screenType => ScreenType.page;

  Function get cancelAction =>
      () => {context.pop()};

  Function? get saveAction => null;

  bool get showLogout => false;

  NotificationArgs? get notificationNavArgs => null;

  VoidCallback? get actionButtonCallback => null;

  bool get showActionButton => false;

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
        listeners: buildListeners(context),
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
      screenType: screenType,
      isLoading: isSubmitting,
      cancelAction: cancelAction,
      saveAction: saveAction,
      showLogout: showLogout,
      notificationNavArgs: notificationNavArgs,
    );
  }

  Widget buildHeaderArea(BuildContext context) {
    return const SizedBox.shrink();
  }

  @mustBeOverridden
  Widget buildMainArea(BuildContext context);

  Widget buildReload(String errorMsg, VoidCallback retryCallback) {
    final errorColor = context.colorScheme.error;
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: Responsive.getIconSize(
                context,
                mobile: 60,
                tablet: 64,
                desktop: 68,
              ),
              color: errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              errorMsg,
              style: context.bodyText.copyWith(color: errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            HeliumElevatedButton(
              buttonText: 'Reload',
              onPressed: retryCallback,
            ),
          ],
        ),
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
    if (clearSnackBar) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? context.colorScheme.error
            : context.semanticColors.success,
        duration: Duration(seconds: seconds),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
