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
| [Q-023](#q-023--health-check-bats-scope) | you: judgment | Should `health-check.sh` gate 5 run all bats suites, not just `test/skills/` and `test/hooks/`? | 2026-09-18 |
| [Q-024](#q-024--draft-review-market-sizing) | you: judgment | `business-plan-critique-market-sizing` says draft-review typically invokes it, but draft-review never selec... | 2026-09-18 |
| [Q-025](#q-025--lite-review-install-path) | you: judgment | pr-prep and review-fix-loop tell agents to run `scripts/lite-review.py`, which does not exist in projects t... | 2026-09-18 |
| [Q-026](#q-026--guard-project-claude-dir) | you: judgment | `hooks/guard-trusted-writes.py` treats any `.claude/settings*.json` or `.claude/hooks/**` as HARD and defer... | 2026-09-18 |
| [Q-028](#q-028--onboarding-trigger-never-clears) | you: judgment | Decision-tree row 1 fires onboarding when a project has "no `docs/thoughts/`", but onboarding only writes `... | 2026-09-18 |
| [Q-029](#q-029--perf-cold-path-severity) | you: judgment | performance-reviewer gives two defaults for an algorithmic (macro) problem on a cold path: the hot-path gat... | 2026-09-18 |
| [Q-030](#q-030--arch-review-stale-security-input) | you: judgment | architecture-review reads "the most recent" `docs/reviews/security-review-*.md` for trust boundaries and ne... | 2026-09-18 |
| [Q-031](#q-031--draft-review-unmapped-verdicts) | you: judgment | draft-review's rubric tier rules place Inaccurate, Mostly Accurate, Unverified and Accurate, but fact-check... | 2026-09-18 |
| [Q-032](#q-032--self-eval-rubric-outside-repo) | you: judgment | self-eval requires `docs/evaluation-rubric.md`, which exists only in this repo; `link-claude-home.sh` doesn... | 2026-09-18 |
| [Q-033](#q-033--claude-api-flat-file) | you: judgment | `skills/claude-api.md` is a flat file, so the harness never loads it as a skill (skills load from `skills/<... | 2026-09-18 |
| [Q-011](#q-011--mathlib-cache-host) | you: terminal | What is the current mathlib olean cache hostname? (`lake exe cache get` is minutes vs hours per repo.) | 2026-09-12 |
<!-- index:end -->

## Open

### Q-011 · mathlib-cache-host
**Needs:** you: terminal · **Opened:** 2026-09-12 · **Status:** OPEN

What is the current mathlib olean cache hostname? (`lake exe cache get` is minutes vs hours per repo.)

- **Attempt 2026-09-17 — your run was against the right file, and the answer is that the question's shape is wrong.** `rg -o 'https://[^"]*' .../mathlib/Cache/Requests.lean` returned exactly two strings: a bare `https://` and `https://github.com/leanprover-community/mathlib4.git`. A bare prefix means the cache URL is **assembled at runtime**, not written down as a constant — which is also what your sketched docstring describes (`MATHLIB_CACHE_GET_URL` → `--cache-from` → `MATHLIB_CACHE_FROM` → `defaultContainersForRepo repo`). So there may be no single hostname to list: the host comes from a per-repo container list, and an allowlist entry has to name whatever `defaultContainersForRepo` resolves to for mathlib4.
- **Attempt 2026-09-18: half answered, and the entry stays open.** Your paste (`docs/human-author/answers-9-18-26.txt`) settles which *kind* of host it is. `Cache/Marker.lean:34` builds URLs as `s!"{container.azureURL}/m/{normalizeRepo repo}/{sha}"`, so every container is an **Azure Blob** endpoint, not ghcr.io or another registry, and the registry branch of "What I do with it" is ruled out. It does not show the storage-account hostname. `head -60` cut the output off before the definitions of `defaultContainersForRepo` and `azureURL`, where that literal lives. I could guess `lakecache` from the old code, but the VERIFY comment asks for the name to be *seen*, so I am not closing on a guess. Also worth checking: "widens the lookup chain" suggests several containers. An Azure container is a path under one account, so they probably share one host. If they span accounts, the allowlist needs each account.
- **Read:** `devcontainer-config/egress/lean.txt` (the `lakecache.blob.core.windows.net` entry and its ACCEPTED RISK note)
- **The paste**, narrowed to the one missing literal:

```bash
M=verifier/lean-project/.lake/packages/mathlib     # any mathlib4 checkout works
rg -n 'blob\.core\.windows\.net|azureURL|def defaultContainersForRepo' -A6 "$M"/Cache/*.lean
```

- **What I do with it:** if every hostname it prints is `lakecache.blob.core.windows.net`, the VERIFY comment is discharged and the entry stays as it is. If it prints another account, `egress/lean.txt` swaps to it (or lists each one). The ACCEPTED RISK note holds either way, since every candidate is Azure Blob.
- **Interim:** `lakecache.blob.core.windows.net` stays listed, carrying its VERIFY comment. A wrong entry degrades to "stays blocked", never to a wider allowlist, so the cost of being wrong is a slow first build rather than an exposure.
- **If the answer differs:** correct `egress/lean.txt`, re-install, re-bless.

### Q-023 · health-check-bats-scope
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** OPEN

Should `health-check.sh` gate 5 run all bats suites, not just `test/skills/` and `test/hooks/`?

- **Why it's yours:** trades health-check runtime against coverage. A green health-check says nothing about 40 suites, including `link-claude-home-wiring.bats`, which a health-check comment claims hard-gates the wiring invariants.
- **Read:** `scripts/health-check.sh:336` (`check_bats`), `scripts/run-tests.sh --fast|--slow|--all`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Call `run-tests.sh --fast`** | Gate covers every `@category fast` suite | health-check slows by the fast-suite time | A slow-only regression still slips past |
| **[2] Call `run-tests.sh --all`** | Gate covers everything | health-check takes several minutes | You stop running it because it's slow |
| **[3] Leave it** | Only fix the misleading comment | none | A red suite sits unnoticed, as the format suites did until 2026-09-18 |

- **Interim:** unchanged; the full suite was run by hand in the 2026-09-18 improvement run.

### Q-024 · draft-review-market-sizing
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** OPEN

`business-plan-critique-market-sizing` says draft-review typically invokes it, but draft-review never selects it. Which side changes?

- **Read:** `skills/business-plan-critique-market-sizing/SKILL.md:36`, `skills/draft-review/SKILL.md` (description, known-critics block, business-plan row ~90)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Add it to draft-review** | Business-plan drafts get a third critic | One more critic's tokens per business-plan review | Extra noise if market sizing rarely matters to your drafts |
| **[2] Fix the market-sizing claim** | It stays standalone-only, and says so | none | Business-plan reviews keep missing market-sizing critique |

- **Interim:** unchanged.

### Q-025 · lite-review-install-path
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** OPEN

pr-prep and review-fix-loop tell agents to run `scripts/lite-review.py`, which does not exist in projects these workflows are installed into. How should installed projects reach it?

- **Read:** `workflows/pr-prep.md:218`, `workflows/review-fix-loop.md:69` (also omits the required `--range`), `README.md:14-23` (install links; no `scripts`), `devcontainer-config/link-claude-home.sh:47` (links `scripts` to `~/.claude/scripts`)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Use `~/.claude/scripts/lite-review.py`** | Docs use the installed path; README install adds `scripts` | none | Bare-host installs that skip the link still fail |
| **[2] Mark the step optional** | "If available" wording; skip when absent | none | Fix-drift checks silently stop outside this repo |

- **Interim:** unchanged; the command works only inside this repo.

### Q-026 · guard-project-claude-dir
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** OPEN

`hooks/guard-trusted-writes.py` treats any `.claude/settings*.json` or `.claude/hooks/**` as HARD and defers to `permissions.deny`, but the deny rules cover only `~/.claude`. A project's own `.claude/settings.local.json` (which can add Bash allow rules) therefore gets no ask, even in a web-tainted session. Close it?

- **Read:** `hooks/guard-trusted-writes.py:51-53,123-126`, `hooks/wiring.json` deny rules. Reproduced by the 2026-09-18 scripts defect hunt.
- **Related:** decision log row 53 (auto-approve gaps accepted as risk; the sandbox is the boundary)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Project `.claude/` falls to SOFT** | Tainted sessions get an "ask" on project settings/hooks writes | An occasional extra prompt | Little |
| **[2] Add project paths to deny** | Hard-block writes to project `.claude/settings*` | Claude can't edit project settings at all | Blocks legitimate `update-config` use |
| **[3] Accept, like row 53** | Record as accepted risk | none | A tainted session can widen its own allow list |

- **Interim:** unchanged.

### Q-028 · onboarding-trigger-never-clears
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** OPEN

Decision-tree row 1 fires onboarding when a project has "no `docs/thoughts/`", but onboarding only writes `docs/working/onboarding-{project}.md` and never creates `docs/thoughts/`. So row 1 fires again every session in an onboarded project. Which side changes?

- **Read:** `global-instructions/CLAUDE.md:19` (row 1), `workflows/codebase-onboarding.md:18` ("Not a trigger: from-scratch projects") and step 12 (orientation doc)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Key row 1 on the orientation doc** | Trigger is "no `docs/working/onboarding-*.md`" | none | Projects onboarded by hand (no doc) get re-onboarded once |
| **[2] Onboarding creates `docs/thoughts/`** | Step 12 also seeds a thoughts file | One more file per onboarded project | Empty thoughts dirs that nobody updates |

- **Interim:** unchanged. The row keeps over-firing; in practice agents skip it when the repo is already familiar.

### Q-029 · perf-cold-path-severity
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** OPEN

performance-reviewer gives two defaults for an algorithmic (macro) problem on a cold path: the hot-path gate says "Low or Informational"; the calibration matrix says "Medium". Under code-review's mapping, Medium is 🟡 Must Address and Low is 🟢 Consider, so the same finding either blocks or doesn't. Which wins?

- **Read:** `skills/performance-reviewer/SKILL.md:46` (gate) vs `:280` (Macro × Cold row), `skills/code-review/references/rubric.md:270-271`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Macro × Cold → Low** | Matrix follows the gate; cold-path N+1s become Consider | none | A cold path that runs at scale (a nightly batch) slips through as optional |
| **[2] Keep Medium; narrow the gate** | Gate only blocks escalation to Critical/High; micro issues stay Low | More Must-Address rows on startup/migration code | Review noise on code that runs once |

- **Interim:** unchanged; agents get whichever paragraph they weigh more.

### Q-030 · arch-review-stale-security-input
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** OPEN

architecture-review reads "the most recent" `docs/reviews/security-review-*.md` for trust boundaries and never checks its `Commit:` line, so a security review of an older diff or another branch is treated as authoritative. Gate it?

- **Read:** `skills/architecture-review/SKILL.md:191-209`, `skills/security-reviewer/SKILL.md:554` (writes `Commit: <hash>`). `docs/reviews/` here holds 10+ security reviews from different branches.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Require a matching commit** | Use the file only if its `Commit:` is HEAD or the review base; otherwise skip the step | none | Standalone arch reviews lose the trust-boundary input more often |
| **[2] Use it, label its commit** | Any recent file is used; the finding cites the commit it came from | You judge staleness when reading findings | A stale boundary still shapes the finding |

- **Interim:** unchanged.

### Q-031 · draft-review-unmapped-verdicts
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** OPEN

draft-review's rubric tier rules place Inaccurate, Mostly Accurate, Unverified and Accurate, but fact-check also emits `Disputed` and `Secondary-only`, which have no tier. Where do they go?

- **Read:** `skills/draft-review/SKILL.md:460-480` (tier rules), `skills/fact-check/SKILL.md:163,172` (verdict definitions)

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Both → 🟡 Amber** | Disputed and Secondary-only need justification, like Unverified | none | A secondary-only claim that is actually wrong isn't flagged red |
| **[2] Disputed 🟡, Secondary-only 🔴** | Only-secondary sourcing must be fixed before publishing | More red rows on essays citing news coverage | Red becomes noisy and you start ignoring it |

- **Interim:** unchanged; the orchestrating agent picks a tier ad hoc.

### Q-032 · self-eval-rubric-outside-repo
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** OPEN

self-eval requires `docs/evaluation-rubric.md`, which exists only in this repo; `link-claude-home.sh` doesn't install `docs/`, and `guides/cross-project-setup.md` calls self-eval "standalone". In another project it has no rubric. Ship it or scope it?

- **Read:** `skills/self-eval/SKILL.md:50`, `devcontainer-config/link-claude-home.sh:47`

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Ship the rubric with the skill** | Move it to `skills/self-eval/references/` | One copy must stay canonical (the SI loop reads `docs/`) | Two copies drift if both are kept |
| **[2] Declare self-eval repo-only** | Skill stops with a clear message when the rubric is missing; the guide stops calling it standalone | none | You lose self-eval in other projects |

- **Interim:** unchanged.

### Q-033 · claude-api-flat-file
**Needs:** you: judgment · **Opened:** 2026-09-18 · **Status:** OPEN

`skills/claude-api.md` is a flat file, so the harness never loads it as a skill (skills load from `skills/<name>/SKILL.md`), and its body is four lines with none of the reference material its description promises. Archive or build?

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Archive it** | Move to `archive/` per the archive-don't-delete rule | none | You wanted the supplement and it's gone from view |
| **[2] Make it a real skill** | `skills/claude-api/SKILL.md` with real content | Content to write and keep current against the bundled skill | It shadows or conflicts with the bundled `claude-api` skill |

- **Interim:** unchanged; it is inert.

