// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/core/views/notification_screen.dart';
import 'package:heliumapp/presentation/ui/components/settings_button.dart';
import 'package:heliumapp/presentation/ui/feedback/loading_indicator.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

enum ScreenType { page, subPage, entityPage }

class PageHeader extends StatelessWidget {
  static const String saveButtonKey = 'page_header_save_button';

  final String title;
  final IconData? icon;
  final ScreenType screenType;
  final bool isLoading;
  final Function? cancelAction;
  final Function? saveAction;
  final List<BlocProvider>? inheritableProviders;

  const PageHeader({
    super.key,
    required this.title,
    this.icon,
    required this.screenType,
    this.isLoading = false,
    this.cancelAction,
    this.saveAction,
    this.inheritableProviders,
  });

  /// Returns true if the settings button should appear in the page header
  /// (mobile, or desktop with short height). When false, settings appears
  /// in the navigation rail instead.
  static bool showSettingsInHeader(BuildContext context) {
    return Responsive.isMobile(context) ||
        (!Responsive.isTouchDevice(context) &&
            MediaQuery.of(context).size.height <
                AppConstants.minHeightForTrailingNav);
  }

  Widget _buildContent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (screenType == ScreenType.entityPage ||
            screenType == ScreenType.subPage)
          IconButton(
            onPressed: () {
              cancelAction?.call();
            },
            icon: Icon(Icons.close, color: context.colorScheme.secondary),
          )
        else if (showSettingsInHeader(context))
          const SettingsButton()
        else
          const Icon(Icons.space_bar, color: Colors.transparent),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: context.colorScheme.primary),
              const SizedBox(width: 8),
            ],
            Text(title, style: AppStyles.pageTitle(context)),
          ],
        ),

        Row(
          children: [
            if (screenType == ScreenType.page)
              IconButton(
                onPressed: () {
                  showNotifications(context);
                },
                icon: Icon(
                  Icons.notifications,
                  color: context.colorScheme.primary,
                ),
              )
            else if (screenType == ScreenType.entityPage)
              IconButton(
                key: const Key(saveButtonKey),
                onPressed: isLoading
                    ? null
                    : () {
                        saveAction?.call();
                      },
                icon: isLoading
                    ? const LoadingIndicator(
                        size: 20,
                        expanded: false,
                        strokeWidth: 2.5,
                      )
                    : Icon(
                        Icons.check,
                        color: context.colorScheme.primary,
                      ),
              ),

            // Help keep things centered when no right button
            if (screenType == ScreenType.subPage)
              const Icon(Icons.space_bar, color: Colors.transparent),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wrappedContent =
        inheritableProviders != null && inheritableProviders!.isNotEmpty
        ? MultiBlocProvider(
            providers: inheritableProviders!,
            child: Builder(builder: (context) => _buildContent(context)),
          )
        : _buildContent(context);

    return Container(
      color: context.colorScheme.surface,
      padding: const EdgeInsets.only(top: 6, bottom: 2, left: 12, right: 12),
      child: wrappedContent,
    );
  }
}
