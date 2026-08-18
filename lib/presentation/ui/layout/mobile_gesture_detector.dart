// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class MobileGestureDetector extends StatelessWidget {
  final GestureTapCallback onTap;
  final Widget child;

  const MobileGestureDetector({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return MouseRegion(
      cursor: isMobile ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: isMobile
            ? () {
                Feedback.forTap(context);
                onTap();
              }
            : null,
        child: child,
      ),
    );
  }
}
