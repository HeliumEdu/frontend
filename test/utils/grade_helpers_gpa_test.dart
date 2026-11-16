import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/grade_scale_constants.dart';

void main() {
  final fourPoint = GradeScaleTemplate.scales[1]!;
  final plusMinus = GradeScaleTemplate.scales[2]!;
  final oneToFivePass75 = GradeScaleTemplate.scales[9]!;

  group('GradeHelper.gradePointFor matches the platform\'s grade_point_for', () {
    test('a grade at a band edge earns that band', () {
      // WHEN
      final atEdge = GradeHelper.gradePointFor(80, fourPoint);
      final belowEdge = GradeHelper.gradePointFor(79.99, fourPoint);

      // THEN
      expect(atEdge, 3.0);
      expect(belowEdge, 2.0);
    });

    test('uses the grade rounded as displayed', () {
      // WHEN
      final roundsUp = GradeHelper.gradePointFor(89.995, fourPoint);
      final roundsDown = GradeHelper.gradePointFor(89.9949, fourPoint);

      // THEN
      expect(roundsUp, 4.0, reason: '89.995 shows as 90.00, though its binary value is just under it');
      expect(roundsDown, 3.0);
    });

    test('a grade above 100 earns the top band', () {
      // WHEN
      final gradePoint = GradeHelper.gradePointFor(104.5, fourPoint);

      // THEN
      expect(gradePoint, 4.0);
    });

    test('an ungraded class has no grade point', () {
      // WHEN
      final negative = GradeHelper.gradePointFor(-1, fourPoint);
      final missing = GradeHelper.gradePointFor(null, fourPoint);
      final noScale = GradeHelper.gradePointFor(90, const []);

      // THEN
      expect(negative, isNull);
      expect(missing, isNull);
      expect(noScale, isNull);
    });

    test('works on a scale where lower is better', () {
      // WHEN
      final top = GradeHelper.gradePointFor(97, oneToFivePass75);
      final passing = GradeHelper.gradePointFor(75, oneToFivePass75);
      final failing = GradeHelper.gradePointFor(74.99, oneToFivePass75);

      // THEN
      expect(top, 1.0);
      expect(passing, 3.0);
      expect(failing, 5.0);
      expect(GradeHelper.isHigherGradePointBetter(oneToFivePass75), isFalse);
      expect(GradeHelper.isHigherGradePointBetter(fourPoint), isTrue);
    });

    test('every preset grade point falls in its band', () {
      for (final MapEntry(key: template, value: scale) in GradeScaleTemplate.scales.entries) {
        for (final band in scale) {
          // WHEN
          final gradePoint = GradeHelper.gradePointFor(band.minGrade, scale);

          // THEN
          expect(gradePoint, band.gradePoint, reason: 'preset $template at ${band.minGrade}');
        }
      }
    });
  });

  group('GradeHelper.gradeBandFor', () {
    test('gives the band a grade falls in, as displayed', () {
      // WHEN
      final atEdge = GradeHelper.gradeBandFor(87, plusMinus);
      final belowEdge = GradeHelper.gradeBandFor(86.99, plusMinus);
      final roundsUp = GradeHelper.gradeBandFor(86.995, plusMinus);

      // THEN
      expect(atEdge?.label, 'B+');
      expect(belowEdge?.label, 'B');
      expect(roundsUp?.label, 'B+');
    });

    test('an ungraded class has no band', () {
      // WHEN
      final negative = GradeHelper.gradeBandFor(-1, fourPoint);
      final noScale = GradeHelper.gradeBandFor(90, const []);

      // THEN
      expect(negative, isNull);
      expect(noScale, isNull);
    });
  });

  group('GradeHelper.gpaFor matches the platform\'s gpa_for', () {
    test('weighs classes by credits', () {
      // WHEN
      final gpa = GradeHelper.gpaFor([(credits: 3, gradePoint: 4), (credits: 1, gradePoint: 2)]);

      // THEN
      expect(gpa, 3.5);
    });

    test('leaves out classes without credits', () {
      // WHEN
      final gpa = GradeHelper.gpaFor([(credits: 3, gradePoint: 4), (credits: 0, gradePoint: 0)]);

      // THEN
      expect(gpa, 4.0);
    });

    test('has no GPA when no class has credits', () {
      // WHEN
      final gpa = GradeHelper.gpaFor([(credits: 0, gradePoint: 4), (credits: 0, gradePoint: 2)]);

      // THEN
      expect(gpa, isNull);
    });

    test('leaves out ungraded classes', () {
      // WHEN
      final gpa = GradeHelper.gpaFor([(credits: 3, gradePoint: null), (credits: 1, gradePoint: 2)]);

      // THEN
      expect(gpa, 2.0);
    });

    test('has no GPA when only ungraded classes have credits', () {
      // WHEN
      final gpa = GradeHelper.gpaFor([
        (credits: 3, gradePoint: null),
        (credits: 0, gradePoint: 4),
        (credits: 0, gradePoint: 2),
      ]);

      // THEN
      expect(gpa, isNull);
    });

    test('rounds to four places on the value the platform rounds', () {
      // WHEN
      final gpa = GradeHelper.gpaFor([
        (credits: 1.5, gradePoint: 4.0),
        (credits: 1.5, gradePoint: 3.3),
        (credits: 5, gradePoint: 4.0),
      ]);

      // THEN
      expect(gpa, 3.8687, reason: '3.86875 is stored just below the tie, which the platform rounds down');
    });

    test('rounds to four places', () {
      // WHEN
      final gpa = GradeHelper.gpaFor([(credits: 3, gradePoint: 3.7), (credits: 3, gradePoint: 3.3), (credits: 3, gradePoint: 3)]);

      // THEN
      expect(gpa, 3.3333);
    });
  });
}
