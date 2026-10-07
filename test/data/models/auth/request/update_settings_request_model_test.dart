import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/auth/request/update_settings_request_model.dart';

void main() {
  group('UpdateSettingsRequestModel', () {
    test('reports the dialog as shown by sending only getting_started_due false', () {
      // GIVEN
      final request = UpdateSettingsRequestModel(gettingStartedDue: false);

      // WHEN
      final json = request.toJson();

      // THEN
      expect(json, {'getting_started_due': false});
    });
  });
}
