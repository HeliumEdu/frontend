/**
 * Copyright (c) 2018 Helium Edu.
 *
 * FIXME: This implementation is pretty crude compared to modern standards and will be completely overhauled in favor of a framework once the open source migration is completed.
 *
 * @author Alex Laird
 * @version 1.4.0
 */

var SITE_HOST = location.host + "/";
var SITE_URL = location.protocol + "//" + SITE_HOST;
if (SITE_URL === "http://localhost:3000/" || SITE_URL === "http://127.0.0.1:3000/") {
    API_URL = "http://localhost:8000";
} else if (SITE_URL === "https://www.heliumedu.test/") {
    API_URL = "https://api.heliumedu.test";
} else {
    API_URL = "https://api.heliumedu.com";
}

$.ajax({
    type: "GET",
    url: API_URL + "/common/info/",
    dataType: "json",
    success: function (data) {
        window.location.replace(data.support_url);
    }
});
