import 'package:heliumapp/utils/conversion_helpers.dart';

class GradeScaleBandModel {
  final double minGrade;
  final double gradePoint;
  final String label;

  const GradeScaleBandModel({
    required this.minGrade,
    required this.gradePoint,
    required this.label,
  });

  factory GradeScaleBandModel.fromJson(Map<String, dynamic> json) {
    return GradeScaleBandModel(
      minGrade: toDouble(json['min_grade'])!,
      gradePoint: toDouble(json['grade_point'])!,
      label: json['label'],
    );
  }

  static List<GradeScaleBandModel> listFromJson(dynamic json) {
    return (json as List<dynamic>)
        .map(
          (band) => GradeScaleBandModel.fromJson(band as Map<String, dynamic>),
        )
        .toList();
  }
}
