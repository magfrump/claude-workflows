Commit: 4aa2e98e

# Security Review — feat/build-loop-u1a (U1a, review-fix iteration 4, final confirming pass)

**Scope:** `git diff main...feat/build-loop-u1a` code files: scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats (docs/reviews excluded). The focus is the main-commit readers (main_entry, brief_fields, check_answer) and the iteration-4 fix commit 4aa2e98e.
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check summary (k=3 at 4aa2e98e; replicates `docs/reviews/code-fact-check-report-build-loop-u1a-r1/-r2/-r3.md`); this file at 722884c7 (iteration 3, F1 and F2); override-log rows dated 2026-10-05 (220-238 for this branch).

## Iteration-3 findings: status at 4aa2e98e (executed)

All probes ran in scratch repos under `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i4/security/` on bash 5.2.15 and git 2.39.5, each under `timeout`.

- **Iteration-3 F1 (the R2 skip needed the caller's pipefail): FIXED.** Both readers now set pipefail themselves: `local - out l; set -o pipefail` (`scripts/lib/dev-cycle-read.sh:292`) and `local - a="$1" f e r hit="" where="" n why; set -o pipefail` (`:548`). The fixture: main's questions.md holds Q-1 OPEN and the archive holds Q-1 ANSWERED `[1] keep`. With both blobs present, the result is a "both files" skip. With questions.md's blob deleted from the object store, `out="$(check_answer Q-1)"` gives the following under each caller option set:

  | Caller options | check_answer output | caller pipefail after a direct call |
  |---|---|---|
  | `set -euo pipefail` | `skip Q-1: docs/working/questions.md could not be read from the default branch` | ON (unchanged) |
  | `set -eu` | same skip | off (unchanged) |
  | `set +e +u` | same skip | off (unchanged) |

  At 722884c7 the `set -eu` row printed `keep Q-1`. Three further probes:
  - An awk that fails alone (a PATH shim exiting 2, under `set -eu`) gives the skip in check_answer and `refused [error]` from brief_fields.
  - An early return (`check_answer bogus`) leaves the caller's pipefail off.
  - Neither awk program (FENCE_AWK, ANSWER_AWK) has an `exit` or `getline`. The pipefail arm therefore cannot fire on SIGPIPE from a well-formed read, so pipefail adds no false skips.
- **Iteration-3 F2 (readers honour `refs/replace`):** covered by override row 235 (Defer to U3b's `--state`, with GIT_NO_REPLACE_OBJECTS in U1b). It is not re-raised.

Suite: `bats test/scripts/dev-cycle.bats` passes 68/68, with `LC_ALL=C.UTF-8` and TMPDIR unset. That includes tests 60-68 for this unit, and test 67's no-pipefail case.

## Trust Boundary Map

```
B1:          [refs/heads/main | origin/HEAD in the shared .git]      → [resolve_main / main_by_name]                          → [MAIN_SHA, the trusted snapshot]
B2:          [tree entries under MAIN_SHA]                           → [main_entry: one ls-tree -t, dup → error]              → [blob|absent|notfile|notdir PART|error]
B3:          [blob bytes at MAIN_SHA:path]                           → [git cat-file | FENCE_AWK (+ANSWER_AWK), `|| skip`]    → [BRIEF[...] / check_answer's option word]
B4 (removed for answers): [working tree docs/working/questions*.md]  → [no longer read by check_answer]                       → [—]
B5 (moved):  [git/awk exit status inside $(...)]                     → [`local -; set -o pipefail` in-function, then `||`]    → [caller's skip-or-answer decision]
B6:          [CLI args: brief path, Q-ID]                            → [pathform/isbrief, ^Q-[0-9]+$]                        → [git argv / awk -v]
```

```
S1: refs/heads/main, origin/HEAD          — runtime-mutable — UNTRUSTED toward authorization (writable by anything with .git write; plan F19);
                                                              the trust anchor by design (D8)
S2: tree objects under MAIN_SHA           — runtime-mutable — UNTRUSTED toward the "regular file under plain dirs" decision
S3: blob contents on main                 — runtime-mutable — UNTRUSTED toward print/exec/path sinks; parsed only through FENCE_AWK
S4: CLI args (brief path, Q-ID)           — request-time    — UNTRUSTED; pathform/isbrief and ^Q-[0-9]+$ before any git/awk use
S5: questions file paths (two constants)  — code-constant   — trusted (all sinks)
S6: git/awk exit status, object presence  — environment     — trusted as a signal; now reaches the `||` whatever the caller's options (B5)
S7: refs/replace/*                        — runtime-mutable — UNTRUSTED toward B3 reads (override row 235)
S8: caller's shell options                — per caller      — no longer load-bearing for B5 (set in-function)
S9: $0 (dev-cycle.sh's own path, --help)  — deploy-time     — trusted (read-only sed over the script itself)
```

The diff moves the answer reader off the working tree, which the loop can write (B4), and onto main's commit (B1-B3). main_entry is the check that a B3 read hits a regular file under plain directories. The fix commit removes the last implicit precondition on B5: a failed read is now a skip under any caller options. This was executed under three option sets. The one remaining contract the next units inherit is S7, already deferred by row 235.

## Findings

No findings at Low or above. One Informational coverage note follows.

#### 1. `local -` portability (fact-check escalation) has no security bearing: every bash version fails closed

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:292`, `:548`
**Boundary:** B5 (S6, S8)
**Move:** #3 (error path)
**Confidence:** Medium. The bash 4.4-5.0 and pre-4.4 behaviour is reasoned from the fact-check's NEWS/CHANGES citations, not executed: only bash 5.2 is in the sandbox.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  local - out l; set -o pipefail
```
```
  local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields
```

The fact-check escalated `local -` to the api-consistency and architecture critics as a portability question. It is filed here only to record the security disposition, so that synthesis does not treat it as a fail-open risk.
- **bash ≥ 5.1:** pipefail is on inside the function and restored on return. Executed on 5.2.
- **bash 4.4-5.0:** `local -` may not restore pipefail, so pipefail could stay ON in the caller after return. That changes the caller's option hygiene, not the reader's decision. pipefail is still on during the read, so a failed read is still a skip.
- **bash < 4.4:** `local -` is an invalid identifier, so `local` returns non-zero. Under the documented `set -e` contract the function's shell exits before any read. Called as `out="$(check_answer …)"`, that gives an empty `out`, which the lib header says to treat as a refusal. Without `set -e`, `set -o pipefail` still runs, and the read is guarded.

In no case does a missing blob fall through to the other file or yield an answer. Whether to state a minimum bash version is an API/architecture call, not a security one.

**Recommendation:** None for security. If a minimum bash version is stated (api/architecture), 5.1 makes the "for this function only" comment at `:290-291` exact.

## Untested bypass candidates

For the guardrail this iteration changed (B5, the in-function pipefail plus the `||` skip):
- **Tested:** caller `set -eu`, caller `set +e +u`, caller `set -euo pipefail` (table above); awk failing alone; early return restoring options; test 67's `set -eu` case.
- **Listed, not tested:**
  - bash 4.4-5.0 and < 4.4. No such bash is in the sandbox; Finding 1 reasons that both fail closed.
  - A git that exits 0 with a truncated blob stream on a damaged pack. This was not constructible here: a deleted loose object gives exit 128, which was tested.

The main_entry candidates (a gitlink, core.quotePath, `./x`, slash-named and duplicate entries) were dispositioned in iteration 3 and in rows 230 and 236. They are unchanged by 4aa2e98e: main_entry has no diff since 722884c7.

## Endorsement Claims

- **Claim:** At 4aa2e98e, when main's questions.md blob is unreadable, check_answer prints a skip line under each of the caller option sets `-euo pipefail`, `-eu` and `+e +u`, and leaves the caller's pipefail setting as it found it.
  **Location:** `scripts/lib/dev-cycle-read.sh:548`, `:561-562`
  **Evidence:** executed
  **Verified:** deleted-blob fixture through the sourced lib under three option sets, in `$(...)` and as a direct call (table above); bats test 67.
  **Not verified:** bash versions before 5.1 (Finding 1).
  **route: code-fact-check**
- **Claim:** At 4aa2e98e, brief_fields returns 1 with `BRIEF_ODD=error` when its pipeline fails, under a caller with `set -eu` and no pipefail. This holds when cat-file fails (test 67) and when awk fails alone (PATH shim probe).
  **Location:** `scripts/lib/dev-cycle-read.sh:292`, `:297-304`
  **Evidence:** executed
  **Verified:** test 67's `set -eu` case, and the awk-exit-2 shim probe.
  **Not verified:** the U1b and U3 callers' handling of a `return 1` from brief_fields (not yet written).
  **route: code-fact-check**
- **Claim:** check_answer's only reads are `main_entry "$f"` and `git cat-file blob "$MAIN_SHA:$f"`, with `f` from a two-element constant list. A working-tree-only answer reads `open`.
  **Location:** `scripts/lib/dev-cycle-read.sh:547-575`
  **Evidence:** executed (bats test 60, T34) and read-static (the whole function, :547-575)
  **Verified:** test 60 passes; read every line of check_answer.
  **Not verified:** reads through `refs/replace` (override row 235).
  **route: code-fact-check**

## Primitive sweep

Primitive: process exec of `git` / `awk` / `sed` with repo- or argument-derived argv

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:263` `git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1"` | S4, S5, S2 | `--`, pathform by caller, hash MAIN_SHA, dup → error | cleared (unchanged since iteration 3); S7 → row 235 |
| `scripts/lib/dev-cycle-read.sh:297` `git cat-file blob "$MAIN_SHA:$1" \| awk "$FENCE_AWK"…` | S4, S3 | pathform + main_entry == blob; in-function pipefail; `\|\| BRIEF_ODD=error` | cleared (executed under `-eu`) |
| `scripts/lib/dev-cycle-read.sh:561` `git cat-file blob "$MAIN_SHA:$f" \| awk -v id="$a"` | S5, S4 (Q-ID), S3 | main_entry; `^Q-[0-9]+$`; in-function pipefail; `\|\| skip` | cleared (executed under three option sets) |
| `scripts/dev-cycle.sh:112` `sed -n '2,/^[^#]/{/^#/p}' "$0"` | S9 | none needed | cleared: reads the script's own header, read-only, no repo text |
| `scripts/dev-cycle.sh` check dispatch (`check_answer "$a"`, `check_brief "$a"`) | S4 | per-function validation; main_by_name gate before the loop | cleared; `-euo pipefail` script-wide |

Primitive: printing repo text (S3). check_answer prints only an option word or a skip line built from constant paths and line numbers. brief_fields prints nothing. Printing of BRIEF values belongs to U1b and later, out of scope. Nothing here changed since iteration 3.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `local -` portability fails closed on every bash version (coverage note, no action) | Informational | B5 | `scripts/lib/dev-cycle-read.sh:292`, `:548` | Medium |

## Overall Assessment

The iteration-4 fix closes the one open security contract from iteration 3. The main-commit readers now treat a failed blob read as a skip whatever the caller's shell options; this was executed under `-euo pipefail`, `-eu` and `+e +u`, and with awk failing alone. The caller's options are left as found on bash 5.2. The `--help` change reads only the script's own header and has no security surface. Nothing new reaches Low or above within the code paths read. The remaining boundary contract, refs/replace (S7), is settled as Defer by override row 235 for U3b. Every Endorsement Claim is `Evidence: executed` and names its `Not verified` hop. Within that scope, this change is safe to merge from a security standpoint.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/security-reviewer-review-2026-10-05-build-loop-u1a.md, structured per the security-reviewer skill, first line `Commit: 4aa2e98e`.
- Answered: yes. The iteration-3 F1 fix was confirmed by execution, there are no Low-or-above findings, and there is one Informational coverage note.
- Out of scope: the stale test title at test/scripts/dev-cycle.bats:767, the "until committed" help wording, the `2,/^[^#]/` comment precision and BSD sed's `{/^#/p}` parsing are fact-check/API items with no security bearing. Override rows 220-238 are not re-raised (row 235 is cited for refs/replace).
- Escalate: nothing.
- Decisions I made: I filed the `local -` escalation as a security coverage note, saying it fails closed, rather than as a finding. I did not execute it on bash < 5.1, because none is available.
