Commit: ca95fead

# Security Review — feat/build-loop-u4a (U4a, confirming pass)

**Scope:** partial. The fix range is b1a6f0a2..ca95fead (8d18e566 code, ca95fead docs): `scripts/build-loop.sh` `cycle_rules` (the new allowlist, the `-STEM-N` binding, `qrc`), `questions_rules` (return 2, `cy.new` with heading lines), the header and comment text, and the U4a cycle-diff and U3c roadmap tests. The rest of the branch is context only and was not re-reviewed (read for context: `truthrule`, `writable`, `isrecord`, `anybrief`, `isstart`, `INSTRUCTION_FILE`, `QKEYS_AWK`, `cycle_diff`, `land_cycle`, `scripts/dev-cycle.sh` `check_fix`, `skills/dev-cycle/SKILL.md` steps 1 and 6).
**Date:** 2026-10-13
**Based on:** docs/reviews/security-review-2026-10-13-u4a-final.md (F1-F4), the brief's fix-range claims C1, C2 and C6. No code fact-check report for this range was provided. Claims about security properties in comments were checked against the code here, not by a separate fact-check.

Threat model, per the brief: honest-path slips must fail loudly. A hostile same-uid loop with a shell is Q-103's residual class. Probes P1-P7 ran once, in a `git archive` of ca95fead under `/tmp/u4a-secc-*`, through a bats file that loaded `test/lib/build-loop-fixtures.bash` on benign fixtures. The directories were removed afterwards and no process was left running.

## Verdict on the final pass's findings

| Final finding | Fix | Status | Basis |
|---|---|---|---|
| F1: a loop branch's code lands as chore | C1 allowlist | **Closed for code.** `src/app.sh` refuses (the branch test, plus P7's control). Residue: a carried commit that touches only `docs/**.md` still lands as chore. Those files are documentation, which the allowlist admits on purpose. This is Informational and inside row 745's class. | executed (test; P7) |
| F2: Asked: ID not bound to its entry's brief | C2 `-STEM-N` | **Closed as filed** (the probe-P3 shape, Y's entry on X, now refuses: test). **Narrowed residue, F-A below:** a brief whose name ends with another brief's whole stem satisfies the other brief's binding. | executed (test; P4, P4b) |
| F3: a directory at an instruction file's name | C1 allowlist | **Closed at the top level** (`AGENTS.md/x` is outside the allowlist). **Open under docs/:** `docs/AGENTS.md/x.md` lands (F-C). | executed (P2) |
| F4: Unicode case variant of a gate/truth path | C1 allowlist | **Closed for gate code** (scripts/ and skills/ are outside the allowlist; the test's Kelvin-sign case refuses). **Open for docs/:** a Unicode variant of a truth file or a cycle file under docs/ lands (F-D, row 393 class). | executed (P5a, P5b on Linux) |

## Answers to the three questions

1. **Can a real cycle's honest staging now be refused by the allowlist?** In this repo, no, for everything steps 1-6 write. P7 staged a new cycle record, a brief moved to `closed/`, an Asked: append bound to a new entry, a new idea log, `docs/thoughts.md`, `docs/working/triage-x.md` and `docs/reviews/r.md`. `--cycle-diff` printed `ok`, and `--land-cycle` landed it. **Yes, in a repo whose readme is not spelled `README.md`** (`readme.md`, `Readme.md`), or whose docs are under a differently cased `Docs/`. `--check-fix` allows those in-cycle fixes and the allowlist refuses them (F-B, executed P1). The failure is loud and fails closed, and it costs one cycle's fix.
2. **Can the -STEM-N binding be satisfied by an entry filed for another brief?** Yes, in one naming shape. Brief B's file name has to end, at a hyphen, with brief A's whole stem (for example a follow-up brief `2026-10-02-foo-2026-10-01-x` beside `2026-10-01-x`). B's entry `keep-or-drop-2026-10-02-foo-2026-10-01-x-1` then passes when it is appended to A's `Asked:` line (F-A, executed P4). The brief's claim 2 example (`2026-10-01-x` against `2026-10-01-ax`) does hold, because the `(^|-)` anchor rejects it.
3. **Does qrc 2 let an item through that would otherwise refuse?** No. Every path that returns 2 also sets `bad=1` in `cycle_rules` through `|| { qrc=$?; bad=1; }`, so the run refuses (exit 2) whatever the items hold. qrc 2 only drops the per-item NEW, binding and `used[]` messages. In P6, a whole-file refusal together with `, Q-002, Q-002, Q-777` printed only the questions-file refusal, with exit 2. All seven fatal exits in `questions_rules` return 2. An entry refusal still returns 1 after it writes `cy.new` (by reading: `bad=1` in the `while read` loop, then the `cy.new` awk, then `return "$bad"`).

## Trust Boundary Map

```
B2 (modified): R vs BASE listing (RAW_P paths)            → cycle_rules: GATE_CODE → truthrule(lower) != cycle → cycle case → allowlist (cycle | docs/*.md | README.md) (new) → per-file rules
B3 (modified): brief Asked: items in R (keyed by file name) → form regex → NEW[id] → heading "#* · " =~ (^|-)STEM-[0-9]+$ (new) → used[] → step 2's --check-answer by ID
B4 (modified): questions headings in R (QKEYS h lines)    → cy.new "ID<TAB>heading" (new) → newh[] → B3; qrc 2 when a copy is unread (new)
```

Input-source classification:

```
S2: brief Asked: lines in R            — runtime-mutable — UNTRUSTED toward answer application
S3: questions entry headings in R      — runtime-mutable — UNTRUSTED as the authority binding an ID to a brief (now used as that authority)
S4: path spellings in R (case, Unicode, mode) — runtime-mutable — UNTRUSTED toward readers on a case-insensitive checkout and toward later writers
S7: brief file names (STEM)            — runtime-mutable, SLUG-limited ([a-z0-9-]) — trusted as a literal in the regex (quoted), not as unique among suffixes
```

The fix range turns B2's catch-all from allow to deny for anything outside `docs/*.md` and `README.md`, which closes the code-carrying shapes. It also makes B4's heading text the binding authority for B3. Both rules are string matches, and the findings below are where the strings say less than the rule means: a stem that occurs as a hyphen-suffix, ASCII-only case, link modes, and nesting under docs/.

## Findings

#### F-A. The -STEM-N binding accepts another brief's entry when that brief's name ends with this brief's stem

**Severity:** Medium
**Location:** `scripts/build-loop.sh` cycle_rules, the per-item loop (`elif ! [[ "${newh[$id]#* · }" =~ (^|-)"${f%.md}"-[0123456789]+$ ]]`)
**Boundary:** B3, B4
**Move:** 11
**Confidence:** High that it passes (executed). Low that it happens: it needs a brief named with another brief's full stem, and the swap slip.
**Legibility-target:** for-orchestrator-synthesis
**Regression:** not from main (main has no Asked: rule) and not from b1a6f0a2 (there any brief passed). It is a narrowed residue of final F2.
**Evidence (P4, executed):** briefs `2026-10-01-x.md` and `2026-10-02-foo-2026-10-01-x.md`. The change files `### Q-002 · keep-or-drop-2026-10-02-foo-2026-10-01-x-1` and appends `, Q-002` to **x**'s `Asked:` line. `--cycle-diff` printed `ok`, exit 0. Source: `      elif ! [[ "${newh[$id]#* · }" =~ (^|-)"${f%.md}"-[0123456789]+$ ]]; then echo "refuse ${ap[$f]}: …"; bad=1` (one arm of the per-item if; the remainder is the `used[]` arm and the loop ends).

The pattern is anchored only at a hyphen, not at the slug's start. A brief name can legally hold another brief's stem as its tail, because SLUG admits digits and hyphens, and a follow-up brief that names its parent is a plausible honest name. So the entry filed for B binds to A. That is the same consequence as final F2: step 2 applies the user's keep-or-drop answer about B to A, and B's own question is never applied. The floor rule keeps this at Medium. The odds belong in Confidence.

**Recommendation:** anchor to the slug form the skill fixes (`SKILL.md:316`): require the heading text after ` · ` to match `^keep-or-drop-STEM-[0-9]+$`. A stem starts with a date, so the anchored form cannot match another brief's entry. Also put that case in the U4a test.

#### F-B. The allowlist refuses in-cycle fixes that --check-fix allows: a lower- or mixed-case readme, a differently cased docs/

**Severity:** Low
**Location:** `scripts/build-loop.sh` cycle_rules (`if [[ "$TRUTH_WHY" != cycle && "$p" != docs/*.md && "$p" != README.md ]]`), against `scripts/dev-cycle.sh` check_fix (`! "$lp" =~ ^docs/.*\.md$|^readme\.md$`)
**Boundary:** B2
**Move:** 3 (error path), 5
**Confidence:** High (P1, executed)
**Legibility-target:** for-orchestrator-synthesis
**Regression:** from main, yes for availability (main had no gate on the chore land, so this commit landed). From b1a6f0a2, yes (there it passed). It is not a security weakening, because it fails closed.
**Evidence (P1, executed):** a repo with `readme.md`; the chore commit edits it. `--cycle-diff` printed `refuse readme.md: not a file the cycle changes (its own files, a .md under docs/ or README.md, which --check-fix may allow)`, exit 2. `check_fix` compares the lower-cased path to `^readme\.md$`, so it would have printed `ok` for the same fix.

The new header and comment say the allowlist is "what --check-fix may allow". The allowlist compares the path as spelled, and check_fix compares it lower-cased. So an honest cycle in a repo whose readme or docs directory is not spelled exactly `README.md` or `docs/` makes the fix that step 1 permitted, and the cycle then fails to land. In the other direction, the allowlist is broader than check_fix: it admits `docs/working/**`, `docs/reviews/**`, @-imported docs and non-regular modes. Those admissions are deliberate or already settled (rows 745, 764), so only the wording overstates the match.

**Recommendation:** compare `lp` (`"$lp" == docs/*.md || "$lp" == readme.md`), as check_fix does. The cycle-case rule above already refuses a cycle file in another case, so lowering admits no cycle-file alias. Also reword the comment to "a superset of what --check-fix allows".

#### F-C. Floor's "below" class is still open under docs/: a directory at an instruction file's name inside docs/ lands

**Severity:** Low
**Location:** `scripts/build-loop.sh` cycle_rules, the allowlist line, against `scripts/lib/dev-cycle-read.sh` `isstart` and `INSTRUCTION_FILE`
**Boundary:** B2
**Move:** 11
**Confidence:** High (P2, executed)
**Legibility-target:** for-orchestrator-synthesis
**Regression:** no (residue of final F3)
**Evidence (P2, executed):** a chore commit that adds `docs/AGENTS.md/x.md` gave `--cycle-diff` → `ok`, exit 0. `isstart` reads the base name (`[[ "${1##*/}" =~ $INSTRUCTION_FILE ]]`), so `docs/agents.md` is an instruction-file name, and floor's `below` walk would refuse the directory there.

The effect is the same as F3's: a nested instruction file `docs/AGENTS.md` can no longer be created. It is availability, not injection. The allowlist's `docs/*.md` glob matches across `/`, so a `.md` leaf under such a directory passes.

**Recommendation:** apply floor's below walk (any prefix that `isstart` names) in cycle_rules, or refuse a docs path any of whose directory components matches `INSTRUCTION_FILE`.

#### F-D. Informational: Unicode case variants of docs/ truth and cycle files pass the allowlist (row 393 class)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh` `lower` (ASCII `tr`), `scripts/build-loop.sh` cycle_rules
**Boundary:** B2
**Move:** 11
**Confidence:** Low (needs a checkout that folds Unicode case; not tested on one)
**Legibility-target:** for-orchestrator-synthesis
**Regression:** no (residue of final F4)
**Evidence (P5a, P5b, executed on Linux):** `docs/con<U+017F>traints.md` (LATIN SMALL LETTER LONG S) and `docs/working/que<U+017F>tions.md` each gave `--cycle-diff` → `ok`. Both are `.md` under docs/, and neither is lower-equal to a truth or cycle name. On a filesystem that applies full Unicode case folding they may alias `docs/constraints.md` and the questions file. The second case would put an unjudged questions copy beside the judged one.

C1 closes F4 for the gate's code, which now sits outside the allowlist, but not for the truth and cycle names under docs/.

**Recommendation:** none for this unit. When row 393 fires, refuse non-`pathform` paths in cycle_rules, as `--check-fix` does.

#### F-E. Informational: a link (mode 120000) at a docs/*.md path passes

**Severity:** Informational
**Location:** `scripts/build-loop.sh` cycle_rules, the allowlist line (it does not test the mode for non-cycle paths)
**Boundary:** B2
**Move:** 11
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Regression:** no (any path passed at b1a6f0a2)
**Evidence (P3, executed):** `docs/x.md` → `../docs/working/questions.md` symlink gave `--cycle-diff` → `ok`.

`--check-fix`'s `check_path` would not offer a link as an in-cycle fix, so an honest cycle does not stage one. A carried one makes a docs path that later writers (a loop editing docs/x.md) write through to the link's target. The lib's plain-path checks block the cycle's own reads. Low impact.

**Recommendation:** in the allowlist arm, also require `RAW_NM` to be `100644` or `000000` for non-cycle paths. That is cheap and matches `--check-fix`.

## Untested bypass candidates

- **NFD/NFC spellings, NTFS trailing dots and 8.3 names** of docs/ truth paths: not tested on a host where they alias (F-D's class).
- **A carried loop commit that touches only docs .md**, such as a loop's `docs/working/plan-*.md` (F1's residue): admitted by design. Not probed beyond P7's control.
- **A CRLF or trailing-space heading** on an honestly filed entry: by reading, QKEYS strips `\r`, and a trailing space makes the binding refuse. That fails loudly, and it was not executed.
- **`Applied:` pre-filled with a new ID** (carried from the final pass): still not probed.

## Endorsement Claims

- **Claim:** questions_rules returns 2 on each of its seven fatal exits, and cycle_rules sets `bad=1` whenever it returns non-zero, so `qrc 2` never turns a refusal into a pass.
  **Location:** `scripts/build-loop.sh` questions_rules (the seven `return 2`), cycle_rules (`|| { qrc=$?; bad=1; }`)
  **Evidence:** executed (P6; the U4a test's unbalanced-fence case) and read-static (all seven exits)
  **Verified:** P6 refused with exit 2 and only the whole-file line. The diff's seven `return 1` → `return 2` edits are all the fatal exits in the function.
  **Not verified:** a failing `QDIFF_AWK` or `cy.new` awk (exits 6 and 7) were not forced at run time.
  **route: code-fact-check**
- **Claim:** a real cycle's staging in this repo passes both modes under the allowlist.
  **Location:** `scripts/build-loop.sh` cycle_rules, land_cycle
  **Evidence:** executed (P7)
  **Verified:** record, brief to closed/, bound Asked: append, new idea log, docs/thoughts.md, docs/working/triage-x.md, docs/reviews/r.md: `ok`, then `landed …`
  **Not verified:** a roadmap rewrite in the same commit (covered by the U3c roadmap test, not re-run here), and files a repo's health check might write inside the tree
- **Claim:** the binding's `(^|-)` anchor rejects a stem that is a non-hyphen suffix (`…-x` against `…-ax`).
  **Location:** cycle_rules per-item loop
  **Evidence:** read-static
  **Verified:** regex text. The quoted stem is literal, and SLUG excludes regex metacharacters.
  **Not verified:** not executed. F-A covers the hyphen-suffix case.

The allowlist and the Asked: binding do not appear as endorsed guardrails. F-A is a tested bypass of the binding, and F-C, F-D and F-E are tested bypasses of the allowlist's intent.

## Primitive sweep

The fix range adds no new dangerous primitive. Its changes are to the rules that feed the existing ref write.

Primitive: repo blob text into regex/awk

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cy.new` awk (heading line after a tab) | S3 | ANSWER_AWK whole-file refusal first; `-F '\t'` | cleared as a reader |
| `while IFS=$'\t' read -r id k` → `newh` | S3 | id is QKEYS's `Q-digits` | cleared |
| `${newh[$id]#* · } =~ (^|-)"STEM"-[0-9]+$` | S3, S7 | quoted stem (literal) | F-A (unanchored start) |
| allowlist `[[ "$p" != docs/*.md ... ]]` | S4 | none beyond earlier rules | F-B, F-C, F-D, F-E |

Primitive: git ref write (main moved): unchanged in this range. See the final report's sweep. P7 landed through it.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence | Regression |
|---|---------|----------|----------|----------|------------|---|
| F-A | -STEM-N binding satisfied by a brief whose name ends with this brief's stem | Medium | B3, B4 | cycle_rules per-item loop | High (executed); low likelihood | No (narrowed residue of final F2) |
| F-B | Allowlist compares as spelled: `readme.md`/`Docs/` fixes that --check-fix allows refuse; comment overstates the match | Low | B2 | cycle_rules allowlist line | High | Yes (availability, fails closed) from main and b1a6f0a2; not a security weakening |
| F-C | Directory at an instruction-file name under docs/ lands | Low | B2 | cycle_rules allowlist line | High | No (residue of final F3) |
| F-D | Unicode case variants of docs/ truth or cycle files pass | Informational | B2 | `lower`, allowlist | Low | No (residue of final F4; row 393) |
| F-E | A link at a docs/*.md path passes | Informational | B2 | allowlist line | Medium | No |

## Overall Assessment

The fix range does what it claims for the shapes the final pass filed. A loop's code carried on the chore branch now refuses. The Y-entry-on-X swap refuses. The gate-code Kelvin variant refuses. qrc 2 suppresses messages only, never a refusal. Nothing in the range weakens a refusal that existed at b1a6f0a2. The one behavioural regression, F-B, fails closed. It refuses an honest fix only in repos whose readme or docs directory is spelled otherwise, and it is a one-line change to compare `lp`. The only Medium is F-A: the new binding is anchored at a hyphen rather than at the slug's start, so a follow-up brief named after its parent can take the parent's entry. It needs both that naming and the swap slip, and the fix is one regex anchor (`^keep-or-drop-STEM-[0-9]+$`). Whether F-A counts as a new Must Address that blocks the merge or a defer row beside row 745 is the loop's call. It is a narrower residue of the already-filed F2, not a new class. Verdict: no findings above Medium within the code paths read. The endorsement claims are executed or scoped, with their Not-verified hops named.

## Goal-Alignment Note

- **User goal:** land unit U4a of the build-loop handoff (claude-workflows) once its review-fix loop is clean.
- **Current task:** security critic on the narrow confirming pass over b1a6f0a2..ca95fead of `feat/build-loop-u4a`.
- **Success criterion:** a markdown report saved at the exact path your own prompt names, structured per your skill.
- **Alignment:** saved at `docs/reviews/security-review-2026-10-13-u4a-confirm.md` with `Commit: ca95fead` first. It contains: the verdict on final F1-F4; answers to the three questions; the trust boundary map and source table; findings with Severity, Location, Evidence, Confidence, Legibility-target and regression status; untested candidates; endorsement claims; the primitive sweep. Probes ran in `/tmp/u4a-secc-*` (removed). No other file was written.
