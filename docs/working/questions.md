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
| [Q-011](#q-011--mathlib-cache-host) | you: terminal | What is the current mathlib olean cache hostname? (`lake exe cache get` is minutes vs hours per repo.) | 2026-09-12 |
| [Q-027](#q-027--readme-wire-docs) | agent | `README.md` (lines 27-149) and `guides/claude-config-security-checkup.md:47` point at `docs/working/wire-*.... | 2026-09-18 |
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

### Q-027 · readme-wire-docs
**Needs:** agent · **Opened:** 2026-09-18 · **Status:** OPEN

`README.md` (lines 27-149) and `guides/claude-config-security-checkup.md:47` point at `docs/working/wire-*.md`, archived 2026-08-06 (9b0f583). Repoint them at `hooks/wiring.json` (decision 023) and move the bare-host and WSL2 notes somewhere tracked.

- **Interim:** links dangle in fresh clones. Not restored on 2026-09-18, because the wire docs predate `hooks/wiring.json` and would reintroduce stale steps.

