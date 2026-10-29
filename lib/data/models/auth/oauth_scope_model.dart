class OAuthScopeModel {
  final String scope;
  final String description;

  OAuthScopeModel({required this.scope, required this.description});

  factory OAuthScopeModel.fromJson(Map<String, dynamic> json) {
    return OAuthScopeModel(
      scope: json['scope'],
      description: json['description'],
    );
  }
}
