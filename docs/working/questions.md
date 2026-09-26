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
| [Q-068](#q-068--si-loop-retire-or-resume) | you: judgment | Should `scripts/self-improvement.sh` be retired or resumed? The triage decided this was your call (D3), but... | 2026-09-26 |
| [Q-069](#q-069--host-git-on-container-checkout) | you: judgment | cc-isolated's recommended workflow is "commit in the container, push from the host with your keys". But the... | 2026-09-26 |
| [Q-070](#q-070--auto-approve-backstops-in-cc-isolated) | you: judgment | `hooks/auto-approve-allowed-commands.sh` accepts its known bypasses because "permissions.deny plus the sand... | 2026-09-26 |
| [Q-071](#q-071--skill-eval-suite-design) | you: judgment | The 50 `@needs-reports` suites can't stay green under this repo's editing rate. Their freshness stamp hashe... | 2026-09-26 |
| [Q-072](#q-072--living-ledger-not-fed) | you: judgment | The review-eval goal is "recall against the living issue ledger", but `docs/working/canon-issue-ledger.md` ... | 2026-09-26 |
| [Q-073](#q-073--skill-descriptions-truncated) | you: judgment | Skill descriptions run 957–2973 characters, and the live skill listing truncates them. In this session 7 ... | 2026-09-26 |
| [Q-066](#q-066--sandbox-tool-map-host-drift-run) | you: terminal | The permission allow list exists only on your host, so the two drift checks in `test/sandbox-tool-map-drift... | 2026-09-26 |
| [Q-065](#q-065--si-input-rejected-history-dead-code) | deferred | `prepend_si_input_rejected_history` (`scripts/lib/si-input.sh:214`) has had no caller since it landed in 06... | 2026-09-26 |
| [Q-067](#q-067--regenerate-skill-eval-reports) | deferred | When should the skill eval reports be regenerated, so that the 50 `@needs-reports` suites constrain the cur... | 2026-09-26 |
| [Q-074](#q-074--failure-pattern-writer-trigger) | trigger | After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about... | 2026-09-26 |
<!-- index:end -->

## Open





### Q-065 · si-input-rejected-history-dead-code
**Needs:** deferred · **Opened:** 2026-09-26 · **Status:** OPEN

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
- **If the answer differs:** nothing to redo; only when regeneration happens changes.

### Q-068 · si-loop-retire-or-resume
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** OPEN

Should `scripts/self-improvement.sh` be retired or resumed? The triage decided this was your call (D3), but it was never filed, and 17 commits have hardened the loop since.

- **Why it's yours:** it decides where the repo's maintenance effort goes. Four other items wait on it.
- **Read:** `docs/working/triage-2026-09-17-backlog.md` §4 (verdict: "#7 + #2 dominates"; "keep as-is and resume" marked Drop) · `archive/docs/2026-09-18-handoff-self-improvement-loop.md` §4–§5 (the three couplings any retirement must handle).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Retire, keep the carve-out, build the triage report** | The triage's pick (#7 + #2). The loop goes to `archive/`. The 25-line `tap_*` carve-out and its 11 tests stay. An attention-triage report replaces what the loop was kept for. | Review one retirement diff | The loop is gone. Reviving it is one `git mv` back from `archive/` |
| **[2] Retire entirely** | As [1] without the carve-out | Same | The `tap_*` helpers would have to be rewritten if something needs them |
| **[3] Resume as-is** | Run it again | Its morning summaries: the 50-question queue the triage calls the anti-pattern | Your attention budget, again |
| **[4] Leave dormant, stop maintaining it** | No runs and no more hardening commits | None | Code keeps drifting from the decisions that describe it |

- **Blocks:** Q-065 (dead helper) · reconciling decision 020 with Gate 1h's fail-closed behaviour · the planner prompts and morning-summary verdict gate that still treat usage.jsonl counts as evidence (Q-017)
- **Interim:** [4] in practice. Nothing runs it. The review found a stale comment and a stale header on it; I fixed only those.
- **If the answer differs:** nothing to undo.

### Q-069 · host-git-on-container-checkout
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** OPEN

cc-isolated's recommended workflow is "commit in the container, push from the host with your keys". But the container can write `.git`, so a plain host `git push` or `git status` runs whatever hooks and fsmonitor it planted, as you. How should the host touch a container-written checkout?

- **Why it's yours:** it changes your daily push habit, and it weighs your time against how exposed your credentials are.
- **Read:** `guides/cc-isolated-usage.md` (the new caveat under "No credentials") · decision 015 H1 · decision 034 ("the host never reads a container-written `.git`", so far applied only to the benchmark harness) · decision 037 line 81.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Push from a separate host clone** | Keep a host-only clone. `git fetch` from the container checkout and push from there. Nothing reads the container's config. | One extra clone per project, plus a fetch before each push | Nothing |
| **[2] Guarded git for container checkouts** | A shell function that adds `-c core.hooksPath=/dev/null -c core.fsmonitor=false` in container-mounted paths | Setup once | Filter drivers and `include` keys are still exposed; an unguarded `git status` slips through |
| **[3] Launcher-side scan** | `cc-isolated.sh` refuses to exit cleanly (or warns) when `.git` gained hooks, fsmonitor, filters or includes during the session, reusing install.sh's refusal list | None day to day; I build it | A planted key added after the scan, or on a container that is never stopped |
| **[4] Accept the risk** | Keep the documented caveat only | None | An injected agent gets your ssh keys at your next push |

- **Interim:** the guide now documents the risk and the safer push command. Nothing is enforced.
- **If the answer differs:** [3] is a code change to an enforcement file, so it needs a live-verified commit.

### Q-070 · auto-approve-backstops-in-cc-isolated
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** OPEN

`hooks/auto-approve-allowed-commands.sh` accepts its known bypasses because "permissions.deny plus the sandbox are the boundary". Inside cc-isolated neither exists: no `sandbox` key and no Bash deny rules. The reviewer got it to auto-approve a `curl -d @…/.credentials.json` nested in `$(( ))`, which gets past the `Read(.credentials.json)` deny rule. What should auto-approve rest on there?

- **Why it's yours:** it trades prompt friction against what an injected agent can run without asking.
- **Read:** the hook's header, lines 25–35 · `hooks/wiring.json` permissions block · decision 023 ("widens nothing") · decision 015 (the container is low-stakes, but the credentials file is not). The global instructions' "Tool Preferences" section also assumes a bwrap sandbox that cc-isolated does not have.
- **Caveat:** I have relayed the reproduction; I have not re-run it.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Supply the backstops** | Add Bash deny rules for the credentials path, and a sandbox config, to the cc-isolated settings merge | Some new prompts where the sandbox blocks | Rules are string matches too, so obfuscation may still get through |
| **[2] Narrow the hook** | Refuse to auto-approve any command with `$(`, backticks, `$((`, redirections or env-assignment prefixes, whatever the allowlist says | More prompts on compound commands | Little: those fall back to a normal prompt |
| **[3] Unwire it in cc-isolated** | `CC_SKIP_HOOK_WIRING`-style opt-out for this one hook | Every piped command prompts | Friction only |
| **[4] Accept** | 015 calls the container low-stakes | None | The OAuth credential is exfiltrable without a prompt |

- **Interim:** nothing changed.
- **If the answer differs:** [2] is a small hook change plus tests. I'd recommend it as the default whichever else you pick.

### Q-071 · skill-eval-suite-design
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** OPEN

The 50 `@needs-reports` suites can't stay green under this repo's editing rate. Their freshness stamp hashes the skill dir, the per-skill runner and the shared `test/skills/runner-contract.bash`. That shared file changed 8 times in 30 days, and every change makes every skill's reports stale, which fails the suites. Keep the design, or change it?

- **Why it's yours:** it decides whether skill-output testing costs quota on every skill edit, and whether it exists at all.
- **Read:** `docs/working/audit-test-constraint-2026-09-26.md` batch G · commit 48680e2 · `test/skills/runner-contract.bash` `report_stamp`. Reports are gitignored (`.gitignore:5`), so they also never survive a fresh clone.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Narrow the stamp, commit the reports** | Stamp the skill's own files and the fixture only (not the shared contract), and track `output/*.report.md` | One regeneration run, then only skills you edit | A contract change that alters output goes unnoticed until the next regeneration |
| **[2] Stale = skip, loudly** | Keep full stamps, but a stale report skips with a NOT RUN line instead of failing | None | The suites rarely run, as today |
| **[3] Retire them** | Delete the output-dependent suites and keep the prose-contract tests | None | Skill-output regressions stay invisible, as they are today |
| **[4] As is** | Strict stamps, reports gitignored | Regenerating everything after every contract edit | The suites are red whenever reports exist |

- **Blocks:** Q-067 (when to regenerate) matters only under [1], [2] or [4].
- **Interim:** [4]. The suites print NOT RUN, because no reports exist.
- **If the answer differs:** [1] and [2] are small edits to `runner-contract.bash` and its freshness tests.

### Q-072 · living-ledger-not-fed
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** OPEN

The review-eval goal is "recall against the living issue ledger", but `docs/working/canon-issue-ledger.md` hasn't changed since 2026-08-18. Since then, 112 September review artifacts have been written to `docs/reviews/`, and none feed back into it. Feed it, or restate the goal?

- **Why it's yours:** you defined the metric (memory, 2026-08-14 correction). Whether the ledger stays living is a scope call, and it changes what the A8 measurement can claim.
- **Read:** `docs/working/canon-issue-ledger.md` header · `docs/thoughts/code-review-evaluation-state.md` (now marked stale).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Automate the feed** | A script lifts confirmed Must-Fix rows from new `docs/reviews/` rubrics into the ledger as candidates. It is a script, not a workflow step: steps in workflow docs don't run | Review candidate rows now and then | Noise in the ledger if the lifting is loose |
| **[2] Feed it at A8 time only** | One backfill pass when A8 runs | One review pass then | Recall numbers before A8 use a stale denominator |
| **[3] Freeze and rename** | Call it the 8-instance canon and drop "living" | None | The metric is the frozen benchmark you ruled out |

- **Interim:** no change. The ledger's header still says "living".
- **If the answer differs:** nothing to undo.

### Q-073 · skill-descriptions-truncated
**Needs:** you: judgment · **Opened:** 2026-09-26 · **Status:** OPEN

Skill descriptions run 957–2973 characters, and the live skill listing truncates them. In this session 7 skills (cowen, yglesias, the 3 business-plan critics, design-space-situating, self-eval) showed **no description at all**, and pre-mortem/what-if's disambiguation is cut mid-sentence. Separately, cowen and yglesias both call themselves "the DEFAULT critic", and "what am I missing" triggers three skills. Rewrite the descriptions?

- **Why it's yours:** descriptions are what triggers the skills. Rewriting them changes when each skill fires, and which critic is the default is a taste call.
- **Read:** `guides/skill-format-audit.md` F4 (open since April) · `guides/skill-trigger-guide.md`. I did not verify the cause; the listing's overall character budget is the likely one.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Front-load and trim** | First ~250 chars carry the trigger phrases and the "not this, use X" line; the rest moves to the body | Skim 25 diffs | Some long-tail trigger phrasing is lost |
| **[2] [1] plus de-overlap** | Also pick one default prose critic and give each overlapping phrase one owner | Plus: name the default critic | A phrase you liked routing two ways routes one way |
| **[3] Leave** | — | None | 7 skills stay effectively invisible to triggering |

- **Interim:** nothing changed. I removed only the health-check requirement for the unread `when:` field (F1).
- **If the answer differs:** n/a.

### Q-074 · failure-pattern-writer-trigger
**Needs:** trigger · **Opened:** 2026-09-26 · **Status:** OPEN

After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only. If it reaches 2026-10-26 with fewer than 5 new entries, reopen L1 as a judgment: automate the harvest, or drop the "do not skip" line.

- **Interim:** nothing changed. The read side (the RPI failure-pattern grep) works.
