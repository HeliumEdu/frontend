/**
 * Copyright (c) 2018, Helium Edu
 *
 * FIXME: This implementation is pretty crude compared to modern standards and will be completely overhauled in favor of a framework once the open source migration is completed.
 *
 * @license MIT
 * @version 1.5.1
 */

var AUTH_TOKEN = Cookies.get("authtoken", {path: "/"});

if (AUTH_TOKEN !== undefined) {
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