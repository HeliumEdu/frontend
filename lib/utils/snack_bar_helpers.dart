// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_style.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

enum SnackType {
  success,
  info,
  error;

  Color backgroundColor(BuildContext context) {
    return switch (this) {
      SnackType.success => context.semanticColors.success,
      SnackType.info => context.semanticColors.info,
      SnackType.error => context.colorScheme.error,
    };
  }

  Color foregroundColor(BuildContext context) {
    return switch (this) {
      SnackType.success => context.semanticColors.onSuccess,
      SnackType.info => context.semanticColors.onInfo,
      SnackType.error => context.colorScheme.onError,
    };
  }
}

class SnackBarHelper {
  static void show(BuildContext context,
      String message, {
        int seconds = 2,
        SnackType type = SnackType.success,
        bool clearSnackBar = true,
        SnackBarAction? action,
        bool useRootMessenger = false,
      }) {
    final messenger = _resolveMessenger(
      context,
      useRootMessenger: useRootMessenger,
    );
    if (messenger == null) return;

    if (clearSnackBar) {
      messenger.clearSnackBars();
    }

    final controller = messenger.showSnackBar(
      SnackBar(
        content: SelectableText(
          message,
          style: AppStyles.standardBodyText(
            context,
          ).copyWith(color: type.foregroundColor(context)),
        ),
        backgroundColor: type.backgroundColor(context),
        duration: Duration(seconds: seconds),
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );

    // SnackBar won't automatically close with an action, so set a callback.
    if (action != null) {
      Future.delayed(Duration(seconds: seconds), () {
        try {
          controller.close();
        } catch (_) {
          // SnackBar may have already been dismissed.
        }
      });
    }
  }

  static ScaffoldMessengerState? _resolveMessenger(BuildContext context, {
    required bool useRootMessenger,
  }) {
    if (!useRootMessenger) {
      final local = ScaffoldMessenger.maybeOf(context);
      if (local != null) return local;
    }
    return rootScaffoldMessengerKey.currentState;
  }
}
