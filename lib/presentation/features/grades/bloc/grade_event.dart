abstract class GradeEvent {}

class FetchGradeScreenDataEvent extends GradeEvent {
  final bool forceRefresh;
  final bool background;

  FetchGradeScreenDataEvent({this.forceRefresh = false, this.background = false});
}

class CalculateNeededGradeEvent extends GradeEvent {
  final int courseId;
  final int targetId;
  final double? desiredGrade;
  final double? desiredGpa;

  CalculateNeededGradeEvent({
    required this.courseId,
    required this.targetId,
    this.desiredGrade,
    this.desiredGpa,
  }) : assert((desiredGrade == null) != (desiredGpa == null));
}

/// Clears all grade state. Dispatched on logout so per-user data does not
/// carry into the next session.
class ResetGradesEvent extends GradeEvent {}
