import re

from playwright.sync_api import Page, expect


def test_login(page: Page, app_host: str, test_credentials: dict) -> None:
    """
    Smoke test: navigate to the app, log in with test credentials, and verify the
    planner screen loads. Validates basic frontend/backend connectivity end-to-end.
    """
    page.goto(app_host)

    # Wait for Flutter to initialize and position the email input
    page.wait_for_selector('flt-text-editing-host input[name="email"]', timeout=30_000)
    expect(page).to_have_title(re.compile(r"Login"), timeout=10_000)

    # Flutter (CanvasKit) renders the UI on a canvas with no interactive DOM elements.
    # The email input's CSS transform stores the canvas coordinates of the active text
    # field (used by the OS for IME positioning). Clicking at those coordinates sends a
    # pointer event to flutter-view, which Flutter routes to the email TextField, focuses
    # it, and activates it for keyboard input. Tab then moves Flutter's internal focus
    # to the password field, where the same keyboard routing applies.
    coords = page.evaluate("""() => {
        const el = document.querySelector('flt-text-editing-host input[name="email"]');
        const m = el.style.transform.match(/matrix\\([^,]+,[^,]+,[^,]+,[^,]+,([^,]+),([^)]+)\\)/);
        return m ? {x: parseFloat(m[1]), y: parseFloat(m[2])} : null;
    }""")
    assert coords, "Could not read email field canvas coordinates from Flutter input transform"

    page.mouse.click(coords["x"], coords["y"])
    page.keyboard.type(test_credentials["email"])

    page.keyboard.press("Tab")
    page.keyboard.type(test_credentials["password"])

    # Enter in the password field triggers onFieldSubmitted -> login
    page.keyboard.press("Enter")

    # Verify the app navigates to the planner screen
    page.wait_for_url(re.compile(r"/planner"), timeout=30_000)
    expect(page).to_have_title(re.compile(r"Planner"), timeout=10_000)
