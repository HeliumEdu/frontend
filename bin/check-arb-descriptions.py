#!/usr/bin/env python3
"""Fails unless every message in lib/l10n/app_en.arb has a translator description.

`flutter gen-l10n` (required-resource-attributes) only requires the `@key`
entry; this also requires its `description`.
"""

import json
import sys
from pathlib import Path

SOURCE_ARB = Path(__file__).resolve().parent.parent / "lib" / "l10n" / "app_en.arb"


def main():
    messages = json.loads(SOURCE_ARB.read_text(encoding="utf-8"))
    missing = [
        key
        for key in messages
        if not key.startswith("@")
        and not str((messages.get(f"@{key}") or {}).get("description", "")).strip()
    ]
    if missing:
        print(f"{SOURCE_ARB.name}: add a translator description to @{', @'.join(missing)}", file=sys.stderr)
        return 1
    print(f"{SOURCE_ARB.name}: all {sum(not key.startswith('@') for key in messages)} messages described.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
