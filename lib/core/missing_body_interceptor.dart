import 'package:dio/dio.dart';

/// A successful JSON response without its body was cut off in transit.
class MissingBodyInterceptor extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final data = response.data;
    final isMissingBody =
        response.requestOptions.responseType == ResponseType.json &&
        const {200, 201}.contains(response.statusCode) &&
        (data == null || data == '');
    if (isMissingBody) {
      return handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.connectionError,
          message: 'Response arrived without its body',
        ),
        true,
      );
    }
    handler.next(response);
  }
}
