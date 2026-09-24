Commit: 835f99d

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-guard (branch `ans/guard-q048-q050`)
**Scope:** branch diff `970e525..835f99d` (5 commits): `hooks/guard-trusted-writes.py`, `test/hooks/guard-trusted-writes.bats`, `guides/bare-host-hook-wiring.md`, plus the five commit messages. Full re-review after the pass-1 fix.
**Checked:** 2026-09-23
**Total claims checked:** 17
**Summary:** 11 verified, 2 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 7 entries) read first; no entry concerns this hook, worktrees, or shell classification, and no claim below matches a logged pattern.

**Execution provenance (shared by every `executed` claim).** All probe scripts and captured outputs are in `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/gfc-rr-r3/` (called `$R` below). Every hook run used a temp `HOME` and a temp `CC_WEB_TAINT_DIR`; nothing read or wrote the real `~/.claude`.
- `bash $R/run1.sh` (cwd `$R`, exit 0, 2026-09-23T23:42:40Z): runs `bats test/hooks/guard-trusted-writes.bats` at HEAD (exit 0, 78/78 ok → `$R/bats-head.txt`), then runs the 456bded test file and the HEAD test file against the 970e525 and 035869c hooks (`$R/bats-456tests-on-970e525.txt`, `$R/bats-headtests-on-035869c.txt`, etc.; exit codes in `$R/ts.txt`).
- `python3 $R/probe.py` (cwd `$R`, exit 0, 2026-09-23T23:45:54Z): builds a fixture with a real `git worktree add` (`repo/.claude/wt-foo`, `repo/.claude/worktrees/foo`), a repo under HOME, and a bare-host checkout. It records the HEAD, 970e525 and ccda554 decisions for 23 commands, then runs two of them in the fixture → `$R/probe-out.txt`.
- `python3 $R/probe2.py` (cwd `$R`, exit 0, 2026-09-23T23:46:37Z): N12 loop edge cases, the ccda554 relative-path note, and a HOME=/workspace-style layout → `$R/probe2-out.txt`.
- `bash $R/probe3.sh` (cwd `$R`, exit 0, 2026-09-23T23:46:49Z): decisions only, nothing executed, for the real `/workspace/.claude/wt-guard` layout with a temp HOME → `$R/probe3-out.txt`.

---

## Claim 1: "the guard **denies** Claude's file tools on its checkout copy, in a tainted session or not: `global-instructions/CLAUDE.md` behind a linked `~/.claude/CLAUDE.md`, and every `hooks/<name>` linked one file at a time into `~/.claude/hooks/`"

**Location:** `guides/bare-host-hook-wiring.md:59-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Edit/Write/MultiEdit on the checkout `global-instructions/CLAUDE.md` and on a per-file-linked hook's checkout path, clean and tainted. It does not cover Bash writes to those paths: a Bash write to the linked hook's checkout path is not denied (see Claim 5). The guide's wording ("file tools") is accurately narrow.
**Legibility-target:** for-orchestrator-synthesis

The hook sends a resolved-only HARD path to its own deny (`hooks/guard-trusted-writes.py:386-393`, quoted under Claim 9). The per-file targets come from the N12 loop:

```python
# hooks/guard-trusted-writes.py:123-128
try:
    for _e in (CONFIG_DIR / "hooks").iterdir():
        _t = _safe_resolve(_e)
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
except Exception:
    pass
```

At HEAD the bats tests "Q-050: the checkout CLAUDE.md behind a symlinked ~/.claude/CLAUDE.md is denied" and "Q-050 / N12: a per-file symlinked hook's checkout target is denied" pass (78/78). The latter loops over `clean sess1` × `Edit Write MultiEdit`. In `probe.py`, F1 `Edit <checkout>/hooks/log-usage.sh` → HEAD `deny`, 970e525 `defer`.

**Evidence:** `guides/bare-host-hook-wiring.md:59-64`, `hooks/guard-trusted-writes.py:123-128`, `hooks/guard-trusted-writes.py:386-393`, `test/hooks/guard-trusted-writes.bats` (Q-050 tests), `$R/bats-head.txt`, `$R/probe-out.txt`

---

## Claim 2: "No deny rule names the checkout path, so deferring would leave it with no gate at all."

**Location:** `guides/bare-host-hook-wiring.md:64-65`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the deny rules shipped in `hooks/wiring.json` (every one is spelled under `{{CLAUDE_DIR}}` or `~`, never a checkout path). Per the brief's context, aa21535 on the parent branch found that the single-slash rules matched nothing at all, so "no gate" was also true of the config-dir spellings. That point is outside this diff.
**Legibility-target:** for-orchestrator-synthesis

```json
// hooks/wiring.json:120-124
      "Edit({{CLAUDE_DIR}}/settings*.json)",
      "Write({{CLAUDE_DIR}}/settings*.json)",
      "Edit({{CLAUDE_DIR}}/hooks/**)",
      "Write({{CLAUDE_DIR}}/hooks/**)",
      "Edit({{CLAUDE_DIR}}/CLAUDE.md)",
```

No rule names `global-instructions/` or a checkout `hooks/` path (paraphrased — no quote available because the claim is about the absence of any such rule in the deny block at `hooks/wiring.json:115` onward).

**Evidence:** `hooks/wiring.json:115-124`

---

## Claim 3: "Hooks installed as copies are not affected."

**Location:** `guides/bare-host-hook-wiring.md:66-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a checkout hook whose `~/.claude/hooks/` counterpart is a regular-file copy, clean and tainted (defer). Does not establish anything about nested per-file links inside a real subdirectory of `~/.claude/hooks/` (the loop is not recursive; see Claim 7).
**Legibility-target:** for-orchestrator-synthesis

A copy resolves to itself inside the config dir, so the loop adds a config-dir path, not the checkout path (`hooks/guard-trusted-writes.py:125`, `_t = _safe_resolve(_e)`). The bats test "Q-050: a repo hook file with no link into ~/.claude/hooks is not denied" asserts `assert_defer` for `copied.py`, clean and tainted, and it passes at HEAD.

**Evidence:** `hooks/guard-trusted-writes.py:123-128`, `$R/bats-head.txt`

---

## Claim 4: "resolved = … a bare host's checkout global-instructions/CLAUDE.md or a hook script linked one file at a time into a real ~/.claude/hooks/ (N12) … A regular-file COPY in ~/.claude leaves its source out of the HARD tier: a copied hook's source is ungated, a copied CLAUDE.md's source is SOFT (ask when tainted)."

**Location:** `hooks/guard-trusted-writes.py:22-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file-tool classification of linked vs copied hooks and CLAUDE.md. "Ungated" and "SOFT" describe the file tools only. For Bash, a copied or linked hook's checkout path gets no opinion either way (Claim 5).
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:180-181
    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
        return "hard-resolved"
```

The copied-CLAUDE.md source falls to SOFT through `name in ("claude.md", …)` (`:190-192`). The bats test "Q-050: with a regular-file ~/.claude/CLAUDE.md copy, the checkout file is not denied" expects defer when clean and `ask` when tainted, and it passes.

**Evidence:** `hooks/guard-trusted-writes.py:22-33`, `hooks/guard-trusted-writes.py:180-192`, `$R/bats-head.txt`

---

## Claim 5: "For Bash, which deny rules don't cover at all, HARD is \"deny\" outright." (read together with :25-28, which makes a per-file-linked hook's checkout path HARD)

**Location:** `hooks/guard-trusted-writes.py:34`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Bash writes to a per-file-linked hook's checkout path (brief item 0b). The file tools deny that path, but the Bash tier gives no opinion, clean or tainted. That was already true at 970e525, and no docstring, TODO or guide sentence states it. Does not cover the checkout `global-instructions/CLAUDE.md`, which Bash does deny through the `global-instructions` indicator.
**Legibility-target:** for-author

Bash "HARD" is the text co-occurrence tier (`:41-47`), not the resolved tier just defined. The paragraph therefore reads as though Bash denies the N12 path, and it does not. A write to `<checkout>/hooks/log-usage.sh` names neither `.claude` nor the config dir, so no rule fires:

```python
# hooks/guard-trusted-writes.py:338-344
    # A10: settings*.json / hooks plus the config dir named anywhere.
    if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
        return "hard"
    # Only a CLAUDE.md with NO home/global indicator anywhere reaches SOFT (Q-035).
    if SOFT_FRAG.search(cmd):
        return "soft"
    return None
```

`probe.py` E1 `echo x > <checkout>/hooks/log-usage.sh`: HEAD `defer`, 970e525 `defer`, ccda554 `defer`. E2 (`<checkout>/global-instructions/CLAUDE.md`): `deny` in all three. The TODO(N2) list names the installed-layout analog ("`/opt/claude-workflows/hooks/...` (the payload, by its real path)", `:206`) but not the bare-host checkout path that N12 now treats as a live hook. Precise version: "For Bash, HARD is the text tier below: a linked hook's checkout path is not recognized and gets no opinion (like the /opt payload in TODO N2)."

**Evidence:** `hooks/guard-trusted-writes.py:25-34`, `hooks/guard-trusted-writes.py:206`, `hooks/guard-trusted-writes.py:338-344`, `$R/probe-out.txt` (E1, E2)

---

## Claim 6a: "an agent worktree path … is not a `.claude` indicator ONLY when its whole shell word is an absolute path with no quote, expandable character or `..`, and its worktree root exists at hook time as a real, unsymlinked git worktree (a `.git` file) clear of the config dir, ~/.claude and HOME"

**Location:** `hooks/guard-trusted-writes.py:49-54` (mirrored in the comment at `:251-270`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-word exemption test. Every pass-1 route (quote-split `..`, a quote before `/.claude`, a second `=`, a quoted wt-shaped CLAUDE_CONFIG_DIR parent, a symlinked worktree dir) is closed, and so are relative, missing-root, non-worktree, symlinked-root, in-config-dir and symlink-leads-out cases. Does not establish that the command as a whole stays inside the worktree. Other words in the same command are not constrained (Claim 13), and a root replaced later in the same command is not seen (Claim 6c). Residual, not probed: bind mounts (need root) and case-insensitive filesystems (Linux sandbox only). A pre-existing hard link inside a worktree is invisible to `realpath`, but creating one already passes at 970e525 because `ln` is not a write primitive (A8).
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:283-309
def _real_worktree_root(root: str) -> bool:
    """True when `root` is, right now, a real (unsymlinked) git worktree dir that
    is clear of the config dir, ~/.claude and HOME."""
    try:
        if os.path.islink(root) or not os.path.isdir(root):
            return False
        if os.path.realpath(root) != root:
            return False
        git = os.path.join(root, ".git")
        if os.path.islink(git) or not os.path.isfile(git):
            return False
    except OSError:
        return False
    protected = {str(g) for g in GLOBAL_DIRS}
    protected |= {str(HOME / ".claude"), os.path.realpath(str(HOME / ".claude"))}
    if any(_within(root, p) or _within(p, root) for p in protected):
        return False
    home = {str(HOME), os.path.realpath(str(HOME))}
    return not any(_within(h, root) for h in home)

def _exempt_worktree(word: str, root: str) -> bool:
    if _WT_UNSAFE.search(word) or not word.startswith("/"):
        return False
    root = os.path.normpath(root)
    if not _real_worktree_root(root):
        return False
    return _within(os.path.realpath(word), root)
```

Execution:
- The 8 f480c24 tests (bypass pins, relative, missing/non-worktree, symlinked root, in-config-dir, symlink leading out) all pass at HEAD. Seven of them fail at 035869c (`$R/bats-headtests-on-035869c.txt`: not ok 57-62, 64).
- `probe.py`: A1/A2 (real absolute worktree) → HEAD `defer`. D1 `…/wt-foo/./settings.json` and D2 `…/wt-foo//settings.json` → `defer`, and both really stay inside the root. D3 `of=/…/wt-foo/settings.json` → `deny` (the word starts `of=`, so it is not absolute).
- `probe2.py` HOMEWS: with HOME equal to the repo root, a real worktree at `$HOME/.claude/wt-x` → `deny`. In a HOME=/workspace-style layout no agent worktree is exempt.
- The attacker-created `.git` file case (paraphrased — no quote available because this is an inference from the checks above): a fake `.git` file only makes a real directory outside every protected dir exempt, and writes through that word stay inside it because realpath is checked. That grants nothing beyond an ordinary directory.

**Evidence:** `hooks/guard-trusted-writes.py:49-54`, `hooks/guard-trusted-writes.py:272-326`, `$R/bats-head.txt`, `$R/bats-headtests-on-035869c.txt`, `$R/probe-out.txt`, `$R/probe2-out.txt`

---

## Claim 6b: "So a relative worktree path (`cd … && … .claude/wt-x/…`) is NOT exempt"

**Location:** `hooks/guard-trusted-writes.py:54-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a relative word that itself contains `.claude/wt-*` or `.claude/worktrees/*`. Does not cover a relative word with no `.claude` in it that is resolved against an exempt absolute `cd` target (Claim 13).
**Legibility-target:** for-orchestrator-synthesis

`if _WT_UNSAFE.search(word) or not word.startswith("/"): return False` (`hooks/guard-trusted-writes.py:304-305`). `probe2.py` REL: `cd ~ && echo x > .claude/wt-a/settings.json`, `cd ~ && ln -s . .claude/wt-q && echo PWN > .claude/wt-q/settings.json` and `cd ~ && echo x > .claude/worktrees/x/settings.json` all return HEAD `deny` (ccda554 `defer`). The bats test "Q-048: a relative worktree path is not exempt" passes.

**Evidence:** `hooks/guard-trusted-writes.py:303-305`, `$R/probe2-out.txt`, `$R/bats-head.txt`

---

## Claim 6c: "and neither is a worktree the same command creates or symlinks: it does not exist when the hook runs."

**Location:** `hooks/guard-trusted-writes.py:55-56` (also `:264-265`: "A worktree created or symlinked by the same command does not exist yet, so it is not exempt")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a worktree that exists at hook time and that the same command then moves aside and replaces with a symlink. The check is time-of-check only, so the replaced root is exempt. Does not establish that this is a stronger attack than the known deferred residuals. The link target must avoid the literal `.claude` (a glob), which is N2-class, and a two-command `ln -s` route already passes at 970e525 (A8). The commit message names only the weaker residual (a symlink created *inside* an existing worktree).
**Legibility-target:** for-author

The root check (`:287-289`, quoted in Claim 6a) runs once, at hook time. A root that exists then passes, even if the same command later replaces it. `probe.py` C1:

`mv <REPO>/.claude/wt-foo <T>/moved && ln -s <HOME>/.cla?de <REPO>/.claude/wt-foo && echo PWN > <REPO>/.claude/wt-foo/settings.json` → HEAD `defer`, 970e525 `deny`. When executed in the fixture it left the temp `~/.claude/settings.json` = `PWN` (`$R/probe-out.txt`, "--- execution ---"). C2, the same command with the literal `.claude` link target, → `deny`, because the unexempt `.claude` in the `ln` target still counts. Precise version: "a worktree the same command creates is not exempt; one it re-points after the hook runs is (time-of-check residual)".

**Evidence:** `hooks/guard-trusted-writes.py:55-56`, `hooks/guard-trusted-writes.py:264-265`, `hooks/guard-trusted-writes.py:283-309`, `$R/probe-out.txt` (C1, C2, execution)

---

## Claim 7: "resolve each entry: a checkout file that IS a live hook is HARD (resolved tier -> deny). A regular-file copy resolves into the config dir itself, which leaves its checkout original out of the HARD tier"

**Location:** `hooks/guard-trusted-writes.py:117-122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-file links and copies directly in `~/.claude/hooks/`. Does not cover nested per-file links inside a real subdirectory, because `iterdir()` is not recursive. Also reported: a hooks entry that links to a *directory* makes that whole target directory HARD, a dangling link's target is denied, and a `hooks` dir that is itself a symlink is already covered.
**Legibility-target:** for-orchestrator-synthesis

Loop quoted under Claim 1 (`:123-128`). Execution (`probe2.py`):
- **hooks dir is a symlink into a payload.** `Edit payload/hooks/a.sh` → `deny`; `payload/hooks/lib/u.sh` → `deny`; `payload/other.txt` → `defer`.
- **a per-entry link to a directory** (`hooks/lib -> <checkout>/hooks/lib`). `Edit <checkout>/hooks/lib/u.sh` → `deny`; `<checkout>/README.md` → `defer`.
- **an entry linking the checkout root.** `<checkout>/README.md` → `deny`: the whole checkout becomes resolved-HARD.
- **a dangling link.** `probe.py` F2: the missing target path → `deny`.

The README layout links five individual files (`README.md:27-30`, a `for h in log-usage.sh … claude-config-audit.sh` loop), so the directory case does not arise in the documented setup.

**Evidence:** `hooks/guard-trusted-writes.py:117-128`, `README.md:27-30`, `$R/probe2-out.txt`, `$R/probe-out.txt` (F2, F3)

---

## Claim 8: "Every other `.claude` in the command still counts." / neutralization runs before every indicator check

**Location:** `hooks/guard-trusted-writes.py:271` (with `:328-344`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers textual `.claude` occurrences. Neutralization runs once, before `HARD_FRAG` and every indicator test, and cannot create a `HARD_FRAG` match. `WRITE_PRIMITIVE` is tested on the un-neutralized text, which is conservative. Does not establish that a path spelled without `.claude` (via `..` from an exempt `cd`) is caught (Claim 13).
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:328-334
def bash_targets(cmd: str):
    has_write = bool(WRITE_PRIMITIVE.search(cmd))
    if not has_write:
        return None
    cmd = _neutralize_worktrees(cmd)
    if HARD_FRAG.search(cmd):
        return "hard"
```

`_neutralize_worktrees` replaces only the matched `.claude/wt-*` / `.claude/worktrees/<name>` span with `AGENT_WORKTREE`, and only when `_exempt_worktree` returns true (`:320-324`). The replacement token contains no `.claude`. The bats test "a worktree path does not mask a real .claude indicator elsewhere" passes. So does the `probe.py` B5 control `cd <REPO> && echo PWN > .claude/settings.json` → `deny`.

**Evidence:** `hooks/guard-trusted-writes.py:271-274`, `hooks/guard-trusted-writes.py:311-334`, `$R/bats-head.txt`, `$R/probe-out.txt`

---

## Claim 9: N15: neither deny message points at a denied path, and the Bash advice ("write that text with the Write tool and pass the file") is allowed

**Location:** `hooks/guard-trusted-writes.py:367-371`, `hooks/guard-trusted-writes.py:389-393`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two emitted strings, and a Write to a scratch `.txt` plus `git commit -F <file>`. Does not cover a scratch file placed in a policy location (such a file would be classified by its own path).
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:390-393
            emit("deny", f"This path is a live protected policy file ({Path(fp).name}: a global "
                         "hook, settings or CLAUDE.md, reached here by its real path or through a "
                         "symlink), so Claude's file tools cannot edit it. Make the change outside "
                         "Claude, in your own editor or shell, and review it there.")
```

The Bash message (`:367-371`) says "make the change outside Claude, in your own editor or shell … write that text with the Write tool and pass the file instead". No path is named except the basename. `probe.py` G1 `Write <T>/msg.txt` → `defer` and G2 `git commit -F <T>/msg.txt …` → `defer`. The bats N15 test passes.

**Evidence:** `hooks/guard-trusted-writes.py:364-371`, `hooks/guard-trusted-writes.py:386-393`, `$R/probe-out.txt` (G1, G2), `$R/bats-head.txt`

---

## Claim 10: "An unexpanded relative worktree path (cd ~ && ... .claude/wt-x/...) is exempt, which only reaches ~/.claude/wt-x, not a HARD entry."

**Location:** commit `ccda554` message, Notes
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim as true of the ccda554 hook. It was false when written: a symlinked `.claude/wt-*` or `.claude/worktrees` reaches HARD entries. HEAD no longer relies on it (relative paths are not exempt, Claim 6b), so this is historical and does not describe HEAD behavior.
**Legibility-target:** for-orchestrator-synthesis

`probe2.py` against the ccda554 hook:
- `cd ~ && ln -s . .claude/wt-q && echo PWN > .claude/wt-q/settings.json` → ccda554 `defer`.
- A pre-existing `~/.claude/worktrees -> .` plus a pre-existing `~/.claude/x/up -> ..`: `cd ~ && echo PWN2 > .claude/worktrees/x/up/settings.json` → ccda554 `defer`. Executed, it wrote the temp `~/.claude/settings.json` = `PWN2`.

HEAD denies both. Pass-1 reported the first route already; it is listed here only to verdict the commit note.

**Evidence:** `$R/probe2-out.txt` (REL lines), `hooks/guard-trusted-writes.py:303-305`

---

## Claim 11: "Per-file link targets are read at hook load, like the other target sets."

**Location:** commit `ccda554` message, Notes (code at `hooks/guard-trusted-writes.py:123-128`)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the fact that the loop is module-level code, and that the wiring starts the hook as a fresh `python3` command, so targets are re-read on each invocation. Does not establish Claude Code's per-event process spawning from source. That rests on the command-hook model, not on code in this repo.
**Legibility-target:** for-orchestrator-synthesis

The loop sits at module top level (`:123-128`, quoted under Claim 1). The wiring runs `"command": "python3 {{CLAUDE_DIR}}/hooks/guard-trusted-writes.py"` (`hooks/wiring.json:55`), one process per hook event, so a link added mid-session is seen on the next call.

**Evidence:** `hooks/guard-trusted-writes.py:123-128`, `hooks/wiring.json:55`

---

## Claim 12: "Red against 970e525: tests 54, 55, 56 (worktree allow), 62 (N12) and 65 (N15) fail; the rest are regression pins that already pass" (12 tests added)

**Location:** commit `456bded` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 456bded test file against the 970e525 hook. Does not cover later renumbering: at HEAD those tests are 54-56, 70 and 73.
**Legibility-target:** for-orchestrator-synthesis

The test count goes from 58 (970e525) to 70 (456bded), i.e. 12 added (`git show <rev>:test/hooks/guard-trusted-writes.bats | grep -c '^@test'`). The 456bded tests on the 970e525 hook give exactly `not ok 54, 55, 56, 62, 65`, 65/70 ok (`$R/bats-456tests-on-970e525.txt`).

**Evidence:** `test/hooks/guard-trusted-writes.bats`, `$R/bats-456tests-on-970e525.txt`, `$R/ts.txt`

---

## Claim 13: "a `..` escape, a home-prefixed or config-dir worktree path, and a real .claude elsewhere are still denied" (Q-048 [2]: "`..` escapes … stay denied")

**Location:** commit `456bded` message (the same promise is in `ccda554` and the brief's Q-048 statement). Mechanism at `hooks/guard-trusted-writes.py:311-326`.
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `..` in a *separate* shell word, resolved against an exempt absolute `cd` into a real worktree. It reaches the parent project's `.claude/settings*.json` and `.claude/hooks/`, and the hook gives no opinion, clean or tainted. 970e525 denied the same commands. Does not reach the global config dir without an N2-class obfuscation, because the worktree root cannot contain HOME or lie in the config dir. The file tools treat the target as SOFT (ask when tainted), so the Bash route is now weaker than Edit on it. Separately, a two-step A8 `ln -s` route to the same file already existed at 970e525. Pass-1 did not report this route.
**Legibility-target:** for-author

The exemption is decided per word. Once the absolute `cd` target is neutralized, no `.claude` is left in the text, and a later relative word spelled with `..` carries no indicator:

```python
# hooks/guard-trusted-writes.py:311-326
def _neutralize_worktrees(cmd: str) -> str:
    out, last = [], 0
    for m in _WT_SEG.finditer(cmd):
        s = m.start()
        while s > 0 and cmd[s - 1] not in _WORD_DELIM:
            s -= 1
        e = m.end()
        while e < len(cmd) and cmd[e] not in _WORD_DELIM:
            e += 1
        if not _exempt_worktree(cmd[s:e], cmd[s:m.end()]):
            continue
        out.append(cmd[last:m.start()])
        out.append("AGENT_WORKTREE")
        last = m.end()
    out.append(cmd[last:])
    return "".join(out)
```

`probe.py` (HEAD / 970e525):

| Case | Command | HEAD | 970e525 |
|------|---------|------|---------|
| B1 | `cd <REPO>/.claude/wt-foo && echo PWN > ../settings.json` | `defer` | `deny` |
| B2 | `cd <wt> && cd .. && echo PWN > settings.json` | `defer` | `deny` |
| B3 | `cd <wt> && echo PWN > ../hooks/x.sh` | `defer` | `deny` |
| B4 | `cd <REPO>/.claude/worktrees/foo && echo PWN > ../../settings.local.json` | `defer` | `deny` |

Executing B1 in the fixture left the project `.claude/settings.json` = `PWN`. On this machine's real layout (`probe3.sh`, decision only, temp HOME): `cd /workspace/.claude/wt-guard && echo x > ../settings.json` → `defer`, and `… cp /tmp/evil ../settings.local.json` → `defer`. The control `cd /workspace && echo x > .claude/settings.json` → `deny`. `/workspace/.claude/settings.json` exists (665 bytes). Tier `None` is a defer regardless of taint (`:342-344`, quoted under Claim 5; `:372-375`).

**Evidence:** `hooks/guard-trusted-writes.py:311-344`, `hooks/guard-trusted-writes.py:372-375`, `$R/probe-out.txt` (B1-B5, execution), `$R/probe3-out.txt`

---

## Claim 14: "8 of the new tests fail at 035869c (red before the fix)."

**Location:** commit `f480c24` message
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the HEAD test file (identical to f480c24's; 835f99d touches only the hook) against the 035869c hook. Does not affect whether the fix is correct. All 8 pass at HEAD.
**Legibility-target:** for-author

f480c24 adds 8 tests (70 → 78). Against the 035869c hook, 7 of them fail: `not ok 57, 58, 59, 60, 61, 62, 64` (`$R/bats-headtests-on-035869c.txt`, 71/78 ok). Test 63, "Q-048: a real worktree inside the config dir is not exempt", already passes at 035869c, because `$HOME/.claude/wt-home/…` was denied by the old home-prefix rule. Precise version: "7 of the 8 new tests fail at 035869c; the eighth pins behavior 035869c already had."

**Evidence:** `$R/bats-headtests-on-035869c.txt`, `$R/ts.txt`

---

## Claim 15: "so a project worktree under ~/code/... stays exempt"

**Location:** commit `835f99d` message, Notes
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `.claude`-indicator exemption for a real worktree under HOME, which does hold. Does not extend to CLAUDE.md writes there. Those are still denied because the literal home path is itself a HOME indicator.
**Legibility-target:** for-author

`probe.py` D5 `echo x > <HOME>/code/repo/.claude/wt-h/settings.json` → HEAD `defer`. D6 `echo x >> <HOME>/code/repo/.claude/wt-h/CLAUDE.md` → HEAD `deny`. D7, the same CLAUDE.md write in a worktree outside HOME, → `defer`. The mechanism is `_HOME_INDICATORS.append(re.escape(_lit))` for the literal HOME (`hooks/guard-trusted-writes.py:237-239`) together with `if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd): return "hard"` (`:336-337`). Precise version: "stays exempt from the `.claude` indicator; its CLAUDE.md is still HARD via the literal home path".

**Evidence:** `hooks/guard-trusted-writes.py:237-239`, `hooks/guard-trusted-writes.py:335-337`, `$R/probe-out.txt` (D5-D7)

---

## Claims Requiring Attention

### Incorrect
- **Claim 13** (`hooks/guard-trusted-writes.py:311-326`, commit 456bded): a `..` in a separate word after `cd <exempt worktree>` (`cd /workspace/.claude/wt-guard && echo x > ../settings.json`) writes the parent project's `.claude/settings*.json` / `.claude/hooks/` with no opinion, even tainted. 970e525 denied it. This is new (not in pass-1). Either make an exempt occurrence non-exempt when the command also has a relative word containing `..`, or state it as a residual.
- **Claim 6c** (`hooks/guard-trusted-writes.py:55-56`, `:264-265`): a worktree that exists at hook time and is re-pointed by the same command (`mv wt aside && ln -s ~/.cla?de wt && echo > wt/settings.json`) is exempt, and it wrote `~/.claude/settings.json` in the fixture. This is a time-of-check residual that needs an N2-class glob. Correct the docstring or add it to the stated residuals.
- **Claim 14** (commit f480c24): 7 of 8 new tests are red at 035869c, not 8 (test 63 already passed).
- **Claim 10** (commit ccda554 note): the relative-path exemption did reach HARD entries through symlinks. Historical; HEAD removed it.

### Mostly Accurate
- **Claim 5** (`hooks/guard-trusted-writes.py:34`): Bash gives no opinion on a per-file-linked hook's checkout path, which the file tools now deny. The gap predates this branch and is stated nowhere; add it to TODO(N2) next to the `/opt` payload entry.
- **Claim 15** (commit 835f99d): a worktree under `~/code/...` is exempt from the `.claude` indicator, but its CLAUDE.md is still denied via the literal home path.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 835f99d` line.
- Answered: yes (all brief items 0-6 checked, mostly by execution)
- Out of scope: bind-mounted roots (need root) and case-insensitive filesystems (not available in this Linux sandbox); pass-1 findings the fix closed are not re-filed.
- Escalate: Claim 13. The fix opens a new plain-text route (`cd <abs worktree> && … ../settings.json`) to project `.claude` policy files that 970e525 denied. That bears directly on "closes every pass-1 route and opens no new one".
