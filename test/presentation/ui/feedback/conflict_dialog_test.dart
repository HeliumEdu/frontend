import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/ui/feedback/conflict_dialog.dart';

void main() {
  ConflictResolution? resolution;

  Future<void> givenDialogIsOpen(
    WidgetTester tester, {
    bool canKeepEditing = false,
  }) async {
    resolution = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  resolution = await confirmConflictResolution(
                    context,
                    canKeepEditing: canKeepEditing,
                  ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Discard Changes resolves to loadLatest', (tester) async {
    // GIVEN
    await givenDialogIsOpen(tester);

    // WHEN
    await tester.tap(find.text('Discard Changes'));
    await tester.pumpAndSettle();

    // THEN
    expect(resolution, ConflictResolution.loadLatest);
  });

  testWidgets('Save Changes resolves to overwrite', (tester) async {
    // GIVEN
    await givenDialogIsOpen(tester);

    // WHEN
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // THEN
    expect(resolution, ConflictResolution.overwrite);
  });

  testWidgets('Keep Editing resolves to keepEditing', (tester) async {
    // GIVEN
    await givenDialogIsOpen(tester, canKeepEditing: true);

    // WHEN
    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();

    // THEN
    expect(resolution, ConflictResolution.keepEditing);
  });

  testWidgets('all three choices fit a phone-width dialog', (tester) async {
    // GIVEN
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // WHEN
    await givenDialogIsOpen(tester, canKeepEditing: true);

    // THEN
    expect(tester.takeException(), isNull);
    final save = tester.getRect(find.text('Save Changes'));
    final discard = tester.getRect(find.text('Discard Changes'));
    final keepEditing = tester.getRect(find.text('Keep Editing'));
    expect(keepEditing.center.dy, discard.center.dy);
    expect(save.top, greaterThan(discard.bottom),
        reason: 'Saving, the answer the message asks about, has its own row');
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
