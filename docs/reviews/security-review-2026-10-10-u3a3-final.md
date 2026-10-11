Commit: 01a2935f

# Security Review: feat/build-loop-u3a3 (final confirming pass, full branch)

**Scope:** `git diff main...HEAD` (18f32952, a7a4f784, e25a6e89, 01a2935f): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-{check,merge}.bats. Self-read; enclosing functions read in full (check_line, srules, nrules, status_fields, approval, land, the merge arm, check_answer, ANSWER_AWK, floor, floor_why, truthwalk, imported_names' changed lines, check_fix).
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3a3-final.md (no behavioral defect; comment wording only); rubric docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a3.md; override rows dated 2026-10-10 for this branch; security reviews i1 and i2.
**Threat model:** a hostile build loop (same uid) controls its branch and worktree. The gate, run from main's copy, must not land anything the rules refuse. An answer must have reached main (D8). Same-uid planted or racing git state is the Q-103 residual (row 509, Q-138 interim [1]).

## Trust Boundary Map

```
B1: loop branch tip, its tree and changed paths (S1) → check_line: --expect, merge_result, store_check, nrules, `lps =~ $GATE_CODE` → VERDICT (tip, tree, policy, stem, gate)
B2: questions entry on main (S2)                     → check_answer (ANSWER_AWK at MAIN_SHA) → $GATE_TMP/answer + ANSWER_HEADING → approval()  (new)
B3: VERDICT + --approved Q-NNN (S3, S4)              → approval(): exact "keep Q-NNN" + byte-exact heading → land(AUTH, Q-NNN) → CAS from MAIN_SHA / ff in W  (new)
B4: changed path under self-merge (S1)               → srules → floor (word) → floor_why → DENY  (moved: words instead of sentences)
B5: instruction-file walks (S5)                      → truthwalk main|tree → TRUTH_WHY + TRUTH_WHERE → floor_why / dev-cycle.sh check_fix  (moved)
B6: gate scratch dir $GATE_TMP (S6)                  → files the gate writes then reads back (line, diff, msg, answer, ...) → decisions and output  (answer is new)
```

Input-source classification:

```
S1: loop branch tip, tree, paths             — runtime-mutable (loop-owned) — UNTRUSTED for every sink (merge content,
                                                gate bit, floor, printed paths: shown as ? unless pathform)
S2: docs/working/questions{,-archive}.md     — runtime-mutable, but only through main; the N rules deny both to any merge
    at MAIN_SHA                                 — trusted as authorisation only as parsed fail-closed (exact keep + heading)
S3: brief path / stem                        — orchestrator argument; check_brief and status_fields read it from main —
                                                trusted for naming the heading
S4: --expect SHA, --approved Q-NNN           — orchestrator arguments — format-checked (full 40/64 hex, mandatory with
                                                --merge; ^Q-[0-9]+$, once); trusted for selection, not for content
S5: instruction files on main / checkout     — runtime-mutable — UNTRUSTED; their walks fail closed (TRUTH_WHY=walk)
S6: $GATE_TMP files                          — written by the gate, writable by any same-uid process during the run —
                                                untrusted against a racing writer (Q-103 residual, row 509)
S7: GATE_CODE regex, floor_why words         — code-constant — trusted
```

What enters from outside: the loop's tip (S1) and the questions entry on main (S2). The diff adds one authorisation boundary (B2 to B3). An approved run drops the S rules and the checkout rule. It keeps the N rules, --expect, merge_result, store_check and every land gate. The floor and walk refactors (B4, B5) change only how a refusal is worded. Every return path is the same as before.

## Findings

#### 1. The authorisation word crosses $GATE_TMP as a file, which adds the answer itself to the same-uid racing surface

**Severity:** Informational (the floor rule's exception applies: the attacker is a same-uid writer, the class row 509 settled as a Q-103 residual)
**Location:** `scripts/build-loop.sh:1083` (approval)
**Boundary:** B6, B2
**Move:** 4 (check vs use), 11
**Confidence:** High that the mechanism exists (traced read-static). Low that it matters: a same-uid writer can move main itself (row 509).
**Legibility-target:** the Q-103 residual list (row 509's "Surface:" sentence), for U5's re-route.

Evidence (verbatim):
```
  check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"
```
```
  [[ "$ANSWER_HEADING" == "$1 · $s" ]] \
```
The heading is held in a shell variable, so a racing writer cannot forge it. The answer word goes through a file instead. The orchestrator files the entry with the exact heading before the user answers, so an open entry has a matching ANSWER_HEADING. A same-uid process that rewrites `$GATE_TMP/answer` to `keep Q-NNN` between the write and the read would turn `open Q-NNN` (or `drop`) into an approval, and land() would then run. The `msg`, `line` and `diff` files already carry this class, and row 509 decided it is a residual because no in-script measure stops the same uid. Here, though, the file holds the authorisation itself rather than an input to a computation. This diff adds it, and row 509's surface list does not name it.

**Recommendation:** at minimum, add `answer` to row 509's surface list, or to Q-103's list at U5. A zero-cost alternative removes it from the surface: check_answer already sets ANSWER_HEADING as a side value, so it could also set its result word (for example ANSWER_WORD), and approval would compare that instead of reading the file back. The file redirect would stay only to discard stdout.

No other findings. Every override row dated 2026-10-10 for this branch still holds: the 12-hex prefix (U4), health-check.sh (Q-103/U5), the floor paths and sibling skills on a plain merge- entry (U4), and the config_seeds flake. None of them regressed at 01a2935f.

## Answers to the brief's focus questions

- **Can a hostile loop make `--merge --approved` land something its answer did not approve?** Not within the code paths read, apart from Finding 1's same-uid race. The loop controls S1 only.
  - (a) The tip is bound in full by the mandatory `--expect` (`check_line`: `"$sha" != "$EXPECT"` refuses before anything reads AUTH; executed: build-loop-merge.bats test 10, mismatched `--expect` under `--approved`).
  - (b) The heading binds the stem, the tip's first 12 hex digits and the gate bit. The gate bit comes from the merge's own diff-tree against MAIN_SHA, deletions included, and is compared lower-cased. The loop cannot clear it while changing gate code.
  - (c) The answer is read from MAIN_SHA, which the N rules deny to any merge. The loop cannot plant it on its branch, in the worktree (executed: working-tree answer refuses) or through the merge that is being decided.
  - (d) land's first parent and its compare-and-swap old value are the same MAIN_SHA the answer was read from. If the user revokes the answer on main after the check, main moves and update-ref refuses.
  - (e) Replay is refused. After a landing the branch is 0 ahead ("has no commit the default branch lacks"). Any new commit changes the tip and so the heading.
  - (f) A stem collision ("merge-gate-X-T" read as stem `gate-X` with no gate bit) cannot happen. For the same tip and MAIN_SHA the diff, and so the gate bit, are identical whichever brief names the tip, and briefs are main-only files the loop cannot add (N rules).
- **Can a refusal print as merged?** No, within the merge arm read. `v` starts `merged` only on the `elif land ...` arm's success. The policy refusal, every approval refusal and every land refusal assign `v="refuse $a: ..."`, and `[[ "$v" == merged* ]] || exit 2` follows. A check_line skip or refuse leaves VERDICT[tree] empty and exits 2 before approval. approval returns 0 only on the exact `keep Q-NNN` arm followed by a byte-exact heading compare. A failed read of the answer file leaves `r` empty, which takes the `*` arm and refuses.
- **The floor-word refactor: does any refusal become a pass?** No. Each floor branch still ends with exit status 0: an assignment, or `[[ "$FLOOR_WHY" != settings ]] || FLOOR_WHY=cycle`, both 0. The only `return 1` is unchanged (after the walk succeeded and no directory matched). Every word truthrule sets (case, instr, dot, cycle, settings mapped to cycle, user, record), plus gate, working, review, walk, imported and below, has a floor_why arm. Any other word falls to a non-empty default, so srules' DENY is never empty after a floor refusal. If `$(floor_why ...)` cannot fork, the run aborts and nothing lands: a probe with `ulimit -u 1` under `set -euo pipefail` exits 254 without returning from the caller (`security/probe-fork.sh`). No truthwalk runs between floor and floor_why in srules, so TRUTH_WHERE belongs to that path's walk.
- **TRUTH_WHERE: does any refusal become a pass?** No. truthwalk returns 0 on every walk failure in both modes. The new braces end in `return 0` after `;`, so a failed walk_why substitution still returns 0. TRUTH_WHERE is text only: both callers (floor_why's walk arm and dev-cycle.sh check_fix) print it, and neither decides on it. In check_fix both arms after `elif truthwalk tree` are skip lines. IMPORTED_WHY cannot go stale: a readers failure empties IMPORTED_DONE, so the next call walks again and resets IMPORTED_WHY to empty.
- **The S rules under `--approved`:** they are skipped, as plan line 213 intends. With AUTH empty (`--check`) or self-merge, `sm` is 1 exactly when the policy is self-merge, which matches the pre-diff conditions on read_paths, checkout_gate and srules. build-loop-check.bats ran 146/146, unchanged.

Candidates traced or executed against the approval guard (move 11; none bypass, apart from Finding 1):
- heading with a trailing CR (awk drops it) or a trailing space or tab (byte-exact compare refuses);
- `Q-01` vs `Q-1` (awk matches the literal id plus a space; the heading compare uses `$1` literally);
- the entry in both questions files (skip) or twice in one file (dup, skip);
- options [2] and [3], `merge`, open, a working-tree-only answer, no entry, another brief's or an older tip's slug, a plain slug for gate code (executed, tests 9 to 11);
- a mismatched `--expect` (executed);
- a planted answer line in the entry body: the parser takes the first `Q-NNN:` or `**Answer` line, but per F41 and F48 the body is `--check`'s output (lines start `ok`, `path`, `deny`, `refuse`; paths cannot hold `:` or `*`) plus `> `-prefixed loop text (read-static against the plan; U4's writer is unbuilt);
- the `$GATE_TMP/answer` race (Finding 1);
- fork exhaustion in `$(floor_why)` (executed probe, aborts).

## Untested bypass candidates

- **A Unicode-lookalike `·` or hyphen in a heading**: not executed. The heading is written by the orchestrator or the user, not the loop, and any byte difference refuses. It is listed only because no test exercises a non-ASCII mismatch.

## Endorsement Claims

- **Claim:** `--merge` prints a line starting `merged` only when land returns 0. Every policy, approval and land refusal prints `refuse BRIEF: ...` and exits 2.
  **Location:** `scripts/build-loop.sh:1218-1230`
  **Evidence:** executed (build-loop-merge.bats 12/12 serial: refusal tests check that main did not move and the exit status) plus read-static (merge arm)
  **Verified:** the three `v=` arms, the `exit 2` guard, and the refusal tests' assertions.
  **Not verified:** a land refusal after NEW is written (the state gate re-run failing) under `--approved` in an executed run.
  **route: code-fact-check**

- **Claim:** under `--approved`, approval returns 0 only when check_answer's output at MAIN_SHA is exactly `keep Q-NNN` and ANSWER_HEADING equals `Q-NNN · merge[-gate]-STEM-TIP12` byte for byte, with `-gate` exactly when VERDICT[gate] is set.
  **Location:** `scripts/build-loop.sh:1077-1092`, `scripts/lib/dev-cycle-read.sh:2082-2110`
  **Evidence:** executed (tests 9 to 11) plus read-static
  **Verified:** the case arms, the heading compare, the awk's `head` capture (first matching heading only; count>1 is dup), and check_answer's split of the two lines.
  **Not verified:** check_answer's `odd`, `unbalanced` and `quoted` results through approval in an executed run (read: they print `skip Q-NNN: ...`, which goes to the skip arm). Also Finding 1's racing writer.
  **route: code-fact-check**

- **Claim:** VERDICT[gate] is set when any diff-tree record of the merge, including D and T records, has a lower-cased path matching GATE_CODE, and the floor refuses the same paths under self-merge.
  **Location:** `scripts/build-loop.sh:1049`, `scripts/lib/dev-cycle-read.sh:1925,1957`
  **Evidence:** executed (merge test 11, upper-case and skills/dev-cycle cases; check test T10 incl. skills/dev-cycle-x passing) plus read-static
  **Verified:** that the gc line runs for every changed path regardless of DENY, and the T10 rows.
  **Not verified:** a deletion-only change to a gate file under `--approved` in an executed run.
  **route: code-fact-check**

- **Claim:** the answer is read from the same MAIN_SHA that land uses as the first parent and as update-ref's old value, so an answer changed on main after the check makes the compare-and-swap refuse.
  **Location:** `scripts/build-loop.sh:1083,1180,1186`
  **Evidence:** read-static
  **Verified:** that MAIN_SHA is set once in gate_start (default_gate) and read by check_answer, commit-tree `-p "$MAIN_SHA"` and `update-ref ... "$NEW" "$MAIN_SHA"`.
  **Not verified:** the W branch (merge --ff-only) when main moves backward to an ancestor of MAIN_SHA. That path is pre-existing from U3a2, and NEW still carries MAIN_SHA as a parent.
  **route: code-fact-check**

- **Claim:** after the floor-word refactor, floor refuses exactly the paths it refused before, and srules' DENY is non-empty for every refusal.
  **Location:** `scripts/lib/dev-cycle-read.sh:1952-1990`, `scripts/build-loop.sh:839`
  **Evidence:** executed (build-loop-check.bats 146/146 serial; probe-fork.sh) plus read-static
  **Verified:** the branch-by-branch exit statuses, floor_why's arms for every word truthrule sets, and the default arm.
  **Not verified:** a word that truthrule might add later (it would reach floor_why's default arm, which still refuses).
  **route: code-fact-check**

- **Claim:** truthwalk returns 0 on every walk failure in both modes. TRUTH_WHERE only changes printed text, and check_fix still prints a skip for both outcomes.
  **Location:** `scripts/lib/dev-cycle-read.sh:1894-1904`, `scripts/dev-cycle.sh:185-187`
  **Evidence:** executed (dev-cycle.bats 79/79 serial) plus read-static
  **Verified:** the two failure braces and check_fix's two arms.
  **Not verified:** check_fix's readers-failure line without IMPORT_READER_WHY (the fact-check's escalation: it fails closed and is untested).

## Primitive sweep

Primitive: authorisation decision (answer → land)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1225` review-policy refusal | S3 policy from main | AUTH=self-merge | cleared: refuses review without --approved |
| `scripts/build-loop.sh:1226` approval "$APPROVED" | S2, S1 (tip, gate bit), S3, S4 | exact `keep Q-NNN` + byte-exact heading | cleared, except Finding 1 (answer word via S6) |
| `scripts/build-loop.sh:1227` land "$AUTH" "$APPROVED" | S4 | AUTH set only from APPROVED; `%s` printf | cleared: the trailer only labels the commit |

Primitive: file write then read-back in $GATE_TMP (S6)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1083` answer | S2 via check_answer | none against same uid | Finding 1 (new in this diff) |
| `scripts/build-loop.sh:1222` line | check_line output | none against same uid | cleared: pre-existing, row 509 residual; decisions use VERDICT, not the file |
| `scripts/build-loop.sh:1179` msg | VERDICT, S4 | none against same uid | cleared: pre-existing, row 509 residual |
| `scripts/build-loop.sh:1003` diff | gate_git diff-tree | NUL count check | cleared: pre-existing, row 509 surface |

Primitive: GATE_CODE match
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1049` gc bit | S1 lower-cased | lower_all, pathform, mode rule | cleared (tests); neighbours deferred per rows (U4, Q-103/U5) |
| `scripts/lib/dev-cycle-read.sh:1957` floor `gate` | S1 lower-cased | truthrule runs first | cleared (T10) |

Primitive: process exec with repo-derived arguments
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:2095` `awk -v id="$a"` | S4 | `^Q-[0-9]+$` (arg parse and check_answer) | cleared |
| `scripts/build-loop.sh:1186` `update-ref -m "$msg"` | S3 stem | check_brief path form | cleared: argv, not a shell |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | The approval's answer word is read back from $GATE_TMP/answer, adding the authorisation itself to the same-uid racing surface (row 509 / Q-103 class; not on its surface list) | Informational | B6, B2 | `scripts/build-loop.sh:1083` | High (mechanism) / Low (impact) |

## Overall Assessment

The `--approved` path fails closed end to end within the code paths read. It needs the mandatory full `--expect`, an exact `keep` answer read from MAIN_SHA, and a byte-exact heading that binds the stem, the tip prefix and the gate bit. The N rules and every land gate still run, and the compare-and-swap uses the commit the answer was read from. A refusal cannot print as merged. Neither the floor-word refactor nor TRUTH_WHERE turns a refusal into a pass: return paths are unchanged, every word has a non-empty sentence, and a failed substitution aborts the run. The three suites pass serially (merge 12/12, check 146/146, dev-cycle 79/79). The one new item is Informational and belongs to an already-decided residual class: the authorisation word round-trips through `$GATE_TMP`. The cheapest useful action is to name `answer` in row 509's surface list, or to replace the read-back with a side variable at no cost. No findings block the merge within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/security-review-2026-10-10-u3a3-final.md, structured per the security-reviewer skill, with `Commit: 01a2935f` at the top."

This report is at that path, with `Commit: 01a2935f` on its first line. It follows the skill's structure: boundary map, source table, findings with severity, location, verbatim evidence, confidence and legibility target, untested bypass candidates, endorsements with routes, primitive sweep, summary and assessment. It serves the user goal of getting U3a3 through its review-fix loop and merged locally. The final pass finds no regression and no landing path the rules refuse. It leaves one Informational item for the Q-103 surface list.
