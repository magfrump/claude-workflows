# DD — closing R1: `install.sh` sits outside every gate that covers its siblings

- **Goal**: decide how (or whether) to bring `devcontainer-config/install.sh` — host-executed, agent-writable, and the file that decides which diff the human reviews — under a gate.
- **Project state**: `main`, no feature branch · closing the last open item in `docs/working/questions.md` (four review findings needing a human call) · not blocked, but R1's leading fix is sequenced behind A7.
- **Task status**: in-progress (diverge/diagnose/match complete, awaiting Path-B decision)

## Context

2026-09-12 code review (`docs/reviews/code-review-rubric-2026-09-12-main-questions-closeout.md`), finding R1 🔴.
Facts as established there and re-verified here:

- `install.sh` runs on the **host**, from inside a repo that agent sessions bind-mount read-write.
- Not in `PAYLOAD` (`install.sh:25`) → the `diff -ru` loop at `:83-99` never shows changes to itself.
- Not in `enforcement_files()` (`cc-isolated.sh:107-130`) → not manifest-hashed, not in the config hash.
- Not in `live-verify-gate.sh:57`'s enforcement regex → commit `8980861` modified it with no `Live-verified:` trailer.
- Its own header (`:7-14`) says "edits here are inert", which is true of every `PAYLOAD` entry and **false of this file**.

Pre-existing structural exposure; the 2026-09-12 diff is what put it in scope.

## Step 1.0 — Pre-generation grep

`grep -B1 -A20 "Pruned candidates" docs/decisions/*.md | rg -i "install|bless|gate|boundary|hash|manifest|verify"`
Matches in 015, 016, 017, 021, 028, 030, 031. Two are in scope (both boundary-*distribution* decisions):

- `[carried from 016-multi-project-devcontainer-central-config [4] hybrid central + blessed override]`: *"covers 6/6 but pays for two code paths and two trust regimes, and its override path re-opens exactly the agent-writable surface [3] was chosen to eliminate."* → carried forward as soft constraint S2 below; it is why candidates 6 and 13 (two reviewers, two paths) are pruned rather than re-proposed on their merits.
- `[carried from 016 [11] raw CLI]`: *"buys portability by deleting the trust manifest and the boundary probe; 015's failure-driven mitigation is explicit that a silently-degrading boundary is worse than none."* → carried forward; it is why candidate 1 (pure do-nothing, leaving the false header in place) cannot be the whole answer.
- `[carried from 015-cc-process-isolation-docker-devcontainer]` failure-driven mitigation: *"a boundary that silently degrades is worse than none"* → hard constraint H5 (the header must stop asserting inertness) derives from it directly.

## Step 1 — Diverge (14 candidates)

0. **Status quo as designed** (016/022/023): install.sh's diff-and-bless *is* the human gate; the human reading it is the trust anchor.
1. **Do nothing**, close R1 as accepted residual with an entry in `docs/reviews/override-log.md`.
2. **Docs-only**: rewrite the header's "edits here are inert" to name install.sh as the exception and say what the real gate is.
3. **Commit-time gate**: add `install\.sh` to `hooks/live-verify-gate.sh:57`'s enforcement regex, so a commit touching it needs a `Live-verified:` trailer.
4. **Self-diff**: install.sh records a copy of itself at `$DEST/.install.sh.last` and diffs repo-vs-recorded above the `[y/N]` prompt.
5. **Self-diff + manifest**: 4, plus the recorded copy joins `enforcement_files()` so it is hashed and baked into the config hash.
6. **Shim**: repo `install.sh` becomes a thin exec'er of the *installed* (hashed, non-bind-mounted) reviewer in `$DEST`.
7. **Move it off the repo**: the installer lives on the host outside every bind mount; the repo carries payload only.
8. **Provenance print**: install.sh prints `git log -1 --stat -- install.sh` plus a dirty-worktree warning immediately above the prompt.
9. **Ideal-if-free**: detached signature over the manifest with a key held outside the container; the host refuses an unsigned install.
10. **Naive**: make the repo copy root-owned `0444` so `node` cannot edit it.
11. **Social**: a checklist line in README/`guides/devcontainer-setup.md` — "always `git diff -- devcontainer-config/install.sh` before installing". No code.
12. **Time-shift**: treat R1 as blocked on A7 — install the hook first, land the regex change in the same commit.
13. **Reframe**: move the diff-and-prompt into `cc-isolated.sh --bless` (installed and hashed); install.sh only copies.
14. **Detection**: a tracked `install.sh.sha256` checked by a pre-commit/bats guard, so any edit surfaces as a second diff.

**Generation health check.** Clustering flagged: 3/4/5/6/13 all sit in one region ("where does the review happen"), so 7/9/10 (ownership of the file), 11 (procedural), 12 (sequencing) and 14 (detection) were added to move on different dimensions. Do-nothing present (1), minimal-change present (2), ideal-if-free present (9), naive present (10), newcomer-flavoured present (14). Lenses represented: technical (3–7, 9, 13, 14), procedural (11, 12), social (11), time-shifted (12), reframe (1, 2, 13). Dimension check passes — enforcement *location*, file *ownership*, *sequencing* and *documentation* are four distinct levers, not four variants of one.

## Step 2 — Diagnose (7 constraints: 5 hard · 2 soft)

- **H1 (hard)** — An agent-authored edit to `install.sh` must become visible to the human before that edit executes on the host.
  `success:` given a commit that modifies `devcontainer-config/install.sh`, a human following only the documented flow (edit → commit → run install.sh → read → bless) sees a concrete artifact naming the change: a blocked commit, a diff hunk above the prompt, or a printed notice. Checkable by a bats case that drives the flow with a modified install.sh and asserts the artifact appears.
- **H2 (hard)** — The mechanism must not depend on `install.sh` being honest about itself.
  `success:` the enforcing code lives in a file that a running agent session cannot make effective without a human-gated step. Concretely: the file is served from the root-owned `0555` image payload (`/opt/claude-workflows`, decision 022), so an in-session edit to the repo copy does not change the code that runs until install.sh + rebuild + bless.
- **H3 (hard)** — No contortion of the installed-manifest model. `install.sh:24` states it is not installed; the manifest hashes what the launcher reads.
  `success:` `bats test/` fast suite stays green (`1..623`, 0 `not ok`), no new file appears under `$DEST` that install.sh does not own and re-write on every run, and the `PAYLOAD ⊆ enforcement_files()` test still passes unchanged.
- **H5 (hard)** — The header must stop asserting a property this file does not have.
  `success:` `grep -n "edits here are inert" devcontainer-config/install.sh` returns a line whose surrounding sentence names install.sh as the exception, or returns nothing.
- **H7 (hard)** — Verifiable from this sandbox, which has no Docker and no host.
  `success:` every behavioural change ships with at least one bats case that passes in the current sandbox (`bats test/` with no container, no network).
- **S1 (soft)** — Cost proportionate to a pre-existing, solo-dev, single-host exposure with no external attacker in the threat model.
- **S2 (soft)** — One trust regime, not two [carried from 016 [4]]: no second reviewer, no second code path, no override lane.

## Step 3 — Match and prune

| # | Approach | H1 visible | H2 not self-trusting | H3 manifest | H5 docs | H7 testable | S1 cost | S2 one regime |
|---|---|---|---|---|---|---|---|---|
| 0 | status quo | ~ | ✗ | ✓ | ✗ | ✓ | ● | ✓ |
| 1 | do nothing + override log | ~ | ✗ | ✓ | ✗ | ✓ | ● | ✓ |
| 2 | docs-only | ~ | ✗ | ✓ | ✓ | ✓ | ● | ✓ |
| 3 | commit-time regex | ✓ | ✓ | ✓ | ~ | ✓ | ● | ✓ |
| 4 | self-diff | ✓ | ✗ | ~ | ~ | ✓ | ◐ | ✓ |
| 5 | self-diff + manifest | ✓ | ✗ | ⚠ | ~ | ◐ | ○ | ~ |
| 6 | shim to installed reviewer | ✓ | ✓ | ~ | ~ | ◐ | ○ | ✗ |
| 7 | move off the repo | ✓ | ✓ | ✓ | ✓ | ✗ | ○ | ✗ |
| 8 | provenance print | ✓ | ✗ | ✓ | ~ | ✓ | ● | ✓ |
| 9 | signed manifest | ✓ | ✓ | ~ | ✓ | ✗ | ○ | ✗ |
| 10 | root-owned 0444 | ~ | ✓ | ✓ | ✗ | ⚠ | ◐ | ✗ |
| 11 | social checklist | ~ | ✗ | ✓ | ✓ | ✗ | ● | ✓ |
| 12 | sequence behind A7 | — | — | — | — | — | — | — |
| 13 | review moves to --bless | ⚠ | ✓ | ~ | ~ | ◐ | ○ | ✗ |
| 14 | tracked sha256 + guard | ~ | ✗ | ✓ | ~ | ✓ | ◐ | ~ |

Pruned and why:

- **[0]/[1]** — ✗ on H5: both leave the header asserting inertness for a file that is not inert, which is exactly 015's *"a boundary that silently degrades is worse than none"*.
- **[5]** — ⚠ on H3: installing a copy of a file whose header says it is not installed, and re-blessing on every install-script edit, buys nothing over [4] because the threat is the host-side *execution*, not the installed bytes.
- **[6]/[13]** — ✗ on S2 [carried from 016 [4]]: two reviewers, two code paths. [13] additionally takes ⚠ on H1 — `--bless` runs *after* the `cp -r`, so its review would happen after the mutation it is supposed to gate.
- **[9]** — ✗ on H7 and no key infrastructure on this host; kept as the ideal-if-free space-widener.
- **[10]** — ⚠ on H7/usability: a root-owned `0444` file inside a git worktree breaks `git checkout`/`git stash` for the very human it protects, and the repo is bind-mounted rw so the ownership would have to be maintained host-side out of band.
- **[11]** — ✗ on H7 and only ~ on H1: a checklist is not an artifact the flow produces.
- **[14]** — ~ on H1 and ✗ on H2: the checker is a repo file the same session can edit, so it reduces to [4] with more ritual.
- **[12]** — not a rival; **absorbed** as a sequencing requirement on whichever candidate wins (the hook is declared in `hooks/wiring.json:62-72` but absent from live settings — finding A7 — so any hook-based fix is inert until A7 lands).
- **[2]** — not a rival; **absorbed** into every survivor as a required sub-fix, the same way 016 absorbed its `[1] loud-fail guard`. H5 is a hard constraint no enforcement candidate satisfies on its own.

**Survivors: [3] [8] [4] [7].**

Fix sketches for survivor weaknesses:

- **[3]** on H5: absorbed [2] closes it. On the regex comment (`live-verify-gate.sh:55-56` says the set is "what `enforcement_files()` hashes"): reword to "the enforcement set, plus install.sh, which gates the review itself" so the stated correspondence stays true.
- **[8]** on H2: unfixable in kind — it is install.sh talking about install.sh. Its value is that it costs almost nothing and covers the one path [3] misses (see the failure-driven move in step 4).
- **[4]** on H3: keep the recorded copy as a dotfile install.sh rewrites on every run, never in `PAYLOAD`, never in the manifest.
- **[7]** on H7/S2: no in-sandbox verification path at all, and it splits the canonical-config-is-committed property 016 chose.

## Step 4 — Tradeoff matrix, stress test, decision

| # | Approach | Effort | Risk | Hard coverage | Key downside |
|---|---|---|---|---|---|
| 3 | commit-time regex (+[2], behind A7) | ~30 min: one regex alternation, one comment reword, 2 bats cases | low | 5/5 | fires only on container-session commits; a host-side commit is unreached (mitig. — pair with [8]) |
| 8 | provenance print | ~1 h | med | 4/5 | install.sh vouching for install.sh; a prose notice, not a diff |
| 4 | self-diff against recorded copy | ~2 h | med | 4/5 | same self-reference as [8], at 4× the code and a new dotfile in `$DEST` |
| 7 | move the installer off the repo | ~half day + migration | high | 4/5 | unverifiable from this sandbox; splits 016's canonical-config-is-committed property |

Falsifiable hypotheses:

- **[3]** — If we add `install\.sh` to the gate regex, we expect the next in-session commit touching `devcontainer-config/install.sh` to be blocked pending a `Live-verified:` trailer, within the first such commit after A7 lands; counter-evidence = a commit touching it lands with no trailer and no block.
- **[8]** — If install.sh prints its own provenance, we expect every install run where the file differs from the last-installed revision to display a non-empty "install.sh changed" notice, from the first host run; counter-evidence = an install where install.sh had changed and the prompt showed nothing.
- **[4]** — If install.sh self-diffs against a recorded copy, we expect the first post-change install to show a non-empty hunk for install.sh above the prompt, on the first host run; counter-evidence = a changed install.sh producing an empty self-diff (recorded copy stale, or written after the diff).
- **[7]** — If the installer moves out of the bind mount, we expect zero agent-authored edits to it thereafter, measured over the following month; counter-evidence = the repo re-acquires a convenience copy, or host/repo drift appears within that month.

Stress-test moves applied:

- **Boring alternative** (applied to the field) → the boring version is [2] docs-only, and it was tested rather than assumed: it leaves H1 and H2 unmet, so it is not sufficient alone. It *is* cheap enough to be absorbed into every survivor, which is what step 3 did. No matrix change beyond the absorption.
- **Failure-driven** (applied to [3]) → enumerated a new failure category the compatibility matrix missed: `live-verify-gate.sh` is a PreToolUse/Bash hook, so it sees only commits made *through a hooked container session*. `install.sh` is by definition the host-side file; a commit authored at the host shell, or in a session that unwired its hooks (decision 023 is explicit that the wiring is "a default, not a boundary" — the merged `settings.json` stays node-writable), never trips it. **Mitigation: pair [3] with [8]**, whose print runs on the host at the exact moment [3] has no reach. [3]'s risk stays low, but its key downside gains the `(mitig.)` tag and the recommendation becomes [3] + [8] rather than [3] alone.
- **Organizational survival** (applied to [3]) → the `Live-verified:` trailer ritual already exists for six sibling files under decision 45, and `git log --grep 'Live-verified: no'` is already the documented debt list. Adding a seventh file costs no new habit and no new concept; a future maintainer meets the mechanism in `guides/devcontainer-setup.md` where it is already explained. No matrix change — this is why [3]'s risk is rated low rather than medium.
- **Invert the thesis** (applied to [7], the strongest rival) → argued sincerely: [7] is the only candidate that removes the exposure rather than reporting it, and "the reviewer must not live where the reviewed can write" is the correct principle. What survives the inversion: it does not survive H7 — nothing about it can be checked from this sandbox, so it would ship unverified against a threat model with no external attacker. What it exposes about [3]: [3] does not *close* the exposure, it makes an edit **loud**. That is a real concession and is recorded as [3]'s residual, not hidden. [7] stays on the table as a revisit trigger if the host ever gains a second operator.
