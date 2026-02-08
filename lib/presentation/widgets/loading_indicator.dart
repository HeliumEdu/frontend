// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  final bool small;
  final Color? color;
  final bool expanded;

  const LoadingIndicator({
    super.key,
    this.small = false,
    this.color,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Cleanup: not sure the small version is necessary
    if (small) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? context.colorScheme.onPrimary,
          ),
        ),
      );
    }

    const content = Center(
      child: CircularProgressIndicator(),
    );

    return expanded ? const Expanded(child: content) : content;
  }
}
