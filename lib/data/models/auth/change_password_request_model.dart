class ChangePasswordRequestModel {
  final String? username;
  final String? email;
  final String oldPassword;
  final String password;

  ChangePasswordRequestModel({
    this.username,
    this.email,
    required this.oldPassword,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      'old_password': oldPassword,
      'password': password,
    };
  }
}
