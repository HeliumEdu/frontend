import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/auth/oauth_authorization_model.dart';

void main() {
  group('OAuthAuthorizationModel', () {
    Map<String, dynamic> givenAuthorizationJson({
      String? userEmail,
      List<String>? userOAuthProviders,
    }) => {
      'client_name': 'Claude',
      'redirect_uri': 'https://claude.ai/api/mcp/auth_callback',
      'scopes': [
        {'scope': 'planner:read', 'description': 'Read your planner', 'required': true},
        {'scope': 'planner:notes:read', 'description': 'Read your notes', 'required': false},
        {'scope': 'planner:import', 'description': 'Import terms'},
      ],
      'user_email': ?userEmail,
      'user_oauth_providers': ?userOAuthProviders,
    };

    test('parses the signed-in account the access would be granted for', () {
      // GIVEN
      final json = givenAuthorizationJson(
        userEmail: 'student@example.com',
        userOAuthProviders: ['google'],
      );

      // WHEN
      final authorization = OAuthAuthorizationModel.fromJson(json);

      // THEN
      expect(authorization.userEmail, 'student@example.com');
      expect(authorization.userOAuthProviders, ['google']);
    });

    test('parses which scopes are required, defaulting to required', () {
      // GIVEN
      final json = givenAuthorizationJson();

      // WHEN
      final authorization = OAuthAuthorizationModel.fromJson(json);

      // THEN
      expect(
        {for (final scope in authorization.scopes) scope.scope: scope.required},
        {'planner:read': true, 'planner:notes:read': false, 'planner:import': true},
      );
    });

    test('leaves the account unset when the API does not return it', () {
      // GIVEN
      final json = givenAuthorizationJson();

      // WHEN
      final authorization = OAuthAuthorizationModel.fromJson(json);

      // THEN
      expect(authorization.userEmail, isNull);
      expect(authorization.userOAuthProviders, isEmpty);
    });
  });
}
