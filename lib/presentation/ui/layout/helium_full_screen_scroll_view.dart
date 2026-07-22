// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

/// A [SingleChildScrollView] that, inside a full-screen dialog, pads the
/// bottom of its content by the device's bottom safe-area inset. The dialog
/// renders with `SafeArea(bottom: false)` so content flows into the rounded
/// corner while scrolling; this padding lets the last item still come to rest
/// above the home indicator. A plain scroll view otherwise (no padding outside
/// full-screen mode or when there's no bottom inset).
///
/// The inset pads the content rather than the scroll viewport: viewport
/// padding around an `AutofillGroup` dismisses the keyboard on focus on iOS.
///
/// For scroll views that take a `padding:` param rather than a child to wrap
/// (e.g. `ListView.builder`), use [insetOf] instead.
class HeliumFullScreenScrollView extends StatelessWidget {
  final Widget child;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  const HeliumFullScreenScrollView({
    super.key,
    required this.child,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.controller,
    this.physics,
  });

  /// The bottom scroll-extent inset for the current context. Zero outside
  /// full-screen dialogs or when there's no bottom inset.
  static double insetOf(BuildContext context) {
    if (!DialogModeProvider.isFullScreenMode(context)) return 0;
    return Responsive.bottomSafeAreaInset(context);
  }

  @override
  Widget build(BuildContext context) {
    final inset = insetOf(context);
    return SingleChildScrollView(
      keyboardDismissBehavior: keyboardDismissBehavior,
      controller: controller,
      physics: physics,
      child: inset == 0
          ? child
          : Padding(
              padding: EdgeInsets.only(bottom: inset),
              child: child,
            ),
    );
  }
}
