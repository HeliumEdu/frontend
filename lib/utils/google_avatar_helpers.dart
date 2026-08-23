import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _log = Logger('utils');

class GoogleAvatar {
  static const Duration _precacheTimeout = Duration(milliseconds: 2500);

  /// Googleusercontent sizes by the `=sNN` suffix; 3x the sheet's 56pt circle.
  static const int _pixelSize = 192;

  static final RegExp _sizeSuffix = RegExp(r'=s\d+');

  /// The [photoUrl] sized for the confirm sheet's avatar.
  static String? sizedUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }

    return photoUrl.replaceFirst(_sizeSuffix, '=s$_pixelSize');
  }

  /// Warms the image cache so the confirm sheet's avatar renders on open.
  static Future<void> precache(BuildContext context, String? photoUrl) async {
    final url = sizedUrl(photoUrl);
    if (url == null) {
      return;
    }

    try {
      await precacheImage(
        NetworkImage(url),
        context,
        onError: (e, s) => _log.info('Google avatar precache failed', e, s),
      ).timeout(_precacheTimeout);
    } catch (e) {
      _log.info('Google avatar precache did not complete: ${e.runtimeType}');
    }
  }
}
