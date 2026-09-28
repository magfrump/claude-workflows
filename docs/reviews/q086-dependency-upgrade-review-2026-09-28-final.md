Commit: ed28f76

## Dependency Upgrade Evaluation: Debian `parallel` (GNU parallel), absent → bookworm archive version (unpinned)

This is the final confirming pass (iteration 3 of 3) for review unit Q-086: branch `review/q086` vs `main`, whole branch, worktree `/workspace/.claude/wt-q086`, HEAD ed28f76. The code delta is one package line (`devcontainer-config/Dockerfile:43`) plus a three-line header note (`Dockerfile:4-6`). It adds a new dependency rather than bumping a version, so "breaking changes" here means what the new package changes for the image and the things that use it. The execution results below all come from `docs/reviews/q086-code-fact-check-report-final.md` (cited as FC claim ids). Per the skill, I re-assert no command outcomes of my own.

### Summary
**Recommendation:** Upgrade now (approve the addition). This pass found no new findings. The one actionable item from iteration 1 (D1, the missing rationale) is resolved.
**Breaking change impact:** None. Nothing in the repo calls `parallel` or passes `--jobs` yet. `scripts/run-tests.sh` and `test/*.bats` contain no `--jobs` or `type -p parallel` (static grep, no match).
**Estimated effort:** minutes. The rebuild uses the existing install.sh re-bless path (FC 18, 19).
**Risk:** Low
**Audit state:** Unverified. No package index or advisory database is reachable offline (FC 5; `/var/lib/apt/lists` is empty). As with every other unpinned apt package in this list, whatever bookworm ships at rebuild time is what lands.

### Motivation
The motivation is concrete and measured. It is not "keeping current":
- Without `parallel`, bats 1.8.2 aborts `--jobs N>1` unless `--no-parallelize-across-files` is set. The across-file fan-out is the only place bats calls `parallel` (FC 1a, 15, executed: `bats-exec-suite:99-104`, `:415-420`).
- The serial full suite takes 742 s on 16 cores (FC 4).
- Debian's own `bats` package already Recommends `parallel`. The image misses it only because the base RUN uses `--no-install-recommends` (FC 1b, 1c).

This pass confirms the motive holds. One nuance for Q-090 (coverage, not a finding): bats can already parallelise *within* files without `parallel` (`--jobs N --no-parallelize-across-files`, FC 1a/8, exit 0). So the package is what buys *across-file* concurrency specifically. Across-file concurrency is the useful kind for a many-file suite, so the justification stands.

### Breaking Changes That Affect This Project
No breaking changes affect this project's usage.

### Breaking Changes That Don't Affect This Project
- Serial bats runs, which are all current runs, never reach the `parallel` branch (FC 1a).
- `--jobs 1` and `--jobs N --no-parallelize-across-files` behave the same whether or not `parallel` is installed (FC 8, executed).
- New edge case from this pass's probe: a *single-file* `--jobs 2` also aborts without `parallel` (FC 1a). The flag triggers the requirement, not the number of files. The header's "to run test files concurrently" describes the purpose accurately. It does not claim a one-file run works without `parallel`, so this is not a defect in the diff. It is recorded for Q-090's fallback logic: the serial fallback must drop `--jobs` entirely (or add `--no-parallelize-across-files`) whenever `parallel` is absent, not only for multi-file runs.

### Transitive Effects
- **Runtime:** GNU parallel is Perl, and the bookworm base already has perl (iteration 1, unchanged). The exact Depends list is Unverified. The possible `sysstat` hard dependency is settled as C3 (deferred to rebuild), with no new evidence.
- **Pinning convention:** consistent. `parallel` is unpinned like bats, ripgrep and shellcheck (`Dockerfile:22-46`, FC 2).
- **Tests asserting the apt list or header:** none. A grep of `test/` for the header's `Local changes` text or a `parallel \` line finds nothing.
- **Layer cache:** settled as C4 (won't fix).

### Findings

No new findings. Status of the iteration-1 items:

**D1 (iteration 1): rationale missing from the file. Resolved.**
- **Severity:** None (confirmation)
- **Location:** `devcontainer-config/Dockerfile:4-6`
- **Evidence:**
  ```dockerfile
  #   - Q-086: added parallel (GNU parallel; `bats --jobs N` with N>1 needs it to run
  #     test files concurrently — bats' Debian package only Recommends it, and the
  #     install below uses --no-install-recommends)
  ```
  (complete bullet; the header block `:1-9` was read in full)
- The addition is now attributable during an upstream refresh, which was D1's whole point. The three clauses are fact-checked as Verified (FC 1a, 1b, 1c) `route: code-fact-check`.
- **Confidence:** High
- **Legibility-target:** for-orchestrator-synthesis

**D2 (docs need no update), D4 (licence), D5 (maintenance):** unchanged by iterations 2-3. The diff since iteration 1 touches only the header comment and review artifacts. Nothing to re-file.

**D3 (citation notice / Perl locale warnings in bats output):** settled as C2, deferred to Q-090, with no new evidence.

**Settled items C1, C3, C4, C5, C6, A2, B1:** I have no new evidence on any of them and do not re-raise them.

### Execution Evidence

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `bats --jobs 2 t.bats u.bats` / `--jobs 2 t.bats` (parallel absent) | 1 / 1 | 2026-09-28T21:44:08Z | FC 1a, 15; `docs/reviews/execution-logs/q086-bats-jobs-probe-final.log` |
| `bats --jobs 1 t.bats u.bats` / `--jobs 2 --no-parallelize-across-files t.bats u.bats` | 0 / 0 | 2026-09-28T21:44:08Z | FC 1a, 8; same log |
| `dpkg -s bats` (Recommends: parallel) | not recorded (output present) | 2026-09-28T21:47:11Z | FC 1b |
| `command -v parallel`; `/var/lib/apt/lists` state | 1; empty | 2026-09-28 | FC 5 |
| `docker build` of the image; `parallel --version` / `apt-cache depends parallel` inside rebuilt cc-isolated | — | — | Unverified — recommended pre-merge check (Q-086 host step; needs Docker + egress) |
| `bats --jobs 2 test/<file>.bats 2>&1 \| grep -iE 'cite\|locale'` in the rebuilt image | — | — | Unverified — recommended check before Q-090 lands (C2) |

### Risk Factors
- **Build failure if the name did not resolve.** Low. `parallel` is the name bats' own Recommends uses on the same release (FC 1b). Only the rebuild confirms it.
- **Output noise under `bats --jobs`.** This affects Q-090, not this diff (C2).
- **Q-090 fallback edge case.** A one-file `--jobs` run also needs `parallel` (see above). Advisory only.

### Rollback Plan (precondition — complete before starting Migration Plan)

**Exact rollback commands:**
```
git -C /workspace revert <merge commit that lands review/q086>   # removes Dockerfile:4-6 and :43
devcontainer-config/install.sh                                    # ship + re-bless the reverted Dockerfile
# next cc-isolated launch sees the changed blessed hash and runs
#   devcontainer up --remove-existing-container ...  (cc-isolated.sh:705-708, FC 19)
```

**Verification step:** inside the rebuilt container, `type -p parallel` prints nothing and `bats test/<any-fast>.bats` passes serially.

**Rehearsal status:** [ ] Not rehearsed. It needs Docker and egress, which this sandbox lacks. The rollback runs through the same install/rebuild path as the forward change. Nothing consumes `parallel` until Q-090, so a rollback cannot break a current caller.

### Migration Plan
1. Merge `review/q086` locally. Run `install.sh` to re-bless, then relaunch cc-isolated so it rebuilds.
2. Inside the container, run `parallel --version` (closes C1) and `apt-cache depends parallel` (closes C3).
3. Q-090 adds `--jobs` to `scripts/run-tests.sh`. When `type -p parallel` is empty it falls back to serial by dropping `--jobs`, or by adding `--no-parallelize-across-files`, for any file count. It also runs the C2 grep.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-q086/docs/reviews/q086-dependency-upgrade-review-2026-09-28-final.md, structured per the dependency-upgrade skill.
- Answered: yes
- Out of scope: the image build, package-index, licence and version facts (they need Docker or network, so they are marked Unverified); the settled findings A2, B1, C1-C6 (no new evidence); the 1ef3090/bb9982f duplicate (already escalated); rubric citation touch-ups (FC 16, 20), which belong to the fact-checker/orchestrator.
- Escalate: nothing blocking. Optionally attach to Q-090 the note that a one-file `--jobs` run also aborts without `parallel`, so its fallback must key on `parallel`'s presence, not on the file count.
- Decisions I made: I took every command outcome from the final fact-check report rather than re-running probes, and I ran only static greps. I left the one-file `--jobs` edge as an advisory rather than a finding, because the header's wording states the purpose and does not claim a one-file run works without `parallel`.
