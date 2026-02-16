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
  final bool showCard;

  const ResponsiveCenterCard({
    super.key,
    required this.child,
    this.maxWidth = 450,
    this.showCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final content = isMobile
        ? Padding(padding: const EdgeInsets.all(16), child: child)
        : Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            margin: const EdgeInsets.symmetric(vertical: 25),
            child: showCard
                ? Card(
                    child:
                        Padding(padding: const EdgeInsets.all(16), child: child),
                  )
                : Padding(padding: const EdgeInsets.all(16), child: child),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}
