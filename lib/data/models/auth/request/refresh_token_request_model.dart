// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

class RefreshTokenRequestModel {
  final String refresh;

  RefreshTokenRequestModel({required this.refresh});

  Map<String, dynamic> toJson() {
    return {'refresh': refresh};
  }
}
