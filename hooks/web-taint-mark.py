#!/usr/bin/env python3
"""PostToolUse hook (matcher: WebSearch|WebFetch [+ any web-capable MCP tools]).
Marks this session as having ingested untrusted web content. Non-blocking; exit 0.
NOTE: taint covers WebSearch|WebFetch only — add MCP web tool names to the matcher.
Taint does NOT propagate between subagent and parent sessions. Single-user machine
assumption: markers live under a 0700 dir so other local users can't forge them.

The marker's EXISTENCE is the taint signal (guard-trusted-writes.py checks only
that), so it is created first and nothing after it can undo it. Then, best-effort:
  - one JSON line is appended to the marker per fetch, {"t", "tool", "target"}
    (target = the URL for WebFetch, the query for WebSearch, compact tool_input
    for anything else), so the guard's ask can name the fetches behind it;
  - a top-level `systemMessage` is printed, so the user sees each fetch that sets
    the taint as it happens and can review it.
Targets are model-chosen (possibly injection-influenced), so control characters
(ESC/ANSI, newlines) are stripped and each is cut to MAX_TARGET chars."""
import sys, os, re, json, pathlib, datetime, unicodedata
TAINT_DIR = pathlib.Path(os.environ.get("CC_WEB_TAINT_DIR", "/tmp/cc-web-taint"))
MAX_TARGET = 200
# Stripped: Cc = C0/DEL/C1 (ESC, \n, CSI...); Cf = format chars, incl. the bidi
# overrides (U+202E) that can make a URL read as a different one in the prompt;
# Zl/Zp = U+2028/U+2029 line breaks.
_STRIP_CATS = {"Cc", "Cf", "Zl", "Zp"}

def clean(s, limit=MAX_TARGET):
    s = "".join(" " if unicodedata.category(c) in _STRIP_CATS else c for c in str(s))
    s = re.sub(r" {2,}", " ", s).strip()
    return s if len(s) <= limit else s[:limit - 1] + "…"

def target_of(tool, ti):
    if not isinstance(ti, dict):
        ti = {}
    if tool == "WebFetch" and ti.get("url"):
        return ti["url"]
    if tool == "WebSearch" and ti.get("query"):
        return ti["query"]
    try:
        return json.dumps(ti, separators=(",", ":"), sort_keys=True, default=str)
    except Exception:
        return ""

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if not isinstance(data, dict):
    sys.exit(0)
sid = re.sub(r"[^A-Za-z0-9_-]", "", str(data.get("session_id", "")))
if not sid:
    sys.exit(0)
marker = TAINT_DIR / sid
try:
    TAINT_DIR.mkdir(parents=True, exist_ok=True)
    try: os.chmod(TAINT_DIR, 0o700)
    except OSError: pass
    marker.touch(mode=0o600)
except Exception:
    sys.exit(0)
try: os.chmod(marker, 0o600)        # the log names what was fetched: owner-only
except OSError: pass

try:
    tool = clean(data.get("tool_name", "") or "?", 80)
    target = clean(target_of(data.get("tool_name"), data.get("tool_input")))
    line = json.dumps({"t": datetime.datetime.now(datetime.timezone.utc)
                                .strftime("%Y-%m-%dT%H:%M:%SZ"),
                       "tool": tool, "target": target}, ensure_ascii=False)
    # O_APPEND: one write() per line, so concurrent tool calls don't interleave.
    fd = os.open(marker, os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o600)
    try:
        os.write(fd, (line + "\n").encode("utf-8"))
    finally:
        os.close(fd)
    try:
        with open(marker, "rb") as f:
            n = sum(1 for ln in f if ln.strip())
    except Exception:
        n = 0
    nth = f" (fetch #{n} this session)" if n else ""
    print(json.dumps({"systemMessage":
        f"⚠ web taint: {tool} {target or '(no target)'}{nth} — later writes to policy "
        f"files (skills, CLAUDE.md, .claude/) will ask for review. Log: {marker}"}))
    # ensure_ascii (the default) on stdout: valid JSON whatever the locale's encoding.
except Exception:
    pass
sys.exit(0)
