Commit: 6f624cdf

# Security Review — feat/build-loop-u2a1

**Scope:** branch diff `git diff main...HEAD` (6f624cdf, one commit on main 900c47d0), plus the enclosing functions and callers in scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, test/lib/build-loop-fixtures.bash, test/scripts/dev-cycle.bats
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2a1.md (Stage 1, k=1); docs/reviews/override-log.md rows 202-204, 228, 233, 284, 292, 298, 306-320

## Trust Boundary Map

```
B1: [caller-supplied path (--check-brief/--check-fix arg; U2a2: a changed path from diff-tree)] → [pathform → main_entry word] → [read of main's blob / refusal]
B2: [main_entry word + path]           → [entry_why]                        → [skip line on stdout, parsed by the orchestrating agent]
B3 (new for constraints.md): [agent-proposed in-cycle fix path] → [check_fix denylist + check_path] → [working-tree edit of user-owned docs]
B4 (moved): [brief paths listed from main's tree]  → [isbrief / isclosed]    → [writable, check_brief, shared_branches decisions]
B5: [test runner's inherited environment (GIT_DIR, GIT_CONFIG_*)] → [bl_setup / dev-cycle.bats setup] → [git writes in the fixture repo]
```

Input-source classification:

```
S1: --check-* argument path           — request-time (agent-chosen; prompt-injectable by repo text) — UNTRUSTED for path/read/edit sinks and for stdout line framing
S2: path from main's tree (ls-tree / diff-tree, U2a2) — runtime-mutable (any branch author)       — UNTRUSTED for stdout line framing and for gate decisions
S3: fixed file names (docs/dev-cycle.md, docs/constraints.md, questions files) — code-constant    — trusted (all sinks)
S4: main_entry's word                 — derived (code-constant vocabulary)                         — trusted as a closed set only while every consumer has a default-refuse arm
S5: inherited process environment     — deploy/run-time (hook context, user shell)                 — UNTRUSTED for "which repo do fixture git commands write to"
```

What enters: agent-chosen paths (S1) and, from U2a2 on, branch-author-controlled tree paths (S2). The diff splits main_entry's refusal vocabulary (`badform` beside `error`), routes every refusal's wording through one function that interpolates the raw path, narrows the in-cycle-fix allowlist, and closes the GIT_DIR exposure for one of the two bats suites that build git fixtures.

## Findings

#### 1. dev-cycle.bats still writes fixture commits into an inherited GIT_DIR repo; the fix landed in only one of the two suites

**Severity:** Medium
**Location:** `test/scripts/dev-cycle.bats:8-26` (setup, make_repo); contrast `test/lib/build-loop-fixtures.bash:3,11-13`
**Boundary:** B5
**Move:** 12 (sweep every call site of the engaged primitive: fixture git writes), 1
**Confidence:** Medium (executed; reachability depends on whether any hook runs the suite)
**Legibility-target:** for-author

**Evidence:**
```
# test/lib/build-loop-fixtures.bash:3
# $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as
# test/lib/build-loop-fixtures.bash:11-13
    # An inherited GIT_DIR (a run from a git hook, say) would send every
    # fixture command to that repo instead of the throwaway one.
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
# test/scripts/dev-cycle.bats:8-11
setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    DC="$REPO_ROOT/scripts/dev-cycle.sh"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
# test/scripts/dev-cycle.bats:22-26
make_repo() {
    mkdir -p "$1"
    (
        cd "$1" || exit 1
        git init -q -b "$2"
```

The diff resolves row 314 for build-loop-fixtures.bash, but dev-cycle.bats (also edited in this diff) builds its fixtures the same way and clears nothing. Executed: a scratch victim repo (`trunk`, 1 commit), then `GIT_DIR=<victim>/.git bats -f 'check-fix refuses files an instruction file imports' test/scripts/dev-cycle.bats`. Result: `warning: re-init: ignored --initial-branch=main`, and the victim afterwards held 3 commits and a new branch `f1` (`t feature 1`, `t initial` on top of `v victim`). Run from a git hook (the trigger row 314 names) with GIT_DIR set, the suite re-inits and commits into the user's real repo. The fixture header's "the same hermetic git environment as test/scripts/dev-cycle.bats" is now false in the unsafe direction: the copy is stricter than the original. Pre-existing on main; not introduced by this diff, but in a file this diff edits and on the exact mechanism the diff fixes next door.

**Recommendation:** Add the same unset line to dev-cycle.bats `setup()` (or have both call one shared helper), and correct the fixture header. A GIT_DIR-victim test like the one the fact-check ran for bl_setup pins it.

#### 2. entry_why interpolates the raw path into a skip line; for `badform` that path is by definition one pathform refused, including newlines

**Severity:** Low (latent: unreachable from current callers; becomes Medium the moment U2a2/U2c pass an S2 path)
**Location:** `scripts/lib/dev-cycle-read.sh:282-289` (entry_why), `:267` (badform), consumers `:352`, `:570`, `scripts/build-loop.sh:133`
**Boundary:** B2 (fed by B1)
**Move:** 2 (implicit sanitization assumption), 11
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
# scripts/lib/dev-cycle-read.sh:282-289
entry_why() {
  case "$1" in
    notdir\ *) echo "${1#notdir } is not a directory on the default branch" ;;
    notfile) echo "$2 is not a regular file on the default branch" ;;
    badform) echo "$2 is not an allowed path form" ;;
    error) echo "the tree of the default branch could not be read" ;;
    *) echo "the default branch answered $1 for $2" ;;
  esac
}
```

Every other skip line in the lib that names a refused-form path scrubs newlines first (`echo "skip ${a//$'\n'/ }: not an allowed path form"`, check_brief, check_path, check_write, check_fix). entry_why's `badform` arm is the one place a pathform-refused path is echoed unscrubbed. Executed: `main_entry $'docs/x.md\nok docs/constraints.md'` answers `badform`, and `echo "skip X: $(entry_why "$e" "$p")"` prints two lines, the second being `ok docs/constraints.md is not an allowed path form` — a forged line beginning `ok <path>`. Today every caller is safe: check_brief runs pathform (with scrub) first, check_answer and main_file pass fixed names (S3), so the fact-check's "default arm unreachable" also holds for badform's path content. U2a2's floor is the planned first caller that passes branch-controlled paths (S2), and a name holding a newline is one of the shapes Q-119 says it must refuse; if that refusal's reason goes through entry_why, the gate's own skip output becomes forgeable by the branch under review.

**Recommendation:** Scrub in entry_why itself (`${2//$'\n'/ }`, and the same for `$1` in the default arm) so the shared mapping carries the invariant its callers each repeat. A one-line lib test with a newline path pins it.

#### 3. `badform` now carries the most security-relevant changed paths (.gitattributes, .gitmodules, .github/…); U2a2 must refuse self-merge on it, not skip the path

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:250-262` (contract), `:266-267`
**Boundary:** B1
**Move:** 3 (error path), 5 (invert the access model)
**Confidence:** Medium (forward-looking; depends on U2a2 code not yet written)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
# scripts/lib/dev-cycle-read.sh:266-267
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
```

No fail-open today: all four consumers (check_brief, check_answer, main_file via `*)` arms; brief_fields via `!= blob`) treat badform as a refusal (fact-check, executed), and the contract comment says "only absent means there is none: every other word is a refusal". The new risk is semantic: `badform` reads as "not a path we handle", and in the floor the paths that answer it are .gitattributes (filters, diff/merge drivers), .gitmodules and .github/workflows — exactly the paths a self-merge must never wave through. Row 308 pins this for `error` only. A floor arm such as `badform) continue ;;` ("not a gate file") would be a fail-open path created by the split.

**Recommendation:** Extend row 308's revisit trigger to name `badform` explicitly: U2a2's floor refuses self-merge of the whole branch on any changed path answering anything but `blob`/`absent`, and a test changes `.gitattributes` and expects a refusal.

#### 4. bl_setup's unset list is narrower than git's own repo-local variable list

**Severity:** Informational
**Location:** `test/lib/build-loop-fixtures.bash:13`
**Boundary:** B5
**Move:** 11
**Confidence:** Low (not executed beyond listing the variables)
**Legibility-target:** for-author

**Evidence:**
```
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
```

`git rev-parse --local-env-vars` (git 2.39.5) also lists GIT_CONFIG, GIT_CONFIG_PARAMETERS, GIT_CONFIG_COUNT, GIT_IMPLICIT_WORK_TREE, GIT_GRAFT_FILE, GIT_NO_REPLACE_OBJECTS, GIT_REPLACE_REF_BASE, GIT_PREFIX, GIT_INTERNAL_SUPER_PREFIX, GIT_SHALLOW_FILE. A hook started by `git -c core.hooksPath=… commit` inherits GIT_CONFIG_PARAMETERS, which then applies to every fixture git command (running real hooks on fixture commits, or flipping core.useReplaceRefs under the replace-ref test). These do not redirect writes to another repo the way GIT_DIR does, so this is test integrity rather than host integrity.

**Recommendation:** `unset $(git rev-parse --local-env-vars)` in both suites' setup replaces the hand list (keep the explicit GIT_CONFIG_GLOBAL/NOSYSTEM exports after it).

## Bypass analysis (move 11)

Guardrail: check_fix's new `docs/constraints.md` refusal (B3). Executed against a scratch fixture repo with tracked `docs/constraints.md`, `docs/notes.md` and a symlink `docs/c.md -> constraints.md`, via `scripts/dev-cycle.sh --check-fix`:

| Candidate | Result |
|---|---|
| `docs/CONSTRAINTS.MD` (case) | skip: in-cycle fixes edit only… |
| `docs//constraints.md`, `docs/./constraints.md`, `docs/x/../constraints.md` | skip: not an allowed path form |
| `docs/c.md` (symlink to it) | skip: reached through a symlink, or not a regular file |
| `docs/constraints.md.` (Windows trailing-dot alias) | skip: in-cycle fixes edit only… (fails the `.md$` rule) |
| Unicode case-fold aliases (`conſtraints`, APFS) | closed by construction: pathform's NAMECHARS is ASCII-only (`dev-cycle-read.sh` NAMECHARS line), read-static |
| control `docs/notes.md` | ok |

Guardrail: `isclosed` (B4). Executed: `closed/docs/working/briefs/<brief>`, `closed/closed/<brief>`, a trailing newline, `closed//<brief>`, an upper-case slug all answer no; the plain closed brief answers yes. Complements the fact-check's 23-case equivalence run.

Untested bypass candidates:
- A working-tree hard link from an allowed `docs/*.md` to `docs/constraints.md` — not tested: creating it needs a shell on the host, which is outside the threat (the agent edits through the checked path).
- check_fix against a repo whose `docs/constraints.md` is untracked or ignored — not tested; check_path refuses untracked files outside docs/working/ per its comment, unexecuted here.

## Endorsement Claims

- **Claim:** every current consumer of main_entry treats `badform` as a refusal (no arm maps it to absent/ok).
  **Location:** `scripts/lib/dev-cycle-read.sh:310, 348-353, 566-570`; `scripts/build-loop.sh:129-134`
  **Evidence:** read-static (the fact-check executed it)
  **Verified:** read the four case/compare sites; grep found no other main_entry caller in scripts/.
  **Not verified:** U2a2's floor, the next caller (Finding 3).
  **route: code-fact-check**
- **Claim:** main_entry answers `badform` before any git read for a pathform-refused path, so ls-tree never sees such a name.
  **Location:** `scripts/lib/dev-cycle-read.sh:266-268`
  **Evidence:** executed (probe answered `badform` for a newline path; fact-check counted 0 git calls)
  **Verified:** the newline-path probe in a scratch repo.
  **Not verified:** paths pathform accepts that ls-tree still quotes under a non-default core.quotePath (row 233 territory).
  **route: code-fact-check**

## Primitive sweep

Primitive: stdout skip-line interpolation of a path (line-framing injection)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:286` (entry_why badform) | S1/S2 via callers | none | Finding 2 |
| `scripts/lib/dev-cycle-read.sh:285` (entry_why notfile) | S1/S3 | pathform upstream (main_entry returns notfile only after pathform passed) | cleared — newline cannot reach |
| `scripts/lib/dev-cycle-read.sh:288` (entry_why default) | S4 + path | unreachable from current callers | Finding 2 (same fix) |
| `scripts/lib/dev-cycle-read.sh:352` (check_brief) | S1 | pathform with scrub at an earlier line | cleared |
| `scripts/lib/dev-cycle-read.sh:570` (check_answer) | S3 | fixed names | cleared |
| `scripts/build-loop.sh:133` (main_file) | S3 | fixed names | cleared |

Primitive: fixture git writes under an inherited environment
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/lib/build-loop-fixtures.bash:13-21` | S5 | partial unset | Finding 4 (residue) |
| `test/scripts/dev-cycle.bats:8-26` | S5 | none | Finding 1 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | dev-cycle.bats still writes into an inherited GIT_DIR repo | Medium | B5 | `test/scripts/dev-cycle.bats:8-26` | Medium |
| 2 | entry_why echoes the raw path; badform paths can carry newlines | Low | B2 | `scripts/lib/dev-cycle-read.sh:286,288` | High |
| 3 | badform carries .git* paths; U2a2 must refuse, not skip | Informational | B1 | `scripts/lib/dev-cycle-read.sh:266-267` | Medium |
| 4 | bl_setup unset list narrower than git's local-env-vars | Informational | B5 | `test/lib/build-loop-fixtures.bash:13` | Low |

## Overall Assessment

No fail-open path in the code as it stands: the `badform`/`error` split keeps every current consumer default-refusing, and the constraints.md refusal held against every bypass candidate executed. The two items worth acting on are small and fixable in place: (1) dev-cycle.bats has the same GIT_DIR exposure this diff fixes for build-loop fixtures, and it writes into a real repo when run from a hook; (2) entry_why, now the single mapping U2a2's floor will consume, echoes a path that pathform refused without scrubbing newlines, a latent line-forgery in the gate's own output. The single most important thing before U2a2: make entry_why scrub its path argument (Finding 2), so the shared mapping is safe for branch-controlled paths. No findings beyond these within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: 6f624cdf` as its first line.
- **Answered:** security design review of `git diff main...HEAD` with the four focus areas: main_entry's refusal words as U2a2 will consume them (Findings 2, 3), badform-vs-error fail-open (none today; Finding 3 for U2a2), the --check-fix allowlist (bypass table, all refused), test-fixture hermeticity (Findings 1, 4).
- **Out of scope:** U2a2's floor code (not written); row 307's broken-config reads; re-filing settled rows (308 is extended, not re-filed).
- **Escalate:** none (no HALT pattern).
- **Decisions:** Finding 1 rated Medium under the floor rule (executed mechanism; reachable when a hook runs the suite), although pre-existing and outside the diff's changed lines.
