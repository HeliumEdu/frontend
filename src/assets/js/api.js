/**
 * Copyright (c), 2025 Helium Edu
 *
 * JavaScript API for requests into server-side functionality for /planner pages.
 *
 * Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 * The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 * project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.15.8
 */

/**
 * Create the Helium API persistence object.
 *
 * @constructor construct the HeliumPlannerAPI persistence object
 */
function HeliumPlannerAPI() {
    "use strict";

    this.course_groups_by_user_id = {};
    this.course_group = {};

    this.courses_by_course_group_id = {};
    this.courses_by_user_id = {};
    this.course = {};

    this.material_groups_by_user_id = {};
    this.material_group = {};

    this.materials_by_material_group_id = {};
    this.materials_by_course_id = {};
    this.material = {};

    this.categories_by_course_id = {};
    this.categories_by_user_id = {};
    this.category = {};

    this.homework_by_user_id = {};
    this.homework = {};

    this.events_by_user_id = {};
    this.event = {};

    this.external_calendars_by_user_id = {};

    this.external_calendar_events = {};

    this.class_schedules_events = {};

    let self = this;

    this.register = function (callback, username, email, password, time_zone) {
        return $.ajax({
                          type: "POST",
                          url: helium.API_URL + "/auth/user/register/",
                          data: JSON.stringify(
                              {username: username, email: email, password: password, time_zone: time_zone}),
                          dataType: "json",
                          success: function (data) {
                              callback(data)
                          },
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    this.login = function (callback, username, password) {
        return $.ajax({
                          type: "POST",
                          url: helium.API_URL + "/auth/token/",
                          data: JSON.stringify({username: username, password: password, last_login_now: true}),
                          dataType: "json",
                          success: function (data) {
                              localStorage.setItem("access_token", data.access);
                              localStorage.setItem("refresh_token", data.refresh);
                              localStorage.setItem("access_token_exp", helium.parse_jwt(data.access).exp);

                              callback(data);
                          },
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    this.logout = function (callback, async) {
        const refreshToken = localStorage.getItem("refresh_token");
        if (refreshToken === null) {
            callback({});
        }

        return $.ajax({
                          type: "POST",
                          url: helium.API_URL + "/auth/token/blacklist/",
                          data: JSON.stringify({refresh: refreshToken}),
                          dataType: "json",
                          async: async,
                          success: function (data) {
                              helium.clear_access_token();

                              callback(data);
                          },
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    this.forgot = function (callback, email) {
        return $.ajax({
                          type: "PUT",
                          url: helium.API_URL + "/auth/user/forgot/",
                          data: JSON.stringify({email: email}),
                          success: function (data) {
                              callback(data)
                          },
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Update user details.
     *
     * @param callback function to pass response data and call after completion
     * @param user_id the user ID to update
     * @param data the array of values to update for the user
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.update_user_details = function (callback, user_id, data, async) {
        async = typeof async === "undefined" ? true : async;
        return $.ajax({
                          type: "PUT",
                          url: helium.API_URL + "/auth/user/settings/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Compile data for display on the /grades page for the given User ID and pass the values to the given callback
     * function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.get_grades = function (callback, async) {
        async = typeof async === "undefined" ? true : async;

        return $.ajax({
                          type: "GET",
                          url: helium.API_URL + "/planner/grades/",
                          async: async,
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Compile the CourseGroups for the given User ID and pass the values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_course_groups = function (callback, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.course_groups_by_user_id.hasOwnProperty(helium.USER_PREFS.id)) {
            ret_val = callback(self.course_groups_by_user_id[helium.USER_PREFS.id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/coursegroups/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.course_groups_by_user_id[helium.USER_PREFS.id] = data;
                                     callback(self.course_groups_by_user_id[helium.USER_PREFS.id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile the CourseGroup for the given ID and pass the values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the CourseGroup
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_course_group = function (callback, id, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.course_group.hasOwnProperty(id)) {
            ret_val = callback(self.course_group[id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/coursegroups/" + id + "/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.course_group[id] = data;
                                     callback(self.course_group[id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Create a new CourseGroup and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param data the array of values to set for the new CourseGroup
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.add_course_group = function (callback, data, async) {
        async = typeof async === "undefined" ? true : async;
        self.course_groups_by_user_id = {};
        return $.ajax({
                          type: "POST",
                          url: helium.API_URL + "/planner/coursegroups/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Edit the CourseGroup for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the CourseGroup
     * @param data the array of values to update for the CourseGroup
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.edit_course_group = function (callback, id, data, async) {
        async = typeof async === "undefined" ? true : async;
        delete self.course_group[id];
        self.course_groups_by_user_id = {};
        return $.ajax({
                          type: "PUT",
                          url: helium.API_URL + "/planner/coursegroups/" + id + "/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Delete the CourseGroup for the given ID and pass the returned values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the CourseGroup
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.delete_course_group = function (callback, id, async) {
        async = typeof async === "undefined" ? true : async;
        delete self.course_group[id];
        self.course_groups_by_user_id = {};
        return $.ajax({
                          type: "DELETE",
                          url: helium.API_URL + "/planner/coursegroups/" + id + "/",
                          async: async,
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Compile all Courses for the given CourseGroup ID and pass the values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the CourseGroup with which to associate
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_courses_by_course_group_id = function (callback, id, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.courses_by_course_group_id.hasOwnProperty(id)) {
            ret_val = callback(self.courses_by_course_group_id[id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/coursegroups/" + id + "/courses/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.courses_by_course_group_id[id] = data;
                                     callback(self.courses_by_course_group_id[id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile all Courses for the given User Profile ID and pass the values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_all_courses_by_user_id = function (callback, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.courses_by_user_id.hasOwnProperty(helium.USER_PREFS.id)) {
            ret_val = callback(self.courses_by_user_id[helium.USER_PREFS.id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/courses/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.courses_by_user_id[helium.USER_PREFS.id] = data;
                                     callback(self.courses_by_user_id[helium.USER_PREFS.id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile all Courses (excluding those in hidden groups) for the given User Profile ID and pass the values to the
     * given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_courses = function (callback, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.courses_by_user_id.hasOwnProperty(helium.USER_PREFS.id)) {
            ret_val = callback(self.courses_by_user_id[helium.USER_PREFS.id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/courses/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.courses_by_user_id[helium.USER_PREFS.id] = data;
                                     callback(self.courses_by_user_id[helium.USER_PREFS.id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile all Events for the given CourseSchedule and pass the values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id The ID of the CourseGroup.
     * @param course_id The ID of the Course.
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     * @param search A search string to filter by
     */
    this.get_class_schedule_events = function (callback, course_group_id, course_id, async, use_cache, search) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        let cache_key = course_id + search;
        if (use_cache && self.class_schedules_events.hasOwnProperty(cache_key)) {
            ret_val = callback(self.class_schedules_events[cache_key]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/"
                                      + course_id + "/courseschedules/events/"
                                      + (helium.str_not_empty(search) ? "?search=" + search : ""),
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.class_schedules_events[cache_key] = data;
                                     callback(self.class_schedules_events[cache_key]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile the Course for the given ID and pass the values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param id the ID of the Course
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_course = function (callback, course_group_id, id, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.course.hasOwnProperty(id)) {
            ret_val = callback(self.course[id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + id
                                      + "/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.course[id] = data;
                                     callback(self.course[id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Create a new Course and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param data the array of values to set for the new Course
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.add_course = function (callback, course_group_id, data, async) {
        async = typeof async === "undefined" ? true : async;
        self.courses_by_course_group_id = {};
        self.courses_by_user_id = {};
        self.class_schedules_events = {};
        self.categories_by_user_id = {};
        self.categories_by_course_id = {};
        self.homework_by_user_id = {};
        return $.ajax({
                          type: "POST",
                          url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Edit the Course for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param id the ID of the Course
     * @param data the array of values to update for the Course
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.edit_course = function (callback, course_group_id, id, data, async) {
        async = typeof async === "undefined" ? true : async;
        delete self.course[id];
        self.courses_by_course_group_id = {};
        self.courses_by_user_id = {};
        self.class_schedules_events = {}
        self.categories_by_user_id = {};
        self.categories_by_course_id = {};
        self.homework_by_user_id = {};
        return $.ajax({
                          type: "PUT",
                          url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + id + "/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Delete the Course for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param id the ID of the Course
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.delete_course = function (callback, course_group_id, id, async) {
        async = typeof async === "undefined" ? true : async;
        delete self.course[id];
        self.courses_by_course_group_id = {};
        self.courses_by_user_id = {};
        self.class_schedules_events = {};
        self.categories_by_user_id = {};
        self.categories_by_course_id = {};
        self.homework_by_user_id = {};
        return $.ajax({
                          type: "DELETE",
                          url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + id + "/",
                          async: async,
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Create a new Course and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param course_id the ID of the Course
     * @param data the array of values to set for the new Course
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.add_courseschedule = function (callback, course_group_id, course_id, data, async) {
        async = typeof async === "undefined" ? true : async;
        return $.ajax({
                          type: "POST",
                          url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + course_id
                               + "/courseschedules/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Edit the Course for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param course_id the ID of the CourseGroup
     * @param id the ID of the Course
     * @param data the array of values to update for the Course
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.edit_courseschedule = function (callback, course_group_id, course_id, id, data, async) {
        async = typeof async === "undefined" ? true : async;
        return $.ajax({
                          type: "PUT",
                          url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + course_id
                               + "/courseschedules/" + id + "/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Delete the Course for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param id the ID of the Course
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.delete_course = function (callback, course_group_id, id, async) {
        async = typeof async === "undefined" ? true : async;
        delete self.course[id];
        self.courses_by_course_group_id = {};
        self.courses_by_user_id = {};
        self.categories_by_user_id = {};
        self.categories_by_course_id = {};
        return $.ajax({
                          type: "DELETE",
                          url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + id + "/",
                          async: async,
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Compile the MaterialGroups for the given User ID and pass the values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_material_groups = function (callback, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.material_groups_by_user_id.hasOwnProperty(helium.USER_PREFS.id)) {
            ret_val = callback(self.material_groups_by_user_id[helium.USER_PREFS.id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/materialgroups/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.material_groups_by_user_id[helium.USER_PREFS.id] = data;
                                     callback(self.material_groups_by_user_id[helium.USER_PREFS.id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile the MaterialGroup for the given ID and pass the values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the MaterialGroup
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_material_group = function (callback, id, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.material_group.hasOwnProperty(id)) {
            ret_val = callback(self.material_group[id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/materialgroups/" + id + "/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.material_group[id] = data;
                                     callback(self.material_group[id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Create a new MaterialGroup and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param data the array of values to set for the new MaterialGroup
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.add_material_group = function (callback, data, async) {
        async = typeof async === "undefined" ? true : async;
        self.material_group = {};
        return $.ajax({
                          type: "POST",
                          url: helium.API_URL + "/planner/materialgroups/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Edit the MaterialGroup for the given ID and pass the returned values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the MaterialGroup
     * @param data the array of values to update for the CourseGroup
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.edit_material_group = function (callback, id, data, async) {
        async = typeof async === "undefined" ? true : async;
        delete self.material_group[id];
        self.material_group = {};
        return $.ajax({
                          type: "PUT",
                          url: helium.API_URL + "/planner/materialgroups/" + id + "/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Delete the MaterialGroup for the given ID and pass the returned values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the MaterialGroup
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.delete_material_group = function (callback, id, async) {
        async = typeof async === "undefined" ? true : async;
        delete self.material_group[id];
        return $.ajax({
                          type: "DELETE",
                          url: helium.API_URL + "/planner/materialgroups/" + id + "/",
                          async: async,
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Compile all Materials for the given Course ID and pass the values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the Course with which to associate
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_materials_by_course_id = function (callback, id, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.materials_by_course_id.hasOwnProperty(id)) {
            ret_val = callback(self.materials_by_course_id[id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/materials/?courses=" + id,
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.materials_by_course_id[id] = data;
                                     callback(self.materials_by_course_id[id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile the Material for the given ID and pass the values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param material_group_id the ID of the MaterialGroup
     * @param id the ID of the Material
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_material = function (callback, material_group_id, id, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.material.hasOwnProperty(id)) {
            ret_val = callback(self.material[id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/materialgroups/" + material_group_id + "/materials/"
                                      + id + "/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.material[id] = data;
                                     callback(self.material[id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile the Material for the given material group ID and pass the values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the MaterialGroup
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_materials_by_material_group_id = function (callback, id, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.materials_by_material_group_id.hasOwnProperty(id)) {
            ret_val = callback(self.materials_by_material_group_id[id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/materialgroups/" + id + "/materials/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.materials_by_material_group_id[id] = data;
                                     callback(self.materials_by_material_group_id[id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Create a new Material and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param material_group_id the ID of the MaterialGroup
     * @param data the array of values to set for the new Material
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.add_material = function (callback, material_group_id, data, async) {
        async = typeof async === "undefined" ? true : async;
        self.materials_by_course_id = {};
        return $.ajax({
                          type: "POST",
                          url: helium.API_URL + "/planner/materialgroups/" + material_group_id + "/materials/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Edit the Material for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param material_group_id the ID of the MaterialGroup
     * @param id the ID of the Material
     * @param data the array of values to update for the Material
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.edit_material = function (callback, material_group_id, id, data, async) {
        async = typeof async === "undefined" ? true : async;
        delete self.material[id];
        self.materials_by_course_id = {};
        return $.ajax({
                          type: "PUT",
                          url: helium.API_URL + "/planner/materialgroups/" + material_group_id + "/materials/" + id
                               + "/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Delete the Material for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param material_group_id the ID of the MaterialGroup
     * @param id the ID of the Material
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.delete_material = function (callback, material_group_id, id, async) {
        async = typeof async === "undefined" ? true : async;
        delete self.material[id];
        self.materials_by_course_id = {};
        return $.ajax({
                          type: "DELETE",
                          url: helium.API_URL + "/planner/materialgroups/" + material_group_id + "/materials/" + id
                               + "/",
                          async: async,
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Compile all Categories and pass the values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_categories_by_user_id = function (callback, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.categories_by_user_id.hasOwnProperty(helium.USER_PREFS.id)) {
            ret_val = callback(self.categories_by_user_id[helium.USER_PREFS.id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/categories/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.categories_by_user_id[helium.USER_PREFS.id] = data;
                                     callback(self.categories_by_user_id[helium.USER_PREFS.id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile all Categories for the given Course ID and pass the values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup with which to associate
     * @param id the ID of the Course with which to associate
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_categories_by_course_id = function (callback, course_group_id, id, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.categories_by_course_id.hasOwnProperty(id)) {
            ret_val = callback(self.categories_by_course_id[id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + id
                                      + "/categories/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.categories_by_course_id[id] = data;
                                     callback(self.categories_by_course_id[id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Create new Categories and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param course_id the ID of the Course
     * @param data the array of values to set for the new Category
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.add_category = function (callback, course_group_id, course_id, data, async) {
        async = typeof async === "undefined" ? true : async;
        self.categories_by_user_id = {};
        self.categories_by_course_id = {};
        return $.ajax({
                          type: "POST",
                          url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + course_id
                               + "/categories/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Edit the Category for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param course_id the ID of the Course
     * @param id the ID of the Category
     * @param data the array of values to update for the Category
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.edit_category = function (callback, course_group_id, course_id, id, data, async) {
        async = typeof async === "undefined" ? true : async;
        delete self.category[id];
        self.categories_by_user_id = {};
        self.categories_by_course_id = {};
        return $.ajax({
                          type: "PUT",
                          url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + course_id
                               + "/categories/" + id + "/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Delete the Category for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param course_id the ID of the Course
     * @param id the ID of the Category
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.delete_category = function (callback, course_group_id, course_id, id, async) {
        async = typeof async === "undefined" ? true : async;
        delete self.category[id];
        self.categories_by_user_id = {};
        self.categories_by_course_id = {};
        return $.ajax({
                          type: "DELETE",
                          url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + course_id
                               + "/categories/" + id + "/",
                          async: async,
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Compile all Attachments for the given Course ID and pass the values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the Course with which to associate
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.get_attachments_by_course_id = function (callback, id, async) {
        async = typeof async === "undefined" ? true : async;

        return $.ajax({
                          type: "GET",
                          url: helium.API_URL + "/planner/attachments/?course=" + id,
                          async: async,
                          dataType: "json",
                          success: function (data) {
                              callback(data);
                          },
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Delete the Attachment for the given ID and pass the returned values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the Attachment
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.delete_attachment = function (callback, id, async) {
        async = typeof async === "undefined" ? true : async;
        self.attachments_by_course_id = {};
        return $.ajax({
                          type: "DELETE",
                          url: helium.API_URL + "/planner/attachments/" + id,
                          async: async,
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Compile all Homework for the given Course ID and pass the values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     * @param start The start time window
     * @param end The end time window
     * @param courses A CSV string of course IDs to filter
     * @param categories A CSV string of category titles to filter
     * @param completed Filter by completed
     * @param overdue Filter by overdue
     * @param search A search string to filter by
     */
    this.get_homework_by_user = function (callback, async, use_cache, start, end, courses, categories, completed,
                                          overdue, search) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        let cache_key = start + end + courses + categories + completed + overdue + search;
        if (use_cache && self.homework_by_user_id.hasOwnProperty(cache_key)) {
            ret_val = callback(self.homework_by_user_id[cache_key]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/homework/?shown_on_calendar=true"
                                      + (start !== undefined ? "&start__gte=" + start : "")
                                      + (end !== undefined ? "&end__lt=" + end : "")
                                      + (helium.str_not_empty(courses) ? "&course__id__in=" + courses.split(
                                         ",") : "")
                                      + (helium.str_not_empty(categories) ? "&category__title__in="
                                      + categories.split(",") : "")
                                      + (helium.str_not_empty(completed) ? "&completed=" + completed : "")
                                      + (helium.str_not_empty(overdue) ? "&overdue=" + overdue : "")
                                      + (helium.str_not_empty(search) ? "&search=" + search : ""),
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.homework_by_user_id[cache_key] = data;
                                     callback(self.homework_by_user_id[cache_key]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile the Homework for the given ID and pass the values to the given callback function in JSON format.
     *
     * @param id The ID of the homework
     * @param callback function to pass response data and call after completion
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_homework_by_id = function (callback, id, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.homework.hasOwnProperty(id)) {
            ret_val = callback(self.homework[id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/homework/?id=" + id,
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     if (data.length > 0) {
                                         self.homework[id] = data[0];
                                         callback(self.homework[id]);
                                     } else {
                                         callback(null);
                                     }
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile the Homework for the given ID and pass the values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param course_id the ID of the Course
     * @param id the ID of the Homework
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_homework = function (callback, course_group_id, course_id, id, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.homework.hasOwnProperty(id)) {
            ret_val = callback(self.homework[id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/"
                                      + course_id + "/homework/" + id + "/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.homework[id] = data;
                                     callback(self.homework[id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Create a new Homework and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param course_id the ID of the Course
     * @param data the array of values to set for the new Homework
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.add_homework = function (callback, course_group_id, course_id, data, async) {
        async = typeof async === "undefined" ? true : async;
        self.homework_by_user_id = {};
        return $.ajax({
                          type: "POST",
                          url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + course_id
                               + "/homework/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Edit the Homework for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param course_id the ID of the Course
     * @param id the ID of the Homework
     * @param data the array of values to update for the Homework
     * @param async true if call should be async, false otherwise (default is true)
     * @param patch true if call should be patch instead of put, false otherwise (default is false)
     */
    this.edit_homework = function (callback, course_group_id, course_id, id, data, async, patch) {
        async = typeof async === "undefined" ? true : async;
        patch = typeof patch === "undefined" ? false : patch;
        delete self.homework[id];
        self.homework_by_user_id = {};
        return $.ajax({
                          type: patch ? "PATCH" : "PUT",
                          url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + course_id
                               + "/homework/" + id + "/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Delete the Homework for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param course_group_id the ID of the CourseGroup
     * @param course_id the ID of the Course
     * @param id the ID of the Homework
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.delete_homework = function (callback, course_group_id, course_id, id, async) {
        async = typeof async === "undefined" ? true : async;
        delete self.homework[id];
        self.homework_by_user_id = {};
        return $.ajax({
                          type: "DELETE",
                          url: helium.API_URL + "/planner/coursegroups/" + course_group_id + "/courses/" + course_id
                               + "/homework/" + id + "/",
                          async: async,
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Compile all Events for the given User ID and pass the values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     * @param start The start time window
     * @param end The end time window
     * @param search A search string to filter by
     */
    this.get_events = function (callback, async, use_cache, start, end, search) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        let cache_key = start + end + search;
        if (use_cache && self.events_by_user_id.hasOwnProperty(cache_key)) {
            ret_val = callback(self.events_by_user_id[cache_key]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/events/"
                                      + (start !== undefined ? "?start__gte=" + start : "")
                                      + (end !== undefined ? "&end__lt=" + end : "")
                                      + (helium.str_not_empty(search) ? "&search=" + search : ""),
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.events_by_user_id[cache_key] = data;
                                     callback(self.events_by_user_id[cache_key]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile the Event for the given ID and pass the values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the Event.
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     */
    this.get_event = function (callback, id, async, use_cache) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (id.lastIndexOf("event_", 0) === 0) {
            id = id.substr(6);
        }

        if (use_cache && self.event.hasOwnProperty(id)) {
            ret_val = callback(self.event[id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/planner/events/" + id + "/",
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.event[id] = data;
                                     callback(self.event[id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Create a new Event and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param data the array of values to set for the new Event
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.add_event = function (callback, data, async) {
        async = typeof async === "undefined" ? true : async;
        self.events_by_user_id = {};
        return $.ajax({
                          type: "POST",
                          url: helium.API_URL + "/planner/events/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Edit the Event for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the Event.
     * @param data the array of values to update for the Event
     * @param async true if call should be async, false otherwise (default is true)
     * @param patch true if call should be patch instead of put, false otherwise (default is false)
     */
    this.edit_event = function (callback, id, data, async, patch) {
        async = typeof async === "undefined" ? true : async;
        patch = typeof patch === "undefined" ? true : patch;

        if (id.lastIndexOf("event_", 0) === 0) {
            id = id.substr(6);
        }

        delete self.event[id];
        self.events_by_user_id = {};
        return $.ajax({
                          type: patch ? "PATCH" : "PUT",
                          url: helium.API_URL + "/planner/events/" + id + "/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Delete the Event for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the Event.
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.delete_event = function (callback, id, async) {
        async = typeof async === "undefined" ? true : async;

        if (id.lastIndexOf("event_", 0) === 0) {
            id = id.substr(6);
        }

        delete self.event[id];
        self.events_by_user_id = {};
        return $.ajax({
                          type: "DELETE",
                          url: helium.API_URL + "/planner/events/" + id + "/",
                          async: async,
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Compile all Calendar Sources for the given user and pass the values to the given callback function in JSON
     * format.
     *
     * @param callback function to pass response data and call after completion
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     * @param shown_on_calendar Only fetch enabled calendars
     */
    this.get_external_calendars = function (callback, async, use_cache, shown_on_calendar) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        if (use_cache && self.external_calendars_by_user_id.hasOwnProperty(helium.USER_PREFS.id)) {
            ret_val = callback(self.external_calendars_by_user_id[helium.USER_PREFS.id]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/feed/externalcalendars/"
                                      + (shown_on_calendar !== undefined && shown_on_calendar !== null
                                         ? "?shown_on_calendar=" + shown_on_calendar : ""),
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.external_calendars_by_user_id[helium.USER_PREFS.id] = data;
                                     callback(self.external_calendars_by_user_id[helium.USER_PREFS.id]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile all Events for the given External Calendar source and pass the values to the given callback function in
     * JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param id The ID of the ExternalCalendar.
     * @param async true if call should be async, false otherwise (default is true)
     * @param use_cache true if the call should attempt to used cache data, false if a database call should be made to
     *     refresh the cache (default to false)
     * @param start The start time window
     * @param end The end time window
     * @param search A search string to filter by
     */
    this.get_external_calendar_events = function (callback, id, async, use_cache, start, end, search) {
        async = typeof async === "undefined" ? true : async;
        use_cache = typeof use_cache === "undefined" ? false : use_cache;
        let ret_val;

        let cache_key = id + start + end + search;
        if (use_cache && self.external_calendar_events.hasOwnProperty(cache_key)) {
            ret_val = callback(self.external_calendar_events[cache_key]);
        } else {
            ret_val = $.ajax({
                                 type: "GET",
                                 url: helium.API_URL + "/feed/externalcalendars/" + id + "/events/"
                                      + (start !== undefined ? "?start__gte=" + start : "")
                                      + (end !== undefined ? "&end__lt=" + end : "")
                                      + (helium.str_not_empty(search) ? "&search=" + search : ""),
                                 async: async,
                                 dataType: "json",
                                 success: function (data) {
                                     self.external_calendar_events[cache_key] = data;
                                     callback(self.external_calendar_events[cache_key]);
                                 },
                                 error: function (jqXHR, textStatus, errorThrown) {
                                     document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                                 }
                             });
        }

        return ret_val;
    };

    /**
     * Compile all Reminders for the authenticated user.
     *
     * @param callback function to pass response data and call after completion
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.get_reminders = function (callback, async) {
        async = typeof async === "undefined" ? true : async;

        return $.ajax({
                          type: "GET",
                          url: helium.API_URL + "/planner/reminders/?sent=false&type=0&start_of_range__lte="
                               + moment().toISOString(),
                          async: async,
                          dataType: "json",
                          success: function (data) {
                              callback(data);
                          },
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Create a new Reminder and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param data the array of values to set for the new Reminder
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.add_reminder = function (callback, data, async) {
        async = typeof async === "undefined" ? true : async;
        self.events_by_user_id = {};
        return $.ajax({
                          type: "POST",
                          url: helium.API_URL + "/planner/reminders/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Compile the Reminder for the given ID and pass the values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the Reminder.
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.get_reminder = function (callback, id, async) {
        async = typeof async === "undefined" ? true : async;

        return $.ajax({
                          type: "GET",
                          url: helium.API_URL + "/planner/reminders/" + id + "/",
                          async: async,
                          dataType: "json",
                          success: function (data) {
                              callback(data);
                          },
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Edit the Reminder for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the Reminder
     * @param data the array of values to update for the Category
     * @param async true if call should be async, false otherwise (default is true)
     * @param patch true if call should be patch instead of put, false otherwise (default is false)
     */
    this.edit_reminder = function (callback, id, data, async, patch) {
        async = typeof async === "undefined" ? true : async;
        patch = typeof patch === "undefined" ? false : patch;

        return $.ajax({
                          type: patch ? "PATCH" : "PUT",
                          url: helium.API_URL + "/planner/reminders/" + id + "/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };

    /**
     * Edit the Reminder for the given ID and pass the returned values to the given callback function in JSON format.
     *
     * @param callback function to pass response data and call after completion
     * @param id the ID of the Reminder
     * @param data the array of values to update for the Category
     * @param async true if call should be async, false otherwise (default is true)
     */
    this.delete_reminder = function (callback, id, data, async) {
        async = typeof async === "undefined" ? true : async;

        return $.ajax({
                          type: "DELETE",
                          url: helium.API_URL + "/planner/reminders/" + id + "/",
                          async: async,
                          data: JSON.stringify(data),
                          dataType: "json",
                          success: callback,
                          error: function (jqXHR, textStatus, errorThrown) {
                              document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, callback);
                          }
                      });
    };
}

// Initialize HeliumPlannerAPI and give a reference to the Helium object
helium.planner_api = new HeliumPlannerAPI();

$(document).ready(function () {
    "use strict";
    if (!window.REDIRECTING && localStorage.getItem("access_token") !== null) {
        $.when.apply($, helium.ajax_calls).done(function () {
            helium.planner_api.get_reminders(function (data) {
                helium.process_reminders(data);
            });
        });

        window.setInterval(function () {
            helium.planner_api.get_reminders(function (data) {
                helium.process_reminders(data);
            });
        }, 60000);
    }
});
