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
| [Q-067](#q-067--regenerate-skill-eval-reports) | deferred | When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the cur... | 2026-09-26 |
| [Q-098](#q-098--global-allowlist-after-sandbox) | deferred | Ship a global `permissions.allow` in `hooks/wiring.json` once cc-isolated has a Bash sandbox (Q-088). Branc... | 2026-09-28 |
| [Q-276](#q-276--q272-return-with-data) | deferred | Return the run-or-refuse question (Q-272: what the test-confinement script does when it has only its weak t... | 2026-11-11 |
| [Q-161](#q-161--revive-hermeticity-layer2-after-q125) | trigger | When Q-125's sandbox merges (bwrap in the cc-isolated image), decision 017's T2 fires: revive hermeticity l... | 2026-10-14 |
| [Q-262](#q-262--merge-approval-revisit) | trigger | Should merge approval be reopened? The design record picked no change on 2026-11-06, and this watch holds i... | 2026-11-06 |
| [Q-264](#q-264--gloss-rule-falsifier) | trigger | Q-264: met — counted on 2026-11-11 at five entries opened since the install (Q-269 to Q-273): the falsifi... | 2026-11-06 |
| [Q-275](#q-275--self-answer-plan-after-q272) | trigger | Q-275: met — the owner answered Q-272 on 2026-11-11 with [1] "to start" (run and warn). The exception is ... | 2026-11-11 |
<!-- index:end -->

## Open

### Q-161 · revive-hermeticity-layer2-after-q125
**Needs:** trigger · **Opened:** 2026-10-14 · **Status:** OPEN

When Q-125's sandbox merges (bwrap in the cc-isolated image), decision 017's T2 fires: revive hermeticity layer 2 as an in-session gate, and re-run decision 014's layer-3 per-suite confinement RPI, reconsidering its pruned candidate 15. 014 T3 has already fired: the Q-126 host probe showed bwrap starting on WSL2 under Q-125's seccomp profile.

- **Read:** `docs/decisions/014-secure-tool-guidance-layers.md` and `docs/decisions/017-polyglot-test-hermeticity.md` (Revisit triggers) · Q-126 in the archive · Q-125
- **Interim:** nothing changes until Q-125 merges. The condition: `command -v bwrap` succeeds in a cc-isolated session on main's image.
- **2026-11-11:** Q-125 merged at 3cd6d9bb (Q-267 [1]). The image a session runs is still the old one, so the condition waits on the release (Q-273) and a new sandbox launch.
- **2026-11-12:** the sandbox was rolled back (7caea26d, Q-277 [3]), and the revert took `bwrap` out of the image, so the condition cannot be met until the sandbox returns. The image sessions run (80b7dabe) has no `bwrap`.

### Q-067 · regenerate-skill-eval-reports
**Needs:** deferred · **Opened:** 2026-09-26 · **Status:** OPEN

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
- **2026-11-12:** Q-277 was answered [3] and main rolled the sandbox back (7caea26d), so no sandbox exists to meet the trigger. It now waits for the sandbox's return, which needs worktree creation under it as well as the two gaps closed (research brief `docs/working/briefs/2026-11-12-sandbox-return-research.md`).

### Q-262 · merge-approval-revisit
**Needs:** trigger · **Opened:** 2026-11-06 · **Status:** OPEN

Should merge approval be reopened? The design record picked no change on 2026-11-06, and this watch holds its revisit triggers.

- **Read:** `docs/working/research-2026-11-06-merge-friction-design.md`, section 11.
- **Interim:** merge entries stay as they are. The conditions are that section's list: the owner names merge entries or approvals as a blocker; merge entries exceed 11 a week in 3 of the next 4 weekly digests, which reopens the record's candidate [5]; or the record's median-wait trigger.

## Closed

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
