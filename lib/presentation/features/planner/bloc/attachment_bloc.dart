// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:bloc/bloc.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/attachment_model.dart';
import 'package:heliumapp/domain/repositories/attachment_repository.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_event.dart';
import 'package:heliumapp/presentation/features/planner/bloc/attachment_state.dart';
import 'package:heliumapp/utils/format_helpers.dart';

class AttachmentBloc extends Bloc<AttachmentEvent, AttachmentState> {
  final AttachmentRepository attachmentRepository;

  AttachmentBloc({required this.attachmentRepository})
    : super(AttachmentInitial()) {
    on<FetchAttachmentsEvent>(_onFetchAttachments);
    on<CreateAttachmentEvent>(_onCreateAttachments);
    on<DeleteAttachmentEvent>(_onDeleteAttachments);
  }

  Future<void> _onFetchAttachments(
    FetchAttachmentsEvent event,
    Emitter<AttachmentState> emit,
  ) async {
    emit(AttachmentsLoading());
    try {
      final attachments = await attachmentRepository.getAttachments(
        eventId: event.eventId,
        homeworkId: event.homeworkId,
        courseId: event.courseId,
        forceRefresh: event.forceRefresh,
      );
      emit(AttachmentsFetched(attachments: attachments));
    } on HeliumException catch (e) {
      emit(AttachmentsError(message: e.message));
    } catch (e) {
      emit(AttachmentsError(message: 'An unexpected error occurred.'));
    }
  }

  Future<void> _onCreateAttachments(
    CreateAttachmentEvent event,
    Emitter<AttachmentState> emit,
  ) async {
    emit(AttachmentsLoading());

    final successes = <AttachmentModel>[];
    var failureCount = 0;

    final results = await Future.wait(
      event.files.map(
        (file) => attachmentRepository
            .createAttachment(
              bytes: file.bytes,
              filename: file.title,
              course: event.courseId,
              event: event.eventId,
              homework: event.homeworkId,
            )
            .then<AttachmentModel?>((a) => a)
            .catchError((_) => null),
      ),
    );

    for (final result in results) {
      if (result != null) {
        successes.add(result);
      } else {
        failureCount++;
      }
    }

    if (successes.isNotEmpty) {
      emit(AttachmentsCreated(attachments: successes));
    }

    if (failureCount > 0) {
      emit(
        AttachmentsError(
          message:
              '$failureCount ${failureCount.plural('attachment')} failed to upload',
        ),
      );
    }
  }

  Future<void> _onDeleteAttachments(
    DeleteAttachmentEvent event,
    Emitter<AttachmentState> emit,
  ) async {
    emit(AttachmentsLoading());

    try {
      await attachmentRepository.deleteAttachment(event.id);
      emit(
        AttachmentDeleted(
          id: event.id,
          courseId: event.courseId,
          eventId: event.eventId,
          homeworkId: event.homeworkId,
        ),
      );
    } on HeliumException catch (e) {
      emit(AttachmentsError(message: e.message));
    } catch (e) {
      emit(AttachmentsError(message: 'An unexpected error occurred.'));
    }
  }
}
