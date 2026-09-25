# Code Fact-Check Report

**Repository:** claude-workflows, worktree `/workspace/.claude/wt-copyinstall`, branch `ans/copy-install` at `b4fd792`
**Scope:** commit range `9ae6e46..b4fd792` (8 commits), limited to `devcontainer-config/install.sh`, `test/install-host.bats`, `test/cc-isolated-functions.bats`, `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `guides/bare-host-hook-wiring.md`, `docs/working/plan-copy-install-bare-host.md`, and the commit messages. `docs/reviews/` files in the range were read as context only. Merged from three independent replicate reports (`code-fact-check-report-r1.md`, `-r2.md`, `-r3.md`) by most-severe-wins; commit-message locations `review/log.txt:<line>` follow r1's convention (r1's scratchpad copy of `git log 9ae6e46..b4fd792`).
**Checked:** 2026-09-24
**Commit:** b4fd792
**Replication:** k=3
**Total claims checked:** 48
**Summary:** 28 verified, 15 mostly accurate, 0 stale, 3 incorrect, 2 unverifiable

Merge provenance. Replicate claim counts: r1 32, r2 31, r3 25. They merge into 48 clusters (47 numbered positions, with the fa69656 `| vis` note split into 10a/10b as r3 split it). A replicate that verdicted a sentence or several locations as one compound claim has its verdict recorded on each finer-grained row, annotated `(compound)`. The headline evidence, `Scope`, `Confidence`, `Verification mode` and `Legibility-target` of each claim come from the replicate named in its `Carried from` line. Execution logs cited below are the replicates' own: r1 under `docs/reviews/execution-logs/` with prefix `q058-r1-`, r2 under `docs/reviews/execution-logs/q058-b4fd792-r2/`, r3 under `docs/reviews/execution-logs/q058-r3-b4fd792/`. Test IDs P1–P5 and E1–E6 are r2's probe and run labels; X1–X4 are r1's and r3's scratch probes (numbered independently per replicate).

---

## Claim 1: "Before it stages anything, and again after each y, it refuses while a Claude Code process of your uid or a running cc-isolated container (it can write the checkout through its bind mount) is found, and names each one with how to stop it."

**Location:** `README.md:33-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers where the gate is called and what its refusal message says. It does not establish that the probe finds every agent (see Claims 14, 25 and 30), and it does not establish that anything runs between the calls: the gate takes a sample at three points and does not watch continuously (Claim 24).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "the gate samples three moments rather than watching continuously; does not establish coverage between check points" · r1+r2+r3: "does not establish that the gate/detectors find every real agent" · r2: "The README's wording is precise: 'is found' at a check point. Unlike the guide (Claim 35), it does not claim continuous refusal." · r1: verdicted README:33-39 and `guides/bare-host-hook-wiring.md:17-20` as one claim (see Claim 35) · r3: Scope also claims to cover the same statement in `--help` (`install.sh:51-58`, see Claim 2) and in the guide.

Carried from r1 Claim 1. The three call sites are `install.sh:947`, `:391` and `:695` (Claim 13). The refusal names each process and container and says how to stop each one:

```bash
# devcontainer-config/install.sh:873-882
    if [ -n "$procs" ]; then
      echo "       Claude Code processes of uid $(id -u) (PID and command line):"
      printf '%s\n' "$procs" | sed 's/^/           /'
      echo "       Stop them: end each Claude Code session (/exit), or kill <PID>."
    fi
    if [ -n "$ctrs" ]; then
      echo "       Running cc-isolated containers (name and project id):"
      printf '%s\n' "$ctrs" | sed 's/^/           /'
      echo "       Stop them: docker stop <name>"
    fi
(excerpt ends :882; enclosing agent_gate() continues to :886 — read)
```

Executed: `bats test/install-host.bats`, cwd `/workspace/.claude/wt-copyinstall`, 2026-09-25T06:38:42Z, exit 0, 64/64 ok. T50 (refused at startup, with no `[y/N]`, no `Canonical` line and no mirror created), T51 (container named, `docker stop`), T54 and T55 (refused after each y) all pass.

**Evidence:** `devcontainer-config/install.sh:390-391`, `:694-695`, `:870-885`, `:947`; `test/install-host.bats:791-887`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 2: "install.sh refuses, before it stages anything and again after each y, while any agent can run: a Claude Code process of your uid (pgrep on the command line), or a running cc-isolated container (docker ps, label cc-project). It names each one and how to stop it."

**Location:** `devcontainer-config/install.sh:51-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the check points, the two detectors as named, and the naming of each process or container. It does not establish that "while any agent can run" holds between check points or for processes the regex misses (the next sentences of `--help` define "agent" as exactly the two detectors, which is what was verified).
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: verdicted `install.sh:51-58` as one claim (split here into Claims 2, 3, 4) · r3: verdict taken from r3 Claim 1, whose Scope states it covers "the same statement in … `--help` (`install.sh:51-58`)"; "does not establish that the gate detects every real agent … the gate samples three moments rather than watching continuously".

Carried from r2 Claim 2. The detectors are `pgrep -u "$(id -u)" -af -- "$CLAUDE_PROC_RE"` (`:845`) and `timeout 20 docker ps --filter label=cc-project` (`:860`). In S1, T50–T55 (check points, naming) and T56 (`--help` mentions both detectors) passed.

**Evidence:** `devcontainer-config/install.sh:838-886`; `test/install-host.bats:822-899`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 3: "Without pgrep it refuses"

**Location:** `devcontainer-config/install.sh:56`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers missing pgrep, pgrep exit >1, missing docker, and docker exiting non-zero. It does not establish the case where docker hangs past 20 s. That case is also treated as unreachable (`timeout 20` exits 124), so it fails open with the same NOTE. Nor does it establish a docker that answers from a different daemon than cc-isolated's: that returns an empty list with no NOTE.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2+r3: verdicted the pgrep and docker halves of the `--help` sentence together (docker half is Claim 4) · r2: the same code path's commit-message form ("No pgrep: refuse.") is Claim 17; "does not establish pgrep's behaviour on non-procps implementations (such as a BSD pgrep)".

Carried from r3 Claim 3.

```bash
# devcontainer-config/install.sh:840-849
  if ! command -v pgrep >/dev/null 2>&1; then
    echo "ERROR: pgrep is not installed, so install.sh cannot check that no Claude Code" >&2
    echo "       session is running (Q-058). Install procps and rerun. $what" >&2
    exit 1
  fi
  procs="$(pgrep -u "$(id -u)" -af -- "$CLAUDE_PROC_RE")" || rc=$?
  if [ "$rc" -gt 1 ]; then
    echo "ERROR: pgrep failed (exit $rc) while checking for Claude Code sessions (Q-058). $what" >&2
    exit 1
  fi
```
(excerpt ends :849; the enclosing `agent_gate()` continues to :886, read)

Test T53 passes.

**Evidence:** `devcontainer-config/install.sh:838-886`; `test/install-host.bats` T53; `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`

---

## Claim 4: "without a reachable docker it says so in one line and treats no container as running"

**Location:** `devcontainer-config/install.sh:56-57`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers how many NOTE lines are printed and what "unreachable" means. It does not establish how a real docker CLI or daemon behaves.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: verdicted this sentence together with its restatements in commit ea2c8fb (Claim 19) and `037:70` (Claim 26) · r2+r3: verdicted it together with the pgrep half (Claim 3) · r1+r2+r3: "a docker that hangs past 20 s counts as unreachable (timeout), which is fail-open with the same NOTE" · r3: "a docker that answers from a different daemon than cc-isolated's returns an empty list with no NOTE" · r1: "a docker that lists a container and then exits non-zero: its stdout is thrown away and the install goes ahead".

Carried from r1 Claim 3. The NOTE is printed on every `agent_gate` call, not once per run:

```bash
# devcontainer-config/install.sh:853-854
  if ! command -v docker >/dev/null 2>&1; then
    echo "NOTE: docker not found: cc-isolated containers not checked, treated as none running."
```

Executed as scratch X3: `bats --show-output-of-passing-tests test/x.bats`, cwd scratch `x/`, 2026-09-25T06:41:02Z, exit 0. A `--yes` run with docker absent printed the NOTE twice (`NOTES=2`: once from the startup gate, once from the gate after target 1). An interactive run that answers y twice would print it three times. "Unreachable" also covers every non-zero exit from `timeout 20 docker ps …` (`:860-865`). That includes a docker that lists a container and then exits non-zero: its stdout is thrown away and the install goes ahead (executed, `q058-r1-gate-docker-fail.log`, 2026-09-25T06:51:27Z, exit 0: `gate returned 0`). A 20-second timeout counts as unreachable too. The precise version: "one NOTE line per check (up to three per run); any docker failure or timeout counts as no container running".

**Evidence:** `devcontainer-config/install.sh:853-868`; `docs/reviews/execution-logs/q058-r1-scratch-experiments.log` (X3, X4), `docs/reviews/execution-logs/q058-r1-gate-docker-fail.log`

---

## Claim 5: "Needs git, perl (the review's control-byte filter) and pgrep; refuses without them."

**Location:** `devcontainer-config/install.sh:66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers refusal without perl (T57) or pgrep (T53), both executed, and without git, read only. It does not establish that these are the only required tools: `timeout`, GNU find, sort and diff are also used, and a missing `timeout` reads as "docker is unreachable" and fails open. Nor does it establish that the no-git refusal message is accurate.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "`timeout` is also needed; without it the docker probe fails open to 'unreachable' instead of refusing" · r3: "GNU find, sort and diff are also used" · r2+r3: "the no-git message says 'no readable HEAD commit', not 'git is missing', but the run is refused" · r3: "the no-git refusal comes only after `mktemp -d` of DC_TMP".

Carried from r3 Claim 4. The perl check is at `main` `:941-945`, before the gate at `:947`. With no git, `head_commit` (`:130`, `if ! git -C "$REPO_ROOT" rev-parse …`) exits with "no readable HEAD commit". That message names HEAD, not git, and it comes only after `mktemp -d` of DC_TMP (paraphrased, no quote available because the no-git path was traced by reading, not run).

**Evidence:** `devcontainer-config/install.sh:129-135`, `:941-947`; `test/install-host.bats` T53, T57; `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`

---

## Claim 6: "vis: filter that makes control bytes visible (all but newline and tab; NUL included)" / "-a: a file with a NUL byte … is diffed as text, with vis showing each NUL as "?", rather than as "Binary files differ""

**Location:** `devcontainer-config/install.sh:110-111`, `devcontainer-config/install.sh:262-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers NUL handling in `vis` and in `review_diff`. It does not establish how `mode_diff` or the MOVE/ADD listings handle a NUL (they print path names, not contents).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: "does not establish the output of `mode_diff` (or `payload_hash`), which do not print file content" · r2: "'Only ever on the destination side' holds because `extract_commit` refuses any staged NUL file (Claim 7)"; "does not establish how the terminal renders other multi-byte sequences".

Carried from r1 Claim 5. `s/[\x00-\x08\x0b\x0c\x0e-\x1a\x1c-\x1f\x7f]/?/g;` (`:122`), and `diff -ruNa "$dest/$item" "$src/$item" 2>&1 | vis` (`:265`). T62 passes: the output holds `-bad?byte` and no `Binary files` (64/64 log).

**Evidence:** `devcontainer-config/install.sh:119-126`, `:247-281`; `test/install-host.bats:976-987`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 7: "and so is a payload file holding a NUL byte (a binary the diff cannot show)" / "extract_commit scans every staged file (both targets) and refuses, listing them through vis, any file holding a NUL, before any review or prompt (T61)"

**Location:** `devcontainer-config/install.sh:49`, `devcontainer-config/install.sh:181-199`, `review/log.txt:85-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the scan inside `extract_commit` and the fact that both targets reach it (via `assemble` at :219, and at :349 for the devcontainer items), before any review. It does not establish that the host target's own scan is exercised separately by a test: T61's first run is refused in the devcontainer target's `assemble`, which is the same function.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r3: "T61's runs are both caught on the devcontainer side (`hooks/` is also in the devcontainer's claude-home); the host site runs the same function via `assemble` (`:585`), established by reading the code only" · r3: "The scan fails closed, because under `pipefail` a perl `die` makes the `if !` branch exit" · r2: "A scan failure is fatal (`:190-191`)" · r2+r3: verdicted this together with the no-NUL-today payload statement (Claim 8).

Carried from r1 Claim 2.

```bash
# devcontainer-config/install.sh:186-199
  if ! nul="$(cd "$dir" && find . -type f -print0 | LC_ALL=C sort -z | LC_ALL=C perl -0ne '
        chomp; open(my $f, "<:raw", $_) or die "$_: $!\n";
        my $c = do { local $/; <$f> };
        print substr($_, 2), "\n" if defined $c && index($c, "\0") >= 0;')"; then
    echo "ERROR: could not scan the staged payload for NUL bytes. Nothing was installed." >&2
    exit 1
  fi
  if [ -n "$nul" ]; then
    ...
    printf '%s\n' "$nul" | sed 's/^/         /' | vis >&2
    ...
    exit 1
  fi
}
```

`assemble` calls `extract_commit "$commit" "$stage" "${CLAUDE_HOME_SRC[@]}"` (`:219`). Both targets call `assemble` before their review: the devcontainer target at `:348`, followed by `extract_commit "$STAGED_COMMIT" "$stage" "${dc_paths[@]}"` at `:349`, and the host target at `:585`. T61 passes (64/64 log): it lists `hooks/blob.bin`, never prints `Binary files` or `[y/N]`, and on the second run lists `egress/x.bin`.

**Evidence:** `devcontainer-config/install.sh:181-200`, `:212-219`, `:348-349`, `:585`; `test/install-host.bats:954-975`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 8: "No allowlist: `git archive HEAD` of the payload paths holds no NUL today." / "The payload is text today (checked 2026-09-23: no committed payload file holds a NUL), so there is no allowlist"

**Location:** `devcontainer-config/install.sh:182-184`, `review/log.txt:87`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the committed payload at b4fd792 (122 files). It does not cover future commits.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: "does not establish that future commits stay NUL-free" · r3: "122 files, no NUL files and 0 symlinks" · r1: verdicted together with the ~125-files figure (Claim 44) and the T9 rationale (Claim 37) · r2: together with the scan (Claim 7) · r3: together with the scan (Claim 7) and ~125 files (Claim 44).

Carried from r1 Claim 29. Executed: `bash q058-r1-nulscan.sh`, running `git -C /workspace archive b4fd792 -- <CLAUDE_HOME_SRC + devcontainer-config PAYLOAD items> | tar -x` and then the same perl NUL scan. Result at 2026-09-25T06:49:58Z: `files: 122`, no `NUL:` lines, scan exit 0.

**Evidence:** `devcontainer-config/install.sh:182-184`; `docs/reviews/execution-logs/q058-r1-nul-scan.log`, `docs/reviews/execution-logs/q058-r1-nulscan.sh`

---

## Claim 9: "review_diff checks vis's PIPESTATUS too; a non-zero vis aborts before the prompt like any other diff trouble" / "A vis failure is trouble too: its output is the review"

**Location:** `devcontainer-config/install.sh:259-271`, `review/log.txt:46-49`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers vis failure inside `review_diff`, both before and after the fix. It does not cover the other `| vis` sites (Claims 10a and 10b).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: "does not cover the other `| vis` sites (Claims 10a/10b)" · r2: "covers every call path, including the host ADD path's `review_diff … || true` (the explicit `exit 1` ignores the `||`)"; probe P2 (mode-only change, vis failing) printed `ERROR: could not show the review of payload item 'devcontainer.json' (vis exit 1).` and no `bless it?` · r1+r3: "the first pre-fix replay without `LC_ALL=C` failed earlier, on the pre-648124c docker bug; inconclusive, superseded by the `LC_ALL=C` rerun" · r1+r2+r3: the pre-fix half ("reached the prompt with an empty review") is Claim 40.

Carried from r1 Claim 6.

```bash
# devcontainer-config/install.sh:265-271
    diff -ruNa "$dest/$item" "$src/$item" 2>&1 | vis && st=(0 0) || st=("${PIPESTATUS[@]}")
    rc="${st[0]}"
    if [ "${st[1]}" -ne 0 ]; then
      echo "ERROR: could not show the review of payload item '$item' (vis exit ${st[1]})." >&2
      echo "       The review diff is incomplete, so nothing was installed." >&2
      exit 1
    fi
(excerpt ends :271; enclosing review_diff() continues to :281 — read)
```

After a failed pipeline, `PIPESTATUS` still holds the `diff | vis` statuses when `st=` expands, because the `&& st=(0 0)` branch is skipped. T58 passes at b4fd792.

**Evidence:** `devcontainer-config/install.sh:247-281`; `test/install-host.bats:911-927`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`, `docs/reviews/execution-logs/q058-r1-prefix-replays.log`

---

## Claim 10a: "other `| vis` uses (MODE …) are not individually checked; perl missing is now refused up front, and a vis that fails there fails in review_diff too, which aborts."

**Location:** `devcontainer-config/install.sh:299`, `review/log.txt:53-55`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the stated mechanism at the host target's MOVE, REPLACE and ADD sites. The practical conclusion (no prompt is reached) holds. It does not cover a vis that fails only on some inputs, which a fixed perl regex does not do.
**Replicate verdicts:** r1=Incorrect (compound) · r2=Mostly accurate (compound) · r3=Verified
**Replicate annotations:** Merge note: the Incorrect on this MODE row is r1's compound verdict on the whole fa69656 Notes sentence; r1's Incorrect reasoning is about the MOVE/REPLACE/ADD lines (Claim 10b) · r1: "The MODE lines differ: `mode_diff` runs in an `||` / `if !` context (`:367`, `:668`), where `set -e` is suspended, so a failing vis there is ignored. There the claimed mechanism (the next `review_diff` aborts) does apply." · r2: "MODE lines are dropped and then caught by `review_diff`" (probe P2) · r3: "`mode_diff` is always followed by `review_diff` over the same items (`:367-368`, `:668-670`)"; probe X1 showed no MODE line, then the `review_diff` ERROR and exit 1 before the prompt: "This is the mechanism the note states"; "does not establish a vis that fails only on some inputs" · r1+r2+r3: the conclusion (no prompt reached with a failed vis) holds.

Carried from r1 Claim 27 (the MODE-line part of its evidence). `mode_diff` runs in an `||` / `if !` context (`:367`, `:668`), where `set -e` is suspended, so a failing vis there is ignored; the next `review_diff` over the same items then aborts. r1's compound verdict rests on the host-target lines:

```bash
# devcontainer-config/install.sh:598-601 (install_claude_home, called plainly from main :954)
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -L "$dest/$name" ]; then
      echo "REPLACE symlink $dest/$name -> $(readlink "$dest/$name") with a copy" | vis
      changed=1
(excerpt ends :601; enclosing install_claude_home() continues to :816 — read)
```

Executed as scratch X1 and X2 (`bats --show-output-of-passing-tests test/x.bats`, cwd scratch `x/`, 2026-09-25T06:41:02Z, exit 0), with T58's stub, which fails only `perl -pe`: the host runs stop at `=== Changes this install would make ===` with `STATUS=1`, no prompt and no error text (see Claim 10b). The precise version: "MODE lines rely on the following review_diff; MOVE, REPLACE and ADD lines abort through set -e/pipefail, with no message."

**Evidence:** `devcontainer-config/install.sh:26`, `:283-305`, `:367-368`, `:598-671`; `docs/reviews/execution-logs/q058-r1-scratch-experiments.log`, `docs/reviews/execution-logs/q058-r1-scratch-experiments.bats`

---

## Claim 10b: "other `| vis` uses (… MOVE, ADD lines) are not individually checked; … a vis that fails there fails in review_diff too, which aborts."

**Location:** `devcontainer-config/install.sh:600`, `:606`, `:625`, `:646-654`; `review/log.txt:53-55`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the REPLACE, MOVE and ADD lines of the host target. It establishes that these fail closed, but through a different mechanism than the note states, and with no error message. It does not establish that `set -e` and `pipefail` stay in force: they are what carry the refusal.
**Replicate verdicts:** r1=Incorrect (compound) · r2=Mostly accurate (compound) · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "the conclusion holds: no prompt is reached with a failed vis (fail-closed)" · r1+r2: "for a new entry over 200 lines (a first install whose entries are all over 200 lines), `review_diff` is not called at all (`:649-655`)" · r1+r2: "does not establish behaviour for a vis that fails only some of the time" · r2: rated the note Mostly accurate because "the stated route ('fails in review_diff too') is only one of two"; probe P1 (host first install, vis failing) stopped at `=== Changes this install would make ===`, status 1, no ERROR line.

Carried from r3 Claim 7b. These lines are in `install_claude_home`, which `main` calls outside any `||` or `if` context, so `set -euo pipefail` (`:26`) applies. The first failing `echo … | vis` ends the script there. `review_diff` is never reached:

```bash
# devcontainer-config/install.sh:646-647
      echo "ADD $dest/$name (new, $n file(s)):" | vis
      (cd "$stage" && find "$name" -type f | LC_ALL=C sort) | sed 's/^/    /' | vis
```
(excerpt ends :647; the enclosing `install_claude_home()` continues to :816, read)

Probes X2 (first install, ADD lines only) and X3 (symlink migration, REPLACE and MOVE lines) both exit 1. The output stops right after `=== Changes this install would make ===`, with no error line and no prompt, and the destination is unchanged. The conclusion (it never reaches `[y/N]`) holds. The stated mechanism ("fails in review_diff too") is refuted: the abort is `set -e`, and it is silent.

**Evidence:** `devcontainer-config/install.sh:26`, `:593-675`; `docs/reviews/execution-logs/q058-r3-b4fd792/vis-paths.log`

---

## Claim 11: "A symlink at claude-home, or at any directory between the repo root and it, would send the rebuild's writes wherever it points …, so refuse one." / "each component from the repo root down to claude-home is checked with -L; a link is refused, named, and left in place (T59, T60)" / "The claude-home symlink error now passes readlink's output through vis."

**Location:** `devcontainer-config/install.sh:331-345`, `review/log.txt:67-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the components below `REPO_ROOT` on the logical `SRC` path, checked once before staging. It does not cover the repo root itself or anything above it, and it does not establish that a link planted after this check and before the `rm` at `:353` is caught (Claim 12).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2+r3: "does not establish anything about `REPO_ROOT` itself or its ancestors" · r2: "or about a script invoked through a different physical path (the chain is built from the logical `SRC`)" · r1+r2+r3: "does not establish a swap between the check and the rebuild (Claims 12, 43)" · r2+r3: "b4fd792 put the `readlink` output through `vis` (`:340`)" · r3: "`SRC` and `REPO_ROOT` are logical `pwd` paths (`:78`, `:85`); the check runs before `mktemp` and `assemble` (`:346-348`)" · r2: verdicted together with the no-follow rebuild (Claim 12).

Carried from r1 Claim 7.

```bash
# devcontainer-config/install.sh:334-345
  local p="$REPO_ROOT" comp
  local -a comps
  IFS=/ read -ra comps <<< "${SRC#"$REPO_ROOT"/}/claude-home"
  for comp in "${comps[@]}"; do
    p="$p/$comp"
    if [ -L "$p" ]; then
      echo "ERROR: $p is a symlink ($(readlink "$p")). install.sh rebuilds" | vis >&2
      ...
      exit 1
    fi
  done
```

T59 and T60 pass at b4fd792 (64/64 log). The pre-fix half of dfa5791's T60 claim was replayed against fa69656's install.sh (Claim 42).

**Evidence:** `devcontainer-config/install.sh:78`, `:85`, `:331-345`; `test/install-host.bats:928-953`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`, `docs/reviews/execution-logs/q058-r1-prefix-replays.log`

---

## Claim 12: "No-follow rebuild: rm of a path without a trailing slash removes a link itself, never its target; mkdir fails rather than follow anything that appeared since, so the copy lands in a directory this run just created."

**Location:** `devcontainer-config/install.sh:350-358`, `review/log.txt:69-71`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the `rm` and `mkdir` of the last path component. It does not establish that the `cp` lands in the directory `mkdir` made when something writes concurrently, and it does not cover the parent components, which are only checked at `:334-345`.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r3: "`rm`, `mkdir` and `cp` all resolve `$SRC` itself, and `devcontainer-config` is checked only once, at `:339`. That is before `assemble` and `extract_commit` run `git archive` (`:348-349`). A directory swapped for a link in that window is followed." Precise version: "no-follow at `claude-home`; the directories above it are checked once, before staging." · r2: "does not establish anything about a swap between the check and the rebuild (Claim 43)" · r1: "dfa5791's Notes name the mkdir-to-cp swap as a residual (Claim 43). The parent components are not named there."

Carried from r1 Claim 8.

```bash
# devcontainer-config/install.sh:353-358
  rm -rf "$SRC/claude-home"
  if ! mkdir "$SRC/claude-home"; then
    echo "ERROR: could not recreate $SRC/claude-home (something reappeared there). Nothing was installed." >&2
    exit 1
  fi
  cp -Rp "$stage/claude-home/." "$SRC/claude-home/"
```

The `rm` and `mkdir` steps are no-follow, as stated. The `cp` destination `"$SRC/claude-home/"` is resolved again when `cp` runs, through every parent component. So "the copy lands in a directory this run just created" holds only if nothing swaps that directory or a parent between `:354` and `:358` (or a parent between `:339` and `:353`). The precise version: "…so, absent a concurrent writer, the copy lands in a directory this run just created".

**Evidence:** `devcontainer-config/install.sh:331-358`

---

## Claim 13: "agent_gate refuses … at startup, before either target stages anything; after the devcontainer y, before it writes; after the host y, right before the lock, copies and swap."

**Location:** `devcontainer-config/install.sh:390-391`, `:694-695`, `:819-825`, `:947`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order of calls in `main` and in both targets, and that nothing writes between each y and its gate. It does not establish coverage between check points. The host target stages after the devcontainer prompt without a fresh check (P4), and the devcontainer stage is not re-checked for content after y (P3; see Claims 23 and 30).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: "does not establish detection between samples: an agent that starts after one gate and exits before the next is not seen" · r1+r2: "With `--yes` there is no devcontainer y, but the post-target-1 gate still runs (`:391` is outside the `if`)" · r3: "Nor does it establish the pre-prompt mirror rebuild, which decision 037:68 calls a staging copy".

Carried from r2 Claim 8. `main`: the perl check (`:941-945`), then `agent_gate "Nothing was staged or installed."` (`:947`), then `trap host_cleanup EXIT` (`:950`), `install_devcontainer` and `install_claude_home` (`:953-954`). Devcontainer: `if ! confirm 'Install this config and bless it?'; then … return 0; fi` (`:380-387`), then `agent_gate …` (`:391`), then `mkdir -p "$DEST" "$BIN_DIR"` (`:393`). No write sits between them. Host: `if ! confirm "Install these files into $dest?"; then … fi` (`:688-692`), then `agent_gate …` (`:695`), then the lock `mkdir -p "$dest"` … `mkdir "$dest/.claude-workflows-lock"` (`:700-702`). In S1, T50 (startup: no `Canonical`, no claude-home mirror, no `[y/N]`), T54 (host: no lock, no `.cw-new.*`) and T55 (devcontainer: no `$CLAUDE_DEVC_CONFIG_DIR`) passed.

**Evidence:** `devcontainer-config/install.sh:379-393`, `:688-702`, `:902-956`; `test/install-host.bats:791-808`, `:860-887`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`, `docs/reviews/execution-logs/q058-b4fd792-r2/probe.bats.verbose.log`

---

## Claim 14: "A Claude Code process is one of this uid's processes whose command line runs `claude` (the native binary, argv0 "claude" or ".../claude") or the npm package (`node .../bin/claude`, `.../@anthropic-ai/claude-code/...`)."

**Location:** `devcontainer-config/install.sh:827-829`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the shapes the comment lists (they all match under the real pgrep) and the one live Claude Code process on this machine. It does not establish that every real Claude Code launch uses one of these shapes. E1 shows misses for a versioned native path (`…/.local/share/claude/versions/2.0.14 --resume`), `node cli.js` run from the package directory, the Agent SDK's bundled CLI (`…/@anthropic-ai/claude-agent-sdk/cli.js`) and argv0 `claude-code`. Whether any shipped Claude Code build presents those shapes was not observable here.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** Misses observed with the real pgrep (union): r1+r2+r3: the native installer's versioned path `…/share/claude/versions/<ver>` · r1+r2: the Agent SDK's `…/@anthropic-ai/claude-agent-sdk/cli.js` · r1+r2+r3: argv0 `claude-code` · r2: `node cli.js` from the package directory · r1+r3: `npx @anthropic-ai/claude-code` (r1: "the npx wrapper process; its node child matches") · r1: a capitalised `Claude` · r3: `python3 -m claude_agent_sdk` · r1: "whether Claude Code is ever started under them on this host was not established" · r3: "does not establish which shapes real Claude Code launchers produce (Claim 25)" · r1: verdicted together with decision 037:69 and commit ea2c8fb (Claim 25) · r3: verdicted together with Claims 15 and 16.

Carried from r2 Claim 9. `CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/'` (`:834`), used as `pgrep -u "$(id -u)" -af -- "$CLAUDE_PROC_RE"` (`:845`). E1 result: MATCH for `claude`, `/usr/local/bin/claude --resume`, `node /usr/local/bin/claude --resume`, `node …/@anthropic-ai/claude-code/cli.js -p x` and `…/resources/native-binary/claude`. It missed the four shapes named in Scope. The live session process on this host (PID 1750) has cmdline `claude` and exe `…/@anthropic-ai/claude-code/bin/claude.exe`. It matches (paraphrased — no quote available because this was read from `/proc/1750/cmdline` and `/proc/1750/exe` at run time, not from a file in the repo).

**Evidence:** `devcontainer-config/install.sh:827-850`; `docs/reviews/execution-logs/q058-b4fd792-r2/proc-shape-probe.log`, `docs/reviews/execution-logs/q058-b4fd792-r2/proc-shape-probe.sh`

---

## Claim 15: "pgrep never lists itself and this script's own command line does not match; $$ is dropped only as a belt-and-braces guard."

**Location:** `devcontainer-config/install.sh:829-831`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the installer's own command line under the usual checkout paths, and the `$$` filter. It does not establish the parent processes' command lines (a `script -qec …` wrapper around a checkout path like the one below would also match, and `$$` does not filter it).
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1: "does not cover a checkout path with a component that is exactly `claude` followed by a space, which cannot occur in a path that goes on to `/devcontainer-config/…`" · r1: in the executed probe, "pgrep's own PID never appeared" · r3: `bash /home/u/claude-workflows/devcontainer-config/install.sh` and `bash /home/u/claude/devcontainer-config/install.sh` miss (real pgrep) · r2: the conclusion (no self-refusal) holds.

Carried from r2 Claim 10. The script's own command line does match when the checkout path holds `/claude` followed by a space. E5: `bash /home/u/claude code/devcontainer-config/install.sh` → MATCH, while `bash ./devcontainer-config/install.sh` and `bash /home/u/claude/devcontainer-config/install.sh` miss. In that case the `$$` filter is what removes it: `procs="$(printf '%s\n' "$procs" | awk -v self="$$" 'NF && $1 != self')"` (`:850`). The precise version: "this script's own command line does not match unless the checkout path contains `/claude ` (a directory named `claude <something>`); `$$` is dropped for that case."

**Evidence:** `devcontainer-config/install.sh:834`, `:845-850`; `docs/reviews/execution-logs/q058-b4fd792-r2/self-match-regex.log`

---

## Claim 16: "A command line with a `.../claude` argument (`vim ./claude`, `tail -f /var/log/claude`) also matches: the install is refused, and the message names the process."

**Location:** `devcontainer-config/install.sh:831-833`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers these false positives. It does not claim that every argument containing `claude` matches: `man claude` (preceded by a space, not `/`) does not.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2+r3: "the review session's own shell (its command line held the regex text) also matched, another fail-closed false match of the same kind" · r2: "does not establish how often such false matches occur on the user's host" · r3: `vim claude` (no slash) misses.

Carried from r1 Claim 12. In the probe log, `grep -E` with the regex printed `MATCH vim ./claude`. `/var/log/claude` matches through `/claude$`. A match fills `procs`, and the message prints each one (`:873-876`).

**Evidence:** `devcontainer-config/install.sh:834`, `:869-886`; `docs/reviews/execution-logs/q058-r1-probe-regex.log`

---

## Claim 17: "No pgrep: refuse." / pgrep failure refuses

**Location:** `devcontainer-config/install.sh:840-849`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a missing pgrep (T53) and a pgrep exit above 1 (by reading the code). It does not establish pgrep's behaviour on non-procps implementations (such as a BSD pgrep).
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** Placement note: the same code path is verdicted Verified by r2 and r3 under the `--help` wording (Claim 3), and r3's Claim 3 Scope covers "missing pgrep, pgrep exit >1".

Carried from r2 Claim 12. `if ! command -v pgrep …; then … exit 1; fi` (`:840-844`); `procs="$(pgrep …)" || rc=$?`; `if [ "$rc" -gt 1 ]; then echo "ERROR: pgrep failed (exit $rc) …" >&2; exit 1` (`:845-849`). Exit 1 (no match) is the only non-zero exit accepted. T53 passed in S1.

**Evidence:** `devcontainer-config/install.sh:838-850`; `test/install-host.bats:849-859`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 18: "cc-isolated's containers carry the label cc-project=<id> (its --id-label)."

**Location:** `devcontainer-config/install.sh:851`, `:860-861`; `docs/decisions/037-bare-host-copy-install.md:70`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fact that cc-isolated passes `--id-label cc-project=<pid>` on both of its `devcontainer` invocation paths. It does not establish, by execution, that the devcontainer CLI turns an id-label into a docker container label (no docker in this sandbox), although decision 016 relies on exactly that for container reuse.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3: "not established by a live run that the devcontainer CLI applies `--id-label` as a docker container label (no docker daemon reachable)" · r2: "does not establish that docker lists containers from another docker context or runtime (a residual in decision 037)" · r3: "These are the only two id-label sites" · r3: verdicted together with the stderr handling (Claim 20).

Carried from r1 Claim 13. `--id-label "cc-project=$pid")` appears at `devcontainer-config/cc-isolated.sh:412` and `:623`, and install.sh filters `docker ps --filter label=cc-project` (`:860`). `docker ps` without `-a` lists only running containers.

**Evidence:** `devcontainer-config/cc-isolated.sh:410-412`, `:621-623`; `devcontainer-config/install.sh:851-868`; `docs/decisions/016-multi-project-devcontainer-central-config.md:98-101`

---

## Claim 19: "No or unreachable docker: one NOTE line, treated as none running." (commit ea2c8fb)

**Location:** `review/log.txt:26-27`, `devcontainer-config/install.sh:853-868`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers how many NOTE lines are printed and what "unreachable" means. It does not establish how a real docker CLI or daemon behaves.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified (compound) · r3=—
**Replicate annotations:** r1: verdicted together with `install.sh:56-57` (Claim 4) and `037:70` (Claim 26) · r2: verdicted together with 648124c's stderr sentence (Claim 20); "does not establish that the one stderr line shown is docker's own error rather than an earlier warning (`head -n 1`), or behaviour when `docker ps` hangs past 20 s (it is treated as unreachable, which is fail-open)".

Carried from r1 Claim 3 (see Claim 4 for the full executed evidence). The NOTE is printed on every `agent_gate` call, not once per run: `echo "NOTE: docker not found: cc-isolated containers not checked, treated as none running."` (`install.sh:854`). Scratch X3 (`--yes`, docker absent) printed it twice; an interactive run answering y twice prints it three times. Any non-zero exit of `timeout 20 docker ps …` (`:860-865`), including a docker that listed a container then exited non-zero (`q058-r1-gate-docker-fail.log`: `gate returned 0`), or a 20-second timeout, counts as unreachable.

**Evidence:** `devcontainer-config/install.sh:853-868`; `docs/reviews/execution-logs/q058-r1-scratch-experiments.log`, `docs/reviews/execution-logs/q058-r1-gate-docker-fail.log`

---

## Claim 20: "Only stdout is the container list. stderr … is kept apart and shown only when the call fails." / 648124c: "stderr now goes to a temp file, shown only when docker fails, and blank lines are dropped from the list" (T64)

**Location:** `devcontainer-config/install.sh:856-867`, `review/log.txt:124-127`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the missing-docker and failing-docker paths, stdout-only capture and blank-line removal. It does not establish that the one stderr line shown is docker's own error rather than an earlier warning (`head -n 1`), or behaviour when `docker ps` hangs past 20 s (it is treated as unreachable, which is fail-open).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r2: "the NOTE shows only the first stderr line (`head -n 1`), which in a shell with a broken locale is the bash `setlocale` warning, not docker's error" · r3: "T64 fails against 66891a7's install.sh (the parent of 648124c), listing `WARNING: some docker CLI notice` under 'Running cc-isolated containers' — the commit said T64 had not been run against the pre-fix code; that run is now done" · r3: "does not establish, by a live run, that the devcontainer CLI applies `--id-label` as a docker container label".

Carried from r2 Claim 14. `echo "NOTE: docker not found: …"` (`:854`); `if ! ctrs="$(timeout 20 docker ps … 2>"$errf")"; then err="$(head -n 1 "$errf" 2>/dev/null)"; echo "NOTE: docker is unreachable ($err): …" | vis; ctrs=""; fi; rm -f "$errf"; ctrs="$(printf '%s\n' "$ctrs" | awk 'NF')"` (`:860-867`). T52 and T64 passed in S1. The suite as a whole also passed with `LC_ALL` set to an uninstalled locale, which is the condition 648124c describes.

**Evidence:** `devcontainer-config/install.sh:852-869`; `test/install-host.bats:822-848`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`; `docs/reviews/execution-logs/q058-r3-b4fd792/prefix-66891a7-T64.log`

---

## Claim 21: "main refuses at startup when `command -v perl` fails, before the gate or any staging (T57)."

**Location:** `devcontainer-config/install.sh:940-947`, `review/log.txt:45-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order of the perl check, the gate and staging. It does not cover perl that is present but broken (that case is caught by the vis status checks, Claims 9, 10a and 10b).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r1+r2: "does not establish that perl works, only that it is on PATH" · r3 (Claim 19 Scope): "does not establish … that T57 asserts ordering before the gate (the ordering was established by reading `:941-947`)".

Carried from r1 Claim 15. `if ! command -v perl >/dev/null 2>&1; then … exit 1; fi` (`:941-945`) comes before `agent_gate` (`:947`) and `install_devcontainer` (`:953`). T57 passes (64/64 log).

**Evidence:** `devcontainer-config/install.sh:940-954`; `test/install-host.bats:900-910`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 22: "A cc-isolated container writes the checkout, `.git` included, through its bind mount, whatever uid it runs as."

**Location:** `docs/decisions/037-bare-host-copy-install.md:64`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the read-write workspace bind mount. It does not establish write access for an arbitrary uid: a bind mount enforces host permissions, so a non-root container uid that differs from the owner cannot write the user's 0644/0755 files.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: "'Whatever uid' is read as 'the mount itself is read-write'"; "does not establish file-permission outcomes for a container uid other than the owner's"; no `,readonly` flag and no separate `.git` mount · r3: "does not establish a linked worktree checkout, whose `.git` data sits outside the mounted folder. Nor does it establish container-side permission details (uid mapping), which were not read" · r2: "The practical point, that the docker probe must not filter by uid, is right."

Carried from r2 Claim 16. `"remoteUser": "node"` (`devcontainer-config/devcontainer.json:71`) and `"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated"` (`:134`). The mount is read-write. The container user writes it when its uid matches the host owner's (devcontainer's default UID sync), or as root (paraphrased — no quote available because this is bind-mount permission semantics, not code in the file). The precise version: "writes the checkout through its bind mount (its user is mapped to your uid), which is why the container check is not uid-scoped."

**Evidence:** `devcontainer-config/devcontainer.json:71`, `:134`

---

## Claim 23: "The hash check (R2) catches a stage edited while the prompt waits."

**Location:** `docs/decisions/037-bare-host-copy-install.md:66`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the host target's stage (hashed before review, re-hashed on the copies after y). It does not establish anything for the devcontainer target, whose stage has no hash. An edit to it while the prompt waits, by a process gone (or undetected) at y, is installed and blessed.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "the R2 hash covers the host target only; the devcontainer target relies on the gate alone (the prior rubric's R1)" · r1: "does not assess whether the gate alone protects target 1" · r3: "The sentence sits in a section about both targets" · r2 escalation: "The R1 target-1 half is closed only against agents present at the devcontainer y" (see Escalations E2).

Carried from r2 Claim 17. Host: `reviewed_hash="$(payload_hash "$stage" "" "$stage/.manifest")"` (`install.sh:589`), and after the copies `if [ "$(payload_hash "$dest" .cw-new. "$dest/.cw-new.manifest")" != "$reviewed_hash" ]; then … echo "ERROR: stage changed after review …"` (`:729-733`). Devcontainer: after y and the gate, `for item in "${PAYLOAD[@]}"; do rm -rf "${DEST:?}/$item"; cp -Rp "$stage/$item" "$DEST/$item"; done` (`:399-402`) copies from `$DC_TMP/config` with no content check. Probe P3 (E2) reviewed `+{"v":2}`. While the prompt waited it wrote `TAMPERED` into `$TMPDIR/cw-devc-stage.*/config/devcontainer.json`, with the pgrep stub reporting no agent, and answered y. The output shows `BLESS-STUB --bless`, and the installed file reads `installed: TAMPERED`. The precise version: "The host target's hash check (R2) catches its stage edited while the prompt waits; the devcontainer target has no such check and relies on the gate alone."

**Evidence:** `devcontainer-config/install.sh:321-424`, `:583-589`, `:729-734`; `docs/reviews/execution-logs/q058-b4fd792-r2/probe.bats`, `docs/reviews/execution-logs/q058-b4fd792-r2/probe.bats.verbose.log`

---

## Claim 24: "`install.sh` refuses to run while an agent can run … It checks at startup, before either target stages anything, and again after each y, before that target writes to its destination. (The devcontainer target rebuilds its `claude-home` mirror inside the checkout before its prompt; that is a staging copy, not an install.)"

**Location:** `docs/decisions/037-bare-host-copy-install.md:68`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the gate's sampling behaviour against the guarantee as stated at `:66` ("no agent runs from the start of the install to the end of the swap"). The call sites and the mirror parenthetical are accurate (Claim 13).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=—
**Replicate annotations:** r2: "does not establish the headline 'refuses to run while an agent can run' as continuous: the checks are at three points"; the mirror rebuild (`:353-358`) comes before the review and prompt (`:364-388`) · r2: verdicted `037:68-70` as one claim (with Claims 25, 26).

Carried from r1 Claim 18. The gate samples at three instants (`:947`, `:391`, `:695`). It does not watch the whole interval. An agent (or a scheduled `claude -p`) that starts after the startup check and exits before the post-y check is never seen. For target 1 this means an edit to `$DC_TMP/config` made during the review installs without detection, because target 1 has no hash check (Claim 23). For target 2, an agent that starts after `:695` can edit the `.cw-new.*` copies between the hash at `:729` and the `mv` at `:766`. Both need the agent to be absent at every sample. The sentence "refuses to run while an agent can run" reads as continuous enforcement (paraphrased — no quote available because this is a reading of the decision's wording against the code paths cited). The precise version: "refuses if an agent is found at startup or after either y".

**Evidence:** `devcontainer-config/install.sh:390-402`, `:694-695`, `:729-768`, `:947`

---

## Claim 25: "a Claude Code process of the user's uid: `pgrep -u <uid> -af` for a command line that runs `claude` (argv0 `claude` or `…/claude`, the native binary) or the npm package" (also commit ea2c8fb, "matches the claude CLI's command-line shape")

**Location:** `docs/decisions/037-bare-host-copy-install.md:69`, `review/log.txt:23-25`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex matching the described shapes (executed, Claim 14) and one live process. It does not establish that every real launcher produces these shapes: native versioned installs, IDE extensions and SDK wrappers were not observed.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Unverifiable
**Replicate annotations:** r1: verdicted with the `install.sh:827-829` comment (Claim 14); its Scope: "two stock-adjacent shapes miss … whether Claude Code is ever started under them on this host was not established" · r2: verdicted `037:68-70` as one claim; "Detectors: `:845` and `:860` match the bullets" · r3 escalation: host-side probe needed (see Escalations E4).

Carried from r3 Claim 15. In this sandbox, the only live Claude Code process is PID 1750. Its cmdline is `claude` and its comm is `claude`. It is an npm global install whose `bin/claude` links to `@anthropic-ai/claude-code/bin/claude.exe` (paraphrased — no quote available because this was read from the live process table). The real pgrep matched it. Two nearby shapes miss:
- The native installer's versioned binary, `…/.local/share/claude/versions/<ver>`, when exec'd by absolute path.
- An argv0 of `claude-code`.

No native install or IDE extension was available to observe. b4fd792's notes also call the VS Code extension's shape unverified. To verify, the probe needs to run on the bare host with each launcher in use: the native install, the VS Code extension, and the SDK.

**Evidence:** `devcontainer-config/install.sh:834`; `docs/reviews/execution-logs/q058-r3-b4fd792/regex-probe.log`; `ps -o pid,comm,args -p 1750` (paraphrased, no quote available because the command was run interactively and not captured to a file; output `1750 claude claude`)

---

## Claim 26: "If docker is missing or unreachable, one line says so and no container is assumed." (with the container-detector bullet's label reference)

**Location:** `docs/decisions/037-bare-host-copy-install.md:70`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers how many NOTE lines are printed and what "unreachable" means. It does not establish how a real docker CLI or daemon behaves.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified (compound) · r3=—
**Replicate annotations:** r1: its Claim 13 (compound, also citing `037:70`) verdicted the bullet's label half ("cc-project=<id>, its --id-label") Verified (Claim 18) · r1: verdicted together with Claims 4 and 19 · r2: verdicted `037:68-70` as one claim; "`--id-label` matches `cc-isolated.sh:412`".

Carried from r1 Claim 3 (see Claim 4 for the full executed evidence). The NOTE is printed once per `agent_gate` call (`install.sh:853-854`), twice in a `--yes` run and up to three times in an interactive run (scratch X3). Any non-zero exit or 20-second timeout of `timeout 20 docker ps …` (`:860-865`) counts as unreachable, including a docker that listed a container and then exited non-zero (`q058-r1-gate-docker-fail.log`). The precise version: "one NOTE line per check (up to three per run); any docker failure or timeout counts as no container running".

**Evidence:** `devcontainer-config/install.sh:853-868`; `docs/reviews/execution-logs/q058-r1-scratch-experiments.log`, `docs/reviews/execution-logs/q058-r1-gate-docker-fail.log`

---

## Claim 27: "File or directory names holding a TAB or newline … Both need a crafted name, which needs an agent, which the gate refuses."

**Location:** `docs/decisions/037-bare-host-copy-install.md:73`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the TAB mis-prune residual (A4) when the crafted name was planted before the run. It does not separately execute the newline-cwd residual (A5), whose crafted directory is persistent state in the same way.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1: "does not re-verify the underlying A4/A5 behaviour, which the pass-3 fact-check Claims 4 and 6 established" · r1: "dfa5791 handles the analogous planted-in-advance case (a symlink at `claude-home`) with an explicit on-disk check (Claim 11), not with the gate"; "A reader would take A4 and A5 as closed by Q-058 when they are not." · r3: "The residual can reasonably still be accepted, since writing either name needs write access that already allows worse. But the stated reason, 'the gate refuses', is not the mechanism."; "does not establish whether an agent can write `~/.claude/.claude-workflows-backup` on a given host: that depends on the sandbox denyWrite setting"; "Only newlines are skipped, at `:801`" · r1+r2+r3 escalation: the rationale is refuted and the user's Q-058 answer relied on the decision text (see Escalations E3).

Carried from r2 Claim 19a. The gate checks for *running* processes at three points during one run (`install.sh:391`, `:695`, `:947`). A crafted name is persistent filesystem state, which an agent can plant in an earlier session, long before the install. The gate never looks for it. The prune loop still truncates a TAB name at `cut -f2`: `printf '%s\t%s\n' "$e" "${d##*/}"` … `| LC_ALL=C sort -t "$(printf '\t')" -k1,1nr -k2,2r | tail -n +3 | cut -f2)` (`:806-807`), feeding `rm -rf "${bkroot:?}/$old"` (`:797`). Probe P5 (E3) planted `20200101T000000Z<TAB>junk` (epoch 100) next to real backups `20200101T000000Z` (200) and `20200102T000000Z` (300) before running. The pgrep stub reported no agent, so every gate passed, and the run printed `Installed into …` and `(1 older removed)`. The listing afterwards shows `20200101T000000Z	junk`, `20200102T000000Z` and this run's backup: the real `20200101T000000Z`, which should have been kept, was deleted, and the planted one survived. The precise version: "Both need a crafted name. The gate does not stop a name planted before the run; these residuals rest on nothing but their exotic-input rarity."

**Evidence:** `devcontainer-config/install.sh:784-809`, `:838-886`; `docs/reviews/execution-logs/q058-b4fd792-r2/probe5.bats`, `docs/reviews/execution-logs/q058-b4fd792-r2/probe5.bats.log`

---

## Claim 28: "(fact-check final Claims 4 and 6; rubric A4, A5, parked)" / "Review record: code-review-rubric-2026-09-23-ans-copy-install-final.md"

**Location:** `docs/decisions/037-bare-host-copy-install.md:73`, `:77`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the cited report claims and rubric rows exist and describe these residuals. It does not establish their verdicts beyond what those files say.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** Placement note: r1's Claim 27 Scope relies on the same references ("the pass-3 fact-check Claims 4 and 6 established" A4/A5) and its Evidence cites `code-review-rubric-2026-09-23-ans-copy-install-final.md:29-30`. Note: the pass-3 report r2 cites as `docs/reviews/code-fact-check-report.md` is now staged as `docs/reviews/code-fact-check-report-pass3-9ae6e46.md`.

Carried from r2 Claim 19b. The final (pass-3, 9ae6e46) fact-check report's `## Claim 4:` (`:95`) is the backup-pruning claim and its `## Claim 6:` (`:152`) is the newline-destination `read` claim. The rubric has `| A4 | A TAB in a backup dir's name makes \`cut -f2\` prune the wrong dir …` (`docs/reviews/code-review-rubric-2026-09-23-ans-copy-install-final.md:29`) and `| A5 | A relative \`CLAUDE_HOME_DIR\` from a working dir whose name contains a newline …` (`:30`). The linked file exists.

**Evidence:** `docs/reviews/code-fact-check-report-pass3-9ae6e46.md:95`, `:152`; `docs/reviews/code-review-rubric-2026-09-23-ans-copy-install-final.md:29-30`

---

## Claim 29: "git obeys the checkout's `.git/config` (hooks paths, `core.fsmonitor`, filters) when `install.sh` runs `git archive` and `git status`."

**Location:** `docs/decisions/037-bare-host-copy-install.md:74`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers which git commands install.sh runs in the checkout. It does not establish which config keys each subcommand honours.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "As in Claim 19 [merged Claim 27], a `.git/config` edit can also be planted before the install, when the gate is not running"; "The residual's conclusion (the same exposure as any user git command) is unaffected."

Carried from r1 Claim 20. install.sh also runs `git -C "$REPO_ROOT" rev-parse --verify -q 'HEAD^{commit}'` (`:130`) and `git -C "$REPO_ROOT" cat-file -e "$commit:$item"` (`:150`), in addition to `archive` (`:162`) and `status` (`:225-226`). The list should read "every git command it runs (`rev-parse`, `cat-file`, `archive`, `status`)".

**Evidence:** `devcontainer-config/install.sh:130`, `:150`, `:162`, `:225-226`

---

## Claim 30: "A process the probe misses: an agent on another host or in another container runtime writing the checkout (a network or shared mount), a renamed or wrapped binary whose command line does not end in `claude`, one running under another uid, or a docker the user's uid cannot reach."

**Location:** `docs/decisions/037-bare-host-copy-install.md:75`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether the listed residual categories match the probe's real misses. It does not establish whether any stock Claude Code launcher (VS Code extension, auto-updater restart) starts the CLI under a non-matching argv0. b4fd792's Notes leave that unverified.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** Unlisted misses (union): r1+r2+r3: agents present only between the three samples (r2: executed as P3 and P4) · r2+r3: same-uid processes that are not Claude Code, such as a detached loop left by an earlier session (r2 E1: `bash -c while sleep 1; do cp evil …; done` → miss) · r1+r2+r3: the native versioned-binary path · r1+r2: the Agent SDK's `claude-agent-sdk/cli.js` · r2: `node cli.js` · r1: a docker that listed a container and then exited non-zero, or a 20-second timeout · r2+r3: "'command line does not end in `claude`' misstates the regex: `/usr/local/bin/claude --resume` matches" · r2+r3: "does not establish that the list is complete" · r1: "The revisit trigger at `:83` covers (a) and (b) only if someone notices the process shape changed."

Carried from r1 Claim 21. The four categories are real. The list leaves out misses that are neither "renamed" nor "wrapped" by the user. (a) The native installer's own file name is a version string (`…/share/claude/versions/<ver>`), and a process exec'd by that path does not match (executed, Claim 14). (b) An Agent-SDK-bundled CLI (`…/@anthropic-ai/claude-agent-sdk/cli.js`) does not match (executed, Claim 14). (c) Any agent absent at the three sample instants is missed, including a short-lived one (Claim 24). (d) Any docker failure or a 20-second timeout counts as "cannot reach", including a docker that listed a container and then exited non-zero (Claim 4, X4).

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:75`, `:83`; `devcontainer-config/install.sh:834`, `:860-865`; `docs/reviews/execution-logs/q058-r1-probe-regex.log`, `docs/reviews/execution-logs/q058-r1-gate-docker-fail.log`

---

## Claim 31: "`install.sh` now refuses at startup and again after each y while a Claude Code process of the user's uid (`pgrep -af`) or a running cc-isolated container … is found (T50-T56). Residuals accepted in decision 037 …"

**Location:** `docs/working/plan-copy-install-bare-host.md:244`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the check points, the T50–T56 mapping and the false-match note. It does not establish that the residual list is complete (it mirrors 037's list; see Claims 27 and 30).
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate (compound) · r3=Verified (compound)
**Replicate annotations:** Merge note: r2's Mostly accurate is its verdict on the whole `plan:244` line; its own prose says "The check points and tests hold", and the deviation it names is the false-match sentence (Claim 32) · r1: "does not endorse the Risks line's residual list, which repeats decision 037 (Claims 27 and 30)" · r1: verdicted `plan:244-245` and `:248` together (with Claims 32, 33, 34) · r3: verdicted the test IDs of `plan:244-245` together with the T50–T64 existence check (Claims 33, 38).

Carried from r2 Claim 21. The check points and tests hold (Claims 13 and 38). The false-match note is too narrow. An unrelated command line matches whenever `/claude` is followed by a space, not only at its end. E1 shows `vim ./claude` matching, and E5 shows `bash /home/u/claude code/…` matching (`CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|…'`, `install.sh:834`).

**Evidence:** `devcontainer-config/install.sh:834`; `test/install-host.bats:791-899`; `docs/reviews/execution-logs/q058-b4fd792-r2/proc-shape-probe.log`, `docs/reviews/execution-logs/q058-b4fd792-r2/self-match-regex.log`

---

## Claim 32: "The probe is also a new way for the install to be refused on a host where some unrelated command line ends in `/claude`; the message names the process."

**Location:** `docs/working/plan-copy-install-bare-host.md:244`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the false-positive classes seen with the real pgrep. It does not establish how often they occur on the user's host.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "'some unrelated command line ends in `/claude`' is a slight understatement: any argument ending in `/claude` matches (Claim 16)" · r2: E5 `bash /home/u/claude code/…` matches; precise version "…where some unrelated command line holds a `/claude` word (`vim ./claude`, a path through a `claude …` directory)".

Carried from r3 Claim 18. A false positive does not need the `/claude` at the end of the line. `vim ./claude` matched, and `(^|/)claude(\.exe)?( |$)` also matches a `/claude` token followed by more arguments (for example `vim ./claude notes.txt`), a bare argv0 of `claude`, or any line containing `/@anthropic-ai/claude-code/`. In an earlier interactive pgrep run in this review, the review shell's own command line matched too, because the text of that command contained the regex (paraphrased, no quote available because that run was interactive and not captured to a file). The precise version: "…where some unrelated command line has a `/claude` token or an argv0 of `claude`." The second half ("the message names the process") is verified (`install.sh:874-875`).

**Evidence:** `devcontainer-config/install.sh:834`, `:873-876`; `docs/reviews/execution-logs/q058-r3-b4fd792/regex-probe.log`

---

## Claim 33: "Hardening after the final review (2026-09-23): perl is required at startup and a `vis` failure aborts the review (T57, T58); the `claude-home` mirror is never rebuilt through a symlink (T59, T60); payload files holding a NUL byte are refused, and the review diffs as text (T61, T62)."

**Location:** `docs/working/plan-copy-install-bare-host.md:245`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test-to-fix mapping and that each named test passes. "Never rebuilt through a symlink" holds for links present at check time (Claim 11); it does not establish anything for a swap during the run (Claim 43).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "does not establish that T61 tests the host-target NUL scan separately (Claim 7), or that T57 asserts ordering before the gate".

Carried from r2 Claim 22. The tests exist at `test/install-host.bats:900`, `:911`, `:928`, `:942`, `:954` and `:976`, with titles matching the fixes, and all passed in S1. Behaviour: Claims 6, 7, 9, 11 and 21.

**Evidence:** `test/install-host.bats:900-987`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 34: "install.sh is 958 lines after the review, fact-check and Q-058 fixes (808 before Q-058)"

**Location:** `docs/working/plan-copy-install-bare-host.md:248`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line counts at 9ae6e46 and b4fd792. It does not establish counts at later commits.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: 66891a7's install.sh is 948 lines, the figure in that commit's message (Claim 45) · r3: the 808 count "was an interactive count not captured to a file".

Carried from r2 Claim 23. E6: `9ae6e46 808`, `66891a7 948`, `648124c 956`, `b4fd792 958`. The plan was corrected to 958 in b4fd792.

**Evidence:** `docs/reviews/execution-logs/q058-b4fd792-r2/line-counts.log`

---

## Claim 35: "First close every Claude Code session and stop every cc-isolated container: the installer refuses to stage or install while either runs (Q-058; see `install.sh --help` and decision 037, "Trust model"), since a running agent could change what you review before it is installed."

**Location:** `guides/bare-host-hook-wiring.md:17-20`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what happens when an agent is present at one of the three check points. It does not establish "refuses to stage … while either runs" for an agent that appears after the startup check. The host target stages with no fresh check.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: verdicted with README:33-39 (Claim 1) · r3: "T56 greps this guide for `Q-058` and `cc-isolated container` and passes"; the cross-references resolve (`install.sh:51-58`, decision 037's `## Trust model (Q-058)` at line 60); "does not establish the detector's completeness" · r1+r3: "the gate samples at three points; does not watch continuously".

Carried from r2 Claim 24. Probe P4 (E2): the pgrep stub reported `779 claude` from the moment the devcontainer prompt was up until after the host stage was built. The user answered n to the devcontainer target. The host target then staged and printed its full review, including `Install these files`, with no refusal. The agent was gone by the host y, and the install completed. Staging is gated only by the startup check: `agent_gate "Nothing was staged or installed."` (`install.sh:947`). `install_claude_home` calls `assemble "$stage"` (`:585`) with no gate before it. The precise version: "…refuses at startup, before anything is staged, and again after each y, while either runs."

**Evidence:** `devcontainer-config/install.sh:530-695`, `:947`; `docs/reviews/execution-logs/q058-b4fd792-r2/probe.bats`, `docs/reviews/execution-logs/q058-b4fd792-r2/probe.bats.verbose.log`

---

## Claim 36: "install.sh's no-agent gate (Q-058) asks pgrep and docker what runs; the session running these tests is a Claude Code process, so both report none." / "the existing suites stub them to "none", because the session running them is itself a claude process"

**Location:** `test/cc-isolated-functions.bats:44-48`, `test/install-host.bats:35-41`, `review/log.txt:28-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the premise (a live claude process of this uid exists) and the stubs in the two suites that run install.sh. It does not cover other suites, which only grep install.sh and never run it (`link-claude-home-wiring.bats:270`, `hooks/claude-config-audit.bats:231`, `hooks/live-verify-gate.bats:74`).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "does not establish that the docker stub is harmless to the cc-isolated tests beyond this run" · r2: verdicted together with the no-env-override note (Claim 41).

Carried from r1 Claim 24. The real `pgrep` with the gate's regex lists `1750 claude` in this sandbox (`q058-r1-probe-regex.log`). Without the stubs, the gate would refuse every run. The stubs `printf '#!/usr/bin/env bash\nexit 1\n' > "$TEST_TMPDIR/bin/pgrep"` (`:46`) and `stub_pgrep 'exit 1'` (`install-host.bats:39`) make it report nothing.

**Evidence:** `test/cc-isolated-functions.bats:41-49`; `test/install-host.bats:35-42`; `docs/reviews/execution-logs/q058-r1-probe-regex.log`

---

## Claim 37: "T9 now copies the committed hooks/scripts (git archive) instead of the tree, whose ignored __pycache__/*.pyc the new check refuses"

**Location:** `test/install-host.bats:278-288`, `review/log.txt:96-97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the T9 fixture change and T58's stub dispatch. It does not establish that `__pycache__` holds NUL bytes in every checkout (it is git-ignored and local).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: verdicted with the no-NUL-today and ~125-files statements (Claims 8, 44); r1 Claim 23 also records "T9 now uses `git -C "$CONFIG_SRC/.." archive HEAD hooks scripts | tar -xf - -C "$ROOT"` (`:283`)" · r2: verdicted with the T58 stub and ~125 files (Claims 39, 44) · r3: verdicted with the T58 stub (Claim 39).

Carried from r3 Claim 23.

```bash
# test/install-host.bats (T9)
  git -C "$CONFIG_SRC/.." archive HEAD hooks scripts | tar -xf - -C "$ROOT"
```

T9 passes.

**Evidence:** `test/install-host.bats:278-290`; `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`

---

## Claim 38: T50–T64 exist and assert what their commits say (ea2c8fb T50–T56, fa69656 T57–T58, dfa5791 T59–T60, 8d9be0c T61–T62 and T9, 66891a7 T63, 648124c T64)

**Location:** `test/install-host.bats:791-1000`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of each test, what it asserts, and that it passes at b4fd792. It does not establish that each test fails before its fix except T58 and T60 (replayed, Claims 40 and 42) and T64 (the commit itself says it was not replayed).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: "does not establish that T64 fails on pre-648124c code" — r3 ran it: T64 fails against 66891a7's install.sh (Claim 20) · r2: "or live-host behaviour ('Live-verified: no' on every commit)" · r3: "does not establish that T61 tests the host-target NUL scan separately, or that T57 asserts ordering before the gate" · r3: "T54's feed answers n to the devcontainer target, then creates the agent marker while the host prompt waits … T55 creates the marker after the mirror's `.manifest` appears" · r3: verdicted with the plan's test references (Claims 31, 33).

Carried from r1 Claim 23. Each test was read in full, and each asserts what its commit claims. T50 checks no `[y/N]`, no `Canonical`, no mirror, and `pgrep -u $(id -u) -af` in `probe.log`. T51 checks the container name and `docker stop`. T52 checks the unreachable and missing-docker NOTEs and that the install goes ahead. T53 refuses without pgrep. T54 and T55 cover an agent appearing during each prompt. T56 checks the docs grep. T57 and T58 cover perl and vis. T59 and T60 cover the symlinks. T61 and T62 cover NUL. T63 checks the 037 section and the plan's Risks. T64 covers docker stderr. Executed: `bats test/install-host.bats`, 64/64, exit 0.

**Evidence:** `test/install-host.bats:32-72`, `:278-288`, `:791-1000`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 39: "T58's perl stub fails vis only, so the NUL scan runs real perl."

**Location:** `test/install-host.bats:911-927`, `review/log.txt:96-97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the T9 change, T58's stub dispatch and the payload file count. It does not establish scan timing ("well under a second" was not timed).
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2+r3: verdicted together with T9 (Claim 37); r2 also with ~125 files (Claim 44).

Carried from r2 Claim 29. T58's stub: `case "$1" in -pe) cat >/dev/null; exit 1 ;; esac\nexec %s "$@"` (`:917`). `vis` calls `perl -pe` (`install.sh:120`), while the NUL scan calls `perl -0ne` (`:186`), which falls through to the real perl. T58 passed in S1.

**Evidence:** `test/install-host.bats:911-927`; `devcontainer-config/install.sh:120`, `:186`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 40: "T58, which reached the prompt with an empty review before this fix"

**Location:** `review/log.txt:48-49` (commit fa69656 message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the pre-fix behaviour at ea2c8fb (the parent of fa69656), run with `LC_ALL=C` so the separate pre-648124c docker bug does not fire. It does not cover "an unchanged one read as (none)", which was not replayed.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r3: "The first pre-fix attempt without `LC_ALL=C` failed earlier, on T58's setup. The bash docker stub printed a setlocale warning, which ea2c8fb's `2>&1` capture counted as a container" — inconclusive, superseded by the `LC_ALL=C` rerun · r2: verdicted via the code comment ("a failed vis over a differing item read as an empty diff that still reached [y/N]") together with Claim 9, without a pre-fix replay.

Carried from r1 Claim 26. b4fd792's T58 was run against ea2c8fb's install.sh, cwd scratch `tree-ea2c8fb`, `env LC_ALL=C … bats -f T58 test/t58.bats`, exit 1. It failed on `could not show the review`, and its output shows `=== Changes this install would make ===` with no diff lines, then `Install this config and bless it? [y/N]`.

**Evidence:** `docs/reviews/execution-logs/q058-r1-prefix-replays.log`, `docs/reviews/execution-logs/q058-r1-prefix.sh`; `docs/reviews/execution-logs/q058-r3-b4fd792/prefix-ea2c8fb-T58-LC_C.log`

---

## Claim 41: "No env override for the probes: tests use PATH stubs, so the gate has no bypass beyond what PATH already allows."

**Location:** `review/log.txt:34-35` (commit ea2c8fb message); `devcontainer-config/install.sh:834-868`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the knobs install.sh itself defines. It does not establish anything about environment variables read by the probed tools.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "pointing `DOCKER_HOST`/`DOCKER_CONTEXT`/`~/.docker/config.json` at a dead socket turns the container check into 'treated as none running' without touching PATH. It does print the NOTE."; "Decision 037's residual 'a docker the user's uid cannot reach' covers the outcome but not this route to it"; "does not cover editing install.sh itself, which decision 035 covers" · r2: "`main` accepts only `--yes` and `-h/--help` (`:904-911`)"; "does not establish that the detectors are complete. The misses there are blind spots, not bypass knobs." · r2: verdicted together with the stub premise (Claim 36).

Carried from r3 Claim 22. install.sh defines no override: `CLAUDE_PROC_RE` is assigned unconditionally at the top level (`:834`), so an exported value is overwritten, and `agent_gate` reads no other variable except `TMPDIR` for its temp file. But docker's own environment (`DOCKER_HOST`, `DOCKER_CONTEXT`) chooses which daemon `docker ps` asks (paraphrased — no quote available because this is the docker CLI's behaviour, external to the repo). A daemon that is unreachable fails open with one NOTE (`:860-865`). A reachable, different daemon returns an empty list silently. Decision 037 accepts "a docker the user's uid cannot reach" but not a different daemon. The precise version: "install.sh adds no override; PATH and docker's own daemon-selection variables can still blind the probes."

**Evidence:** `devcontainer-config/install.sh:834`, `:838-868`

---

## Claim 42: "(T60: a symlinked devcontainer-config made the run create claude-home outside the repo)"

**Location:** `review/log.txt:64-65` (commit dfa5791 message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fact that pre-fix install.sh (fa69656) completes through a symlinked `devcontainer-config`. It does not re-check the created path directly, because the replayed T60 stops at its first assertion (status).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r1 Claim 28a. The pre-fix half was replayed against fa69656's install.sh (cwd scratch `tree-fa69656`, 2026-09-25T06:50:55Z, exit 1). The install completed (`BLESS-STUB --bless`) instead of refusing, so the mirror rebuild went through the link to `$S/realdc`.

**Evidence:** `docs/reviews/execution-logs/q058-r1-prefix-replays.log`, `docs/reviews/execution-logs/q058-r1-t60.sh`

---

## Claim 43: "a swap of the fresh directory for a link between mkdir and cp is a residual; it needs an agent running during the install, which the Q-058 gate refuses."

**Location:** `review/log.txt:74-76` (commit dfa5791 message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the gate calls around the rebuild. It does not establish refusal of a process that is not Claude Code, or one started after the startup check.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=—
**Replicate annotations:** r1: "The mirror `cp` (`:358`) runs before the devcontainer prompt … The gate then refuses the install, not the write that already happened." Precise version: "needs an agent running during the install; the gate refuses one that is running at startup"; "does not assess how likely such a race is" · r2: "The race window is short (staging time), which bounds the practical risk."

Carried from r2 Claim 28. The rebuild (`install.sh:353-358`) runs after only the startup check (`:947`). No gate runs between that check and the rebuild. The gate refuses only a process matching `CLAUDE_PROC_RE`, or a labelled container, present at that moment (`:845`, `:860`). A same-uid process an agent left running (E1: a `bash -c while …` loop → miss), or one started after `:947`, is not refused. The precise version: "…it needs a process racing the install; the gate refuses only a Claude Code process or cc-isolated container present at startup."

**Evidence:** `devcontainer-config/install.sh:346-358`, `:845`, `:947`; `docs/reviews/execution-logs/q058-b4fd792-r2/proc-shape-probe.log`

---

## Claim 44: "the payload is ~125 small text files"

**Location:** `review/log.txt:91-93` (commit 8d9be0c message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the committed payload at b4fd792 (122 files). It does not cover future commits.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish scan timing ('well under a second' was not timed)" · r1+r2+r3: each verdicted this figure inside a compound claim (with Claims 8, 37; 37, 39; 7, 8 respectively).

Carried from r1 Claim 29. The payload scan at 2026-09-25T06:49:58Z counted `files: 122`. 122 fits "~125".

**Evidence:** `docs/reviews/execution-logs/q058-r1-nul-scan.log`, `docs/reviews/execution-logs/q058-r1-nulscan.sh`

---

## Claim 45: "The plan's Risks record the gate, the post-review hardening (T57-T62) and install.sh's new length (948 lines). T63 pins the section and the Risks line."

**Location:** `review/log.txt:112-114` (commit 66891a7 message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count at 66891a7 itself (b4fd792 later updated the plan to 958, Claim 34) and what T63 asserts. It does not establish that T63 pins the line count (it does not; it greps `Q-058` in Risks).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** Placement note: r2 (Claim 23 prose: "The 948 in 66891a7's message was right for that commit") and r3 (Claim 20 prose: 948 at 66891a7 "matches that commit's own figure") corroborate the count; r2 and r3 both describe T63's greps (r3: "the rubric link, the four residual keywords, and `Q-058` in the plan's Risks section").

Carried from r1 Claim 30. `git show 66891a7:devcontainer-config/install.sh | wc -l` gives 948. T63 greps `^## Trust model (Q-058)`, the residual keywords, and `Q-058` in the plan's Risks (`test/install-host.bats:988-999`).

**Evidence:** `test/install-host.bats:988-999`

---

## Claim 46: "The suite passed where the shell printed no warning and failed 53 tests where it did."

**Location:** `review/log.txt:122-123` (commit 648124c message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** "The suite" is `install-host.bats` (53 failures). The same pre-fix run also failed 8 tests in `cc-isolated-functions.bats` (61 in all), which the message does not mention.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: verdicted together with "315/315" (Claim 47) · Placement note: r3 (Claim 12 prose): "The 'failed 53 tests' figure matches the 53 `not ok` lines in the context log `execution-logs/q058-648124c/ih-66891a7.log`."

Carried from r1 Claim 31. Pre-fix: the four suites at 66891a7, in this shell with `LC_ALL=en_US.UTF-8` uninstalled (a warning on every bash start), 1..314, exit 1. There were 53 `not ok` in `install-host.bats` (numbers ≤63) and 8 in `cc-isolated-functions.bats`.

**Evidence:** `docs/reviews/execution-logs/q058-r1-prefix-replays.log`, `docs/reviews/execution-logs/q058-r1-run4.sh`

---

## Claim 47: "All suites: 315/315." (648124c) / "Suites 315/315." (b4fd792)

**Location:** `review/log.txt:127`, `:146-147` (commits 648124c and b4fd792 messages)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two suites that run install.sh (156/156, run here). It does not establish which suite set totals 315.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Unverifiable
**Replicate annotations:** r1: "'All suites' is the four-suite set used by the Q-058 reports, not all 1,599 tests in the repo"; post-fix run of `install-host.bats`, `cc-isolated-functions.bats`, `link-claude-home-wiring.bats` and `test/hooks/*.bats` at b4fd792 gave 1..315, 315 ok · r2: "the four suites named in the final rubric's count … 64 + 92 + 14 + 145 = 315, all passing"; "does not establish the count at 648124c (not re-run) or on the bare host" · r3: "`bats --count` gives 689 for all of `test/*.bats`" · r3 escalation: the commit should name the suite list (see Escalations E5).

Carried from r3 Claim 24. The context log `execution-logs/q058-648124c/suites.log` shows `1..315`, but neither commit names the suites. `bats --count` gives 689 for all of `test/*.bats`, and 208 for the five files that mention install.sh (170 + 20 + 18) (paraphrased, no quote available because the counts were interactive and not captured). To verify, the commit needs to name the suite list.

**Evidence:** `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`; `docs/reviews/execution-logs/q058-648124c/suites.log` (context)

---

## Claims Requiring Attention

### Incorrect
- **Claim 10a** (`install.sh:299`, fa69656 Notes): merged Incorrect from r1's compound verdict on the whole Notes sentence. For MODE lines themselves, all three replicates' prose says the stated mechanism (`review_diff` aborts next) does apply.
- **Claim 10b** (`install.sh:600-654`, fa69656 Notes): a failing vis on the host target's REPLACE, MOVE or ADD lines never reaches `review_diff`. `set -e` and `pipefail` end the run at the first `| vis`, with no message (exit 1). The run fails closed, but the note names the wrong mechanism.
- **Claim 27** (`037:73`): the gate sees only agents running at its three probe moments. A crafted TAB or newline name planted by an earlier session persists (P5: a planted TAB name made the prune delete a kept backup), so "which the gate refuses" does not cover the A4/A5 residuals.

### Stale
- none

### Mostly Accurate
- **Claim 4** (`install.sh:56-57`): the NOTE prints once per gate call (up to three per run), and any docker failure or timeout counts as none running, even after docker listed a container.
- **Claim 12** (`install.sh:350-358`): the no-follow guarantee covers only `claude-home`. The parent directories are checked once and resolved again by `cp`.
- **Claim 15** (`install.sh:829-831`): the script's own command line does match when the checkout path holds `/claude ` (a directory named `claude <x>`), and in that case `$$` is what drops it.
- **Claim 19** (ea2c8fb message): same as Claim 4.
- **Claim 22** (`037:64`): "whatever uid it runs as" is too strong. The container user must be mapped to the owner's uid or be root.
- **Claim 23** (`037:66`): the R2 hash covers the host target only. A devcontainer stage edited while the prompt waits is installed and blessed (P3).
- **Claim 24** (`037:68`): the gate samples at three instants and does not watch continuously.
- **Claim 26** (`037:70`): same as Claim 4.
- **Claim 29** (`037:74`): install.sh also runs `git rev-parse` and `git cat-file` in the checkout.
- **Claim 30** (`037:75`): the residual list leaves out agents that run between samples, non-Claude same-uid processes, and regex misses (the native versioned path, the Agent SDK CLI). "Does not end in `claude`" misdescribes the regex.
- **Claim 31** (`plan:244`): r2 rated the whole line Mostly accurate. The deviation it names is the false-match sentence (Claim 32).
- **Claim 32** (`plan:244`): false positives come from any `/claude` token or an argv0 of `claude`, not only from lines that end in `/claude`.
- **Claim 35** (`guide:17-20`): "refuses to stage … while either runs" is too broad. The host target stages with no fresh check after the startup gate (P4).
- **Claim 41** (ea2c8fb message): install.sh adds no override, but docker's `DOCKER_HOST`/`DOCKER_CONTEXT` can still blind the container probe.
- **Claim 43** (dfa5791 message): the gate refuses only a Claude Code process or container present at startup, not a racing process that starts later or is not Claude Code.

### Unverifiable
- **Claim 25** (`037:69`): whether every real Claude Code launcher (native versioned install, VS Code extension, SDK) produces a matching command line. Verifying it needs a pgrep probe on the bare host.
- **Claim 47** (commits 648124c, b4fd792): the suite set behind "315/315" is not named in either commit. r1 and r2 each reproduced 315 with a four-suite set.

## Goal-Alignment Note
- Success criterion (restated): merge the three `b4fd792` replicate reports into one canonical code-fact-check report by most-severe-wins, keep the schema, record per-replicate verdicts and the union of annotations, and add Escalations and Verdict stability sections. Add no claims or evidence of my own.
- Answered: yes. There are 48 merged claims (47 positions plus the 10a/10b split). Every replicate claim maps to at least one cluster. The report is saved to `docs/reviews/code-fact-check-report.md`.
- Out of scope: re-verifying any replicate's verdict or evidence, and running any of the replicates' probes.
- Escalate: see `## Escalations` (5 entries).
- Decisions I made:
  - Splits follow the finest granularity any replicate used, including splits across locations. One sentence restated in `--help`, in a commit message and in 037 became Claims 4, 19 and 26 because r2 verdicted those locations separately. The effect is that a compound verdict from one replicate appears on several rows.
  - Applying the rule mechanically makes Claim 10a (MODE lines) Incorrect, because r1 verdicted the whole fa69656 sentence Incorrect. Claim 31 is Mostly accurate for a similar reason (r2's compound verdict). Both carry a merge note.
  - Claim 2 counts r3 as Verified (compound) because r3's Claim 1 Scope explicitly claims to cover `--help`.
  - Claims 17, 28, 45 and 46 are marked single-replicate even where another replicate's prose corroborates them, because only one replicate verdicted each as a claim. The corroboration is recorded as a placement note.
  - Ties went by Scope specificity, then the lowest replicate number.
  - Claim 28's Evidence line points at the pass-3 report under its staged rename (`code-fact-check-report-pass3-9ae6e46.md`), because this merge overwrites the old path.

## Escalations

- **E1. The gate samples three moments; it does not cover the run.** `devcontainer-config/install.sh:391`, `:695`, `:947` (and `:834`). An agent present only between samples is not seen (P4: the host target staged and reviewed while an agent ran). Same-uid processes that are not Claude Code, such as detached leftovers, are never detected. Regex misses include the native versioned path and the Agent-SDK CLI. Decision 037 does not list these as accepted residuals. Raised by r1 (Goal-Alignment Escalate), r2 (Escalate item 2; Out of scope: "whether the gate design is enough to merge. That is a security or synthesis judgment") and r3 (Out of scope: "whether the gate's point sampling is an adequate design, as against a continuous check. That is for the security critic"). Addressee: **security-reviewer**. r1 frames acceptability as the user's call on Q-058's reading, so the orchestrator should surface it too.
- **E2. The devcontainer target (prior R1) has no content check after review.** `devcontainer-config/install.sh:399-402`; `docs/decisions/037-bare-host-copy-install.md:66`. P3 installed and blessed a stage edited while the prompt waited, with no process detected at y. 037:66 implies that the R2 hash covers this case. Raised by r1 (Escalate: "the prior R1 … is now covered only by point-in-time sampling") and r2 (Escalate item 1). Addressee: **orchestrator**.
- **E3. 037's TAB/newline residual rationale is refuted.** `docs/decisions/037-bare-host-copy-install.md:73`; `devcontainer-config/install.sh:806-807`. A name planted before the run bypasses the gate (Claim 27). r3 notes that "the user's Q-058 answer relied on the decision text". Raised by r1 (Escalate), r2 (Escalate item 3) and r3 (Escalate). Addressee: **orchestrator**.
- **E4. The probe shapes and the id-label were not checked on the bare host.** `devcontainer-config/install.sh:834`, `:860`; `docs/decisions/037-bare-host-copy-install.md:69`. Still unobserved: the process shape of the native launcher, the VS Code extension and the SDK, and whether the devcontainer CLI's `--id-label` becomes a docker label. r3's Claim 25 prose: "To verify, the probe needs to run on the bare host with each launcher in use". Raised by r1 (Out of scope: "live behaviour of real docker and devcontainer CLIs … the process shape of the VS Code extension or the native launcher on the user's host") and r3 (Claim 25). Addressee: **orchestrator** (host check).
- **E5. "315/315" does not name its suite set.** Commits `648124c` and `b4fd792` (`review/log.txt:127`, `:146-147`). r3's Claim 47 prose: "To verify, the commit needs to name the suite list." Raised by r3. Addressee: **orchestrator**.

## Verdict stability

- Total clusters: **48** (Claims 1–47, with 10 split into 10a/10b).
- Clusters where all reporting replicates agreed: **33**, including 6 single-replicate clusters (Claims 17, 28, 29, 42, 45, 46).
- Clusters where verdicts disagreed: **15**
  - Claim 4: r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Verified (compound)
  - Claim 10a: r1=Incorrect (compound) · r2=Mostly accurate (compound) · r3=Verified
  - Claim 10b: r1=Incorrect (compound) · r2=Mostly accurate (compound) · r3=Incorrect
  - Claim 12: r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
  - Claim 15: r1=Verified · r2=Mostly accurate · r3=Verified (compound)
  - Claim 19: r1=Mostly accurate (compound) · r2=Verified (compound) · r3=—
  - Claim 22: r1=Verified · r2=Mostly accurate · r3=Verified
  - Claim 24: r1=Mostly accurate · r2=Verified (compound) · r3=—
  - Claim 25: r1=Verified (compound) · r2=Verified (compound) · r3=Unverifiable
  - Claim 26: r1=Mostly accurate (compound) · r2=Verified (compound) · r3=—
  - Claim 31: r1=Verified (compound) · r2=Mostly accurate (compound) · r3=Verified (compound)
  - Claim 32: r1=Verified (compound) · r2=Mostly accurate (compound) · r3=Mostly accurate
  - Claim 35: r1=Verified (compound) · r2=Mostly accurate · r3=Verified
  - Claim 41: r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
  - Claim 47: r1=Verified (compound) · r2=Verified · r3=Unverifiable
- Agreement rate: **33/48 = 68.8%** of all clusters. Counting only the 42 clusters that two or more replicates surfaced, it is **27/42 = 64.3%**. Fourteen of the 15 disagreements have at least one compound-verdict participant (the exception is Claim 22).
