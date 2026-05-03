// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'dart:convert';

import 'package:heliumapp/core/api_url.dart';
import 'package:heliumapp/data/models/planner/category_model.dart';
import 'package:heliumapp/data/models/planner/course_model.dart';
import 'package:heliumapp/data/models/planner/course_schedule_model.dart';
import 'package:heliumapp/data/models/planner/event_model.dart';
import 'package:heliumapp/data/models/planner/homework_model.dart';
import 'package:heliumapp/data/models/planner/request/homework_request_model.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'test_config.dart';

final _log = Logger('api_helper');

/// Helper for direct API calls during integration tests.
class ApiHelper {
  final TestConfig _config = TestConfig();

  /// Cached so we don't hammer /auth/token/ — the platform throttles it,
  /// which can starve the UI's own login later in the run.
  String? _cachedAccessToken;

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
    final loginResponse = await http.post(
      Uri.parse('$apiHost${ApiUrl.authTokenUrl}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': email, 'password': password}),
    );

    if (loginResponse.statusCode == 200) {
      // User exists and is verified - delete via authenticated endpoint
      final tokens = jsonDecode(loginResponse.body) as Map<String, dynamic>;
      final accessToken = tokens['access'] as String;

      _log.info('User exists from previous run, cleaning up ...');

      final deleteRequest = http.Request(
        'DELETE',
        Uri.parse('$apiHost${ApiUrl.authUserDeleteUrl}'),
      );
      deleteRequest.headers['Content-Type'] = 'application/json';
      deleteRequest.headers['Authorization'] = 'Bearer $accessToken';
      deleteRequest.body = jsonEncode({'password': password});

      await deleteRequest.send();
    } else {
      // Login failed - user might be unverified, try inactive deletion endpoint
      _log.info(
        'Cleanup inactive user from previous run (if present) ...',
      );

      final deleteInactiveRequest = http.Request(
        'DELETE',
        Uri.parse('$apiHost${ApiUrl.authUserDeleteUrl}inactive/'),
      );
      deleteInactiveRequest.headers['Content-Type'] = 'application/json';
      deleteInactiveRequest.body = jsonEncode({
        'username': email,
        'password': password,
      });

      await deleteInactiveRequest.send();
    }

    invalidateAccessToken();

    // Poll up to 3 minutes for deletion to finalise. Re-invalidate each
    // iteration so a stale cached token can't masquerade as "still exists".
    const maxRetries = 36;
    const retryDelay = Duration(seconds: 5);

    for (var i = 0; i < maxRetries; i++) {
      await Future.delayed(retryDelay);
      invalidateAccessToken();
      final exists = await userExists(email);
      if (!exists) {
        _log.info('No user from previous runs, ready for testing');
        return;
      }

      _log.info(
        'User still exists, waiting for deletion to complete ... (${i + 1}/$maxRetries)',
      );
    }

    throw Exception(
      'Test could not be initialized, user from previous run was never deleted after ${maxRetries * retryDelay.inSeconds} seconds',
    );
  }

  /// Returns true if a user with [email] exists. For the configured test
  /// email this reuses [getAccessToken]'s cache; callers must invalidate
  /// after logout/deletion.
  Future<bool> userExists(String email) async {
    if (email == _config.testEmail) {
      final token = await getAccessToken();
      return token != null;
    }

    final password = _config.testPassword;
    final apiHost = _config.projectApiHost;

    try {
      final loginResponse = await http.post(
        Uri.parse('$apiHost${ApiUrl.authTokenUrl}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );

      // 200 means user exists and password is correct
      // 401/400 means user doesn't exist or wrong password
      return loginResponse.statusCode == 200;
    } catch (e) {
      _log.warning('Error checking if user exists: $e');
      return false;
    }
  }

  /// Returns an access token for the test user, cached after the first
  /// successful call. Clear via [invalidateAccessToken] on 401.
  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;

    final email = _config.testEmail;
    final password = _config.testPassword;
    final apiHost = _config.projectApiHost;

    try {
      final loginResponse = await http.post(
        Uri.parse('$apiHost${ApiUrl.authTokenUrl}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );

      if (loginResponse.statusCode == 200) {
        final tokens = jsonDecode(loginResponse.body) as Map<String, dynamic>;
        _cachedAccessToken = tokens['access'] as String;
        return _cachedAccessToken;
      }
      return null;
    } catch (e) {
      _log.warning('Error getting access token: $e');
      return null;
    }
  }

  void invalidateAccessToken() {
    _cachedAccessToken = null;
  }

  /// Fetches all courses for the test user.
  Future<List<CourseModel>?> getCourses() async {
    final apiHost = _config.projectApiHost;
    final accessToken = await getAccessToken();

    if (accessToken == null) {
      _log.warning('Could not get access token to fetch courses');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$apiHost${ApiUrl.plannerCoursesListUrl}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body);
        return items.map((item) => CourseModel.fromJson(item)).toList();
      }
      _log.warning('Failed to fetch courses: ${response.statusCode}');
      return null;
    } catch (e) {
      _log.warning('Error fetching courses: $e');
      return null;
    }
  }

  /// Fetches all homework items for the test user.
  /// If [from] and [to] are provided, filters by date range.
  Future<List<HomeworkModel>?> getHomeworkItems({
    String? from,
    String? to,
    bool? shownOnCalendar,
  }) async {
    final apiHost = _config.projectApiHost;
    final accessToken = await getAccessToken();

    if (accessToken == null) {
      _log.warning('Could not get access token to fetch homework');
      return null;
    }

    try {
      final queryParams = <String, String>{};
      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;
      if (shownOnCalendar != null) {
        queryParams['shown_on_calendar'] = shownOnCalendar.toString();
      }

      final uri = Uri.parse('$apiHost${ApiUrl.plannerHomeworkListUrl}')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body);
        return items.map((item) => HomeworkModel.fromJson(item)).toList();
      }
      _log.warning('Failed to fetch homework: ${response.statusCode}');
      return null;
    } catch (e) {
      _log.warning('Error fetching homework: $e');
      return null;
    }
  }

  /// Finds a homework item by title (partial match).
  Future<HomeworkModel?> findHomeworkByTitle(String titleContains) async {
    final items = await getHomeworkItems();
    if (items == null) return null;

    try {
      return items.firstWhere(
        (item) => item.title.contains(titleContains),
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetches all categories for the test user across every course.
  Future<List<CategoryModel>?> getCategories() async {
    final apiHost = _config.projectApiHost;
    final accessToken = await getAccessToken();

    if (accessToken == null) {
      _log.warning('Could not get access token to fetch categories');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$apiHost${ApiUrl.plannerCategoriesListUrl}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body);
        return items.map((item) => CategoryModel.fromJson(item)).toList();
      }
      _log.warning('Failed to fetch categories: ${response.statusCode}');
      return null;
    } catch (e) {
      _log.warning('Error fetching categories: $e');
      return null;
    }
  }

  /// Fetches all events for the test user.
  /// If [from] and [to] are provided, filters by date range.
  Future<List<EventModel>?> getEvents({String? from, String? to}) async {
    final apiHost = _config.projectApiHost;
    final accessToken = await getAccessToken();

    if (accessToken == null) {
      _log.warning('Could not get access token to fetch events');
      return null;
    }

    try {
      final queryParams = <String, String>{};
      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;

      final uri = Uri.parse('$apiHost${ApiUrl.plannerEventsListUrl}')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body);
        return items.map((item) => EventModel.fromJson(item)).toList();
      }
      _log.warning('Failed to fetch events: ${response.statusCode}');
      return null;
    } catch (e) {
      _log.warning('Error fetching events: $e');
      return null;
    }
  }

  /// Fetches all course schedules for the test user.
  ///
  /// Note: the new frontend uses these only as recurrence definitions and
  /// expands occurrences client-side via SfCalendar. The flat
  /// `/planner/courseschedules/` endpoint is deprecated on the platform but
  /// still serves the snapshot we need for deterministic test counts.
  Future<List<CourseScheduleModel>?> getCourseSchedules() async {
    final apiHost = _config.projectApiHost;
    final accessToken = await getAccessToken();

    if (accessToken == null) {
      _log.warning('Could not get access token to fetch course schedules');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$apiHost${ApiUrl.plannerCourseSchedulesUrl}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body);
        return items
            .map((item) => CourseScheduleModel.fromJson(item))
            .toList();
      }
      _log.warning(
        'Failed to fetch course schedules: ${response.statusCode}',
      );
      return null;
    } catch (e) {
      _log.warning('Error fetching course schedules: $e');
      return null;
    }
  }

  /// Creates an external calendar via the platform API. Returns the new
  /// calendar's id, or `null` on failure.
  Future<int?> createExternalCalendar({
    required String title,
    required String url,
    String color = '#3498db',
    bool shownOnCalendar = true,
  }) async {
    final apiHost = _config.projectApiHost;
    final accessToken = await getAccessToken();

    if (accessToken == null) {
      _log.warning('Could not get access token to create external calendar');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiHost${ApiUrl.feedExternalCalendarsListUrl}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'title': title,
          'url': url,
          'color': color,
          'shown_on_calendar': shownOnCalendar,
        }),
      );

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['id'] as int;
      }
      _log.warning(
        'Failed to create external calendar: ${response.statusCode} ${response.body}',
      );
      return null;
    } catch (e) {
      _log.warning('Error creating external calendar: $e');
      return null;
    }
  }

  /// Deletes an external calendar by id. Returns true on success.
  Future<bool> deleteExternalCalendar(int id) async {
    final apiHost = _config.projectApiHost;
    final accessToken = await getAccessToken();

    if (accessToken == null) {
      _log.warning('Could not get access token to delete external calendar');
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('$apiHost${ApiUrl.feedExternalCalendarDetailUrl(id)}'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      return response.statusCode == 204;
    } catch (e) {
      _log.warning('Error deleting external calendar: $e');
      return false;
    }
  }

  /// Updates a homework item.
  /// Follows the same signature pattern as HomeworkRemoteDataSource.
  Future<bool> updateHomework({
    required int groupId,
    required int courseId,
    required int homeworkId,
    required HomeworkRequestModel request,
  }) async {
    final apiHost = _config.projectApiHost;
    final accessToken = await getAccessToken();

    if (accessToken == null) {
      _log.warning('Could not get access token to update homework');
      return false;
    }

    try {
      final response = await http.patch(
        Uri.parse(
          '$apiHost${ApiUrl.plannerCourseGroupsCoursesHomeworkDetailsUrl(groupId, courseId, homeworkId)}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      }
      _log.warning('Failed to update homework: ${response.statusCode}');
      return false;
    } catch (e) {
      _log.warning('Error updating homework: $e');
      return false;
    }
  }
}
