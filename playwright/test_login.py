import re

from playwright.sync_api import Page, expect


def _fill_flutter_field(page: Page, field_index: int, value: str) -> None:
    """
    Fill a Flutter web text field by index.

    Flutter web renders form fields as flt-semantics[role='textbox'] elements in the
    accessibility/semantic layer. Clicking one focuses it, after which Flutter inserts
    a real <input> into flt-text-editing-host that Playwright can fill normally.
    """
    page.locator("flt-semantics[role='textbox']").nth(field_index).click()
    page.locator(
        "flt-text-editing-host input, flt-text-editing-host textarea"
    ).first.fill(value)


def test_login(page: Page, app_host: str, test_credentials: dict) -> None:
    """
    Smoke test: navigate to the app, log in with test credentials, and verify the
    planner screen loads. Validates basic frontend/backend connectivity end-to-end.
    """
    page.goto(app_host)

    # Wait for the login screen to be ready (Sign In button appears in the semantic tree)
    page.get_by_role("button", name="Sign In").wait_for(state="visible", timeout=30_000)
    expect(page).to_have_title(re.compile(r"Login"), timeout=10_000)

    _fill_flutter_field(page, 0, test_credentials["email"])
    _fill_flutter_field(page, 1, test_credentials["password"])

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
