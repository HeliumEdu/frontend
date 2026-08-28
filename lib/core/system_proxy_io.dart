import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('core');

const _channel = MethodChannel('com.heliumedu.heliumapp/native');

const _direct = 'DIRECT';

/// Read synchronously by `HttpClient.findProxy`, so the platform lookup has to
/// resolve out of band via [refreshSystemProxy].
String _proxy = _direct;

/// Re-reads the OS proxy configuration; `dart:io` discovers only `http_proxy`
/// environment variables, which mobile does not use.
Future<void> refreshSystemProxy() async {
  try {
    final settings = await _channel.invokeMapMethod<String, dynamic>(
      'getSystemProxy',
    );
    final host = settings?['host'] as String?;
    final port = settings?['port'] as int?;

    _proxy = host != null && host.isNotEmpty && port != null && port > 0
        ? 'PROXY $host:$port; $_direct'
        : _direct;
  } on MissingPluginException {
    _proxy = _direct;
  } catch (e) {
    _log.warning('Failed to read the system proxy configuration', e);
    _proxy = _direct;
  }
}

/// Routes [dio] through the OS proxy when one is configured. The trailing
/// `DIRECT` is load-bearing: `dart:io` retries the next entry on connection
/// failure, so a stale proxy degrades to a direct connection.
void applySystemProxy(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () => HttpClient()
      // Matches the idleTimeout Dio's own default adapter applies.
      ..idleTimeout = const Duration(seconds: 3)
      ..findProxy = (_) => _proxy,
  );
}
