// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should generate device ID with correct length', () {
    const fcmToken =
        'cmtjK_7-R3O2U0cZKFEt8g:APA91bGGFXf-bvOlmzz_tlRioqtz9206V317zvnKlvD-asNzrx2m73Ix2zwDf0D_Rr5mdLMm9seaPtT2TIvu1VNF34w_SR2aYuMBUI0C3L8npw3w5eelI9c';

    final deviceId =
        '${fcmToken.substring(0, 30)}_${DateTime.now().millisecondsSinceEpoch}';

    expect(deviceId.length, lessThan(100));
    expect(deviceId.length, greaterThan(30));
  });
}
