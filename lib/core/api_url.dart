// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

class ApiUrl {
  static const baseUrl = String.fromEnvironment(
    'PROJECT_API_HOST',
    defaultValue: 'https://api.heliumedu.com',
  );

  // Unauthenticated URLs
  static const authUserRegisterUrl = '/auth/user/register/';
  static const authUserVerifyUrl = '/auth/user/verify/';
  static const authUserVerifyResendUrl = '/auth/user/verify/resend/';
  static const authUserForgotUrl = '/auth/user/forgot/';
  static const authTokenUrl = '/auth/token/';

  // Authenticated URLs
  // User
  static const authUserUrl = '/auth/user/';
  static const authUserDeleteUrl = '/auth/user/delete/';
  static const authUserSettingsUrl = '/auth/user/settings/';
  static const authUserPushTokenUrl = '/auth/user/pushtoken/';

  // Token
  static const authTokenRefreshUrl = '/auth/token/refresh/';
  static const authTokenBlacklistUrl = '/auth/token/blacklist/';

  // Grades
  static const plannerGradesUrl = '/planner/grades/';

  // External Calendars & Feeds
  static const feedPrivateEnableUrl = '/feed/private/enable/';
  static const feedPrivateDisableUrl = '/feed/private/disable/';
  static const feedExternalCalendarsListUrl = '/feed/externalcalendars/';

  static String feedExternalCalendarDetailUrl(int externalCalendarId) =>
      '/feed/externalcalendars/$externalCalendarId/';

  // Calendar
  static const plannerCoursesListUrl = '/planner/courses/';
  static const plannerCategoriesListUrl = '/planner/categories/';
  static const plannerMaterialsListUrl = '/planner/materials/';
  static const plannerHomeworkListUrl = '/planner/homework/';
  static const plannerEventsListUrl = '/planner/events/';
  static const plannerSchedulesEvents = '/planner/courseschedules/events/';
  static const feedExternalCalendarsEventsListUrl =
      '/feed/externalcalendars/events/';
  static const plannerRemindersListUrl = '/planner/reminders/';
  static const plannerAttachmentsListUrl = '/planner/attachments/';

  static String plannerCourseGroupsCoursesHomeworkDetailsUrl(
    int groupId,
    int courseId,
    int homeworkId,
  ) => '/planner/coursegroups/$groupId/courses/$courseId/homework/$homeworkId/';

  static String plannerEventsDetailsUrl(int eventId) =>
      '/planner/events/$eventId/';

  static String plannerRemindersDetailsUrl(int reminderId) =>
      '/planner/reminders/$reminderId/';

  static String plannerAttachmentsDetailsUrl(int attachmentId) =>
      '/planner/attachments/$attachmentId/';

  static String plannerCourseGroupsCoursesHomeworkListUrl(
    int groupId,
    int courseId,
  ) => '/planner/coursegroups/$groupId/courses/$courseId/homework/';

  // Courses
  static const plannerCourseGroupsListUrl = '/planner/coursegroups/';

  static String plannerCourseGroupsDetailsUrl(int groupId) =>
      '/planner/coursegroups/$groupId/';

  static String plannerCourseGroupsCoursesListUrl(int groupId) =>
      '/planner/coursegroups/$groupId/courses/';

  static String plannerCourseGroupsCoursesDetailsUrl(
    int groupId,
    int courseId,
  ) => '/planner/coursegroups/$groupId/courses/$courseId/';

  static const plannerCourseSchedulesUrl = '/planner/courseschedules/';

  static String plannerCourseGroupsCoursesSchedulesListUrl(
    int groupId,
    int courseId,
  ) => '/planner/coursegroups/$groupId/courses/$courseId/courseschedules/';

  static String plannerCourseGroupsCoursesSchedulesDetailsUrl(
    int groupId,
    int courseId,
    int scheduleId,
  ) =>
      '/planner/coursegroups/$groupId/courses/$courseId/courseschedules/$scheduleId/';

  static String plannerCourseGroupsCoursesCategoriesListUrl(
    int groupId,
    int courseId,
  ) => '/planner/coursegroups/$groupId/courses/$courseId/categories/';

  static String plannerCourseGroupsCoursesCategoriesDetailsUrl(
    int groupId,
    int courseId,
    int categoryId,
  ) =>
      '/planner/coursegroups/$groupId/courses/$courseId/categories/$categoryId/';

  // Materials
  static const plannerMaterialGroupsListUrl = '/planner/materialgroups/';

  static String plannerMaterialGroupsDetailsUrl(int groupId) =>
      '/planner/materialgroups/$groupId/';

  static String plannerMaterialGroupsMaterialsListUrl(int groupId) =>
      '/planner/materialgroups/$groupId/materials/';

  static String plannerMaterialGroupsMaterialDetailsUrl(
    int groupId,
    int materialId,
  ) => '/planner/materialgroups/$groupId/materials/$materialId/';
}
