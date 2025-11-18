class ForgotPasswordResponseModel {
  final String? message;

  ForgotPasswordResponseModel({this.message});

  factory ForgotPasswordResponseModel.fromJson(Map<String, dynamic> json) {
    // API might return {} or {"detail": "..."} or custom message
    final msg = json['message'] ?? json['detail'] ?? json['status'] ?? '';
    return ForgotPasswordResponseModel(
      message: msg is String ? msg : msg?.toString(),
    );
  }
}
