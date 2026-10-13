Commit: 5583a2cd

# API Consistency Review: feat/build-loop-u3b3 (iteration 3 of 3, final confirming pass)

**Scope:** branch diff `main...5583a2cd` (docs/reviews/ excluded from the saved diff; the seven new override rows at the end of `docs/reviews/override-log.md` and the rubric read as part of the change): `scripts/lib/dev-cycle-read.sh` (git_harden), `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `test/lib/d6-snippet.bash`, the two bats suites, the plan's U3b3 as-built note
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3b3-final-r{1,2,3}.md` (k=3; no behavioural Incorrect), the i2 rubric rows B4, B12, B14, B15, B18, B19
**Agent:** api4. Probe: `/tmp/claude-1000/-workspace/c69d4d0f-5190-473b-ba2f-85b5a43f49ee/scratchpad/api4/p1.sh`, run under `timeout 120` in its own `mktemp -d /tmp/u3b3-api4-XXXX` dir (removed; "cleaned" printed). `bats test/scripts/build-loop-orchestrator.bats` run serially with its own TMPDIR: 20/20 ok.

## Baseline Conventions

- **Output lines.** build-loop.sh's verdicts are fixed-shape stdout lines: `ok ...`, `skip BRIEF: WHY`, `refuse BRIEF: WHY`, `refuse state WHAT: WHY`, `refuse main-log: WHY` (a fixed token in BRIEF's slot). Usage errors and environmental stops go to stderr.
- **Exit codes** (`scripts/build-loop.sh:420-430`): 0 every line ok/printed; 2 a refuse/other verdict or the state gate; 1 bad usage, a non-decimal GIT_CONFIG_COUNT, no repo, no perl or lib, **a failed mktemp** ("no line printed"), or no default branch. dev-cycle.sh exits 0 or 1 only (`scripts/dev-cycle.sh:87-90`). U3b1's hand-off: U4 reads any exit but 0 or 2 as "stop and quote stderr".
- **Lib surface.** snake_case functions, UPPER_CASE globals; git helpers take a `git_` prefix.
- **Hand-offs to U4** are recorded as dated override rows and in the plan's as-built note.

## Status of iteration 2's API items

| i2 item | Status at 5583a2cd | Evidence |
|---|---|---|
| B4 (--state header listed six HARDEN keys) | Fixed | `scripts/build-loop.sh:134-137` now reads "(the lib's HARDEN list: core.useReplaceRefs, core.hooksPath, / core.fsmonitor, core.attributesFile, core.commitGraph, / core.multiPackIndex, log.date, log.showSignature; ...)". Probe p1: `GIT_CONFIG_PARAMETERS="'log.date'='iso'"` through the snippet, `--state` printed `refuse state log.date: set by the caller's git -c or GIT_CONFIG_COUNT pairs, ...`, rc=2, as documented. |
| B12 (dev-cycle.sh header silent on dropped config/transport) | Fixed | `scripts/dev-cycle.sh:83-86`: "Its git reads are hardened (the lib's git_harden): they read no user / or system git config (a repository owned by another user that needs a global / safe.directory reads as "Not inside a git repository") and no transport". The Exit line names the new GIT_CONFIG_COUNT case in build-loop.sh's words. |
| B14, B15, B18, B19 | Deferred / Won't-Fix by row | See "Re-flagged settled decisions". |

## Name-Pattern Audit

New public names are unchanged from iteration 2 (that audit's rows stand: `git_harden`, `HARDEN`, `CALLER_COUNT`, `refuse d6: WHY`, the `d6:` usage line, `D6_ROOT`, `D6_OPT`, the file `test/lib/d6-snippet.bash`). Names new since 5d175c0e:

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `P` (the verified reader's perl program), `obj`, `entry` | private to the snippet's child bash / perl | n/a | none (private) | Not a public surface; skipped per the private-locals rule. |
| `main` / `other` (perl's answer to bash) | internal protocol between perl and the snippet | `ok`/`skip` tokens | `scripts/build-loop.sh` | Private: never printed to the caller; the bash side maps any other answer to `refuse d6: the verified reader gave no answer`. |
| `inplace`, `A1` | test helper / test constant | `d6_is`, `state_is`, `shim` | `test/scripts/build-loop-orchestrator.bats` | Consistent (file-local; snake_case helper, UPPER_CASE constant as `B`, `K`, `RULE`). |
| `refuse d6: the verified reader gave no answer`, `refuse d6: ... could not be read whole, or an object does not hash to its id`, `refuse d6: the temp dir could not be laid out` | refusal WHY texts | `refuse d6: mktemp failed`, `refuse main-log: X is not on ...` | `test/lib/d6-snippet.bash:39-85`, `scripts/build-loop.sh` | Consistent in shape (constant text plus `$m` or D6_OPT paths only). Their exit class is Finding 1. |

## Findings

#### 1. The snippet reports environmental failures (a failed mktemp, a broken perl) as `refuse d6:` exit 2, where the scripts exit 1 on stderr; U4's hand-off reads every `refuse d6:` as planted state

**Severity:** Minor
**Location:** `test/lib/d6-snippet.bash:72`, `:78`, `:26-32`; U4 hand-off in `docs/reviews/override-log.md` (the 2026-10-12 `feat/build-loop-u3b3` `refuse d6:` row) and the plan's as-built note (`docs/working/plan-build-loop-handoff.md:326`)
**Move:** 4 (error consistency), 3 (consumer contract)
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `t="$(mktemp -d)" || no "mktemp failed"` and `x="$(LC_ALL=C perl -e "$P" ...)" || no "$m's first-parent history, the trees above scripts/lib/ or the four files could not be read whole, or an object does not hash to its id"`, with `no() { echo "refuse d6: $*"; exit 2; }`. build-loop.sh's Exit header classes the same event the other way: "1 bad usage, ... a failed mktemp / (--state, --main-log, --check, ...; no line printed)". The override row's hand-off reads "match a first line starting `refuse d6: ` before parsing a mode's own output, and treat it as a stop (planted state), never as a brief's verdict."

Probe p1, same repository, `TMPDIR` naming a missing directory:
- snippet: `rc=2 out=[refuse d6: mktemp failed]`
- `bash scripts/build-loop.sh --state` direct: `rc=1 out=[]`, mktemp's message on stderr.

Probe p1, a perl whose `Digest::SHA` fails to load (via `PERL5LIB`): `rc=2 out=[refuse d6: main's first-parent history, ... or an object does not hash to its id]`; the real cause ("no Digest::SHA / Compilation failed") is only on stderr.

The snippet's Exit header documents this ("or a git read or / temp-dir step that fails"), so nothing is wrong against its own contract. The inconsistency is across the two layers. The scripts keep "planted state, exit 2, stdout" apart from "environment broke, exit 1, stderr". Behind the snippet both arrive as exit 2 and a `refuse d6:` line. U4 is told to read that line as planted state, so a full disk or a missing perl module would be reported to the user as a hostile loop. The perl WHY names only read and hash failures. Both are stops, so nothing unsafe runs; the cost is a misleading diagnosis.

**Recommendation:** The cheapest fix is the hand-off text, deferred to U4 with the existing row: "treat it as a stop and quote the WHY (and stderr); not every refusal is planted state". Optionally add "or perl failed" to the reader's WHY. Moving mktemp to exit 1 would match build-loop.sh but adds a third outcome U4 must parse, so it is not recommended.

#### 2. The snippet scrubs BASH_ENV and ENV for the script it runs, but not the perl variables that reach the verified reader, which decides what runs

**Severity:** Informational
**Location:** `test/lib/d6-snippet.bash:78`, `:87`
**Move:** 7 (asymmetry)
**Confidence:** Medium (the asymmetry is executed; whether it matters is a trust-model call, not mine)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED bash "$d/scripts/$s" "$@"` against `LC_ALL=C perl -e "$P" ...`. In probe p1, `PERL5LIB` put a substitute `Digest::SHA` in front of the real one, and the reader loaded it. Here the substitute died, so the snippet refused. A substitute whose `sha1_hex` returned its input's expected id would make the "uses only bytes it hashed" gate say yes to anything.

The lib's trust model trusts the caller's environment: "the caller's own environment is" (`scripts/lib/dev-cycle-read.sh:331-332`). build-loop.sh's --state header lists what it does not cover: "anything else such an environment can do (BASH_ENV, PATH)" (`scripts/build-loop.sh:549`). Under that model this is settled. The asymmetry is still visible to a reader of the contract. The snippet's header gives no reason for unsetting two variables, so a reader cannot tell whether BASH_ENV/ENV are unset as a defence (in which case PERL5LIB/PERL5OPT belong beside them) or for hygiene.

**Recommendation:** Add one clause to the header naming why BASH_ENV/ENV are unset and that perl's environment is the caller's (trusted), or add `PERL5LIB`/`PERL5OPT` to the perl call's environment. Routed to security for the trust-model call; no API change needed.

## Re-flagged settled decisions

| Row | Settled decision | How it shows here | Status |
|---|---|---|---|
| 2026-10-12 `feat/build-loop-u3b3`, "`refuse d6: WHY` (exit 2) can now precede any mode's output" (i2 B14) | Defer to U4: match `refuse d6: ` first, as a stop | Probe p1: `--main-log` through the snippet with main and master both present printed only `refuse d6: the default branch is not exactly one of main and master`, rc=2, with no `main MAIN -` line. "As a stop" covers U3b2's bootstrap. Finding 1 asks only for the row's "(planted state)" wording to be loosened. | Settled; not re-opened. |
| 704, amended by the 2026-10-12 `feat/build-loop-u3b3` row (i2 B15) | git_harden is no shell wrapper; U4 routes its git through a script mode or a pinned third HARDEN copy | Row 704's own text still ends "U3b3's git_harden is the shared wrapper"; the amendment lives in the later row and in the plan note ("row 704 amended"). A reader who lands on 704 alone gets the old premise. | Settled; the trigger text is stale by design (append-only log). |
| 2026-10-12 `feat/build-loop-u3b3`, `-c` vs count-pair precedence (i2 B18) | Won't-Fix: the snippet is the stricter side | The snippet header still says only "Its git carries the lib's HARDEN pairs and git_harden's environment (G; a test pins the two lists equal)" (`test/lib/d6-snippet.bash:32-33`), which is accurate. | Settled. |
| 2026-10-12 `feat/build-loop-u3b3`, canonical copy in test/lib/ (i2 B19) | Defer to U4 | Unchanged. | Settled. |
| 702 | --state is called with no git_harden pair exported | Executed: T33 (`build-loop-orchestrator.bats:423-424`) runs `--state` through the snippet → `ok`. The snippet exports no pair: G's pairs are `-c` on its own git calls, and the script runs under `env -u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED` only. | Settled; holds. |
| 548 | dev-cycle.sh runs no state_gate/default_gate | The lib header now says so ("dev-cycle.sh runs no state gate (row 548)"). The snippet's "before, not instead of, the script's own state and default-branch gates" (`test/lib/d6-snippet.bash:33-34`) holds for build-loop.sh's gated modes only. This is the Stage 1 Mostly Accurate item; not re-filed. | Settled. |
| 2026-10-12 `feat/build-loop-u3b3` moved-main Won't-Fix (i2 B3) | The snippet trusts refs/heads/main | Stage 1 r1's escalation (`test/lib/d6-snippet.bash:67`: in another project, a first-parent chain rewritten to end at a copy of 640cf007's public commit object selects "main" over the /opt copy) is about which copy runs, not about the interface. From the API side, the header's "In any other repository (another root, or not SHA-1) it runs the image copy" is the contract and is what an honest repository gets. Whether the moved-main row covers the forged-root case is the security reviewer's call. | Cross-reference only. |

## Cross-references (not re-filed)

- Stage 1, all three replicates: Incorrect (doc) "each comment names the other" (plan :326; c9648432's B10). build-loop.sh's store_check comment names the snippet, but the snippet never names store_check. This is a one-directional cross-reference in the contract text; it belongs to the fact-check rows.
- Stage 1: Stale `build-loop-orchestrator.bats:306` "git names the mismatch on stderr too" (only perl's line now).

## What Looks Good

- **Invocation and arguments.** `bash -s -- SCRIPT ARG...` passes the script's own grammar through unchanged. In probe p1, `dev-cycle.sh --help` through the snippet printed the 89-line header, rc=0. A missing or other first argument goes to stderr with exit 1 and no stdout (`d6: the first argument is build-loop.sh or dev-cycle.sh`), matching the scripts' usage convention.
- **One refusal shape for every planted-state check**, `refuse d6: WHY` on stdout with exit 2, follows the `refuse main-log:` precedent. Every WHY is constant text or a D6_OPT path, so no repository text reaches the line unscrubbed.
- **git_harden's contract is pinned from both sides.** Test 19 checks the exact `GIT_*` environment and the second-call no-op. Both "every git call carries HARDEN" tests (`build-loop-check.bats:1699-1701`, `build-loop-orchestrator.bats:542-545`) now read HARDEN from the lib, so a key added there cannot go unchecked (i2 B9).
- **The --state header and the dev-cycle.sh header now state their contracts** (B4, B12). The row-307 test's switch from `log.date` to `log.abbrevCommit` keeps its intent and carries a comment explaining the change.
- **Hand-offs** for U4 follow the precedent of earlier units: dated override rows plus a "U4 hand-offs" sentence in the plan's as-built note.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Failed mktemp or broken perl → `refuse d6:` exit 2 (scripts: exit 1, stderr); U4's hand-off reads every `refuse d6:` as planted state | Minor | `test/lib/d6-snippet.bash:72,78`; override row (U4 hand-off) | High |
| 2 | Snippet unsets BASH_ENV/ENV for the script but not PERL5LIB/PERL5OPT for its verified reader; header gives no reason (trust model: caller env trusted) | Informational | `test/lib/d6-snippet.bash:78,87` | Medium |

## Overall Assessment

The interface is consistent with the codebase's conventions. git_harden is named and placed like the lib's other helpers. `refuse d6:` and the exit-1 usage line follow build-loop.sh's split. The snippet passes each script's argument grammar through unchanged. Iteration 2's one Inconsistent item (B4) and its dev-cycle.sh documentation gap (B12) are fixed and confirmed by probe. The deferred hand-offs (B14, B15, B19) are recorded as rows and in the plan note, in the form earlier units used. Neither remaining finding blocks the merge. Finding 1 is a wording fix to a U4 hand-off: "a stop, quote the WHY", rather than "planted state". Finding 2 is a header clause or a trust-model call for security. Consumer impact on existing callers is limited to the documented dev-cycle.sh change: no user or system config, and no transport.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/api-consistency-review-2026-10-12-u3b3-final.md, structured per the api-consistency-reviewer skill.
- Answered: yes. I reviewed the snippet's invocation, arguments, refusal line and exit codes against build-loop.sh and dev-cycle.sh conventions and the plan's U4 hand-offs; git_harden's contract; dev-cycle.sh's changed behaviour; and the new override rows' hand-off text. I confirmed i2's B4 and B12 fixed, by probe and by reading.
- Out of scope: the forged-root and moved-main questions and the verified reader's parsing (security, Stage 1 escalation). Only the orchestrator suite was run (20/20), not build-loop-check.bats.
- Escalate: Finding 2's trust-model question to security. Finding 1 can ride the existing U4 hand-off row.
- Decisions I made: I filed Finding 1 as a cross-layer inconsistency even though the snippet's own Exit header documents it. I did not re-file anything a settled row covers; those are listed under "Re-flagged settled decisions".
