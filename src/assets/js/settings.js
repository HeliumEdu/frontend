/**
 * Copyright (c) 2018 Helium Edu
 *
 * JavaScript for /settings page.
 *
 * FIXME: Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 *  The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 *  project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.11.20
 */

/**
 * Create the HeliumSettings persistence object.
 *
 * @constructor construct the HeliumSettings persistence object
 */
function HeliumSettings() {
    "use strict";

    let self = this;

    self.to_delete = [];

    self.populate_externalcalendars = function () {
        $('tr[id^="externalcalendar-"]').each(function () {
            $(this).remove();
        });

        $.ajax({
                   type: "GET",
                   url: helium.API_URL + "/feed/externalcalendars/",
                   async: false,
                   dataType: "json",
                   success: function (data) {
                       $.each(data, function (key, externalcalendar) {
                           helium.settings.create_externalcalendar(externalcalendar.id, externalcalendar.title,
                                                                   externalcalendar.url,
                                                                   externalcalendar.shown_on_calendar,
                                                                   externalcalendar.color);
                       });
                   }
               });

        if ($("#externalcalendars-table-body").children().length === 1) {
            $("#no-externalcalendars").show();
        }
    };

    self.email_pending = function (email_changing) {
        ($("#id_email_verification_status")
            .html('<i class="icon-time bigger-110 orange"></i> Pending verification of ' + email_changing));
    };

    self.phone_pending = function (phone_changing) {
        $($("#id_phone_verification_status")
              .html('<i class="icon-time bigger-110 orange"></i> Pending verification of ' + phone_changing));
        $("#phone_verification_row").show("fast");
    };

    self.create_externalcalendar = function (id, title, url, shown_on_calendar, color) {
        const row = $('<tr id="externalcalendar-' + id + '">');
        row.append($('<td>').append('<a class="cursor-hover external-title">' + title + '</a>'));
        row.append($('<td class="hidden-480">').append('<a class="cursor-hover external-url">' + url + '</a>'));
        row.append($('<td>').append(
            '<input type="checkbox" class="ace shown-on-calendar" ' + (shown_on_calendar ? 'checked="checked"' : '')
            + '/><span class="lbl" />'));
        row.append(
            $('<td>').append($('<select class="hide color-picker">' + $("#id_color_select").html() + '</select>')));
        row.append($('<td>').append(
            '<div class="btn-group"><button type="button" class="btn btn-xs btn-danger delete-externalcalendar"><i class="icon-trash bigger-120"></i></button></div></td></tr>'));

        $("#externalcalendars-table-body").append(row);

        row.find(".color-picker").simplecolorpicker({
                                                        picker: true,
                                                        theme: "glyphicons"
                                                    });
        row.find(".color-picker").simplecolorpicker("selectColor", color);
        row.find(".external-title").editable({
                                                 type: "text",
                                                 tpl: '<input type="text" maxlength="255">'
                                             });
        row.find(".external-url").editable({
                                               type: "text",
                                               tpl: '<input type="text" maxlength="255">'
                                           });
        row.find(".delete-externalcalendar").on("click", self.delete_externalcalendar);

        if ($("#externalcalendars-table-body").children().length === 2) {
            $("#no-externalcalendars").hide();
        }
    };

    self.delete_externalcalendar = function () {
        let row = $(this).parent().parent().parent(), dom_id, id;
        row.hide("fast", function () {
            dom_id = $(this).attr("id");
            id = dom_id.split("-");
            id = id[id.length - 1];
            if (id !== "null") {
                self.to_delete.push(id);
            }

            $(this).remove();
            if ($("#externalcalendars-table-body").children().length === 1) {
                $("#no-externalcalendars").show();
            }
        });
    };

    self.save_externalcalendars = function (form) {
        let dom_id, id;

        $.each(form.find("tr[id^='externalcalendar-']"), function () {
            dom_id = $(this).attr("id");
            id = dom_id.split("-");
            id = id[id.length - 1];
            const data = {
                title: $(this).find(".external-title").html(),
                url: $(this).find(".external-url").html(),
                color: $(this).find(".color-picker").val(),
                shown_on_calendar: $(this).find(".shown-on-calendar").is(":checked")
            };
            if (id === "null") {
                $.ajax({
                           async: false,
                           context: form,
                           data: JSON.stringify(data),
                           type: 'POST',
                           url: helium.API_URL + '/feed/externalcalendars/',
                           error: function (xhr) {
                               $("#status_preferences").html(
                                   'Oops, an error occurred while saving changes to external calendars. Was the URL valid?')
                                   .addClass("alert-warning").removeClass("hidden");
                           }
                       });
            } else {
                $.ajax({
                           async: false,
                           context: form,
                           data: JSON.stringify(data),
                           type: 'PUT',
                           url: helium.API_URL + '/feed/externalcalendars/' + id + '/',
                           error: function (xhr) {
                               $("#status_preferences").html(
                                   'Oops, an error occurred while saving changes to external calendars. Was the URL valid?')
                                   .addClass("alert-warning").removeClass("hidden");
                           }
                       });
            }
        });
    };

    $("#create-externalcalendar").on("click", function () {
        self.create_externalcalendar("null", 'Holidays',
                                     'https://calendar.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics',
                                     false, $($("#id_color_select option")[Math.floor(
                Math.random() * $("#id_color_select option").length)]).val());
    });

    $("#importexport-form").submit(function (e) {
        // Prevent default submit
        e.preventDefault();
        e.returnValue = false;

        if (!$('#id_file').val()) {
            $("#status_importexport").html("You must choose a file to import first.").addClass("alert-info")
                .removeClass("hidden");

            return false;
        }

        $("#import-button").prop("disabled", true);

        $("#loading-importexport").spin(helium.SMALL_LOADING_OPTS);

        helium.clear_form_errors($(this).attr("id"));

        $.ajax({
                   processData: false,
                   contentType: false,
                   data: new FormData(this),
                   type: 'POST',
                   url: helium.API_URL + '/importexport/import/',
                   error: function (xhr) {
                       $("#status_importexport").html(JSON.stringify(xhr.responseJSON)).addClass("alert-danger")
                           .removeClass("hidden");

                       $("#import-button").prop("disabled", false);

                       $("#loading-importexport").spin(false);
                   },
                   success: function () {
                       $("#import-button").prop("disabled", false);

                       helium.clear_form_errors("importexport-form");

                       localStorage.removeItem("filter_courses_" + helium.USER_PREFS.id);

                       $("#status_importexport").html("Import successful.").addClass("alert-success")
                           .removeClass("hidden");

                       $("#loading-importexport").spin(false);
                   }
               });
    });

    $("#preferences-form").submit(function (e) {
        // Prevent default submit
        e.preventDefault();
        e.returnValue = false;

        $("#loading-preferences").spin(helium.SMALL_LOADING_OPTS);

        helium.clear_form_errors($(this).attr("id"));

        $.ajax().always(function () {
            const form = $("#preferences-form"), data = form.serializeArray();
            data.push({"name": "show_getting_started", "value": helium.USER_PREFS.settings.show_getting_started});
            data.push({
                          "name": "receive_emails_from_admin",
                          "value": helium.USER_PREFS.settings.receive_emails_from_admin
                      });
            data.push({"name": "private_slug", "value": helium.USER_PREFS.settings.private_slug});
            data.push({"name": "events_color", "value": $("#id_color_select").val()});

            self.save_externalcalendars(form);

            $.each(self.to_delete, function (index, id) {
                $.ajax({
                           async: false,
                           type: 'DELETE',
                           url: helium.API_URL + '/feed/externalcalendars/' + id + '/',
                           error: function (xhr) {
                               // TODO: show errors
                           }
                       });
            });
            self.to_delete = [];

            self.populate_externalcalendars();

            $.ajax({
                       async: false,
                       context: form,
                       data: data,
                       contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
                       type: 'PUT',
                       url: helium.API_URL + '/auth/user/settings/',
                       error: function (xhr) {
                           if (xhr.hasOwnProperty("responseJSON")) {
                               $.each(xhr.responseJSON, function (key, value) {
                                   helium.show_error("preferences", key, value);
                               });
                           } else {
                               helium.show_error("", "preferences", helium.planner_api.GENERIC_ERROR_MESSAGE);
                           }

                           $("#loading-preferences").spin(false);
                       },
                       success: function () {
                           helium.clear_form_errors("preferences-form");

                           $("#status_preferences").html("Changes saved.").addClass("alert-success")
                               .removeClass("hidden");

                           $("#loading-preferences").spin(false);
                       }
                   });
        });
    });

    $("#personal-form").submit(function (e) {
        // Prevent default submit
        e.preventDefault();
        e.returnValue = false;

        $("#loading-personal").spin(helium.SMALL_LOADING_OPTS);

        helium.clear_form_errors($(this).attr("id"));

        $.ajax().always(function () {
            const form = $("#personal-form"), data = form.serializeArray();

            $.ajax({
                       async: false,
                       context: form,
                       data: data,
                       contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
                       type: 'PUT',
                       url: helium.API_URL + '/auth/user/profile/',
                       error: function (xhr) {
                           if (xhr.hasOwnProperty("responseJSON")) {
                               $.each(xhr.responseJSON, function (key, value) {
                                   helium.show_error("personal", key, value);
                               });
                           } else {
                               helium.show_error("personal", "", helium.planner_api.GENERIC_ERROR_MESSAGE);
                           }

                           $("#loading-personal").spin(false);
                       },
                       success: function (data) {
                           if (data.phone_changing) {
                               self.phone_pending(data.phone_changing);
                           } else {
                               $("#id_phone").val(data.phone);

                               if (data.phone_verified) {
                                   $($("#id_phone_verification_status")
                                         .html('<i class="icon-ok bigger-110 green"></i> Verified'));
                               } else {
                                   $($("#id_phone_verification_status").html(''));
                               }
                               $("#phone_verification_row").hide("fast");
                           }

                           helium.clear_form_errors("personal-form");

                           $("#status_personal").html("Changes saved.").addClass("alert-success").removeClass("hidden");

                           $("#loading-personal").spin(false);
                       }
                   });
        });
    });

    $("#account-form").submit(function (e) {
        // Prevent default submit
        e.preventDefault();
        e.returnValue = false;

        $("#loading-account").spin(helium.SMALL_LOADING_OPTS);

        helium.clear_form_errors($(this).attr("id"));

        if ($("#id_old_password").val() !== '' || $("#id_password").val() !== '' || $("#id_password2").val() !== '') {
            // If one is present, all three must be present
            let has_error = false;
            if ($("#id_old_password").val() === '') {
                helium.show_error("account", "old_password", "This field is required.");

                has_error = true;
            }
            if ($("#id_password").val() === '') {
                helium.show_error("account", "password", "This field is required.");

                has_error = true;
            }
            if ($("#id_password2").val() === '') {
                helium.show_error("account", "password2", "This field is required.");

                has_error = true;
            }
            if (!has_error && $("#id_password").val() !== $("#id_password2").val()) {
                helium.show_error("account", "password2", "You must enter matching passwords.");

                has_error = true;
            }

            if (has_error) {
                $("#loading-account").spin(false);

                return false;
            }
        }

        $.ajax().always(function () {
            const form = $("#account-form"), data = form.serializeArray();

            for (let i = data.length - 1; i >= 0; --i) {
                if (data[i].name.indexOf('password') !== -1 && data[i].value == '') {
                    data.splice(i);
                }
            }

            $.ajax({
                       async: false,
                       context: form,
                       data: data,
                       contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
                       type: 'PUT',
                       url: helium.API_URL + '/auth/user/',
                       error: function (xhr) {
                           if (xhr.hasOwnProperty("responseJSON")) {
                               $.each(xhr.responseJSON, function (key, value) {
                                   helium.show_error("account", key, value);
                               });
                           } else {
                               helium.show_error("account", "", helium.planner_api.GENERIC_ERROR_MESSAGE);
                           }

                           $("#loading-account").spin(false);
                       },
                       success: function (data) {
                           if (data.email_changing) {
                               self.email_pending(data.email_changing);
                           }

                           helium.clear_form_errors("account-form");

                           $("#id_old_password").val("");
                           $("#id_password").val("");
                           $("#id_password2").val("");

                           $("#status_account").html("Changes saved.").addClass("alert-success").removeClass("hidden");

                           $("#loading-account").spin(false);
                       }
                   });
        });
    });

    this.refresh_feeds = function () {
        if (helium.USER_PREFS.settings.private_slug === null || helium.USER_PREFS.settings.private_slug === "") {
            $("#enable-disable-feed").addClass("btn-success");
            $("#enable-disable-feed").removeClass("btn-warning");
            $("#enable-disable-feed").html('<i class="icon-check"></i>Enable Private Feeds');

            $("#private-feed-urls").html("Private feeds are not yet enabled. Enable using the button below.");
        } else {
            $("#enable-disable-feed").removeClass("btn-success");
            $("#enable-disable-feed").addClass("btn-warning");
            $("#enable-disable-feed").html('<i class="icon-check-minus"></i>Disable Private Feeds');

            const base_url = helium.API_URL + "/feed/private/" + helium.USER_PREFS.settings.private_slug;

            $("#private-feed-urls").html(
                "<strong>Events: </strong><a href=\"" + base_url + "/events.ics\">" + base_url + "/events.ics</a>" +
                "<br /><strong>Homework: </strong><a href=\"" + base_url + "/homework.ics\">" + base_url
                + "/homework.ics</a>" +
                "<br /><strong>Class Schedule: </strong><a href=\"" + base_url + "/courseschedules.ics\">" + base_url
                + "/courseschedules.ics</a>");
        }
    };

    $("#enable-disable-feed").on("click", function () {
        $("#loading-feed").spin(helium.SMALL_LOADING_OPTS);

        if (helium.USER_PREFS.settings.private_slug === null || helium.USER_PREFS.settings.private_slug === "") {
            $.ajax({
                       async: false,
                       type: 'PUT',
                       url: helium.API_URL + '/feed/private/enable/',
                       error: function () {
                           $("#status_feed").html(
                               'Sorry, an unknown error occurred while trying to enable feeds. Please <a href="/contact">contact support</a>')
                               .addClass("alert-warning").removeClass("hidden");

                           $("#loading-feed").spin(false);
                       },
                       success: function (data) {
                           helium.USER_PREFS.settings.private_slug =
                               data.events_private_url.substr(14, data.events_private_url.lastIndexOf('/') - 14);

                           $("#loading-feed").spin(false);
                       }
                   });
        } else {
            $.ajax({
                       async: false,
                       type: 'PUT',
                       url: helium.API_URL + '/feed/private/disable/',
                       error: function () {
                           $("#status_feed").html(
                               'Sorry, an unknown error occurred while trying to enable feeds. Please <a href="/contact">contact support</a>')
                               .addClass("alert-warning").removeClass("hidden");

                           $("#loading-feed").spin(false);
                       },
                       success: function () {
                           helium.USER_PREFS.settings.private_slug = null;

                           $("#loading-feed").spin(false);
                       }
                   });
        }

        self.refresh_feeds();
    });

    $("#delete-account").on("click", function () {
        bootbox.dialog({
                           title: "To permanently delete your Helium account <em>and all data you have stored in Helium</em>, confirm your password below.",
                           message: '<input id="delete-account-password" name="delete-account-password" type="password" class="form-control" />',
                           inputType: "password",
                           closeButton: true,
                           onEscape: true,
                           buttons: {
                               cancel: {
                                   label: "Cancel",
                                   className: "btn-default"
                               },
                               success: {
                                   label: "OK",
                                   className: "btn-primary",
                                   callback: function () {
                                       $("#loading-account").spin(helium.SMALL_LOADING_OPTS);

                                       const data = {
                                           "password": $("input[name='delete-account-password']").val()
                                       };

                                       $.ajax({
                                                  async: false,
                                                  data: JSON.stringify(data),
                                                  type: 'DELETE',
                                                  url: helium.API_URL + '/auth/user/delete/',
                                                  error: function (data) {
                                                      if (data !== undefined && data.hasOwnProperty("responseJSON")
                                                          && data.responseJSON.hasOwnProperty("password")) {
                                                          $("#status_account").html(data.responseJSON.password)
                                                              .addClass("alert-warning").removeClass("hidden");
                                                      } else {
                                                          $("#status_account").html(
                                                              'Sorry, an unknown error occurred while trying to delete your account. Please <a href="/contact">contact support</a>')
                                                              .addClass("alert-warning").removeClass("hidden");
                                                      }

                                                      $("#loading-account").spin(false);
                                                  },
                                                  success: function () {
                                                      $("#loading-account").spin(false);

                                                      localStorage.setItem("status_type", "warning");
                                                      localStorage.setItem("status_msg",
                                                                           "Sorry to see you go! We've deleted all traces of your existence from Helium.");

                                                      window.location = "/logout";
                                                  }
                                              });
                                   }
                               }
                           }
                       });
    });

    $("#export-button").on("click", function (e) {
        e.preventDefault();
        e.returnValue = false;

        $.ajax({
                   url: helium.API_URL + "/importexport/export/",
                   type: "GET",
                   dataType: "json",
                   success: function (data) {
                       const jsonStr = JSON.stringify(data);
                       const base64 = "data:application/json;charset=utf-8;base64," + btoa(jsonStr);

                       $("<a>")
                           .attr({
                                     "href": base64,
                                     "download": "Helium_" + helium.USER_PREFS.username + ".json"
                                 }).html($("<a>").attr("download")).get(0).click();
                   }
               });
    });
}

// Initialize HeliumSettings and give a reference to the Helium object
helium.settings = new HeliumSettings();

$(document).ready(function () {
    "use strict";

    $("#loading-preferences").spin(false);
    $("#loading-personal").spin(false);
    $("#loading-account").spin(false);

    $("#id_phone_carrier").chosen({width: "100%", search_contains: true, no_results_text: "No carriers match"});
    $("#id_time_zone").chosen({width: "100%", search_contains: true, no_results_text: "No time zones match"});
    $("#id_color_select").simplecolorpicker({picker: true, theme: "glyphicons"});

    if ($(".externalcalendars-help").length > 0) {
        $(".externalcalendars-help").popover({html: true}).data("bs.popover").tip().css("z-index", 1060);
        $(".externalcalendars-help").on("click", function () {
            window.open("https://support.google.com/calendar/answer/37648?hl=en");
        });
    }

    helium.settings.populate_externalcalendars();

    $("#id_default_view").val(helium.USER_PREFS.settings.default_view);
    $("#id_week_starts_on").val(helium.USER_PREFS.settings.week_starts_on);
    $("#id_time_zone").val(helium.USER_PREFS.settings.time_zone);
    $("#id_time_zone").trigger("change");
    $("#id_time_zone").trigger("chosen:updated");
    $("#id_color_select").simplecolorpicker("selectColor", helium.USER_PREFS.settings.events_color);
    $("#id_default_reminder_type").val(helium.USER_PREFS.settings.default_reminder_type);
    $("#id_default_reminder_offset").val(helium.USER_PREFS.settings.default_reminder_offset);
    $("#id_default_reminder_offset_type").val(helium.USER_PREFS.settings.default_reminder_offset_type);
    $("#id_phone").val(helium.USER_PREFS.profile.phone);
    $("#id_username").val(helium.USER_PREFS.username);
    $("#id_email").val(helium.USER_PREFS.email);

    if (helium.USER_PREFS.email_changing === null) {
        ($("#id_email_verification_status").html('<i class="icon-ok bigger-110 green"></i> Verified'));
    } else {
        helium.settings.email_pending(helium.USER_PREFS.email_changing);
    }

    if (helium.USER_PREFS.profile.phone_changing !== null && helium.USER_PREFS.profile.phone_changing !== '') {
        helium.settings.phone_pending(helium.USER_PREFS.profile.phone_changing);
    } else if (helium.USER_PREFS.profile.phone_verified) {
        ($("#id_phone_verification_status").html('<i class="icon-ok bigger-110 green"></i> Verified'));
    }

    helium.settings.refresh_feeds();
});
