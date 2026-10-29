import 'package:heliumapp/data/models/auth/oauth_scope_model.dart';

class OAuthAuthorizationModel {
  final String clientName;
  final String redirectUri;
  final List<OAuthScopeModel> scopes;

  OAuthAuthorizationModel({
    required this.clientName,
    required this.redirectUri,
    required this.scopes,
  });

  factory OAuthAuthorizationModel.fromJson(Map<String, dynamic> json) {
    return OAuthAuthorizationModel(
      clientName: json['client_name'],
      redirectUri: json['redirect_uri'],
      scopes: (json['scopes'] as List<dynamic>)
          .map((scope) => OAuthScopeModel.fromJson(scope))
          .toList(),
    );
  }
}
