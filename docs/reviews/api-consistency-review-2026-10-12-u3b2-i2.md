Commit: cca66dc2

# API Consistency Review: `feat/build-loop-u3b2` (`--main-log SINCE`), iteration 2 (fix range)

**Scope:** PARTIAL: fix range `1d829fee..cca66dc2`. Covers `scripts/build-loop.sh` (header, gate_msg comment, ANSWERS_AWK, log_class, main_log), the `scripts/lib/dev-cycle-read.sh` back-pointer, test 10 in `test/scripts/build-loop-orchestrator.bats`, the plan's U3b2 as-built note, and the override rows dated 2026-10-12 for `feat/build-loop-u3b2`. Commits 1d829fee and 250ea69a serve as context only.
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i2.md` (29 verified, 5 mostly accurate, 2 incorrect: a rubric partition and a vacuous test fixture; neither is behavioural in `scripts/`). That report verified D4 (`main MAIN -` first), D9 (`-` for an empty subject) and the header text (Claims 5, 8, 17, 19, 26), so this review does not re-verify them.

## Baseline Conventions

The baseline is the same as in iteration 1 (`docs/reviews/api-consistency-review-2026-10-12-u3b2-i1.md`, "Baseline Conventions"). This fix range touches two parts of it:

- **`-` for an empty field.** --status prints `-` only in fields whose real value can never be `-`: BRANCH, SHA and DATE (`"ok $a new review - absent - - 0"`, `scripts/build-loop.sh:811`; header `"-" when absent`, `:76`). A branch named `-` is invalid (`git check-ref-format --branch -` gives `fatal: '-' is not a valid branch name`). The one free-text field that comes last on a line, --status' REASON, is *omitted* when empty (`ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]`, `:68`). It never prints as `-`.
- **Lines before a refusal.** In the existing modes, a refusal line stands alone. The `main MAIN -` line is the first case of a fixed data line printed before a `refuse` line in the same run.

## Name-Pattern Audit

The fix range adds no new flag, function or class word. It adds new output *values* to two existing fields. They are audited here as fields.

| New name / value | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main MAIN -` (N = `-`) | output field value | `-` for absent BRANCH/SHA/DATE in --status | `scripts/build-loop.sh:76`, `:811` | Consistent. N is numeric or `-`, and a count can never really be `-`, so the value is unambiguous. |
| SUBJECT `-` | output field value | --status' REASON (free text, last, omitted when empty); `-` in BRANCH/SHA/DATE | `scripts/build-loop.sh:68`, `:811` | Mixed. It matches the `-` placeholder, but unlike every earlier `-` field it can collide with a real value (Finding 1). |
| `refuse main-log:` after `main MAIN -` | output sequence | `refuse state WHAT: WHY` (alone), `refuse BRIEF: WHY` (alone) | `scripts/build-loop.sh:150-190` (--check) | New pattern. Fact-check Claims 5 and 26 show it is documented in the header and the plan, so U4 can rely on it. |

## Findings

#### 1. SUBJECT `-` is ambiguous: a real subject `-`, an empty subject and a message starting with a blank line all print the same, and a blank-only subject still prints an empty-looking field

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1637`, header `scripts/build-loop.sh:148`
**Move:** 8 (nullability), 7 (asymmetry with the `-` precedent)
**Confidence:** High
**Legibility-target:** U4 implementer (parser of class lines, and the D13 `you: judgment` entry that names the commit)

Precedent: `-` as the empty value only where a real value cannot be `-` (BRANCH, SHA, DATE), used in `scripts/build-loop.sh:76`, `:811`. An empty free-text last field (REASON) is omitted (`:68`).

> `mapfile -t -n 5 m < "$GATE_TMP/m"; SUBJ="${m[0]-}"; [[ -n "$SUBJ" ]] || SUBJ=-` (`:1637`)

I ran a probe (`/tmp/u3b2rv-api2-XXXX`, removed) on four commits after SINCE, piping the output through `cat -A`:

```
other 7c8da2076763188285c04c1fe9b9be2e11d2a53f -$      <- message ''
other 53c96211451d4f3a20c4de7d3980977e7e7ab2f9 -$      <- message '-'
other 8090f25b749d268124467405608e0680889721f2    $   <- message '   '
other e3f0f14548dbe11e5baaf2a39cf9c2f213734086 -$      <- message '\nbody only'
```

Three different messages print the same `-`. The blank-only subject still gives the iteration-1 shape: a trailing run of blanks that a `read class sha subj` parser sees as an empty field. For the leading-blank-line message, the script prints `-` where `git log --format=%s` would print `body only`. That is true to the header's wording ("the message's first line"), but a person comparing the two outputs may be surprised. The class and the SHA are unaffected in every case, and row 726 already tells U4 to "parse class and SHA by position, SUBJECT only as data". So none of this changes a decision. It matters only if U4 or a person treats SUBJECT `-` as meaning "no subject".

**Recommendation:** No code change is needed. Add half a sentence to the header at `:148`: SUBJECT `-` means "empty *or* the text `-`", and SUBJECT is display only. The alternative is to follow REASON's precedent and omit an empty subject. That would bring back the trailing-field-absent case, which `-` was added to remove. So keeping `-` with the caveat is the better trade.

#### 2. A failed commit read still prints an empty SUBJECT with a trailing space; the `-` rule is skipped on that path

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1633-1637`, `:1685`
**Move:** 8 (nullability)
**Confidence:** High (static); reachability Low
**Legibility-target:** future maintainer of log_class

> `CLASS=other; SUBJ=""` (`:1633`)
> `gate_git cat-file commit "$c" > "$GATE_TMP/c" || return 0` (`:1634`)
> `LC_ALL=C perl -0777 -ne 's/\A.*?\n\n//s and print' "$GATE_TMP/c" > "$GATE_TMP/m" || return 0` (`:1636`)
> `log_class "$c"; echo "$CLASS $c $SUBJ"; ...` (`:1685`)

On the "any failed read makes C other" path, SUBJ is still `""` when log_class returns, so main_log prints `other SHA ` with a trailing space. That is the exact iteration-1 shape that D9 fixed for the empty-message case. The header promises `"-" when empty` with no exception. The path is hard to reach, because rev-list just listed the commit from the same store. The class is still `other`, which fails closed.

**Recommendation:** Initialise `SUBJ=-` at `:1633` instead of `""`. Then every early return prints `-`, and `:1637`'s fallback stays as it is.

#### 3. The bootstrap SINCE for U4's first iteration is still undocumented; row 726 names a source that does not exist yet

**Severity:** Minor
**Location:** `docs/reviews/override-log.md:726`, `docs/working/plan-build-loop-handoff.md:325`, `scripts/build-loop.sh:172-175`
**Move:** 3 (consumer contract); follow-up to i1 Finding 1
**Confidence:** High
**Legibility-target:** U4 implementer (`skills/dev-cycle/SKILL.md` step 1 / step 9)

The code half of i1 Finding 1 is fixed. The probe's `--main-log 0000000000000000000000000000000000000000` printed:

```
main e3f0f14548dbe11e5baaf2a39cf9c2f213734086 -
refuse main-log: 0000000000000000000000000000000000000000 is not on the default branch's first-parent history at e3f0f14548dbe11e5baaf2a39cf9c2f213734086
rc 2
```

Passing that MAIN back as SINCE then gave `main e3f0f145... 0` with `rc 0`. So a hardened bootstrap exists. No text tells U4 about it, though. The plan note says only `else `main MAIN -` and `refuse main-log: WHY``. Row 726's revisit text says "SINCE never far back (bootstrap from the first record's Main at:)". But no record holds a `Main at:` line today: `grep -c 'Main at' docs/working/cycles/*.md` gives `0` for the only record, `cycle-2026-10-02.md`. The first U4 iteration therefore has no SINCE. Without this text, U4 may read main's commit with bare git, which U3b1's note warns against, or treat the expected bootstrap refusal as a real stop.

**Recommendation:** Add one clause to the plan's U3b2 note and to row 726: "first iteration (no `Main at:` yet): U4 takes MAIN from the `main MAIN -` line of a refused run, then reruns with that MAIN as SINCE (`main MAIN 0`, exit 0); after a real refusal (main rewritten), the `main` line is what the judgment entry records." Alternatively, name a deliberate bootstrap SINCE. The all-zero id works today, but it rests on an implicit property.

#### 4. The edited U4 hand-off row 719 states the tree rule but not the merge settings it assumes

**Severity:** Minor
**Location:** `docs/reviews/override-log.md:719`; header `scripts/build-loop.sh:149-152`
**Move:** 3 (documentation drift against the consumer contract); builds on fact-check Claim 20 (Mostly accurate)
**Confidence:** Medium
**Legibility-target:** U4 implementer (lands chore with `git merge --no-ff` in the main checkout)

Row 719 now says:

> `with no hand-resolved conflict (the merge's tree must be merge-tree's)`

The header says:

> `the clean merge of its parents (merge-tree), as --merge and` / `git merge write it` (`:150-151`)

Fact-check Claim 20 ran two cases where an honest, clean `git merge` read `other`:

- the caller's global `merge.directoryRenames = true`;
- a `merge=union` attribute in the checkout.

The gate repository reads neither. The state gate refuses `merge.*` keys only in repo config, so global config is not covered. This repo's `.gitattributes` (`* text=auto eol=lf`, `docs/working/** linguist-generated`) sets no merge driver today, so the attribute case is latent. Both cases fail closed (`other`, an attention cost). U4 nevertheless writes to this row. "no hand-resolved conflict" is necessary but not sufficient, and "-X" options or a strategy flag on U4's merge would also break the rule.

**Recommendation:** In row 719, change "with no hand-resolved conflict" to "with no hand-resolved conflict and git's default merge (no `-s`/`-X`, no merge.* in global config, no merge attribute)". In the header, change "as git merge write[s] it" to "as git merge writes it with its defaults". This is the precise wording fact-check Claim 20 already gives.

## What Looks Good

- **i1 Finding 1 (code half) is fixed consistently.** `main MAIN -` uses the codebase's `-` placeholder in a numeric field, where it cannot collide with a real count. Both refusal paths print it (`:1678`, `:1681`), and test 10 pins it (`main $T -` then the refuse line). A state-gate refusal still prints no `main` line (probe: `refuse state merge.renames: ...`, rc 2), which matches the iteration-1 exit table. The `main` line belongs to the mode, and the gate refuses before the mode runs.
- **i1 Finding 2 is fixed.** Row 719, the plan note and the header now all carry three items: the subject tail (`then the end, " into " or ":"`), mode 100644 for both the record and the questions files, and short-SINCE-is-usage-exit-1. The three texts agree with one another and with the code (fact-check Claims 17, 21, 26).
- **i1 Finding 4 is fixed.** Row 719 tells U4 to write `Branch: B` "as an unfenced line near the top", and it records that a record updated in place over several iterations gathers several such lines, any of which counts. The header now says "anywhere in it", so the permissive reading is explicit rather than implied.
- **i1 Finding 3 is fixed for the empty case** (with the caveats in Findings 1 and 2). Row 726 adds "parse class and SHA by position, SUBJECT only as data", which is the parsing contract U4 needs.
- **The two-literal coupling is documented both ways.** gate_msg's comment names log_class as its parser (`:1365-1368`). ANSWERS_AWK and the lib's ANSWER_AWK point at each other (`:1602`, `dev-cycle-read.sh:2019-2020`). A maintainer who changes either side is told about the other.
- **No existing contract broke.** land's message bytes are unchanged, and the class words, the flag, the usage text and the exit codes are all the same. The fix only narrows what reads as gate, chore or answers, and anything that falls out now reads as `other`, so it fails closed.

**What U4 must parse (updated from iteration 1):**

| Exit | stdout | Meaning |
|---|---|---|
| 1 | nothing; stderr | Usage (a non-full SINCE), environment, mktemp or no default branch. Stop and quote stderr. |
| 2 | `refuse state ...` lines only | State gate or default_gate. No `main` line. |
| 2 | `main MAIN -`, then `refuse main-log: WHY` | SINCE is off main's first-parent history, or the history could not be listed. MAIN is usable: as the bootstrap SINCE (Finding 3), or in the judgment entry. |
| 2 | `main MAIN N`, then N class lines, at least one `other` | Stop dispatch and file an entry per D13. Name each commit by its SHA. |
| 0 | `main MAIN N`, then N lines of gate, chore or answers | Proceed. Write MAIN as the next `Main at:`. |

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 3 | No documented bootstrap SINCE. Row 726 points at a `Main at:` that no record holds yet | Minor | `docs/reviews/override-log.md:726`, `docs/working/plan-build-loop-handoff.md:325` | High |
| 4 | Row 719 and the header omit that the tree rule assumes git merge's defaults (global merge.*, -X, merge attributes) | Minor | `docs/reviews/override-log.md:719`, `scripts/build-loop.sh:149-152` | Medium |
| 1 | SUBJECT `-` collides with a real `-` subject and a leading-blank-line message; a blank-only subject still looks empty | Informational | `scripts/build-loop.sh:1637`, `:148` | High |
| 2 | A failed commit read prints an empty SUBJECT (trailing space), bypassing the `-` rule | Informational | `scripts/build-loop.sh:1633-1637` | High |

## Overall Assessment

The fix range is consistent with the script's conventions and resolves iteration 1's four API findings in substance:

- `main MAIN -` reuses the `-` placeholder where it is unambiguous.
- The U4 hand-off now carries the subject tail, mode 100644 and the usage-versus-refuse split.
- The `Branch:` line placement is now explicit.

What remains is all handoff text or a placeholder edge case:

- The first-iteration bootstrap is possible but unwritten (Finding 3).
- Row 719 does not name the merge defaults the tree rule assumes (Finding 4).
- The SUBJECT `-` placeholder, unlike the precedent's `-`, can collide with a real value. This is harmless under the "SUBJECT only as data" contract (Finding 1). One read-failure path skips the placeholder (Finding 2).

Every finding fails closed, none breaks a consumer, and all can be fixed in place: three are text, and Finding 2 is a one-token initialiser change.

## Goal-Alignment Note

Success criterion: "An API-consistency review saved to docs/reviews/api-consistency-review-2026-10-12-u3b2-i2.md in the worktree, per the api-consistency-reviewer skill." Met.

- **File.** The review is at that path, and its first line is `Commit: cca66dc2`.
- **Sections.** It has the skill's sections: header with Based on, baseline, name-pattern audit, findings in the template, What Looks Good, summary table and overall assessment.
- **Findings format.** Every finding carries Severity, Location, Move, Confidence and a Legibility-target line. Evidence is quoted verbatim from the cited file:line or from probe output.
- **Precedent rule.** None of the findings is about naming, so the precedent-line rule applies to none. Finding 1 cites its precedent anyway, because it measures the new value against the existing `-` convention.
- **Recorded rows.** Recorded override rows were not re-filed. Findings 3 and 4 extend rows 726 and 719 with facts those rows' own text omits: a record without `Main at:`, and fact-check Claim 20's merge-defaults qualifier. Neither finding disputes the rows' reasoning.
- **Probes.** The probes ran under `/tmp/u3b2rv-api2-` with `set -eu`, their own mktemp, a pwd check, `timeout`, and git config isolated to `/dev/null`. The first attempt aborted on a git empty-message refusal, and I removed its directory. The second removed its own directory. Nothing is left running, and nothing matches `/tmp/u3b2rv-api2-*`.
- **Writes.** I wrote only this file.
