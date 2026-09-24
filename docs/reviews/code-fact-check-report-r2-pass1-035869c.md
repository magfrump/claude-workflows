Commit: 035869c

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-guard (branch `ans/guard-q048-q050`)
**Scope:** branch diff `970e525..035869c` (3 commits): `guides/bare-host-hook-wiring.md`, `hooks/guard-trusted-writes.py`, `test/hooks/guard-trusted-writes.bats`, plus the three commit messages. Whole branch, not partial.
**Checked:** 2026-09-23
**Total claims checked:** 16
**Summary:** 12 verified, 0 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Execution logs for every `executed` claim are in `docs/reviews/execution-logs/code-fact-check-r2-guard/` (`run.sh` + `bats-new.txt`/`bats-old.txt`/`ts.txt`; `probe.sh` + `probe.txt`; `demo.sh` + `demo.txt`; `demo2.sh` + `demo2.txt`). All runs used a temp `HOME`, an unset `CLAUDE_CONFIG_DIR` and a temp `CC_WEB_TAINT_DIR`; nothing touched the real `~/.claude`. The "old hook" is `git show 970e525:hooks/guard-trusted-writes.py`.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`); no claim here matches a logged pattern, and none of the Incorrect verdicts below is a fabricated symbol (they are behavior mismatches), so nothing was appended.

---

## Claim 1: "While a global file is symlinked into `~/.claude`, the guard **denies** Claude's file tools on its checkout copy, in a tainted session or not: `global-instructions/CLAUDE.md` behind a linked `~/.claude/CLAUDE.md`, and every `hooks/<name>` linked one file at a time into `~/.claude/hooks/`."

**Location:** `guides/bare-host-hook-wiring.md:59-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers Edit/Write/MultiEdit on the checkout CLAUDE.md and on a checkout hook that is a direct (top-level) entry of a real `~/.claude/hooks/`, clean and tainted; does not establish anything for a link placed inside a real subdirectory of `~/.claude/hooks/` (probe P17: `co/nested.sh -> defer`), nor for Bash writes to those checkout paths (the Bash tier is text-based and names neither).

Tests 61 and 62 (`test/hooks/guard-trusted-writes.bats:616-639`) build the README layout and assert `deny` for both sessions and all three tools; both pass on HEAD (`ok 61`, `ok 62` in `bats-new.txt`). The mechanism is the per-entry loop:

```python
# hooks/guard-trusted-writes.py:116-121
try:
    for _e in (CONFIG_DIR / "hooks").iterdir():
        _t = _safe_resolve(_e)
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
except Exception:
    pass
```

and the resolved-tier check that ignores taint:

```python
# hooks/guard-trusted-writes.py:173-174
    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
        return "hard-resolved"
```

`iterdir()` is not recursive (paraphrased — no quote available because the claim is about absence of recursion in the loop quoted above), so "every `hooks/<name>`" holds for the README's layout, which links named scripts directly into `~/.claude/hooks/` (`README.md:29`: `ln -s ~/claude-workflows/hooks/$h ~/.claude/hooks/$h`).

**Evidence:** `hooks/guard-trusted-writes.py:116-121`, `hooks/guard-trusted-writes.py:173-174`, `hooks/guard-trusted-writes.py:350-357`, `test/hooks/guard-trusted-writes.bats:616-639`, `README.md:26-30`, `docs/reviews/execution-logs/code-fact-check-r2-guard/bats-new.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt` (command `bats test/hooks/guard-trusted-writes.bats`, cwd `/workspace/.claude/wt-guard`, exit 0, 2026-09-23T16:29:54-07:00)

---

## Claim 2: "No deny rule names the checkout path, so deferring would leave it with no gate at all."

**Location:** `guides/bare-host-hook-wiring.md:64-65`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the `permissions.deny` list shipped in this branch's `hooks/wiring.json`; does not establish what a user's hand-merged settings.json holds, and does not address whether the config-dir rules themselves match (context: aa21535 on `answers-2026-09-20`, not in this diff, found the single-slash rules matched nothing — this branch still carries the pre-aa21535 `{{CLAUDE_DIR}}` spellings).

Every Edit/Write deny rule is anchored at the config dir or `~/CLAUDE.md`; none names a checkout path:

```
hooks/wiring.json (permissions.deny, printed via json.load)
  "Edit({{CLAUDE_DIR}}/settings*.json)",  "Write({{CLAUDE_DIR}}/settings*.json)",
  "Edit({{CLAUDE_DIR}}/hooks/**)",        "Write({{CLAUDE_DIR}}/hooks/**)",
  "Edit({{CLAUDE_DIR}}/CLAUDE.md)",       "Write({{CLAUDE_DIR}}/CLAUDE.md)",
  "Edit(~/CLAUDE.md)",                    "Write(~/CLAUDE.md)"
```

**Evidence:** `hooks/wiring.json` (`permissions.deny` block)

---

## Claim 3: "Hooks installed as copies are not affected."

**Location:** `guides/bare-host-hook-wiring.md:66-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers Edit of the checkout source of a regular-file copy in `~/.claude/hooks/`, clean and tainted; does not establish that the copy in `~/.claude/hooks/` is itself gated (that is the covered tier, deferred to deny rules — see Claim 2's residue).

Test 63 asserts `assert_defer` for `$CHECKOUT/hooks/copied.py` in a clean and a tainted session (`test/hooks/guard-trusted-writes.bats:641-651`); it passes on HEAD (`ok 63`). A copy resolves to itself inside the config dir, so its checkout source is in neither target set (paraphrased — no quote available because this follows from `_safe_resolve` on a regular file returning its own path, lines 92-94, combined with the loop in Claim 1).

**Evidence:** `test/hooks/guard-trusted-writes.bats:641-651`, `hooks/guard-trusted-writes.py:92-94`, `hooks/guard-trusted-writes.py:116-121`, `docs/reviews/execution-logs/code-fact-check-r2-guard/bats-new.txt`

---

## Claim 4: "a bare host's checkout global-instructions/CLAUDE.md or a hook script linked one file at a time into a real ~/.claude/hooks/ (N12) … the hook returns "deny" itself … A regular-file COPY in ~/.claude leaves its source ungated."

**Location:** `hooks/guard-trusted-writes.py:22-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the same cases as Claims 1 and 3 plus test 64 (a copied `~/.claude/CLAUDE.md` leaves the checkout file at defer clean / ask tainted); does not establish behavior for links nested below a real subdirectory of `~/.claude/hooks/`.

```python
# hooks/guard-trusted-writes.py:350-357
        if tier == "hard-resolved":
            # No deny rule names this spelling, so a defer would be no gate at all,
            # and an ask is wrong for a HARD target. Deny outright.
            # N15: do not point at the config-dir spelling: permissions.deny blocks it.
            emit("deny", f"This path is a live protected policy file ({Path(fp).name}: a global "
                         "hook, settings or CLAUDE.md, reached here by its real path or through a "
                         "symlink), so Claude's file tools cannot edit it. Make the change outside "
                         "Claude, in your own editor or shell, and review it there.")
```

Tests 61-64 pass on HEAD (`bats-new.txt`).

**Evidence:** `hooks/guard-trusted-writes.py:350-357`, `test/hooks/guard-trusted-writes.bats:616-663`, `docs/reviews/execution-logs/code-fact-check-r2-guard/bats-new.txt`

---

## Claim 5: "Exception (Q-048 [2]): an agent worktree path (`.claude/wt-<name>`, `.claude/worktrees/<name>`) is not a `.claude` indicator, unless its shell word holds `..` or an expandable character, sits directly under the home dir, or overlaps the config dir (_neutralize_worktrees)."

**Location:** `hooks/guard-trusted-writes.py:47-50`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the "shell word" mechanism for `..`, which the code implements over a narrower unit than a shell word; does not establish that the other listed conditions fail (the unquoted `..`, `~`, `$HOME`, literal-home and config-dir cases all deny — tests 57-60 pass, probes P9/P12).

The code's "word" stops at any quote character, but a shell word continues across quotes:

```python
# hooks/guard-trusted-writes.py:259-260
_WORD_DELIM = set(" \t\n\"'`;|&<>()")
_WT_UNSAFE = re.compile(r"[$`~\\*?\[{]|(^|[/=])\.\.(/|=|$)")
```

```python
# hooks/guard-trusted-writes.py:272-290 (whole function)
def _neutralize_worktrees(cmd: str) -> str:
    out, last = [], 0
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
        out.append(cmd[last:m.start()])
        out.append("AGENT_WORKTREE")
        last = m.end()
    out.append(cmd[last:])
    return "".join(out)
```

So in `~/".claude/wt-a"/../settings.json` the prefix is `""` and the suffix is `""` (both bounded by `"`), the `~` and the `/../` are never examined, and the segment is neutralized. The result then carries no `.claude` indicator. Executed probes (new vs 970e525):

```
P4   new=defer  old=deny   echo x > ~/".claude/wt-a"/../settings.json
P5   new=defer  old=deny   echo x > ~/'.claude/wt-a'/../settings.json
P6   new=defer  old=deny   cd ~ && echo x > ".claude/wt-a"/../settings.json
P7   new=defer  old=deny   cd ~ && cp /tmp/h ".claude/wt-a"/../hooks/h
```

and the shell really writes the config dir (`demo.txt`, 2026-09-23T16:32:20-07:00, exit 0): the command `cd ~ && mkdir -p .claude/wt-z && echo PWNED > ".claude/wt-z"/../settings.json && cp /etc/hostname ".claude/wt-z"/../hooks/h` got empty guard output (defer) from the new hook and `deny` from the old one, then left `settings.json now: PWNED` and a new `~/.claude/hooks/h`. The 970e525 hook denied all four; this is a regression the diff introduces, not one of the deferred N2 spellings (the `.claude`, `settings` and `hooks` tokens are intact — the quote only hides the `..`). A CLAUDE.md target is still denied via the separate `~`/CLAUDE.md co-occurrence rule (P8).

**Evidence:** `hooks/guard-trusted-writes.py:259-260`, `hooks/guard-trusted-writes.py:272-290`, `hooks/guard-trusted-writes.py:292-308`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt` (command `bash probe.sh`, cwd scratchpad, exit 0, 2026-09-23T16:31:45-07:00), `docs/reviews/execution-logs/code-fact-check-r2-guard/demo.txt` (command `bash demo.sh`, exit 0, 2026-09-23T16:32:20-07:00)

---

## Claim 6: "N12 / Q-050: … resolve each entry: a checkout file that IS a live hook is HARD (resolved tier -> deny). A regular-file copy resolves into the config dir itself, which leaves its checkout original ungated, as intended."

**Location:** `hooks/guard-trusted-writes.py:111-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers top-level entries of `CONFIG_DIR/hooks` (file links, copies, links to directories, dangling links, and `hooks` itself being a symlink); does not establish anything for entries below a real subdirectory, and does not establish that entries after one raising a non-ignored `OSError` (e.g. `PermissionError` from `is_dir()`) are still processed — the single `try` wraps the whole loop, so such an error silently skips the rest.

Code as quoted in Claim 1 (`:116-121`). Probe results (`probe.txt`):

```
P17 Edit co/hooks/lib/a.sh -> deny      # ~/.claude/hooks/lib -> checkout hooks/lib: whole target dir is HARD
P17 Edit nonexistent/x.sh -> deny       # dangling link: its target path is denied
P17 Edit co/nested.sh -> defer          # link inside a real ~/.claude/hooks/sub/: not seen
P17 Edit co/other/b -> defer
P18 Edit opt/hooks/g.py (hooks->opt) -> deny   # hooks itself a symlink: already covered by the dir target
```

A directory link makes its whole resolved target HARD-resolved (paraphrased — no quote available because this is the `_t.is_dir()` branch at `:119` feeding the `d in rp.parents` test at `:173`); the README does not link any directory into `~/.claude/hooks/` (`README.md:27-30` loops over five named scripts).

**Evidence:** `hooks/guard-trusted-writes.py:111-121`, `hooks/guard-trusted-writes.py:173-174`, `README.md:26-30`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt`

---

## Claim 7a: "Any of these keeps the occurrence as an indicator: a `..` component, or a shell-expandable character ($ ` ~ \ * ? [ {), anywhere in the shell word, since the shell could turn it back into the config dir"

**Location:** `hooks/guard-trusted-writes.py:246-248`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the definition of "shell word" used by the check; does not establish any failure of the character set itself for unquoted words.

Same mechanism and evidence as Claim 5: `_WORD_DELIM` (`:259`) includes `"`, `'` and `` ` ``, so the checked unit ends at a quote while the shell word does not; a `..` or `~` on the far side of a quote is not seen (probes P4-P7; `demo.txt`).

**Evidence:** `hooks/guard-trusted-writes.py:259-260`, `hooks/guard-trusted-writes.py:276-282`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/demo.txt`

---

## Claim 7b: "Only the exact shape is exempt. … Every other `.claude` in the command still counts."

**Location:** `hooks/guard-trusted-writes.py:245-252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `.claude` occurrences outside a `_WT_SEG` match (test 59's five commands deny; `~/.claude` elsewhere still denies); does not establish anything about text *inside* a match, where a name like `wt-.claude` absorbs a second `.claude` (`/srv/.claude/wt-.claude/hooks/x`: new defer, old deny, probe P13 — not a config-dir path, so no reachable HARD entry).

```python
# hooks/guard-trusted-writes.py:253-255
_WT_SEG = re.compile(
    r"\.claude/(?:wt-[A-Za-z0-9_.-]*|worktrees/[A-Za-z0-9_-][A-Za-z0-9_.-]*)"
    r"(?=/|[\s\"'`;|&<>()]|$)")
```

Only the matched span is replaced (`out.append("AGENT_WORKTREE")`, `:287`). Test 59 (`test/hooks/guard-trusted-writes.bats:579-591`) passes on HEAD.

**Evidence:** `hooks/guard-trusted-writes.py:253-255`, `hooks/guard-trusted-writes.py:286-288`, `test/hooks/guard-trusted-writes.bats:579-591`, `docs/reviews/execution-logs/code-fact-check-r2-guard/bats-new.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt`

---

## Claim 8: "`=` is NOT a boundary: `a=/../x` is one path, so the whole word is checked, and an assignment's value (after the first `=`) is additionally checked on its own for the home / config-dir tests."

**Location:** `hooks/guard-trusted-writes.py:256-258`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `=` absent from `_WORD_DELIM`, the `[/=]` alternative in the `..` regex, and the first-`=` split; does not establish handling of a second `=` (`x=b=/…` checks only `b=/…`, which never starts with `/`), which matters only for home/config-dir spellings that carry no `..` or expandable char.

```python
# hooks/guard-trusted-writes.py:259-260
_WORD_DELIM = set(" \t\n\"'`;|&<>()")
_WT_UNSAFE = re.compile(r"[$`~\\*?\[{]|(^|[/=])\.\.(/|=|$)")
```

```python
# hooks/guard-trusted-writes.py:284
        if any(_is_home_or_cfg(p, m.group(0)) for p in {prefix, prefix.split("=", 1)[-1]}):
```

**Evidence:** `hooks/guard-trusted-writes.py:256-260`, `hooks/guard-trusted-writes.py:265-270`, `hooks/guard-trusted-writes.py:284`

---

## Claim 9: "bash_targets() first neutralizes agent worktree segments … so they no longer count as the .claude indicator."

**Location:** `hooks/guard-trusted-writes.py:292-308` (claim text from commit ccda554)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers ordering (neutralization precedes HARD_FRAG, CLAUDE_MD/HOME_INDICATOR, SETTINGS_OR_HOOKS/CFG_INDICATOR and SOFT_FRAG; only WRITE_PRIMITIVE sees the raw text) and that the token `AGENT_WORKTREE` cannot itself match any indicator or fragment regex; does not establish that neutralization never hides a reachable HARD target (it does — Claims 5 and 13).

```python
# hooks/guard-trusted-writes.py:292-308 (whole function)
def bash_targets(cmd: str):
    has_write = bool(WRITE_PRIMITIVE.search(cmd))
    if not has_write:
        return None
    cmd = _neutralize_worktrees(cmd)
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
```

`AGENT_WORKTREE` contains no `.claude`, `claude.md`, `settings…json`, `hooks`, `~`, `$HOME`, `global-instructions` or `CLAUDE_CONFIG_DIR` (paraphrased — no quote available because this is a comparison of the literal against the regexes at `:225-242`). Removing a matched `.claude/wt-x` cannot create a `.claude/hooks` or `.claude/settings` adjacency because the replacement has no `.claude` prefix.

**Evidence:** `hooks/guard-trusted-writes.py:225-242`, `hooks/guard-trusted-writes.py:292-308`

---

## Claim 10: "N15: do not point at the config-dir spelling: permissions.deny blocks it." / both deny reasons now say to make the change outside Claude; Bash reason: "write that text with the Write tool and pass the file instead."

**Location:** `hooks/guard-trusted-writes.py:331-335`, `hooks/guard-trusted-writes.py:353-357`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both deny strings naming no editable path and the Write-then-`-F` route for prose (a Write to `/tmp/msg.txt` defers; `git commit -F /tmp/msg.txt` defers); does not establish that every prose-carrying command has a file-argument form, nor that a Write whose own target is a policy path would be allowed.

```python
# hooks/guard-trusted-writes.py:331-335
            emit("deny", "Bash write to a protected policy file (.claude hooks/settings, global CLAUDE.md). "
                         "Claude cannot write these: make the change outside Claude, in your own "
                         "editor or shell, and review it there. If the command only mentions such a "
                         "path in prose (a heredoc or message), write that text with the Write tool "
                         "and pass the file instead.")
```

Test 65 (`test/hooks/guard-trusted-writes.bats:665-676`) passes on HEAD and fails on 970e525 (`bats-old.txt`: `not ok 65`). Probes: `P15 new=defer old=defer git commit -F /tmp/msg.txt`; `P16 Write /tmp/msg.txt -> (empty=defer)`.

**Evidence:** `hooks/guard-trusted-writes.py:331-335`, `hooks/guard-trusted-writes.py:353-357`, `test/hooks/guard-trusted-writes.bats:665-676`, `docs/reviews/execution-logs/code-fact-check-r2-guard/bats-new.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/bats-old.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt`

---

## Claim 11: "Only those exact shapes are exempt: a `..` after them, a home/config-dir prefix, or any other `.claude` in the command still counts."

**Location:** `test/hooks/guard-trusted-writes.bats:519-520`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the "a `..` after them still counts" part when a quote separates the segment from the `..`; does not dispute the home/config-dir and other-`.claude` parts (Claim 7b; tests 58-60 pass). The test at `:549-561` only exercises unquoted `..`, which is why it did not catch this.

A `..` after the segment is missed when a quote closes right after the segment: `echo x > ~/".claude/wt-a"/../settings.json` → new `defer`, old `deny` (probe P4; demo in `demo.txt`). Mechanism as in Claim 5.

**Evidence:** `test/hooks/guard-trusted-writes.bats:519-520`, `test/hooks/guard-trusted-writes.bats:549-561`, `hooks/guard-trusted-writes.py:259-260`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt`

---

## Claim 12: "Red against 970e525: tests 54, 55, 56 (worktree allow), 62 (N12) and 65 (N15) fail; the rest are regression pins that already pass." and "12 tests" (brief).

**Location:** `git:456bded` (commit message; tests at `test/hooks/guard-trusted-writes.bats:517-676`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test count and pass/fail sets for the new suite against the HEAD hook and the 970e525 hook; does not establish that the tests cover quoted-word escapes (they do not — Claim 11).

Command `bash run.sh` (runs `bats test/hooks/guard-trusted-writes.bats` in `/workspace/.claude/wt-guard`, then the same file against the 970e525 hook in a temp tree), 2026-09-23T16:29:54-07:00: `new exit=0` (70/70 ok), `old exit=1`. `grep '^not ok' bats-old.txt` lists exactly:

```
not ok 54 Q-048: a Bash write into a .claude/wt-* worktree's hooks/ is not denied
not ok 55 Q-048: a Bash write into a .claude/worktrees/<name> worktree's hooks/ is not denied
not ok 56 Q-048: a worktree CLAUDE.md write is SOFT (defer; ask when tainted), not denied
not ok 62 Q-050 / N12: a per-file symlinked hook's checkout target is denied
not ok 65 N15: the resolved-path deny reason does not send the user to a denied path
```

`@test` count is 70 at HEAD and 58 at 970e525 (12 added).

**Evidence:** `test/hooks/guard-trusted-writes.bats:517-676`, `docs/reviews/execution-logs/code-fact-check-r2-guard/run.sh`, `docs/reviews/execution-logs/code-fact-check-r2-guard/ts.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/bats-new.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/bats-old.txt`

---

## Claim 13: "An unexpanded relative worktree path (cd ~ && ... .claude/wt-x/...) is exempt, which only reaches ~/.claude/wt-x, not a HARD entry."

**Location:** `git:ccda554` (commit message Notes; code at `hooks/guard-trusted-writes.py:272-290`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the case where `~/.claude/wt-x` (or `.claude/worktrees/x`) is a symlink, including one created in the same command; true when `wt-x` is a real directory (`~/.claude/wt-x/hooks/…` and `~/.claude/wt-x/settings.json` are not HARD entries). Does not re-file pre-existing symlink bypasses that name no `.claude` at all (N2 class).

The exemption is purely textual and ignores whether the segment is a link. Executed (`demo2.txt`, 2026-09-23T16:32:34-07:00, exit 0):

```
command: cd ~ && ln -s . .claude/wt-q && echo PWNED > .claude/wt-q/settings.json
new guard output: []
old guard decision: [deny]
shell exit=0
settings.json now: PWNED
```

Both occurrences are neutralized (empty prefix, suffix `""` / `/settings.json`), leaving `settings.json` with no config-dir indicator, so `bash_targets` returns None (paraphrased — no quote available because this is the combined flow of `:272-290` into `:303`, quoted in Claims 5 and 9). The 970e525 hook denied it. `ln -s` itself is an A8 unrecognized primitive, but the write here is the `>` redirect, and the loss of the deny is caused by this diff's neutralization. Probes P2/P3 (`cd ~ && echo x > .claude/wt-a/hooks/x`, `... .claude/worktrees/x/settings.json`) show the same new-defer / old-deny flip for a pre-existing link.

**Evidence:** `hooks/guard-trusted-writes.py:272-290`, `hooks/guard-trusted-writes.py:303`, `docs/reviews/execution-logs/code-fact-check-r2-guard/demo2.sh`, `docs/reviews/execution-logs/code-fact-check-r2-guard/demo2.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt`

---

## Claim 14: "A worktree path next to `global-instructions` is still denied (that is a separate indicator, outside Q-048 [2]). Per-file link targets are read at hook load, like the other target sets."

**Location:** `git:ccda554` (commit message Notes; code at `hooks/guard-trusted-writes.py:103-121`, `:225-226`)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `global-instructions` remaining in `_HOME_INDICATORS` (so CLAUDE.md + `global-instructions` is HARD regardless of neutralization) and the N12 loop being module-level code like the other target sets; does not establish that Claude Code spawns a fresh process per hook call (harness behavior — if it does, as for command hooks, a link added mid-session is seen on the next call).

```python
# hooks/guard-trusted-writes.py:225-226
_HOME_INDICATORS = [r"~", r"\$HOME\b", r"\$\{[!#]?HOME\b", r"\.claude\b",
                    r"global-instructions", r"CLAUDE_CONFIG_DIR"]
```

The loop at `:116-121` sits at module top level beside `_HARD_FILE_TARGETS` (`:103-109`), so it runs once per interpreter start (paraphrased — no quote available because the claim is about placement, i.e. file structure).

**Evidence:** `hooks/guard-trusted-writes.py:103-121`, `hooks/guard-trusted-writes.py:225-226`, `hooks/guard-trusted-writes.py:300-301`

---

## Claim 15: "all fixtures use a temp HOME and CC_WEB_TAINT_DIR; nothing reads the real ~/.claude."

**Location:** `git:456bded` (commit message Notes; code at `test/hooks/guard-trusted-writes.bats:30-38`)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the per-test `setup()` used by all 12 new tests and `bare_host_layout()`; does not establish anything about suites outside this file.

```bash
# test/hooks/guard-trusted-writes.bats:30-38
setup() {
  TEST_TMPDIR=$(mktemp -d)
  export HOME="$TEST_TMPDIR/home"
  mkdir -p "$HOME"
  export CC_WEB_TAINT_DIR="$TEST_TMPDIR/taint"
  # The config dir defaults to $HOME/.claude; an inherited CLAUDE_CONFIG_DIR
  # (the sandbox sets one) would make the temp ~/.claude non-global.
  unset CLAUDE_CONFIG_DIR
}
```

`bare_host_layout()` builds everything under `$TEST_TMPDIR` and `$HOME` (`:604-614`).

**Evidence:** `test/hooks/guard-trusted-writes.bats:30-38`, `test/hooks/guard-trusted-writes.bats:604-614`

---

## Claim 16: "install scripts and README install steps are untouched"

**Location:** `git:035869c` (commit message Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the file list of `970e525..035869c`; does not establish that the guide's new paragraph is consistent with every README step (README still installs the five logging/routing hooks as per-file links, which the guide now says Claude cannot edit at their checkout path).

The diff touches exactly `guides/bare-host-hook-wiring.md`, `hooks/guard-trusted-writes.py` and `test/hooks/guard-trusted-writes.bats` (paraphrased — no quote available because the claim is about absence of changes to other files, read from the assembled diff's `diff --git` headers).

**Evidence:** `guides/bare-host-hook-wiring.md:59-70`, `README.md:26-30`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`hooks/guard-trusted-writes.py:47-50`): "shell word" is really "run of chars between quotes/spaces"; a quote right after the worktree segment hides `~` and `..`, so `~/".claude/wt-a"/../settings.json` and `cd ~ && cp x ".claude/wt-a"/../hooks/h` now defer (970e525 denied) and do write the config dir. Regression introduced by this diff.
- **Claim 7a** (`hooks/guard-trusted-writes.py:246-248`): same defect in the Q-048 block comment.
- **Claim 11** (`test/hooks/guard-trusted-writes.bats:519-520`): "a `..` after them still counts" is false for the quoted form; the `..` test (`:549-561`) has no quoted case.
- **Claim 13** (commit ccda554 Notes): an exempt relative/home worktree segment can be a symlink to the config dir (`cd ~ && ln -s . .claude/wt-q && echo x > .claude/wt-q/settings.json` now defers and writes settings.json; 970e525 denied).

### Stale
- none

### Mostly Accurate
- none

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 035869c` line.
- Answered: yes
- Out of scope: whether the regressions should block merge or how to fix them (critics' call); pre-existing N2/A8 spellings not made worse by this diff.
- Escalate: Claims 5/13 — the Q-048 exemption opens two Bash routes to `~/.claude/settings.json` and `~/.claude/hooks/*` that the 970e525 hook denied (quote-split `..`; worktree-named symlink). Both reproduced end-to-end in a temp HOME.
