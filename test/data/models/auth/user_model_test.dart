import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/auth/user_model.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../../../helpers/auth_helper.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('UserModel', () {
    test('parses when the API token was created', () {
      // GIVEN
      final json = givenUserJson()
        ..['api_token_created_at'] = '2026-11-01T15:30:00Z';

      // WHEN
      final user = UserModel.fromJson(json);

      // THEN
      expect(user.apiTokenCreatedAt, DateTime.utc(2026, 11, 1, 15, 30));
    });

    test('reports no API token when the API returns null', () {
      // GIVEN
      final json = givenUserJson()..['api_token_created_at'] = null;

      // WHEN
      final user = UserModel.fromJson(json);

      // THEN
      expect(user.apiTokenCreatedAt, isNull);
    });
  });
}
