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
| [Q-083](#q-083--host-tools-trust-category) | you: judgment | The trust manifest's rule "every shipped file is hashed" puts host-only tools (`cc-push.sh`, and soon `cc-e... | 2026-09-27 |
| [Q-066](#q-066--sandbox-tool-map-host-drift-run) | you: terminal | The permission allow list exists only on your host, so the two drift checks in `test/sandbox-tool-map-drift... | 2026-09-26 |
| [Q-082](#q-082--auto-approve-host-checks) | you: terminal | Two Claude Code behaviours decide whether the auto-approve hook's deny reader is load-bearing or redundant,... | 2026-09-27 |
| [Q-084](#q-084--q076-live-checks) | you: terminal | Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git... | 2026-09-27 |
| [Q-075](#q-075--si-loop-trust-before-resume) | agent | Q-068 was answered "resume", but only once the user trusts `scripts/self-improvement.sh` not to break their... | 2026-09-27 |
| [Q-076](#q-076--cc-isolated-git-exit-scan) | agent | Implement Q-069 [3]. At session exit, `cc-isolated.sh` warns about, or refuses, `.git` changes made during ... | 2026-09-27 |
| [Q-079](#q-079--canon-instance-proposal-filter) | agent | Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the high... | 2026-09-27 |
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

### Q-079 · canon-instance-proposal-filter
**Needs:** agent · **Opened:** 2026-09-27 · **Status:** OPEN

Design, per Q-072, (a) a script that turns a commit or commit range into a canon instance, and (b) the higher-level heuristic that decides which candidates get *proposed*. The canon should stay compact and broad in issue types. Growth should be justified by coverage, not triggered by volume. Draft it as a divergent-design doc. The filter choice then comes back as a `you: judgment` entry.

- **Read:** `docs/working/canon-issue-ledger.md` · `review-canon.md` §1 · the 112 September `docs/reviews/` artifacts as the candidate pool
- **Interim:** the ledger is unchanged.

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

### Q-084 · q076-live-checks
**Needs:** you: terminal · **Opened:** 2026-09-27 · **Status:** OPEN

Q-076 (`cc-push`, the exit scan) was verified only with bats: stubbed docker and local-path remotes, on git 2.39.5. After merging, re-run `install.sh` (it re-blesses; `cc-push.sh`, `cc-exit-scan.sh` and `cc-gitdir.sh` are new), then run this on the host:

```
git --version          # cc-push refuses below 2.39.4 / 2.40.2 / 2.41.1 / 2.42.2 / 2.43.4 / 2.44.1 / 2.45.1 (or <2.46 otherwise)
# 1. a clean session: launch, make one commit, exit claude -> expect exit 0 and no WARNING
cc-isolated ~/path/to/a/scratch/repo
# 2. while that container is still up, in another host shell -> expect a refusal naming the running container
cc-push --remote <your real remote URL> ~/path/to/a/scratch/repo
# 3. stop the container (or exit cc-isolated), then push for real -> expect the preview, then the push
cc-push ~/path/to/a/scratch/repo
```

- **Interim:** every enforcement-file commit on Q-076 carries `Live-verified: no`.
- **If the answer differs:** a refusal on step 3, a warning on step 1, or a version refused that git's release notes list as fixed means a follow-up fix. Also check git's May 2024 security release notes against the version list in the `cc-push.sh` header, which was written from memory.

### Q-083 · host-tools-trust-category
**Needs:** you: judgment · **Opened:** 2026-09-27 · **Status:** OPEN

The trust manifest's rule "every shipped file is hashed" puts host-only tools (`cc-push.sh`, and soon `cc-exit-scan.sh` and `cc-gitdir.sh`) in the container-boundary enforcement category. Should host tools get their own category?

- **Why it's yours:** it amends decision log row 45's scope and changes what the live-verify gate demands of every commit to these files.
- **Read:** `docs/reviews/q076-architecture-review-2026-09-27.md` Finding 3 · decision log row 45 · `hooks/live-verify-gate.sh` · `enforcement_files` in `devcontainer-config/cc-isolated.sh`.
- **The problem, concretely:** host tools can't be live-probed, so every commit to them carries `Live-verified: no`, which dilutes row 45's debt list. `check_manifest` runs only when cc-isolated launches, so a changed `cc-push.sh` blocks every launch until re-blessed, while `cc-push` itself runs unchecked.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Separate host-tools category** | Its own manifest section and commit trailer (e.g. `Host-tool-tested:`); `cc-push` verifies its own hash before running; row 45 amended | Review one enforcement change | More machinery for two or three files |
| **[2] Keep as enforcement files** | Record in row 45 that host tools are deliberately in the enforcement set | None | Debt list stays diluted; a cc-push edit keeps blocking launches until re-bless |
| **[3] Unhash host tools** | Drop them from the manifest; rely on git review only | None | A tampered cc-push on the host goes unnoticed |

- **Interim:** [2] in practice (user deferred this at the Q-076 fix batch, 2026-09-27).
- **If the answer differs:** [1] is a small enforcement-file change with tests; [3] edits the manifest and the tests that pin it.
- **If the answer differs:** denied in both runs ⇒ Claude Code's `permissions.deny` wins over a hook allow, and the hook's deny reader can be deleted (architecture-review 1). Runs or prompts only with the hook wired ⇒ keep it and reclassify the hook as an enforcement component. Also record whether the leading `*` in `Bash(*.credentials.json*)` matched at all.
