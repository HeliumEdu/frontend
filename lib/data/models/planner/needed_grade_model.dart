/// Outcome of a "What Do I Need?" calculation.
enum NeededGradeState {
  achievable,
  aboveTarget,
  unachievable,
  targetCategoryHasNoWeight,
  invalidTotalWeight;

  static NeededGradeState fromJson(String value) {
    return switch (value) {
      'achievable' => NeededGradeState.achievable,
      'above_target' => NeededGradeState.aboveTarget,
      'unachievable' => NeededGradeState.unachievable,
      'target_category_has_no_weight' =>
        NeededGradeState.targetCategoryHasNoWeight,
      'invalid_total_weight' => NeededGradeState.invalidTotalWeight,
      _ => throw ArgumentError('Unknown needed grade state: $value'),
    };
  }
}

class NeededGradeAssignmentModel {
  final int id;
  final String title;
  final double pointsPossible;
  final double neededPoints;

  NeededGradeAssignmentModel({
    required this.id,
    required this.title,
    required this.pointsPossible,
    required this.neededPoints,
  });

  factory NeededGradeAssignmentModel.fromJson(Map<String, dynamic> json) {
    return NeededGradeAssignmentModel(
      id: json['id'],
      title: json['title'],
      pointsPossible: (json['points_possible'] as num).toDouble(),
      neededPoints: (json['needed_points'] as num).toDouble(),
    );
  }
}

/// The score a class needs to reach a desired grade: on [assignment] when
/// there is one, otherwise as the average of the category solved for.
class NeededGradeModel {
  final NeededGradeState state;
  final double neededGrade;
  final bool weighted;
  final NeededGradeAssignmentModel? assignment;
  final double? totalWeightAccountedFor;

  NeededGradeModel({
    required this.state,
    required this.neededGrade,
    required this.weighted,
    this.assignment,
    this.totalWeightAccountedFor,
  });

  bool get isAchievable =>
      state == NeededGradeState.achievable ||
      state == NeededGradeState.aboveTarget;

  factory NeededGradeModel.fromJson(Map<String, dynamic> json) {
    return NeededGradeModel(
      state: NeededGradeState.fromJson(json['state']),
      neededGrade: (json['needed_grade'] as num).toDouble(),
      weighted: json['weighted'],
      assignment: json['assignment'] == null
          ? null
          : NeededGradeAssignmentModel.fromJson(
              json['assignment'] as Map<String, dynamic>,
            ),
      totalWeightAccountedFor: (json['total_weight_accounted_for'] as num?)
          ?.toDouble(),
    );
  }
}
