import 'package:dio/dio.dart';
import 'package:heliumapp/core/dio_error_mapper.dart';
import 'package:heliumapp/core/helium_exception.dart';

abstract class BaseDataSource {
  HeliumException handleDioError(
    DioException e,
    StackTrace s, {
    String? notFoundEntity,
  }) => DioErrorMapper.map(e, s, notFoundEntity: notFoundEntity);

  /// Options that make a write conditional on [version], the item's raw
  /// `updated_at` as last read. A stale version fails with a
  /// [ConflictException]; a null version writes unconditionally.
  Options? ifMatchOptions(String? version) =>
      version == null ? null : Options(headers: {'If-Match': version});

  /// The endpoint returned a 2xx this call doesn't expect.
  ///
  /// Dio's `validateStatus` turns every non-2xx into a `DioException` before we
  /// get here, so reaching this means the backend's status contract changed —
  /// keep the tripwire rather than assuming the body is usable.
  ServerException unexpectedStatus(Response<dynamic> response, String message) =>
      ServerException(message: message, code: response.statusCode.toString());
}
