#!/usr/bin/env python3
"""Fails while any translation lacks an ARB message, listing them from gen-l10n's untranslated-messages-file.

The app shows English for a missing message.
"""

import json
import sys
from pathlib import Path

UNTRANSLATED = Path(__file__).resolve().parent.parent / ".dart_tool" / "untranslated_messages.json"


def main():
    missing = json.loads(UNTRANSLATED.read_text(encoding="utf-8"))
    if not missing:
        print("Translations OK: every language has every message.")
        return 0
    for language, keys in sorted(missing.items()):
        print(f"{language}: {len(keys)} untranslated message(s), shown in English:", file=sys.stderr)
        print("\n".join(f"    {key}" for key in keys), file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
