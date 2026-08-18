class ResetPasswordRequestModel {
  final String uid;
  final String token;
  final String password;

  ResetPasswordRequestModel({
    required this.uid,
    required this.token,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'token': token,
    'password': password,
  };
}
