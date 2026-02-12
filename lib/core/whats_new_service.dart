// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';

class WhatsNewService {
  // Bump this number to show the "What's New" dialog to users again
  static const int currentWhatsNewVersion = 2;

  static final WhatsNewService _instance = WhatsNewService._internal();

  factory WhatsNewService() => _instance;

  WhatsNewService._internal();

  final DioClient _dioClient = DioClient();

  Future<bool> shouldShowWhatsNew() async {
    final seenVersion = (await _dioClient.getSettings())!.whatsNewVersionSeen;
    return seenVersion < currentWhatsNewVersion;
  }

  Future<void> markWhatsNewAsSeen() async {
    await _dioClient.updateSettings(
      UpdateSettingsRequestModel(whatsNewVersionSeen: currentWhatsNewVersion),
    );
  }
}
