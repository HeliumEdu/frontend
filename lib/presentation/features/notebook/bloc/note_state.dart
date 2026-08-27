import 'dart:ui';

import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/resource_group_model.dart';
import 'package:heliumapp/data/models/planner/resource_model.dart';
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

mixin NoteScreenDataIdentity {
  int? get noteId;

  int? get linkHomeworkId;

  int? get linkEventId;

  int? get linkResourceId;

  bool matches({
    int? noteId,
    int? linkHomeworkId,
    int? linkEventId,
    int? linkResourceId,
  }) =>
      this.noteId == noteId &&
      this.linkHomeworkId == linkHomeworkId &&
      this.linkEventId == linkEventId &&
      this.linkResourceId == linkResourceId;
}

class NoteScreenDataFailed extends NotesError with NoteScreenDataIdentity {
  @override
  final int? noteId;
  @override
  final int? linkHomeworkId;
  @override
  final int? linkEventId;
  @override
  final int? linkResourceId;

  NoteScreenDataFailed({
    required super.origin,
    required super.message,
    this.noteId,
    this.linkHomeworkId,
    this.linkEventId,
    this.linkResourceId,
  });
}

class NoteScreenDataFetched extends NoteState with NoteScreenDataIdentity {
  final NoteModel? note;
  final String? linkedEntityType;
  final String? linkedEntityTitle;
  final Color? linkedEntityColor;
  final bool? linkedEntityCompleted;
  @override
  final int? noteId;
  @override
  final int? linkHomeworkId;
  @override
  final int? linkEventId;
  @override
  final int? linkResourceId;

  NoteScreenDataFetched({
    required super.origin,
    this.note,
    this.linkedEntityType,
    this.linkedEntityTitle,
    this.linkedEntityColor,
    this.linkedEntityCompleted,
    this.noteId,
    this.linkHomeworkId,
    this.linkEventId,
    this.linkResourceId,
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

class LinkableEntitiesFetched extends NoteState {
  final List<HomeworkModel> homework;
  final List<EventModel> events;
  final List<ResourceModel> resources;
  final List<CourseModel> courses;
  final List<ResourceGroupModel> resourceGroups;
  final List<CategoryModel> categories;

  LinkableEntitiesFetched({
    required super.origin,
    required this.homework,
    required this.events,
    required this.resources,
    required this.courses,
    required this.resourceGroups,
    required this.categories,
  });
}
