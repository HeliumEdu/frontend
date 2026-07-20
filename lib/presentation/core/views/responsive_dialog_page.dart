// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// Returns a [Page] that renders [child] as a full-screen [MaterialPage] on
/// mobile and an overlay [Dialog] on desktop. Used by GoRoute pageBuilders for
/// any dialog-style screen.
///
/// The dialog vs. full-screen choice is made at pageBuilder time — a window
/// resize while a dialog is open does not switch modes.
Page<T> responsiveDialogPage<T>(
  BuildContext context,
  GoRouterState state, {
  required Widget child,
  double width = 500,
  double? height,
  AlignmentGeometry alignment = Alignment.center,
  EdgeInsets insetPadding = const EdgeInsets.all(16),
  bool? barrierDismissible,
  LocalKey? key,
}) {
  final pageKey = key ?? state.pageKey;
  if (Responsive.useCompactLayout(context)) {
    return MaterialPage<T>(
      key: pageKey,
      child: _FullScreenPageContent(child: child),
    );
  }
  return _DialogPage<T>(
    key: pageKey,
    child: child,
    width: width,
    height: height,
    alignment: alignment,
    insetPadding: insetPadding,
    barrierDismissible:
        barrierDismissible ?? !Responsive.isTouchDevice(context),
  );
}

class _DialogPage<T> extends Page<T> {
  final Widget child;
  final double width;
  final double? height;
  final AlignmentGeometry alignment;
  final EdgeInsets insetPadding;
  final bool barrierDismissible;

  const _DialogPage({
    super.key,
    required this.child,
    required this.width,
    this.height,
    required this.alignment,
    required this.insetPadding,
    required this.barrierDismissible,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return DialogRoute<T>(
      context: context,
      settings: this,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black54,
      // _DialogPageContent reads its data from the route's settings on every
      // build, so URL-driven Page swaps under a shared page key reach the
      // dialog content via the modal scope's `changedInternalState` rebuild.
      builder: (dialogContext) => const _DialogPageContent(),
    );
  }
}

class _FullScreenPageContent extends StatefulWidget {
  final Widget child;

  const _FullScreenPageContent({required this.child});

  @override
  State<_FullScreenPageContent> createState() => _FullScreenPageContentState();
}

class _FullScreenPageContentState extends State<_FullScreenPageContent> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      // Opaque so the full-screen overlay fully covers the shell (incl. its
      // bottom nav bar) beneath it on the root navigator; a transparent scaffold
      // let the bar bleed through during the slide-in.
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: DialogModeProvider(
          isFullScreen: true,
          scaffoldMessengerKey: _scaffoldMessengerKey,
          child: widget.child,
        ),
      ),
    );
  }
}

class _DialogPageContent extends StatefulWidget {
  const _DialogPageContent();

  @override
  State<_DialogPageContent> createState() => _DialogPageContentState();
}

class _DialogPageContentState extends State<_DialogPageContent> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final page = ModalRoute.of(context)!.settings as _DialogPage;
    final mediaQuery = MediaQuery.of(context);
    final effectiveHeight = page.height ?? mediaQuery.size.height - 32;
    return Dialog(
      alignment: page.alignment,
      insetPadding: page.insetPadding,
      child: SizedBox(
        width: page.width,
        height: effectiveHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ScaffoldMessenger(
            key: _scaffoldMessengerKey,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: DialogModeProvider(
                width: page.width,
                height: effectiveHeight,
                isFullScreen: false,
                scaffoldMessengerKey: _scaffoldMessengerKey,
                child: page.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
