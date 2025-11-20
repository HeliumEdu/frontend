import 'package:flutter_test/flutter_test.dart';
import 'package:heliumedu/core/jwt_utils.dart';

void main() {
  test('should extract user ID from real HeliumEdu JWT token', () {
    const token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYxMzA5MjU4LCJpYXQiOjE3NjEzMDgyOTgsImp0aSI6IjVmOWVlM2UyMzQ1YzQxYzM5MDQ0NGE4N2Q5NTc0NTNiIiwidXNlcl9pZCI6IjEzNDgzIn0.ZkTwQeZKHfE4ndQtwg_iagRQKDDsJ2LJUthoW3hC8ok';

    final userId = JWTUtils.getUserId(token);
    expect(userId, equals(13483));

    final payload = JWTUtils.decodePayload(token);
    expect(payload, isNotNull);
    expect(payload!['user_id'], equals('13483'));
    expect(payload['token_type'], equals('access'));
  });
}
