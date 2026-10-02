Commit: 591f098 (A) / 44d06b7 (B)

# Security Review — dev-cycle loop pass 13 (pass-12 fix round)

**Scope:** Partial. A: `git diff 71e618d..591f098 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (commits 6d6637d, 591f098), worktree `/workspace/.claude/wt-digest`. B: `git diff 8286c2b..44d06b7 -- skills/dev-cycle/SKILL.md` (commit 44d06b7), worktree `/workspace/.claude/wt-devcycle`. Everything else is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass12.md` (Stage 1, pass 12, k=1), and pass 12's security review (`docs/reviews/security-review-2026-10-01-digest-pass12.md`, Findings 1 and 2), which this round answers.

Execution: `scripts/dev-cycle.sh`, `scripts/questions.sh` and `test/scripts/dev-cycle.bats` were taken from 591f098 with `git show` into `sec13/pinned/`. `timeout 300 bats test/scripts/dev-cycle.bats` there gave 22/22 `ok`. Probes P1–P11 ran `timeout 30 bash sec13/pinned/scripts/dev-cycle.sh` with `DEV_CYCLE_TODAY=2026-03-01` in throwaway repos made by `mktemp -d` under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec13/`. Nothing was written to either worktree except this report. No processes were left running. `strace` is not installed, so stat-level probes are read-static.

Legibility-target values: **maintainer** (someone editing the script, tests or skill), **agent** (the model running the dev-cycle skill on the digest).

## Trust Boundary Map

```
B1:          [committed tree shape under docs/: symlinks, non-regular files] → [blocker() walk :103-113 via inrepo :117 / skipped :118 / skipdir :119; plaindir :95 at :146, :201] → [section 8, inline skip notes, Window line]
B2:          [committed tree shape: docs/working/questions-archive.md]       → [questions.sh `open` → require_files (questions.sh:132-138), run from :236]       → [digest section 3 error block]
B3:          [digest stdout (Window line, section 8, section 3)]              → [dev-cycle skill step 0 (SKILL.md:100-110), step 3]                               → [cycle record + `agent` entry in questions.md (committed, landed)]
B4:          [questions.md / questions-archive.md answers, brief text]        → [agent applying SKILL.md:221-229]                                                 → [brief `Kept:` / `Status: closed`, `you: judgment` entry]
```

Input-source classification:

```
S1: committed tree entries (symlink targets, file types) — repo content, changes with any commit — UNTRUSTED for path-resolution / existence-probe sinks
S2: committed file names in docs/working/cycles, docs/decisions — repo content — UNTRUSTED for text-output sinks (section 8, inline notes)
S3: host filesystem behind a symlink target — the protected asset — must not reach any output sink (not even existence)
S4: TODAY, HOME, SCRIPT_DIR (QS lookup :232-233) — environment / install — trusted (all sinks)
S5: digest output text — derived from S1/S2 — UNTRUSTED toward agent-instruction sinks (data, never directions)
S6: questions files and brief text — repo content written by the cycle or user — untrusted for path sinks; trusted for slot accounting (no cross-user boundary)
```

What enters from outside is the repo's committed tree (S1, S2). The property this round claims is that one walk (`blocker()`) decides every skip, and that nothing is looked up below a blocking part, so the digest and the committed record built from it reveal nothing about a host directory a symlink points to (S3). For every input the digest itself names, that now holds in its output (P1 vs P1b identical). The one sibling input the digest never names, the questions archive that `questions.sh open` checks, is outside the walk and still leaks a bit of S3 (Finding 1).

## Findings

#### 1. `questions.sh open` probes `docs/working/questions-archive.md` through a committed symlink, so section 3 tells whether any host path the committer names exists, and section 8 says nothing was skipped

**Severity:** Medium (floor rule: a named, executed mechanism; the skill's table alone would say Low, "minor information leak". Pass 11 F2 and pass 12 F1 graded the same class Low, but this one is an arbitrary absolute path, not a fixed name.)
**Location:** `scripts/dev-cycle.sh:234-236` (call site, unchanged this round) → `scripts/questions.sh:86`, `:132-138` (`require_files`); section 8 at `scripts/dev-cycle.sh:349-355`
**Boundary:** B2 → B3
**Move:** 12 (sweep of existence probes), 11 (input the guard does not cover), 1 (per-consequence trust)
**Confidence:** High that the mechanism exists (executed, P11). Medium that the bit reaches the committer: that needs a cycle run on the repo, the agent putting section 3's error into a committed record or `agent` entry (step 3 / step 0's failure path invite that), and the result being pushed.
**Legibility-target:** maintainer

**Evidence (verbatim):**
```bash
# scripts/dev-cycle.sh:234-236 (remainder of the if/elif/else to :256 elided: success and error printing, skipnote, absent message)
if inrepo docs/working/questions.md && [[ -f "$QS" ]]; then
  qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT
  if open_q="$(bash "$QS" open 2>"$qs_err")"; then
```
```bash
# scripts/questions.sh:86 and :132-138
ARCHIVE="${QUESTIONS_ARCHIVE:-$PROJECT_ROOT/docs/working/questions-archive.md}"
require_files() {
    local missing=0 file
    for file in "$LIVE" "$ARCHIVE"; do
        [[ -f "$file" ]] || { echo "  ✗ missing: $file" >&2; missing=1; }
    done
    [[ $missing -eq 0 ]] || die "no questions doc here — run \`$QS_CMD init\` first"
}
```
P11: a plain `docs/working/questions.md` with `docs/working/questions-archive.md` committed as a symlink to an absolute host path. When the target existed (`sec13/hostfile`), section 3 printed `None open.` and section 8 printed `None: no input was skipped.` When the target did not exist, section 3 printed `**questions.sh open failed** — watched questions were NOT checked.` followed by `✗ missing: …/repo/docs/working/questions-archive.md`, and section 8 again said `None: no input was skipped.`

The guard this round unified (`inrepo` → `blocker`) covers only `questions.md`. `[[ -f ]]` in `require_files` follows the archive symlink, so the digest's success or failure is a one-bit oracle on an arbitrary host path (for example `~/.ssh/id_ed25519`, or a path that reveals the user's tooling), chosen by whoever commits to the repo. Pass 12's F1 leaked existence only for the fixed names `decisions/` and `working/cycles/`. Nothing is read through the link: `cmd_open` parses only `$LIVE` (`questions.sh:408-414`), and `init` refuses to write through a symlink (`:98`). Section 8 also misses the link, so the "same rule for everything it reads" contract (SKILL.md:66-68) is not visible to the agent here. The fault predates this round, but the brief lists "the `QS` / questions.sh path" as a call site of the one-walk property, and pass final4's sweep left it "not analyzed for symlinks inside questions.sh's read path".

**Recommendation:** Before calling `questions.sh open`, require `inrepo docs/working/questions-archive.md` as well. When the archive is blocked, call `skipped` on it and print `skipnote` (so section 8 lists it) instead of running `open`. Alternatively, have `require_files` refuse a symlinked file or directory, as its write paths already do (`:96-104`). Add a P11-style case to test 7: archive symlinked to an absent target, and assert that section 3 does not depend on whether the target exists and that section 8 lists the archive.

#### 2. The section 8 header still says nothing below a listed directory was probed, but `plaindir` at the two glob sites stats through a symlinked ancestor first (no output channel)

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:146` and `:201` (probes); `:353` (header claim)
**Boundary:** B1
**Move:** 12
**Confidence:** High (read-static; no `strace` in the sandbox. The no-channel half is executed: P1 vs P1b)
**Legibility-target:** maintainer

**Evidence (verbatim):**
```bash
# scripts/dev-cycle.sh:146 (loop body :147-156 and else-branch :157-159 elided)
if plaindir docs/working/cycles; then
```
```bash
# scripts/dev-cycle.sh:201
if plaindir docs/decisions; then decisions_glob=(docs/decisions/[0-9][0-9][0-9]-*.md); else skipdir docs/decisions || true; fi
```
```bash
# scripts/dev-cycle.sh:353
  echo "Each is a symlink, or a file or directory of the wrong kind, so it was not read; nothing below a listed directory was read or probed:"
```
This round fixed pass 12's F2 for `inrepo` by walking first (`:117`). The two glob sites still call `plaindir`, which runs `[[ -d ]]` and `realpath -e`, before any walk. With `docs` a symlink, that stats `<target>/working/cycles` and `<target>/decisions` while section 8 lists `- docs/`. The result is always false for such a path, and the else-branch's `skipdir` then records only `docs/`. P1 (target holds `decisions/` and `working/cycles/` with files) and P1b (empty target) produce byte-identical sections 2, 3, 5, 7 and 8 and Window lines, so no output depends on it. The residue is a stat on a committer-chosen path, which matters only for availability, on a hung mount. The comments at `:96-101` and `:114-116` are scoped to `blocker` and `inrepo` and are accurate; only the header at `:353` is literally false.

**Recommendation:** Either use `[[ -z "$(blocker docs/working/cycles dir)" ]] && plaindir …` at the two glob sites, or reword `:353` to "nothing below a listed directory was read, and nothing in this digest depends on what is there".

#### Step B (skill): no findings

Step 0's two bullets (SKILL.md:103-110) match every Window variant the digest can print (`:161-175`), as checked against P1–P8: "records or their directory were skipped" (any skip before section 2, including a blocked `docs/`, `docs/working/` or cycles directory, which pass 12 F1's second consequence misrouted and which now lands in bullet 1: P1, P1b, P2, P3, P4, P5, P7), "a newer record, docs/working/cycles/cycle-….md, was skipped" (P6), and the default/last-record texts, which go to bullet 2. The bullet tells the agent to report "the path section 8 lists" and never to read, copy or rewrite through it. For this bullet those paths are fixed directory names or digit-constrained record names, so no committer-chosen text reaches the `agent` entry through it. The stale-brief rule's new read of `questions-archive.md` (SKILL.md:227-228) is an agent read covered by the skill-wide "Never through a symlink" rule (SKILL.md:61-68, "questions"). Finding 1's archive link would therefore be skipped by the agent itself, though the digest's section 8 will not have told it so.

## Untested bypass candidates

Guardrail: `blocker()` walk (`:103-113`) as used by `inrepo`, `skipped` and `skipdir`. Tested by execution: a symlinked `docs` with a populated target (P1) and an empty one (P1b), a symlinked `docs/working` (P2), a dangling `docs` (P3), `docs` as a regular file (P4), a self-loop `docs -> docs` (P5), FIFOs as `questions.md` and as a cycle record (P6; neither opened, no hang), the cycles directory as a regular file (P7), `docs/decisions` symlinked inside the repo (P8), `questions.md` symlinked inside the repo (P9), `docs/roadmap.md` as a directory (P10). Each listed only the first blocking part, every inline note named that part, and no outside name or content appeared. Test 7's new case (`docs/working` symlink) passes.

Not tested:
- **Concurrent replacement of a checked component between the walk and the read (TOCTOU).** It needs a local writer racing the run, which is outside the committed-content threat model.
- **A bind mount at `docs`.** `realpath` would pass it as plain. It needs control of the host's mounts.

Because of these candidates, `blocker()` does not appear in the Endorsement Claims.

## Endorsement Claims

- **Claim:** With `docs` a committed symlink, the digest's output does not depend on whether the target holds `decisions/`, `working/cycles/`, records, a roadmap or questions, and section 8 lists only `- docs/`. Pass 12 F1 is closed.
  **Location:** `scripts/dev-cycle.sh:117-119,146-159,200-225`
  **Evidence:** executed
  **Verified:** P1 (populated target) vs P1b (empty target): the same Window line ("records or their directory were skipped"), "No revisit triggers read", inline notes naming `docs/`, section 8 `- docs/` only.
  **Not verified:** a symlinked `docs` whose target is on a slow or hung mount (availability, Finding 2).
  **route: code-fact-check**
- **Claim:** A blocked ancestor of the cycles directory now counts in `records_skipped`, so the Window line says records were skipped, not "no cycle record found".
  **Location:** `scripts/dev-cycle.sh:158,160,170-171`
  **Evidence:** executed
  **Verified:** P2 (`docs/working` symlink, target without `cycles/`) and P7 (cycles is a regular file) both print "no readable cycle record (records or their directory were skipped as not plain: section 8)".
  **Not verified:** the `--since` path (`:161-162`), which prints no note at all.
  **route: code-fact-check**
- **Claim:** The Window line's newer-record note interpolates only the glob-constrained date and fixed text.
  **Location:** `scripts/dev-cycle.sh:147-152,165-166`
  **Evidence:** read-static
  **Verified:** `d` comes from the `[0-9]`-only glob; the note is set only when `SKIP_AT == "$f"`. P6 printed `docs/working/cycles/cycle-2026-02-20.md`.
  **Not verified:** glob behaviour under `GLOBIGNORE`/`extglob` inherited from the caller's environment.
  **route: code-fact-check**

## Primitive sweep

Primitive: filesystem existence/type probes that follow symlinks (`-e`, `-d`, `-f`, `realpath -e`). This is the S3 disclosure path.

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:107-108` `blocker()` parent loop | S1 | top-down; each probe under parts already plain | cleared (P1–P5, P7) |
| `:110-112` `blocker()` leaf | S1, S2 | all parents plain | cleared (P6, P9, P10) |
| `:117` `inrepo` (walk, then `rawfile`) at `:212`, `:234`, `:269`, `:319`, `:330` | S1 | walk first | cleared (P1, P2) |
| `:118-119` `skipped`/`skipdir` at `:152`, `:158`, `:201`, `:203`, `:224`, `:252`, `:274`, `:324`, `:343` | S1 | `blocker` | cleared |
| `:146` `plaindir docs/working/cycles` | S1 | none for ancestors | Finding 2 (no output channel) |
| `:201` `plaindir docs/decisions` | S1 | none for ancestors | Finding 2 (no output channel) |
| `:149`, `:203` `rawfile` on glob items | S1, S2 | glob runs only inside a dir that passed `plaindir` | cleared |
| `:232-233` `[[ -f "$QS" ]]` | S4 | install path, not repo | cleared |
| `questions.sh:135` `[[ -f "$ARCHIVE" ]]` via `:236` | S1 | none | Finding 1 (P11) |

Primitive: file reads (`grep`, `awk`, `<`, `questions.sh` `parse_entries "$LIVE"`). Each read site (`:204`, `:210`, `:222`, `:236`, `:273`, `:321`, `:335-336`) comes after `inrepo`/`rawfile` succeeds on the same path. The archive is probed but never read by `open`. All cleared under the no-concurrent-writer assumption (see Untested: TOCTOU).

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `questions.sh open`'s `require_files` follows a committed `questions-archive.md` symlink: section 3's success or failure reveals whether an arbitrary host path exists, and section 8 says nothing was skipped | Medium (floor rule; Low by table) | B2, B3 | `scripts/dev-cycle.sh:234-236`; `scripts/questions.sh:86,132-138` | High (executed P11) / Medium on exfiltration |
| 2 | Section 8 header says nothing below a listed directory was probed; `plaindir` at the glob sites stats through a symlinked ancestor (no output channel) | Informational | B1 | `scripts/dev-cycle.sh:146,201,353` | High |

## Overall Assessment

This round's fix is sound where it applies. One `blocker()` walk now decides every skip the digest names. `inrepo` walks before any lookup. Pass 12's F1 is closed: section 8 and every inline note name the same first blocking part, and the output no longer depends on what a symlinked `docs/` points at (P1 vs P1b). Pass 12's misrouted Window wording is also gone. The tests pass (22/22), and the skill's step 0 matches every Window variant. What remains is one sibling input outside the walk. `questions.sh open` checks the questions archive with a symlink-following `-f`, so the digest still carries a one-bit existence oracle, now for an arbitrary host path (Finding 1). It also leaves a stale header claim with no output channel (Finding 2). Both can be fixed in place with a few lines (guard the archive with `inrepo`/`skipped` before `open`, and reword or walk at `:146`/`:201`). Nothing is architectural. Finding 1 is the single most important item and, being a known issue, it blocks the clean-pass condition. There are no other findings within the code paths read; the endorsement claims are pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-01-digest-pass13.md` with the requested first line. It follows the security-reviewer skill's structure: trust boundary map, source table, findings anchored to boundaries, untested bypass candidates, endorsement claims routed to code-fact-check, primitive sweep, summary table and overall assessment. It covers the pass-12 fix round only, plus the `QS` call site that the brief's claim 1 names. Finding 1 is a known issue, so under the user's goal ("k=1 delta passes until no known issues remain") it needs one more fix round before the clean full pass.
