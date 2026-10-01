import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';

Map<String, dynamic> _givenGradeCourseJson({required double pointsEarned, required double pointsPossible}) {
  return {
    'id': 1,
    'title': 'Intro to Psychology',
    'overall_grade': 54.5455,
    'color': '#4caf50',
    'trend': null,
    'num_homework': 3,
    'num_homework_completed': 2,
    'num_homework_graded': 2,
    'categories': [],
    'homework_series': [],
    'points_earned': pointsEarned,
    'points_possible': pointsPossible,
  };
}

void main() {
  group('GradeCourseModel', () {
    group('fromJson', () {
      test('parses the course point totals', () {
        // GIVEN
        final json = _givenGradeCourseJson(pointsEarned: 60.0, pointsPossible: 110.0);

        // WHEN
        final course = GradeCourseModel.fromJson(json);

        // THEN
        expect(course.pointsEarned, 60.0);
        expect(course.pointsPossible, 110.0);
      });
    });
  });
}
