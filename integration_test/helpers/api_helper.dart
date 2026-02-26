// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'test_config.dart';

final _log = Logger('api_helper');

/// Helper for direct API calls during integration tests.
class ApiHelper {
  final TestConfig _config = TestConfig();

  /// Cleans up the test user if they exist from a previous run.
  ///
  /// This attempts to log in with the test credentials and delete the user.
  /// If login fails (e.g., user is unverified), tries the inactive user deletion endpoint.
  /// Always polls afterward to verify deletion completed.
  Future<void> cleanupTestUser() async {
    final email = _config.testEmail;
    final password = _config.testPassword;
    final apiHost = _config.projectApiHost;

    _log.info('Checking if test user exists: $email');

    // Attempt to log in to check if user exists
    var loginResponse = await http.post(
      Uri.parse('$apiHost/auth/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': email,
        'password': password,
      }),
    );

    if (loginResponse.statusCode == 200) {
      // User exists and is verified - delete via authenticated endpoint
      final tokens = jsonDecode(loginResponse.body) as Map<String, dynamic>;
      final accessToken = tokens['access'] as String;

      _log.info('User exists from previous run, cleaning up ...');

      final deleteRequest =
          http.Request('DELETE', Uri.parse('$apiHost/auth/user/delete/'));
      deleteRequest.headers['Content-Type'] = 'application/json';
      deleteRequest.headers['Authorization'] = 'Bearer $accessToken';
      deleteRequest.body = jsonEncode({'password': password});

      await deleteRequest.send();
    } else {
      // Login failed - user might be unverified, try inactive deletion endpoint
      _log.info('Attempting to delete inactive user (if exists from previous failed run) ...');

      final deleteInactiveRequest =
          http.Request('DELETE', Uri.parse('$apiHost/auth/user/delete/inactive/'));
      deleteInactiveRequest.headers['Content-Type'] = 'application/json';
      deleteInactiveRequest.body = jsonEncode({
        'username': email,
        'password': password,
      });

      await deleteInactiveRequest.send();
    }

    // Poll until user is confirmed deleted (login returns 401)
    const maxRetries = 10;
    const retryDelay = Duration(seconds: 3);

    for (var i = 0; i < maxRetries && loginResponse.statusCode != 401; i++) {
      _log.info('Response ${loginResponse.statusCode}, waiting for user deletion to complete ...');
      await Future.delayed(retryDelay);

      loginResponse = await http.post(
        Uri.parse('$apiHost/auth/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
      );
    }

    if (loginResponse.statusCode != 401) {
      throw Exception(
        'Workspace could not be initialized, user from previous run was never deleted',
      );
    }

    _log.info('Workspace is clean');
  }

  /// Checks if a user with the given email exists.
  ///
  /// Attempts to log in with the test password. Returns true if login succeeds
  /// (user exists), false otherwise.
  Future<bool> userExists(String email) async {
    final password = _config.testPassword;
    final apiHost = _config.projectApiHost;

    try {
      final loginResponse = await http.post(
        Uri.parse('$apiHost/auth/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
      );

      // 200 means user exists and password is correct
      // 401/400 means user doesn't exist or wrong password
      return loginResponse.statusCode == 200;
    } catch (e) {
      _log.warning('Error checking if user exists: $e');
      return false;
    }
  }
}
