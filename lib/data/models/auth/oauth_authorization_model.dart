import 'package:heliumapp/data/models/auth/oauth_scope_model.dart';

class OAuthAuthorizationModel {
  final String clientName;
  final String redirectUri;
  final List<OAuthScopeModel> scopes;

  /// The signed-in account the access would be granted for.
  final String? userEmail;
  final List<String> userOAuthProviders;

  OAuthAuthorizationModel({
    required this.clientName,
    required this.redirectUri,
    required this.scopes,
    this.userEmail,
    this.userOAuthProviders = const [],
  });

  factory OAuthAuthorizationModel.fromJson(Map<String, dynamic> json) {
    return OAuthAuthorizationModel(
      clientName: json['client_name'],
      redirectUri: json['redirect_uri'],
      scopes: (json['scopes'] as List<dynamic>)
          .map((scope) => OAuthScopeModel.fromJson(scope))
          .toList(),
      userEmail: json['user_email'],
      userOAuthProviders: List<String>.from(json['user_oauth_providers'] ?? []),
    );
  }
}
