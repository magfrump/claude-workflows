Commit: 74deb04e

# API Consistency Review — feat/build-loop-u3c, iteration 2

**Scope:** `git diff main...HEAD` (main = dafc0e74, HEAD = 74deb04e). Public surface: `scripts/build-loop.sh --cycle-diff [--answered Q-NNN]...` (header, usage, parser, output, exit) and `scripts/health-check.sh`'s `HEALTH_CHECK_LOCK_HELD`, lock file and messages. Also read: the plan's interface list, which U4 will build against.
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3c-i2.md` (33 claims, 0 Incorrect, 4 Mostly accurate). Behaviour verified there is not re-verified here.

## Baseline Conventions

These come from build-loop.sh's other modes (`scripts/build-loop.sh:7-464`, the parser at `:479-530`) and its siblings dev-cycle.sh and health-check.sh.

- **Mode shape.** One leading `--mode` in kebab case (`--main-log`, `--check`, `--merge`). Positional operands are listed with `...`: `--status BRIEF...`, `--check BRIEF...`, and dev-cycle.sh's `--check-answer Q-NNN...` (`scripts/dev-cycle.sh:14`). Each option is valid in one mode, given once, and says so in its usage text: "--expect takes one commit id, given once", "--approved takes one question ID (Q- and digits), given once", "--steal goes with --prompt, given once" (`:510`, `:516`, `:526`). A malformed command line exits 1 with stdout empty and one usage message on stderr.
- **Output lines.** Each line is a fixed keyword, then fields, then `: WHY`:
  - `ok BRIEF ...` and `refuse BRIEF: WHY` (--check, --merge, --start, --prompt)
  - `refuse state WHAT: WHY` (the state gate)
  - `refuse main-log: WHY`
  - a bare `ok` (--state)

  Parsable fields come before the colon. The WHY is prose, except where the header pins its text ("the text up to '; ' is fixed", `:262-265`).
- **Exit codes.** 0 when the mode's ok holds, 2 for a refusal, 1 for usage or environment errors. The header's `Exit:` paragraph (`:454-464`) lists every mode by name for each code.
- **Gating.** The phrase "after --state's gate but its caller check" is shared with --main-log.
- **health-check.sh.** Its contract is "Exits 0 if all checks pass, non-zero otherwise" (`:9`). Its environment seams are `HEALTH_CHECK_*` variables documented in the header (`:11-29`). The one variable the script passes to its own nested runs, `HEALTH_CHECK_SKIP_BATS`, is "When 1" and is tested with `== 1` (`:20`, `:374`). Messages use the log-format helpers (`red`, `yellow`, `fail`, `warn`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--cycle-diff` | CLI mode | `--main-log`, `--check`, `--merge` | `scripts/build-loop.sh:479-530` | Consistent: kebab-case noun phrase like `--main-log`. "diff" names the input it reads, not its output (a verdict). `--main-log` follows the same pattern, so this is acceptable. |
| `--answered Q-NNN` | CLI option | `--approved Q-NNN`, `--expect SHA`, dev-cycle `--check-answer Q-NNN...` | `scripts/build-loop.sh:514-517`, `scripts/dev-cycle.sh:14` | Consistent: past participle and same ID regex as `--approved`. The shape is new: it is the first repeatable option in scripts/ (Finding 5). |
| `refuse PATH: WHY` / `refuse HEAD: …` / `refuse index: …` | output line | `refuse BRIEF: WHY`, `refuse state WHAT: WHY`, `refuse main-log: WHY` | `scripts/build-loop.sh:174-181`, `:225-243` | Mostly consistent. The subject slot holds either a path or a fixed token, and the refused ID is only in the WHY (Finding 4). |
| `ok` (bare) | output line | `--state`'s bare `ok` | `scripts/build-loop.sh:143-146` | Consistent |
| `HEALTH_CHECK_LOCK_HELD` | env var | `HEALTH_CHECK_SKIP_BATS`, `HEALTH_CHECK_RUN_TESTS`, `HEALTH_CHECK_SKILLS_DIR` | `scripts/health-check.sh:11-29` | Consistent prefix. Its truthiness rule differs from its closest sibling (Finding 3). |
| `health-check.lock` | lock file (common git dir) | `build-loop-dispatch.lock` | `scripts/build-loop.sh:1918` | Consistent: `<tool>[-<purpose>].lock` in `--git-common-dir`, with the same plain-file test |
| `raw_records`, `RAW_OM/NM/OO/NO/S/P`, `QKEYS_AWK`, `QDIFF_AWK`, `ROADMAP_AWK`, `cyc_blob`, `cycle_diff`, `take_lock` | internal helpers | `ANSWERS_AWK`, `FENCE_AWK`, `log_class`, `main_log` | `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` | Not public. Their names follow the file's `*_AWK` and snake_case conventions. |

## Findings

#### 1. The header's `Exit:` paragraph does not list --cycle-diff

**Severity:** Minor
**Location:** `scripts/build-loop.sh:454-464`
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** High

The paragraph lists every other gated mode by name: exit 0 "for --state ok, for --main-log no other line…", exit 2 for "--main-log's other or refuse line…", and exit 1 for "a failed mktemp (--state, --main-log, --check, --merge, --start, --prompt; no line printed)". The branch adds a mode to the usage line (`:11`, `:479`) but leaves this paragraph unchanged. Evidence, verbatim:

```
# Exit: 0 every line printed (or help; a --marker skip is a line), for
# --state ok, for --main-log no other line, for --check every verdict line ok,
# for --merge merged, for --start and --prompt ok; 2 any other --check,
# --merge, --start or --prompt verdict line, --main-log's other or refuse
# line, or the state gate (--state's included) not ok. ...
# ... a failed mktemp
# (--state, --main-log, --check, --merge, --start, --prompt; no line printed),
```

The mode's own block states "Prints ok, or one line per finding and exit 2" (`:186-187`), so the contract is stated, but only there. U4's orchestrator author will read the summary paragraph that every other mode is enumerated in. --cycle-diff also runs state_start, so it shares --main-log's mktemp exit 1. Read literally, the paragraph's first clause, "0 every line printed", would cover a --cycle-diff that printed refuse lines.

**Recommendation:** Add "for --cycle-diff ok" to the exit-0 clause and "--cycle-diff's refuse lines" to the exit-2 clause. Add --cycle-diff to the mktemp list.

#### 2. The plan's interface list still says the diff is against MAIN_SHA

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:104`, `:209`
**Move:** 3 (documentation drift for the downstream consumer)
**Confidence:** High

The implementation and the U3c bullet (`:328`) use the fork point, `git merge-base HEAD MAIN_SHA`. The fact-check's Claim 4 shows this is load-bearing: mutant m3 (base = MAIN_SHA) fails T38. The two places U4's author will read first still say the opposite. Evidence, verbatim:

- `:104`: "`build-loop.sh --cycle-diff --answered Q-…` compares the staged files with `MAIN_SHA`."
- `:209`: "`--cycle-diff [--answered Q-…]` → `ok`, or `refuse PATH: why` (exit 2); run in the orchestrator's worktree against `MAIN_SHA`."

Step 9 (`:259`) is the U4 step that calls this mode, and its "before the chore commit" contract sits at `:104`. An orchestrator built from `:104` or `:209` would expect a main that moved within the iteration (step 7's merges) to show in the comparison. The fork-point base exists precisely so that it does not.

**Recommendation:** Reword `:104` and `:209` to "against the fork point of HEAD and MAIN_SHA (git merge-base)". Alternatively, point both lines at the U3c bullet.

#### 3. `HEALTH_CHECK_LOCK_HELD` is on for any non-empty value; its sibling is on only for `1`

**Severity:** Minor
**Location:** `scripts/health-check.sh:27-29`, `:1108`
**Move:** 2 (naming and convention: variable value semantics)
**Confidence:** High

Precedent: the nested-run variable is on only for the value `1` (`[[ "${HEALTH_CHECK_SKIP_BATS:-}" == 1 ]]`), used in `scripts/health-check.sh:374`, documented "When 1" at `:20`.

The new variable is checked with `[[ -z "${HEALTH_CHECK_LOCK_HELD:-}" ]] || return 0` (`:1108`), and its header entry (`:27-29`) gives no value. So `HEALTH_CHECK_LOCK_HELD=0`, or `=false` left in a shell profile, switches the lock off with no message. The two variables sit side by side in the same header and play the same role: a marker the script passes to its own nested runs. A reader will assume they share a truthiness rule. The fact-check's Claim 25 scope already notes that a caller setting it takes no lock.

**Recommendation:** Test `== 1` as the sibling does, and document "When 1". Optionally say in the header that callers must not set it, as `HEALTH_CHECK_SKIP_BATS`'s entry says who sets it.

#### 4. The refusal grammar: the ID a caller needs is only in the WHY text

**Severity:** Informational
**Location:** `scripts/build-loop.sh:188`, `:1855-1858`; `docs/working/plan-build-loop-handoff.md:209`
**Move:** 7 (asymmetry with sibling output lines) / 3 (what U4 parses)
**Confidence:** Medium

The header gives one grammar, `refuse PATH: WHY` (`:188`), but the mode prints three subject kinds:

- a path (`refuse docs/working/questions.md: …`)
- the fixed token `HEAD`
- the fixed token `index`

The questions refusals carry the entry ID only inside the prose. Evidence, verbatim:

```
    if [[ "$k" == gone ]]; then echo "refuse docs/working/$f: $i's heading, Needs or answer lines changed or are gone, and $i is not in --answered"
    else echo "refuse docs/working/$f: $i is a new entry filed answered (Status ANSWERED or an answer line), and $i is not in --answered"; fi
```

Elsewhere, build-loop.sh puts the fields a caller acts on before the colon: `deny BRIEF S PATH: WHY`, `refuse state WHAT: WHY`. Where a WHY's text is a contract, the header says so (--check's "the text up to '; ' is fixed", `:262-265`). U4's step 9 will likely want to show which IDs blocked the commit, or ask the user about them. To do that it has to match the possessive "Q-001's" or "Q-004 is a new entry" in prose that the header does not pin. HEAD and index cannot collide with a judged path, because only four fixed paths are judged, so the subject slot is unambiguous today. It is only under-documented.

**Recommendation:** In the header, either document the subjects as `refuse PATH|HEAD|index: WHY` and state that each questions WHY starts with the entry's ID, or move the ID before the colon, for example `refuse docs/working/questions.md Q-001: …`. Whichever is chosen, T38's `cd_is` strings (`test/scripts/build-loop-orchestrator.bats:404-422`) already pin the current text.

#### 5. `--answered` is the first repeatable option, and it accepts any ID silently

**Severity:** Informational
**Location:** `scripts/build-loop.sh:11`, `:489-494`
**Move:** 2 (option shape) / 7 (asymmetry with `--approved`)
**Confidence:** Medium

Precedent: multiple IDs or paths are taken as a positional list (`--status BRIEF...`, `--check BRIEF...` in `scripts/build-loop.sh:7-12`; `--check-answer Q-NNN...` in `scripts/dev-cycle.sh:14`). Every flag that takes a value is "given once" (`scripts/build-loop.sh:510`, `:516`, `:526`).

`--cycle-diff [--answered Q-NNN]...` sets a new shape. The flag name does say what the IDs mean, which a bare `--cycle-diff Q-NNN...` would not. Two other differences from `--approved` follow, and neither is documented:

- A duplicate ID is accepted.
- An ID that names no changed or new entry is accepted and ignored. T38 relies on this: `cd_is ok --answered Q-003 --answered Q-001` (`test/scripts/build-loop-orchestrator.bats:405`).

`--approved` is bound to the entry it names and refuses when that entry does not read as it should. A mistyped ID in `--answered` (Q-041 for Q-014) fails safe for the intended entry, which still refuses. It silently licenses Q-041 if that entry also changed. IDs match as exact strings, so `Q-14` does not license `Q-014`. That is consistent with check_answer's `h == id` (`scripts/lib/dev-cycle-read.sh:2076`) but is not stated.

**Recommendation:** Keep the repeated flag. It is the clearer form, and the header already marks it with `]...`. Add one line to the --cycle-diff block: "an --answered ID that names no changed entry is ignored; IDs match the heading exactly." Optionally refuse an unused ID, so a stale or mistyped list shows up.

#### 6. Two failures in health-check.sh's lock exit without the script's own message

**Severity:** Informational
**Location:** `scripts/health-check.sh:1106-1121`
**Move:** 4 (error consistency)
**Confidence:** Medium

The lock adds a runtime dependency on util-linux `flock` with `-o` and `-E`. Two failures exit without a message of the script's own:

- With `flock` missing, `flock ... || rc=$?` exits 127 with the shell's "command not found".
- When the lock file exists as a plain file but cannot be opened, flock prints its own message and exits with its own status (the fact-check's Claim 9 scope leaves this unestablished).

Both are non-zero, so "non-zero otherwise" (`:9`) still holds for gate callers. Precedent for naming the case:

- build-loop.sh checks its dependency up front: `command -v perl >/dev/null || { echo "build-loop.sh needs perl (to scrub its output)" >&2; exit 1; }` (`scripts/build-loop.sh:468`).
- Its dispatch lock names both cases in one message: "is not a plain file or cannot be opened" (`:1920`).

The new message, `red "health-check.lock in $d is not a plain file"; exit 1`, covers only the first.

**Recommendation:** Optionally add a `command -v flock` precheck with a `red` line, and widen the message to "is not a plain file or cannot be opened" (test with `[[ -r "$lk" || ! -e "$lk" ]]` or an open probe), to match the dispatch lock.

## What Looks Good

- `--cycle-diff` fits the mode family:
  - gated by default (`GATED` is set for any mode not in the read-only list, `:648`)
  - "after --state's gate but its caller check", word for word as `--main-log`
  - a bare `ok` as `--state`
  - exit 2 per refusal, and exit 1 with empty stdout for a malformed command line (T38 checks three shapes, `test/scripts/build-loop-orchestrator.bats:444`)
- The usage string and `-h` header were both updated, in the same position (after `--main-log`, before `--check`). The usage error text, "--cycle-diff takes only --answered Q-NNN, one ID each", matches the tone of the existing messages.
- `--answered` uses `--approved`'s exact ID regex, `^Q-[0123456789]+$`, so both options accept the same IDs.
- Refusal ordering is deterministic: roadmap and idea-log lines come in git's path order, and questions lines are sorted. Multi-line output is stable for a parser and for the tests' exact-string assertions.
- The health-check lock mirrors the dispatch lock in name, location (`--git-common-dir`), plain-file test and wording ("in this repository"). `HEALTH_CHECK_LOCK_HELD` follows the `HEALTH_CHECK_*` prefix and is documented in the same header table. The not-a-plain-file case exits 1, which keeps health-check's 0/1 contract rather than borrowing build-loop's 2.
- `raw_records` is an internal refactor. check_line's refusal text is unchanged (fact-check Claim 18), so no consumer-visible line moved.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The `Exit:` paragraph omits --cycle-diff (exit 0, exit 2, mktemp exit 1) | Minor | `scripts/build-loop.sh:454-464` | High |
| 2 | The plan's interface list says MAIN_SHA; the code uses the merge-base | Minor | `docs/working/plan-build-loop-handoff.md:104`, `:209` | High |
| 3 | `HEALTH_CHECK_LOCK_HELD` is on for any non-empty value; its sibling only for `== 1` | Minor | `scripts/health-check.sh:27-29`, `:1108` | High |
| 4 | Refusal subjects (path, HEAD or index) under one documented grammar; the ID only in prose WHY | Informational | `scripts/build-loop.sh:188`, `:1855-1858` | Medium |
| 5 | The first repeatable option; unused and duplicate `--answered` IDs silently accepted, undocumented | Informational | `scripts/build-loop.sh:11`, `:489-494` | Medium |
| 6 | Missing flock, or an unopenable lock file, exits without the script's own message | Informational | `scripts/health-check.sh:1106-1121` | Medium |

## Overall Assessment

The new surface follows the script's conventions closely: mode naming, gate placement, a bare `ok`, exit 2 per refusal, usage errors and the lock-file pattern all match their nearest siblings. Nothing breaks an existing consumer. The only existing output that changed is internal (raw_records), and its text is preserved.

The gaps are in the documents U4 will be written against:

- The header's `Exit:` summary (Finding 1)
- The plan's interface list, which still names MAIN_SHA as the base (Finding 2)
- The refusal lines' WHY text that U4 will need to parse (Finding 4)

All three can be fixed in place in a few lines. One small convention slip is the `HEALTH_CHECK_LOCK_HELD` truthiness rule (Finding 3). No finding is at blocking grade.

**Goal-alignment note.** The PR's goal is that the orchestrator cannot launder an answer, or drop roadmap or idea-log content, through its chore commit. The interface serves that goal: one call, a fixed ok/refuse contract, and an explicit allow-list (`--answered`) that the orchestrator must name. Findings 2, 4 and 5 bear on how reliably U4 will call and read the mode, so they are worth fixing before U4 starts.
