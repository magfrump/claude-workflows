#!/usr/bin/env python3
"""
guard-trusted-writes.py  (v2)  — PreToolUse hook (matcher: Edit|Write|MultiEdit|Bash)

Purpose: stop untrusted content ingested this session from reaching TRUSTED-POLICY
files without review, across BOTH the file tools and Bash (which the v1 hook and the
sandbox-write-deny were the only things covering — and the sandbox is currently down).

Two tiers of policy path:
  HARD  = ~/.claude/hooks/**, ~/.claude/settings*.json, ~/.claude/CLAUDE.md, ~/CLAUDE.md
          These are also covered by your Edit/Write DENY rules. Critical: a hook that
          returns "ask" SILENTLY OVERRIDES permissions.deny (Claude Code issue #39344,
          precedence deny > defer > ask > allow). So this hook must NEVER "ask" on a
          HARD path — it DEFERS (lets the deny rule block the file tools) and, for the
          Bash path that deny rules don't cover, returns "deny" outright.
  SOFT  = skills / memories / commands / agents / project CLAUDE.md|AGENTS.md / *.mdc
          Legitimately edited. Gated to "ask" only when the session is web-tainted.

Decisions: emit JSON only for ask/deny. For "no opinion", exit 0 with NO output — the
documented, version-independent defer (avoids the headless tool_deferred semantics of
permissionDecision:"defer").
"""
from __future__ import annotations
import sys, os, re, json
from pathlib import Path

TAINT_DIR = Path(os.environ.get("CC_WEB_TAINT_DIR", "/tmp/cc-web-taint"))

def emit(decision, reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": decision,
        "permissionDecisionReason": reason}}))
    sys.exit(0)

def defer():                      # no opinion -> normal flow (deny rules still apply)
    sys.exit(0)

# ── path classification for the FILE tools ──────────────────────────────────
HOME = Path.home()
def classify_path(fp: str) -> str:
    p = Path(os.path.expanduser(str(fp)))
    try: rp = p.resolve()
    except Exception: rp = p
    for cand in (p, rp):
        parts = cand.parts
        name = cand.name.lower()
        low = {seg.lower() for seg in parts}
        claude_idx = next((i for i, s in enumerate(parts) if s == ".claude"), None)
        # HARD
        if claude_idx is not None and claude_idx + 1 < len(parts) and parts[claude_idx + 1] == "hooks":
            return "hard"
        if name.startswith("settings") and cand.suffix == ".json" and ".claude" in low:
            return "hard"
        if name == "claude.md" and (".claude" in low or cand.parent == HOME):
            return "hard"
        if name in ("managed-settings.json",):
            return "hard"
    for cand in (p, rp):
        low = {seg.lower() for seg in cand.parts}
        name = cand.name.lower()
        if low & {"skills", "memories", "commands", "agents"} and cand.suffix.lower() in (".md", ".txt", ""):
            return "soft"
        if name in ("claude.md", "agents.md", "claude.local.md") or cand.suffix.lower() == ".mdc":
            return "soft"
        if ".claude" in low:
            return "soft"
    return "none"

# ── write-intent detection for the BASH tool ───────────────────────────────
WRITE_PRIMITIVE = re.compile(
    r"(?<![0-9&])>>?(?![&])"                       # > or >> to a file (not 2>&1, >&2)
    r"|\btee\b|\bsed\b[^\n|;&]*\s-\w*i\w*\b"       # tee, sed -i
    r"|\bdd\b[^\n]*\bof=|\btruncate\b"             # dd of=, truncate
    r"|\b(cp|mv|install|rsync)\b"                  # copy/move/install (dest ambiguous)
    r"|\b(python[0-9.]*|node|perl|ruby)\b[^\n]*\s-[ce]\b"  # inline interpreters
)
HARD_FRAG = re.compile(
    r"\.claude/hooks(/|\b)|\.claude/settings|\.claude/CLAUDE\.md"
    r"|managed-settings|(^|[\s\"'=~/])CLAUDE\.md", re.I)
SOFT_FRAG = re.compile(
    r"\.claude/(skills|memories|commands|agents)|(^|[\s\"'=/])AGENTS\.md|\.mdc(\b|$)", re.I)

def bash_targets(cmd: str):
    has_write = bool(WRITE_PRIMITIVE.search(cmd))
    if not has_write:
        return None
    if HARD_FRAG.search(cmd):
        return "hard"
    if SOFT_FRAG.search(cmd):
        return "soft"
    return None

# ── main ────────────────────────────────────────────────────────────────────
def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        defer()
    tool = data.get("tool_name", "")
    ti = data.get("tool_input", {}) or {}
    sid = re.sub(r"[^A-Za-z0-9_-]", "", str(data.get("session_id", "")))
    tainted = bool(sid) and (TAINT_DIR / sid).exists()

    if tool == "Bash":
        cmd = str(ti.get("command", ""))
        tier = bash_targets(cmd)
        if tier == "hard":
            # deny rules don't cover Bash-mediated writes; block outright.
            # "deny" wins over any auto-approve hook's "allow" (deny > ... > allow).
            emit("deny", "Bash write to a protected policy file (~/.claude hooks/settings/CLAUDE.md). "
                         "Edit it directly with review, not via a shell write.")
        if tier == "soft" and tainted:
            emit("ask", "This session fetched web content and this Bash command writes to a "
                        "trusted-policy file. Review it for injected content before allowing.")
        defer()

    if tool in ("Edit", "Write", "MultiEdit"):
        fp = ti.get("file_path") or ti.get("path") or ""
        if not fp:
            defer()
        tier = classify_path(fp)
        if tier == "hard":
            # DO NOT "ask": that would override your permissions.deny (#39344).
            # Defer and let the deny rule block it.
            defer()
        if tier == "soft" and tainted:
            emit("ask", f"This session fetched web content and this write targets a trusted-policy "
                        f"file ({Path(fp).name}). Review it for injected instructions before allowing.")
        defer()

    defer()

if __name__ == "__main__":
    main()