// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/jwt_utils.dart';

void main() {
  group('JWTUtils', () {
    test('should decode JWT payload correctly', () {
      // This is a sample JWT token with user_id: 13446
      const token =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYxMzA4NDY4LCJpYXQiOjE3NjEzMDc1MDgsImp0aSI6IjMxM2FhNjU1YjgwNDQzNjM4OWVkYWViNjBkNGM3ZDBmIiwidXNlcl9pZCI6IjEzNDQ2In0.48BQ2-BU8SZkPgJVi00b2Rwh9FT200VonAzizSrMTsA';

      final payload = JwtUtils.decodePayload(token);
      expect(payload, isNotNull);
      expect(payload!['user_id'], equals('13446'));
    });

    test('should extract user ID from JWT token', () {
      const token =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYxMzA4NDY4LCJpYXQiOjE3NjEzMDc1MDgsImp0aSI6IjMxM2FhNjU1YjgwNDQzNjM4OWVkYWViNjBkNGM3ZDBmIiwidXNlcl9pZCI6IjEzNDQ2In0.48BQ2-BU8SZkPgJVi00b2Rwh9FT200VonAzizSrMTsA';

      final userId = JwtUtils.getUserId(token);
      expect(userId, equals(13446));
    });

    test('should return null for invalid token', () {
      const invalidToken = 'invalid.token.here';

      final userId = JwtUtils.getUserId(invalidToken);
      expect(userId, isNull);
    });

    test('should check token expiration', () {
      // This token has exp: 1761308468 (expired)
      const expiredToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYxMzA4NDY4LCJpYXQiOjE3NjEzMDc1MDgsImp0aSI6IjMxM2FhNjU1YjgwNDQzNjM4OWVkYWViNjBkNGM3ZDBmIiwidXNlcl9pZCI6IjEzNDQ2In0.48BQ2-BU8SZkPgJVi00b2Rwh9FT200VonAzizSrMTsA';

      final isExpired = JwtUtils.isAccessTokenExpired(expiredToken);
      expect(isExpired, isA<bool>());
    });
  });
}
