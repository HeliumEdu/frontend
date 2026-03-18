import os
from typing import TYPE_CHECKING, Any

import pytest

if TYPE_CHECKING:
    from playwright.sync_api import Page

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
    headless = os.environ.get("INTEGRATION_HEADLESS", "true").lower() != "false"
    return {**browser_type_launch_args, "headless": headless}


def enable_flutter_semantics(page: "Page") -> None:
    """
    Enable Flutter web's accessibility/semantics tree.

    Flutter web (CanvasKit) renders into a canvas with an empty flt-semantics-host
    by default. A hidden flt-semantics-placeholder button lives in the shadow DOM
    of flt-glass-pane; clicking it populates flt-semantics-host with the full
    accessibility tree, enabling role- and label-based element targeting.
    """
    page.wait_for_selector("flt-glass-pane", timeout=30_000)
    page.evaluate(
        "document.querySelector('flt-glass-pane')"
        ".shadowRoot"
        ".querySelector('flt-semantics-placeholder')"
        ".click()"
    )
    page.wait_for_selector("flt-semantics", timeout=10_000)


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
