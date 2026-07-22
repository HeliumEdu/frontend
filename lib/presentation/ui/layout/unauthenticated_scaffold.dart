// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/layout/responsive_center_card.dart';

/// Scaffold for full-page screens outside the authenticated area (sign in,
/// sign up, account setup). With no bottom navigation, content flows
/// edge-to-edge: [SafeArea] drops its bottom inset and [ResponsiveCenterCard]
/// reserves it as scroll padding so the last item rests above the home
/// indicator.
class UnauthenticatedScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final double maxWidth;
  final bool showCard;

  /// Set false on screens whose fields use `AutofillGroup`: on iOS the bottom
  /// scroll inset dismisses the keyboard when a field gains focus.
  final bool flowIntoBottomInset;

  const UnauthenticatedScaffold({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 450,
    this.showCard = true,
    this.flowIntoBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Title(
      title: title,
      color: context.colorScheme.primary,
      child: Scaffold(
        body: SafeArea(
          bottom: !flowIntoBottomInset,
          child: ResponsiveCenterCard(
            flowIntoBottomInset: flowIntoBottomInset,
            maxWidth: maxWidth,
            showCard: showCard,
            child: child,
          ),
        ),
      ),
    );
  }
}
