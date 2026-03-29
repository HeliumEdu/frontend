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

  static const double compactDialogHeight = 410.0;
}

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static bool isIOSPlatform() => defaultTargetPlatform == TargetPlatform.iOS;

  static bool isAndroidPlatform() =>
      defaultTargetPlatform == TargetPlatform.android;

  static bool isMobile(BuildContext context) {
    return isMobileWidth(MediaQuery.of(context).size.width);
  }

  /// Returns true when the device is in a "phone landscape" configuration:
  /// width qualifies as tablet (600-1024px) but height is very short (<500px).
  static bool isPhoneLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= ResponsiveBreakpoints.mobile &&
        size.width < ResponsiveBreakpoints.tablet &&
        size.height < 500;
  }

  /// Returns true when compact/mobile layout should be used.
  /// This includes both mobile portrait and phone landscape orientations.
  static bool useCompactLayout(BuildContext context) {
    return isMobile(context) || isPhoneLandscape(context);
  }

  static bool isTablet(BuildContext context) {
    return isTabletWidth(MediaQuery.of(context).size.width);
  }

  static bool isDesktop(BuildContext context) {
    return isDesktopWidth(MediaQuery.of(context).size.width);
  }

  static bool isCompact(BuildContext context) {
    return isCompactWidth(MediaQuery.of(context).size.width);
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

  static bool isCompactWidth(double width) {
    return width < 800;
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

  static double getResponsiveValue(
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

  /// Returns true when the available viewport height (after subtracting the
  /// keyboard and system padding) is at or below [ResponsiveBreakpoints.compactDialogHeight].
  /// Useful for collapsing optional vertical space inside dialogs on very
  /// small devices when the keyboard is open.
  static bool isCompactDialogHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final availableHeight = mq.size.height
        - mq.viewInsets.bottom
        - mq.padding.top
        - mq.padding.bottom;
    return availableHeight <= ResponsiveBreakpoints.compactDialogHeight;
  }

  static double getDialogWidth(BuildContext context, {double fallback = 350}) {
    if (isMobile(context)) {
      return MediaQuery.of(context).size.width * 0.9;
    } else {
      return fallback;
    }
  }
}
