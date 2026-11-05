import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/id_or_entity.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/presentation/features/planner/widgets/planner_item_meta_row.dart';

import '../../../../mocks/mock_models.dart';

void main() {
  HomeworkModel givenHomeworkWithOwnAttachments(int count) {
    return MockModels.createHomework(id: 1).copyWith(
      attachments: [
        for (var i = 0; i < count; i++)
          IdOrEntity<AttachmentModel>(
            id: i,
            entity: MockModels.createAttachment(id: i, homework: 1),
          ),
      ],
    );
  }

  Future<void> givenMetaRow(
    WidgetTester tester, {
    required HomeworkModel homework,
    int pulledThroughAttachmentCount = 0,
    void Function(BuildContext anchorContext)? onOpenAttachments,
    VoidCallback? onRowTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: GestureDetector(
            onTap: onRowTap,
            child: PlannerItemMetaRow(
              plannerItem: homework,
              userSettings: MockModels.createUserSettings(),
              countTextStyle: const TextStyle(),
              pulledThroughAttachmentCount: pulledThroughAttachmentCount,
              onOpenAttachments: onOpenAttachments,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows own plus pulled-through attachments as one count', (tester) async {
    // GIVEN
    final homework = givenHomeworkWithOwnAttachments(1);

    // WHEN
    await givenMetaRow(tester, homework: homework, pulledThroughAttachmentCount: 2);

    // THEN
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('shows a pulled-through-only count when the item has none of its own',
      (tester) async {
    // GIVEN
    final homework = givenHomeworkWithOwnAttachments(0);

    // WHEN
    final hasAny = PlannerItemMetaRow.hasAny(homework, pulledThroughAttachmentCount: 2);
    await givenMetaRow(tester, homework: homework, pulledThroughAttachmentCount: 2);

    // THEN
    expect(hasAny, isTrue);
    expect(find.byIcon(Icons.attachment), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('tapping the paperclip opens attachments without tapping the row',
      (tester) async {
    // GIVEN
    BuildContext? anchor;
    var rowTapped = false;
    await givenMetaRow(
      tester,
      homework: givenHomeworkWithOwnAttachments(1),
      onOpenAttachments: (anchorContext) => anchor = anchorContext,
      onRowTap: () => rowTapped = true,
    );

    // WHEN
    await tester.tap(find.byIcon(Icons.attachment));
    await tester.pump();

    // THEN
    expect(anchor, isNotNull);
    expect(rowTapped, isFalse, reason: 'The paperclip takes the tap');
  });

  testWidgets('without a callback the paperclip is not interactive', (tester) async {
    // GIVEN
    var rowTapped = false;
    await givenMetaRow(
      tester,
      homework: givenHomeworkWithOwnAttachments(1),
      onRowTap: () => rowTapped = true,
    );

    // WHEN
    await tester.tap(find.byIcon(Icons.attachment));
    await tester.pump();

    // THEN
    expect(find.byTooltip('Show attachments'), findsNothing);
    expect(rowTapped, isTrue, reason: 'A tooltip row passes taps through');
  });

  testWidgets('counts only the resources it is given, and tapping them opens resources',
      (tester) async {
    // GIVEN
    final homework = MockModels.createHomework(id: 1, resourceIds: [20, 21, 22]);
    BuildContext? anchor;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: PlannerItemMetaRow(
              plannerItem: homework,
              userSettings: MockModels.createUserSettings(),
              countTextStyle: const TextStyle(),
              resources: [
                MockModels.createResource(id: 20),
                MockModels.createResource(id: 21),
              ],
              onOpenResources: (anchorContext) => anchor = anchorContext,
            ),
          ),
        ),
      ),
    );

    // WHEN
    await tester.tap(find.byIcon(Icons.book_outlined));

    // THEN
    expect(find.text('2'), findsOneWidget,
        reason: 'a resource in a hidden group stays linked but isn\'t counted');
    expect(anchor, isNotNull);
  });

  testWidgets('tappable icons fit the same width and a todos row height', (tester) async {
    // GIVEN
    final homework = MockModels.createHomework(id: 1, resourceIds: [20, 21]).copyWith(
      attachments: [
        IdOrEntity<AttachmentModel>(
          id: 1,
          entity: MockModels.createAttachment(id: 1, homework: 1),
        ),
      ],
    );
    final resources = [
      MockModels.createResource(id: 20),
      MockModels.createResource(id: 21),
    ];
    Future<Size> metaRowSize({required bool tappable}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: PlannerItemMetaRow(
                plannerItem: homework,
                userSettings: MockModels.createUserSettings(),
                countTextStyle: const TextStyle(),
                onOpenAttachments: tappable ? (_) {} : null,
                resources: resources,
                onOpenResources: tappable ? (_) {} : null,
              ),
            ),
          ),
        ),
      );
      return tester.getSize(find.byType(PlannerItemMetaRow));
    }

    // WHEN
    final plain = await metaRowSize(tappable: false);
    final tappable = await metaRowSize(tappable: true);

    // THEN
    expect(tappable.width, plain.width,
        reason: 'the todos meta column is a fixed width, so a wider row overflows it');
    expect(tappable.height, lessThanOrEqualTo(50),
        reason: 'todos rows are 50 tall');
  });
}
