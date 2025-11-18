class FCMTokenModel {
  final String token;
  final DateTime? timestamp;
  final bool? isActive;

  FCMTokenModel({required this.token, this.timestamp, this.isActive});

  factory FCMTokenModel.fromJson(Map<String, dynamic> json) {
    return FCMTokenModel(
      token: json['token'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'timestamp': timestamp?.toIso8601String(),
      'is_active': isActive,
    };
  }

  FCMTokenModel copyWith({String? token, DateTime? timestamp, bool? isActive}) {
    return FCMTokenModel(
      token: token ?? this.token,
      timestamp: timestamp ?? this.timestamp,
      isActive: isActive ?? this.isActive,
    );
  }
}
