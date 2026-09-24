Commit: 035869c

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-guard (branch `ans/guard-q048-q050`)
**Scope:** branch diff `970e525..035869c` (3 commits): `guides/bare-host-hook-wiring.md`, `hooks/guard-trusted-writes.py`, `test/hooks/guard-trusted-writes.bats`, and the three commit messages
**Checked:** 2026-09-23
**Total claims checked:** 15
**Summary:** 10 verified, 2 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern, and none of the Incorrect verdicts is a fabricated symbol, so the log is not updated.

Execution provenance common to the executed claims (all run with cwd `/workspace/.claude/wt-guard` or the scratchpad `fc/` dir, a temp `HOME`, `CLAUDE_CONFIG_DIR` unset; the real `~/.claude` was never touched). Captured output lives in `docs/reviews/execution-logs/fact-check-guard-r1/`:
- **E1** `bats test/hooks/guard-trusted-writes.bats` (HEAD hook) — exit 0, 2026-09-23T23:30:41Z → `cfc-new.txt`
- **E2** same suite run against a copy whose `hooks/guard-trusted-writes.py` is `git show 970e525:hooks/guard-trusted-writes.py` — exit 1, 2026-09-23T23:30:41Z → `cfc-old.txt`
- **E3** `python3 probe.py` (feeds Bash/Edit payloads to the old and new hook; builds N12 layouts) — exit 0, 2026-09-23T23:31:18Z → `cfc-probe.txt`
- **E4** `bash shell_demo.sh` (what bash actually writes for the quote-split word) — exit 0, 2026-09-23T23:31:33Z → `cfc-shell_demo.txt`
- **E5** `python3 probe2.py` (`=` handling, the N15 Write-then-pass-the-file route) — exit 0, 2026-09-23T23:32:04Z → `cfc-probe2.txt`

---

## Claim 1: "While a global file is symlinked into `~/.claude`, the guard **denies** Claude's file tools on its checkout copy, in a tainted session or not: `global-instructions/CLAUDE.md` behind a linked `~/.claude/CLAUDE.md`, and every `hooks/<name>` linked one file at a time into `~/.claude/hooks/`."

**Location:** `guides/bare-host-hook-wiring.md:59-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers Edit/Write/MultiEdit on the checkout CLAUDE.md and on a per-file-linked hook, clean and tainted, in the README bare-host layout; does not establish anything about Bash writes to those checkout paths (the Bash tier is text-only and does not resolve links — `echo x > ~/claude-workflows/hooks/linked.sh` carries no `.claude` indicator).

The hook returns deny for the resolved tier with no taint condition:

```python
# hooks/guard-trusted-writes.py:350-357
        if tier == "hard-resolved":
            # No deny rule names this spelling, so a defer would be no gate at all,
            # and an ask is wrong for a HARD target. Deny outright.
            # N15: do not point at the config-dir spelling: permissions.deny blocks it.
            emit("deny", f"This path is a live protected policy file ({Path(fp).name}: a global "
```
(excerpt ends :354; enclosing `main()` continues to :363 — read)

E1 shows tests 61 ("the checkout CLAUDE.md behind a symlinked ~/.claude/CLAUDE.md is denied", loops `clean` and `sess1`) and 62 ("a per-file symlinked hook's checkout target is denied", Edit/Write/MultiEdit × clean/tainted) passing.

**Evidence:** `hooks/guard-trusted-writes.py:116-121`, `hooks/guard-trusted-writes.py:173-174`, `hooks/guard-trusted-writes.py:350-357`, `test/hooks/guard-trusted-writes.bats:616-639`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-new.txt`

---

## Claim 2: "No deny rule names the checkout path, so deferring would leave it with no gate at all."

**Location:** `guides/bare-host-hook-wiring.md:64`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the deny list shipped in `hooks/wiring.json`; does not establish the content of a user's hand-merged `settings.json`, nor whether the `{{CLAUDE_DIR}}` rules themselves match (Q-049/aa21535, off this branch, found the single-slash forms matched nothing — which only strengthens "no gate at all" for the checkout path).

Every Edit/Write deny rule is anchored at the config dir or `~/CLAUDE.md`; none names a checkout path:

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

**Evidence:** `hooks/wiring.json:114-129`

---

## Claim 3: "Hooks installed as copies are not affected."

**Location:** `guides/bare-host-hook-wiring.md:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a regular-file hook copy in `~/.claude/hooks/` (its checkout source defers, clean and tainted); does not cover a copied `~/.claude/CLAUDE.md`, whose source still gets the SOFT ask when tainted (see Claim 4).

E1 test 63 ("a repo hook file with no link into ~/.claude/hooks is not denied") passes: `assert_defer` on `$CHECKOUT/hooks/copied.py`, clean and tainted (`test/hooks/guard-trusted-writes.bats:641-651`). The copy's own resolution lands inside the config dir (paraphrased — no quote available because the property is the result of `_safe_resolve` on a non-link, i.e. the entry path itself, at `hooks/guard-trusted-writes.py:118`).

**Evidence:** `hooks/guard-trusted-writes.py:116-121`, `test/hooks/guard-trusted-writes.bats:641-651`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-new.txt`

---

## Claim 4: "A regular-file COPY in ~/.claude leaves its source ungated."

**Location:** `hooks/guard-trusted-writes.py:30-31`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the resolved-HARD tier (a copy does not put its source there); does not hold for the CLAUDE.md case in the full sense of "ungated" — the source still falls to SOFT.

True for hooks (Claim 3). For a copied `~/.claude/CLAUDE.md`, the checkout `global-instructions/CLAUDE.md` is not HARD but is still SOFT by name, so a tainted session gets an ask — the branch's own test pins that:

```bash
# test/hooks/guard-trusted-writes.bats:659-662
  # It is still a CLAUDE.md, so a tainted session gets the SOFT ask.
  taint sess1
  guard "$(file_payload Edit "$CHECKOUT/global-instructions/CLAUDE.md" sess1)"
  assert_decision ask
```

Precise version: "…leaves its source out of the HARD tier (a CLAUDE.md source is still SOFT)." E1 test 64 passes.

**Evidence:** `hooks/guard-trusted-writes.py:183-185`, `test/hooks/guard-trusted-writes.bats:653-663`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-new.txt`

---

## Claim 5: "Exception (Q-048 [2]): an agent worktree path … is not a `.claude` indicator, unless its shell word holds `..` or an expandable character, sits directly under the home dir, or overlaps the config dir (_neutralize_worktrees)."

**Location:** `hooks/guard-trusted-writes.py:47-50`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the "shell word" mechanism for all three keep-as-indicator conditions; does not establish any bypass that avoids quotes (unquoted `..`, `~`, `$`, home and config-dir prefixes are all caught, E3/E5).

The code's "word" is bounded by `_WORD_DELIM`, which includes `"` and `'`. A shell word is not split by quotes, so `..`, `$HOME`, or a home/config-dir prefix sitting in a quoted part of the *same shell word* is never examined:

```python
# hooks/guard-trusted-writes.py:259-260
_WORD_DELIM = set(" \t\n\"'`;|&<>()")
_WT_UNSAFE = re.compile(r"[$`~\\*?\[{]|(^|[/=])\.\.(/|=|$)")
```
```python
# hooks/guard-trusted-writes.py:274-285
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
(excerpt ends :285; enclosing `_neutralize_worktrees()` continues to :290 — read; the neutralized string is consumed at `bash_targets` :296-307 — read)

`_WT_SEG`'s lookahead also accepts `"` right after the name (`(?=/|[\s\"'`;|&<>()]|$)`, :255), so the suffix is empty. E3, old hook → new hook:

```
deny     -> defer    | cd ~ && echo x > .claude/wt-x"/.."/settings.json
deny     -> defer    | cd ~ && echo x > .claude/wt-x"/../hooks/"evil.sh
deny     -> defer    | echo x > "/tmp/tmpfgzp5y_a/home"/.claude/wt-x"/.."/settings.json
deny     -> defer    | echo x > "$HOME"/.claude/wt-x"/.."/settings.json
deny     -> defer    | echo x > '/tmp/tmpfgzp5y_a/home'/.claude/wt-x'/..'/hooks/evil.sh
deny     -> defer    | echo x > "$HOME"/.claude/wt-x/hooks/x.sh
```

E4 confirms bash writes the real config file for the first form (`~/.claude/wt-x` need only exist; `mkdir` is not a write primitive, so creating it defers): `ls` shows `settings.json` created in `$HOME/.claude`, contents `x`. The last row shows the "directly under the home dir" condition also fails when the home prefix is quoted (that row alone reaches only `~/.claude/wt-x/…`, not a HARD entry). This is a regression: all six were denied at 970e525. A `.claude/settings.json` / `.claude/hooks/*` write via `"$HOME"/.claude/wt-x"/.."/…` is a HARD Bash write that now gets no opinion, tainted or not.

**Evidence:** `hooks/guard-trusted-writes.py:253-260`, `hooks/guard-trusted-writes.py:272-307`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe.txt`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-shell_demo.txt`

---

## Claim 6: "N12 / Q-050: … resolve each entry: a checkout file that IS a live hook is HARD (resolved tier -> deny). A regular-file copy resolves into the config dir itself, which leaves its checkout original ungated, as intended."

**Location:** `hooks/guard-trusted-writes.py:111-121`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers per-file links, copies, a symlinked `hooks` dir, a directory entry, and a dangling entry; does not establish that the resulting blast radius is the intended one — an entry linking to a directory makes that entire directory HARD (an entry linking to the checkout root denies every file in the checkout).

```python
# hooks/guard-trusted-writes.py:116-121
try:
    for _e in (CONFIG_DIR / "hooks").iterdir():
        _t = _safe_resolve(_e)
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
except Exception:
    pass
```

E3 layouts (Edit on a checkout path):

```
hooks-symlink  deny     | hooks/a.py
hooks-symlink  deny     | hooks/lib/u.py
hooks-symlink  defer    | other/f.py
dir-entry      deny     | hooks/lib/u.py
dir-entry      defer    | hooks/a.py
dangling       deny     | gone.py
dangling       defer    | hooks/a.py
root-entry     deny     | other/f.py
root-entry     deny     | hooks/a.py
```

When `hooks` itself is a symlink (devcontainer), iterdir walks the target and the entries are already inside the pre-existing `_HARD_DIR_TARGETS` entry, so behavior is unchanged. A dangling link adds its would-be target as a file target (denied if later created). E1 tests 62-63 pass. The single `try` wraps the whole loop, so one exception stops the remaining entries (paraphrased — no quote available because this is about the scope of the `try` at :116-121 quoted above, not a separate line).

**Evidence:** `hooks/guard-trusted-writes.py:110-121`, `hooks/guard-trusted-writes.py:173-174`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe.txt`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-new.txt`

---

## Claim 7: "Any of these keeps the occurrence as an indicator: a `..` component, or a shell-expandable character ($ ` ~ \ * ? [ {), anywhere in the shell word, since the shell could turn it back into the config dir; a prefix that is the home dir itself …; a worktree path that equals, contains or lies inside the config dir."

**Location:** `hooks/guard-trusted-writes.py:244-252`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Same mechanism and evidence as Claim 5 (the code comment restates the docstring); does not establish a bypass for unquoted words.

"Anywhere in the shell word" is false: the scan stops at quote characters (`_WORD_DELIM`, :259), so `..`/`$`/`~` or a literal home/config-dir prefix inside a quoted segment of the same shell word are not seen. See Claim 5 for the quoted code and E3/E4 output.

**Evidence:** `hooks/guard-trusted-writes.py:259-260`, `hooks/guard-trusted-writes.py:274-285`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe.txt`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-shell_demo.txt`

---

## Claim 8: "`=` is NOT a boundary: `a=/../x` is one path, so the whole word is checked, and an assignment's value (after the first `=`) is additionally checked on its own for the home / config-dir tests."

**Location:** `hooks/guard-trusted-writes.py:256-258`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers unquoted assignment-shaped words; does not establish handling of a quoted value (`x="/.."/.claude/wt-x/...`), which falls under the quote-split defect in Claim 5.

`=` is absent from `_WORD_DELIM` (:259), `_WT_UNSAFE` matches `..` after `=` or `/` (:260), and the value is re-tested via `prefix.split("=", 1)[-1]` (:284). E5:

```
deny     | x=/../.claude/wt-x/hooks/y; cp a "$x"
deny     | cp a x=/../.claude/wt-x/hooks/y
```

E3: `cp a --target-directory=<HOME>/.claude/wt-x/hooks` → deny (value tested for the home prefix).

**Evidence:** `hooks/guard-trusted-writes.py:259-260`, `hooks/guard-trusted-writes.py:284`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe2.txt`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe.txt`

---

## Claim 9: "bash_targets() first neutralizes agent worktree segments … Other .claude occurrences are untouched." (brief item 2: runs before every indicator check; cannot create/hide a HARD_FRAG match)

**Location:** `hooks/guard-trusted-writes.py:292-307`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers ordering (neutralization precedes HARD_FRAG, CLAUDE_MD+HOME, SETTINGS_OR_HOOKS+CFG and SOFT_FRAG) and that the replacement token `AGENT_WORKTREE` contains no indicator; does not establish that removing the worktree's `.claude` is safe — that is exactly what the quote-split bypass (Claim 5) exploits.

```python
# hooks/guard-trusted-writes.py:293-298
    has_write = bool(WRITE_PRIMITIVE.search(cmd))
    if not has_write:
        return None
    cmd = _neutralize_worktrees(cmd)
    if HARD_FRAG.search(cmd):
        return "hard"
```
(excerpt ends :298; enclosing `bash_targets()` continues to :308 — read; every later check uses the rebound `cmd`)

A `.claude/wt-x` match can never itself be a HARD_FRAG (`\.claude/hooks|\.claude/settings`, :239), so neutralizing it cannot hide one; a real `.claude/hooks` nested after it survives (E5: `echo x > .claude/wt-x/.claude/hooks/y` → deny). WRITE_PRIMITIVE runs on the original text, which neutralization cannot affect.

**Evidence:** `hooks/guard-trusted-writes.py:239`, `hooks/guard-trusted-writes.py:292-308`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe2.txt`

---

## Claim 10: "If the command only mentions such a path in prose (a heredoc or message), write that text with the Write tool and pass the file instead."

**Location:** `hooks/guard-trusted-writes.py:331-335`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers Write of a non-policy-named file (defer, even tainted) and a consumer such as `git commit -F <file>` (defer); does not establish that every consumer command is unflagged — one that itself contains a write primitive plus `CLAUDE.md` and a home indicator is still denied, and writing the text to a SOFT-named path (a `CLAUDE.md`, a `.claude/` path) asks when tainted.

The message avoids naming any path. E5:

```
defer    | git commit -F /tmp/msg.txt
tainted Write defer    | /tmp/msg.txt
tainted Write defer    | /srv/repo/docs/working/notes.md
```

`classify_path` inspects only the path, never the content (paraphrased — no quote available because this is an absence claim: `main()` passes only `fp` to `classify_path`, :342-345).

**Evidence:** `hooks/guard-trusted-writes.py:331-335`, `hooks/guard-trusted-writes.py:341-361`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe2.txt`

---

## Claim 11: "N15: do not point at the config-dir spelling: permissions.deny blocks it."

**Location:** `hooks/guard-trusted-writes.py:353-357`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both new deny reasons (resolved-tier file tools and Bash HARD); does not establish wording of the pre-existing SOFT ask messages.

```python
# hooks/guard-trusted-writes.py:354-357
            emit("deny", f"This path is a live protected policy file ({Path(fp).name}: a global "
                         "hook, settings or CLAUDE.md, reached here by its real path or through a "
                         "symlink), so Claude's file tools cannot edit it. Make the change outside "
                         "Claude, in your own editor or shell, and review it there.")
```

Only the basename is interpolated; no `~/.claude` spelling. E1 test 65 (checks absence of `~/.claude path` and presence of `outside Claude` in both reasons) passes.

**Evidence:** `hooks/guard-trusted-writes.py:331-335`, `hooks/guard-trusted-writes.py:354-357`, `test/hooks/guard-trusted-writes.bats:665-676`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-new.txt`

---

## Claim 12: "An unexpanded relative worktree path (cd ~ && ... .claude/wt-x/...) is exempt, which only reaches ~/.claude/wt-x, not a HARD entry."

**Location:** commit `ccda554` (message, Notes)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the claim that the exempt relative form cannot reach a HARD entry; does not dispute that the *unquoted* `..` form is still denied (E3: `cd ~ && echo x > .claude/wt-x/../settings.json` → deny).

The exempt form reaches `~/.claude/settings.json` when the escape sits in a quoted segment: E3 `cd ~ && echo x > .claude/wt-x"/.."/settings.json` → defer (deny at 970e525), and E4 shows bash writes `$HOME/.claude/settings.json`. Separately, if `~/.claude/wt-x` is a symlink to the config dir (created with `ln -s`, a primitive the hook does not see — deferred A8), `cd ~ && echo x > .claude/wt-x/settings.json` (E3: defer) writes the real settings file (paraphrased — no quote available because the symlink case follows from the defer result plus kernel path resolution, not a code line). The `.claude/worktrees/x` form from `~` behaves the same way.

**Evidence:** `hooks/guard-trusted-writes.py:259-260`, `hooks/guard-trusted-writes.py:274-285`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe.txt`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-shell_demo.txt`

---

## Claim 13: "Per-file link targets are read at hook load, like the other target sets."

**Location:** commit `ccda554` (message, Notes)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the loop runs at module import, alongside `_HARD_FILE_TARGETS`/`_settings_names`; does not establish that Claude Code spawns a fresh process per hook call (external harness behavior — not checked here; the script itself holds no cache across runs).

The loop is module-level (`hooks/guard-trusted-writes.py:116-121`, quoted in Claim 6), next to the other sets at :103-110, and `main()` runs only from `if __name__ == "__main__": main()` (:365-366).

**Evidence:** `hooks/guard-trusted-writes.py:103-121`, `hooks/guard-trusted-writes.py:365-366`

---

## Claim 14: "Copies resolve into the config dir and leave their source ungated."

**Location:** commit `ccda554` (message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Same as Claim 4: exact for hook copies; a copied CLAUDE.md's source is still SOFT (ask when tainted).

See Claim 4 (`test/hooks/guard-trusted-writes.bats:659-662`: `assert_decision ask` on the tainted checkout CLAUDE.md after a copy). Precise version: "…leave their source out of the HARD tier."

**Evidence:** `test/hooks/guard-trusted-writes.bats:653-663`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-new.txt`

---

## Claim 15: "Red against 970e525: tests 54, 55, 56 (worktree allow), 62 (N12) and 65 (N15) fail; the rest are regression pins that already pass." (and "12 tests" per the brief)

**Location:** commit `456bded` (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the red/green set and the count of added tests; does not establish that the pins cover the quote-split forms (none do — the Claim 5 regression passes the suite).

E2 (old hook) `not ok` lines are exactly 54, 55, 56, 62, 65; E1 (HEAD) all 70 pass. The diff adds 12 `@test` blocks (7 Q-048 at `test/hooks/guard-trusted-writes.bats:522-597`, 4 Q-050 + 1 N15 at :616-676); suite size 70.

**Evidence:** `test/hooks/guard-trusted-writes.bats:522-676`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-old.txt`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-new.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`hooks/guard-trusted-writes.py:47-50`): the "shell word" scan stops at quotes, so `.claude/wt-x"/.."/settings.json` (from `~`, or behind a quoted `"$HOME"`/literal home) escapes to the real `~/.claude/settings.json` / `hooks/` with no opinion — a regression from deny at 970e525, executed end to end.
- **Claim 7** (`hooks/guard-trusted-writes.py:244-252`): same defect in the code comment ("anywhere in the shell word").
- **Claim 12** (commit `ccda554` Notes): the exempt relative form can reach a HARD entry (quote-split `..`; or a symlinked `wt-*` created via the unseen `ln -s`).

### Stale
- none

### Mostly Accurate
- **Claim 4** (`hooks/guard-trusted-writes.py:30-31`): a copied CLAUDE.md's source is not "ungated" — it is SOFT (ask when tainted); say "out of the HARD tier".
- **Claim 14** (commit `ccda554`): same imprecision.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 035869c` line.
- Answered: yes
- Out of scope: Bash writes to checkout paths of linked hooks (text tier, pre-existing); code-quality judgments
- Escalate: Claim 5 — the Q-048 exemption opens a real HARD bypass via quote-split words (`"$HOME"/.claude/wt-x"/.."/settings.json`), denied before this branch; the tests do not pin it.
