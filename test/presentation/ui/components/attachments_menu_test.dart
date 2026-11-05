import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/ui/components/attachments_menu.dart';
import 'package:heliumapp/utils/attachment_helpers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';

void main() {
  late MockAttachmentRepository repository;

  setUp(() {
    repository = MockAttachmentRepository();
  });

  Future<void> givenMenu(WidgetTester tester, List<AttachmentGroup> groups) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AttachmentBloc(attachmentRepository: repository),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: AttachmentsMenuContent(groups: groups)),
        ),
      ),
    );
  }

  final rubric = MockModels.createAttachment(id: 1, title: 'rubric.pdf', homework: 1);
  final syllabus = MockModels.createAttachment(id: 2, title: 'syllabus.pdf', course: 10);
  final labSheet = MockModels.createAttachment(id: 3, title: 'lab sheet.pdf', resource: 20);

  testWidgets('lists its own attachments under the title, then each heading', (tester) async {
    // GIVEN
    final homework = MockModels.createHomework(id: 1, courseId: 10, resourceIds: [20]);

    // WHEN
    await givenMenu(
      tester,
      AttachmentGroups.forHomework(homework, [rubric, syllabus, labSheet]),
    );

    // THEN
    expect(find.text('Attachments'), findsOneWidget);
    expect(find.text('CLASS'), findsOneWidget);
    expect(find.text('RESOURCE'), findsOneWidget);
    final top = tester.getTopLeft(find.text('Attachments')).dy;
    final rubricY = tester.getTopLeft(find.text('rubric.pdf')).dy;
    final classY = tester.getTopLeft(find.text('CLASS')).dy;
    final syllabusY = tester.getTopLeft(find.text('syllabus.pdf')).dy;
    final resourceY = tester.getTopLeft(find.text('RESOURCE')).dy;
    final labSheetY = tester.getTopLeft(find.text('lab sheet.pdf')).dy;
    expect([top, rubricY, classY, syllabusY, resourceY, labSheetY], orderedEquals(
      [top, rubricY, classY, syllabusY, resourceY, labSheetY]..sort(),
    ));
    expect(find.bySemanticsLabel('Download'), findsNWidgets(3));
  });

  testWidgets('a class\'s attachments have no sub-heading', (tester) async {
    // WHEN
    await givenMenu(tester, AttachmentGroups.forCourse(10, [syllabus]));

    // THEN
    expect(find.text('Attachments'), findsOneWidget);
    expect(find.text('syllabus.pdf'), findsOneWidget);
    expect(find.text('CLASS'), findsNothing);
  });

  testWidgets('says so when nothing is left to download', (tester) async {
    // WHEN
    await givenMenu(tester, const []);

    // THEN
    expect(find.text('No attachments'), findsOneWidget);
  });

  testWidgets('downloading fetches a fresh link, and reports one deleted since', (tester) async {
    // GIVEN
    when(
      () => repository.getAttachments(courseId: 10, forceRefresh: true),
    ).thenAnswer((_) async => []);
    await givenMenu(tester, AttachmentGroups.forCourse(10, [syllabus]));

    // WHEN
    await tester.tap(find.bySemanticsLabel('Download'));
    await tester.pumpAndSettle();

    // THEN
    verify(() => repository.getAttachments(courseId: 10, forceRefresh: true)).called(1);
    expect(find.text('"syllabus.pdf" was deleted.'), findsOneWidget);
  });

  testWidgets('a failed link fetch reports the error', (tester) async {
    // GIVEN
    when(
      () => repository.getAttachments(courseId: 10, forceRefresh: true),
    ).thenThrow(NetworkException(message: 'No connection.'));
    await givenMenu(tester, AttachmentGroups.forCourse(10, [syllabus]));

    // WHEN
    await tester.tap(find.bySemanticsLabel('Download'));
    await tester.pumpAndSettle();

    // THEN
    expect(find.text('No connection.'), findsOneWidget);
  });
}
