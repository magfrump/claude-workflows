Commit: 71e618d (A) / 8286c2b (B)

# Security Review — dev-cycle loop pass 12 (pass-11 fix round)

**Scope:** Partial. A: `git diff c034a75..71e618d -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (commits e08d526, 5dd5377, 71e618d), worktree `/workspace/.claude/wt-digest`. B: `git diff a218ad8..8286c2b -- skills/dev-cycle/SKILL.md docs/working/questions.md` (commit 8286c2b), worktree `/workspace/.claude/wt-devcycle`. Everything else is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass11.md` (Stage 1, pass 11, k=1), and pass 11's security review (`docs/reviews/security-review-2026-10-01-digest-pass11.md`, Finding 2) for the grading this round's fix answers.

Execution: during this review, the wt-digest working tree picked up uncommitted edits to `scripts/dev-cycle.sh` and `test/scripts/dev-cycle.bats` from another session (a `blocker()` helper shared by `skipped`/`skipdir`). The working tree therefore stopped matching 71e618d, and one working-tree bats run printed `not ok 10`. To get results that match the commit under review, every result below was re-run against files taken from the commit with `git show 71e618d:<path>` into `sec12/pinned/`. `timeout 300 bats test/scripts/dev-cycle.bats` there gave 22/22 `ok`. Probes P1–P8 ran `timeout 30 bash sec12/pinned/scripts/dev-cycle.sh` with `DEV_CYCLE_TODAY=2026-03-01` in throwaway repos made by `mktemp -d` under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec12/`. The pinned results match the earlier working-tree probe results. The uncommitted edits are out of scope and were not reviewed, though they appear aimed at Finding 1. Nothing was written to either worktree except this report. No background processes were left running.

Legibility-target values: **maintainer** (someone editing the script, tests or skill), **agent** (the model running the dev-cycle skill on the digest).

## Trust Boundary Map

```
B1:          [committed tree shape under docs/: symlinks, non-regular files] → [skipped() parent walk :104-113, skipdir() :114, plaindir()/inrepo() :92-95] → [digest section 8, section 2/3/5/7 status lines, Window line]
B2:          [committed file names: cycle-YYYY-MM-DD.md glob items]           → [glob pattern :141 + ${f##*/cycle-} :142]                                    → [Window line note :160]
B3:          [digest stdout (section 8, Window line)]                          → [dev-cycle skill step 0, SKILL.md:100-106]                                 → [cycle record + `agent` entry in questions.md (committed, pushed)]
B4:          [build-brief text: date, `Kept:` line, branch]                    → [agent applying SKILL.md:217-223]                                          → [`you: judgment` entry; In-flight slot count]
```

Input-source classification:

```
S1: committed tree entries (symlink targets, file types) — repo content, changes with any commit — UNTRUSTED for path-resolution / existence-probe sinks
S2: committed file names in docs/working/cycles, docs/decisions — repo content — UNTRUSTED for text-output sinks (Window line, section 8)
S3: host filesystem behind a symlink target — the protected asset — must not reach any output sink (not even existence)
S4: TODAY (DEV_CYCLE_TODAY or `date`) — environment — trusted (all sinks)
S5: digest output text — derived from S1/S2 — UNTRUSTED toward agent-instruction sinks (data, never directions)
S6: brief text (dates, `Kept:`, branch) — repo content written by the cycle or user — untrusted for git-argument sinks; trusted for slot accounting (no cross-user boundary)
```

What enters from outside is the repo's committed tree (S1, S2): a clone can carry symlinks and odd file types. The diff's stated property this round is that below a parent that is not a plain directory nothing is probed, so the digest (and the committed cycle record built from it) reveals nothing about the host directory S1 points at (S3). `skipped()` now meets that property. `skipdir()`, the other recorder, does not (Finding 1).

## Findings

#### 1. `skipdir()` still probes through a symlinked ancestor, so section 8 reveals whether `decisions/` and `working/cycles/` exist in the host directory a committed symlink points to

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:114`, called at `:152` and `:195`. False claims about it are at `:101-103`, `:347`, and in the messages of commits 5dd5377 and 71e618d.
**Boundary:** B1 (S1 → S3 → section 8 → B3's committed record)
**Move:** 1 (per-consequence trust), 11 (bypass of the parent walk), 12 (sweep of existence probes)
**Confidence:** High that the mechanism exists (executed, P1 and P2). Likelihood is low: it needs a committed symlink at `docs` or `docs/working`, a cycle run, and a pushed record.
**Legibility-target:** maintainer

**Evidence (verbatim):**
```bash
# scripts/dev-cycle.sh:114
skipdir() { if [[ -e "$1" || -L "$1" ]] && ! plaindir "$1"; then SKIPPED+=("$1/"); return 0; fi; return 1; }
```
```bash
# scripts/dev-cycle.sh:347
  echo "Reached through a symlink, or not a regular file or directory, so not read; nothing below a listed directory was read or probed:"
```
Commit 5dd5377: "The committed record no longer reveals which fixed names exist in a directory a symlink points to." Commit 71e618d: "says nothing below a listed directory was read or probed (true since 5dd5377)".

P1 committed `docs` as a symlink to `$T/outside`. When `outside` held neither `decisions/` nor `working/cycles/`, section 8 listed only `- docs/`. After `mkdir -p outside/decisions outside/working/cycles`, the same repo's section 8 listed `- docs/`, `- docs/decisions/` and `- docs/working/cycles/`. `[[ -e "$1" ]]` in `skipdir` follows the symlinked `docs`, and `skipdir` does not walk its parents. That is the pass-11 Finding 2 leak (one bit per fixed name about a directory a committer chooses), and this round fixed it only in `skipped()`. The fixed names `decisions` and `working/cycles` remain. The section 8 header, the `skipped()` comment and both commit messages now say this cannot happen, and a listed `docs/` with a listed `docs/decisions/` below it contradicts the header on its face.

Second consequence (integrity, same root cause): when `docs/working` (P2) or `docs` is a symlink whose target has no `cycles/`, `skipdir` returns 1 and `records_skipped` stays 0. The Window line then reads `no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)` while section 8 lists `- docs/working/`. Step 0 (SKILL.md:100-102) routes that wording to "that cycle skipped step 7", not to the skipped-record branch this round added. Writes stay safe because the skill's never-through-a-symlink rule (SKILL.md:60-68) still blocks a record written through `docs/working`. The cost is a misattributed note in the record.

Graded Low, as pass 11 graded the same leak ("minor information leak": fixed names, one bit each). Exploitability is not the issue here; the incomplete fix and its false claims are.

**Recommendation:** Move the parent walk out of `skipped()` into a shared helper and call it from `skipdir()` before its `-e` probe, so a non-plain ancestor is recorded and nothing below it is probed. For example, `skipdir docs/decisions` would record `docs/` when `docs` is the symlink. Count a skipped ancestor of `docs/working/cycles` in `records_skipped`, so the Window line says "skipped" and not "no cycle record found". Extend test 7 or add a test: symlink `docs` to a target that holds `decisions/` and `working/cycles/`, then assert section 8 lists only `- docs/`.

#### 2. The "nothing is probed" comment is literally false for `inrepo`/`plaindir`, which stat through a symlinked parent before `skipped()` runs (no output channel)

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:101-103` (comment); probes at `:206`, `:228`, `:263`, `:313`, `:324` via `inrepo` (`:92`)
**Boundary:** B1
**Move:** 12 (sweep of existence probes)
**Confidence:** High (read-static; no strace in the sandbox, so not observed directly)
**Legibility-target:** maintainer

**Evidence (verbatim):**
```bash
# scripts/dev-cycle.sh:101-103
# Parents are checked first, top down: below a parent that is not a plain
# directory nothing is probed (not even whether a file exists there), and the
# parent is what gets recorded.
```
```bash
# scripts/dev-cycle.sh:206 … :218 (if-branch body elided)
if inrepo docs/decisions/log.md; then
  … [log-row loop, :207-216]
else
  skipped docs/decisions/log.md || true
fi
```
`inrepo` runs `[[ -f "$1" ]]` and then possibly `realpath -e` on the full path. Both follow a symlinked `docs/decisions`, before `skipped()` gets the chance to walk the parents. Its result is always false for such a path, because the realpath cannot equal `$ROOT_REAL/$1`, so no output differs (test 7 and P1–P2 confirm). The only residual effect is a `stat` on a path the committer chose. A path on a hung network mount could stall the run, which is availability only, and requires that mount to exist on the runner's host. No reachable confidentiality mechanism, so Informational.

**Recommendation:** Reword the comment to "nothing below it is reported (no output depends on whether a file exists there)". Alternatively, make the read sites call the parent walk before `inrepo`, which would also cover Finding 1 if the helper is shared.

#### Step B (skill and docs): no findings

The step 0 rewrite (SKILL.md:103-106) answers pass-11 Finding 3. "fix or report the link" is gone. The text now says "file one `agent` entry reporting the path (never read, copy or rewrite through it)", so the agent is no longer invited to resolve a link target into a committed file. Its trigger phrases match the digest's two texts: "one or more were skipped as not plain files" (`:165`) and "a newer record, cycle-…md, was skipped" (`:160`). The one uncovered case comes from Finding 1's Window misclassification, not from the skill. The stale-brief rule (SKILL.md:219-223) is cleared. A future-dated `Kept:` date would keep a brief from ever being nudged, but brief text is written by the cycle or the user (S6), with no cross-user boundary, so that is slot accounting, not security. Q-103's "harness settings" now matches the seed's rule 3 verbatim (`docs/working/seed-build-loop-handoff.md:33-35`). Its security meaning is unchanged.

## Untested bypass candidates

For the guardrail `skipped()` parent walk (`:104-113`). Tested by execution: a symlinked `docs` (P1, live and with targets present), a symlinked `docs/working` whose target holds `questions.md` and `idea-log.md` (P2: both read "not a plain file", section 8 lists only `- docs/working/`), a dangling `docs` (P3), `docs` as a regular file (P4), a self-referential `docs` loop (P5), and a directory and a FIFO as decision glob items (P6). Each recorded only the first non-plain component and printed no outside name. Traced in code but not executed: an absolute path (first component `""`: `-e ""` is false, return 1, treated as absent), `..` (`docs/..` fails `plaindir`, so it is recorded and stops), and a trailing slash. None can reach the function, because every call site passes a constant or a glob item under a parent already checked to be plain.

Not tested:
- **Concurrent replacement of a checked parent between `plaindir` and the read (TOCTOU).** It needs a local writer racing the run, which is outside the committed-content threat model. Not exercised.
- **A bind mount at `docs`.** `realpath` would pass it as plain. It needs control of the host's mounts. Not exercised.

Because of these candidates, `skipped()` does not appear in the Endorsement Claims below.

## Endorsement Claims

- **Claim:** The Window-line note interpolates only the date part of a cycle record's name, and that part is limited to the glob's `[0-9]` positions and `-`, so no attacker-chosen text reaches the Window line through it.
  **Location:** `scripts/dev-cycle.sh:141-146,159-160`
  **Evidence:** read-static
  **Verified:** `d="${f##*/cycle-}"; d="${d%.md}"` takes the name from the glob `cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md`. The note is assigned only after `skipped "$f"` returns 0, which requires the entry to exist, so an unmatched literal pattern is excluded.
  **Not verified:** the shell's glob behaviour under a non-default `GLOBIGNORE` or `extglob` inherited from the caller's environment.
  **route: code-fact-check**
- **Claim:** The note names the newest skipped record that is not future-dated, and only when it is newer than the record the window starts from.
  **Location:** `scripts/dev-cycle.sh:146,159`
  **Evidence:** executed
  **Verified:** P7 (readable 2026-01-01, skipped 2026-02-01, 2026-02-20 and 2027-01-01, TODAY 2026-03-01) names `cycle-2026-02-20.md`. P8 (skipped 2026-01-01, readable 2026-02-01) adds no note. The test `a skipped newer cycle record is named in the window line` passes. bats prints it as `ok 10`, but the e08d526 message calls it "New test 3", which is wrong.
  **Not verified:** the `--since` path (`:155-156`), where the note is not printed at all even when a newer record was skipped.
  **route: code-fact-check**
- **Claim:** Section 2's skip count now includes a skipped `docs/decisions`, so a symlinked decisions directory prints "No revisit triggers read" and not "No revisit triggers recorded".
  **Location:** `scripts/dev-cycle.sh:193-195,220-222`
  **Evidence:** executed
  **Verified:** P1 prints `No revisit triggers read: decision records or the log were skipped as not plain files (section 8).`, and test 7's new assertion passes.
  **Not verified:** a decisions directory that is plain but whose every record is skipped, with no `log.md` present (counted by `skipped "$f"` at `:197`; not run).
  **route: code-fact-check**

## Primitive sweep

Primitive: filesystem existence/type probes that follow symlinks (`-e`, `-d`, `-f`, `realpath -e`). This is the S3 disclosure path.

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:108-109` `skipped()` parent loop | S1 | top-down: each probe sits under a parent already checked to be plain | cleared (P1–P5) |
| `:111` `skipped()` leaf | S1, S2 | all parents plain | cleared |
| `:114` `skipdir()` via `:152` (`docs/working/cycles`) | S1 | none for its ancestors | Finding 1 |
| `:114` `skipdir()` via `:195` (`docs/decisions`) | S1 | none for its ancestors | Finding 1 (P1) |
| `:140` `plaindir docs/working/cycles` | S1 | none (result constant under a symlinked ancestor) | cleared: output is the same either way; Finding 2's note covers the stat |
| `:195` `plaindir docs/decisions` | S1 | same | cleared, same reason |
| `:143`, `:197` `inrepo` on glob items | S1, S2 | parent plain (glob only runs inside a plain directory) | cleared |
| `:206`, `:228`, `:263`, `:313`, `:324` `inrepo` on fixed names | S1 | none for ancestors | Finding 2 (no output channel) |

Primitive: file reads (`grep`, `awk`, `<`) are cleared at every site (`:198`, `:204`, `:216`, `:267`, `:315`, `:329-330`): each one comes only after `inrepo` succeeds on the same path, and S1 is committed content with no concurrent writer (see Untested: TOCTOU).

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `skipdir()` probes through a symlinked ancestor; section 8 reveals `decisions/` / `working/cycles/` existence at the target. The header and the 5dd5377/71e618d claims are false for it, and the Window line misreports a skipped ancestor as "no cycle record found" | Low | B1, B3 | `scripts/dev-cycle.sh:114` (via `:152`, `:195`); `:101-103`, `:347` | High (executed) |
| 2 | "nothing is probed" comment is false for `inrepo`'s stat through a symlinked parent; no output channel | Informational | B1 | `scripts/dev-cycle.sh:101-103`, `:92` | High (read-static) |

## Overall Assessment

The round's main security fix is right where it applies. `skipped()` now records the first non-plain ancestor and probes nothing below it, and executed probes P1–P6 plus test 7 confirm this for live, dangling, looped and regular-file parents. The step 0 rewrite removes pass-11's invitation to copy a link target into a committed file. The fix is incomplete, though. `skipdir()`, the second recorder, was not given the parent walk. The leak pass 11 graded Low therefore survives for the fixed names `decisions/` and `working/cycles/`, while the section 8 header and two commit messages now state that it cannot happen. This is fixable in place: share the walk with `skipdir()`, count a skipped ancestor in `records_skipped`, and add one test with a symlinked `docs` whose target holds both directories. Nothing here is architectural. There are no findings within the other code paths read; the endorsement claims are pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-01-digest-pass12.md` with the requested first line. It follows the security-reviewer skill's structure: trust boundary map, source table, findings anchored to boundaries, untested bypass candidates, endorsement claims routed to code-fact-check, primitive sweep, summary table and overall assessment. It covers the pass-11 fix round only. Finding 1 is a residual of a pass-11 finding that this round set out to close, so it bears directly on the "no known issues remain" condition for merging.
