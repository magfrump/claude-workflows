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
| [Q-161](#q-161--revive-hermeticity-layer2-after-q125) | trigger | When Q-125's sandbox merges (bwrap in the cc-isolated image), decision 017's T2 fires: revive hermeticity l... | 2026-10-14 |
| [Q-262](#q-262--merge-approval-revisit) | trigger | Should merge approval be reopened? The design record picked no change on 2026-11-06, and this watch holds i... | 2026-11-06 |
| [Q-264](#q-264--gloss-rule-falsifier) | trigger | Did the rule to explain every internal reference work? Decision-log row 84 names what would show it did not. | 2026-11-06 |
<!-- index:end -->

## Open

### Q-161 · revive-hermeticity-layer2-after-q125
**Needs:** trigger · **Opened:** 2026-10-14 · **Status:** OPEN

When Q-125's sandbox merges (bwrap in the cc-isolated image), decision 017's T2 fires: revive hermeticity layer 2 as an in-session gate, and re-run decision 014's layer-3 per-suite confinement RPI, reconsidering its pruned candidate 15. 014 T3 has already fired: the Q-126 host probe showed bwrap starting on WSL2 under Q-125's seccomp profile.

- **Read:** `docs/decisions/014-secure-tool-guidance-layers.md` and `docs/decisions/017-polyglot-test-hermeticity.md` (Revisit triggers) · Q-126 in the archive · Q-125
- **Interim:** nothing changes until Q-125 merges. The condition: `command -v bwrap` succeeds in a cc-isolated session on main's image.

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

### Q-262 · merge-approval-revisit
**Needs:** trigger · **Opened:** 2026-11-06 · **Status:** OPEN

Should merge approval be reopened? The design record picked no change on 2026-11-06, and this watch holds its revisit triggers.

- **Read:** `docs/working/research-2026-11-06-merge-friction-design.md`, section 11.
- **Interim:** merge entries stay as they are. The conditions are that section's list: the owner names merge entries or approvals as a blocker; merge entries exceed 11 a week in 3 of the next 4 weekly digests, which reopens the record's candidate [5]; or the record's median-wait trigger.

### Q-264 · gloss-rule-falsifier
**Needs:** trigger · **Opened:** 2026-11-06 · **Status:** OPEN

Did the rule to explain every internal reference work? Decision-log row 84 names what would show it did not.

- **Read:** `docs/decisions/log.md`, row 84.
- **Interim:** the rule stands. The condition, counted once 5 or more entries have opened after the first install from a commit holding 771c84e8, with entries' own text and marker bodies counted separately: half or more still carry a bare numbered label, or filed marker bodies mostly do, or the owner again names references as the problem. Then re-run divergent design.
- **2026-11-10:** that first install has happened. The image is at 536b7082, which holds 771c84e8 (`git merge-base --is-ancestor`), so the count starts with entries opened from today. So far: 4 (Q-269, Q-270, Q-271, Q-272); the count is made at 5.

## Closed
