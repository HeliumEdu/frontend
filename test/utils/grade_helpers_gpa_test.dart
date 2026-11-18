import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/utils/grade_helpers.dart';
import 'package:heliumapp/utils/grade_scale_constants.dart';

import '../mocks/mock_models.dart';

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

  group('GradeHelper.gpaAcrossTerms', () {
    test('graphs only the terms that count toward the cumulative GPA', () {
      // GIVEN
      final groups = [
        _term(1, 'Example', gpa: 4.0, inCumulativeGpa: false, exampleSchedule: true,
            classes: [(credits: 3, gradePoint: 4.0)]),
        _term(2, 'Fall 2024', gpa: 3.0, inCumulativeGpa: false, classes: [(credits: 3, gradePoint: 3.0)]),
        _term(3, 'Spring 2025', gpa: 4.0, classes: [(credits: 3, gradePoint: 4.0)]),
        _term(4, 'Fall 2025', gpa: 2.0, classes: [(credits: 1, gradePoint: 2.0)]),
      ];

      // WHEN
      final points = GradeHelper.gpaAcrossTerms(groups, priorCredits: 0, priorGpa: 0, onlyTermsWithGpa: false);

      // THEN
      expect(points, [
        (title: 'Spring 2025', termGpa: 4.0, cumulativeGpa: 4.0),
        (title: 'Fall 2025', termGpa: 2.0, cumulativeGpa: 3.5),
      ], reason: 'the example schedule and the term on another scale stay out');
    });

    test('leads with a Prior point when there are prior credits', () {
      // GIVEN
      final groups = [
        _term(1, 'Fall 2025', gpa: 4.0, classes: [(credits: 3, gradePoint: 4.0)]),
      ];

      // WHEN
      final points = GradeHelper.gpaAcrossTerms(groups, priorCredits: 60, priorGpa: 3.4, onlyTermsWithGpa: false);

      // THEN
      expect(points, [
        (title: 'Prior', termGpa: null, cumulativeGpa: 3.4),
        (title: 'Fall 2025', termGpa: 4.0, cumulativeGpa: 3.4286),
      ]);
    });

    test('has no Prior point without prior credits', () {
      // GIVEN
      final groups = [
        _term(1, 'Fall 2025', gpa: 4.0, classes: [(credits: 3, gradePoint: 4.0)]),
      ];

      // WHEN
      final points = GradeHelper.gpaAcrossTerms(groups, priorCredits: 0, priorGpa: 0, onlyTermsWithGpa: false);

      // THEN
      expect(points.map((point) => point.title), ['Fall 2025']);
    });

    test('ends at the cumulative GPA the platform computes', () {
      // GIVEN
      final groups = [
        _term(1, 'Fall 2024', gpa: 3.35, classes: [(credits: 3, gradePoint: 3.7), (credits: 3, gradePoint: 3.0)]),
        _term(2, 'Spring 2025', gpa: 3.2143, classes: [
          (credits: 4, gradePoint: 3.3),
          (credits: 3, gradePoint: 3.0),
          (credits: 0, gradePoint: 4.0),
          (credits: 3, gradePoint: null),
        ]),
      ];
      final cumulativeGpa = GradeHelper.gpaFor([
        (credits: 3, gradePoint: 3.7),
        (credits: 3, gradePoint: 3.0),
        (credits: 4, gradePoint: 3.3),
        (credits: 3, gradePoint: 3.0),
        (credits: 12.5, gradePoint: 3.85),
      ]);

      // WHEN
      final points = GradeHelper.gpaAcrossTerms(groups, priorCredits: 12.5, priorGpa: 3.85, onlyTermsWithGpa: false);

      // THEN
      expect(points.last.cumulativeGpa, cumulativeGpa);
      expect(points.last.cumulativeGpa, 3.5461);
    });

    test('keeps a term with no GPA yet as an empty slot', () {
      // GIVEN
      final groups = [
        _term(1, 'Fall 2024', gpa: 3.0, classes: [(credits: 3, gradePoint: 3.0)]),
        _term(2, 'Spring 2025', classes: [(credits: 3, gradePoint: null)]),
        _term(3, 'Fall 2025', gpa: 4.0, classes: [(credits: 3, gradePoint: 4.0)]),
      ];

      // WHEN
      final points = GradeHelper.gpaAcrossTerms(groups, priorCredits: 0, priorGpa: 0, onlyTermsWithGpa: false);

      // THEN
      expect(points, [
        (title: 'Fall 2024', termGpa: 3.0, cumulativeGpa: 3.0),
        (title: 'Spring 2025', termGpa: null, cumulativeGpa: null),
        (title: 'Fall 2025', termGpa: 4.0, cumulativeGpa: 3.5),
      ]);
    });

    test('leaves out a term with no GPA yet when only terms with a GPA are shown', () {
      // GIVEN
      final groups = [
        _term(1, 'Fall 2024', gpa: 3.0, classes: [(credits: 3, gradePoint: 3.0)]),
        _term(2, 'Spring 2025', classes: [(credits: 3, gradePoint: null)]),
        _term(3, 'Fall 2025', gpa: 4.0, classes: [(credits: 3, gradePoint: 4.0)]),
      ];

      // WHEN
      final points = GradeHelper.gpaAcrossTerms(groups, priorCredits: 60, priorGpa: 3.4, onlyTermsWithGpa: true);

      // THEN
      expect(points.map((point) => point.title), ['Prior', 'Fall 2024', 'Fall 2025'],
          reason: 'the Prior point stays, as it always has a GPA');
    });
  });
}

GradeCourseGroupModel _term(
  int id,
  String title, {
  double? gpa,
  bool inCumulativeGpa = true,
  bool exampleSchedule = false,
  List<({double credits, double? gradePoint})> classes = const [],
}) => MockModels.createGradeCourseGroup(
  id: id,
  title: title,
  gpa: gpa,
  inCumulativeGpa: inCumulativeGpa,
  exampleSchedule: exampleSchedule,
  courses: [
    for (final (index, gradedClass) in classes.indexed)
      MockModels.createGradeCourse(
        id: id * 100 + index,
        credits: gradedClass.credits,
        gradePoint: gradedClass.gradePoint,
      ),
  ],
);
