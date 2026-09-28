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
| [Q-081](#q-081--cc-isolated-sandbox-half) | you: judgment | Q-070 [1] asked for Bash deny rules *and* a sandbox config in cc-isolated. Only the deny half was built (Q-... | 2026-09-27 |
| [Q-066](#q-066--sandbox-tool-map-host-drift-run) | you: terminal | The permission allow list exists only on your host, so the two drift checks in `test/sandbox-tool-map-drift... | 2026-09-26 |
| [Q-082](#q-082--auto-approve-host-checks) | you: terminal | Two Claude Code behaviours decide whether the auto-approve hook's deny reader is load-bearing or redundant,... | 2026-09-27 |
| [Q-075](#q-075--si-loop-trust-before-resume) | agent | Q-068 was answered "resume", but only once the user trusts `scripts/self-improvement.sh` not to break their... | 2026-09-27 |
| [Q-076](#q-076--cc-isolated-git-exit-scan) | agent | Implement Q-069 [3]. At session exit, `cc-isolated.sh` warns about, or refuses, `.git` changes made during ... | 2026-09-27 |
| [Q-077](#q-077--cc-isolated-auto-approve-backstops) | agent | Implement Q-070 [1]. The cc-isolated settings merge gains Bash deny rules for the credentials path and a sa... | 2026-09-27 |
| [Q-078](#q-078--narrow-skill-report-stamp) | agent | Implement Q-071 [1]. `report_stamp` in `test/skills/runner-contract.bash` hashes only the skill dir and the... | 2026-09-27 |
| [Q-079](#q-079--canon-instance-proposal-filter) | agent | Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the high... | 2026-09-27 |
| [Q-080](#q-080--front-load-skill-descriptions) | agent | Implement Q-073 [1] across the ~25 skills. The first ~250 characters of each description carry the trigger ... | 2026-09-27 |
| [Q-067](#q-067--regenerate-skill-eval-reports) | deferred | When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the cur... | 2026-09-26 |
| [Q-074](#q-074--failure-pattern-writer-trigger) | trigger | After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about... | 2026-09-26 |
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
- **Deferred 2026-09-26 behind Q-068:** if the loop is retired, this is moot; if it resumes, ask again.
- **Un-deferred 2026-09-27:** Q-068 was answered "resume". [2] now matters, because the preamble would show up in real runs. It is not urgent, since the loop won't run until Q-075 is settled.
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

### Q-074 · failure-pattern-writer-trigger
**Needs:** trigger · **Opened:** 2026-09-26 · **Status:** OPEN

After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only. If it reaches 2026-10-26 with fewer than 5 new entries, reopen L1 as a judgment: automate the harvest, or drop the "do not skip" line.

- **Interim:** nothing changed. The read side (the RPI failure-pattern grep) works.

### Q-075 · si-loop-trust-before-resume
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** OPEN

Q-068 was answered "resume", but only once the user trusts `scripts/self-improvement.sh` not to break their setup. Build the evidence for that: list every path, config, hook, credential and git ref the loop can write outside its own working docs, then run it once hermetically with every env-overridable destination redirected, and diff the setup before and after.

- **Read:** `archive/docs/2026-09-18-handoff-self-improvement-loop.md` §4–§5 · memory [[prove-old-code-fails-hermetically]]
- **Interim:** the loop stays dormant.
- **If the answer differs:** n/a. The output is a report the user reads before the first real run.

### Q-076 · cc-isolated-git-exit-scan
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** OPEN

Implement Q-069 [3]. At session exit, `cc-isolated.sh` warns about, or refuses, `.git` changes made during the session: new hooks, `core.fsmonitor`, filter drivers, `include`/`includeIf`. It reuses install.sh's refusal list.

- **Interim:** the guide's documented caveat only.
- **Blocks:** nothing. This is an enforcement file, so it needs a live-verified commit.

### Q-077 · cc-isolated-auto-approve-backstops
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** OPEN

Implement Q-070 [1]. The cc-isolated settings merge gains Bash deny rules for the credentials path and a sandbox config. Then re-run the reported `$(( ))` credentials reproduction against the result.

- **Interim:** nothing changed. The reproduction has still not been re-run first-hand.

### Q-078 · narrow-skill-report-stamp
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** OPEN

Implement Q-071 [1]. `report_stamp` in `test/skills/runner-contract.bash` hashes only the skill dir and the fixture, `.gitignore:5` stops ignoring `output/*.report.md`, and the freshness tests are updated to match.

- **Interim:** the suites print NOT RUN.

### Q-079 · canon-instance-proposal-filter
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** OPEN

Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the higher-level heuristic that decides which candidates get *proposed*. The canon should stay compact and broad in issue types. Growth should be justified by coverage, not triggered by volume. Draft it as a divergent-design doc. The filter choice then comes back as a `you: judgment` entry.

- **Read:** `docs/working/canon-issue-ledger.md` · `review-canon.md` §1 · the 112 September `docs/reviews/` artifacts as the candidate pool
- **Interim:** the ledger is unchanged.

### Q-080 · front-load-skill-descriptions
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** OPEN

Implement Q-073 [1] across the ~25 skills. The first ~250 characters of each description carry the trigger phrases and the "not this, use X" line, and the rest moves to the SKILL.md body. No de-overlap. The user skims the diffs.

- **Interim:** 7 skills still show no description in the listing.

### Q-081 · cc-isolated-sandbox-half
**Needs:** you: judgment · **Opened:** 2026-09-27 · **Status:** OPEN

Q-070 [1] asked for Bash deny rules *and* a sandbox config in cc-isolated. Only the deny half was built (Q-077): the image has no `bwrap`/`socat`, and Docker's default seccomp blocks user namespaces (`unshare -Ur` → EPERM). Build the sandbox, or accept the container plus `permissions.deny` as the boundary?

- **Why it's yours:** it trades kernel attack surface and image changes against how much a prompt-injected agent can do without asking. The deny rule alone does not stop a determined injection: a glob `.cred*`, a variable set earlier, and brace/ANSI-C spellings are pinned as accepted in `test/auto-approve-allowed-commands.bats`.
- **Read:** the `hooks/auto-approve-allowed-commands.sh` header (GUARANTEES / RESIDUALS) · decision log 53 · `docs/reviews/security-review-2026-09-27.md` F5.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Build the sandbox** | Add `bubblewrap` and `socat` to the Dockerfile, a seccomp/runArgs change allowing user namespaces, and a `sandbox` settings block (`autoAllowBashIfSandboxed` decided explicitly; `allowedDomains` matched to the egress allowlist) | Review an enforcement-file change and one live container check | Wider kernel surface; mismatched domains make `gh`/`git push` prompt |
| **[2] Spike `enableWeakerNestedSandbox` first** | Test whether the weaker nested mode avoids the user-namespace change, then do [1] or [3] | One spike | May cost a spike for nothing |
| **[3] Accept deny + container** | Record that in cc-isolated the boundary is the container plus `permissions.deny` | None | The OAuth credential stays reachable by a determined injection |

- **Interim:** [3] in practice. Nothing sandboxes Bash in cc-isolated.
- **If the answer differs:** [1]/[2] are new enforcement-file work with a live-verified commit.

### Q-082 · auto-approve-host-checks
**Needs:** you: terminal · **Opened:** 2026-09-27 · **Status:** OPEN

Two Claude Code behaviours decide whether the auto-approve hook's deny reader is load-bearing or redundant, and the sandbox can't check them (no network, no live Claude Code). In a host Claude Code session **after re-running `install.sh`**, so the merged settings carry `Bash(*.credentials.json*)`, with auto-approve wired and `Bash(echo:*)` allowed, ask Claude to run each line and note whether it runs, prompts, or is denied:

```
echo $((1 + $(cat ~/.claude/.credentials.json | wc -c)))
echo "$(cat ~/.claude/.credentials.json | wc -c)"
```

Then repeat with the auto-approve hook removed from settings for that session.

- **Interim:** the hook header calls its deny check load-bearing in cc-isolated until this is known.
- **If the answer differs:** denied in both runs ⇒ Claude Code's `permissions.deny` wins over a hook allow, and the hook's deny reader can be deleted (architecture-review 1). Runs or prompts only with the hook wired ⇒ keep it and reclassify the hook as an enforcement component. Also record whether the leading `*` in `Bash(*.credentials.json*)` matched at all.
