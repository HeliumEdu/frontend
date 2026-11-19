import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/auth/token_response_model.dart';

void main() {
  group('TokenResponseModel', () {
    test('parses the providers the sign-in unlinked', () {
      // GIVEN
      final json = {
        'access': 'access-token',
        'refresh': 'refresh-token',
        'unlinked_providers': ['microsoft'],
      };

      // WHEN
      final response = TokenResponseModel.fromJson(json);

      // THEN
      expect(response.unlinkedProviders, ['microsoft']);
    });

    test('unlinks nothing when the API omits unlinked providers', () {
      // GIVEN
      final json = {'access': 'access-token', 'refresh': 'refresh-token'};

      // WHEN
      final response = TokenResponseModel.fromJson(json);

      // THEN
      expect(response.unlinkedProviders, isEmpty);
    });
  });
}
