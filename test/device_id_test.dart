import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should generate device ID with correct length', () {
    const fcmToken =
        'cmtjK_7-R3O2U0cZKFEt8g:APA91bGGFXf-bvOlmzz_tlRioqtz9206V317zvnKlvD-asNzrx2m73Ix2zwDf0D_Rr5mdLMm9seaPtT2TIvu1VNF34w_SR2aYuMBUI0C3L8npw3w5eelI9c';

    final deviceId =
        '${fcmToken.substring(0, 30)}_${DateTime.now().millisecondsSinceEpoch}';

    print('FCM Token length: ${fcmToken.length}');
    print('Device ID: $deviceId');
    print('Device ID length: ${deviceId.length}');

    // Should be less than 100 characters
    expect(deviceId.length, lessThan(100));
    expect(deviceId.length, greaterThan(30));
  });
}
