# Running questions

Questions raised during autonomous work that did not justify stopping.

**To answer:** write `Q-0NN: <your answer>` anywhere — a reply, a file, a commit.
The ID is the whole handle; you never have to restate the question. Answers move
the entry to `questions-archive.md`, so this file only ever holds what is still open.

**Needs** is the route — who or what actually discharges the item, from
`docs/working/triage-2026-09-17-backlog.md` §3.1:

| Route | Meaning |
|---|---|
| `you: judgment` | Needs your taste or authority. The only real attention spend. |
| `you: terminal` | Needs your machine, not your mind. Collected into one paste below. |
| `agent` | Mechanical. Should not be here long. |
| `trigger` | Not a question yet — a condition being watched. Costs you nothing. |
| `deferred` | Scheduled behind an event that has not happened. |

Maintained by `scripts/questions.sh` (`check` · `index` · `archive` · `next-id` · `open`).
The index below is generated — edit entries, not the table.

## Index

<!-- index:start -->
| ID | Needs | Question | Opened |
|---|---|---|---|
| [Q-065](#q-065--si-input-rejected-history-dead-code) | you: judgment | `prepend_si_input_rejected_history` (`scripts/lib/si-input.sh:214`) has had no caller since it landed in 06... | 2026-09-26 |
| [Q-067](#q-067--regenerate-skill-eval-reports) | you: judgment | When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the cur... | 2026-09-26 |
| [Q-066](#q-066--sandbox-tool-map-host-drift-run) | you: terminal | The permission allow list exists only on your host, so the two drift checks in `test/sandbox-tool-map-drift... | 2026-09-26 |
<!-- index:end -->

## Open





### Q-065 · si-input-rejected-history-dead-code
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** OPEN

`prepend_si_input_rejected_history` (`scripts/lib/si-input.sh:214`) has had no caller since it landed in 06903d6 (2026-05-19). 12 of the 14 tests in `test/si-input-rejected-history.bats` exercise only this dead function. Should it be wired in or deleted?

- **Why it's yours:** whether the self-improvement loop should show recent rejections in si-input.md is a product call. The code can't tell whether leaving it unwired was deliberate.
- **Read:** `docs/working/audit-test-constraint-2026-09-26.md` batch D. The function's header comment describes it as the "new-cycle bootstrap".

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Delete** | Remove the function and its 12 tests. Keep the 2 `parse_si_input` tests. | None | The rejected-history preamble never appears. It never has so far. |
| **[2] Wire it in** | Call it at run start in `self-improvement.sh` and add a wiring test. | Review one behaviour change to si-input.md | Rejection rows appear in a file you edit, and may be noise |
| **[3] Leave as is** | The 12 tests keep constraining code that nothing runs | None | The suite overstates coverage |

- **Interim:** [3], nothing changed. No production path reaches it, so nothing is at risk.
- **If the answer differs:** [1] or [2] is a single small commit.

### Q-066 · sandbox-tool-map-host-drift-run
**Needs:** you: terminal · **Opened:** 2026-09-26 · **Status:** OPEN

The permission allow list exists only on your host, so the two drift checks in `test/sandbox-tool-map-drift.bats` always skip in the sandbox. Run them once on the host in strict mode, from the repo root:

```
REQUIRE_LIVE_SETTINGS=1 bats test/sandbox-tool-map-drift.bats
```

- **Interim:** the sandbox run proves only that the checks can fail (fixture tests), not that `guides/sandbox-tool-map.md` matches your live settings.
- **If the answer differs:** a red result lists the drifted `Bash(X:*)` entries. Fix the guide's table and markers to match.

### Q-067 · regenerate-skill-eval-reports
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** OPEN

When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the current SKILL.md files instead of being NOT RUN?

- **Why it's yours:** regenerating means one headless model run per fixture, about 180 fixtures across 23 skills. Memory [[run-a8-measurement-after-settling]] says no big compute before the A8 measurement.
- **Read:** `docs/working/audit-test-constraint-2026-09-26.md` batch G, and commit 48680e2 (stamps plus the per-skill gate).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Fold into A8** | Regenerate as part of the A8 run once the code settles | None now | Skill-prompt regressions go uncaught until then, as they have all along |
| **[2] One skill now** | Regenerate one high-value skill (e.g. security-reviewer) to prove the loop end to end | About 12 model runs | A little quota spent before A8 |
| **[3] All now** | `bash test/skills/generate-reports.bash` for every skill | About 180 runs, which may skew A8's baseline | Quota spent, and A8 comparability muddied |

- **Interim:** [1]. The suites print NOT RUN, and health-check warns with the count, so no one mistakes them for a pass.
- **If the answer differs:** nothing to redo; only when regeneration happens changes.
