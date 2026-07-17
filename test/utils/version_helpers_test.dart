// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/version_helpers.dart';

void main() {
  group('VersionHelpers.isBelow', () {
    test('is true when the version is older than the minimum', () {
      expect(VersionHelpers.isBelow('3.5.0', '3.6.0'), isTrue);
      expect(VersionHelpers.isBelow('3.6.17', '3.6.18'), isTrue);
      expect(VersionHelpers.isBelow('2.9.9', '3.0.0'), isTrue);
    });

    test('is false when the version meets or exceeds the minimum', () {
      expect(VersionHelpers.isBelow('3.6.0', '3.6.0'), isFalse);
      expect(VersionHelpers.isBelow('3.7.0', '3.6.0'), isFalse);
      expect(VersionHelpers.isBelow('4.0.0', '3.9.9'), isFalse);
    });

    test('ignores build metadata', () {
      expect(VersionHelpers.isBelow('3.6.18+336', '3.6.18'), isFalse);
      expect(VersionHelpers.isBelow('3.6.17+999', '3.6.18'), isTrue);
    });

    test('fails open — malformed input never gates the user out', () {
      expect(VersionHelpers.isBelow('', '3.6.0'), isFalse);
      expect(VersionHelpers.isBelow('not-a-version', '3.6.0'), isFalse);
      expect(VersionHelpers.isBelow('3.6', '3.6.0'), isFalse);
      expect(VersionHelpers.isBelow('3.5.0', 'garbage'), isFalse);
    });
  });
}
