import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_router.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/presentation/core/dialogs/whats_new_dialog.dart';

void main() {
  setUpAll(initializeRouter);

  Future<void> pumpDialog(WidgetTester tester, {required int versionSeen}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showWhatsNewDialog(context, versionSeen: versionSeen),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists only the items released since the version last seen', (tester) async {
    // GIVEN
    const versionSeen = 13;

    // WHEN
    await pumpDialog(tester, versionSeen: versionSeen);

    // THEN
    expect(find.text('Repeating Assignments & Events'), findsOneWidget);
    expect(find.text('GPA Tracking'), findsOneWidget);
    expect(find.text('Class Notes & Resource Attachments'), findsNothing);
    expect(find.text('Your Planner, Your Way'), findsNothing);
  });

  testWidgets('lists the newest item alone when only it is unseen', (tester) async {
    // GIVEN
    const versionSeen = 14;

    // WHEN
    await pumpDialog(tester, versionSeen: versionSeen);

    // THEN
    expect(find.text('Repeating Assignments & Events'), findsOneWidget);
    expect(find.text('GPA Tracking'), findsNothing);
  });

  testWidgets('lists every item for a user who has never seen What\'s New', (tester) async {
    // GIVEN
    const versionSeen = 0;

    // WHEN
    await pumpDialog(tester, versionSeen: versionSeen);

    // THEN
    expect(find.text('Repeating Assignments & Events'), findsOneWidget);
    expect(find.text('GPA Tracking'), findsOneWidget);
    expect(find.text('Class Notes & Resource Attachments'), findsOneWidget);
    expect(find.text('Your Planner, Your Way'), findsOneWidget);
  });
}
