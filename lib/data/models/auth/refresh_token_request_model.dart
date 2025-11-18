class RefreshTokenRequestModel {
  final String refresh;

  RefreshTokenRequestModel({required this.refresh});

  Map<String, dynamic> toJson() {
    return {'refresh': refresh};
  }
}
