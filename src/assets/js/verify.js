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

localStorage.removeItem("access_token");

var username = url('?username');
var code = url('?code');
var welcome_email = url('?welcome-email');

var SITE_HOST = location.host + "/";
var SITE_URL = location.protocol + "//" + SITE_HOST;
if (SITE_URL === "http://localhost:3000/" || SITE_URL === "http://127.0.0.1:3000/") {
    API_URL = "http://localhost:8000";
} else if (SITE_URL === "https://www.heliumedu.com/") {
    // Prod
    API_URL = "https://api.heliumedu.com";
} else {
    // Env-prefixed
    API_URL = SITE_URL.replace("www", "api");
}

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

API_VERIFY_URL = API_URL + "/auth/user/verify/?username=" + username + "&code=" + code
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
        var data = [{
            'err_msg': "Oops, an unknown error has occurred. If the issue persists, <a href=\"https://github.com/HeliumEdu/platform/issues/new/choose\">open a ticket</a>.",
            'jqXHR': jqXHR,
            'textStatus': textStatus,
            'errorThrown': errorThrown
        }];
        if (jqXHR.hasOwnProperty('responseJSON') && Object.keys(jqXHR.responseJSON).length > 0) {
            var name = Object.keys(jqXHR.responseJSON)[0];
            if (jqXHR.responseJSON[name].length > 0) {
                data[0]['err_msg'] = jqXHR.responseJSON[Object.keys(jqXHR.responseJSON)[0]][0];
            }
        }

        callback(data);
    }
});