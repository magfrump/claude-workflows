#!/usr/bin/env python3
"""
guard-trusted-writes.py  (v2)  — PreToolUse hook (matcher: Edit|Write|MultiEdit|Bash)

Purpose: stop untrusted content ingested this session from reaching TRUSTED-POLICY
files without review, across BOTH the file tools and Bash (which the v1 hook and the
sandbox-write-deny were the only things covering — and the sandbox is currently down).

Two tiers of policy path:
  HARD  = the GLOBAL config dir only: ~/.claude/hooks/**, ~/.claude/settings*.json,
          ~/.claude/CLAUDE.md, ~/CLAUDE.md (the config dir is $CLAUDE_CONFIG_DIR when set,
          else ~/.claude — the same {{CLAUDE_DIR}} hooks/wiring.json substitutes).
          These are also covered by your Edit/Write DENY rules. Critical: a hook that
          returns "ask" SILENTLY OVERRIDES permissions.deny (Claude Code issue #39344,
          precedence deny > defer > ask > allow). So this hook must NEVER "ask" on a
          HARD path — it DEFERS (lets the deny rule block the file tools) and, for the
          Bash path that deny rules don't cover, returns "deny" outright.
  SOFT  = skills / memories / commands / agents / project CLAUDE.md|AGENTS.md / *.mdc,
          and a PROJECT's own .claude/ (settings*.json, hooks/**; Q-026). The deny
          rules name only the global dir, so deferring on a project .claude/ path would
          leave it with no gate at all; it is SOFT instead.
          Legitimately edited. Gated to "ask" only when the session is web-tainted.

Bash is classified by command TEXT, so it can't resolve a relative path:
  HARD  = any `.claude/hooks`, `.claude/settings`, `.claude/CLAUDE.md` fragment (global
          or project — the text doesn't say which), managed-settings, and CLAUDE.md
          only when qualified as global: `~/`, `$HOME/`, `${HOME}/`, the literal home
          path, or `global-instructions/CLAUDE.md` (this repo's source of the global
          file; hard for Bash per the 2026-09-12 security review).
  SOFT  = a bare/project `CLAUDE.md` (Q-035) — matching the Edit/Write tier, so a
          heredoc or commit message that merely names the file is no longer denied.

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

def _global_dirs():
    """The global config dir(s), as given and resolved. HARD applies only here."""
    dirs = [HOME / ".claude"]
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    if cfg:
        dirs.append(Path(os.path.expanduser(cfg)))
    out = []
    for d in dirs:
        out.append(d)
        try: out.append(d.resolve())
        except Exception: pass
    return out

GLOBAL_DIRS = _global_dirs()

def _global_rel(cand: Path):
    """Path of `cand` relative to a global config dir, or None if outside all of them."""
    for g in GLOBAL_DIRS:
        try:
            return cand.relative_to(g)
        except ValueError:
            continue
    return None

def classify_path(fp: str) -> str:
    p = Path(os.path.expanduser(str(fp)))
    try: rp = p.resolve()
    except Exception: rp = p
    for cand in (p, rp):
        name = cand.name.lower()
        # HARD: only the global config dir (what permissions.deny covers). A project's
        # own .claude/ falls through to SOFT below (Q-026).
        rel = _global_rel(cand)
        if rel is not None and rel.parts:
            if rel.parts[0] == "hooks":
                return "hard"
            if len(rel.parts) == 1 and name.startswith("settings") and cand.suffix == ".json":
                return "hard"
            if len(rel.parts) == 1 and name == "claude.md":
                return "hard"
        if name == "claude.md" and cand.parent == HOME:
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
    # >, >>, 1>, 2>, &> and >&FILE to a file. Only a digit or `-` after `>&`
    # is an fd duplicate/close (2>&1, >&2, >&-); `>& word` writes to `word`.
    r">>?(?!&\s*(?:\d|-)|\s*/dev/null\b)"
    r"|\btee\b|\bsed\b[^\n|;&]*\s-\w*i\w*\b"       # tee, sed -i
    r"|\bdd\b[^\n]*\bof=|\btruncate\b"             # dd of=, truncate
    r"|\b(cp|mv|install|rsync)\b"                  # copy/move/install (dest ambiguous)
    r"|\b(python[0-9.]*|node|perl|ruby)\b[^\n]*\s-[ce]\b"  # inline interpreters
)
# CLAUDE.md is HARD in Bash only when the text qualifies it as the global file
# (Q-035); a bare/project CLAUDE.md is SOFT, like the Edit/Write tier.
_GLOBAL_PREFIXES = [r"~", r"\$HOME", r"\$\{HOME\}", r"global-instructions"]
if str(HOME).rstrip("/"):         # HOME="/" would make this prefix empty and match any "/CLAUDE.md"
    _GLOBAL_PREFIXES.append(re.escape(str(HOME).rstrip("/")))
HARD_FRAG = re.compile(
    r"\.claude/hooks(/|\b)|\.claude/settings|\.claude/CLAUDE\.md|managed-settings"
    r"|(?:" + "|".join(_GLOBAL_PREFIXES) + r")/CLAUDE\.md",
    re.I)
SOFT_FRAG = re.compile(
    r"\.claude/(skills|memories|commands|agents)"
    r"|(^|[\s\"'=/])(AGENTS|CLAUDE|CLAUDE\.local)\.md|\.mdc(\b|$)", re.I)

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
    if not isinstance(data, dict):  # valid JSON but not an object ([] / "x"): no opinion
        defer()
    tool = data.get("tool_name", "")
    ti = data.get("tool_input", {}) or {}
    if not isinstance(ti, dict):    # e.g. tool_input as a bare string: no opinion
        defer()
    sid = re.sub(r"[^A-Za-z0-9_-]", "", str(data.get("session_id", "")))
    tainted = bool(sid) and (TAINT_DIR / sid).exists()

    if tool == "Bash":
        cmd = str(ti.get("command", ""))
        tier = bash_targets(cmd)
        if tier == "hard":
            # deny rules don't cover Bash-mediated writes; block outright.
            # "deny" wins over any auto-approve hook's "allow" (deny > ... > allow).
            emit("deny", "Bash write to a protected policy file (.claude hooks/settings, global CLAUDE.md). "
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