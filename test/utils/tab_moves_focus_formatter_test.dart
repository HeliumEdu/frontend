import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/tab_moves_focus_formatter.dart';

TextEditingValue _value(String text, TextSelection selection) =>
    TextEditingValue(text: text, selection: selection);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TabMovesFocusFormatter', () {
    test('a tab typed at the caret is dropped', () {
      // GIVEN
      final before = _value('Essay', const TextSelection.collapsed(offset: 5));
      final after = _value('Essay\t', const TextSelection.collapsed(offset: 6));

      // WHEN
      final result = const TabMovesFocusFormatter().formatEditUpdate(before, after);

      // THEN
      expect(result, before);
    });

    test('a tab typed over a selection is dropped', () {
      // GIVEN
      final before = _value('Essay', const TextSelection(baseOffset: 0, extentOffset: 5));
      final after = _value('\t', const TextSelection.collapsed(offset: 1));

      // WHEN
      final result = const TabMovesFocusFormatter().formatEditUpdate(before, after);

      // THEN
      expect(result, before);
    });

    test('other typing passes through', () {
      // GIVEN
      final before = _value('Essa', const TextSelection.collapsed(offset: 4));
      final after = _value('Essay', const TextSelection.collapsed(offset: 5));

      // WHEN
      final result = const TabMovesFocusFormatter().formatEditUpdate(before, after);

      // THEN
      expect(result, after);
    });

    test('pasted text that contains a tab passes through', () {
      // GIVEN
      final before = _value('', const TextSelection.collapsed(offset: 0));
      final after = _value('a\tb', const TextSelection.collapsed(offset: 3));

      // WHEN
      final result = const TabMovesFocusFormatter().formatEditUpdate(before, after);

      // THEN
      expect(result, after, reason: 'Only a lone typed tab moves focus');
    });
  });
}
