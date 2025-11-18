class UpdatePhoneResponseModel {
  final String? phone;
  final String? phoneChanging;
  final bool phoneVerified;
  final int? user;

  UpdatePhoneResponseModel({
    this.phone,
    this.phoneChanging,
    required this.phoneVerified,
    this.user,
  });

  factory UpdatePhoneResponseModel.fromJson(Map<String, dynamic> json) {
    return UpdatePhoneResponseModel(
      phone: json['phone'],
      phoneChanging: json['phone_changing'],
      phoneVerified: json['phone_verified'] ?? false,
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'phone_changing': phoneChanging,
      'phone_verified': phoneVerified,
      'user': user,
    };
  }
}
