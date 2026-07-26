from playwright.sync_api import Page
from playwright.sync_api import TimeoutError as PlaywrightTimeoutError

# Visible button text for the app's startup dialogs (Getting Started, What's New),
# in the order the app itself shows them when both are pending (see
# NavigationShell._checkDialogs in lib/presentation/navigation/shell/navigation_shell.dart).
_STARTUP_DIALOG_BUTTONS = ("I'll explore first", "Dive In!")


def enable_flutter_semantics(page: Page) -> None:
    """
    Turn on Flutter web's accessibility semantics tree.

    Flutter web renders everything to a canvas by default, so widget text and
    buttons aren't real DOM nodes and can't be located by Playwright. The
    engine gates the accessible DOM mirror behind an invisible placeholder
    button (aria-label "Enable accessibility") to avoid the performance cost
    for users who don't need it; on desktop the engine positions this
    placeholder off-screen (1x1px), so it's clicked via JS rather than
    Playwright's mouse click. Once clicked, Flutter mirrors every visible
    widget into an accessible DOM tree, which is what lets dialog buttons be
    located by their visible text.
    """
    page.evaluate("document.querySelector('flt-semantics-placeholder')?.click()")


def dismiss_dialog_if_present(page: Page, button_name: str, timeout: float = 3_000) -> None:
    """
    Dismiss a dialog if it's showing, by clicking its named button the way a
    real user would.

    Absence is the common case, so the lookup is bounded to a short timeout
    rather than blocking indefinitely.
    """
    try:
        page.get_by_role("button", name=button_name, exact=True).click(timeout=timeout)
    except PlaywrightTimeoutError:
        pass


def dismiss_startup_dialogs(page: Page) -> None:
    """
    Dismiss the app's startup dialogs (Getting Started, What's New) if either
    is showing.

    Either dialog can appear over the Planner screen right after login, and
    NavigationShell defers the browser title update while one is the topmost
    route. Call this after login before asserting on anything that depends
    on the shell being the current route (e.g. the browser title).
    """
    enable_flutter_semantics(page)
    for button_name in _STARTUP_DIALOG_BUTTONS:
        dismiss_dialog_if_present(page, button_name)
