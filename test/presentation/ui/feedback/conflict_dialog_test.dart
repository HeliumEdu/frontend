import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/feedback/conflict_dialog.dart';

void main() {
  ConflictResolution? resolution;

  Future<void> givenDialogIsOpen(WidgetTester tester) async {
    resolution = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  resolution = await confirmConflictResolution(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Load Latest resolves to loadLatest', (tester) async {
    // GIVEN
    await givenDialogIsOpen(tester);

    // WHEN
    await tester.tap(find.text('Load Latest'));
    await tester.pumpAndSettle();

    // THEN
    expect(resolution, ConflictResolution.loadLatest);
  });

  testWidgets('Overwrite resolves to overwrite', (tester) async {
    // GIVEN
    await givenDialogIsOpen(tester);

    // WHEN
    await tester.tap(find.text('Overwrite'));
    await tester.pumpAndSettle();

    // THEN
    expect(resolution, ConflictResolution.overwrite);
  });

  testWidgets('tapping outside does not dismiss it', (tester) async {
    // GIVEN
    await givenDialogIsOpen(tester);

    // WHEN
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // THEN
    expect(
      find.text('Changed on Another Device'),
      findsOneWidget,
      reason: 'Nothing may be resolved without the user choosing',
    );
    expect(resolution, isNull);
  });
}
