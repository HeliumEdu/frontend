import os
import pytest
from typing import Any

# ---------------------------------------------------------------------------
# Environment config
# ---------------------------------------------------------------------------

_ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev-local")


def _app_host() -> str:
    if _ENVIRONMENT == "dev-local":
        return "http://localhost:8080"
    if _ENVIRONMENT == "prod":
        return "https://app.heliumedu.com"
    return f"https://app.{_ENVIRONMENT}.heliumedu.com"


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(scope="session")
def browser_type_launch_args(browser_type_launch_args: dict[str, Any]) -> dict[str, Any]:
    headless = os.environ.get("HEADLESS", "true").lower() != "false"
    return {**browser_type_launch_args, "headless": headless}


@pytest.fixture(scope="session")
def app_host() -> str:
    return _app_host()


@pytest.fixture(autouse=True)
def setup_api_interceptor(context, app_host: str) -> None:
    """
    Set up Origin header injection for API requests.

    Headless Chrome omits the Origin header on cross-origin requests, which breaks
    CORS validation. This interceptor adds the Origin header to all API requests.
    """
    api_host = app_host.replace("://app.", "://api.")

    def add_origin_header(route, request):
        headers = {**request.headers, "origin": app_host}
        route.continue_(headers=headers)

    context.route(f"{api_host}/**", add_origin_header)
    context.grant_permissions(["notifications"], origin=app_host)


@pytest.fixture(scope="session")
def test_credentials() -> dict:
    email = os.environ.get("PLAYWRIGHT_SMOKE_TEST_EMAIL")
    password = os.environ.get("PLAYWRIGHT_SMOKE_TEST_PASSWORD")

    assert email, "PLAYWRIGHT_SMOKE_TEST_EMAIL environment variable is required"
    assert password, "PLAYWRIGHT_SMOKE_TEST_PASSWORD environment variable is required"

    return {"email": email, "password": password}
