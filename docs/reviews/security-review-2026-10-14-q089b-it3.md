Commit: 25d8f272

# Security Review — Q-089 unit B, iteration 3 (live-verify-gate, it2 fixes)

**Scope:** `git diff 79f22357 25d8f272`. Code: `hooks/live-verify-gate.sh` (the `comment_only_diff` diff calls), `test/hooks/live-verify-gate.bats` (three new tests, two new install.sh assertions, header). Prose: `guides/devcontainer-setup.md` (host-tools scope wording), decision log row 71. Context read at 25d8f272: the whole hook, the bats helpers, `.gitattributes`, `cc-isolated.sh` egress handling. HEAD 5baa9d2f adds only a questions doc; hook and tests are identical.
**Date:** 2026-10-14
**Based on:** iteration 2 `docs/reviews/security-review-2026-10-14-q089b-it2.md` (F1-F3); the it3 code-fact-check was not available to me when this was written.
**Iteration:** 3 of 3, unit B review-fix loop (`--loop-pass`), delta scope.
**Probes:** I ran everything in a fresh `mktemp -d` under `/home/node/.claude/jobs/00bcf178/tmp/`, using a `git archive 25d8f272 hooks test devcontainer-config` extract, with `HOME` redirected, `LC_ALL=C` and `GIT_CONFIG_NOSYSTEM=1`. Every hook run was under `timeout 20` and every bats run under `timeout 300`. Mutants were edited only in the extract. The script and log are in `docs/reviews/execution-logs/sec-q089b-it3/probe-it3.{sh,log}` (written, not committed). The probe dir was removed and no process was left running.

> ⚠️ **No code fact-check report for this iteration.** Claims about the gate's behaviour below rest on my own execution (mutant bats runs and direct hook runs), not on a fact-check.

The property is unchanged: a commit that changes the boundary cannot leave live verification unasked (decision 45), and one that changes a host tool cannot leave host testing unasked (row 71). The gate is a process control, not an adversarial barrier: the agent being gated also writes its inputs.

## Trust Boundary Map

```
B1: [commit command text + -F file (agent-written)]          → [has_trailer grep, per set]            → [commit allowed into history]
B2: [index/worktree path list, rendered by repo git config]  → [--name-only lists → two regexes]      → [which trailer is demanded]
B3: [staged diff text + repo git config/attributes] (moved)  → [comment_only_diff, per set]           → [trailer waived]
B4: [repo copy of the two regexes]                           → [bats pins]                            → [live gate after install]
```

B3 is marked moved: diff drivers (textconv, `diff.external`, `diff.<x>.command`) no longer shape the text the waiver reads.

```
S1: tool_input.command / -F file             — request-time — UNTRUSTED for the trailer decision
S3: git index / worktree path list           — request-time — UNTRUSTED for set membership
S4: staged diff body                         — request-time — UNTRUSTED for the comment-only waiver
S5: the regexes in live-verify-gate.sh       — repo-mutable — UNTRUSTED toward "which trailer"; pinned as far as bats reaches
S6: enforcement_files()/host_tool_files()    — repo-mutable — trusted as the set definitions
S7: .git/config + .gitattributes             — repo-mutable (agent-writable) — UNTRUSTED toward both the waiver (B3) and the name lists (B2)
S8: hook process cwd                         — set by the harness — trusted only if always the repo root (not verified)
```

The delta stops S7 from reaching B3 through diff drivers. S7 still reaches B2 through output-shaping config (`core.quotePath` by default, and `diff.relative` together with S8). The waiver's own comment rule also accepts `//` lines in every file, including the shell scripts (Finding 1). None of this is in the delta.

## Verdict on iteration-2 findings

All three are **closed**, and each fix is pinned by a test that goes red when the fix is reverted. I executed this: mutant bats runs against the 25d8f272 extract, 31 tests, and the clean run is green.

| it2 finding | Mutant | Red test |
|---|---|---|
| F1 `install.sh` movable into `host_tools` | `\|install\.sh$` dropped from `enforcement`, `install.sh$` (unescaped dot) added to `host_tools` | `not ok 9 install.sh is gated although it is not manifest-hashed` |
| F2 `--no-renames` on the `-a` call unpinned | flag dropped from line 77 | `not ok 29 a rename committed with -a ... is still gated` |
| F3 textconv driver fakes comment-only | `--no-textconv` dropped from both calls | `not ok 30 a repo-local textconv driver cannot make a real change read as comment-only` |

The F1 fix is behavioural (Host-tool-tested alone → 2, Live-verified alone → 0), so it holds under any spelling of the moved entry. This was the gap the it2 names-test could not close. For F3, the external-driver half (`--no-ext-diff`) works but is not pinned (Finding 2).

**Does `--no-textconv --no-ext-diff` change what the escape accepts for legitimate edits? No.** I made comment-only edits (a jsonc `//` line in `devcontainer.json`, `#` lines in `egress/base.txt` and `init-firewall.sh`). Without any diff driver, `git diff --cached -U0 --no-color` gave byte-identical output (same md5) with and without the two flags, under default config and 13 variants. All 14 configs let the edit through (exit 0), and all 14 gated a real jsonc change added on top (exit 2). The variants were `diff.noprefix`, `diff.mnemonicPrefix`, `color.diff=always`, `color.ui=always`, `diff.algorithm=patience|histogram`, `core.quotePath=false`, `diff.suppressBlankEmpty`, `diff.relative` (root cwd), `diff.renames=copies`, `diff.indentHeuristic=false`, `diff.colorMoved=zebra` and `diff.wsErrorHighlight=all`. The repo's committed `.gitattributes` (`* text=auto eol=lf`, `linguist-generated`) sets no diff driver, so no legitimate path depended on textconv. Without textconv, a binary-attributed file renders as `Binary files differ`, which the hook already treats as substantive: fail-closed.

On the other `-U0` shapers: prefix config only rewrites the `---`/`+++` headers, which the parser skips between `diff --git` and `@@`. `--no-color` overrides colour config. The diff algorithm cannot hide a non-comment change. If every `+`/`-` line is a comment, all non-comment lines of both sides lie in the common subsequence in order, so the non-comment line sequence is unchanged whichever algorithm is used. Two pieces of config that do matter act on the name lists, not on `-U0`: Findings 3 and 4.

The `guides/devcontainer-setup.md` scope wording narrows a statement, which widens what reviewers treat as enforcement files. That is the safe direction, and it opens nothing.

## Findings

#### 1. The `//` comment rule applies to every file, and bash executes a `//` line (pre-existing)

**Severity:** Medium
**Location:** `hooks/live-verify-gate.sh:142` (rule), `:101-102` (its stated scope)
**Boundary:** B3 (S4)
**Move:** 2 (implicit sanitization assumption), 11 (bypasses)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence:

```bash
# hooks/live-verify-gate.sh:101-102 (the intent) and :142 (the rule, applied to every file in the set)
# line is blank or a comment. `#` covers the Dockerfile, the shell scripts, the
# python and the egress/*.txt lists; `//` covers the jsonc devcontainer.json.
      '#'*|'//'*) continue ;;      # comment
```
```
# probe-it3.log, P3
P3 init-firewall.sh gains //usr/bin/curl line: exit 0
P3 bash runs a // line: RAN-AS-COMMAND
P3b cc-push.sh gains //bin/sh line: exit 0
```

`//` is a comment only in `devcontainer.json`. In the shell enforcement files and host tools, `//usr/bin/curl …` or `//bin/sh -c …` is a command, because POSIX treats `//` as the root path. Appending such a line to `init-firewall.sh`, `cc-isolated.sh`, `link-claude-home.sh`, `install.sh` or `cc-push.sh` adds code that runs as root in the firewall or on the host, and the commit passes with no trailer. This is the same waiver class as it2 F3, and it also bypasses mechanically. The fix is cheaper than F3's: no config is needed, only a line. It is not in the delta. The runtime backstop still holds, because the bless diff shows the bytes.

**Recommendation:** Accept `//` only for `devcontainer.json`. Track the current file from the `diff --git a/<path>` header and pick the comment prefix per file. Add a bats case: a `//bin/echo` line appended to an enforcement shell file → exit 2.

#### 2. `--no-ext-diff` is load-bearing but unpinned

**Severity:** Low
**Location:** `hooks/live-verify-gate.sh:111,113`; `test/hooks/live-verify-gate.bats` (only textconv is tested)
**Boundary:** B3 (S7)
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence:

```
# probe-it3.log — M-F3b mutant (both --no-ext-diff removed), full suite
== bats M-F3b drop --no-ext-diff: rc=0
1..31
# P1: egress/base.txt gains evil.example.com; diff.external = script printing "-# old/+# new"
P1 25d8f272, diff.external set, real widening: exit 2
P1 mutant (no --no-ext-diff), diff.external set: exit 0
P1b 25d8f272, diff.<x>.command via attributes: exit 2
P1b mutant (no --no-ext-diff), diff.<x>.command: exit 0
```

The current code is correct. Removing `--no-ext-diff` would reopen the external-driver half of it2 F3, through either `diff.external` or `diff=<x>` plus `diff.<x>.command`, and every test would stay green. This is the it2 F2 pattern again: a regression-guard gap, not a live bypass.

**Recommendation:** Add a bats case mirroring the textconv test: set `git config diff.external` to a script that prints a comment-only patch, stage a real change, and assert exit 2.

#### 3. A non-ASCII enforcement path is quoted by `core.quotePath` and escapes the regex (pre-existing)

**Severity:** Medium
**Location:** `hooks/live-verify-gate.sh:73,77,92-93`
**Boundary:** B2 (S3, S7)
**Move:** 11
**Confidence:** Medium (executed; a new non-ASCII egress file widens nothing until a profile names it, and `enforcement_files()` still hashes it, so the bless diff shows it)
**Legibility-target:** for-author

Evidence:

```
# probe-it3.log, P4 (new devcontainer-config/egress/bü.txt containing evil.example.com)
"devcontainer-config/egress/b\303\274.txt"
P4 new egress/b<u-umlaut>.txt, quotePath default: exit 0
P4 same, quotePath=false: exit 2
```

Under git's default `core.quotePath=true`, `--name-only` wraps any non-ASCII path in quotes. The `^devcontainer-config/` anchor then misses it, so the file is never classified and no trailer is asked for. This was listed as untested in it2; it is now executed. `core.quotePath=false` does not fully fix it, because a `"`, a tab or a newline in a name is quoted regardless.

**Recommendation:** Read the name lists with `-z` (NUL-separated, never quoted) on both name-only calls, and match each NUL-terminated entry. Alternatively, as a minimum, run `git -c core.quotePath=false`. This can join the F3-F5 "gate's unseen inputs" Idea.

#### 4. `diff.relative=true` hides paths outside a subdirectory cwd (pre-existing, conditional)

**Severity:** Medium
**Location:** `hooks/live-verify-gate.sh:73,77`
**Boundary:** B2 (S7, S8)
**Move:** 11, 1 (trace the trust boundaries)
**Confidence:** Low (depends on whether the harness ever runs the hook with a cwd other than the repo root, which I did not verify)
**Legibility-target:** for-author

Evidence:

```
# probe-it3.log, P5 (egress/base.txt widened and staged)
P5 subdir cwd, diff.relative unset: exit 2
P5 root cwd, diff.relative=true: exit 2
P5 subdir cwd, diff.relative=true: exit 0
```

With `diff.relative=true` set in `.git/config` (agent-writable), `--name-only` lists only paths under the cwd, relative to it. Run from the repo root, the setting does nothing. The gate fails closed when the cwd is a subdirectory and the setting is unset. It fails open only when both hold. This is the same family as F4 (`git -C`).

**Recommendation:** Pass `--no-relative` on the two name-only calls, or `cd "$(git rev-parse --show-toplevel)"` once at the top. Route it with Finding 3.

## Untested bypass candidates

- Heredoc or multi-line-string bodies in the shell and Python enforcement files: a `#` line inside them is data, not a comment. Adding or removing one is waived. Whether any current heredoc's data carries meaning in a `#`-led line was not checked. Pre-existing.
- `.git/info/attributes` or `core.attributesFile` as the driver source instead of `.gitattributes`: this is the same mechanism the two flags neutralize regardless of where the attribute comes from, so it was not run separately.
- `GIT_EXTERNAL_DIFF` or `GIT_DIFF_OPTS` in the hook's environment: the agent cannot set the harness's environment for the hook, and `--no-ext-diff` covers the former anyway. Not run.
- A case-insensitive filesystem: still unavailable here, as in it1 and it2.

## Endorsement Claims

- **Claim:** At 25d8f272, reverting any one of the three it2 fixes (the install.sh trailer pin, `--no-renames` on the `-a` call, `--no-textconv`) turns exactly one bats test red, and the unmutated suite is green (31/31).
  **Location:** `test/hooks/live-verify-gate.bats` tests 9, 29, 30
  **Evidence:** executed (probe-it3.log, mutant bats runs)
  **Verified:** one mutant per fix, full suite run against each.
  **Not verified:** other spellings of the F1 mutant beyond the unescaped-dot form (the assertion is behavioural, so the spelling should not matter, but only one was run).
- **Claim:** For a comment-only edit with no diff driver configured, adding `--no-textconv --no-ext-diff` leaves the `-U0` text byte-identical and the gate's decision unchanged, under default config and the 13 config variants listed above.
  **Location:** `hooks/live-verify-gate.sh:111,113`
  **Evidence:** executed (P2)
  **Verified:** md5 equality with and without the flags; exit 0 for comment-only, exit 2 with a real jsonc change added on top, in all 14 configs.
  **Not verified:** `/* */` block comments in the jsonc (not recognised either way, so they fail closed); combinations of variants.
- **Claim:** With `--no-ext-diff` in place, a `diff.external` driver or a `diff.<x>.command` driver cannot make a real egress widening read as comment-only.
  **Location:** `hooks/live-verify-gate.sh:111,113`
  **Evidence:** executed (P1, P1b)
  **Verified:** exit 2 on 25d8f272, exit 0 on the flag-dropped mutant.
  **Not verified:** the `-a` worktree call specifically (P1 used the index call; both lines carry the same flags).

## Primitive sweep

Primitive: `git diff` output rendered under agent-writable repo config (S3, S4, S7)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `hooks/live-verify-gate.sh:73` `git diff --cached --name-only --no-renames` | S3, S7, S8 | `--no-renames` | renames cleared (it2 F2). Quoted paths: Finding 3. `diff.relative`: Finding 4. Pathspec commits: F3 (pre-existing) |
| `hooks/live-verify-gate.sh:77` `git diff --name-only --no-renames` | S3, S7, S8 | `--no-renames` (now pinned, test 29) | Findings 3, 4 |
| `hooks/live-verify-gate.sh:111` `git diff --cached -U0 --no-color --no-textconv --no-ext-diff --` | S4, S7 | flags, `--` | drivers cleared (executed). Output-shaping config cleared (P2). `--no-ext-diff` unpinned: Finding 2. `//` rule: Finding 1 |
| `hooks/live-verify-gate.sh:113` `git diff -U0 --no-color --no-textconv --no-ext-diff --` | S4, S7 | flags, `--` | same as :111 (not separately probed for drivers) |

The `-F` file read at `:165` is unchanged (cleared in it1). There is no eval, deserialization or network use in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `//` accepted as a comment in shell files; bash runs it (pre-existing) | Medium | B3 | `hook:142` | High |
| 3 | Non-ASCII path quoted by `core.quotePath`, escapes gating (pre-existing) | Medium | B2 | `hook:73,77` | Medium |
| 4 | `diff.relative` plus a subdirectory cwd hides paths (pre-existing, conditional) | Medium | B2 | `hook:73,77` | Low |
| 2 | `--no-ext-diff` load-bearing but unpinned | Low | B3 | `hook:111,113` | High |

## Overall Assessment

The iteration-2 fixes are closed and each is pinned: reverting any one turns its own test red. The delta opens nothing. The new flags leave legitimate comment-only edits, the jsonc `//` case included, byte-identical across 14 git configs. Within the delta, the only gap is Finding 2, a missing test for `--no-ext-diff`, in the same mould as it2 F2. Findings 1, 3 and 4 are pre-existing and not in the delta. They belong with F3-F5 (the gate's agent-controlled inputs). Finding 1 is the single most important: it is executed, it lets root-run firewall code or host-tool code into a commit with no trailer, and its fix is one line plus one test. If the loop takes anything more before merge, take Finding 1 and the Finding 2 pin. Otherwise file both with F3-F5 and merge. For the delta: no findings beyond Finding 2 within the code paths read. All three endorsement claims are `Evidence: executed`, with their `Not verified` hops named.

## Goal-Alignment Note
- Success criterion (restated verbatim): report at /workspace/.claude/wt-q089b/docs/reviews/security-review-2026-10-14-q089b-it3.md per the security-reviewer skill, `Commit: 25d8f272` at top.
- Answered: yes. F1, F2 and F3 are judged closed, each by a mutant that turns its pin red. The delta was checked for new openings: none found. The `--no-textconv`/`--no-ext-diff` question for legitimate cases (jsonc comments) was executed across the listed configs, with no change in behaviour. Each named git config (`diff.noprefix`, `color.diff`, `core.quotePath`, `diff.mnemonicPrefix`, `diff.relative`, `diff.algorithm`, `diff.external`) was probed. Two act on the name lists (Findings 3, 4), and `diff.external` is neutralized but unpinned (Finding 2).
- Out of scope: F3-F5 (pathspec/`-o`, `git -C`, shebang), unchanged roadmap Ideas; the A1/A2 launcher code.
- Escalate: none. No HALT pattern. The merge decision under Q-148 [1] is the caller's: the delta is clean apart from the Low pin gap. Finding 1 is pre-existing but cheap and executed, so I recommend fixing it in this unit or filing it explicitly, not dropping it.
- Decisions I made: rated Findings 3 and 4 Medium under the floor rule (named mechanisms in an agent-writable config), with confidence lowered for their preconditions. Rated Finding 2 Low because the current code is correct. Probed `diff.relative` only with a hand-set subdirectory cwd, because I did not verify the harness's hook cwd. Wrote probe artifacts to `docs/reviews/execution-logs/sec-q089b-it3/` without committing them.
