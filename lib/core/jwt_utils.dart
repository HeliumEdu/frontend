import 'dart:convert';

class JWTUtils {
  /// Decode JWT token and extract payload
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decode the payload (second part)
      final payload = parts[1];

      // Add padding if needed
      String normalized = payload;
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      final decoded = utf8.decode(base64Url.decode(normalized));

      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Failed to decode JWT token: $e');
      return null;
    }
  }

  /// Extract user ID from JWT token
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

  /// Check if access token is expired
  static bool isAccessTokenExpired(String accessToken) {
    final payload = decodePayload(accessToken);
    if (payload != null && payload.containsKey('exp')) {
      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now >= exp;
    }
    return true; // Assume expired if we can't decode
  }
}
