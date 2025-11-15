/**
 * Copyright (c) 2025 Helium Edu
 *
 * JavaScript functionality for persistence and the HeliumCalendar object on the /planner/calendar page.
 *
 * Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 * The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 * project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.17.18
 */

/**
 * Create the HeliumCalendar persistence object.
 *
 * @constructor construct the HeliumCalendar persistence object
 */
function HeliumCalendar() {
    "use strict";

    this.DEFAULT_VIEWS = ["month", "agendaWeek", "agendaDay", "listWeek", "assignmentsList"];
    this.DONE_TYPING_INTERVAL = 500;

    this.loading_div = null;

    this.last_view = null;
    this.edit = false;
    this.init_calendar_item = false;
    this.current_class_id = -1;
    this.start = null;
    this.end = null;
    this.all_day = null;
    this.show_end_time = null;
    this.current_calendar_item = null;
    this.calendar_item_for_dropzone = null;
    this.preferred_material_ids = null;
    this.preferred_category_name = null;
    this.reminder_unsaved_pk = 0;
    this.typing_timer = 0;
    this.last_good_grade = "";
    this.last_type_event = false;
    this.last_good_date = null;
    this.last_good_end_date = null;
    this.last_search_string = "";
    this.dropzone = null;
    this.is_resizing_calendar_item = false;
    this.course_groups = {};
    this.courses = {};
    this.external_calendars = {};

    let self = this;

    /*******************************************
     * Functions
     ******************************************/

    /**
     * Revert persistence for adding/editing a Homework.
     */
    this.nullify_calendar_item_persistence = function () {
        self.edit = false;
        self.start = null;
        self.end = null;
        self.current_class_id = -1;
        self.current_course_group_id = -1;
        self.all_day = null;
        self.show_end_time = null;
        self.current_calendar_item = null;
        self.preferred_category_name = null;
        self.preferred_material_ids = null;
        self.reminder_unsaved_pk = 0;
        self.last_good_grade = "";
        self.is_resizing_calendar_item = false;
        helium.ajax_error_occurred = false;
    };

    /**
     * Clear Homework marked in the Homework modal.
     */
    this.clear_calendar_item_errors = function () {
        helium.ajax_error_occurred = false;
        $("#homework-title").parent().parent().removeClass("has-error");
        $("#homework-start-date").parent().parent().removeClass("has-error");
        $("#homework-end-date").parent().parent().removeClass("has-error");
        $("#homework-category").parent().parent().removeClass("has-error");
    };

    /**
     * Retrieve the course from the given list with the given ID.
     *
     * @param courses the list of courses
     * @param pk the key to look for
     */
    this.get_course_from_list_by_pk = function (courses, pk) {
        let i, course = null;

        for (i = 0; i < courses.length; i += 1) {
            if (courses[i].id === parseInt(pk)) {
                course = courses[i];
                break;
            }
        }

        return course;
    };

    /**
     * Reset filters from storage, if applicable.
     */
    this.reset_filters = function () {
        if (!helium.USER_PREFS.settings.remember_filter_state) {
            localStorage.removeItem("filter_show_homework");
            localStorage.removeItem("filter_show_events");
            localStorage.removeItem("filter_show_external");
            localStorage.removeItem("filter_show_class");
            localStorage.removeItem("filter_categories");
            localStorage.removeItem("filter_complete");
            localStorage.removeItem("filter_overdue");
            localStorage.removeItem("filter_courses");
        }

        localStorage.removeItem("filter_search_string");
    };

    this.init_filters = function () {
        if (helium.USER_PREFS.settings.remember_filter_state) {
            let courses = localStorage.getItem("filter_courses");
            if (courses) {
                $.each(courses.split(","), function (index, course_id) {
                    let course_selector = $("#calendar-filter-course-" + course_id);
                    if (course_selector.length === 1) {
                        course_selector.prop("checked", true);
                    }
                });
            }

            $("#calendar-filter-homework")
                .prop("checked", localStorage.getItem("filter_show_homework") === "true");
            $("#calendar-filter-events").prop("checked", localStorage.getItem("filter_show_events") === "true");
            $("#calendar-filter-external")
                .prop("checked", localStorage.getItem("filter_show_external") === "true");
            $("#calendar-filter-class").prop("checked", localStorage.getItem("filter_show_class") === "true");
            $("#calendar-filter-categories")
                .prop("checked", localStorage.getItem("filter_categories") === "true");
            $("#calendar-filter-overdue").prop("checked", localStorage.getItem("filter_overdue") === "true");
            let filter_complete = localStorage.getItem("filter_complete");
            if (filter_complete) {
                if (filter_complete === "true") {
                    $("#calendar-filter-complete").prop("checked", true);
                } else {
                    $("#calendar-filter-incomplete").prop("checked", true);
                }
            } else {
                $("#calendar-filter-complete").prop("checked", false);
                $("#calendar-filter-incomplete").prop("checked", false);
            }

            let category_names = localStorage.getItem("filter_categories");
            if (category_names) {
                $.each(category_names.split(","), function (index, category_name_encoded) {
                    let category_name = decodeURIComponent(category_name_encoded).replace(/^'|'$/g, '');
                    $("#calendar-filter-list").find("[data-str=\"" + category_name + "\"]").prop("checked", true);
                });
            }

            if ($("#calendar-classes-list").find($("[id^='calendar-filter-course-']:checked")).length > 0) {
                $("#calendar-classes button").addClass("fc-state-active");
            }
            if ($("#calendar-filter-list").find($("[id^='calendar-filter-']:checked")).length > 0) {
                $("#calendar-filters button").addClass("fc-state-active");
            }
        }
    }

    /**
     * Drop an event after it is finished being dragged.
     *
     * @param event the event being dropped
     */
    this.drop_calendar_item = function (event) {
        let all_day = false;
        if (!event.start.hasTime()) {
            all_day = true;
        }

        event.start = $("#calendar").fullCalendar("getCalendar").moment(moment(event.start.format()).format());
        event.end = $("#calendar").fullCalendar("getCalendar").moment(moment(event.end.format()).format());

        helium.ajax_error_occurred = false;

        self.loading_div.spin(helium.SMALL_LOADING_OPTS);

        self.current_calendar_item = event;
        const callback = function (data) {
            if (helium.data_has_err_msg(data)) {
                helium.ajax_error_occurred = true;
                self.loading_div.spin(false);

                bootbox.alert(helium.get_error_msg(data));
            } else {
                // If start does not have a time, this is an all day event
                if (!self.current_calendar_item.start.hasTime()) {
                    const start_end_days_diff = self.current_calendar_item.end ? self.current_calendar_item.end.diff(
                        self.current_calendar_item.start, "days") : 1;
                    self.start = self.current_calendar_item.start;
                    self.end =
                        self.current_calendar_item.start.hasTime() ? self.current_calendar_item.end
                                                                   : (start_end_days_diff <= 1
                                                                      ? self.current_calendar_item.start.clone().add(
                                                                           helium.USER_PREFS.settings.all_day_offset, "minutes")
                                                                      : self.current_calendar_item.end.clone());
                } else {
                    self.start = self.current_calendar_item.start;
                    self.end =
                        self.current_calendar_item.end || self.current_calendar_item.start.clone()
                                                           .add(helium.USER_PREFS.settings.all_day_offset, "minutes");
                }
            }
        };
        if (event.calendar_item_type === 0) {
            helium.ajax_calls.push(helium.planner_api.get_event(callback, event.id));
        } else {
            const course = helium.calendar.courses[event.course];

            helium.ajax_calls.push(helium.planner_api.get_homework(callback, course.course_group, course.id, event.id));
        }

        $.when.apply($, helium.ajax_calls).done(function () {
            if (!helium.ajax_error_occurred) {
                const data = {
                    "start": self.start.toISOString(),
                    "end": self.end.toISOString(),
                    "allDay": all_day,
                    "all_day": all_day
                };
                const callback = function (data) {
                    const calendar_item = data;

                    if (calendar_item.calendar_item_type === 0) {
                        calendar_item.id = "event_" + calendar_item.id;
                    }

                    self.update_current_calendar_item(calendar_item, false);

                    self.nullify_calendar_item_persistence();

                    self.loading_div.spin(false);
                };
                if (event.calendar_item_type === 0) {
                    helium.planner_api.edit_event(callback, event.id, data, true, true);
                } else {
                    const course = helium.calendar.courses[event.course];

                    helium.planner_api.edit_homework(callback, course.course_group, course.id, event.id, data,
                                                     true, true);
                }
            }
        });
    };

    /**
     * Resize an event after it is finished being resized.
     *
     * @param event the event being resized
     */
    this.resize_calendar_item = function (event) {
        event.start = $("#calendar").fullCalendar("getCalendar").moment(moment(event.start.format()).format());
        event.end = $("#calendar").fullCalendar("getCalendar").moment(moment(event.end.format()).format());

        self.is_resizing_calendar_item = true;
        helium.ajax_error_occurred = false;

        let data;

        self.loading_div.spin(helium.SMALL_LOADING_OPTS);

        self.current_calendar_item = event;
        self.start = event.start;
        self.end = event.end;
        data = {
            "start": self.start.toISOString(),
            "end": self.end.toISOString()
        };
        const callback = function (data) {
            if (helium.data_has_err_msg(data)) {
                self.is_resizing_calendar_item = false;
                helium.ajax_error_occurred = true;
                self.loading_div.spin(false);

                bootbox.alert(helium.get_error_msg(data));
            } else {
                const calendar_item = data;

                if (calendar_item.calendar_item_type === 0) {
                    calendar_item.id = "event_" + calendar_item.id;
                }

                self.update_current_calendar_item(calendar_item, false);

                self.nullify_calendar_item_persistence();

                self.loading_div.spin(false);

                self.is_resizing_calendar_item = false;
            }
        };
        if (event.calendar_item_type === 0) {
            helium.planner_api.edit_event(callback, event.id, data, true, true);
        } else {
            const course = helium.calendar.courses[event.course];

            helium.planner_api.edit_homework(callback, course.course_group, course.id, event.id, data, true, true);
        }
    };

    /**
     * Clicking on the calendar triggers an event being added, which will bring up the Homework modal.
     *
     * @param start the start date/time of the event being added
     * @param end the end date/time of the event being added
     * @param event the jQuery event
     * @param view the current view of the calendar
     * @param calendar_item_type 0 for event, 1 for homework, 2 for course
     */
    this.add_calendar_item_btn = function (start, end, event, view, calendar_item_type) {
        calendar_item_type = typeof calendar_item_type === "undefined" ? self.last_type_event : calendar_item_type;

        const start_end_days_diff = end.diff(start, "days");
        self.init_calendar_item = true;
        self.edit = false;

        self.reminders_to_delete = [];
        self.attachments_to_delete = [];

        if ($("[id^='calendar-filter-course-']").length > 0) {
            $("#homework-event-switch").parent().show();
        } else {
            $("#homework-event-switch").parent().hide();

            calendar_item_type = 0;
        }
        $("#delete-homework").hide();
        $("#clone-homework").hide();
        $('a[href="#homework-panel-tab-1"]').tab("show");

        self.start = start;
        self.end =
            (start.hasTime && start.hasTime()) ? end : (start_end_days_diff <= 1 ? start.clone()
                .add(helium.USER_PREFS.settings.all_day_offset, "minutes") : end.clone());
        self.all_day = start.hasTime && !start.hasTime();
        self.show_end_time =
            !self.all_day || (($("#calendar").fullCalendar("getView").name === self.DEFAULT_VIEWS[0] || $("#calendar")
                              .fullCalendar("getView").name === self.DEFAULT_VIEWS[1]) && start_end_days_diff > 1);
        // If we're adding an all-day event spanning multiple days, correct the end date to be offset by one
        if (self.all_day && !self.start.isSame(self.end, 'day')) {
            self.end = self.end.subtract(1, "days");
        }

        if ($("#homework-class option").length <= 1) {
            $("#homework-class-form-group").hide("fast");
        } else {
            $("#homework-class-form-group").show("fast");
        }

        // Set the preferred IDs, which will be set when the global event is triggered selecting the course
        self.preferred_material_ids = null;
        self.preferred_category_name = null;

        if ($("[id^='calendar-filter-course-']").length > 0) {
            $("#homework-class").trigger("chosen:updated");
            $("#homework-class").trigger("change");
        } else {
            self.start.hour(12);
            self.start.minute(0);
            if (!self.all_day) {
                self.end.hour(12);
                self.end.minute(50);
            } else {
                self.end.hour(12);
                self.end.minute(helium.USER_PREFS.settings.all_day_offset);
            }
        }

        if (calendar_item_type === 0) {
            $("#homework-event-switch").prop("checked", true).trigger("change");
        } else {
            $("#homework-event-switch").prop("checked", false).trigger("change");
        }

        $("#homework-title").val("");
        $("#homework-start-date").datepicker("setDate", self.start.toDate());
        $("#homework-end-date").datepicker("setDate", self.end.toDate());
        $("#homework-all-day").prop("checked", self.all_day).trigger("change");
        $("#homework-show-end-time").prop("checked", self.show_end_time).trigger("change");
        $("#homework-priority > span").slider("value", "50");
        $("#homework-completed").prop("checked", false).trigger("change");
        $("#homework-grade").val("");
        $("#homework-grade-percent > span").text("");
        $("#homework-comments").html("");

        $("tr[id^='attachment-']").remove();
        $("#no-attachments").show();
        if (self.dropzone !== null) {
            self.dropzone.removeAllFiles();
        }

        $("tr[id^='reminder-']").remove();
        $("#no-reminders").show();

        $("#loading-homework-modal").spin(false);
        $("#homework-modal").modal("show");
        $("#calendar").fullCalendar("unselect");
        self.init_calendar_item = false;
    };

    /**
     * Delete an attachment from the list of attachments.
     */
    this.delete_attachment = function () {
        const dom_id = $(this).attr("id");
        let id = dom_id.split("-");
        id = id[id.length - 1];
        helium.calendar.attachments_to_delete.push(id);

        if ($("#attachments-table-body").children().length === 1) {
            $("#no-attachments").show();
        }
        $("#attachment-" + $(this).attr("id").split("delete-attachment-")[1]).hide("fast", function () {
            $(this).remove();
            if ($("#attachments-table-body").children().length === 1) {
                $("#no-attachments").show();
            }
        });
    };

    this.on_day_of_week = function (schedule, day) {
        if (schedule == null) {
            return false;
        }

        return schedule.days_of_week.substring(day, day + 1) == '1';
    };

    this.same_time = function (schedule) {
        return (
            (schedule.sun_start_time == schedule.mon_start_time &&
            schedule.sun_start_time == schedule.tue_start_time &&
            schedule.sun_start_time == schedule.wed_start_time &&
            schedule.sun_start_time == schedule.thu_start_time &&
            schedule.sun_start_time == schedule.fri_start_time &&
            schedule.sun_start_time == schedule.sat_start_time)
            &&
            (schedule.sun_end_time == schedule.mon_end_time &&
            schedule.sun_end_time == schedule.tue_end_time &&
            schedule.sun_end_time == schedule.wed_end_time &&
            schedule.sun_end_time == schedule.thu_end_time &&
            schedule.sun_end_time == schedule.fri_end_time &&
            schedule.sun_end_time == schedule.sat_end_time)
        )
    };

    this.has_schedule = function (schedule) {
        return schedule.days_of_week !== '0000000' || !self.same_time(schedule);
    };

    /**
     * Clicking on a calendar item on the calendar triggers an event being edited, which will bring up the Homework
     * modal.
     *
     * @param calendar_item the homework or event being edited
     * @param jsEvent the event that triggered the callback
     */
    this.edit_calendar_item_btn = function (calendar_item, jsEvent) {
        helium.ajax_error_occurred = false;

        let ret_val = true, i = 0;
        // If what we've clicked on is an external source with a URL, open in a new window
        if ((calendar_item.calendar_item_type === 2 || calendar_item.calendar_item_type === 3)
            && helium.str_not_empty(calendar_item.url)) {
            window.open(calendar_item.url);
            ret_val = false;
        } else {
            // If the click is on a homework's checkbox, fall to the "else" block
            if (calendar_item.calendar_item_type !== 1 || jsEvent === undefined ||
                !$(jsEvent.target).is(':checkbox')) {
                if (!self.edit) {
                    self.loading_div.spin(helium.SMALL_LOADING_OPTS);
                    self.init_calendar_item = true;
                    self.edit = true;

                    self.reminders_to_delete = [];
                    self.attachments_to_delete = [];

                    $("#homework-event-switch").parent().hide();
                    $("#delete-homework").show();
                    $("#clone-homework").show();

                    self.current_calendar_item = calendar_item;
                    // Initialize dialog attributes for editing
                    const callback = function (data) {
                        if (helium.data_has_err_msg(data)) {
                            helium.ajax_error_occurred = true;
                            self.loading_div.spin(false);
                            $("#loading-homework-modal").spin(false);
                            self.init_calendar_item = false;
                            self.edit = false;

                            bootbox.alert(helium.get_error_msg(data));
                        } else {
                            const calendar_item_fields = data;

                            // Change display to the first tab
                            $('a[href="#homework-panel-tab-1"]').tab("show");

                            self.start = moment(calendar_item_fields.start);
                            self.end = moment(calendar_item_fields.end);
                            self.all_day = calendar_item_fields.all_day;
                            self.show_end_time = calendar_item_fields.show_end_time;
                            // If we're adding an all-day event spanning multiple days, correct the end date to be
                            // offset by one
                            if (self.all_day && !self.start.isSame(self.end, "day")) {
                                self.end = self.end.subtract(1, "days");
                            }

                            if ($("#homework-class option").length <= 1 || $("#homework-event-switch")
                                .is(":checked")) {
                                $("#homework-class-form-group").hide("fast");
                            } else {
                                $("#homework-class-form-group").show("fast");
                            }

                            if (calendar_item_fields.calendar_item_type === 1) {
                                // Set the preferred IDs, which will be set when the global event is triggered
                                // selecting the course
                                self.preferred_material_ids = [];
                                if (calendar_item_fields.materials) {
                                    $.each(calendar_item_fields.materials, function (index, id) {
                                        self.preferred_material_ids.push(id);
                                    });
                                }

                                if (calendar_item_fields.category) {
                                    self.preferred_category_name = self.categories[calendar_item_fields.category].title;
                                }

                                $("#homework-class").val(helium.calendar.courses[calendar_item_fields.course].id);

                                // Triggering this class change is also what triggers the all day/end time checkboxes
                                // to be triggered
                                $("#homework-class").trigger("chosen:updated");
                                $("#homework-class").trigger("change");

                                $("#homework-event-switch").prop("checked", false).trigger("change");
                            } else {
                                $("#homework-event-switch").prop("checked", true).trigger("change");

                                // This function usually is triggered in #homework-class, but that won't get triggered
                                // for events
                                self.set_timing_fields();
                            }

                            $("#homework-title").val(calendar_item_fields.title);

                            $("#homework-start-date").datepicker("setDate", self.start.toDate());
                            $("#homework-end-date").datepicker("setDate", self.end.toDate());
                            $("#homework-all-day").prop("checked", calendar_item_fields.all_day).trigger("change");
                            $("#homework-show-end-time").prop("checked", calendar_item_fields.show_end_time)
                                .trigger("change");
                            $("#homework-priority > span").slider("value", calendar_item_fields.priority);
                            $("#homework-completed").prop("checked", calendar_item_fields.completed).trigger("change");
                            if (calendar_item_fields.calendar_item_type === 1) {
                                self.last_good_grade =
                                    calendar_item_fields.current_grade !== "-1/100" ? calendar_item_fields.current_grade
                                                                                    : "";
                                $("#homework-grade").val(self.last_good_grade);
                                self.homework_render_percentage(self.last_good_grade);
                            } else {
                                $("#homework-grade-percent > span").text("");
                            }
                            $("#homework-comments").html(calendar_item_fields.comments);

                            $("tr[id^='attachment-']").remove();
                            if (calendar_item_fields.attachments.length === 0) {
                                $("#no-attachments").show();
                            } else {
                                $("#no-attachments").hide();
                            }
                            if (self.dropzone !== null) {
                                self.dropzone.removeAllFiles();
                            }

                            for (i = 0; i < calendar_item_fields.attachments.length; i += 1) {
                                $("#attachments-table-body").append(
                                    "<tr id=\"attachment-" + calendar_item_fields.attachments[i].id + "\"><td>"
                                    + calendar_item_fields.attachments[i].title + "</td><td>" + helium.bytes_to_size(
                                                               parseInt(calendar_item_fields.attachments[i].size))
                                    + "</td><td><div class=\"btn-group\"><a class=\"btn btn-xs btn-success\" download target=\"_blank\" href=\""
                                    + calendar_item_fields.attachments[i].attachment
                                    + "\"><i class=\"icon-cloud-download bigger-120\"></i></a> <button class=\"btn btn-xs btn-danger\" aria-label=\"Delete Attachment\" id=\"delete-attachment-"
                                    + calendar_item_fields.attachments[i].id
                                    + "\"><i class=\"icon-trash bigger-120\"></i></button></div></td></tr>");
                                $("#delete-attachment-" + calendar_item_fields.attachments[i].id)
                                    .on("click", self.delete_attachment);
                            }

                            $("tr[id^='reminder-']").remove();
                            $("#no-reminders").show();

                            self.reminder_unsaved_pk = calendar_item_fields.reminders.length + 1;
                            for (i = 0; i < calendar_item_fields.reminders.length; i += 1) {
                                self.add_reminder_to_table(calendar_item_fields.reminders[i], false);
                            }

                            self.loading_div.spin(false);
                            $("#loading-homework-modal").spin(false);
                            $("#homework-modal").modal("show");
                            self.init_calendar_item = false;
                        }
                    };
                    if (calendar_item.calendar_item_type === 0) {
                        helium.planner_api.get_event(callback, calendar_item.id, true, false);
                    } else if (calendar_item.calendar_item_type === 1) {
                        const course = helium.calendar.courses[calendar_item.course];

                        helium.planner_api.get_homework(callback, course.course_group, course.id, calendar_item.id,
                                                        true, false);
                    } else {
                        self.loading_div.spin(false);
                        self.init_calendar_item = false;
                        self.edit = false;
                    }
                }
            } else {
                helium.ajax_error_occurred = false;

                let completed = $(jsEvent.target).is(":checked"), data;
                helium.calendar.loading_div.spin(helium.SMALL_LOADING_OPTS);

                const course = helium.calendar.courses[calendar_item.course];

                data = {"completed": completed};
                helium.planner_api.edit_homework(function (data) {
                    self.homework_by_course_id = {};
                    self.homework_by_user_id = {};

                    if (helium.data_has_err_msg(data)) {
                        helium.ajax_error_occurred = true;
                        helium.calendar.loading_div.spin(false);

                        bootbox.alert(helium.get_error_msg(data));
                    } else {
                        helium.calendar.update_current_calendar_item(data, false);

                        helium.calendar.nullify_calendar_item_persistence();

                        helium.calendar.loading_div.spin(false);
                    }
                }, course.course_group, course.id, calendar_item.id, data, true, true);
            }
        }

        return ret_val;
    };

    /**
     * Render the grade percentage display based on the given grade, assuming it should be shown.
     *
     * @param grade the grade string for display
     */
    this.homework_render_percentage = function (grade) {
        if (grade.indexOf("/") !== -1) {
            $("#homework-grade-percent > span").text(helium.grade_for_display(grade));
        } else if (grade.indexOf("%") !== -1) {
            // The grade is already prepped, so just display it
            $("#homework-grade-percent > span").text(grade);
        } else {
            $("#homework-grade-percent > span").text("");
        }
    };

    /**
     * Handle a click on a parent element that contains a checkbox, and trigger that checkbox.
     */
    this.trigger_child_checkbox = function (event) {
        if (!$(event.target).is(':checkbox') && !$(event.target).is('label')) {
            const checkbox = $(this).find("input:checkbox");
            checkbox.prop("checked", !checkbox.is(":checked")).trigger("change");
        }
    };

    /**
     * Adjust the calendar size based on the current viewport.
     */
    this.adjust_calendar_size = function () {
        const calendar = $("#calendar");

        calendar.fullCalendar("option", "height", $(window).height() - 70);

        // The comparison operators here are intentionally vague, as they check for both null and undefined
        if ($(document).width() < 768 && self.last_view === null) {
            if (calendar.fullCalendar("getView").name !== "agendaDay" && calendar.fullCalendar("getView").name
                !== "assignmentsList") {
                self.last_view = calendar.fullCalendar("getView").name;
                calendar.fullCalendar("changeView", "listWeek");
            }
        } else if ($(document).width() >= 768 && self.last_view !== null) {
            if (calendar.fullCalendar("getView").name !== self.last_view) {
                calendar.fullCalendar("changeView", self.last_view);
            }
            self.last_view = null;
        }
    };

    /**
     * Refresh the filters based on the current filter selection.
     */
    this.refresh_filters = function (refetch) {
        refetch = typeof refetch === "undefined" ? true : refetch;

        let categories = $("[id^='calendar-filter-category-']"), calendar_search = $("#calendar-search").val(),
            category_names = "";

        // Whether to filter by a search string
        localStorage.setItem("filter_search_string", calendar_search);
        self.last_search_string = calendar_search;

        // Whether or not to filter by assignments, events, or both
        if (!$("#calendar-filter-homework").prop("checked") &&
            !$("#calendar-filter-events").prop("checked") &&
            !$("#calendar-filter-class").prop("checked") &&
            !$("#calendar-filter-external").prop("checked")) {
            localStorage.removeItem("filter_show_homework");
            localStorage.removeItem("filter_show_events");
            localStorage.removeItem("filter_show_class");
            localStorage.removeItem("filter_show_external");
        } else {
            localStorage.setItem("filter_show_homework",
                                 $("#calendar-filter-homework").prop("checked"));
            localStorage.setItem("filter_show_events",
                                 $("#calendar-filter-events").prop("checked"));
            localStorage.setItem("filter_show_class",
                                 $("#calendar-filter-class").prop("checked"));
            localStorage.setItem("filter_show_external",
                                 $("#calendar-filter-external").prop("checked"));
        }

        // Check if we should filter by selected categories
        $.each(categories, function () {
            if ($(this).prop("checked")) {
                category_names += (encodeURIComponent("'" + $(this).attr("data-str")) + "',");
            }
        });
        if (category_names.match(/,$/)) {
            category_names = category_names.substring(0, category_names.length - 1);
        }
        if (category_names !== "") {
            localStorage.setItem("filter_categories", category_names);
        } else {
            localStorage.removeItem("filter_categories");
        }

        // If neither OR both complete/incomplete checkboxes are checked, we're not filtering by completion
        if ((!$("#calendar-filter-complete").prop("checked") &&
             !$("#calendar-filter-incomplete").prop("checked")
            ) || (($("#calendar-filter-complete").prop("checked") &&
                   $("#calendar-filter-incomplete").prop("checked")))) {
            localStorage.removeItem("filter_complete");
        } else {
            // If one of the complete/incomplete checkbox was checked, just take the status of the complete checkbox
            // since we only need a true/false value
            localStorage.setItem("filter_complete",
                                 $("#calendar-filter-complete").prop("checked"));
        }

        // If we should filter by overdue elements
        if ($("#calendar-filter-overdue").prop("checked")) {
            localStorage.setItem("filter_overdue",
                                 $("#calendar-filter-overdue").prop("checked"));
        } else {
            localStorage.removeItem("filter_overdue");
        }

        // If all filters are off, clear the filter title
        if (category_names === "" &&
            !$("#calendar-filter-complete").prop("checked") &&
            !$("#calendar-filter-incomplete").prop("checked") &&
            !$("#calendar-filter-overdue").prop("checked") &&
            !$("#calendar-filter-homework").prop("checked") &&
            !$("#calendar-filter-events").prop("checked") &&
            !$("#calendar-filter-class").prop("checked") &&
            !$("#calendar-filter-external").prop("checked")) {
            $("#calendar-filters button").removeClass("fc-state-active");
        } else {
            $("#calendar-filters button").addClass("fc-state-active");
        }

        if (refetch) {
            $("#calendar").fullCalendar("refetchEvents");
        }
    };

    this.calculate_course_filter_window = function () {
        if (Object.keys(helium.calendar.courses).length === 0) {
            self.course_filter_window_start = moment().stripTime().subtract(1, "years");
            self.course_filter_window_end = moment().stripTime().add(1, "years");
        } else {
            $.each(helium.calendar.courses, function (index, course) {
                const start_date = moment(course.start_date);
                const end_date = moment(course.end_date);
                if (self.course_filter_window_start === undefined
                    || start_date < self.course_filter_window_start) {
                    self.course_filter_window_start = start_date;
                }
                if (self.course_filter_window_end === undefined
                    || end_date > self.course_filter_window_end) {
                    self.course_filter_window_end = end_date.add(1, "days")
                }
            });
        }
    }

    /**
     * Refresh the classes based on the current filter selection.
     */
    this.refresh_classes = function (refetch) {
        refetch = typeof refetch === "undefined" ? true : refetch;

        let courses = $("[id^='calendar-filter-course-']"), course_ids = "";

        // Check if we should filter by selected courses
        $.each(courses, function () {
            if ($(this).prop("checked")) {
                course_ids += ($(this).attr("id").split("calendar-filter-course-")[1] + ",");
            }
        });
        if (course_ids.match(/,$/)) {
            course_ids = course_ids.substring(0, course_ids.length - 1);
        }
        localStorage.setItem("filter_courses", course_ids);

        // If all class (or none) filters are check, clear the filter title
        if (courses.size() !== course_ids.split(",").length
            && course_ids !== "") {
            $("#calendar-classes button").addClass("fc-state-active");
        } else {
            $("#calendar-classes button").removeClass("fc-state-active");
        }

        if (refetch) {
            $("#calendar").fullCalendar("refetchEvents");
        }
    };

    this.get_calendar_item_checkbox = function (calendar_item) {
        return '<input id="calendar-homework-checkbox-' + calendar_item.id
               + '" type="checkbox" class="ace calendar-homework-checkbox"' + (calendar_item.completed
                                                                               ? ' checked="checked"' : '')
               + '><span class="lbl" style="margin-top: -3px; margin-right: 3px;"></span>';
    }

    this.get_calendar_item_title = function (calendar_item) {
        if (calendar_item.calendar_item_type === 1) {
            return "<span class=\"fc-has-url\">" + (calendar_item.completed ? "<s>" : "") + calendar_item.title
                   + (calendar_item.completed
                      ? "</s>" : "") + "</span>";
        } else if (calendar_item.calendar_item_type === 0) {
            return "<span class=\"fc-has-url\">" + calendar_item.title + "</span>";
        } else {
            return calendar_item.title;
        }
    };

    this.event_source_external_calendars = function (start, end, timezone, callback) {
        const events = [];
        const current_view = $("#calendar").fullCalendar("getView").name;

        if (current_view !== "assignmentsList" &&
            (localStorage.getItem("filter_show_external") === null ||
             localStorage.getItem("filter_show_external") === "true")) {
            $.each(helium.calendar.external_calendars, function (index, external_calendar) {
                if (!helium.calendar.external_calendars[external_calendar.id].shown_on_calendar) {
                    return true;
                }

                helium.ajax_calls.push(helium.planner_api.get_external_calendar_events(function (data) {
                    $.each(data, function (i, calendar_item) {
                        if (calendar_item.hasOwnProperty("err_msg")) {
                            helium.ajax_error_occurred = true;

                            return false;
                        }

                        events.push(
                            {
                                id: "ext_" + external_calendar.id + "_" + calendar_item.id,
                                color: external_calendar.color,
                                checkbox: "",
                                title: helium.calendar.get_calendar_item_title(calendar_item),
                                title_no_format: calendar_item.title,
                                start: moment(calendar_item.start)
                                    .tz(helium.USER_PREFS.settings.time_zone),
                                end: moment(calendar_item.end)
                                    .tz(helium.USER_PREFS.settings.time_zone),
                                allDay: calendar_item.all_day,
                                all_day: calendar_item.all_day,
                                editable: false,
                                // The following elements are for list view display accuracy
                                materials: [],
                                show_end_time: !calendar_item.all_day,
                                calendar_item_type: calendar_item.calendar_item_type,
                                course: null,
                                category: null,
                                completed: false,
                                priority: null,
                                current_grade: null,
                                url: calendar_item.url,
                                comments: '',
                                attachments: [],
                                reminders: []
                            });
                    });
                }, external_calendar.id, true, true, start.toISOString(), end.toISOString(), localStorage.getItem(
                    "filter_search_string")));
            });
        }

        $.when.apply($, helium.ajax_calls).done(function () {
            callback(events);
        }).fail(function () {
            self.loading_div.spin(false);

            if ($('.bootbox.modal').length === 0) {
                bootbox.alert(document.GENERIC_ERROR_MESSAGE);
            }
        });
    }

    this.event_source_events = function (start, end, timezone, callback) {
        const events = [];
        const current_view = $("#calendar").fullCalendar("getView").name;

        if (current_view !== "assignmentsList" &&
            (localStorage.getItem("filter_show_events") === null ||
             localStorage.getItem("filter_show_events") === "true")) {
            helium.ajax_calls.push(helium.planner_api.get_events(function (data) {
                $.each(data, function (i, calendar_item) {
                    if (calendar_item.hasOwnProperty("err_msg")) {
                        helium.ajax_error_occurred = true;

                        return false;
                    }

                    events.push(
                        {
                            id: "event_" + calendar_item.id,
                            color: helium.USER_PREFS.settings.events_color,
                            checkbox: "",
                            title: helium.calendar.get_calendar_item_title(calendar_item),
                            title_no_format: calendar_item.title,
                            start: moment(calendar_item.start).tz(helium.USER_PREFS.settings.time_zone),
                            end: moment(calendar_item.end).tz(helium.USER_PREFS.settings.time_zone),
                            allDay: calendar_item.all_day,
                            all_day: calendar_item.all_day,
                            // The following elements are for list view display accuracy
                            materials: [],
                            show_end_time: calendar_item.show_end_time,
                            calendar_item_type: calendar_item.calendar_item_type,
                            course: null,
                            category: null,
                            completed: calendar_item.completed,
                            priority: calendar_item.priority,
                            current_grade: null,
                            url: null,
                            comments: calendar_item.comments,
                            attachments: calendar_item.attachments,
                            reminders: calendar_item.reminders
                        });
                });
            }, true, true, start.toISOString(), end.toISOString(), localStorage.getItem("filter_search_string")));
        }

        $.when.apply($, helium.ajax_calls).done(function () {
            callback(events);
        }).fail(function () {
            self.loading_div.spin(false);

            if ($('.bootbox.modal').length === 0) {
                bootbox.alert(document.GENERIC_ERROR_MESSAGE);
            }
        });
    }

    this.event_source_class_schedules = function (start, end, timezone, callback) {
        const events = [];
        const current_view = $("#calendar").fullCalendar("getView").name;

        if (current_view !== "assignmentsList" &&
            (localStorage.getItem("filter_show_class") === null ||
             localStorage.getItem("filter_show_class") === "true")) {
            $.each(helium.calendar.courses, function (index, course) {
                if (!helium.calendar.course_groups[helium.calendar.courses[course.id].course_group].shown_on_calendar) {
                    return true;
                }

                if (localStorage.getItem("filter_courses") !== null &&
                    localStorage.getItem("filter_courses") !== "" &&
                    $.inArray(course.id.toString(),
                              localStorage.getItem("filter_courses").split(",")) === -1) {
                    return true;
                }

                helium.ajax_calls.push(helium.planner_api.get_class_schedule_events(function (data) {
                    $.each(data, function (i, calendar_item) {
                        if (calendar_item.hasOwnProperty("err_msg")) {
                            helium.ajax_error_occurred = true;

                            return false;
                        }

                        const course = helium.calendar.courses[calendar_item.owner_id];

                        events.push(
                            {
                                id: "class_" + course.id + "_" + calendar_item.id,
                                color: course.color,
                                checkbox: "",
                                title: helium.calendar.get_calendar_item_title(calendar_item),
                                title_no_format: calendar_item.title,
                                start: moment(calendar_item.start).tz(helium.USER_PREFS.settings.time_zone),
                                end: moment(calendar_item.end).tz(helium.USER_PREFS.settings.time_zone),
                                allDay: calendar_item.all_day,
                                all_day: calendar_item.all_day,
                                editable: false,
                                // The following elements are for list view display accuracy
                                materials: helium.calendar.get_material_ids_for_course(course),
                                show_end_time: !calendar_item.all_day,
                                calendar_item_type: calendar_item.calendar_item_type,
                                course: course.id,
                                category: null,
                                completed: false,
                                priority: null,
                                current_grade: null,
                                url: calendar_item.url,
                                comments: '',
                                attachments: calendar_item.attachments,
                                reminders: calendar_item.reminders
                            });
                    });
                }, helium.calendar.courses[course.id].course_group, course.id, true, true, localStorage.getItem(
                    "filter_search_string")));
            });
        }

        $.when.apply($, helium.ajax_calls).done(function () {
            callback(events);
        }).fail(function () {
            self.loading_div.spin(false);

            if ($('.bootbox.modal').length === 0) {
                bootbox.alert(document.GENERIC_ERROR_MESSAGE);
            }
        });
    }

    this.event_source_homework = function (start, end, timezone, callback) {
        const events = [];

        if (localStorage.getItem("filter_show_homework") === null ||
            localStorage.getItem("filter_show_homework") === "true") {
            helium.ajax_calls.push(
                helium.planner_api.get_homework_by_user(
                    function (data) {
                        $.each(data, function (i, calendar_item) {
                            if (calendar_item.hasOwnProperty("err_msg")) {
                                helium.ajax_error_occurred = true;

                                return false;
                            }

                            const homework_color = helium.USER_PREFS.settings.calendar_use_category_colors
                                                   ? helium.calendar.categories[calendar_item.category].color
                                                   : helium.calendar.courses[calendar_item.course].color;

                            events.push(
                                {
                                    id: calendar_item.id,
                                    color: homework_color,
                                    checkbox: helium.calendar.get_calendar_item_checkbox(calendar_item),
                                    title: helium.calendar.get_calendar_item_title(calendar_item),
                                    title_no_format: calendar_item.title,
                                    start: moment(calendar_item.start).tz(helium.USER_PREFS.settings.time_zone),
                                    end: moment(calendar_item.end).tz(helium.USER_PREFS.settings.time_zone),
                                    allDay: calendar_item.all_day,
                                    all_day: calendar_item.all_day,
                                    // The following elements are for list view display accuracy
                                    materials: calendar_item.materials,
                                    show_end_time: calendar_item.show_end_time,
                                    calendar_item_type: calendar_item.calendar_item_type,
                                    course: calendar_item.course,
                                    category: calendar_item.category,
                                    completed: calendar_item.completed,
                                    priority: calendar_item.priority,
                                    current_grade: calendar_item.current_grade,
                                    url: null,
                                    comments: calendar_item.comments,
                                    attachments: calendar_item.attachments,
                                    reminders: calendar_item.reminders
                                });
                        });
                    }, true, true, start.toISOString(), end.toISOString(),
                    localStorage.getItem("filter_courses"),
                    localStorage.getItem("filter_categories"),
                    localStorage.getItem("filter_complete"),
                    localStorage.getItem("filter_overdue"),
                    localStorage.getItem("filter_search_string")));
        }

        $.when.apply($, helium.ajax_calls).done(function () {
            callback(events);
        }).fail(function () {
            self.loading_div.spin(false);

            if ($('.bootbox.modal').length === 0) {
                bootbox.alert(document.GENERIC_ERROR_MESSAGE);
            }
        });
    };

    this.refresh_view = function (view) {
        if (view.name === 'assignmentsList') {
            $('.fc-toolbar .fc-prev-button').addClass('fc-state-disabled');
            $('.fc-toolbar .fc-next-button').addClass('fc-state-disabled');

            $('#calendar-filter-homework').parent().parent().addClass('hidden');
            $('#calendar-filter-events').parent().parent().addClass('hidden');
            $('#calendar-filter-class').parent().parent().addClass('hidden');
            $('#calendar-filter-external').parent().parent().addClass('hidden');
            $('#calendar-filter-external').parent().parent().next().addClass('hidden');

            let filters_changed = false;
            if ($("#calendar-filter-events").is(":checked")) {
                $("#calendar-filter-events").prop("checked", false);
                filters_changed = true;
            }
            if ($("#calendar-filter-class").is(":checked")) {
                $("#calendar-filter-class").prop("checked", false);
                filters_changed = true;
            }
            if ($("#calendar-filter-external").is(":checked")) {
                $("#calendar-filter-external").prop("checked", false);
                filters_changed = true;
            }

            if (filters_changed) {
                self.refresh_filters();
            }
        } else {
            $('.fc-toolbar .fc-prev-button').removeClass('fc-state-disabled');
            $('.fc-toolbar .fc-next-button').removeClass('fc-state-disabled');

            $('#calendar-filter-homework').parent().parent().removeClass('hidden');
            $('#calendar-filter-events').parent().parent().removeClass('hidden');
            $('#calendar-filter-class').parent().parent().removeClass('hidden');
            $('#calendar-filter-external').parent().parent().removeClass('hidden');
            $('#calendar-filter-external').parent().parent().next().removeClass('hidden');
        }

        $("#loading-calendar").spin(false);
        $("#calendar").removeClass("hidden");
        helium.calendar.adjust_calendar_size();
    };

    /**
     * Initialize the FullCalendar plugin.
     */
    this.initialize_calendar = function () {
        self.calculate_course_filter_window();

        let user_view_pref = helium.USER_PREFS.settings.default_view;
        if (user_view_pref === 3) {
            user_view_pref = 4;
        } else if (user_view_pref === 4) {
            user_view_pref = 3;
        }

        if ($(window).width() < 768 &&
            (user_view_pref === 0 || user_view_pref === 1)) {
            user_view_pref = 3;
        }

        $.when.apply($, helium.ajax_calls).done(function () {
            self.reset_filters();

            $("#calendar").fullCalendar(
                {
                    eventSources: [
                        helium.calendar.event_source_external_calendars,
                        helium.calendar.event_source_events,
                        helium.calendar.event_source_class_schedules,
                        helium.calendar.event_source_homework
                    ],
                    defaultTimedEventDuration: moment().hours(0)
                        .minutes(helium.USER_PREFS.settings.all_day_offset).seconds(0)
                        .format("HH:mm:ss"),
                    defaultView: self.DEFAULT_VIEWS[user_view_pref],
                    timezone: helium.USER_PREFS.settings.time_zone,
                    editable: true,
                    eventClick: self.edit_calendar_item_btn,
                    eventDrop: self.drop_calendar_item,
                    eventColor: "#438eb9",
                    eventResize: self.resize_calendar_item,
                    noEventsMessage: "Nothing to see here. Change the date or filters, or click \"+\" to add something.",
                    displayEventTime: false,
                    weekNumbersWithinDays: true,
                    eventLimit: helium.USER_PREFS.settings.calendar_event_limit,
                    nowIndicator: true,
                    viewDestroy: function (view) {
                        self.previous_view = view.name;
                    },
                    viewRender: function (view) {
                        if (self.previous_view !== undefined && self.previous_view === "assignmentsList") {
                            // Effectively the "calendar" views and the "list" view have two different event
                            // management styles, so we force-repopulate the sources to ensure the windowing is
                            // correct between view transitions
                            view.calendar.removeEventSource(helium.calendar.event_source_homework);

                            view.calendar.eventManager.currentPeriod.start = view.start;
                            view.calendar.eventManager.currentPeriod.end = view.end;
                            view.calendar.eventManager.setPeriod(view.calendar.eventManager.currentPeriod);

                            view.calendar.addEventSource(helium.calendar.event_source_homework);
                            view.calendar.addEventSource(helium.calendar.event_source_external_calendars);
                            view.calendar.addEventSource(helium.calendar.event_source_events);
                            view.calendar.addEventSource(helium.calendar.event_source_class_schedules);

                            self.previous_view = null;
                        }
                    },
                    eventAfterAllRender: self.refresh_view,
                    eventResizeStart: function () {
                        self.is_resizing_calendar_item = true;
                    },
                    eventResizeStop: function () {
                        self.is_resizing_calendar_item = false;
                    },
                    eventRender: function (event, element) {
                        if (!event.id || !event.title) {
                            return;
                        }

                        let title = event.title;
                        let title_for_assignments_list = '<span class="fc-event fc-day-grid-event inline" style="background-color: '
                                                         + event.color
                                                         + ' !important; border: 1px solid ' + event.color + '">'
                                                         + title
                                                         + "<span class=\"visible-xs\"> " + (event.calendar_item_type
                                                                                             === 1 ? "("
                                                         + helium.calendar.courses[event.course].title + ")" : "")
                                                         + "</span></span>";

                        let title_for_calendar = title + (!event.allDay ? ", " + moment(event.start)
                            .format(helium.HE_TIME_STRING_CLIENT) : "");
                        let title_for_agenda = title_for_assignments_list + (!event.allDay ? " " + moment(event.start)
                            .format(helium.HE_TIME_STRING_CLIENT) : "");

                        element.find(".fc-title").html(event.checkbox + title_for_calendar);

                        element.find(".fc-list-item-marker").html(event.checkbox);
                        element.find(".fc-assignmentList-item-title").html(title_for_assignments_list);

                        element.find(".fc-list-item-title").html(title_for_agenda);

                        element.find(".title-label:has(.planner-title-with-link)").on("click", function (e) {
                            e.stopImmediatePropagation();
                        });

                        let start, end = null, course_string;

                        start = moment(event.start).format(helium.HE_REMINDER_DATE_STRING);
                        // Construct a pleasant start date/time
                        if (!event.allDay) {
                            start += (" at " + moment(event.start).format(helium.HE_TIME_STRING_CLIENT));
                        }

                        // Construct a pleasant end date/time
                        if (event.end) {
                            if (event.start.clone().toDate().setHours(0, 0, 0, 0)
                                !== event.end.clone().toDate().setHours(0, 0, 0, 0)) {
                                end = moment(event.end);
                                // If we're adding an all-day event spanning multiple days,
                                // correct the end date to be offset by one
                                if (event.allDay && !moment(event.start).isSame(end, "day")) {
                                    end = end.subtract(1, "days");
                                }
                                end = " " + end.format(helium.HE_REMINDER_DATE_STRING);
                            }
                            if (!event.allDay) {
                                if (end === null) {
                                    end = "";
                                }
                                end += (" " + moment(event.end).format(helium.HE_TIME_STRING_CLIENT));
                            }
                        }

                        course_string = event.calendar_item_type === 1
                                        ? ('<span class="label label-sm" style="background-color: '
                                           + helium.calendar.courses[event.course].color + ' !important">'
                                           + (helium.str_not_empty(helium.calendar.courses[event.course].website)
                                              && helium.calendar.courses[event.course].website.replace(/\s/g,
                                                                                                       "").length
                                              > 0
                                              ? "<a target=\"_blank\" href=\""
                                           + helium.calendar.courses[event.course].website
                                           + "\" class=\"planner-title-with-link\">" : "")
                                           + helium.calendar.courses[event.course].title
                                           + (helium.str_not_empty(helium.calendar.courses[event.course].website)
                                              && helium.calendar.courses[event.course].website.replace(/\s/g,
                                                                                                       "").length
                                              > 0 ? " <i class=\"icon-external-link\"></i></a>"
                                                  : "")
                                           + '</span>') : "";

                        if ($(window).width() > 768) {
                            // We attached to the subelement here to prevent tooltips from showing in list view
                            element.find(".fc-content, .fc-list-item-title").qtip(
                                {
                                    content: "<div class=\"row\"><div class=\"col-xs-12\">"
                                             + "<strong>When:</strong> " + start +
                                             (event.show_end_time && end ? (" to " + end) : "") +
                                             "</div></div>" +
                                             ((event.calendar_item_type === 1
                                               || event.calendar_item_type === 3) && ((event.category !== null
                                                                                       && helium.calendar.categories[event.category].title
                                                                                       !== "Uncategorized"
                                                                                       && course_string !== "")
                                                                                      || helium.calendar.courses[event.course].room)
                                              ? "<div class=\"row\"><div class=\"col-xs-12\"><strong>Info:</strong> "
                                             + (event.category !== null
                                                && helium.calendar.categories[event.category].title
                                                !== "Uncategorized"
                                                ? ('<span class="label label-sm" style="background-color: '
                                             + helium.calendar.categories[event.category].color + ' !important">'
                                             + helium.calendar.categories[event.category].title
                                             + "</span> for ") : "") + course_string + (
                                                 !helium.calendar.courses[event.course].is_online
                                                 && helium.calendar.courses[event.course].room.replace(
                                                     /\s/g, "").length > 0 ? (event.calendar_item_type === 1
                                                                              ? " in "
                                                                              : "")
                                             + helium.calendar.courses[event.course].room : "") + "</div></div>"
                                              : "")
                                             + (event.calendar_item_type === 1 && event.materials !== undefined
                                                && event.materials.length > 0
                                                && helium.calendar.get_materials_titles_badges_from_ids(
                                            event.materials)
                                                ? "<div class=\"row\"><div class=\"col-xs-12\"><strong>Materials:</strong> "
                                             + helium.calendar.get_materials_titles_badges_from_ids(
                                                event.materials) + "</div></div>" : "") + (
                                                 event.calendar_item_type === 1
                                                 && event.completed && event.current_grade
                                                 !== "-1/100"
                                                 ? "<div class=\"row\"><div class=\"col-xs-12\"><strong>Grade:</strong> "
                                             + "<span class=\"badge\" style=\"background-color: "
                                             + helium.USER_PREFS.settings.grade_color + " !important\">"
                                             + helium.grade_for_display(
                                                         event.current_grade) + "</span>"
                                             + "</div></div>" : ""
                                             ) + (
                                                 event.attachments !== undefined && event.attachments.length > 0
                                                 ? "<div class=\"row\"><div class=\"col-xs-12\"><strong>Attachments:</strong> "
                                             + helium.calendar.get_attachment_bullets_from_data(
                                                         event.attachments)
                                             + "</div></div>" : "")
                                             + (event.comments.replace(/\s/g, "").length > 0
                                                ? "<div class=\"row\"><div class=\"col-xs-12\"><br/>"
                                             + helium.get_comments_with_link(
                                                event.comments) + "</div></div>"
                                                : ""),
                                    hide: {
                                        event: "mousedown mouseup mouseleave",
                                        fixed: true,
                                        delay: helium.QTIP_HIDE_INTERVAL
                                    },
                                    position: {
                                        my: "top center",
                                        at: "bottom center",
                                        adjust: {resize: false},
                                        viewport: $(window)
                                    },
                                    show: {
                                        solo: true,
                                        delay: helium.QTIP_SHOW_INTERVAL
                                    },
                                    style: {classes: "qtip-bootstrap hidden-print"}
                                });
                        }
                    },
                    firstDay: helium.USER_PREFS.settings.week_starts_on,
                    header: {
                        left: "today prev,next title",
                        right: self.DEFAULT_VIEWS.toString()
                    },
                    locale: 'en',
                    loading: function (loading) {
                        if (self.loading_div) {
                            if (loading) {
                                self.loading_div.spin(helium.SMALL_LOADING_OPTS);
                            } else {
                                self.loading_div.spin(false);
                            }
                        }
                    },
                    nextDayThreshold: "00:00:00",
                    selectable: true,
                    selectHelper: true,
                    select: self.add_calendar_item_btn,
                    views: {
                        month: {
                            titleFormat: "MMMM YYYY"
                        },
                        week: {
                            titleFormat: "MMM D YYYY"
                        },
                        day: {
                            titleFormat: "ddd, MMM D, YYYY"
                        },
                        list: {
                            buttonText: 'agenda',
                            titleFormat: "MMM D YYYY"
                        },
                        assignmentsList: {
                            buttonText: 'todos'
                        },
                    }
                });

            self.last_good_date = moment("12:00 PM", "HH:mm A");
            self.last_good_end_date = self.last_good_date.clone();
            self.last_good_end_date.add(helium.USER_PREFS.settings.all_day_offset, "minutes");

            // Customize the calendar header
            $(".fc-toolbar .fc-right").prepend(
                "<div class=\"fc-button-group\">"
                + "<div class='btn-group' id=\"calendar-classes\"><button data-toggle=\"dropdown\" aria-label=\"Classes\" class=\"fc-button fc-state-default dropdown-toggle\"><span><i class=\"icon-book\"></i></span> <span class=\"icon-caret-down icon-on-right\"></span></button><ul id=\"calendar-classes-list\" class=\"dropdown-menu dropdown-menu-form dropdown-menu-right\" role=\"menu\"><li id=\"filter-classes-clear\"><a class=\"cursor-hover\"><span class='lbl smaller-90'>Clear Filters</span></a></li><li class=\"divider\"></li></ul></div>"
                + "<div class='btn-group' id=\"calendar-filters\"><button data-toggle=\"dropdown\" aria-label=\"Filters\" class=\"fc-button fc-state-default dropdown-toggle\"><span><i class=\"icon-filter\"></i></span> <span class=\"icon-caret-down icon-on-right\"></span></button><ul id=\"calendar-filter-list\" class=\"dropdown-menu dropdown-menu-form dropdown-menu-right\" role=\"menu\"><li id=\"filter-clear\"><a class=\"cursor-hover\"><span class='lbl smaller-90'>Clear Filters</span></a></li></ul></div>"
                + "</div>");
            $("#calendar-classes button, #calendar-filters button").hover(
                function () {
                    if (!$(this).hasClass("fc-state-active") && !$(this).hasClass("fc-state-disabled")) {
                        $(this).addClass("fc-state-hover");
                    }
                },
                function () {
                    $(this).removeClass("fc-state-hover");
                }
            );
            $(".fc-toolbar .fc-right").prepend(
                "<div class=\"btn-group\"><button id=\"create-homework\" aria-label=\"Create\" type=\"button\" class=\"fc-button btn btn-primary btn-sm btn-xs\"><i class=\"icon-plus\"></i></button></div>");
            $(".fc-toolbar .fc-right").append(
                "<span class=\"input-icon\" id=\"search-bar\"><input type=\"text\" placeholder=\"Search ...\" class=\"input-sm search-query\" id=\"calendar-search\" autocomplete=\"off\" /><i class=\"icon-search nav-search-icon\"></i></span>");
            $(".fc-toolbar, .fc-button").addClass("hidden-print");
            $(".fc-toolbar .fc-right").addClass("hidden-print");
            $(".fc-month-button, .fc-agendaWeek-button, #search-bar")
                .addClass("hidden-xs");
            self.loading_div =
                $(".fc-toolbar .fc-left").append(
                    "<div id=\"fullcalendar-loading\" class=\"loading-mini\" style=\"padding-left: 25px; padding-top: 2px;\"><div id=\"loading-fullcalendar\"></div></div>")
                    .find("#loading-fullcalendar");
            $("#loading-calendar").spin(false);
            $("#calendar").removeClass("hidden");
            self.loading_div.spin(helium.SMALL_LOADING_OPTS);

            self.populate_filter_dropdowns();
            self.initialize_search_bindings();

            self.init_filters();

            $("#filter-classes-clear").on("click", function () {
                $("#calendar-classes button").addClass("fc-state-active");
                $.each(
                    $("[id^='calendar-filter-course-']"),
                    function () {
                        $(this).prop("checked", false);
                    });
                self.refresh_classes();
            });

            $("#filter-clear").on("click", function () {
                $("#calendar-filters button").removeClass("fc-state-active");
                $.each(
                    $("[id^='calendar-filter-category-'], #calendar-filter-homework, #calendar-filter-events, #calendar-filter-class, #calendar-filter-external, #calendar-filter-complete, #calendar-filter-incomplete, #calendar-filter-overdue"),
                    function () {
                        $(this).prop("checked", false);
                    });
                self.refresh_filters();
            });

            $(".dropdown-menu").on("click", function (e) {
                if ($(this).hasClass("dropdown-menu-form")) {
                    e.stopPropagation();
                }
            });

            $("#calendar").fullCalendar("option", "height", $(window).height() - 70);
        });
    };

    /**
     * Initialize bindings for the search form.
     */
    this.initialize_search_bindings = function () {
        $("#calendar-search").keyup(function () {
            if ($("#calendar-search").val() !== self.last_search_string) {
                clearTimeout(self.typing_timer);
                self.typing_timer = setTimeout(function () {
                    self.refresh_filters(false);
                    self.refresh_classes(false);
                    $("#calendar").fullCalendar("refetchEvents");
                }, self.DONE_TYPING_INTERVAL);
            }
        });

        $("#calendar-search").keydown(function () {
            clearTimeout(self.typing_timer);
        });
    };

    this.get_materials_titles_badges_from_ids = function (materials) {
        let titles = "";

        $.each(materials, function (index, id) {
            if (!helium.calendar.material_groups[helium.calendar.materials[id].material_group].shown_on_calendar) {
                return true;
            }

            let title = helium.calendar.materials[id].title;
            if (helium.str_not_empty(helium.calendar.materials[id].website)) {
                title = "<a href='" + helium.calendar.materials[id].website
                        + "' target='_blank' class='planner-title-with-link'>"
                        + helium.calendar.materials[id].title
                        + " <i class=\"icon-external-link\"></i></a>";
            }

            titles += '<span class="label label-sm title-label" style="background-color: '
                      + helium.USER_PREFS.settings.material_color + ' !important;">'
                      + title + "</span> ";
        });

        return titles;
    };

    this.get_attachment_bullets_from_data = function (data) {
        let titles = "";

        $.each(data, function (index, item) {
            titles += '<li><a href="' + item.attachment + '" download>' + item.title + '</a></li>';
        });

        if (titles.length > 0) {
            titles = '<ul>' + titles + '</ul>';
        }
        return titles;
    };

    this.get_material_ids_for_course = function (course) {
        const ids = [];

        $.each(helium.calendar.materials, function (index, material) {
            if ($.inArray(course.id, material.courses) !== -1) {
                ids.push(material.id);
            }
        });

        return ids;
    };

    /**
     * Initialize the filters.
     */
    this.populate_filter_dropdowns = function () {
        let i = 0, loading_filters;

        loading_filters =
            $("#calendar-filter-list").prepend(
                "<div id=\"filters-loading\" class=\"loading-inline pull-left\"><div id=\"loading-filters\"></div></div>")
                .find("#loading-filters");
        loading_filters.spin(helium.FILTER_LOADING_OPTS);
        $("#calendar-filter-list").append(
            "<li class=\"divider\"></li>"
            + "<li><a class=\"checkbox cursor-hover\"><input id=\"calendar-filter-homework\" type=\"checkbox\" class='ace'/><label class='lbl smaller-90' for='calendar-filter-homework'> Assignments</label></a></li>"
            + "<li><a class=\"checkbox cursor-hover\"><input id=\"calendar-filter-events\" type=\"checkbox\" class='ace'/><label class='lbl smaller-90' for='calendar-filter-events'> Events <span class=\"color-dot inline\" style=\"background-color: "
            + helium.USER_PREFS.settings.events_color + "\"></span></label></a></li>"
            + "<li><a class=\"checkbox cursor-hover\"><input id=\"calendar-filter-class\" type=\"checkbox\" class='ace'/><label class='lbl smaller-90' for='calendar-filter-class'> Class Schedules</label></a></li>"
            + "<li><a class=\"checkbox cursor-hover\"><input id=\"calendar-filter-external\" type=\"checkbox\" class='ace'/><label class='lbl smaller-90' for='calendar-filter-external'> External Calendars</label></a></li>"
            + "<li class=\"divider\"></li>"
            + "<li><a class=\"checkbox cursor-hover\"><input id=\"calendar-filter-complete\" type=\"checkbox\" class='ace'/><label class='lbl smaller-90' for='calendar-filter-complete'> Complete</label></a></li>"
            + "<li><a class=\"checkbox cursor-hover\"><input id=\"calendar-filter-incomplete\" type=\"checkbox\" class='ace'/><label class='lbl smaller-90' for='calendar-filter-incomplete'> Incomplete</label></a></li>"
            + "<li><a class=\"checkbox cursor-hover\"><input id=\"calendar-filter-overdue\" type=\"checkbox\" class='ace'/><label class='lbl smaller-90' for='calendar-filter-overdue'> Overdue</label></a></li>");
        $("#calendar-filter-homework").change(self.refresh_filters);
        $("#calendar-filter-homework").parent().on("click", self.trigger_child_checkbox);
        $("#calendar-filter-events").change(self.refresh_filters);
        $("#calendar-filter-events").parent().on("click", self.trigger_child_checkbox);
        $("#calendar-filter-class").change(self.refresh_filters);
        $("#calendar-filter-class").parent().on("click", self.trigger_child_checkbox);
        $("#calendar-filter-external").change(self.refresh_filters);
        $("#calendar-filter-external").parent().on("click", self.trigger_child_checkbox);
        $("#calendar-filter-complete").change(self.refresh_filters);
        $("#calendar-filter-complete").parent().on("click", self.trigger_child_checkbox);
        $("#calendar-filter-incomplete").change(self.refresh_filters);
        $("#calendar-filter-incomplete").parent().on("click", self.trigger_child_checkbox);
        $("#calendar-filter-overdue").change(self.refresh_filters);
        $("#calendar-filter-overdue").parent().on("click", self.trigger_child_checkbox);

        if (!helium.ajax_error_occurred) {
            // Initialize course filters
            let courses_added = 0;
            if (Object.keys(helium.calendar.courses).length > 0) {
                let course_groups = Object.entries(helium.calendar.course_groups);
                course_groups.sort((a, b) => {
                    const a_start = moment(a[1].start_date);
                    const b_start = moment(b[1].start_date);

                    if (a_start.isAfter(b_start)) {
                        return -1;
                    } else if (a_start.isBefore(b_start)) {
                        return 1;
                    }
                    return 0;
                });

                let groups_shown = 0;
                $.each(course_groups, function (group_index, course_group_tuple) {
                    let course_group = course_group_tuple[1];
                    if (!course_group.shown_on_calendar) {
                        return true;
                    }

                    const courses = Object.entries(helium.calendar.courses).filter(([, course]) => {
                        return course.course_group === course_group.id;
                    });
                    if (courses.length > 0 && groups_shown > 0) {
                        $("#calendar-classes-list").append("<li class=\"divider\"></li>");
                    }
                    groups_shown += 1;

                    courses.sort((a, b) => {
                        if (a[1].title < b[1].title) {
                            return -1;
                        } else if (a[1].title > b[1].title) {
                            return 1;
                        }
                        return 0;
                    });

                    $.each(courses, function (course_index, course_tuple) {
                        let course = course_tuple[1]

                        $("#calendar-classes-list").append(
                            "<li><a class=\"checkbox cursor-hover\"><input type=\"checkbox\" id=\"calendar-filter-course-"
                            + course.id + "\" class='ace'/><label class='lbl smaller-90' for=\"calendar-filter-course-"
                            + course.id + "\"> " + course.title
                            + " <span class=\"color-dot inline\" style=\"background-color: "
                            + course.color + "\"></span></label></a></li>");
                        $("#calendar-filter-course-" + course.id).change(self.refresh_classes);
                        $("#calendar-filter-course-" + course.id).parent().on("click", self.trigger_child_checkbox);

                        courses_added += 1;
                    });
                });
            }

            if (courses_added === 0) {
                $("#calendar-classes button").addClass("fc-state-disabled").attr("disabled", "disabled");
                $("#calendar-filters button").addClass("fc-state-disabled").attr("disabled", "disabled");
            } else if (courses_added === 1) {
                $("#calendar-classes button").addClass("fc-state-disabled").attr("disabled", "disabled");
            }

            // Initialize category filters
            const categories = Object.entries(helium.calendar.categories).filter(([, category]) => {
                return helium.calendar.course_groups[helium.calendar.courses[category.course].course_group].shown_on_calendar;
            });

            categories.sort((a, b) => {
                if (a[1].title < b[1].title) {
                    return -1;
                } else if (a[1].title > b[1].title) {
                    return 1;
                }
                return 0;
            });

            if (categories.length > 0) {
                $("#calendar-filter-list").append("<div class=\"filter-strike\"><span>Categories</span></div>");
            }
            helium.calendar.category_names = [];
            for (i = 0; i < categories.length; i += 1) {
                let category = categories[i][1];
                const slug = category.title;
                if ($.inArray(category.title, helium.calendar.category_names) === -1) {
                    helium.calendar.category_names.push(slug);
                    $("#calendar-filter-list").append(
                        "<li><a class=\"checkbox cursor-hover\"><input id=\"calendar-filter-category-" + category.id
                        + "\" type=\"checkbox\" class='ace' data-str=\"" + category.title
                        + "\"/><label class='lbl smaller-90' for='calendar-filter-category-" + category.id + "'> "
                        + category.title + "</label></a></li>");
                    $("#calendar-filter-category-" + category.id).change(self.refresh_filters);
                    $("#calendar-filter-category-" + category.id).parent().on("click", self.trigger_child_checkbox);
                }
            }

            loading_filters.spin(false);
        }
    };

    /**
     * Delete the given homework ID.
     *
     * @param event the calendar item to delete.
     */
    this.delete_calendar_item = function (event) {
        helium.ajax_error_occurred = false;

        let item_to_delete = helium.calendar.current_calendar_item.id;
        $("#homework-modal").modal("hide");

        let type;
        if (event.calendar_item_type === 0) {
            type = "event";
        } else {
            type = "assignment";
        }

        bootbox.dialog(
            {
                message: "Are you sure you want to delete this " + type + "?",
                onEscape: true,
                buttons: {
                    "delete": {
                        "label": '<i class="icon-trash"></i> Delete',
                        "className": "btn-sm btn-danger",
                        "callback": function () {
                            self.loading_div.spin(helium.SMALL_LOADING_OPTS);

                            const callback = function (data) {
                                if (helium.data_has_err_msg(data)) {
                                    helium.ajax_error_occurred = true;
                                    self.loading_div.spin(false);

                                    bootbox.alert(helium.get_error_msg(data));
                                } else {
                                    $("#calendar").fullCalendar("unselect");
                                    $("#calendar").fullCalendar("removeEvents", [item_to_delete]);

                                    self.nullify_calendar_item_persistence();

                                    self.loading_div.spin(false);
                                }
                            };
                            if (event.calendar_item_type === 0) {
                                helium.planner_api.delete_event(callback, event.id);
                            } else {
                                const course = helium.calendar.courses[event.course];

                                helium.planner_api.delete_homework(callback, course.course_group, course.id, event.id);
                            }
                        }
                    },
                    "cancel": {
                        "label": '<i class="icon-remove"></i> Cancel',
                        "className": "btn-sm"
                    }
                }
            });
    };

    /**
     * Clone the given homework ID.
     *
     * @param event the calendar item to clone.
     */
    this.clone_calendar_item = function (event) {
        helium.ajax_error_occurred = false;

        $("#loading-homework-modal").spin(helium.SMALL_LOADING_OPTS);

        const callback = function (data) {
            if (helium.data_has_err_msg(data)) {
                helium.ajax_error_occurred = true;
                $("#loading-homework-modal").spin(false);

                $("#homework-error").html(helium.get_error_msg(data));
                $("#homework-error").parent().show("fast");
            } else {
                let calendar_item = data;
                calendar_item.id =
                    calendar_item.calendar_item_type === 0 ? "event_" + calendar_item.id : calendar_item.id;

                let color;
                if (calendar_item.calendar_item_type === 1) {
                    color = helium.USER_PREFS.settings.calendar_use_category_colors
                            ? helium.calendar.categories[calendar_item.category].color
                            : helium.calendar.courses[calendar_item.course].color;
                } else {
                    color = helium.USER_PREFS.settings.events_color
                }

                $("#calendar").fullCalendar("renderEvent", {
                    id: calendar_item.id,
                    color: color,
                    checkbox: calendar_item.calendar_item_type === 1 ? helium.calendar.get_calendar_item_checkbox(
                        calendar_item) : "",
                    title: helium.calendar.get_calendar_item_title(calendar_item),
                    title_no_format: calendar_item.title,
                    start: moment(calendar_item.start).tz(helium.USER_PREFS.settings.time_zone),
                    end: moment(calendar_item.end).tz(helium.USER_PREFS.settings.time_zone),
                    allDay: calendar_item.all_day,
                    all_day: calendar_item.all_day,
                    // The following elements are for list view display accuracy
                    materials: calendar_item.calendar_item_type === 1 ? calendar_item.materials : [],
                    show_end_time: calendar_item.show_end_time,
                    calendar_item_type: calendar_item.calendar_item_type,
                    course: calendar_item.calendar_item_type === 1 ? calendar_item.course : null,
                    category: calendar_item.calendar_item_type === 1 ? calendar_item.category : null,
                    completed: calendar_item.calendar_item_type === 1 ? calendar_item.completed : false,
                    priority: calendar_item.priority,
                    current_grade: calendar_item.calendar_item_type === 1 ? calendar_item.current_grade : null,
                    url: (calendar_item.calendar_item_type !== 0 && calendar_item.calendar_item_type === 1)
                         ? calendar_item.url : null,
                    comments: calendar_item.comments,
                    attachments: calendar_item.attachments,
                    reminders: calendar_item.reminders
                });
                event = $("#calendar").fullCalendar("clientEvents", [calendar_item.id])[0];

                self.edit = false;
                self.edit_calendar_item_btn(event);
            }
        };
        const cloned = $.extend({}, self.current_calendar_item);

        delete cloned["attachments"];
        delete cloned["materials"];
        delete cloned["reminders"];
        delete cloned["source"];

        let start = cloned.start;
        let end = cloned.end;
        if (start instanceof moment) {
            start = moment(start.format()).format();
            end = moment(end.format()).format();
        }

        cloned["title"] = $("#homework-title").val() + " (Cloned)";
        cloned["start"] = start;
        cloned["end"] = end;
        cloned["course"] = $("#homework-class").val();
        cloned["all_day"] = cloned["allDay"];
        cloned["category"] = $("#homework-category").val() !== null ? $("#homework-category").val().toString() : "-1"
        if ($("#homework-materials").val()) {
            cloned["materials"] = $("#homework-materials").val();
        }

        if (event.calendar_item_type === 0) {
            helium.planner_api.add_event(callback, cloned);
        } else {
            const course = helium.calendar.courses[event.course];

            helium.planner_api.add_homework(callback, course.course_group, course.id, cloned);
        }
    };

    /**
     * Add the given reminder data to the reminder table.
     *
     * @param reminder the reminder data to be added
     * @param unsaved true if the reminder being added has not yet been saved to the database
     */
    this.add_reminder_to_table = function (reminder, unsaved) {
        let unsaved_string, row, i, offset_type_options = "", type_options = "";
        $("#no-reminders").hide();
        unsaved_string = "";
        if (unsaved) {
            unsaved_string = "-unsaved";
            self.reminder_unsaved_pk += 1;
        }

        for (i = 0; i < helium.REMINDER_OFFSET_TYPE_CHOICES.length; i += 1) {
            offset_type_options +=
                ("<option value=\"" + i + "\"" + (i === parseInt(reminder.offset_type) ? " selected=\"true\"" : "")
                 + ">" + helium.REMINDER_OFFSET_TYPE_CHOICES[i] + "</option>");
        }
        for (i = 0; i < helium.REMINDER_TYPE_CHOICES.length; i += 1) {
            type_options +=
                ("<option value=\"" + i + "\"" + (i === parseInt(reminder.type) ? " selected=\"true\"" : "") + ">"
                 + helium.REMINDER_TYPE_CHOICES[i] + "</option>");
        }
        row =
            "<tr id=\"reminder-" + reminder.id + unsaved_string
            + "\"><td><a class=\"cursor-hover\" data-type=\"textarea\" id=\"reminder-" + reminder.id + unsaved_string
            + "-message\">" + $.fullCalendar.htmlEscape(reminder.message) + "</a></td><td><select id=\"reminder-"
            + reminder.id + unsaved_string
            + "-type\">" + type_options + "</select> <a class=\"cursor-hover\" data-type=\"text\" id=\"reminder-"
            + reminder.id + unsaved_string + "-offset\">" + reminder.offset + "</a> <select id=\"reminder-"
            + reminder.id + unsaved_string + "-offset-type\">" + offset_type_options
            + "</select></td><td><div class=\"btn-group\"><button aria-label=\"Delete Reminder\"  class=\"btn btn-xs btn-danger\" id=\"delete-reminder-"
            + reminder.id + unsaved_string + "\"><i class=\"icon-trash bigger-120\"></i></button></div></td></tr>";
        $("#reminders-table-body").append(row);

        // Bind attributes within added row
        $("#reminder-" + reminder.id + unsaved_string + "-message").editable(
            {
                value: reminder.message,
                success: function () {
                    let parent_id = $(this).parent().parent().attr("id");
                    if (parent_id.indexOf("unsaved") === -1 && parent_id.indexOf("modified") === -1) {
                        $(this).parent().parent().attr("id", $(this).parent().parent().attr("id") + "-modified");
                    }
                },
                type: "textarea",
                placement: "bottom"
            });
        $("#reminder-" + reminder.id + unsaved_string + "-type").on("change", function () {
            let parent_id = $(this).parent().parent().attr("id");
            if (parent_id.indexOf("unsaved") === -1 && parent_id.indexOf("modified") === -1) {
                $(this).parent().parent().attr("id", $(this).parent().parent().attr("id") + "-modified");
            }
        });
        $("#reminder-" + reminder.id + unsaved_string + "-offset").editable(
            {
                value: reminder.offset,
                success: function () {
                    let parent_id = $(this).parent()
                        .parent().attr("id");
                    if (parent_id.indexOf("unsaved") === -1 && parent_id.indexOf("modified") === -1) {
                        $(this).parent().parent().attr("id", $(this).parent().parent().attr("id") + "-modified");
                    }
                },
                type: "text",
                tpl: '<input type="text" maxlength="5" style="max-width: 60px;">',
                placement: "bottom",
                validate: function (value) {
                    let response = "";
                    if (!/\S/.test(value)) {
                        response =
                            "This cannot be empty.";
                    } else if (isNaN(value)) {
                        response =
                            "This must be a number.";
                    }
                    return response;
                }
            });
        $("#reminder-" + reminder.id + unsaved_string + "-offset-type").on("change", function () {
            let parent_id = $(this).parent().parent().attr("id");
            if (parent_id.indexOf("unsaved") === -1 && parent_id.indexOf("modified") === -1) {
                $(this).parent().parent().attr("id", $(this).parent().parent().attr("id") + "-modified");
            }
        });

        $("#delete-reminder-" + reminder.id + unsaved_string).on("click", function () {
            $("#reminder-" + reminder.id + unsaved_string + ", #reminder-" + reminder.id + "-modified")
                .hide("fast", function () {
                    $(this).remove();
                    if ($("#reminders-table-body").children().length === 1) {
                        $("#no-reminders").show();
                    }
                });
        });
        $("#delete-reminder-" + reminder.id).on("click", function () {
            const dom_id = $(this).attr("id");
            let id = dom_id.split("-");
            id = id[id.length - 1];
            helium.calendar.reminders_to_delete.push(id);

            if ($("#reminders-table-body").children().length === 1) {
                $("#no-reminders").show();
            }
            $("#reminder-" + reminder.id).hide("fast", function () {
                $(this).remove();
                if ($("#reminders-table-body").children().length === 1) {
                    $("#no-reminders").show();
                }
            });
        });
    };

    /**
     * Save changes to the calendar item.
     */
    this.save_calendar_item = function () {
        let callback;
        helium.ajax_error_occurred = false;

        let calendar_item_title = $("#homework-title").val(),
            calendar_item_start_date = $("#homework-start-date").val(),
            calendar_item_start_time = $("#homework-start-time").val(),
            moment_end_time = moment(calendar_item_start_time, helium.HE_TIME_STRING_CLIENT),
            calendar_item_end_time,
            calendar_item_end_date = $("#homework-show-end-time").is(":checked") ? $("#homework-end-date").val()
                                                                                 : calendar_item_start_date,
            homework_category = $("#homework-category").val(), completed, is_category_valid, data;

        if ($("#homework-end-time").is(":visible")) {
            calendar_item_end_time = $("#homework-end-time").val();
        } else {
            let end_offset = helium.USER_PREFS.settings.all_day_offset;
            const updated_end = moment_end_time.clone().add(end_offset, "minutes");
            // Check if the offset causes us to roll in to the next day, and if so, cut it off
            if (updated_end.day() !== moment_end_time.day()) {
                const midnight = updated_end.startOf("day");
                end_offset = midnight.diff(moment_end_time, 'minutes') - 1;
            }
            calendar_item_end_time = moment_end_time.add(end_offset, "minutes").format(helium.HE_TIME_STRING_CLIENT);
        }

        self.clear_calendar_item_errors();

        // Validate
        is_category_valid =
            $("#homework-category").find("option").length === 0 || homework_category !== null
            || (self.current_calendar_item !== null && self.current_calendar_item.calendar_item_type === 0) || $(
                                                              "#homework-event-switch").is(":checked");
        if (/\S/.test(calendar_item_title) && calendar_item_start_date !== "" && calendar_item_end_date !== ""
            && is_category_valid) {
            let reminders_data = [], start, end;
            $("#loading-homework-modal").spin(helium.SMALL_LOADING_OPTS);

            completed = $("#homework-completed").is(":checked");

            // Build a JSONifyable list of reminder elements
            $("[id^='reminder-'][id$='-modified']").each(function () {
                helium.planner_api.edit_reminder(function () {
                                                 }, $(this).attr("id").split("reminder-")[1].split("-modified")[0],
                                                 {
                                                     "title": $($(this).children()[0]).text(),
                                                     "message": $($(this).children()[0]).text(),
                                                     "type": $($(this).children()[1]).find("[id$='-type']").val(),
                                                     "offset": $($(this).children()[1]).find("[id$='-offset']").text(),
                                                     "offset_type": $($(this).children()[1])
                                                         .find("[id$='-offset-type']").val()
                                                 });
            });

            $("[id^='reminder-'][id$='-unsaved']").each(function () {
                reminders_data.push({
                                        "title": $($(this).children()[0]).text(),
                                        "message": $($(this).children()[0]).text(),
                                        "type": $($(this).children()[1]).find("[id$='-type']").val(),
                                        "offset": $($(this).children()[1]).find("[id$='-offset']").text(),
                                        "offset_type": $($(this).children()[1]).find("[id$='-offset-type']").val()
                                    });
            });

            // If the all-day box is checked, set times to midnight
            if ($("#homework-all-day").is(":checked")) {
                start = moment(calendar_item_start_date + " 12:00 AM", helium.HE_DATE_TIME_STRING_CLIENT);
                end = moment(calendar_item_end_date + " 12:00 AM", helium.HE_DATE_TIME_STRING_CLIENT).add(1, "days");
            } else {
                start =
                    moment(calendar_item_start_date + " " + calendar_item_start_time,
                           helium.HE_DATE_TIME_STRING_CLIENT);
                end = moment(calendar_item_end_date + " " + calendar_item_end_time, helium.HE_DATE_TIME_STRING_CLIENT);
            }

            // In the event that all-day was not checked, but the timed event spans multiple days, still correct for
            // the all-day offset
            if (!$("#homework-all-day").is(":checked") && !start.isSame(end, "day")) {
                end = end.add(1, "days");
            }

            // Stringify
            start = start.toISOString();
            end = end.toISOString();

            data = {
                "title": $("#homework-title").val(),
                "all_day": $("#homework-all-day").is(":checked"),
                "show_end_time": $("#homework-show-end-time").is(":checked"),
                "start": start,
                "end": end,
                "current_grade": completed && $("#homework-grade").val() !== "" ? $("#homework-grade").val()
                    .replace(/\s/g, "") : "-1/100",
                "priority": $("#homework-priority > span").slider("option", "value"),
                "completed": completed,
                "comments": $("#homework-comments").html(),
                "course": $("#homework-class").val(),
                "category": homework_category !== null ? homework_category.toString() : "-1"
            };
            if ($("#homework-materials").val()) {
                data["materials"] = $("#homework-materials").val();
            } else {
                data["materials"] = []
            }
            if (self.edit) {
                if (self.current_calendar_item.calendar_item_type === 1) {
                    helium.planner_api.get_courses(function (courses) {
                        data["course_group"] =
                            helium.calendar.get_course_from_list_by_pk(courses, data["course"]).course_group;
                    }, false, true, false);
                }

                $.each(reminders_data, function (i, reminder_data) {
                    if (self.current_calendar_item.calendar_item_type === 1) {
                        reminder_data["homework"] = self.current_calendar_item.id;
                    } else {
                        reminder_data["event"] = self.current_calendar_item.id.substr(6);
                    }
                    if (reminder_data.title === "Empty") {
                        reminder_data.title = "";
                    }

                    helium.ajax_calls.push(helium.planner_api.add_reminder(function (data) {
                        if (helium.data_has_err_msg(data)) {
                            helium.ajax_error_occurred = true;
                            $("#loading-homework-modal").spin(false);

                            $("#homework-error").html("Reminders: " + helium.get_error_msg(data));
                            $("#homework-error").parent().show("fast");

                            return false;
                        }
                    }, reminder_data));
                });

                if (!helium.ajax_error_occurred) {
                    $.each(helium.calendar.reminders_to_delete, function (i, reminder_id) {
                        helium.ajax_calls.push(helium.planner_api.delete_reminder(function () {
                            if (helium.data_has_err_msg(data)) {
                                helium.ajax_error_occurred = true;
                                $("#loading-homework-modal").spin(false);

                                $("#homework-error").html("Reminders: " + helium.get_error_msg(data));
                                $("#homework-error").parent().show("fast");

                                return false;
                            } else {
                                const new_count = parseInt($("#reminder-bell-count").text()) - 1;
                                const popup = $("#reminder-popup-" + reminder_id);

                                if (popup.length > 0) {
                                    popup.hide();

                                    $("#reminder-bell-count")
                                        .html(new_count + " Reminder" + (new_count > 1 ? "s" : ""));
                                    $("#reminder-bell-alt-count").html(new_count);
                                    if (new_count === 0) {
                                        $("#reminder-bell-alt-count").hide("fast");
                                    }
                                }
                            }
                        }, reminder_id));
                    });
                }

                if (!helium.ajax_error_occurred) {
                    $.each(helium.calendar.attachments_to_delete, function (i, attachment_id) {
                        helium.ajax_calls.push(helium.planner_api.delete_attachment(function () {
                            if (helium.data_has_err_msg(data)) {
                                helium.ajax_error_occurred = true;
                                $("#loading-homework-modal").spin(false);

                                $("#homework-error").html(helium.get_error_msg(data));
                                $("#homework-error").parent().show("fast");

                                return false;
                            }
                        }, attachment_id));
                    });
                }

                callback = function (data) {
                    if (helium.data_has_err_msg(data)) {
                        helium.ajax_error_occurred = true;
                        $("#loading-homework-modal").spin(false);

                        $("#homework-error").html(helium.get_error_msg(data));
                        $("#homework-error").parent().show("fast");
                    } else {
                        if (!helium.ajax_error_occurred) {
                            if (data.calendar_item_type === 0) {
                                data.id = "event_" + data.id;
                            }

                            self.update_current_calendar_item(data, false);

                            self.last_type_event = $("#homework-event-switch").is(":checked");
                            self.last_good_date = moment(data.start);
                            self.last_good_end_date = moment(data.end);

                            self.calendar_item_for_dropzone = data;

                            if (self.dropzone !== null && self.dropzone.getQueuedFiles().length > 0) {
                                self.dropzone.processQueue();
                            } else {
                                $("#calendar").fullCalendar("unselect");

                                $("#loading-homework-modal").spin(false);
                                $("#homework-modal").modal("hide");
                            }
                        }
                    }
                };

                $.when.apply($, helium.ajax_calls).done(function () {
                    helium.calendar.reminders_to_delete = [];
                    helium.calendar.attachments_to_delete = [];

                    if (self.current_calendar_item.calendar_item_type === 0) {
                        helium.planner_api.edit_event(callback, self.current_calendar_item.id, data);
                    } else {
                        const course = helium.calendar.courses[self.current_calendar_item.course];

                        helium.planner_api.edit_homework(callback, course.course_group, course.id,
                                                         self.current_calendar_item.id, data);
                    }

                    self.nullify_calendar_item_persistence();
                });
            } else {
                if (!$("#homework-event-switch").is(":checked")) {
                    helium.planner_api.get_courses(function (courses) {
                        data["course_group"] =
                            helium.calendar.get_course_from_list_by_pk(courses, data["course"]).course_group;
                    }, false, true);
                }

                callback = function (data) {
                    if (helium.data_has_err_msg(data)) {
                        helium.ajax_error_occurred = true;
                        $("#loading-homework-modal").spin(false);

                        $("#homework-error").html(helium.get_error_msg(data));
                        $("#homework-error").parent().show("fast");
                    } else {
                        const calendar_item = data;
                        calendar_item.id =
                            calendar_item.calendar_item_type === 0 ? "event_" + calendar_item.id : calendar_item.id;

                        let color;
                        if (calendar_item.calendar_item_type === 1) {
                            color = helium.USER_PREFS.settings.calendar_use_category_colors
                                    ? helium.calendar.categories[calendar_item.category].color
                                    : helium.calendar.courses[calendar_item.course].color;
                        } else {
                            color = helium.USER_PREFS.settings.events_color
                        }

                        $("#calendar").fullCalendar("renderEvent", {
                            id: calendar_item.id,
                            color: color,
                            checkbox: calendar_item.calendar_item_type === 1
                                      ? helium.calendar.get_calendar_item_checkbox(
                                    calendar_item) : "",
                            title: helium.calendar.get_calendar_item_title(calendar_item),
                            title_no_format: calendar_item.title,
                            start: moment(calendar_item.start).tz(helium.USER_PREFS.settings.time_zone),
                            end: moment(calendar_item.end).tz(helium.USER_PREFS.settings.time_zone),
                            allDay: calendar_item.all_day,
                            all_day: calendar_item.all_day,
                            // The following elements are for list view display accuracy
                            materials: calendar_item.calendar_item_type === 1 ? calendar_item.materials : [],
                            show_end_time: calendar_item.show_end_time,
                            calendar_item_type: calendar_item.calendar_item_type,
                            course: calendar_item.calendar_item_type === 1 ? calendar_item.course : null,
                            category: calendar_item.calendar_item_type === 1 ? calendar_item.category : null,
                            completed: calendar_item.calendar_item_type === 1 ? calendar_item.completed : false,
                            priority: calendar_item.priority,
                            current_grade: calendar_item.calendar_item_type === 1 ? calendar_item.current_grade : null,
                            url: (calendar_item.calendar_item_type !== 0 && calendar_item.calendar_item_type === 1)
                                 ? calendar_item.url : null,
                            comments: calendar_item.comments,
                            attachments: calendar_item.attachments,
                            reminders: calendar_item.reminders
                        });

                        if (!helium.ajax_error_occurred) {
                            $.each(reminders_data, function (i, reminder_data) {
                                if (calendar_item.calendar_item_type === 1) {
                                    reminder_data["homework"] = calendar_item.id;
                                } else {
                                    reminder_data["event"] = calendar_item.id.substr(6);
                                }

                                helium.ajax_calls.push(helium.planner_api.add_reminder(function (data) {
                                    if (helium.data_has_err_msg(data)) {
                                        helium.ajax_error_occurred = true;
                                        $("#loading-homework-modal").spin(false);

                                        $("#homework-error").html("Reminders: " + helium.get_error_msg(data));
                                        $("#homework-error").parent().show("fast");

                                        return false;
                                    }
                                }, reminder_data));
                            });

                            self.last_type_event = $("#homework-event-switch").is(":checked");
                            self.last_good_date = moment(calendar_item.start);
                            self.last_good_end_date = moment(calendar_item.end);

                            self.calendar_item_for_dropzone = calendar_item;

                            if (self.dropzone !== null && self.dropzone.getQueuedFiles().length > 0) {
                                self.dropzone.processQueue();
                            } else {
                                $("#calendar").fullCalendar("unselect");

                                $("#loading-homework-modal").spin(false);
                                $("#homework-modal").modal("hide");
                            }
                        }
                    }
                };

                $.when.apply($, helium.ajax_calls).done(function () {
                    helium.calendar.reminders_to_delete = [];
                    helium.calendar.attachments_to_delete = [];

                    if ($("#homework-event-switch").is(":checked")) {
                        helium.planner_api.add_event(function (event) {
                            helium.planner_api.get_event(callback, "event_" + event.id, false);
                        }, data);
                    } else {
                        helium.planner_api.add_homework(function (homework) {
                            helium.planner_api.get_homework(callback, data.course_group, data.course, homework.id);
                        }, data.course_group, data.course, data);
                    }

                    self.nullify_calendar_item_persistence();
                });
            }
        } else {
            // Validation failed, so don't save and prompt the user for action
            $("#homework-error").html("These fields are required.");
            $("#homework-error").parent().show("fast");

            if (!/\S/.test(calendar_item_title)) {
                $("#homework-title").parent().parent().addClass("has-error");
            }
            if (calendar_item_start_date === "") {
                $("#homework-start-date").parent().parent().addClass("has-error");
            }
            if (calendar_item_end_date === "") {
                $("#homework-end-date").parent().parent().addClass("has-error");
            }
            if (homework_category === null) {
                $("#homework-category").parent().parent().addClass("has-error");
            }

            $("a[href='#homework-panel-tab-1']").tab("show");
        }
    };

    /**
     * Set the timing fields with the Calendar's start, end, all_day, and set_end_time values.
     */
    this.set_timing_fields = function () {
        $("#homework-start-time").timepicker("setTime", helium.calendar.start.format(helium.HE_TIME_STRING_CLIENT));
        $("#homework-end-time").timepicker("setTime", helium.calendar.end.format(helium.HE_TIME_STRING_CLIENT));
        $("#homework-all-day").prop("checked", helium.calendar.all_day).trigger("change");
        $("#homework-show-end-time").prop("checked", helium.calendar.show_end_time).trigger("change");
    };

    /**
     * Update the current_calendar_item with the given calendar_item data from the database.
     *
     * @param calendar_item the latest calendar item from the database
     */
    this.update_current_calendar_item = function (calendar_item, update_related) {
        self.current_calendar_item = $("#calendar").fullCalendar("clientEvents", [calendar_item.id])[0];
        if (self.current_calendar_item === undefined) {
            console.debug("current_calendar_item not currently shown on calendar, so nothing to do")

            return;
        }

        calendar_item.start = moment(calendar_item.start).tz(helium.USER_PREFS.settings.time_zone);
        calendar_item.end = moment(calendar_item.end).tz(helium.USER_PREFS.settings.time_zone);

        let color;
        if (calendar_item.calendar_item_type === 1) {
            color = helium.USER_PREFS.settings.calendar_use_category_colors
                    ? helium.calendar.categories[calendar_item.category].color
                    : helium.calendar.courses[calendar_item.course].color;
        } else {
            color = helium.USER_PREFS.settings.events_color
        }

        self.current_calendar_item.color = color;
        self.current_calendar_item.checkbox =
            calendar_item.calendar_item_type === 1 ? helium.calendar.get_calendar_item_checkbox(calendar_item) : "";
        self.current_calendar_item.title = helium.calendar.get_calendar_item_title(calendar_item);
        self.current_calendar_item.title_no_format = calendar_item.title;
        self.current_calendar_item.start =
            !calendar_item.all_day ? calendar_item.start : $("#calendar").fullCalendar("getCalendar")
                .moment(calendar_item.start).stripTime().stripZone();
        self.current_calendar_item.end =
            !calendar_item.all_day ? calendar_item.end : $("#calendar").fullCalendar("getCalendar")
                .moment(calendar_item.end).stripTime().stripZone();
        self.current_calendar_item.allDay = calendar_item.all_day;

        // The following elements are for list view display accuracy
        self.current_calendar_item.materials = calendar_item.calendar_item_type === 1 ? calendar_item.materials : [];
        self.current_calendar_item.show_end_time = calendar_item.show_end_time;
        self.current_calendar_item.course = calendar_item.calendar_item_type === 1 ? calendar_item.course : null;
        self.current_calendar_item.category = calendar_item.calendar_item_type === 1 ? calendar_item.category : null;
        self.current_calendar_item.completed = calendar_item.calendar_item_type === 1 ? calendar_item.completed : false;
        self.current_calendar_item.priority = calendar_item.priority;
        self.current_calendar_item.current_grade =
            calendar_item.calendar_item_type === 1 ? calendar_item.current_grade : null;
        self.current_calendar_item.comments = calendar_item.comments;
        if (update_related) {
            self.current_calendar_item.attachments = calendar_item.attachments;
            self.current_calendar_item.reminders = calendar_item.reminders;
        }

        $("#calendar").fullCalendar("updateEvent", self.current_calendar_item);
        $("#calendar").fullCalendar("unselect");
    };
}

(function () {
    $.fullCalendar.views.assignmentsList = $.fullCalendar.ListView.extend(
        {
            tableEl: null,
            dataTable: null,
            latestRow: null,

            buildCurrentRangeInfo: function () {
                const duration = moment.duration({
                                                     days: helium.calendar.course_filter_window_end.diff(
                                                         helium.calendar.course_filter_window_start, "days")
                                                 });
                const unit = "day";
                const unzonedRange = new $.fullCalendar.UnzonedRange(
                    helium.calendar.course_filter_window_start,
                    helium.calendar.course_filter_window_end
                );

                return {duration: duration, unit: unit, unzonedRange: unzonedRange};
            },

            setDate: function (date) {
                this.calendar.removeEventSource(helium.calendar.event_source_external_calendars);
                this.calendar.removeEventSource(helium.calendar.event_source_events);
                this.calendar.removeEventSource(helium.calendar.event_source_class_schedules);

                var currentDateProfile = this.get('dateProfile');
                var newDateProfile = this.buildDateProfile(date, null, true); // forceToValid=true

                if (
                    !currentDateProfile ||
                    !currentDateProfile.activeUnzonedRange.equals(newDateProfile.activeUnzonedRange)
                ) {
                    this.set('dateProfile', newDateProfile);
                }
            },

            eventRendererClass: $.fullCalendar.EventRenderer.extend(
                {
                    renderFgSegs: function (segs) {
                        if (!segs.length) {
                            this.component.renderEmptyMessage();
                        } else {
                            this.component.renderSegList(segs);
                        }
                    },

                    fgSegHtml: function (seg) {
                        const view = this.view;
                        const calendar = view.calendar;
                        const theme = calendar.theme;
                        const eventFootprint = seg.footprint;
                        const eventDef = eventFootprint.eventDef;
                        const classes = ['fc-list-item'].concat(this.getClasses(eventDef));

                        if (eventDef.miscProps.calendar_item_type !== 1) {
                            return "";
                        }

                        let course_string = eventDef.miscProps.calendar_item_type === 1
                                            ? ('<span class="label label-sm title-label" style="background-color: '
                                               + helium.calendar.courses[eventDef.miscProps.course].color
                                               + ' !important">'
                                               + (helium.str_not_empty(
                                    helium.calendar.courses[eventDef.miscProps.course].website)
                                                  && helium.calendar.courses[eventDef.miscProps.course].website.replace(
                                    /\s/g,
                                    "").length
                                                  > 0
                                                  ? "<a target=\"_blank\" href=\""
                                               + helium.calendar.courses[eventDef.miscProps.course].website
                                               + "\" class=\"planner-title-with-link\">" : "")
                                               + helium.calendar.courses[eventDef.miscProps.course].title
                                               + (helium.str_not_empty(
                                    helium.calendar.courses[eventDef.miscProps.course].website)
                                                  && helium.calendar.courses[eventDef.miscProps.course].website.replace(
                                    /\s/g,
                                    "").length
                                                  > 0 ? " <i class=\"icon-external-link\"></i></a>"
                                                      : "")
                                               + '</span>') : "";

                        return '<tr class="' + classes.join(' ') + '">' +
                               '<td class="' + theme.getClass('widgetContent') + '">' + eventDef.miscProps.checkbox
                               + '</td>' +
                               '<td class="fc-assignmentList-item-title ' + theme.getClass('widgetContent') + '">'
                               + eventDef.title + '</td>' +
                               '<td class="' + theme.getClass('widgetContent') + '">' + $.fullCalendar.formatDate(
                                eventDef.dateProfile.start, "MMM D, YYYY") + (!eventDef.miscProps.all_day
                                                                              ? $.fullCalendar.formatDate(
                                    eventDef.dateProfile.start, " h:mm a") : "") + '</td>' +
                               '<td class="' + theme.getClass('widgetContent')
                               + '">' + course_string + '</td>' +
                               '<td class="' + theme.getClass('widgetContent') + '">'
                               + (eventDef.miscProps.calendar_item_type
                                  === 1 ? (eventDef.miscProps.category
                                           !== null
                                           ? ("<span class=\"label label-sm\" style=\"background-color: "
                               + helium.calendar.categories[eventDef.miscProps.category].color + " !important\">"
                               + helium.calendar.categories[eventDef.miscProps.category].title + "</span>") : "") : "")
                               + '</td>' +
                               '<td class="' + theme.getClass('widgetContent') + '">'
                               + (eventDef.miscProps.calendar_item_type
                                  === 1
                                  ? helium.calendar.get_materials_titles_badges_from_ids(
                                    eventDef.miscProps.materials) : "") + '</td>' +
                               '<td class="' + theme.getClass('widgetContent') + '">'
                               + (eventDef.miscProps.calendar_item_type
                                  === 1
                                  ? "<div class=\"progress progress-mini progress-striped\" style=\"margin-top: 6px; margin-bottom: 0;\"><div class=\"progress-bar progress-bar-success\" style=\"width: "
                               + eventDef.miscProps.priority + "%;\"><span class=\"hidden\">"
                               + eventDef.miscProps.priority
                               + "</span></div></div>" : "") + '</td>' +
                               '<td class="' + theme.getClass('widgetContent') + '">' + (eventDef.miscProps.completed
                                                                                         && eventDef.miscProps.current_grade
                                                                                         !== "-1/100"
                                                                                         ? "<span class=\"badge\" style=\"background-color: "
                               + helium.USER_PREFS.settings.grade_color + " !important\">"
                               + helium.grade_for_display(eventDef.miscProps.current_grade) + "</span>" : "") + '</td>'
                               +
                               '</tr>';
                    },

                    computeEventTimeFormat: function () {
                        return this.opt('mediumTimeFormat');
                    }

                }),

            headerHtml: function () {
                const calendar = this.calendar;
                const theme = calendar.theme;

                return '<thead class="fc-list-heading"><tr>'
                       + '<th class=' + theme.getClass('widgetHeader') + '></th>'
                       + '<th class=' + theme.getClass('widgetHeader')
                       + '><span class="hidden-xs">Title</span><span class="visible-xs">Assignment</span></th>'
                       + '<th class=' + theme.getClass('widgetHeader') + '>Due <span class="hidden-xs">Date</span></th>'
                       + '<th class=' + theme.getClass('widgetHeader') + '>Class</th>'
                       + '<th class=' + theme.getClass('widgetHeader') + '>Category</th>'
                       + '<th class=' + theme.getClass('widgetHeader') + '>Materials</th>'
                       + '<th class=' + theme.getClass('widgetHeader') + '>Priority</th>'
                       + '<th class=' + theme.getClass('widgetHeader') + '>Grade</th>'
                       + '</tr></thead>';
            },

            renderSegList: function (segs) {
                const calendar = this.calendar;
                const theme = calendar.theme;

                if (this.dataTable !== null) {
                    this.dataTable.clear();
                }

                const table_div = this.tableEl = $(
                    '<table id="assignments-list-table"  class="fc-list-table table-striped '
                    + theme.getClass(
                        'tableList')
                    + '"><tbody/></table>');
                const tbodyEl = table_div.find('tbody');

                table_div.append(this.headerHtml());

                let i;
                for (i = 0; i < segs.length; i++) {
                    tbodyEl.append(segs[i].el);
                }

                this.contentEl.empty().append(table_div);

                this.dataTable = table_div.dataTable(
                    {
                        lengthMenu: [
                            [5, 10, 25, 50, 100, -1],
                            [5, 10, 25, 50, 100, "All"]
                        ],
                        pageLength: 10,
                        order: [2, "asc"],
                        aoColumns: [
                            // Checkbox
                            {bSearchable: false, sClass: "hidden-print", sWidth: "50px", orderDataType: "dom-checkbox"},
                            // Title
                            null,
                            // Due Date
                            {sType: "date", sWidth: "180px"},
                            // Class
                            {sClass: "hidden-xs"},
                            // Category
                            {sClass: "hidden-xs hidden-sm"},
                            // Materials
                            {sClass: "hidden-xs"},
                            // Priority
                            {sClass: "hidden-xs", sWidth: "110px"},
                            // Grade
                            {sWidth: "110px"}
                        ],
                        stateSave: helium.USER_PREFS.settings.remember_filter_state,
                        oLanguage: {
                            sEmptyTable: "Nothing to see here. Change the date or filters, or click \"+\" to add an assignment.",
                            sInfo: "Showing _START_ to _END_ of _TOTAL_ todos",
                            sInfoEmpty: "Showing 0 to 0 of 0 todos",
                            sLengthMenu: "Show _MENU_ todos",
                            oPaginate: {
                                sPrevious: "<i class=\"icon-angle-left\"></i>",
                                sNext: "<i class=\"icon-angle-right\"></i>"
                            }
                        },
                        destroy: true
                    }).DataTable();

                table_div.parent().find("#assignments-list-table_length").parent()
                    .addClass("col-xs-12").removeClass("col-xs-6")
                    .next().remove();
                table_div.parent().find("#assignments-list-table_length").parent().parent()
                    .addClass("hidden-print");
                table_div.parent().find("#assignments-list-table_length select").attr("style", "display: inline");
                table_div.parent().find("#assignments-list-table_info").parent()
                    .addClass("col-sm-6 col-xs-12").removeClass("col-xs-6")
                    .parent().addClass("hidden-print");
                table_div.parent().find("#assignments-list-table_info").parent().next()
                    .addClass("col-sm-6 col-xs-12").removeClass("col-xs-6");

                table_div.wrap('<div class="row"></div>');

                this.latestBeforeToday = moment(calendar.eventManager.currentPeriod.start);
                for (let seg of segs) {
                    let eventDef = seg.footprint.eventDef;
                    let row = $(seg.el[0]);

                    row.attr("id", "homework-table-row-" + eventDef.id);

                    // Check if we've reached today's date
                    if (!this.dataTable !== null && eventDef.dateProfile.start.unix() < moment().stripZone().unix() &&
                        eventDef.dateProfile.start.unix() > this.latestBeforeToday.unix()) {
                        this.latestBeforeToday = eventDef.dateProfile.start;
                        this.latestRow = row;
                    }
                }

                if (this.dataTable !== null &&
                    this.dataTable.order()[0][0] === 2 &&
                    this.dataTable.order()[0][1] === "asc" &&
                    this.latestRow &&
                    this.latestRow.children().length > 0) {
                    // Jump to the page with the current date's row on it
                    let rowIndex = this.dataTable.row(this.latestRow).index(), pageNum;
                    if (rowIndex !== 0) {
                        pageNum = Math.floor(rowIndex / this.dataTable.page.len());
                    } else {
                        pageNum = 0;
                    }
                    this.dataTable.page(pageNum).draw(false);
                }
            }
        });

    $.fullCalendar.views.assignmentsList.watch('dateProfileForCalendarOverride', ['dateProfile'], function () {
        this.unwatch('titleForCalendar');
    });

    $.fullCalendar.views.assignmentsList.watch('titleForCalendarOverride', ['title'], function () {
        this.calendar.header.el.find('h2')
            .html(
                "Assignments <span class=\"assignmentslist-help help-button\" data-rel=\"popover\" data-trigger=\"hover\" data-container=\"body\" data-placement=\"right\" data-content=\"This view shows only assignments—no class schedules, events, or external calendars—allowing you to quickly sort through and review your schoolwork.\" title=\"Todo View\">?</span>")
            .find(".help-button").popover({html: true}).data("bs.popover").tip().css("z-index", 1060);
    });
})();

// Initialize HeliumClasses and give a reference to the Helium object
helium.calendar = new HeliumCalendar();

/*******************************************
 * jQuery initialization
 ******************************************/

$(window).resize(function () {
    "use strict";

    if ($('#calendar').data('fullCalendar') && !helium.calendar.is_resizing_calendar_item) {
        helium.calendar.adjust_calendar_size();
    }
});

$(document).ready(function () {
    "use strict";

    $("#loading-calendar").spin(document.LARGE_LOADING_OPTS);

    $("#dropzone-form").attr("action", helium.API_URL + "/planner/attachments/");

    // Prevent Dropzone auto-initialization, as we'll do it in a bit
    Dropzone.autoDiscover = false;

    /*******************************************
     * Initialize component libraries
     ******************************************/
    // Searching is provided by the calendar page, so disable it in the dataTables library
    $.extend($.fn.dataTable.defaults, {
        "searching": false
    });

    // Add a plugin to allow ordering by checkbox
    $.fn.dataTable.ext.order['dom-checkbox'] = function (settings, col) {
        return this.api().column(col, {order: 'index'}).nodes().map(function (td) {
            return $('input', td).prop('checked') ? '1' : '0';
        });
    };

    bootbox.setDefaults({
                            locale: 'en'
                        });

    $.when.apply($, helium.ajax_calls).done(function () {
        moment.tz.setDefault(helium.USER_PREFS.settings.time_zone);

        $("#homework-modal").scroll(function () {
            "use strict";

            $('.date-picker').datepicker('place');
        });

        $("#homework-grade-percent span")
            .attr("style", "background-color: " + helium.USER_PREFS.settings.grade_color + " !important");

        $(".date-picker").datepicker({
                                         autoclose: true,
                                         language: 'en',
                                         weekStart: helium.USER_PREFS.settings.week_starts_on
                                     }).next().on("click", function () {
            $(this).prev().focus();
        });
        $("#homework-start-date").datepicker().on("changeDate", function () {
            const start_date = moment($("#homework-start-date").val()).toDate(),
                end_date = moment($("#homework-end-date").val()).toDate();
            if (start_date > end_date) {
                $("#homework-end-date").datepicker("setDate", start_date);
            }
        });
        $("#homework-end-date").datepicker().on("changeDate", function () {
            const start_date = moment($("#homework-start-date").val()).toDate(),
                end_date = moment($("#homework-end-date").val()).toDate();
            if (start_date > end_date) {
                $("#homework-start-date").datepicker("setDate", end_date);
            }
        });
        $(".time-picker").timepicker({
                                         minuteStep: 5
                                     }).next().on("click", function () {
            $(this).prev().focus();
        });
        $("#homework-start-time").timepicker().on("changeTime.timepicker", function (event) {
            const start_time = moment($("#homework-start-date").val() + " " + event.time.value,
                                      helium.HE_DATE_TIME_STRING_CLIENT),
                end_time = moment($("#homework-end-date").val() + " " + $("#homework-end-time").val(),
                                  helium.HE_DATE_TIME_STRING_CLIENT);
            if (start_time.isAfter(end_time)) {
                $("#homework-end-time").timepicker("setTime", start_time.format(helium.HE_TIME_STRING_CLIENT));
            }
        });
        $("#homework-end-time").timepicker().on("changeTime.timepicker", function (event) {
            const start_time = moment($("#homework-start-date").val() + " " + $("#homework-start-time").val(),
                                      helium.HE_DATE_TIME_STRING_CLIENT),
                end_time = moment($("#homework-end-date").val() + " " + event.time.value,
                                  helium.HE_DATE_TIME_STRING_CLIENT);
            if (start_time.isAfter(end_time)) {
                $("#homework-start-time").timepicker("setTime", end_time.format(helium.HE_TIME_STRING_CLIENT));
            }
        });
        $("#homework-priority > span").css({width: "90%", "float": "left", margin: "15px"}).each(function () {
            const value = parseInt($(this).text(), 10);
            $(this).empty().slider({
                                       value: value,
                                       range: "min",
                                       animate: true
                                   });
        });
        if ($(window).width() > 768) {
            $("#homework-materials").chosen({
                                                width: "100%",
                                                search_contains: true,
                                                no_results_text: "No materials match"
                                            });
            $("#homework-category").chosen({
                                               width: "100%",
                                               enable_split_word_search: false,
                                               no_results_text: "No categories match"
                                           });
            $("#homework-category").chosen().change(function () {
                $("#homework-completed").trigger("change");
            });
        } else {
            $("#homework-materials").css("max-width", "100%");
            $("#homework-category").css("max-width", "100%");
        }

        $("#homework-event-switch").next().find(".toggle-on").attr("style",
                                                                   "background-color: "
                                                                   + helium.USER_PREFS.settings.events_color
                                                                   + " !important;"
                                                                   + "border-color: "
                                                                   + helium.USER_PREFS.settings.events_color
                                                                   + " !important;");

        /*******************************************
         * Other page initialization
         ******************************************/
        helium.calendar.course_groups = {};
        helium.calendar.courses = {};

        helium.planner_api.get_course_groups(function (data) {
            if (helium.data_has_err_msg(data)) {
                helium.ajax_error_occurred = true;
                $("#loading-calendar").spin(false);

                bootbox.alert(helium.get_error_msg(data));
            } else {
                $.each(data, function (index, course_group) {
                    helium.calendar.course_groups[course_group['id']] = course_group;
                });
            }
        }, false);

        helium.calendar.categories = {};

        if (!helium.ajax_error_occurred) {
            helium.planner_api.get_categories_by_user_id(function (data) {
                if (helium.data_has_err_msg(data)) {
                    helium.ajax_error_occurred = true;
                    $("#loading-calendar").spin(false);

                    bootbox.alert(helium.get_error_msg(data));
                } else {
                    $.each(data, function (index, category) {
                        helium.calendar.categories[category.id] = category;
                    });
                }
            }, false);
        }

        helium.calendar.material_groups = {};
        helium.calendar.materials = {};

        if (!helium.ajax_error_occurred) {
            helium.planner_api.get_material_groups(function (data) {
                if (helium.data_has_err_msg(data)) {
                    helium.ajax_error_occurred = true;
                    $("#loading-calendar").spin(false);

                    bootbox.alert(helium.get_error_msg(data));
                } else {
                    $.each(data, function (index, material_group) {
                        helium.calendar.material_groups[material_group['id']] = material_group;

                        helium.planner_api.get_materials_by_material_group_id(function (data) {
                            $.each(data, function (index, material) {
                                helium.calendar.materials[material['id']] = material;
                            });
                        }, material_group['id'], false, true);
                    });
                }
            }, false);
        }

        if (!helium.ajax_error_occurred) {
            helium.planner_api.get_external_calendars(function (data) {
                if (helium.data_has_err_msg(data)) {
                    helium.ajax_error_occurred = true;
                    $("#loading-calendar").spin(false);

                    bootbox.alert(helium.get_error_msg(data));
                } else {
                    $.each(data, function (index, external_calendar) {
                        if (!helium.calendar.courses.hasOwnProperty(external_calendar.id)) {
                            helium.calendar.external_calendars[external_calendar.id] = external_calendar;
                        }
                    });
                }
            }, false, false);
        }

        if (!helium.ajax_error_occurred) {
            helium.planner_api.get_courses(function (courses) {
                if (helium.data_has_err_msg(courses)) {
                    helium.ajax_error_occurred = true;
                    $("#loading-calendar").spin(false);

                    bootbox.alert(helium.get_error_msg(courses));
                } else {
                    let course_groups = Object.entries(helium.calendar.course_groups);
                    course_groups.sort((a, b) => {
                        const a_start = moment(a[1].start_date);
                        const b_start = moment(b[1].start_date);

                        if (a_start.isAfter(b_start)) {
                            return -1;
                        } else if (a_start.isBefore(b_start)) {
                            return 1;
                        }
                        return 0;
                    });

                    $.each(course_groups, function (group_index, course_group_tuple) {
                        let course_group = course_group_tuple[1];

                        const group = $("<optgroup>");
                        $("#homework-class").append(group);
                        $.each(courses, function (index, course) {
                            if (!helium.calendar.courses.hasOwnProperty(course.id)) {
                                helium.calendar.courses[course.id] = course;
                            }

                            if (!helium.calendar.course_groups[course.course_group].shown_on_calendar ||
                                course_group.id !== course.course_group) {
                                return true;
                            }

                            group.append("<option value=\"" + course.id + "\">" + course.title
                                        + " <span class=\"color-dot inline\" style=\"background-color: "
                                        + course.color + "\"></span></option>");
                        });
                    });

                    if ($(window).width() > 768) {
                        $("#homework-class").chosen({
                                                        width: "100%",
                                                        enable_split_word_search: false,
                                                        no_results_text: "No classes match"
                                                    });
                    }
                }
            }, false, false, false);
        }

        $.when.apply($, helium.ajax_calls).done(function () {
            if (!helium.ajax_error_occurred) {
                helium.calendar.initialize_calendar();

                $.when.apply($, helium.ajax_calls).done(function () {
                    $(".materials-help").on("click", function () {
                        window.location = "/planner/materials";
                    });

                    $(".wysiwyg-editor").ace_wysiwyg({
                                                         toolbar: [
                                                             'font',
                                                             null,
                                                             {name: "bold", className: 'btn-info'},
                                                             {name: "italic", className: 'btn-info'},
                                                             {name: "strikethrough", className: 'btn-info'},
                                                             {name: "underline", className: 'btn-info'},
                                                             null,
                                                             {name: "createLink", className: 'btn-pink'},
                                                             {name: "unlink", className: 'btn-pink'},
                                                             null,
                                                             {
                                                                 name: "insertunorderedlist",
                                                                 className: 'btn-success'
                                                             },
                                                             {name: "insertorderedlist", className: 'btn-success'},
                                                             null,
                                                             {name: "indent", className: 'btn-purple'},
                                                             {name: "outdent", className: 'btn-purple'},
                                                             null,
                                                             "foreColor"
                                                         ]
                                                     }).prev().addClass("wysiwyg-style3");

                    try {
                        $(".dropzone").dropzone(
                            {
                                maxFilesize: 10,
                                addRemoveLinks: true,
                                autoProcessQueue: false,
                                uploadMultiple: true,
                                parallelUploads: 10,
                                dictDefaultMessage: "<span class=\"bigger-150 bolder\"><i class=\"icon-caret-right red\"></i> Drop files</span> to upload <span class=\"smaller-80 grey\">(or click)</span> <br /> <i class=\"upload-icon icon-cloud-upload blue icon-3x\"></i>",
                                dictResponseError: "An error occurred while uploading the file.",
                                previewTemplate: "<div class=\"dz-preview dz-file-preview\">\n  <div class=\"dz-details\">\n    <div class=\"dz-filename\"><span data-dz-name></span></div>\n    <div class=\"dz-size\" data-dz-size></div>\n    <img data-dz-thumbnail />\n  </div>\n  <div class=\"progress progress-small progress-striped active\"><div class=\"progress-bar progress-bar-success\" data-dz-uploadprogress></div></div>\n  <div class=\"dz-success-mark\"><span></span></div>\n  <div class=\"dz-error-mark\"><span></span></div>\n  <div class=\"dz-error-message\"><span data-dz-errormessage></span></div>\n</div>",
                                init: function () {
                                    helium.calendar.dropzone = this;

                                    this.on("sendingmultiple", function (na, xhr, form_data) {
                                        xhr.setRequestHeader("Authorization",
                                                             "Bearer " + localStorage.getItem("access_token"));
                                        if (helium.calendar.calendar_item_for_dropzone.calendar_item_type === 0) {
                                            form_data.append("event",
                                                             helium.calendar.calendar_item_for_dropzone.id.substr(
                                                                 6));
                                        } else {
                                            form_data.append("homework",
                                                             helium.calendar.calendar_item_for_dropzone.id);
                                        }
                                    });
                                    this.on("successmultiple", function () {
                                        const callback = function (data) {
                                            if (helium.data_has_err_msg(data)) {
                                                $("#loading-homework-modal").spin(false);
                                                helium.ajax_error_occurred = true;

                                                $("#homework-error").html(
                                                    "An error occurred after saving the attachment. Check <a href=\"" + window.STATUS_URL + "\">the status page</a> if the issue persists, and <a href=\"" + window.SUPPORT_URL + "\">contact support</a> if something isn't already mentioned there.");
                                                $("#homework-error").parent().show("fast");

                                                $("a[href='#homework-panel-tab-3']").tab("show");

                                                helium.calendar.calendar_item_for_dropzone = null;
                                            } else {
                                                if (data.calendar_item_type === 0) {
                                                    delete helium.planner_api.event[data.id];
                                                    helium.planner_api.events_by_user_id = {};
                                                    helium.planner_api.reminders_by_calendar_item = {};

                                                    data.id = "event_" + data.id;
                                                } else {
                                                    delete helium.planner_api.homework[data.id];
                                                    helium.planner_api.homework_by_course_id = {};
                                                    helium.planner_api.homework_by_user_id = {};
                                                    helium.planner_api.reminders_by_calendar_item = {};
                                                }
                                                helium.calendar.update_current_calendar_item(data, true)

                                                $("#loading-homework-modal").spin(false);
                                                $("#homework-modal").modal("hide");

                                                helium.calendar.calendar_item_for_dropzone = null;
                                                helium.calendar.dropzone.removeAllFiles();
                                            }
                                        }
                                        if (helium.calendar.calendar_item_for_dropzone.calendar_item_type === 0) {
                                            helium.planner_api.get_event(callback,
                                                                         helium.calendar.calendar_item_for_dropzone.id,
                                                                         true, false);
                                        } else {
                                            helium.planner_api.get_homework(callback,
                                                                            helium.calendar.courses[helium.calendar.calendar_item_for_dropzone.course].course_group,
                                                                            helium.calendar.calendar_item_for_dropzone.course,
                                                                            helium.calendar.calendar_item_for_dropzone.id,
                                                                            true, false);
                                        }
                                    });
                                    this.on("errormultiple", function () {
                                        $("#loading-homework-modal").spin(false);

                                        $("#homework-error").html("The max file size is 10mb.");
                                        $("#homework-error").parent().show("fast");

                                        $("a[href='#homework-panel-tab-3']").tab("show");

                                        helium.calendar.calendar_item_for_dropzone = null;
                                        helium.calendar.dropzone.removeAllFiles();
                                    });
                                }
                            });
                    } catch (e) {
                        helium.calendar.dropzone = null;
                        bootbox.alert("Attachments are not supported in older browsers.");
                    }

                    /*******************************************
                     * Check storage for triggers passed in
                     ******************************************/
                    if (localStorage.getItem("edit_calendar_item") !== null) {
                        helium.calendar.loading_div.spin(helium.SMALL_LOADING_OPTS);

                        let id = localStorage.getItem("edit_calendar_item");

                        const callback = function (data) {
                            if (helium.data_has_err_msg(data)) {
                                helium.ajax_error_occurred = true;
                                helium.calendar.loading_div.spin(false);

                                bootbox.alert(helium.get_error_msg(data));
                            } else {
                                helium.calendar.loading_div.spin(false);

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

                        localStorage.removeItem("edit_calendar_item");
                    } else if (helium.USER_PREFS.settings.show_getting_started && !helium.ajax_error_occurred) {
                        $("#getting-started-modal").modal("show");
                    }
                });
            }
        });
    });
});
