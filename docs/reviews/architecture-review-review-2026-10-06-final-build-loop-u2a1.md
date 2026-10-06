Commit: d48f4645

# Architecture Review — feat/build-loop-u2a1 (final confirming pass)

**Scope:** `git diff main...HEAD` at d48f4645 (6f624cdf unit, 706e0499 iteration-1 artifacts, d48f4645 iteration-1 fixes); in-scope code: `scripts/lib/dev-cycle-read.sh`, `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`
**Date:** 2026-10-06
**Based on:** Stage 1 code-fact-check k=3 at d48f4645 (`docs/reviews/code-fact-check-report-build-loop-u2a1-r{1,2,3}.md`: 0 Incorrect, 0 Stale, 0 Unverifiable); iteration-1 rubric `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md`; override-log rows 204, 228, 292, 306-325

**Scope check.** In scope under "Public APIs". The lib's caller contract changes: main_entry gains the word `badform`, and `entry_why` and `isclosed` are new lib functions called from both scripts. `entry_why`'s signature changed again in d48f4645, because `$2` may now be empty. `--check-fix`'s refusal set widens. The test, fixture and plan/questions hunks are out of scope for this lens: the `unset $(git rev-parse --local-env-vars)` in both setups, the split `&&` chains, and the T7 comment. They are listed here only as scoped exclusions.

**Trust-boundary scan.** `ls docs/reviews/security-review-*.md` matches files. The newest is `security-review-egress-zone-entries-2026-09-19.md`, which covers an unrelated diff. This pass files no module-boundary finding under move 3, so the cross-reference is a no-op. This branch's own security report is named `security-reviewer-review-*` and falls outside the scan glob.

**Settled context, not re-filed:** row 322 (check_fix and the floor's shared subset, Defer to U2a2), row 323 (`anybrief`, Defer to U2b), row 324 (the floor's check order and refusing on any word but blob/absent, Defer to U2a2), row 325 (entry_why's subshell cost, Won't-Fix). Nothing in d48f4645 changes the premises of these rows.

## Dependency Map

Direction is unchanged from iteration 1. `scripts/dev-cycle.sh` and `scripts/build-loop.sh` source `scripts/lib/dev-cycle-read.sh` from their own directory, and the lib calls into neither script.

- `main_entry` (lib:262-279) answers `blob` / `absent` / `notfile` / `notdir PART` / `badform` / `error`. It has four callers: check_brief (lib:350), check_answer (lib:568), brief_fields (lib:312, which reads anything but `blob` as error), and build-loop.sh's main_file (:129).
- `entry_why` (lib:283-292) is pure: no git, no globals. Three callers pass every word except `blob`/`absent` to it: check_brief with `""` (lib:354), check_answer with `$f` (lib:573-574), and main_file with `$f` (build-loop.sh:133).
- `isclosed` (lib:158) is built on `isbrief`, and is called by writable (lib:161), check_brief (lib:344) and shared_branches (build-loop.sh:318).
- check_fix (dev-cycle.sh:170-185) stays in the script and reads the lib's `writable`, `INSTRUCTION_FILE` and `IMPORTED`.

The fixes add no new cycle, no new module and no new edge.

## Iteration-1 fixes, checked through this lens

| Fix | Structural effect | Status |
|---|---|---|
| A2 (newline folding in entry_why) | Confined to entry_why, with no new surface. Every caller gets a one-line reason without doing anything itself, which is the right owner for that rule. | No new finding |
| A3 (error arm names the path) | main_file's reason regains its subject without main_file branching on the word. The mapping stays single. | No new finding |
| A4 (optional, possibly empty `$2`) | The fix makes `$2` mean something different in each arm and asks check_answer to know which arm names what. See F1. | F1 (Minor) |
| A5 (check_fix comment points to the header) | Removes the fifth copy of the refusal set (iteration-1 architecture I2). Four copies remain: the header at dev-cycle.sh:50-54, the regex at :179-180, the skip message at :181, and SKILL.md:72-75. Each one lists constraints.md. The comment now keeps only the why (D2, thoughts/ stays fixable). | Fixed as intended |
| A1/C5 (setup unsets git's repo-local variables) | Test-only, out of scope. | Not reviewed |
| A6 (header reflow) | Wording only. The fact-check found the reflow partial (lib:16 is 96 columns, :25 is 52). | Not an architecture concern |

## Findings

#### F1. entry_why's `$2` has a different role in each arm, and check_answer carries that knowledge in a special case

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:280-292`, `:571-574`
**Move:** 7 (coupling surface), 5 (interface segregation)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
scripts/lib/dev-cycle-read.sh:280-292
# Why main_entry's word $1 is not a file to read, for a skip line. $2 is the
# path, named in the reason; pass "" when the skip line already names it. A
# newline in either becomes a space, so the reason stays one line.
entry_why() {
  local w="${1//$'\n'/ }" p="${2//$'\n'/ }"
  case "$w" in
    notdir\ *) echo "${w#notdir } is not a directory on the default branch" ;;
    notfile) echo "${p:+$p is }not a regular file on the default branch" ;;
    badform) echo "${p:+$p is }not an allowed path form" ;;
    error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;
    *) echo "the default branch answered $w${p:+ for $p}" ;;
  esac
}
```
```
scripts/lib/dev-cycle-read.sh:571-574
      # "it" is $f, except after notdir, whose reason names a directory above it.
      notdir\ *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in it is read"; return ;;
    esac
```

After A4, `$2` plays four different roles depending on the word. In `notfile` and `badform` it is the sentence's subject. In `error` and the default arm it is a trailing `for $p`. In `notdir` it is ignored, and PART is the subject. An empty `$2` switches every arm except `notdir` into a subjectless form. The comment documents none of this ("$2 is the path, named in the reason"; fact-check r3 Mostly accurate: the notdir arm names the directory, not `$2`). A caller that continues the sentence ("so no entry in it is read") therefore has to know which arms leave `$2` as the antecedent of "it", and check_answer encodes that in a second `notdir` arm. Within the unit this is correct. The cost lands when someone adds a word: U2a2's floor and U2b's walk are the next consumers named in rows 308 and 324. A new word whose reason names some other part, as notdir does, would leave check_answer's catch-all printing an "it" that refers to the wrong path, and no test would catch it, because the fixture suites assert today's four words. The mapping was meant to remove per-caller knowledge of the words (row 228). This brings a small piece of it back.

**Recommendation:** Either option works, and neither blocks the merge.
- (a) Spell out the per-word subject in entry_why's comment: "notdir names PART and ignores `$2`; notfile and badform make `$2` the subject; error and unknown words add `for $2`". The special case at :571-572 then follows from a stated contract rather than from reading the function.
- (b) Have check_answer end every arm with "so no entry in `$f` is read", as its own odd/unbalanced/quoted arms already do at :582-584. That drops the notdir special case at the price of naming `$f` twice for notfile/badform/error, which A4 deliberately avoided.

Option (a) is the cheaper fit and could land with U2a2's first edit of the lib.

## What Looks Good

Each row below is a claim submitted for verification, not a certified result.

| Observation | Location | Status |
|---|---|---|
| The fixes leave dependency direction unchanged: d48f4645 adds no lib-to-script call, and entry_why still uses no git and no globals | lib:283-292 | [unverified — submitted as claim] |
| One mapping still serves all three callers after A3/A4. main_file, check_brief and check_answer each keep only their own `absent`/`blob` arms and delegate every other word, so a new main_entry word needs one edit in entry_why, apart from check_answer's notdir case (F1) | build-loop.sh:130-134; lib:351-355, :569-575 | [unverified — submitted as claim]; fact-check executed: every main_entry caller refuses every word but blob/absent |
| Newline folding lives in entry_why, not in each caller, so the one-line guarantee is owned once | lib:284 | [unverified — submitted as claim]; fact-check r3: the mutant reverting folding of the word argument survives (no caller can produce such a word) |
| A5 drops the drifted fifth copy of the check_fix refusal set. The comment keeps only the rationale (D2, thoughts/ fixable), so the header is the single prose statement of the rule within the script | dev-cycle.sh:167-169 | [unverified — submitted as claim]; fact-check r1-r3: "the skip message below repeats it" holds only for the three skip messages together |
| main_entry's contract sentence "Only blob reads the file, and only absent means there is none: every other word is a refusal" still holds after the fixes, so rows 308 and 324 have a stated rule to build on | lib:256-258 | [unverified — submitted as claim] |
| `isclosed` remains the single spelling of the closed/ rule across writable, check_brief and shared_branches | lib:158, :161, :344; build-loop.sh:318 | [unverified — submitted as claim]; fact-check executed: equal to the three old spellings on 23-27 cases |

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | entry_why's `$2` has a different role per arm (subject / `for $2` / ignored / subjectless when empty), and check_answer encodes which arm names what; a future word can make its "it" wrong silently | Minor | `scripts/lib/dev-cycle-read.sh:280-292`, `:571-574` | Medium |

## Overall Assessment

The iteration-1 fixes keep the structure iteration 1 approved. They add no dependency, module or public function. main_entry keeps a closed refusal contract, and entry_why is still the one mapping its three callers share. A5 also removes one copy of the check_fix list. The only new structural point is F1, a Minor coupling introduced by A4. The optional, per-arm meaning of `$2` makes check_answer know which reasons name which path. It is correct today and cheap to settle by documenting the per-word subject. Rows 322-324 already carry the larger open items, the shared read-as-truth subset and the floor's check order, to U2a2 and U2b. Nothing here is Structural or Coupling, and nothing blocks the merge.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-final-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: d48f4645` as its first line.
- **Answered:** Saved as `docs/reviews/architecture-review-review-2026-10-06-final-build-loop-u2a1.md`. The iteration-1 fixes A2-A5 are structurally sound. A4 introduced one Minor coupling (F1). A1/A6 are out of this lens. 0 Structural, 0 Coupling, 1 Minor, 0 Informational.
- **Out of scope:** test and fixture hunks (setup unsets, split chains, the T7 comment), wording and line length (A6), security and performance. Settled rows 322-325 were not re-filed, since their premises still hold.
- **Escalate:** none.
- **Decisions:** F1 can be routed as Fix (option (a), a comment-only change) or as a Defer row triggered by U2a2's first lib edit. The orchestrator decides.
