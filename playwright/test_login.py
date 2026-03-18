import re

from playwright.sync_api import Page, expect


def _click_flutter_field(page: Page, x: float, y: float, active_input_selector: str) -> None:
    """
    Click a Flutter canvas field and wait for Flutter to finish activating it.

    Flutter's pointer event handling is async — clicking a canvas coordinate and
    immediately typing may race against Flutter focusing the DOM input. We wait for
    Flutter to add the flt-text-editing class to the relevant input, which confirms
    the field is active and ready to receive keyboard input.
    """
    page.mouse.click(x, y)
    page.wait_for_function(
        f"document.querySelector('{active_input_selector}').classList.contains('flt-text-editing')",
        timeout=5_000,
    )


def _type_into_active_flutter_input(page: Page, selector: str, value: str) -> None:
    """
    Type a value into an active Flutter web text input.

    keyboard.type() mishandles special characters (e.g. $, %) when the target is
    Flutter's canvas-backed DOM input. Instead, we set the value directly on the
    DOM element and dispatch an 'input' event so Flutter's TextEditingController
    picks it up correctly regardless of the characters involved.
    """
    page.evaluate(
        """([sel, val]) => {
            const el = document.querySelector(sel);
            const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
            setter.call(el, val);
            el.dispatchEvent(new Event('input', { bubbles: true }));
        }""",
        [selector, value],
    )


def test_login(page: Page, app_host: str, test_credentials: dict) -> None:
    """
    Smoke test: navigate to the app, log in with test credentials, and verify the
    planner screen loads. Validates basic frontend/backend connectivity end-to-end.
    """
    # Headless Chrome omits Origin header on cross-origin requests; add it for CORS
    api_host = app_host.replace("://app.", "://api.")

    def add_origin_header(route, request):
        headers = {**request.headers, "origin": app_host}
        route.continue_(headers=headers)

    page.context.route(f"{api_host}/**", add_origin_header)
    page.goto(app_host)
    page.context.grant_permissions(["notifications"], origin=app_host)

    # Wait for Flutter to initialize and position the email input
    page.wait_for_selector('flt-text-editing-host input[name="email"]', timeout=30_000)
    expect(page).to_have_title(re.compile(r"Login"), timeout=10_000)

    # Read the email field's canvas coordinates from Flutter's IME transform
    email_coords = page.evaluate("""() => {
        const el = document.querySelector('flt-text-editing-host input[name="email"]');
        const m = el.style.transform.match(/matrix\\([^,]+,[^,]+,[^,]+,[^,]+,([^,]+),([^)]+)\\)/);
        return m ? {x: parseFloat(m[1]), y: parseFloat(m[2])} : null;
    }""")
    assert email_coords, "Could not read email field canvas coordinates from Flutter input transform"

    _click_flutter_field(
        page,
        email_coords["x"],
        email_coords["y"],
        'flt-text-editing-host input[name="email"]',
    )
    _type_into_active_flutter_input(page, 'flt-text-editing-host input[name="email"]', test_credentials["email"])

    # Tab to password field
    page.keyboard.press("Tab")
    page.wait_for_function(
        "document.querySelector('flt-text-editing-host input[name=\"current-password\"]').classList.contains('flt-text-editing')",
        timeout=5_000,
    )
    _type_into_active_flutter_input(page, 'flt-text-editing-host input[name="current-password"]', test_credentials["password"])

    # Tab to the Sign In button and press Enter to submit
    page.keyboard.press("Tab")
    page.keyboard.press("Tab")
    page.keyboard.press("Tab")
    page.keyboard.press("Enter")

    # Verify the app navigates to the planner screen
    page.wait_for_url(re.compile(r"/planner"), timeout=30_000)
    expect(page).to_have_title(re.compile(r"Planner"), timeout=10_000)
