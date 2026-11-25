#!/usr/bin/env python3
"""Writes lib/l10n/app_en_XA.arb, a pseudo-translation of app_en.arb.

Every message is accented, padded about 35% longer and bracketed, so English
that skipped the ARB, truncation and clipping stand out when the app runs as
`en-XA` (`make run-pseudo-locale`). Placeholders and ICU plural/select syntax
are kept intact. The output is gitignored and must never ship.
"""

import json
import math
from pathlib import Path

L10N_DIR = Path(__file__).resolve().parent.parent / "lib" / "l10n"
SOURCE_ARB = L10N_DIR / "app_en.arb"
PSEUDO_ARB = L10N_DIR / "app_en_XA.arb"
PSEUDO_LOCALE = "en_XA"
EXPANSION = 0.35

ACCENTED = str.maketrans(
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "åƀçđéƒĝĥîĵķļɱñöþǫŕšţûṽŵẋýžÅƁÇĐÉƑĜĤÎĴĶĻṀÑÖÞǪŔŠŢÛṼŴẊÝŽ",
)
ICU_TYPES = ("plural", "select", "selectordinal")


def _matching_brace(message, start):
    depth = 0
    for index in range(start, len(message)):
        if message[index] == "{":
            depth += 1
        elif message[index] == "}":
            depth -= 1
            if depth == 0:
                return index
    raise ValueError(f"Unbalanced braces in {message!r}")


def _pseudo_argument(argument):
    parts = argument.split(",", 2)
    if len(parts) < 3 or parts[1].strip() not in ICU_TYPES:
        return "{" + argument + "}"
    cases = parts[2]
    rewritten = []
    index = 0
    while index < len(cases):
        open_brace = cases.find("{", index)
        if open_brace == -1:
            rewritten.append(cases[index:])
            break
        close_brace = _matching_brace(cases, open_brace)
        rewritten.append(cases[index:open_brace])
        rewritten.append("{" + pseudo_text(cases[open_brace + 1:close_brace]) + "}")
        index = close_brace + 1
    return "{" + parts[0] + "," + parts[1] + "," + "".join(rewritten) + "}"


def pseudo_text(message):
    result = []
    index = 0
    while index < len(message):
        if message[index] == "{":
            close_brace = _matching_brace(message, index)
            result.append(_pseudo_argument(message[index + 1:close_brace]))
            index = close_brace + 1
        else:
            result.append(message[index].translate(ACCENTED))
            index += 1
    return "".join(result)


def pseudo_message(message):
    padding = "·" * math.ceil(len(message) * EXPANSION)
    return f"⟦{pseudo_text(message)}{padding}⟧"


def main():
    source = json.loads(SOURCE_ARB.read_text(encoding="utf-8"))
    pseudo = {"@@locale": PSEUDO_LOCALE}
    pseudo.update(
        {key: pseudo_message(value) for key, value in source.items() if not key.startswith("@")}
    )
    PSEUDO_ARB.write_text(json.dumps(pseudo, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {PSEUDO_ARB.relative_to(L10N_DIR.parent.parent)} ({len(pseudo) - 1} messages).")


if __name__ == "__main__":
    main()
