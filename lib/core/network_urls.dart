class NetworkUrl {
  static const baseUrl = "https://api.heliumedu.com";
  static const signUpUrl = "/auth/user/register/";
  static const signInUrl = "/auth/token/";
  static const refreshTokenUrl = "/auth/token/refresh/";
  static const blacklistTokenUrl = "/auth/token/blacklist/";
  static const getProfileUrl = "/auth/user/";
  static const deleteAccountUrl = "/auth/user/delete/";
  static const pushTokenUrl = "/auth/user/pushtoken/";
  static const allCategoriesUrl = "/planner/categories/";
  static const updatePhoneProfileUrl = "/auth/user/profile/";
  static const changePasswordUrl = "/auth/user/";
  static const userSettingsUrl = "/auth/user/settings/";
  static const forgotPasswordUrl = "/auth/user/forgot/";
  static const getCoursesUrl = "/planner/courses/";
  static String createCourseUrl(int groupId) =>
      "/planner/coursegroups/$groupId/courses/";
  static String deleteCourseUrl(int groupId, int courseId) =>
      "/planner/coursegroups/$groupId/courses/$courseId/";
  static String createCourseScheduleUrl(int groupId, int courseId) =>
      "/planner/coursegroups/$groupId/courses/$courseId/courseschedules/";
  static String getCourseScheduleUrl(
    int groupId,
    int courseId,
    int scheduleId,
  ) =>
      "/planner/coursegroups/$groupId/courses/$courseId/courseschedules/$scheduleId/";
  static String categoriesUrls(int groupId, int courseId) =>
      "/planner/coursegroups/$groupId/courses/$courseId/categories/";
  static String deleteCategoryUrl(int groupId, int courseId, int categoryId) =>
      "/planner/coursegroups/$groupId/courses/$courseId/categories/$categoryId/";
  static const courseGroupsUrl = "/planner/coursegroups/";
  static const attachmentsUrl = "/planner/attachments/";
  static String deleteAttachmentUrl(int attachmentId) =>
      "/planner/attachments/$attachmentId/";
  static const materialGroupsUrl = "/planner/materialgroups/";
  static String materialGroupByIdUrl(int groupId) =>
      "/planner/materialgroups/$groupId/";
  static String materialsUrl(int groupId) =>
      "/planner/materialgroups/$groupId/materials/";
  static String materialByIdUrl(int groupId, int materialId) =>
      "/planner/materialgroups/$groupId/materials/$materialId/";
  static const allMaterialsUrl = "/planner/materials/";
  static const allHomeworkUrl = "/planner/homework/";
  static String homeworkUrl(int groupId, int courseId) =>
      "/planner/coursegroups/$groupId/courses/$courseId/homework/";
  static String homeworkByIdUrl(int groupId, int courseId, int homeworkId) =>
      "/planner/coursegroups/$groupId/courses/$courseId/homework/$homeworkId/";
  static const remindersUrl = "/planner/reminders/";
  static String reminderByIdUrl(int reminderId) =>
      "/planner/reminders/$reminderId/";
  static const eventsUrl = "/planner/events/";
  static String eventByIdUrl(int eventId) => "/planner/events/$eventId/";
  static const gradesUrl = "/planner/grades/";
  static const externalCalendarsUrl = "/feed/externalcalendars/";
  static String externalCalendarDetailUrl(int calendarId) =>
      "/feed/externalcalendars/$calendarId/";
  static String externalCalendarEventsUrl(int calendarId) =>
      "/feed/externalcalendars/$calendarId/events/";
  // Private Feed URLs
  static const enablePrivateFeedsUrl = "/feed/private/enable/";
  static const disablePrivateFeedsUrl = "/feed/private/disable/";
}
