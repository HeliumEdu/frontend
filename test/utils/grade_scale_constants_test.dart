import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/grade_scale_constants.dart';

void main() {
  group('GradeScaleTemplate', () {
    test('every preset but None has a scale that starts at 0 and ascends', () {
      // WHEN/THEN
      expect(GradeScaleTemplate.scales.keys, GradeScaleTemplate.labels.keys);
      expect(GradeScaleTemplate.scales[GradeScaleTemplate.none], isEmpty);
      for (final template in GradeScaleTemplate.labels.keys) {
        if (template == GradeScaleTemplate.none) continue;
        final scale = GradeScaleTemplate.scales[template]!;
        expect(scale.first.minGrade, 0, reason: '$template');
        for (var i = 1; i < scale.length; i++) {
          expect(
            scale[i].minGrade,
            greaterThan(scale[i - 1].minGrade),
            reason: '$template',
          );
        }
      }
    });

    test('offers every preset but not Custom', () {
      // WHEN
      final ids = GradeScaleTemplate.items.map((item) => item.id).toList();

      // THEN
      expect(ids, GradeScaleTemplate.labels.keys.toList());
      expect(ids, isNot(contains(GradeScaleTemplate.custom)));
    });

    test('summarizes a scale by its preset, or as Custom', () {
      // WHEN/THEN
      for (final MapEntry(key: template, value: label) in GradeScaleTemplate.labels.entries) {
        expect(GradeScaleTemplate.summaryLabel(template), label);
      }
      expect(
        GradeScaleTemplate.summaryLabel(GradeScaleTemplate.custom),
        'Custom',
      );
    });
  });
}
