import os
from typing import Any

import pytest

# ---------------------------------------------------------------------------
# Environment config
# ---------------------------------------------------------------------------

_ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev-local")


def _app_host() -> str:
    if _ENVIRONMENT == "dev-local":
        return "http://localhost:8080"
    if _ENVIRONMENT == "prod":
        return "https://app.heliumedu.com"
    if _ENVIRONMENT == "ci":
        host = os.environ.get("CI_APP_HOST")
        if not host:
            pytest.skip("CI_APP_HOST secret is not defined; skipping ci canary tests")
        return host
    return f"https://app.{_ENVIRONMENT}.heliumedu.com"


def _api_host() -> str:
    if _ENVIRONMENT == "dev-local":
        return "http://localhost:8000"
    if _ENVIRONMENT in ("prod", "ci"):
        return "https://api.heliumedu.com"
    return f"https://api.{_ENVIRONMENT}.heliumedu.com"


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


@pytest.fixture(scope="session")
def api_host() -> str:
    return _api_host()


@pytest.fixture
def context(context, app_host: str):
    """
    Configure browser context for API requests.

    - Grants local-network-access permission (Chrome 141+ blocks FCM service worker without it)
    """
    context.grant_permissions(["local-network-access"])
    return context


@pytest.fixture(scope="session")
def test_credentials() -> dict:
    email = os.environ.get("PLAYWRIGHT_SMOKE_TEST_EMAIL")
    password = os.environ.get("PLAYWRIGHT_SMOKE_TEST_PASSWORD")

    assert email, "PLAYWRIGHT_SMOKE_TEST_EMAIL environment variable is required"
    assert password, "PLAYWRIGHT_SMOKE_TEST_PASSWORD environment variable is required"

    return {"email": email, "password": password}


@pytest.fixture(scope="session")
def firebase_credentials() -> dict:
    project_id = os.environ.get("PLATFORM_FIREBASE_PROJECT_ID")
    client_email = os.environ.get("PLATFORM_FIREBASE_CLIENT_EMAIL")
    private_key = os.environ.get("PLATFORM_FIREBASE_PRIVATE_KEY", "").replace("\\n", "\n")

    assert project_id, "PLATFORM_FIREBASE_PROJECT_ID environment variable is required"
    assert client_email, "PLATFORM_FIREBASE_CLIENT_EMAIL environment variable is required"
    assert private_key, "PLATFORM_FIREBASE_PRIVATE_KEY environment variable is required"

    return {"project_id": project_id, "client_email": client_email, "private_key": private_key}


@pytest.fixture(scope="session")
def apple_sign_in_credentials() -> dict:
    key_p8 = os.environ.get("PLATFORM_APPLE_KEY_P8", "").replace("\\n", "\n")
    key_id = os.environ.get("PLATFORM_APPLE_KEY_ID")
    team_id = os.environ.get("APP_STORE_CONNECT_TEAM_ID")
    client_id = os.environ.get("PLATFORM_APPLE_CLIENT_ID")

    assert key_p8, "PLATFORM_APPLE_KEY_P8 environment variable is required"
    assert key_id, "PLATFORM_APPLE_KEY_ID environment variable is required"
    assert team_id, "APP_STORE_CONNECT_TEAM_ID environment variable is required"
    assert client_id, "PLATFORM_APPLE_CLIENT_ID environment variable is required"

    return {"key_p8": key_p8, "key_id": key_id, "team_id": team_id, "client_id": client_id}
