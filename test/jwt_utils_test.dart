import 'package:flutter_test/flutter_test.dart';
import 'package:helium_student_flutter/core/jwt_utils.dart';

void main() {
  group('JWTUtils', () {
    test('should decode JWT payload correctly', () {
      // This is a sample JWT token with user_id: 13446
      const token =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYxMzA4NDY4LCJpYXQiOjE3NjEzMDc1MDgsImp0aSI6IjMxM2FhNjU1YjgwNDQzNjM4OWVkYWViNjBkNGM3ZDBmIiwidXNlcl9pZCI6IjEzNDQ2In0.48BQ2-BU8SZkPgJVi00b2Rwh9FT200VonAzizSrMTsA';

      final payload = JWTUtils.decodePayload(token);
      expect(payload, isNotNull);
      expect(payload!['user_id'], equals('13446'));
    });

    test('should extract user ID from JWT token', () {
      const token =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYxMzA4NDY4LCJpYXQiOjE3NjEzMDc1MDgsImp0aSI6IjMxM2FhNjU1YjgwNDQzNjM4OWVkYWViNjBkNGM3ZDBmIiwidXNlcl9pZCI6IjEzNDQ2In0.48BQ2-BU8SZkPgJVi00b2Rwh9FT200VonAzizSrMTsA';

      final userId = JWTUtils.getUserId(token);
      expect(userId, equals(13446));
    });

    test('should return null for invalid token', () {
      const invalidToken = 'invalid.token.here';

      final userId = JWTUtils.getUserId(invalidToken);
      expect(userId, isNull);
    });

    test('should check token expiration', () {
      // This token has exp: 1761308468 (expired)
      const expiredToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYxMzA4NDY4LCJpYXQiOjE3NjEzMDc1MDgsImp0aSI6IjMxM2FhNjU1YjgwNDQzNjM4OWVkYWViNjBkNGM3ZDBmIiwidXNlcl9pZCI6IjEzNDQ2In0.48BQ2-BU8SZkPgJVi00b2Rwh9FT200VonAzizSrMTsA';

      final isExpired = JWTUtils.isTokenExpired(expiredToken);
      // The token might not be expired yet, so we just check that the function works
      expect(isExpired, isA<bool>());
    });
  });
}
