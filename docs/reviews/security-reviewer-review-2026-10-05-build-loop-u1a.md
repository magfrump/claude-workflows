Commit: 722884c7

# Security Review — feat/build-loop-u1a (U1a, review-fix iteration 3, final confirming pass)

**Scope:** `git diff main...feat/build-loop-u1a -- . ':!docs/reviews'`: scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats. The focus is the main-commit readers (main_entry, brief_fields, check_answer), the trust boundary U1b and U3 will consume.
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check summary (k=3, Commit 722884c7; replicates `docs/reviews/code-fact-check-report-build-loop-u1a-r1/-r2/-r3.md`); iteration-2 report (this file at 2da477b7, F1 = A12, F2 = R2); override-log rows dated 2026-10-05.

## Iteration-2 findings: status at 722884c7 (executed)

All probes ran in scratch repos under `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i3/security/`. Trees were built byte by byte and written with `git hash-object -t tree --literally`, then `commit-tree` and `update-ref refs/heads/main`. Each probe ran `set -euo pipefail; source lib; resolve_main; main_entry …; out="$(check_answer Q-1)"`.

- **F1 / A12 (duplicate tree entries): FIXED.** `main_entry` now sets `dup` whenever a path repeats and answers `error`, at `scripts/lib/dev-cycle-read.sh:266` and `:269`. The probe results:

  | Tree shape on main | main_entry | check_answer |
  |---|---|---|
  | leaf `120000` then `100644` (the iteration-2 exploit) | `error` | skip |
  | leaf `100644` then `120000` | `error` | skip |
  | leaf two `100644` (answered first) | `error` | skip |
  | leaf `100644` and `100755`, same blob | `error` | skip |
  | parent `120000 working` then `040000 working` | `error` | skip |
  | parent `040000` then `120000` | `error` | skip |
  | parent two `040000` trees | `error` | skip |
  | a `working/questions.md` slash-named entry in `docs`, beside a real `working` tree that also holds `questions.md` | `error` (ls-tree prints both) | skip |
  | brief leaf `120000` then `100644`, via `check_brief` / `brief_fields` | | `skip …: the default branch's tree could not be read` / `BRIEF_ODD=error` |

  The iteration-2 exploit printed `keep Q-1`. It now prints `skip Q-1: the default branch's tree could not be read, so docs/working/questions.md is not read`. Bats test 67 also covers it.
- **F2 / R2 (failed `git cat-file` swallowed): FIXED under the documented caller contract (`-euo pipefail`).** Setup: questions.md holds Q-1 OPEN, the archive holds Q-1 ANSWERED [1], and the blobs of questions.md and a brief are deleted. Results:
  - `out="$(check_answer Q-1)"` gives `skip Q-1: docs/working/questions.md could not be read from the default branch`. In iteration 2 this was `keep Q-1`.
  - `brief_fields` gives rc=1 and `BRIEF_ODD=[error]`. In iteration 2 it gave rc=0 with no keys.
  - `check_brief` gives `skip …: the brief could not be read from the default branch`.
  - Run through `scripts/dev-cycle.sh`, both modes print the skip line and exit 0. In iteration 2 they exited 128 with no answer line.

  Under `set -eu` without pipefail, check_answer still prints `keep Q-1` and brief_fields returns 0 with no keys. Finding 1 below covers this.

Suite: `bats test/scripts/dev-cycle.bats` gives 66/67 with `TMPDIR` set to the scratch dir. Test 21 fails only on the dot-leading TMPDIR path component, per the orchestrator's note. The five new U1a tests (63–67) pass.

## Trust Boundary Map

```
B1:          [refs/heads/main | origin/HEAD in the shared .git]       → [resolve_main / main_by_name]                        → [MAIN_SHA, the trusted snapshot]
B2 (new):    [tree entries under MAIN_SHA]                            → [main_entry: one ls-tree -t, dup → error]            → [blob|absent|notfile|notdir PART|error]
B3 (moved):  [blob bytes at MAIN_SHA:path (via refs/replace if any)]  → [git cat-file | FENCE_AWK (+ANSWER_AWK), `|| skip`] → [BRIEF[...] / check_answer's option word]
B4 (removed for answers): [working tree docs/working/questions*.md]   → [no longer read by check_answer]                     → [—]
B5 (new):    [git/awk exit status inside $(...)]                      → [`|| { skip / BRIEF_ODD=error }`, needs pipefail]    → [caller's skip-or-answer decision]
B6:          [CLI args: brief path, Q-ID]                             → [pathform/isbrief, ^Q-[0-9]+$]                      → [git argv / awk -v]
```

```
S1: refs/heads/main, origin/HEAD          — runtime-mutable — UNTRUSTED toward authorization (anything with .git write can move it; plan F19);
                                                              the trust anchor by design (D8)
S2: tree objects under MAIN_SHA           — runtime-mutable — UNTRUSTED toward the "regular file under plain dirs" decision (malformed trees pass
                                                              local update-ref/commit-tree without fsck)
S3: blob contents on main                 — runtime-mutable — UNTRUSTED toward print/exec/path sinks; parsed only through FENCE_AWK
S4: CLI args (brief path, Q-ID)           — request-time    — UNTRUSTED; pathform/isbrief and ^Q-[0-9]+$ before any git/awk use
S5: questions file paths (two constants)  — code-constant   — trusted (all sinks)
S6: git exit status / object presence     — environment     — trusted as a signal only when the caller's pipefail lets it reach the `||` (B5)
S7: refs/replace/*, info/grafts           — runtime-mutable — UNTRUSTED toward every B3 read (cat-file and ls-tree honour replace refs)
S8: caller's shell options (pipefail)     — code-constant per caller — trusted for dev-cycle.sh (:83); unknown for U1b/U3 callers
```

The diff moves the answer reader off the loop-writable working tree (B4) and onto main's commit (B1–B3). main_entry is the guard that the B3 read hits a regular file under plain directories. Both iteration-2 gaps are closed (B2 duplicate handling, B5 error arm). Two assumptions remain implicit, and both concern future callers rather than dev-cycle.sh today. First, the caller's pipefail is what makes the B5 arm fire. Second, the snapshot B3 reads is only as fixed as refs/replace allows (S7).

## Findings

#### 1. The R2 fix rests on the caller's `pipefail`; under `set -eu` alone a missing questions.md blob still yields the archive's answer

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:559-560` (check_answer), `:295-302` (brief_fields)
**Boundary:** B5 (S6, S8)
**Move:** #3 (error path), #2 (assumed precondition)
**Confidence:** High (executed)
**Legibility-target:** for-author / U1b author

**Evidence:**
```
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
      || { echo "skip $a: $f could not be read from the default branch"; return; }
```
(excerpt ends :560; the enclosing check_answer() continues to :573 — read: an empty `r` `continue`s to the archive at :561.)

The `||` arm sees cat-file's failure only when pipefail is set. Without it, the pipeline's status is awk's, which is 0. Executed with `set -eu`, on the R2 fixture with questions.md's blob deleted: `check_answer` printed `keep Q-1`, and `brief_fields` returned 0 with `n=0 odd=[]`. With `-euo pipefail` both refuse, as shown above. The lib header states the contract ("The caller sets -euo pipefail") and dev-cycle.sh honours it (`scripts/dev-cycle.sh:83`). This is therefore not reachable today, and it is not filed above Informational. However, check_answer is the function U3's `--approved` merge gate will consume. Nothing in the lib enforces pipefail, whereas it does enforce ROOT_REAL through need_root. A caller that drops the option fails open silently, which is the R2 symptom.

**Recommendation:** Make the two readers self-sufficient with `local -; set -o pipefail` at the top of check_answer and brief_fields. `local -` (bash ≥ 4.4) restores the caller's options on return. Executed: inside such a function, `r="$(false | cat)" || …` takes the `||` arm, and pipefail is off again after return. Alternatively, test `[[ -o pipefail ]]` in a need_root-style guard.

#### 2. The main-commit readers honour `refs/replace`; D8's guarantee depends on `--state` (F51/T42) running before any consumer

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:263` (ls-tree), `:295`, `:559` (cat-file)
**Boundary:** B3 (S7)
**Move:** #1 (trust classification of a runtime-mutable source), #11 (bypass of the "answer must have reached main" guard)
**Confidence:** High (executed)
**Legibility-target:** for the orchestrator / U3 author

**Evidence:**
```
replace ref: keep Q-1
with GIT_NO_REPLACE_OBJECTS: open Q-1
```
(Probe: main's questions.md holds Q-1 OPEN; `git replace <that blob> <an ANSWERED blob>`; then `out="$(check_answer Q-1)"`.)

A process that can write `.git/refs/replace/` can make check_answer return an answer that main's commit does not hold. main does not move, so `git log main` and D13's `--main-log` show nothing. The plan already covers this class: F25/F51 ("`--state` at the start of each iteration", which refuses `refs/replace/`, T42) and F38 for the D6 extraction. No loop exists before U3, so it is not reachable in this unit. It is recorded so that the boundary U1b/U3 inherit is explicit: the lib's "reads the default branch's commit" holds only after `--state` passes, or under `GIT_NO_REPLACE_OBJECTS=1`.

**Recommendation:** No change in U1a. When U3 wires `--approved` to check_answer, its T42/T35 tests should include a blob replace ref on questions.md, and should show either that `--state` refuses first or that the gate's git calls carry `GIT_NO_REPLACE_OBJECTS=1`.

## Untested bypass candidates (main_entry guard)

Iteration-2 candidates (override-log C8), now dispositioned:
- A gitlink at the leaf **tested**: `notfile`, then skip. A gitlink at the parent **tested**: `notdir docs/working`, then skip.
- core.quotePath: traced only. pathform's NAMECHARS is ASCII `[A-Za-z0-9._/-]`, so no requested name is quoted. Not executed under odd configs.
- `./x` from a subdirectory: traced only. pathform rejects `.` segments, and both readers call pathform first (check_brief at :323, brief_fields at :292). Not exercised.

New this pass, **tested**: slash-named tree entries (`working/questions.md` stored inside `docs`). A 100644 entry alone, beside a `working` tree without questions.md, gives `blob`, and cat-file reads that same 100644 blob. That is consistent and not a symlink read: `git show main:docs/working/questions.md` reads it too. Paired with a real or symlink `questions.md` under `working`, ls-tree prints the path twice, so the answer is `error`. A 120000 slash-named entry gives `notfile`.

Not tested: `GIT_ICASE_PATHSPECS` / `GIT_GLOB_PATHSPECS` in the caller's environment (deploy-time S8-class; the map is keyed by exact path and cat-file is exact, so an extra case-variant line could only add an entry, never change the exact key's mode). The other candidate is ls-tree exiting 0 with a partial listing on a damaged tree. Stage-1 found none; only a missing subtree was probed, and it gave exit 1 and `error`.

## Endorsement Claims

- **Claim:** At 722884c7, main_entry answers `error` for every duplicate-entry tree probed (leaf and parent, every order and mode pairing listed above), and both callers turn `error` into a skip.
  **Location:** `scripts/lib/dev-cycle-read.sh:264-269`, `:335`, `:555`
  **Evidence:** executed
  **Verified:** 8 crafted trees on main through `main_entry` and `check_answer`, and 1 through `check_brief`/`brief_fields` (table above); bats test 67.
  **Not verified:** duplicates more than two levels above the leaf (e.g. a duplicated `docs`), which go through the same `dup` flag but were not executed.
  **route: code-fact-check**
- **Claim:** Under `set -euo pipefail`, a blob that main_entry calls `blob` but cat-file cannot read is a skip in check_answer (no fall-through to the archive) and `BRIEF_ODD=error`, rc 1, in brief_fields.
  **Location:** `scripts/lib/dev-cycle-read.sh:295-302`, `:559-560`
  **Evidence:** executed
  **Verified:** R2 fixture with deleted blobs: via the sourced lib in `$(...)`, and via `scripts/dev-cycle.sh --check-answer` / `--check-brief` (skip line, rc 0).
  **Not verified:** the same under `set -eu` without pipefail (fails open: Finding 1); a failure of awk alone.
  **route: code-fact-check**
- **Claim:** check_answer opens no working-tree path. Its only reads are `main_entry "$f"` and `git cat-file blob "$MAIN_SHA:$f"`, with `f` from a two-element constant list.
  **Location:** `scripts/lib/dev-cycle-read.sh:549-560`
  **Evidence:** executed (bats test 63: a working-tree-only answer reads `open`; a removed working-tree file reads main's `drop`) and read-static
  **Verified:** read check_answer :545-573; test 63 passes.
  **Not verified:** reads through `refs/replace` (Finding 2).
  **route: code-fact-check**
- **Claim:** The Q-ID reaches `awk -v id=` only after matching `^Q-[0123456789]+$`, so awk's `-v` escape processing has no backslash to act on.
  **Location:** `scripts/lib/dev-cycle-read.sh:547`, `:559`
  **Evidence:** read-static
  **Verified:** the regex test at the top of check_answer returns before any git or awk call.
  **Not verified:** U3 callers that build ANSWER_AWK invocations themselves.

## Primitive sweep

Primitive: process exec of `git` / `awk` with repo- or argument-derived argv

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:263` `git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1"` | S4, S5, S2 | `--`, pathform by caller, hash-only MAIN_SHA, dup → error | cleared (iteration-2 F1 fixed); S7 → Finding 2 |
| `scripts/lib/dev-cycle-read.sh:295` `git cat-file blob "$MAIN_SHA:$1" \| awk "$FENCE_AWK"…` | S4, S3 | pathform + main_entry == blob in-function; `\|\| BRIEF_ODD=error` | cleared under pipefail; Findings 1, 2 |
| `scripts/lib/dev-cycle-read.sh:559` `git cat-file blob "$MAIN_SHA:$f" \| awk -v id="$a"` | S5, S4 (Q-ID), S3 | main_entry; `^Q-[0-9]+$`; `\|\| skip` | cleared under pipefail; Findings 1, 2 |
| `scripts/lib/dev-cycle-read.sh:355-356` `git log … -G'^Status: ' "$MAIN_SHA" -- "$a"` (unchanged context) | S4 | pathform, isbrief, `--` | cleared, not changed by this diff |
| `scripts/dev-cycle.sh:196-204` check dispatch (`check_answer "$a"`, `check_brief "$a"`) | S4 | per-function validation; main_by_name gate at :192 | cleared; under `-euo pipefail` (:83) |

Primitive: printing repo text (S3). check_answer prints only an option word from ANSWER_AWK's `option()` and skip lines built from constant paths and line numbers. brief_fields prints nothing; it fills BRIEF with raw lines, with NUL, CR and LF excluded (test 66) and printing left to callers through scrub. git's own `fatal: … bad file` stderr line names only MAIN_SHA and a pathform-checked path. Cleared for this diff; U1b's printing of BRIEF values is out of scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | The R2 skip needs the caller's pipefail; under `set -eu` alone check_answer still answers from the archive | Informational | B5 | `scripts/lib/dev-cycle-read.sh:559-560`, `:295-302` | High |
| 2 | Readers honour refs/replace; D8 holds only once `--state` (F51/T42) has refused replace refs | Informational | B3 | `scripts/lib/dev-cycle-read.sh:263`, `:295`, `:559` | High |

## Overall Assessment

Both iteration-2 findings are fixed at 722884c7, confirmed by execution. Duplicate tree entries in every probed order and position are `error`, so no symlink's target text is read. An unreadable blob is a skip in check_answer and `BRIEF_ODD=error` in brief_fields, both via the sourced lib and via dev-cycle.sh. The D8 move works as intended: no working-tree path feeds an answer. No finding reaches Low or above within the code paths read. The two Informational items are contracts the next consumers inherit, not defects in this unit. The single most useful hardening before U3's `--approved` consumes check_answer is `local -; set -o pipefail` in the two readers (Finding 1). Every Endorsement Claim is `Evidence: executed` (one also read-static) or scoped with its `Not verified` hop named. Within that scope, this change is safe to merge from a security standpoint.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u1a/docs/reviews/security-reviewer-review-2026-10-05-build-loop-u1a.md (overwrite the iteration-2 one), first line `Commit: 722884c7`, structured per the security-reviewer skill, every finding with Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with the canonical Goal-Alignment Note.
- Answered: the iteration-2 F1 (A12) and F2 (R2) fixes, confirmed by execution at 722884c7; a security review of the main-commit readers as the boundary U1b/U3 consume. The result is no Low-or-above findings and two Informational contracts.
- Out of scope: the `--help` range regression (`2,80p`, fact-check Incorrect); it has no security bearing and belongs to the fact-check/API critics. Settled override-log rows 220–231 (incl. C8, now largely dispositioned by execution) and 208/209/215/216 are not re-raised. U1b/U1c printing of BRIEF values is also out of scope.
- Escalate: none blocking. For the U3 author: carry Finding 2 into the T35/T42 tests, and Finding 1 if `local -` is not adopted.
