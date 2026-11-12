// AUTO-GENERATED — DO NOT EDIT.
// Written from platform/helium/common/enums.py by:
//   platform/bin/sync-shared-constants.py

import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/data/models/planner/grade_scale_band_model.dart';

class GradeScaleTemplate {
  GradeScaleTemplate._();

  static const int none = 0;

  static const int custom = -1;

  static const Map<int, String> labels = {
    0: 'None',
    1: '4.0',
    2: '4.0 with +/-',
    3: '4.33 with +/-',
    4: '4.5',
    5: '7.0',
    6: '9.0',
    7: '10.0',
    8: '1.0-5.0 (pass at 50%)',
    9: '1.0-5.0 (pass at 75%)',
  };

  static const Map<int, List<GradeScaleBandModel>> scales = {
    0: [],
    1: [
      GradeScaleBandModel(minGrade: 0.0, gradePoint: 0.0, label: 'F'),
      GradeScaleBandModel(minGrade: 60.0, gradePoint: 1.0, label: 'D'),
      GradeScaleBandModel(minGrade: 70.0, gradePoint: 2.0, label: 'C'),
      GradeScaleBandModel(minGrade: 80.0, gradePoint: 3.0, label: 'B'),
      GradeScaleBandModel(minGrade: 90.0, gradePoint: 4.0, label: 'A'),
    ],
    2: [
      GradeScaleBandModel(minGrade: 0.0, gradePoint: 0.0, label: 'F'),
      GradeScaleBandModel(minGrade: 60.0, gradePoint: 0.7, label: 'D-'),
      GradeScaleBandModel(minGrade: 63.0, gradePoint: 1.0, label: 'D'),
      GradeScaleBandModel(minGrade: 67.0, gradePoint: 1.3, label: 'D+'),
      GradeScaleBandModel(minGrade: 70.0, gradePoint: 1.7, label: 'C-'),
      GradeScaleBandModel(minGrade: 73.0, gradePoint: 2.0, label: 'C'),
      GradeScaleBandModel(minGrade: 77.0, gradePoint: 2.3, label: 'C+'),
      GradeScaleBandModel(minGrade: 80.0, gradePoint: 2.7, label: 'B-'),
      GradeScaleBandModel(minGrade: 83.0, gradePoint: 3.0, label: 'B'),
      GradeScaleBandModel(minGrade: 87.0, gradePoint: 3.3, label: 'B+'),
      GradeScaleBandModel(minGrade: 90.0, gradePoint: 3.7, label: 'A-'),
      GradeScaleBandModel(minGrade: 93.0, gradePoint: 4.0, label: 'A'),
      GradeScaleBandModel(minGrade: 97.0, gradePoint: 4.0, label: 'A+'),
    ],
    3: [
      GradeScaleBandModel(minGrade: 0.0, gradePoint: 0.0, label: 'F'),
      GradeScaleBandModel(minGrade: 60.0, gradePoint: 0.7, label: 'D-'),
      GradeScaleBandModel(minGrade: 63.0, gradePoint: 1.0, label: 'D'),
      GradeScaleBandModel(minGrade: 67.0, gradePoint: 1.3, label: 'D+'),
      GradeScaleBandModel(minGrade: 70.0, gradePoint: 1.7, label: 'C-'),
      GradeScaleBandModel(minGrade: 73.0, gradePoint: 2.0, label: 'C'),
      GradeScaleBandModel(minGrade: 77.0, gradePoint: 2.3, label: 'C+'),
      GradeScaleBandModel(minGrade: 80.0, gradePoint: 2.7, label: 'B-'),
      GradeScaleBandModel(minGrade: 83.0, gradePoint: 3.0, label: 'B'),
      GradeScaleBandModel(minGrade: 87.0, gradePoint: 3.3, label: 'B+'),
      GradeScaleBandModel(minGrade: 90.0, gradePoint: 3.7, label: 'A-'),
      GradeScaleBandModel(minGrade: 93.0, gradePoint: 4.0, label: 'A'),
      GradeScaleBandModel(minGrade: 97.0, gradePoint: 4.33, label: 'A+'),
    ],
    4: [
      GradeScaleBandModel(minGrade: 0.0, gradePoint: 0.0, label: 'F'),
      GradeScaleBandModel(minGrade: 60.0, gradePoint: 1.0, label: 'D'),
      GradeScaleBandModel(minGrade: 65.0, gradePoint: 1.5, label: 'D+'),
      GradeScaleBandModel(minGrade: 70.0, gradePoint: 2.0, label: 'C'),
      GradeScaleBandModel(minGrade: 75.0, gradePoint: 2.5, label: 'C+'),
      GradeScaleBandModel(minGrade: 80.0, gradePoint: 3.0, label: 'B'),
      GradeScaleBandModel(minGrade: 85.0, gradePoint: 3.5, label: 'B+'),
      GradeScaleBandModel(minGrade: 90.0, gradePoint: 4.0, label: 'A'),
      GradeScaleBandModel(minGrade: 95.0, gradePoint: 4.5, label: 'A+'),
    ],
    5: [
      GradeScaleBandModel(minGrade: 0.0, gradePoint: 0.0, label: 'F'),
      GradeScaleBandModel(minGrade: 50.0, gradePoint: 4.0, label: 'P'),
      GradeScaleBandModel(minGrade: 65.0, gradePoint: 5.0, label: 'C'),
      GradeScaleBandModel(minGrade: 75.0, gradePoint: 6.0, label: 'D'),
      GradeScaleBandModel(minGrade: 85.0, gradePoint: 7.0, label: 'HD'),
    ],
    6: [
      GradeScaleBandModel(minGrade: 0.0, gradePoint: 0.0, label: 'D'),
      GradeScaleBandModel(minGrade: 50.0, gradePoint: 1.0, label: 'C-'),
      GradeScaleBandModel(minGrade: 55.0, gradePoint: 2.0, label: 'C'),
      GradeScaleBandModel(minGrade: 60.0, gradePoint: 3.0, label: 'C+'),
      GradeScaleBandModel(minGrade: 65.0, gradePoint: 4.0, label: 'B-'),
      GradeScaleBandModel(minGrade: 70.0, gradePoint: 5.0, label: 'B'),
      GradeScaleBandModel(minGrade: 75.0, gradePoint: 6.0, label: 'B+'),
      GradeScaleBandModel(minGrade: 80.0, gradePoint: 7.0, label: 'A-'),
      GradeScaleBandModel(minGrade: 85.0, gradePoint: 8.0, label: 'A'),
      GradeScaleBandModel(minGrade: 90.0, gradePoint: 9.0, label: 'A+'),
    ],
    7: [
      GradeScaleBandModel(minGrade: 0.0, gradePoint: 0.0, label: 'F'),
      GradeScaleBandModel(minGrade: 40.0, gradePoint: 4.0, label: 'P'),
      GradeScaleBandModel(minGrade: 45.0, gradePoint: 5.0, label: 'C'),
      GradeScaleBandModel(minGrade: 50.0, gradePoint: 6.0, label: 'B'),
      GradeScaleBandModel(minGrade: 60.0, gradePoint: 7.0, label: 'B+'),
      GradeScaleBandModel(minGrade: 70.0, gradePoint: 8.0, label: 'A'),
      GradeScaleBandModel(minGrade: 80.0, gradePoint: 9.0, label: 'A+'),
      GradeScaleBandModel(minGrade: 90.0, gradePoint: 10.0, label: 'O'),
    ],
    8: [
      GradeScaleBandModel(minGrade: 0.0, gradePoint: 5.0, label: ''),
      GradeScaleBandModel(minGrade: 50.0, gradePoint: 4.0, label: ''),
      GradeScaleBandModel(minGrade: 55.0, gradePoint: 3.7, label: ''),
      GradeScaleBandModel(minGrade: 60.0, gradePoint: 3.3, label: ''),
      GradeScaleBandModel(minGrade: 65.0, gradePoint: 3.0, label: ''),
      GradeScaleBandModel(minGrade: 70.0, gradePoint: 2.7, label: ''),
      GradeScaleBandModel(minGrade: 75.0, gradePoint: 2.3, label: ''),
      GradeScaleBandModel(minGrade: 80.0, gradePoint: 2.0, label: ''),
      GradeScaleBandModel(minGrade: 85.0, gradePoint: 1.7, label: ''),
      GradeScaleBandModel(minGrade: 90.0, gradePoint: 1.3, label: ''),
      GradeScaleBandModel(minGrade: 95.0, gradePoint: 1.0, label: ''),
    ],
    9: [
      GradeScaleBandModel(minGrade: 0.0, gradePoint: 5.0, label: ''),
      GradeScaleBandModel(minGrade: 75.0, gradePoint: 3.0, label: ''),
      GradeScaleBandModel(minGrade: 76.0, gradePoint: 2.75, label: ''),
      GradeScaleBandModel(minGrade: 79.0, gradePoint: 2.5, label: ''),
      GradeScaleBandModel(minGrade: 82.0, gradePoint: 2.25, label: ''),
      GradeScaleBandModel(minGrade: 85.0, gradePoint: 2.0, label: ''),
      GradeScaleBandModel(minGrade: 88.0, gradePoint: 1.75, label: ''),
      GradeScaleBandModel(minGrade: 91.0, gradePoint: 1.5, label: ''),
      GradeScaleBandModel(minGrade: 94.0, gradePoint: 1.25, label: ''),
      GradeScaleBandModel(minGrade: 97.0, gradePoint: 1.0, label: ''),
    ],
  };

  static String summaryLabel(int template) =>
      template == custom ? 'Custom' : labels[template]!;

  static List<DropDownItem<int>> get items => [
    for (final entry in labels.entries)
      DropDownItem(id: entry.key, value: entry.key, label: entry.value),
  ];

  static DropDownItem<int> get customItem =>
      DropDownItem(id: custom, value: custom, label: 'Custom');
}
