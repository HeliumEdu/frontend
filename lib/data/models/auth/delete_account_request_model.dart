class DeleteAccountRequestModel {
  final String password;

  DeleteAccountRequestModel({required this.password});

  Map<String, dynamic> toJson() {
    return {'password': password};
  }
}
