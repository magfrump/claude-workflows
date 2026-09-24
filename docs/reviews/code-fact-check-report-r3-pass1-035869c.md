Commit: 035869c

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-guard`, branch `ans/guard-q048-q050`)
**Scope:** branch diff `970e525..035869c` (3 commits: 456bded, ccda554, 035869c) — `hooks/guard-trusted-writes.py`, `test/hooks/guard-trusted-writes.bats`, `guides/bare-host-hook-wiring.md`, plus the three commit messages; `hooks/wiring.json` and `README.md` read as referenced context
**Checked:** 2026-09-23
**Total claims checked:** 15
**Summary:** 8 verified, 2 mostly accurate, 0 stale, 4 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 7 entries). The one relevant class is "a specific measured value (test count) quoted from a checked-in artifact set that does not contain it"; Claim 15 was compared against it and does **not** match (the count holds).

Execution provenance (shared by all `executed` claims):
- Suite runs: `bash /tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/review/run_new.sh`, cwd `/workspace/.claude/wt-guard` (then a scratch copy of the test tree with `git show 970e525:hooks/guard-trusted-writes.py` swapped in), timestamp 2026-09-23T23:29:55Z. Branch hook: exit 0, 70/70 ok. 970e525 hook: exit 1. Output: `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-new.log`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-old.log`.
- Probes: `python3 probe.py` (copied as `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.py`), cwd the review scratchpad, exit 0, timestamp 2026-09-23T23:31:49Z; output `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`. `python3 probe2.py` (copied as `…-probe2.py`), exit 0, timestamp 2026-09-23T23:32:25Z; output `docs/reviews/execution-logs/2026-09-23-r3-guard-probe2.log`. Every probe runs the hook as a subprocess with a temp `HOME` (and temp `CLAUDE_CONFIG_DIR` where noted); the real `~/.claude` is never touched. Shell-effect probes ran `bash -c` against the same temp HOME only.

---

## Claim 1: "the guard **denies** Claude's file tools on its checkout copy, in a tainted session or not: `global-instructions/CLAUDE.md` behind a linked `~/.claude/CLAUDE.md`, and every `hooks/<name>` linked one file at a time into `~/.claude/hooks/`"

**Location:** `guides/bare-host-hook-wiring.md:60-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Edit/Write/MultiEdit on the checkout CLAUDE.md and a per-file-linked hook in the README bare-host layout, clean and tainted; does not establish behavior for Bash writes to those checkout paths (the Bash tier is text-based and does not resolve links) or for directory-level hook links (see Claim 11).
**Legibility-target:** for-orchestrator-synthesis

Tests 61 and 62 pass on the branch and exercise exactly this layout. The per-file link target is added by the new load-time loop:

```python
# hooks/guard-trusted-writes.py:116-121
try:
    for _e in (CONFIG_DIR / "hooks").iterdir():
        _t = _safe_resolve(_e)
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
except Exception:
    pass
```

and `classify_path` turns a match into `hard-resolved`, which `main()` denies regardless of taint:

```python
# hooks/guard-trusted-writes.py:173-174 (excerpt ends :174; enclosing classify_path() continues to :188 — read)
    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
        return "hard-resolved"
```

The test log shows `ok 61 Q-050: the checkout CLAUDE.md behind a symlinked ~/.claude/CLAUDE.md is denied` and `ok 62 Q-050 / N12: a per-file symlinked hook's checkout target is denied`; test 62 fails against 970e525 (the N12 gap), test 61 already passed there (the CLAUDE.md case came from `_HARD_FILE_TARGETS` at :103 before this diff).

**Evidence:** `guides/bare-host-hook-wiring.md:60-64`, `hooks/guard-trusted-writes.py:103`, `hooks/guard-trusted-writes.py:116-121`, `hooks/guard-trusted-writes.py:170-174`, `hooks/guard-trusted-writes.py:350-357`, `test/hooks/guard-trusted-writes.bats:616-639`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-new.log`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-old.log`

---

## Claim 2: "No deny rule names the checkout path, so deferring would leave it with no gate at all."

**Location:** `guides/bare-host-hook-wiring.md:65-66`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the deny list shipped in `hooks/wiring.json` on this branch; does not establish the contents of a user's hand-merged settings.json, and does not establish that the config-dir rules themselves match anything (Q-049, fixed on `answers-2026-09-20` at aa21535, outside this diff).
**Legibility-target:** for-orchestrator-synthesis

Every Edit/Write deny rule is spelled under `{{CLAUDE_DIR}}` or `~`; none names a checkout path:

```json
// hooks/wiring.json:120-127
      "Edit({{CLAUDE_DIR}}/settings*.json)",
      "Write({{CLAUDE_DIR}}/settings*.json)",
      "Edit({{CLAUDE_DIR}}/hooks/**)",
      "Write({{CLAUDE_DIR}}/hooks/**)",
      "Edit({{CLAUDE_DIR}}/CLAUDE.md)",
      "Write({{CLAUDE_DIR}}/CLAUDE.md)",
      "Edit(~/CLAUDE.md)",
      "Write(~/CLAUDE.md)"
```

**Evidence:** `hooks/wiring.json:115-128`

---

## Claim 3: "A hook deny has no approve option"

**Location:** `guides/bare-host-hook-wiring.md:66-67`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only that the hook emits `permissionDecision: "deny"` for these paths; does not establish how Claude Code presents a PreToolUse deny to the user (whether any override prompt exists).
**Legibility-target:** for-orchestrator-synthesis

The hook side is confirmed: `emit("deny", f"This path is a live protected policy file ...` (`hooks/guard-trusted-writes.py:354`). Whether the harness offers an approve path on a hook deny is Claude Code behavior outside the codebase (paraphrased — no quote available because the claim is about the external harness, not repo code). Verifying it needs a live Claude Code session or its hook documentation.

**Evidence:** `hooks/guard-trusted-writes.py:350-357`

---

## Claim 4: "Hooks installed as copies are not affected."

**Location:** `guides/bare-host-hook-wiring.md:68-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the checkout source of a regular-file copy in `~/.claude/hooks/` (clean and tainted: defer); does not establish the tainted behavior for a copied CLAUDE.md's source, which is SOFT (Claim 5).
**Legibility-target:** for-orchestrator-synthesis

A copy's `_safe_resolve` lands inside the config dir, not on the checkout file (`_t = _safe_resolve(_e)`, `hooks/guard-trusted-writes.py:118`), so the source never enters `_HARD_FILE_TARGETS`. Test 63 (`guard "$(file_payload Edit "$CHECKOUT/hooks/copied.py" sess1)"` then `assert_defer`, `test/hooks/guard-trusted-writes.bats:649-650`) passes. README installs the security hooks as copies (`cp ~/claude-workflows/hooks/guard-trusted-writes.py \`, `README.md:34`).

**Evidence:** `hooks/guard-trusted-writes.py:116-121`, `test/hooks/guard-trusted-writes.bats:641-651`, `README.md:32-37`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-new.log`

---

## Claim 5: "A regular-file COPY in ~/.claude leaves its source ungated."

**Location:** `hooks/guard-trusted-writes.py:31`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the HARD tier (a copy's source is never `hard-resolved`); does not hold for "ungated" in the broad sense — a copied CLAUDE.md's checkout source is still SOFT and asks in a tainted session.
**Legibility-target:** for-author

Test 64 pins the CLAUDE.md case as SOFT, not ungated:

```bash
# test/hooks/guard-trusted-writes.bats:659-662
  # It is still a CLAUDE.md, so a tainted session gets the SOFT ask.
  taint sess1
  guard "$(file_payload Edit "$CHECKOUT/global-instructions/CLAUDE.md" sess1)"
  assert_decision ask
```

Precise version: "leaves its source out of the HARD tier" (hook-script sources are fully ungated; CLAUDE.md sources remain SOFT).

**Evidence:** `hooks/guard-trusted-writes.py:22-31`, `hooks/guard-trusted-writes.py:178-187`, `test/hooks/guard-trusted-writes.bats:653-663`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-new.log`

---

## Claim 6a: "a worktree occurrence stays an indicator when its shell word has a `..` component or an expandable character ($ ` ~ \ * ? [ {)"

**Location:** `hooks/guard-trusted-writes.py:47-50` (docstring), `hooks/guard-trusted-writes.py:247-248` (comment), commit ccda554 body; same rule restated at `test/hooks/guard-trusted-writes.bats:519-520`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unquoted words (correct: e.g. `.claude/wt-foo/../hooks/x.sh` is still denied, test 57) and quote-split words (refuted); does not establish every other shell spelling (e.g. `$'…'`, which the `$` check catches only when unquoted-adjacent).
**Legibility-target:** for-author

The code's "word" is not the shell word. The scan stops at quote characters:

```python
# hooks/guard-trusted-writes.py:259-260
_WORD_DELIM = set(" \t\n\"'`;|&<>()")
_WT_UNSAFE = re.compile(r"[$`~\\*?\[{]|(^|[/=])\.\.(/|=|$)")
```

```python
# hooks/guard-trusted-writes.py:274-285 (excerpt ends :285; enclosing _neutralize_worktrees() continues to :290 — read)
    for m in _WT_SEG.finditer(cmd):
        s = m.start()
        while s > 0 and cmd[s - 1] not in _WORD_DELIM:
            s -= 1
        e = m.end()
        while e < len(cmd) and cmd[e] not in _WORD_DELIM:
            e += 1
        prefix, suffix = cmd[s:m.start()], cmd[m.end():e]
        if _WT_UNSAFE.search(prefix) or _WT_UNSAFE.search(suffix):
            continue
        if any(_is_home_or_cfg(p, m.group(0)) for p in {prefix, prefix.split("=", 1)[-1]}):
            continue
```

So in `.claude/wt-x'/..'/settings.json` the `/..` sits after a `'` and is outside the checked suffix; the shell concatenates it into one word. The same holds for `.claude/wt-x/.""./settings.json` (suffix `/.` passes `_WT_UNSAFE`). After neutralization no `.claude` remains, so `SETTINGS_OR_HOOKS` finds no `CFG_INDICATOR` partner and `bash_targets` returns None (`hooks/guard-trusted-writes.py:303-308`). Probe results (branch vs 970e525):

- `cd ~ && echo '{}' > .claude/wt-x'/..'/settings.json` → new=defer, old=deny
- `cd ~ && echo '{}' > .claude/wt-x/.""./settings.json` → new=defer, old=deny
- `echo '{}' > "$HOME"/.claude/wt-x"/../"settings.json` → new=defer, old=deny

Live effect under a temp HOME: the guard deferred on `cd ~ && echo '{"bypass":1}' > .claude/wt-x'/..'/settings.json` and on `mkdir -p "$HOME"/.claude/wt-y && echo '{"bypass":2}' > "$HOME"/.claude/wt-y"/../"settings.local.json`; bash exited 0 and wrote `{"bypass":1}` to `$HOME/.claude/settings.json` and `{"bypass":2}` to `$HOME/.claude/settings.local.json`. The second command is self-contained: `mkdir` is not a `WRITE_PRIMITIVE` alternative (`hooks/guard-trusted-writes.py:210-218`) and its quote-split `.claude/wt-y` is neutralized too. This is a HARD write (hook wiring + deny list) that 970e525 denied. The quoted-`.claude`-name gap in the N2 TODO (`hooks/guard-trusted-writes.py:196-198`) is a different spelling (quotes inside `.claude`/`hooks`); this one needs the unquoted `.claude` that previously triggered the deny, so the diff widens the known gap.

**Evidence:** `hooks/guard-trusted-writes.py:47-50`, `hooks/guard-trusted-writes.py:244-260`, `hooks/guard-trusted-writes.py:272-308`, `test/hooks/guard-trusted-writes.bats:549-561`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`

---

## Claim 6b: "…sits directly under the home dir, or overlaps the config dir" / "a prefix that is the home dir itself (`~/.claude/wt-x`, `$HOME/...`, the literal home path); a worktree path that equals, contains or lies inside the config dir"

**Location:** `hooks/guard-trusted-writes.py:49-50`, `hooks/guard-trusted-writes.py:249-251`, commit ccda554 body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unquoted spellings (correct; tests 58 and 60 pass) and quote-split / double-`=` spellings (refuted); does not establish reachability of HARD entries for the home-prefix residue alone (a `~/.claude/wt-x/...` target is not itself HARD unless combined with Claim 6a or a symlinked `wt-x`).
**Legibility-target:** for-author

The home/config test runs on the word-local prefix only:

```python
# hooks/guard-trusted-writes.py:265-270
def _is_home_or_cfg(path_prefix: str, seg: str) -> bool:
    if path_prefix and os.path.normpath(path_prefix) == os.path.normpath(str(HOME)):
        return True
    full = os.path.normpath(path_prefix + seg)
    return full.startswith("/") and any(_within(full, str(g)) or _within(str(g), full)
                                        for g in GLOBAL_DIRS)
```

With a quote before `/.claude`, the prefix is just `/`; with `a=b=<home>/`, `prefix.split("=", 1)[-1]` (`:284`) is `b=<home>/`, not the home path. Probe results:

- `echo x > "$HOME"/.claude/wt-x/settings.json` → new=defer, old=deny
- `echo x > "<literal home>"/.claude/wt-x/settings.json` → new=defer, old=deny
- `echo x > a=b=<literal home>/.claude/wt-x/settings.json` → new=defer, old=deny
- `dd of=<literal home>/.claude/wt-x/settings.json` → deny (single `=`, handled)
- With `CLAUDE_CONFIG_DIR=<tmp>/srv/repo/.claude/wt-cfg`: `echo x > <cfg>/settings.json` → deny, but `echo x > "<tmp>/srv/repo"/.claude/wt-cfg/settings.json` → new=defer, old=deny. That last one is a direct HARD write (the configured config dir's settings.json) with no `..` involved.

Related observation (not a refutation): when HOME is the worktree's parent (a `HOME=/workspace`-style layout), absolute worktree paths are always denied (`<home>/.claude/wt-guard/hooks/x.sh` → deny) while relative ones are exempt (`echo x > .claude/wt-guard/hooks/x.sh` → defer), because the worktree then lies inside the config dir.

**Evidence:** `hooks/guard-trusted-writes.py:262-290`, `test/hooks/guard-trusted-writes.bats:563-577`, `test/hooks/guard-trusted-writes.bats:593-597`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe2.log`

---

## Claim 7: "`=` is NOT a boundary: `a=/../x` is one path, so the whole word is checked, and an assignment's value (after the first `=`) is additionally checked on its own for the home / config-dir tests."

**Location:** `hooks/guard-trusted-writes.py:256-258`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the delimiter set and the single-split value check as described; does not establish that checking only the text after the first `=` is sufficient (a second `=` defeats the home test — Claim 6b).
**Legibility-target:** for-orchestrator-synthesis

`=` is absent from `_WORD_DELIM = set(" \t\n\"'`;|&<>()")` (`:259`), `_WT_UNSAFE` matches `(^|[/=])\.\.(/|=|$)` (`:260`), and the value is taken with `prefix.split("=", 1)[-1]` (`:284`). Probe: `echo x > a=/../.claude/wt-x/hooks/x` → deny; `dd of=<home>/.claude/wt-x/settings.json` → deny.

**Evidence:** `hooks/guard-trusted-writes.py:256-260`, `hooks/guard-trusted-writes.py:284`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`

---

## Claim 8: "bash_targets() first neutralizes agent worktree segments … Other .claude occurrences are untouched." (brief item 2: neutralization cannot create or hide a HARD_FRAG match and runs before every indicator check)

**Location:** `hooks/guard-trusted-writes.py:292-308`, commit ccda554 body
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ordering within `bash_targets` and the textual non-interaction of the replacement with `HARD_FRAG`; does not establish that `_WT_SEG` matches only real worktree paths (it has no left boundary, so `/srv/foo.claude/wt-x/hooks/x` is also neutralized — probe: new=defer, old=deny; that string is not the config dir either way).
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:292-298 (excerpt ends :298; enclosing bash_targets() continues to :308 — read)
def bash_targets(cmd: str):
    has_write = bool(WRITE_PRIMITIVE.search(cmd))
    if not has_write:
        return None
    cmd = _neutralize_worktrees(cmd)
    if HARD_FRAG.search(cmd):
        return "hard"
```

All later checks (`CLAUDE_MD`/`HOME_INDICATOR` :300, `SETTINGS_OR_HOOKS`/`CFG_INDICATOR` :303, `SOFT_FRAG` :306) use the rebound `cmd`. The replacement token `AGENT_WORKTREE` contains no `.claude`, so it cannot create a `HARD_FRAG` (`\.claude/hooks(/|\b)|\.claude/settings|managed-settings`, `:239`) match; `_WT_SEG` requires `wt-` or `worktrees/` immediately after `.claude/` (`:254`), so it cannot consume a `.claude/hooks` or `.claude/settings` occurrence. `.claude/wt-x/settings.json` never matched `HARD_FRAG` before the diff either (it was denied via `CFG_INDICATOR`), so neutralization hides no `HARD_FRAG` match; the `..` spelling `.claude/wt-x/../settings.json` stays un-neutralized (test 57). The regressions found are in the indicator tests, via Claims 6a/6b.

**Evidence:** `hooks/guard-trusted-writes.py:239`, `hooks/guard-trusted-writes.py:253-255`, `hooks/guard-trusted-writes.py:292-308`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`

---

## Claim 9: "N15: do not point at the config-dir spelling: permissions.deny blocks it." / "both deny reasons now say to make the change outside Claude, instead of pointing at the ~/.claude spelling"

**Location:** `hooks/guard-trusted-writes.py:331-335`, `hooks/guard-trusted-writes.py:353-357`, commit ccda554 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text of both deny reasons; does not establish that "your own editor or shell" is outside every sandbox the user runs (a Claude-launched shell is not "outside Claude").
**Legibility-target:** for-orchestrator-synthesis

The file-tool reason: `"symlink), so Claude's file tools cannot edit it. Make the change outside "` / `"Claude, in your own editor or shell, and review it there."` (`:356-357`). The Bash reason: `"Claude cannot write these: make the change outside Claude, in your own "` (`:332`). Neither names an editable path; the old `"~/.claude path, with review."` string is gone. Test 65 asserts `!= *"~/.claude path"*` and `== *"outside Claude"*` for both and passes (fails on 970e525).

**Evidence:** `hooks/guard-trusted-writes.py:331-335`, `hooks/guard-trusted-writes.py:353-357`, `test/hooks/guard-trusted-writes.bats:665-676`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-new.log`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-old.log`

---

## Claim 10: "If the command only mentions such a path in prose (a heredoc or message), write that text with the Write tool and pass the file instead."

**Location:** `hooks/guard-trusted-writes.py:333-335`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a Write to a non-policy temp path and passing it via `git commit -F` / `gh pr create --body-file`; does not establish the case where the chosen file path is itself a policy path, or where the passing command still carries the prose inline.
**Legibility-target:** for-orchestrator-synthesis

The hook inspects only `file_path` for the Write tool (`fp = ti.get("file_path") or ti.get("path") or ""`, `:342`), not the content. Probe: Write to `<tmp>/msg.txt` → defer; `git commit -F <tmp>/msg.txt` → defer; `gh pr create --body-file <tmp>/msg.txt` → defer; the heredoc form `cat > /tmp/m <<'E'\nsee ~/.claude/CLAUDE.md\nE` → deny.

**Evidence:** `hooks/guard-trusted-writes.py:341-361`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`

---

## Claim 11: "on a bare host ~/.claude/hooks is a REAL dir whose entries can be per-file symlinks into the checkout (README setup). Resolving only the directory misses them, so resolve each entry: a checkout file that IS a live hook is HARD (resolved tier -> deny). A regular-file copy resolves into the config dir itself, which leaves its checkout original ungated, as intended."

**Location:** `hooks/guard-trusted-writes.py:111-115`, commit ccda554 body
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-file links, copies, a `hooks` that is itself a directory symlink, a directory-valued entry and a dangling entry; does not establish the README's per-file loop as the only layout in use.
**Legibility-target:** for-author

The per-file and copy halves hold (Claims 1, 4; README links hooks one file at a time: `ln -s ~/claude-workflows/hooks/$h ~/.claude/hooks/$h`, `README.md:29`). The comment says "a checkout file", but the loop also registers directories:

```python
# hooks/guard-trusted-writes.py:119
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
```

Probe results:
- entry `hooks/lib -> <checkout>/hooks/lib`: Edit `<checkout>/hooks/lib/util.py` → deny, and Edit of a not-yet-existing `<checkout>/hooks/lib/new.py` → deny (old: defer, defer).
- entry `hooks/root -> <checkout>` (checkout root): Edit `<checkout>/README.md` → deny (old: defer). One directory link makes its whole target tree HARD.
- dangling `hooks/gone.sh -> <checkout>/hooks/gone.sh`: Edit of that target → deny (old: defer). `resolve()` is non-strict, so the missing target is registered as a file.
- `hooks` itself a symlink into an `/opt`-like payload: `<opt>/hooks/g.py` and `<opt>/hooks/new.py` → deny on both old and new (the pre-existing `_HARD_DIR_TARGETS` entry at `:110` already covers it; the loop adds only redundant entries).

Precise version: "resolve each entry; a checkout file or directory that is a live hook entry is HARD, including dangling link targets."

**Evidence:** `hooks/guard-trusted-writes.py:110-121`, `hooks/guard-trusted-writes.py:173-174`, `README.md:26-37`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`

---

## Claim 12: "An unexpanded relative worktree path (cd ~ && ... .claude/wt-x/...) is exempt, which only reaches ~/.claude/wt-x, not a HARD entry."

**Location:** commit ccda554 body (Notes)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `cd ~ && … .claude/wt-x…` shape with quote-split and empty-quote `..` spellings (refuted) and the plain `.claude/wt-x/<file>` spelling (lexically true); does not establish behavior when `~/.claude/wt-x` is a symlink (which would also reach HARD; creating it via `ln -s` is an ungated A8 primitive).
**Legibility-target:** for-author

Exemption confirmed: `cd ~ && echo x > .claude/wt-a/hooks/x` → new=defer (old=deny). But the same shape reaches a HARD entry: `cd ~ && echo '{"bypass":1}' > .claude/wt-x'/..'/settings.json` was deferred by the branch hook, and bash wrote `{"bypass":1}` to `$HOME/.claude/settings.json` in the temp HOME. The quote-split mechanism is in Claim 6a (paraphrased — no quote available because it is the same `_WORD_DELIM` code quoted there).

**Evidence:** `hooks/guard-trusted-writes.py:259-260`, `hooks/guard-trusted-writes.py:272-290`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`

---

## Claim 13: "A worktree path next to `global-instructions` is still denied (that is a separate indicator, outside Q-048 [2])."

**Location:** commit ccda554 body (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a CLAUDE.md write under `<worktree>/global-instructions/`; does not establish the case of `global-instructions` naming a non-CLAUDE.md file (that rule pairs only with `CLAUDE_MD`).
**Legibility-target:** for-orchestrator-synthesis

`r"global-instructions"` is in `_HOME_INDICATORS` (`:226`) and survives neutralization; `if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):` (`:300`) fires. Probe: `echo x > /srv/repo/.claude/wt-foo/global-instructions/CLAUDE.md` → deny.

**Evidence:** `hooks/guard-trusted-writes.py:225-226`, `hooks/guard-trusted-writes.py:300-301`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`

---

## Claim 14: "Per-file link targets are read at hook load, like the other target sets."

**Location:** commit ccda554 body (Notes)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the loop runs at module import alongside `_HARD_FILE_TARGETS`/`_HARD_DIR_TARGETS`; does not establish from repo code that Claude Code spawns a fresh process per hook call (the wiring runs it as a command, which implies it, but the harness is external).
**Legibility-target:** for-orchestrator-synthesis

The loop is module-level code (`for _e in (CONFIG_DIR / "hooks").iterdir():`, `:117`), next to the other module-level target sets (`:103-110`). The wiring invokes it as a fresh command: `"command": "python3 {{CLAUDE_DIR}}/hooks/guard-trusted-writes.py"` (`hooks/wiring.json:55`).

**Evidence:** `hooks/guard-trusted-writes.py:96-121`, `hooks/wiring.json:55`

---

## Claim 15: "Red against 970e525: tests 54, 55, 56 (worktree allow), 62 (N12) and 65 (N15) fail; the rest are regression pins that already pass" (commit adds "12 tests")

**Location:** commit 456bded body; `test/hooks/guard-trusted-writes.bats:517-676`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full 70-test suite against both hook versions; does not establish that the regression pins (57-61, 63-64) catch the quote-split spellings in Claims 6a/6b (they do not include any).
**Legibility-target:** for-orchestrator-synthesis

The diff adds tests numbered 54-65 (12 tests). Against the branch hook: `1..70`, all `ok`, exit 0. Against the 970e525 hook the only failures are:

```
not ok 54 Q-048: a Bash write into a .claude/wt-* worktree's hooks/ is not denied
not ok 55 Q-048: a Bash write into a .claude/worktrees/<name> worktree's hooks/ is not denied
not ok 56 Q-048: a worktree CLAUDE.md write is SOFT (defer; ask when tainted), not denied
not ok 62 Q-050 / N12: a per-file symlinked hook's checkout target is denied
not ok 65 N15: the resolved-path deny reason does not send the user to a denied path
```

Compared with the logged "test-count denominator" hallucination pattern (first seen 2026-09-12): no match — the stated count and red set are exact.

**Evidence:** `test/hooks/guard-trusted-writes.bats:517-676`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-new.log`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-old.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6a** (`hooks/guard-trusted-writes.py:47-50, 247-248`): the "shell word" the `..`/expandable check scans stops at quotes, so `.claude/wt-x'/..'/settings.json` and `"$HOME"/.claude/wt-x"/../"settings.json` are exempt; executed in a temp HOME, one self-contained command wrote `~/.claude/settings.local.json` with the guard deferring (970e525 denied it). Regression, and it reaches HARD.
- **Claim 6b** (`hooks/guard-trusted-writes.py:49-50, 249-251`): the home / config-dir tests are also defeated by a quote before `/.claude` or a second `=`; with a wt-shaped `CLAUDE_CONFIG_DIR`, `"<parent>"/.claude/wt-cfg/settings.json` is a direct HARD write that now defers.
- **Claim 12** (commit ccda554 Notes): "only reaches ~/.claude/wt-x, not a HARD entry" is false for the quote-split `..` spelling of the same `cd ~ && … .claude/wt-x…` shape.

### Mostly Accurate
- **Claim 5** (`hooks/guard-trusted-writes.py:31`): a copied CLAUDE.md's source is SOFT (asks when tainted), not "ungated"; say "out of the HARD tier".
- **Claim 11** (`hooks/guard-trusted-writes.py:111-115`): the loop registers directory entries and dangling targets too, so a directory link makes its whole target tree HARD; the comment says only "a checkout file".

### Unverifiable
- **Claim 3** (`guides/bare-host-hook-wiring.md:66-67`): "a hook deny has no approve option" is Claude Code harness behavior; needs a live session or the harness hook docs.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 035869c` line.
- Answered: yes
- Out of scope: the deferred N2/A8 items (not re-filed; Claim 6a notes only that this diff widens N2); code-quality judgments on the fix shape.
- Escalate: Claim 6a/12, a regression that reaches a HARD path (`~/.claude/settings*.json`) through a quote-split `..` next to a worktree segment, with a self-contained repro; the regression pins do not cover quoted spellings.
