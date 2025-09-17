/**
 * Copyright (c) 2018 Helium Edu
 *
 * FIXME: This implementation is pretty crude compared to modern standards and will be completely overhauled in favor of a framework once the open source migration is completed.
 *
 * @license MIT
 * @version 1.5.1
 */

var AUTH_TOKEN = localStorage.getItem("authtoken");

if (AUTH_TOKEN !== null) {
    window.location.href = "/planner/calendar";
}

$("#login-form").submit(function (e) {
    e.preventDefault();
    e.returnValue = false;

    var username = $("#id_username").val();
    var password = $("#id_password").val();

    helium.planner_api.login(function (data) {
        if (helium.data_has_err_msg(data)) {
            $("#status").html(helium.get_error_msg(data)).addClass("alert-warning").removeClass("hidden");
        } else {
            var next = url('?next');

            if (next !== undefined) {
                window.location.href = next;
            } else {
                window.location.href = "/planner/calendar";
            }
        }
    }, username, password);
});

$(window).on("load", function () {
    "use strict";

    var status_type = localStorage.getItem("status_type");
    var status_msg = localStorage.getItem("status_msg");

    if (status_type !== null && status_msg !== null) {
        $("#status").html(status_msg).addClass("alert-" + status_type).removeClass("hidden");

        localStorage.removeItem("status_type");
        localStorage.removeItem("status_msg");
    }

    $("#id_username").focus();
}());
