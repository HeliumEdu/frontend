import os

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
def app_host() -> str:
    return _app_host()


@pytest.fixture(scope="session")
def test_credentials() -> dict:
    """
    Credentials for a pre-existing smoke test user. Provide via environment variables:
      SMOKE_TEST_EMAIL     – email address of the test user
      SMOKE_TEST_PASSWORD  – password of the test user
    """
    email = os.environ.get("SMOKE_TEST_EMAIL")
    password = os.environ.get("SMOKE_TEST_PASSWORD")

    assert email, "SMOKE_TEST_EMAIL environment variable is required"
    assert password, "SMOKE_TEST_PASSWORD environment variable is required"

    return {"email": email, "password": password}
