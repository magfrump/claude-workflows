#!/usr/bin/env python3
"""PostToolUse hook (matcher: WebSearch|WebFetch [+ any web-capable MCP tools]).
Marks this session as having ingested untrusted web content. Non-blocking; exit 0.
NOTE: taint covers WebSearch|WebFetch only — add MCP web tool names to the matcher.
Taint does NOT propagate between subagent and parent sessions. Single-user machine
assumption: markers live under a 0700 dir so other local users can't forge them."""
import sys, os, re, json, pathlib
TAINT_DIR = pathlib.Path(os.environ.get("CC_WEB_TAINT_DIR", "/tmp/cc-web-taint"))
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
sid = re.sub(r"[^A-Za-z0-9_-]", "", str(data.get("session_id", "")))
if sid:
    TAINT_DIR.mkdir(parents=True, exist_ok=True)
    try: os.chmod(TAINT_DIR, 0o700)
    except OSError: pass
    (TAINT_DIR / sid).touch()
sys.exit(0)