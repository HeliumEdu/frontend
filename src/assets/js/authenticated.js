var AUTH_TOKEN = Cookies.get("authtoken");

if (AUTH_TOKEN === undefined) {
    window.location.href = "/login?next=" + window.location.pathname;
}
