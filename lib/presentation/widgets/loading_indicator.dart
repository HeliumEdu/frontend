// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final bool expanded;
  final double? strokeWidth;

  const LoadingIndicator({
    super.key,
    this.size = 36,
    this.strokeWidth,
    this.color,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? context.colorScheme.primary,
        ),
      ),
    );

    if (expanded) {
      return Expanded(child: Center(child: indicator));
    }
    return indicator;
  }
}
