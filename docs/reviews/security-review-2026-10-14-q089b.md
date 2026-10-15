Commit: 9001bf80

# Security Review — Q-089 unit B (live-verify-gate host-tool split)

**Scope:** `git diff cc2640b7 9001bf80` — `hooks/live-verify-gate.sh`, `test/hooks/live-verify-gate.bats`, `docs/decisions/log.md` (row 71), `guides/devcontainer-setup.md`, `guides/cc-isolated-usage.md`. Context read at 9001bf80: `devcontainer-config/{cc-isolated.sh,install.sh,Dockerfile}`, `hooks/wiring.json`, `hooks/guard-trusted-writes.py` header.
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report-q089b.md` (Commit 9001bf80); its mutation M3 is reused, not re-run.
**Iteration:** 1 of 3, unit B review-fix loop (`--loop-pass`), full scope.
**Probes:** fresh `mktemp -d` under `/home/node/.claude/jobs/00bcf178/tmp/`, the gate taken from `git archive 9001bf80 hooks/live-verify-gate.sh`, `HOME` redirected into the probe dir, `LC_ALL=C`, `GIT_CONFIG_NOSYSTEM=1`, every hook run under `timeout 20`. Scripts and logs: `docs/reviews/execution-logs/sec-q089b/` (`probe.sh`/`probe.log`, `probe2.sh`/`probe2.log`). Probe repos removed afterwards; no process left running.

The property under review is decision log 45's: **a commit that changes the boundary cannot leave live verification unasked.** Row 71 adds a second one: a commit that changes a host tool cannot leave host testing unasked. The gate is a process control, not an adversarial barrier. The runtime backstops are the manifest check plus the human-read bless diff for boundary files, and `verify_host_tools` for host tools. Each finding below says which backstop still holds.

## Trust Boundary Map

```
B1: [commit command text + -F file (agent-written)] → [has_trailer grep, per set]          → [commit allowed into repo history]
B2: [staged/working-tree paths (agent-written)]     → [enforcement / host_tools regexes]    → [which trailer is demanded]
B3: [staged diff text (agent-written)]              → [comment_only_diff, per set] (moved) → [trailer waived]
B4: [repo copy of hooks/live-verify-gate.sh]        → [claude-home payload → install/bless] → [root-owned live gate in /opt/claude-workflows/hooks]
B5: [committed devcontainer-config/ files]          → [install.sh + bless + verify_host_tools / manifest] → [host execution / image build]
```

B3 is marked moved: the escape now runs once per set instead of once over the union.

```
S1: tool_input.command (incl. chained commands)  — request-time  — UNTRUSTED for the "trailer present" decision; it is the gated party's own text
S2: -F/--file message file                       — request-time  — UNTRUSTED (same author as S1)
S3: git index / worktree path list               — request-time  — UNTRUSTED for set membership; the agent chooses paths, renames and pathspecs
S4: staged diff body                             — request-time  — UNTRUSTED for the comment-only waiver
S5: the two regexes in hooks/live-verify-gate.sh — repo-mutable  — UNTRUSTED toward the "which trailer" sink: any session can edit the repo copy, and the edit reaches the live gate at the next install (B4)
S6: host_tool_files()/enforcement_files()        — repo-mutable  — trusted as the definition of the sets; the bats pins treat it as the source of truth
```

What enters is wholly agent-authored: the command, the message, the paths and the diff. The gated party controls every input to the gate, which is why the gate claims only that the question gets asked and not that the answer is honest. The diff's new trust assumption is that S5 (two regexes) stays partitioned the way S6 says. Findings 2-5 are pre-existing gaps in B2/B3 that the split leaves unchanged. They were in scope because the caller asked whether any path lets a boundary file escape.

## Findings

#### 1. Moving a boundary file into `host_tools` is not caught; boundary commits then pass with only `Host-tool-tested:`

**Severity:** Medium
**Location:** `hooks/live-verify-gate.sh:73-78`; `test/hooks/live-verify-gate.bats:110-136` (and `:325-340`)
**Boundary:** B2, B4 (S5)
**Move:** 5 (invert the access-control model), 11 (bypasses)
**Confidence:** High (mechanism executed by the fact-check's M3)
**Legibility-target:** for-author

Evidence:

```bash
# test/hooks/live-verify-gate.bats:128-131
    git add "devcontainer-config/$f"
    run bash "$HOOK" <<< "$(payload 'git commit -m "x"')"
    [ "$status" -eq 2 ] || { echo "not gated: $f"; return 1; }
```

Fact-check Claim 32/36, M3: "25/25 green with `init-firewall.sh` moved to the host regex."

Before this diff, "exit 2" meant "needs `Live-verified:`", so the enforcement-set test pinned the property. After the split, exit 2 means "needs some trailer". The test only checks the exit code, so it stopped pinning which trailer. A one-token edit can move `init-firewall.sh`, `Dockerfile` or `egress/` from `enforcement` into `host_tools`. Every bats test stays green, and from then on a real firewall change commits with `Host-tool-tested: no — bats`. That is exactly the "boundary commit, live verification unasked" state that decision 45 exists to prevent. On who edits the gate: any agent session can edit the repo copy (S5), and the edit itself is ungated, since `hooks/` is in neither set. The edit reaches the live root-owned copy at the next `install.sh`. The backstop is the human reading the `claude-home/` diff at bless. That diff is large, and a regex alternation moving between two adjacent lines is easy to miss there, so it is a weak backstop. The likely cause is an honest refactor, such as "tidying" the alternation lists, rather than an attack. The stale header (Finding 6) makes that edit more likely.

**Recommendation:** In the `every manifest-hashed file` loop, also assert that `-m "Host-tool-tested: no — x"` alone still gives 2 and that `-m "Live-verified: no — x"` alone gives 0. In the host-tool loop, add the converse (it already asserts the first half). Add a disjointness check: no `enforcement_files()` entry matches `host_tools`. These are three asserts, no code change.

#### 2. A rename moves a gated file out of its path without any trailer

**Severity:** Medium
**Location:** `hooks/live-verify-gate.sh:63,67` (pre-existing; the header's `:29-32` claims renames fall through to the gate)
**Boundary:** B2 (S3)
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (`probe.log`):

```
== R1 rename a boundary file away (init-firewall.sh -> fw.sh)
   name-only: devcontainer-config/fw.sh
R1   exit=0  cmd=git commit -m x
== R2 rename a host tool away (cc-push.sh -> x.sh)
   name-only: devcontainer-config/x.sh
R2   exit=0  cmd=git commit -m x
```

`git diff --cached --name-only` applies rename detection by default and prints only the destination. When the destination is outside both regexes, the gated source path vanishes from `$files`. The `rename from` check in `comment_only_diff` never runs because nothing was touched. In both sets the runtime consequence fails closed today. The Dockerfile's `COPY init-firewall.sh` breaks the build, and `compute_host_tools_manifest` refuses ("host tool missing") at bless. Removing an `egress/*.txt` list narrows egress. So the gate's property is violated, but no widening was found. The header's claim that "a rename … falls through to the gate" is false for this direction. Both sets have the gap; the split neither adds nor removes it.

**Recommendation:** Add `--no-renames` to both `git diff --name-only` calls (probe N1: both sides then appear). It is a one-flag change that could ride along with this unit.

#### 3. `git commit <pathspec>` / `-o` / `-i` commits unstaged gated changes without a trailer

**Severity:** Medium
**Location:** `hooks/live-verify-gate.sh:62-68` (pre-existing)
**Boundary:** B2 (S3)
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (`probe.log`):

```
P1   exit=0  cmd=git commit -m x devcontainer-config/egress/base.txt
P1b  exit=0  cmd=git commit -m x -- devcontainer-config/cc-push.sh
P2   exit=0  cmd=git commit -o -m x devcontainer-config/cc-push.sh
P2b  exit=0  cmd=git commit -i -m x devcontainer-config/cc-push.sh
```

The gate reads the index, widened only for `-a`. A pathspec commit takes the named paths from the working tree, so an unstaged egress widening (P1) or host-tool change (P1b) lands with no trailer. `git commit -m msg file` is an ordinary agent habit, so this is an accidental bypass, not an exotic one. The backstops are unchanged: the bless diff, and `verify_host_tools` refusing an un-reblessed host tool.

**Recommendation:** When the command carries non-option operands after `commit` (or `-o`/`-i`/`--only`/`--include`), widen `files` the same way `-a` does, with `git diff --name-only` added. Over-gating is the safe direction. A follow-up unit is fine.

#### 4. `git -C <dir> commit` and `cd <dir> && git commit` are judged against the hook's cwd, not the committing repo

**Severity:** Medium
**Location:** `hooks/live-verify-gate.sh:57,63` (pre-existing)
**Boundary:** B2 (S3)
**Move:** 11, 3 (error path)
**Confidence:** Medium. Executed with a non-repo cwd, where `git diff` fails and the gate exits 0. With `/workspace` as cwd it would read the wrong index; that was traced, not run.
**Legibility-target:** for-author

Evidence (`probe.log`, `probe2.log`):

```
G1   exit=0  cmd=git -C …/repo-g1 commit -m x
D1   exit=0  cmd=cd …/repo2-d1 && git commit -m x
```

The commit regex explicitly accepts `-C <path>`, but the diff never uses that path. This repo commits into `.claude/wt-*` worktrees from an orchestrator whose cwd is `/workspace`. That is the normal shape of this review loop, so a boundary change committed into a worktree via `-C` is checked against the main checkout's index instead.

**Recommendation:** Extract the last `-C <path>` from the matched command and run every `git diff` with `-C "$path"`. Treat a leading `cd <path> &&` the same way, or fail closed (exit 2 with a message) when a `-C` or `cd` path is present but cannot be read. Follow-up unit.

#### 5. A shebang edit counts as comment-only and needs no trailer

**Severity:** Medium
**Location:** `hooks/live-verify-gate.sh:124-127` (pre-existing rule, now applied to the host set too)
**Boundary:** B3 (S4)
**Move:** 2 (implicit sanitization assumption)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (`probe2.log`):

```
S1   exit=0  cmd=git commit -m x      # cc-push.sh: #!/usr/bin/env bash -> #!/bin/sh
S2   exit=0  cmd=git commit -m x      # init-firewall.sh: #!/bin/bash -> #!/bin/sh
```

`#!` is a comment to the gate but not to the kernel. `cc-push.sh` and `init-firewall.sh` are executed directly (`install.sh:596` chmods both), so changing the interpreter changes what runs. The same applies to dropping or adding `set -euo pipefail` semantics via `#!/bin/bash -e`. The backstops still hold: `verify_host_tools` refuses the changed `cc-push.sh` until it is re-blessed, and the manifest diff shows `init-firewall.sh`. But the commit itself passes without a trailer. Each set is now judged separately, so this applies per set, and the split did not widen it.

**Recommendation:** In `comment_only_diff`, treat a changed line beginning `#!` as substantive (one `case` arm before the comment arm).

#### 6. Gate header, behaviour table and `wiring.json` still describe a one-trailer gate

**Severity:** Low
**Location:** `hooks/live-verify-gate.sh:1-43,84-89,100-101`; `hooks/wiring.json:27-28`
**Boundary:** B4 (S5)
**Move:** 1 (fact-check stale claims 26, 29)
**Confidence:** High
**Legibility-target:** for-author

Evidence:

```
# hooks/live-verify-gate.sh:37
#   - enforcement file staged, no trailer                              → exit 2 (blocks;
# hooks/wiring.json:27-28
"live-verify-gate.sh (blocks a `git commit` of a cc-isolated enforcement file whose",
"message has no Live-verified: trailer — decision log #45).",
```

The header is what the next editor of the guardrail reads. A header that does not name the two sets as a partition invites the regex shuffle in Finding 1. Low on its own, because it is documentation only.

**Recommendation:** Rewrite the header's WHAT IT ENFORCES and Behavior table for two sets and two trailers, and state that the sets must stay disjoint. Update the `wiring.json` description line.

#### 7. One trailer's value can satisfy the other trailer

**Severity:** Informational
**Location:** `hooks/live-verify-gate.sh:152-154`
**Boundary:** B1 (S1, S2)
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis

Evidence (`probe.log`):

```
T1   exit=0  cmd=git commit -m x -m "Host-tool-tested: no — see Live-verified: later"
T2   exit=0  cmd=echo "Live-verified: Host-tool-tested:" >/dev/null; git commit -m x
```

`has_trailer` matches `Name:` after any whitespace anywhere in the command plus `-F` text. A both-sets commit therefore passes on a single line that names the other trailer in passing. This is not rated Medium, because the gate deliberately does not judge the value, and an author who types `Live-verified:` has asked the question. That is the whole property. Anchoring to `^Name:` at line start in the message would tighten it. It would also break the heredoc and `-m` forms the existing tests accept, so that is not recommended now.

## Untested bypass candidates

- **Case-variant path on a case-insensitive install target.** Probe K1 shows `devcontainer-config/CC-PUSH.sh` is ungated (exit 0). It is not tested whether `install.sh`'s `git archive HEAD` extract onto a case-insensitive filesystem (a macOS host) would let it overwrite `cc-push.sh`. There was no such filesystem in the sandbox. If it did, `verify_host_tools` and the bless diff would still catch the content change. The same applies to the boundary set (pre-existing).
- **Quoted `-F` paths with spaces.** These are not extractable by `[^[:space:]]+` (fact-check Claim 31, pre-existing). The result is a false block (the safe direction), so it was not probed.
- **`git commit --amend` with a new `-m` over a commit that already contains gated changes, with nothing newly staged.** `$files` reads only the index delta, so the amended commit's existing gated content is not re-examined. This was traced, not run. The original commit already passed the gate, so this is only an amend that rewrites the message to drop its trailer.

Tested by trace and cleared: the `host_tools` `$` anchor vs the prefix-matched enforcement alternation. `cc-isolated.sh.orig` over-gates (the safe direction), and a path cannot be both `cc-push.sh` and `cc-push.sh/…`. Tracked files under `devcontainer-config/` in neither set: none (`git ls-tree -r 9001bf80 devcontainer-config/` minus both regexes is empty). `projects/*.profile` is hashed but written to the install dir by `--register`, not shipped by `install.sh`'s `PAYLOAD`. Rename of a host tool into `egress/` (R4): blocked for `Live-verified:`. Deleting a host tool (R3): blocked. Per-set comment-only escape with both sets touched (C1 both comment-only → 0; C2 boundary comment + host real → needs only `Host-tool-tested:`; C3 commenting out a real host line → 2): behaves as row 71 states, and no cross-set leak was found. Each call to `comment_only_diff` reads only its own set's paths (`:92-97`).

## Endorsement Claims

- **Claim:** When a commit touches both sets with substantive changes, each set's trailer is demanded independently. Supplying one set's trailer does not clear the other's demand, unless its text names the other trailer (Finding 7).
  **Location:** `hooks/live-verify-gate.sh:138-158`
  **Evidence:** executed
  **Verified:** bats T2 (fact-check), probe C2/C2b, fact-check G4.
  **Not verified:** the `-a` path with one set staged and the other only in the worktree.
- **Claim:** The per-set comment-only waiver for one set reads only that set's paths, so a comment-only edit in one set does not waive a substantive edit in the other.
  **Location:** `hooks/live-verify-gate.sh:90-97,139-140`
  **Evidence:** executed
  **Verified:** probes C1, C2, C3; fact-check G2/G3.
  **Not verified:** shebang lines (Finding 5) and `-o`/pathspec commits (Finding 3), which bypass the waiver's input entirely.
  **route: code-fact-check**

## Primitive sweep

Primitive: process exec / file read driven by agent-written input (`cat "$f"` on `-F` paths, `git diff -- <paths>`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `hooks/live-verify-gate.sh:150` `cat "$f"` | S1 (-F path) | `[ -r "$f" ]` | cleared. The read goes into a grep only, never into an eval or exec. A path to a large or special file is the agent DoS-ing its own commit. |
| `hooks/live-verify-gate.sh:95,97` `git diff -- "${touched_files[@]}"` | S3 | `--` separator; paths come from git's own name list | cleared. No option injection after `--`. |
| `hooks/live-verify-gate.sh:63,67` `git diff --name-only` | S3 | none needed | Finding 2 (renames), Findings 3 and 4 (wrong path set) |

No eval, deserialization or network use in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Boundary file movable into `host_tools` with all tests green | Medium | B2, B4 | `hooks/live-verify-gate.sh:73-78`, `test/hooks/live-verify-gate.bats:110-136` | High |
| 2 | Rename out of a gated path needs no trailer (pre-existing) | Medium | B2 | `hooks/live-verify-gate.sh:63,67` | High |
| 3 | Pathspec / `-o` / `-i` commit bypasses the index read (pre-existing) | Medium | B2 | `hooks/live-verify-gate.sh:62-68` | High |
| 4 | `git -C` / `cd &&` commit judged in the wrong repo (pre-existing) | Medium | B2 | `hooks/live-verify-gate.sh:57,63` | Medium |
| 5 | Shebang edit passes as comment-only (pre-existing) | Medium | B3 | `hooks/live-verify-gate.sh:124-127` | High |
| 6 | Header, behaviour table and wiring.json describe one trailer | Low | B4 | `hooks/live-verify-gate.sh:1-43`, `hooks/wiring.json:27-28` | High |
| 7 | One trailer's value satisfies the other | Informational | B1 | `hooks/live-verify-gate.sh:152-154` | High |

## Overall Assessment

The split does what row 71 says, and no path was found by which it lets a boundary file escape that the pre-split gate caught. Both-sets commits demand both trailers, the per-set comment escape does not leak across sets, and no tracked `devcontainer-config/` file falls in neither set. The one regression the diff introduces is Finding 1. The enforcement-set test lost its meaning when exit 2 stopped implying `Live-verified:`, so the partition between the two regexes is now unpinned in exactly the direction decision 45 cares about. It is fixable in place with three bats assertions, and it is the single thing to address before merge. Fixing Finding 6's header alongside it removes the most likely route to the swap. Findings 2-5 are pre-existing gaps in how the gate learns which paths a commit carries. Each fails closed at runtime (bless diff, `verify_host_tools`) but lets the commit itself through without a trailer. Finding 2's fix is one flag (`--no-renames`) and could ride along; 3-5 belong in a follow-up unit. Not safe to merge as-is only because of Finding 1. Endorsement claims are executed but scoped to the paths read.

## Goal-Alignment Note
- Success criterion (restated verbatim): report at /workspace/.claude/wt-q089b/docs/reviews/security-review-2026-10-14-q089b.md per the security-reviewer skill, `Commit: 9001bf80` at top.
- Answered: yes. Regex-swap severity judged (Medium, the one in-diff regression). The split's escape paths were probed: anchors, case, renames, files in neither set, and per-set comment escape with both sets touched.
- Out of scope: A1/A2 code below cc2640b7 (context only). A case-insensitive filesystem install was not available.
- Escalate: Findings 3-5 (pre-existing gate input gaps) as a follow-up unit, not blockers for unit B.
- Decisions I made: reported the pre-existing bypasses at Medium per the floor rule and marked them pre-existing rather than dropping them, because the caller asked for any escape. Rated Finding 7 Informational because naming a trailer is asking the question.
