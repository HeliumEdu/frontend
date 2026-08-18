// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/navigation/shell/navigation_shell.dart';

class SettingsButton extends StatelessWidget {
  static const String buttonKey = 'settings_button';

  final bool compact;

  const SettingsButton({super.key, this.compact = true});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key(buttonKey),
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      onPressed: () {
        if (!context.mounted) return;
        // Push relative to the current shell tab so settings overlays it
        // (e.g. /classes/settings) rather than always landing on /planner.
        final shellPath = BranchPathScope.of(context);
        context.push('$shellPath${AppRoute.settingScreen}');
      },
      icon: Icon(
        Icons.settings_outlined,
        color: context.colorScheme.primary,
      ),
      tooltip: 'Settings',
    );
  }
}
