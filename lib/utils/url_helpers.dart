// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:url_launcher/url_launcher.dart';

class UrlHelpers {
  UrlHelpers._();

  /// Launches [url] only if its scheme is http or https.
  ///
  /// Silently no-ops for any other scheme (e.g. javascript:, file://) to
  /// prevent user-supplied or API-supplied URLs from triggering unintended
  /// platform behaviour.
  static Future<void> launchWebUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    await launchUrl(uri);
  }
}
