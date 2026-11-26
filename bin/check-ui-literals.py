#!/usr/bin/env python3
"""Fails on any raw UI string literal in lib/presentation.

User-facing text goes through lib/l10n/app_en.arb.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCAN_DIR = ROOT / "lib" / "presentation"

UI_TEXT_NAMED_ARGUMENTS = (
    "buttonText",
    "description",
    "errorText",
    "helperText",
    "hintText",
    "label",
    "labelText",
    "message",
    "semanticLabel",
    "semanticsLabel",
    "subtitle",
    "text",
    "title",
    "tooltip",
)

UI_TEXT_OPENERS = re.compile(
    r"\b(?:Text|SelectableText|Tooltip)\(\s*"
    r"|\bshowSnackBar\(\s*\w+\s*,\s*"
    r"|\bget\s+screenTitle\s*=>\s*"
    r"|\b(?:" + "|".join(UI_TEXT_NAMED_ARGUMENTS) + r")\s*:\s*"
)

STRING_START = re.compile(r"r?('''|\"\"\"|'|\")")
INTERPOLATION = re.compile(r"\$\{[^}]*\}|\$\w+")


def read_string_literal(source, start):
    """The contents of the adjacent string literals at `start`, or None."""
    parts = []
    position = start
    while True:
        match = STRING_START.match(source, position)
        if not match:
            break
        quote = match.group(1)
        raw = match.group(0).startswith("r")
        index = match.end()
        while index < len(source):
            if not raw and source[index] == "\\":
                index += 2
                continue
            if source.startswith(quote, index):
                break
            if len(quote) == 1 and source[index] == "\n":
                return None
            index += 1
        parts.append(source[match.end():index])
        position = index + len(quote)
        whitespace = re.match(r"\s*", source[position:])
        position += whitespace.end()
    return "".join(parts) if parts else None


def is_user_facing(literal):
    return re.search(r"[A-Za-z]{2,}", INTERPOLATION.sub("", literal)) is not None


def literals_in(path):
    source = path.read_text(encoding="utf-8")
    found = []
    for opener in UI_TEXT_OPENERS.finditer(source):
        literal = read_string_literal(source, opener.end())
        if literal is not None and is_user_facing(literal):
            line = source.count("\n", 0, opener.start()) + 1
            found.append((line, literal))
    return found


def scan():
    return [
        (path.relative_to(ROOT).as_posix(), line, literal)
        for path in sorted(SCAN_DIR.rglob("*.dart"))
        for line, literal in literals_in(path)
    ]


def main():
    found = scan()
    if found:
        print("User-facing text goes through lib/l10n/app_en.arb (AppLocalizations.of(context)):", file=sys.stderr)
        print("\n".join(f"    {path}:{line}: {literal!r}" for path, line, literal in found), file=sys.stderr)
        return 1
    print("UI literals OK: none in lib/presentation.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
