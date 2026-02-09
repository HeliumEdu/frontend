// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class ResponsiveCenterCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool hasAppBar;

  const ResponsiveCenterCard({
    super.key,
    required this.child,
    this.maxWidth = 450,
    this.hasAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    // Use viewPadding for raw device insets (not consumed by Scaffold/AppBar)
    final topPadding = mediaQuery.viewPadding.top;
    final bottomPadding = mediaQuery.viewPadding.bottom;
    final appBarHeight = hasAppBar ? kToolbarHeight : 0;
    final availableHeight =
        screenHeight - topPadding - bottomPadding - appBarHeight;

    if (isMobile) {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: availableHeight),
        child: Center(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: availableHeight),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: const EdgeInsets.symmetric(vertical: 25),
          child: Card(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
  }
}
