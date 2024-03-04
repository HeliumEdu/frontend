/**
 * Copyright (c) 2018, Helium Edu
 *
 * FIXME: This implementation is pretty crude compared to modern standards and will be completely overhauled in favor of a framework once the open source migration is completed.
 *
 * @license MIT
 * @version 1.5.1
 */

window.PRIVILEGED_ROUTE = true;

var AUTH_TOKEN = Cookies.get("authtoken");

if (AUTH_TOKEN === undefined) {
    window.location.href = "/login?next=" + window.location.pathname;
}
