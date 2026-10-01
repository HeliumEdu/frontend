import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/data/models/planner/grade_category_model.dart';

Map<String, dynamic> _givenGradeCategoryJson({required double pointsEarned, required double pointsPossible}) {
  return {
    'id': 1,
    'title': 'Exams',
    'overall_grade': 80.0,
    'weight': 50.0,
    'color': '#4caf50',
    'grade_by_weight': 40.0,
    'trend': null,
    'num_homework': 2,
    'num_homework_graded': 1,
    'homework_series': [],
    'points_earned': pointsEarned,
    'points_possible': pointsPossible,
  };
}

void main() {
  group('GradeCategoryModel', () {
    group('fromJson', () {
      test('parses the category point totals', () {
        // GIVEN
        final json = _givenGradeCategoryJson(pointsEarned: 40.0, pointsPossible: 50.0);

        // WHEN
        final category = GradeCategoryModel.fromJson(json);

        // THEN
        expect(category.pointsEarned, 40.0);
        expect(category.pointsPossible, 50.0);
      });
    });
  });
}
