/**
 * Copyright (c) 2018 Helium Edu
 *
 * FIXME: Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 *  The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 *  project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.10.35
 */

var AUTH_TOKEN = localStorage.getItem("access_token");

if (AUTH_TOKEN !== null) {
    window.location.href = "/settings";
}

$("#forgot-form").submit(function (e) {
    e.preventDefault();
    e.returnValue = false;

    var email = $("#id_email").val();

    helium.planner_api.forgot(function (data) {
        if (helium.data_has_err_msg(data)) {
            $("#status").html(helium.get_error_msg(data)).addClass("alert-warning").removeClass("hidden");
        } else {
            $("#status").html("You've been emailed a temporary password. Login to your account immediately using the temporary password, then change your password").addClass("alert-info").removeClass("hidden");
        }
    }, email);
});

$(window).on("load", function () {
    "use strict";

    $("#id_email").focus();
}());