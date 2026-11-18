### Q-278 · q272-returned-run-or-refuse
**Needs:** you: judgment · **Opened:** 2026-11-11 · **Status:** OPEN

You asked for Q-272 back with data. When the test-confinement script (`scripts/confine-tests.sh`) cannot use `bwrap`, should it still run tests under its weaker tool, `unshare`, or refuse?

**If you say no:** your Q-272 answer stands, [1] "to start": the script runs under `unshare` after a warning. That is a provisional exception to hard constraint H2 (a degraded tool refuses and names what went unenforced), not written into `docs/constraints.md`.

**The data** (a build loop gathered it from the repo's records; nothing was run on the host):

- **How often `bwrap` is missing.** Not enough data yet. In this sandbox, and in the image sessions run today (536b7082), neither tool works: `bwrap` is not installed, and Docker's default seccomp refuses user namespaces, so `--probe` exits 3 here. The image after the release (Q-273, on hold for Q-277) installs `bwrap`. But in a session, that `bwrap` would run inside Claude Code's own sandbox, and nobody has tried that yet. Your host is not on record.
- **How much friction a refusal would cause.** None so far. 7 build loops ran the script (2026-11-05 to 2026-11-11), plus their reviewers. Every run exited 3 because neither tool worked, so the `unshare` fallback has never run and its warning has never printed. A refusal would have stopped 0 more runs. On exit 3 a loop already runs `scripts/run-tests.sh` unconfined, plus the hermeticity lint (a static check for tests that could reach the network). That fallback is weaker than `unshare`: it loses the network denial.
- **2026-11-12, one change to the first point.** The release that was to install `bwrap` did not ship it: main rolled the Bash sandbox back (7caea26d, your Q-277 answer [3]), and that revert also took `bwrap` out of the image. Sessions now run the image built from 80b7dabe, which has neither tool working, so the script still exits 3 here and nothing above has changed in practice.
- **One gap.** Every full test run already calls the real `--probe` (`test/scripts/confine-tests.bats:228-245`), and nothing records which tool it found.

- **Why it's yours:** it is an exception to a hard constraint, which only you grant.
- **Read:** `docs/working/research-2026-11-11-confine-tests-fallback-data.md` (merged at b9c8966a; section 3 lists six ways to track the warnings, none built) · Q-272 in `docs/working/questions-archive.md` · decision-log row 87

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Run and warn (as now)** | The fallback stays; the exception to H2 gets written into `docs/constraints.md` | One line in the constraints file | A fallback pass reads as "confined" to anyone who misses the warning; there have been 0 such runs so far |
| **[2] Refuse unless asked** | Without `bwrap` the script exits 3, unless a new flag asks for `unshare`; the briefs' test wording passes that flag | One self-merged build loop | A run without `bwrap` that does not pass the flag stops until someone passes it; 0 runs would have stopped so far |
| **[3] Always refuse** | Without `bwrap` the script exits 3; `unshare` only behind the existing `--no-loopback` flag | One self-merged build loop | Loops that hit the fallback lose the network denial, as every exit 3 does today |

The loop's tentative pick is [2], because it follows H2 as written with no exception and loops keep `unshare`'s network denial, which [3] gives up. If you'd rather wait for data, keep [1] until the first `--probe` inside a session after the release.

- **Blocks:** nothing. The script has no caller that the fallback would change today.
- **Interim:** [1], your Q-272 answer.
- **If the answer differs:** [2] or [3] becomes a brief for one build loop; [1] becomes one line in `docs/constraints.md`, which you commit.
