import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/reminder_model.dart';
import 'package:heliumapp/config/regional_settings_notifier.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/format_helpers.dart';

void main() {
  group('format helpers', () {
    group('reminderOffset', () {
      test('formats singular minute offset', () {
        final reminder = _createReminder(offset: 1, offsetType: 0);
        expect(reminderOffset(reminder), '1 minute');
      });

      test('formats plural minutes offset', () {
        final reminder = _createReminder(offset: 15, offsetType: 0);
        expect(reminderOffset(reminder), '15 minutes');
      });

      test('formats singular hour offset', () {
        final reminder = _createReminder(offset: 1, offsetType: 1);
        expect(reminderOffset(reminder), '1 hour');
      });

      test('formats plural hours offset', () {
        final reminder = _createReminder(offset: 2, offsetType: 1);
        expect(reminderOffset(reminder), '2 hours');
      });

      test('formats singular day offset', () {
        final reminder = _createReminder(offset: 1, offsetType: 2);
        expect(reminderOffset(reminder), '1 day');
      });

      test('formats plural days offset', () {
        final reminder = _createReminder(offset: 3, offsetType: 2);
        expect(reminderOffset(reminder), '3 days');
      });

      test('formats singular week offset', () {
        final reminder = _createReminder(offset: 1, offsetType: 3);
        expect(reminderOffset(reminder), '1 week');
      });

      test('formats plural weeks offset', () {
        final reminder = _createReminder(offset: 2, offsetType: 3);
        expect(reminderOffset(reminder), '2 weeks');
      });
    });
  });

  group('PluralExtension', () {
    test('returns plural for 0', () {
      expect(0.plural('item'), 'items');
    });

    test('returns singular for 1', () {
      expect(1.plural('item'), 'item');
    });

    test('returns plural for 2', () {
      expect(2.plural('item'), 'items');
    });

    test('uses custom plural word', () {
      expect(2.plural('box', 'boxes'), 'boxes');
    });
  });
  group('HeliumNumber', () {
    group('detectNumberFormat', () {
      test('detects a point for US, UK, and Japanese locales', () {
        for (final locale in [const Locale('en', 'US'), const Locale('en', 'GB'), const Locale('ja', 'JP')]) {
          expect(HeliumNumber.detectNumberFormat(locale), RegionalFormatConstants.numberFormatPoint,
              reason: locale.toString());
        }
      });

      test('detects a comma for German, French, and Brazilian locales', () {
        for (final locale in [const Locale('de', 'DE'), const Locale('fr', 'FR'), const Locale('pt', 'BR')]) {
          expect(HeliumNumber.detectNumberFormat(locale), RegionalFormatConstants.numberFormatComma,
              reason: locale.toString());
        }
      });

      test('falls back to a point for an unknown locale', () {
        expect(HeliumNumber.detectNumberFormat(const Locale('xx', 'XX')), FallbackConstants.defaultNumberFormat);
      });
    });

    group('parse', () {
      test('accepts a point or a comma as the decimal separator', () {
        expect(HeliumNumber.parse('85.5'), 85.5);
        expect(HeliumNumber.parse('85,5'), 85.5);
        expect(HeliumNumber.parse(' 3 '), 3);
      });

      test('reads grouped numbers in either format', () {
        expect(HeliumNumber.parse('1,234.5'), 1234.5);
        expect(HeliumNumber.parse('1.234,5'), 1234.5);
        expect(HeliumNumber.parse('1,234,567'), 1234567);
        expect(HeliumNumber.parse('1.234.567,89'), 1234567.89);
      });

      test('rejects text with no digits', () {
        expect(HeliumNumber.parse(''), isNull);
        expect(HeliumNumber.parse('abc'), isNull);
      });
    });

    group('normalize', () {
      test('canonicalises a comma to a point without parsing', () {
        expect(HeliumNumber.normalize(' 85,5/100 '), '85.5/100');
        expect(HeliumNumber.normalize('85.5'), '85.5');
      });
    });

    group('format', () {
      Future<void> useSeparator(int numberFormat) => RegionalSettingsNotifier().update(
            weekStartsOn: 0,
            dateFormat: 0,
            timeFormat: 0,
            numberFormat: numberFormat,
          );

      tearDown(() => useSeparator(RegionalFormatConstants.numberFormatPoint));

      test('fixes precision and trims trailing zeros on request', () async {
        await useSeparator(RegionalFormatConstants.numberFormatPoint);
        expect(HeliumNumber.format(85.5, fractionDigits: 2), '85.50');
        expect(HeliumNumber.format(85.0, fractionDigits: 2, trimZeros: true), '85');
        expect(HeliumNumber.format(85.5, fractionDigits: 2, trimZeros: true), '85.5');
        expect(HeliumNumber.format(3.0, trimZeros: true), '3');
        expect(HeliumNumber.format(2.5), '2.5');
      });

      test('groups thousands with the regional separators', () async {
        await useSeparator(RegionalFormatConstants.numberFormatPoint);
        expect(HeliumNumber.format(1234.5, fractionDigits: 1), '1,234.5');
        await useSeparator(RegionalFormatConstants.numberFormatComma);
        expect(HeliumNumber.format(85.5, fractionDigits: 2), '85,50');
        expect(HeliumNumber.format(1234.5, fractionDigits: 1), '1.234,5');
        expect(HeliumNumber.format(85.0, trimZeros: true), '85');
      });

      test('round-trips through parse in either format', () async {
        for (final numberFormat in RegionalFormatConstants.numberFormats) {
          await useSeparator(numberFormat);
          expect(HeliumNumber.parse(HeliumNumber.format(1234.5, fractionDigits: 1)), 1234.5);
          expect(HeliumNumber.parse(HeliumNumber.format(85.5, fractionDigits: 2)), 85.5);
        }
      });
    });

    group('numberFormatExample', () {
      test('renders the separator for each format', () {
        expect(HeliumNumber.numberFormatExample(RegionalFormatConstants.numberFormatPoint), '1,234.5');
        expect(HeliumNumber.numberFormatExample(RegionalFormatConstants.numberFormatComma), '1.234,5');
      });
    });
  });
}

ReminderModel _createReminder({required int offset, required int offsetType}) {
  return ReminderModel(
    id: 1,
    message: 'Test message',
    startOfRange: DateTime.parse('2025-01-01T10:00:00Z'),
    offset: offset,
    offsetType: offsetType,
    type: 0,
    sent: false,
    dismissed: false,
  );
}
