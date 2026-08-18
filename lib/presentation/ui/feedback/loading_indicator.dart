// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

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
