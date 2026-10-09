Commit: a382a3f8

# Security Review — feat/build-loop-u2b1b, iteration 2 (fix commit a382a3f8)

**Scope:** `git diff 809df345..a382a3f8` (scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh header, test/scripts/build-loop-check.bats); surrounding code read for context (`truthrule`, `writable`, `isstart`, `pathform`, `nul_list`, `lower_all`, `gate_repo`, `gate_git`, `merge_result`, `resolve_main`, `state_gate`'s origin/HEAD check)
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check `docs/reviews/code-fact-check-report-build-loop-u2b1b-i2.md` (25 Verified, 5 Mostly accurate, 0 Incorrect); iteration 1 security review `docs/reviews/security-reviewer-review-2026-10-08-build-loop-u2b1b.md`

## Trust Boundary Map

```
B1: [loop-written branch tip TIP: commits, trees, blob ids (S1)] → [merge_result (merge-tree in GATE_TMP) → diff-tree -z → cat-file --batch-check (new)] → [path list ps/oms/nms/nos/ss the N rules judge]
B2: [changed path strings from diff-tree (S1)]                   → [pathform → lower_all via nul_list (moved: one pass) → truthrule words (moved: was writable+regex)] → [DENY / "ok BRIEF TIP TREE" verdict the orchestrator trusts]
B3: [main's copy of the brief (S2)]                               → [own_blob, exit status now checked (changed)] → [the one blob id the own brief may take]
B4: [repo-local refs: refs/heads/{main,master}, origin/HEAD (S3)] → [state_gate; default_gate (moved from inline)] → [MAIN / MAIN_SHA as the trusted base]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | branch tip objects and the paths/modes/blob ids diff-tree derives from them | loop-written (request-time) | UNTRUSTED for the merge verdict, path classification and object-existence sinks |
| S2 | main's brief blob | reviewed, on main | trusted for content; its *read* can fail (store damage, race), so the read's status is untrusted toward the equality sink |
| S3 | refs in the shared repo | runtime-mutable by any same-uid process | UNTRUSTED toward the "which branch is main" decision |
| S4 | GATE_TMP (gate repo dir, err file) | same-uid writable | Q-103 residual (R8, decided in a382a3f8) |

Everything the gate judges enters at B1 from the loop's branch. The fix commit adds one new check at B1 (object presence and type for every new regular file), reroutes B2's classification through the lib's `truthrule`, batches B2's lower-casing, and makes B3 fail closed on a failed read. No boundary is removed.

## Verification of iteration 1 findings

**F1 (own_blob status) — fixed.** `scripts/build-loop.sh:558`:
```
    { [[ "$5" == M && "$2" == "$3" ]] && ob="$(own_blob "$1")" && [[ "$4" == "$ob" ]]; } \
      || DENY="this brief: only its first Status: line outside a fence may change, from open to done"
```
`own_blob` (`:535-542`) runs its last pipeline `git cat-file blob … | perl … | gate_git hash-object --no-filters --stdin` under the script-wide `set -euo pipefail` (`:140`), inherited by the `$(...)` subshell, so a failed `cat-file` makes the function non-zero; the assignment's status is that of the substitution, and the `&&` chain then sets DENY. The first read's failure and `n == 0` return 1 (`:539-540`). `gate_git` returns 3 on any stderr (`:509-514`). Fact-check summary item 3 confirms "non-zero (1, 128 or 3); nrules tests non-zero only". Honest-path fix; complete.

**F2 (missing blob) — fixed for every path that can land.** `scripts/build-loop.sh:602` collects `ids` for every record whose new mode is 100644 or 100755; `:609-611`:
```
  if [[ ${#ids[@]} -gt 0 ]] && { ! out="$(printf '%s\n' "${ids[@]}" | gate_git cat-file --batch-check='%(objecttype)')" \
    || [[ "$(printf '%s\n' "$out" | grep -cx blob)" -ne ${#ids[@]} ]]; }; then
    echo "refuse $a: the merge of $br names a file the object store lacks"; return
```
A missing object prints `<oid> missing` (not `blob`), so the count falls short; a git failure or any stderr (gate_git rc 3) refuses. Entries not in `ids` (symlink 120000, gitlink 160000, deletions 000000) are either denied by the mode rule or do not land. Executed (probe file `scratchpad/u2b1b-i2/sec/probe.bats`):
- P2: one present and one missing blob in the same tip → `refuse …: the merge of feat/x names a file the object store lacks`, status 2.
- P3: a missing blob at mode 100755 → same refusal, status 2.
- P1: a crafted tree (`hash-object -t tree --literally`) with an existing *tree* id under mode 100644 → same refusal, status 2 (the type check, not only presence, holds).

## Regression checks on what the fixes changed

**nrules through truthrule (`:556-566`).** Concern: `truthrule` (`scripts/lib/dev-cycle-read.sh:1087-1097`) tests `case`, `instr` (`isstart`) and `dot` *before* `cycle`; any of those words falls to the `*)` arm, which refuses only the `briefs/`/`cycles/` prefixes. A cycle-owned path that also matched `isstart` or the dot test would therefore pass. Traced: `writable` (`:204-207`) admits only `docs/roadmap.md`, `docs/working/{questions,questions-archive,idea-log}.md`, `docs/working/cycles/cycle-DATE.md` and dated-slug briefs; none has a dot-prefixed component, and none has a basename matching `INSTRUCTION_FILE` (`^(claude|agents?|gemini)(\.…)?\.md$|^skill\.md$`, `:516`) or a `.claude/` part (`PROMPT_DIR`, `:525`). `docs/dev-cycle.md` and `docs/constraints.md` match neither. `case` cannot fire: `$7` is lower-cased by the same ASCII-only `tr` set that `truthrule`'s case test uses, and pathform has already refused every non-NAMECHARS byte. Coverage is identical to 809df345's `writable "$lp" || [[ "$lp" =~ ^docs/(dev-cycle\.md$|working/(briefs|cycles)/) ]]` plus the constraints compare. Executed P4: `docs/working/briefs/CLAUDE.md` (instr word, briefs prefix), `docs/working/cycles/.x` (dot word, cycles prefix), `docs/Constraints.md`, `docs/working/Idea-Log.md` → all four denied with the right reasons; `work-feat-x.txt` passes. Cleared; one latent coupling noted as Finding 2.

**Batch lower via nul_list/lower_all (`:614`).** `nul_list` empties the array and returns 1 unless `lower_all` exited 0 and its output ended in NUL (`dev-cycle-read.sh:852`); `lower_all` emits one NUL-terminated record per argument through one `tr` under `pipefail` (`:857`), and `tr` maps bytes one-to-one, so record order and count are preserved. `:614` additionally refuses when `${#lps[@]} -ne ${#ps[@]}`. diff-tree never emits an empty path, and the zero-path case returns at `:606` before `lower_all` runs (where `printf '%s\0'` with no arguments would emit one empty record). Index `i` addresses `oms/nms/nos/ss/ps/lps` from the same loop iteration (`:600-602`). Executed P5: 1,002 paths mixed-case (`d/F1.md`…`d/f1000.md`, `docs/working/QUESTIONS.md`) → exactly `1 of 1002 … refused`, the one deny on `docs/working/QUESTIONS.md`. Cleared.

**NUL-count guard (`:605`).** `2 * ${#ps[@]}` replaces `2 * i` with the same count (one `ps` append per accepted record; a malformed record returns before). Unchanged semantics.

**default_gate (`:240-249`, called `:259`).** Logic moved unchanged from the inline block, now accumulating both findings before `exit 2`. Same position: after `state_gate`, `resolve_main` and `main_by_name`, before any brief is read. A loop pointing origin/HEAD at `origin/<x>` with a local `<x>` would satisfy `default_gate`'s equality, but `state_gate` already refuses an origin/HEAD naming anything but origin/main or origin/master (iteration 1 api review, `:229`), so that path is closed. Fact-check summary notes no test of both findings in one run (an output-completeness gap, not a pass-through: either finding alone sets `bad=1`). Cleared.

## Findings

#### 1. The "object store lacks" refusal also covers present objects of the wrong type, and its wording says otherwise

**Severity:** Informational
**Location:** `scripts/build-loop.sh:609-611`
**Boundary:** B1
**Move:** 3 (error path), 11 (bypass enumeration)
**Confidence:** High
**Class:** hostile-loop (an honest branch cannot produce a tree or commit id under a regular-file mode; git's own tools refuse it, see P1's first attempt: `fatal: entry 'new.txt' object … is a tree but specified type was (blob)`)
**Legibility-target:** the orchestrator or user reading the refusal line

Evidence: `|| [[ "$(printf '%s\n' "$out" | grep -cx blob)" -ne ${#ids[@]} ]]; }; then` / `echo "refuse $a: the merge of $br names a file the object store lacks"`. P1 (a present tree id under mode 100644) prints that line. The refusal is correct and fail-closed; only the reason misdescribes the case, which could send a reader looking for a missing object (or a fetch) that would not fix anything.

**Recommendation:** Optional: word it "names a file the object store lacks or holds as another type", or leave as is; no security change needed.

#### 2. nrules' cycle/user coverage now depends on truthrule's word order

**Severity:** Informational
**Location:** `scripts/build-loop.sh:561-565`; `scripts/lib/dev-cycle-read.sh:1089-1094`
**Boundary:** B2
**Move:** 5 (invert the access model), 11
**Confidence:** High
**Class:** honest-path (a future edit, not an attacker)
**Legibility-target:** the next maintainer of `writable`, `INSTRUCTION_FILE` or `truthrule`

Evidence: `truthrule "$7" || true  # $7 is lower-cased, so no word hides cycle, settings or user` and, in the lib, `elif isstart "$1"; then TRUTH_WHY="instr"` / `elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"` / `elif writable "$1"; then TRUTH_WHY="cycle"`. The comment's claim holds today only for `case`; `instr` and `dot` also precede `cycle`, and nrules' `*)` arm passes any non-briefs/cycles path that gets those words. No current writable file, `docs/dev-cycle.md` or `docs/constraints.md` can match `isstart` or the dot test (traced above; P4 executed), so nothing passes now. Adding, say, a dot-directory cycle file or a `writable` entry named like an instruction file would silently drop it from the N rules (the S rules of U2c may or may not catch it).

**Recommendation:** Either test `writable`/settings/user directly in nrules before `truthrule` is consulted, or extend the comment to name the invariant ("no cycle, settings or user path is an instr or dot path") so the dependency is visible where `writable` is edited.

#### 3. A16's two guards are pinned only jointly

**Severity:** Informational
**Location:** `scripts/build-loop.sh:595`; `test/scripts/build-loop-check.bats:1507-1510`
**Boundary:** B1
**Move:** 11
**Confidence:** High (from Stage 1, item 1 and its escalation; not re-executed here)
**Class:** honest-path (test gap)
**Legibility-target:** the orchestrator (already escalated by Stage 1)

Evidence: `gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree"`; test comment `# ignore = all in .gitmodules and the repo config: diff-tree in the real repository would hide gl (A16).` Stage 1: "T12 fails only when diff-tree both runs in the real repo AND drops --ignore-submodules=none; either guard alone passes T12." Either guard alone keeps the moved gitlink visible, so no path lands today; a regression that removed one guard would go unnoticed until the other also went.

**Recommendation:** Accept as designed defense-in-depth with a note, or add a mutant-style test per guard. Not a red.

## Untested bypass candidates

- `own_blob`'s failure branch (`:558`) was read, not executed: forcing a failed second `cat-file` of main's brief needs a race or a store fault between `status_line` and `own_blob` (iteration 1 override row declined testing the race). The fail-closed path is established by reading `:535-542` under `set -o pipefail` (`:140`).
- A lower_all/tr that dies after a partial flush (`:614`) was not induced; covered by `nul_list`'s trailing `rc=0` sentinel and the count compare, both read.

## Endorsement Claims

- **Claim:** A tip whose merge adds or changes a regular file to a blob id the object store lacks, or to an id of another type, is refused before any path verdict prints.
  **Location:** `scripts/build-loop.sh:602,609-611`
  **Evidence:** executed
  **Verified:** probes P1 (tree id under 100644), P2 (one present, one missing), P3 (missing at 100755), each `refuse …: names a file the object store lacks`, status 2; the suite's R6 test (fact-check: the missing-blob mutant fails it).
  **Not verified:** a missing blob at a path whose old side is a symlink (T to file) was not probed; it is in `ids` by the `nms` test at `:602`.
  **route: code-fact-check**
- **Claim:** nrules refuses briefs/, cycles/, writable, `docs/dev-cycle.md` and `docs/constraints.md` paths in any ASCII case, including those `truthrule` words `instr` or `dot`.
  **Location:** `scripts/build-loop.sh:556-566`
  **Evidence:** executed
  **Verified:** P4 (briefs/CLAUDE.md, cycles/.x, docs/Constraints.md, docs/working/Idea-Log.md all denied); P5 (docs/working/QUESTIONS.md denied among 1,002 paths); suite T14 (16 paths) per Stage 1.
  **Not verified:** a writable path that `isstart` matches; none exists under the current regexes (Finding 2).
  **route: code-fact-check**
- **Claim:** The lower-cased list `lps` is index-aligned with `ps` whenever nrules runs.
  **Location:** `scripts/build-loop.sh:614-618`
  **Evidence:** executed
  **Verified:** P5's single deny falls on the one cycle path among 1,002; code read of `nul_list`/`lower_all` and the count compare.
  **Not verified:** behaviour when `tr` is killed mid-stream (not induced).

## Primitive sweep

Primitive: git object reads/writes on loop-supplied ids (gate repository)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:595` `gate_git diff-tree … "$MAIN_SHA" "$tree"` | S1 (tree from merge_result) | gate_git rc/stderr; record regex `:600` | cleared — unchanged in range |
| `scripts/build-loop.sh:609` `gate_git cat-file --batch-check` | S1 (blob ids, hex only by regex `:600`) | count of `blob` lines; gate_git stderr | cleared — P1-P3; gate repo has no refs, so a 40-hex name cannot resolve to a ref (R8 residual aside) |
| `scripts/build-loop.sh:541` `gate_git hash-object --no-filters --stdin` | S2 | pipefail, now checked at `:558` | cleared — F1 fix |
| `scripts/build-loop.sh:539,541` `git cat-file blob "$MAIN_SHA:$1"` (real repo) | S2 | pipefail | cleared — unchanged in range; brief path from status_line |

Primitive: path classification on loop-supplied names
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:555` `pathform "$6"` | S1 | first rule | cleared — unchanged logic |
| `scripts/build-loop.sh:561` `truthrule "$7"` | S1 lower-cased | pathform first; `*)` prefix arm | Finding 2 (latent ordering dependency) |
| `scripts/build-loop.sh:614` `nul_list lps lower_all` | S1 | sentinel + count compare | cleared — P5 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | "object store lacks" also covers wrong-type objects; wording | Informational | B1 | `scripts/build-loop.sh:609-611` | High |
| 2 | nrules' cycle/user coverage depends on truthrule's word order | Informational | B2 | `scripts/build-loop.sh:561-565` | High |
| 3 | A16's two guards pinned only jointly (Stage 1 escalation) | Informational | B1 | `scripts/build-loop.sh:595` | High |

## Overall Assessment

Both iteration-1 security findings are fixed: F1 fails closed on any failed read of main's brief, and F2's batch-check refuses a missing or wrong-type object for every new regular file (executed). The changes the fixes brought in did not open a pass-through: routing nrules through `truthrule` keeps exactly the old coverage (no cycle, settings or user path can take the `instr`/`dot` words that precede `cycle`), the batch lower-casing is index-aligned and fails closed, and `default_gate` keeps its position and now prints every finding. The three findings are Informational (one wording, one latent coupling worth a comment, one test gap Stage 1 already escalated). No red. R8 stays the Q-103 residual a382a3f8 recorded; the new batch-check adds one more `gate_git` call to that same surface and no new kind of exposure. The single most useful follow-up is Finding 2's comment or direct check, so a future `writable` edit cannot silently fall out of the N rules.

## Goal-Alignment Note

The user's goal is to land U2b1b after a clean review-fix loop. This pass found no red and no Medium-or-higher finding within the fix range; the fixes for security F1 and F2 hold under execution, and nothing they changed opens a path the gate used to refuse. The three Informational items can go to override rows or a one-line comment without another fix iteration, so on the security axis this review does not block landing.
