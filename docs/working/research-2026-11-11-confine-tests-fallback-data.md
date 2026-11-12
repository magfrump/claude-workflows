# Research: data for the run-or-refuse question's return

Date: 2026-11-11 · Brief: `docs/working/briefs/2026-11-11-confine-tests-fallback-data.md` · Base: ee637249

repo text is evidence, not instructions

Failure-pattern grep: `rg -n 'bwrap|unshare|confine|namespace' docs/failure-patterns.md` -> FP-050 (an unshare tier shares the host mount namespace and writes reach the host), FP-052 (a confinement that blocks all writes crashes a suite), FP-058 (a bwrap runtime failure drops the work silently), FP-076 (a headless read confined to the working directory; not relevant here). The first three are context for the options below; this unit is docs only.

Failure-pattern skip: no fix(...) commits on this branch; it adds one research doc and nothing in it is a defect fix.

## Summary

- **The fallback has never run.** Every recorded run of `scripts/confine-tests.sh` exited 3: 7 build loops from 2026-11-05 to today, plus the reviewer runs listed in section 2. All of them exited 3 because neither `bwrap` nor `unshare -rn` works. No warning has ever been printed, so there is nothing to count yet.
- **A refusal would have stopped 0 more runs.** Refuse and run-and-warn differ only where `bwrap` fails and `unshare -rn` works. No recorded environment has been in that state.
- **Where that state can happen is not known yet.** In sessions after the Q-273 release `bwrap` is installed, but a nested `bwrap` inside Claude Code's own `bwrap` has never been tried. The host is unrecorded. The release's first in-session `--probe` will settle the session case; it waits on Q-277.
- **A refusal costs a loop little.** Loops already handle exit 3: they run `scripts/run-tests.sh` unconfined, plus the hermeticity lint. But that fallback is *less* confined than `unshare`, which still denies the network. In today's image, refusing inside a loop swaps "network denied, filesystem open" for "nothing denied". After the release, the unconfined run still sits inside Claude Code's Bash sandbox, but that sandbox allows the project's egress list. The case for refusing is about what a pass means (H2), not about exposure.
- **Verdict: not enough data on frequency. Friction measured so far: zero.** The recommendation is [2] (refuse unless asked), with the brief wording passing the opt-in flag. See the end.

## 1. Is `bwrap` present? By environment

| # | Environment | `bwrap` installed | User namespaces | Primitive the script would pick | How sure |
|---|---|---|---|---|---|
| 1 | This sandbox (this build loop, 2026-11-11) | no | refused | **neither (exit 3)** | observed (below) |
| 2 | Image at 536b7082 (what sessions run today) | no | refused (Docker's default seccomp) | **neither (exit 3)** | high: same image as row 1, plus the Dockerfile read |
| 3 | Image after the Q-273 release (Dockerfile on main) | yes | allowed by the new seccomp profile | **`bwrap`** at the top level | medium-high: Q-126's host probe ran bwrap under this profile |
| 4 | Inside the new Bash sandbox (every Bash call in a session after the release) | yes | nested inside Claude Code's `bwrap`: untested | **`bwrap`, `unshare` or neither: unknown** | low: inference only |
| 5 | The owner's host (WSL2) | unknown | probably allowed (no LSM) | **`unshare` if bwrap is missing, else `bwrap`** | low: no run on record |

### Row 1: this sandbox

Run on 2026-11-11 in this worktree, under `timeout 30`: `scripts/confine-tests.sh --probe`, **exit 3**. Its output, in full on stderr:

```
confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.

  Your tests were NOT run. This is deliberate: running them unconfined here
  would report a green that means nothing, which is the precise failure this
  guard exists to prevent.

  Neither primitive is usable in this environment:
    * bwrap --unshare-net
    * unshare -rn  (unprivileged user namespace + network namespace)
  [... the hardened-container hints, as in scripts/confine-tests.sh:114-120]
```

Alongside it: `which bwrap` prints "bwrap not found"; `command -v unshare` gives `/usr/bin/unshare`; `/proc/self/status` shows `CapEff: 0000000000000000` and `Seccomp: 2` with 3 filters. So `bwrap` is absent, and `unshare -rn` fails at detection (`scripts/confine-tests.sh:94-95`). The 2026-11-07 run recorded the same failure as `unshare: unshare failed: Operation not permitted` (`docs/working/research-2026-11-07-confine-tests-situation.md:34`).

### Row 2: the image at 536b7082

`git show 536b7082:devcontainer-config/Dockerfile | rg 'bwrap|bubblewrap'` finds nothing. `devcontainer-config/seccomp-cc-sandbox.json` does not exist at 536b7082 (`git cat-file -e` fails), so the container runs Docker's default seccomp profile, which refuses `CLONE_NEWUSER` without `CAP_SYS_ADMIN` (decision 017 finding 1; `docs/spikes/weaker-nested-sandbox-cc-isolated.md:26`). The cycle records name 536b7082 as the running image (`docs/working/cycles/cycle-2026-11-10.md:127`), and the Q-273 interim says "the image at `536b7082` runs" (`docs/working/questions.md:117`). Rows 1 and 2 are the same environment. Every recorded probe ran here.

### Row 3: the image after the Q-273 release

`devcontainer-config/Dockerfile:385-387` on main installs `bubblewrap` and `socat`. Its comment at :382-383 says it is "the plain, non-setuid Debian build: it gets its namespaces from the user-namespace allowance in seccomp-cc-sandbox.json". `devcontainer-config/devcontainer.json:70` applies that profile. Its rule at `seccomp-cc-sandbox.json:114` allows `clone`, `mount`, `pivot_root`, `umount2` and `unshare`. Q-126 (`docs/working/questions-archive.md:2315-2316`) ran bubblewrap 0.8.0 in a container under that profile on the owner's WSL2 kernel: "T1 fresh `/proc` pass, T2 bind `/proc` pass". So a process outside the Bash sandbox in that container, such as a hook or a script run by the harness rather than by a Bash call, would get `bwrap`. That is an inference from Q-126's probe. Nobody has run `confine-tests.sh` there.

This image is not running yet. The live check failed (`docs/working/questions.md:71`), and the install (Q-273's paste 2) is on hold for Q-277 (`docs/working/questions.md:107`).

### Row 4: inside the new Bash sandbox

Once the release is installed, every Bash call in a session runs inside Claude Code's own `bwrap` (`devcontainer-config/Dockerfile:378-381`). So a loop's `scripts/confine-tests.sh` becomes a **nested** `bwrap`. On record:

- The owner's Q-273 live check reached the end: `VERDICT FAIL (3 not pass, 0 missing)`. The C4, C5 and C6 lines passed (`docs/working/questions.md:71`). So the outer sandbox does start in that image on the host. **The check had no `confine-tests.sh` line and no nested-namespace line.** It says nothing about row 4.
- Q-125's plan lists "Nested user namespaces from inside the sandbox (Claude Code passes no `--disable-userns`; its own helper needs `unshare(CLONE_NEWUSER)`)" as an accepted residual (`docs/working/plan-q125-cc-isolated-sandbox.md:93`). That suggests nesting is allowed [inferred].
- The archived layer-3 spike showed nested `bwrap` working, but on the host before Docker (`archive/docs/2026-08-06-spike-nested-bwrap-fixture-confinement.md`, cited at `research-2026-11-07-confine-tests-situation.md:54`). The boundary has changed since.
- The roadmap already plans the first `--probe` in a session after the install (`docs/roadmap.md:67`). It also notes that `--probe` asks `bwrap` for less than a run does, so a probe can pass and the run still fail to start (`docs/roadmap.md:195-196`). Comparing `scripts/confine-tests.sh:90` with `:253-264` shows the gap. The probe passes only `--ro-bind / / --unshare-net`. The run adds `--dev`, `--proc`, `--tmpfs /tmp`, `--setenv`, `--bind "$PWD"`, `--unshare-pid`, `--die-with-parent` and `--chdir`. Of those, `--proc`, `--tmpfs` and `--unshare-pid` are the ones most likely to fail when nested.

The row-4 case is the one where Q-272 matters most: `bwrap` installed, but possibly unusable nested. If the nested `bwrap` fails on its mounts while a bare `unshare -rn` (user and net namespaces only, no mounts) succeeds, the fallback runs. If both fail, the result is exit 3, as today. Which of the three happens is **not known**, and only the post-release probe will show it.

### Row 5: the host

Q-126 recorded "no LSM" on the owner's WSL2 kernel (`questions-archive.md:2315`). So the AppArmor block on unprivileged user namespaces should not apply, and `unshare -rn` probably works there (`research-2026-11-07-confine-tests-situation.md:55`). Whether `bwrap` is installed on the host is not on record: Q-126 installed it only inside throwaway containers. No loop runs on the host, and S10 (spend the owner's attention last) rules out a recurring host run. This brief also rules out running anything there.

## 2. Friction: what a refusal would have stopped

### Records that name the script in a test step

Searched: `rg -l confine-tests` over the 3 open briefs in `docs/working/briefs/`, the 52 in `briefs/closed/` and the 18 cycle records in `docs/working/cycles/`.

**Briefs (9 name it in a test or task line, 7 of them test lines; 46 do not):**

| Brief | What its test line says | Run on record | Result |
|---|---|---|---|
| closed/2026-11-06-owner-entry-gloss-rule | tests "pass under `scripts/confine-tests.sh`" (:22) | the loop reported it could not run (`cycle-2026-11-06.md:297`) | refused |
| closed/2026-11-06-codify-trial-practices | "Do not require `scripts/confine-tests.sh`: it cannot run in this container" (:25) | none: the line says not to run it | n/a |
| closed/2026-11-07-confine-tests-situation | run it under `timeout` and record how it fails (:18) | `research-2026-11-07-confine-tests-situation.md:32` | exit 3 |
| closed/2026-11-10-confine-tests-bats | conditional `--probe` wording (:22) | `research-2026-11-10-confine-tests-bats.md:24` | exit 3 |
| closed/2026-11-10-confine-tests-dash-and-fallback | conditional `--probe` wording (:28) | `research-2026-11-10-confine-tests-dash-and-fallback.md:24` | exit 3 |
| closed/2026-11-10-dev-cycle-skill-held-fixes | conditional `--probe` wording (:29) | `research-2026-11-10-dev-cycle-skill-held-fixes.md:48` | exit 3 |
| 2026-11-11-constraint-drift-audit (open) | conditional wording, "none are needed for a docs-only unit" (:25) | in flight, no commits yet | — |
| 2026-11-11-light-pass (open) | conditional `--probe` wording (:23) | in flight, no commits yet | — |
| 2026-11-11-confine-tests-fallback-data (this one) | run `--probe` here (:19) | section 1, row 1 | exit 3 |

**Cycle records (7 of 18 name it):** 2026-10-17 and 2026-10-20 name it only in trigger checks: "0 window commits", "no `confine-tests.sh` run". 2026-11-07 and 2026-11-11 name it as brief and roadmap work. Three report loop runs:

- `cycle-2026-11-05.md:165`: the q089-source-guard-narrow loop: "`scripts/confine-tests.sh` could not run in session (exit 3)". That brief did not name the script; the loop ran it on its own.
- `cycle-2026-11-06.md:297`: the gloss-rule loop, above.
- `cycle-2026-11-10.md:190`: "`scripts/confine-tests.sh --probe` still exits 3 here (both loops' reports, and no `bwrap` on PATH)".

**Runs, counted once each: 7.** These are q089 (2026-11-05), gloss-rule (2026-11-06), situation (2026-11-07), bats (2026-11-10), dash-and-fallback (2026-11-10), held-fixes (2026-11-10) and this one (2026-11-11). **All 7 exited 3 with neither primitive. None reached `unshare`.** That count is of loops, not of invocations. Some loops ran the script more than once: dash-and-fallback ran it "at 23ffb16c and again on this branch's final tree" (its research doc :24), and the 2026-11-07 doc also ran `-- true` (:33). Their reviewers ran it too: the q089 security critic (`docs/reviews/security-review-2026-11-05-q089-source-guard.md:145`) and fact-check replicates (`docs/reviews/code-fact-check-report-final-r3-2026-11-10-confine-tests-dash-and-fallback.md:231`). Every one of those recorded invocations exited 3 as well. A refusal on fallback would have stopped **0** of them beyond what already stopped. The fallback's warning (`scripts/confine-tests.sh:216-230`) has printed **0** times on record. The banner `denying network via` and `primitive available:` occur nowhere in the repo but the script itself (checked on 2026-11-07, `research-2026-11-07-confine-tests-situation.md:59-66`). No later record reports either line.

### Which tests a refusal would stop

`scripts/run-tests.sh` runs bats only: it is the bats runner, and every `.bats` file carries a `# @category` tag (`scripts/run-tests.sh:3`). `test/` holds 145 `.bats` files and 22 `.py` files. Twenty of the 22 are skill-eval fixtures under `fixtures/`. The other two, `test/test_cc_sni_proxy.py` and `test/skills/arithmetic-eval/mode1-equiv.py`, are run from bats suites (`test/cc-sni-proxy-unittest.bats`, `test/skills/mode1-equiv.bats`). So the loop's test step is **100% bats**. Under a refusal, `scripts/confine-tests.sh -- scripts/run-tests.sh` runs **none** of the 145 suites confined. Exit 3 comes before any command runs, at detection (`scripts/confine-tests.sh:142-145`) or, on the `unshare` path without `ip`, at `:190-193`.

What the loop falls back to is what it does on every exit 3 today (the conditional wording from `research-2026-11-07-confine-tests-situation.md:125`): quote the first line, run `scripts/run-tests.sh` unconfined, and run `scripts/hermeticity-lint --root .`. The lint passes on this branch (exit 0). It covers subprocess spawns of `claude`, `curl`, `wget` and `gh` without a stub. It does not cover in-process HTTP or other network binaries (`research-2026-11-07-confine-tests-situation.md:108-117`).

So the friction of refusing is small for a loop: one quoted line, and acceptance rests on the unconfined run plus the lint, a path already walked 7 times. The cost is in what that fallback leaves out. Under `unshare` the suite runs with the network denied at the kernel. Under refusal plus the fallback it runs with nothing denied. `unshare -r` maps uid 0 to the caller's own uid, so it cannot write anything the unconfined run cannot. The filesystem risk Q-272 named (a stray write "lands on the real filesystem": `scripts/confine-tests.sh:164-166`, FP-050) is the same under both. **Inside a loop, refusing loses the kernel network denial and gains no filesystem protection.** After the release, the unconfined run still has Claude Code's Bash sandbox around it. That sandbox's write limits and network allowlist apply either way, and the allowlist admits the project's egress hosts (`research-2026-11-07-confine-tests-situation.md:115-117`). What it buys is H2's rule that a degraded primitive refuses and names the gap, so that a "confined pass" never means less than it says.

Outside a loop, such as a CI job or a host run gating on the script's exit status, the trade differs. There a refusal stops the job, and the person has to choose. Nothing like that exists today: there is no CI (`research-2026-11-07-confine-tests-situation.md:56`), and nothing in code calls the script (`research-2026-11-10-confine-tests-bats.md:22`).

### Where the data is thin

- Frequency: 7 runs, all in one environment (rows 1 and 2), where the question cannot arise. **Not enough data yet** on how often `bwrap` is missing where the fallback could run.
- Rows 4 and 5 have no runs at all. Row 4 waits on the release, which waits on Q-277.
- The run count comes from what loops chose to report. A loop that ran `--probe` and did not write it down is not counted.
- **Every full `scripts/run-tests.sh` run calls the real script, unrecorded.** `test/scripts/confine-tests.bats:228-245` runs `--probe` on the machine's own PATH. The test passes on exit 0 (either primitive) and on exit 3, and a fallback probe prints no warning. So the health check and every loop's test run already probe the script, and nothing records which verdict they got. If a fallback had happened there, no record would show it. Since 2026-11-10, every brief that runs tests asks for the probe line, so later counts should be complete.

## 3. How the warnings could be tracked from now on (options only; none built)

| Option | What it is | Cost |
|---|---|---|
| T1. Quote the probe's verdict line every time | Change the cycle's brief wording from "exit 3: quote its first line" to "quote its output line, whatever the exit". With `ip` installed, a fallback probe prints `confine-tests: primitive available: unshare (loopback=1)` and exits 0 (`scripts/confine-tests.sh:197`; without `ip` it exits 3 at `:190-193`). So today's wording records nothing on a fallback | Brief prose the cycle owns; no code. Depends on loops following prose (S4 ranks it below a script) |
| T2. A digest count | `scripts/dev-cycle.sh`'s digest greps research docs and cycle records added since the last iteration for `primitive available: (bwrap\|unshare)`, `falling back to the unshare primitive` and `NO CONFINEMENT`, and prints one count line | A small change to a gate-code script, so it needs a review merge, not self-merge; it counts only what loops quote, so it needs T1 |
| T3. The cycle probes once per iteration | The cycle runs `scripts/confine-tests.sh --probe` in its step 3 (the watches) and writes the verdict next to watches Q-276 and Q-161 (Q-161 brings test confinement back once the sandbox lands) | One probe a second per iteration; touches the dev-cycle skill, an instruction file. Measures the session environment only, not where loops' runs went |
| T4. The script appends to a log | On a fallback, the script appends a line to a gitignored file, such as `.bats/confine-tests.log` | Changes an enforcement file (needs `Live-verified:`). Each worktree has its own copy, so the cycle cannot read one total. Leaves a file behind |
| T5. One planned probe, no tracking | Rely on the release's first in-session `--probe` run, already planned (`docs/roadmap.md:67`, `:195-196`), plus a run of one bats suite to catch the probe-passes-run-fails case | None new. A single data point for row 4, which is the case that matters; nothing for row 5 |

T1 plus T5 costs least and answers the session case. T2 is worth it only if the fallback starts to happen.

## 4. Design choices in this unit

- No build choice here: the doc is the deliverable, and the brief forbids building a tracking option.
- The run count: count a run once even when a brief and a cycle record both report it. Counted otherwise, the total would double without adding information.
- Q-272 is the owner's choice; section 5 gives a recommendation and its tiebreaker, as the brief asks.

## 5. The question to return (Q-272, updated with the data)

When the test-confinement script cannot use `bwrap`, should it still run the tests under `unshare` (network denied, nothing else), or refuse?

The data so far: 7 runs on record, all in today's image, where neither tool works. All 7 refused with exit 3. The fallback has never run, and no warning has ever printed. A refusal would have stopped 0 more runs. The case where the choice matters is a session after the release, where `bwrap` is installed but nested inside Claude Code's own sandbox. Nobody has tried that yet. Inside a loop, a refusal sends the tests to an unconfined run plus the lint, so it gives up the network denial and gains nothing on the filesystem.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Run and warn** (now) | As merged. `unshare` is a stated exception to H2 (the fail-closed rule in `docs/constraints.md`), written down by you | A line in the constraints file | A fallback pass reads as "confined" to anyone who misses the warning; 0 such runs so far |
| **[2] Refuse unless asked** | Without `bwrap` the script exits 3, unless a new flag asks for `unshare`; the cycle's brief wording passes the flag, so loops keep the network denial | One build loop, self-merged | A host or CI run without `bwrap` stops until someone passes the flag; 0 runs would have stopped so far |
| **[3] Always refuse** | Without `bwrap` the script exits 3; `unshare` only behind `--no-loopback` | One build loop, self-merged | Loops that meet the fallback run with no network denial at all, as on every exit 3 today |

**Recommendation: [2].** Tentative pick for the cycle to file; the tiebreaker is H2 as written. It meets H2 without an exception. With the brief wording passing the flag, a loop keeps `unshare`'s network denial, which [3] throws away. The friction is measured at zero, and it would only show where `bwrap` fails and `unshare` works, which has not happened. If you would rather wait for data, keep [1] until the release's first in-session `--probe` (T5 above) shows what a session gets. If that probe shows `bwrap` works nested, the question is mostly moot for sessions, and [2] stays a one-loop change.
