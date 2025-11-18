class RegisterResponseModel {
  final String message;
  final int? userId;
  final String? username;
  final String? email;

  RegisterResponseModel({
    required this.message,
    this.userId,
    this.username,
    this.email,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      message: json['message'] ?? json['detail'] ?? 'Registration successful',
      userId: json['id'],
      username: json['username'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'id': userId,
      'username': username,
      'email': email,
    };
  }
}
