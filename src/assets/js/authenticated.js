/**
 * Copyright (c) 2018 Helium Edu
 *
 * FIXME: This implementation is pretty crude compared to modern standards and will be completely overhauled in favor of a framework once the open source migration is completed.
 *
 * @license MIT
 * @version 1.10.35
 */

window.PRIVILEGED_ROUTE = true;

var AUTH_TOKEN = localStorage.getItem("authtoken");

if (AUTH_TOKEN === null) {
    window.location.href = "/login?next=" + window.location.pathname;
}
