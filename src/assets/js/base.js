/**
 * Copyright (c) 2025 Helium Edu
 *
 * Dynamic functionality shared among all pages.
 *
 * Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 * The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 * project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.15.11
 */

/**
 * Create the Helium persistence object.
 *
 * @constructor construct the Helium persistence object
 */
function Helium() {
    "use strict";

    this.REMINDER_OFFSET_TYPE_CHOICES = [
        "minutes",
        "hours",
        "days",
        "weeks"
    ];
    this.REMINDER_TYPE_CHOICES = [
        "Popup",
        "Email"
    ];

    this.QTIP_SHOW_INTERVAL = 250;
    this.QTIP_HIDE_INTERVAL = 100;

    // Variables to establish the current request/page the user is accessing
    this.APP_URL = window.APP_URL;
    this.API_URL = window.API_URL;
    this.CURRENT_PAGE_URL = document.URL;
    this.CURRENT_PAGE = this.CURRENT_PAGE_URL.split(this.APP_URL)[1];
    if (this.CURRENT_PAGE.substr(-1) === "/") {
        this.CURRENT_PAGE = this.CURRENT_PAGE.substr(0, this.CURRENT_PAGE.length - 1);
    }

    // This object gets initialized in the base template
    this.USER_PREFS = {};

    // Date/Time formats used between the client and server
    this.HE_DATE_STRING_SERVER = "YYYY-MM-DD";
    this.HE_TIME_STRING_SERVER = "HH:mm:ss";
    this.HE_DATE_STRING_CLIENT = "MMM D, YYYY";
    this.HE_TIME_STRING_CLIENT = "h:mm A";
    this.HE_DATE_TIME_STRING_CLIENT = this.HE_DATE_STRING_CLIENT + " " + this.HE_TIME_STRING_CLIENT;
    this.HE_REMINDER_DATE_STRING = "ddd, MMM DD";

    this.SMALL_LOADING_OPTS = {
        lines: 13,
        length: 4,
        width: 2,
        radius: 4,
        corners: 1,
        rotate: 0,
        direction: 1,
        color: "#000",
        speed: 1,
        trail: 60,
        shadow: false,
        hwaccel: false,
        className: "loading-mini",
        zIndex: 200,
        top: "-14px",
        left: "-20px"
    };
    this.FILTER_LOADING_OPTS = {
        lines: 13,
        length: 4,
        width: 2,
        radius: 4,
        corners: 1,
        rotate: 0,
        direction: 1,
        color: "#000",
        speed: 1,
        trail: 60,
        shadow: false,
        hwaccel: false,
        className: "loading-inline",
        zIndex: 200,
        top: "3px",
        left: "5px"
    };

    // Persistence objects within Helium
    this.ajax_calls = [];
    this.planner_api = null;
    this.settings = null;
    this.classes = null;
    this.calendar = null;
    this.materials = null;
    this.grades = null;

    /**
     * Check if the access token currently in localStorage has expired and needs refreshed.
     */
    this.check_token_exp = function () {
        const refresh_token = localStorage.getItem("refresh_token");
        // TODO: replace hacky lock mechanism with an actual when/wait method (that handles retries with fresh token)
        const refresh_token_lock = localStorage.getItem('refresh_token_lock');
        if (refresh_token === null || refresh_token_lock === "true") {
            return;
        }
        localStorage.setItem("refresh_token_lock", "true");

        const refresh_time = new Date((localStorage.getItem("access_token_exp") - 90) * 1000);
        if (new Date() > refresh_time) {
            helium.ajax_calls.push($.ajax({
                                              type: "POST",
                                              url: helium.API_URL + "/auth/token/refresh/",
                                              data: JSON.stringify({refresh: refresh_token}),
                                              dataType: "json",
                                              async: false,
                                              success: function (data) {
                                                  localStorage.setItem("access_token", data.access);
                                                  localStorage.setItem("refresh_token", data.refresh);
                                                  localStorage.setItem("access_token_exp",
                                                                       helium.parse_jwt(data.access).exp);

                                                  localStorage.setItem("refresh_token_lock", "false");
                                              }
                                          }));
        } else {
            localStorage.setItem("refresh_token_lock", "false");
        }
    }

    this.clear_access_token_reprompt_login = function () {
        this.clear_access_token();

        localStorage.setItem("status_type", "warning");
        localStorage.setItem("status_msg", "Please login again to continue.");

        window.location.href = "/login?next=" + window.location.pathname;
    }

    this.clear_access_token = function () {
        localStorage.removeItem("access_token");
        localStorage.removeItem("refresh_token");
        localStorage.removeItem("access_token_exp");
    }

    this.str_not_empty = function (str) {
        return str !== undefined && str !== null && str.trim() !== '';
    }

    /**
     * Parse the given JWT token to JSON.
     *
     * @param token The JWT token to parse
     */
    this.parse_jwt = function (token) {
        const base64_url = token.split('.')[1];
        const base64 = base64_url.replace(/-/g, '+').replace(/_/g, '/');
        const json_payload = decodeURIComponent(atob(base64).split('').map(function (c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));

        return JSON.parse(json_payload);
    }

    /**
     * From a given string (which may be a mathematical operation), convert the string to a percentage string.
     *
     * @param value the string to convert to a percentage value
     * @param last_good_value the last good percentage string value
     * @return the percentage value from the given string, or the last_good_value, if the given string was invalid
     */
    this.calculate_to_percent = function (value, last_good_value) {
        let split;
        // Remove any spaces before we try to be smart
        value = value.replace(/\s/g, "");
        // Drop the percent, if it exists
        if (value.match(/%$/)) {
            value = value.substring(0, value.length - 1);
        }
        // If this is a ratio, convert it to a percent
        if (value.indexOf("/") !== -1) {
            split = value.split("/");
            if (!isNaN(split[0]) && !isNaN(split[1])) {
                value = ((split[0] / split[1]) * 100).toString();
            } else {
                value = last_good_value;
            }
        } else if (isNaN(value)) {
            // Not sure what this value is, so drop in the last known value
            value = last_good_value;
        }
        // If the value we have is negative, drop in the last know value
        if (value < 0) {
            value = last_good_value;
        }
        // Ensure no more than three digits to the left of the decimal
        if (value.split(".")[0].length > 3) {
            value = last_good_value;
        }
        // Set the percentage string
        if (value !== "" && !isNaN(value)) {
            value = Math.round(value * 100) / 100 + "%";
        }
        return value;
    };

    /**
     * This function converts a database grade (in a fractional format) into a grade for display. If the grade is out
     * of 100, a simple percent is returned, otherwise the grade and points are returned.
     *
     * @param grade
     */
    this.grade_for_display = function (grade) {
        let split, value;
        if (grade.indexOf("/") !== -1) {
            split = grade.split("/");
            value = (parseFloat(split[0]) / parseFloat(split[1])) * 100;
        } else {
            value = grade;
        }

        return (Math.round(value * 100) / 100) + "%";
    };

    /**
     * Checks if data from the return of an Ajax call is valid or contains an error message.
     *
     * Note that value comparisons in this function are intentionally fuzzy, as they returned data type may not
     * necessarily be known.
     *
     * @param data the returned data object
     */
    this.data_has_err_msg = function (data) {
        return data !== undefined && data.length === 1 && data[0].hasOwnProperty("err_msg");
    };

    this.clear_storage = function () {
        localStorage.removeItem("filter_show_homework");
        localStorage.removeItem("filter_show_events");
        localStorage.removeItem("filter_show_external");
        localStorage.removeItem("filter_show_class");
        localStorage.removeItem("filter_categories");
        localStorage.removeItem("filter_complete");
        localStorage.removeItem("filter_overdue");
        localStorage.removeItem("filter_courses");
        localStorage.removeItem("filter_search_string");
        localStorage.removeItem("edit_calendar_item");
        localStorage.removeItem("edit_categories");
        localStorage.removeItem("course_id");
        localStorage.removeItem("DataTables_assignments-list-table_/planner/calendar/");
    }

    /**
     * Extract the error message from a response already know to have an error.
     *
     * @returns An HTML formatted error response.
     */
    this.get_error_msg = function (data) {
        const response = data[0];
        // If responseJSON exists, we can likely find a more detailed message to be parsed
        if (response.hasOwnProperty('jqXHR') &&
            response.jqXHR !== undefined &&
            response.jqXHR.hasOwnProperty('responseJSON') &&
            response.jqXHR.responseJSON !== undefined &&
            response.jqXHR.responseJSON.hasOwnProperty('detail')) {
            // TODO: we could parse more API responses here, but may make more sense to just wait and improve error
            //  handling when we rebuild the entire UI
            return response.jqXHR.responseJSON.detail;
        } else {
            return response.err_msg
        }
    };

    this.bytes_to_size = function (bytes) {
        const sizes = ['bytes', 'KB', 'MB', 'GB', 'TB'];
        if (bytes === 0) {
            return '0 ' + sizes[0];
        }
        const i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
        return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i];
    };

    /**
     * Retrieve the string with proper HTML (for table view) for comments.
     */
    this.get_comments_with_link = function (comment_str) {
        return comment_str.replace(
            /(http|ftp|https):\/\/([-\w_]+(?:(?:\.[-\w_]+)+))([-\w\.,@?^=%&amp;:/~\+#]*[-\w\@?^=%&amp;/~\+#])?/g,
            function (str) {
                return "<a target=\"_blank\" class=\"title-with-link\" href=\"" + str + "\">" + str + "</a>";
            });
    };

    this.clear_form_errors = function (selector) {
        $("#status_" + selector.split("-form")[0]).html("").removeClass("alter-danger").removeClass("alter-warning")
            .addClass("hidden");

        $("#" + selector + " *").filter(':input').each(function (index, data) {
            if ($(data).attr("id") !== undefined) {
                $($(data).parent()).removeClass("has-error");
                $("#status_" + $(data).attr("id").substring(3)).html("").addClass("hidden");
            }
        });
    };

    this.show_error = function (form_id, selector, error_msg) {
        const status_tag = $("#status_" + selector);
        if (status_tag.length > 0) {
            $($("#id_" + selector).parent()).addClass("has-error");
            status_tag.html(error_msg).removeClass("hidden");
        } else {
            $("#status_" + form_id).html(error_msg).addClass("alert-warning").removeClass("hidden");
        }
    };

    this.add_reminder_to_page = function (data) {
        let type = "system";
        let start = moment(data.start_of_range);
        let id_str = "reminder-system-" + data.id;
        if (data.homework !== null) {
            type = "homework";
            id_str = "reminder-for-homework-" + data.homework.id;
            start = moment(data.homework.start);
        } else if (data.event !== null) {
            type = "event";
            id_str = "reminder-for-event-" + data.event.id;
            start = moment(data.event.start);
        }

        const list_item = $('<li id="reminder-popup-' + data.id
                            + '" class="reminder-popup"><button type="button" aria-label="Dismiss Reminder"  class="close reminder-close"><i class="icon-remove"></i></button></li>');
        const reminder_body = $('<span class="reminder-msg-body cursor-hover" id="' + id_str + '"></span>');
        list_item.append(reminder_body);

        const msg_body = $('<span class="msg-body">');
        reminder_body.append(msg_body);
        if (type === "homework") {
            msg_body.append(
                '<span class="msg-title"><span class="blue">(' + data.homework.course.title + ') ' + data.homework.title
                + '</span> ' + data.message + '</span>');
        } else if (type === "event") {
            msg_body.append(
                '<span class="msg-title"><span class="blue">(Event) ' + data.event.title + '</span> ' + data.message
                + '</span>');
        }

        const msg_time = $('<span class="msg-time">');
        reminder_body.append(msg_time);
        msg_time.append('<i class="icon-time"></i>');
        msg_time.append('<span>&nbsp;' + start.format(helium.HE_REMINDER_DATE_STRING) + ' at ' + start.format(
            helium.HE_TIME_STRING_CLIENT) + '</span>');

        list_item.find('.reminder-close').on("click", function () {
            helium.ajax_error_occurred = false;

            const put_data = {
                'sent': true
            }, reminder_div = $(this).parent();
            helium.planner_api.edit_reminder(function (data) {
                if (helium.data_has_err_msg(data)) {
                    helium.ajax_error_occurred = true;

                    bootbox.alert(helium.get_error_msg(data));
                } else {
                    const reminder_bell_tag = $("#reminder-bell-count");
                    const new_count = parseInt(reminder_bell_tag.text()) - 1;
                    reminder_div.hide();

                    reminder_bell_tag.html(new_count + " Reminder" + (new_count > 1 ? "s" : ""));
                    const reminder_bell_alt_tag = $("#reminder-bell-alt-count");
                    reminder_bell_alt_tag.html(new_count);
                    if (new_count === 0) {
                        reminder_bell_alt_tag.hide("fast");
                    }
                }
            }, data.id, put_data, true, true);
        });
        list_item.find('[id^="reminder-for-"]').on("click", function () {
            let id = $(this).attr("id").split("reminder-for-")[1];
            if (id.indexOf("event-") !== -1) {
                id = id.replace("-", "_");
            } else {
                id = id.split("-")[1];
            }

            if (location.href.indexOf('/planner/calendar') !== -1) {
                if ($('#calendar').data('fullCalendar')) {
                    helium.calendar.current_calendar_item = $("#calendar").fullCalendar("clientEvents", [id])[0];
                }
                // If current_calendar_item was set, the event is currently in view on a loaded calendar; otherwise
                // we'll need to query the database
                if (helium.calendar.current_calendar_item === undefined) {
                    helium.calendar.loading_div.spin(helium.SMALL_LOADING_OPTS);

                    const callback = function (data) {
                        if (helium.data_has_err_msg(data)) {
                            helium.ajax_error_occurred = true;
                            helium.calendar.loading_div.spin(false);

                            bootbox.alert(helium.get_error_msg(data));
                        } else {
                            if (data.calendar_item_type === 0) {
                                data.id = "event_" + data.id;
                            }
                            helium.calendar.edit_calendar_item_btn(data);
                        }
                    };
                    if (id.startsWith("event_")) {
                        helium.planner_api.get_event(callback, id, true, true);
                    } else {
                        helium.planner_api.get_homework_by_id(callback, id, true, true);
                    }
                } else {
                    helium.calendar.edit_calendar_item_btn(helium.calendar.current_calendar_item);
                }
            } else {
                localStorage.setItem("edit_calendar_item", id);
                window.location = "/planner/calendar";
            }
        });

        $($($("#reminder-bell-count").parent()).parent()).append(list_item);
    };

    this.process_reminders = function (data) {
        if (!helium.data_has_err_msg(data)) {
            $("[id^='reminder-popup-']").remove();

            $.each(data, function (i, reminder_data) {
                helium.add_reminder_to_page(reminder_data);
            });

            $("#reminder-bell-count").html(data.length + " Reminder" + (data.length > 1 ? "s" : ""));
            const reminder_bell_alt_tag = $("#reminder-bell-alt-count");
            reminder_bell_alt_tag.html(data.length);
            if (data.length > 0) {
                reminder_bell_alt_tag.show("fast");
            } else {
                reminder_bell_alt_tag.hide("fast");
            }
        }
    };
}

// Initialize the Helium object
const helium = new Helium();

// Initialize AJAX configuration
$.ajaxSetup({
                beforeSend: function (jqXHR, options) {
                    "use strict";

                    jqXHR.url = options.url;

                    if (!(/^(GET|HEAD|OPTIONS|TRACE)$/.test(options.type))) {
                        // Send the token to same-origin, relative URLs only.
                        // Send the token only if the method warrants CSRF protection
                        // Using the CSRFToken value acquired earlier
                        jqXHR.setRequestHeader("X-CSRFToken", Cookies.get("csrftoken"));
                    }
                    const access_token = localStorage.getItem("access_token");
                    if (access_token !== null &&
                        options.url !== helium.API_URL + "/info/" &&
                        options.url !== helium.API_URL + "/auth/token/refresh/") {
                        helium.check_token_exp();

                        jqXHR.setRequestHeader("Authorization", "Bearer " + access_token);
                    }
                },
                contentType: "application/json; charset=UTF-8"
            });

$(document).ajaxError(function (event, jqXHR, textStatus, errorThrown) {
    if (jqXHR.status === 401 &&
        jqXHR.url.startsWith(helium.API_URL) &&
        jqXHR.url !== helium.API_URL + "/info" &&
        !jqXHR.url.startsWith(helium.API_URL + "/auth/token") &&
        // TODO: this isn't ideal, but will work for now, since the reminder check also effectively acts as a
        //  heartbeat for token refresh token refresh
        !jqXHR.url.startsWith(helium.API_URL + "/planner/reminders")) {
        helium.clear_access_token_reprompt_login();
    }
});

$(document).ready(function () {
    "use strict";

    helium.check_token_exp();

    if (!window.REDIRECTING && localStorage.getItem("access_token") !== null) {
        helium.ajax_calls.push($.ajax(
            {
                type: "GET",
                url: helium.API_URL + "/auth/user/",
                dataType: "json",
                async: false,
                success: function (data) {
                    $.extend(helium.USER_PREFS, data);

                    localStorage.setItem("refresh_token_lock", "false");

                    if (helium.USER_PREFS.profile !== null
                        && helium.USER_PREFS.profile.phone
                        !== null) {
                        helium.REMINDER_TYPE_CHOICES.push("Text");
                    }

                    if (typeof Rollbar !== "undefined") {
                        Rollbar.configure(
                            {
                                payload: {
                                    person: {
                                        id: helium.USER_PREFS.id
                                    }
                                }
                            });
                    }
                }
            }));
    }

    $(".open-website button").on("click", function () {
        window.open($("#" + $(this).attr("for")).val());
    });

    $("#" + $(".open-website button").attr("for")).focusout(function () {
        if ($(this).val() === "") {
            $(".open-website button").attr("disabled", "disabled");
        } else {
            $(".open-website button").attr("disabled", null);
        }
    });

    $.each($(".help-button"), function () {
        $(this).popover({html: true}).data("bs.popover").tip().css("z-index", 1060);
    });

    let pathname = window.location.pathname.replace(/\/+$/, '');

    const current_nav = $('a[href="' + pathname + '"]');
    if (current_nav) {
        if (pathname === "/settings") {
            $("#authenticated-dropdown-nav").addClass("active");
        } else {
            current_nav.parent().addClass("active");
        }
    }

    if (localStorage.getItem("access_token") !== null) {
        $("#planned-nav").removeClass("hidden");
        $("#reminder-nav").removeClass("hidden");
        $("#authenticated-dropdown-nav").removeClass("hidden");
    } else {
        $("#register-nav").removeClass("hidden");
        $("#login-nav").removeClass("hidden");
    }
});
