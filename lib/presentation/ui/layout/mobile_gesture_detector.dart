// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

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
    return MouseRegion(
      cursor: Responsive.isMobile(context)
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: GestureDetector(
        onTap: Responsive.isMobile(context) ? onTap : null,
        child: child,
      ),
    );
  }
}
