Commit: 4e14d1cc

# Architecture Review: feat/build-loop-u4a, iteration 2 (fix range 722c2e10..4e14d1cc)

**Scope:** Partial scope: the fix range 722c2e10..4e14d1cc (70d24331, c0cafb66, 4e14d1cc). Code under review: `scripts/build-loop.sh` (header, parser, `land`, `chore_msg`, `cycle_diff`, `cycle_rules`, `asked_rule`, `land_cycle`) and `test/scripts/build-loop-orchestrator.bats`. 722c2e10 is context only.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4a-i2.md` (21 verified, 4 mostly accurate, 1 incorrect). Trust Boundary Map from `docs/reviews/security-review-2026-10-13-u4a-i1.md` (Commit: `722c2e10`, the base of this range).

Scope check: in scope. The range changes a public CLI flag (`--expect` becomes `--main` for `--land-cycle`) and a shared unit's signature (`cycle_rules BASE` becomes `cycle_rules BASE SIDE`). It adds a helper, `asked_rule`, that shares state with its caller. It moves a precondition from the shared unit into one caller, and it adds a new consumer of the lib's `truthrule`.

Complete-unit reading: I read every function cited here in full: `land` (1476-1562), `gate_msg`, `chore_msg`, `chore_record`, `log_class` (1751-1782), `cycle_diff` (1869-1892), `cycle_rules` (1903-1972), `asked_rule` (1980-2000), `land_cycle` (2004-2037), `nrules` (1132-1159), and, in the lib, `truthrule`, `truthwalk` and `floor` (1899-2004). I also read `check_fix`'s truthrule lines (`scripts/dev-cycle.sh:183-196`). Probe: one bash script ran in `/tmp/u4a-arch2-XXXX` under `timeout 10` and was then removed. It touched no repository (finding 1).

## Dependency Map

- **`cycle_diff`** lists the index against the merge base and fills `RAW_*`. It now holds the questions guard itself, which runs only when `RAW_P` names a questions file and returns before the rules. It then calls `cycle_rules "$base" index`.
- **`land_cycle`** checks the branch regex, `LAND_MAIN == MAIN_SHA`, the clean index, `merge_result`, `store_check`, and the diff-tree of R against main, which fills `RAW_*`. It then calls `cycle_rules "$MAIN_SHA" merge`, `chore_record`, fills all six `VERDICT` keys and `CHANGED`, and calls `land cycle`.
- **`cycle_rules BASE SIDE`** reads `RAW_*` and calls `lower`, `GATE_CODE`, **`truthrule` (new: the lib)**, `anybrief`, `asked`, `cyc_blob`, `ROADMAP_AWK`, `ANSWER_AWK`, `QKEYS_AWK` and `QDIFF_AWK`. It ends in **`asked_rule` (new)**, which it calls from two exit points. `SIDE` is read once, as the copy label in the whole-file refusal.
- **`asked_rule NEW`** takes one positional argument (the new-entry ID file). It reads four associative arrays local to `cycle_rules` (`ao`, `an`, `ap`, `aop`) through bash's dynamic scope.
- **`land`** calls `chore_msg` for the `cycle` authority and `gate_msg` otherwise. **`log_class`** recognises the chore message by its own regex. It does not call `chore_msg`.
- **The lib's `truthrule`** now has four consumers: `check_fix` (dev-cycle.sh), `floor` (lib), `nrules` (build-loop.sh), and now `cycle_rules` (build-loop.sh). Dependencies still run from the scripts down to the lib, and no cycle is introduced.

## Findings

#### 1. `asked_rule` reads `cycle_rules`' locals by dynamic scope, and anywhere else it passes everything

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1980-2000` (asked_rule); `:1905`, `:1939`, `:1970` (cycle_rules)
**Move:** 7 (coupling surface: content coupling)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**

```bash
# A brief deleted, or renamed to another file name, with an Asked: line
# refuses too (i1 security F3). Reads cycle_rules' ao, an, ap and aop (bash
# scope is dynamic); called only there. Returns 1 on any refusal.
asked_rule() {
  local f o n a x bad=0
  for f in "${!ao[@]}"; do
```
(excerpt; asked_rule continues to :2000, read)

`asked_rule` takes the rule's real inputs as hidden state: four associative arrays that `cycle_rules` declares with `local -A`. The comment states this coupling and says it is called only from `cycle_rules`, which matches the code (fact-check claim 16). What the comment does not say is the failure mode. I probed it under `set -euo pipefail` (bash 5.2.15). Inside a function that declares `local -A ao=([a]=1) an=()`, `for x in "${!ao[@]}"` iterates as intended. Called from a scope where `ao` is not declared, `"${!ao[@]}"` expands to nothing under `set -u`. No error is raised, and the function would return 0.

So a second caller, for example a future mode that reuses the Asked: rule (U4b's skill may want a pre-check), would get a rule that silently passes every brief rather than one that fails loudly. That is the reverse of the brief's threat model ("honest-path slips must fail loudly"). The rule sits on `B2` from `docs/reviews/security-review-2026-10-13-u4a-i1.md` (Commit: `722c2e10`), the "judged" verdict that authorises the land's write.

**Recommendation:** Pass the arrays explicitly with namerefs (`asked_rule NEW AO AN AP AOP`, then `local -n`), so a wrong call fails on an unbound name. Alternatively, fold the rule back into `cycle_rules` as one tail section. Either way the boundary stays where it is: this changes how B2's inputs reach the rule, not where B2 sits.

#### 2. `truthrule` gains a fourth consumer whose allow-list is "the cycle word only", but the lib's contract names three consumers

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1908-1913` (cycle_rules); `scripts/lib/dev-cycle-read.sh:1899-1910` (truthrule header)
**Move:** 3 (module boundary) / 7 (coupling)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**

```bash
# scripts/build-loop.sh cycle_rules (excerpt; cycle_rules continues to :1972, read)
    if truthrule "$lp" && [[ "$TRUTH_WHY" != cycle ]]; then echo "refuse $p: a file sessions or later cycles read as truth ($TRUTH_WHY); an in-cycle fix edits only docs --check-fix allows"; bad=1; continue; fi
```

```bash
# scripts/lib/dev-cycle-read.sh truthrule header (excerpt)
# The read-as-truth rule --check-fix and floor share (plan D5 items 1, 2 and 4;
# build-loop.sh's N rules read its cycle, settings and user words too, so a
# word tested before them must never match a file those words cover:
# override rows 204, 322, 348), ...
# Each caller words the words and adds its own rules
```

`cycle_rules` now depends on two properties of `truthrule`'s word order:

- every file the cycle writes classifies as `cycle`;
- `instr` and `dot`, which are tested before `cycle`, never match a `writable()` path.

The second is the same invariant the header states for the N rules, and `nrules` notes "truthrule names this third consumer". The lib header does not name `cycle_rules`, so someone editing `truthrule` sees three consumers, not four.

Drift fails closed in both directions:

- a new truth word refuses in `--cycle-diff` and `--land-cycle` too, which is the intent;
- a word that shadows a cycle file blocks every land.

Neither failure is silent. The cost is diagnosis: the stop surfaces as a cycle that cannot land, far from the lib edit.

The refusal text and the comment also claim parity with `--check-fix` ("an in-cycle fix edits only docs --check-fix allows"). `cycle_rules` enforces a subset of it: no `truthwalk` and no `^docs/.*\.md$` restriction. The commit body of 70d24331 states this (fact-check claim 23), but the code does not. "What an in-cycle fix may edit" now has two encodings, `check_fix`'s and `cycle_rules`', and the subset relation is recorded only in git history.

**Recommendation:** Add `cycle_rules` (build-loop.sh's `--cycle-diff` and `--land-cycle`) to the truthrule header's consumer list, under the same word-order invariant as the N rules. In `cycle_rules`' comment, say it is a subset of `--check-fix` (no import walk, any path type), and say the skill runs `--check-fix` first. Optional: a test that every `writable()` form passes `cycle_rules`, the analogue of T14 for the N rules.

#### 3. `cycle_rules` reaches `asked_rule` from two exit paths, around the questions block

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1938-1939`, `:1967-1971`
**Move:** 8 (extension points) / 2 (responsibility)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**

```bash
# cycle_rules (excerpt; cycle_rules continues to :1972, read)
  : > "$t.new"
  if [[ ${#qi[@]} -eq 0 ]]; then asked_rule "$t.new" || bad=1; return "$bad"; fi
  ...
  asked_rule "$t.new" || bad=1
  return "$bad"
```

The function now has three parts in sequence: per-path rules, the questions-entry comparison, and the Asked: rule. Two of the three are rules over the whole listing. The questions block sits in the middle and is written as an early-return region: it returns early when no questions file changed, and it uses `return 1` on its own whole-file or read refusals. To keep the Asked: rule running when no questions file changed, it had to be called twice.

The next rule appended to `cycle_rules`, of which U4b's text may bring more, must be added on both paths. If it is added only at the tail, it silently skips every cycle that leaves the questions files alone, which is the common case. The questions block's `return 1` paths also skip `asked_rule`. Those paths already refuse, so nothing lands, but the remaining refusals show only on a rerun. This is the same co-refusal loss that fact-check claim 11 records for the guard moved into `cycle_diff`.

This is the B2 rule set (security i1, Commit: `722c2e10`). The restructure keeps B2 in place.

**Recommendation:** Extract the questions block as `questions_rules BASE SIDE OUT` (writes NEW to OUT, returns non-zero on any refusal). `cycle_rules` then reads as a flat list: `per-path || bad=1; questions_rules ... || bad=1; asked_rule ... || bad=1; return $bad`, with one call site per rule.

#### 4. `chore_msg` exists, but its link to `log_class` is one-way, and `land` still switches on authority twice

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1726-1728` (chore_msg), `:1768` (log_class), `:1478-1480` and `:1545` (land)
**Move:** 7 (coupling) / 8 (extension points)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**

```bash
# chore_msg B: the message of a chore merge, as git merge writes it and
# --land-cycle writes it (land); log_class reads it back by its subject regex.
chore_msg() { printf "Merge branch '%s'\n" "$1"; }
```

```bash
# land (excerpt; land continues to :1562, read)
  [[ "$1" != cycle ]] || what="cycle land"
...
  { if [[ "$1" == cycle ]]; then chore_msg "${VERDICT[branch]}"; else gate_msg "${VERDICT[branch]}" "$what" "${VERDICT[stem]}" "${2-}"; fi; } > "$GATE_TMP/msg" \
```

Iteration 1's finding 3 (rubric A10) is resolved in substance. The writer is now one named function, and its comment names the reader.

Two smaller points remain:

- **`chore_msg` and `log_class` (two-way pointer).** `chore_msg` sits beside `chore_record`, not beside `gate_msg`, which is defensible because the chore class is defined by the record, not by the message bytes. But `log_class`' comment and regex do not name `chore_msg`. Unlike `gate_msg`, which `log_class` regenerates and compares with `cmp`, the chore regex is deliberately wider (`into`, `:`) to accept git's own hand-merge messages. So nothing pins the two together except test 26 end to end. Drift fails closed: a land would read as `other`.
- **Two authority switches in `land`.** The second half of iteration 1's finding 3 was not taken and has no override row: `land` still branches on `cycle` in two places. This is a pragmatic choice at three authorities.

**Recommendation:** Add "chore_msg writes what this matches" to `log_class`' chore branch comment. Optionally, record the declined "caller writes the message" half in the override log, so the next authority added to `land` has a pointer.

#### 5. The moved questions guard returns before `cycle_rules`, so `--cycle-diff` now reports in two rounds

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1884-1891`
**Move:** 2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence (verbatim):**

```bash
# cycle_diff (excerpt; cycle_diff continues to :1892, read)
  for p in "${RAW_P[@]}"; do
    [[ "$p" == docs/working/questions.md || "$p" == docs/working/questions-archive.md ]] || continue
    ...
    cmp -s "$t.lb" "$t.lm" || { echo "refuse docs/working/questions.md: the default branch changed the questions files since the fork point $base; merge it into HEAD, then stage again"; return 1; }
    break
  done
  cycle_rules "$base" index
```

Iteration 1's finding 6 is resolved as recommended. `cycle_rules` now judges a listing and nothing else, and the guard sits with the one caller whose listing (index against fork point) it concerns. `--land-cycle` loses nothing, because its old compare was `MAIN_SHA` against itself (fact-check claim 11).

The cost is a placement side-effect: the guard now runs first and returns, so co-occurring refusals that 722c2e10 printed alongside it now appear only after the user merges main and reruns. The guard's own remedy forces a rerun anyway, so the effect is small.

**Recommendation:** None required. If U4b's skill text promises "all refusals in one run", either run the guard after `cycle_rules` and OR the results, or have the skill state the two-round behaviour.

## Iteration 1 findings: resolution check

| i1 # | Finding | Status in 4e14d1cc |
|---|---|---|
| 1 | land_cycle repeats check_line's compute half; missing-blob check unsaid | **Resolved (comment option).** `:2022-2023` states store_check's coverage, which fact-check claim 17 verified. The duplication itself remains, as the recommendation allowed. |
| 2 | Shared refusals say "index"/"stage again" under --land-cycle | **Resolved.** `SIDE` labels the copy (`:1955`, claim 8 executed "its merge copy"). `refuse index:` and "stage again" now live only in `cycle_diff`. |
| 3 | Chore message has two literals; land switches twice | **Mostly resolved.** `chore_msg` is the one writer. The reader link is one-way, and the second switch remains (finding 4). |
| 4 | VERDICT key sets differ; RAW_* reuse unstated | **Resolved.** All six keys are set (`:2033`, claim 19). The RAW_* invariant is stated at the call site (`:2029`, claim 18). `[policy]=-` is outside check_line's vocabulary (review, self-merge), but `land` never reads it, and the dispatch's policy check runs only under `--merge`. |
| 6 | Questions guard inside shared cycle_rules | **Resolved** as recommended (finding 5 notes the side-effect). |

## What Looks Good

- **`cycle_rules BASE SIDE`.** The shared unit's output vocabulary is now a parameter, like its inputs. That is the clean fix for i1 finding 2. `SIDE` has one use, so it does not become a control flag.
- **Reusing `truthrule` rather than copying its class list.** The truth classes stay in one place in the lib, and a new class propagates to the cycle gate automatically, failing closed. Finding 2 asks only that the lib's contract record the new consumer.
- **`--main` instead of `--expect`.** The flag name now says what the value is (main's commit, the CAS base), and `--merge`'s `--expect` keeps its own meaning (a branch tip). The header states the contrast at the point of confusion.
- **Fail-loud on the honest path.** Deleting or renaming a brief that has an Asked: line refuses, and so does an added item that names no new entry. Both are expressed over the same `ao`/`an` maps as the existing line-shape rule, not as a third pass over the listing.
- **Test rewrite.** The U4a test now pins each new class (F1 none/another's, F3 delete, F2 truth words including the lower-cased `(instr)`), and it fails on 722c2e10 (fact-check claim 20).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | asked_rule reads cycle_rules' locals by dynamic scope; outside it the rule passes everything (probed) | Minor | `scripts/build-loop.sh:1980-2000` | High |
| 2 | truthrule's fourth consumer (cycle_rules) is not named in the lib's consumer/word-order contract; --check-fix parity is a subset, stated only in a commit body | Minor | `scripts/build-loop.sh:1908-1913`, `scripts/lib/dev-cycle-read.sh:1899-1910` | High |
| 3 | cycle_rules calls asked_rule from two exit paths around the questions block; next rule must be added twice | Minor | `scripts/build-loop.sh:1938-1939, 1967-1971` | High |
| 4 | chore_msg to log_class link is one-way; land still switches on authority twice (undeclined) | Informational | `scripts/build-loop.sh:1726-1728, 1768, 1478, 1545` | High |
| 5 | Moved questions guard returns before cycle_rules: two-round refusals | Informational | `scripts/build-loop.sh:1884-1891` | High |

## Overall Assessment

The fix range improves the structure it set out to fix. Iteration 1's findings 1, 2, 4 and 6 are resolved, and finding 3 is resolved in substance. The shared rule set now takes its output vocabulary as a parameter, and the caller-specific guard has moved to its caller. Nothing is Structural or Coupling-grade, and every remaining item can be fixed in place without moving the B2 trust boundary.

The most important concern is finding 1. The new Asked: rule depends on hidden caller state and would fail open if it were ever called from anywhere else. Findings 2 and 3 are the same theme at a larger scale: `cycle_rules` is becoming the cycle gate's rule registry, and its dependencies (truthrule's word order) and its shape (rules split around an early-return block) are not yet written down where the next editor will look. None of these blocks landing U4a.

The fact-check's one Incorrect (claim 4b: an Asked: item is anchored only at its start) is a behavioural gap for the security critic. Structurally, it sits inside `asked_rule`'s parsing and does not change the findings above.

## Goal-Alignment Note

- **User goal:** land unit U4a of the build-loop handoff (claude-workflows) once its review-fix loop is clean.
- **Current task:** architecture review of the fix range 722c2e10..4e14d1cc of `feat/build-loop-u4a` (partial scope).
- **Success criterion (verbatim):** "a markdown report saved at the exact path your own prompt names, structured per your skill."
- **Alignment:**
  - **Saved where named:** `docs/reviews/architecture-review-2026-10-13-u4a-i2.md`, first line `Commit: 4e14d1cc`. It follows the architecture-review skill's sections, and every finding carries Severity, Location, verbatim Evidence, Confidence and Legibility-target.
  - **Focus items:**
    - `asked_rule`'s dynamic scope: finding 1.
    - The moved guard: finding 5 and the i1 #6 row.
    - The SIDE parameter: the i1 #2 row and What Looks Good.
    - `chore_msg` against `gate_msg` and `log_class`' regex: finding 4.
    - The truthrule coupling and whether it is stated: finding 2.
    - The full `VERDICT`: the i1 #4 row.
    - Iteration 1's findings 1-4 and 6: the resolution table.
  - **Blocking:** no finding blocks landing.
