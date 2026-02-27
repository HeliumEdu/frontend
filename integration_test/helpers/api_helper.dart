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

    // Poll until user is confirmed deleted (auth stops working)
    // Use same timeout as delete_user_test (3 minutes) to handle slow deletions
    const maxRetries = 36;
    const retryDelay = Duration(seconds: 5);

    for (var i = 0; i < maxRetries; i++) {
      await Future.delayed(retryDelay);

      final exists = await userExists(email);
      if (!exists) {
        _log.info('Workspace is clean');
        return;
      }

      _log.info('User still exists, waiting for deletion to complete ... (${i + 1}/$maxRetries)');
    }

    throw Exception(
      'Workspace could not be initialized, user from previous run was never deleted after ${maxRetries * retryDelay.inSeconds} seconds',
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

  /// Gets an access token for the test user.
  Future<String?> getAccessToken() async {
    final email = _config.testEmail;
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

      if (loginResponse.statusCode == 200) {
        final tokens = jsonDecode(loginResponse.body) as Map<String, dynamic>;
        return tokens['access'] as String;
      }
      return null;
    } catch (e) {
      _log.warning('Error getting access token: $e');
      return null;
    }
  }

  /// Fetches all homework items for the test user.
  /// Returns a list of homework items as maps, or null if fetch fails.
  Future<List<Map<String, dynamic>>?> getHomeworkItems() async {
    final apiHost = _config.projectApiHost;
    final accessToken = await getAccessToken();

    if (accessToken == null) {
      _log.warning('Could not get access token to fetch homework');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$apiHost/planner/homework/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body);
        return items.cast<Map<String, dynamic>>();
      }
      _log.warning('Failed to fetch homework: ${response.statusCode}');
      return null;
    } catch (e) {
      _log.warning('Error fetching homework: $e');
      return null;
    }
  }

  /// Finds a homework item by title (partial match).
  /// Returns the homework item as a map, or null if not found.
  Future<Map<String, dynamic>?> findHomeworkByTitle(String titleContains) async {
    final items = await getHomeworkItems();
    if (items == null) return null;

    try {
      return items.firstWhere(
        (item) => (item['title'] as String).contains(titleContains),
      );
    } catch (e) {
      _log.info('No homework found with title containing: $titleContains');
      return null;
    }
  }
}
