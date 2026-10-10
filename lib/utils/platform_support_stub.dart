import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('utils');

const _channel = MethodChannel('com.heliumedu.heliumapp/native');

/// An iPad build running on an Apple silicon Mac reports as iOS but runs on
/// macOS and is driven by a pointer. Read synchronously, so it resolves out of
/// band via [initialize].
bool _isIOSAppOnMac = false;

Future<void> initialize() async {
  await _detectIOSAppOnMac();
}

Future<void> _detectIOSAppOnMac() async {
  if (defaultTargetPlatform != TargetPlatform.iOS) return;

  try {
    _isIOSAppOnMac = await _channel.invokeMethod<bool>('isiOSAppOnMac') == true;
  } on MissingPluginException {
    _isIOSAppOnMac = false;
  } catch (e) {
    _log.warning('Failed to detect whether running on a Mac', e);
    _isIOSAppOnMac = false;
  }
}

bool get hasTouchInput =>
    (defaultTargetPlatform == TargetPlatform.iOS && !_isIOSAppOnMac) ||
    defaultTargetPlatform == TargetPlatform.android;

TargetPlatform get hostPlatform =>
    _isIOSAppOnMac ? TargetPlatform.macOS : defaultTargetPlatform;
