import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/presentation/features/settings/views/preferences_screen.dart';
import 'package:heliumapp/presentation/ui/components/helium_checkbox_list_tile.dart';
import 'package:heliumapp/presentation/ui/components/searchable_dropdown.dart';
import 'package:heliumapp/presentation/ui/components/settings_button.dart';
import 'package:heliumapp/presentation/ui/layout/page_header.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'helpers/api_helper.dart';
import 'helpers/test_app.dart';
import 'helpers/test_config.dart';

final _log = Logger('preferences_test');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final config = TestConfig();
  initializeTestLogging(
    environment: config.environment,
    apiHost: config.projectApiHost,
  );

  group('Preferences Tests', () {
    final testEmail = config.testEmail;
    final testPassword = config.testPassword;
    final apiHelper = ApiHelper();

    bool canProceed = false;

    setUpAll(() async {
      await startSuite('Preferences Tests');
      _log.info('Test email: $testEmail');
      canProceed = await apiHelper.userExists(testEmail);
      if (!canProceed) {
        _log.warning('Test user does not exist. Run signup_user_test first.');
      }
    });

    tearDownAll(() async {
      await endSuite();
    });

    namedTestWidgets('1. Preferences shows the regional settings and saves a change', (tester) async {
      if (!canProceed) {
        skipTest('user does not exist (run signup_user_test first)');
        return;
      }

      final settings = await apiHelper.getUserSettings();
      expect(settings, isNotNull, reason: 'Should read settings from the API');

      await initializeTestApp(tester);
      final loggedIn = await loginAndNavigateToPlanner(tester, testEmail, testPassword);
      expect(loggedIn, isTrue, reason: 'Should be logged in');

      _log.info('Opening settings ...');
      final settingsButton = find.byKey(const Key(SettingsButton.buttonKey));
      final settingsFound = await waitForWidget(tester, settingsButton, timeout: config.apiTimeout);
      expect(settingsFound, isTrue, reason: 'Settings button should be visible');
      await tester.tap(settingsButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      _log.info('Navigating to Preferences ...');
      final preferencesItem = find.text('Preferences');
      await scrollUntilVisible(tester, preferencesItem);
      await tester.tap(preferencesItem);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final timeZoneField = find.byKey(const Key(PreferencesScreen.timeZoneField));
      final loaded = await waitForWidget(tester, timeZoneField, timeout: config.apiTimeout);
      expect(loaded, isTrue, reason: 'Preferences form should load');

      // The regional settings detected (or chosen) at signup populate the form
      expect(
        tester.widget<SearchableDropdown<String>>(timeZoneField).initialValue.value,
        equals(settings!['time_zone']),
        reason: 'Time zone should match the account',
      );
      expect(
        tester.widget<SegmentedButton<int>>(find.byKey(const Key(PreferencesScreen.dateFormatField))).selected.first,
        equals(settings['date_format']),
        reason: 'Date format should match the account',
      );
      expect(
        tester.widget<SegmentedButton<int>>(find.byKey(const Key(PreferencesScreen.timeFormatField))).selected.first,
        equals(settings['time_format']),
        reason: 'Time format should match the account',
      );
      expect(
        tester.widget<SegmentedButton<int>>(find.byKey(const Key(PreferencesScreen.numberFormatField))).selected.first,
        equals(settings['number_format']),
        reason: 'Number format should match the account',
      );

      // Toggle a field no other suite depends on and save
      final dragAndDropField = find.byKey(const Key(PreferencesScreen.dragAndDropField));
      final originalDragAndDrop = settings['drag_and_drop_on_mobile'] as bool;
      expect(
        tester.widget<HeliumCheckboxListTile>(dragAndDropField).value,
        equals(originalDragAndDrop),
        reason: 'Drag-and-drop should match the account',
      );
      await scrollUntilVisible(tester, dragAndDropField);
      await tester.tap(dragAndDropField);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key(PageHeader.saveButtonKey)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final saved = await waitForWidgetToDisappear(tester, timeZoneField, timeout: config.apiTimeout);
      expect(saved, isTrue, reason: 'Preferences should close after saving');

      final updated = await apiHelper.getUserSettings();
      expect(
        updated!['drag_and_drop_on_mobile'],
        equals(!originalDragAndDrop),
        reason: 'Saved preference should persist to the account',
      );
      _log.info('Preferences read and save complete');
    });
  });
}
