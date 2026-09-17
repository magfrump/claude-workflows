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
| [Q-009](#q-009--live-verify-gate-not-installed) | you: judgment | Review finding A7 — `live-verify-gate.sh` is declared but not installed, so no `devcontainer-config/` cha... | 2026-09-12 |
| [Q-020](#q-020--asks-unit-weighting) | you: judgment | Is `asks` (triage §3.3) the right unit, or does it undercount one hard judgment against several easy ones? | 2026-09-17 |
| [Q-021](#q-021--drop-delete-or-archive) | you: judgment | Should DROP items be deleted or archived? | 2026-09-17 |
| [Q-022](#q-022--lite-review-findings-invariant) | you: judgment | Review findings A5 + A6 + X1 — `parse_findings` has no invariant that a line inside the FINDINGS block is... | 2026-09-17 |
| [Q-011](#q-011--mathlib-cache-host) | you: terminal | What is the current mathlib olean cache hostname? (`lake exe cache get` is minutes vs hours per repo.) | 2026-09-12 |
| [Q-019](#q-019--worktree-cleanup) | you: terminal | Reclaim the 231 MB under `.claude/worktrees/` — you approved deleting the merged ones, but the sandbox bl... | 2026-09-17 |
| [Q-012](#q-012--elan-sha256-pins) | deferred | Pin the per-arch SHA-256 of the elan release as build ARGs | 2026-09-12 |
| [Q-014](#q-014--profile-replace-only) | trigger | Should `--profile` stay replace-only, or grow `--add-profile`/`--remove-profile`? | 2026-09-15 |
| [Q-016](#q-016--scholar-oa-escape-hatch) | trigger | Does `scholar` need a companion escape hatch for publisher-hosted OA PDFs? | 2026-09-17 |
<!-- index:end -->

## Open

### Q-009 · live-verify-gate-not-installed
**Needs:** you: judgment · **Opened:** 2026-09-12 · **Status:** OPEN

Review finding A7 — `live-verify-gate.sh` is declared but not installed, so no `devcontainer-config/` change is actually gated. Install it, drop the declaration, or leave the gap open?

- **Why it's yours:** the fix edits the live `settings.json`, which is deny-listed to me. You are the only one who can make it, and whether to run a PreToolUse gate on every Bash call is a working-comfort call, not a correctness one.
- **Read:** `docs/reviews/code-review-rubric-2026-09-12-main-questions-closeout.md` (finding A7, row 28) · `hooks/wiring.json:62-72` · `hooks/live-verify-gate.sh` · `docs/decisions/035-install-sh-gating.md`
- **Blocks:** R1's fix. Decision 035 chose option [3], the commit-time regex, and it lands *with* A7 — so R1 is decided but cannot ship until this is.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Install it** | Add the `wiring.json:62-72` entry to live settings; 11 existing bats tests already cover the script's behaviour | One edit; then a gate runs on Bash calls touching `devcontainer-config/` | A gate you find noisy — reversible by deleting the entry |
| **[2] Drop the declaration** | Delete it from `wiring.json`; accept that `devcontainer-config/` changes are ungated | None | R1's chosen fix loses its enforcement half, and 035 needs revisiting |
| **[3] Leave as-is** | Declared but not installed | None now | The current state: eleven tests pass, nothing is enforced, and the declaration reads as protection that does not exist |

- **Interim:** [3], unchanged since 2026-09-12 — not a choice, just the absence of one.
- **If the answer differs:** [1] also closes the "nothing tests that it is installed" gap the review named; that test is worth adding either way if the declaration stays.

### Q-022 · lite-review-findings-invariant
**Needs:** you: judgment · **Opened:** 2026-09-17 · **Status:** OPEN

Review findings A5 + A6 + X1 — `parse_findings` has no invariant that a line inside the FINDINGS block is either a well-formed row or the `NONE` sentinel. Add one, or patch the two symptoms separately?

- **Why it's yours:** the two obvious one-liners pull in opposite directions, so this cannot be fixed one finding at a time. Which way it resolves is a call about how much a clean review is allowed to mean.
- **Read:** `docs/reviews/code-review-rubric-2026-09-12-main-questions-closeout.md` (rows 26, 27, 36 — A5, A6, X1) · `scripts/lite-review.py:86-108,196` · `test/lite-review-grammar.bats:94-95`
- **The two symptoms, one root:** A5 — a model refusal (`"I cannot emit FINDINGS for this diff."`) parses as `parse_ok=True`, 0 rows, so `main()` prints `FINDINGS: NONE`, exit 0, and the review-fix loop reads it as a clean pass. A6 — `FINDING_RE` backtracks catastrophically on a solid whitespace run inside the block: 16,000 chars took **877 s** measured, ~7.9× per doubling, a hang rather than a slow parse. X1 — both exist because unmatched lines are silently skipped.

| Option | What it means | Consequence |
|---|---|---|
| **[1] Reject the block** *(closes all three)* | A line inside FINDINGS that matches neither a row nor the sentinel makes the parse fail | A refusal stops reading as clean; prose never reaches the regex, so A6's input is gone too. Strictest, and the only one X1 endorses. |
| **[2] Performance's one-liner** | `if "\|" not in line: continue` | Fixes A6 by skipping non-row lines *more* silently — which makes A5 worse. |
| **[3] Security's one-liner** | Reject unparseable lines | Fixes A5; leaves the regex reachable by anything containing a pipe. |
| **[4] Leave it** | Tests 6/7 currently pin the present behaviour as normative | The hang is unreachable on this cold, single-call, self-fed path today — which is why it is Medium and not High. |

- **Interim:** [4]. The path no attacker supplies and no caller feeds cold input to, so nothing is burning.
- **If the answer differs:** [1] needs tests 6/7 in `test/lite-review-grammar.bats` re-pinned, since they currently assert the behaviour it removes.
- **Note:** this was bundled with A7 in a single entry until 2026-09-17; splitting it is why it now has its own ID.

### Q-011 · mathlib-cache-host
**Needs:** you: terminal · **Opened:** 2026-09-12 · **Status:** OPEN

What is the current mathlib olean cache hostname? (`lake exe cache get` is minutes vs hours per repo.)

- **Attempt 2026-09-17 — inconclusive, my fault not yours.** The probe returned `Cache/Requests.lean: No such file or directory`. The command needs a **mathlib4 checkout** as its working directory; I gave it without saying so, and it ran against a container that has Lean installed but no mathlib source tree. Not evidence about the hostname either way.
- **Read:** `devcontainer-config/egress/lean.txt` (the `lakecache.blob.core.windows.net` entry and its ACCEPTED RISK note)
- **The paste**, once you are somewhere with a mathlib4 clone:

```bash
git clone --depth 1 https://github.com/leanprover-community/mathlib4 /tmp/mathlib4 2>/dev/null
rg -o 'https://[^"]*' /tmp/mathlib4/Cache/Requests.lean
```

- **Interim:** `lakecache.blob.core.windows.net` stays listed, carrying its VERIFY comment. A wrong entry degrades to "stays blocked", never to a wider allowlist, so the cost of being wrong is a slow first build rather than an exposure.
- **If the answer differs:** correct `egress/lean.txt`, re-install, re-bless.

### Q-012 · elan-sha256-pins
**Needs:** deferred · **Opened:** 2026-09-12 · **Status:** OPEN

Pin the per-arch SHA-256 of the elan release as build ARGs

- **Context:** the new Dockerfile layer fetches elan from its GitHub release without a checksum, following the rustup layer's documented deferral (the authoring environment cannot reach the host to obtain the digests)
- **Interim:** version-pinned, unverified — bounded by running at build time, but this layer installs into a node-writable tree, so the pin is worth more here than in the rustup layer
- **If the answer differs:** add `ELAN_SHA256_AMD64`/`ELAN_SHA256_ARM64` ARGs and a `sha256sum -c` at the next host-side `ELAN_VERSION` bump, matching the shfmt and .NET layers.

### Q-014 · profile-replace-only
**Needs:** trigger · **Opened:** 2026-09-15 · **Status:** OPEN

Should `--profile` stay replace-only, or grow `--add-profile`/`--remove-profile`?

- **Context:** `register_project` overwrites the stored grant, so re-registering a project to add `lean` silently dropped the `dotnet` it already had; found while trying to get the `lean` profile into a live container
- **Interim:** kept replace (a grant you can only widen is not a grant) and made it loud instead — the transition and any dropped profile are printed, `--list` already showed the current grant, and the line-10 comment no longer says "widen"
- **If the answer differs:** if you find yourself re-typing the full list often, add the two additive flags rather than changing what `--profile` means.

### Q-016 · scholar-oa-escape-hatch
**Needs:** trigger · **Opened:** 2026-09-17 · **Status:** OPEN

Does `scholar` need a companion escape hatch for publisher-hosted OA PDFs?

- **Context:** the profile's honest limit is that Unpaywall/Crossref routinely return full-text URLs on hosts the SNI proxy rejects (publisher domains, institutional repositories, S3 buckets), so a literature-review session gets metadata for everything and bytes for the arXiv/PMC/bioRxiv subset only
- **Interim:** no escape hatch — documented as a failure mode in `guides/cc-isolated-usage.md` rather than widened, since the alternative is a per-paper, per-publisher allowlist churn that nobody will maintain
- **If the answer differs:** if this bites in practice, the shapes are (a) a narrow `scholar-extra` profile listing the two or three publishers you actually read, or (b) fetching those PDFs on the host and dropping them into the workspace, which needs no boundary change at all.

### Q-019 · worktree-cleanup
**Needs:** you: terminal · **Opened:** 2026-09-17 · **Status:** OPEN

Reclaim the 231 MB under `.claude/worktrees/` — you approved deleting the merged ones, but the sandbox blocks me from doing it.

- **Answered in part 2026-09-17:** "Do delete worktrees whose work is merged." Acted on as far as I can: merged status is established below. `git worktree remove` and `git branch -d` are both refused by the permission classifier, so the deletion itself is yours.
- **Merged, safe to delete (5):** `worktree-agent-a009cad5cfce1c436`, `-a08e604dfe89c164a`, `-a4a18886714e71f87`, `-a6de5e054c0c183fc`, `-ad3ea139c0500baba` — each is an ancestor of `main`.
- **Not verifiable (6):** `archive-stale-docs`, `cross-model-review-sweep`, `e7-rep23-ledger`, `fact-check-codereview-writeup`, `ledger-cubic-column`, `python-toolchain-uv`. Their branch refs no longer exist (`HEAD` reads `0000000`), so "is it merged" cannot be answered — these are orphaned registrations, not work. Their large `git status` counts are an artifact of the unresolvable HEAD, not uncommitted changes.
- **The paste:**

```bash
cd /workspace
for b in a009cad5cfce1c436 a08e604dfe89c164a a4a18886714e71f87 a6de5e054c0c183fc ad3ea139c0500baba; do
  git worktree remove --force ".claude/worktrees/agent-$b" && git branch -d "worktree-agent-$b"
done
git worktree prune          # clears the 6 orphaned registrations
du -sh .claude/worktrees    # expect well under 231M
```

- **If the answer differs:** if you want the 6 orphans kept, drop the `prune` line — but nothing references them and their branches are already gone.

### Q-020 · asks-unit-weighting
**Needs:** you: judgment · **Opened:** 2026-09-17 · **Status:** OPEN

Is `asks` (triage §3.3) the right unit, or does it undercount one hard judgment against several easy ones?

- **Context:** today's 5 asks range from a one-bit call to a four-part review decision
- **Interim:** counting items, not weight, because assigning weight is itself a judgment and therefore itself an ask
- **If the answer differs:** entries carry a coarse S/M/L and the alarm threshold becomes a sum.

### Q-021 · drop-delete-or-archive
**Needs:** you: judgment · **Opened:** 2026-09-17 · **Status:** OPEN

Should DROP items be deleted or archived?

- **Context:** `docs/working/incident-journal.md` is dormant-because-unfed rather than wrong — deleting it loses a schema someone designed
- **Interim:** propose deletion, do not delete
- **If the answer differs:** if archive, DROP needs a destination and the route stops being free.
