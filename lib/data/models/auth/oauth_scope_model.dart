class OAuthScopeModel {
  final String scope;
  final String description;

  /// Whether granting the scope is required; the user chooses whether to
  /// grant one that isn't, offered unselected.
  final bool required;

  OAuthScopeModel({
    required this.scope,
    required this.description,
    this.required = true,
  });

  factory OAuthScopeModel.fromJson(Map<String, dynamic> json) {
    return OAuthScopeModel(
      scope: json['scope'],
      description: json['description'],
      required: json['required'] ?? true,
    );
  }
}
