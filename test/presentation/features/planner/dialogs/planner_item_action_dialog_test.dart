import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/l10n/app_localizations.dart';
import 'package:heliumapp/presentation/features/planner/dialogs/planner_item_action_dialog.dart';

void main() {
  Future<void> givenMenuIsOpen(WidgetTester tester, String whenLabel) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPlannerItemActionDialog(
                context: context,
                icon: Icons.school,
                title: 'Biology 101',
                color: Colors.blue,
                whenLabel: whenLabel,
                actions: const [],
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

  testWidgets('the header shows when the occurrence is', (tester) async {
    // GIVEN
    await givenMenuIsOpen(tester, 'Wed, Nov 18 • 2 PM');

    // THEN
    expect(find.text('Wed, Nov 18 • 2 PM'), findsOneWidget);
  });
}
