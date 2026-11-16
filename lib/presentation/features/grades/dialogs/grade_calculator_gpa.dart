import 'package:heliumapp/data/models/planner/grade_course_group_model.dart';
import 'package:heliumapp/data/models/planner/grade_course_model.dart';
import 'package:heliumapp/data/models/planner/grade_scale_band_model.dart';
import 'package:heliumapp/utils/grade_helpers.dart';

enum GradeCalculatorMode { classGrade, termGpa }

/// What the Grade Calculator's GPA mode works from: a class's grade scale and
/// credits, the classes whose grade points make up its term's GPA, and, when
/// the term counts toward it, the classes behind the cumulative GPA.
class GradeCalculatorGpa {
  final GradeCourseModel course;
  final List<GradeCourseModel> termCourses;
  final double? termGpa;
  final List<GradeCourseModel>? cumulativeCourses;
  final double? cumulativeGpa;

  const GradeCalculatorGpa({
    required this.course,
    required this.termCourses,
    required this.termGpa,
    this.cumulativeCourses,
    this.cumulativeGpa,
  });

  /// GPA for [course] in [courseGroup], with the cumulative GPA included only
  /// when the group counts toward it alongside another group.
  factory GradeCalculatorGpa.of(
    GradeCourseModel course,
    GradeCourseGroupModel courseGroup,
    List<GradeCourseGroupModel> courseGroups,
    double? cumulativeGpa,
  ) {
    final countsTowardCumulative = courseGroup.inCumulativeGpa &&
        cumulativeGpa != null &&
        courseGroups.where((group) => group.inCumulativeGpa).length > 1;
    return GradeCalculatorGpa(
      course: course,
      termCourses: courseGroup.courses,
      termGpa: courseGroup.gpa,
      cumulativeCourses: countsTowardCumulative
          ? [
              for (final group in courseGroups)
                if (group.inCumulativeGpa) ...group.courses,
            ]
          : null,
      cumulativeGpa: countsTowardCumulative ? cumulativeGpa : null,
    );
  }

  List<GradeScaleBandModel> get gradeScale => course.gradeScale;

  bool get isHigherBetter => GradeHelper.isHigherGradePointBetter(gradeScale);

  double? termGpaWith(double? gradePoint) =>
      _gpaWith(termCourses, gradePoint);

  double? cumulativeGpaWith(double? gradePoint) => cumulativeCourses == null
      ? null
      : _gpaWith(cumulativeCourses!, gradePoint);

  bool holdsOrImproves(double from, double to) =>
      isHigherBetter ? to >= from : to <= from;

  double? _gpaWith(List<GradeCourseModel> courses, double? gradePoint) =>
      GradeHelper.gpaFor([
        for (final other in courses)
          (
            credits: other.credits,
            gradePoint: other.id == course.id ? gradePoint : other.gradePoint,
          ),
      ]);
}
