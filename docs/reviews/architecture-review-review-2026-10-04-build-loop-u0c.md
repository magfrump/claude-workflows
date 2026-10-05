Commit: 27e38dc4

# Architecture Review — feat/build-loop-u0c (U0c: import walk and check_answer into the lib)

**Scope:** `git diff feat/build-loop-u0b..feat/build-loop-u0c` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats), read at tip 27e38dc4 with `git show`; plan rev 4 D5 (floor), F10/F11/F12, "Approach"
**Date:** 2026-10-04
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0c.md (Stage 1); docs/reviews/architecture-review-build-loop-handoff.md

Scope check: in scope. The diff changes module structure: the instruction-file import walk and the answer reader move into the shared lib. It also creates a new cross-module boundary between `check_fix` (which stays) and the walk's cache (which moves).

Trust-boundary cross-reference: active. The most recent security review is `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73` — security review predates this diff; boundaries may be stale). Findings 1–4 touch its **B1** (`repo text → --check-fix gate, check_fix() → edit to a docs/ or README.md file`) and **B2** (`instruction files → imported_names() walk → IMPORTED refusal set`).

Not re-filed (already in the fact-check report): the commit's "build-loop.sh will need only the walk and INSTRUCTION_FILE" contradicting plan line 187 and F10 (Claim 10b), the `ROOT_REAL` SC2034 comment omitting the walk (Claim 2), and T29's list omitting `IMPORTED`/`IMPORTED_DONE` (Claim 8). Finding 1 answers the design question Claim 10b leaves open: where `check_fix`'s predicate should go.

## Dependency Map

```
dev-cycle.sh check_fix ──calls──▶ lib imported_names ──writes──▶ IMPORTED (newline-delimited, lower-cased), IMPORTED_DONE
dev-cycle.sh check_fix ──reads──▶ IMPORTED's encoding directly; INSTRUCTION_FILE; writable; pathform
dev-cycle.sh check_fix ──calls──▶ check_path (stays in dev-cycle.sh) ──▶ git ls-files
lib check_answer ──▶ FENCE_AWK + ANSWER_AWK, skipped (SKIPPED), working-tree questions files
lib imported_names ──reads──▶ ROOT_REAL (set by dev-cycle.sh:115), cwd, git ls-files (tracked + untracked)
```

After this unit, dev-cycle.sh still calls into the lib, but the lib no longer reaches back into anything defined in dev-cycle.sh. Before U0c the walk and `check_answer` lived in the script and read lib items. Now every reader is in the lib, and dev-cycle.sh holds only the CLI dispatch, the three fix/path/write policies, and the digest. This is a clean layering. The leftover coupling is data. `check_fix` reads the walk's cache variable directly (finding 2), and `ROOT_REAL` is now a global that dev-cycle.sh sets but only the lib reads, which is why the new SC2034 directive was needed.

## Findings

#### 1. Where `check_fix`'s predicate belongs: not U0 as written; a separate floor predicate in U2, built from parts the lib now shares

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:161-181` (check_fix, whole function); plan `docs/working/plan-build-loop-handoff.md:187` and `:68-75` (D5 floor)
**Move:** 2 (responsibility boundaries), 3 (module boundary)
**Confidence:** High
**Legibility target:** for-author

Evidence (tip 27e38dc4):

```bash
check_fix() {
  local a="$1" low lp
  if [[ "$a" == *[*?]* ]]; then echo "skip ${a//$'\n'/ }: --check-fix takes one file, not a glob"; return; fi
  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi
  # Compared lower-cased: on a case-insensitive filesystem docs/Working/ is docs/working/.
  lp="$(printf '%s' "$a" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"
  low="${lp##*/}"
  imported_names
  if writable "$a" || writable "$lp"; then echo "skip $a: one of the cycle's own files (use --check-write)"
  elif [[ ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|human-author|reviews|decisions)/ \
    || "$lp" == docs/dev-cycle.md || "$a" == */.* || "$low" =~ $INSTRUCTION_FILE ]]; then
    echo "skip $a: in-cycle fixes edit only tracked .md documentation under docs/ (not working/, human-author/, reviews/, decisions/, dev-cycle.md, dot-directories or dotfiles, or instruction files) and README.md; file it instead"
  elif [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]; then
    echo "skip $a: an instruction file imports it with @ (directly or through another import), so it is read as instructions; file it instead"
  else check_path "$a"; fi
}
```
(the whole function)

Plan rev 4, D5's floor (`:68-75`), which is what `build-loop.sh`'s S rules apply in U2, refuses: (1) instruction files and their `@`-imports; (2) any `.`-prefixed component; (3) the gate's own code; (4) the cycle-owned files, `docs/constraints.md`, `docs/decisions/`, `docs/thoughts/`, `docs/human-author/` and other briefs' working docs; (5) symlinks and gitlinks.

`check_fix`'s predicate answers a different question: is this an in-cycle-editable documentation file? It works as an allowlist (`^docs/.*\.md$|^readme\.md$`) with denials carved out of it. The floor is a denylist applied over arbitrary paths that the brief's `Paths:` allows. Lifting one into the other does not give the other:

- **Shared parts:** `INSTRUCTION_FILE`, the import walk, `writable`, and a dot-component test. U0c (with U0a) already put the first three in the lib. The dot test is inline: `"$a" == */.*`.
- **Parts that differ:**
  - `check_fix` denies all of `working/` and `reviews/`. The floor allows the loop's own-stem files there.
  - `check_fix` allows `docs/thoughts/` and `docs/constraints.md`. The floor denies them.
  - `check_fix`'s dot test misses a leading-dot top-level path. That never matters for `check_fix`, because such a path also fails `^docs/`. It does matter for the floor, which sees `.envrc`.
  - The allowlist half (`^docs/…\.md`, `check_path`'s "tracked file" test) has no meaning for the floor.

Moving "`check_fix`'s predicate" in U0 would mean splitting `check_fix` into a parameterized function serving two policies. That is not a move. It would put a policy switch into the lib (control coupling) to serve a consumer that does not exist yet, and it would change the structure of a function that 38 review passes hardened. U0c's choice is the right boundary: move the shared building blocks and leave the two policies in the scripts that own them. The departure from plan line 187 needs to be recorded, as Stage 1 says, but the plan line is the thing to amend, not the code.

**Recommendation:**

- Amend plan line 187 to: "`writable`, `isbrief`, `INSTRUCTION_FILE` and the import walk (U0); the floor predicate is new in U2, composed from them; `check_fix` stays whole in dev-cycle.sh".
- Add one decision-log row or plan revision note that names the reason: the two policies differ.
- In U2, add the floor as its own lib function, for example `floor_denied PATH STEM`, built from `INSTRUCTION_FILE`, an import-membership predicate (finding 2), `writable`, and a dot-component test that also covers a leading dot. Keep it in the lib, not in `build-loop.sh`: D5 item 3 makes the lib gate code anyway, and keeping it next to `check_fix`'s building blocks makes a divergence visible in one file.
- **Security implication:** this places floor item 1 on B2. The `IMPORTED` refusal set gains a second sink (the merge gate) alongside B1's `--check-fix`, so B2's known gap against B3 (F1–F4 in the pass-38 review; the plan's F11 "partly") becomes a gate gap as well. The plan already accepts this in F11 and Q-103. The combined architecture and security pass on U2 should confirm it rather than inherit it unexamined.

#### 2. `check_fix` reads the walk's cache encoding across the module boundary

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:173`, `:178`; `scripts/lib/dev-cycle-read.sh:316`, `:321`, `:343`
**Move:** 3, 7 (coupling surface)
**Confidence:** High
**Legibility target:** for-author

Evidence (tip 27e38dc4):

```bash
IMPORTED=$'\n'; IMPORTED_DONE=""
...
  [[ -n "$IMPORTED_DONE" ]] && return; IMPORTED_DONE=1
...
      IMPORTED+="$(lower "$p")"$'\n'
```
(lib `:316`, `:321`, `:343`; `imported_names` runs `:319-347` — read)

```bash
  imported_names
...
  elif [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]; then
```
(dev-cycle.sh `:173`, `:178`; inside check_fix, which runs `:166-181` and is quoted whole in finding 1)

Before U0c, the cache and its one reader were in the same file. Now `check_fix` depends on three lib internals: the call-before-read protocol, the newline-framed encoding, and the rule that the caller lower-cases its argument to match. This is content coupling. `build-loop.sh`'s floor item 1 (finding 1) will be a second reader and will have to copy the same idiom. If the encoding ever changes (an associative array, a NUL frame, a cache keyed by root for finding 4), both readers break silently: a membership test that never matches means fail-open on B2.

**Recommendation:** In U2, when the second reader arrives, or now if the loop wants it, add a lib predicate such as `isimported() { imported_names; [[ "$IMPORTED" == *$'\n'"$(lower "$1")"$'\n'* ]]; }` and have both `check_fix` and the floor call it. For dev-cycle.sh this is a behaviour-neutral one-line substitution, covered by the three existing import tests.

#### 3. Two "files read as truth" lists will now drift: `check_fix` lets an in-cycle fix edit `docs/thoughts/` and `docs/constraints.md`

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:175-176`; plan `:72` (floor item 4)
**Move:** 2
**Confidence:** High (static reading of the regex)
**Legibility target:** for-orchestrator-synthesis

Evidence (tip 27e38dc4):

```bash
  elif [[ ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|human-author|reviews|decisions)/ \
    || "$lp" == docs/dev-cycle.md || "$a" == */.* || "$low" =~ $INSTRUCTION_FILE ]]; then
```
(excerpt ends inside check_fix, which continues to `:181`. The remainder adds only the import denial and `check_path`; neither denies `thoughts/` or `constraints.md`.)

Rev 4 makes `docs/constraints.md` the dispatch gate's input (D2) and floor item 4 treats `docs/thoughts/` as "read as truth on the next run". `check_fix`'s denial list, written before either decision, lets an in-cycle fix (B1's sink) edit both. This unit does not change that behaviour; it was there before and moved nothing. It matters now because U2 will write a second list of the same concept, so the system will have two hand-maintained answers to "which docs do later runs trust?".

**Recommendation:** Do not change `check_fix` in U0. When U2 writes the floor, either share a single `truthdoc()` list between the two policies, or file a `you: judgment` entry asking whether in-cycle fixes may edit `docs/thoughts/` and `docs/constraints.md`. Do not let the floor and `check_fix` disagree by accident. **Security implication:** if `check_fix` starts denying these paths, B1's allowed sink narrows. That is a fail-closed change for the security reviewer to confirm.

#### 4. The moved walk is bound to one working tree and cached once per process

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:316-347`
**Move:** 8 (extension points)
**Confidence:** Medium
**Legibility target:** for-orchestrator-synthesis

Evidence (tip 27e38dc4):

```bash
  done < <({ git ls-files -z
             GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; } \
```
(`:331-332`; excerpt ends inside imported_names, which continues to `:347` — read: the remainder reads each file with `grep` from the working tree and resolves against `$ROOT_REAL`.)

The plan-stage review's finding 8 said the walk reads the working tree, while the gate judges main's commit plus the loop's diff, so floor coverage "needs a commit-based import walk". U0c moves the working-tree walk unchanged, which is correct for a pure move. The commit then names it as what `build-loop.sh` will use for floor item 1. Used from the gate, its answer depends on the orchestrator's checkout, including untracked instruction files there (`--others`), not on `MAIN_SHA`. `IMPORTED_DONE` also makes it answer for whichever tree it saw first in the process. This is B2's source side. The plan's F11 entry ("partly … its known-issues A2/A3 remain") accepts a partial walk, but it does not name the tree-binding.

**Recommendation:** No change in U0c. In U2, either state the precondition (the gate runs the walk in a worktree checked out at `MAIN_SHA` with no untracked instruction files, and test it), or add a commit-based variant. Add "walk reads the working tree, not `MAIN_SHA`" to F11's Q-103 text so the limit stays visible.

## What Looks Good

- **The layering is clean.** After U0c, every reader is in the lib and dev-cycle.sh keeps only CLI dispatch, its three write/fix policies and the digest. No lib function calls back into the script.
- **Policies stayed with their owners.** `check_fix`, `check_path` and `check_write` encode dev-cycle-specific write policy and correctly stay out of the shared reader (see finding 1).
- **One answer grammar.** `check_answer` in the lib is the precondition for D8 (U1 reads answers from main's commit) without a second parser. The plan-stage review praised this ("no new answer grammar").
- **Location-dependent comments still hold.** Stage 1 verified that the hermeticity-lint note, "Computed once" and the questions.sh references still read correctly from `scripts/lib/`. The move did not strand any rationale.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `check_fix`'s predicate: keep it whole (U0c is right); amend plan :187; build the floor predicate in U2 from the shared parts (B2) | Minor | `scripts/dev-cycle.sh:166-181`; plan :187, :68-75 | High |
| 2 | `check_fix` reads `IMPORTED`'s encoding across the boundary; add an `isimported` predicate | Minor | `scripts/dev-cycle.sh:173, 178`; lib `:316, 321, 343` | High |
| 3 | In-cycle fix policy and floor item 4 disagree on `docs/thoughts/`, `docs/constraints.md` | Informational | `scripts/dev-cycle.sh:175-176`; plan :72 | High |
| 4 | Moved walk is working-tree-bound and process-cached; gate reuse needs a stated precondition (B2) | Informational | `scripts/lib/dev-cycle-read.sh:316-347` | Medium |

## Overall Assessment

U0c finishes the extraction with a clean layering. All readers are in the lib, dev-cycle.sh keeps its own policies, and no dependency points back up. The open question from Stage 1 is where `check_fix`'s predicate belongs. On structural grounds the answer is "not in U0". `check_fix`'s predicate and D5's floor are two different policies that share three building blocks, and U0c has already moved those blocks. Lifting `check_fix` would put a policy switch into the lib for a consumer that does not exist yet. The work belongs in U2, as a new floor predicate in the lib composed from the shared parts, together with an `isimported` predicate so neither policy reads the cache's encoding. Before U0 is called complete, the plan's line 187 should be amended and the reason recorded. That is the single most important item, because without it the approved plan and the code disagree about a module boundary. No finding blocks the move itself.

## Goal-Alignment Note

The goal is a pure move with dev-cycle.sh's behaviour unchanged. Stage 1's executed evidence (moved block byte-identical apart from the scope comment, 56/56 tests, identical digest and check modes) supports it, and this review finds no structural regression. Finding 1 turns Stage 1's Incorrect claim into a concrete, cheap resolution: amend the plan and do not move code. That keeps U0c a pure move and closes the plan/code mismatch the fact-check flagged. Findings 2–4 are inputs to U2's design and need no change to land U0c.
