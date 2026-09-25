# Code Review Rubric

Commit: b4fd792

**Scope:** `ans/copy-install` `9ae6e46..b4fd792` (the Q-058 restart: 8 commits). Limited to `devcontainer-config/install.sh`, `test/install-host.bats`, `test/cc-isolated-functions.bats`, `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `guides/bare-host-hook-wiring.md`, `docs/working/plan-copy-install-bare-host.md`, plus the commit messages. Partial scope; the branch's earlier commits are context only. At `skill-fixtures` HEAD these files are identical to b4fd792, except a one-line shellcheck fix to `install-host.bats` (423b51c). | **Reviewed:** 2026-09-24/25 | **Status: 🔴 DOES NOT PASS** — 3 red item(s) unresolved (pass 2; see the pass-2 section at the end)

Delivery mode: self-read. Agents read the 36 KB diff file and the b4fd792 worktree, and read their skill files themselves instead of having them pasted, because sub-agents here have file access. Replication: k=3 fact-check (opus), plus 3 core critics (opus). Prior rubric: `code-review-rubric-2026-09-23-ans-copy-install-final.md` (R1 and R2 parked).

**Prior reds:**
- **R2 (perl fail-open): resolved.** Fact-check Claims 5, 9, 21, 40 are executed; the security and API critics concur.
- **R1 (review/install divergence): not resolved.** It is carried forward as R2 below, now executed on the host target, and as A1 on the devcontainer target.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | **The checkout's `.git/config` and `.git/info/attributes` run commands as the host user on every install.** `git archive` runs a planted `filter.*.smudge`, and `git status` runs a planted `core.fsmonitor`. A cc-isolated container writes `.git` through its bind mount (037:64 says so), so an agent inside the isolated container can plant a command that the user's unsandboxed shell runs at the next install. That is a container-to-host escape, and the Q-058 gate can't see it because it is persistent state. The acceptance at 037:74 ("any git command the user runs has the same exposure") understates it: install.sh is the one git-running program the bare host is *required* to run, and 66891a7 recorded that acceptance autonomously. Evidence: `git -C "$REPO_ROOT" -c tar.umask=022 archive --format=tar "$commit" -- "$@"` (:162) and `git -C "$REPO_ROOT" -c core.quotePath=true status --porcelain …` (:225). **Fix:** add `-c core.fsmonitor=false` to both `status` calls. Before any git call, refuse when `git config --local --get-regexp '^(filter\.\|core\.fsmonitor\|include)'` prints anything, or when `.git/info/attributes` is non-empty, naming the entry. Rewrite 037:74. (This repo's own `.git/config` has none of these, and it has no attributes file, so the refusal doesn't block a normal install.) Was A3 (🟡) in the prior rubric; now executed (SP3) with the container path named. | Security | High (executed, SP3, git 2.39.5) | security-reviewer F4; fact-check Claim 29 (Mostly accurate) | `devcontainer-config/install.sh:162`, `:225-226`; `docs/decisions/037-bare-host-copy-install.md:74` | for-author | — | 🔴 Partly fixed (24ce814); reopened by pass 2 as P2-R1 |
| R2 | **Host target: a swap-and-revert during the review installs content the review never showed** (the host half of the prior R1). The stage is hashed *before* the review reads it (`reviewed_hash="$(payload_hash "$stage" "" "$stage/.manifest")"`, :589). The review reads the stage again (:670), and the check after y compares against that pre-review hash (:729). A writer that swaps in a benign copy for the review and restores the original before y passes every check. SP1 did this 6 times out of 6 with pgrep and docker reporting nothing running: the review showed only a benign guide change, and `~/.claude/hooks/h.sh` was installed with `MALICIOUS-PAYLOAD`. The only barrier left is the premise that no writer runs between the startup gate (:947) and the host gate (:695), and the gate samples that premise without enforcing it (A2). 037:66 claims "The hash check (R2) catches a stage edited while the prompt waits", which is false for this case (the doc half). Reach depends on who can write `/tmp/cw-*` on the bare host (see Coverage). **Resolution is Q-061:** [1] the structural fix: copy into `$dest/.cw-new.*`, behind `denyWrite ~/.claude`, *before* the review, review those copies, then hash-check and swap them (about 15 lines; the host target then stops depending on the gate). Or [2] correct 037:66 and accept the residual under Q-058 [2]. | Security | High (executed 6/6, SP1) | security-reviewer F1; fact-check Claim 23 (037:66), E2 | `devcontainer-config/install.sh:589`, `:670`, `:729`; `docs/decisions/037-bare-host-copy-install.md:66` | for-author | — | ✅ Fixed (6ec64c3; SP1 re-run: review shows the payload that is installed). Q-061 [1] interim |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | **Devcontainer target: nothing checks that what is installed and blessed is what was reviewed.** It has the y-gate (`agent_gate "Nothing was installed. (devcontainer config)"`, :391) and nothing else. The copy loop (:399-402) is followed by `--bless` (:410), which certifies whatever is in `$DEST`. Probe P3 edited the stage while the prompt waited, with no agent at y, and the edit was installed and blessed. The payload is the sandbox boundary (firewall, egress lists, the host-run `cc-isolated.sh`). Medium, because a writer that can reach `~/.config/claude-devcontainer` can already edit it and re-bless without the installer, and that directory isn't in the documented denyWrite list. **Fix:** hash the PAYLOAD before the review (:367) and re-check `$DEST` after the copy, before `--bless`. State in 037 that target 1 relies on the gate alone. The staging part of the fix follows Q-061. | Security | Medium (executed, P3) | security-reviewer F2; fact-check E2 (r1+r2) | for-author | — | 🟡 Open | — |
| A2 | **The gate samples three moments and recognizes only Claude-shaped command lines.** `CLAUDE_PROC_RE='(^\|/)claude(\.exe)?( \|$)\|/@anthropic-ai/claude-code/'` (:834) misses the versioned native path (`…/share/claude/versions/<ver>`), the Agent SDK `…/claude-agent-sdk/cli.js`, and `node cli.js` (SP2, run against the real pgrep). There is no gate before `assemble` in `install_claude_home` (:583-585), so an agent visible only during the devcontainer prompt lets the host target stage and review while it runs (P4). Same-uid helpers that aren't Claude, and loop drivers, are never seen. 037:75's residual list names none of this, and it misdescribes the regex as "does not end in `claude`". **Fix (all fail-closed):** add one `agent_gate` call at the top of `install_claude_home`, widen the regex with `/claude/versions/` and `/claude-agent-sdk/`, and list residuals (i)–(iii) in 037. Whether a detached helper counts as "an agent" is part of Q-061. | Security | Medium (executed, SP2 + P4) | security-reviewer F3; fact-check E1 (r1+r2+r3), Claims 25, 30; perf escalation (the slow docker probe widens the gap after pgrep) | for-author | — | 🟡 Open | — |
| A3 | **037:73's reason for accepting the TAB/newline residuals is false.** It says "Both need a crafted name, which needs an agent, which the gate refuses", but the gate sees only running processes, so a name planted earlier persists. P5 planted a TAB-named backup dir, every gate passed, and the prune deleted a real backup that should have been kept (the `cut -f2` split, :796-807). **Fix:** `case "$d" in *$'\n'*\|*$'\t'*) continue ;; esac` at :801, and restate 037:73 (the real reason the risk is low is denyWrite on `~/.claude`). | Correctness / Docs | Incorrect (high), 3/3 replicates; doc claim over a live mechanism | fact-check Claim 27 (E3); security-reviewer F5 | for-author | — | 🟡 Open | — |
| A4 | **The docs still describe an in-session run that no longer happens.** `--help` (:60-63), README:28-31 and 037:31-34 say a run inside a Claude Code session installs target 1 and skips target 2 "with no effect on the exit status". The startup gate (:947) now finds the session itself and exits 1, as Q-058 [2] intends. 037:33's "unchanged apart from two extra lines" is stale. | API / Docs | Inconsistent | api-consistency F1 | for-author | — | 🟡 Open | — |
| A5 | **Doc accuracy cluster (all Mostly accurate, fix the text):** "one NOTE line" is actually once per gate call, 2–3 per run (`--help`, 037:70, api F3; Claims 4, 19, 26). The guide's (17-20) "refuses to stage … while either runs" is broader than the code (api F5; Claim 35). plan:244's false-positive wording is too narrow (Claim 32). `DOCKER_HOST`/`DOCKER_CONTEXT` are undocumented inputs that can point the container probe at an empty daemon (api F6; Claim 41). 037:64 "whatever uid it runs as" should say mapped-uid or root (Claim 22). | Docs | Mostly accurate ×6; Minor | fact-check; api-consistency F3, F5, F6 | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Each `agent_gate` runs `timeout 20 docker ps` with no progress line first (:859-868). On a host where docker hangs, that is ~60 s of silent waiting per interactive run, some of it between y and the writes. Print a line before the probe, and consider a ~5 s timeout once `docker ps` has been timed on the host (see `you: terminal` in Coverage). | performance-reviewer 1 | Low | for-author | — | 🟢 Open |
| C2 | The T50–T64 tests add ~20 s to the two suites. ~6.8 s of that is `path_without` (`test/install-host.bats:382-396`), which symlinks all ~2,000 PATH executables in each of T52, T53 and T57. Build it once per file, or link only the tools the installer needs. | performance-reviewer 3 | Low | for-author | — | 🟢 Open |
| C3 | A `vis` failure outside `review_diff` (the host REPLACE/MOVE/ADD lines, the gate's own messages, the claude-home symlink error) exits 1 through `set -e` with no message, unlike every other refusal. It still fails closed. An ERR trap printing "Nothing was installed" would unify it. (The commit-note half is logged as Accepted-immutable in the override log.) | api-consistency F2; security F7; fact-check Claim 10b | Minor | for-author | — | 🟢 Open |
| C4 | The "docker is unreachable (…)" NOTE mislabels a timeout (an empty `()`), shows a locale warning in place of the error, and gives a missing `timeout` the same wording. `timeout` isn't in the Needs line. | api-consistency F4 | Minor | for-author | — | 🟢 Open |
| C5 | A docker failure or timeout counts as "no cc-isolated container". Low marginal risk, since containers can't reach the /tmp stage; their route to the host is R1. | security-reviewer F6 | Informational | for-author | — | 🟢 Open |
| C6 | `timeout 20` may not bound `$(…)` if a docker child keeps the pipe open (not run; pending execution verification). | performance-reviewer 2 | Informational | for-author | — | 🟢 Open |
| C7 | Mixed refusal trailers ("Nothing was staged or installed." vs "Nothing was installed."). A gate refusal shares exit 1 with a decline. perl and pgrep are named only in `--help`. | api-consistency F7–F9 | Informational | for-author | — | 🟢 Open |
| C8 | Rejected hardening, recorded so it isn't re-proposed: a re-hash right before the swap adds nothing, since anyone who can write `$dest/.cw-new.*` can write `$dest`. | security-reviewer F8 | Informational | for-orchestrator-synthesis | — | 🟢 Won't-Fix |
| C9 | The NUL scan reads the claude-home payload three times per run (~6 MB); negligible. | performance-reviewer 4 | Informational | for-orchestrator-synthesis | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff. The nearest row, 2026-09-21 `answers-2026-09-20` A7 (`~/.claude/scripts/` linking), concerns a different change (aa9a5a0). This run appended one `Accepted-immutable` row, for the fa69656 commit note (fact-check Claims 10a/10b).

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Prior R2 closed: a missing perl is refused at startup, before the gate or any staging | ✅ Confirmed | Claim 21 (executed, T57): "main refuses at startup when `command -v perl` fails, before the gate or any staging" | fact-check (k=3) | for-orchestrator-synthesis |
| A vis failure inside `review_diff` aborts before the prompt; T58 fails on the pre-fix code | ✅ Confirmed | Claims 9 and 40 (executed): "T58, which reached the prompt with an empty review before this fix" | fact-check | for-orchestrator-synthesis |
| The gate runs at startup (:947), after the devcontainer y (:391) and after the host y (:695), with no writes between a y and its gate | ✅ Confirmed | Claim 13 (executed) | fact-check (3/3) | for-orchestrator-synthesis |
| Payload files holding a NUL are refused on both targets, and the review diffs as text | ✅ Confirmed | Claims 6 and 7 (executed, T61/T62) | fact-check | for-orchestrator-synthesis |
| docker stderr no longer counts as a container; T64 fails on 66891a7 | ✅ Confirmed | Claims 20 and 46 (executed) | fact-check | for-orchestrator-synthesis |
| A symlink at or above claude-home is refused and named | ✅ Confirmed (scope: the -L walk runs once before `git archive`. Claim 12 is Mostly accurate: directories above claude-home are followed after that check) | Claims 11 and 42 (executed, T59/T60) | fact-check | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved. The orchestrator spot-checked R1's and R2's quoted lines against the b4fd792 worktree (:162, :225-226, :589, :729, :801, :834).

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. No contextual critics were auto-selected: tests changed alongside the source, the diff is 7 files and 458 lines (below 10 files and 500 lines), there's no dependency manifest or UI code, and no module-structure change.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `install.sh:585-589`, `:729`; `037:66` | security F1, F8; fact-check Claim 23 | distinct defects: F1 states the mechanism and both fixes completely; F8 is a rejected alternative |
| 2 | `install.sh:834-886` (gate) | security F3, F6; api F3, F4, F6; perf 1, 2; fact-check Claims 17, 25, 41 | distinct defects: each states its own mechanism (regex coverage, docker fail-open, NOTE wording, timeout). Perf's pgrep-before-docker ordering is carried in A2 as convergence, not a new root |
| 3 | `install.sh:600-654` (vis sites) | fact-check Claim 10b; api F2; security F7 | distinct defects: the same silent-exit behavior, stated completely by each → C3 |
| 4 | `install.sh:796-807`; `037:73` | fact-check Claim 27; security F5 | distinct defects: F5 already states the mechanism and the one-line fix → A3 |

---

To pass review, every 🔴 item must be resolved. Every 🟡 item must be fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

---

# Pass 2: fix commits `c7c4e34..feba07d` (Commit: feba07d)

**Reports:**
- Fact-check, k=1 (a decision-031 loop pass): `code-fact-check-report.md`. 43 claims: 37 Verified, 4 Incorrect.
- Critics: `security-review-2026-09-25-copy-install-q058-pass2.md`, `api-consistency-review-2026-09-25-copy-install-q058-pass2.md`, `performance-review-2026-09-25-copy-install-q058-pass2.md`. They ran in parallel with the fact-check, so their reports carry the no-fact-check warning.

**Pass-1 items after the fixes:**
- R1 is partly fixed and reopened here as P2-R1. R2 is fixed.
- A1–A5 are fixed, except the doc drift re-raised in P2-A3.
- C1–C3 are fixed; C2 only partly (see P2-C2).

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| P2-R1 | **R1 incomplete: `git status` still runs commands the checkout controls.** A planted `.git/hooks/post-index-change` runs when status refreshes the index (SP3b 6/6; fact-check case A). So does a hook under a `core.hooksPath` dir, which isn't in the refused list (SP3c; fact-check case B), and a submodule git dir's clean filter and hook (SP3d). The install then blesses. **Fix, tested by the critic:** add `--no-optional-locks -c core.hooksPath=/dev/null … --ignore-submodules=all` to both status calls, and correct 037:78 to name hooks and submodule git dirs. | Security | High (executed; 2 sources) | security-reviewer N1; fact-check Claims 6, 26 (Incorrect) | `install.sh:171-211`, `:304-305`; `037:78` | for-author | — | 🔴 Unresolved |
| P2-R2 | **A symlink planted in the stage after `extract_commit`'s link check gets installed as a live link.** `tree_hash` records links but never refuses them. On the host target, an installed hook becomes a link to an agent-writable file, a lasting bypass of the destination's denyWrite (SP1d 12/12). On the devcontainer target, a `cc-isolated.sh` link passes both A1 hashes and is blessed (SP1e 12/12). **Fix:** refuse links at every hash site, or make `tree_hash` fail on a link. | Security | High (executed) | security-reviewer N2 | `install.sh:250`, `:497`, `:581`, `:742` | for-author | — | 🔴 Unresolved |
| P2-R3 | **The old side of the host review (`$HOST_TMP/installed`) sits in `$TMPDIR`.** Rewriting it to match the new copy hides the malicious change from the review, and the hash check still passes (SP1b 6/6). **Fix, together with P2-A1:** take the lock first, then extract the host stage and build the old-side view under `$dest` (`mktemp -d "$dest/.cw-stage.XXXXXX"`), so the host target no longer depends on `$TMPDIR`. | Security | High (executed) | security-reviewer N3 | `install.sh:807`, `:826`, `:837` | for-author | — | 🔴 Unresolved |

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| P2-A1 | A stage edit between `git archive` and the copy into `$dest` gets installed. On a first-install entry over 200 lines, the review shows only file names plus "it is skills at commit X", which is then false (SP1c 6/6). P2-R3's move fixes it. | Security | Medium (executed) | security-reviewer N4 | for-author | — | 🟡 Open | — |
| P2-A2 | A1 fails open on its error path. If a later `cp` in the devcontainer loop fails, `set -e` exits before the post-copy check, and an altered `cc-isolated.sh` stays live. Route a cp failure through the mismatch removal path. | Security | Medium (simulated with a cp stub) | security-reviewer N5 | for-author | — | 🟡 Open | — |
| P2-A3 | Doc and comment drift:<br>• 037:74's NOTE count says "two or three"; runs measured 1–4.<br>• The comment at install.sh:133-134 says review_diff re-shows MODE lines; it doesn't.<br>• 037:67's "under ~/.claude" holds only for the default destination.<br>• plan:139 still says the lock is "taken after y".<br>• 037's process-shape revisit trigger predates the A2 widening.<br>• 037:33 and plan:252 don't count the new progress line. | Docs | Incorrect (doc) ×2; Mostly accurate; Minor | fact-check Claims 5b, 24a, 21; api F1, F4, F8 | for-author | — | 🟡 Open | — |
| P2-A4 | The new git-state refusal isn't in `--help` or README, and it blocks both targets. Its remedy, `git config --local --unset <key>`, exits 5 for `config.worktree` keys (which need `--worktree`) and for a multi-valued `include.path` (which needs `--unset-all`). It doesn't warn that removing `filter.lfs.*` breaks LFS. Suggested remedy: `git config --file <named file> --unset-all <key>`. | API | Minor (the suggested command fails) | api-consistency F2 | for-author | — | 🟡 Open | — |
| P2-A5 | An unwritable destination is now refused before the review even when nothing would change: exit 1 where the old run printed "Nothing to install" and exited 0. The docs don't mention it. | API | Minor | api-consistency F3 | for-author | — | 🟡 Open | — |

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| P2-C1 | A 4th docker probe means a hung docker costs ~80 s per y/y run. The gate after the devcontainer y and the host pre-stage gate run seconds apart, so the second could reuse the first's result. | performance 1 | Low | for-author | — | 🟢 Open |
| P2-C2 | `path_without` still costs ~1.2 s per call under bats. Use a single `ln -s "$dir"/* "$farm/"`, or build the farm in `setup_file`. | performance 2 | Low | for-author | — | 🟢 Open |
| P2-C3 | T65–T74 add 18.3 s, ~10.5 s of it fixed sleeps. T72 waits out its full sleep, and T67's 1.5 s/2 s windows may flake under load. | performance 3 | Low | for-author | — | 🟢 Open |
| P2-C4 | The lock and ~1.9 MB of copies now persist through the review. A SIGKILL leaves a stale lock that has to be removed by hand. | performance 4 | Informational | for-author | — | 🟢 Open |
| P2-C5 | Four smaller API points:<br>• The "Nothing was installed." trailer is wrong after target 1 has installed (`vis_or_die`, `git_state_gate`); this widens C7.<br>• Declining a nested first install leaves parent dirs behind.<br>• `review_diff`'s prefix argument has a different form from `tree_hash`'s.<br>• After an A1 mismatch, the message doesn't say the previous config is gone. | api F5–F7, F9 | Informational | for-author | — | 🟢 Open |

## ↩️ Considered Overrides (pass 2)

No prior overrides matched. The pass-1 Accepted-immutable row (fa69656) doesn't apply to these commits.

## 🧩 Composition check (pass 2)

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `install.sh:171-211`, `:304-305`; 037:78 | security N1; fact-check Claims 6, 26 | distinct defects: both sources state the same defect completely → P2-R1 |
| 2 | `install.sh:742`, `:807-837` | security N2, N3, N4 | shared fix, not a new row: the host target still reads three inputs from `$TMPDIR` (the stage, links inside it, the old-side view). Staging all of it under `$dest` closes all three. N3's recommendation already states that joint fix |
| 3 | `install.sh:495-509` | security N5 | single source |
