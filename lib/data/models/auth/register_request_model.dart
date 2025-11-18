class RegisterRequestModel {
  final String username;
  final String email;
  final String password;
  final String timezone;

  RegisterRequestModel({
    required this.username,
    required this.email,
    required this.password,
    required this.timezone,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'timezone': timezone,
    };
  }
}
