class OAuthScopeModel {
  final String scope;
  final String description;

  /// Whether the scope must be granted; an optional one is offered unchecked.
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
