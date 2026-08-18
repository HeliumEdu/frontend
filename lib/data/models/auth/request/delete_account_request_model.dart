class DeleteAccountRequestModel {
  final String? password;

  DeleteAccountRequestModel({this.password});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (password != null && password!.isNotEmpty) {
      json['password'] = password;
    }
    return json;
  }
}
