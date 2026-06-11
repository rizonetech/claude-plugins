#!/usr/bin/env python3
"""Format `claude -p --output-format stream-json --verbose` output for run logs.

Reads stream-json lines on stdin and writes one timestamped line per event:
assistant text blocks (when the message completes), tool-use events as
"tool: <name>", and the final result marked "=== final ===". Lines that are
not parseable JSON pass through unchanged. Stdlib only.
"""
from __future__ import annotations

import json
import sys
from datetime import datetime


def stamp() -> str:
    return datetime.now().strftime("%H:%M:%S")


def emit(text: str) -> None:
    for line in text.splitlines() or [""]:
        sys.stdout.write(f"{stamp()} {line}\n")
    sys.stdout.flush()


def handle(event: dict) -> None:
    kind = event.get("type")
    if kind == "assistant":
        for block in (event.get("message") or {}).get("content") or []:
            if block.get("type") == "text" and block.get("text"):
                emit(block["text"])
            elif block.get("type") == "tool_use":
                emit(f"tool: {block.get('name', 'unknown')}")
    elif kind == "result":
        emit("=== final ===")
        result = event.get("result")
        if isinstance(result, str) and result:
            emit(result)


def main() -> int:
    for raw in sys.stdin:
        line = raw.rstrip("\n")
        if not line.strip():
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            sys.stdout.write(raw if raw.endswith("\n") else raw + "\n")
            sys.stdout.flush()
            continue
        if isinstance(event, dict):
            handle(event)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
