# Code Fact-Check Report

**Commit:** 3e9e448
**Replication:** k=1 (confirmation pass after the review-fix loop cap)

**Repository:** `/workspace/.claude/wt-guard` (branch `ans/guard-q048-q050`)
**Scope:** net diff `970e525..3e9e448`: `hooks/guard-trusted-writes.py` (whole file read, 326 lines), `test/hooks/guard-trusted-writes.bats` (+345), `guides/bare-host-hook-wiring.md` (+14), and the commit message of 3e9e448. Also consulted: `hooks/wiring.json`, `README.md` bare-host setup, `hooks/log-usage.sh`, `hooks/log-usage-post.sh`, `docs/reviews/hallucination-patterns.md` (no logged pattern matches any claim below).
**Checked:** 2026-09-23
**Total claims checked:** 19
**Summary:** 11 verified, 4 mostly accurate, 0 stale, 2 incorrect, 2 unverifiable

Execution provenance (all runs: cwd `/workspace/.claude/wt-guard`, temp `HOME` under the scratchpad, `CLAUDE_CONFIG_DIR` unset, never the real `~/.claude`). `$S` = `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/gfc-final`.

| Run | Command | Exit | Timestamp (UTC) | Output |
|---|---|---|---|---|
| E1 | `bash $S/run-bats.sh` (part 1: `bats test/hooks/guard-trusted-writes.bats` at HEAD) | 0 (85/85 ok) | 2026-09-24T00:14:56Z | `$S/bats-head.log` |
| E2 | `bash $S/run-bats.sh` (part 2: HEAD bats file against the `970e525` hook, `$S/oldtree/`) | 1 (83/85; only tests 77 N12 and 80 N15 fail) | 2026-09-24T00:15:10Z | `$S/bats-old-hook.log` |
| E3 | `python3 $S/probe.py` (N12 edges, Bash to checkout paths, N15 messages) | 0 | 2026-09-24T00:15:59Z | `$S/probe.log` |
| E4 | `python3 $S/probe2.py` (hooks/lib and scripts/lib sourced by a linked hook) | 0 | 2026-09-24T00:16:46Z | `$S/probe2.log` |
| E5 | `python3 $S/probe3.py` (N15 Bash-message remedies) | 0 | 2026-09-24T00:17:36Z | `$S/probe3.log` |

(Timestamps come from the sandbox clock, which reads 2026-09-24 UTC while the session date is 2026-09-23.)

---

## Claim 1: "Symlinked global files can't be edited from Claude."

**Location:** `guides/bare-host-hook-wiring.md:59`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the heading's reach against the README bare-host layout; does not establish anything about the devcontainer layout, where hooks is a whole-directory link.

The body below the heading narrows it to `global-instructions/CLAUDE.md` and per-file hook links, and for those the heading holds (Claim 2). As a standalone statement it reads broader than what the code does. On the README layout a linked hook executes checkout code the guard does not tie to it. `hooks/log-usage.sh:11` resolves its own link and sources a sibling from the checkout:

```bash
# hooks/log-usage.sh:11
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/usage-common.sh"
```

E4 ran Edit against those sourced files in a README-shaped layout (`log-usage.sh` linked per file):

```
[Edit checkout hooks/log-usage.sh] deny
[Edit checkout hooks/lib/usage-common.sh] defer
[Edit checkout scripts/lib/skill-paths.sh] defer
```

The heading also covers the README's directory links (`README.md:15-24`: `ln -s ~/claude-workflows/skills ~/.claude/skills` and similar). Those are editable from Claude by design (SOFT). (paraphrased — no quote available because this is the SOFT branch of `classify_path`, `hooks/guard-trusted-writes.py:187-196`, applied to a path that the README layout makes live.) Precise version: "Global CLAUDE.md and per-file-linked hooks can't be edited from Claude through their checkout paths; code those hooks source (`hooks/lib/`, `scripts/lib/`) still can."

**Evidence:** `guides/bare-host-hook-wiring.md:59-64`, `hooks/log-usage.sh:11,14`, `hooks/log-usage-post.sh:20`, `README.md:13-30`, `$S/probe2.log`

---

## Claim 2: "the guard **denies** Claude's file tools on its checkout copy, in a tainted session or not: `global-instructions/CLAUDE.md` behind a linked `~/.claude/CLAUDE.md`, and every `hooks/<name>` linked one file at a time into `~/.claude/hooks/`"

**Location:** `guides/bare-host-hook-wiring.md:60-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers Edit/Write/MultiEdit on the checkout CLAUDE.md and on top-level per-file hook links, clean and tainted. It does not establish coverage of a link nested inside a real subdirectory of `~/.claude/hooks/`, which defers (E3), or of files a linked hook sources (Claim 1).

E3 output:

```
[per-file link target] deny
[checkout CLAUDE.md] deny
[checkout CLAUDE.md tainted] deny
```

The bats test `Q-050 / N12: a per-file symlinked hook's checkout target is denied` loops `clean`/`sess1` × `Edit Write MultiEdit` and passes in E1. It fails against the 970e525 hook in E2 (test 77), so the per-file part is new behaviour. The CLAUDE.md part already held at 970e525: E3 shows `[old checkout CLAUDE.md] deny`.

**Evidence:** `test/hooks/guard-trusted-writes.bats` (Q-050 section), `hooks/guard-trusted-writes.py:125-130,182-183,310-317`, `$S/probe.log`, `$S/bats-head.log`, `$S/bats-old-hook.log`

---

## Claim 3: "No deny rule names the checkout path, so deferring would leave it with no gate at all."

**Location:** `guides/bare-host-hook-wiring.md:64-65`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the deny list the repo ships in `hooks/wiring.json`. It does not establish what extra rules a user added by hand when merging it.

```json
// hooks/wiring.json:120-127
"Edit({{CLAUDE_DIR}}/settings*.json)", "Write({{CLAUDE_DIR}}/settings*.json)",
"Edit({{CLAUDE_DIR}}/hooks/**)",       "Write({{CLAUDE_DIR}}/hooks/**)",
"Edit({{CLAUDE_DIR}}/CLAUDE.md)",      "Write({{CLAUDE_DIR}}/CLAUDE.md)",
"Edit(~/CLAUDE.md)",                   "Write(~/CLAUDE.md)"
```

(Quoted lines reflowed two per row; the content is verbatim.) Every rule is anchored at `{{CLAUDE_DIR}}` or `~/CLAUDE.md`, and none names a checkout path such as `~/claude-workflows/...`.

**Evidence:** `hooks/wiring.json:115-129`

---

## Claim 4: "A hook deny has no approve option"

**Location:** `guides/bare-host-hook-wiring.md:65` (same claim at `hooks/guard-trusted-writes.py:29-30`)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers only that the hook emits `permissionDecision: "deny"` (`hooks/guard-trusted-writes.py:310-317`). It does not establish how the Claude Code UI presents a hook deny.

The hook side is confirmed: it emits `deny` (E3). Whether the harness offers the user no override is Claude Code runtime behaviour outside the codebase. To verify, trigger the resolved-tier deny in an interactive session and observe the prompt.

**Evidence:** `hooks/guard-trusted-writes.py:73-78,310-317`, `$S/probe.log`

---

## Claim 5: "Bash writes to that checkout path (`echo x > <checkout>/hooks/<name>`, `cp`) are NOT gated by this hook, only Edit/Write are: a pre-existing gap, alongside the N2/A8 ones in the hook's TODOs."

**Location:** `guides/bare-host-hook-wiring.md:66-68`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers Bash writes to a linked hook's checkout path and to the checkout CLAUDE.md. It does not establish other Bash write routes that N2/A8 already list.

The antecedent of "that checkout path" is the whole paragraph, which names both `global-instructions/CLAUDE.md` and linked hooks. For the CLAUDE.md, Bash writes ARE denied: `global-instructions` is a home indicator (`hooks/guard-trusted-writes.py:234-235`), and a `claude.md` mention plus any indicator makes the command HARD:

```python
# hooks/guard-trusted-writes.py:259-261
    # R1 / Q-035: CLAUDE.md plus any home/global indicator -> the global file may be meant.
    if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):
        return "hard"
```

For hook checkout paths, the claim holds only when the command text carries no `.claude` or config-dir literal. A checkout that lives under a `.claude` dir, as this worktree does, is denied. E3 output:

```
[bash echo > checkout hook] defer
[bash cp -> checkout hook] defer
[bash echo > checkout hook tainted] defer
[bash echo > checkout CLAUDE.md] deny
[bash cp -> checkout CLAUDE.md] deny
[bash checkout under /x/.claude/wt/hooks] deny
```

"Pre-existing" holds. The Bash tier is unchanged from 970e525 except for the message text: the only Bash-side hunk is `@@ -261,7 +289,10 @@`, the emit string. The N2/A8 TODOs exist at `hooks/guard-trusted-writes.py:200-218`. Precise version: "Bash writes to a linked hook's checkout path (…) are not gated … (Bash writes to the checkout CLAUDE.md are denied)."

**Evidence:** `guides/bare-host-hook-wiring.md:66-68`, `hooks/guard-trusted-writes.py:200-218,234-268`, `$S/probe.log`

---

## Claim 6: "Hooks installed as copies are not affected."

**Location:** `guides/bare-host-hook-wiring.md:68-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers Edit on the checkout source of a hook copied into `~/.claude/hooks/`, clean and tainted. It does not establish Edit on the copy itself, which is covered HARD and defers to the deny rule by design.

E3: `[copied hook source] defer`, `[copied hook source tainted] defer`. The bats test `Q-050: a repo hook file with no link into ~/.claude/hooks is not denied` asserts `assert_defer` for `copied.py` clean and tainted, and passes in E1.

**Evidence:** `hooks/guard-trusted-writes.py:125-130`, `test/hooks/guard-trusted-writes.bats` (Q-050 section), `$S/probe.log`, `$S/bats-head.log`

---

## Claim 7: "The planned copy-based install (edits are committed, then copied into `~/.claude` by `install.sh` after you approve them) removes this: no checkout file will be a live global file."

**Location:** `guides/bare-host-hook-wiring.md:69-71`
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers only the conditional mechanism (copies do not tie the checkout to the live file; Claim 6). It does not establish that `install.sh` exists or will behave as described, since the claim is about future work.

No `install.sh` exists at 3e9e448. (paraphrased — no quote available because the claim concerns an absent file.) The plan is referenced by commit `e80fa0b` ("docs(questions): file Q-054 to Q-057 from the copy-install plan"). The consequence follows from Claim 6 if every global file becomes a copy. The claim becomes checkable once `install.sh` lands.

**Evidence:** `guides/bare-host-hook-wiring.md:69-71`, commit `e80fa0b`

---

## Claim 8: resolved tier docstring — "… a bare host's checkout global-instructions/CLAUDE.md or a hook script linked one file at a time into a real ~/.claude/hooks/ (N12) … the hook returns "deny" itself … A regular-file COPY in ~/.claude leaves its source out of the HARD tier: a copied hook's source is ungated, a copied CLAUDE.md's source is SOFT (ask when tainted)."

**Location:** `hooks/guard-trusted-writes.py:22-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four named cases (linked CLAUDE.md, per-file hook link, copied hook, copied CLAUDE.md). It does not establish nested links or sourced libraries (Claims 1 and 11).

E3 shows deny for the linked CLAUDE.md and the per-file hook link, and defer for the copied hook clean and tainted. For the copied CLAUDE.md, the bats test `Q-050: with a regular-file ~/.claude/CLAUDE.md copy, the checkout file is not denied` asserts `assert_defer` clean and `assert_decision ask` tainted, and passes in E1. The SOFT outcome comes from the filename rule:

```python
# hooks/guard-trusted-writes.py:192-194
        if name in ("claude.md", "agents.md", "claude.local.md", "managed-settings.json") \
                or cand.suffix.lower() == ".mdc":
            return "soft"
```

**Evidence:** `hooks/guard-trusted-writes.py:22-33,162-197`, `$S/probe.log`, `$S/bats-head.log`

---

## Claim 9a: "No worktree exemption: Q-048 [2]'s exemption for agent worktrees (`.claude/wt-*`, `.claude/worktrees/*`) was tried and withdrawn … so a worktree Bash write that mentions `.claude` plus a policy name is denied"

**Location:** `hooks/guard-trusted-writes.py:49-54`
**Type:** Behavioral / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the absence of any worktree code path and Bash-tier behaviour identical to 970e525 on every Q-048 test. It does not establish coverage of Bash routes that were already ungated at 970e525 (N2/A8).

A grep for `wt-|worktree|neutral` in the hook matches only docstring lines 49, 50 and 54. (paraphrased — no quote available because this is an absence-of-code claim.) `bash_targets` (`hooks/guard-trusted-writes.py:253-268`) has no worktree branch:

```python
# hooks/guard-trusted-writes.py:253-258
def bash_targets(cmd: str):
    has_write = bool(WRITE_PRIMITIVE.search(cmd))
    if not has_write:
        return None
    if HARD_FRAG.search(cmd):
        return "hard"
(excerpt ends :258; enclosing bash_targets() continues to :268 — read)
```

`git diff 970e525 3e9e448 -- hooks/guard-trusted-writes.py` has five hunks. Two are docstring, one is the N12 block, and two are emit strings; none touches `bash_targets` or its regexes. E2 ran the HEAD bats file against the 970e525 hook. Every Q-048 test passed there, including the four flipped ones, all pass-1/2/3 bypass sets and the no-policy-name defer. The only failures were tests 77 (N12) and 80 (N15). So the flipped tests match 970e525 behaviour exactly.

**Evidence:** `hooks/guard-trusted-writes.py:49-55,219-268`, `$S/bats-head.log`, `$S/bats-old-hook.log`

---

## Claim 9b: "docs/reviews/code-fact-check-report*-pass{1,2,3}-*.md"

**Location:** `hooks/guard-trusted-writes.py:53`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what the glob resolves to in the committed tree at 3e9e448 and in the working tree. It does not establish whether the reports are committed before merge.

The reports this glob means (`code-fact-check-report-r{1,2,3}-pass{1,2,3}-<sha>.md`, `-pass1-035869c.md`) exist in the worktree but are **untracked** (`git status`: `?? docs/reviews/code-fact-check-report-r1-pass1-035869c.md`, …). The only tracked files the glob matches are `code-fact-check-report-pass2-r{1,2,3}.md`, which are unrelated cc-isolated reports (`**Commit:** 6edaa21`, branch `harden/cc-isolated-egress`, last touched in `5ec95c5`). As committed, the pointer reaches the wrong reports. It becomes accurate once the pass reports are committed. A narrower glob such as `code-fact-check-report-r*-pass*-*.md` would also avoid the pass2-r* collision.

**Evidence:** `hooks/guard-trusted-writes.py:53`, `docs/reviews/code-fact-check-report-pass2-r1.md:3-5`

---

## Claim 9c: "… and agents there use Edit/Write or absolute paths."

**Location:** `hooks/guard-trusted-writes.py:54-55`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the "absolute paths" remedy for the case the sentence describes (a worktree Bash write naming `.claude` plus a policy name). It does not dispute the Edit/Write remedy, which works (SOFT: defer, or ask when tainted).

An absolute worktree path still contains `.claude`, so an absolute-path Bash write that names a policy file is denied. The branch pins this itself: the test `Q-048 withdrawn: plain absolute worktree policy writes are denied, look-alike words or not` asserts deny for `"echo x > $wt/hooks/x.sh"` with `wt="$REPO/.claude/wt-foo"`, and passes in E1. E5: `[Bash echo > /srv/proj/.claude/wt-foo/hooks/x.sh] deny`. An agent that follows this advice is denied again. The commit message of 3e9e448 has the precise form ("use Edit/Write or absolute paths without a policy name for Bash"). The docstring dropped the qualifier, and absolute paths add nothing: any worktree Bash write that names no policy file defers, relative or not.

**Evidence:** `hooks/guard-trusted-writes.py:54-55,253-268`, `test/hooks/guard-trusted-writes.bats` ("plain absolute worktree policy writes are denied"), `$S/probe3.log`, `$S/bats-head.log`

---

## Claim 10: "Not gated here: Bash writes to a linked hook's CHECKOUT path (e.g. `echo x > <checkout>/hooks/<name>` on a bare host) get no opinion; only Edit/Write are denied there (N12). Pre-existing, alongside N2/A8."

**Location:** `hooks/guard-trusted-writes.py:56-58`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers Bash writes to a linked hook's checkout path. It does not establish anything about the checkout CLAUDE.md (correctly outside this sentence; Bash writes to it are denied, per pass-3 r3).

Unlike the guide (Claim 5), this sentence is scoped precisely to a *linked hook's* checkout path, so it does not contradict the checkout-CLAUDE.md denial. One qualifier is missing: "no opinion" holds only when the command names no `.claude` or config-dir literal. A checkout under a `.claude` dir (such as `/workspace/.claude/wt-guard/hooks/<name>`) is denied through `SETTINGS_OR_HOOKS` + `CFG_INDICATOR`:

```python
# hooks/guard-trusted-writes.py:262-264
    # A10: settings*.json / hooks plus the config dir named anywhere.
    if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
        return "hard"
```

E3: `[bash echo > checkout hook] defer`, `[bash checkout under /x/.claude/wt/hooks] deny`, `[bash checkout under $HOME (no .claude)] defer`. The gap is in the fail-open direction, but only for the common checkout location.

**Evidence:** `hooks/guard-trusted-writes.py:56-58,238-268`, `$S/probe.log`

---

## Claim 11: N12 comment — "resolve each entry: a checkout file that IS a live hook is HARD (resolved tier -> deny). A regular-file copy resolves into the config dir itself, which leaves its checkout original out of the HARD tier, as intended (a CLAUDE.md original still falls to SOFT and asks when tainted)."

**Location:** `hooks/guard-trusted-writes.py:119-130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the one-level per-entry resolution shown below. It does not establish: nested links inside a real subdirectory (not resolved: defer); files sourced by a linked hook (Claim 1); or the effect of an exception on one entry. The loop-level `except Exception: pass` abandons the remaining entries, which was static-read only.

```python
# hooks/guard-trusted-writes.py:125-130
try:
    for _e in (CONFIG_DIR / "hooks").iterdir():
        _t = _safe_resolve(_e)
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
except Exception:
    pass
```

Per-case behaviour, E3 (and E1 for the named bats tests):

| Case | Result |
|---|---|
| per-file link | target file denied (`[per-file link target] deny`) |
| directory link (`hooks/lib -> <co>/hooks/subdir`) | whole target dir HARD: existing and new files denied (`[dir-link target, new file inside] deny`) |
| dangling link | its nonexistent target is HARD: creating it is denied (`[dangling link target (nonexistent)] deny`) |
| `~/.claude/hooks` itself a symlink | target dir already HARD via `_HARD_DIR_TARGETS` (`:118`); `iterdir` follows it (`[hooks-dir-link target new file] deny`) |
| nested link in a real subdir | not resolved (`[nested link inside real subdir] defer`) |
| copy | checkout source defers (`[copied hook source] defer`) |
| no `~/.claude/hooks` | `iterdir` raises, caught, no change (`[no hooks dir, unrelated edit] defer`) |

The comment names only the per-file and copy cases, and both match. The dir-link, dangling and hooks-symlink outcomes are not described but are consistent with "resolve each entry". The dangling case is stricter than "IS a live hook", since the target does not exist yet; that errs toward denying.

**Evidence:** `hooks/guard-trusted-writes.py:100-130,182-183`, `$S/probe.log`, `$S/bats-head.log`

---

## Claim 12a: Bash deny message — "Claude cannot write these: make the change outside Claude, in your own editor or shell, and review it there. If the command only mentions such a path in prose (a heredoc or message), write that text with the Write tool and pass the file instead." (global targets)

**Location:** `hooks/guard-trusted-writes.py:291-295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers Bash-HARD commands aimed at the global config dir or global CLAUDE.md, and the prose workaround. It does not cover Bash-HARD commands aimed at a project's or worktree's own `.claude/` (Claim 12b).

For global targets the message points at no path (N15), and the global files are closed to Claude: the file tools defer to the deny rules (`:306-309`) or deny (`:310-317`). The prose workaround works. E5: `[Write msg file to scratch] defer`, `[Bash git commit -F msg file] defer`. The bats N15 test asserts `"outside Claude"` in the Bash reason and passes in E1.

**Evidence:** `hooks/guard-trusted-writes.py:285-299,306-317`, `$S/probe3.log`, `$S/bats-head.log`

---

## Claim 12b: Bash deny message — "Claude cannot write these: make the change outside Claude" (project / worktree `.claude` targets)

**Location:** `hooks/guard-trusted-writes.py:291-293`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the message as shown for Bash writes to a project's own `.claude/settings.json` or `.claude/hooks/` and to agent-worktree paths. It does not establish anything about global targets (Claim 12a).

`HARD_FRAG` matches any `.claude/hooks` or `.claude/settings`, project or global:

```python
# hooks/guard-trusted-writes.py:248
HARD_FRAG = re.compile(r"\.claude/hooks(/|\b)|\.claude/settings|managed-settings", re.I)
```

So a Bash write to a project's `.claude/settings.json`, or into an agent worktree, receives "Claude cannot write these: make the change outside Claude". For the file tools, those paths are SOFT (`:195-196`: `if ".claude" in low: return "soft"`), and Claude can write them. E5:

```
[Bash echo > /srv/proj/.claude/settings.json] deny
[Edit /srv/proj/.claude/settings.json (clean)] defer
[Bash echo > /srv/proj/.claude/wt-foo/hooks/x.sh] deny
[Edit /srv/proj/.claude/wt-foo/hooks/x.sh (clean)] defer
```

The message contradicts the hook's own remedy for exactly the withdrawal case: the docstring (`:54-55`) tells worktree agents to use Edit/Write, while the message says to go outside Claude. The replaced 970e525 text ("Edit it directly with review, not via a shell write") was accurate for this subset.

**Evidence:** `hooks/guard-trusted-writes.py:187-196,248,257-258,291-295`, `$S/probe3.log`

---

## Claim 13: resolved-tier deny message — "This path is a live protected policy file (…: a global hook, settings or CLAUDE.md, reached here by its real path or through a symlink), so Claude's file tools cannot edit it. Make the change outside Claude, in your own editor or shell, and review it there."

**Location:** `hooks/guard-trusted-writes.py:313-317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the message for existing linked targets and its N15 property (no `~/.claude path` pointer). It does not cover wording precision for not-yet-existing files under a directory-link or dangling target: "is a live protected policy file" is loose there.

```python
# hooks/guard-trusted-writes.py:313-317
            # N15: do not point at the config-dir spelling: permissions.deny blocks it.
            emit("deny", f"This path is a live protected policy file ({Path(fp).name}: a global "
                         "hook, settings or CLAUDE.md, reached here by its real path or through a "
                         "symlink), so Claude's file tools cannot edit it. Make the change outside "
                         "Claude, in your own editor or shell, and review it there.")
```

The N15 bats test asserts the reason lacks `~/.claude path` and contains `outside Claude`. It passes in E1 and fails against 970e525 in E2 (test 80). E3 shows the full text for `linked.sh`.

**Evidence:** `hooks/guard-trusted-writes.py:310-317`, `$S/probe.log`, `$S/bats-head.log`, `$S/bats-old-hook.log`

---

## Claim 14: "bash_targets no longer neutralizes `.claude/wt-*` / `.claude/worktrees/*`, so every `.claude` counts as an indicator again, as at 970e525. The worktree helpers and gate are deleted"

**Location:** commit `3e9e448` message
**Type:** Behavioral / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the hook at 3e9e448 against 970e525 on the whole HEAD bats file. It does not establish equivalence on Bash inputs outside that file, although the code-level diff shows no Bash-tier logic change (Claim 9a).

`git diff 053c0b7 3e9e448 --stat` shows `hooks/guard-trusted-writes.py | 147 ++---…` (50 insertions, 173 deletions across two files), and no worktree symbol remains (Claim 9a grep). E2: the 970e525 hook passes every Q-048 test in the HEAD bats file.

**Evidence:** `hooks/guard-trusted-writes.py:253-268`, `$S/bats-old-hook.log`

---

## Claim 15: "the four exemption allow tests are flipped to deny; every pass-1 and pass-2 bypass test stays as a deny test; pass-3 routes (-t.., .{,.}, env -C, install, find -delete + cp -P, git checkout, tar -x, cp -rs) are pinned as a new deny test; a worktree write naming no policy file still defers."

**Location:** commit `3e9e448` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test-file delta 053c0b7→3e9e448 and its pass status. It does not establish whether pass-3 found routes beyond the eight listed.

`git diff 053c0b7 3e9e448 -- test/hooks/guard-trusted-writes.bats` shows exactly four renamed `@test` lines whose bodies change from `assert_defer`/`ask`/exempt to deny (wt-* hooks, worktrees/<name> hooks, worktree CLAUDE.md, plain absolute + look-alikes). It adds two tests (`worktree write naming no policy file is not denied` with `assert_defer`, and `Q-048 pass 3: …`) and removes no other `@test`. The pass-3 test's commands include `-t..`, `.{,.}`, `env -C`, `install -t..`, `find … -delete && cp -P`, `git -C … checkout`, `tar -xf … -C`, `cp -rs`. All pass in E1 and against the 970e525 hook in E2.

**Evidence:** `test/hooks/guard-trusted-writes.bats` (Q-048 sections), `$S/bats-head.log`, `$S/bats-old-hook.log`

---

## Claim 16: "guide has no Q-048 text to remove."

**Location:** commit `3e9e448` message (Notes)
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `guides/bare-host-hook-wiring.md` at 3e9e448. It does not cover other docs or `docs/working/questions.md` entries about Q-048.

`grep -n -iE 'Q-048|worktree' guides/bare-host-hook-wiring.md` returns no lines. (paraphrased — no quote available because this is an absence-of-text claim.)

**Evidence:** `guides/bare-host-hook-wiring.md:1-80`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9c** (`hooks/guard-trusted-writes.py:54-55`): "agents there use … absolute paths": an absolute worktree path still contains `.claude` and is denied (the branch's own test pins it). Restore the commit message's qualifier ("absolute paths without a policy name"), or drop "or absolute paths".
- **Claim 12b** (`hooks/guard-trusted-writes.py:291-293`): the Bash deny message tells the user to go "outside Claude" for project and worktree `.claude/settings*.json` / `.claude/hooks/` writes, which Edit/Write can make (SOFT). This contradicts the docstring's Edit/Write remedy for worktrees.

### Mostly Accurate
- **Claim 1** (`guides/bare-host-hook-wiring.md:59`): the heading over-reads. Code sourced by a linked hook (`hooks/lib/`, `scripts/lib/`) stays editable from Claude.
- **Claim 5** (`guides/bare-host-hook-wiring.md:66-68`): "that checkout path" includes the checkout CLAUDE.md, whose Bash writes ARE denied. Scope the sentence to linked hooks, as the docstring does.
- **Claim 9b** (`hooks/guard-trusted-writes.py:53`): the report glob matches only untracked files, plus unrelated tracked `pass2-r*` cc-isolated reports. Commit the pass reports or narrow the glob.
- **Claim 10** (`hooks/guard-trusted-writes.py:56-58`): "no opinion" holds only when the command names no `.claude`/config-dir literal; a checkout under a `.claude` dir is denied.

### Unverifiable
- **Claim 4** (`guides/bare-host-hook-wiring.md:65`): "no approve option" is Claude Code UI behaviour. Verify by observing a hook deny in an interactive session.
- **Claim 7** (`guides/bare-host-hook-wiring.md:69-71`): the copy-based `install.sh` does not exist yet. Re-check when it lands.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 3e9e448` line."
- **Answered:** The exemption is gone: no worktree code remains, and the HEAD bats file passes against the 970e525 hook on every Q-048 test (E2), so 970e525's Bash-tier behaviour is restored. The N12 per-entry resolution was executed for per-file, directory, dangling, hooks-as-symlink, nested and copy cases. Both N15 messages and every sentence of the guide paragraph were checked. On brief item 3: the docstring's "Not gated here" sentence is precise about CLAUDE.md, but the guide's version is not (Claim 5).
- **Out of scope:** security judgement of the remaining ungated routes (nested links, sourced `hooks/lib`, Bash to checkout hooks); these are recorded as facts, not rated.
- **Escalate:** Claim 12b. The N15 Bash message now gives wrong advice for project and worktree `.claude` writes, the exact case the withdrawal routes to deny. Claim 9b: the docstring's report pointer is dangling unless the pass reports are committed before merge.
