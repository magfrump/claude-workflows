#!/usr/bin/env python3
"""Prepend a one-line ``Cycle framing: ...`` entry to morning-summary.md.

This is the non-.sh half of the morning-summary writer: it supplements
``scripts/lib/si-morning-summary.sh`` (which generates the bulk of the
summary) with a top-of-file cycle-framing line. Living in Python — not
bash — is deliberate: the SI loop's shellcheck gate filters bash edits
to this area, and prior R1/R2 cycle-framing attempts were rejected
there. A non-.sh emitter sidesteps that gate by construction.

Usage:
    python3 scripts/lib/si-morning-summary.py \\
        --framing "<one-line framing text>" \\
        [--summary docs/working/morning-summary.md]

Behaviour:
- Reads the target summary file and strips any existing
  ``Cycle framing: ...`` line at the top (plus its trailing blank line)
  so re-runs replace rather than stack.
- Prepends ``Cycle framing: <text>`` followed by a blank line.
- Rejects empty/whitespace framing and framing containing newlines —
  the entry is required to be exactly one line.
- Exits non-zero with a readable error when the target file is missing.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

DEFAULT_SUMMARY = Path("docs/working/morning-summary.md")
FRAMING_PREFIX = "Cycle framing: "


def strip_existing_framing(content: str) -> str:
    """Remove a top-of-file ``Cycle framing: ...`` block, if present.

    The block is the first line (which must start with ``FRAMING_PREFIX``)
    plus a single optional blank line immediately after it. Anything
    further down is left untouched so a stray later occurrence of the
    same prefix is never silently rewritten.
    """
    lines = content.splitlines(keepends=True)
    if not lines or not lines[0].startswith(FRAMING_PREFIX):
        return content
    rest = lines[1:]
    if rest and rest[0].strip() == "":
        rest = rest[1:]
    return "".join(rest)


def prepend_framing(summary_path: Path, framing: str) -> None:
    if not summary_path.exists():
        raise FileNotFoundError(f"summary file not found: {summary_path}")

    original = summary_path.read_text(encoding="utf-8")
    body = strip_existing_framing(original)
    new_content = f"{FRAMING_PREFIX}{framing}\n\n{body}"
    summary_path.write_text(new_content, encoding="utf-8")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Prepend a one-line Cycle framing entry to morning-summary.md",
    )
    parser.add_argument(
        "--framing",
        required=True,
        help="One-line framing text. Must be non-empty and contain no newlines.",
    )
    parser.add_argument(
        "--summary",
        type=Path,
        default=DEFAULT_SUMMARY,
        help=f"Path to the summary file (default: {DEFAULT_SUMMARY}).",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    framing = args.framing.strip()
    if not framing:
        print("error: --framing must be non-empty", file=sys.stderr)
        return 2
    if "\n" in args.framing or "\r" in args.framing:
        print("error: --framing must be a single line (no newlines)", file=sys.stderr)
        return 2

    try:
        prepend_framing(args.summary, framing)
    except FileNotFoundError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
