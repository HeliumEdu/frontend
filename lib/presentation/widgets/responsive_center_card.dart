// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

// FIXME: adjust this to center vertically too (or scroll if not enough room, but parent widget might take care of that)
class ResponsiveCenterCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenterCard({
    super.key,
    required this.child,
    this.maxWidth = 450,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Padding(padding: const EdgeInsets.all(16), child: child);
    }

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 25),
        child: Card(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}
