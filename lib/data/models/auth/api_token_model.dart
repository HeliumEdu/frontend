class ApiTokenModel {
  /// The plaintext token, returned only when it's created.
  final String token;
  final DateTime createdAt;

  ApiTokenModel({required this.token, required this.createdAt});

  factory ApiTokenModel.fromJson(Map<String, dynamic> json) {
    return ApiTokenModel(
      token: json['token'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
