import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/utils/conversion_helpers.dart';

class GradesModel {
  final List<GradeCourseGroupModel> courseGroups;
  final double? cumulativeGpa;

  GradesModel({required this.courseGroups, this.cumulativeGpa});

  factory GradesModel.fromJson(Map<String, dynamic> json) {
    return GradesModel(
      courseGroups: (json['course_groups'] as List<dynamic>)
          .map(
            (group) =>
                GradeCourseGroupModel.fromJson(group as Map<String, dynamic>),
          )
          .toList(),
      cumulativeGpa: toGradedDouble(json['cumulative_gpa']),
    );
  }
}
