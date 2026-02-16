// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/color_helpers.dart';

void main() {
  group('HeliumColors', () {
    group('hexToColor', () {
      test('converts hex to Color', () {
        expect(HeliumColors.hexToColor('#FF5733'), const Color(0xFFFF5733));
        expect(HeliumColors.hexToColor('4CAF50'), const Color(0xFF4CAF50));
        expect(HeliumColors.hexToColor('#F00'), const Color(0xFFFF0000));
        expect(HeliumColors.hexToColor('0F0'), const Color(0xFF00FF00));
        expect(HeliumColors.hexToColor('#abcdef'), const Color(0xFFABCDEF));
        expect(HeliumColors.hexToColor('#AbCdEf'), const Color(0xFFABCDEF));
      });
    });

    group('colorToHex', () {
      test('converts Color to hex string', () {
        expect(HeliumColors.colorToHex(const Color(0xFFFF5733)), '#ff5733');
        expect(HeliumColors.colorToHex(const Color(0xFFFFFFFF)), '#ffffff');
        expect(HeliumColors.colorToHex(const Color(0xFF000000)), '#000000');
      });

      test('ignores alpha channel in output', () {
        final hex = HeliumColors.colorToHex(const Color(0x80FF5733));
        expect(hex.length, 7);
        expect(hex.startsWith('#'), isTrue);
      });
    });

    group('getRandomColor', () {
      test('returns a color from preferredColors list', () {
        final color = HeliumColors.getRandomColor();
        expect(HeliumColors.preferredColors.contains(color), isTrue);
      });

      test('returns different colors on multiple calls', () {
        final colors = <Color>{};
        for (int i = 0; i < 100; i++) {
          colors.add(HeliumColors.getRandomColor());
        }
        expect(colors.length, greaterThan(1));
      });
    });

    group('getColorForPriority', () {
      test('returns gradient from green (low) to red (high)', () {
        expect(HeliumColors.getColorForPriority(1), const Color(0xff6FCC43));
        expect(HeliumColors.getColorForPriority(50), const Color(0xffD9DF1E));
        expect(HeliumColors.getColorForPriority(100), const Color(0xffD92727));
      });

      test('clamps out-of-range values', () {
        expect(HeliumColors.getColorForPriority(0), const Color(0xff6FCC43));
        expect(HeliumColors.getColorForPriority(150), const Color(0xffD92727));
      });
    });
  });
}
