// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:dio/dio.dart';
import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/helium_exception.dart';
import 'package:heliumapp/data/models/planner/note_model.dart';
import 'package:heliumapp/data/models/planner/request/note_request_model.dart';
import 'package:heliumapp/data/sources/base_data_source.dart';
import 'package:logging/logging.dart';

final _log = Logger('data.sources');

abstract class NoteRemoteDataSource extends BaseDataSource {
  Future<List<NoteModel>> getNotes({
    String? search,
    String? linkedEntityType,
    int? homeworkId,
    int? eventId,
    int? resourceId,
    DateTime? updatedAtGte,
    bool includeContent = false,
    bool forceRefresh = false,
  });

  Future<NoteModel> getNote({required int id, bool forceRefresh = false});

  Future<NoteModel> createNote({required NoteRequestModel request});

  /// Updates a note. Returns the updated note, or null if the note was deleted
  /// (when content is cleared on a note with linked entities).
  Future<NoteModel?> updateNote({
    required int noteId,
    required NoteRequestModel request,
  });

  Future<void> deleteNote({required int noteId});
}

class NoteRemoteDataSourceImpl extends NoteRemoteDataSource {
  final DioClient dioClient;

  NoteRemoteDataSourceImpl({required this.dioClient});

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
    try {
      _log.info('Fetching Notes ...');

      final Map<String, dynamic> queryParameters = {};
      if (search != null) queryParameters['search'] = search;
      if (linkedEntityType != null) {
        queryParameters['linked_entity_type'] = linkedEntityType;
      }
      if (homeworkId != null) queryParameters['homework'] = homeworkId;
      if (eventId != null) queryParameters['event'] = eventId;
      if (resourceId != null) queryParameters['resource'] = resourceId;
      if (updatedAtGte != null) {
        queryParameters['updated_at__gte'] = updatedAtGte.toIso8601String();
      }
      if (includeContent) queryParameters['include_content'] = 'true';

      final response = await dioClient.dio.get(
        ApiUrl.plannerNotesListUrl,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        options: forceRefresh
            ? dioClient.cacheService.forceRefreshOptions()
            : null,
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data;
          final notes = data.map((json) => NoteModel.fromJson(json)).toList();
          _log.info('... fetched ${notes.length} Note(s)');
          return notes;
        } else {
          throw ServerException(
            message: 'Invalid response format',
            code: '200',
          );
        }
      } else {
        throw ServerException(
          message: 'Failed to fetch notes: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: 'An unexpected error occurred.');
    }
  }

  @override
  Future<NoteModel> getNote({
    required int id,
    bool forceRefresh = false,
  }) async {
    try {
      _log.info('Fetching Note $id ...');
      final response = await dioClient.dio.get(
        ApiUrl.plannerNotesDetailsUrl(id),
        options: forceRefresh
            ? dioClient.cacheService.forceRefreshOptions()
            : null,
      );

      if (response.statusCode == 200) {
        _log.info('... Note $id fetched');
        return NoteModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch note: ${response.statusCode}',
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: 'An unexpected error occurred.');
    }
  }

  @override
  Future<NoteModel> createNote({required NoteRequestModel request}) async {
    try {
      _log.info('Creating Note ...');
      final response = await dioClient.dio.post(
        ApiUrl.plannerNotesListUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final note = NoteModel.fromJson(response.data);
        _log.info('... Note ${note.id} created');
        await dioClient.cacheService.invalidateAll();
        return note;
      } else {
        throw ServerException(
          message: 'Failed to create note: ${response.statusCode}',
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: 'An unexpected error occurred.');
    }
  }

  @override
  Future<NoteModel?> updateNote({
    required int noteId,
    required NoteRequestModel request,
  }) async {
    try {
      _log.info('Updating Note $noteId ...');
      final response = await dioClient.dio.patch(
        ApiUrl.plannerNotesDetailsUrl(noteId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        _log.info('... Note $noteId updated');
        await dioClient.cacheService.invalidateAll();
        return NoteModel.fromJson(response.data);
      } else if (response.statusCode == 204) {
        // Note was deleted because content was cleared
        _log.info('... Note $noteId deleted (content cleared)');
        await dioClient.cacheService.invalidateAll();
        return null;
      } else {
        throw ServerException(
          message: 'Failed to update note: ${response.statusCode}',
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: 'An unexpected error occurred.');
    }
  }

  @override
  Future<void> deleteNote({required int noteId}) async {
    try {
      _log.info('Deleting Note $noteId ...');
      final response = await dioClient.dio.delete(
        ApiUrl.plannerNotesDetailsUrl(noteId),
      );

      if (response.statusCode == 204) {
        _log.info('... Note $noteId deleted');
        await dioClient.cacheService.invalidateAll();
      } else {
        throw ServerException(
          message: 'Failed to delete note: ${response.statusCode}',
        );
      }
    } on DioException catch (e, s) {
      throw handleDioError(e, s);
    } catch (e, s) {
      _log.severe('An unexpected error occurred', e, s);
      throw HeliumException(message: 'An unexpected error occurred.');
    }
  }
}
