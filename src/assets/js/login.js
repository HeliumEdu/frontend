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

$("#login-form").submit(function (e) {
    e.preventDefault();
    e.returnValue = false;

    const username = $("#id_username").val();
    const password = $("#id_password").val();

    helium.planner_api.login(function (data) {
        if (helium.data_has_err_msg(data)) {
            $("#status").html(helium.get_error_msg(data)).addClass("alert-warning").removeClass("hidden");
        } else {
            helium.clear_storage();

            const next = url('?next');

            if (next !== undefined) {
                window.location.href = next;
            } else {
                window.location.href = "/planner/calendar";
            }
        }
    }, username, password);
});

$(document).ready(function () {
    "use strict";

    const status_type = localStorage.getItem("status_type");
    const status_msg = localStorage.getItem("status_msg");

    if (status_type !== null && status_msg !== null) {
        $("#status").html(status_msg).addClass("alert-" + status_type).removeClass("hidden");

        localStorage.removeItem("status_type");
        localStorage.removeItem("status_msg");
    }

    $("#id_username").focus();
});
