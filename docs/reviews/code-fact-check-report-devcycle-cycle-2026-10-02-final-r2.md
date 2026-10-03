Commit: daf5bd82

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** full branch, `git diff main...HEAD` on chore/dev-cycle-2026-10-02 at daf5bd82 (docs only: cycle record, roadmap, questions, idea log, 3 build briefs, the pass 1–3 rubric and reports). Final confirming pass, replicate r2 of k=3.
**Commit:** daf5bd82
**Replication:** k=3 final confirming pass (decision log row 63), this report is replicate r2
**Checked:** 2026-10-02
**Total claims checked:** 24
**Summary:** 22 verified, 1 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Tag: Legibility-target. This applies to every claim below. The diff holds docs only, so every claim is a count, hash, line number, categorization or source statement in a doc.

Execution provenance. Every command ran under `timeout`, with cwd `/workspace` unless noted, on 2026-10-02/03 UTC. The timestamps are in `ts-*` files. Output was captured in the job scratch directory `/home/node/.claude/jobs/db6d1182/tmp/fc-EDCgm3/`, not `docs/reviews/execution-logs/`, because this pass may write only this report. That directory is ephemeral. Commands and exit codes:
- `timeout 300 scripts/dev-cycle.sh` exited 0. Output: `digest.md`.
- `timeout 300 scripts/dev-cycle.sh --since=2026-09-18` exited 0. Output: `digest-0918.md`. This re-creates the record's window on main at 188e0a7d.
- `scripts/dev-cycle.sh --check-branch …` and `--check-brief …` each exited 0. Output: `branch.out`, `brief.out`.
- In a scratch clone (`git clone --no-hardlinks /workspace clone; git checkout -B main daf5bd82`), `--check-brief` ran for each brief and exited 0. Output: `checkbrief-clone.log`.
- `HEALTH_CHECK_SKIP_BATS=1 LC_ALL=C.UTF-8 timeout 400 scripts/health-check.sh` exited 0. Output: `hc.log`.
- `RUN_TESTS_NOT_RUN_FILE=$S/nr LC_ALL=C.UTF-8 timeout 120 bats -f 'a stamp or .failed marker alone is not a report' test/skills/eval-helpers-gating.bats` exited 0. `nr` was seeded with 50. Output: `q110.log`, plus the `nr` file.
- `LC_ALL=C.UTF-8 timeout 500 bats test/cc-push.bats test/cc-isolated-functions.bats` exited 0. Output: `bats-cutf8.log`. The same command under the ambient `LC_ALL=en_US.UTF-8` exited 1. Output: `bats-bare.log`.
- `timeout 60 scripts/questions.sh check` exited 0. Output: `qcheck.log`.
- `LC_ALL=C.UTF-8 timeout 120 bats -f 'install.sh is gated although' test/hooks/live-verify-gate.bats` exited 0. Its output was read inline, not captured: a PreToolUse hook refused redirecting it into the scratch path.
- `git status` was clean afterwards, apart from the pre-existing untracked `devcontainer-config/` placeholders. Q-109's paste block was not run.

Hallucination-pattern log read: none of its 8 entries matches a claim here. The closest is the "claimed test count vs actual" shape, and every count below re-derived.

---

## Claim 1: Window line and the window counts: "48 skill/workflow files changed", "16 decision records changed", "Merges with code but no docs (17)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:2`, `:43`, `:52-55`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three counts for the digest re-run with `--since=2026-09-18` on main at 188e0a7d, and the Window line's wording against the script's `source_note`. It does not establish that the original digest run printed byte-identical output, since that run was not captured in the repo.

The re-run digest (`digest-0918.md`) prints "`- Skill or workflow files changed on \`main\` in the window: 48`" and "`- Decision records added or changed on \`main\` in the window …: 16`". Its section 6 holds 17 `- <hash>` lines, including "`- fc3bff82 2026-09-18 Merge branch 'si4/devc' (5 file(s), no doc change)`". The Window line's reason text matches the script exactly: `scripts/dev-cycle.sh:646` reads `source_note="no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)"`. A full walk that also counts second-parent files gives 49. The `--first-parent --diff-merges=first-parent` filter at `scripts/dev-cycle.sh:821` gives the record's 48 (paraphrased, no quote available because the comparison is two `git log` runs, saved as `win.txt`/`win2.txt`).

**Evidence:** `scripts/dev-cycle.sh:646,821-824`, scratch `digest-0918.md`, `win2.txt`

---

## Claim 2: "8 router skills plus `skills/dev-cycle/SKILL.md` were added in the window"; 037 "created in the window at 29cdd160"; 031 and 037 the major ones; "e.g. 035's status note, 020's amendment, 021's superseded note"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:52-57`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the router count in 4225753a, 037's creation commit and the three example categorizations. Whether 031 and 037 are the only "major" decisions is a judgment and is not checked.

`git diff --name-status 4225753a^1 4225753a` lists `A` for exactly 8 `skills/*/SKILL.md` files: branch-strategy, codebase-onboarding, parallel-worktrees, pr-prep, research-plan-implement, spike, task-decomposition and user-testing-workflow. divergent-design is `M`. `git log --diff-filter=A -- docs/decisions/037-*` gives `29cdd160 2026-09-23`. 020 contains "amend" twice and "supersed" zero times. 021 contains "supersed" once. 035 has status lines (paraphrased, no quote available because these are grep counts over three files).

**Evidence:** `git show 4225753a`, `docs/decisions/037-bare-host-copy-install.md`, `docs/decisions/020-*.md`, `docs/decisions/021-*.md`

---

## Claim 3: Health check, "7/7 freshness-tracked docs stale (check 11); 10 skills without fixtures (check 9); 50 report-dependent BATS suites not run … the health-check summary line says 4"; `dev-cycle` missing from AGENTS.md/GEMINI.md "from 90364c73"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:11-15`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers checks 9, 11 and the divergence check on this tree, plus the count of 50 `@needs-reports` suites. The "4" in the summary line is checked by mechanism in Claim 13, not by re-running the full suite.

`hc.log` prints "`Coverage: 24/34 skills have test fixtures (10 without)`" and "`Freshness: 7 checked, 0 fresh, 7 stale, 0 missing fields`". The worst entry is "`code-review-evaluation-state.md: STALE — 67 commit(s)`", which matches the idea log's "one by 67 commits". It also prints "`⚠ Skills referenced in global-instructions/CLAUDE.md but not AGENTS.md: dev-cycle`" and the same line for GEMINI.md. `rg -l '^# @needs-reports' test | wc -l` gives 50. `git diff 90364c73^1 90364c73 -- global-instructions/CLAUDE.md` adds the row "`| 12 | **Maintenance or planning pass over the repo**, … "run the dev cycle"`".

**Evidence:** scratch `hc.log`, `scripts/run-tests.sh:356-357`, `global-instructions/CLAUDE.md`

---

## Claim 4: Merged branches "(0 commits beyond main)" and the unmerged branches "feat/wiring-allowlist (6 ahead), feat/wiring-allowlist-b (7 ahead)"; "worktrees: only /workspace"; "nothing to archive (0 answered entries)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:16-21`; `docs/working/questions.md` Q-109
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch ahead-counts at daf5bd82 time, the worktree list and the count of ANSWERED entries. Whether `branch -d` would succeed was not run (Q-109 must not be run).

`git rev-list --count main..<b>` gives 0 for each of the four Q-109 branches, 6 for feat/wiring-allowlist and 7 for feat/wiring-allowlist-b. `git worktree list` shows only `/workspace`. `grep -c 'Status:\*\* ANSWERED' docs/working/questions.md` gives 0 (paraphrased, no quote available because these are command counts).

**Evidence:** `git rev-list`, `git worktree list`, `docs/working/questions.md`

---

## Claim 5: Q-074, "0 of 5 new failure-pattern entries since it opened (134 fix commits since its opening commit e7aa412d); it reopens … on 2026-10-26"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:31-32`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts with "fix commit" read as a subject starting `fix(` or `fix:`, over `e7aa412d..main`. Other readings of "fix commit" are not covered.

`git log --format=%s e7aa412d..main | grep -cE '^fix(\(|:)'` gives 134. `git diff e7aa412d main -- docs/thoughts/failure-patterns.md` is empty. e7aa412d is "docs(questions): file Q-068..Q-074 …". The Q-074 entry says "`If it reaches 2026-10-26 with fewer than 5 new entries, reopen L1 as a judgment`" (`docs/working/questions.md:198`).

**Evidence:** `docs/working/questions.md:195-198`, `git log e7aa412d..main`

---

## Claim 6: Spot-check, "220/220 with `LC_ALL=C.UTF-8`. Bare `bats` shows 5 false reds … `run-tests.sh` pins the locale"; "`test/cross-reference-integrity.bats` ok"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:37-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both suite runs and the runner's locale pin in this container. It does not establish that the 5 reds are caused only by the locale beyond the fact that they disappear under C.UTF-8.

`bats-cutf8.log` shows `1..220`, 220 `ok`, 0 `not ok`, exit 0. `bats-bare.log` (ambient `LC_ALL=en_US.UTF-8`) shows 5 `not ok` (tests 28, 46, 159, 160, 208), exit 1. `scripts/run-tests.sh:175-180` reads `ambient_locale="${LC_ALL:-${LANG:-}}"` … `export LC_ALL="$pinned"` (excerpt ends :180; the enclosing block :175-181 was read). `bats test/cross-reference-integrity.bats` gives `ok 1`.

**Evidence:** scratch `bats-cutf8.log`, `bats-bare.log`, `scripts/run-tests.sh:79-82,175-180`

---

## Claim 7: fc3bff82 "changed init-firewall's recovery hint, but `guides/cc-isolated-usage.md` (~line 897) still advises the bare `devcontainer up --remove-existing-container`"; "`guides/devcontainer-setup.md:366`"; init-firewall "around line 343"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:44-48`; `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:73-81`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line numbers, the advice they hold, and that the hint arrived through fc3bff82's second parent. It does not cover rewording elsewhere in the guides.

`guides/cc-isolated-usage.md:897`: "`If it cannot bootstrap any more, recreate: \`devcontainer up --remove-existing-container …\`.`" Line 903, below it, says the bare form gives "`base-only`" egress and an empty `/etc/cc-config-hash`. `devcontainer-config/init-firewall.sh:343`: "`# Not a bare \`devcontainer up --remove-existing-container\`: run from a normal`", followed at :349 by "`cc-isolated --probe-only <repo>`". `git blame` attributes :343-349 to 48a8200b (2026-09-18), which is not an ancestor of fc3bff82^1, so the merge brought it in. `guides/devcontainer-setup.md:366`: "`change, \`devcontainer up --remove-existing-container …\` by hand.`" It was blamed to 2d679ce5 (09-09). `rebuild_hint` (c1e5abd7, 09-15) predates fc3bff82, which matches the brief's "predates fc3bff82 (rebuild_hint already warned against it)". `guides/cc-isolated-usage.md:58` describes the launcher's step 5, not hand advice.

**Evidence:** `guides/cc-isolated-usage.md:55-60,897,903`, `devcontainer-config/init-firewall.sh:335-350`, `guides/devcontainer-setup.md:363-373`

---

## Claim 8: "d98cac98 (a 3-file code fix to `scripts/dev-cycle.sh`) landed on main directly after the pass-38 review, with no rubric covering it"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:50-51`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file count, the first-parent position after c8c83211 (pass-38 artifacts), and that no review doc outside this branch names d98cac98. It does not establish that no unnamed review covered the change.

`git show --stat d98cac98` lists `docs/working/known-issues-dev-cycle.md`, `scripts/dev-cycle.sh` and `test/scripts/dev-cycle.bats`, 3 files. In `git log --first-parent main`, d98cac98 directly follows c8c83211 "docs(reviews): pass-38 final k=1 delta on the merged dev-cycle; 1 red". `grep -rl d98cac98 docs/` finds only this branch's record and pass-1 report (paraphrased, no quote available because these are grep and log results).

**Evidence:** `git show d98cac98`, `git log --first-parent main -5`

---

## Claim 9: Fired-trigger evidence, 015 T2: "f906b50f (09-09), 6c35e39d (09-12), 7c970bfe (09-19), all from this repo's own boundary changes"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:81`; Q-105 `docs/working/questions.md`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the dates, that three session-breaking fixes fall within one 2-week window (09-09 to 09-22), and Q-105's one-line description of each. Whether these count as "breakage" is Q-105's open judgment.

The commit bodies say: f906b50f, "`so \`node\` had no DNS and no HTTPS while the boundary reported healthy`"; 6c35e39d, "`cc-isolated refused to start with \`PROBE FAIL (firewall)\``" on "`every HEALTHY container`"; 7c970bfe, "`The filtering resolver refused that name (EAI_AGAIN …)`" for `.frame.claudeusercontent.com`. All three are `fix(cc-isolated)` commits.

**Evidence:** `git log -1 --format=%b f906b50f 6c35e39d 7c970bfe`

---

## Claim 10: Fired-trigger evidence, 036 T3: "037's host target (built 6793b79a, recorded 29cdd160) uses `assemble()` alongside the devcontainer target (install.sh:498, :857)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:138`; Q-107
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two call sites and the commit roles. Whether `assemble()` meets candidate [11]'s seam is Q-107's open task.

`devcontainer-config/install.sh:498`: `assemble "$stage/claude-home" "${dc_paths[@]}"`. `:857`: `assemble "$stage"`. `assemble()` (:329-361, read whole) stages `CLAUDE_HOME_SRC` via `extract_commit "$commit" "$stage" "${CLAUDE_HOME_SRC[@]}"`, and its header says "`the payload is \`git archive HEAD\`, never \`cp -r\` of the tree`" (:326-327). 6793b79a: "feat: install.sh offers the host ~/.claude target on every run". 29cdd160: "docs: … decision 037".

**Evidence:** `devcontainer-config/install.sh:319-361,496-499,855-858`

---

## Claim 11: Fired-trigger evidence, 037 T1 and T3: "Q-049 was answered 2026-09-23 (aa21535d)"; "The regex landed (addae610) and install.sh is covered (`test/hooks/live-verify-gate.bats`); 037's lines 37 and 58 are stale"; Q-106's "install.sh header (line 44)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:143-145`; Q-106, Q-108
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commits, the archive status, the cited lines and the install.sh gating test. It does not cover whether 037's other lines are current.

The Q-049 archive entry is `**Status:** ANSWERED`. Its runs are dated 2026-09-23, and aa21535d (09-23) is "fix(wiring): … (Q-049)". addae610 (09-26) is "fix(hooks): gate install.sh commits on Live-verified, as decision 035 chose". `docs/decisions/037-bare-host-copy-install.md:37` says "`Q-049 is open`", and `:58` says "`035's still-pending regex`". The test at `test/hooks/live-verify-gate.bats:138` "install.sh is gated although it is not manifest-hashed (decision 035)" ran `ok 1`, exit 0 (output read inline, not captured: see provenance). `devcontainer-config/install.sh:44`: "`settings.json is never written; hook wiring stays a manual merge.`"

**Evidence:** `docs/working/questions-archive.md:1165-1172`, `docs/decisions/037-bare-host-copy-install.md:37,58`, `test/hooks/live-verify-gate.bats:138-150`, `devcontainer-config/install.sh:44`

---

## Claim 12: Fired-trigger evidence, log row 62: "396 to 1861 code lines outside `docs/` (de530691 → 5652d33f …) over 37 passes"; Q-104's "run-tests 254 lines, skill-invocation fix 32 lines"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:154`; Q-104
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shortstat against base 4225753a (3aee1385's parent, the unit's base), the pass numbering, and the two sibling sizes, counted as insertions plus deletions. It does not establish that the unit had no rubric before de530691 under another file name.

`git diff --shortstat 4225753a de530691 -- . ':!docs'` gives "`2 files changed, 396 insertions(+)`". At 5652d33f it gives "`2 files changed, 1861 insertions(+)`". 5652d33f is "fix(dev-cycle): pass-37 …". The rubric file was added in de530691 ("digest final-pass-1 artifacts, rubric"). Its "Pass 38" section is "post-merge; on 90364c73". run-tests (4225753a..6ee986d8): 246 insertions + 8 deletions = 254. 188e0a7d: 31 + 1 = 32.

**Evidence:** `git diff --shortstat`, `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md:837-851`

---

## Claim 13: Q-110 cause, "`test/skills/eval-helpers-gating.bats` runs nested `run-tests.sh --fast` calls (lines 76–91 …) that do not override `RUN_TESTS_NOT_RUN_FILE` … overwrites the parent's count (50, written before any suite runs, `scripts/run-tests.sh:356`) with its own 4"

**Location:** `docs/working/questions.md` Q-110
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line-76 test leaking into an inherited NOT_RUN file and the cited line numbers. It does not establish which nested call writes last in a real health-check run, or that no other suite also leaks.

Unoverridden calls are at `test/skills/eval-helpers-gating.bats:76`, `:83` and `:91`: `run bash "$T/scripts/run-tests.sh" --fast`. Lines :50 and :63 do override (`run env RUN_TESTS_NOT_RUN_FILE="$T/nr" …`). `scripts/run-tests.sh:356-357`: `if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"`. The suites are dispatched later, at :360 onward (`bats_args` at :405). Executed: the file was seeded with `50`, the line-76 test was run with it inherited, and the file then read `4` (`q110.log`, exit 0).

**Evidence:** `test/skills/eval-helpers-gating.bats:9-30,50,63,74-92`, `scripts/run-tests.sh:350-360`, scratch `q110.log`, `nr`

---

## Claim 14: Not-fired and cannot-tell evidence spot-checks: 035 T2/T3 "All 3 install.sh commits after addae610 carry `Live-verified: no`" and the Claude trailer; 036 T2 "0 commits"; 014 T2 "`test/fixture-hermeticity.bats` 2/2"; 017 T2 / row 53 "`unshare` EPERM; no bwrap/socat"; row 35 "last changed 2026-09-28 (14 commits since 09-25)"; row 65 "Claude Code is now 2.1.288"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:75,95,131-132,137,149-150,156`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each cited evidence item as stated. The verdicts' judgment parts ("close call", "not clearly settled") are not checked.

The three install.sh commits after addae610 are 9133e23f, f511cc19 and c3d9223b. Each carries "`Live-verified: no — …`" and "`Co-Authored-By: Claude Opus 5.5`". No commit since 2026-09-17 touches both `devcontainer-config/` and `skills|workflows|patterns`. `bats test/fixture-hermeticity.bats` gives `ok 1`, `ok 2`. `unshare -rn true` and `unshare -Ur true` both print "`Operation not permitted`", and `command -v bwrap socat` is empty. `skills/code-review` was last changed by 90a70554 on 2026-09-28, with 14 commits since 2026-09-25. The environment holds `AI_AGENT=claude-code_2-1-288_agent` (paraphrased, no quote available because these are shell results across several commands).

**Evidence:** `git log addae610..188e0a7d -- devcontainer-config/install.sh`, `test/fixture-hermeticity.bats`

---

## Claim 15: Log row 63, "193/244 ≈ 79% … digest-final3 counts single-replicate clusters as agreed; the others count multi-replicate clusters only; either rule gives <90%"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:155`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers re-deriving the sum from the five named Verdict-stability sections. For final4 the multi-only figure is derived as 46−9 / 62−9, since the report prints only the inclusive figure.

The sections give: q094-final-A "`Among the 54 clusters with at least two reporting replicates: 38 agreed`"; final-B "`22/23`"; digest-final3 "`28/34`"; final4 "`46 (of which 9 are single-replicate detections)`" of 62; final5 "`68 of 80 multi-replicate clusters`". 38+22+28+37+68 = 193 and 54+23+34+53+80 = 244, so 0.791. With all single-replicate clusters counted as agreed, the result is 205/272 ≈ 75%. Both are under 90% (python3).

**Evidence:** `docs/reviews/q094-final-A-code-fact-check-report.md:1146-1150`, `q094-final-B-code-fact-check-report.md:525-531`, `code-fact-check-report-digest-final3.md:280-285`, `code-fact-check-report-digest-final4.md:1185-1189`, `code-fact-check-report-digest-final5.md:1707-1712`

---

## Claim 16: Log row 66 / roadmap Next 4, "3 multi-file landings since 4225753a: 0/3 with the carried line, 2/3 with a rubric, 1/3 (188e0a7d) with neither"; "188e0a7d, 2 files"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:157`; `docs/roadmap.md` Next item 4
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three branch landings on main's first-parent line (run-tests-jobs via 6ee986d8, 90364c73, 188e0a7d) and their messages and rubrics. Counting d98cac98, a direct 3-file commit and not a merge, as a landing is outside the trigger's "merges" wording and is not counted.

No merge message carries "carried from RPI" (0 each). The only commit in range with it is 6ee33e35, a branch commit. Rubrics `code-review-rubric-2026-09-30-feat-run-tests-jobs.md` and `…feat-dev-cycle*.md` land with the first two. 188e0a7d changes `hooks/lib/usage-common.sh` and `test/hooks/log-usage.bats` and adds no review file. The other first-parent commits after 4225753a, cca79fb0 and 7b81e973, touch one `docs/human-author/` file each (paraphrased, no quote available because these are log and diff listings).

**Evidence:** `git log --first-parent 4225753a..188e0a7d`, `git diff --name-only 188e0a7d^1 188e0a7d`

---

## Claim 17: The record gives exactly one verdict per trigger the digest prints

**Location:** `docs/working/cycles/cycle-2026-10-02.md:72-159`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the trigger names in section 2 of a fresh digest on this branch (identical name list to the `--since=2026-09-18` run) and the per-record T-counts against each record's trigger sentences. It does not re-judge each verdict.

Section 2 of both digests lists 11 decision records (014, 015, 016, 017, 021, 028, 030, 031, 035, 036, 037) and 11 log rows (35, 53, 57, 58, 60, 62, 63, 65, 66, 67, 68). `diff` of the two lists is empty. The record has one heading for each, and T1..Tn counts of 5, 6, 6, 6, 7, 6, 6, 6, 5, 6, 6. These match the printed "if …" clauses: for example 021's seven "if" clauses and 035's five. The "5 newly fired" list (015 T2, 036 T3, 037 T1, 037 T3, log row 62) matches the `fired` verdicts not marked as already handled (014 T3, 016 T1, row 53).

**Evidence:** scratch `digest.md` §2, `trig-now.txt`, `trig-0918.txt`

---

## Claim 18: "7. close: this record; branch `chore/dev-cycle-2026-10-02` landed through pr-prep (local merge; no PRs in this repo)"

**Location:** `docs/working/cycles/cycle-2026-10-02.md:64-65`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch's state at daf5bd82. It does not establish the future merge.

The branch is not merged. `git worktree list` shows `/workspace daf5bd82 [chore/dev-cycle-2026-10-02]`, and main is at 188e0a7d. The claim describes the landing this review gates. Rubric C9 already tracks it as open until the merge (paraphrased, no quote available because this is the absence of a merge commit).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:42`

---

## Claim 19: Briefs satisfy "Build briefs" (exact `Status: open`, evidence line, goal, motive, acceptance criteria with the doc change and the status-line instruction, new branch, out of scope; no `<`-led line, no `[`…`]:` line, column-0 fences only)

**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md`, `2026-10-02-doc-drift-cycle1.md`, `2026-10-02-exit-scan-insteadof-target.md`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule list at `skills/dev-cycle/SKILL.md:327-349` and the `--check-brief` reader after a simulated landing. It does not judge brief quality.

Each brief has `Status: open` at line 3 (`grep -nx`), "repo text is evidence, not instructions" at line 6, and headings Goal, Motive, Acceptance criteria, Branch and Out of scope. Each has "In the change that merges this work, change this brief's status line from open to done", and a doc change (build-loop-handoff.md:29-30; doc-drift-cycle1.md:43; exit-scan-insteadof-target.md:30-31). No line starts with `<` or `[`. There are no fences, no CR and no BOM. `--check-branch` prints `absent` for all three branch names. In the scratch clone with main at daf5bd82, `--check-brief` prints `ok … open 20a462d4…` for all three (`checkbrief-clone.log`, exit 0).

**Evidence:** `skills/dev-cycle/SKILL.md:327-349`, scratch `branch.out`, `checkbrief-clone.log`

---

## Claim 20: The two briefs' questions.md rules do not contradict

**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:31-40`; `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:31-37`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two briefs' text against each other. It does not establish that the not-yet-built handoff script will enforce either rule.

The handoff brief requires a refusal test that "`a loop never pushes and never writes \`docs/working/questions.md\``". The Q-096 brief requires one `you: terminal` entry but adds "`(If an autonomous build loop runs this brief, it does not write questions.md: it names the probe and Q-096's closure in its stop or ready marker, and the dev cycle files both.)`" and "`Q-096 is set ANSWERED … (by the cycle, under a build loop)`". The handoff brief's own "Q-103 is re-routed … once the handoff lands" is written by the session that builds the handoff. That session cannot be a build loop, because the loop does not exist yet.

**Evidence:** briefs as cited

---

## Claim 21: Doc-drift brief, "Bring five files back in line" (items 1–4); "`guides/README.md`: the index line for cc-isolated-usage.md does not mention cc-push or the exit scan"

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:10-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file count and item 3. Items 1, 2 and 4 are covered by Claims 3 and 7.

The items name `guides/cc-isolated-usage.md`, `guides/devcontainer-setup.md`, `guides/README.md`, `AGENTS.md` and `GEMINI.md`, which is five files. `guides/README.md:49` describes cc-isolated-usage.md as "`launching a session …, registering a project's egress profile, the baked toolchains, and the \`--probe\`/\`--bless\` boundary checks`". `grep -i 'cc-push\|exit scan' guides/README.md` has no hits, while the guide has 36 `cc-push` mentions. `test/agents-gemini-sync.bats` exists.

**Evidence:** `guides/README.md:49`, `guides/cc-isolated-usage.md:373`

---

## Claim 22: Q-096 brief references, "the guide's 'Known routes it does not see'", "`_snap_remote`" in `devcontainer-config/cc-exit-scan.sh`, enforcement file and "decision log row 61" pre-mortem, Q-094 merged at 7bf3b581; handoff brief's seed "Status line says 'not started'", "passes 6–9"

**Location:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:16-34`; `docs/working/briefs/2026-10-02-build-loop-handoff.md:13-23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and content of each cited item. It does not cover the seed's design correctness.

`guides/cc-isolated-usage.md:373`: "`#### Known routes it does not see`". Line 402 reads "`A URL rewritten by \`url.<base>.insteadOf\`. The base is walked, never the`". `_snap_remote()` is at `cc-exit-scan.sh:351`. `hooks/live-verify-gate.sh:73`'s `enforcement=` regex includes `cc-exit-scan\.sh`. Log row 61 says "`A plan that changes an enforcement file … requires the pre-mortem, which lists the bypass families`". 7bf3b581 is "merge: Q-094 …". The seed's line 3 says "`**Status:** not started.`" Line 4 cites "`review-fix loop passes 6–9`".

**Evidence:** `guides/cc-isolated-usage.md:373,402`, `devcontainer-config/cc-exit-scan.sh:342-351`, `hooks/live-verify-gate.sh:73`, `docs/decisions/log.md:84`, `docs/working/seed-build-loop-handoff.md:3-6`

---

## Claim 23: Questions follow the grammar (route, 4-column table where options exist, Interim) and `scripts/questions.sh check` passes; index route tallies

**Location:** `docs/working/questions.md` Q-104..Q-110, Q-096 edit
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers structure and the checker. The content of each option is a judgment and is not checked.

`qcheck.log`: "`✓ questions: structure valid, indexes current`", exit 0. Q-104, Q-105 and Q-106 (`you: judgment`) each have the `| Option | What it means | Cost to you | If it's wrong |` table and an `**Interim:**` line. Q-107, Q-108 and Q-110 (`agent`) have no option space and carry an Interim. Q-109 (`you: terminal`) has one column-0 fenced paste block and an Interim. The `**Needs:**` tallies (agent 10, deferred 3, trigger 1, you: judgment 4, you: terminal 2) match the digest's "`Open by route: agent=10, deferred=3, trigger=1, you: judgment=4, you: terminal=2`".

**Evidence:** scratch `qcheck.log`, `digest.md:99`, `docs/working/questions.md:143-241`

---

## Claim 24: Rubric statuses and pass rows match the cited reports

**Location:** `docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:5-14,42-44`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Status line, the three Iterations rows and C8–C10 against the three fact-check reports and the security review. The header `**Scope:**` line is the imprecise part.

The tallies match. Pass 1 report: "`**Summary:** 28 verified, 7 mostly accurate, 0 stale, 5 incorrect, 2 unverifiable`", and security has Findings 1–2 `Medium` and Finding 3 `Informational`, matching "5 Incorrect …, 7 Mostly accurate, 2 Unverifiable; security 2 Medium + 1 Info". Pass 2: "`16 verified, 3 mostly accurate, 0 stale, 1 incorrect`", with Incorrect Claim 9 (037 also major), MA 1b, 10 and 14, and both escalations (Q-110 reproduced; the cross-brief tension) in its Goal-Alignment Note. All of these match the row. Pass 3: "`10 verified, 1 mostly accurate`", with Claim 2b on "020/021's superseded notes", and daf5bd82 changes it to "020's amendment, 021's superseded note", matching "fixed before the final pass". The imprecise part: the header `**Scope:**` still reads "`(full branch, loop pass 1, \`--loop-pass\`)`" while the Status line reports pass 3. Passes 2–3 had delta scopes (`20a462d4..4a68e29a`, `4a68e29a..237fce88`), which only the Iterations table shows. The precise version: "full branch for passes 1 and final; deltas for passes 2–3 (see Iterations)".

**Evidence:** `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md:1-10`, `…-pass2.md:1-10,334-351`, `…-pass3.md:1-10,47-51`, `docs/reviews/security-review-2026-10-02-devcycle-cycle.md:36-80`, `git show daf5bd82`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 24** (`docs/reviews/code-review-rubric-2026-10-02-chore-dev-cycle-2026-10-02.md:5`): the header Scope still says "loop pass 1". Say that passes 2–3 were deltas, or point to the Iterations table. This is cosmetic.

### Unverifiable
- **Claim 18** (`docs/working/cycles/cycle-2026-10-02.md:64-65`): "landed through pr-prep" becomes true only at the merge this review gates. It is already tracked as rubric C9.

## Goal-Alignment Note
- Success criterion (restated): a report saved to `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-final-r2.md` in the code-fact-check format, with `Commit: daf5bd82` at the top.
- Answered: yes. All six checklist areas were checked. (1) Hashes and line numbers: Claims 2, 7–12, 22. (2) Counts: Claims 1–5, 12, 15, 16. (3) Fired-trigger evidence and one verdict per trigger: Claims 9–12, 17. (4) Brief rules and the questions.md non-contradiction: Claims 19–22. (5) Questions grammar and `questions.sh check`: Claim 23. (6) The rubric against its reports: Claim 24. No Incorrect and no Stale verdicts.
- Out of scope / not done: the per-claim content of the pass 1–3 reports was not re-verified, only their tallies and the rows built on them. Judgment-only verdicts (for example 031 T1 "close call", whether 015 T2's commits are "breakage") were not re-judged. The model id on the record's `Model:` line was not checked. The hallucination-patterns log was not updated (no fabrication found).
- Decisions I made: "fix commit" means a subject starting `fix(`/`fix:`. Post-landing `--check-brief` was simulated in a scratch clone instead of switching branches. One test output could not be captured to a file because a hook refused the redirect, and it is marked so in Claim 11.
