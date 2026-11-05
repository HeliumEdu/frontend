import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/utils/attachment_helpers.dart';

import '../mocks/mock_models.dart';

void main() {
  final homework = MockModels.createHomework(
    id: 1,
    courseId: 10,
    resourceIds: [20, 21],
  );

  final ownRubric = MockModels.createAttachment(id: 100, title: 'rubric.pdf', homework: 1);
  final ownBrief = MockModels.createAttachment(id: 105, title: 'brief.pdf', homework: 1);
  final otherHomeworkAttachment = MockModels.createAttachment(id: 101, homework: 2);
  final syllabus = MockModels.createAttachment(id: 102, title: 'syllabus.pdf', course: 10);
  final otherCourseAttachment = MockModels.createAttachment(id: 103, course: 11);
  final textbookChapter = MockModels.createAttachment(id: 104, title: 'chapter 2.pdf', resource: 21);
  final labSheet = MockModels.createAttachment(id: 106, title: 'answers.pdf', resource: 20);
  final otherResourceAttachment = MockModels.createAttachment(id: 107, resource: 99);
  final attachments = [
    ownRubric,
    ownBrief,
    otherHomeworkAttachment,
    syllabus,
    otherCourseAttachment,
    textbookChapter,
    labSheet,
    otherResourceAttachment,
  ];

  group('AttachmentGroups.forHomework', () {
    test('lists its own without a heading, then Class, then Resource, each by title', () {
      // WHEN
      final groups = AttachmentGroups.forHomework(homework, attachments);

      // THEN
      expect(groups.map((g) => g.title), [null, 'Class', 'Resource']);
      expect(groups[0].attachments, [ownBrief, ownRubric]);
      expect(groups[1].attachments, [syllabus]);
      expect(groups[2].attachments, [labSheet, textbookChapter],
          reason: 'every resource on the assignment shares one Resource group');
    });

    test('pulled-through groups leave out the assignment\'s own', () {
      // WHEN
      final groups = AttachmentGroups.pulledThroughForHomework(homework, attachments);

      // THEN
      expect(groups.map((g) => g.title), ['Class', 'Resource']);
    });

    test('leaves out sources with no attachments', () {
      // GIVEN
      final classOnly = [syllabus, otherResourceAttachment];

      // WHEN
      final groups = AttachmentGroups.forHomework(homework, classOnly);

      // THEN
      expect(groups.map((g) => g.title), ['Class']);
    });
  });

  group('AttachmentGroups.forCourse and forResource', () {
    test('list only the item\'s own attachments, without a heading', () {
      // WHEN
      final courseGroups = AttachmentGroups.forCourse(10, attachments);
      final resourceGroups = AttachmentGroups.forResource(21, attachments);

      // THEN
      expect(courseGroups.single.title, isNull);
      expect(courseGroups.single.attachments, [syllabus]);
      expect(resourceGroups.single.attachments, [textbookChapter]);
    });

    test('are empty when the item has no attachments', () {
      // WHEN
      final groups = AttachmentGroups.forResource(22, attachments);

      // THEN
      expect(groups, isEmpty);
    });
  });

  group('AttachmentGroups.pulledThroughCount', () {
    test('adds the class and every resource on the assignment', () {
      // WHEN
      final count = AttachmentGroups.pulledThroughCount(homework, attachments);

      // THEN
      expect(count, 3, reason: 'resource 99 and class 11 aren\'t on this assignment');
    });
  });
}
