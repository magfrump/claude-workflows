Commit: 835f99d

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-guard (branch `ans/guard-q048-q050`)
**Scope:** branch diff `970e525..835f99d` (5 commits): `guides/bare-host-hook-wiring.md`, `hooks/guard-trusted-writes.py`, `test/hooks/guard-trusted-writes.bats`, plus the five commit messages. Full re-review after the 835f99d fix.
**Checked:** 2026-09-23
**Total claims checked:** 18 (16 numbered; Claim 6 split into 6a/6b/6c)
**Summary:** 10 verified, 4 mostly accurate, 2 stale, 2 incorrect, 0 unverifiable

Execution provenance for every `executed` claim: logs and probe scripts are copied to `docs/reviews/execution-logs/gfc-rr-r1/` (originals in the session scratchpad `gfc-rr-r1/`). All probes ran the hook as `python3 <hook>` with a temp `HOME` and temp `CC_WEB_TAINT_DIR` and a real `git worktree add` fixture; nothing touched the real `~/.claude`. Old hooks were taken with `git show <rev>:hooks/guard-trusted-writes.py`. Runs were made 2026-09-23T23:46Z–23:48Z.

- `run_bats.sh <label> <hook-rev> [<test-rev>]` → `bats-*.txt` (cwd = a copy tree under `gfc-rr-r1/trees/<label>`)
- `probe.py` → `probe1.txt`; `probe2.py` → `probe2.txt` (cwd = `gfc-rr-r1/`)
- `e2e.sh` → `e2e.txt` (it runs the hook, then actually runs the command under the fake HOME and shows where the bytes landed)

Hallucination-pattern log read; no claim below matches a logged pattern.

---

## Claim 1: "While a global file is symlinked into `~/.claude`, the guard **denies** Claude's file tools on its checkout copy, in a tainted session or not: `global-instructions/CLAUDE.md` behind a linked `~/.claude/CLAUDE.md`, and every `hooks/<name>` linked one file at a time into `~/.claude/hooks/`."

**Location:** `guides/bare-host-hook-wiring.md:59-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Edit/Write/MultiEdit on the checkout CLAUDE.md and on a checkout hook that is a top-level per-file link in a real `~/.claude/hooks/`, clean and tainted; does not establish anything for Bash writes to those checkout hook paths (they get no opinion, see Claim 5), nor for a link placed inside a real subdirectory of `~/.claude/hooks/` (`iterdir()` is not recursive).
**Legibility-target:** for-orchestrator-synthesis

The resolved tier catches both: `_HARD_FILE_TARGETS` holds the resolved `CONFIG_DIR / "CLAUDE.md"` (`hooks/guard-trusted-writes.py:109`) and the new loop adds each hooks entry's target:

```python
# hooks/guard-trusted-writes.py:123-128
try:
    for _e in (CONFIG_DIR / "hooks").iterdir():
        _t = _safe_resolve(_e)
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
except Exception:
    pass
```

`classify_path` returns `"hard-resolved"` on `rp in _HARD_FILE_TARGETS` (`:180-181`), and `main()` emits `deny` for that tier with no taint condition (`:386-393`). Executed: bats tests 69 and 70 pass at HEAD and 70 fails at 970e525; probe1 rows `N12 edit linked hook` → `HEAD=deny BASE=defer`, and the same row tainted → `deny`.

**Evidence:** `hooks/guard-trusted-writes.py:109`, `hooks/guard-trusted-writes.py:123-128`, `hooks/guard-trusted-writes.py:180-181`, `hooks/guard-trusted-writes.py:386-393`, `test/hooks/guard-trusted-writes.bats:721-744`, `docs/reviews/execution-logs/gfc-rr-r1/bats-head.txt`, `docs/reviews/execution-logs/gfc-rr-r1/bats-base.txt`, `docs/reviews/execution-logs/gfc-rr-r1/probe1.txt`

---

## Claim 2: "No deny rule names the checkout path, so deferring would leave it with no gate at all."

**Location:** `guides/bare-host-hook-wiring.md:64-65`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the deny list shipped in `hooks/wiring.json`; does not establish the contents of a user's hand-merged settings, and (context, off this branch) aa21535/Q-049 found the single-slash `{{CLAUDE_DIR}}` forms matched nothing, which only strengthens the statement.
**Legibility-target:** for-orchestrator-synthesis

Every Edit/Write deny rule is anchored at the config dir or `~/CLAUDE.md`:

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

## Claim 3: "A hook deny has no approve option, so make these edits outside Claude, in your own editor or shell (Q-050). Hooks installed as copies are not affected."

**Location:** `guides/bare-host-hook-wiring.md:65-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file tools on a copied hook's checkout source (defer, clean and tainted); does not establish that Claude as a whole cannot edit a *linked* hook's checkout file — its Bash tool can, with no opinion (Claim 5).
**Legibility-target:** for-orchestrator-synthesis

A copy's entry resolves to itself inside the config dir, so its checkout source never enters `_HARD_FILE_TARGETS` (`hooks/guard-trusted-writes.py:125` quoted in Claim 1). Executed: bats test 71 ("a repo hook file with no link into ~/.claude/hooks is not denied") passes at HEAD, asserting `assert_defer` for `$CHECKOUT/hooks/copied.py` clean and tainted (`test/hooks/guard-trusted-writes.bats:746-756`).

**Evidence:** `hooks/guard-trusted-writes.py:123-128`, `test/hooks/guard-trusted-writes.bats:746-756`, `docs/reviews/execution-logs/gfc-rr-r1/bats-head.txt`

---

## Claim 4: "A regular-file COPY in ~/.claude leaves its source out of the HARD tier: a copied hook's source is ungated, a copied CLAUDE.md's source is SOFT (ask when tainted)."

**Location:** `hooks/guard-trusted-writes.py:31-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file-tool tier for a copied hook and a copied `~/.claude/CLAUDE.md`; does not cover Bash writes to either source.
**Legibility-target:** for-orchestrator-synthesis

The copied-CLAUDE.md source falls to the SOFT name match `if name in ("claude.md", ...)` (`hooks/guard-trusted-writes.py:190-192`). Executed: bats tests 71 and 72 pass at HEAD (72 asserts `assert_defer` clean, `assert_decision ask` tainted at `test/hooks/guard-trusted-writes.bats:758-768`). This closes pass-1's wording finding (the ccda554 text said "ungated" for both).

**Evidence:** `hooks/guard-trusted-writes.py:31-33`, `hooks/guard-trusted-writes.py:190-192`, `test/hooks/guard-trusted-writes.bats:746-768`, `docs/reviews/execution-logs/gfc-rr-r1/bats-head.txt`

---

## Claim 5: "For Bash, which deny rules don't cover at all, HARD is \"deny\" outright." (read with the resolved-tier list above it, which now includes "a hook script linked one file at a time into a real ~/.claude/hooks/ (N12)")

**Location:** `hooks/guard-trusted-writes.py:22-34`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Bash writes to the two N12/Q-050 checkout targets; does not establish anything about other Bash write forms (N2/A8 residuals, deferred).
**Legibility-target:** for-author

The resolved-tier list (which now names the per-file linked hook checkout target) is enforced only for the file tools: `bash_targets()` classifies by text and never consults `_HARD_FILE_TARGETS` (`hooks/guard-trusted-writes.py:328-344`, read in full). A Bash write to a linked hook's checkout path carries no `.claude` indicator, so it gets no opinion, clean or tainted. Executed (probe1): `echo x > <checkout>/hooks/linked.sh` → `HEAD=defer BASE=defer`, tainted `defer`; `cp /tmp/a <checkout>/hooks/lib/util.sh` → same. The checkout CLAUDE.md is covered in Bash (`global-instructions` is a HOME indicator: `_HOME_INDICATORS = [..., r"global-instructions", ...]` at `:232-233`) → `deny`. This is brief item 0b: the gap is not new (970e525 also deferred), but it is stated nowhere — the N2 TODO lists only the installed-layout analogue, `#   - \`/opt/claude-workflows/hooks/...\` (the payload, by its real path);` (`:206`), and the guide says to edit "outside Claude" without noting Claude's Bash is ungated there. Precise version: "the resolved tier is file-tools-only; a Bash write to a linked hook's checkout path is not gated (add it to the N2 list)".

**Evidence:** `hooks/guard-trusted-writes.py:22-34`, `hooks/guard-trusted-writes.py:198-210`, `hooks/guard-trusted-writes.py:232-233`, `hooks/guard-trusted-writes.py:328-344`, `docs/reviews/execution-logs/gfc-rr-r1/probe1.txt`

---

## Claim 6a: "An agent worktree path (`.claude/wt-<name>`, `.claude/worktrees/<name>`) is not a `.claude` indicator ONLY when its whole shell word is an absolute path with no quote, expandable character or `..`, and its worktree root exists at hook time as a real, unsymlinked git worktree (a `.git` file) clear of the config dir, ~/.claude and HOME" — i.e. every pass-1 bypass is closed

**Location:** `hooks/guard-trusted-writes.py:49-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-word conditions as implemented and every pass-1 route (quote-split `..`, quote before `/.claude`, second `=`, quoted wt-shaped CLAUDE_CONFIG_DIR parent, symlinked root, symlink inside a worktree leading out), plus `//`, `/./`, trailing `/.`, leading `//`, `=`-prefixed words and globs; does not establish that the command as a whole stays inside the worktree — words *other than* the exempt one can still move relative to it (Claim 6b), and a root replaced by the same command is seen as it was (Claim 6c). Case-insensitive filesystems and bind mounts were not executable here (Linux sandbox, no mount privilege).
**Legibility-target:** for-orchestrator-synthesis

Implementation (functions read in full, `:280-326`):

```python
# hooks/guard-trusted-writes.py:303-309
def _exempt_worktree(word: str, root: str) -> bool:
    if _WT_UNSAFE.search(word) or not word.startswith("/"):
        return False
    root = os.path.normpath(root)
    if not _real_worktree_root(root):
        return False
    return _within(os.path.realpath(word), root)
```

`_real_worktree_root` rejects a symlinked root or ancestor (`if os.path.realpath(root) != root: return False`, `:289`), requires a non-link `.git` file (`:291-293`), rejects roots equal to/inside/containing `GLOBAL_DIRS`, `~/.claude` and its realpath (`:296-299`), and roots containing HOME (`:300-301`). `bash_targets` neutralizes before every indicator test (`cmd = _neutralize_worktrees(cmd)` at `:332`, ahead of `HARD_FRAG`/`CLAUDE_MD`/`SETTINGS_OR_HOOKS`/`SOFT_FRAG` at `:333-343`); the replacement token `AGENT_WORKTREE` cannot itself match any indicator regex, and it can only hide text inside a real worktree root.

Executed: all 78 bats tests pass at HEAD; with the HEAD tests against the ccda554/035869c hook, tests 57-62 and 64 fail (the pass-1 routes), so the fix closes them. probe1: `<repo>/.claude/wt-foo/hooks/x.sh`, `<repo>//.claude/...`, `/./` → `HEAD=defer` (exempt, writes the worktree); leading `//`, `of=`, `--target-directory=`, `hooks/*.sh` → `deny` (not exempt). Note: the `.git` requirement is only "a regular file named `.git`" — it is not checked against `git worktree list`, so an agent-created `.git` file qualifies; this does not widen reach, because the root must still be a real non-config directory and the word's realpath must stay inside it.

**Evidence:** `hooks/guard-trusted-writes.py:49-56`, `hooks/guard-trusted-writes.py:272-344`, `test/hooks/guard-trusted-writes.bats:573-700`, `docs/reviews/execution-logs/gfc-rr-r1/bats-head.txt`, `docs/reviews/execution-logs/gfc-rr-r1/bats-tf48-hccda.txt`, `docs/reviews/execution-logs/gfc-rr-r1/probe1.txt`

---

## Claim 6b: "a `..` escape … still denied" (456bded message; Q-048 [2] intent that `..` escapes stay denied; docstring: exempt only when the word has "no `..` component … Every other `.claude` in the command still counts")

**Location:** `hooks/guard-trusted-writes.py:255-271`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `..` placed in a separate shell word after `cd` into an exempt absolute worktree (`cd <abs wt> && cd .. && …`), which reaches the **parent project's** `.claude/` (settings*.json, hooks/); does not reach the global config dir (a root inside `~/.claude` or the config dir is never exempt, `:296-299`), and the `..`-in-the-same-word form is correctly denied (test 67).
**Legibility-target:** for-author

The `..` test looks only at the word that holds the worktree segment: `_WT_UNSAFE = re.compile(r"[\"'$`~\\*?\[{]|(^|/)\.\.(/|$)")` (`:278`) is applied to `cmd[s:e]` for each `_WT_SEG` match (`:313-320`). A later `cd ..` is a different word with no `.claude` in it, so it is never examined, and once the worktree's `.claude` is neutralized nothing else in the command is an indicator. The relative `settings.json`/`hooks/x.sh` that follows then lands in `<repo>/.claude/`. Executed:

- probe2: `cd <repo>/.claude/wt-foo && cd .. && echo '{}' > settings.json` → `HEAD=defer BASE=deny`, **tainted too** (`HEAD=defer`); same for `… && echo x > hooks/x.sh` and `cd <wt>; cd ../; cp /tmp/a settings.local.json`. Control: `cd <repo>/.claude && echo '{}' > settings.json` → `deny`; the Edit tool on the same `<repo>/.claude/settings.json` → `ask` when tainted.
- e2e: the hook emitted no output, then the command ran and `<repo>/.claude/settings.json` contained `{"hooks":"PWNED"}`.

So after this diff a web-tainted session can rewrite a project's own hook wiring through Bash with no prompt, where 970e525 denied it and the file-tool tier asks. None of the 22 new tests covers a `cd` into a worktree followed by a relative `..` (test 67's `cd $REPO/.claude/worktrees/.. && …` does not match `_WT_SEG`, whose worktrees name cannot start with `.`).

**Evidence:** `hooks/guard-trusted-writes.py:255-278`, `hooks/guard-trusted-writes.py:311-344`, `test/hooks/guard-trusted-writes.bats:652-665`, `docs/reviews/execution-logs/gfc-rr-r1/probe2.txt`, `docs/reviews/execution-logs/gfc-rr-r1/e2e.txt`

---

## Claim 6c: "and neither is a worktree the same command creates or symlinks: it does not exist when the hook runs."

**Location:** `hooks/guard-trusted-writes.py:55-56`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The "creates" half holds (a new root does not exist at hook time, test 62's `ln -s . .claude/wt-q` is denied); the "symlinks" half fails when the command *replaces an existing* worktree root with a symlink (`rm -rf <wt> && ln -s … <wt>`), since the hook sees the real worktree. Reach is bounded to targets the rest of the command can name without an indicator — in practice N2-class spellings (bare `cd`, `$(cd;pwd)`); `~`/`$HOME` still trip the HOME indicator.
**Legibility-target:** for-author

The root test runs once, at hook time (`if os.path.islink(root) or not os.path.isdir(root):` at `:287`); nothing re-validates it after earlier parts of the same command run. Executed: probe1 `rm -rf <wt> && ln -s "$(cd;pwd)" <wt> && echo x > <wt>/CLAUDE.md` → `HEAD=defer BASE=deny`; the `ln -s ~ …` variant → `deny`. e2e ran the first form under the fake HOME: the hook gave no output and `~/CLAUDE.md` then contained `PWNED` (a HARD file; tainted it gets the SOFT ask, the same outcome as N2's `cd; echo x > CLAUDE.md`). The same time-of-check gap applies across calls (a background `sleep; rm; ln` issued earlier contains no write primitive, so it is not gated — A8 class). Precise version: "…nor a worktree the same command creates; a worktree the command replaces is judged as it was at hook time (residual)".

**Evidence:** `hooks/guard-trusted-writes.py:55-56`, `hooks/guard-trusted-writes.py:283-301`, `docs/reviews/execution-logs/gfc-rr-r1/probe1.txt`, `docs/reviews/execution-logs/gfc-rr-r1/e2e.txt`

---

## Claim 7: "N12 / Q-050: … resolve each entry: a checkout file that IS a live hook is HARD (resolved tier -> deny). A regular-file copy resolves into the config dir itself, which leaves its checkout original out of the HARD tier, as intended (a CLAUDE.md original still falls to SOFT and asks when tainted)."

**Location:** `hooks/guard-trusted-writes.py:117-122`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-file links, copies, a directory-valued entry, a dangling entry, and `hooks` itself a symlink (installed layout); does not cover links nested in a real subdirectory (not recursed). Pass-1 raised the same residue; 835f99d fixed only the copy wording.
**Legibility-target:** for-author

The loop (quoted in Claim 1, `:123-128`) also registers directories and missing targets, which the comment's "a checkout file" does not say. Executed: probe1 `hooks/lib -> <checkout>/hooks/lib` → Edit `<checkout>/hooks/lib/util.sh` `HEAD=deny BASE=defer`; dangling `hooks/dangling.sh -> <checkout>/hooks/gone.sh` → Edit of the target `deny`; probe2 `hooks/ck -> <whole checkout>` → Edit `<ck>/src/x.py` `deny` (one directory link makes its whole tree HARD). With `hooks` itself a symlink (installed layout), probe2 shows payload files denied at HEAD and base alike — the loop only adds redundant entries. Each hook call is a new process (`"command": "python3 {{CLAUDE_DIR}}/hooks/guard-trusted-writes.py"`, `hooks/wiring.json:55`), so the load-time scan is fresh per call. Precise version: "a checkout file or directory that is a live hooks entry, including a dangling link's target, is HARD".

**Evidence:** `hooks/guard-trusted-writes.py:117-128`, `hooks/wiring.json:55`, `docs/reviews/execution-logs/gfc-rr-r1/probe1.txt`, `docs/reviews/execution-logs/gfc-rr-r1/probe2.txt`

---

## Claim 8: "the word, resolved, stays inside the root (a symlink inside the worktree that leads out of it is not exempt; one created by the same command is a residual)."

**Location:** `hooks/guard-trusted-writes.py:268-270`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a pre-existing out-leading symlink (denied) and the disclosed same-command residual (confirmed); does not establish anything about hard links to files outside the worktree (pre-existing hard links are invisible to `realpath`; creating one needs the target named).
**Legibility-target:** for-orchestrator-synthesis

`return _within(os.path.realpath(word), root)` (`:309`). Executed: bats test 64 passes (pre-existing `cfg -> ~/.claude` denied); probe1 `ln -s "$(cd;pwd)" <wt>/h && echo x > <wt>/h/CLAUDE.md` → `HEAD=defer BASE=deny` — the residual the comment names (reach again limited to N2-class spellings; the `ln -s ~` form → `deny`).

**Evidence:** `hooks/guard-trusted-writes.py:268-270`, `hooks/guard-trusted-writes.py:303-309`, `test/hooks/guard-trusted-writes.bats:645-650`, `docs/reviews/execution-logs/gfc-rr-r1/probe1.txt`

---

## Claim 9: Bash deny reason "Claude cannot write these: make the change outside Claude, in your own editor or shell, and review it there. If the command only mentions such a path in prose (a heredoc or message), write that text with the Write tool and pass the file instead." and file-tool reason "… Make the change outside Claude, in your own editor or shell, and review it there." (N15)

**Location:** `hooks/guard-trusted-writes.py:367-371`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both deny messages naming no path and the advised Write-then-pass route being allowed for an ordinary temp file; does not establish the route for a prose file whose own name is policy-shaped (e.g. `…/CLAUDE.md`, SOFT).
**Legibility-target:** for-orchestrator-synthesis

Neither message names a config-dir spelling (file-tool text at `:390-393`: `"This path is a live protected policy file ({Path(fp).name}: a global "`). Executed: bats test 73 passes (asserts `!= *"~/.claude path"*` and `== *"outside Claude"*` for both tiers); probe1 Write of `<T>/msg.txt` → `defer`, and `git commit -F <T>/msg.txt` → `defer` (no write primitive).

**Evidence:** `hooks/guard-trusted-writes.py:367-371`, `hooks/guard-trusted-writes.py:386-393`, `test/hooks/guard-trusted-writes.bats:770-781`, `docs/reviews/execution-logs/gfc-rr-r1/probe1.txt`

---

## Claim 10: "Interpretation call: 'not inside HOME' was read as 'root does not equal or contain HOME, and is not inside ~/.claude', so a project worktree under ~/code/... stays exempt"

**Location:** commit `835f99d` message (Notes)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers hooks/settings and CLAUDE.md writes into a real worktree at `~/code/repo/.claude/wt-x`, and a HOME that is the repo; does not change any gate's strength (the shortfall is a false positive, not a bypass).
**Legibility-target:** for-author

The root rule is as stated (`return not any(_within(h, root) for h in home)`, `hooks/guard-trusted-writes.py:300-301`), and hooks/settings writes there are exempt (probe2 → `HEAD=defer BASE=deny`). But a CLAUDE.md write into that worktree is still denied: the word keeps the literal home prefix, which is a HOME indicator (`for _lit in {str(HOME).rstrip("/"), ...}: _HOME_INDICATORS.append(re.escape(_lit))`, `:237-239`), and `CLAUDE_MD` + HOME indicator is HARD (`:336-337`). probe2 `echo x >> <home2>/code/repo/.claude/wt-x/CLAUDE.md` → `HEAD=deny`. The branch's own CLAUDE.md-is-SOFT test uses a repo outside HOME (`test/hooks/guard-trusted-writes.bats:564-571`). With HOME equal to the repo (`HOME=/workspace` style), probe2 confirms the worktree is never exempt (inside `~/.claude`). Precise version: "…stays exempt for hooks/settings; a CLAUDE.md in it is still denied by the home-path indicator".

**Evidence:** `hooks/guard-trusted-writes.py:237-243`, `hooks/guard-trusted-writes.py:300-301`, `hooks/guard-trusted-writes.py:336-337`, `docs/reviews/execution-logs/gfc-rr-r1/probe2.txt`

---

## Claim 11: "An unexpanded relative worktree path (cd ~ && ... .claude/wt-x/...) is exempt, which only reaches ~/.claude/wt-x, not a HARD entry."

**Location:** commit `ccda554` message (Notes)
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim at HEAD; does not re-judge ccda554 in isolation (pass-1 showed it was already false there: `.claude/wt-q` symlinked to `.` reached settings.json).
**Legibility-target:** for-author

835f99d made relative paths non-exempt (`or not word.startswith("/")`, `hooks/guard-trusted-writes.py:304`), and its message says so. Executed: bats test 57 (`cd $REPO && echo x > .claude/wt-foo/settings.json` → deny) passes at HEAD.

**Evidence:** `hooks/guard-trusted-writes.py:303-305`, `test/hooks/guard-trusted-writes.bats:573-578`, `docs/reviews/execution-logs/gfc-rr-r1/bats-head.txt`

---

## Claim 12: "Copies resolve into the config dir and leave their source ungated."

**Location:** commit `ccda554` message
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the copied-CLAUDE.md half; the copied-hook half is still true (Claim 3).
**Legibility-target:** for-author

Corrected in 835f99d: "a copied CLAUDE.md's source is SOFT (ask when tainted)" (`hooks/guard-trusted-writes.py:32-33`); see Claim 4 for the executed check.

**Evidence:** `hooks/guard-trusted-writes.py:31-33`

---

## Claim 13: "Per-file link targets are read at hook load, like the other target sets."

**Location:** commit `ccda554` message (Notes)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers module-level evaluation and one process per hook call; does not establish behavior if a harness ever kept the hook resident (none does here).
**Legibility-target:** for-orchestrator-synthesis

The loop is module-level code (`hooks/guard-trusted-writes.py:123-128`, next to `_HARD_DIR_TARGETS = {_safe_resolve(CONFIG_DIR / "hooks")}` at `:116`), and the wiring runs `"command": "python3 {{CLAUDE_DIR}}/hooks/guard-trusted-writes.py"` (`hooks/wiring.json:55`) — a fresh interpreter per call.

**Evidence:** `hooks/guard-trusted-writes.py:116-128`, `hooks/wiring.json:55`

---

## Claim 14: "Red against 970e525: tests 54, 55, 56 (worktree allow), 62 (N12) and 65 (N15) fail; the rest are regression pins that already pass." with 12 tests added

**Location:** commit `456bded` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 456bded test file against the 970e525 and ccda554 hooks; test numbers refer to 456bded's file (they shift at f480c24).
**Legibility-target:** for-orchestrator-synthesis

Executed: `run_bats.sh t456-h970 970e525 456bded` → 70 tests, `not ok` exactly 54, 55, 56, 62, 65; the 970e525 file has 58 tests, so 12 were added. `run_bats.sh t456-hccda ccda554 456bded` → all 70 pass (exit 0).

**Evidence:** `test/hooks/guard-trusted-writes.bats`, `docs/reviews/execution-logs/gfc-rr-r1/bats-t456-h970.txt`, `docs/reviews/execution-logs/gfc-rr-r1/bats-t456-hccda.txt`

---

## Claim 15: "8 of the new tests fail at 035869c (red before the fix)."

**Location:** commit `f480c24` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the f480c24 test file (identical to HEAD's) against the 035869c (= ccda554) hook; does not re-count the moved allow cases.
**Legibility-target:** for-author

f480c24 adds 8 tests (70 → 78). Executed: `run_bats.sh tf48-hccda ccda554 f480c24` → 7 fail (57, 58, 59, 60, 61, 62, 64); test 63 ("a real worktree inside the config dir is not exempt") already passes at 035869c, because that hook's home-prefix test denied `$HOME/.claude/wt-home/...`. Precise version: "7 of the 8 new tests fail at 035869c".

**Evidence:** `test/hooks/guard-trusted-writes.bats:573-650`, `docs/reviews/execution-logs/gfc-rr-r1/bats-tf48-hccda.txt`

---

## Claim 16: "Record Q-050 [2] … install scripts and README install steps are untouched" / README bare-host layout links hooks one file at a time

**Location:** commit `035869c` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diffstat of 035869c and the README hook-link step the guide relies on; does not assess README accuracy otherwise.
**Legibility-target:** for-orchestrator-synthesis

035869c touches only `guides/bare-host-hook-wiring.md` (`1 file changed, 12 insertions(+)`), and the README links hooks per file: `ln -s ~/claude-workflows/hooks/$h ~/.claude/hooks/$h` (`README.md:29`), with four hooks copied instead (`README.md:34-37`) — matching the guide's linked/copied split.

**Evidence:** `README.md:29`, `README.md:34-37`, `guides/bare-host-hook-wiring.md:59-69`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6b** (`hooks/guard-trusted-writes.py:255-271`): `cd <abs worktree> && cd .. && echo … > settings.json` (or `hooks/x.sh`) writes the parent project's `.claude/` with no opinion even when tainted (970e525: deny; Edit tool: ask). The `..` check only sees the worktree's own word. Executed end-to-end. New regression from this diff; untested.
- **Claim 6c** (`hooks/guard-trusted-writes.py:55-56`): a worktree root that the same command *replaces* with a symlink is judged as it was at hook time (e2e wrote `~/CLAUDE.md`). Reach bounded to N2-class spellings; fix the docstring or record it as a residual next to the one at :268-270.

### Stale
- **Claim 11** (commit ccda554): relative worktree paths are no longer exempt (835f99d).
- **Claim 12** (commit ccda554): a copied CLAUDE.md's source is SOFT, not ungated (fixed in the docstring by 835f99d).

### Mostly Accurate
- **Claim 5** (`hooks/guard-trusted-writes.py:22-34`): the N12 resolved-tier deny is file-tools-only; Bash writes to a linked hook's checkout path get no opinion (also tainted) and this is not in the N2 list.
- **Claim 7** (`hooks/guard-trusted-writes.py:117-122`): the loop also makes directory-valued entries' whole trees and dangling targets HARD; the comment says "file".
- **Claim 10** (commit 835f99d): a worktree under `~/code/...` is exempt for hooks/settings, but a CLAUDE.md there is still denied by the literal-home indicator.
- **Claim 15** (commit f480c24): 7 of the 8 new tests fail at 035869c, not 8 (test 63 already passed).

### Unverifiable
- (none as a whole claim; within Claim 6a's scope, case-insensitive filesystems and bind-mounted roots could not be exercised on this Linux sandbox without mount privilege)

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 835f99d` line.
- Answered: yes — all brief items 0, 0b, 1-6 verdicted, mostly by execution.
- Out of scope: N2/A8 residuals (not re-filed; Claims 6c/8 note that their reach stays within those classes); code-quality judgments.
- Escalate: Claim 6b — the exemption opens a tainted-session, no-prompt Bash route to a project's own `.claude/settings.json`/hooks that 970e525 denied; a fix or an explicit accepted-residual decision is needed before merge.
