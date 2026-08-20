import 'package:flutter/foundation.dart';

/// Platform buckets for gating platform-specific features.
enum AppPlatform { ios, android, web }

/// Current platform; web wins over the underlying OS (iOS Safari is web).
AppPlatform get currentAppPlatform {
  if (kIsWeb) return AppPlatform.web;
  return defaultTargetPlatform == TargetPlatform.iOS
      ? AppPlatform.ios
      : AppPlatform.android;
}

/// Per-platform donation-link visibility. Flip a flag to show or hide every
/// donation surface on that platform. iOS is off: App Store guideline 3.1.1
/// treats an external donation link as an in-app purchase.
const Map<AppPlatform, bool> _donationVisibleByPlatform = {
  AppPlatform.ios: true,
  AppPlatform.android: true,
  AppPlatform.web: true,
};

bool get showDonationLink =>
    _donationVisibleByPlatform[currentAppPlatform] ?? true;
