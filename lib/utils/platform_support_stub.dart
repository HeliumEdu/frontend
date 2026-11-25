import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _log = Logger('utils');

const _channel = MethodChannel('com.heliumedu.heliumapp/native');

/// An iPad build running on an Apple silicon Mac reports as iOS but runs on
/// macOS and is driven by a pointer. Read synchronously, so it resolves out of
/// band via [initialize].
bool _isIOSAppOnMac = false;

Future<void> initialize() async {
  await _detectIOSAppOnMac();
  if (_isIOSAppOnMac) _channel.setMethodCallHandler(_onNativeCall);
}

Future<void> _onNativeCall(MethodCall call) async {
  switch (call.method) {
    case 'escapePressed':
      _deliverEscape();
    default:
      throw MissingPluginException(call.method);
  }
}

void _deliverEscape() {
  const events = [
    KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.escape,
      logicalKey: LogicalKeyboardKey.escape,
      timeStamp: Duration.zero,
    ),
    KeyUpEvent(
      physicalKey: PhysicalKeyboardKey.escape,
      logicalKey: LogicalKeyboardKey.escape,
      timeStamp: Duration.zero,
    ),
  ];
  for (final event in events) {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return;
    for (final node in [focus, ...focus.ancestors]) {
      final result =
          node.onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
      if (result != KeyEventResult.ignored) break;
    }
  }
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
