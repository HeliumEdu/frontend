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
      test('converts 6-digit hex with # prefix to Color', () {
        final color = HeliumColors.hexToColor('#FF5733');
        expect(color, const Color(0xFFFF5733));
      });

      test('converts 6-digit hex without # prefix to Color', () {
        final color = HeliumColors.hexToColor('4CAF50');
        expect(color, const Color(0xFF4CAF50));
      });

      test('converts 3-digit hex with # prefix to Color', () {
        final color = HeliumColors.hexToColor('#F00');
        expect(color, const Color(0xFFFF0000));
      });

      test('converts 3-digit hex without # prefix to Color', () {
        final color = HeliumColors.hexToColor('0F0');
        expect(color, const Color(0xFF00FF00));
      });

      test('handles lowercase hex values', () {
        final color = HeliumColors.hexToColor('#abcdef');
        expect(color, const Color(0xFFABCDEF));
      });

      test('handles mixed case hex values', () {
        final color = HeliumColors.hexToColor('#AbCdEf');
        expect(color, const Color(0xFFABCDEF));
      });
    });

    group('colorToHex', () {
      test('converts Color to hex string with # prefix', () {
        const color = Color(0xFFFF5733);
        final hex = HeliumColors.colorToHex(color);
        expect(hex, '#ff5733');
      });

      test('converts white to hex string', () {
        const color = Color(0xFFFFFFFF);
        final hex = HeliumColors.colorToHex(color);
        expect(hex, '#ffffff');
      });

      test('converts black to hex string', () {
        const color = Color(0xFF000000);
        final hex = HeliumColors.colorToHex(color);
        expect(hex, '#000000');
      });

      test('ignores alpha channel in output', () {
        const color = Color(0x80FF5733);
        final hex = HeliumColors.colorToHex(color);
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
      test('returns green for lowest priority (1)', () {
        final color = HeliumColors.getColorForPriority(1);
        expect(color, const Color(0xff6FCC43));
      });

      test('returns red for highest priority (100)', () {
        final color = HeliumColors.getColorForPriority(100);
        expect(color, const Color(0xffD92727));
      });

      test('returns appropriate color for mid-range priority (50)', () {
        final color = HeliumColors.getColorForPriority(50);
        expect(color, const Color(0xffD9DF1E));
      });

      test('clamps values below 1 to minimum color', () {
        final color = HeliumColors.getColorForPriority(0);
        expect(color, const Color(0xff6FCC43));
      });

      test('clamps values above 100 to maximum color', () {
        final color = HeliumColors.getColorForPriority(150);
        expect(color, const Color(0xffD92727));
      });

      test('returns correct color for boundary value 10', () {
        final color = HeliumColors.getColorForPriority(10);
        expect(color, const Color(0xff6FCC43));
      });

      test('returns correct color for boundary value 11', () {
        final color = HeliumColors.getColorForPriority(11);
        expect(color, const Color(0xff86D238));
      });

      test('returns correct color for priority 91-100 range', () {
        final color = HeliumColors.getColorForPriority(95);
        expect(color, const Color(0xffD92727));
      });
    });
  });
}
