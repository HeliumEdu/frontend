import 'package:dio/dio.dart';

/// The browser resolves the system proxy itself, so there is nothing to read.
Future<void> refreshSystemProxy() async {}

/// The browser adapter cannot take an `HttpClient`, and does not need one.
void applySystemProxy(Dio dio) {}
