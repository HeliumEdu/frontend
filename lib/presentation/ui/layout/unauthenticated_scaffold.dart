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
/// sign up, account setup, etc.). These have no bottom navigation, so their
/// content flows edge-to-edge past the bottom safe area: [SafeArea] omits its
/// bottom inset and [ResponsiveCenterCard] reserves that inset as scroll
/// padding so the last item still rests above the home indicator. Pairing
/// those two settings here keeps them from drifting apart per screen.
class UnauthenticatedScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final double maxWidth;
  final bool showCard;

  const UnauthenticatedScaffold({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 450,
    this.showCard = true,
  });

  @override
  Widget build(BuildContext context) {
    return Title(
      title: title,
      color: context.colorScheme.primary,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: ResponsiveCenterCard(
            flowIntoBottomInset: true,
            maxWidth: maxWidth,
            showCard: showCard,
            child: child,
          ),
        ),
      ),
    );
  }
}
