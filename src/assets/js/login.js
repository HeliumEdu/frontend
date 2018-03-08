var AUTH_TOKEN = Cookies.get("authtoken");

$("#login-form").submit(function(e) {
    e.preventDefault();
    e.returnValue = false;

    var username = $("#id_username").val();
    var password = $("#id_password").val();

    helium.planner_api.login(function (data) {
        if (helium.data_has_err_msg(data)) {
            $("#status").html(helium.get_error_msg(data)).addClass("alert-warning").removeClass("hidden");
        } else {
            window.location.href = "/planner/calendar";
        }
    }, username, password);
});

$(window).on("load", function () {
    "use strict";

    $("#id_username").focus();
}());