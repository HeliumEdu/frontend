import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/presentation/features/grades/widgets/grade_trend_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;

import '../../../../mocks/mock_models.dart';

charts.LineSeries<GradeTrendPoint, DateTime> _series(
  List<GradeTrendPoint> points,
) {
  return charts.LineSeries<GradeTrendPoint, DateTime>(
    dataSource: points,
    xValueMapper: (point, _) => point.date,
    yValueMapper: (point, _) => point.grade,
  );
}

GradeTrendPoint _point(DateTime date, double grade) =>
    GradeTrendPoint(date: date, grade: grade);

void main() {
  group('GradeTrendChart', () {
    group('calculateYAxisRange', () {
      test('with no visible series the axis spans 0 to 100', () {
        // WHEN
        final range = GradeTrendChart.calculateYAxisRange([]);

        // THEN
        expect(range.min, 0);
        expect(range.max, 100);
      });

      test(
        'the axis floor sits below the lowest grade by the headroom above the highest',
        () {
          // GIVEN
          final series = [
            _series([
              _point(DateTime(2025, 9, 1), 82),
              _point(DateTime(2025, 9, 8), 95),
            ]),
            _series([_point(DateTime(2025, 9, 3), 70.5)]),
          ];

          // WHEN
          final range = GradeTrendChart.calculateYAxisRange(series);

          // THEN
          expect(
            range.min,
            60,
            reason: '70.5 - (100 - 95) - 5 = 60.5, floored',
          );
          expect(range.max, 100);
        },
      );

      test('a wide grade spread clamps the floor at 0', () {
        // GIVEN
        final series = [
          _series([
            _point(DateTime(2025, 9, 1), 10),
            _point(DateTime(2025, 9, 8), 50),
          ]),
        ];

        // WHEN
        final range = GradeTrendChart.calculateYAxisRange(series);

        // THEN
        expect(range.min, 0);
      });
    });

    group('calculateXAxisRange', () {
      final courseGroup = MockModels.createCourseGroup(
        startDate: DateTime(2025, 8, 25),
        endDate: DateTime(2025, 12, 15),
      );
      final series = [
        _series([
          _point(DateTime(2025, 9, 10), 90),
          _point(DateTime(2025, 10, 2), 85),
        ]),
        _series([_point(DateTime(2025, 9, 3), 70)]),
      ];

      test('without auto-adjust the axis spans the whole term', () {
        // WHEN
        final range = GradeTrendChart.calculateXAxisRange(
          series,
          courseGroup,
          autoAdjustToGradedRange: false,
        );

        // THEN
        expect(range.min, courseGroup.startDate);
        expect(range.max, courseGroup.endDate);
      });

      test(
        'with auto-adjust the axis spans the earliest to latest graded point across series',
        () {
          // WHEN
          final range = GradeTrendChart.calculateXAxisRange(
            series,
            courseGroup,
            autoAdjustToGradedRange: true,
          );

          // THEN
          expect(range.min, DateTime(2025, 9, 3));
          expect(range.max, DateTime(2025, 10, 2));
        },
      );

      test(
        'with auto-adjust but no points the axis falls back to the whole term',
        () {
          // WHEN
          final range = GradeTrendChart.calculateXAxisRange(
            [_series([])],
            courseGroup,
            autoAdjustToGradedRange: true,
          );

          // THEN
          expect(range.min, courseGroup.startDate);
          expect(range.max, courseGroup.endDate);
        },
      );
    });
  });
}
