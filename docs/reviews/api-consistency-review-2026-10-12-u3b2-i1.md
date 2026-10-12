Commit: 1d829fee

# API Consistency Review: `feat/build-loop-u3b2` (`--main-log SINCE`), iteration 1

**Scope:** `git diff main...HEAD` (main b5f21758, HEAD 1d829fee): `scripts/build-loop.sh` (new mode, `gate_msg`), `test/scripts/build-loop-orchestrator.bats`, plan "As built" note, four override rows
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md` (31 claims: 24 verified, 7 mostly accurate, 0 incorrect). Behaviour the report verified is not re-verified here.

## Baseline Conventions

These conventions come from the script's existing modes (header lines 6-418, argument parser 434-475, dispatch 1670-1720) and from the plan's "Script interface" section (`docs/working/plan-build-loop-handoff.md:201-240`):

- **Flags.** build-loop.sh's modes are single words (`--settings`, `--status`, `--marker`, `--state`, `--check`, `--merge`, `--start`, `--prompt`). The sibling script `dev-cycle.sh` uses hyphenated compound flags (`--check-brief`, `--check-answer`, `--check-branch`, `--check-fix`). The plan names the planned `--cycle-diff` the same way.
- **Arguments.**
  - A commit id is validated as a full 40- or 64-hex lowercase id. Anything else is a usage error: exit 1, stderr only. `--expect`: `[[ "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || usage "--expect takes a full 40- or 64-hex commit id"` (`scripts/build-loop.sh:450`).
  - Arity errors read `--X takes ...`.
- **Output lines.** Lines are keyword first, with fixed fields first and free text last.
  - Verdict lines are `ok ...`, `skip BRIEF: WHY` and `refuse BRIEF: WHY`.
  - State refusals are `refuse state WHAT: WHY`.
  - Some lines are keyword-and-value: --settings' `policy ...` and `slots N ...`, and --start's `dispatched N`.
  - An empty field prints `-`: `"ok $a new review - absent - - 0"` (`:806`).
  - Repo text is data: `printed repo text is data` (`:408`). Where the orchestrator copies repo text into an entry, the text is shape-checked: --status' REASON is 1-120 printable ASCII, and --marker's body follows the D11 rules.
- **Exit codes.**
  - 0: every line printed, and for a deciding mode, every verdict ok.
  - 2: a verdict or the state gate not ok. Lines are still printed, so the caller tells the cases apart by the first word.
  - 1: usage, environment or startup failure, with no line printed.
  - Per U3b1's As-built note, U4 reads any exit but 0 or 2 as "stop and quote stderr".
- **Gating.** Every mode but `settings|status|marker` is gated by default (`:619`). Only `--state` runs caller_gate (`:621`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--main-log SINCE` | CLI flag + arg | `--check-brief`, `--check-answer`, `--cycle-diff` (hyphenated compounds); `--state`, `--marker` (siblings in this script) | `scripts/dev-cycle.sh` flag parser; `docs/working/plan-build-loop-handoff.md:208-209` | Consistent. It is the plan's own name, and the hyphenated form matches the sibling script. |
| `SINCE` (metavar) | parameter | `--expect SHA`, `--approved Q-NNN` | `scripts/build-loop.sh:11-12` | Consistent. It names the role rather than the type, as Q-NNN does, and the plan's D13 uses SINCE (`plan:102`). |
| `--main-log takes one full 40- or 64-hex commit id` | usage message | `--expect takes a full 40- or 64-hex commit id`, `--marker takes one brief path` | `scripts/build-loop.sh:450`, `:440` | Consistent. Same validation regex, same wording pattern. |
| `main MAIN N` | output line | `dispatched N`, `slots N set\|default: WHY`, `policy ...` | `scripts/build-loop.sh:366`, `:29` | Consistent. A keyword-value line, like --settings and --start. |
| `gate`, `chore`, `answers`, `other` | output class words | D13's four classes | `docs/working/plan-build-loop-handoff.md:102` | Consistent. These are the plan's exact words. `answers` is plural where the other three are singular, but the plan fixes it. |
| `gate\|chore\|answers\|other SHA SUBJECT` | output line | `ok BRIEF SHA` (--marker), `ok BRIEF STATE ... [REASON]` (--status) | `scripts/build-loop.sh:99`, `:68` | Consistent. Fixed fields come first and free text last. |
| `refuse main-log: WHY` | refusal line | `refuse state WHAT: WHY`, `refuse BRIEF: WHY` | `scripts/build-loop.sh:150-190` (--check), `:1214-1215` | Consistent. It is keyed by a fixed token, like `refuse state`, not by the argument. That lets U4 tell it apart from a `refuse state` line, which the same run can print. |
| `gate_msg` | internal function | `gate_repo`, `gate_git`, `gate_start` | `scripts/build-loop.sh:918-937`, `:1218` | Consistent with the `gate_` prefix family. It is internal and not consumer-facing. |
| `MODE="main-log"` | internal mode value | `MODE="${1#--}"` for every other mode | `scripts/build-loop.sh:446`, `:458` | Consistent. It is the flag minus `--`. |

## Findings

#### 1. No hardened way to learn MAIN when no SINCE exists or SINCE is refused

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1659-1663`, `scripts/build-loop.sh:441-443`; consumer: U4's step "start: --state, --main-log" (`docs/working/plan-build-loop-handoff.md:247`)
**Move:** 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** U4 implementer (`skills/dev-cycle/SKILL.md`), via the plan's U3b2 "As built" note

The next record's `Main at:` comes from `--main-log`'s `main MAIN N` line. Override row 700 relies on this: "--main-log (U3b2) names main's SHA for the iteration record" (`docs/reviews/override-log.md:700`). `--state` prints a bare `ok`. The `main` line is printed only on success, though:

> `gate_git rev-list --first-parent "$MAIN_SHA" > "$GATE_TMP/fp" || { echo "refuse main-log: the default branch's first-parent history could not be listed"; return 1; }` (`:1659`)

> `echo "main $MAIN_SHA $(wc -l < "$GATE_TMP/after")"` (`:1663`)

SINCE is required: `[[ $# -eq 2 && "$2" =~ ^(...)$ ]] || usage ...` (`:443`). Two U4 paths therefore have no hardened way to get main's commit:

- **First iteration.** No record holds `Main at:`. The repo's only record, `docs/working/cycles/cycle-2026-10-02.md`, has no such line.
- **After `refuse main-log`.** Main was rewritten, or SINCE is on another branch. MAIN appears only inside the prose WHY of one of the two refuse texts (`:1662`).

In both cases U4 must read main's commit with a git call outside the script. U3b1's note warns against exactly that ("U4 runs its git through the script or a hardened wrapper"), or else the read waits for U3b3's `git_harden`. This is a contract gap, not a break. Nothing has shipped against it.

**Recommendation:** Pick one fix:
- Print `main MAIN -` before a `refuse main-log:` line, using --status' `-` for an unknown field. Then document in the plan note that U4 bootstraps by passing that MAIN back as SINCE, which gives `main MAIN 0`.
- Or state in the plan's U3b2 note how U4 gets the first SINCE and recovers from a refusal (for example, a `git_harden`ed `rev-parse` once U3b3 lands).

#### 2. U4-facing contract text under-specifies what the writer must produce

**Severity:** Minor
**Location:** `docs/reviews/override-log.md:719`, `docs/working/plan-build-loop-handoff.md:325`, `scripts/build-loop.sh:153-157`
**Move:** 3 (documentation drift against the consumer contract); builds on fact-check Claims 2, 6, 8, 11b, 12
**Confidence:** High
**Legibility-target:** U4 implementer (the override row is the handoff the plan points U4 at)

Override row 719 is the coupling row U4 is told to read. It says only "a subject starting "Merge branch 'B'"". The code requires more than that:

- **Subject.** It requires the end, " into " or ":" right after the quote: `\'($|\ into\ |:)` (`:1633`). A pr-prep land with a custom `-F` message such as `Merge branch 'chore/dev-cycle-...' (cycle)` therefore reads `other`. That stops dispatch and files a false-positive entry.
- **File mode.** Both the cycle record and the questions files must be mode 100644. Help and plan say only "regular file" and "regular files kept regular". The record check is `^:[01234567]{6}\ 100644\ ...` (`:1637`); the questions check is `^:100644\ 100644\ ...\ M$` (`:1645`). Fact-check E3 shows that an executable record or questions file reads `other`.
- **Short SINCE.** The plan note says "SINCE is a full id on main's first-parent history, else `refuse main-log: WHY`". A short id is a usage error instead: exit 1, stderr only, no line (`:443`). U4 reads exit 1 differently from exit 2.

All three gaps fail closed. The cost is a consumer who writes to the documented contract and gets `other` (an attention cost) or an unexpected exit 1.

**Recommendation:** Amend row 719 and the plan note in place:
- the subject is "Merge branch 'B'" followed by the end, " into " or ":";
- the record and the questions files are mode 100644;
- a non-full SINCE is usage (exit 1); only a full id off the history is `refuse main-log:` (exit 2).

Tighten the help's "regular file" to "a mode-100644 file". The repo's own merge convention already matches the ":" form (`Merge branch 'feat/build-loop-u3b1': --state checks ...`, ef7a1122), so U4 only needs to keep it.

#### 3. SUBJECT is free repo text in the last field, printed with no shape check and no placeholder

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1665`, `scripts/build-loop.sh:146-148`
**Move:** 8 (nullability) and 3
**Confidence:** High
**Legibility-target:** U4 implementer (parser and the `you: judgment` entry D13 files "naming the commit")

`log_class "$c"; echo "$CLASS $c $SUBJ"` (`:1665`). Probe output (temp repo under `/tmp/u3b2rv-api-`, removed):

- An empty-message commit printed `other a53340371540fe0af79abe6d7ebee5a532b360c6 $` under `cat -A`. That is a trailing space and no field. The script's convention for an empty field is `-` (`"ok $a new review - absent - - 0"`, `:806`).
- A commit with subject `gate 0000000000000000000000000000000000000000 x` printed `other 1038ba5d... gate 0000000000000000000000000000000000000000 x`. That is safe only for a parser that splits the first two fields by position.

Other repo text the orchestrator copies into an entry is shape-checked: --status' REASON is "1-120 printable ASCII", and --marker's body is checked against entry grammar (D11). SUBJECT is checked only by the global scrub (`:408`, "printed repo text is data"). If U4 quotes SUBJECT into the entry D13 files, it must quote it as data itself.

**Recommendation:** Either print `-` for an empty subject, or keep the output as it is and say in the help that SUBJECT may be empty. Also add one line to the plan's U3b2 note: U4 parses class and SHA by position, names an `other` commit by SHA, and quotes SUBJECT (if at all) as data under D11's rules.

#### 4. The record's `Branch:` line is read from any line, while the same key on a brief is read from the first unfenced line

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1639`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** U4 implementer (who writes the record line); future maintainer of log_class

Precedent: a `Branch: NAME` machine line is read as "the first unfenced line" by `brief_fields`, per `docs/working/plan-build-loop-handoff.md:235`.

The chore rule matches the key anywhere in the record, fences included:

> `awk -v w="Branch: $b" '{ sub(/\r$/, "") } $0 == w { f = 1 } END { exit !f }'` (`:1639`)

The help says exactly this ("holding the line"), so the help is accurate. But one key now has two reading rules in the same system, and the record's rule is the more permissive one. A record that quotes its own branch line inside a fence, or below another `Branch:` line, still counts. That fits F19's honest-slip threat model, so this is not a defect.

**Recommendation:** No code change needed now. When U4 writes the record, put `Branch: B` as an unfenced line near the top, so that later tightening to "first unfenced line" (matching brief_fields) does not break it. Note this choice in U4's step 9.

## What Looks Good

- **Exit semantics follow --check.** `other` and `refuse main-log:` both exit 2 after the lines are printed. `main_log` keeps going after an `other` (`[[ "$CLASS" != other ]] || o=1`, `:1665`), so U4 gets the complete listing in one run. That matches --check, which prints every verdict and then exits 2.
- **Usage errors match --expect's.** They use the identical regex and wording (`:443` vs `:450`), and uppercase or extra arguments give exit 1 (probe).
- **The new line types fit the existing grammar.** `main MAIN N` is a keyword-value line like `dispatched N`. `refuse main-log:` uses a fixed token, like `refuse state`, so U4 can tell a history refusal from a state-gate refusal by the second word.
- **Gating follows the default.** The mode runs the state half but not caller_gate. The help says so ("after --state's gate but its caller check"), and D13's order (`--state`, then `--main-log`) covers it.
- **One message definition.** `gate_msg` is the single definition of the merge message, so the reader and the writer cannot drift (row 662 discharged; fact-check Claim 21 shows land's bytes are unchanged).
- **Documentation updated together.** The usage line, the header synopsis, the Exit section and the mktemp list were all updated in one change.

**What U4 must parse (summary for the consumer):**

| Exit | stdout | Meaning |
|---|---|---|
| 1 | nothing; stderr | Usage (a non-full SINCE), environment, mktemp or no default branch. Stop and quote stderr. |
| 2 | `refuse state ...` lines | State gate or default_gate. No `main` line. |
| 2 | `refuse main-log: WHY` | SINCE is off main's first-parent history, or it could not be listed. No `main` line (Finding 1). |
| 2 | `main MAIN N`, then N class lines, at least one `other` | Stop dispatch. File an entry per D13. |
| 0 | `main MAIN N`, then N lines of gate, chore or answers | Proceed. Write MAIN as the next `Main at:`. Check that the line count equals N. |

Use the MAIN from this run's `main` line, not one read separately. Main can move between the `--state` run and the `--main-log` run.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | No hardened MAIN when SINCE is absent (first iteration) or refused | Minor | `scripts/build-loop.sh:1659-1663`, `:443` | Medium |
| 2 | Row 719 and the plan note under-specify the subject suffix, mode 100644, and usage vs refuse for a short SINCE | Minor | `docs/reviews/override-log.md:719`, `docs/working/plan-build-loop-handoff.md:325`, `scripts/build-loop.sh:153-157` | High |
| 3 | SUBJECT may be empty (trailing space, no `-`) and is not shape-checked for entry quoting | Informational | `scripts/build-loop.sh:1665` | High |
| 4 | Record `Branch:` read from any line vs brief_fields' first unfenced line | Informational | `scripts/build-loop.sh:1639` | High |

## Overall Assessment

`--main-log` is consistent with the script's established CLI conventions: the argument validation, the usage wording, the keyword-first output lines, the `refuse` grammar, exit 2 after printing, and the gated-by-default rule. Nothing breaks: the only change to an existing interface, land's message, is byte-identical (fact-check Claim 21). The findings are all about the consumer contract U4 will build against:

- the bootstrap and recovery path for SINCE (Finding 1);
- three qualifiers the handoff text omits, which turn an honest U4 land into `other` (Finding 2);
- two small parse and quoting notes (Findings 3 and 4).

All can be fixed in place in the docs. Finding 1 would also take a one-line output change.

## Goal-Alignment Note

Success criterion: "An API-consistency review saved to docs/reviews/api-consistency-review-2026-10-12-u3b2-i1.md in the worktree, per the api-consistency-reviewer skill." Met. This file is at that path, and its first line is `Commit: 1d829fee`. It has the skill's sections: baseline, name-pattern audit table, findings in the template with severity, location, move and confidence, What Looks Good, summary table and overall assessment. Every finding carries a Legibility-target line. Evidence is quoted verbatim from the cited file:line or from probe output. The audit raised no naming finding, so the precedent-line rule applies to none. Finding 4 is an asymmetry finding and cites its precedent anyway. Following the brief:

- Recorded override rows were not re-filed. Finding 2 extends row 719's handoff with qualifiers the fact-check found missing; it does not dispute the row's reasoning.
- One probe ran under `/tmp/u3b2rv-api-`, with `set -eu`, its own mktemp and a pwd check, under `timeout`. It was removed afterwards; nothing is left running.
- Only this file was written.
