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

$.ajax({
           type: "GET",
           url: window.API_URL + "/info/",
           async: false,
           dataType: "json",
           success: function (data) {
               window.location.replace(data.support_url);
           }
       });
