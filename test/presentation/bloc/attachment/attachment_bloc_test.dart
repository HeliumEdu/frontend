// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_bloc.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_models.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/register_fallbacks.dart';

void main() {
  late MockAttachmentRepository mockAttachmentRepository;
  late AttachmentBloc attachmentBloc;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockAttachmentRepository = MockAttachmentRepository();
    attachmentBloc = AttachmentBloc(
      attachmentRepository: mockAttachmentRepository,
    );
  });

  tearDown(() {
    attachmentBloc.close();
  });

  group('AttachmentBloc', () {
    test('initial state is AttachmentInitial', () {
      expect(attachmentBloc.state, isA<AttachmentInitial>());
    });

    group('FetchAttachmentsEvent', () {
      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsFetched] when fetch succeeds without filters',
        build: () {
          when(
            () => mockAttachmentRepository.getAttachments(
              eventId: any(named: 'eventId'),
              homeworkId: any(named: 'homeworkId'),
              courseId: any(named: 'courseId'),
            ),
          ).thenAnswer((_) async => MockModels.createAttachments());
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(FetchAttachmentsEvent()),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsFetched>().having(
            (s) => s.attachments.length,
            'attachments length',
            3,
          ),
        ],
        verify: (_) {
          verify(
            () => mockAttachmentRepository.getAttachments(
              eventId: null,
              homeworkId: null,
              courseId: null,
            ),
          ).called(1);
        },
      );

      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsFetched] with homeworkId filter',
        build: () {
          when(
            () => mockAttachmentRepository.getAttachments(
              eventId: null,
              homeworkId: 5,
              courseId: null,
            ),
          ).thenAnswer(
            (_) async => MockModels.createAttachments(count: 2, homeworkId: 5),
          );
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(FetchAttachmentsEvent(homeworkId: 5)),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsFetched>().having(
            (s) => s.attachments.length,
            'attachments length',
            2,
          ),
        ],
      );

      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsFetched] with eventId filter',
        build: () {
          when(
            () => mockAttachmentRepository.getAttachments(
              eventId: 3,
              homeworkId: null,
              courseId: null,
            ),
          ).thenAnswer(
            (_) async => MockModels.createAttachments(count: 1, eventId: 3),
          );
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(FetchAttachmentsEvent(eventId: 3)),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsFetched>().having(
            (s) => s.attachments.length,
            'attachments length',
            1,
          ),
        ],
      );

      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsFetched] with courseId filter',
        build: () {
          when(
            () => mockAttachmentRepository.getAttachments(
              eventId: null,
              homeworkId: null,
              courseId: 2,
            ),
          ).thenAnswer(
            (_) async => MockModels.createAttachments(count: 4, courseId: 2),
          );
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(FetchAttachmentsEvent(courseId: 2)),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsFetched>().having(
            (s) => s.attachments.length,
            'attachments length',
            4,
          ),
        ],
      );

      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsError] when HeliumException occurs',
        build: () {
          when(
            () => mockAttachmentRepository.getAttachments(
              eventId: any(named: 'eventId'),
              homeworkId: any(named: 'homeworkId'),
              courseId: any(named: 'courseId'),
            ),
          ).thenThrow(ServerException(message: 'Server error'));
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(FetchAttachmentsEvent()),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsError>().having(
            (e) => e.message,
            'message',
            'Server error',
          ),
        ],
      );

      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsError] with generic message for unexpected errors',
        build: () {
          when(
            () => mockAttachmentRepository.getAttachments(
              eventId: any(named: 'eventId'),
              homeworkId: any(named: 'homeworkId'),
              courseId: any(named: 'courseId'),
            ),
          ).thenThrow(Exception('Unknown error'));
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(FetchAttachmentsEvent()),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );
    });

    group('CreateAttachmentEvent', () {
      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsCreated] when single file upload succeeds',
        build: () {
          MockModels.createAttachmentFile();
          when(
            () => mockAttachmentRepository.createAttachment(
              bytes: any(named: 'bytes'),
              filename: any(named: 'filename'),
              homework: any(named: 'homework'),
              event: any(named: 'event'),
              course: any(named: 'course'),
            ),
          ).thenAnswer((_) async => MockModels.createAttachment());
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(
          CreateAttachmentEvent(
            files: [MockModels.createAttachmentFile()],
            homeworkId: 1,
          ),
        ),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsCreated>().having(
            (s) => s.attachments.length,
            'attachments length',
            1,
          ),
        ],
      );

      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsCreated] when multiple file upload succeeds',
        build: () {
          when(
            () => mockAttachmentRepository.createAttachment(
              bytes: any(named: 'bytes'),
              filename: any(named: 'filename'),
              homework: any(named: 'homework'),
              event: any(named: 'event'),
              course: any(named: 'course'),
            ),
          ).thenAnswer((_) async => MockModels.createAttachment());
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(
          CreateAttachmentEvent(
            files: MockModels.createAttachmentFiles(count: 3),
            eventId: 2,
          ),
        ),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsCreated>().having(
            (s) => s.attachments.length,
            'attachments length',
            3,
          ),
        ],
        verify: (_) {
          verify(
            () => mockAttachmentRepository.createAttachment(
              bytes: any(named: 'bytes'),
              filename: any(named: 'filename'),
              homework: null,
              event: 2,
              course: null,
            ),
          ).called(3);
        },
      );

      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsCreated] with courseId',
        build: () {
          when(
            () => mockAttachmentRepository.createAttachment(
              bytes: any(named: 'bytes'),
              filename: any(named: 'filename'),
              homework: any(named: 'homework'),
              event: any(named: 'event'),
              course: any(named: 'course'),
            ),
          ).thenAnswer((_) async => MockModels.createAttachment(course: 5));
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(
          CreateAttachmentEvent(
            files: [MockModels.createAttachmentFile()],
            courseId: 5,
          ),
        ),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsCreated>().having(
            (s) => s.attachments.first.course,
            'course id',
            5,
          ),
        ],
      );

      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsError] when upload fails',
        build: () {
          when(
            () => mockAttachmentRepository.createAttachment(
              bytes: any(named: 'bytes'),
              filename: any(named: 'filename'),
              homework: any(named: 'homework'),
              event: any(named: 'event'),
              course: any(named: 'course'),
            ),
          ).thenThrow(ServerException(message: 'Upload failed'));
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(
          CreateAttachmentEvent(
            files: [MockModels.createAttachmentFile()],
            homeworkId: 1,
          ),
        ),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsError>().having(
            (e) => e.message,
            'message',
            'Upload failed',
          ),
        ],
      );

      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsError] for unexpected error during upload',
        build: () {
          when(
            () => mockAttachmentRepository.createAttachment(
              bytes: any(named: 'bytes'),
              filename: any(named: 'filename'),
              homework: any(named: 'homework'),
              event: any(named: 'event'),
              course: any(named: 'course'),
            ),
          ).thenThrow(Exception('Network timeout'));
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(
          CreateAttachmentEvent(
            files: [MockModels.createAttachmentFile()],
            homeworkId: 1,
          ),
        ),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );
    });

    group('DeleteAttachmentEvent', () {
      const attachmentId = 1;

      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentDeleted] when deletion succeeds',
        build: () {
          when(
            () => mockAttachmentRepository.deleteAttachment(attachmentId),
          ).thenAnswer((_) async {});
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(DeleteAttachmentEvent(id: attachmentId)),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentDeleted>().having((s) => s.id, 'id', attachmentId),
        ],
        verify: (_) {
          verify(
            () => mockAttachmentRepository.deleteAttachment(attachmentId),
          ).called(1);
        },
      );

      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsError] when attachment not found',
        build: () {
          when(
            () => mockAttachmentRepository.deleteAttachment(attachmentId),
          ).thenThrow(NotFoundException(message: 'Attachment not found'));
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(DeleteAttachmentEvent(id: attachmentId)),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsError>().having(
            (e) => e.message,
            'message',
            'Attachment not found',
          ),
        ],
      );

      blocTest<AttachmentBloc, AttachmentState>(
        'emits [AttachmentsLoading, AttachmentsError] for unexpected error during deletion',
        build: () {
          when(
            () => mockAttachmentRepository.deleteAttachment(attachmentId),
          ).thenThrow(Exception('Permission denied'));
          return attachmentBloc;
        },
        act: (bloc) => bloc.add(DeleteAttachmentEvent(id: attachmentId)),
        expect: () => [
          isA<AttachmentsLoading>(),
          isA<AttachmentsError>().having(
            (e) => e.message,
            'message',
            contains('unexpected'),
          ),
        ],
      );
    });
  });
}
