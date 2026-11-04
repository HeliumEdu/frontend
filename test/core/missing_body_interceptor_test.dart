import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/core/cache_service.dart';
import 'package:heliumapp/core/dio_client.dart';
import 'package:heliumapp/core/missing_body_interceptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final statusCode in [200, 201]) {
    test(
      'a $statusCode with no body fails as a connection error rather than '
      'reaching the caller',
      () async {
        // GIVEN
        final dio = _dioAnswering(statusCode, body: '');

        // WHEN
        final request = dio.get('/planner/categories/');

        // THEN
        await expectLater(
          request,
          throwsA(
            isA<DioException>()
                .having((e) => e.type, 'type', DioExceptionType.connectionError)
                .having((e) => e.response?.statusCode, 'status', statusCode),
          ),
        );
      },
    );
  }

  test('a 200 with a JSON body reaches the caller', () async {
    // GIVEN
    final dio = _dioAnswering(200, body: jsonEncode({'count': 0}));

    // WHEN
    final response = await dio.get('/planner/reminders/');

    // THEN
    expect(response.data, {'count': 0});
  });

  test('a 204 with no body reaches the caller', () async {
    // GIVEN
    final dio = _dioAnswering(204, body: '');

    // WHEN
    final response = await dio.delete('/planner/events/1/');

    // THEN
    expect(response.statusCode, 204);
  });

  test('a non-JSON request with no body reaches the caller', () async {
    // GIVEN
    final dio = _dioAnswering(200, body: '');

    // WHEN
    final response = await dio.get(
      '/feed/private/x.ics',
      options: Options(responseType: ResponseType.plain),
    );

    // THEN
    expect(response.statusCode, 200);
  });

  test('the API client rejects a missing body before the cache stores it', () {
    // GIVEN
    DioClient.resetForTesting();
    final interceptors = DioClient().dio.interceptors;

    // WHEN
    final missingBody = interceptors.indexWhere(
      (interceptor) => interceptor is MissingBodyInterceptor,
    );
    final cache = interceptors.indexOf(DioClient().cacheService.interceptor);

    // THEN
    expect(missingBody, isNonNegative);
    expect(missingBody, lessThan(cache));
  });

  test('a write whose body went missing still clears cached reads', () async {
    // GIVEN
    final cacheService = CacheService();
    final adapter = _CountingAdapter();
    final dio = DioClient.createDio(baseUrl: 'https://api.test')
      ..interceptors.addAll([MissingBodyInterceptor(), cacheService.interceptor])
      ..httpClientAdapter = adapter;
    await dio.get<dynamic>('/planner/notes/');

    // WHEN
    await expectLater(
      dio.post<dynamic>('/planner/notes/', data: {'title': 'Lecture 4'}),
      throwsA(isA<DioException>()),
    );
    final afterWrite = await dio.get<dynamic>('/planner/notes/');

    // THEN
    expect(afterWrite.data, {'read': 2});
  });
}

Dio _dioAnswering(int statusCode, {required String body}) {
  final dio = DioClient.createDio(baseUrl: 'https://api.test');
  dio.interceptors.add(MissingBodyInterceptor());
  dio.httpClientAdapter = _FixedResponseAdapter(statusCode, body);
  return dio;
}

class _FixedResponseAdapter implements HttpClientAdapter {
  final int statusCode;
  final String body;

  _FixedResponseAdapter(this.statusCode, this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _CountingAdapter implements HttpClientAdapter {
  int _reads = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = options.method == 'GET' ? jsonEncode({'read': ++_reads}) : '';
    return ResponseBody.fromString(
      body,
      options.method == 'GET' ? 200 : 201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
