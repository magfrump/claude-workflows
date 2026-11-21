# Watching

Watches the agents own and close: conditions and events being waited on, moved
out of `questions.md` (decision 040). Same entry grammar; a closed watch gets
Status ANSWERED and moves under `## Closed`.

| Route | Meaning |
|---|---|
| `deferred` | Waiting on an event that has not happened. |
| `trigger` | A condition being watched, not a question yet. |

Maintained by `~/.claude/scripts/questions.sh` (`check` · `index` · `migrate`); the index below is generated.

## Index

<!-- index:start -->
| ID | Needs | Question | Opened |
|---|---|---|---|
| [Q-067](#q-067--regenerate-skill-eval-reports) | deferred | Q-067: met — the A8 measurement it waited on ran and merged (eddcaf16, Q-320 [1]); the regeneration quest... | 2026-09-26 |
| [Q-098](#q-098--global-allowlist-after-sandbox) | deferred | Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088). Branc... | 2026-09-28 |
| [Q-167](#q-167--post-install-host-probes) | deferred | At the next release whose install re-blesses, ask the owner for the hint text that the fresh bless prints b... | 2026-10-15 |
| [Q-276](#q-276--q272-return-with-data) | deferred | Return the run-or-refuse question (Q-272: what the test-confinement script does when it has only its weak t... | 2026-11-11 |
| [Q-322](#q-322--quarterly-threat-model-walkthrough-due) | deferred | Q-322: met — the owner's T12 verdict came first (Q-327 [2], `docs/human-author/answers-11-20-26.txt` line... | 2026-11-19 |
| [Q-161](#q-161--revive-hermeticity-layer2-after-q125) | trigger | When Q-125's sandbox merges (bwrap in the cc-isolated image), decision 017's T2 fires: revive hermeticity l... | 2026-10-14 |
| [Q-262](#q-262--merge-approval-revisit) | trigger | Should merge approval be reopened? The design record picked no change on 2026-11-06, and this watch holds i... | 2026-11-06 |
| [Q-264](#q-264--gloss-rule-falsifier) | trigger | Q-264: met — counted on 2026-11-11 at five entries opened since the install (Q-269 to Q-273): the falsifi... | 2026-11-06 |
| [Q-275](#q-275--self-answer-plan-after-q272) | trigger | Q-275: met — the owner answered Q-272 on 2026-11-11 with [1] "to start" (run and warn). The exception is ... | 2026-11-11 |
| [Q-301](#q-301--test-confinement-fallback-reachable) | trigger | Bring the test-confinement script's run-or-refuse question (`scripts/confine-tests.sh`: run under `unshare`... | 2026-11-18 |
| [Q-313](#q-313--live-verify-merge-of-main-stop) | trigger | Reopen the dropped roadmap Idea "The live-verify hook reads a merge commit's staged diff against HEAD only"... | 2026-11-19 |
| [Q-331](#q-331--write-guard-claude-worktree-live-check) | trigger | Record the live check of the write-guard fix in 61122f34 (Q-326 [1]: `hooks/guard-trusted-writes.py` judges... | 2026-11-20 |
| [Q-334](#q-334--constraint-cited-routing-revisit) | trigger | Reopen "a judgment entry's 'Why it's yours' quotes the constraint it relies on" if a second case appears of... | 2026-11-20 |
| [Q-338](#q-338--parked-shell-removal-observable) | trigger | Replace R2 (worktrees removed in a separate call after a bare `cd` into `.worktrees`) with option 2 (each r... | 2026-11-20 |
<!-- index:end -->

## Open

### Q-161 · revive-hermeticity-layer2-after-q125
**Needs:** trigger · **Opened:** 2026-10-14 · **Status:** OPEN

When Q-125's sandbox merges (bwrap in the cc-isolated image), decision 017's T2 fires: revive hermeticity layer 2 as an in-session gate, and re-run decision 014's layer-3 per-suite confinement RPI, reconsidering its pruned candidate 15. 014 T3 has already fired: the Q-126 host probe showed bwrap starting on WSL2 under Q-125's seccomp profile.

- **Read:** `docs/decisions/014-secure-tool-guidance-layers.md` and `docs/decisions/017-polyglot-test-hermeticity.md` (Revisit triggers) · Q-126 in the archive · Q-125
- **Interim:** nothing changes until Q-125 merges. The condition: `command -v bwrap` succeeds in a cc-isolated session on main's image.
- **2026-11-11:** Q-125 merged at 3cd6d9bb (Q-267 [1]). The image a session runs is still the old one, so the condition waits on the release (Q-273) and a new sandbox launch.
- **2026-11-12, later:** the owner chose to keep no sandbox (decision-log row 88). This watch is dormant unless `bwrap` returns to the image some other way.
- **2026-11-12:** the sandbox was rolled back (7caea26d, Q-277 [3]), and the revert took `bwrap` out of the image, so the condition cannot be met until the sandbox returns. The image sessions run (80b7dabe) has no `bwrap`.

### Q-098 · global-allowlist-after-sandbox
**Needs:** deferred · **Opened:** 2026-09-28 · **Status:** OPEN

Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088). Branch `feat/wiring-allowlist-b` holds the 778-rule list, its tests and two review passes. It stays unmerged: without a sandbox, allowed tools leak through their own flags. The hook's shape check (decision log 64) cannot see that.

- **Read:** `docs/reviews/code-fact-check-report-wiring-pass1-5094b99.md` (on that branch) · `docs/reviews/code-fact-check-report-wiring-pass2-e511a14.md` (on that branch; the leak list's source) · decision log 64 · Q-088
- **Leak list, to use as the sandbox spike's test set.** Each item was approved with no prompt by the 778-rule list and the shape-checked hook, or was run in a scratch repo:
  - `git diff --no-index /dev/null ~/.claude/.c*` reads the credentials file;
  - `git log -1 --format=%B --output=/home/node/.claude/settings.json` writes the config volume (`guard-trusted-writes.py` does not catch `--output`);
  - `git status`, `git diff`, `git log -p` and `git show` run `core.fsmonitor`, `diff.external` and textconv drivers from repo config the agent can edit;
  - `man -l <file>` and `date -f <file>` read a file (both reproduced by the unit-A pass-2 fact-check).
  - Not on this list because the hook now refuses them whatever the rules say: bash builtins that evaluate their arguments (`read 'a[$(cmd)]'`, `test -v`, `printf -v`, `mapfile -C`, `hash -p`) and the shell constructs in decision log 64.
- **Trigger:** Q-125 lands (Q-124 answered [1], build the sandbox) and the sandbox denies reads of `~/.claude/.credentials.json` and writes to `~/.claude/settings*.json`. Then re-run the leak list inside it before merging any list.
- **Interim:** no global allow list. cc-isolated sessions prompt for commands not in their project's `.claude/settings.json`.
- **2026-11-11:** Q-125 landed at 3cd6d9bb (Q-267 [1]), with no live run on record. The second half of the trigger, the sandbox denying those reads and writes, is what the live check in Q-273 shows; the leak list waits for it.
- **2026-11-11, later:** the live check ran on the owner's host and failed (Q-273). The trigger's second half is not met: a sandboxed command still running when the credential is replaced by rename, as a token refresh does, read the new file (`X4-cred-across-rename FAIL`). Reads before a rename and writes to the user settings files were refused, by the verdict's count. No list ships until the roadmap item "a sandboxed command can read the credential after a token refresh" is closed and the check passes, whatever the owner answers to Q-277 (install with the gaps, or hold).
- **2026-11-12, later:** the owner chose to keep no sandbox (decision-log row 88: "worktree usage is too important"). This watch is dormant: nothing is expected to meet it unless a sandbox is proposed again.
- **2026-11-12:** Q-277 was answered [3] and main rolled the sandbox back (7caea26d), so no sandbox exists to meet the trigger. It now waits for the sandbox's return, which needs worktree creation under it as well as the two gaps closed (research brief `docs/working/briefs/2026-11-12-sandbox-return-research.md`).

### Q-262 · merge-approval-revisit
**Needs:** trigger · **Opened:** 2026-11-06 · **Status:** OPEN

Should merge approval be reopened? The design record picked no change on 2026-11-06, and this watch holds its revisit triggers.

- **Read:** `docs/working/research-2026-11-06-merge-friction-design.md`, section 11.
- **Interim:** merge entries stay as they are. The conditions are that section's list: the owner names merge entries or approvals as a blocker; merge entries exceed 11 a week in 3 of the next 4 weekly digests, which reopens the record's candidate [5]; or the record's median-wait trigger.
- **2026-11-19, iteration 0331 UTC:** the record's section 11 lists five conditions; this watch held three. The other two: an approved merge is reverted (which goes first to the entry's wording, area B's B7, then here), and a T5 sample reply is recorded. The revert condition fired on 2026-11-12 (the sandbox merge 3cd6d9bb, reverted by 7caea26d), and area A's research (e9fb762c) reopened the question; it is asked in Q-323. The watch stays open for the remaining conditions.

### Q-301 · test-confinement-fallback-reachable
**Needs:** trigger · **Opened:** 2026-11-18 · **Status:** OPEN

Bring the test-confinement script's run-or-refuse question (`scripts/confine-tests.sh`: run under `unshare` after a warning, or refuse, when `bwrap` is unusable) back to the owner once an answer could change what the script does.

- **Read:** `docs/working/research-2026-11-18-rewrite-q278.md` (why it was withdrawn, and what the returning entry must hold) · Q-272 in `docs/working/questions-archive.md`, Q-278 and fyi Q-300 in `docs/working/questions.md` (or the archive once answered) · decision-log rows 87 and 88 (`docs/decisions/log.md`)
- **Condition** (any one, checked each iteration in the watches step):
  (a) a build loop's research doc, a review or a cycle record, added or changed since the last iteration, quotes a line the script printed in a run: `confine-tests: primitive available:` or `falling back to the unshare primitive` (`rg -l` over those files under `docs/`, excluding `docs/working/questions*.md`, `docs/working/watching.md` and `docs/working/research-2026-11-18-rewrite-q278.md`, which quote the strings to describe this watch);
  (b) `command -v bwrap` succeeds in a session;
  (c) a CI job, host step or hook starts calling `scripts/confine-tests.sh` (a new caller outside build-loop test steps and `test/scripts/confine-tests.bats`).
- **Interim:** the owner's Q-272 answer stands: when only `unshare` works, the script warns and runs. A loop that meets the fallback quotes its line in its research doc (that is condition (a)); it does not build a refusal and does not file the fallback as a new H2 finding. No line is added to `docs/constraints.md` while this is open.
- **When it fires:** file a `you: judgment` entry. Its first line names the test-confinement script and says it is not Claude Code's Bash sandbox; it uses that one name throughout. Its options are run and warn (with the `docs/constraints.md` line it needs, drafted), refuse (a loop then falls back to the unconfined run plus `scripts/hermeticity-lint`), and do not confine tests at all (retire the script and the briefs' probe step), each with the costs observed by then and any count's undercount stated. Host facts go in a separate `you: terminal` entry. Then close this watch.

### Q-167 · post-install-host-probes
**Needs:** deferred · **Opened:** 2026-10-15 · **Status:** OPEN

At the next release whose install re-blesses, ask the owner for the hint text that the fresh bless prints before any probe. Its four other checks passed on 2026-11-03 and 2026-11-07.

- **Moved here 2026-11-18** from `you: terminal`, on the owner's go-ahead in session: the hint shows only during an install that re-blesses, so there was nothing for the owner to run until then. Full record: `docs/working/history-terminal-entries-2026-11-18.md`.
- **Condition:** the cycle files an `image-lag` release entry (dev-cycle step 0.1). That entry then adds one line asking the owner to paste the bless output's `Verified live:` and `Next:` lines, and `cc-isolated --list`'s `Blessed config` line, before running any probe. Pass: `Verified live:  NO — a bless is a review, not a test.`, `Next: cc-isolated --probe-only <repo>` alone on its line, and `--list` showing `verified live: NO (run: cc-isolated --probe-only <repo>)`.
- **Interim:** the rebuild-hint commits keep `Live-verified: no`; that output rests on bats. The second half (a probe marks the bless verified) is live-verified on bless 3c5dd7853cf7a3f9.
- **Closes:** when those pasted lines are on record here.
- **2026-11-19, iteration 0056 UTC:** the owner reports the 0feaf080 install did re-bless, but its output was too large to find the lines in, and the Q-303 entry's ask was hard to spot. The `--list` line is asked for alone in Q-316 (one grep). The bless's own `Verified live:` and `Next:` lines are gone with that output; at the next re-bless, the image-lag entry's paste ends with `| tee "$TMPDIR/install.log"` and asks for `grep -E 'Verified live:|^Next:' "$TMPDIR/install.log"`, a two-line answer.
- **2026-11-20:** the owner pasted Q-316's `--list` output: `Blessed config c9e7e4e468927b93 — verified live: yes`. A probe had already run since the bless, so the pre-probe `verified live: NO (run: cc-isolated --probe-only <repo>)` hint was not seen. Q-317's install (main 61122f34) came back `done` with no install log. All three lines are still unobserved, so this stays open. At the next image-lag entry, ask for the `tee`/`grep` two lines **and** `cc-isolated --list 2>&1 | grep -i 'blessed config'`, all run right after the install and before any probe.

### Q-331 · write-guard-claude-worktree-live-check
**Needs:** trigger · **Opened:** 2026-11-20 · **Status:** OPEN

Record the live check of the write-guard fix in 61122f34 (Q-326 [1]: `hooks/guard-trusted-writes.py` judges an edit inside a `.claude/` linked worktree by its path within that worktree). Its commit says `Live-verified: no`.

- **Read:** Q-317 (image-lag) in `docs/working/questions-archive.md`, the release that installed it, answered `done` with no `guard:` line · Q-326 in the same archive.
- **Condition:** the owner, or a session record, reports what happened in a web-tainted session (one that has run a web search) on the installed image: an ordinary file edit inside a `.claude/worktrees/` worktree, and an edit to that worktree's CLAUDE.md.
- **Pass:** the ordinary edit applies with no ask, and the CLAUDE.md edit still asks. Anything else becomes a fix.
- **Interim:** the fix rests on bats (`test/hooks/guard-trusted-writes.bats`). Worktrees under `.worktrees/` never asked, so the cycle's own work does not depend on it. Not routed to the owner as a terminal entry: the owner's normal math-research work produces the observation, so it needs no extra session.
- **Closes:** when that report is recorded here.

### Q-313 · live-verify-merge-of-main-stop
**Needs:** trigger · **Opened:** 2026-11-19 · **Status:** OPEN

Reopen the dropped roadmap Idea "The live-verify hook reads a merge commit's staged diff against HEAD only" if a build loop or session is ever stopped by `hooks/live-verify-gate.sh` (the hook that asks for a `Live-verified:` trailer on enforcement-file commits) while merging main into its branch.

- **Read:** `docs/working/research-2026-11-19-live-verify-merge-head-count.md` (the count, 4 of 108 merges in the case, none stopped; its Recommendation section holds the fix sketch and bypass list).
- **Condition:** a `blocked` or `stopped` marker, or a cycle record, names this hook during a merge of main.
- **Interim:** nothing is built; such merges carry `Live-verified: no — merge of main; main's commit carries its own trailer`, which the hook accepts.

### Q-334 · constraint-cited-routing-revisit
**Needs:** trigger · **Opened:** 2026-11-20 · **Status:** OPEN

Reopen "a judgment entry's 'Why it's yours' quotes the constraint it relies on" if a second case appears of an owner entry sent to the owner on a constraint that does not cover it.

- **Read:** `docs/working/research-2026-11-20-why-its-yours-constraint-research.md` (merged 6a07b026: in this repo 0 of 153 "Why it's yours" lines cite a constraint by number, and the two entries routed by one, Q-272 and Q-278 on H2, cover their case; the one reported miss is philosophy-research's F-007, Q-133 there, written before the gloss rule of decision-log row 84) · F-007 in `docs/working/feedback/philosophy-research.md`.
- **Condition** (either): a harness-feedback entry from any repo, after F-007, reports a judgment entry routed by a constraint that does not cover the case; or a session in philosophy-research runs the research doc's count there and finds a second such entry.
- **When it fires:** brief the doc's runner-up as a review brief: one clause added to the global instructions' "Gloss every reference" rule (`global-instructions/CLAUDE.md`), so an entry that relies on a constraint quotes its line. Then close this watch.
- **Interim:** no rule; entries follow the existing gloss rule. Held here, not as a decision-log row, because `docs/decisions/` is the owner's file and the cycle does not write it.

### Q-338 · parked-shell-removal-observable
**Needs:** trigger · **Opened:** 2026-11-20 · **Status:** OPEN

Replace R2 (worktrees removed in a separate call after a bare `cd` into `.worktrees`) with option 2 (each removal moved to the next iteration) if a build loop is still refused after a parked removal.

- **Read:** `docs/working/research-2026-11-20-loop-start-dir-research.md` (merged 319559d9: the mechanism, 31 of 69 loops refused, and the pairing method) · merge entry Q-337 and the brief `docs/working/briefs/2026-11-20-remove-worktrees-parked-shell.md`.
- **Condition:** a build loop's report, marker or transcript shows a Bash call refused with "no longer exists, so this command was not run" within minutes of an orchestrator worktree removal made after a bare `cd` into `.worktrees` (applied by hand since iteration 2026-11-20-2133). Each iteration that dispatched or collected loops checks the loops' hand-back reports for that line.
- **When it fires:** file a review brief for option 2, citing the refusal, and close this watch.
- **Closes:** also when ten parked removals in a row show no such refusal, recorded here with the iterations.
- **Interim:** R2 by hand (and in the skill once Q-337 merges and installs). Since 2133: the R2, self-improvement and `--cycle-diff` loops started from a parked shell; none of the two that handed back reports a refusal.

## Closed

### Q-322 · quarterly-threat-model-walkthrough-due
**Needs:** deferred · **Opened:** 2026-11-19 · **Status:** ANSWERED
Q-322: met — the owner's T12 verdict came first (Q-327 [2], `docs/human-author/answers-11-20-26.txt` line 246, 7df4654d): T12 is kept but "doesn't really address the chain of trust between the reports and the facts in the code"; the walk-through question is Q-340.

Bring the owner's quarterly threat-model walk-through of Q-103's accepted residual risks (area B's idea B8) back as a question when it first falls due, in 2027-01, unless trial T12's verdict covers it first.

- **Read:** `docs/working/research-2026-11-19-area-b-ask-habituation.md` §6 (set aside: about 20 owner minutes a quarter; T12, `docs/working/trials/2026-11-06-attention-and-trust.md`, tests a cheaper answer to the same need) · the idea-log line "Quarterly threat-model walk-through of Q-103's residuals".
- **Condition:** the first cycle iteration on or after 2027-01-01, or the owner's T12 verdict, whichever comes first.
- **Interim:** nothing is scheduled; T12 runs.

### Q-067 · regenerate-skill-eval-reports
**Needs:** deferred · **Opened:** 2026-09-26 · **Status:** ANSWERED
Q-067: met — the A8 measurement it waited on ran and merged (eddcaf16, Q-320 [1]); the regeneration question returns to the owner as Q-321.

When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the current SKILL.md files instead of being NOT RUN?

- **Why it's yours:** regenerating means one headless model run per fixture, about 180 fixtures across 23 skills. Memory [[run-a8-measurement-after-settling]] says no big compute before the A8 measurement.
- **Read:** `docs/working/audit-test-constraint-2026-09-26.md` batch G, and commit 48680e2 (stamps plus the per-skill gate).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Fold into A8** | Regenerate as part of the A8 run once the code settles | None now | Skill-prompt regressions go uncaught until then, as they have all along |
| **[2] One skill now** | Regenerate one high-value skill (e.g. security-reviewer) to prove the loop end to end | About 12 model runs | A little quota spent before A8 |
| **[3] All now** | `bash test/skills/generate-reports.bash` for every skill | About 180 runs, which may skew A8's baseline | Quota spent, and A8 comparability muddied |

- **Interim:** [1]. The suites print NOT RUN, and health-check warns with the count, so no one mistakes them for a pass.
- **Deferred 2026-09-26 behind Q-071:** under the current stamp design, regenerated reports go stale at the next contract edit, so the suite design comes first.
- **2026-09-27:** Q-071 was answered [1] (narrow stamp, committed reports), so one regeneration now stays valid until the skill itself changes. This remains deferred behind A8 only ([[run-a8-measurement-after-settling]]).
- **If the answer differs:** nothing to redo; only when regeneration happens changes.

### Q-276 · q272-return-with-data
**Needs:** deferred · **Opened:** 2026-11-11 · **Status:** ANSWERED

Return the run-or-refuse question (Q-272: what the test-confinement script does when it has only its weak tool) to the owner with data, a few days after 2026-11-11, as the owner asked.

- **Read:** Q-272 in `docs/working/questions-archive.md` · the roadmap Now item "data for the run-or-refuse question's return" · decision-log row 87 (`docs/decisions/log.md`) · H2 in `docs/constraints.md`
- **Interim:** the owner's answer, [1] "to start": `scripts/confine-tests.sh` runs under `unshare` after a warning when `bwrap` is missing. No exception to H2 is written into `docs/constraints.md` while the answer is provisional. The event: 2026-11-16, or the data being ready, whichever comes first. Then file a new `you: judgment` entry with Q-272's three options and the two things the owner asked for: how often `bwrap` was absent where the script ran, and how much friction a refusal would cause (how many test runs it would have stopped). If there is no data by then, the entry says so and says why; it does not wait longer.
- **If the owner then refuses the exception:** the self-answering plan's exceptions rule (closed watch Q-275) has its first confirmed case.

Q-276: met — the data is ready: docs/working/research-2026-11-11-confine-tests-fallback-data.md, merged at b9c8966a (brief 2026-11-11-confine-tests-fallback-data). Filed for the owner as Q-278.

### Q-275 · self-answer-plan-after-q272
**Needs:** trigger · **Opened:** 2026-11-11 · **Status:** ANSWERED
Q-275: met — the owner answered Q-272 on 2026-11-11 with [1] "to start" (run and warn). The exception is granted for now, so the exceptions rule has no confirmed case and is dropped, as this watch's interim says; Q-274 was answered [1] the same day (build nothing). The owner asked for Q-272 back with data in a few days, which is watch Q-276; a refusal then would be the rule's first case.

When the owner answers Q-272 (run or refuse when the test-confinement script has only its weak tool), does the self-answering plan's exceptions rule have a case?

- **Read:** `docs/working/research-2026-11-11-self-answer-measure.md`, sections 9.2 and 9.6 · Q-274 (how far the plan goes) · Q-272
- **Interim:** nothing is built (Q-274's option [1]). The condition: Q-272 is answered. If the owner refuses the exception there, the rule "a brief may not scope out a hard constraint, and an entry does not ask about an exception its writer recommends against" has its first confirmed case, and one design unit can take it up, unless Q-274 says otherwise. If the owner grants it, drop the rule. This watch exists because the cycle's revisit step does not read working docs.

### Q-264 · gloss-rule-falsifier
**Needs:** trigger · **Opened:** 2026-11-06 · **Status:** ANSWERED
Q-264: met — counted on 2026-11-11 at five entries opened since the install (Q-269 to Q-273): the falsifier did not show. One of the five carries a numbered label without its doc (Q-269 names "the A8 token measurement" and says what it is, with no link); the one marker body filed whole (in Q-271) carries none; the owner has not named references as a problem since. Counted by the session that wrote all five, so decision-log row 84's trigger stays the standing check.

Did the rule to explain every internal reference work? Decision-log row 84 names what would show it did not.

- **Read:** `docs/decisions/log.md`, row 84.
- **Interim:** the rule stands. The condition, counted once 5 or more entries have opened after the first install from a commit holding 771c84e8, with entries' own text and marker bodies counted separately: half or more still carry a bare numbered label, or filed marker bodies mostly do, or the owner again names references as the problem. Then re-run divergent design.
- **2026-11-10:** that first install has happened. The image is at 536b7082, which holds 771c84e8 (`git merge-base --is-ancestor`), so the count starts with entries opened from today. So far: 4 (Q-269, Q-270, Q-271, Q-272); the count is made at 5.
