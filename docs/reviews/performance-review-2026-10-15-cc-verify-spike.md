Commit: 53770142

# Performance Review: cc-verify Q-117 spike paste (final pass, iteration 2)

**Scope:** `docs/working/spike-cc-verify-q117.md` at 53770142 (`git diff main...HEAD -- docs/working/spike-cc-verify-q117.md`). The script text is byte-identical to `spike-q117.final.sh` (checked with `cmp`).
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report-cc-verify-spike.md` (iteration 2, k=3, at 190fa1a4) and the fix commit 53770142.
**Focus:** host-side cost while other sessions keep running, resource lifecycle (leftovers, disk), and hang or timeout risks.

## Data Flow and Hot Paths

This script runs once, by hand, on the host, for up to about an hour. Every path in it is **cold** in the skill's sense: nothing runs per request or per item at scale. The costs that matter are the ones that affect the user's *other* sessions running at the same time (shared dockerd, disk, CPU), and whether the run's result stays trustworthy while those sessions change docker state underneath it.

Each phase, with its size, measured where I could:
- **Step 1, bare `--no-local` clone of the checkout.** Measured in my scratch dir against `/workspace`, the same repo: 1.3 s wall, a 31 MB bare repo.
- **Step 4, a second `--no-local` clone** into `VERIFY-<T8>`: 1.3 s wall, 116 MB (working tree plus `.git`). Both clones together: under 3 s and about 150 MB.
- **Snapshot hashing of `~/.config/claude-devcontainer`.** The install holds the ten payload items plus `claude-home` (skills, workflows, guides, patterns, hooks and scripts, about 2.7 MB in the repo). Hashing it twice is negligible.
- **Step 7, image build plus probe.** `devcontainer up --remove-existing-container` (cc-isolated.sh:883) uses no `--no-cache`. The Dockerfile is pinned to main's copy, so BuildKit should reuse every layer up to `ARG CC_CONFIG_HASH` (Dockerfile:484). Only the tail rebuilds: the COPY steps at :486-500 and the final RUN, a few MB. This is the dominant host cost, and it depends on the cache (Finding 2).
- **Step 8, the in-container wait.** One `devcontainer exec`, up to 90 polls 30 s apart (about 45 min, more if `getent` itself is slow). The host process only waits during it.
- **`relay`.** Measured: 20,000 lines (about 1.5 MB) in under 1 s. Build output is far smaller.
- **Teardown and compare.** About ten docker CLI calls in total, plus one per verify container (exactly one) and one per new image. Nothing scales with the host's container or image count, apart from `docker image ls` and `ps -a` listings and one `grep` against the snapshot file per verify image.

## Findings

#### 1. Concurrent docker activity by other sessions turns a clean run into exit 1 and blames the research claim

**Severity:** Medium
**Location:** `docs/working/spike-cc-verify-q117.md:159-172` (`compare`), `:147-149` (`snapshot`)
**Move:** Find the contention point (shared dockerd across the run's window)
**Classification:** Macro (the run's result depends on all host docker state across about an hour) / Cold path (one-shot run that blocks the verdict)
**Confidence:** High (executed)
**Legibility-target:** the user reading the pasted-back `CHECK` lines, and whoever acts on the §7 image-naming claim
**Baseline:** no baseline available — flagged as speculative (how often other sessions recreate containers in an hour is unmeasured; the mechanism itself was executed, below)

Evidence (verbatim):
```
  x="$(comm -23 "$b/containers" "$a/containers")"
  if [ -z "$x" ]; then echo "CHECK no pre-existing container removed: ok"
  else echo "CHECK no pre-existing container removed: FAIL"; printf '  %s\n' "$x"; bad=1; fi
  ...
  x="$(comm -23 "$b/images" "$a/images" | grep -v '^<none>:<none> ' || true)"
  ...
  else echo "CHECK no pre-existing image tag moved or removed: FAIL (research §7 image-naming claim)"; printf '  %s\n' "$x"; bad=1; fi
```
The before snapshot is taken at step 5 and the after snapshot after teardown, about an hour later. Any line present before and gone after counts as a FAIL. The doc's premise is that other sessions keep running. Main's own launcher recreates a project's container with `devcontainer up --remove-existing-container` (cc-isolated.sh:883, :895) whenever the blessed config changed since that container was built, and on every `--probe-only`. That gives the container a new ID, and its rebuilt `vsc-<project>-…` tag moves to a new image id. Both CHECKs then FAIL, `bad=1`, and the run exits 1. The image FAIL message attributes the failure to the research §7 image-naming claim.

Reproduced in a copy of the stub harness. During step 8, the fake `devcontainer` replaced the harness container `charness111` with `charness222` (same label) and moved `vsc-claude-workflows-xyz:latest` to a new id. Output:
```
RESULT Q-117 pass (tree 65e65962…, config 6ed8a5e3457bee6e)
CHECK no pre-existing container removed: FAIL
  charness111 ctr-aaaaaaaaaaaa
CHECK no pre-existing image tag moved or removed: FAIL (research §7 image-naming claim)
  vsc-claude-workflows-xyz:latest sha256:aaa94026…
NOTE created during the run and still present (another session's, or a build leftover; not removed):
  charness222 ctr-aaaaaaaaaaaa
RESULT spike-q117 exit=1
```
Q-117 passed and nothing outside the run was touched by the script. The run still reports exit 1 and a refuted research claim. The doc's exit-status list says `1` means "a failed CHECK", and it anticipates other sessions only for *additions* (the NOTE block, :457). Removals and retags caused by other sessions are not mentioned. The opposite error does not occur: concurrency cannot hide a real removal by the script. So this only produces false alarms. The script cannot tell its own effect from a neighbour's on the same object, which makes the harm a misread result, not a host-safety problem.

**Recommendation:** Scope these two CHECKs to what this run could plausibly touch, or say in the doc what concurrency does to them. Two ways to scope:
- Before failing, check each missing image tag against the image ids the run itself created (the container's image and the `vsc-verify-<T8>` ids).
- Match each "removed" container's `cc-project` label against the after-snapshot (same label, new ID: a neighbour's recreate).

At minimum, add one sentence under "Exit status" or "What to paste back": "a CHECK FAIL that names another project's container or `vsc-<other>` tag, with a matching NOTE line, is usually another session's rebuild during the run." Also drop the unconditional "(research §7 image-naming claim)" attribution: that claim is refuted only if the moved tag belongs to this run's build.

#### 2. BuildKit build cache from the verify build is a disk leftover that nothing snapshots, reports or removes (multi-GB if the cache misses)

**Severity:** Low (Medium if the build misses main's cache)
**Location:** `docs/working/spike-cc-verify-q117.md:22` (created table, the image row), `:100-142` (`teardown`), `:524` (Not verified 12)
**Move:** Trace the resource lifecycle; price the deployment environment
**Classification:** Macro (the leftover's size equals the rebuilt layer volume) / Cold path (one-shot), escalated if the build runs over large data
**Confidence:** Medium on the mechanism (BuildKit cache records outlive `docker image rm` until `docker builder prune`); Low on the trigger for a full rebuild
**Legibility-target:** the user, who is told teardown removes "everything the script creates"
**Baseline:** no baseline available — flagged as speculative (the sandbox has no docker; build cache size and hit rate were not measured)

Evidence (verbatim):
```
| one image | the one the container ran, plus any `vsc-verify-<TREE8>-…` build tag | the trap, only with proof the image is this run's: ...
```
```
12. **The build's network and time.** Base layers are probably cache-shared with main's image, because the Dockerfile is identical. Not measured.
```
The teardown removes the verify container's image and the `vsc-verify-<T8>` tags. The layers BuildKit built for them stay in its build cache (`docker system df`, "Build Cache"). The snapshot lists only containers, volumes and image tags, so the leftover appears in neither a CHECK nor the NOTE. In the expected case (cache hit through Dockerfile:484) the leftover is small: `egress/`, the three scripts, `claude-home/` (about 3 MB) and the final RUN layer, plus any `-uid` layer the devcontainer CLI adds.

Two things can make the build miss main's cache, and the leftover is then the full image: node, Android SDK, .NET, Rust, Lean, gigabytes. The full rebuild also downloads all of that and burns CPU and IO on the host the other sessions share for tens of minutes, which the doc's "up to about an hour" does not budget for. The two triggers:
- A build arg that differs from the one main's image was built with. The likeliest is `"TZ": "${localEnv:TZ:America/Los_Angeles}"` (devcontainer.json build args, consumed at Dockerfile:16-17, the second instruction). The terminal the user pastes into may export a different `TZ` than the shell that built main's image.
- A pruned builder cache.

**Recommendation:** Add the build cache to the created table as "not removed (shared cache; remove only by hand)". Do not have the script prune: `docker builder prune` is global and would evict other sessions' cache. Optionally record `docker system df` in both snapshots and print the build-cache delta as a NOTE. Under "Not verified 12", name the TZ/build-arg match as the condition for the cached build and give the uncached cost in words ("if step 7 starts downloading the Android SDK, the cache missed: expect a full rebuild").

#### 3. TERM to the script is deferred until the current foreground command finishes, up to about 45 min in step 8

**Severity:** Low
**Location:** `docs/working/spike-cc-verify-q117.md:244` (`trap 'exit 130' INT TERM HUP`), `:385-387` (step 8), `:462` (exit-status 130 line)
**Move:** Find the contention point (signal delivery across a blocking foreground pipeline)
**Classification:** Micro (latency of interruption only) / Cold path
**Confidence:** High (executed)
**Legibility-target:** the user stopping a run with `kill`, and the doc's exit-status list
**Baseline:** measured in the stub harness (this review, 2026-10-15): SIGTERM sent to the script's PID during a 60 s fake step-8 exec took 59.9 s to reach `RESULT spike-q117 exit=130`.

Evidence (verbatim):
```
trap 'exit 130' INT TERM HUP
```
```
- `130`: interrupted (Ctrl-C, TERM, HUP). The trap still tears down.
```
Bash runs a trap only after the foreground command returns. Ctrl-C reaches the whole foreground process group, so `devcontainer exec` and `relay` die and the trap runs at once. A `kill <pid>` of the script reaches only bash. Bash then waits for `devcontainer exec`, which runs the 45-minute poll inside the container, or for the image build in step 7, and only then tears down. Neither step has a host-side timeout either. A hung build or exec blocks until Ctrl-C. Docker resources are not lost, since teardown does eventually run and `--clean` covers a `kill -9`. But someone who TERMs the run to free the host (the case this focus cares about) sees no teardown for up to an hour.

**Recommendation:** Add to the 130 line: "TERM sent to the script alone waits for the current step (up to about 45 min in step 8); use Ctrl-C in its terminal, or signal its process group (`kill -TERM -- -<pgid>`)." Optionally run the two long steps in the background and `wait` on them, so a trap can interrupt `wait`. That is a larger change than a spike needs.

#### 4. The step-4 workspace clone copies the objects a second time where a hardlinked or shallow clone would do

**Severity:** Informational
**Location:** `docs/working/spike-cc-verify-q117.md:326`
**Move:** Find the work in the wrong place
**Classification:** Micro / Cold path
**Confidence:** High (measured)
**Legibility-target:** spike maintainer
**Baseline:** measured in my scratch dir against `/workspace` (2026-10-15): `clone --no-local` from the bare clone took 1.26 s, 116 MB; a hardlinking local clone took 0.35 s, 85 MB of new data; `--depth 1` took 1.06 s, 108 MB.

Evidence (verbatim):
```
git -c core.hooksPath=/dev/null -c core.fsmonitor=false clone -q --no-local --template= -- "$SRCGIT" "$W" </dev/null
```
The source here is the script's own bare clone, not the user's checkout. So the trust reason for `--no-local` in step 1 (upload-pack reading the checkout's config) does not apply in the same way, and the copy costs about 30 MB and 1 s more than a hardlinked clone. At this repo's size that is noise.

**Recommendation:** Leave it unless the repo grows by an order of magnitude. Keeping `--no-local` means no inode is shared between `SRCGIT` and the container-writable `VERIFY/.git`. That is the right default for a spike.

## Endorsements

- The host-side git cost is small and bounded. Both clones together took under 3 s and wrote about 150 MB for this repo, and every git object operation runs against the script's scratch bare clone, never the checkout's working tree. [read: docs/working/spike-cc-verify-q117.md:250-271,326] (timings measured in this review, scratch dir removed)
- `relay`'s per-line bash loop is not a bottleneck. 20,000 lines (about 1.5 MB) passed through `vis` and the loop in under 1 s, so it cannot backpressure the launcher meaningfully at build-output volumes. [read: docs/working/spike-cc-verify-q117.md:86-89] (measured in this review)
- The step-8 wait cannot spin for 45 minutes on a missing address. With an empty or `NONE` `$first`, `grep -qxF` against `getent` output fails on the first poll and the loop breaks, so the long wait happens only when there is a real address to wait out. [unverified — submitted as claim]
- After an incomplete teardown, only the small before-snapshot (three listings and a hash file) is kept for `--clean`. The after-snapshot is removed in `compare`, and the log is the only file that grows across runs (one per run, holding build output). [read: docs/working/spike-cc-verify-q117.md:159-201]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Concurrent recreate or rebuild by another session fails two CHECKs, exits 1 and blames §7 | Medium | `spike-cc-verify-q117.md:159-172` | High |
| 2 | BuildKit build cache leftover is not snapshotted, reported or documented; multi-GB on a cache miss (e.g. TZ build arg) | Low (Medium on cache miss) | `spike-cc-verify-q117.md:22,100-142,524` | Medium |
| 3 | TERM to the script waits for the foreground step (measured 59.9 s for a 60 s step; up to about 45 min real) | Low | `spike-cc-verify-q117.md:244,385-387,462` | High |
| 4 | Step-4 clone duplicates objects; about 1 s, 30 MB | Informational | `spike-cc-verify-q117.md:326` | High |

## Overall Assessment

The run's own host cost is modest and bounded: under 3 s of git, about 150 MB on disk, negligible hashing and relay cost, and one cached image build. It creates no resource that teardown does not either remove or report, with one exception: the BuildKit build cache. That cache is the one item worth documenting, and it becomes a real cost only if the build misses main's cache. The most important finding is about trusting the result under concurrency, not cost. A neighbour session that rebuilds its container during the hour produces `CHECK … FAIL`, exit 1, and a false attribution to the research §7 image-naming claim. That is fixable in place with a doc sentence or a label-aware comparison. None of the findings indicate a structural problem, and none re-open an iteration-1 or iteration-2 fix. I found no new hang beyond the documented 45-minute wait. The one exception is that a TERM to the script alone does not interrupt that wait. Confirming Finding 2's cache-hit assumption needs the host run: watch whether step 7 rebuilds anything before `ARG CC_CONFIG_HASH`, and run `docker system df` before and after.

Execution hygiene: all runs used my own `mktemp -d` dirs under `/home/node/.claude/jobs/00bcf178/tmp/` and a copy of the harness. `t1/` and the final script were not modified. Every process ran under `timeout` and was stopped by PID. Both scratch dirs were removed, and no harness process remains.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved to the path named at the end of this prompt, structured per your role's skill, with a `Commit: 53770142` first line."

This report is saved at `docs/reviews/performance-review-2026-10-15-cc-verify-spike.md` in the branch worktree. It opens with `Commit: 53770142` and follows the performance-reviewer structure: data flow, findings with baselines, evidence-tagged endorsements, summary table and assessment. It serves the user goal, "a reviewed, safe one-paste host spike that live-verifies a branch without installing it", by showing that the paste is cheap and leaves little behind on a shared host. It also shows where the run's verdict can be misread while other sessions keep running (Finding 1) and where a cost assumption is untested (Finding 2). No finding blocks the paste's safety.
