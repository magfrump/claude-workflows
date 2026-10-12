# Security Review — feat/build-loop-u3b1 (U3b1: --state and --marker), final confirming pass

**Scope:** full branch `git diff main...HEAD` on `feat/build-loop-u3b1` at 5e816c5b: `scripts/build-loop.sh`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-merge.bats`, plan step 9's U3b1 note, override rows dated 2026-10-12. Read beyond the diff: `scripts/lib/dev-cycle-read.sh` (scrub, FENCE_AWK, ANSWER_AWK, check_answer), `scripts/questions.sh` (parse_entries, extract_entry, cmd_check, render_index, live_without_entry, cmd_archive).
**Date:** 2026-10-12
**Commit:** 5e816c5b564e460e00a688400afcc7a9e84e8e1d
**Based on:** `docs/reviews/code-fact-check-report-u3b1-final.md` (k=3, 0 behavioural Incorrect; its escalation `scripts/questions.sh:184` is taken up as Finding 1), predecessor `docs/reviews/security-review-2026-10-12-u3b1-i1.md`, rubric `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b1.md`.
**Probes:** p1 `/tmp/u3b1fsec-Hixf`, p2 `/tmp/u3b1fsec-112r`, p3 `/tmp/u3b1fsec-ePCX`, one inline (`/tmp/u3b1fsec-*`, newline keys). Scripts are in the session scratchpad under `u3b1fsec/p{1,2,3}.sh`. All temp dirs removed; no background process started. git 2.39.5.

No escalation pattern matched.

## Trust Boundary Map

```
B1: [loop-authored marker commit message]  → [marker(): cat-file -s cap → scrub → BODY_RULE/UTF-8 perl → caps → FENCE_AWK x2 → "> " prefix] → [orchestrator pastes into a questions entry it heads]
B2: [quoted body inside questions.md]      → [ANSWER_AWK/check_answer; questions.sh parse_entries (summary), render_index, check, archive] → [answers, index table, gate decisions]
B3: [caller environment (GIT_*, -c pairs)] → [harden decimal check; caller_gate (stray_vars, command-scope pairs)]            → [--state "ok"]
B4: [repo-local git state planted by a loop] → [state_gate + default_gate + store_check via state_start]                     → [--state "ok"]
B5: [loop-movable refs (main, loop branch)] → [status_fields/marker_kind, ungated in --marker]                              → [ok BRIEF SHA + body]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | Marker commit message (headers and body), loop-authored, may be hand-hashed | request-time | UNTRUSTED for every sink: questions file text, index table, orchestrator LLM context, terminal |
| S2 | Caller environment: GIT_* repo-local vars, GIT_CONFIG_PARAMETERS/COUNT | runtime-mutable (uid's shell rc) | UNTRUSTED toward the state gate's reads (caller_gate's purpose); trusted for exec by design (BASH_ENV/PATH residual, row 705) |
| S3 | Repo-local git state (.git/config, info/*, refs) | runtime-mutable | UNTRUSTED for git reads and exec |
| S4 | `BODY_RULE`, `HARDEN`, `STATE_KEYS_RE`, program text of perl/awk | code-constant | trusted |
| S5 | BRIEF argument | request-time (orchestrator) | checked by check_brief (pre-existing) |

S1 crosses into a file that line-oriented readers parse for answers and that `questions.sh` rewrites; S2/S3 decide `--state`'s `ok`. The diff assumes every questions reader either anchors at column 0 or is kept off the body by the rule; the one reader that is neither (the index summary) is Finding 1.

## Iteration-1 findings: resolution check

| i1 | Disposition claimed | Verified here |
|---|---|---|
| F1 `<!-- index:start -->` truncates via render_index | `--marker` refuses any `<!--` line (B1); questions.sh half deferred (row 707) | Resolved for the loop path. `index($l[$i], "<!--") >= 0` at `scripts/build-loop.sh:841` runs on scrubbed text: p3 `<!\xC2\x85-- index:start -->` (C1 control scrubbed into `<!--`) skips; `<!\xC2\xAD--` (soft hyphen, unscrubbed) prints but has no literal `<!--`, so render_index's `index($0, start)` and check's sed range do not match it. Row 707 stands. |
| F2 invalid UTF-8 fails `questions.sh check` | strict regex (B2/C1) | Resolved. p3: an `encoding ISO-8859-1` commit with body `caf\xE9` skips. Fact-check final: 0 mismatches vs Python strict decode over ~1.27 M inputs. The cut keeps output valid (input is valid; the trailing short sequence is dropped). |
| F3 `--state ok` vs orchestrator's bare git | header narrowed + row 704 (U4) | Settled. Header `:120-123`: "it does not make a plain git command safe in the caller's shell, and it is a snapshot". Code unchanged under the row. |
| F4 caller_gate denylist | Won't-Fix row 705, comment narrowed | Settled. Comment `:521-523`: "Not covered: anything else such an environment can do (BASH_ENV, PATH), and what changes after the snapshot." p1: `core.sshCommand` passes, as the row accepts. |
| F5 LLM pasting agent | Defer row 706 (U4) | Settled; p2 confirms ZWSP/NBSP/fullwidth `#`/U+2010 shapes print and stay inert to the awk readers. |

## Findings

#### 1. A quoted body line becomes the entry's index summary, and its `|` characters add cells to the index row

**Severity:** Low
**Location:** `scripts/questions.sh:184-201` (parse_entries summary), `scripts/questions.sh:326-327` (row printf); `scripts/build-loop.sh:816-818` (column-0 comment)
**Boundary:** B1 → B2
**Move:** #11, #2
**Confidence:** High for the mechanism (executed, p2). Medium for reach: it needs the orchestrator to paste the body as the first prose line after the Needs line; the entry layout is U3b2/U3b3/U4's.
**Legibility-target:** the comment "the questions readers anchor at column 0, so a quoted line is never read as a heading, a Needs line or an answer" (`scripts/build-loop.sh:816-818`); fact-check final escalation "questions.sh:184 (index summary) takes a quoted line as summary text".

**Evidence (verbatim):**

```awk
# scripts/questions.sh:184 (block :184-201 read; flow to render_index :326-327)
        want_summary && status != "" && /[^[:space:]]/ && !/^\*\*/ && !/^###/ && !/^</ {
```

p2: a blocked marker with body `x | you: judgment | pick [1] | 2026-01-01 | [Q-002](#q-002--y)` passed `--marker` (rc 0). Pasted under Q-001's Needs line, `questions.sh index` wrote:

```
| [Q-001](#q-001--loop-x) | you: judgment | > x | you: judgment | pick [1] | 2026-01-01 | [Q-002](#q-002--y) | 2026-10-12 |
```

`questions.sh check` then printed `✓ questions: structure valid, indexes current` (rc 0); ANSWER_AWK read Q-001 as `open` and Q-002 as `drop` (its real answer); `archive` moved only Q-002. So no machine decision changed: the ID and Needs cells are the orchestrator's, `check`'s `^| \[Q-` match is line-anchored, and the body cannot hold `<!--`. What the loop does control is the Question cell of its own row and, through `|`, the rendered cells after it (a GFM renderer drops cells past the header's four, so "Opened" shows `you: judgment` here). The questions protocol reads the index "instead of the entries" (`questions.sh:287-288` comment), so a human scanning it sees loop-chosen text as the question. Rated Low, not Medium under the floor rule: no property the unit states (heading, Needs/Status, answer) is violated, and the effect is a human-facing display only, of the same class as row 706.

**Recommendation:** Do not fix in U3b1. Carry it into row 706's trigger (U4's collect step): the orchestrator writes its own one-line prose question before pasting the `--marker` lines, so the summary is never loop text. Optionally, at row 707's trigger (next unit editing questions.sh), skip lines starting `>` as summary candidates and escape `|` in the summary.

### Untested bypass candidates

- **GFM rendering of the forged row** (Finding 1): not rendered; the cell-dropping behaviour is from the GFM table rule, not executed.
- **COUNT-vs-PARAMETERS ordering on git other than 2.39.5:** p1 shows `git -c` wins over GIT_CONFIG_COUNT on 2.39.5 (`/x`); other versions not run.
- **Two bodies pasted adjacently with no orchestrator line between** (lazy continuation for a markdown renderer): traced static only. Quoted lines cannot open, close or be refused inside a fence by FENCE_AWK (`fenceish`/`rawhtml` need a non-`>` start; `opencomment` needs `<!--`, refused), so the awk readers are unaffected; renderer effects not tested.

## Endorsement Claims

- **Claim:** A GIT_CONFIG_COUNT that is not plain decimal stops `--state`, `--settings`, `--status`, `--marker` and `--check` with exit 1 before any git process starts.
  **Location:** `scripts/build-loop.sh:456-464`
  **Evidence:** executed
  **Verified:** p1, PATH shim logging every git exec: `010` with --state and `" 1"` with each other mode gave rc 1 and 0 logged git calls; stderr `build-loop.sh: GIT_CONFIG_COUNT is not a plain decimal count`.
  **Not verified:** `--merge`, `--start`, `--prompt` (same `harden` call at top level, not run).
  **route: code-fact-check**
- **Claim:** caller_gate reads only the caller's pairs, and a `git -c` pair overrides harden's COUNT pairs.
  **Location:** `scripts/build-loop.sh:532-546`
  **Evidence:** executed
  **Verified:** p1: `GIT_CONFIG_COUNT=1 KEY_0=core.hooksPath VALUE_0=/dev/null GIT_CONFIG_PARAMETERS="'core.hookspath'='/x'" git config --get core.hookspath` printed `/x`; case variants `CORE.HOOKSPATH`, `Core.FsMonitor`, `include.path`, `includeIf.gitdir:/.path`, `remote.Origin.promisor` each refused (rc 2); a newline inside a key makes git fatal, and caller_gate then refuses (`caller-config`).
  **Not verified:** pairs supplied by an `include.path` inside GIT_CONFIG_PARAMETERS (refused at the include key itself; the included keys' scope label not inspected).
  **route: code-fact-check**
- **Claim:** A caller GIT_DIR (and GIT_WORK_TREE) naming another repository with a planted core.fsmonitor is refused by `--state` (exit 2) before state_gate, and the fsmonitor does not run.
  **Location:** `scripts/build-loop.sh:573-583`
  **Evidence:** executed
  **Verified:** p1: rc 2, `refuse state GIT_DIR: ...` (and `GIT_WORK_TREE`), fsmonitor log empty; git calls before the refusal were `rev-parse --show-toplevel` and `rev-parse --local-env-vars` (with harden's 6 pairs) and `config --list` (count 0).
  **Not verified:** a FIFO include in the other repo's config (would hang `rev-parse --show-toplevel`, pre-existing class).
  **route: code-fact-check**
- **Claim:** marker()'s body extraction takes the text after the first empty line for commits with gpgsig and mergetag headers, and a commit with no message is not a marker.
  **Location:** `scripts/build-loop.sh:831-832`
  **Evidence:** executed
  **Verified:** p2/p3: hand-hashed commits with a gpgsig (blank continuation ` `) and a mergetag holding `handoff: blocked` and `**Answer:** [1]` in its continuation lines printed only the real body (`> real question`, `> q2`); a header-only commit answered `working`.
  **Not verified:** a header line that is itself empty-but-for-continuation in a format git's fsck would refuse (hash-object --literally only).
  **route: code-fact-check**
- **Claim:** The `<!--` and UTF-8 rules read the scrubbed body, so a scrubbed control cannot assemble `<!--` after the check.
  **Location:** `scripts/build-loop.sh:836-842`
  **Evidence:** executed
  **Verified:** p3 `<!\xC2\x85--` skipped; CRLF body with `**Answer:** [1]\r` skipped (CR scrubbed, rule hit).
  **Not verified:** idempotence of the second scrub in scrub_reexec over every printed line (relied on, not fuzzed).

## Primitive sweep

Primitive: interpreter run on a program string (perl -e / awk / sed -E)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:836` perl -e (rules, caps) | S4 program; S1 on stdin | constant program | cleared: S1 never reaches program text |
| `scripts/build-loop.sh:859` sed -E `s/^> ?//` | S4 | constant | cleared |
| `scripts/build-loop.sh:861` awk "$FENCE_AWK"… | S4 program; S1 on stdin | constant | cleared |
| `scripts/questions.sh:184` parse_entries summary (reader, not in diff) | S1 via pasted body | none | Finding 1 |

Primitive: shell variable-name construction

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:460` `export "GIT_CONFIG_KEY_$c=…"` | S2 count | decimal regex `:458` | cleared (p1) |
| `scripts/build-loop.sh:517` `${!v+set}` in stray_vars | git's `--local-env-vars` list | none needed | cleared |

Primitive: git read keyed by loop-movable ref or caller env

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:829,831` `cat-file -s` / `cat-file commit` on `STATUS[sha]` | S3/B5 | content-addressed SHA, 64 KiB cap, harden | cleared; post-`--state` grafts settled by row 708 |
| `scripts/build-loop.sh:537` `git config --list` at the caller's count | S2, S3 | runs without harden's pairs; lists config only | cleared: config listing execs nothing (p1) |
| `scripts/build-loop.sh:564-565` show-ref + `cat-file -t` | S3 | fails closed | cleared (fact-check claim 5) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Quoted body line becomes the index summary; `\|` adds rendered cells | Low | B1→B2 | `scripts/questions.sh:184`; `scripts/build-loop.sh:816-818` | High (mechanism) / Medium (reach) |

## Overall Assessment

The i1 Medium findings are resolved in code (F1 loop path, F2 via the strict regex) or settled by override rows whose code has not changed under them (F3 row 704, F4 row 705, F5 row 706, F1's questions.sh half row 707). Every refusal tested fails closed, the non-decimal count stops before any git process, and the caller's GIT_DIR cannot steer a reader before caller_gate reports it. The one new item, the index summary, changes no machine decision and belongs to the orchestrator-layout units, so it does not block the merge. No findings above Low within the code paths read. Endorsement claims are executed but marked pending execution verification by code-fact-check where routed.

## Goal-Alignment Note

- Success criterion (verbatim): "A markdown report saved to /workspace/.claude/wt-build-loop-u3b1/docs/reviews/security-review-2026-10-12-u3b1-final.md, structured per the security-reviewer skill."
- Answered: yes. For the goal (land U3b1 after a clean review-fix loop): no new security finding blocks landing. Finding 1 is Low and deferrable: an override row, or an addition to row 706's U4 trigger.
- Out of scope: questions.sh fixes (row 707's surface), the orchestrator entry layout (U3b2/U3b3/U4).
- Escalate: none.
