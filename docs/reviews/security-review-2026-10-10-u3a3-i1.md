Commit: a7a4f784

# Security Review: feat/build-loop-u3a3 (iteration 1, loop pass)

**Scope:** `git diff main...HEAD` (18f32952 tests, a7a4f784 code): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-{check,merge}.bats
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3a3-i1.md (22 Verified, 4 Mostly accurate, all comment wording); shared brief u3a3-i1/brief.md
**Threat model:** a hostile build loop (same uid) that controls its branch, its worktree and anything it can get committed through other channels. Question: can `--merge --approved Q-NNN` land something the user did not approve?

## Trust Boundary Map

```
B1 (new): loop branch tip (S1) + brief path (S3)     → check_line (N rules only, AUTH=approved) → VERDICT[tip, stem, gate]
B2 (new): questions entry on main (S2)               → check_answer / ANSWER_AWK → ANSWER_HEAD + "keep Q-NNN" → approval()
B3 (new): VERDICT[stem]+VERDICT[tip]:0:12+VERDICT[gate] → approval()'s exact heading compare → land(approved, Q-NNN) → CAS on main from MAIN_SHA
B4 (moved): changed path (S1, lower-cased)            → floor → FLOOR_WHY word → floor_why sentence → srules DENY (self-merge only)
B5 (moved): import-walk failure state (S4)            → truthwalk TRUTH_WHERE → floor_why "walk" / dev-cycle.sh check_fix skip line
```

Input-source classification:

```
S1: loop branch tip, its tree and paths  — runtime-mutable (loop-owned) — UNTRUSTED for every sink (merge content, gate detection, heading binding)
S2: docs/working/questions{,-archive}.md at MAIN_SHA — written by the user / orchestrator (D8, D11);
                                         reaches main only outside the gate (N rules deny both files)
                                         — trusted as authorisation only if its write channels stay closed to S1;
                                           its bytes still parsed fail-closed (fences, dup, CR)
S3: brief path argument / stem          — orchestrator argument; the brief must be open on main (status_fields)
                                         — trusted for naming, checked against main
S4: import-walk state (IMPORTED_WHY, IMPORTED_MAIN_WHY, TRUTH_WHERE) — computed in-process — trusted (wording only)
S5: --expect SHA, --approved Q-NNN      — orchestrator arguments — format-checked (40/64 hex; ^Q-[0-9]+$, once);
                                         where the orchestrator sources --expect is not in this diff
S6: GATE_CODE regex                     — code-constant — trusted; its coverage is Finding 2
```

What enters from outside is the loop's branch (S1); the authorisation is the questions entry on main (S2). The diff adds one new trust transition: a user's ANSWERED [1] on a heading `Q-NNN · merge[-gate]-STEM-SHA12` now replaces the S rules, the floor and the checkout rule for that merge. The binding between "what the user approved" and "what lands" is the stem, the tip's first 12 hex digits, and the gate bit.

## Findings

#### 1. The approval binds only 48 bits of the tip; a loop that can grind a 12-hex prefix collision lands unapproved content if the orchestrator takes --expect from the live branch

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1066-1084` (approval), `scripts/build-loop.sh:1214-1217` (merge arm)
**Boundary:** B1, B3
**Move:** 11 (bypass the guardrail), 4 (check vs use)
**Confidence:** Low (cost-bound and depends on the unbuilt orchestrator's source of `--expect`)
**Legibility-target:** the plan's L2/F33 rows say merge entries "pin TIP, checked by `--approved`"; a reader of approval() should see that only the prefix is pinned and that the full pin lives in `--expect`.

Evidence (verbatim):
```
  s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"
  [[ "$ANSWER_HEAD" == "$1 · $s" ]] \
```
and in the plan (`docs/working/plan-build-loop-handoff.md:148`): `merge entries pin TIP, checked by --approved (T35)`.

The full tip is bound only by `--expect`, which `check_line` compares to the branch's current tip (`[[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]`). The heading binds `TIP[0:12]`, 48 bits. Scenario: the user reviews tip X and answers [1] on `merge-STEM-X12`. The loop then grinds a commit Y with different content and `Y[0:12] == X[0:12]`, which is a second preimage on 48 bits (about 2^48 SHA-1 evaluations, a nonce in the commit message; days of CPU, hours of GPU), and resets its branch to Y. If the orchestrator builds `--expect` from the branch's live tip (or from the loop's ready marker) rather than from the full SHA recorded when it filed the entry, `--merge BRIEF --expect Y --approved Q-NNN` passes every check and lands Y. If the orchestrator always passes the full TIP it recorded at filing time, the attack fails at `--expect`. The script cannot tell which, so the property rests on an orchestrator rule that is not written down here.

**Recommendation:** have approval() check the full tip, for example a `Tip: <full sha>` line in the entry body or the `Q-NNN@SHA` key D4 already describes, compared to `VERDICT[tip]`. Failing that, state in the `--merge` header and the U4 skill text that `--expect` must be the full SHA recorded in the entry, never the branch's current tip.

#### 2. GATE_CODE omits `skills/dev-cycle/`, which the plan lists as gate code needing a `merge-gate-` slug (F52)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1915` (GATE_CODE), `scripts/build-loop.sh:1041` (gc detection), header `scripts/build-loop.sh:229-230`
**Boundary:** B1, B3
**Move:** 5 (invert the access control model), 11
**Confidence:** Medium (the plan contradicts itself: line 61 includes `skills/dev-cycle/`, line 71's floor item 3 lists only the four scripts)
**Legibility-target:** the user reading a `merge-STEM-SHA12` entry must be able to rely on the plain slug meaning "no gate change".

Evidence (verbatim):
```
GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/'
    [[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1
```
Plan `docs/working/plan-build-loop-handoff.md:61`:
```
    - A change to the gate's own files (`scripts/{build-loop,dev-cycle,questions}.sh`, `scripts/lib/`, `skills/dev-cycle/`) gets its own slug, `merge-gate-…`. Plain `--approved` refuses such a change (F52).
```

Under `--approved` only the N rules run, so a change to `skills/dev-cycle/SKILL.md` lands under a plain `merge-STEM-SHA12` answer. Under self-merge the floor's `instr` word still refuses it, since `SKILL.md` matches `INSTRUCTION_FILE`. That skill is the orchestrator's procedure, including D6's rule for how the gate is launched (main's copy, hash-checked) and, in U4, how `--expect` and `--approved` are passed (see Finding 1). A loop that bundles an edit there with an otherwise benign change gets it approved without the distinct `merge-gate-` warning F52 exists to give. The user still approved a merge, so this weakens the approval's labelling and does not bypass it. That is why it is Medium and not High.

**Recommendation:** add `^skills/dev-cycle/` to GATE_CODE, or a separate approval-only pattern if the floor should keep its current wording, and add a T35 case. Otherwise reconcile plan lines 61 and 71 with an override row that records `skills/dev-cycle/` as deliberately plain-slug.

#### 3. A plain `merge-` approval gives no signal for the other paths the floor treats as take-effect-on-merge (instruction files, dot-paths, `docs/thoughts/`)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:974` (`sm` under AUTH=approved), `scripts/build-loop.sh:1066-1084`
**Boundary:** B1, B3
**Move:** 5
**Confidence:** High (behaviour); intended per plan line 213
**Legibility-target:** the merge entry the orchestrator files (U4).

Evidence (verbatim):
```
  [[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1  # the S rules and the checkout
```
Under `--approved` the floor is skipped by design: plan line 213, "With it, only the N rules apply". So `.claude/settings.json`, hooks under dot-directories, `CLAUDE.md`/`AGENTS.md` and `@`-imported files land under a plain slug. D5 defines the floor as "what takes effect on merge with no later review", and gate code is the only one of those categories with its own slug. This is the intended authority, not a bypass. It is listed because the user's attention on the entry is the only control left for these paths. **Recommendation:** have U4's entry body list any changed path the floor would refuse, with its `floor_why` reason. The words this diff introduces make that cheap.

## Untested bypass candidates

- **Prefix-grind of SHA12 (Finding 1):** not executed. A 2^48 search is out of budget for a review. Its cost was estimated, not measured.
- **Orchestrator's choice of `--expect`:** not testable. U4 is not built.

Candidates tested (traced or executed; none bypass):
- Heading lookalikes and trailing text (executed, probe `security/probe1.sh` against the lib's check_answer). `· ` replaced by U+2022, a tab before `·`, and trailing ` trailing` all reach ANSWER_HEAD verbatim, and approval()'s quoted `==` compares bytes, so each refuses. A trailing CR is dropped once (`sub(/\r$/, "")`), which is intended. The test suite also covers a trailing space, `-x` suffix, another stem, an older tip and gate-vs-plain (`build-loop-merge.bats:224-247`, run: ok).
- Glob in stem: the RHS of `==` is quoted, so it is a literal.
- `Q-01` vs `Q-1`: `heading()` matches the ID string exactly and approval() compares `"$1 · $s"`, so a mismatch refuses.
- Two entries for one ID: `dup` in one file, or "in both" across questions.md and the archive, gives a skip, which refuses.
- Smuggling a forged answer onto main through a gate merge: `docs/working/questions.md` and `questions-archive.md` match `writable()`, so `nrules` denies them as "one of the dev cycle's own files" under both authorities. Tests cover this for `docs/roadmap.md` only (read-static for the questions files).
- Upper-case gate paths: lower-cased via `lower_all` before GATE_CODE (`Scripts/Lib/x.sh` test, run: ok). A deleted gate file is a `D` record in `lps`, so `gc=1`.
- Fork failure turning `DENY="$(floor_why ...)"` empty (move 3; srules runs inside an `||` list, where set -e is off). Executed `security/fk.sh` under `ulimit -u 1`: bash exits 254 on a command-substitution fork failure, before the next command, so no empty DENY is produced. This is fail-closed.

## Endorsement Claims

- **Claim:** approval() reads the answer only from MAIN_SHA's blobs, the same commit land() uses as the merge's first parent and as the CAS old value, so the answer and the landed base cannot diverge without the CAS failing.
  **Location:** `scripts/lib/dev-cycle-read.sh:2083`, `scripts/build-loop.sh:1170,1176`
  **Evidence:** read-static
  **Verified:** check_answer's `git cat-file blob "$MAIN_SHA:$f"`, land's `commit-tree ... -p "$MAIN_SHA"` and `update-ref --no-deref ... "$NEW" "$MAIN_SHA"`; gate_start's `store_check --main "$MAIN_SHA"` lists `ls-tree -r -t` of main, so the questions blobs are re-hashed and single-copy checked.
  **Not verified:** the W branch of land (`merge --ff-only` in the worktree with main checked out), whose old-value check is the `rev-parse HEAD == MAIN_SHA` test at `build-loop.sh:1148`, not a CAS. Racing writers are Q-103.
  **route: code-fact-check**

- **Claim:** an approved merge cannot change `docs/working/questions.md` or `questions-archive.md` (any case, or a path below either), so a user-approved merge cannot carry a forged answer for a later `--approved`.
  **Location:** `scripts/build-loop.sh:767-797` (nrules), `scripts/lib/dev-cycle-read.sh:238-241` (writable)
  **Evidence:** read-static
  **Verified:** writable's regex `^docs/working/(questions|questions-archive|idea-log)\.md$`; truthrule maps it to `cycle`; nrules denies `cycle` for `$7` (lower-cased) and for every directory above it.
  **Not verified:** an executed T35 case with `docs/working/questions.md` (the test uses `docs/roadmap.md`), and write channels to main outside the gate (the orchestrator's commits, D13 `--cycle-diff`, T38).
  **route: code-fact-check**

- **Claim:** every FLOOR_WHY word floor can set (case, instr, dot, cycle via settings, user, record, gate, working, review, walk, imported, below) has a non-empty floor_why sentence, and an unknown or empty word prints a non-empty default, so the refactor turns no refusal into an empty DENY.
  **Location:** `scripts/lib/dev-cycle-read.sh:1940-1978`, `scripts/build-loop.sh:831`
  **Evidence:** read-static (plus the executed fork-failure probe above)
  **Verified:** floor's branches each assign a word and the if-compound returns 0. truthrule's words are listed at `dev-cycle-read.sh:1867-1878`. floor_why's `*)` case echoes `refused by the self-merge floor (...)`.
  **Not verified:** a future truthrule word added without a floor_why case. It would print the default sentence (still a deny), not its own wording.
  **route: code-fact-check**

- **Claim:** with AUTH empty (`--check`) or self-merge, `sm` is set exactly when the policy is self-merge, which is the pre-diff condition for the checkout rule, read_paths and srules.
  **Location:** `scripts/build-loop.sh:974,1024,1027,1042`
  **Evidence:** executed (`bats -f approved test/scripts/build-loop-merge.bats`: 5/5 ok; build-loop-check.bats not re-run here)
  **Verified:** the `sm` expression and its three uses; test 207 shows the checkout rule refusing without `--approved` and skipped with it.
  **Not verified:** the full build-loop-check.bats run at a7a4f784.

## Primitive sweep

Primitive: authorisation decision (answer → land)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:1215` approval "$APPROVED" | S2, S1 (tip), S3 (stem) | check_answer keep + exact heading | Finding 1 (48-bit tip binding), Finding 2 (gate bit coverage) |
| `scripts/build-loop.sh:1214` review-policy refusal | S1 policy from main | AUTH=self-merge | cleared: unchanged condition, only the message changed (row 661) |
| `scripts/build-loop.sh:1216` land "$AUTH" "$APPROVED" | S5 | APPROVED format `^Q-[0-9]+$` | cleared: printf `%s` into the message file, not a format string |

Primitive: command substitution on a deny path
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:831` `DENY="$(floor_why ...)"` | S4 | default case, fork failure exits | cleared (probe fk.sh) |
| `scripts/lib/dev-cycle-read.sh` truthwalk `TRUTH_WHERE="$(walk_why ...)"` (main, tree) | S4 | wording only; return 0 (walk) fixed before it | cleared: an empty TRUTH_WHERE still refuses |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Approval binds only TIP[0:12]; prefix grind plus a live-tip `--expect` lands unapproved content | Medium | B1, B3 | `scripts/build-loop.sh:1066-1084` | Low |
| 2 | GATE_CODE omits `skills/dev-cycle/` (plan line 61, F52), so a plain `merge-` slug approves it | Medium | B1, B3 | `scripts/lib/dev-cycle-read.sh:1915` | Medium |
| 3 | Plain `merge-` slug gives no signal for other floor categories (intended authority) | Informational | B1, B3 | `scripts/build-loop.sh:974` | High |

## Overall Assessment

The `--approved` path fails closed on every input shape I could construct: lookalike headings, trailing text, wrong IDs, duplicate entries, working-tree-only answers and fork failure. The answer is read from the same main commit that the CAS lands on, and the questions files are N-rule-denied, so a loop cannot get a forged answer onto main through the gate. The floor-word refactor leaves no path to an empty DENY. Both findings are about the binding between the approval and what lands, not a parser bypass, and both can be fixed in place. Finding 1 is the most important. The heading pins 48 bits of the tip, and the full pin depends on how the not-yet-built orchestrator sources `--expect`. Either check the full tip from the entry or write that orchestrator rule down. Finding 2 is a spec mismatch to resolve with an override row or a one-line GATE_CODE change. No findings within the code paths read beyond these; endorsement claims pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/security-review-2026-10-10-u3a3-i1.md, structured per the security-reviewer skill, with `Commit: a7a4f784` at the top."

This report is at that path, with `Commit: a7a4f784` on its first line and the skill's structure: boundary map, source table, findings, untested bypass candidates, endorsements, primitive sweep, summary and assessment. It serves the user goal by identifying two Medium items for the review-fix loop to fix or route before U3a3 merges. Neither involves a parser or rule bypass.
