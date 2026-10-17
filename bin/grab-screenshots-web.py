#!/usr/bin/env python3
"""
Captures Helium web marketing and press screenshots in a Playwright-driven
Chrome window and writes each PNG straight into the www project:

  www/src/assets/img/screenshots/                (feature shots, 1880x1000)
  www/src/assets/img/screenshots/grade-calculator-square.png   (1000x1160)
  www/public/press/screenshots/web/helium-web-full-*.png       (2880x1680)
  www/src/assets/img/screenshots/frames/frame-laptop.png       (framed month view)
  www/src/assets/img/og-default.png                            (OG card, 1200x630)

The press page's other web shots are symlinks to the feature shots, and the
Flutter onboarding copies are synced at the end, so neither needs capturing.

For each shot the script lands on the right page at the right viewport and
zoom and dismisses the Getting Started / What's New dialogs; you do the rest
in the app (switch views, open a dialog, scroll), then confirm.

The browser keeps its own profile (~/.helium-screenshots/chrome), so sign in
once and later runs stay signed in.

  APP_URL=http://localhost:8080 .venv/bin/python bin/grab-screenshots-web.py

Requires Google Chrome, Playwright and Pillow (make screenshots sets up .venv).
"""

import base64
import io
import os
import subprocess
import sys
import time
from pathlib import Path

from PIL import Image
from playwright.sync_api import sync_playwright

REPO = Path(__file__).resolve().parent.parent
WWW = REPO.parent / "www"
FEATURE_DEST = WWW / "src/assets/img/screenshots"
PRESS_DEST = WWW / "public/press/screenshots/web"
LAPTOP_DEST = WWW / "src/assets/img/screenshots/frames/frame-laptop.png"
LAPTOP_TEMPLATE = REPO / "bin/frame-laptop.png"
APP_URL = os.environ.get("APP_URL", "https://app.heliumedu.com")
PROFILE = Path.home() / ".helium-screenshots/chrome"
PAGE_SETTLE_SECONDS = 5

# Feature shots: 1144x760 at 1.8x (90% zoom on a 2x display), cropped to 1880x1000.
FEATURE_SIZE = (1144, 760)
FEATURE_SCALE = 1.8
FEATURE_CROP = (1880, 1000)

# The calculator square is the same dialog at 2x, center-cropped with a margin of dimmed background.
SQUARE_SCALE = 2
SQUARE_CROP = (1000, 1160)

# Press shots and the laptop frame: 1440x840 at 2x (2880x1680), uncropped.
PRESS_SIZE = (1440, 840)
PRESS_SCALE = 2
LAPTOP_VIEWPORT_ORIGIN = (51, 209)

# (slug, route, viewport width, crop x, crop y), crop origin in device px.
FEATURE_SHOTS = [
    ("month-view", "/planner", 1144, 176, 106),
    ("week-view", "/planner", 1144, 176, 217),
    ("todos", "/planner", 1144, 176, 106),
    ("edit-assignment", "/planner", 1144, 52, 325),
    ("reminders", "/planner/notifications", 1144, 167, 23),
    ("external-calendars", "/planner", 1144, 44, 19),
    ("grades-dashboard", "/grades", 1144, 176, 231),
    ("grades-breakdown", "/grades", 1144, 176, 24),
    ("grade-calculator", "/grades", 1144, 88, 181),
    ("class-manager", "/classes", 1144, 176, 24),
    ("notebook", "/notebook", 1144, 176, 24),
    ("edit-note", "/notebook", 1064, 10, 51),
    ("resources", "/resources", 1144, 176, 24),
]

# One-time setup to show before a shot's prompt.
SETUP_NOTES = {
    "todos": "Open the filter menu with two items selected.",
    "external-calendars": 'With Agenda view showing behind it, add a dark green named "Molecular Biology '
                          'Seminars" with URL https://mcb.berkeley.edu/seminars/mcb_seminars.ics — delete when done.',
}

# Shots whose www filename differs from the name shown in the prompt.
OUTPUT_NAMES = {"edit-assignment": "assignment-planner"}

# Shots taken before signing in, in the FEATURE_SHOTS shape.
LOGGED_OUT_SHOTS = []

# (slug, route)
PRESS_SHOTS = [
    ("month-view", "/planner"),
    ("grades-dashboard", "/grades"),
    ("edit-note", "/notebook"),
]

BANNER = "════════════════════════════════════════════════════════════"


class QuitRequested(Exception):
    pass


def ask(prompt):
    reply = input(prompt).strip().lower()
    if reply == "q":
        raise QuitRequested
    return reply


class Browser:
    def __init__(self, page, cdp):
        self.page = page
        self.cdp = cdp
        self.signed_in = True

    def fit_window(self, size):
        """Sizes the real window so its page area matches the emulated viewport."""
        width, height = size
        self.cdp.send("Emulation.clearDeviceMetricsOverride")
        window_id = self.cdp.send("Browser.getWindowForTarget")["windowId"]
        self.cdp.send("Browser.setWindowBounds", {"windowId": window_id, "bounds": {"windowState": "normal"}})
        chrome_width, chrome_height = self.page.evaluate(
            "[outerWidth - innerWidth, outerHeight - innerHeight]"
        )
        self.cdp.send("Browser.setWindowBounds", {
            "windowId": window_id,
            "bounds": {"width": width + chrome_width, "height": height + chrome_height},
        })

    def emulate(self, size, scale):
        width, height = size
        self.cdp.send("Emulation.setDeviceMetricsOverride", {
            "width": width,
            "height": height,
            "deviceScaleFactor": scale,
            "mobile": False,
        })

    def open(self, route, size, scale):
        self.fit_window(size)
        self.emulate(size, scale)
        self.page.goto(f"{APP_URL}{route}")
        time.sleep(PAGE_SETTLE_SECONDS)
        while self.signed_in and is_signed_out(self.page):
            print(f"\n{BANNER}\n  Sign in\n{BANNER}")
            ask("The browser is open. Sign in to Helium in that window, then press Enter to continue: ")
            self.page.goto(f"{APP_URL}{route}")
            time.sleep(PAGE_SETTLE_SECONDS)
        # Getting Started, then What's New if it follows; Escape is a no-op otherwise.
        for _ in range(2):
            self.page.keyboard.press("Escape")
            time.sleep(1)

    def capture(self):
        # Through the same DevTools session, so the emulated scale applies.
        data = self.cdp.send("Page.captureScreenshot", {"format": "png"})["data"]
        return Image.open(io.BytesIO(base64.b64decode(data)))


def confirm_capture(slug):
    print()
    if slug in SETUP_NOTES:
        print(f"    {SETUP_NOTES[slug]}")
    reply = ask(f"  → Navigate to '{slug}'. Press Enter to capture, 's' to skip, 'q' to quit: ")
    if reply == "s":
        print("  ↷ skipped")
        return False
    return True


def save(image, out):
    image.save(out, optimize=True)
    print(f"  ✓ {out}")


def crop(image, x, y, size):
    width, height = size
    return image.crop((x, y, x + width, y + height))


def center_crop(image, size):
    width, height = size
    return crop(image, (image.width - width) // 2, (image.height - height) // 2, size)


def capture_feature(browser, slug, route, width, crop_x, crop_y):
    size = (width, FEATURE_SIZE[1])
    browser.open(route, size, FEATURE_SCALE)
    if not confirm_capture(slug):
        return
    save(crop(browser.capture(), crop_x, crop_y, FEATURE_CROP), FEATURE_DEST / f"{OUTPUT_NAMES.get(slug, slug)}.png")
    if slug == "grade-calculator":
        browser.emulate(size, SQUARE_SCALE)
        time.sleep(1.5)
        save(center_crop(browser.capture(), SQUARE_CROP), FEATURE_DEST / "grade-calculator-square.png")
        browser.emulate(size, FEATURE_SCALE)


def frame_laptop(capture):
    template = Image.open(LAPTOP_TEMPLATE).convert("RGBA")
    x, y = LAPTOP_VIEWPORT_ORIGIN
    mask = template.crop((x, y, x + capture.width, y + capture.height)).getchannel("A")
    template.paste(capture.convert("RGBA"), (x, y), mask)
    save(template, LAPTOP_DEST)


def capture_press(browser, slug, route):
    browser.open(route, PRESS_SIZE, PRESS_SCALE)
    if not confirm_capture(slug):
        return
    capture = browser.capture()
    save(capture, PRESS_DEST / f"helium-web-full-{slug}.png")
    if slug == "month-view":
        frame_laptop(capture)


class Session:
    """Launches the browser on first use, so declining every device never opens it."""

    def __init__(self, playwright):
        self.playwright = playwright
        self.context = None
        self.browser = None

    def open_browser(self):
        if self.browser is None:
            self.context = self.playwright.chromium.launch_persistent_context(
                str(PROFILE),
                channel="chrome",
                headless=False,
                no_viewport=True,
                color_scheme="light",
            )
            page = self.context.pages[0] if self.context.pages else self.context.new_page()
            self.browser = Browser(page, self.context.new_cdp_session(page))
        return self.browser

    def close(self):
        if self.context is not None:
            self.context.close()


def run_device(session, label, dest, capture, shots, signed_in=True):
    print(f"\n{BANNER}\n  {label}  ({len(shots)} screenshots → {dest})\n{BANNER}")
    if ask(f"Press Enter to open the browser for {label} ('s' to skip this device): ") == "s":
        print(f"Skipping {label}.")
        return
    browser = session.open_browser()
    browser.signed_in = signed_in
    for shot in shots:
        capture(browser, *shot)


def is_signed_out(page):
    return "/signin" in page.url or "/login" in page.url


def build_og_image():
    print(f"\n{BANNER}\nRebuilding the OG image from the laptop frame ...\n{BANNER}")
    subprocess.run(["npm", "run", "build-og-image"], cwd=WWW, check=False)


def sync_onboarding():
    print(f"\n{BANNER}\nSyncing onboarding screenshots from www ...\n{BANNER}")
    subprocess.run([str(REPO / "bin/sync-onboarding.sh")], check=False)


def main():
    if not WWW.is_dir():
        sys.exit(f"✗ www not found at {WWW}")

    print(f"\n\n{BANNER}\n  Web screenshots\n{BANNER}")
    print(f"App           → {APP_URL}")
    print(f"Feature shots → {FEATURE_DEST}")
    print(f"Press shots   → {PRESS_DEST}")

    PROFILE.mkdir(parents=True, exist_ok=True)
    laptop_before = LAPTOP_DEST.stat().st_mtime if LAPTOP_DEST.exists() else None
    with sync_playwright() as playwright:
        session = Session(playwright)
        try:
            if LOGGED_OUT_SHOTS:
                run_device(session, "Web: signed-out shots (1144x760 @1.8x)", FEATURE_DEST, capture_feature,
                           LOGGED_OUT_SHOTS, signed_in=False)
            run_device(session, "Web: marketing site feature shots (1144x760 @1.8x)", FEATURE_DEST, capture_feature,
                       FEATURE_SHOTS)
            run_device(session, "Web: press kit full-app shots (1440x840 @2x)", PRESS_DEST, capture_press, PRESS_SHOTS)
        except QuitRequested:
            print("Quitting.")
            session.close()
            return
        session.close()

    laptop_after = LAPTOP_DEST.stat().st_mtime if LAPTOP_DEST.exists() else None
    if laptop_after != laptop_before:
        build_og_image()
    sync_onboarding()


if __name__ == "__main__":
    main()
