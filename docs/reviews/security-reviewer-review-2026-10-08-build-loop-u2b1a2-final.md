Commit: 63ea50e7

# Security Review — feat/build-loop-u2b1a2 (final confirming pass)

**Scope:** `git diff feat/build-loop-u2b1a1...HEAD`, `scripts/build-loop.sh` (`--check`, `harden`, `state_gate`, `gate_repo`, `merge_result`, `check_line`) and the lib functions it calls (`resolve_main`, `check_branch`)
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check r1-r3 (shared brief summary); iteration-2 security review F1-F10; override-log rows 492-502

Probe safety: every probe made its own `mktemp -d /tmp/secu2b1a2b-XXXX`, checked `pwd -P` before running any fixture git command, and ran on a copy of `scripts/`. No fixture git command ran under /workspace. One background watcher (P2) ran under `timeout 20` and was killed inside its script. Cleanup checked afterwards: no probe processes, no probe directories, and the review worktree's status is unchanged.

## Trust Boundary Map

```
B1: [repo .git state: config, info/, shallow, refs]       → [state_gate, once at start]        → [every later git call]
B2: [ref namespace: refs/heads/*, refs/remotes/origin/HEAD] → [state_gate origin/HEAD rule; resolve_main] → [MAIN / MAIN_SHA: "the default branch"]
B3: [GATE_TMP (same-uid mktemp -d) git/ and work/]        → [gate_repo writes it, then nothing re-checks it] → [merge-tree's config/attributes]
B4: [object store: loose, packs, midx, alternates]        → [no check (F3 deferred)]           → [brief, settings, trees merge-tree reads]
B5: [merge-tree stdout + exit code (stderr discarded)]    → [merge_result: 40/64-hex first line, rc<=1] → [ok BRIEF TIP TREE]
```

| Label | Source | Mutability | Trust |
|---|---|---|---|
| S1 | `.git/config`, `config.worktree`, `info/*`, `shallow` | runtime-mutable (any same-uid loop) | UNTRUSTED for exec / merge-shaping sinks |
| S2 | `refs/heads/main`, `refs/heads/master`, `refs/remotes/origin/HEAD` | runtime-mutable | UNTRUSTED for choosing the default branch |
| S3 | `$GATE_TMP/git/{config,info/attributes}`, `$GATE_TMP/work/.gitattributes` | runtime-mutable during the run (same uid, path listable under TMPDIR) | UNTRUSTED for exec / merge-shaping sinks |
| S4 | objects under `.git/objects` | runtime-mutable | UNTRUSTED for content (F3) |
| S5 | caller environment (`git -c`, GIT_CONFIG_COUNT, TMPDIR) | deploy-time / caller | trusted (as the code states) |

A loop running as the same uid controls S1-S4. The diff trusts S2 when the name is `origin/main` or `origin/master`, and treats S3 as private to the gate once `gate_repo` has written it.

## Findings

#### F1. origin/HEAD → origin/master plus a loop-created local `master` makes a loop branch "the default branch" (F1 bypass)

**Severity:** High
**Location:** `scripts/build-loop.sh:196-199` (state_gate's origin/HEAD rule); `scripts/lib/dev-cycle-read.sh:486-495` (resolve_main)
**Boundary:** B2
**Move:** 11 (bypasses for every guardrail)
**Confidence:** High (executed, P1)
**Legibility-target:** for-author

**Evidence:**
```
  if [[ "$rc" -gt 1 ]] || [[ -n "$p" && "$p" != refs/remotes/origin/main && "$p" != refs/remotes/origin/master ]]; then
```
```
  origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  [[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")
```

The state gate lets origin/HEAD name either `origin/main` or `origin/master`, whichever branch is really the default. In a `main` repo, a loop runs `git branch master <any commit>` and `git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master` (the target need not exist). The gate passes, and resolve_main then takes `master`, a loop-written ref, as main. The brief status, the policy and never list, and the merge base are then all read from the loop's commit. P1: a brief that is `done` on the real main was reported `ok BRIEF TIP TREE`, exit 0, and refs/heads/main never moved. P1b, the related case: in a `master`-only repo, a loop-created `main` wins with no origin/HEAD at all (resolve_main tries `main` first), and the same done brief printed ok.

**Recommendation:** In `--check`, refuse when both `refs/heads/main` and `refs/heads/master` exist, and accept origin/HEAD only when it names the one that exists. Better, have the caller (the orchestrator) pass the default branch's name or SHA. Add P1 and P1b as tests.

#### F2. A merge driver or attributes planted in GATE_TMP mid-run runs a command inside merge-tree and turns a conflict into ok

**Severity:** High
**Location:** `scripts/build-loop.sh:447-456` (gate_repo), `:460-466` (merge_result), `:502` (`GATE_TMP="$(mktemp -d)"`)
**Boundary:** B3
**Move:** 4 (TOCTOU)
**Confidence:** High (executed: mechanism P2b; end-to-end race P2, 3 of 3 runs)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  printf '[core]\n\trepositoryformatversion = 1\n[extensions]\n\tobjectformat = %s\n' "$fmt" > "$GATE_TMP/git/config"
```
```
  out="$(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?
```

GATE_TMP is a same-uid directory under a listable TMPDIR. Nothing checks it between `gate_repo` writing it and `merge_result` reading it. That window is the whole of `check_line`, about 40 ms per brief in the fixture. merge-tree honours `$GIT_DIR/config` merge drivers and both `$GIT_DIR/info/attributes` and `./.gitattributes` in the work directory. P2b, run directly: with `[merge "ev"] driver = ...` and `* merge=ev`, the driver ran and the conflict exited 0. With only `* merge=union` in info/attributes, there was no command but still a clean wrong tree. P2, a concurrent watcher that plants once `git/config` is non-empty: the run that printed `refuse ... conflicts` without the watcher printed `ok BRIEF TIP TREE` with the attacker's tree, and the driver command ran, in 3 of 3 runs. This refutes override row 494's stated mitigation ("the gate repository closes merge-tree"). It also undercuts R2/A8's fix wording ("merge-tree reads none of the repo's config"). Reasoning, not separately probed: `info/grafts` and `shallow` in the gate dir are the same race, with no command needed.

**Recommendation:** A same-uid directory cannot be defended against a concurrent same-uid writer. Either run --check only when no loop process is running (orchestrator quiescence) and say so in the help and the plan, or run the gate in a private mount namespace (a bwrap `--tmpfs` TMPDIR, say) or under another uid. At minimum, amend row 494 and the gate_repo comment to name this race.

#### F3. "2 when git failed" also fails open when the merge base's root tree is missing: reported as a conflict, not a failure (fail-closed, mislabelled)

**Severity:** Low
**Location:** `scripts/build-loop.sh:460-466` (merge_result)
**Boundary:** B5, B4
**Move:** 3 (error path)
**Confidence:** High (executed, P3)
**Legibility-target:** for-author

**Evidence:**
```
  [[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2
  [[ "$rc" -eq 0 ]] || return 1
```

Lead (b) probed. A missing main-side subtree, merge-base subtree, any of the three blobs in a 3-way content merge, or the tip's subtree: each gave `refuse ...: the merge of feat/x could not be computed`. A missing merge-base root tree gave `refuse ...: feat/x conflicts with the default branch`, with git's `fatal: unable to read tree` reaching stderr from another call. A missing merge-base commit made check_branch skip. None of these printed ok. The only wrong ok in this class is Stage 1's missing tip tree, which is not re-reported here. The base-root-tree case refuses, so it is safe, but under the wrong reason.

**Recommendation:** None needed for safety. If the "conflicts" wording matters to U3's `--merge`, keep stderr and treat a `fatal:`/`error:` line as rc 2.

## Untested bypass candidates

- **Lead (c), packs shadowing loose objects:** not probed this pass. Static reading of git's lookup order (packs, including the multi-pack-index and alternates' packs, are searched before loose objects) suggests a planted pack can shadow an existing loose object, not only add one. If so, Stage 1's "alternates can only add objects" is incomplete. Either way F3's deferral row (492) should name every object source, not only "a loose object". Its proposed fix (re-hash the bytes read) would cover every source for blobs, but not trees or commits.
- **origin/HEAD race between state_gate and resolve_main** (each reads it separately): not probed. It is the same effect as F1 and is closed by the same fix.
- **Grafts or shallow planted in GATE_TMP:** reasoned, not run (see F2).

## Primitive sweep

Primitive: a command run by git through config or attributes

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:463` merge-tree (gate repo) | S3 | gate_repo's clean config, written once | F2 (race) |
| `lib:448` check_branch `git log` | S1 | state_gate, once | settled row 494 (F7) |
| `lib:486-495` resolve_main reads | S2 | state_gate origin/HEAD rule | F1 |

## Endorsement Claims

- **Claim:** With no concurrent writer, a missing main-side or merge-base subtree, or a missing 3-way blob, makes --check refuse ("could not be computed"), not print ok.
  **Location:** `scripts/build-loop.sh:460-475`
  **Evidence:** executed (P3, git 2.39.5, SHA-1)
  **Verified:** 8 deletions of loose objects, each refused or skipped
  **Not verified:** the same deletions in a SHA-256 repo or with packed objects
  **route: code-fact-check**

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---|---|---|---|---|
| F1 | origin/HEAD→origin/master plus a planted local master (or a planted main in a master repo) spoofs the default branch; done brief → ok | High | B2 | `build-loop.sh:196-199`; `lib:486-495` | High |
| F2 | GATE_TMP race: planted merge driver/attributes run a command in merge-tree; conflict → ok with attacker's tree | High | B3 | `build-loop.sh:447-466,502` | High |
| F3 | Missing merge-base root tree refuses as "conflicts", not "could not be computed" | Low | B5 | `build-loop.sh:460-466` | High |

## Overall Assessment

There are two High findings, both executed end to end, and both make --check print ok for a merge that is not the true merge of the tip into main. F1 is a direct bypass of iteration 2's F1 fix: allowing `origin/master` in a `main` repo is the hole. It is fixable in place. F2 is architectural: the gate-owned repository is only as private as a same-uid directory, so the claim that it "closes merge-tree" holds only when no loop is running. The fix belongs in the orchestration model (quiescence, or a private namespace/uid), and row 494 should be corrected. Lead (b) held: it found no new wrong ok. Lead (c) is untested and is listed for F3's deferral row.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 63ea50e7` line at the top.
- Answered: yes
- Out of scope: Stage 1's findings (not re-reported); lead (c) left unprobed
- Escalate: F1 and F2 (High) before landing
