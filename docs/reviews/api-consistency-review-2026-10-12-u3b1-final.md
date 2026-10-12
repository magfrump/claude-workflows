# API Consistency Review — feat/build-loop-u3b1 (U3b1, final confirming pass)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-build-loop-u3b1` (HEAD 5e816c5b): `scripts/build-loop.sh`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-merge.bats` (one case), `docs/working/plan-build-loop-handoff.md` (step 9's U3b1 note), override-log rows dated 2026-10-12
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-u3b1-final.md` (k=3 merge: 0 behavioural Incorrect; text clusters 1-7, cited as `FC n`); iteration 1's `api-consistency-review-2026-10-12-u3b1-i1.md` (cited as `i1 n`); rubric `code-review-rubric-2026-10-12-feat-build-loop-u3b1.md` (B1-B21, C1-C5)

The public surface is the same as in iteration 1:
- `build-loop.sh`'s CLI modes `--marker BRIEF` and `--state`, with their output lines and exit codes;
- the header documentation that `--help` prints;
- the loop prompt's blocked-body sentence, built from `BODY_RULE`, `BODY_LINES`, `BODY_BYTES` and `MARKER_MAX`;
- the plan's "Script interface" bullets and step 9's U3b1 as-built note, which U4 will be written from.

Since iteration 1, the changes that touch this surface are the new skip causes (the 64 KiB cap, `<!--`, strict UTF-8), the reworded caller-pair refusal, `BODY_RULE`'s fuller text, the default_gate check on the ref's own type, and the as-built note. Probes (prefix `/tmp/u3b1fapi-`, one throwaway repo, removed afterwards) confirmed these:
- `--state` prints `ok` with exit 0 from the top level and from a subdirectory;
- `--marker` prints `ok BRIEF SHA` plus quoted lines with exit 0 from both places, and exits 0 on a rule skip;
- the rule skip line embeds the full `BODY_RULE`;
- a caller pair equal to harden's own (`core.hooksPath=/dev/null` by GIT_CONFIG_COUNT) is refused, exit 2 (the deferred B9, as documented);
- a CRLF marker subject gets `--status`'s "not a marker" skip, so `--marker` and `--status` agree.

## Baseline Conventions

These are unchanged from i1 and re-checked against HEAD:
- **Mode names.** Modes are `--noun` flags whose arity is checked in the `case` arm. A bad arity calls `usage "--MODE takes …"`, which exits 1 with the usage line on stderr (`scripts/build-loop.sh:399-406`).
- **Line grammar.** `ok BRIEF FIELDS…` is an answer or verdict. `skip BRIEF: WHY` is a read mode declining. `refuse BRIEF: WHY` is a verdict. `refuse state WHAT: WHY` is a state-gate finding, where WHAT is a git path, a lowercased config key or a hyphenated tag, and the source of the problem goes in WHY.
- **Payloads.** A multi-line payload may follow an `ok` line, as `--start`/`--prompt` print the prompt after `ok …` and `dispatched N`.
- **Exit codes.** Read modes exit 0 when every argument was answered, a skip included. Deciding modes and the state gate exit 2 on any refusal. Exit 1 means usage or startup failure, with no stdout line. Any exit but 0 means "nothing decided" (`:375-385`).
- **Shared constants and helpers.** Constants are upper-case globals (`STATE_KEYS_RE`, `FENCE_AWK`, `GATE_ENV`). Helpers are lower-case (`callervar`, `oddwhy`, `status_fields`). Checks that print `refuse state` lines are named `*_gate`, and startup sequences `*_start`.
- **Plan as-built notes.** A unit's note says it "supersedes" Script-interface bullets where they differ (U3d precedent, plan step 9).

## Name-Pattern Audit

The new names were all audited in i1, and those rows still hold. The rows below cover the names and lines that are new since i1, plus the two modes, re-checked at HEAD.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--marker BRIEF` | CLI mode | `--status BRIEF...`, `--start BRIEF`, `--prompt BRIEF` | `scripts/build-loop.sh:399-406` | Consistent (i1 audit stands) |
| `--state` | CLI mode | `--settings` (no args), `--check` | `scripts/build-loop.sh:402,405` | Consistent (i1 audit stands) |
| `skip BRIEF: its marker is N bytes, over the 65536-byte cap` | output line | `--status` skips (`skip BRIEF: its first Dispatched: line is not exactly …`) | `scripts/build-loop.sh:771-795` | Consistent: `skip BRIEF: <reason naming the limit>` |
| `skip BRIEF: a line of its marker's body breaks the blocked-body rule (BODY_RULE): line N` | output line | FENCE skip `skip BRIEF: line N of its marker's body …` | `scripts/build-loop.sh:855,864` | Consistent; it now carries the whole rule the check applies (i1 3 resolved) |
| `refuse state KEY: set by the caller's git -c or GIT_CONFIG_COUNT pairs, a key the state gate refuses or one the gate's own hardening sets (a git -c pair wins over it)` | refusal WHY | `refuse state KEY: set in config, it can make …` | `scripts/build-loop.sh:493` | Consistent: the source goes in WHY, and the reason is now true for both sources (i1 2 resolved) |
| `HARDEN` | shared array | `GATE_ENV`, `STATE_KEYS_RE` | `scripts/build-loop.sh:455`, `:883` | Consistent (upper-case shared global) |
| `stray_vars` | helper | `callervar`, `status_fields`, `oddwhy` | `scripts/build-loop.sh:513` | Consistent (lower-case helper; the script mixes run-on and snake_case, and this picks snake) |
| `MARKER_MAX` | constant | `BODY_LINES`, `BODY_BYTES` | `scripts/build-loop.sh:810` | Consistent enough: same prefix family, internal, read only through the prompt text ("a commit over 65536 bytes is skipped") |

## Iteration-1 findings: disposition at HEAD

| i1 | Finding | Rubric | At HEAD |
|---|---|---|---|
| 1 | land's re-run reports a moved main as a non-commit | B4 | **Resolved.** `:564-565` checks `cat-file -t` of the ref's own value. Merge-suite case `build-loop-merge.bats:60-63` pins the compare-and-swap reason (mutant killed, C3). |
| 2 | Caller-pair WHY claimed a COUNT pair overrides harden | B10 | **Resolved.** The line now reads "a key the state gate refuses or one the gate's own hardening sets (a git -c pair wins over it)" (`:542`), and the test's `K` matches (`orchestrator.bats:44`). |
| 3 | BODY_RULE omitted case-insensitivity and list markers; the cap read as hard | B10 | **Resolved.** `BODY_RULE` (`:807`) names the list markers and "in any case"; the prompt says "(longer is cut; a commit over $MARKER_MAX bytes is skipped)" (`:1538`). |
| 4 | Plan's `--state` interface bullet stale | B7 | **Resolved** by the as-built note's "supersedes the 'Script interface' `--marker` and `--state` bullets where they differ" (plan `:324`), as U3d did. |
| 5 | Two caller plantings exit 1, no `refuse state` line | B6 | **Resolved as documented** (header `:124-126`, plan `:324`). The list is not exhaustive, though: see Finding 1. |
| 6 | Bare `ok` from `--state` | B13 | Settled by Won't-Fix row (override-log, 2026-10-12, first U3b1 row). The code is unchanged under it. |
| 7 | One `skip` shape for three causes | B14 | Settled by Defer row, revisit at U4's collect step. The code is unchanged in kind; the three new causes also use `skip`, which stays inside the row's scope. |
| 8 | "Only --state" pinned on ungated `--settings` | B11 | **Resolved.** A gated `--check` case was added (`orchestrator.bats:56-60`). |

## Findings

#### 1. `--state`'s documented exit-1 causes read as a closed list; U4 should be told "any exit but 0 or 2"

**Severity:** Minor
**Location:** `scripts/build-loop.sh:124-126`; `docs/working/plan-build-loop-handoff.md:324` (as-built note)
**Move:** 3 (consumer contract: documentation the U4 author writes from) / 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```bash
# scripts/build-loop.sh:124-126
#             and it is a snapshot. Exit 1 (stderr only) for a caller's
#             GIT_CONFIG_COUNT that is not plain decimal, or a GIT_DIR
#             naming no repository. First, read only here, the
```
```markdown
<!-- docs/working/plan-build-loop-handoff.md:324 (as-built note, excerpt; the note continues) -->
`--state` exits 1 (stderr only) for a non-decimal GIT_CONFIG_COUNT or a GIT_DIR naming no repository,
```
FC 3 (Mostly accurate, r1 and r3, executed) found more exit-1 cases. Each prints only to stderr, and all fail closed:
- a GIT_CONFIG_COUNT that names an unset key, or a huge count;
- a malformed GIT_CONFIG_PARAMETERS;
- a GIT_WORK_TREE naming a missing directory;
- a GIT_COMMON_DIR or GIT_OBJECT_DIRECTORY naming nothing.

The general Exit paragraph (`:375-385`) says "a caller reads any exit but 0 as nothing decided", but only in the sentence about `--check`/`--merge` stopping part way. The `--state` paragraph and the as-built note, which supersedes the Script-interface bullet, name two causes as if they were all of them. Nothing breaks today: there is no consumer yet, and every case fails closed. The risk is that the U4 skill, written from the note, branches on `ok`/exit 2 and on "these two causes" and has no rule for the others.

**Recommendation:** In both places, say "exit 1 (stderr only) when the caller's environment stops git or the script before any line (for example …)", and state the U4 rule: any exit but 0 or 2 means stop and quote stderr. This is a text change only.

#### 2. "The questions readers anchor at column 0" leaves out questions.sh's index-summary reader, which takes a quoted line as the summary

**Severity:** Informational
**Location:** `scripts/build-loop.sh:816-818` (marker's comment); `scripts/questions.sh:183-184`; `test/scripts/build-loop-orchestrator.bats:147-157` (T34 fixture)
**Move:** 3 (consumer contract) / 8 (when a field is absent: the entry has no prose line of its own)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```bash
# scripts/build-loop.sh:816-818
# The orchestrator files the body inside an entry it heads itself: the
# questions readers anchor at column 0, so a quoted line is never read as a
# heading, a Needs line or an answer (E2, E3). A body line breaking BODY_RULE
```
```awk
# scripts/questions.sh:183-184 (the summary block continues to :201)
        # First prose line after the header pair becomes the index summary.
        want_summary && status != "" && /[^[:space:]]/ && !/^\*\*/ && !/^###/ && !/^</ {
```
The comment's claim holds for what it lists: heading, Needs line and answer. ANSWER_AWK, extract_entry and parse_entries match those only at column 0. The summary reader, though, excludes lines starting `**`, `###` and `<`, but not lines starting `>`. If the orchestrator pastes `--marker`'s lines directly under the header pair, the first quoted line becomes the entry's index summary. That puts loop-written text, which may hold `|` characters, in the index table cell rendered from `| [%s](#…) | … |` (`questions.sh:326-333`). The T34 fixture builds exactly that shape: a header pair followed straight away by quoted lines. The fact-check also escalated this (FC Escalations, r3). It is not an answer or grammar risk, since index rows start with `| `, which no column-0 reader matches. It is a contract the U4 author needs: the orchestrator's own one-line question must come before the pasted body. The questions-entry template already puts "the question in one line" first.

**Recommendation:** No code change. Optionally widen the comment to "never read as a heading, a Needs line or an answer (the index summary is the entry's first prose line, so the orchestrator writes its own first)". Carry the ordering rule into U4's collect step, together with the existing B14/B17 Defer rows.

## What Looks Good

- **Every i1 finding is closed in code or text, or settled by a row whose code is unchanged.** No regression appeared in the fix iterations.
- **One rule string.** `BODY_RULE` now matches the perl check clause for clause: the list markers, "in any case", `<!--` and strict UTF-8. The prompt (`:1538`), the skip line (`:855`), the help (`:107-118`) and the suite's `RULE` (`orchestrator.bats:20`) all spell it the same way. The producer and the checker cannot drift.
- **The prompt states the caps as `--marker` applies them.** It says "longer is cut" for the 100×300 limit and "skipped" for a commit over `MARKER_MAX`, built from the same constants the code uses.
- **The `skip` lines follow the read-mode precedent.** Each new cause (the size cap, `<!--`, UTF-8) prints `skip BRIEF: WHY` with exit 0. The probe confirmed exit 0 on a rule skip and on `ok`.
- **The default_gate change is narrower and correctly placed.** It checks the ref's own object type, so `--merge`'s existing "the default branch moved after the check" refusal is preserved and pinned (`build-loop-merge.bats:60-63`). Only an annotated tag reaches the new line (FC 5).
- **The shared helpers have neutral names.** `HARDEN` and `stray_vars` remove three copies of the same knowledge without changing any output line. checkout_gate's WHY text is unchanged.
- **The plan note follows the U3d precedent**, including the "supersedes … where they differ" pointer, and it now says plainly that rows 493/494/517 close only once U4 starts each iteration with `--state` (FC 6).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--state`'s exit-1 causes documented as a closed list | Minor | `scripts/build-loop.sh:124-126`; plan `:324` | High |
| 2 | "Readers anchor at column 0" omits the index-summary reader | Informational | `scripts/build-loop.sh:816-818`; `scripts/questions.sh:183-184` | High |

Fact-check text clusters that touch this surface are owned by the fact-check and not re-filed here:
- FC 4: "as written" covers only the printed 100 lines;
- FC 5: "anything but a commit" is reachable only by a tag;
- FC 1 and FC 2: commit-body corrections owed in the merge message.

## Overall Assessment

U3b1's public surface is consistent with build-loop.sh's established conventions:
- the mode names and usage text match their neighbours;
- the `ok`/`skip`/`refuse state` grammar holds;
- exit codes follow the read/decide split;
- the payload after `ok` follows the `--start`/`--prompt` shape.

The one change to an existing mode's output (i1 1, `--merge`'s moved-main reason) is fixed and pinned. Both remaining findings are about the documentation U4 will be written from, not about behaviour. Finding 1 is a one-sentence widening in the header and the plan note. Finding 2 is an ordering rule for U4's collect step. Neither blocks the merge. No existing consumer is affected: nothing in the repository calls `--state` or `--marker` yet, and the every-mode GIT_CONFIG_COUNT refusal narrows input only for a count that git and bash would read differently.

## Goal-Alignment Note

- **Success criterion:** "A markdown report saved to /workspace/.claude/wt-build-loop-u3b1/docs/reviews/api-consistency-review-2026-10-12-u3b1-final.md, structured per the api-consistency-reviewer skill."
- **Answered:** yes. The report covers the full branch against main. It follows the skill's sections (Baseline, Name-Pattern Audit, Findings, What Looks Good, Summary, Overall), and each i1 finding has a disposition.
- **Goal served:** U3b1 can land after a clean loop. This pass finds no Breaking or Inconsistent issue on the surface, and no 🔴 or 🟡 candidate. Finding 1 is a 🟢 text fix that could ride along with the merge's commit-body corrections. Finding 2 belongs with the U4 Defer rows (B14, B17).
- **Out of scope:** behaviour outside the consumer contract (owned by security and fact-check), and pre-existing modes except where this diff changes them.
- **Escalate:** none beyond the fact-check's questions.sh:184 escalation, which Finding 2 restates from the contract side.
