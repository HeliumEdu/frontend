// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/data/sources/note_remote_data_source.dart';
import 'package:heliumapp/domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteRemoteDataSource remoteDataSource;

  NoteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<NoteModel>> getNotes({
    String? search,
    String? linkedEntityType,
    int? homeworkId,
    int? eventId,
    int? resourceId,
    DateTime? updatedAtGte,
    bool includeContent = false,
    bool forceRefresh = false,
  }) async {
    return await remoteDataSource.getNotes(
      search: search,
      linkedEntityType: linkedEntityType,
      homeworkId: homeworkId,
      eventId: eventId,
      resourceId: resourceId,
      updatedAtGte: updatedAtGte,
      includeContent: includeContent,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<NoteModel> getNote({
    required int id,
    bool forceRefresh = false,
  }) async {
    return await remoteDataSource.getNote(id: id, forceRefresh: forceRefresh);
  }

  @override
  Future<NoteModel> createNote({required NoteRequestModel request}) async {
    return await remoteDataSource.createNote(request: request);
  }

  @override
  Future<NoteModel?> updateNote({
    required int noteId,
    required NoteRequestModel request,
  }) async {
    return await remoteDataSource.updateNote(
      noteId: noteId,
      request: request,
    );
  }

  @override
  Future<void> deleteNote({required int noteId}) async {
    return await remoteDataSource.deleteNote(noteId: noteId);
  }
}
