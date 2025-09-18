/**
 * Copyright (c) 2018 Helium Edu
 *
 * FIXME: Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 *  The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 *  project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.7.14
 */

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

$.ajax({
    type: "GET",
    url: API_URL + "/info/",
    dataType: "json",
    success: function (data) {
        window.location.replace(data.support_url);
    }
});
