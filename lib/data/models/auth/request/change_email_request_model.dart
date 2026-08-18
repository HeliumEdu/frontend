class ChangeEmailRequestModel {
  final String email;
  final String oldPassword;

  ChangeEmailRequestModel({
    required this.email,
    required this.oldPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'old_password': oldPassword,
    };
  }
}
