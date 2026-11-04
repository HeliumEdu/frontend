import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/platform_behavior.dart';

void main() {
  group('PlatformBehavior.showsDialogsFullScreen', () {
    Future<bool> givenScreen(
      WidgetTester tester,
      Size size, {
      required TargetPlatform platform,
    }) async {
      debugDefaultTargetPlatformOverride = platform;
      late bool fullScreen;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (context) {
              fullScreen = PlatformBehavior.showsDialogsFullScreen(context);
              return const SizedBox();
            },
          ),
        ),
      );
      debugDefaultTargetPlatformOverride = null;
      return fullScreen;
    }

    testWidgets('a portrait tablet shows dialogs full screen', (tester) async {
      // WHEN
      final iPad = await givenScreen(
        tester,
        const Size(820, 1180),
        platform: TargetPlatform.iOS,
      );
      final androidTablet = await givenScreen(
        tester,
        const Size(800, 1280),
        platform: TargetPlatform.android,
      );

      // THEN
      expect(iPad, isTrue);
      expect(androidTablet, isTrue);
    });

    testWidgets('a landscape tablet keeps dialogs', (tester) async {
      // WHEN
      final fullScreen = await givenScreen(
        tester,
        const Size(1180, 820),
        platform: TargetPlatform.iOS,
      );

      // THEN
      expect(fullScreen, isFalse);
    });

    testWidgets('a narrow desktop window keeps dialogs', (tester) async {
      // WHEN
      final fullScreen = await givenScreen(
        tester,
        const Size(820, 1180),
        platform: TargetPlatform.macOS,
      );

      // THEN
      expect(
        fullScreen,
        isFalse,
        reason: 'Only tablets go full screen when upright, not browser windows',
      );
    });

    testWidgets('a phone-width window shows dialogs full screen anywhere',
        (tester) async {
      // WHEN
      final fullScreen = await givenScreen(
        tester,
        const Size(390, 844),
        platform: TargetPlatform.macOS,
      );

      // THEN
      expect(fullScreen, isTrue);
    });
  });
}
