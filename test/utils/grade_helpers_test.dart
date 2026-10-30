import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/regional_settings_notifier.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/grade_helpers.dart';

void main() {
  group('GradeHelper', () {
    group('regional number format', () {
      tearDown(() => RegionalSettingsNotifier().update(weekStartsOn: 0, dateFormat: 0, timeFormat: 0, numberFormat: 0));

      test('grades and weights display with a comma separator', () async {
        await RegionalSettingsNotifier().update(
          weekStartsOn: 0,
          dateFormat: 0,
          timeFormat: 0,
          numberFormat: RegionalFormatConstants.numberFormatComma,
        );
        expect(GradeHelper.gradeForDisplay('85.5/100'), '85,50%');
        expect(GradeHelper.percentForDisplay('12.5', false), '12,5%');
        expect(GradeHelper.percentForDisplay('20', false), '20%');
      });
    });

    group('parseGrade', () {
      test('parses numeric grades', () {
        expect(GradeHelper.parseGrade(85.5), 85.5);
        expect(GradeHelper.parseGrade(90), 90.0);
        expect(GradeHelper.parseGrade(0), 0.0);
      });

      test('parses fraction strings typed with a comma decimal separator', () {
        expect(GradeHelper.parseGrade('85,5/100'), 85.5);
        expect(GradeHelper.parseGrade('17/20,5'), closeTo(82.93, 0.01));
      });

      test('parses fraction strings to percentage', () {
        expect(GradeHelper.parseGrade('85/100'), 85.0);
        expect(GradeHelper.parseGrade('17/20'), 85.0);
        expect(GradeHelper.parseGrade('8.5/10'), 85.0);
      });

      test('returns null for ungraded markers', () {
        expect(GradeHelper.parseGrade(null), null);
        expect(GradeHelper.parseGrade(''), null);
        expect(GradeHelper.parseGrade('-1/100'), null);
        expect(GradeHelper.parseGrade(-1.0), null);
      });

      test('returns null for invalid input', () {
        expect(GradeHelper.parseGrade('invalid'), null);
        expect(GradeHelper.parseGrade('85/'), null);
      });
    });

    group('normalizeFraction', () {
      test('keeps the decimal point on both sides of a fraction', () {
        // GIVEN
        const typed = '8.5/10.25';

        // WHEN
        final normalized = GradeHelper.normalizeFraction(typed);

        // THEN
        expect(normalized, '8.5/10.25');
      });

      test('converts a comma decimal on both sides of a fraction to a point', () {
        // GIVEN
        const typed = '8,5/10,25';

        // WHEN
        final normalized = GradeHelper.normalizeFraction(typed);

        // THEN
        expect(normalized, '8.5/10.25');
      });
    });

    group('gradeForDisplay', () {
      test('formats grades as percentage with 2 decimals', () {
        expect(GradeHelper.gradeForDisplay(85.5), '85.50%');
        expect(GradeHelper.gradeForDisplay(90), '90.00%');
        expect(GradeHelper.gradeForDisplay('17/20'), '85.00%');
        expect(GradeHelper.gradeForDisplay(100.0), '100.00%');
        expect(GradeHelper.gradeForDisplay(0), '0.00%');
      });

      test('returns N/A for invalid/ungraded values', () {
        expect(GradeHelper.gradeForDisplay(null), 'N/A');
        expect(GradeHelper.gradeForDisplay(-1.0), 'N/A');
      });

      test('returns blank when showNaAsBlank is true', () {
        expect(GradeHelper.gradeForDisplay(null, true), '');
        expect(GradeHelper.gradeForDisplay('-1/100', true), '');
      });
    });

    group('percentForDisplay', () {
      test('formats percentages removing trailing zeros', () {
        expect(GradeHelper.percentForDisplay('85', null), '85%');
        expect(GradeHelper.percentForDisplay('85.5', null), '85.5%');
        expect(GradeHelper.percentForDisplay('85.50', null), '85.5%');
        expect(GradeHelper.percentForDisplay('85.00', null), '85%');
        expect(GradeHelper.percentForDisplay('0.01', null), '0.01%');
      });

      test('handles zero with zeroAsNa flag', () {
        expect(GradeHelper.percentForDisplay('0', true), 'N/A');
        expect(GradeHelper.percentForDisplay('0', false), '0%');
      });

      test('returns N/A for invalid input', () {
        expect(GradeHelper.percentForDisplay('invalid', null), 'N/A');
        expect(GradeHelper.percentForDisplay('', null), 'N/A');
      });
    });
  });
}

