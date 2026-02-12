// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_routes.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/views/core/notification_screen.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/presentation/widgets/settings_button.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

enum ScreenType { page, subPage, entityPage }

class PageHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final ScreenType screenType;
  final bool isLoading;
  final Function? cancelAction;
  final Function? saveAction;
  final bool showLogout;
  final VoidCallback? onLogoutConfirmed;
  final List<BlocProvider>? inheritableProviders;

  const PageHeader({
    super.key,
    required this.title,
    this.icon,
    required this.screenType,
    this.isLoading = false,
    this.cancelAction,
    this.saveAction,
    this.showLogout = false,
    this.onLogoutConfirmed,
    this.inheritableProviders,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildContent(BuildContext ctx) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (screenType == ScreenType.subPage)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                if (Navigator.canPop(ctx)) {
                  ctx.pop();
                } else {
                  ctx.go(AppRoutes.plannerScreen);
                }
              },
              icon: Icon(
                Icons.keyboard_arrow_left,
                color: ctx.colorScheme.onSurface,
              ),
            )
          else if (screenType == ScreenType.entityPage)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                cancelAction?.call();
              },
              icon: Icon(Icons.cancel, color: ctx.colorScheme.primary),
            )
          else if (Responsive.isMobile(ctx) ||
              (!Responsive.isTouchDevice(ctx) &&
                  MediaQuery.of(ctx).size.height <
                      AppConstants.minHeightForTrailingNav))
            const SettingsButton()
          else
            const Icon(Icons.space_bar, color: Colors.transparent),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: ctx.colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Text(title, style: AppStyles.pageTitle(ctx)),
            ],
          ),

          Row(
            children: [
              if (screenType == ScreenType.page)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    showNotifications(ctx);
                  },
                  icon: Icon(
                    Icons.notifications,
                    color: ctx.colorScheme.primary,
                  ),
                )
              else if (screenType == ScreenType.entityPage)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: isLoading
                      ? null
                      : () {
                          saveAction?.call();
                        },
                  icon: isLoading
                      ? const LoadingIndicator(size: 20, expanded: false)
                      : Icon(
                          Icons.check_circle,
                          color: ctx.colorScheme.primary,
                        ),
                ),

              if (showLogout)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _showLogoutDialog(ctx);
                  },
                  icon: Icon(
                    Icons.logout_outlined,
                    color: ctx.colorScheme.error,
                  ),
                ),

              // Help keep things centered when no right button
              if (screenType == ScreenType.subPage && !showLogout)
                const Icon(Icons.space_bar, color: Colors.transparent),
            ],
          ),
        ],
      );
    }

    final wrappedContent =
        inheritableProviders != null && inheritableProviders!.isNotEmpty
        ? MultiBlocProvider(
            providers: inheritableProviders!,
            child: Builder(builder: (context) => buildContent(context)),
          )
        : buildContent(context);

    return Container(
      color: context.colorScheme.surface,
      padding: const EdgeInsets.only(top: 6, bottom: 2, left: 12, right: 12),
      child: wrappedContent,
    );
  }

  void _showLogoutDialog(BuildContext parentContext) {
    bool isSubmitting = false;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: context.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text('Logout', style: AppStyles.pageTitle(context)),
              ],
            ),
            content: SizedBox(
              width: Responsive.getDialogWidth(context),
              child: Text(
                'Are you sure you want to logout?',
                style: AppStyles.standardBodyText(context),
              ),
            ),
            actions: [
              SizedBox(
                width: Responsive.getDialogWidth(context),
                child: Row(
                  children: [
                    Expanded(
                      child: HeliumElevatedButton(
                        buttonText: 'Cancel',
                        backgroundColor: context.colorScheme.outline,
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HeliumElevatedButton(
                        buttonText: 'Logout',
                        backgroundColor: context.colorScheme.error,
                        isLoading: isSubmitting,
                        onPressed: () {
                          setState(() {
                            isSubmitting = true;
                          });

                          Navigator.of(dialogContext).pop();

                          onLogoutConfirmed?.call();
                          parentContext.read<AuthBloc>().add(LogoutEvent());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
