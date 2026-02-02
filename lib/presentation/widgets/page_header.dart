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
import 'package:heliumapp/config/route_args.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_bloc.dart';
import 'package:heliumapp/presentation/bloc/auth/auth_event.dart';
import 'package:heliumapp/presentation/widgets/helium_elevated_button.dart';
import 'package:heliumapp/presentation/widgets/loading_indicator.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

enum ScreenType { page, subPage, entityPage }

class PageHeader extends StatelessWidget {
  final String title;
  final ScreenType screenType;
  final bool isLoading;
  final Function? cancelAction;
  final Function? saveAction;
  final NotificationArgs? notificationNavArgs;

  final bool showLogout;

  const PageHeader({
    super.key,
    required this.title,
    required this.screenType,
    this.isLoading = false,
    this.cancelAction,
    this.saveAction,
    this.showLogout = false,
    this.notificationNavArgs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colorScheme.surface,
      padding: const EdgeInsets.only(top: 6, bottom: 2, left: 12, right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (screenType == ScreenType.subPage)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                if (Navigator.canPop(context)) {
                  context.pop();
                } else {
                  context.go(AppRoutes.plannerScreen);
                }
              },
              icon: Icon(
                Icons.keyboard_arrow_left,
                color: context.colorScheme.onSurface,
              ),
            )
          else if (screenType == ScreenType.entityPage)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                cancelAction?.call();
              },
              icon: Icon(Icons.cancel, color: context.colorScheme.primary),
            )
          else
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                if (context.mounted) {
                  context.go(AppRoutes.settingScreen);
                }
              },
              icon: Icon(
                Icons.settings_outlined,
                color: context.colorScheme.primary,
              ),
            ),

          Text(title, style: context.pageTitle),

          // TODO: should add the Helium logo up here
          if (screenType == ScreenType.page)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                context.push(
                  AppRoutes.notificationsScreen,
                  extra: notificationNavArgs,
                );
              },
              icon: Icon(
                Icons.notifications,
                color: context.colorScheme.primary,
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
                  ? const LoadingIndicator(small: true)
                  : Icon(
                      Icons.check_circle,
                      color: context.colorScheme.primary,
                    ),
            ),

          if (showLogout)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                _showLogoutDialog(context);
              },
              icon: Icon(
                Icons.logout_outlined,
                color: context.colorScheme.error,
              ),
            ),

          // Help keep things centered when no right button
          if (screenType == ScreenType.subPage && !showLogout)
            const Icon(Icons.space_bar, color: Colors.transparent),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext parentContext) {
    bool isSubmitting = false;

    // TODO: refactor to a separate class
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
                Text('Logout', style: context.dialogTitle),
              ],
            ),
            content: SizedBox(
              width: Responsive.getDialogWidth(context),
              child: Text(
                'Are you sure you want to logout?',
                style: context.dialogText,
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
                        onPressed: () => dialogContext.pop(),
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
                          context.read<AuthBloc>().add(LogoutEvent());
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
