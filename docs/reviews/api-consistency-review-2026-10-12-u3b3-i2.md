Commit: 5d175c0e

# API Consistency Review: feat/build-loop-u3b3 (iteration 2 of 3)

**Scope:** branch diff `main...5d175c0e` (docs/reviews/ excluded): `scripts/lib/dev-cycle-read.sh` (git_harden), `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `test/lib/d6-snippet.bash`, the two bats suites, the plan's U3b3 as-built note
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3b3-i2.md` (49 verified, 5 mostly accurate, 3 unverifiable; two security escalations)
**Agent:** api2. Probes: `/tmp/claude-1000/-workspace/c69d4d0f-5190-473b-ba2f-85b5a43f49ee/scratchpad/api2/p1.sh`, `p2.sh`. Each ran in its own `mktemp -d /tmp/u3b3-api2-XXXX` dir, under `timeout`, as uid 1000 with git 2.39.5, and removed that dir ("cleaned" printed).

## Baseline Conventions

- **Output lines.** build-loop.sh writes its verdicts to stdout as fixed-shape lines: `ok ...`, `skip BRIEF: WHY`, `refuse BRIEF: WHY`, `refuse state WHAT: WHY`, and `refuse main-log: WHY`. The last comes after a `main MAIN -` line (`scripts/build-loop.sh:1676-1679`). A mode-level refusal therefore uses a fixed token in BRIEF's slot (`main-log`). Usage errors and stop conditions go to stderr.
- **Exit codes** (`scripts/build-loop.sh` Exit header, about :117-127). 0 means every line printed is ok. For --settings, --status and --marker, 0 means "every line printed". 2 means a refuse or other verdict line, from --check, --merge, --start, --prompt, --main-log and --state. 1 means bad usage, a GIT_CONFIG_COUNT that is not plain decimal, no repo, no perl or lib, or a failed mktemp. dev-cycle.sh exits only 0 or 1 (`scripts/dev-cycle.sh:84-87`). U3b1 handed U4 this rule (checkpoint Blocked-on line): "read any exit but 0/2 as stop-and-quote-stderr".
- **Lib surface.** The lib's functions use snake_case (`scrub_reexec`, `resolve_main`, `need_root`, `main_by_name`). Its globals are UPPER_CASE (`MAIN_SHA`, `FENCE_AWK`, `NAMECHARS`). Git-wrapping helpers elsewhere use a `git_` prefix (`git_state_gate`, `devcontainer-config/install.sh:209`; `git_exit_scan`, `git_version_ok`).
- **Documented contracts.** Each mode's usage header lists exactly what the mode refuses (for example the --state header at `scripts/build-loop.sh:118-137`). The plan's as-built notes supersede the plan's interface bullets.
- **Hand-offs to U4** are recorded as override rows and in the checkpoint's Blocked-on line, one line per contract item.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `git_harden` | lib function | `git_state_gate`, `git_exit_scan`, `scrub_reexec` | `devcontainer-config/install.sh:209`, `devcontainer-config/cc-exit-scan.sh:981`, `scripts/lib/dev-cycle-read.sh:155` | Consistent: a `git_` prefix and snake_case. The rename from build-loop.sh's private `harden` is carried through every comment (fact-check Claim 18). |
| `HARDEN`, `CALLER_COUNT` | lib globals (moved) | `MAIN_SHA`, `FENCE_AWK`, `SKIP_AT` | `scripts/lib/dev-cycle-read.sh:186,270,364` | Consistent. Neither name is used by dev-cycle.sh or questions.sh (grep), so the move collides with nothing. |
| `refuse d6: WHY` | output line | `refuse main-log: WHY`, `refuse state WHAT: WHY`, `refuse BRIEF: WHY` | `scripts/build-loop.sh:1676-1679`, `:514-594` | Consistent in shape: a fixed token in BRIEF's slot, as `main-log` is. Its exit semantics are new (Finding 2). |
| `d6: the first argument is ...` (stderr, exit 1) | usage error | `Unknown option: $1`, `--main-log takes one full ...` | `scripts/build-loop.sh:486`, `test/scripts/build-loop-orchestrator.bats:225` | Consistent: usage goes to stderr with exit 1. |
| `${0##*/}: GIT_CONFIG_COUNT is not a plain decimal count` | stderr message | `build-loop.sh: GIT_CONFIG_COUNT ...` (main) | `test/scripts/build-loop-orchestrator.bats:54` | Consistent. Under scrub_reexec and the snippet, `$0` is the script's path, so build-loop.sh keeps its pinned text. |
| `D6_ROOT`, `D6_OPT` | snippet constants | `READ_LIB`, `SCRIPT_DIR` | `scripts/build-loop.sh:433-436` | Consistent (UPPER_CASE). `/opt/claude-workflows` matches the image path used elsewhere (`devcontainer-config/Dockerfile:500`, `scripts/self-improvement.sh:1465`). |
| `d6`, `g`, `no`, `own` | functions private to the snippet's child bash | n/a (not public: they live only in `bash -s`) | none (private) | Not a public surface. Skipped per the audit's "private locals" rule. |
| `test/lib/d6-snippet.bash` | file (canonical source of the SKILL.md block) | `test/lib/build-loop-fixtures.bash`, `test/lib/hermetic-env.bash`, `scripts/lib/dev-cycle-read.sh` | `test/lib/*.bash`, `scripts/lib/` | Divergent placement: production source sits among test fixtures (Finding 6, Informational, set by the plan). |
| `d6_copy`, `d6_setup`, `d6_is`, `shim`, `inplace` | test helpers | `state_is`, `bl`, `brief`, `commit_all` | `test/scripts/build-loop-orchestrator.bats`, `test/lib/build-loop-fixtures.bash` | Consistent (snake_case, file-local). |

## Findings

#### 1. --state's usage header still lists six hardening keys; caller_gate now refuses eight

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:131-136` (not in the diff; made stale by `scripts/lib/dev-cycle-read.sh:348`)
**Move:** 3 (trace the consumer contract: documentation drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:** the header reads "or a caller pair (git -c, GIT_CONFIG_COUNT) setting a key / the state gate refuses or one this script's own hardening sets / (core.useReplaceRefs, core.hooksPath, core.fsmonitor, / core.attributesFile, core.commitGraph, core.multiPackIndex; / a git -c pair would win over it), whatever the value." HARDEN is now `HARDEN=(... core.multiPackIndex=false log.date=default log.showSignature=false)`, and caller_gate loops over all of HARDEN.

Probe p1 ran `GIT_CONFIG_PARAMETERS="'log.date'='iso'" bash build-loop.sh --state` and printed "refuse state log.date: set by the caller's git -c or GIT_CONFIG_COUNT pairs, ..." with rc=2. `log.showSignature=false` gave the same line and rc=2. Before this branch, a caller exporting `git -c log.date=iso` passed `--state`. That caller is now refused, and the mode's own contract does not say so.

The header is what U4 reads to learn which pairs it must not export (rows 702/704's constraint). The new refusal is a narrowing of accepted input, so it is a subtle breaking change for `--state` callers. The as-built note lists the two keys, but the script's own interface text does not. The diff renamed `harden` to `git_harden` in eight comments, yet missed this enumeration, the one place that spells the keys out.

**Recommendation:** Add `log.date, log.showSignature` to the list. Better, replace the enumeration with "a key in the lib's HARDEN list (git_harden)" so the list cannot drift again. Optionally, add a `log.date` case to the T42 caller-pair test at `build-loop-orchestrator.bats:47-49`.

#### 2. The snippet adds exit 2 with `refuse d6:` to modes and a script whose own contract has no exit 2; no U4 hand-off records how to tell it apart

**Severity:** Minor
**Location:** `test/lib/d6-snippet.bash:21-27`, `test/lib/d6-snippet.bash:33`
**Move:** 4 (error consistency), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** "Exit: the script's own status; 2 and one "refuse d6: WHY" line on stdout, / with nothing run, ..." and `no() { echo "refuse d6: $*"; exit 2; }`. Probe p1 ran `bash d6-snippet.bash build-loop.sh --status docs/x.md` with both main and master present. It printed "refuse d6: the default branch is not exactly one of main and master" with rc=2.

Behind the snippet, every mode gains a refusal. Three cases have no precedent:
- For --settings, --status and --marker, the header's exit 0 means "every line printed". They have had no exit-2 case, and their output grammar is per-brief `ok`/`skip`/body lines.
- dev-cycle.sh never exits 2 (`scripts/dev-cycle.sh:84-87`), so a digest consumer now gets exit 2 and a single line instead of a digest.
- For --main-log, the script's own refusal is always preceded by `main MAIN -`, which U4's bootstrap reads (U3b2 hand-off). A d6 refusal has no such line.
- For --check and --merge, `refuse d6: WHY` has exactly the `refuse BRIEF: WHY` shape. A parser keyed on "refuse X:" reads it as a verdict for a brief named `d6`.

The line itself is consistent with the `refuse main-log:` precedent, and exit 2 still falls in the U3b1 rule's "0 or 2" set. What is missing is the rule U4 needs: "a first stdout line starting `refuse d6: ` means nothing ran, whatever the mode; test for it before mode-specific parsing". It is implied by the as-built note, but it is not recorded as a hand-off in the form earlier units used (override rows dated 2026-10-12, the checkpoint Blocked-on line).

**Recommendation:** When U3b3 merges, add one hand-off row or Blocked-on clause for U4. It should say: match `refuse d6: ` on the first stdout line before any mode's parser; exit 2 from a read mode or from dev-cycle.sh means the snippet refused; a d6 refusal of --main-log carries no `main MAIN -` line to bootstrap from. No code change needed.

#### 3. git_harden is not the "shared wrapper" row 704 tells U4 to use for its own git reads

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:326-359`; `docs/reviews/override-log.md:704`
**Move:** 3 (consumer contract)
**Confidence:** Medium (the gap is U4's to resolve; the mismatch between the row's wording and the built surface is certain)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
- Row 704's revisit trigger reads "the orchestrator's git reads go through build-loop.sh or a hardened wrapper, never bare git in its shell; U3b3's git_harden is the shared wrapper."
- As built, git_harden is a function in a uid-writable lib that runs once per process: "build-loop.sh and dev-cycle.sh call it once". It exports into the calling shell and is not idempotent. Probe p2 sourced the lib and called it twice, giving `CALLER_COUNT=8 GIT_CONFIG_COUNT=16`.
- U4 cannot source the lib before the snippet's checks. Exporting git_harden's environment in the orchestrator's shell makes `--state` refuse every HARDEN key (row 702).
- The snippet's own hardened `g()` lives only in its child bash, and the snippet accepts only `build-loop.sh` or `dev-cycle.sh` as its first argument.

So U4 finds no callable hardened-git surface. The as-built note discharges rows 281, 311, 495 and 505 but does not mention row 704, which still names git_harden as the wrapper.

**Recommendation:** Update row 704's trigger, or add a row, to say that git_harden is per-process and not usable by the orchestrator. U4 must either route every git read through build-loop.sh/dev-cycle.sh modes or carry its own `g()`-style line, pinned like the snippet's. Separately, the lib header could state the contract "call once per process; a second call re-counts HARDEN's pairs as the caller's".

#### 4. dev-cycle.sh's changed behaviour for non-gate callers is recorded only in a commit note

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:82-87` (usage and Exit header), `scripts/dev-cycle.sh:124-129`; consumer `skills/dev-cycle/SKILL.md:132`
**Move:** 3 (subtle breaking change, documentation drift), 6 (changed behaviour)
**Confidence:** Medium (the safe.directory consequence is fact-check Claim 55, Unverifiable here; the config and transport changes are Verified as Claim 3)
**Legibility-target:** for-author

**Evidence:**
- The header still promises "Acts on $PWD's git repo (like questions.sh), so the installed copy serves any project."
- The new behaviour is stated only in an in-body comment ("no hook, fsmonitor, / replace ref, user or system config, or transport") and in 9925f2a7's notes ("a host repo that needs a global safe.directory would stop").
- The dev-cycle skill runs `~/.claude/scripts/dev-cycle.sh` in any project, not only through D6.
- For those callers, ~/.gitconfig and /etc/gitconfig are now ignored (safe.directory, includes, any setting the digest's git log or ls-files honours). A partial clone can no longer lazy-fetch. Each of these shows up as the existing generic errors: `Not inside a git repository` (exit 1, `:129`) when the ownership check fails, or a non-zero mid-digest exit.
- The only new exit case is documented in the Exit header (non-decimal GIT_CONFIG_COUNT), which matches build-loop.sh's wording. The broader change is not.

**Recommendation:** Add one header sentence: "Its git reads no user or system config and no transport (the lib's git_harden): a repository that needs a global safe.directory, or a partial clone's missing object, stops it." If wanted, mirror the sentence in docs/dev-cycle.md at U5.

#### 5. The snippet's HARDEN pairs and git_harden's take opposite precedence against a caller's `git -c`

**Severity:** Informational
**Location:** `test/lib/d6-snippet.bash:28-29`, `:34`; `scripts/lib/dev-cycle-read.sh:342-343`, `:355-358`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
- The snippet header says "Its own git calls carry the lib's HARDEN pairs and git_harden's environment (a test pins the two lists equal)".
- The lib header says "The caller's own pairs (git -c, GIT_CONFIG_COUNT) / still apply, git -c ones after HARDEN's".
- Probe p2, with a caller's `GIT_CONFIG_PARAMETERS="'log.date'='iso'"`: the snippet's form (`git -c log.date=default`) read `default`; git_harden's form (a GIT_CONFIG_COUNT pair) read `iso`.

The lists are equal, as the test pins, but the snippet's pairs beat the caller's `git -c` while the scripts' lose to it. The snippet is the stricter of the two and its header is accurate as written, so nothing is wrong. A reader who takes "carries the same" to mean "behaves the same" would be wrong for a caller holding `git -c` pairs. That is exactly the case caller_gate exists for in the scripts, and it has no counterpart in the snippet.

**Recommendation:** Optionally, add "(as `-c`, so they outrank a caller's pairs, where git_harden's do not)" to the snippet header, or note it in the test's comment. No code change.

#### 6. The canonical D6 source lives in test/lib/ beside test fixtures

**Severity:** Informational (by the audit alone this would be Minor; I held it at Informational because the plan's U3b3 bullet sets the path)
**Location:** `test/lib/d6-snippet.bash`
**Move:** 2 (naming and placement against the grain)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: test-only helpers loaded by bats (`load ../lib/build-loop-fixtures`) used in `test/lib/build-loop-fixtures.bash`, `test/lib/hermetic-env.bash`; production shell sources used in `scripts/`, `scripts/lib/`

**Evidence:** the plan bullet reads "`test/lib/d6-snippet.bash`, the byte-equality test (pending until U4 puts the block in SKILL.md)". The file header says "U4 puts this file, / byte for byte, in skills/dev-cycle/SKILL.md".

The file is the source of record for production code, the block U4 pastes, but it sits among fixtures. Its siblings are not executable entry points, and none is named in D4's GATE_CODE list. After U4, T33's byte-equality ties the file to SKILL.md, so a reader who finds the two copies can tell which is canonical only from the header comment.

**Recommendation:** None required (the plan chose the path). If U4 touches it, say in SKILL.md's block comment which copy is canonical, since the test pins equality but not direction.

## Re-flagged settled decisions

| Row | Settled decision | How it shows here | Status |
|---|---|---|---|
| 702 (`docs/reviews/override-log.md:702`) | The orchestrator calls `--state` with no git_harden pairs exported; caller_gate refuses a HARDEN key whatever its value. | Finding 1 (the documented key list is stale) and Finding 3 (no exported git_harden for U4) both build on it. Neither re-opens it. | Settled; not re-opened. |
| 704 (`docs/reviews/override-log.md:704`) | Deferred to U4: the orchestrator's git goes through build-loop.sh or a hardened wrapper. | Finding 3: the row names git_harden as that wrapper, but the built surface cannot serve as one. The row's wording, not its decision, needs updating. | Settled decision; trigger text stale. |
| 548 (`docs/reviews/override-log.md:548`) | dev-cycle.sh runs no state_gate or default_gate (Q-103 residual). | The lib header's "What these cannot switch off, build-loop.sh's state gate refuses" holds only for build-loop.sh. This is fact-check Claim 26, not re-filed. | Settled; not re-opened. |

## Cross-references (not re-filed)

- Fact-check Claims 7/33 and escalation (1): a failed root-check `rev-list` (`test/lib/d6-snippet.bash:48`) selects the image copy and exits with that copy's status, against the Exit header's "a git read ... that fails" → 2. From the consumer side, U4 cannot tell from the output which copy ran. That is part of the security reviewer's call. If the behaviour stays, the Exit header needs the exception.
- Fact-check escalation (2) (refs/heads/main moved by a loop) is a security and threat-model item, not an interface one.

## What Looks Good

- `refuse d6: WHY` follows the `refuse main-log: WHY` precedent: a fixed token, one stdout line, and no repo text in WHY. Every WHY is built from constants, `$m` (main or master) or `D6_OPT` paths, so printing it unscrubbed is safe.
- Usage errors (exit 1, stderr) and refusals (exit 2, stdout) keep the scripts' split, and the snippet's normal exit is the script's own status (`exit "$?"`). Through the snippet, U3b1's rule "any exit but 0/2 → quote stderr" still holds for every script exit.
- `git_harden` keeps the old `harden` contract exactly: the same pairs plus two, the same environment, CALLER_COUNT captured inside, and the same non-decimal refusal text for build-loop.sh (test at `build-loop-orchestrator.bats:54` unchanged and passing). Test 18 pins the exact `GIT_*` environment, closing row 311.
- dev-cycle.sh's new exit-1 case is worded identically to build-loop.sh's Exit header.
- The snippet's invocation form (`bash -s -- SCRIPT ARG... <<'D6'`, stdin from /dev/null, all functions in the child bash) defines nothing in the caller's shell. Its arguments pass through to the script unchanged, so U4 calls each mode with the same argument grammar the script's usage header documents.
- The snippet's HARDEN and environment lists are pinned equal to the lib's by test (fact-check Claim 11), which matters because the snippet cannot source the lib.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | --state usage header lists 6 HARDEN keys; caller_gate refuses 8 (log.date, log.showSignature now refused, undocumented) | Inconsistent | `scripts/build-loop.sh:131-136` | High |
| 2 | Snippet adds exit 2 + `refuse d6:` to read modes and dev-cycle.sh; no U4 hand-off says to match it before mode parsing | Minor | `test/lib/d6-snippet.bash:21-27,33` | High |
| 3 | Row 704 names git_harden as U4's hardened wrapper; as built it cannot be one | Minor | `scripts/lib/dev-cycle-read.sh:326-359`, override-log row 704 | Medium |
| 4 | dev-cycle.sh's dropped user/system config and transport recorded only in a commit note, not its header | Minor | `scripts/dev-cycle.sh:82-87,124-129` | Medium |
| 5 | Snippet's `-c` pairs outrank a caller's `git -c`; git_harden's count pairs do not | Informational | `test/lib/d6-snippet.bash:28-34` | High |
| 6 | Canonical D6 source sits in test/lib/ among fixtures (plan-chosen) | Informational | `test/lib/d6-snippet.bash` | Medium |

## Overall Assessment

The new surfaces follow the codebase's conventions: `git_harden`'s name, the moved globals, the `refuse d6:` token, and the exit split between 1 (usage, stderr) and 2 (refusal, stdout). The move of `harden` into the lib preserves its contract exactly for build-loop.sh.

The problems are contract text the diff did not carry along:
- build-loop.sh's `--state` header still enumerates the old six keys, so a caller exporting `git -c log.date=...` is refused with no documentation of it (Finding 1, the one Inconsistent item).
- Two hand-offs U4 will need are not yet recorded: how to recognise a d6 refusal across every mode, and that git_harden is not the wrapper row 704 promises.
- dev-cycle.sh's stricter git environment is undocumented for its non-gate callers.

All six are fixable in place with comment, header or override-row edits. No code change is required for consistency, and existing consumers of build-loop.sh's gated modes are unaffected beyond Finding 1.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/api-consistency-review-2026-10-12-u3b3-i2.md, structured per the api-consistency-reviewer skill.
- Answered: yes. I reviewed the snippet's invocation form, arguments, output lines and exit codes against build-loop.sh and dev-cycle.sh's conventions and the U3b1/U3b2/U3d hand-offs; git_harden's name and contract as a lib function; and dev-cycle.sh's changed behaviour for its callers. I made two probes (p1: --state against the caller's log.date/log.showSignature pairs, the snippet's refusal and usage exits; p2: -c vs count-pair precedence, git_harden called twice).
- Out of scope: the root-check fallthrough and the moved-main question (security, escalated by the fact-check); the bats suites were not re-run (the fact-check's S1 ran them, 19/19).
- Escalate: Finding 1 is a one-line header fix that should land in this unit. Findings 2 and 3 are U4 hand-offs the merge should record, as earlier units did.
- Decisions I made: I filed the stale `--state` header (outside the diff's hunks) because the diff's HARDEN change made it stale. I held Finding 6 at Informational because the plan names the path. I kept probe scripts in the session scratchpad under `api2/` and their temp dirs under `/tmp/u3b3-api2-*`, all removed.
