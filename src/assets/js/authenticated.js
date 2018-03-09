/**
 * Copyright (c) 2018 Helium Edu.
 *
 * FIXME: This implementation is pretty crude compared to modern standards and will be completely overhauled in favor of a framework once the open source migration is completed.
 *
 * @author Alex Laird
 * @version 1.4.0
 */

window.PRIVILEGED_ROUTE = true;

var AUTH_TOKEN = Cookies.get("authtoken");

if (AUTH_TOKEN === undefined) {
    window.location.href = "/login?next=" + window.location.pathname;
}
