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

          final deleteResponse = await http.delete(
            Uri.parse('$apiHost/auth/user/delete/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          );

          if (deleteResponse.statusCode == 204 || deleteResponse.statusCode == 200) {
            _log.info('Test user deleted successfully');
          } else {
            _log.warning('Failed to delete test user: ${deleteResponse.statusCode} ${deleteResponse.body}');
          }
        }
      } else {
        // Login failed - user might be unverified or doesn't exist
        // Try the inactive user deletion endpoint
        _log.info('Attempting to delete inactive user (if exists from previous failed run)...');

        final deleteInactiveResponse = await http.delete(
          Uri.parse('$apiHost/auth/user/delete/inactive/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': email,
            'password': password,
          }),
        );

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
    const maxRetries = 10;
    const retryDelay = Duration(seconds: 3);

    for (var i = 0; i < maxRetries; i++) {
      final response = await http.post(
        Uri.parse('$apiHost/auth/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );

      if (response.statusCode == 401) {
        _log.info('User deletion confirmed');
        return;
      }

      _log.info('Waiting for user deletion to complete... (${i + 1}/$maxRetries)');
      await Future.delayed(retryDelay);
    }

    _log.warning('User may not have been fully deleted after ${maxRetries * retryDelay.inSeconds}s');
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
