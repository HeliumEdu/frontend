// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_event.dart';

abstract class NoteEvent extends BaseEvent {
  NoteEvent({required super.origin});
}

class FetchNotesEvent extends NoteEvent {
  final String? search;
  final String? linkedEntityType;
  final bool forceRefresh;

  FetchNotesEvent({
    required super.origin,
    this.search,
    this.linkedEntityType,
    this.forceRefresh = false,
  });
}

class FetchNoteEvent extends NoteEvent {
  final int noteId;
  final bool forceRefresh;

  FetchNoteEvent({
    required super.origin,
    required this.noteId,
    this.forceRefresh = false,
  });
}

class FetchNoteScreenDataEvent extends NoteEvent {
  final int? noteId;
  final int? homeworkId;
  final int? eventId;
  final int? resourceId;
  final int? resourceGroupId;

  FetchNoteScreenDataEvent({
    required super.origin,
    this.noteId,
    this.homeworkId,
    this.eventId,
    this.resourceId,
    this.resourceGroupId,
  });
}

class CreateNoteEvent extends NoteEvent {
  final NoteRequestModel request;

  CreateNoteEvent({
    required super.origin,
    required this.request,
  });
}

class UpdateNoteEvent extends NoteEvent {
  final int noteId;
  final NoteRequestModel request;

  UpdateNoteEvent({
    required super.origin,
    required this.noteId,
    required this.request,
  });
}

class DeleteNoteEvent extends NoteEvent {
  final int noteId;

  DeleteNoteEvent({
    required super.origin,
    required this.noteId,
  });
}
