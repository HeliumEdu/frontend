/**
 * Copyright (c) 2018 Helium Edu
 *
 * FIXME: This implementation is pretty crude compared to modern standards and will be completely overhauled in favor of a framework once the open source migration is completed.
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
