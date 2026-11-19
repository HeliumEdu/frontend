class TokenResponseModel {
  final String access;
  final String refresh;
  final List<String> unlinkedProviders;

  TokenResponseModel({
    required this.access,
    required this.refresh,
    this.unlinkedProviders = const [],
  });

  factory TokenResponseModel.fromJson(Map<String, dynamic> json) {
    return TokenResponseModel(
      access: json['access'],
      refresh: json['refresh'],
      unlinkedProviders: (json['unlinked_providers'] as List<dynamic>? ?? [])
          .cast<String>(),
    );
  }
}
