// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/analytics_service.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class ErrorCard extends StatefulWidget {
  final String message;
  final String source;
  final Function onReload;
  final bool expanded;

  const ErrorCard({
    super.key,
    required this.message,
    required this.source,
    required this.onReload,
    this.expanded = true,
  });

  @override
  State<ErrorCard> createState() => _ErrorCardState();
}

class _ErrorCardState extends State<ErrorCard> {
  @override
  void initState() {
    super.initState();
    AnalyticsService().logEvent(
      name: 'error_displayed',
      parameters: {
        'source': widget.source,
        'message': widget.message,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: context.colorScheme.error.withValues(alpha: 0.9),
            size: Responsive.getIconSize(
              context,
              mobile: 60,
              tablet: 64,
              desktop: 68,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.message,
            style: AppStyles.headingText(context).copyWith(
              color: context.colorScheme.error.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          HeliumElevatedButton(
            buttonText: 'Reload',
            onPressed: widget.onReload,
          ),
        ],
      ),
    );

    return widget.expanded ? Expanded(child: content) : content;
  }
}
