// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:ui';

import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/presentation/features/shared/bloc/core/base_state.dart';

abstract class NoteState extends BaseState {
  NoteState({required super.origin, super.message});
}

class NoteInitial extends NoteState {
  NoteInitial({required super.origin});
}

class NotesLoading extends NoteState {
  NotesLoading({required super.origin});
}

class NotesError extends NoteState {
  NotesError({required super.origin, required super.message});
}

class NotesFetched extends NoteState {
  final List<NoteModel> notes;

  NotesFetched({
    required super.origin,
    required this.notes,
  });
}

class NoteFetched extends NoteState {
  final NoteModel note;

  NoteFetched({
    required super.origin,
    required this.note,
  });
}

class NoteScreenDataFetched extends NoteState {
  final NoteModel? note;
  final String? linkedEntityType;
  final String? linkedEntityTitle;
  final Color? linkedEntityColor;

  NoteScreenDataFetched({
    required super.origin,
    this.note,
    this.linkedEntityType,
    this.linkedEntityTitle,
    this.linkedEntityColor,
  });
}

class NoteCreated extends NoteState {
  final NoteModel note;

  NoteCreated({
    required super.origin,
    required this.note,
  });
}

class NoteUpdated extends NoteState {
  final NoteModel note;

  NoteUpdated({
    required super.origin,
    required this.note,
  });
}

class NoteDeleted extends NoteState {
  final int noteId;

  NoteDeleted({
    required super.origin,
    required this.noteId,
  });
}
