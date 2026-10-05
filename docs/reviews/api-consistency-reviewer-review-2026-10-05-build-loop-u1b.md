Commit: 1d79ffef

# API Consistency Review — feat/build-loop-u1b (U1b, review iteration 3, final)

**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` at 1d79ffef: `scripts/build-loop.sh` (`--settings`, `-h|--help`, usage errors), its three printed lines, its exit codes, and the in-process globals `POLICY` / `NEVER` that U1c (`--status`) and U2 (the gate) will consume
**Date:** 2026-10-05
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u1b.md` (Stage-1 merged fact-check at 1d79ffef, k=3), the shared Stage-2 context, the plan `docs/working/plan-build-loop-handoff.md` rev 4 ("Script interface" :201-218, D5 :74), the iteration-2 rubric and `docs/reviews/override-log.md`

Probes ran in throwaway repos under this pass's scratch dir, against copies of `scripts/build-loop.sh` and the lib (one copy with `declare -p POLICY NEVER` appended after the print, to see the globals). Nothing was written in the worktree except this report.

## Baseline Conventions

Surveyed `scripts/dev-cycle.sh` (header and Exit line :1-80, option parse :99-112), the lib `scripts/lib/dev-cycle-read.sh` (`check_brief`, `check_branch`, `check_answer`, `main_entry`, `brief_fields`), the option parsers of `scripts/archive-working-docs.sh:32`, `scripts/flag-removal-candidates.sh:42`, `scripts/paper-queue.sh:52-254`, and the plan's "Script interface" (:201-218).

- **Printed answers** are one line each, `KEYWORD SUBJECT…` then `: reason`; the plan fixes `--settings`' shapes at :204.
- **Modes** are long flags; `-h|--help` prints the header with `sed -n '2,Np' "$0"` and exits 0.
- **Errors** go to stderr; exit 1 for bad usage, no repo, no perl or lib, no default branch found by name; a read mode exits 0 once every line is printed. Unknown flags print `Unknown option: X` (dev-cycle.sh :112, archive-working-docs.sh :32, flag-removal-candidates.sh :42).
- **Reading main's commit** goes through `main_entry` and FENCE_AWK, with the lib's wording for `notdir`, `error` and a failed read.
- **Path text** in repo files is checked by `pathform` (lib :140-149), which refuses any `.git*` part; the plan says never entries are "pathform globs" (:74).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--settings` | CLI mode | `--check-path`, `--check-brief`, `--check-answer` | `scripts/dev-cycle.sh:8-14`; plan :204 | Consistent: long-flag mode, plan-specified |
| `-h` / `--help` | CLI flag | dev-cycle.sh `-h\|--help` | `scripts/dev-cycle.sh:111` | Consistent: same sed idiom; range `2,34` matches the header exactly (probe: last help line is the Exit line) |
| `policy self-merge\|review set\|unset: WHY` | output line | `ok X`, `skip X: why` | lib `check_brief`; plan :204 | Consistent with plan :204 |
| `slots N set\|default: WHY` | output line | same | same | Consistent with plan :204 |
| `never GLOB… set\|none\|malformed: WHY` | output line | same | same | Consistent with plan :204 (status position settled as C11) |
| `Unknown option: X (usage: build-loop.sh --settings)` | error message | `Unknown option: X` | `scripts/dev-cycle.sh:112`, `scripts/archive-working-docs.sh:32`, `scripts/flag-removal-candidates.sh:42` | Casing now consistent (C12); the suffix is new (Finding 4) |
| `POLICY` (string), `NEVER` (array) | in-process globals for U1c/U2 | `BRIEF[...]`, `BRIEF_ODD`, `SKIPPED` (array) | `scripts/lib/dev-cycle-read.sh:106, :288` | Consistent: upper-case globals, an array for a list (like `SKIPPED`); contract note in Finding 5 |
| `globform` | script-private function | `pathform … glob` | `scripts/lib/dev-cycle-read.sh:140-149` | Deliberate divergence; plan text not amended (Finding 2) |
| `main_file`, `read_settings`, `FILE_OUT`, `FILE_WHY`, `SETTINGS_AWK`, `many` | script-private | `brief_fields`, `BRIEF_ODD`, `ANSWER_AWK` | `scripts/lib/dev-cycle-read.sh:288-310, :485` | Consistent (`*_AWK`, `FILE_*` like `BRIEF_*`); not public |

## Findings

#### 1. The header's "markup cannot hide a copy" is false for letter-bearing markup, and the miss fails open for the never list (E1)

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:25-27`, `scripts/build-loop.sh:101-104`
**Move:** 3 (consumer contract: documented vs actual)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence (`scripts/build-loop.sh:25-27`):
```
#             A line counts as a copy when its letters alone, case folded,
#             start with the key's ("buildlooppolicy"), so markup, a table or
#             a misplaced colon cannot hide one.
```
Evidence (`scripts/build-loop.sh:101-104`, inside `SETTINGS_AWK` :96-111; excerpt ends :104, the program continues to :111 — read):
```
  s = tolower($0); gsub(/[^a-z]/, "", s); k = ""
  if (index(s, "buildlooppolicy") == 1) k = "policy"
  else if (index(s, "buildloopslots") == 1) k = "slots"
  else if (index(s, "selfmergenever") == 1) k = "never"
```

The consumer of this sentence is the person editing `docs/dev-cycle.md`, who reads it rendered. Markup that contributes letters before or inside the key changes the letters-only string, so the copy is not counted. Probes at 1d79ffef (line 1 `Build-loop policy: self-merge`, line 2 `Self-merge never: a/`, line 3 blank, line 4 the copy):

- `- [x] Self-merge never: b/` (checked task item; letters `xselfmergenever…`) → `policy self-merge set: …` and `never a/ set: line 2 …`
- `[Self](x)-merge never: b/` (link closing inside the key; letters `selfxmergenever…`) → the same two lines
- `- [x] Build-loop policy: review` beside `Build-loop policy: self-merge` → `policy self-merge set: line 1 …`
- control: a plain `Self-merge never: b/` on line 4 → `never malformed: more than one line starts "Self-merge never:" (lines 2 and 4)`, policy off

Each hidden copy renders as a visible second setting line (`b/` shown as protected, or a second policy saying `review`), while the script keeps self-merge on with the first line only. This is the fact-check's Claim 8/14 (Incorrect) and escalation E1. It is not settled C19: C19's premise is that the hidden copy "does not render as the key", which does not hold for these shapes.

**Recommendation:** Either drop a leading task marker (`[ ]`, `[x]`, any case) and every `](...)` link target from the line before the letters-only match (a few characters in the awk), or narrow the header to what is counted and add these shapes to C19's accepted-limit row. The orchestrator owns which (E1); either one makes the header true.

#### 2. A8's remainder: the plan still says never entries are "pathform globs", while the script accepts `.git*` parts

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:74`; `scripts/build-loop.sh:112-121`
**Move:** 3 (contract drift) / 7 (asymmetry with pathform)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence (`docs/working/plan-build-loop-handoff.md:74`):
```
  - **Per project.** `docs/dev-cycle.md` may add `Self-merge never: GLOB …` (pathform globs, one line, read from main's commit). A malformed line turns self-merge off for that repo (`--settings` says why).
```
Evidence (`scripts/build-loop.sh:112-113`; `globform` follows at :114-121 — read):
```
# A never entry: pathform's rule, but a .git* part (.github/) is allowed, since
# the list only adds refusals and must not turn self-merge off by naming one.
```

The array half of A8 is fixed (see below). The other half A8 named, the plan text at :74, is unchanged, and no decision-log row or override row records the divergence (C4 covers only the duplicated code). Probe: `Self-merge never: .git .GIT/config` prints `never .git .GIT/config set: …` with policy self-merge and `NEVER=([0]=".git" [1]=".GIT/config")`. The divergence is sound (the list only adds refusals). The risk is to U2: an implementer reading the plan would re-check `NEVER` entries with `pathform … glob`, which refuses `.github/`, so the gate and `--settings` would disagree on the same line.

**Recommendation:** Amend plan :74 to "globform globs (pathform's characters and glob marks; `.git*` parts allowed, since the list only adds refusals)", or add a `docs/decisions/log.md` row, and say in U2's brief that the gate uses `NEVER` as given, without re-validating it.

#### 3. The header says a second copy or an unread file "leaves the default"; for the never line both give `malformed`

**Severity:** Minor
**Location:** `scripts/build-loop.sh:11-12`, `scripts/build-loop.sh:146`
**Move:** 3 (documented vs actual output)
**Confidence:** High
**Legibility-target:** for-author

Evidence (`scripts/build-loop.sh:9-12`):
```
#   --settings  three lines from the default branch's commit, never the working
#             tree (a build loop can write any working tree). Each comes from
#             one line of docs/dev-cycle.md; a second copy, or a file the lib's
#             FENCE_AWK refuses, leaves the default (WHY says which):
```
Evidence (`scripts/build-loop.sh:146`, inside `read_settings` :127-179; excerpt ends :146, the function continues to :179 — read):
```
    elif [[ "${cnt[never]}" -gt 1 ]]; then NEVER_LINE="never malformed: $(many 'Self-merge never:' never)"; never_ok=""
```

The never line's default (no line) is `none`, but a second copy prints `never malformed: more than one line starts …` (probe above) and turns self-merge off. A refused file prints `never malformed: …` too (`:136`; T3 pins this at `test/scripts/build-loop-read.bats:49`). The header's :23-24 ("Malformed (or a file not read) turns self-merge off") covers the unread file but not the duplicate. A reader of :11-12 would expect `never none` for both. This fails closed, so only the documentation misleads (fact-check Claim 2, Mostly accurate).

**Recommendation:** In :11-12, change "leaves the default" to "leaves the default (for never: malformed)", or add "a second copy" to :23-24's list of what is malformed.

#### 4. The usage suffix lists only `--settings` and is not in the sibling scripts

**Severity:** Informational
**Location:** `scripts/build-loop.sh:49`, `scripts/build-loop.sh:55`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `Unknown option: X` with no suffix used in `scripts/dev-cycle.sh:112`, `scripts/archive-working-docs.sh:32`, `scripts/flag-removal-candidates.sh:42`

Evidence:
```
usage() { echo "$1 (usage: build-loop.sh --settings)" >&2; exit 1; }
  *) usage "Unknown option: $1" ;;
```

C12's casing is fixed. The `(usage: build-loop.sh --settings)` suffix is accurate today (probe: `--status a` prints `Unknown option: --status (usage: build-loop.sh --settings)`), but it has to change in U1c, U2 and U3, which each add a mode. The tests check only exit 1 and non-empty stderr (`test/scripts/build-loop-read.bats:150-151`), so nothing will catch it when it goes stale. Noted for U1c; no change is needed in this unit.

**Recommendation:** At U1c, use `(see build-loop.sh -h)`, which does not go stale, or have each unit that adds a mode update the suffix.

#### 5. `NEVER` is empty both for "no line" and for "malformed"; only `POLICY` carries the difference

**Severity:** Informational
**Location:** `scripts/build-loop.sh:122-125`, `scripts/build-loop.sh:163-164`
**Move:** 8 (nullability contract)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence (`scripts/build-loop.sh:122-124`):
```
# Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (an array of the checked globs,
# each as written, a trailing / kept) and NEVER_LINE from main's commit. POLICY
# and NEVER are for the modes that judge a brief (--status, then the gate).
```
Evidence (`scripts/build-loop.sh:163-164`, inside `read_settings` :127-179 — read whole):
```
      if [[ -n "$why" ]]; then NEVER_LINE="never malformed: line ${first[never]} $why"; never_ok=""
      else NEVER=("${parts[@]}"); NEVER_LINE="never $v set: line ${first[never]} $where"; fi
```

Probes: no never line gives `NEVER=()` with `POLICY="self-merge"`; `Self-merge never: a a/` gives `NEVER=()` with `POLICY="review"`. Today this is safe, because a malformed line always forces `POLICY=review` and the plan's gate applies the S rules only under self-merge. The contract an in-process consumer depends on is therefore "read `POLICY` before `NEVER`; an empty `NEVER` does not mean nothing is protected". `never_ok` is local, so that rule is not stated anywhere a U1c/U2 author would look. Entries also keep `*`, `?` and a trailing `/` (`NEVER=([0]="workflows/" [1]="x/*.sh" … [3]="a?")`), so a consumer must expand them quoted. The comment says "as written", which covers this.

**Recommendation:** Add one clause to :122-124: "NEVER is empty when there is no line or it is malformed; a malformed line forces POLICY=review, so judge POLICY first." No code change.

## Iteration-2 items in my domain (status at 1d79ffef)

- **A8 (NEVER shape): fixed in code, plan text still open.** `NEVER` is now an array of the checked entries (`scripts/build-loop.sh:164`; probe `declare -a NEVER=([0]="workflows/" [1]="x/*.sh" [2]=".github/" [3]="a?")`), so U2 no longer has to re-split or worry about globbing. The "pathform globs" text at plan :74 is unchanged and unrecorded (Finding 2).
- **A12 (Exit line): fixed.** `scripts/build-loop.sh:33` reads `# Exit: 0 every line printed (or help); 1 bad usage, …`. Probe: `--help` exits 0 and prints through the Exit line.
- **C12 ("Unknown option"): fixed.** `scripts/build-loop.sh:55` prints `Unknown option: $1`, the sibling casing. The usage suffix stays (Finding 4, Informational).

## What Looks Good

- All three printed lines match plan :204's shapes exactly, every outcome carries a WHY, and the order (policy, slots, never) is pinned by a test (`build-loop-read.bats:145-147`).
- Exit codes match dev-cycle.sh and the header: 0 when all three lines print (including the malformed and unread cases), 1 for no mode, an unknown mode, extra arguments, no repo, no lib and no default branch found by name. Errors go to stderr with empty stdout (test :150-151).
- `main_file` now maps `main_entry`'s `error` and a failed blob read to the lib's own wording (`scripts/build-loop.sh:79-83`), which closes iteration 2's error-consistency gap (A7).
- Fail-closed semantics agree across keys: `POLICY` and the printed policy line never disagree. In the self-merge-with-malformed-never case, both say review, and the WHY names the reason.
- `NEVER` as an array follows the lib's precedent of upper-case global arrays (`SKIPPED`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | "Markup cannot hide a copy" is false for `- [x]` task items and links closing inside the key; the hidden never or policy copy fails open (E1) | Inconsistent | `scripts/build-loop.sh:25-27`, `:101-104` | High |
| 2 | A8 remainder: plan :74 still says "pathform globs"; the script accepts `.git*` parts, unrecorded | Minor | `docs/working/plan-build-loop-handoff.md:74`; `scripts/build-loop.sh:112-121` | High |
| 3 | The header's "leaves the default" is wrong for never: a duplicate or unread file gives `malformed`, not `none` | Minor | `scripts/build-loop.sh:11-12`, `:146` | High |
| 4 | The usage suffix lists only `--settings`, which is not sibling practice and goes stale at U1c | Informational | `scripts/build-loop.sh:49` | High |
| 5 | `NEVER` is empty for both none and malformed; consumers must judge `POLICY` first, and this is not documented | Informational | `scripts/build-loop.sh:122-125`, `:163-164` | High |

## Overall Assessment

The public surface of `--settings` is consistent with the plan's Script interface and with dev-cycle.sh's conventions: the line shapes, exit codes, stderr usage, help idiom and the lib's error wording all match. Iteration 2's items in this domain are fixed in code (A8's array, A12, C12). The one finding above Minor is a contract over-claim in the header (Finding 1, fact-check E1). Rendered copies of a key still escape the letters-only match when the markup contributes letters, and for the never list that fails open. Fixing it takes a small strip or a narrower sentence plus an accepted-limit row, at the orchestrator's choice. Findings 2 and 3 are documentation alignment that fails closed, and 4 and 5 are notes for U1c/U2. None needs a survey of conventions; all can be fixed in place.

## Goal-Alignment Note

- **User goal:** Final confirming review pass of build-loop unit U1b before local merge.
- **Current task:** Review the public surface (CLI modes, printed line formats, exit codes, the `NEVER`/`POLICY` globals) of `feat/build-loop-u1a...feat/build-loop-u1b` at 1d79ffef for consistency with plan rev 4's Script interface and the sibling scripts.
- **Success criterion:** This report, saved at `docs/reviews/api-consistency-reviewer-review-2026-10-05-build-loop-u1b.md`, structured per the api-consistency-reviewer skill. Met.
- **Alignment:** Aligned. One Inconsistent finding (1, the E1 header over-claim that fails open for a rendered copy) needs a decision before merge, as amber or as an extension of C19. Findings 2-3 are Minor documentation fixes; 4-5 are Informational notes for U1c/U2.
