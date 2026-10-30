abstract class GradeEvent {}

class FetchGradeScreenDataEvent extends GradeEvent {
  final bool forceRefresh;

  FetchGradeScreenDataEvent({this.forceRefresh = false});
}

class CalculateNeededGradeEvent extends GradeEvent {
  final int courseId;
  final int targetId;
  final double desiredGrade;

  CalculateNeededGradeEvent({
    required this.courseId,
    required this.targetId,
    required this.desiredGrade,
  });
}

/// Clears all grade state. Dispatched on logout so per-user data does not
/// carry into the next session.
class ResetGradesEvent extends GradeEvent {}
