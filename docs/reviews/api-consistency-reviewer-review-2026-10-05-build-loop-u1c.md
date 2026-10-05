Commit: 553a50d5

# API Consistency Review — feat/build-loop-u1c (constraints line and --status)

**Scope:** `git diff feat/build-loop-u1b...feat/build-loop-u1c` (commits 859e29e8, aaae80c6, 553a50d5); public surface of `scripts/build-loop.sh`
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1c.md (Stage 1, k=1); shared-stage2.md; plan rev 4 (docs/working/plan-build-loop-handoff.md, "Script interface" and "Brief machine lines")

## Baseline Conventions

Read: `scripts/dev-cycle.sh:1-115,185-205` (check modes, usage, help), `scripts/build-loop.sh` at HEAD in full, the plan's output conventions (`docs/working/plan-build-loop-handoff.md:196-243`), and override-log rows dated 2026-10-05.

- **Line grammar.** Per-argument read modes print `ok ARG FIELDS…`, `absent ARG` or `skip ARG: WHY` (dev-cycle.sh `--check-brief`, `--check-branch`, `--check-path`). Fields are space-separated. Free text comes only after the first `: `, or as the last field. The plan says `skip X: why` means unreadable and `refuse X: why` is a verdict (plan :196).
- **Settings lines.** `KEY VALUE STATUS: WHY`, one line per key, in a fixed order (U1b). The status word is fixed by the plan per key. Settled: the never line's status-word position (override-log row 245).
- **Exit codes.** Read modes exit 0 when every argument was answered (a skip is an answer). Usage errors, no repo and no default branch exit 1 (dev-cycle.sh:79-81, build-loop.sh:66-67).
- **Usage errors.** `MODE needs at least one argument` and `Unknown option: X` go to stderr and exit 1 (dev-cycle.sh:108-112). build-loop.sh's `usage()` appends `(usage: …)`.
- **Fail-closed reading.** A file the reader cannot trust is reported, never half-read. The settings reader also catches near-miss copies of a key (letters only, case folded) "so markup, a table or a misplaced colon cannot hide one" (build-loop.sh:33-35).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--status BRIEF...` | CLI mode | `--check-brief PATH...`, `--check-branch NAME...`, `--settings` | `scripts/dev-cycle.sh:11-12,107-109`; `scripts/build-loop.sh:85` | Consistent. Variadic, one line per argument in argument order, exit 0. Matches the plan's name (plan :205). |
| `ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]` | output line | `ok <name> <commit> <n> <YYYY-MM-DD>` (--check-branch), `ok <path> open\|done\|dropped <commit>` (--check-brief) | `scripts/dev-cycle.sh:29-47` | Consistent. Field order is the plan's (plan :205), `-` stands for absent values, and the free-text REASON comes last. |
| `skip BRIEF: WHY` | output line | `skip <path>: <reason>` | `scripts/dev-cycle.sh:24,36,45` | Consistent. check_brief's skip lines pass through verbatim (`build-loop.sh:299`). For branch refusals the code prefixes the inner reason with `Branch: ` (`:319`), which keeps the BRIEF key. The help's list of skip causes has errors (F2, F3). |
| STATE `new` | enum value | `ok <path> new` | `scripts/dev-cycle.sh:30` | Consistent. Same word and meaning as --check-brief. |
| LOOP `absent\|working\|ready\|blocked\|stopped` | enum | `absent <name>` (--check-branch) | `scripts/dev-cycle.sh:45`; plan :205 | Consistent. These are exactly the plan's values. |
| `constraints ok N-hard M-soft\|missing\|none-hard\|unreadable: WHY` | settings line | `policy … set\|unset`, `slots N set\|default`, `never … set\|none\|malformed` | `scripts/build-loop.sh:14-25`; plan :204 | Consistent with the plan's fixed vocabulary. It uses `unreadable` where the never line says `malformed` for a grammar error (Informational, F6). |
| `--status needs at least one brief path` | usage message | `$CHECK needs at least one argument` | `scripts/dev-cycle.sh:109` | Consistent. Same shape, with a more specific noun, routed through `usage()` like U1b's `--settings takes no arguments`. |

## Findings

#### F1. A hard constraint written in a near-miss shape is silently dropped, and the dispatch gate still reads `constraints ok`

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:152`, `scripts/build-loop.sh:160` (contract text `:28-32`)
**Move:** 4 (error consistency) / 7 (asymmetry)
**Confidence:** High
**Legibility-target:** orchestrator (U3/U4 gate dispatch on this line) and the user writing docs/constraints.md

Evidence (`scripts/build-loop.sh:152`, excerpt of CONSTRAINTS_AWK, which runs from `:149` to `:168`; the rest was read):
```
/^(- )?[HS][0123456789]+: [^ \t]/ {
```
Evidence (`scripts/build-loop.sh:160`):
```
/^[ \t]*(- )?success: [^ \t]/ { pend = "" }
```
Evidence (`scripts/build-loop.sh:32-35`):
```
#                 repeat. Only "ok" lets the orchestrator dispatch.
#             A line counts as a copy when its letters alone, case folded,
#             start with the key's ("buildlooppolicy"), so markup, a table or
#             a misplaced colon cannot hide one.
```

Probe (scratch repo, HEAD script). A file with `- H1: a` / `  success: b` followed by `* H2: no deps`, `H3:<TAB>tab`, `  H4: indented`, `h5: lower`, `1. H6: num`, `> H7: quote`, `**H9**: bold` and `H10 : sp`, none of which has a success: line, prints `constraints ok 1-hard 0-soft: docs/constraints.md on the default branch`. The same script's settings reader refuses near-miss copies of a key, so markup cannot hide one (`:33-35`). The constraints reader instead ignores them, and ignoring them fails open on the line that gates dispatch (`:32`, plan D2/F55). The success: rule is the reverse: `- H1: a` / `* success: b` reads `unreadable: hard constraint H1 (line 1) has no success: line` (fails closed). The same markup is therefore ignored before a constraint ID but enforced before `success:`. All of these lines still reach the loop prompt as text (plan :227), so nothing is hidden from the loop. What breaks is the N-hard count and the requirement that every hard constraint carries a success line. The fact-check escalated this (Claim 2).

**Recommendation:** Apply the settings reader's rule. Match a candidate constraint line loosely: optional blanks, any list or quote marker, emphasis, a case-folded `[hs]<digits>` and an optional blank before the colon. Report anything that matches loosely but not exactly as `constraints unreadable: line N looks like a constraint but is not exactly "H<n>: text"`. Add these shapes to T44.

#### F2. The --status skip contract says a missing `Dispatched:` line is a skip; the code and the ok-line text say it reads 0

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:55-57` (vs `:53-54`, `:306`)
**Move:** 3 (consumer contract, documentation drift)
**Confidence:** High
**Legibility-target:** U2/U3/U4 authors who parse --status from its help text

Evidence (`scripts/build-loop.sh:55-57`):
```
#             skip BRIEF: WHY
#                 The brief cannot be read (as --check-brief), its Branch: or
#                 Dispatched: line is missing or malformed, its branch name is
```
Evidence (`scripts/build-loop.sh:53-54`):
```
#                 working. DISPATCHED: the brief's "Dispatched: N" (0-99), or
#                 0 without one.
```
Evidence (`scripts/build-loop.sh:306`, excerpt of status_line, which runs from `:296` to `:331`; the rest was read):
```
  if [[ -n "${BRIEF[dispatched]+set}" ]]; then
```

The help text contradicts itself, and the skip list is the wrong half: T5/T6 assert `0` when the line is absent. A consumer reading `:56-57` would expect a skip and could treat a brief that was never dispatched as unreadable. The Dispatched line is optional (the orchestrator writes it after the first `--start`, plan :218), so the code's behaviour is the right contract. Fact-check Claim 12b, Incorrect.

**Recommendation:** Change `:56-57` to "its Branch: line is missing or malformed, its Dispatched: line is malformed, …".

#### F3. F31's same-branch skip counts only briefs directly under `briefs/`, although --status accepts and reports `closed/` briefs as open

**Severity:** Minor
**Location:** `scripts/build-loop.sh:287` (contract text `:58-59`)
**Move:** 7 (asymmetry)
**Confidence:** Medium (impact depends on whether U4 ever passes closed/ paths; plan step 6 moves only done/dropped briefs there)
**Legibility-target:** U2's `--check` (plan F31: "--status/--check skip both") and the orchestrator

Evidence (`scripts/build-loop.sh:287`, excerpt of shared_branches, which runs from `:284` to `:295`; the rest was read):
```
  list="$(git ls-tree --full-tree --name-only "$MAIN_SHA" -- docs/working/briefs/)"
```
Evidence (`scripts/build-loop.sh:58-59`):
```
#                 refused (as --check-branch), another open brief on main
#                 names the same branch (ignoring case), or the tip's subject
```

Probe: main has `briefs/2026-10-01-a.md` and `briefs/closed/2026-10-01-b.md`, both `Status: open` and `Branch: feat/x`. `--status` on both prints two `ok … open review feat/x absent - - 0` lines. Read literally, the help says both should skip. The input set (`ls-tree` without `-r`) and the accepted argument set (check_brief takes `briefs/[closed/]`, dev-cycle.sh:29) differ, and only the code shows it. Fact-check Claims 13/22/45.

**Recommendation:** Either list `briefs/closed/` too (add `-r` and filter with `isbrief`), or narrow the help to "another open brief directly under docs/working/briefs/". Do the same in U2's `--check` so the two modes agree.

#### F4. Settings help: the "copy" rule now sits after the constraints entry and reads as if it governs constraints

**Severity:** Minor
**Location:** `scripts/build-loop.sh:26-35`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a reader of `--help`

Evidence (`scripts/build-loop.sh:31-35`):
```
#                 after "- ") before the next constraint, and no ID may
#                 repeat. Only "ok" lets the orchestrator dispatch.
#             A line counts as a copy when its letters alone, case folded,
#             start with the key's ("buildlooppolicy"), so markup, a table or
#             a misplaced colon cannot hide one.
```

In U1b this paragraph closed the three dev-cycle.md keys that `:11-13` introduces ("Lines 1-3 … a second copy … leaves the default"). Inserting the constraints entry at `:26-32` leaves it after constraints. The constraints reader uses neither the copy rule nor "leaves the default": it uses ID repetition and fails to `unreadable`. A reader can therefore assume, wrongly, that near-miss constraint lines are caught (see F1).

**Recommendation:** Move `:33-35` up to follow `:25` (the end of the never entry), or begin it with "For lines 1-3, …". The --help range (`2,67p`) does not change.

#### F5. Constraint IDs are compared as written: `H1` and `H01` are two constraints

**Severity:** Minor
**Location:** `scripts/build-loop.sh:153-156`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** the user writing docs/constraints.md; the DD seeding that cites IDs

Evidence (`scripts/build-loop.sh:155-156`):
```
  if (bad == "" && (id in seen)) bad = "dup " id " " seen[id] " " NR
  if (!(id in seen)) seen[id] = NR
```

Probe: `- H1: a` / `  success: b` / `H01: z` / `  success: y` reads `constraints ok 2-hard`. The contract "no ID may repeat" (`:31-32`) passes, yet loops and the drift check (plan D2 :51) cite constraints by ID, and `H1`/`H01` read as the same one. Other numeric fields in this script refuse leading zeros (`Dispatched: 01` and `Build-loop slots: 05` are malformed, `:307`, `:234`).

**Recommendation:** Add a leading-zero rule to the constraint regex (`[HS](0|[1-9][0-9]*)`), so `H01` fails closed once F1's near-miss handling exists, or compare IDs numerically.

#### F6. `constraints unreadable` covers both a file not read and a well-formed file that breaks the grammar; the never line calls the latter `malformed`

**Severity:** Informational
**Location:** `scripts/build-loop.sh:246-247`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** the orchestrator's `you: judgment` entry text (plan step 10)

Evidence (`scripts/build-loop.sh:246-247`, excerpt of read_settings, which runs from `:185` to `:250`; the rest was read):
```
      nosuccess) CONSTRAINTS_LINE="constraints unreadable: hard constraint $c (line $l1) has no success: line before the next constraint" ;;
      *) CONSTRAINTS_LINE="constraints unreadable: constraint $c is listed twice (lines $l1 and $l2)" ;;
```

The plan fixes the four-word vocabulary (plan :204), so this is not a defect. A consumer that branches only on `ok` (the plan's rule) is unaffected. The WHY text already tells the user whether the file was read. Recorded so the U5 docs say which kinds of problem `unreadable` covers. Also, `*)` maps any unexpected awk output to the "listed twice" message. That is unreachable today, but an explicit `dup)` arm with a fail-closed default would keep the message honest if the awk program grows.

**Recommendation:** None for the vocabulary. Optionally make the `*)` arm `dup)` and add a generic `unreadable` fallback.

#### F7. STATE `new` also covers a brief already moved to `closed/`

**Severity:** Informational
**Location:** `scripts/build-loop.sh:301`, `:39-41`
**Move:** 8 (nullability / value semantics)
**Confidence:** Medium
**Legibility-target:** U4's collect step

Evidence (`scripts/build-loop.sh:301`):
```
  if [[ "$st" == new ]]; then echo "ok $a new review - absent - - 0"; return; fi
```

This is inherited from check_brief (dev-cycle.sh:30-31: "not landed, or moved to closed/"), and the settled design choice (shared context "a brief not on main prints new review - absent - - 0") stands. `:39-41` says only "new when main has no file there". U4 should not read `new` as "not dispatched yet" after step 6 moves a brief.

**Recommendation:** Add "(not landed, or moved to closed/)" to `:40`, as --check-brief does.

## What Looks Good

- `--status` follows the sibling per-argument convention: variadic, argument order kept, one line per argument, exit 0 when every argument is answered (one bad argument does not abort the run), and a skip is an answer. Probe: `--status A ./A --settings A` prints four lines and exits 0. A bare `--status` exits 1 with the usage message on stderr. `route: code-fact-check`
- The ok line has exactly the plan's field order and LOOP values (plan :205). Absent values use `-`, never an empty field, so `read -r` keeps its column count. REASON is restricted to printable ASCII with no blank at either end and comes last. `route: code-fact-check`
- check_brief's and check_branch's own skip text passes through, so `--status` and dev-cycle.sh word the same failure the same way. `route: code-fact-check`
- The `constraints` line is fourth, after U1b's three, so readers that take lines 1-3 by position still work. The added test asserts the order. `route: code-fact-check`
- Reading the stopped marker is fail-closed: a marker-looking tip that breaks a rule is a skip, never a sixth LOOP value (settled design choice). `route: code-fact-check`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Near-miss hard constraints dropped; `constraints ok` still printed | Inconsistent | `scripts/build-loop.sh:152,160` | High |
| 2 | Skip contract says missing Dispatched: skips; code reads 0 | Inconsistent | `scripts/build-loop.sh:55-57` | High |
| 3 | F31 counts only briefs/ top level; closed/ open briefs both print ok | Minor | `scripts/build-loop.sh:287` | Medium |
| 4 | Copy-rule paragraph now follows the constraints entry | Minor | `scripts/build-loop.sh:33-35` | High |
| 5 | `H1` and `H01` are distinct IDs | Minor | `scripts/build-loop.sh:155-156` | High |
| 6 | `unreadable` covers grammar errors; `*)` arm defaults to the dup message | Informational | `scripts/build-loop.sh:246-247` | High |
| 7 | STATE `new` also means moved to closed/ | Informational | `scripts/build-loop.sh:301` | Medium |

## Overall Assessment

The new surface matches the plan's interface and the sibling check-mode conventions: line grammar, field order, `-` placeholders, skip passthrough, exit codes and usage messages. U2/U3/U4 can parse it as specified. Two contract problems need fixing before those units build on it. The constraints reader fails open on near-miss hard constraints, which goes against the fail-closed rule the same script applies to settings keys (F1). The help text gives the wrong skip rule for a missing Dispatched: line (F2). Both can be fixed in place: F2 is one line, and F1 is a regex plus a T44 case. F3-F5 are small contract clarifications, and F6-F7 are notes for U5's docs.

## Goal-Alignment Note
- Success criterion (restated verbatim): Your report saved at the path given in your task tail, structured per your skill, with every finding carrying a verbatim Evidence quote at a `path:line` in this worktree.
- Answered: yes. The report is saved with 7 findings, each with verbatim evidence at path:line.
- Out of scope: the setlocale stderr warning at `:277` (performance/fact-check escalation); security exploitability of F1 beyond the contract view.
- Escalate: F1 to security-reviewer as a fail-open on the dispatch gate line, if that critic has not already covered it.
- Questions I would have asked: whether U4 ever passes `briefs/closed/` paths to --status (this sets F3's severity).
- Decisions I made: I treated the plan's fixed vocabularies (`unreadable`, F31 as a `skip`) as settled and filed F6 as Informational only. I did not re-raise the --help fixed range or the never-line status-word position (override-log rows 239, 245).
