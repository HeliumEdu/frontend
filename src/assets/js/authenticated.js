/**
 * Copyright (c) 2025 Helium Edu
 *
 * Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 * The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 * project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.11.54
 */

window.PRIVILEGED_ROUTE = true;

if (localStorage.getItem("access_token") === null) {
    localStorage.removeItem("refresh_token");
    localStorage.removeItem("access_token_exp");

    window.location.href = "/login?next=" + window.location.pathname;
}
