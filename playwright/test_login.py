import re

from playwright.sync_api import Page, expect

from conftest import enable_flutter_semantics


def test_login(page: Page, app_host: str, test_credentials: dict) -> None:
    """
    Smoke test: navigate to the app, log in with test credentials, and verify the
    planner screen loads. Validates basic frontend/backend connectivity end-to-end.
    """
    page.goto(app_host)

    # Flutter web (CanvasKit) renders into a canvas; the semantics/accessibility
    # tree is empty by default. Enabling it populates flt-semantics-host, which
    # makes role- and label-based locators work and routes keyboard events correctly.
    enable_flutter_semantics(page)

    expect(page).to_have_title(re.compile(r"Login"), timeout=10_000)

    # Click the semantic textbox to give Flutter focus, then type via keyboard.
    # fill() and JS value-setting are ignored by Flutter's input engine.
    page.get_by_role("textbox", name="Email").click()
    page.keyboard.type(test_credentials["email"])

    page.get_by_role("textbox", name="Password").click()
    page.keyboard.type(test_credentials["password"])

    page.get_by_role("button", name="Sign In").click()

    # Verify the app navigates to the planner screen
    page.wait_for_url(re.compile(r"/planner"), timeout=30_000)
    expect(page).to_have_title(re.compile(r"Planner"), timeout=10_000)

    # Dismiss first-login dialogs if present (Getting Started / What's New)
    for btn_name in ("I'll explore first", "Dive In!"):
        btn = page.get_by_role("button", name=btn_name)
        if btn.count() > 0 and btn.is_visible():
            btn.click()
            page.wait_for_timeout(500)
