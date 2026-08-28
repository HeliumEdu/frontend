import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';
import 'package:logging/logging.dart';

final _log = Logger('core');

class WhatsNewService {
  // Bump this number to show the "What's New" dialog to users again
  static const int currentWhatsNewVersion = 9;

  static final WhatsNewService _instance = WhatsNewService._internal();

  factory WhatsNewService() => _instance;

  WhatsNewService._internal();

  final DioClient _dioClient = DioClient();

  Future<bool> shouldShowWhatsNew() async {
    try {
      final settings = await _dioClient.getSettings();
      if (settings == null) {
        return false;
      }
      return settings.whatsNewVersionSeen < currentWhatsNewVersion;
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
