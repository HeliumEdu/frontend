/**
 * Copyright (c) 2018 Helium Edu
 *
 * FIXME: This implementation is pretty crude compared to modern standards and will be completely overhauled in favor of a framework once the open source migration is completed.
 *
 * @license MIT
 * @version 1.5.1
 */

var AUTH_TOKEN = localStorage.getItem("access_token");

if (AUTH_TOKEN !== null) {
    window.location.href = "/planner/calendar";
}

$("#register-form").submit(function (e) {
    e.preventDefault();
    e.returnValue = false;

    var username = $("#id_username").val();
    var email = $("#id_email").val();
    var password1 = $("#id_password1").val();
    var password2 = $("#id_password2").val();
    var time_zone = $("#id_time_zone").val();

    if (password1 !== password2) {
        $("#status").html("You must enter matching passwords.").addClass("alert-warning").removeClass("hidden");

        return false;
    }

    helium.planner_api.register(function (data) {
        if (helium.data_has_err_msg(data)) {
            $("#status").html(helium.get_error_msg(data)).addClass("alert-warning").removeClass("hidden");
        } else {
            localStorage.setItem("status_type", "info");
            localStorage.setItem("status_msg", "You're almost there! The last step is to verify your email address. Click the link in the email we just sent you and your registration will be complete!");

            window.location.href = "/login";
        }
    }, username, email, password1, time_zone);
});

$(window).on("load", function () {
    "use strict";

    $("#email").focus();
    $("#id_time_zone").chosen({width: "100%", search_contains: true, no_results_text: "No time zones match"});
    $("#id_time_zone").val(moment.tz.guess());
    $("#id_time_zone").trigger("change");
    $("#id_time_zone").trigger("chosen:updated")
}());
