import 'package:flutter/foundation.dart';

bool get hasTouchScreen =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android;
