Commit: 4e14d1cc

# Security Review — feat/build-loop-u4a (U4a, review-fix loop iteration 2)

**Scope:** Partial scope: the fix range 722c2e10..4e14d1cc (70d24331, c0cafb66, 4e14d1cc) in `scripts/build-loop.sh` and `test/scripts/build-loop-orchestrator.bats`. The whole of `cycle_diff`, `cycle_rules`, `asked_rule` and `land_cycle` was read, along with `truthrule`, `writable`, `anybrief`, `check_fix` and the skill's step 2/3 text for context. 722c2e10 is context only.
**Date:** 2026-10-13
**Based on:** docs/reviews/code-fact-check-report-2026-10-13-u4a-i2.md, docs/reviews/security-review-2026-10-13-u4a-i1.md, docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4a.md

Threat model (brief): honest-path slips must fail loudly. A hostile same-uid loop with a shell is Q-103's residual class. As in i1, I also count repo text that steers the orchestrator's own edits. Override rows 754-762 are settled and are not re-filed.

## Verdict on iteration 1's findings

| i1 finding | Rubric | Closed? | Basis |
|---|---|---|---|
| F1: added Asked: IDs not checked | A1 | **Partly.** Closed for an ID that names an old entry or no entry (fact-check P1, P2, P12; test case). Still open in three forms: an item that only *starts* with a new ID (fact-check 4b; confirmed and extended below, F-b); one new entry attached to several briefs (F-a, new); and a brief whose base name exists under both `briefs/` and `closed/` (F-c, i1's untested candidate, now confirmed). | executed |
| F2: truth files land unjudged | A2 | **Yes for the named classes** (instr, dot, settings, user, record), on both modes through the shared `cycle_rules`. Two residues remain: @-imported docs (the commit body states this, and `check_fix`'s walk covers it before staging), and a cycle file spelled in another case (F-d), because lowering the path removes truthrule's `case` word. | executed (fact-check P4/P4b), read-static for --land-cycle |
| F3: deleted or renamed brief | A4 | **Yes**, for deletion and for a rename to another base name (fact-check P3, P9). The same-base-name collision is F-c. | executed |
| A3: `--expect` vs `--main` | A3 | **Yes.** `--land-cycle` accepts only `--main`; `--expect` is now a usage error (fact-check E4 L3). The CAS check is unchanged in substance (`:2009`). | executed |
| Questions guard moved into cycle_diff | A5 | **Nothing lost for security.** The trigger is the same exact-path test. Under `--land-cycle` it was always vacuous (BASE = MAIN_SHA). The only change is that its early return hides other refusal lines until the next run (fact-check claim 11). That costs a run; it does not let anything through. | executed (fact-check P7) |

## Trust Boundary Map

```
B1: chore branch HEAD commit / index (orchestrator worktree) → cycle_diff / land_cycle → cycle_rules(BASE, SIDE)        → "ok" or refs/heads/main via land()
B2 (moved): changed paths (RAW_P), lower-cased             → GATE_CODE, truthrule(lp) != cycle → refuse; else brief / questions / roadmap / idea-log rules → paths judged or passed unjudged
B3 (changed): brief Asked: lines (keyed by base name)       → asked() → asked_rule(NEW)                                → step 2's --check-answer by ID alone → brief kept, dropped or done
B4 (new): questions headings (QKEYS h lines, both files)    → NEW = listing's headings BASE lacks                     → asked_rule's allow-list for added Asked: items
B5: CLI --main SHA / --answered IDs                         → parser regexes                                          → CAS base (LAND_MAIN == MAIN_SHA), QDIFF allow-list
```

Input-source classification:

```
S1: HEAD's commit / the staged index and the trees they reach — runtime-mutable (orchestrator; any same-uid writer) — UNTRUSTED toward the main-ref write sink
S2: brief Asked: lines in S1                                  — runtime-mutable (orchestrator writes; loop text can steer it) — UNTRUSTED toward the answer-application sink
S3: questions files' headings in S1                           — runtime-mutable — UNTRUSTED as an authority over which brief an entry belongs to (the slug is free text the rule does not read)
S4: path spellings in S1 (case)                               — runtime-mutable — UNTRUSTED toward readers on a case-insensitive checkout
S5: --main SHA, --answered IDs                                — request-time (orchestrator's own claim) — trusted toward the CAS base (a wrong value only refuses); --answered as settled in row 748
```

The fix range turns the Asked: rule into an allow-list: an added item must name a heading in NEW (B4). The allow-list is a *set of IDs*. It is not bound to a brief, and it is not used up when an item takes an ID. Each finding below follows from that, or from the keying by base name (B3), or from the lowering in B2.

## Findings

#### F-a. One new questions entry can be added to the Asked: line of several briefs, so one answer closes or keeps all of them

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1968` (NEW), `:1980-2000` (asked_rule; read whole), `:1995`
**Boundary:** B3, B4
**Move:** 11 (guardrail bypasses), 5 (invert the model)
**Confidence:** High (executed)
**Legibility-target:** for-author
**Regression:** none from main or from 722c2e10 (both pass it; on 722c2e10 any added ID passed). This is a residue of A1.

**Evidence:**
```bash
# scripts/build-loop.sh:1995-1996 (excerpt; asked_rule runs :1980-2000, read)
      [[ "$x" =~ ^(Q-[0123456789]+)(@|$) ]] && grep -qxF -- "${BASH_REMATCH[1]}" "$1" \
        || { echo "refuse ${ap[$f]}: its Asked: line adds $x, which names no question entry this change files"; bad=1; }
```
The probe (benign fixture, `/tmp/u4a-sec2-*`, since removed) filed one entry, `### Q-002 · keep-or-drop-2026-10-01-x-1`. It appended `, Q-002` to brief x's Asked: line and added `Asked: Q-002` to brief y. `--cycle-diff` printed `ok` with exit 0, on both 4e14d1cc and 722c2e10.

**Weakness.** `asked_rule`'s comment states the hazard it closes: "an ID ... reused from another entry would apply that question's answer to this brief, since --check-answer matches the ID alone." The rule checks that an ID is in NEW, but NEW is shared across the change. One new entry can therefore be named by any number of briefs. The entry's slug (`keep-or-drop-<brief>-<n>`) names one brief, and nothing reads it.

**Preconditions.** An orchestrator slip in step 3: it files one entry and writes the ID into two briefs (copy-paste, or a loop over briefs that reuses a variable). Repo text that steers the orchestrator would do the same. No shell is needed.

**Impact.** The user answers "drop" or "done" about brief x. Step 2 then applies that answer to brief y too, which closes y without the user ever being asked about it. A "keep" answer resets y's idle clock instead, so y holds its slot. This is the row 745 / i1 F1 integrity failure in a new shape, and no later check surfaces it.

**Fix.** Bind each added ID to its brief. Either (1) require the entry's heading slug to be `keep-or-drop-<the brief's file name without .md>-<n>`, which matches the skill's own slug rule and also defeats F-b's trailing text once the item is anchored, or (2) at minimum, let each NEW ID be added to only one brief per change. (1) is stronger, because it also holds across cycles.

#### F-b. An added item is checked only at its start, so a second ID can ride after `@` (fact-check claim 4b, confirmed and extended)

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1995`, header `:225-226`
**Boundary:** B3
**Move:** 11
**Confidence:** Medium. The mechanism was executed. Whether the orchestrator, reading the line by the skill's ", " rule, would apply the second ID is a reading of an LLM's parse.
**Legibility-target:** for-author
**Regression:** none from main or from 722c2e10 (both pass it).

**Evidence:** the same line as F-a. `(@|$)` accepts anything after `@`. Fact-check E3 P5 (`, Q-002@def,Q-003`) and P5b (`, Q-002@ Q-003`) passed. My probe Q4 (`, Q-002@Q-003`, with Q-002 filed new and Q-003 answered on BASE) printed `ok`, so no separator at all is needed.

**Weakness, preconditions and impact.** These are as in fact-check 4b. The skill's step 2 reads IDs "separated by ', '" (`skills/dev-cycle/SKILL.md:296-297`), but the reader is the orchestrator, and a string that holds two Q-numbers is ambiguous to it. If it reads Q-003, an old answer is applied to the brief, which is the A1 class. The extension is that the `@` form needs no comma and no space. The defect is therefore not about separators, and a fix that only splits on `,` or whitespace would miss it.

**Fix.** Anchor the item to the forms D4 defines, for example `^(Q-[0-9]+)(@[0-9a-f]{7,64})?$` (or exactly 40/64 hex digits if D4 writes full SHAs). Add a test case whose suffix holds a second `Q-` ID.

#### F-c. Two changed briefs with the same base name (one in `briefs/`, one in `closed/`) leave one of them unjudged

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1917-1918` (keying by `${p##*/}`), `:1980-2000`
**Boundary:** B3
**Move:** 11
**Confidence:** Low. The mechanism was executed. The precondition, the same file name in both directories, is a state the skill does not create ("a brief already under `closed/` stays").
**Legibility-target:** for-author
**Regression:** none from main or from 722c2e10. This was i1's "untested bypass candidate", now confirmed.

**Evidence:**
```bash
# scripts/build-loop.sh:1917-1918 (excerpt; cycle_rules runs :1903-1971, read)
      [[ "${RAW_OM[i]}" == 000000 ]] || { ao[${p##*/}]="$(asked "$t.o")"; aop[${p##*/}]="$p"; }
      [[ "${RAW_NM[i]}" == 000000 ]] || { an[${p##*/}]="$(asked "$t.n")"; ap[${p##*/}]="$p"; }
```
Probe Q2: BASE held `briefs/2026-10-01-x.md` and `briefs/closed/2026-10-01-x.md`, both with `Asked: Q-001`. The change rewrote the open brief's line to `Asked: Q-003` (an answered entry) and appended a note to the closed copy. `--cycle-diff` printed `ok`. The closed path sorts after the open one, so its values overwrite the open brief's in `ao` and `an`.

**Weakness and impact.** The rule's map assumes one brief per base name per change. When that does not hold, the last path wins and the open brief's Asked: line goes unchecked: F1's answer reuse, and also F3's drop, since the open brief could be deleted with its pair present. The floor rule sets the severity, because the mechanism is concrete. The unusual precondition is reflected in the confidence.

**Fix.** Key by base name only to pair a D with an A across `briefs/` and `closed/`. Refuse a change in which a base name occurs on more than one old-side path or more than one new-side path.

#### F-d. A cycle file spelled in another case passes both the new truth rule and the cycle file rules unjudged

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1907`, `:1913` (truthrule over `lp`), `:1914-1923` (`anybrief "$p"` and `case "$p"` on the original spelling)
**Boundary:** B2, S4
**Move:** 2 (assumed sanitisation), 5
**Confidence:** Low. The mechanism was executed. Its impact needs a case-insensitive checkout (the macOS default, or WSL on `/mnt/c`), where a working-tree reader opens `docs/working/briefs/` and gets the variant.
**Legibility-target:** for-orchestrator-synthesis
**Regression:** none from main or from 722c2e10, which judged no such path either. It is new *surface* in this range: the A2 fix lowers the path, and that drops truthrule's `case` word, which `--merge`'s floor refuses for exactly this reason.

**Evidence:**
```bash
# scripts/build-loop.sh:1907,1913 (excerpt; cycle_rules continues to :1971, read)
    p="${RAW_P[i]}"; lp="$(lower "$p")"
    if truthrule "$lp" && [[ "$TRUTH_WHY" != cycle ]]; then echo "refuse $p: ..."; bad=1; continue; fi
```
`truthrule` returns `case` for any upper-case letter (`scripts/lib/dev-cycle-read.sh:1914`). On `lp` that word cannot fire. `docs/working/Briefs/2026-10-01-z.md` lowers to a brief, so it is `cycle` and passes. `anybrief "$p"` then tests the original spelling, fails, and the `case` falls to `*) continue`. Probe Q3, a new `docs/working/Briefs/2026-10-01-z.md` with `Asked: Q-003` (an answered entry), printed `ok`. Probe Q5, a new `docs/working/Questions.md` holding an entry filed ANSWERED with no `--answered`, printed `ok`.

**Weakness and impact.** On a case-sensitive checkout these paths are inert. `--check-answer` reads the questions files by exact path from main's commit, so Q5 has no effect there. On a case-insensitive checkout the variant brief is the brief a working-tree reader opens, and its Asked: line was never judged, which reopens A1. For a mixed-case questions file, the checkout overwrites one copy with the other. The precondition is an orchestrator slip in spelling, or steered text. `--check-write` is the honest writer, and I did not read whether it refuses a mixed-case spelling (see "Untested bypass candidates").

**Fix.** Refuse a changed path whose spelling differs from its lowered form when the lowered form is any truthrule class, `cycle` included. The refusal can reuse the floor's `case` wording.

#### F-e. Informational: @-imported docs still land unjudged (the commit states this residue)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1913` (no `truthwalk`)
**Boundary:** B2
**Move:** 1
**Confidence:** High (fact-check claim 23)
**Legibility-target:** for-orchestrator-synthesis
**Regression:** no.

70d24331's body states that a doc an instruction file imports is refused by `check_fix`'s walk before it is staged, not by `cycle_rules`. I agree that this is a coherent split, provided U4b's step text runs `--check-fix` on every in-cycle fix. I recorded it so that U4b's text is checked for that. I am not filing it as a defect.

## Untested bypass candidates

- **`--check-write` and a mixed-case path** (F-d). I did not read whether the cycle's honest writer refuses a non-canonical spelling. If it does, F-d needs a steered or off-path write. If it does not, an honest slip is enough.
- **`Applied:` pre-filled with a new ID.** The rule judges only `Asked:`. Writing an ID to `Applied:` in the same change would stop its answer from ever being read. This is outside the fix range (the line is 722c2e10's context, and no rule judges it on main), and I did not probe it.
- **F-a and F-b under `--land-cycle`.** Not run there. By reading, the mode shares `cycle_rules` with NEW computed main-to-merge, so the same results are expected.

## Endorsement Claims

- **Claim:** `cycle_rules` refuses a changed path whose lowered form truthrule classes as instr, dot, settings, user or record, on both `--cycle-diff` and `--land-cycle`.
  **Location:** `scripts/build-loop.sh:1907-1913`, `:1891`, `:2030`
  **Evidence:** executed (fact-check E3 P4/P4b under --cycle-diff; the U4a test)
  **Verified:** the refusal line and the classes it fires on, under `--cycle-diff`
  **Not verified:** the same paths under `--land-cycle`'s merge listing (not executed; the call site is shared)
  **route: code-fact-check**
- **Claim:** a brief deleted, or renamed to another base name, with a non-empty Asked: line refuses.
  **Location:** `scripts/build-loop.sh:1982-1984`
  **Evidence:** executed (fact-check P3, P9; test case `git rm`)
  **Verified:** deletion and a rename within `briefs/`
  **Not verified:** a base name present on both `briefs/` and `closed/` (F-c refutes the general form)
  **route: code-fact-check**
- **Claim:** `--land-cycle` takes the CAS base only from `--main`, a full hex id given once, and refuses when it differs from MAIN_SHA.
  **Location:** `scripts/build-loop.sh:537-543`, `:2009`
  **Evidence:** executed (fact-check E4 L3; suite test 26)
  **Verified:** the parser branch and the refusal text after main moved
  **Not verified:** a 64-hex `--main` in a SHA-1 repository (it parses, then refuses at the CAS check)
  **route: code-fact-check**

The Asked: item rule (A1) is left out of this list on purpose: F-a, F-b and F-c are bypasses of it.

## Primitive sweep

Primitive: git ref write (main moved)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `land()` `update-ref --no-deref` (via `land_cycle` `:2035`) | S1 (R, h), S5 (LAND_MAIN) | CAS from MAIN_SHA; cycle_rules; store_check | cleared for CAS (unchanged in range apart from the `--main` rename). The content caveats are F-a to F-d |
| `land()` `merge --ff-only` in W | S1 | as i1 | cleared (unchanged in range) |

Primitive: commit object write

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `land()` `commit-tree` with `chore_msg` (`:1545`, `:1728`) | branch name from the `chore/dev-cycle-DATE[-HHMM]` regex | regex limits the message | cleared. `printf '%s'` of a regex-matched name |

Primitive: repo blob text into awk / grep

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `asked()` over `cyc_blob` output (`:1897`) | S2 | 100644 only; FENCE_AWK | parser cleared (row 760). F-a, F-b and F-c are gaps in the rule, not in the parser |
| NEW awk over QKEYS output (`:1968`) | S3 | QKEYS / FENCE_AWK whole-file refusal first | cleared as a reader. F-a concerns its use as an unbound set |
| `grep -qxF -- ID NEW` (`:1995`) | S2 (ID from `BASH_REMATCH`, digits only) | `-F -x --` | cleared. A fixed string cannot inject a pattern |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence | Regression from main / from 722c2e10 |
|---|---------|----------|----------|----------|------------|---|
| F-a | One new entry added to several briefs' Asked: lines; one answer applies to all | Medium | B3, B4 | `scripts/build-loop.sh:1968, 1995` | High | No / No (A1 residue) |
| F-b | Item checked only at its start: `Q-002@Q-003` passes (fact-check 4b, extended) | Medium | B3 | `scripts/build-loop.sh:1995` | Medium | No / No (A1 residue) |
| F-c | Same base name in `briefs/` and `closed/`: one brief's Asked: change unjudged | Medium | B3 | `scripts/build-loop.sh:1917-1918` | Low | No / No (i1 untested candidate) |
| F-d | Mixed-case spelling of a cycle file passes the truth rule and the cycle rules | Medium | B2 | `scripts/build-loop.sh:1907, 1913-1923` | Low | No / No (new surface from the A2 lowering) |
| F-e | @-imported docs unjudged by cycle_rules (stated residue; check_fix covers it) | Informational | B2 | `scripts/build-loop.sh:1913` | High | No / No |

## Overall Assessment

The fix range closes A2 (for the named classes), A3 and A4 as filed, and moving the questions guard loses no security property. It does not regress anything from main or from 722c2e10. Every finding above also passes on 722c2e10's code, where any added ID passed. A1 is only partly closed. The new allow-list stops an added ID that names an old entry or no entry, but it binds neither the ID to a brief (F-a), nor the item to its full form (F-b), nor the rule to one brief per base name (F-c). The single most important change is to bind an added Asked: ID to its brief through the entry's `keep-or-drop-<brief>-<n>` slug, together with anchoring the item (F-b's fix). Those two edits inside `asked_rule` close F-a and F-b, and they make the rule's stated purpose ("reused from another entry") hold. F-c and F-d are small additions to the same loop. No findings beyond these within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

- **User goal:** land unit U4a of the build-loop handoff (claude-workflows) once its review-fix loop is clean.
- **Current task:** security review of the fix range 722c2e10..4e14d1cc of `feat/build-loop-u4a`.
- **Success criterion:** a markdown report saved at the exact path your own prompt names, structured per your skill.
- **Alignment:** saved at `docs/reviews/security-review-2026-10-13-u4a-i2.md`, with `Commit: 4e14d1cc` as the first line and a partial-scope label. It gives a verdict per i1 finding (A1-A5), a trust boundary map and source table, findings with Severity, Location, Evidence, Confidence, Legibility-target and regression status, untested candidates, routed endorsements and a primitive sweep. Probes ran only under `/tmp/u4a-sec2-*`, which has since been removed, on `git archive` copies of 4e14d1cc and 722c2e10. No other file was written.
