class PushTokenRequestModel {
  final String deviceId;
  final String token;
  final int user;
  final String type;

  PushTokenRequestModel({
    required this.deviceId,
    required this.token,
    required this.user,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {'device_id': deviceId, 'token': token, 'user': user, 'type': type};
  }

  factory PushTokenRequestModel.fromJson(Map<String, dynamic> json) {
    return PushTokenRequestModel(
      deviceId: json['device_id'] ?? '',
      token: json['token'] ?? '',
      user: json['user'] ?? 0,
      type: json['type'] ?? '',
    );
  }
}
