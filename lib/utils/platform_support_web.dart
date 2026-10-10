import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

Future<void> initialize() async {}

bool get hasTouchInput => web.window.navigator.maxTouchPoints > 0;

/// Flutter already reports the browser's operating system.
TargetPlatform get hostPlatform => defaultTargetPlatform;
