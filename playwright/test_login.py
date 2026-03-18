import re

from playwright.sync_api import Page, expect


def test_login(page: Page, app_host: str, test_credentials: dict) -> None:
    """
    Smoke test: navigate to the app, log in with test credentials, and verify the
    planner screen loads. Validates basic frontend/backend connectivity end-to-end.
    """
    page.goto(app_host)

    # Wait for the login screen to be ready (Sign In button appears in the semantic tree)
    page.get_by_role("button", name="Sign In").wait_for(state="visible", timeout=30_000)
    expect(page).to_have_title(re.compile(r"Login"), timeout=10_000)

    # Flutter web processes real keyboard events, not JS-injected values.
    # The email field has autofocus on web, so we can type directly into it.
    page.keyboard.type(test_credentials["email"])
    page.keyboard.press("Tab")
    page.keyboard.type(test_credentials["password"])

    # Pressing Enter in the password field triggers onFieldSubmitted -> login
    page.keyboard.press("Enter")

    # Verify the app navigates to the planner screen
    page.wait_for_url(re.compile(r"/planner"), timeout=30_000)
    expect(page).to_have_title(re.compile(r"Planner"), timeout=10_000)

    # Dismiss first-login dialogs if present (Getting Started / What's New)
    for btn_name in ("I'll explore first", "Dive In!"):
        btn = page.get_by_role("button", name=btn_name)
        if btn.count() > 0 and btn.is_visible():
            btn.click()
            page.wait_for_timeout(500)
