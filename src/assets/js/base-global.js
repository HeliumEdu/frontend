/**
 * Copyright (c) 2025 Helium Edu
 *
 * Dynamic functionality shared among all pages.
 *
 * Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 * The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 * project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.11.54
 */

window.APP_URL = location.protocol + "//" + location.host + "/";
if (window.APP_URL === "http://localhost:3000/" || window.APP_URL === "http://127.0.0.1:3000/") {
    window.API_URL = "http://localhost:8000";
} else if (window.APP_URL === "https://www.heliumedu.com/") {
    // Prod
    window.API_URL = "https://api.heliumedu.com";
} else {
    // Env-prefixed
    window.API_URL = window.APP_URL.replace("www", "api");
}

document.LARGE_LOADING_OPTS = {
    lines: 13,
    length: 10,
    width: 5,
    radius: 15,
    corners: 1,
    rotate: 0,
    direction: 1,
    color: "#000",
    speed: 1,
    trail: 60,
    shadow: false,
    hwaccel: false,
    zIndex: 200,
    top: "200px",
    left: "auto"
};

$.ajax({
           type: "GET",
           url: window.API_URL + "/info/",
           dataType: "json",
           success: function (data) {
               document.GENERIC_ERROR_MESSAGE =
                   "Oops, an unknown error has occurred. If the issue persists, <a href=\"" + data.support_url
                   + "\">open a ticket</a>.";
           },
           error: function () {
               document.GENERIC_ERROR_MESSAGE =
                   "Oops, an unknown error has occurred. Please refresh the page and try again.";
           }
       });

document.API_ERROR_FUNCTION = function (jqXHR, textStatus, errorThrown, callback) {
    let data = [{
        'err_msg': document.GENERIC_ERROR_MESSAGE,
        'jqXHR': jqXHR,
        'textStatus': textStatus,
        'errorThrown': errorThrown
    }];
    if (jqXHR.hasOwnProperty('responseJSON') && Object.keys(jqXHR.responseJSON).length > 0) {
        let name = Object.keys(jqXHR.responseJSON)[0];
        if (jqXHR.responseJSON[name].length > 0) {
            data[0]['err_msg'] = jqXHR.responseJSON[Object.keys(jqXHR.responseJSON)[0]][0];
        }
    }
    callback(data);
}