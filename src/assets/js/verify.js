/**
 * Copyright (c) 2018 Helium Edu
 *
 * Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 * The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 * project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.11.38
 */

(function () {
    "use strict";
    const USERNAME = url('?username');
    const CODE = url('?code');
    const WELCOME_EMAIL = url('?welcome-email');

    const VERIFY_CALLBACK_FUNCTION = function (data) {
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

    let API_VERIFY_URL = window.API_URL + "/auth/user/verify/?username=" + USERNAME + "&code=" + CODE;
    if (WELCOME_EMAIL !== undefined) {
        API_VERIFY_URL += "&welcome-email=" + WELCOME_EMAIL
    }

    $.ajax({
               type: "GET",
               url: API_VERIFY_URL,
               success: function (data) {
                   VERIFY_CALLBACK_FUNCTION(data)
               },
               error: function (jqXHR, textStatus, errorThrown) {
                   document.API_ERROR_FUNCTION(jqXHR, textStatus, errorThrown, VERIFY_CALLBACK_FUNCTION);
               }
           });
})();