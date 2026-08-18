// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';

class ShadowContainer extends StatelessWidget {
  static const _containerBorderRadius = 16.0;
  static const _shadowBlurRadius = 12.0;
  static const _shadowOffset = Offset(0, 4);

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;

  const ShadowContainer({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color ?? context.colorScheme.surface,
        borderRadius: BorderRadius.circular(_containerBorderRadius),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: _shadowBlurRadius,
            offset: _shadowOffset,
          ),
        ],
      ),
      child: child,
    );
  }
}
