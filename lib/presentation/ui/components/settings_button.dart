// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/features/settings/views/settings_screen.dart';

class SettingsButton extends StatelessWidget {
  final bool compact;

  const SettingsButton({super.key, this.compact = true});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      onPressed: () {
        if (!context.mounted) return;

        showSettings(context);
      },
      icon: Icon(
        Icons.settings_outlined,
        color: context.colorScheme.primary,
      ),
      tooltip: 'Settings',
    );
  }
}
