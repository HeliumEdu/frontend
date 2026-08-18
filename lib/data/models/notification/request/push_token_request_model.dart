class PushTokenRequestModel {
  final String deviceId;
  final String token;

  PushTokenRequestModel({required this.deviceId, required this.token});

  Map<String, dynamic> toJson() {
    return {'device_id': deviceId, 'token': token};
  }

  factory PushTokenRequestModel.fromJson(Map<String, dynamic> json) {
    return PushTokenRequestModel(
      deviceId: json['device_id'],
      token: json['token'],
    );
  }
}
