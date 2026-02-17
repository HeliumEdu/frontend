// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/jwt_utils.dart';

void main() {
  group('JwtUtils', () {
    group('decodePayload', () {
      test('decodes valid JWT payload correctly', () {
        // JWT with payload: {"token_type":"access","exp":1761308468,"iat":1761307508,"jti":"313aa655b8044363","user_id":"13446"}
        const token =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYxMzA4NDY4LCJpYXQiOjE3NjEzMDc1MDgsImp0aSI6IjMxM2FhNjU1YjgwNDQzNjM4OWVkYWViNjBkNGM3ZDBmIiwidXNlcl9pZCI6IjEzNDQ2In0.48BQ2-BU8SZkPgJVi00b2Rwh9FT200VonAzizSrMTsA';

        final payload = JwtUtils.decodePayload(token);

        expect(payload, isNotNull);
        expect(payload!['token_type'], equals('access'));
        expect(payload['user_id'], equals('13446'));
        expect(payload['exp'], equals(1761308468));
        expect(payload['iat'], equals(1761307508));
      });

      test('returns null for token with invalid format (not 3 parts)', () {
        const invalidToken = 'only.twoparts';
        expect(JwtUtils.decodePayload(invalidToken), isNull);
      });

      test('returns null for token with single part', () {
        const invalidToken = 'singlepart';
        expect(JwtUtils.decodePayload(invalidToken), isNull);
      });

      test('returns null for empty string', () {
        expect(JwtUtils.decodePayload(''), isNull);
      });

      test('returns null for malformed base64 payload', () {
        const invalidToken = 'header.!!!invalid!!!.signature';
        expect(JwtUtils.decodePayload(invalidToken), isNull);
      });

      test('handles payload with non-standard base64 padding', () {
        // Create a token with payload that needs padding
        final payload = {'test': 'value'};
        final encodedPayload = base64Url
            .encode(utf8.encode(jsonEncode(payload)))
            .replaceAll('=', '');
        final token = 'header.$encodedPayload.signature';

        final decoded = JwtUtils.decodePayload(token);
        expect(decoded, isNotNull);
        expect(decoded!['test'], equals('value'));
      });
    });

    group('getUserId', () {
      test('extracts user_id as string and converts to int', () {
        // Token with user_id as string "13446"
        const token =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYxMzA4NDY4LCJpYXQiOjE3NjEzMDc1MDgsImp0aSI6IjMxM2FhNjU1YjgwNDQzNjM4OWVkYWViNjBkNGM3ZDBmIiwidXNlcl9pZCI6IjEzNDQ2In0.48BQ2-BU8SZkPgJVi00b2Rwh9FT200VonAzizSrMTsA';

        final userId = JwtUtils.getUserId(token);
        expect(userId, equals(13446));
      });

      test('extracts user_id as integer directly', () {
        // Create token with user_id as int
        final payload = {'user_id': 42, 'exp': 9999999999};
        final encodedPayload = base64Url.encode(
          utf8.encode(jsonEncode(payload)),
        );
        final token = 'header.$encodedPayload.signature';

        final userId = JwtUtils.getUserId(token);
        expect(userId, equals(42));
      });

      test('returns null for token without user_id', () {
        final payload = {'exp': 9999999999};
        final encodedPayload = base64Url.encode(
          utf8.encode(jsonEncode(payload)),
        );
        final token = 'header.$encodedPayload.signature';

        expect(JwtUtils.getUserId(token), isNull);
      });

      test('returns null for invalid token', () {
        expect(JwtUtils.getUserId('invalid.token.here'), isNull);
      });

      test('returns null for non-numeric string user_id', () {
        final payload = {'user_id': 'not-a-number', 'exp': 9999999999};
        final encodedPayload = base64Url.encode(
          utf8.encode(jsonEncode(payload)),
        );
        final token = 'header.$encodedPayload.signature';

        expect(JwtUtils.getUserId(token), isNull);
      });
    });

    group('isAccessTokenExpired', () {
      test('returns true for expired token', () {
        // Token with exp: 1761308468 (past timestamp)
        const expiredToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYxMzA4NDY4LCJpYXQiOjE3NjEzMDc1MDgsImp0aSI6IjMxM2FhNjU1YjgwNDQzNjM4OWVkYWViNjBkNGM3ZDBmIiwidXNlcl9pZCI6IjEzNDQ2In0.48BQ2-BU8SZkPgJVi00b2Rwh9FT200VonAzizSrMTsA';

        expect(JwtUtils.isAccessTokenExpired(expiredToken), isTrue);
      });

      test('returns false for non-expired token', () {
        // Create token with exp far in the future (year 2100)
        final futureExp = DateTime(2100).millisecondsSinceEpoch ~/ 1000;
        final payload = {'exp': futureExp, 'user_id': 1};
        final encodedPayload = base64Url.encode(
          utf8.encode(jsonEncode(payload)),
        );
        final token = 'header.$encodedPayload.signature';

        expect(JwtUtils.isAccessTokenExpired(token), isFalse);
      });

      test('returns true for token without exp claim', () {
        final payload = {'user_id': 1};
        final encodedPayload = base64Url.encode(
          utf8.encode(jsonEncode(payload)),
        );
        final token = 'header.$encodedPayload.signature';

        expect(JwtUtils.isAccessTokenExpired(token), isTrue);
      });

      test('returns true for invalid token', () {
        expect(JwtUtils.isAccessTokenExpired('invalid'), isTrue);
      });

      test('considers token expired when exp equals current time', () {
        // Token that expires exactly now should be considered expired
        final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final payload = {'exp': nowSeconds, 'user_id': 1};
        final encodedPayload = base64Url.encode(
          utf8.encode(jsonEncode(payload)),
        );
        final token = 'header.$encodedPayload.signature';

        expect(JwtUtils.isAccessTokenExpired(token), isTrue);
      });
    });
  });
}
