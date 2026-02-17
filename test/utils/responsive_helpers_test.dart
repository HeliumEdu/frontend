// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

void main() {
  group('Responsive.getDeviceTypeFromSize', () {
    test('returns mobile for width < 600', () {
      expect(
        Responsive.getDeviceTypeFromSize(const Size(320, 568)),
        DeviceType.mobile,
      );
      expect(
        Responsive.getDeviceTypeFromSize(const Size(599, 800)),
        DeviceType.mobile,
      );
    });

    test('returns tablet for width >= 600 and < 1024', () {
      expect(
        Responsive.getDeviceTypeFromSize(const Size(600, 800)),
        DeviceType.tablet,
      );
      expect(
        Responsive.getDeviceTypeFromSize(const Size(768, 1024)),
        DeviceType.tablet,
      );
      expect(
        Responsive.getDeviceTypeFromSize(const Size(1023, 1366)),
        DeviceType.tablet,
      );
    });

    test('returns desktop for width >= 1024', () {
      expect(
        Responsive.getDeviceTypeFromSize(const Size(1024, 768)),
        DeviceType.desktop,
      );
      expect(
        Responsive.getDeviceTypeFromSize(const Size(1920, 1080)),
        DeviceType.desktop,
      );
      expect(
        Responsive.getDeviceTypeFromSize(const Size(2560, 1440)),
        DeviceType.desktop,
      );
    });

    test('handles boundary values correctly', () {
      expect(
        Responsive.getDeviceTypeFromSize(const Size(599.9, 800)),
        DeviceType.mobile,
      );
      expect(
        Responsive.getDeviceTypeFromSize(const Size(600.0, 800)),
        DeviceType.tablet,
      );
      expect(
        Responsive.getDeviceTypeFromSize(const Size(1023.9, 800)),
        DeviceType.tablet,
      );
      expect(
        Responsive.getDeviceTypeFromSize(const Size(1024.0, 800)),
        DeviceType.desktop,
      );
    });
  });

  group('Responsive with BuildContext', () {
    testWidgets('isMobile returns true for mobile width', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(Responsive.isMobile(context), isTrue);
              expect(Responsive.isTablet(context), isFalse);
              expect(Responsive.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isTablet returns true for tablet width', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              expect(Responsive.isMobile(context), isFalse);
              expect(Responsive.isTablet(context), isTrue);
              expect(Responsive.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isDesktop returns true for desktop width', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1440, 900)),
          child: Builder(
            builder: (context) {
              expect(Responsive.isMobile(context), isFalse);
              expect(Responsive.isTablet(context), isFalse);
              expect(Responsive.isDesktop(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getDeviceType returns correct device type', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(Responsive.getDeviceType(context), DeviceType.mobile);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getIconSize returns default values for each device type',
        (tester) async {
      // Mobile
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(Responsive.getIconSize(context), 24.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1024)),
          child: Builder(
            builder: (context) {
              expect(Responsive.getIconSize(context), 28.0);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1440, 900)),
          child: Builder(
            builder: (context) {
              expect(Responsive.getIconSize(context), 32.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getIconSize returns custom values when provided',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(
                Responsive.getIconSize(context, mobile: 16.0),
                16.0,
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getFontSize returns correct size for mobile', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(
                Responsive.getFontSize(context, mobile: 14.0),
                14.0,
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getFontSize falls back correctly', (tester) async {
      // Desktop falls back to tablet, then mobile
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1440, 900)),
          child: Builder(
            builder: (context) {
              // No desktop or tablet specified, falls back to mobile
              expect(
                Responsive.getFontSize(context, mobile: 14.0),
                14.0,
              );
              // Tablet specified, desktop falls back to tablet
              expect(
                Responsive.getFontSize(context, mobile: 14.0, tablet: 16.0),
                16.0,
              );
              // Desktop specified
              expect(
                Responsive.getFontSize(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
                18.0,
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getDialogWidth returns percentage width for mobile',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(Responsive.getDialogWidth(context), 360.0); // 400 * 0.9
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getDialogWidth returns fixed width for non-mobile',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1024, 768)),
          child: Builder(
            builder: (context) {
              expect(Responsive.getDialogWidth(context), 350.0);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
