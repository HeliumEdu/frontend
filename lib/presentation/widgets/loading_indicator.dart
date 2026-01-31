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

  const LoadingIndicator({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    // TODO: not sure the small version is necessary
    if (small) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            context.colorScheme.onPrimary,
          ),
        ),
      );
    }

    return const Expanded(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
