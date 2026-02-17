// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobile = 600;

  static const double tablet = 1024;

  /// Desktop: 1024px+
  /// (no upper limit needed)
}

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static bool isIOSPlatform() => defaultTargetPlatform == TargetPlatform.iOS;

  static bool isAndroidPlatform() =>
      defaultTargetPlatform == TargetPlatform.android;

  static bool isMobile(BuildContext context) {
    return isMobileWidth(MediaQuery.of(context).size.width);
  }

  static bool isTablet(BuildContext context) {
    return isTabletWidth(MediaQuery.of(context).size.width);
  }

  static bool isDesktop(BuildContext context) {
    return isDesktopWidth(MediaQuery.of(context).size.width);
  }

  static bool isMobileWidth(double width) {
    return width < ResponsiveBreakpoints.mobile;
  }

  static bool isTabletWidth(double width) {
    return width >= ResponsiveBreakpoints.mobile &&
        width < ResponsiveBreakpoints.tablet;
  }

  static bool isDesktopWidth(double width) {
    return width >= ResponsiveBreakpoints.tablet;
  }

  static int getColumnCountForWidth(
    double width, {
    required int mobile,
    required int tablet,
    required int desktop,
  }) {
    final deviceType = getDeviceTypeFromSize(Size(width, 0));
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.mobile:
        return mobile;
    }
  }

  /// - Native iOS/Android → true
  /// - Web on mobile/tablet browser → true (Flutter detects the platform)
  /// - Desktop (native or web) → false
  static bool isTouchDevice(BuildContext context) {
    return isIOSPlatform() || isAndroidPlatform();
  }

  static DeviceType getDeviceType(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width >= ResponsiveBreakpoints.tablet) {
      return DeviceType.desktop;
    } else if (width >= ResponsiveBreakpoints.mobile) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }

  static DeviceType getDeviceTypeFromSize(Size size) {
    if (size.width >= ResponsiveBreakpoints.tablet) {
      return DeviceType.desktop;
    } else if (size.width >= ResponsiveBreakpoints.mobile) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }

  static double getIconSize(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? 32.0;
      case DeviceType.tablet:
        return tablet ?? 28.0;
      case DeviceType.mobile:
        return mobile ?? 24.0;
    }
  }

  static double getFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  static double getDialogWidth(BuildContext context) {
    if (isMobile(context)) {
      return MediaQuery.of(context).size.width * 0.9;
    } else {
      return 350.0;
    }
  }
}
