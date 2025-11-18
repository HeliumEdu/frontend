class DeleteAccountResponseModel {
  final String message;

  DeleteAccountResponseModel({required this.message});

  factory DeleteAccountResponseModel.fromJson(Map<String, dynamic> json) {
    return DeleteAccountResponseModel(
      message:
          json['message'] ?? json['detail'] ?? 'Account deleted successfully',
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message};
  }
}
