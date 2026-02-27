// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

// ANSI color codes
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _red = '\x1B[91m';
const _cyan = '\x1B[36m';
const _grey = '\x1B[90m';
const _reset = '\x1B[0m';

/// Port for the real-time logging server.
const _logServerPort = 4445;

/// Track current test for log indentation
bool _inTest = false;

Future<void> main() async {
  // Start HTTP server for real-time test output
  final server = await _startLogServer();

  try {
    // Use custom callback to suppress default "Failure Details:" output
    // since our log server already provides better formatted output
    await integrationDriver(
      responseDataCallback: (data) async {
        // Silently ignore - our log server handles all output
      },
    );
  } finally {
    await server.close();
  }
}

/// Starts an HTTP server that receives test results and prints them immediately.
Future<HttpServer> _startLogServer() async {
  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    _logServerPort,
  );
  // ignore: avoid_print
  print('${_grey}Log server started on port $_logServerPort$_reset\n');

  server.listen((request) async {
    // Add CORS headers for browser requests
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add(
      'Access-Control-Allow-Methods',
      'POST, OPTIONS',
    );
    request.response.headers.add(
      'Access-Control-Allow-Headers',
      'Content-Type',
    );

    // Handle CORS preflight
    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/log') {
      try {
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        _processResult(data);
        request.response.statusCode = 200;
      } catch (e) {
        request.response.statusCode = 500;
      }
    } else {
      request.response.statusCode = 404;
    }
    await request.response.close();
  });

  return server;
}

void _processResult(Map<String, dynamic> data) {
  final type = data['type'] as String?;

  switch (type) {
    case 'init':
      // ignore: avoid_print
      print(
        '${_cyan}Running integration tests against: ${data['environment']}$_reset',
      );
      // ignore: avoid_print
      print('${_cyan}API host: ${data['apiHost']}$_reset');
      // ignore: avoid_print
      print('${_grey}Integration log level: ${data['logLevel']}$_reset');
      final appLogLevel = data['appLogLevel'] as String?;
      if (appLogLevel != null) {
        // ignore: avoid_print
        print('${_grey}App log level: $appLogLevel$_reset');
      }
      // ignore: avoid_print
      print('');
      break;

    case 'suiteStart':
      // ignore: avoid_print
      print('$_grey${'─' * 70}$_reset');
      // ignore: avoid_print
      print('${_grey}SUITE: ${data['suite']}$_reset');
      break;

    case 'suiteEnd':
      // ignore: avoid_print
      print('$_grey${'─' * 70}$_reset\n');
      break;

    case 'testStart':
      _inTest = true;
      // ignore: avoid_print
      print('\n ${_grey}RUNNING: ${data['test']}$_reset');
      break;

    case 'testPass':
      _inTest = false;
      // ignore: avoid_print
      print(' $_green✓  PASS:$_reset ${data['test']}');
      break;

    case 'testSkip':
      _inTest = false;
      // ignore: avoid_print
      print(' $_yellow⊘  SKIP:$_reset ${data['test']}');
      if (data['reason'] != null) {
        // ignore: avoid_print
        print('    ${_grey}Reason: ${data['reason']}$_reset');
      }
      break;

    case 'testFail':
      _inTest = false;
      // ignore: avoid_print
      print('    ${_red}ERROR:$_reset ${data['error']}');
      final stack = (data['stack'] as String?)?.split('\n') ?? [];
      for (final line in stack.take(10)) {
        // ignore: avoid_print
        print('      $_grey$line$_reset');
      }
      // ignore: avoid_print
      print(' $_red✗  FAIL:$_reset ${data['test']}');
      stdout.flush();
      break;

    case 'log':
      final prefix = _inTest ? '    ' : ' ';
      // ignore: avoid_print
      print('$prefix${data['message']}');
      break;
  }
}
