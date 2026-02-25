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
  Future<void> cleanupTestUser() async {
    final email = _config.testEmail;
    final password = _config.testPassword;
    final apiHost = _config.projectApiHost;

    _log.info('Checking if test user exists: $email');

    try {
      // Attempt to log in
      final loginResponse = await http.post(
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
        final accessToken = tokens['access'] as String?;

        if (accessToken != null) {
          _log.info('Test user exists (verified). Deleting...');

          // Use http.Request to ensure body is sent with DELETE
          // (some HTTP clients don't send body with DELETE by default)
          final deleteRequest = http.Request('DELETE', Uri.parse('$apiHost/auth/user/delete/'));
          deleteRequest.headers['Content-Type'] = 'application/json';
          deleteRequest.headers['Authorization'] = 'Bearer $accessToken';
          deleteRequest.body = jsonEncode({'password': password});

          final deleteStreamedResponse = await deleteRequest.send();
          final deleteResponse = await http.Response.fromStream(deleteStreamedResponse);

          if (deleteResponse.statusCode == 204 || deleteResponse.statusCode == 200) {
            _log.info('Test user deletion scheduled');
          } else {
            _log.warning('Failed to delete test user: ${deleteResponse.statusCode}');
          }
        }
      } else {
        // Login failed - user might be unverified or doesn't exist
        // Try the inactive user deletion endpoint
        _log.info('Attempting to delete inactive user (if exists from previous failed run)...');

        // Use http.Request to ensure body is sent with DELETE
        final deleteInactiveRequest = http.Request('DELETE', Uri.parse('$apiHost/auth/user/delete/inactive/'));
        deleteInactiveRequest.headers['Content-Type'] = 'application/json';
        deleteInactiveRequest.body = jsonEncode({
          'username': email,
          'password': password,
        });

        final deleteInactiveStreamedResponse = await deleteInactiveRequest.send();
        final deleteInactiveResponse = await http.Response.fromStream(deleteInactiveStreamedResponse);

        if (deleteInactiveResponse.statusCode == 204 || deleteInactiveResponse.statusCode == 200) {
          _log.info('Inactive test user deleted successfully');
        } else if (deleteInactiveResponse.statusCode == 404) {
          _log.info('No inactive user found. Workspace is clean.');
        } else {
          _log.info('Inactive user deletion returned: ${deleteInactiveResponse.statusCode}');
        }
      }

      // Wait and verify user is deleted
      await _waitForUserDeletion(email, password, apiHost);
    } catch (e) {
      _log.warning('Error during test user cleanup: $e');
      // Don't fail the test - cleanup is best-effort
    }
  }

  /// Polls until the user no longer exists (login returns 401).
  Future<void> _waitForUserDeletion(String email, String password, String apiHost) async {
    const maxRetries = 20;
    const retryDelay = Duration(seconds: 3);

    for (var i = 0; i < maxRetries; i++) {
      final response = await http.post(
        Uri.parse('$apiHost/auth/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );

      // User is deleted when login returns 401
      if (response.statusCode == 401) {
        _log.info('User deletion confirmed');
        return;
      }

      _log.info('Waiting for user deletion... (${i + 1}/$maxRetries)');
      await Future.delayed(retryDelay);
    }

    throw Exception(
      'User was not fully deleted after ${maxRetries * retryDelay.inSeconds}s. '
      'Test cannot proceed with existing user.',
    );
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
