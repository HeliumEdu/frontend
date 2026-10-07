import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/auth/user_settings_model.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/auth_helper.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  group('UserSettingsModel', () {
    test('parses getting_started_due independently of show_getting_started', () {
      // GIVEN
      final json = givenUserSettingsJson(showGettingStarted: true, gettingStartedDue: false);

      // WHEN
      final settings = UserSettingsModel.fromJson(json);

      // THEN
      expect(settings.showGettingStarted, isTrue);
      expect(settings.gettingStartedDue, isFalse);
    });
  });
}
