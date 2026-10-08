Commit: e02d056b

# API Consistency Review — feat/build-loop-u2b1b (final confirming pass, full branch)

**Scope:** `git diff main...HEAD` (cc9b69d3, 809df345, a382a3f8, e02d056b). Surface: all of `build-loop.sh --check`'s output contract (verdict lines, `path`/`deny` lines, every refusal text, `refuse state` lines from `state_gate`, `default_gate` and the gate-repository setup, the exit status), checked against the help (`scripts/build-loop.sh:80-139`), the plan's interface section (`docs/working/plan-build-loop-handoff.md:207-213`) and its output conventions (`:193-198`).
**Date:** 2026-10-08
**Based on:** Stage 1 summary `scratchpad/u2b1b-i3/factcheck-summary.md` (k=3: `code-fact-check-report-build-loop-u2b1b-final-r{1,2,3}.md`; suites pass, every carried fix's mutant fails its test)
**Consumers:** plan D4's merge entries (`:59`, "The entry body is `--check`'s output") and U3's `--merge` (`:213`, "as `--check`, then commit-tree and CAS"). Neither exists yet: `rg build-loop\.sh` outside `docs/`, `test/` and the script itself finds only lib comments. So no finding here can be Breaking.

## Baseline Conventions

Re-checked at HEAD:

- **Line shape** (`--status`, `--settings`, dev-cycle.sh check modes). The first word gives the line type. Fixed fields come before any colon (`ok BRIEF TIP TREE`, `path BRIEF S PATH`), and prose comes after `WORD ARG:` (`refuse BRIEF:`, `skip BRIEF:`, `deny BRIEF S PATH:`, `refuse state WHAT:`).
- **Plan output convention** (`plan:195-198`): "`skip X: why` means unreadable; `refuse X: why` is a verdict; read modes exit 0 when every argument was answered; writing modes exit 2 on any refusal; usage errors exit 1."
- **State lines.** `refuse state WHAT: WHY`, one per finding, all printed before exit 2. `state_gate` (`:213-235`) and `default_gate` (`:241-251`) both use the accumulate-`bad`, `return "$bad"` contract.
- **Refuse-reason subject.** Per-brief merge refusals name the branch ("the merge of $br ..."), except the K-of-N line, which names TIP and TREE. That exception is settled (override row, iteration 2 api 4, Won't-Fix), so it is not re-flagged.

## Prior api findings: verification at e02d056b

| Item | Verdict | Evidence |
|---|---|---|
| i2 api 1: help says "a .git part" | **Fixed** | `:122` `(a part starting .git, any case: .github/); a mode other than 100644 or 100755` |
| i2 api 2: plan `--state` names only `state_gate` | **Fixed** | `plan:207` "(U2b1a's `state_gate`, then U2b1b's `default_gate` once main is resolved: both main and master, or origin/HEAD naming another branch than the one taken)" |
| i2 api 3: missing-blob noun and its help heading | **Fixed** | `:617` `the merge of $br names a blob the object store lacks`; help `:107-110` now gives it its own sentence: `Or "the merge of BRANCH names a blob the object store lacks": a regular file the merge adds or changes names an object that is absent or not a blob.` |
| i2 api 4: TIP vs branch in "the merge of X" | Won't-Fix row; code unchanged under it | `:626` unchanged |

Probe (fixture under my scratch dir: an own brief open→done, `ok.txt`, `.github/w.yml`, `we ird.txt`). Output matches the help, and the run exited 2:
```
refuse docs/working/briefs/2026-10-01-x.md: 2 of 4 changed paths refused in the merge of bc6e739b... (tree 176570a4...)
deny docs/working/briefs/2026-10-01-x.md A .github/w.yml: not an allowed path form (...; no part starting .git)
path docs/working/briefs/2026-10-01-x.md M docs/working/briefs/2026-10-01-x.md
path docs/working/briefs/2026-10-01-x.md A ok.txt
deny docs/working/briefs/2026-10-01-x.md A ?: not an allowed path form (...)
```

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `path BRIEF S PATH` | output line | `ok BRIEF TIP TREE`, `ok BRIEF STATE POLICY ...` | `scripts/build-loop.sh:94`, `:51` | Consistent: type word, then fixed fields, with no colon |
| `deny BRIEF S PATH: WHY` | output line | `refuse BRIEF: WHY`, `skip BRIEF: WHY` | `:101`, `:112`, `:69` | Consistent: fields, then a colon, then prose. PATH has no blank or colon (NAMECHARS, or `?`), so field positions hold |
| `refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)` | refuse reason | `the tip of $br is $sha, not the expected $EXPECT` | `:590` | Consistent (ids in prose; settled row) |
| `refuse BRIEF: the paths the merge of BR changes could not be listed / read / lower-cased` | refuse reasons | `the merge of $br could not be computed` | `:595` (on main as `:488`) | Consistent with the gate's own precedent. See Finding 4 on the plan's skip/refuse rule |
| `refuse BRIEF: the merge of BR names a blob the object store lacks` | refuse reason | as above | `:595` | Consistent |
| `refuse state default-branch: ...` (two texts) | state line | `refuse state origin/HEAD: ...`, `refuse state refs/replace: ...` | `:232`, `:229` | Consistent shape. Two WHATs exist for origin/HEAD findings (`origin/HEAD`, `default-branch`); offered as optional in i1 and not re-flagged |
| `refuse state gate: its merge repository could not be set up` | state line | the `state_gate` lines | `:216-232` | Consistent shape. Placement in the help is Finding 2 |
| `default_gate` | internal function | `state_gate`, `gate_repo`, `gate_git` | `:213`, `:497`, `:510` | Consistent `<noun>_gate`, and named in plan `:207` for U3b |
| deny WHYs (path form, mode, own brief, cycle file, constraints doc) | deny reasons | `--settings` glob rule, lib pathform comment | `:28-31`; `scripts/lib/dev-cycle-read.sh:172-184` | Consistent fixed strings. Tests pin them exactly (`NFORM`, `NMODE`, `NBRIEF`) |

## Findings

#### 1. Plan `--check` interface line omits the K-of-N verdict's "in the merge of TIP (tree TREE)"

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:212`; code `scripts/build-loop.sh:626`
**Move:** 3 (documentation drift: the planned interface)
**Confidence:** High (fact-check: Stale)
**Legibility-target:** plan interface line `:212`, which U3's `--merge` and D4's merge entry will be built to

Evidence (plan):
```
U2b1b (built): the verdict line comes first (`ok BRIEF TIP TREE`, or `refuse BRIEF: K of N changed paths refused`), then `path BRIEF S PATH` or `deny BRIEF S PATH: WHY` per changed path; exit 0 only when every verdict line is ok.
```
Code (`check_line`, `:579-628`; the line is printed at `:626`, followed by the rows at `:627`):
```
  if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
```
iteration 1's api 1 (rubric C4) added TIP and TREE so that D4/F48's entry pins TIP. The help (`:110-111`) and the tests' `nref` helper carry them, but the plan line a U3 builder reads does not. A `--merge` written from `:212` that matches the verdict exactly, or an entry template that expects the line to end at "refused", would miss them. Nothing consumes the line yet, so this is honest-path doc drift.

**Recommendation:** Amend `:212` to read `refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)`.

#### 2. Help: "refuse state gate" is not printed "before any brief is read", and a failed `mktemp` exits 1 with no line

**Severity:** Minor
**Location:** `scripts/build-loop.sh:90-92` (help), `:137-139` (Exit), `:640-643` (code)
**Move:** 3 (documentation drift), 4 (error/exit consistency)
**Confidence:** High (fact-check: Mostly accurate, r1-r3)
**Legibility-target:** the help's state-gate paragraph and Exit line, which U3's `--merge` and the D6 snippet use to tell a caller error (1) from a refusal (2)

Evidence (help):
```
#             Each finding prints "refuse state WHAT: WHY" and exits 2 before
#             any brief is read ("refuse state gate: WHY" when the gate's own
#             merge repository cannot be set up). Then, per brief path, in
```
```
# Exit: 0 every line printed (or help), and for --check every verdict line ok;
# 2 any --check verdict line or the state gate not ok; 1 bad usage, not a git
# repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name.
```
Code (the `check` arm, `:639-650`):
```
    read_settings
    open_shared  # once, in this shell: check_line runs in a subshell
    GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
    gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
```
`state_gate` and `default_gate` do print before any brief is read (`:257`, `:260`). The `gate` line, though, comes after `read_settings` and `open_shared` have read main's settings and briefs. A failed `mktemp -d` stops the script under `set -e` with status 1 and no line, which the Exit line attributes only to bad usage, no repo, no perl/lib or no default branch. Both fail closed. The cost is legibility: a consumer that reads exit 1 as "my invocation was wrong" gets a silent environment failure.

**Recommendation:** In the help, move the parenthesis after "exits 2" to its own sentence ("... after the briefs on main are listed"). Either add "or no temporary directory" to the Exit line's 1, or print `refuse state gate: no temporary directory` and exit 2 to match the sibling line.

#### 3. D4's merge entry flags S-rule hits from `--check`'s output, but `--check` applies the S rules only under self-merge, and its per-path vocabulary has no non-refusing flag

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:59` vs `:212`; `scripts/build-loop.sh:119-120`
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** the plan's D4 and `--check` lines, which U2c (the S rules) extends

Evidence (D4):
```
Otherwise it files one merge entry, `### Q-NNN · merge-<stem>-<first 12 of TIP>`. The entry body is `--check`'s output: the full 40-hex TIP, every changed path, and each S-rule refusal flagged (for example "changes CLAUDE.md") (F48).
```
and (`:212`):
```
- `--check BRIEF… [--expect SHA]` → D7, the N rules, and the S rules when the stricter policy is self-merge.
```
The merge entry D4 describes is filed only under `review`. Under `review`, though, `--check` does not apply the S rules, so its output has nothing to flag. The line types this unit fixes give U2c two choices: `deny`, which also makes the verdict a refusal and exit 2, or `path`, which carries no flag. The contract is therefore not yet extensible for D4's case without a third line type or a policy switch. This is not a defect in U2b1b, which correctly applies only the N rules, but the per-path vocabulary is being settled now.

**Recommendation:** Before U2c, decide in the plan whether `--check` under `review` prints S-rule hits as a distinct non-refusing line (for example `flag BRIEF S PATH: WHY`, leaving the verdict ok) or whether the orchestrator gets them some other way. Then amend D4 and `:212` to match.

#### 4. The gate reports read failures as `refuse`, while the plan's stated convention reserves `skip` for unreadable

**Severity:** Informational
**Location:** `scripts/build-loop.sh:595, :600, :604, :609, :617, :620`; `docs/working/plan-build-loop-handoff.md:195`
**Move:** 4 (error consistency)
**Confidence:** Medium
**Legibility-target:** plan `:193-198` (the output convention U3 and the D6 snippet follow)

Evidence (plan):
```
- `skip X: why` means unreadable; `refuse X: why` is a verdict;
```
Code (excerpts from `check_line`, `:579-628`):
```
    *) echo "refuse $a: the merge of $br could not be computed"; return ;;
...
    echo "refuse $a: the paths the merge of $br changes could not be listed"; return
...
  if ! nul_list lps lower_all "${ps[@]}" || [[ ${#lps[@]} -ne ${#ps[@]} ]]; then echo "refuse $a: the paths the merge of $br changes could not be lower-cased"; return; fi
```
U2b1a set this precedent ("could not be computed" is a `refuse` on main, `:488`), and U2b1b extends it to five more read failures. Failing closed as a verdict suits a gate, and exit 2 is the same either way. Under D4, however, a self-merge `--check` refusal "falls through to review, with the refusal quoted in the entry". A transient read failure would therefore become a merge entry asking the user to approve a merge that `--merge` will then refuse again. The plan states the convention without the gate's exception.

**Recommendation:** Either add one line to `plan:195` ("the gate reports a merge it could not compute or list as `refuse`, failing closed") or have D4 skip filing an entry for these reasons. No code change is needed for U2b1b.

#### 5. One help line runs to 94 columns

**Severity:** Informational
**Location:** `scripts/build-loop.sh:122`
**Move:** 3 (documentation)
**Confidence:** High
**Legibility-target:** `--help` output

Evidence:
```
#                 (a part starting .git, any case: .github/); a mode other than 100644 or 100755
```
e02d056b's rewording made this the only help line over 80 columns (probe: `--help | awk 'length > 80'` prints only rendered line 121, length 94). Every other help line wraps near 80.

**Recommendation:** Rewrap when the help is next touched.

## What Looks Good

- **One line grammar for the whole mode.** The verdict comes first, `path`/`deny` rows follow in diff-tree order, and every row repeats BRIEF, so multi-brief output can be split by line alone. The exit test (`:647`, first line `ok `) matches the help's "every verdict line ok", which closes the U2b1a row on exit status.
- **Unprintable paths never leak, and `?` appears only on deny rows.** `shown` is the real path only when every character is in NAMECHARS. A path outside NAMECHARS fails pathform, so a `?` can only appear on a refused verdict. A D4 entry therefore never needs to approve a path it cannot show.
- **The refusal family is closed and fixed-string.** Every refusal text in the help matches the code byte for byte at HEAD, and each is a single line with no rows except the K-of-N one, which the help says.
- **`default_gate` follows `state_gate`'s contract** and is named in the plan's `--state` line, so U3b's `--state` and `--check` will print the same state lines.
- **The iteration-1 and -2 api findings are all closed** (C4, C5, D3 and plan D2) with no regressions.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Plan `--check` line omits "in the merge of TIP (tree TREE)" | Minor | `docs/working/plan-build-loop-handoff.md:212` | High |
| 2 | Help: the `gate` state line prints after briefs are read; mktemp failure exits 1 silently, not in Exit | Minor | `scripts/build-loop.sh:90-92, :137-139, :642` | High |
| 3 | D4 flags S-rule hits from `--check`, which applies none under review and has no flag line | Informational | `docs/working/plan-build-loop-handoff.md:59, :212` | Medium |
| 4 | Read failures are `refuse`; the plan reserves `skip` for unreadable | Informational | `scripts/build-loop.sh:595-620`; plan `:195` | Medium |
| 5 | Help line at 94 columns | Informational | `scripts/build-loop.sh:122` | High |

## Overall Assessment

`--check`'s output contract is consistent with the script's other modes and with dev-cycle.sh's line grammar. The help matches the code for every verdict, row and refusal text, the exit status follows the help, and all earlier api findings are fixed. What remains is two Minor text drifts (the plan's verdict line and two help details) and three Informational notes. Two of those notes, the S-rule flag line and skip vs refuse, belong to U2c's and U3's design rather than to this unit. Nothing consumes `--check` until U3, so the consumer impact is nil today. Each Minor item is a one-line edit.

## Goal-Alignment Note

The goal is to land U2b1b after a clean review-fix loop. From the API side the branch is landable: no Breaking or Inconsistent findings, two Minor and three Informational, all text or plan-level. Finding 1 is the one to fix or route before landing, because it is the plan line U3's `--merge` and D4's entry template will be built from. Finding 3 should be routed to U2c's brief rather than fixed here.
