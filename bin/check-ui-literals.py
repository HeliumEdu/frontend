#!/usr/bin/env python3
"""Ratchet on raw UI string literals in lib/presentation.

New user-facing text goes through lib/l10n/app_en.arb. Existing literals are
tolerated per file at the counts in ui-literals-baseline.json, which may only
go down: a file over its count (or a new file with any) fails, and a file
under it fails until `--update` lowers the baseline.
"""

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCAN_DIR = ROOT / "lib" / "presentation"
BASELINE = Path(__file__).resolve().parent / "ui-literals-baseline.json"
BASELINE_COMMENT = ("AUTO-GENERATED — DO NOT EDIT. Raw UI literal counts per file, lowered by: "
                    "frontend/bin/check-ui-literals.py --update (make update-ui-literals-baseline)")

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
    return {
        path.relative_to(ROOT).as_posix(): literals_in(path)
        for path in sorted(SCAN_DIR.rglob("*.dart"))
    }


def load_baseline():
    if not BASELINE.exists():
        return {}
    baseline = json.loads(BASELINE.read_text(encoding="utf-8"))
    baseline.pop("$comment", None)
    return baseline


def write_baseline(counts):
    baseline = {"$comment": BASELINE_COMMENT, **dict(sorted(counts.items()))}
    BASELINE.write_text(json.dumps(baseline, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def check(found, baseline):
    failures = []
    for path, literals in found.items():
        allowed = baseline.get(path, 0)
        if len(literals) > allowed:
            moved = "" if path in baseline else " (a renamed file keeps its count by renaming its baseline key)"
            failures.append(f"{path}: {len(literals)} raw UI literals, baseline allows {allowed}{moved}")
            for line, literal in literals:
                failures.append(f"    {path}:{line}: {literal!r}")
        elif len(literals) < allowed:
            failures.append(
                f"{path}: {len(literals)} raw UI literals, below the baseline of {allowed}; "
                "run `make update-ui-literals-baseline` to lock in the progress"
            )
    for path in sorted(set(baseline) - set(found)):
        failures.append(f"{path}: in the baseline but no longer exists; run `make update-ui-literals-baseline`")
    return failures


def update(found, baseline):
    seeding = not BASELINE.exists()
    counts = {}
    raised = []
    for path, literals in found.items():
        count = len(literals)
        if count == 0:
            continue
        if not seeding and count > baseline.get(path, 0):
            raised.append(f"{path}: {count} raw UI literals, baseline allows {baseline.get(path, 0)}")
            count = baseline.get(path, 0)
        if count:
            counts[path] = count
    write_baseline(counts)
    return raised


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--update", action="store_true", help="lower the baseline to the current counts")
    args = parser.parse_args()

    found = scan()
    baseline = load_baseline()

    if args.update:
        raised = update(found, baseline)
        if raised:
            print("The baseline only goes down; move these strings to lib/l10n/app_en.arb:", file=sys.stderr)
            print("\n".join(raised), file=sys.stderr)
            return 1
        print(f"Baseline written: {sum(load_baseline().values())} raw UI literals.")
        return 0

    failures = check(found, baseline)
    if failures:
        print("New user-facing text goes through lib/l10n/app_en.arb (AppLocalizations.of(context)).", file=sys.stderr)
        print("\n".join(failures), file=sys.stderr)
        return 1
    print(f"UI literals OK: {sum(len(literals) for literals in found.values())} within the baseline.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
