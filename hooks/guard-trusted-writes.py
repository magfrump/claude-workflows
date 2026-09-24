#!/usr/bin/env python3
"""
guard-trusted-writes.py  (v2)  — PreToolUse hook (matcher: Edit|Write|MultiEdit|Bash)

Purpose: stop untrusted content ingested this session from reaching TRUSTED-POLICY
files without review, across BOTH the file tools and Bash (which the v1 hook and the
sandbox-write-deny were the only things covering — and the sandbox is currently down).

Two tiers of policy path:
  HARD  = exactly what permissions.deny covers (hooks/wiring.json): {{CLAUDE_DIR}}/hooks/**,
          {{CLAUDE_DIR}}/settings*.json, {{CLAUDE_DIR}}/CLAUDE.md, ~/CLAUDE.md. {{CLAUDE_DIR}}
          is ONE dir, computed as the linker does (config_dir() below:
          ${CLAUDE_CONFIG_DIR:-$HOME/.claude}); when CLAUDE_CONFIG_DIR points elsewhere,
          ~/.claude is not HARD. Matching is case-sensitive, like the deny rules and
          like Linux paths: ~/.claude/HOOKS/x is not the hooks dir (it falls to SOFT).
          Critical: a hook that returns "ask" SILENTLY OVERRIDES permissions.deny
          (Claude Code issue #39344, precedence deny > defer > ask > allow). So this
          hook must NEVER "ask" on a HARD path. For the file tools HARD splits in two:
            covered  = the path AS GIVEN (lexical, or normpath with `..` folded) names a
                       HARD entry under the config dir as the deny rules spell it. A
                       deny rule names that string, so the hook DEFERS to it.
            resolved = the path is HARD only after resolve() (or only under the config
                       dir's resolved form): e.g. the payload CLAUDE.md addressed by
                       its real /opt path (installed layout: hooks and CLAUDE.md link
                       into /opt/claude-workflows), a bare host's checkout
                       global-instructions/CLAUDE.md or a hook script linked one file at
                       a time into a real ~/.claude/hooks/ (N12), or a project .claude
                       symlinked to ~/.claude. No deny rule names that string, so a defer
                       would be no gate at all; the hook returns "deny" itself, and a
                       deny cannot be approved (Q-050 [2]: such files are edited outside
                       Claude). A regular-file COPY in ~/.claude leaves its source out of
                       the HARD tier: a copied hook's source is ungated, a copied
                       CLAUDE.md's source is SOFT (ask when tainted).
          For Bash, which deny rules don't cover at all, HARD is "deny" outright.
  SOFT  = skills / memories / commands / agents / project CLAUDE.md|AGENTS.md / *.mdc,
          a PROJECT's own .claude/ (settings*.json, hooks/**; Q-026), and
          managed-settings.json. No deny rule names these, so deferring would leave
          them with no gate at all; they are SOFT instead.
          Legitimately edited. Gated to "ask" only when the session is web-tainted.

Bash is classified by command TEXT, so it can't resolve a path, and the shell can spell
one many ways. The global tier is therefore decided by CO-OCCURRENCE in the text:
  HARD  = any `.claude/hooks`, `.claude/settings`, managed-settings fragment; OR a
          CLAUDE.md mention (any case) together with ANY home/global indicator anywhere
          in the command (`~`, `$HOME`, `${HOME…`, the literal home path, `.claude`,
          `global-instructions`, `CLAUDE_CONFIG_DIR`, the literal config dir); OR a
          settings*.json / hooks mention together with `.claude` / the config dir.
          Conservative: a heredoc that names ~/.claude/CLAUDE.md in prose is denied.
          No worktree exemption: Q-048 [2]'s exemption for agent worktrees
          (`.claude/wt-*`, `.claude/worktrees/*`) was tried and withdrawn after
          three review passes each found bypasses (quote-split `..`, `cd ..`/`../`,
          same-command swaps, `-t..`, brace expansion, `env -C`, link-creating
          tools; docs/reviews/code-fact-check-report*-pass{1,2,3}-*.md), so a
          worktree Bash write that mentions `.claude` plus a policy name is denied
          and agents there use Edit/Write or absolute paths.
          Not gated here: Bash writes to a linked hook's CHECKOUT path (e.g.
          `echo x > <checkout>/hooks/<name>` on a bare host) get no opinion; only
          Edit/Write are denied there (N12). Pre-existing, alongside N2/A8.
  SOFT  = a CLAUDE.md with no home/global indicator anywhere (Q-035) — matching the
          Edit/Write tier, so a heredoc or commit message that merely names a project
          CLAUDE.md is no longer denied.

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

def config_dir() -> Path:
    """The ONE global config dir: what the linker substitutes as {{CLAUDE_DIR}}.

    devcontainer-config/link-claude-home.sh uses DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}":
    an empty value falls back, `~` is NOT expanded, and there is no second dir. So
    ~/.claude is NOT global when CLAUDE_CONFIG_DIR points elsewhere (it falls to SOFT,
    since no deny rule covers it). This matches the linker for an unset, empty or
    absolute value. It DIFFERS for a relative value (including one that starts with a
    literal `~`): the linker substitutes the string as written, while this hook anchors
    it at the hook's own cwd with abspath(), so it can't match from anywhere.
    """
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    return Path(os.path.abspath(cfg)) if cfg else HOME / ".claude"

def _safe_resolve(p: Path) -> Path:
    try: return p.resolve()
    except Exception: return p

CONFIG_DIR = config_dir()
# The dir both as written and resolved (it may itself be a symlink).
GLOBAL_DIRS = [CONFIG_DIR, _safe_resolve(CONFIG_DIR)]
# Where the deny-covered entries actually live. In the installed layout
# ~/.claude/hooks and ~/.claude/CLAUDE.md are symlinks into /opt/claude-workflows,
# so resolve() leaves GLOBAL_DIRS; these catch a candidate that resolves onto a
# link target (R4).
_HARD_FILE_TARGETS = {_safe_resolve(CONFIG_DIR / "CLAUDE.md"), _safe_resolve(HOME / "CLAUDE.md")}
try:
    _settings_names = {q.name for q in CONFIG_DIR.glob("settings*.json")}
except Exception:
    _settings_names = set()
for _n in {"settings.json", "settings.local.json"} | _settings_names:
    _HARD_FILE_TARGETS.add(_safe_resolve(CONFIG_DIR / _n))
_HARD_DIR_TARGETS = {_safe_resolve(CONFIG_DIR / "hooks")}
# N12 / Q-050: on a bare host ~/.claude/hooks is a REAL dir whose entries can be
# per-file symlinks into the checkout (README setup). Resolving only the directory
# misses them, so resolve each entry: a checkout file that IS a live hook is HARD
# (resolved tier -> deny). A regular-file copy resolves into the config dir itself,
# which leaves its checkout original out of the HARD tier, as intended (a
# CLAUDE.md original still falls to SOFT and asks when tainted).
try:
    for _e in (CONFIG_DIR / "hooks").iterdir():
        _t = _safe_resolve(_e)
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
except Exception:
    pass

def _rel_under(cand: Path, dirs):
    """Path of `cand` relative to the first of `dirs` that contains it, or None."""
    for g in dirs:
        try:
            return cand.relative_to(g)
        except ValueError:
            continue
    return None

def _is_hard(cand: Path, dirs) -> bool:
    """HARD == exactly what permissions.deny covers (hooks/wiring.json):
    {{CLAUDE_DIR}}/settings*.json, {{CLAUDE_DIR}}/hooks/**, {{CLAUDE_DIR}}/CLAUDE.md,
    ~/CLAUDE.md, with {{CLAUDE_DIR}} taken as each of `dirs`.

    Case-SENSITIVE, like the deny rules (N1): lowercasing here made
    ~/.claude/HOOKS/x and ~/.claude/SETTINGS.JSON "HARD", so the hook deferred onto
    a rule that does not name them and they got no gate at all."""
    rel = _rel_under(cand, dirs)
    if rel is not None and rel.parts:
        first = rel.parts[0]
        if first == "hooks":
            return True
        if len(rel.parts) == 1 and first.startswith("settings") and first.endswith(".json"):
            return True
        if len(rel.parts) == 1 and first == "CLAUDE.md":
            return True
    if cand.name == "CLAUDE.md" and cand.parent == HOME:
        return True
    return False

def classify_path(fp: str) -> str:
    """"hard" (a deny rule names this string: defer), "hard-resolved" (HARD only
    after resolve(), no deny rule names it: deny), "soft", or "none"."""
    p = Path(os.path.expanduser(str(fp)))
    # pathlib already collapses `//` and `/./`; normpath also folds `..` lexically,
    # so `~/.claude/x/../CLAUDE.md` is seen as `~/.claude/CLAUDE.md` (R4).
    norm = Path(os.path.normpath(str(p)))
    rp = _safe_resolve(p)
    cands = (p, norm, rp)
    # HARD first, on EVERY candidate: a HARD path must never reach the "ask" below
    # (an ask overrides permissions.deny, #39344).
    # (a) As given, under the config dir as the deny rules spell it: covered.
    for cand in (p, norm):
        if _is_hard(cand, [CONFIG_DIR]):
            return "hard"
    # (b) Only via the config dir's resolved form, only after resolve(), or onto the
    # target of a symlinked global entry (R4): no deny rule names this string.
    for cand in cands:
        if _is_hard(cand, GLOBAL_DIRS):
            return "hard-resolved"
    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
        return "hard-resolved"
    # SOFT. A project's own .claude/ (settings, hooks) lands here (Q-026), and so does
    # managed-settings.json: no deny rule names it, so deferring would leave it ungated.
    # Case-folded on purpose: SOFT only ever asks, so over-matching is safe.
    for cand in cands:
        low = {seg.lower() for seg in cand.parts}
        name = cand.name.lower()
        if low & {"skills", "memories", "commands", "agents"} and cand.suffix.lower() in (".md", ".txt", ""):
            return "soft"
        if name in ("claude.md", "agents.md", "claude.local.md", "managed-settings.json") \
                or cand.suffix.lower() == ".mdc":
            return "soft"
        if ".claude" in low:
            return "soft"
    return "none"

# ── write-intent detection for the BASH tool ───────────────────────────────
# TODO(N2): command TEXT that writes a global policy file but carries no
# indicator token the co-occurrence rules below look for, so it gets no
# opinion (pre-existing; code-review 2026-09-21 iteration 2, N2):
#   - a bare `cd; echo x > CLAUDE.md` (cd to home with no `~`);
#   - `/home/$USER/CLAUDE.md`;
#   - a globbed or quoted `.claude` name: `~/.clau*/settings.json`,
#     `~/.cl""aude/...`, `D=.cl; ~/${D}aude/...`, `~/.claude/"settings".json`,
#     `hoo"ks"`;
#   - `/opt/claude-workflows/hooks/...` (the payload, by its real path);
#   - whole-tree copies into the config dir: `cp -r dir/. ~/.claude/`,
#     `rsync -a dir/ ~/.claude/`, `cd ~/.claude && cp /tmp/p/* .`. These
#     replace settings.json (hook wiring + deny list) with no gate, even tainted.
# Security's suggested direction: write primitive + CFG_INDICATOR -> HARD.
# TODO(A8): write primitives not recognised here (predates Q-035; code-review
# 2026-09-21 A8): `ln -sf`, `curl -o`, `wget -O`, `tar -C` / `tar -x`,
# `unzip -d`, `sponge`, `python3 script.py` (non-inline interpreters),
# `git checkout` / `git restore` over a tracked policy file, and
# `git config --global`. A command that writes only through these gets no
# opinion from this hook.
WRITE_PRIMITIVE = re.compile(
    # >, >>, 1>, 2>, &> and >&FILE to a file. Only a digit or `-` after `>&`
    # is an fd duplicate/close (2>&1, >&2, >&-); `>& word` writes to `word`.
    r">>?(?!&\s*(?:\d|-)|\s*/dev/null\b)"
    r"|\btee\b|\bsed\b[^\n|;&]*\s-\w*i\w*\b"       # tee, sed -i
    r"|\bdd\b[^\n]*\bof=|\btruncate\b"             # dd of=, truncate
    r"|\b(cp|mv|install|rsync)\b"                  # copy/move/install (dest ambiguous)
    r"|\b(python[0-9.]*|node|perl|ruby)\b[^\n]*\s-[ce]\b"  # inline interpreters
)

# Bash is classified by command TEXT, which the shell can spell many ways
# ("$HOME"/CLAUDE.md, ~//CLAUDE.md, H=~; ... $H/CLAUDE.md, cd ~/.claude && ...).
# So the global tier is decided by CO-OCCURRENCE, not by an exact path spelling:
# a home/global indicator ANYWHERE in the command, together with a policy-file
# name, is HARD (R1, A10). Deliberately conservative.
_HOME_INDICATORS = [r"~", r"\$HOME\b", r"\$\{[!#]?HOME\b", r"\.claude\b",
                    r"global-instructions", r"CLAUDE_CONFIG_DIR"]
# `.claude` / the config dir is the indicator for settings/hooks: `~` alone plus
# the word "hooks" is too weak a signal to deny on.
_CFG_INDICATORS = [r"\.claude\b", r"CLAUDE_CONFIG_DIR"]
for _lit in {str(HOME).rstrip("/"), str(CONFIG_DIR).rstrip("/")}:
    if _lit:                      # HOME="/" would make this empty and match everything
        _HOME_INDICATORS.append(re.escape(_lit))
if str(CONFIG_DIR).rstrip("/"):
    _CFG_INDICATORS.append(re.escape(str(CONFIG_DIR).rstrip("/")))
HOME_INDICATOR = re.compile("|".join(_HOME_INDICATORS), re.I)
CFG_INDICATOR = re.compile("|".join(_CFG_INDICATORS), re.I)
CLAUDE_MD = re.compile(r"claude\.md", re.I)
SETTINGS_OR_HOOKS = re.compile(r"settings[\w.-]*\.json|\bhooks\b", re.I)
HARD_FRAG = re.compile(r"\.claude/hooks(/|\b)|\.claude/settings|managed-settings", re.I)
SOFT_FRAG = re.compile(
    r"\.claude/(skills|memories|commands|agents)"
    r"|(^|[\s\"'=/])(AGENTS|CLAUDE|CLAUDE\.local)\.md|\.mdc(\b|$)", re.I)

def bash_targets(cmd: str):
    has_write = bool(WRITE_PRIMITIVE.search(cmd))
    if not has_write:
        return None
    if HARD_FRAG.search(cmd):
        return "hard"
    # R1 / Q-035: CLAUDE.md plus any home/global indicator -> the global file may be meant.
    if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):
        return "hard"
    # A10: settings*.json / hooks plus the config dir named anywhere.
    if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
        return "hard"
    # Only a CLAUDE.md with NO home/global indicator anywhere reaches SOFT (Q-035).
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
                         "Claude cannot write these: make the change outside Claude, in your own "
                         "editor or shell, and review it there. If the command only mentions such a "
                         "path in prose (a heredoc or message), write that text with the Write tool "
                         "and pass the file instead.")
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
            # Defer and let the deny rule, which names this path, block it.
            defer()
        if tier == "hard-resolved":
            # No deny rule names this spelling, so a defer would be no gate at all,
            # and an ask is wrong for a HARD target. Deny outright.
            # N15: do not point at the config-dir spelling: permissions.deny blocks it.
            emit("deny", f"This path is a live protected policy file ({Path(fp).name}: a global "
                         "hook, settings or CLAUDE.md, reached here by its real path or through a "
                         "symlink), so Claude's file tools cannot edit it. Make the change outside "
                         "Claude, in your own editor or shell, and review it there.")
        if tier == "soft" and tainted:
            emit("ask", f"This session fetched web content and this write targets a trusted-policy "
                        f"file ({Path(fp).name}). Review it for injected instructions before allowing.")
        defer()

    defer()

if __name__ == "__main__":
    main()
