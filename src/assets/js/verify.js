/**
 * Copyright (c) 2018 Helium Edu.
 *
 * FIXME: This implementation is pretty crude compared to modern standards and will be completely overhauled in favor of a framework once the open source migration is completed.
 *
 * @author Alex Laird
 * @version 1.4.0
 */

var username = url('?username');
var code = url('?code');

var SITE_HOST = location.host + "/";
var SITE_URL = location.protocol + "//" + SITE_HOST;

var API_URL = "https://api.heliumedu.com";
if (SITE_URL === "http://localhost:3000/" || SITE_URL === "http://127.0.0.1:3000/") {
    API_URL = "http://localhost:8000";
} else if (SITE_URL === "https://www.heliumedu.dev/") {
    API_URL = "https://api.heliumedu.dev";
}

callback = function (data) {
    if (data !== undefined && data.length === 1) {
        if (data[0].jqXHR.status === 404) {
            window.location.replace("/register");
        } else {
            Cookies.set("status_type", "warning", {path: "/"});
            Cookies.set("status_msg", data[0].err_msg, {path: "/"});

            window.location.replace("/login");
        }
    } else {
        Cookies.set("status_type", "info", {path: "/"});
        Cookies.set("status_msg", "Your email address has been verified. You can now login to Helium using this email or your username.", {path: "/"});

        window.location.replace("/login");
    }
};

$.ajax({
    type: "GET",
    url: API_URL + "/auth/user/verify/?username=" + username + "&code=" + code,
    success: function (data) {
        callback(data)
    },
    error: function (jqXHR, textStatus, errorThrown) {
        var data = [{
            'err_msg': "Oops, an unknown error has occurred. If the issue persists, <a href=\"/support\">contact support</a>.",
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