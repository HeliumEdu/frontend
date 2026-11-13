import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/components/spinner_field.dart';

void main() {
  Future<List<String>> pumpSpinner(WidgetTester tester, TextEditingController controller) async {
    final changes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Form(
            child: SpinnerField(controller: controller, minValue: 1, maxValue: 99, onChanged: changes.add),
          ),
        ),
      ),
    );
    return changes;
  }

  testWidgets('typing past the maximum caps the value at it', (tester) async {
    // GIVEN
    final controller = TextEditingController(text: '1');
    final changes = await pumpSpinner(tester, controller);

    // WHEN
    await tester.enterText(find.byType(TextFormField), '500');

    // THEN
    expect(controller.text, '99');
    expect(changes.last, '99');
  });

  testWidgets('typing within the range keeps the value', (tester) async {
    // GIVEN
    final controller = TextEditingController(text: '1');
    final changes = await pumpSpinner(tester, controller);

    // WHEN
    await tester.enterText(find.byType(TextFormField), '42');

    // THEN
    expect(controller.text, '42');
    expect(changes.last, '42');
  });
}
