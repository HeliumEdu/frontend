import 'package:heliumapp/data/models/base_model.dart';

class PushTokenModel extends BaseModel {
  final String deviceId;
  final String token;
  final int user;

  PushTokenModel({
    required super.id,
    required this.deviceId,
    required this.token,
    required this.user,
  });

  factory PushTokenModel.fromJson(Map<String, dynamic> json) {
    return PushTokenModel(
      id: json['id'],
      deviceId: json['device_id'],
      token: json['token'],
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'token': token,
      'user': user,
    };
  }
}
