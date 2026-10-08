Commit: 9e5d92df

# API Consistency Review: feat/build-loop-u2b1a (`build-loop.sh --check`, iteration 2)

**Scope:** `git diff main...HEAD` at 9e5d92df: `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `test/scripts/build-loop-check.bats`, `docs/working/plan-build-loop-handoff.md`
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b1a-i2.md` (iteration 2). Its Incorrect claims 5, 7 and 18 (the submodule lazy fetch) are not re-reported here.

Probes ran in `/tmp/apiu2b1a-XXXX` (a throwaway repo, removed afterwards). No repo file other than this report was written.

## Baseline Conventions

- **Line grammar** (plan "Approach", `docs/working/plan-build-loop-handoff.md:194-199`; `scripts/dev-cycle.sh:22-63`): each line starts with a verdict word (`ok`, `skip`, `absent`, `refuse`), then the argument. A `skip`/`refuse` line has `ARG: WHY`. An `ok` line has space-separated fields and no colon. `skip` means unreadable and `refuse` is a verdict.
- **Exit codes:** read modes exit 0 when every argument was answered ("a skip is an answer, not an error", `scripts/dev-cycle.sh:80-81`). Writing modes exit 2 on any refusal. Usage errors exit 1.
- **Planned surface** (plan "Script interface", `:203-213`): `--state` → `ok`, or `refuse KEY` for each planted `.git` state (exit 2). `--check BRIEF… [--expect SHA]` lists rules but no output grammar. `--merge BRIEF --expect SHA`. The D4 merge entry quotes `--check`'s output with the full TIP (`:166`).
- **Lib naming** (`scripts/lib/dev-cycle-read.sh`): predicates mostly use an `is` prefix (`isbrief`:199, `isclosed`:200, `isstart`:522, `isimported`:1059). Adjective-style predicates also exist (`writable`:202, `inrepo`:160, `dirok`:166, `rawfile`:135, `ownfile`:1108). A function that computes a process-wide value stores it in an UPPER global of the same stem (`import_home`→`IMPORT_HOME`:790, `floor`→`FLOOR_WHY`:1127, `truthrule`→`TRUTH_WHY`:1079). The failure sentinel is the literal `error` (`IMPORTED=error`:592). Memoisation uses a `*_DONE` flag reset by `import_reset` (:592-594).
- **check_branch skip lines** (`scripts/lib/dev-cycle-read.sh:436-451`): `skip NAME: <reason>`. `status_line` rewrites them as `skip BRIEF: Branch: <reason>` (`scripts/build-loop.sh:422`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--check` | CLI mode | `--status`, `--settings`; dev-cycle.sh `--check-brief`, `--check-branch` | `scripts/build-loop.sh:6-9`, `scripts/dev-cycle.sh:9-14` | Consistent: matches the plan's name (`plan…:212`) |
| `--expect SHA` | CLI flag | plan's `--merge … --expect SHA`; `--answered Q-…`, `--dir DIR` | `docs/working/plan-build-loop-handoff.md:209-216` | Consistent |
| `ok BRIEF TIP TREE` | output line | `ok BRIEF STATE POLICY …` (--status); `ok <name> <commit> <n> <date>` (--check-branch) | `scripts/build-loop.sh:51`, `scripts/dev-cycle.sh:43` | Consistent: verdict word, then the argument, then fields |
| `refuse BRIEF: WHY` | output line | plan `refuse PATH: why` (--cycle-diff) | `docs/working/plan-build-loop-handoff.md:209` | Consistent |
| `refuse state WHAT: WHY` | output line | plan `refuse KEY` (--state) | `docs/working/plan-build-loop-handoff.md:207` | Inconsistent with the plan (F2); WHAT can hold `: ` (F3) |
| `skip BRIEF: WHY` | output line | --status skip lines | `scripts/build-loop.sh:69` | Consistent: reused verbatim |
| `skip NAME: its commit count or date could not be read` | output line (check_branch) | `skip NAME: not an allowed branch name` | `scripts/lib/dev-cycle-read.sh:441-449` | Consistent |
| `anybrief` | lib predicate | `isbrief`, `isclosed`, `isstart`, `isimported` | `scripts/lib/dev-cycle-read.sh:199-200,522,1059` | Minor: drops the `is` prefix (F5) |
| `open_shared` / `OPEN_SHARED` | lib function + global | `import_home`/`IMPORT_HOME`, `floor`/`FLOOR_WHY`, `IMPORTED=error` | `scripts/lib/dev-cycle-read.sh:592,790,1127` | Consistent pairing and `error` sentinel. The name is opaque (F6) |
| `harden`, `state_gate`, `STATE_KEYS_RE`, `merge_result`, `check_line`, `GATE_TMP` | script-private | `status_line`, `read_settings`, `main_file`, `SETTINGS_AWK`, `FILE_OUT` | `scripts/build-loop.sh:213-397` | Consistent (snake_case functions, UPPER globals, `*_line` printers) |

## Findings

#### F1. The state gate's path-read failure prints an empty WHAT: `refuse state : its path could not be read`

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:184-185`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
  for f in config config.worktree; do
    f="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { echo "refuse state $f: its path could not be read"; return 1; }
```
The failed command substitution still assigns `f`, so the message uses the empty (or partial) output rather than the key name. Probe: `f=config; f="$(false)" || echo "refuse state $f: …"` printed `refuse state : its path could not be read`. The sibling loop at `:193-194` assigns to `line` and keeps `$f`, so it prints `refuse state info/attributes: …`. The grammar `refuse state WHAT: WHY` breaks only on this path. The exit is still 2.

**Recommendation:** Assign to a separate variable, as `:194` does (`p="$(git rev-parse … "$f")" || { echo "refuse state $f: …"; }`).

#### F2. The `--check` state lines diverge from the plan's `--state` grammar, and the plan's Script interface section was not updated

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:84-85,190`; `docs/working/plan-build-loop-handoff.md:207,212`
**Move:** 3 (consumer contract: documentation drift), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
- `--state` → `ok`, or `refuse KEY` for each planted `.git` state the gate refuses (exit 2).
```
```
      [[ -n "$line" ]] && { echo "refuse state $line: set in ${f##*/}, it can make the gate's git run a command or change its merge"; bad=1; }
```
The plan specifies `refuse KEY` with no `state` word and no WHY. `--check` prints `refuse state WHAT: WHY`, and WHAT is sometimes a file (`info/grafts`, `refs/replace`, `config`) rather than a key. U3b's `--state` will either reuse `state_gate`, and so contradict its plan line, or print a second grammar for the same finding. The plan's `--check` entry (`:212`) also still records no output grammar (`ok BRIEF TIP TREE` / `refuse` / `skip` / `refuse state`), although the D4 merge entry quotes that output (`:166`). The shipped grammar is the better one, because the `state` token keeps it apart from brief lines.

**Recommendation:** Amend the plan: `--state` prints state_gate's own `refuse state WHAT: WHY` lines (and `ok` when there are none), and `--check`'s entry lists its four line forms and exit 0/1/2.

#### F3. WHAT in `refuse state WHAT: WHY` can contain `: `, so a consumer cannot split the line at the first colon

**Severity:** Minor
**Location:** `scripts/build-loop.sh:187-190`
**Move:** 7 (asymmetry with the `ARG: WHY` grammar)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
    rc=0; out="$(git config --file "$f" --no-includes --name-only --get-regexp "$STATE_KEYS_RE")" || rc=$?
```
Probe: `git config 'remote.a b: c.promisor' true`, then `--check` printed `refuse state remote.a b: c.promisor: set in config, …` (rc=2). A git config subsection may hold spaces and colons. Every other `skip`/`refuse` line has an ARG that passed `pathform` or NAMECHARS, so it holds no `: `. This is the only grammar line whose subject is repo-controlled free text. The verdict (refuse, exit 2) is unaffected; only the WHAT/WHY split is ambiguous, for example in a D4 entry or a log parser.

**Recommendation:** Either document that WHAT runs to the last `: set in`, or print the key after the WHY (`refuse state config: set key remote.a b: c.promisor`). Alternatively, quote or escape keys outside NAMECHARS.

#### F4. `--check`'s per-brief aggregation reads only the first line of `check_line`; U2b1b's per-path lines need the grammar fixed first

**Severity:** Minor
**Location:** `scripts/build-loop.sh:454-455,490-493`
**Move:** 3 (consumer contract, forward compatibility)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    for a in "${ARGS[@]}"; do
      out="$(check_line "$a")"; printf '%s\n' "$out"
      [[ "$out" == "ok "* ]] || fails=1
    done
```
The header promises "one line per brief path" (`:85-86`). U2b1b adds one line per changed path and deny lines to the same output. Today, a multi-line `out` whose first line is `ok` passes `== "ok "*` whatever the later lines hold, so a deny line after the ok line would still exit 0. With several briefs, per-path lines also need an owner. The D4 merge entry quotes this output, so the per-path line prefix becomes a contract the moment U2b1b ships.

**Recommendation:** In U2b1b, decide the path-line grammar before code. Make each line carry its brief or a distinct leading word (for example `path BRIEF MODE PATH`, `deny BRIEF PATH: WHY`), so it cannot be read as an `ok`/`refuse`/`skip` brief line. Settle the brief verdict on one summary line, and update the "one line per brief path" sentence and the plan's `--check` entry together.

#### F5. `anybrief` drops the lib's `is` prefix for predicates on the same noun

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:201`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `is<noun>` predicate used in `scripts/lib/dev-cycle-read.sh:199-200` (`isbrief`, `isclosed`), `:522` (`isstart`), `:1059` (`isimported`)

**Evidence:**
```
anybrief() { isbrief "$1" || isclosed "$1"; }
```
Its two halves are `isbrief` and `isclosed`, so a reader searching for the brief predicates by `is*` misses the union. The lib does have adjective-style predicates (`writable`, `dirok`, `ownfile`), but none of them sits beside an `is` sibling on the same noun.

**Recommendation:** Rename it `isanybrief` (three call sites: `:205`, `:392`, `:472`), or accept it and note the choice. It is low cost either way.

#### F6. `open_shared` / `OPEN_SHARED` does not say what is shared

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:461-477`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `<stem>()` sets `<STEM>` used in `scripts/lib/dev-cycle-read.sh:790` (`import_home`/`IMPORT_HOME`), `:592` (`IMPORTED=error`)

**Evidence:**
```
# The lower-cased branch names that more than one open brief on main (in
# briefs/ or closed/) names, each between newlines, in OPEN_SHARED: a caller
```
The pairing and the `error` sentinel follow precedent. Out of context, "open_shared" reads as "open a shared thing". The value is the set of branch names shared by more than one open brief. The memo is "non-empty means done", unlike `IMPORTED_DONE` plus `import_reset`, so it has no reset hook if a later unit re-resolves MAIN_SHA in-process. That is harmless today, because resolve_main runs once per process.

**Recommendation:** Optional rename (`shared_branches`/`SHARED_BRANCHES`). If U2b2's gate checkout ever re-resolves main, add it to `import_reset`'s reset.

#### F7. Inside `--check`, unreadable state is `refuse`, while an unreadable brief is `skip`, and both exit 2

**Severity:** Informational
**Location:** `scripts/build-loop.sh:107-108,185-197,465,492`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
# Exit: 0 every line printed (or help), and for --check every line ok; 2 any
# --check line or the state gate not ok; 1 bad usage, not a git repo, no perl
```
The plan's convention is that `skip` means unreadable and `refuse` is a verdict, and read modes exit 0 on a skip. `--check` is a gate, so it fails closed on `skip`, which is documented and right. Within `--check`, though, "could not be read" appears under three verdict words: `refuse state …: could not be read`, `refuse BRIEF: its branch … could not be read again`, and `skip BRIEF: …`. A consumer of the D4 entry cannot tell a verdict from an unreadable input by the first word.

**Recommendation:** Keep the behaviour. Add one header sentence: "in --check every non-ok line refuses the merge; skip and the 'could not be read' refusals mean the input was unreadable, not judged".

#### F8. An unknown flag after `--check` becomes a brief argument (exit 2), not a usage error (exit 1)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:131-137`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
      if [[ "$1" == --expect ]]; then
      …
      else ARGS+=("$1"); shift; fi
```
Probe: `--check --bogus` printed `skip --bogus: not an allowed path form` with rc=2. `--status --bogus` gives the same line with rc=0. This matches `--status` and dev-cycle.sh's check modes (every argument is answered, and `pathform` refuses a leading `-`), so it is consistent. A typo like `--expected SHA` yields two skip lines and exit 2 rather than a usage message, which fails closed.

**Recommendation:** None required. Optionally treat any `--*` argument as a usage error in `--check` alone, since gate flags will grow (`--approved` in U3).

## Note on the author's planned fix (temp git dir sharing only the object store)

- **for-author.** A gate-owned git dir with no config defaults to SHA-1. The header promises `--expect` and TREE in 64 hex (`:90`, `:135`, `:450`). In a SHA-256 repo, a config-less temp dir makes merge-tree fail, so every brief reads "the merge … could not be computed". The temp dir needs `core.repositoryformatversion=1` and `extensions.objectFormat` copied from the repo, read through `git config --file … --no-includes`, as the gate already reads.
- **for-author.** Without `modules/`, merge-ort cannot fast-forward a gitlink both sides moved, and reports a conflict. The verdict for those briefs changes from "clean" to "conflicts". That is fail-closed, but the `refuse BRIEF: … conflicts` WHY becomes misleading. Consider a distinct WHY, or document that both-sides gitlink moves refuse.
- **for-author.** Set GIT_OBJECT_DIRECTORY (and GIT_DIR) on the merge-tree command alone, not exported. Otherwise every later lib call reads the temp dir. Confirm that the repo's `objects/info/alternates` is still honoured: it is, because alternates resolve relative to the object directory. Merged objects then still land in the real store, as the header says.

## What Looks Good

- `ok BRIEF TIP TREE`, `refuse BRIEF: WHY` and `skip BRIEF: WHY` follow the lib's verdict-word-first grammar exactly. `--check` reuses `status_line` verbatim for skips, so one brief reads the same in both modes.
- `--expect` matches the plan's `--merge … --expect SHA`, takes only a full 40/64-hex id, is single-use, and is restricted to one brief. Each misuse is a usage error with exit 1, as the convention requires.
- The `state` token in `refuse state …` keeps the state lines apart from brief lines (a brief path can never be `state`). That is a better design than the plan's bare `refuse KEY`.
- check_branch's new skip line uses the existing `skip NAME: reason` shape, and both headers (`dev-cycle.sh:45-50`, `build-loop.sh:73`) document it. `dev-cycle.sh --check-branch` still exits 0 on it.
- `anybrief` replaced both open-coded `isbrief || isclosed` sites (`writable`, `check_brief`), so there is one predicate rather than three spellings.
- The usage line and `-h` stay in sync with the header (`:6-9`, `:124`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Path-read failure prints `refuse state : …` (empty WHAT) | Inconsistent | `scripts/build-loop.sh:185` | High |
| F2 | `refuse state WHAT: WHY` vs plan's `--state` `refuse KEY`; plan's `--check` entry has no grammar | Inconsistent | `scripts/build-loop.sh:190`; plan `:207,212` | High |
| F3 | WHAT can contain `: ` (config subsection) | Minor | `scripts/build-loop.sh:187-190` | High |
| F4 | Aggregation tests only the first line; U2b1b's per-path lines need a grammar | Minor | `scripts/build-loop.sh:490-493` | High |
| F5 | `anybrief` lacks the `is` prefix of its siblings | Minor | `scripts/lib/dev-cycle-read.sh:201` | Medium |
| F6 | `open_shared` name is opaque; no reset hook | Informational | `scripts/lib/dev-cycle-read.sh:461-477` | Medium |
| F7 | Unreadable input is `refuse` or `skip` inside `--check` | Informational | `scripts/build-loop.sh:107-108,185-197,465` | High |
| F8 | Unknown `--flag` after `--check` → skip + exit 2, not usage | Informational | `scripts/build-loop.sh:131-137` | High |

## Overall Assessment

`--check`'s surface is consistent with the lib's check-mode grammar and with `--status`. The one real defect is F1, a one-line fix that restores the `refuse state WHAT: WHY` shape on its failure path. The larger consumer-facing risks are contractual, not code. The plan's Script interface section still describes `--state` as `refuse KEY` and gives `--check` no output grammar (F2). U2b1b will extend the same output that the D4 merge entry quotes, and today's first-line-only aggregation would pass an ok line followed by a deny line (F4). Both are fixable in place, in the plan and in U2b1b's design, before the grammar hardens. Naming is consistent apart from the minor `anybrief` prefix.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 9e5d92df` line at the top.
- Answered: yes
- Out of scope: the submodule lazy fetch itself (fact-check Claims 5, 7, 18, not re-reported); security and performance of the state gate; U2b1b's diff-tree parse (not yet written).
- Escalate: F2 and F4 (the plan's interface text and U2b1b's line grammar) for the orchestrator. The SHA-256 note on the planned temp-git-dir fix goes to the author.
