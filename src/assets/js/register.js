/**
 * Copyright (c) 2025 Helium Edu
 *
 * Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 * The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 * project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.15.6
 */

if (localStorage.getItem("access_token") !== null) {
    window.location.href = "/planner/calendar";
}

$("#register-form").submit(function (e) {
    e.preventDefault();
    e.returnValue = false;

    const username = $("#id_username").val();
    const email = $("#id_email").val();
    const password1 = $("#id_password1").val();
    const password2 = $("#id_password2").val();
    const time_zone = $("#id_time_zone").val();

    if (password1 !== password2) {
        $("#status").html("You must enter matching passwords.").addClass("alert-warning").removeClass("hidden");

        return false;
    }

    helium.planner_api.register(function (data) {
        if (helium.data_has_err_msg(data)) {
            $("#status").html(helium.get_error_msg(data)).addClass("alert-warning").removeClass("hidden");
        } else {
            localStorage.setItem("status_type", "info");
            localStorage.setItem("status_msg",
                                 "You're almost there! The last step is to verify your email address. Click the link in the email we just sent you and your registration will be complete!");

            window.location.href = "/login";
        }
    }, username, email, password1, time_zone);
});

$(document).ready(function () {
    "use strict";

    $("#id_username").focus();
    if ($(window).width() > 768) {
        $("#id_time_zone").chosen({width: "100%", search_contains: true, no_results_text: "No time zones match"});
    }
    $("#id_time_zone").val(moment.tz.guess());
    $("#id_time_zone").trigger("chosen:updated")
    $("#id_time_zone").trigger("change");
});

