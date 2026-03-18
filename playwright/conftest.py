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


@pytest.fixture(scope="session")
def test_credentials() -> dict:
    email = os.environ.get("PLAYWRIGHT_SMOKE_TEST_EMAIL")
    password = os.environ.get("PLAYWRIGHT_SMOKE_TEST_PASSWORD")

    assert email, "PLAYWRIGHT_SMOKE_TEST_EMAIL environment variable is required"
    assert password, "PLAYWRIGHT_SMOKE_TEST_PASSWORD environment variable is required"

    return {"email": email, "password": password}
