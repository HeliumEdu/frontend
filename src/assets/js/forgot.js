$("#forgot-form").submit(function(e) {
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