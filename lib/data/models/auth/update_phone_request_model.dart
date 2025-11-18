class UpdatePhoneRequestModel {
  final String phone;
  final int? phoneVerificationCode;

  UpdatePhoneRequestModel({required this.phone, this.phoneVerificationCode});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'phone': phone};
    if (phoneVerificationCode != null) {
      data['phone_verification_code'] = phoneVerificationCode;
    }
    return data;
  }
}
