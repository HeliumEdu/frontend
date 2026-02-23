// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:logging/logging.dart';

final _log = Logger('core');

class WhatsNewService {
  // Bump this number to show the "What's New" dialog to users again
  static const int currentWhatsNewVersion = 4;

  static final WhatsNewService _instance = WhatsNewService._internal();

  factory WhatsNewService() => _instance;

  WhatsNewService._internal();

  final DioClient _dioClient = DioClient();

  Future<bool> shouldShowWhatsNew() async {
    try {
      final settings = await _dioClient.getSettings();
      final seenVersion =
          settings?.whatsNewVersionSeen ??
          FallbackConstants.defaultWhatsNewVersionSeen;
      return seenVersion < currentWhatsNewVersion;
    } catch (e) {
      _log.warning('Failed to evaluate What\'s New visibility: $e');
      return false;
    }
  }

  Future<void> markWhatsNewAsSeen() async {
    try {
      await _dioClient.updateSettings(
        UpdateSettingsRequestModel(whatsNewVersionSeen: currentWhatsNewVersion),
      );
    } catch (e) {
      _log.warning('Failed to mark What\'s New as seen: $e');
    }
  }
}
