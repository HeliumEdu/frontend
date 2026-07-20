// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/helium_elevated_button.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:heliumapp/utils/url_helpers.dart';
import 'package:heliumapp/utils/web_helpers_stub.dart'
    if (dart.library.js_interop) 'package:heliumapp/utils/web_helpers_web.dart';

/// Full-screen block shown when the running client is older than the backend's
/// minimum supported version. On mobile it links to the app store; on web the
/// latest build ships on reload, so it refreshes the page. Mirrors [ErrorCard]'s
/// layout so it renders through the same base-page path.
class UpdateRequiredCard extends StatelessWidget {
  final bool expanded;

  const UpdateRequiredCard({super.key, this.expanded = true});

  void _update() {
    if (kIsWeb) {
      reloadPage();
    } else {
      UrlHelpers.launchWebUrl(
        Responsive.isIOSPlatform()
            ? AppConstants.iosUrl
            : AppConstants.androidUrl,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.system_update,
            color: context.colorScheme.primary,
            size: Responsive.getIconSize(
              context,
              mobile: 60,
              tablet: 64,
              desktop: 68,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Time for an update! You'll need the latest version of "
            '${AppConstants.appName} to keep using it.',
            textAlign: TextAlign.center,
            style: AppStyles.headingText(context),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: HeliumElevatedButton(
              buttonText: kIsWeb ? 'Reload' : 'Update',
              icon: kIsWeb ? Icons.refresh : Icons.system_update,
              onPressed: _update,
            ),
          ),
        ],
      ),
    );

    return expanded ? Expanded(child: content) : content;
  }
}
