import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/presentation/ui/components/helium_quill_toolbar.dart';

void main() {
  group('toolbarRows with 40pt buttons and 1pt dividers', () {
    const widths = [40.0, 40.0, 1.0, 40.0, 40.0, 1.0, 40.0, 40.0];
    const dividers = [false, false, true, false, false, true, false, false];

    bool startsOrEndsWithDivider(List<int> row) {
      final items = row.where((index) => index >= 0).toList();
      return items.isNotEmpty &&
          (dividers[items.first] || dividers[items.last]);
    }

    test('puts everything in one row, without a toggle, when it fits', () {
      // WHEN
      final layout = toolbarRows(
        widths: widths,
        dividers: dividers,
        toggleWidth: 40,
        maxWidth: 400,
        expanded: true,
      );

      // THEN
      expect(layout.fold, isNull);
      expect(layout.rows, [
        [0, 1, 2, 3, 4, 5, 6, 7],
      ]);
    });

    test('drops a divider that would sit just before the toggle', () {
      // WHEN
      final layout = toolbarRows(
        widths: widths,
        dividers: dividers,
        toggleWidth: 40,
        maxWidth: 150,
        expanded: false,
      );

      // THEN
      expect(
        layout.fold,
        3,
        reason: '40 + 8 + 40 + 8 + 1 + 8 + 40 (toggle) = 145 fits in 150',
      );
      expect(layout.rows, [
        [0, 1, -1],
      ]);
    });

    test('opens into rows that never start or end with a divider', () {
      // WHEN
      final layout = toolbarRows(
        widths: widths,
        dividers: dividers,
        toggleWidth: 40,
        maxWidth: 150,
        expanded: true,
      );

      // THEN
      expect(
        layout.rows.first.last,
        -1,
        reason: 'the toggle ends the first row',
      );
      expect(layout.rows.where(startsOrEndsWithDivider), isEmpty);
      expect(
        layout.rows
            .expand((row) => row)
            .where((index) => index >= 0 && !dividers[index])
            .length,
        6,
        reason: 'every button is shown',
      );
    });
  });
}
