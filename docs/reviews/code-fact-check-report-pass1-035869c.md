# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-guard (branch `ans/guard-q048-q050`)
**Scope:** branch diff `970e525..035869c` (3 commits: 456bded, ccda554, 035869c): `guides/bare-host-hook-wiring.md`, `hooks/guard-trusted-writes.py`, `test/hooks/guard-trusted-writes.bats`, plus the three commit messages; `hooks/wiring.json` and `README.md` read as referenced context
**Checked:** 2026-09-23
**Total claims checked:** 24
**Summary:** 14 verified, 3 mostly accurate, 0 stale, 6 incorrect, 1 unverifiable
**Commit:** 035869c
**Replication:** k=3

Merged from `code-fact-check-report-r1.md`, `-r2.md`, `-r3.md` by most-severe-wins (code-review SKILL.md, "Merging replicate verdicts"). No claim, evidence or verdict was added in the merge. All three replicates read the hallucination-pattern log; none appended to it (r3 compared its Claim 15 against the logged test-count pattern: no match).

Execution provenance (per replicate; every run used a temp `HOME`, unset `CLAUDE_CONFIG_DIR`, and never touched the real `~/.claude`; the "old hook" is `git show 970e525:hooks/guard-trusted-writes.py`):
- **r1** — `docs/reviews/execution-logs/fact-check-guard-r1/`: E1 `bats test/hooks/guard-trusted-writes.bats` (HEAD) exit 0, 2026-09-23T23:30:41Z → `cfc-new.txt`; E2 same suite on the 970e525 hook, exit 1 → `cfc-old.txt`; E3 `python3 probe.py` exit 0, 23:31:18Z → `cfc-probe.txt`; E4 `bash shell_demo.sh` exit 0, 23:31:33Z → `cfc-shell_demo.txt`; E5 `python3 probe2.py` exit 0, 23:32:04Z → `cfc-probe2.txt`.
- **r2** — `docs/reviews/execution-logs/code-fact-check-r2-guard/`: `bash run.sh` (new exit 0, old exit 1), 2026-09-23T16:29:54-07:00 → `bats-new.txt`/`bats-old.txt`/`ts.txt`; `bash probe.sh` exit 0, 16:31:45-07:00 → `probe.txt`; `bash demo.sh` exit 0, 16:32:20-07:00 → `demo.txt`; `demo2.sh` exit 0, 16:32:34-07:00 → `demo2.txt`.
- **r3** — suite runs 2026-09-23T23:29:55Z (branch exit 0 70/70; 970e525 exit 1) → `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-new.log`, `…-bats-old.log`; `python3 probe.py` exit 0, 23:31:49Z → `…-r3-guard-probe.log`; `python3 probe2.py` exit 0, 23:32:25Z → `…-r3-guard-probe2.log`.

---

## Claim 1: "While a global file is symlinked into `~/.claude`, the guard **denies** Claude's file tools on its checkout copy, in a tainted session or not: `global-instructions/CLAUDE.md` behind a linked `~/.claude/CLAUDE.md`, and every `hooks/<name>` linked one file at a time into `~/.claude/hooks/`."

**Location:** `guides/bare-host-hook-wiring.md:59-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Edit/Write/MultiEdit on the checkout CLAUDE.md and on a checkout hook that is a direct (top-level) entry of a real `~/.claude/hooks/`, clean and tainted; does not establish anything for a link placed inside a real subdirectory of `~/.claude/hooks/` (probe P17: `co/nested.sh -> defer`), nor for Bash writes to those checkout paths (the Bash tier is text-based and names neither).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "does not establish anything about Bash writes to those checkout paths (the Bash tier is text-only and does not resolve links — `echo x > ~/claude-workflows/hooks/linked.sh` carries no `.claude` indicator)" · r2: nested links below a real subdirectory of `~/.claude/hooks/` are not seen (`iterdir()` is not recursive; P17 `co/nested.sh -> defer`) · r3: "or for directory-level hook links (see Claim 11 [merged Claim 9])" · r3: test 62 fails against 970e525 but test 61 already passed there ("the CLAUDE.md case came from `_HARD_FILE_TARGETS` at :103 before this diff")

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

**Evidence:** `hooks/guard-trusted-writes.py:116-121`, `hooks/guard-trusted-writes.py:173-174`, `hooks/guard-trusted-writes.py:350-357`, `test/hooks/guard-trusted-writes.bats:616-639`, `README.md:26-30`, `docs/reviews/execution-logs/code-fact-check-r2-guard/bats-new.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt`

---

## Claim 2: "No deny rule names the checkout path, so deferring would leave it with no gate at all."

**Location:** `guides/bare-host-hook-wiring.md:64-66`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the deny list shipped in `hooks/wiring.json`; does not establish the content of a user's hand-merged `settings.json`, nor whether the `{{CLAUDE_DIR}}` rules themselves match (Q-049/aa21535, off this branch, found the single-slash forms matched nothing — which only strengthens "no gate at all" for the checkout path).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: does not establish a user's hand-merged settings.json, nor that the config-dir rules themselves match (Q-049, fixed at aa21535 on `answers-2026-09-20`, outside this diff) · r2: "this branch still carries the pre-aa21535 `{{CLAUDE_DIR}}` spellings"

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

## Claim 3: "A hook deny has no approve option"

**Location:** `guides/bare-host-hook-wiring.md:66-67`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only that the hook emits `permissionDecision: "deny"` for these paths; does not establish how Claude Code presents a PreToolUse deny to the user (whether any override prompt exists).
**Replicate verdicts:** r1=— · r2=— · r3=Unverifiable · single-replicate detection
**Replicate annotations:** r3: "Verifying it needs a live Claude Code session or its hook documentation."

The hook side is confirmed: `emit("deny", f"This path is a live protected policy file ...` (`hooks/guard-trusted-writes.py:354`). Whether the harness offers an approve path on a hook deny is Claude Code behavior outside the codebase (paraphrased — no quote available because the claim is about the external harness, not repo code).

**Evidence:** `hooks/guard-trusted-writes.py:350-357`

---

## Claim 4: "Hooks installed as copies are not affected."

**Location:** `guides/bare-host-hook-wiring.md:65-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a regular-file hook copy in `~/.claude/hooks/` (its checkout source defers, clean and tainted); does not cover a copied `~/.claude/CLAUDE.md`, whose source still gets the SOFT ask when tainted (see Claim 6).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: a copied CLAUDE.md's source is SOFT (asks when tainted), not covered by "not affected" · r2: "does not establish that the copy in `~/.claude/hooks/` is itself gated (that is the covered tier, deferred to deny rules — see Claim 2's residue)" · r3: README installs the security hooks as copies (`README.md:34`)

E1 test 63 ("a repo hook file with no link into ~/.claude/hooks is not denied") passes: `assert_defer` on `$CHECKOUT/hooks/copied.py`, clean and tainted (`test/hooks/guard-trusted-writes.bats:641-651`). The copy's own resolution lands inside the config dir (paraphrased — no quote available because the property is the result of `_safe_resolve` on a non-link, i.e. the entry path itself, at `hooks/guard-trusted-writes.py:118`).

**Evidence:** `hooks/guard-trusted-writes.py:116-121`, `test/hooks/guard-trusted-writes.bats:641-651`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-new.txt`

---

## Claim 5: "a bare host's checkout global-instructions/CLAUDE.md or a hook script linked one file at a time into a real ~/.claude/hooks/ (N12) … the hook returns "deny" itself"

**Location:** `hooks/guard-trusted-writes.py:22-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same cases as Claims 1 and 4 plus test 64; does not establish behavior for links nested below a real subdirectory of `~/.claude/hooks/`.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=— · single-replicate detection
**Replicate annotations:** none

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

## Claim 6: "A regular-file COPY in ~/.claude leaves its source ungated."

**Location:** `hooks/guard-trusted-writes.py:30-31`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the resolved-HARD tier (a copy does not put its source there); does not hold for the CLAUDE.md case in the full sense of "ungated" — the source still falls to SOFT.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1+r3: precise version "…leaves its source out of the HARD tier (a CLAUDE.md source is still SOFT)"; hook-script sources are fully ungated · r2: test 64 read as "a copied `~/.claude/CLAUDE.md` leaves the checkout file at defer clean / ask tainted" (same fact, scored Verified under its compound)

True for hooks (Claim 4). For a copied `~/.claude/CLAUDE.md`, the checkout `global-instructions/CLAUDE.md` is not HARD but is still SOFT by name, so a tainted session gets an ask — the branch's own test pins that:

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

## Claim 7: "Exception (Q-048 [2]): an agent worktree path … is not a `.claude` indicator, unless its shell word holds `..` or an expandable character …"

**Location:** `hooks/guard-trusted-writes.py:47-49` (docstring; restated in commit ccda554 body)
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "shell word" mechanism for `..`, which the code implements over a narrower unit than a shell word; does not establish that the other listed conditions fail for unquoted words (the unquoted `..`, `~`, `$HOME`, literal-home and config-dir cases all deny — tests 57-60 pass, probes P9/P12).
**Replicate verdicts:** r1=Incorrect (compound) · r2=Incorrect (compound) · r3=Incorrect
**Replicate annotations:** r1: "does not establish any bypass that avoids quotes (unquoted `..`, `~`, `$`, home and config-dir prefixes are all caught, E3/E5)"; E4 confirms bash writes the real config file, and "`~/.claude/wt-x` need only exist; `mkdir` is not a write primitive, so creating it defers" · r2: the `.claude`, `settings` and `hooks` tokens are intact, so this is "a regression the diff introduces, not one of the deferred N2 spellings"; "A CLAUDE.md target is still denied via the separate `~`/CLAUDE.md co-occurrence rule (P8)" · r3: also `.claude/wt-x/.""./settings.json` (suffix `/.` passes `_WT_UNSAFE`); self-contained repro `mkdir -p "$HOME"/.claude/wt-y && echo … > "$HOME"/.claude/wt-y"/../"settings.local.json` wrote the file; "does not establish every other shell spelling (e.g. `$'…'`)"; "the diff widens the known [N2] gap" (`hooks/guard-trusted-writes.py:196-198`) · r1+r2+r3: the regression pins do not include any quoted spelling

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

and the shell really writes the config dir (`demo.txt`, 2026-09-23T16:32:20-07:00, exit 0): the command `cd ~ && mkdir -p .claude/wt-z && echo PWNED > ".claude/wt-z"/../settings.json && cp /etc/hostname ".claude/wt-z"/../hooks/h` got empty guard output (defer) from the new hook and `deny` from the old one, then left `settings.json now: PWNED` and a new `~/.claude/hooks/h`. The 970e525 hook denied all four.

**Evidence:** `hooks/guard-trusted-writes.py:259-260`, `hooks/guard-trusted-writes.py:272-290`, `hooks/guard-trusted-writes.py:292-308`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/demo.txt`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe.txt`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-shell_demo.txt`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`

---

## Claim 8: "… [unless its shell word] sits directly under the home dir, or overlaps the config dir (_neutralize_worktrees)."

**Location:** `hooks/guard-trusted-writes.py:49-50` (docstring; restated in commit ccda554 body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unquoted spellings (correct; tests 58 and 60 pass) and quote-split / double-`=` spellings (refuted); does not establish reachability of HARD entries for the home-prefix residue alone (a `~/.claude/wt-x/...` target is not itself HARD unless combined with Claim 7 or a symlinked `wt-x`).
**Replicate verdicts:** r1=Incorrect (compound) · r2=Incorrect (compound) · r3=Incorrect
**Replicate annotations:** r1: the quoted-home row `echo x > "$HOME"/.claude/wt-x/hooks/x.sh` (deny → defer) "alone reaches only `~/.claude/wt-x/…`, not a HARD entry" · r2: its compound Incorrect rests on the `..` mechanism only — "does not establish that the other listed conditions fail" · r3: with a wt-shaped `CLAUDE_CONFIG_DIR`, `"<parent>"/.claude/wt-cfg/settings.json` "is a direct HARD write … with no `..` involved"; when HOME is the worktree's parent, absolute worktree paths always deny while relative ones are exempt (related observation, not a refutation)

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
- With `CLAUDE_CONFIG_DIR=<tmp>/srv/repo/.claude/wt-cfg`: `echo x > <cfg>/settings.json` → deny, but `echo x > "<tmp>/srv/repo"/.claude/wt-cfg/settings.json` → new=defer, old=deny.

**Evidence:** `hooks/guard-trusted-writes.py:262-290`, `test/hooks/guard-trusted-writes.bats:563-577`, `test/hooks/guard-trusted-writes.bats:593-597`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe2.log`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe.txt`

---

## Claim 9: "N12 / Q-050: … resolve each entry: a checkout file that IS a live hook is HARD (resolved tier -> deny). A regular-file copy resolves into the config dir itself, which leaves its checkout original ungated, as intended."

**Location:** `hooks/guard-trusted-writes.py:111-121` (restated in commit ccda554 body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-file links, copies, a `hooks` that is itself a directory symlink, a directory-valued entry and a dangling entry; does not establish the README's per-file loop as the only layout in use.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: a directory-valued entry makes its whole target tree HARD (r1: "an entry linking to the checkout root denies every file in the checkout"; r1 scope: "does not establish that the resulting blast radius is the intended one") · r1+r2: "The single `try` wraps the whole loop, so one exception stops the remaining entries" (r2: e.g. `PermissionError` from `is_dir()` silently skips the rest) · r2: entries below a real subdirectory are not seen (P17 `co/nested.sh -> defer`); the README links no directory into `~/.claude/hooks/` · r1+r2+r3: a dangling link registers its would-be target (denied if later created) · r1+r2+r3: when `hooks` itself is a symlink the loop adds only redundant entries (pre-existing `_HARD_DIR_TARGETS` at `:110`)

The per-file and copy halves hold (Claims 1, 4; README links hooks one file at a time: `ln -s ~/claude-workflows/hooks/$h ~/.claude/hooks/$h`, `README.md:29`). The comment says "a checkout file", but the loop also registers directories:

```python
# hooks/guard-trusted-writes.py:119
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
```

Probe results:
- entry `hooks/lib -> <checkout>/hooks/lib`: Edit `<checkout>/hooks/lib/util.py` → deny, and Edit of a not-yet-existing `<checkout>/hooks/lib/new.py` → deny (old: defer, defer).
- entry `hooks/root -> <checkout>` (checkout root): Edit `<checkout>/README.md` → deny (old: defer). One directory link makes its whole target tree HARD.
- dangling `hooks/gone.sh -> <checkout>/hooks/gone.sh`: Edit of that target → deny (old: defer). `resolve()` is non-strict, so the missing target is registered as a file.
- `hooks` itself a symlink into an `/opt`-like payload: `<opt>/hooks/g.py` and `<opt>/hooks/new.py` → deny on both old and new.

Precise version: "resolve each entry; a checkout file or directory that is a live hook entry is HARD, including dangling link targets."

**Evidence:** `hooks/guard-trusted-writes.py:110-121`, `hooks/guard-trusted-writes.py:173-174`, `README.md:26-37`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt`

---

## Claim 10: "Only the exact shape is exempt. … Every other `.claude` in the command still counts."

**Location:** `hooks/guard-trusted-writes.py:245-252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `.claude` occurrences outside a `_WT_SEG` match (test 59's five commands deny; `~/.claude` elsewhere still denies); does not establish anything about text *inside* a match, where a name like `wt-.claude` absorbs a second `.claude` (`/srv/.claude/wt-.claude/hooks/x`: new defer, old deny, probe P13 — not a config-dir path, so no reachable HARD entry).
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

```python
# hooks/guard-trusted-writes.py:253-255
_WT_SEG = re.compile(
    r"\.claude/(?:wt-[A-Za-z0-9_.-]*|worktrees/[A-Za-z0-9_-][A-Za-z0-9_.-]*)"
    r"(?=/|[\s\"'`;|&<>()]|$)")
```

Only the matched span is replaced (`out.append("AGENT_WORKTREE")`, `:287`). Test 59 (`test/hooks/guard-trusted-writes.bats:579-591`) passes on HEAD.

**Evidence:** `hooks/guard-trusted-writes.py:253-255`, `hooks/guard-trusted-writes.py:286-288`, `test/hooks/guard-trusted-writes.bats:579-591`, `docs/reviews/execution-logs/code-fact-check-r2-guard/bats-new.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt`

---

## Claim 11: "Any of these keeps the occurrence as an indicator: a `..` component, or a shell-expandable character ($ ` ~ \ * ? [ {), anywhere in the shell word, since the shell could turn it back into the config dir"

**Location:** `hooks/guard-trusted-writes.py:246-248`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same mechanism and evidence as Claim 7 (the code comment restates the docstring); does not establish a bypass for unquoted words.
**Replicate verdicts:** r1=Incorrect (compound) · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r2: "does not establish any failure of the character set itself for unquoted words" (same substance as r1's scope) · r3: same annotations as Claim 7 (r3 verdicted docstring and comment as one claim, 6a)

"Anywhere in the shell word" is false: the scan stops at quote characters (`_WORD_DELIM`, :259), so `..`/`$`/`~` or a literal home/config-dir prefix inside a quoted segment of the same shell word are not seen:

```python
# hooks/guard-trusted-writes.py:259-260
_WORD_DELIM = set(" \t\n\"'`;|&<>()")
_WT_UNSAFE = re.compile(r"[$`~\\*?\[{]|(^|[/=])\.\.(/|=|$)")
```

See Claim 7 for the full function and executed output. E3 (r1), old hook → new hook:

```
deny     -> defer    | cd ~ && echo x > .claude/wt-x"/.."/settings.json
deny     -> defer    | cd ~ && echo x > .claude/wt-x"/../hooks/"evil.sh
deny     -> defer    | echo x > "$HOME"/.claude/wt-x"/.."/settings.json
deny     -> defer    | echo x > '/tmp/tmpfgzp5y_a/home'/.claude/wt-x'/..'/hooks/evil.sh
```

**Evidence:** `hooks/guard-trusted-writes.py:259-260`, `hooks/guard-trusted-writes.py:274-285`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe.txt`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-shell_demo.txt`

---

## Claim 12: "a prefix that is the home dir itself (`~/.claude/wt-x`, `$HOME/...`, the literal home path); a worktree path that equals, contains or lies inside the config dir."

**Location:** `hooks/guard-trusted-writes.py:249-251`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unquoted spellings (correct; tests 58 and 60 pass) and quote-split / double-`=` spellings (refuted); does not establish reachability of HARD entries for the home-prefix residue alone.
**Replicate verdicts:** r1=Incorrect (compound) · r2=— · r3=Incorrect
**Replicate annotations:** r1: "The last row shows the 'directly under the home dir' condition also fails when the home prefix is quoted (that row alone reaches only `~/.claude/wt-x/…`, not a HARD entry)" · r3: same annotations as Claim 8 (r3 verdicted docstring and comment as one claim, 6b)

Same mechanism and evidence as Claim 8: `_is_home_or_cfg` (`hooks/guard-trusted-writes.py:265-270`) sees only the word-local prefix, so a quote before `/.claude` leaves prefix `/`, and a second `=` leaves `b=<home>/`. Probe: `echo x > "$HOME"/.claude/wt-x/settings.json` → new=defer, old=deny; `echo x > a=b=<literal home>/.claude/wt-x/settings.json` → new=defer, old=deny (paraphrased — no quote available because the probe lines are quoted in full under Claim 8).

**Evidence:** `hooks/guard-trusted-writes.py:262-290`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe.txt`

---

## Claim 13: "`=` is NOT a boundary: `a=/../x` is one path, so the whole word is checked, and an assignment's value (after the first `=`) is additionally checked on its own for the home / config-dir tests."

**Location:** `hooks/guard-trusted-writes.py:256-258`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `=` absent from `_WORD_DELIM`, the `[/=]` alternative in the `..` regex, and the first-`=` split; does not establish handling of a second `=` (`x=b=/…` checks only `b=/…`, which never starts with `/`), which matters only for home/config-dir spellings that carry no `..` or expandable char.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: a second `=` defeats the home test (see Claim 8) · r1: "does not establish handling of a quoted value (`x="/.."/.claude/wt-x/...`), which falls under the quote-split defect in Claim 5 [merged Claim 7]" · r1+r3 executed: `x=/../.claude/wt-x/hooks/y; cp a "$x"` → deny, `cp a x=/../.claude/wt-x/hooks/y` → deny, `dd of=<home>/.claude/wt-x/settings.json` → deny, `cp a --target-directory=<HOME>/.claude/wt-x/hooks` → deny

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

## Claim 14: "bash_targets() first neutralizes agent worktree segments … Other .claude occurrences are untouched." (brief item 2: neutralization cannot create or hide a HARD_FRAG match and runs before every indicator check)

**Location:** `hooks/guard-trusted-writes.py:292-308` (claim text also in commit ccda554 body)
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ordering within `bash_targets` and the textual non-interaction of the replacement with `HARD_FRAG`; does not establish that `_WT_SEG` matches only real worktree paths (it has no left boundary, so `/srv/foo.claude/wt-x/hooks/x` is also neutralized — probe: new=defer, old=deny; that string is not the config dir either way).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish that removing the worktree's `.claude` is safe — that is exactly what the quote-split bypass (Claim 5 [merged Claim 7]) exploits" · r2: "does not establish that neutralization never hides a reachable HARD target (it does — Claims 5 and 13 [merged Claims 7 and 20])" · r3: "The regressions found are in the indicator tests, via Claims 6a/6b [merged Claims 7-8, 11-12]" · r1: a real `.claude/hooks` nested after the segment survives (E5: `echo x > .claude/wt-x/.claude/hooks/y` → deny)

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

All later checks (`CLAUDE_MD`/`HOME_INDICATOR` :300, `SETTINGS_OR_HOOKS`/`CFG_INDICATOR` :303, `SOFT_FRAG` :306) use the rebound `cmd`. The replacement token `AGENT_WORKTREE` contains no `.claude`, so it cannot create a `HARD_FRAG` (`\.claude/hooks(/|\b)|\.claude/settings|managed-settings`, `:239`) match; `_WT_SEG` requires `wt-` or `worktrees/` immediately after `.claude/` (`:254`), so it cannot consume a `.claude/hooks` or `.claude/settings` occurrence.

**Evidence:** `hooks/guard-trusted-writes.py:239`, `hooks/guard-trusted-writes.py:253-255`, `hooks/guard-trusted-writes.py:292-308`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`

---

## Claim 15: "If the command only mentions such a path in prose (a heredoc or message), write that text with the Write tool and pass the file instead."

**Location:** `hooks/guard-trusted-writes.py:331-335`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers Write of a non-policy-named file (defer, even tainted) and a consumer such as `git commit -F <file>` (defer); does not establish that every consumer command is unflagged — one that itself contains a write primitive plus `CLAUDE.md` and a home indicator is still denied, and writing the text to a SOFT-named path (a `CLAUDE.md`, a `.claude/` path) asks when tainted.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not establish that every prose-carrying command has a file-argument form, nor that a Write whose own target is a policy path would be allowed" · r3: "does not establish … where the passing command still carries the prose inline" (heredoc `cat > /tmp/m <<'E' … ~/.claude/CLAUDE.md` → deny); `gh pr create --body-file` → defer · r1 confidence Medium, r3 High

The message avoids naming any path. E5:

```
defer    | git commit -F /tmp/msg.txt
tainted Write defer    | /tmp/msg.txt
tainted Write defer    | /srv/repo/docs/working/notes.md
```

`classify_path` inspects only the path, never the content (paraphrased — no quote available because this is an absence claim: `main()` passes only `fp` to `classify_path`, :342-345).

**Evidence:** `hooks/guard-trusted-writes.py:331-335`, `hooks/guard-trusted-writes.py:341-361`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-probe2.txt`

---

## Claim 16: "N15: do not point at the config-dir spelling: permissions.deny blocks it." / both deny reasons now say to make the change outside Claude

**Location:** `hooks/guard-trusted-writes.py:353-357` (Bash reason at `:331-335`; commit ccda554 body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text of both deny reasons; does not establish that "your own editor or shell" is outside every sandbox the user runs (a Claude-launched shell is not "outside Claude").
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish wording of the pre-existing SOFT ask messages" · r1+r3: only the basename is interpolated; no `~/.claude` spelling; the old `"~/.claude path, with review."` string is gone

The file-tool reason: `"symlink), so Claude's file tools cannot edit it. Make the change outside "` / `"Claude, in your own editor or shell, and review it there."` (`:356-357`). The Bash reason: `"Claude cannot write these: make the change outside Claude, in your own "` (`:332`). Neither names an editable path. Test 65 asserts `!= *"~/.claude path"*` and `== *"outside Claude"*` for both and passes (fails on 970e525).

**Evidence:** `hooks/guard-trusted-writes.py:331-335`, `hooks/guard-trusted-writes.py:353-357`, `test/hooks/guard-trusted-writes.bats:665-676`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-new.log`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-old.log`

---

## Claim 17: "Only those exact shapes are exempt: a `..` after them, a home/config-dir prefix, or any other `.claude` in the command still counts."

**Location:** `test/hooks/guard-trusted-writes.bats:519-520`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "a `..` after them still counts" part when a quote separates the segment from the `..`; does not dispute the home/config-dir and other-`.claude` parts (Claim 10; tests 58-60 pass). The test at `:549-561` only exercises unquoted `..`, which is why it did not catch this.
**Replicate verdicts:** r1=— · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r3: its 6a names this line as "same rule restated" and its 6b refutes the home/config-dir part for quote-split / double-`=` spellings (see Claim 8), which r2's scope does not dispute

A `..` after the segment is missed when a quote closes right after the segment: `echo x > ~/".claude/wt-a"/../settings.json` → new `defer`, old `deny` (probe P4; demo in `demo.txt`). Mechanism as in Claim 7 (paraphrased — no quote available because the mechanism code is quoted in full under Claim 7).

**Evidence:** `test/hooks/guard-trusted-writes.bats:519-520`, `test/hooks/guard-trusted-writes.bats:549-561`, `hooks/guard-trusted-writes.py:259-260`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt`

---

## Claim 18: "Red against 970e525: tests 54, 55, 56 (worktree allow), 62 (N12) and 65 (N15) fail; the rest are regression pins that already pass." (and "12 tests")

**Location:** commit `456bded` (message); tests at `test/hooks/guard-trusted-writes.bats:517-676`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full 70-test suite against both hook versions; does not establish that the regression pins (57-61, 63-64) catch the quote-split spellings in Claims 7/8 (they do not include any).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the pins do not cover quote-split forms · r2: `@test` count is 70 at HEAD and 58 at 970e525 · r3: no match to the logged test-count hallucination pattern

The diff adds tests numbered 54-65 (12 tests). Against the branch hook: `1..70`, all `ok`, exit 0. Against the 970e525 hook the only failures are:

```
not ok 54 Q-048: a Bash write into a .claude/wt-* worktree's hooks/ is not denied
not ok 55 Q-048: a Bash write into a .claude/worktrees/<name> worktree's hooks/ is not denied
not ok 56 Q-048: a worktree CLAUDE.md write is SOFT (defer; ask when tainted), not denied
not ok 62 Q-050 / N12: a per-file symlinked hook's checkout target is denied
not ok 65 N15: the resolved-path deny reason does not send the user to a denied path
```

**Evidence:** `test/hooks/guard-trusted-writes.bats:517-676`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-new.log`, `docs/reviews/execution-logs/2026-09-23-r3-guard-bats-old.log`

---

## Claim 19: "all fixtures use a temp HOME and CC_WEB_TAINT_DIR; nothing reads the real ~/.claude."

**Location:** commit `456bded` (Notes); code at `test/hooks/guard-trusted-writes.bats:30-38`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the per-test `setup()` used by all 12 new tests and `bare_host_layout()`; does not establish anything about suites outside this file.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

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

## Claim 20: "An unexpanded relative worktree path (cd ~ && ... .claude/wt-x/...) is exempt, which only reaches ~/.claude/wt-x, not a HARD entry."

**Location:** commit `ccda554` (message, Notes); code at `hooks/guard-trusted-writes.py:272-290`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the case where `~/.claude/wt-x` (or `.claude/worktrees/x`) is a symlink, including one created in the same command; true when `wt-x` is a real directory (`~/.claude/wt-x/hooks/…` and `~/.claude/wt-x/settings.json` are not HARD entries). Does not re-file pre-existing symlink bypasses that name no `.claude` at all (N2 class).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r3: the same `cd ~ && … .claude/wt-x…` shape reaches `~/.claude/settings.json` via a quote-split `..` (r3 executed: `cd ~ && echo '{"bypass":1}' > .claude/wt-x'/..'/settings.json` deferred and wrote `$HOME/.claude/settings.json`; r1 E3/E4 same with `"/.."`) · r1: "does not dispute that the *unquoted* `..` form is still denied"; "The `.claude/worktrees/x` form from `~` behaves the same way" · r1+r2: symlinked `wt-*` route; `ln -s` is an unseen A8 primitive, but the lost deny is caused by this diff · r3: "does not establish behavior when `~/.claude/wt-x` is a symlink"

The exemption is purely textual and ignores whether the segment is a link. Executed (`demo2.txt`, 2026-09-23T16:32:34-07:00, exit 0):

```
command: cd ~ && ln -s . .claude/wt-q && echo PWNED > .claude/wt-q/settings.json
new guard output: []
old guard decision: [deny]
shell exit=0
settings.json now: PWNED
```

Both occurrences are neutralized (empty prefix, suffix `""` / `/settings.json`), leaving `settings.json` with no config-dir indicator, so `bash_targets` returns None (paraphrased — no quote available because this is the combined flow of `:272-290` into `:303`, quoted in Claims 7 and 14). The 970e525 hook denied it. Probes P2/P3 (`cd ~ && echo x > .claude/wt-a/hooks/x`, `... .claude/worktrees/x/settings.json`) show the same new-defer / old-deny flip for a pre-existing link.

**Evidence:** `hooks/guard-trusted-writes.py:272-290`, `hooks/guard-trusted-writes.py:303`, `docs/reviews/execution-logs/code-fact-check-r2-guard/demo2.sh`, `docs/reviews/execution-logs/code-fact-check-r2-guard/demo2.txt`, `docs/reviews/execution-logs/code-fact-check-r2-guard/probe.txt`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-shell_demo.txt`

---

## Claim 21: "A worktree path next to `global-instructions` is still denied (that is a separate indicator, outside Q-048 [2])."

**Location:** commit `ccda554` (message, Notes); code at `hooks/guard-trusted-writes.py:225-226`, `:300-301`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a CLAUDE.md write under `<worktree>/global-instructions/`; does not establish the case of `global-instructions` naming a non-CLAUDE.md file (that rule pairs only with `CLAUDE_MD`).
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

`r"global-instructions"` is in `_HOME_INDICATORS` (`:226`) and survives neutralization; `if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):` (`:300`) fires. Probe: `echo x > /srv/repo/.claude/wt-foo/global-instructions/CLAUDE.md` → deny.

**Evidence:** `hooks/guard-trusted-writes.py:225-226`, `hooks/guard-trusted-writes.py:300-301`, `docs/reviews/execution-logs/2026-09-23-r3-guard-probe.log`

---

## Claim 22: "Per-file link targets are read at hook load, like the other target sets."

**Location:** commit `ccda554` (message, Notes); code at `hooks/guard-trusted-writes.py:103-121`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the loop runs at module import alongside `_HARD_FILE_TARGETS`/`_HARD_DIR_TARGETS`; does not establish from repo code that Claude Code spawns a fresh process per hook call (the wiring runs it as a command, which implies it, but the harness is external).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2+r3: fresh-process-per-call is external harness behavior, not checked (r1: "the script itself holds no cache across runs"; r2: "if it does … a link added mid-session is seen on the next call")

The loop is module-level code (`for _e in (CONFIG_DIR / "hooks").iterdir():`, `:117`), next to the other module-level target sets (`:103-110`). The wiring invokes it as a fresh command: `"command": "python3 {{CLAUDE_DIR}}/hooks/guard-trusted-writes.py"` (`hooks/wiring.json:55`).

**Evidence:** `hooks/guard-trusted-writes.py:96-121`, `hooks/wiring.json:55`

---

## Claim 23: "Copies resolve into the config dir and leave their source ungated."

**Location:** commit `ccda554` (message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 6: exact for hook copies; a copied CLAUDE.md's source is still SOFT (ask when tainted).
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Mostly accurate (compound)
**Replicate annotations:** r3: its compound (merged Claim 9) was Mostly accurate for the directory/dangling-entry reason, not for the copy half

See Claim 6 (`test/hooks/guard-trusted-writes.bats:659-662`: `assert_decision ask` on the tainted checkout CLAUDE.md after a copy). Precise version: "…leave their source out of the HARD tier." (paraphrased — no quote available because the test lines are quoted in full under Claim 6).

**Evidence:** `test/hooks/guard-trusted-writes.bats:653-663`, `docs/reviews/execution-logs/fact-check-guard-r1/cfc-new.txt`

---

## Claim 24: "install scripts and README install steps are untouched"

**Location:** commit `035869c` (message, Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file list of `970e525..035869c`; does not establish that the guide's new paragraph is consistent with every README step (README still installs the five logging/routing hooks as per-file links, which the guide now says Claude cannot edit at their checkout path).
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

The diff touches exactly `guides/bare-host-hook-wiring.md`, `hooks/guard-trusted-writes.py` and `test/hooks/guard-trusted-writes.bats` (paraphrased — no quote available because the claim is about absence of changes to other files, read from the assembled diff's `diff --git` headers).

**Evidence:** `guides/bare-host-hook-wiring.md:59-70`, `README.md:26-30`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`hooks/guard-trusted-writes.py:47-49`): the "shell word" scan stops at quotes, so `~/".claude/wt-a"/../settings.json`, `.claude/wt-x'/..'/settings.json` and `cd ~ && cp x ".claude/wt-a"/../hooks/h` now defer (970e525 denied) and do write the config dir — regression, executed end to end by all three replicates.
- **Claim 8** (`hooks/guard-trusted-writes.py:49-50`): the home / config-dir tests are defeated by a quote before `/.claude` or a second `=`; with a wt-shaped `CLAUDE_CONFIG_DIR`, a direct HARD write now defers.
- **Claim 11** (`hooks/guard-trusted-writes.py:246-248`): same `..`/expandable defect in the Q-048 block comment.
- **Claim 12** (`hooks/guard-trusted-writes.py:249-251`): same home/config-dir defect in the block comment.
- **Claim 17** (`test/hooks/guard-trusted-writes.bats:519-520`): "a `..` after them still counts" is false for the quoted form; the `..` test (`:549-561`) has no quoted case.
- **Claim 20** (commit `ccda554` Notes): the exempt relative form reaches HARD entries — via a symlinked `wt-*` (created in the same command) or a quote-split `..`.

### Stale
- none

### Mostly Accurate
- **Claim 6** (`hooks/guard-trusted-writes.py:30-31`): a copied CLAUDE.md's source is SOFT (ask when tainted), not "ungated"; say "out of the HARD tier".
- **Claim 9** (`hooks/guard-trusted-writes.py:111-121`): the loop also registers directory entries and dangling targets; a directory link makes its whole target tree HARD.
- **Claim 23** (commit `ccda554`): same imprecision as Claim 6.

### Unverifiable
- **Claim 3** (`guides/bare-host-hook-wiring.md:66-67`): "a hook deny has no approve option" is Claude Code harness behavior; needs a live session or the harness hook docs.

## Escalations

1. **Quote-split `..` / expandable-char bypass reaches HARD paths** — `hooks/guard-trusted-writes.py:259-290` (Claims 7, 11, 17, 20). Raised by r1+r2+r3 (Goal-Alignment Escalate). The Q-048 exemption lets `~/.claude/settings*.json` and `~/.claude/hooks/*` be written via a quote-split word (`"$HOME"/.claude/wt-x"/.."/settings.json`, `cd ~ && … ".claude/wt-z"/../settings.json`); denied at 970e525; self-contained repros exist; the regression pins do not cover quoted spellings. Addressee: orchestrator.
2. **Worktree-named symlink route** — `hooks/guard-trusted-writes.py:272-290`, commit `ccda554` Notes (Claim 20). Raised by r2 (Goal-Alignment Escalate); r1 and r3 note the case in claim prose. `cd ~ && ln -s . .claude/wt-q && echo … > .claude/wt-q/settings.json` now defers and writes settings.json. Addressee: orchestrator.
3. **Merge-blocking / fix-shape judgment on the regressions** — `hooks/guard-trusted-writes.py:272-290`. Raised by r2 (Out of scope: "whether the regressions should block merge or how to fix them (critics' call)"). Addressee: orchestrator (no critic named).
4. **Diff widens the known N2 quoted-spelling gap** — `hooks/guard-trusted-writes.py:196-198`. Raised by r3 (Out of scope + Claim 6a prose: "the diff widens the known gap"). Addressee: orchestrator.
5. **Bash writes to checkout paths of linked hooks remain ungated (text tier, pre-existing)** — `hooks/guard-trusted-writes.py:292-308` / `guides/bare-host-hook-wiring.md:59-63` (Claim 1). Raised by r1 (Out of scope). Addressee: orchestrator.
6. **"A hook deny has no approve option" needs harness verification** — `guides/bare-host-hook-wiring.md:66-67` (Claim 3). Raised by r3 (claim prose: needs a live Claude Code session or hook docs). Addressee: orchestrator.

## Verdict stability

- **Total clusters:** 24
- **Surfaced by 2+ replicates:** 19; all reporting replicates agreed on 17
- **Single-replicate detections:** 5 (Claims 3 [r3], 5 [r2], 10 [r2], 19 [r2], 24 [r2]) — trivially agreed
- **Disagreed (2):**
  - Claim 6 (`hooks/guard-trusted-writes.py:30-31`, copy leaves source ungated): r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
  - Claim 9 (`hooks/guard-trusted-writes.py:111-121`, N12 per-entry resolution comment): r1=Verified · r2=Verified · r3=Mostly accurate
- **Agreement rate:** 22/24 = 91.7% over all clusters; 17/19 = 89.5% over clusters surfaced by 2+ replicates. No disagreement touched an Incorrect verdict; all six Incorrect clusters were unanimous among reporting replicates. (Confidence-only difference: Claim 15 r1=Medium, r3=High.)
