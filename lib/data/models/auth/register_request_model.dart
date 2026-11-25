class RegisterRequestModel {
  final String email;
  final String password;
  final String timezone;
  final String language;

  RegisterRequestModel({
    required this.email,
    required this.password,
    required this.timezone,
    required this.language,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'time_zone': timezone,
      'language': language,
    };
  }
}
