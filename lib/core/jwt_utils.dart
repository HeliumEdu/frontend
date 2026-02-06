// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:convert';

import 'package:logging/logging.dart';

final _log = Logger('core');

class JwtUtils {
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];

      String normalized = payload;
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      final decoded = utf8.decode(base64Url.decode(normalized));

      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      _log.warning('Failed to decode JWT token', e);
      return null;
    }
  }

  static int? getUserId(String token) {
    final payload = decodePayload(token);
    if (payload != null && payload.containsKey('user_id')) {
      final userId = payload['user_id'];
      if (userId is String) {
        return int.tryParse(userId);
      } else if (userId is int) {
        return userId;
      }
    }
    return null;
  }

  static bool isAccessTokenExpired(String accessToken) {
    final payload = decodePayload(accessToken);
    if (payload != null && payload.containsKey('exp')) {
      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now >= exp;
    }
    return true;
  }
}
