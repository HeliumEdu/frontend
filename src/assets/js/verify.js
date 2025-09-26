/**
 * Copyright (c) 2018 Helium Edu
 *
 * FIXME: Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 *  The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 *  project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.11.8
 */

helium.clear_access_token();

var username = url('?username');
var code = url('?code');
var welcome_email = url('?welcome-email');

var callback = function (data) {
    if (data !== undefined && data.length === 1) {
        if (data[0].jqXHR.status === 404) {
            window.location.replace("/register");
        } else {
            localStorage.setItem("status_type", "warning");
            localStorage.setItem("status_msg", data[0].err_msg);

            window.location.replace("/login");
        }
    } else {
        localStorage.setItem("status_type", "info");
        localStorage.setItem("status_msg", "Your email address has been verified. You can now login to Helium!");

        window.location.replace("/login");
    }
};

var API_VERIFY_URL = helium.API_URL + "/auth/user/verify/?username=" + username + "&code=" + code
if (welcome_email !== undefined) {
    API_VERIFY_URL += "&welcome-email=" + welcome_email
}

$.ajax({
           type: "GET",
           url: API_VERIFY_URL,
           async: false,
           success: function (data) {
               callback(data)
           },
           error: function (jqXHR, textStatus, errorThrown) {
               helium.planner_api.api_error(jqXHR, textStatus, errorThrown, callback);
           }
       });