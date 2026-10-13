Commit: 8389c477

# Security Review — feat/build-loop-u4a (U4a, second confirming pass)

**Scope:** partial. Only the fix range ca95fead..8389c477 is under review: daa09b5f (`scripts/build-loop.sh` cycle_rules, which gets the lower-cased allowlist and the WORDS-STEM-N slug rule, plus header and comment text; `test/scripts/build-loop-orchestrator.bats`, the U4a cycle-diff test) and 8389c477 (docs only: review reports, rubric, override rows). The rest of the branch was read for context only: all of `cycle_rules`, `questions_rules`'s head, and the lib's `lower`, `truthrule`, `writable`, `isbrief`, `anybrief`, `SLUG`, `GATE_CODE`, `INSTRUCTION_FILE` and `isstart`, together with `scripts/dev-cycle.sh` check_fix's path rule and `skills/dev-cycle/SKILL.md:316`.
**Date:** 2026-10-13
**Based on:** docs/reviews/security-review-2026-10-13-u4a-confirm.md (F-A to F-E), and the brief's D1 and D2 and claims 1 to 3. No code fact-check report covers this range. Comment claims were checked against the code here.

Threat model, per the brief: honest-path slips must fail loudly. A hostile same-uid loop with a shell belongs to Q-103's residual class. Two kinds of probe ran:
- The four `--cycle-diff`/`--land-cycle` bats tests, plus the U3c cycle-diff test, ran serially under `/tmp/u4a-secc2-*`. All 5 passed, including the new F-A and F-B cases.
- A probe sourced the lib and evaluated cycle_rules' exact slug expression and its first four path rules on benign strings. These probes are named Q1 and Q2 below.

The temp directories were removed afterwards. No process was left running.

## Status of the previous findings

| Previous finding | Fix in range | Status | Basis |
|---|---|---|---|
| F-A (Medium): the -STEM-N binding was satisfied by a brief whose name ends with this stem | slug must match `^[a-z]+(-[a-z]+)*-STEM-[0-9]+$` | **Closed** | executed (bats case; Q1); argued below |
| F-B (Low): the allowlist compared paths as spelled, while check_fix lower-cases them | allowlist tests `lp` against `docs/*.md` / `readme.md` | **Closed** | executed (bats case `readme.md` + `Docs/x.md` → `ok`; Q2) |
| F-C, F-D, F-E, the docs-only carried commit | none (override rows 2026-10-13) | Settled, unchanged in class. The range adds new spellings for the F-C and F-D shapes: see F-1 | Q2 |

### Why F-A is closed (claim 1)

Take an entry slug S that satisfies the rule for stem A, so S = W-A-N. Suppose S is also the slug of an entry filed for stem B, so S = W'-B-N'. W and W' hold only lower-case letters and hyphens. N and N' are digits with no hyphen. Every stem starts with a date digit, because `isbrief` requires `^docs/working/briefs/DDDD-DD-DD-SLUG\.md$`, and an Asked: item is judged only for a path `anybrief` names. So the first digit in S is where both A and B start, which makes W = W' and A-N = B-N'. If A ≠ B, one stem must extend the other by `-X`, and then N or N' would have to contain a hyphen, which it cannot. So A = B, and an entry slug in this form names exactly one brief.

Q1 (executed) checked the following shapes:

| Shape | Result |
|---|---|
| `keep-or-drop-2026-10-01-x-1` on `x`, and the hypothetical `blocked-2026-10-01-x-12` on `x` | PASS |
| The F-A shape `keep-or-drop-2026-10-02-foo-2026-10-01-x-1` on `x` | refuse |
| `…-2026-10-01-x-2-1` on `x` | refuse |
| `…-2026-10-01-x-2` on `x-2` | refuse |
| `…-2026-10-01-x-1` on `x-1` (an entry with no N that reads as one with N) | refuse |
| An all-digit tail stem `2026-10-01-1` with `…-2026-10-01-1-1` | PASS. That is its own entry, and by the argument above no other stem can produce it |
| A heading with no ` · ` | refuse. `#* · ` strips nothing, and `###` fails `^[a-z]` |
| Two ` · ` separators, a trailing space, an upper-case first letter, a missing WORDS, or an empty word (`--`) | refuse |

Every refusal is loud, with exit 2. An honest slip into any of these shapes therefore fails closed. The letter class is spelled out in full, so it does not depend on the locale. The stem is quoted, so the regex reads it as a literal, and SLUG excludes regex metacharacters in any case. The form the skill writes (`SKILL.md:316`, `keep-or-drop-<brief file name without .md>-<n>`) passes.

### Does the lower-cased allowlist let in a path the earlier rules no longer judge? (claim 2)

No. The allowlist is the fourth rule in the loop. The three rules before it already read `lp`:
1. `GATE_CODE` is matched against `lp`.
2. `truthrule "$lp"` runs.
3. The cycle-case rule refuses when `TRUTH_WHY` is `cycle` and `p` differs from `lp`.

All of them run before the allowlist. The per-file rules (`anybrief "$p"` and the `case "$p"` on the questions, roadmap and idea-log files) read `p` as spelled. That cannot hide anything: every file they judge is a `writable` cycle file, so any other spelling of it has already been refused as `cyclecase`. Q2 (executed) ran the first four rules on these paths:

| Paths | Result |
|---|---|
| `readme.md`, `ReadMe.MD`, `Docs/x.md`, `DOCS/X.MD` | newly pass. The old rule refused them |
| `Docs/working/questions.md`, `DOCS/ROADMAP.MD`, `Docs/working/briefs/2026-10-01-x.md`, `Docs/working/cycles/cycle-2026-10-01.md` | cyclecase refuse |
| `Docs/dev-cycle.md` | truth:settings refuse |
| `Docs/Constraints.md` | truth:user refuse |
| `Docs/decisions/a.md` | truth:record refuse |
| `Docs/AGENTS.md` | truth:instr refuse |
| `Docs/.x.md` | truth:dot refuse |
| `Scripts/lib/a.md` | gate refuse |
| `README.md/x.md`, `readme.markdown` | allowlist refuse |

The paths that are newly admitted are case spellings of README and of docs/ `.md` files that hold no truth, cycle or gate meaning. On a checkout that folds case they alias paths that already passed. `truthrule` resets `TRUTH_WHY` on every call, so the cycle test never reads a value left over from a previous path.

## Trust Boundary Map

```
B2 (modified): R vs BASE listing (RAW_P paths) → cycle_rules: GATE_CODE(lp) → truthrule(lp) != cycle → cycle case (p vs lp) → allowlist on lp (cycle | docs/*.md | readme.md) (moved: p → lp) → per-file rules (p)
B3 (modified): brief Asked: items in R (keyed by file name) → form regex → NEW[id] → slug "#* · " =~ ^WORDS-STEM-N$ (anchored, new) → used[] → step 2's --check-answer by ID
```

Input-source classification:

```
S3: questions entry headings in R — runtime-mutable — UNTRUSTED as the authority binding an ID to a brief (still the authority; now unambiguous by the decomposition argument)
S4: path spellings in R (case, Unicode, mode) — runtime-mutable — UNTRUSTED toward readers on a case-insensitive checkout and toward later writers
S7: brief file names (STEM) — runtime-mutable, isbrief-limited (date prefix, [a-z0-9-]) — trusted as a literal in the regex; the date-digit start is now load-bearing for uniqueness
```

The range makes one change at each boundary. At B3 it replaces a hyphen anchor with a whole-slug anchor. At B2 it moves the allowlist from the path as spelled (`p`) to the lower-cased path (`lp`), which is the same spelling the three earlier rules already read.

## Findings

#### F-1. Informational: the lower-cased allowlist extends the settled F-C and F-D shapes to a differently cased docs/

**Severity:** Informational
**Location:** `scripts/build-loop.sh` cycle_rules, the allowlist line (`if [[ "$TRUTH_WHY" != cycle && "$lp" != docs/*.md && "$lp" != readme.md ]]`)
**Boundary:** B2
**Move:** 11
**Confidence:** High that these spellings now pass (Q2, executed). Low that it matters, because it adds no new class.
**Legibility-target:** for-orchestrator-synthesis
**Regression:** from ca95fead, yes, but only in which spellings reach the deferred classes. Not from main, because main had no gate on the chore land.
**Evidence (Q2, executed):** `pass  docs/AGENTS.md/x.md` (F-C, unchanged). `PASS-NEW(old refused)  Docs/con<U+017F>traints.md`. At ca95fead the second path was refused, because `p` did not match `docs/*.md`. A path like `Docs/AGENTS.md/x.md` also passes now: its `lp` is `docs/agents.md/x.md`, `isstart` reads the base name `x.md`, and so `truthrule` returns nothing.

Before this range, the F-C shape (a directory at an instruction-file name) and the F-D shape (a Unicode case variant of a truth or cycle file) could land only under a literal `docs/`. They now land under any ASCII case of `docs/` as well. On a case-sensitive checkout, `Docs/` is a different directory that nothing reads as truth. On a checkout that folds case, it aliases `docs/`, where both shapes already passed. So the reach and impact are the same as the settled rows. Only the number of spellings grows.

**Recommendation:** none for this unit. The override rows for F-C and F-D cover this. When either row is picked up, its fix should test `lp` (or a component walk over `lp`), so that it covers these spellings too.

## Untested bypass candidates

- **A stem that does not start with a digit.** The uniqueness argument depends on `isbrief`'s date prefix. I did not probe a brief path that `anybrief` names without that prefix, because by reading none exists: `isclosed` reuses `isbrief` on the remaining name. If `isbrief` ever loosens, F-A comes back.
- **NFC/NFD and other Unicode spellings of `readme.md`.** These belong to F-D's class and were not tested on a host that folds them.
- **`Applied:` pre-filled with a new ID** (carried over from earlier passes): still not probed.

## Endorsement Claims

- **Claim:** for brief stems that `isbrief` admits, a slug that passes the WORDS-STEM-N rule matches exactly one stem.
  **Location:** `scripts/build-loop.sh` cycle_rules, the per-item loop
  **Evidence:** executed (Q1's eight shapes; the bats F-A case) and read-static (the decomposition argument above)
  **Verified:** the regex text, `isbrief`'s date prefix, `isclosed`'s reuse of it, and the shapes listed under Q1
  **Not verified:** the `t.new` heading text in the case where `QKEYS_AWK` emits a heading holding a tab. `read` would split it at the tab, and the remainder would sit in `k`. Not executed.
  **route: code-fact-check**
- **Claim:** every path the lower-cased allowlist newly admits passes `GATE_CODE`, `truthrule` and the cycle-case rule as a non-truth, non-cycle path.
  **Location:** `scripts/build-loop.sh` cycle_rules, the first four rules
  **Evidence:** executed (Q2; the bats F-B case)
  **Verified:** the 19 spellings listed in Q2
  **Not verified:** non-ASCII case spellings (F-D's class) on a host that folds case

## Primitive sweep

The range adds no dangerous primitive. Its changes are to the strings that feed the existing regex test and the existing ref write.

Primitive: repo blob text into regex

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `${newh[$id]#* · } =~ ^[a-z]+(-[a-z]+)*-"STEM"-[0-9]+$` | S3, S7 | quoted stem; explicit letter class | cleared (F-A closed) |
| allowlist `[[ "$lp" != docs/*.md && "$lp" != readme.md ]]` | S4 | GATE_CODE(lp), truthrule(lp), cycle case before it | cleared, with F-1 Informational |

Primitive: git ref write (main moved): unchanged in this range. The land-cycle tests ran through it.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence | Regression |
|---|---------|----------|----------|----------|------------|---|
| F-1 | The lowered allowlist extends the settled F-C/F-D shapes to a differently cased `Docs/` | Informational | B2 | cycle_rules allowlist line | High (executed); low impact | From ca95fead in spellings only; not from main |

## Overall Assessment

The fix range closes F-A and F-B as filed.
- **F-A:** the anchored slug rule, combined with `isbrief`'s date-prefixed stems, gives every passing slug exactly one brief. Every malformed heading refuses loudly.
- **F-B:** the allowlist now reads the same lower-cased path that the earlier rules read. Every cycle, truth or gate path in another case is still refused before the allowlist line, so the change admits no path that escapes those rules. It adds only README and docs/ case spellings, plus more spellings for the already-settled F-C and F-D shapes (F-1, Informational).
- **Text:** the header and comment text in the range matches the code. "Wider than --check-fix, whose other refusals the rules here repeat only in part" is accurate: check_fix uses `^docs/.*\.md$|^readme\.md$` on `lp`, and the glob here is equivalent.
- **Tests:** they cover both fixes and pass.

There is no new Must Fix or Must Address within the code paths read. The endorsement claims are executed, and each one names the hop it did not verify.

## Goal-Alignment Note

- **User goal:** land unit U4a of the build-loop handoff (claude-workflows) once its review-fix loop is clean.
- **Current task:** security critic on the second confirming pass over ca95fead..8389c477 of `feat/build-loop-u4a`.
- **Success criterion:** a markdown report saved at the exact path your own prompt names, structured per your skill.
- **Alignment:** the report is saved at `docs/reviews/security-review-2026-10-13-u4a-confirm2.md`, and its first line is `Commit: 8389c477`. It covers the status of F-A and F-B, the answers to claims 1 and 2, the trust boundary map, the findings with their required fields, untested candidates, endorsements and the primitive sweep. Probes ran under `/tmp/u4a-secc2-*` and were removed. No other file was written.
