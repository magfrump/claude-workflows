# Code Fact-Check Report

**Commit:** 190fa1a4
**Replication:** k=3
**Repository:** /workspace/.claude/wt-branch-verify (branch `docs/branch-verify-without-install`)
**Scope:** `docs/working/spike-cc-verify-q117.md` at 190fa1a4, including its embedded script, plus the commit messages of 12fcb61c and 190fa1a4. Review iteration 2, the final confirming pass (decision log 63). Iteration 1's k=1 report (commit 12fcb61c) is in git history at 190fa1a4.
**Checked:** 2026-10-15
**Total claims checked:** 36-37 per replicate (r1 36, r2 36, r3 37), merged into the clusters below
**Summary (merged, most-severe-wins):** 4 Incorrect clusters, 7 Mostly Accurate clusters, all others Verified; 0 Stale, 0 Unverifiable

Merged by the orchestrator, most-severe-wins, from `code-fact-check-report-cc-verify-spike-r1.md`, `-r2.md` and `-r3.md` (all `**Commit:** 190fa1a4`). This is mechanical collation: no claims or evidence were added. The Incorrect and Mostly Accurate clusters are carried as full claims below, with each replicate's verdict. The Verified clusters are listed by r1's numbering; the per-claim evidence is in the replicate reports.

**Deviation from the merge spec:** the Verified clusters are not re-emitted as full `## Claim` sections. Each is listed with r1's verdict, and the stability section records that no replicate gave a contrary verdict on them.

---

## Claim 1: "Task status: paused (paste written; review loop iteration 2 passed; nothing has run on the host)"

**Location:** `docs/working/spike-cc-verify-q117.md:5`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether iteration 2 had passed at 190fa1a4; does not establish this pass's outcome.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "the 190fa1a4 message says iteration 2 'follows'; the only rubric reads DOES NOT PASS (iteration 1)"

**Evidence:** The status line predates the pass it reports. The commit's own message says iteration 2 follows.

## Claim 2: A planted `run-*.env` cannot point `image rm` at an image no verify container ran

**Location:** `docs/working/spike-cc-verify-q117.md:482`; script teardown lines 119-124
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `*verify-<T8>*` tag rule in teardown and `--clean`. The container and volume half of the claim holds (a planted record naming the harness project removed nothing).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1: "records with T8=20261015 and T8=deadbeef removed `vsc-verify-20261015-5f3a:latest` and `other/Project-VERIFY-DEADBEEF-tools:1.0`" · r2: "removed a pre-existing `acme/preverify-deadbeef:1`; impact low, only images whose name contains `verify-<8 hex>`" · r3: "removed `myproj-verify-deadbeef:latest`; `docker image rm -f <id>` also removes every other tag on that id"

**Evidence:** The tag rule is an unanchored substring match, with no new-or-unused guard, and it uses `-f`. A planted record chooses `T8`.

## Claim 3: Commit 190fa1a4, R3/F4: "images come only from this run's containers … cannot steer … image rm"

**Location:** commit 190fa1a4 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same mechanism as Claim 2; the message omits the tag rule.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** none beyond Claim 2

**Evidence:** As in Claim 2.

## Claim 4: "`claude-home` shows under 'differ' whenever main's installed payload predates the merged tree's"

**Location:** `docs/working/spike-cc-verify-q117.md:445`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `.manifest` contents written by the spike and by install.sh.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=— · r3=Incorrect
**Replicate annotations:** r1+r3: "the spike's `.manifest` records a tree id and 'cc-verify spike'; install.sh's a commit id and the checkout path, so `claude-home` differs on every run"

**Evidence:** The two `.manifest` writers can never produce the same bytes.

## Claim 5: `--clean`'s "only if new" image rule

**Location:** script `compare()` (snapshot removal) and teardown
**Type:** Behavioral
**Verdict:** Mostly Accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--clean` after a failed teardown.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "compare() deletes the snapshots even after a failed teardown, so the recommended --clean can remove a pre-existing image a verify container ran (reproduced)"

**Evidence:** "Only if new" holds only while the before-snapshot exists.

## Claim 6: "Every line the launcher or the container prints is shown indented"

**Location:** `docs/working/spike-cc-verify-q117.md:402`
**Type:** Behavioral
**Verdict:** Mostly Accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--register` failure tail, the merge-tree conflict listing and the step-3 diff.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Mostly Accurate · r3=Mostly Accurate
**Replicate annotations:** r1+r2+r3: "these are vis-filtered but not indented"; r2: "the `--register` output is main's launcher's, so the branch cannot forge it"

**Evidence:** Three outputs pass through `vis` but not `relay`.

## Claim 7: The exit-status list (`RESULT spike-q117 exit=<n>`)

**Location:** `docs/working/spike-cc-verify-q117.md:447-451`
**Type:** Behavioral
**Verdict:** Mostly Accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which paths print the RESULT line.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Mostly Accurate · r3=Mostly Accurate
**Replicate annotations:** r1+r2+r3: "preflight refusals (before the trap) and --clean print no RESULT line"

**Evidence:** `on_exit` is registered only after preflight.

## Claim 8: The "Created / Removed by" table

**Location:** `docs/working/spike-cc-verify-q117.md:13-24`
**Type:** Reference
**Verdict:** Mostly Accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the files the script creates under `~/cc-verify`.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly Accurate · r3=Mostly Accurate
**Replicate annotations:** r2+r3: "omits `snap-<RUN>-before/after` and `stage-<T8>.raw`"; r3: "'no tool reads' the log, but the script reads its tail on a register failure"

**Evidence:** The table lists eight entries; the script creates ten.

## Claim 9: The "Not verified" list is complete

**Location:** `docs/working/spike-cc-verify-q117.md:499-508`
**Type:** Reference
**Verdict:** Mostly Accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers host behaviour the stub harness assumes.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Mostly Accurate · r3=Mostly Accurate
**Replicate annotations:** r1: "the devcontainer CLI's own host writes" · r2: "image ls id form = inspect id form; the tag rule's reach; root-owned files in the bind mount can make rm -rf VERIFY fail" · r3: "image rm -f removes every tag; substring tag match; the fake ignores --format for ps; exec as remoteUser node"

**Evidence:** Each replicate named host assumptions that the list leaves out.

## Claim 10: Residual "cc-isolated agents cannot reach ~/cc-verify"

**Location:** `docs/working/spike-cc-verify-q117.md:514`
**Type:** Reference
**Verdict:** Mostly Accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the verify container's bind mount.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly Accurate · r3=— · single-replicate detection
**Replicate annotations:** r2: "the verify container reaches VERIFY-<T8>; 'cannot reach the stage' is accurate"

**Evidence:** The workspace is bind-mounted into the verify container.

## Claim 11: Commit messages 12fcb61c and 190fa1a4, wording

**Location:** commit messages
**Type:** Reference
**Verdict:** Mostly Accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers "before anything else exists" (12fcb61c), "Q-117 fail behaved as documented" and the zsh round trip at 12fcb61c, and A3/A7 in 190fa1a4.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly Accurate · r2=Mostly Accurate · r3=Mostly Accurate
**Replicate annotations:** r1+r2+r3: "the run record and bare clone exist when the merge check runs"; r2+r3: "190fa1a4 A3: --register output not relayed; A7: the bare clone has no fsmonitor=false (harmless, bare), --no-optional-locks is on later calls, not the clones"

**Evidence:** The wording is loose; the behaviour itself is correct.

---

## Verified clusters (r1 numbering; no replicate gave a contrary verdict)

| r1 claim | Subject | r1 verdict | Mode |
|---|---|---|---|
| 2 | Last-verified SHAs, pinned branch | Verified | static |
| 4-5 | runtime checks / by-construction split (no write to ~/.claude or checkout worktree) | Verified | executed |
| 6 | paste is comment-free outside the script; round-trips in bash, zsh -f, zsh -i | Verified | executed |
| 7 | credential unset | Verified | executed |
| 8 | relay strips and indents; verdict parses unindented copy; pipefail kept | Verified | executed |
| 10 | containers and volumes derived from RUN/T8 only | Verified | executed |
| 13-17 | preflight; template-free clones; EXPECT_BR pin; merge-tree refusal; five-path rule | Verified | executed |
| 18 | SIGPIPE fix (old form failed 50/50, 199/200, 200/200 across replicates; new 0) | Verified | executed |
| 19-20 | extract rules and stage layout, current and pre-Q-089 launcher | Verified | executed |
| 21 | Dockerfile + devcontainer.json pins | Verified | executed |
| 22-23 | project id derivation; register writes under the stage | Verified | executed |
| 24 | post-bless manifest check (`<hash>  <path>`, awk `$2 == f` matches) | Verified | executed |
| 25 | launcher executes no staged file, writes only under the stage (tripwires; both launchers) | Verified | executed |
| 26-28 | exec vars and args; Q-117 block verbatim (2463-2475); verdict ordering | Verified | executed |
| 29, 31-33, 35, 36b | expected output; exit codes incl. 130; tested-section results; crash + --clean; upload-pack note; the rest of the 190fa1a4 fix list | Verified (31 Mostly Accurate, merged into Claim 7) | executed |

Every file:line citation in the doc's step table landed, in all three replicates.

## Escalations

- Claim 2 (teardown tag rule, script :119-124): replicates r1, r2, r3; addressee security-reviewer. The planted-record image removal, and `rm -f` removing all tags on an id.
- Claim 5 (`--clean` without a snapshot): replicate r1; addressee security-reviewer.

## Verdict stability

Clusters: about 37. Six of the 11 attention clusters were unanimous in verdict class (Claims 1, 2, 3, 6, 7, 9 and 11). Disagreements:
- Claim 4: r1=Mostly Accurate, r3=Incorrect, r2 did not surface it.
- Claim 8: r1=Verified, r2/r3=Mostly Accurate.
- Claims 5 and 10: each raised by a single replicate.

No Verified cluster drew a contrary verdict. Agreement rate across reporting replicates: 33/37 ≈ 89%.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to the path named at the end of this prompt, structured per the code-fact-check skill, with a `**Commit:** 190fa1a4` line at the top.
- Answered: yes (merged from three replicates that each answered yes)
- Out of scope: host behaviour (no docker or devcontainer CLI in the sandbox)
- Escalate: Claims 2 and 5 to security-reviewer (above)
