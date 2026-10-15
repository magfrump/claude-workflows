Commit: 8ab42eec

# Security Review — chore/q180-repin-pastes, iteration 2 (confirming pass over 8ab42eec)

**Scope:** `git diff 46342d66..8ab42eec -- docs/working docs/roadmap.md`: the guard line, now the same in Q-162, Q-163 and Q-164; the merge flags; Q-162's new prose; Q-169's `git -C`; Q-180's Resolved line in `questions-archive.md`. Context: `git diff main...8ab42eec`.
**Date:** 2026-10-15
**Based on:** iteration-1 security review `docs/reviews/security-review-2026-10-15-q180.md` (F1–F4) and rubric `docs/reviews/code-review-rubric-2026-10-15-chore-q180-repin-pastes.md`. No iteration-2 fact-check report was provided, so claims about security properties were checked here by execution.
**Probes:** `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/security-q180-i2/`. Git 2.39.5, bash and zsh.
- `harness.sh SHELL CASE PASTE` builds a fresh planted copy of `base/` and runs the paste text taken from `git show 8ab42eec:docs/working/questions.md`. Only `cd /workspace` and the pinned hashes are substituted.
- `seq.sh` runs the full pastes on a scratch clone of /workspace.
- `*.log` are the plant logs.

## Trust Boundary Map

```
B1: agent session (same uid) → writes /workspace/.git (config, info/, objects/, refs/, hooks/) → the guard's and the paste's git calls read it
B2: agent session            → writes the container's shell startup (rc files, exported GIT_* variables) → the shell that runs the paste
B3: /workspace/.git          → bind mount of /home/magfrump/claude-workflows (mountinfo, re-read) → host-side git (Q-169, any git-aware prompt)
B4: commit on main after the paste → install.sh / later host pastes read from main → host
B5 (new): the paste's own trailing git calls (worktree remove, branch -d, merge --abort) and a tty-attached merge → run hooks and pagers named by B1 state, after the guard and after the reviewed merge
```

Input sources:

```
S1: repo config (local, worktree, include, GIT_CONFIG_COUNT)  — runtime-mutable — UNTRUSTED for exec sinks (drivers, filters, fsmonitor, gpg, pager.<cmd>)
S2: .git/info/{attributes,grafts}, shallow, alternates        — runtime-mutable — UNTRUSTED for merge content/history
S3: object store (loose, packs, commit-graph)                 — runtime-mutable — UNTRUSTED for content
S4: refs/heads/main                                           — runtime-mutable — UNTRUSTED for the base and for what lands after the merge
S5: shell startup / exported environment                      — runtime-mutable — UNTRUSTED (conceded by the prose)
S6: .git/hooks/* (default hooks directory, no config needed)  — runtime-mutable — UNTRUSTED for exec sinks
S7: pinned hashes in the paste text                           — code-constant (when read from a reviewed commit) — trusted for the merged side only
```

The asset is still the integrity of what lands on main (B4). 8ab42eec moves S1–S3 behind the guard. That leaves S6, and one S1 key class, `pager.<cmd>`. Both are read by commands that run **after** the guard, during or after the reviewed merge. They break the new sentence "So the merged side is the reviewed commit" in a way the prose's stated mitigations (no agent running, a log check beforehand) cannot catch.

## Iteration-1 findings: closure status

| i1 | Claim in 8ab42eec | Status | Evidence |
|---|---|---|---|
| F1 | Guard swapped in, all three pastes; `core.commitGraph=false` on merge | **Closed for the listed classes** | The guard line is byte-identical at lines 89, 118 and 150 (`uniq -c` → 3), and identical to the guard i1 executed (`diff` against `security-q180/guard.txt`). Re-run from the shipped text in bash and zsh, it refused all of these, with no plant run and main unmoved: merge driver + info/attributes; filter; `Filter.X.smudge` (mixed case); include; includeIf→fsmonitor; core.fsmonitor; `core.FsMonitor`; gpg; partialClone; promisor; core.attributesFile; empty info/attributes; alternates; grafts; empty and dangling `shallow`; replace ref; rewritten loose blob; **rewritten object in a pack with a matching .idx** (i1 untested: `cat-file` served `PACKTAMPER`, fsck: "packed b478… is corrupt"); GIT_CONFIG_COUNT fsmonitor; `config.worktree` filter + attributesFile; `diff.x.textconv`; grafts and a `--worktree` fsmonitor seen from a linked worktree. It passed clean in the main checkout and in a linked worktree, and read-only on the real `/workspace` (GUARD-PASS, 5 s, both shells). New gap: F-A below. |
| F2 | Prose names moved main, shell, running agent; log check | **Closed as worded**, but F-A adds a route the log check cannot see | Q-162 line 83 |
| F3 | Bind mount stated; Q-169 uses `git -C` | **Closed** | mountinfo `/home/magfrump/claude-workflows /workspace`. Q-169's line at 8ab42eec, run with HOME pointed at a scratch dir and `~/claude-workflows` pointing at a scratch clone, gave sha256 `032cc9a8…afb7`, 496 lines, in bash and zsh. The `cd` is gone. |
| F4 | "take the block from `git show main:…`" | **Partly closed** (Informational, F-C) | `main` is agent-movable by the prose's own account |

Other claims checked:
- **Read errors.** The `git config` exit status is unchecked (`test -z "$(…)"`). I found no case where `git config` fails while the merge proceeds. An unreadable include and a `~nosuchuser/` include each made every git call fatal, so the paste stops at `git branch --show-current`. The one case that blinds the config check is an exported `GIT_CONFIG` (F-B, shell residual).
- **fsck failing refuses.** Shown by the blob and packblob cases.
- **Nothing planted runs during the guard.** I planted all 30 hook names in `.git/hooks` and set `pager.{config,fsck,for-each-ref,rev-parse}`, then ran the guard under a pty: GUARD-PASS in both shells and no plant ran. The guard's own calls do not run hooks or pagers. Every execution in F-A comes from later calls.
- **Full sequence.** On a scratch clone of /workspace: Q-180 landed first (8ab42eec, `--no-ff`), then the shipped Q-162, then Q-163/Q-164 in both orders. All four runs (2 orders × 2 shells) gave tree `33a44633…`, a clean status and 4 first-parent merges. The second merge picked `6c841192` in each order. `git diff --stat 6c841192 HEAD` equals `git diff --stat b71a4e9e 8ab42eec` (10 files, +1528/−1032). Q-163 on main without Q-162 printed "Q-162's merge is not on main" and left HEAD at b71a4e9e.
- **Host claim.** "On the host this guard refuses anyway, because your global config sets `core.hooksPath`" is supported. `questions-archive.md:2746` says: "The host still reports `core.hooksPath=/home/magfrump/.config/git/hooks`, from the user's global `~/.gitconfig` (checked 2026-10-15 with `--show-scope`)". The container has no global hooksPath (`git config --global --get core.hooksPath` exit 1).

## Findings

#### F-A: Hooks in `.git/hooks` and `pager.merge`/`pager.worktree` run during the paste, after the guard. A planted one replaces the reviewed merge with a forged one that the log check cannot tell apart

**Severity:** Medium
**Location:** `docs/working/questions.md:83` (claim), `:89` (regexp), `:90-91` (Q-162 `merge --abort`, `worktree remove`, `branch -d`), `:121`, `:153` (Q-163/Q-164 merge and `merge --abort`)
**Boundary:** B5 (S6, S1), B4
**Move:** 11 (guardrail bypasses), 12 (sweep every git call), 3 (error path)
**Confidence:** High (executed, bash and zsh)
**Legibility-target:** for-author

Evidence (verbatim, line 83): "the merge also ignores replace refs and runs no hooks. So the merged side is the reviewed commit." Line 91: `for u in … ; do git worktree remove .claude/wt-build-loop-$u && git branch -d feat/build-loop-$u; done`. The `merge --abort` arms read `{ git merge --abort; echo "conflict: …`.

Only the merge carries `-c core.hooksPath=/dev/null`. The guard checks `core.hookspath` and `hook.` config, but not the default hooks directory (i1 called this T2; see Q-139 at `questions-archive.md:2750`). It also does not check `pager.<cmd>` keys. Executed:
- **Hooks.** `.git/hooks/reference-transaction` ran 5 times during Q-162's clean path (prepared, committed, aborted, prepared, committed, all from the `branch -d` loop). `post-index-change` ran once. On the conflict path, each paste's `git merge --abort` ran hooks 5 times.
- **Forged merge from a hook.** `forgehook.sh`, planted as reference-transaction, fires on the first `branch -d` after the user's merge. It writes a merge commit with the same message and the same parents (`be4654b`, `side`), and a tree equal to the reviewed tree plus `payload`. Then it runs `update-ref main` and `read-tree -u`. Result: `git log --oneline --first-parent` shows one merge with the expected message, `git show main:payload` prints `PAYLOAD`, `git status` is clean, and Q-163/Q-164's `merge-base --is-ancestor 09a2876f HEAD` still passes.
- **Pagers.** Under a pty (an interactive paste has one), a planted `pager.merge` and `pager.worktree` each ran once. `forgepager.sh` passes the merge output through, waits for EOF (the merge commit is then written), and forges the same way. Probe `h-pager-forge` (zsh): the paste printed "Merge made… Deleted branch…", and main held `PAYLOAD`. The shipped regexp does not match `pager.merge` (`--get-regexp` rc=1).

This differs from i1's F2 residuals in kind:
- It needs no running agent. The paste itself starts the planted code, so "Run it while no agent session or subagent is working" does not help.
- It acts after the pre-paste log check.
- The forged merge looks the same as the real one in the check the prose prescribes ("it should list only merges you made").

It reaches Q-162 on every run (the `branch -d` loop) and Q-162/Q-163/Q-164 through `pager.merge`. Each paste's abort arm is reached only on a failed merge.

**Recommendation:**
1. Add `-c core.hooksPath=/dev/null` to `git worktree remove`, `git branch -d` and each `git merge --abort` in all three pastes.
2. Add `pager\.` to the guard's regexp (or pass `--no-pager` to `merge` and `worktree`).

Tested on Q-162 (`p162-full.txt`) and on Q-163's abort arm (`p163-fixed.txt`), in bash and zsh, with the regexp change applied to Q-162 only. Hooks and the forged merge from a hook: no plant ran, and the reviewed merge landed. `pager.merge` under a pty: refused ("… driver config … present: stop"), main unmoved. Clean repo: passes and merges. Then narrow line 83 to "the paste runs no hooks or pagers".

#### F-B: An exported `GIT_CONFIG` blinds the config check while the merge still reads the planted keys

**Severity:** Informational (inside the residual the prose already concedes)
**Location:** `docs/working/questions.md:83` ("an alias for `git` or `test` defeats any guard written into a paste"), `:89`
**Boundary:** B2 (S5)
**Move:** 2, 11
**Confidence:** High (executed)
**Legibility-target:** for-author

With `GIT_CONFIG=/dev/null` in the environment, `git config --get-regexp` reads only that file, but `git merge` reads the repo config. The planted filter + `core.attributesFile` passed the guard and ran during the merge (`gitconfigenv`, `PLANT-RAN(1x)`, both shells). Exported `GIT_GRAFT_FILE`, `GIT_OBJECT_DIRECTORY` and `GIT_ALTERNATE_OBJECT_DIRECTORIES` act the same way (`scripts/build-loop.sh` caller_gate lists them; not executed here). This is shell trust, which line 83 concedes. Its example ("an alias") suggests something visible, though, and an exported variable in an rc file is as cheap to plant and less conspicuous.

**Recommendation:** optional wording: "an alias, function or exported `GIT_*` variable in that shell defeats any guard written into a paste". No code change: `unset` can itself be aliased.

#### F-C: "take the block from `git show main:…`" anchors trust on a ref the prose says an agent can move

**Severity:** Informational
**Location:** `docs/working/questions.md:83`
**Boundary:** B1 (S4), B3
**Move:** 2
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence: "take the block from the committed text (`git show main:docs/working/questions.md`), not the working tree an agent can edit". The same paragraph says: "an agent that can commit there can put a change on main". This is better than the working tree, but the block, its pinned hashes and the log-check instruction all come from the same agent-writable ref. The sentence also does not say where to run `git show`. The paragraph's "never in a host shell" most likely governs it. If it is run on the host after `cd ~/claude-workflows`, it repeats i1 F3's prompt/fsmonitor route.

**Recommendation:** name a reviewed hash in the orchestrator's relay (for example, Q-180's landing commit), and add "(in the container shell)". Pre-existing in kind; no change needed on this branch.

#### F-D: Q-180's Resolved line says the guard "refuses everything `scripts/build-loop.sh`'s state gate refuses". It does not refuse `log.showsignature`, origin/HEAD or the gate's environment checks

**Severity:** Informational
**Location:** `docs/working/questions-archive.md:2872`; compare `scripts/build-loop.sh:610`, `:628-631`, `:652-672`
**Boundary:** Internal (wording about B1 coverage)
**Move:** 11
**Confidence:** High (read-static)
**Legibility-target:** for-author

Evidence: "it now refuses everything `scripts/build-loop.sh`'s state gate refuses, plus `fsck.` keys and an object `git fsck` rejects". The paste regexp drops `log\.showsignature`, which i1 dropped deliberately because merge does not log. It also has no origin/HEAD check (default_gate/state_gate) and no stray-variable check (caller_gate). In the other direction it is broader: it reads all config scopes, including global, system and includes, where the gate reads `--file --no-includes`. Line 83's own list also omits `hook.`, `fsck.`, `core.attributesFile` and the partial-clone keys that the guard does refuse.

**Recommendation:** "refuses the state gate's config keys and files (less `log.showSignature`, which a merge does not read), plus …". If F-A is applied, add "pager".

## Untested bypass candidates

- **Crafted commit-graph.** fsck now runs with `core.commitGraph=false`, which also skips `commit-graph verify`. Q-163/Q-164's `merge-base --is-ancestor` selection and Q-162's `branch -d` merged-check read the graph. Worst cases by reading (not crafted): the selection picks the other reviewed hash or skips the Q-162-first stop (B contains 09a2876f either way), or `branch -d` deletes an unmerged `feat/build-loop-*` ref.
- **`gc.auto` → auto-maintenance after the merge.** One probe (`gc.auto=1`, `pre-auto-gc` hook) showed no plant run. I did not confirm that gc actually triggered, so the result is inconclusive. `gc.recentObjectsHook` (git ≥ 2.43) does not exist on the container's 2.39.5.
- **Working-tree `.gitattributes` with built-in `merge=union`/`binary`.** Q-164's second merge does content-merge `docs/working/questions.md` (both sides touch it once Q-180 has landed). It merged clean, so union does not change the result. Untested whether ort reads working-tree attributes here.
- **Planted `MERGE_HEAD`.** Not re-tested. It makes the merge refuse, and `merge --abort` then runs hooks (F-A's fix covers that).
- **Shell startup (F-B) and a concurrent writer.** Inherent to a paste.

The shipped guard has open candidates (above) and an executed bypass (F-A), so it does not appear under Endorsement Claims.

## Endorsement Claims

- **Claim:** The guard line is identical in Q-162, Q-163 and Q-164, and matches the guard i1 executed.
  **Location:** `docs/working/questions.md:89,118,150`
  **Evidence:** executed (`grep | uniq -c` → 3; `diff` against `security-q180/guard.txt` → none)
  **Verified:** the text at 8ab42eec
  **Not verified:** the text the user actually copies (F-C)
- **Claim:** From the shipped text, the guard refused 24 planted states and the rewritten pack object in bash and zsh, passed clean in the main checkout and a linked worktree, and ran no hook or pager itself.
  **Location:** `docs/working/questions.md:89`
  **Evidence:** executed (cases listed in the closure table)
  **Verified:** those states on git 2.39.5
  **Not verified:** the commit-graph, gc and attributes candidates above; other git versions
  **route: code-fact-check**
- **Claim:** With Q-180 landed first, Q-162, then Q-163/Q-164 in either order land tree `33a44633…`, which is 6c841192 plus exactly 8ab42eec's diff.
  **Location:** `docs/working/questions.md:88-90,117-121,149-153`
  **Evidence:** executed (`seq.sh`, 4 runs)
  **Verified:** a scratch clone of /workspace at b71a4e9e
  **Not verified:** a main that has moved past the Q-180 landing before the pastes
  **route: code-fact-check**
- **Claim:** Q-169's `git -C` extraction yields sha256 `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7` and leaves the shell's cwd outside the checkout.
  **Location:** `docs/working/questions.md:263-265`
  **Evidence:** executed (fake HOME, scratch clone, bash and zsh)
  **Verified:** that the output matches; the command has no `cd`
  **Not verified:** the user's host git version and prompt

## Primitive sweep

Primitive: git invocation that reads agent-writable repo state (can run config- or hooks-dir-named commands)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:88,117,149` `git branch --show-current` | S1, S4 | none | cleared: no hook or pager (allhooks probe) |
| `:89,118,150` guard's `for-each-ref`, `config`, `rev-parse`, `fsck` | S1–S3, S6 | — | cleared: 30 hooks + `pager.*` planted, none ran |
| `:90` Q-162 `git merge` | S1–S4, S6 | hooks off, no replace, no commit-graph, guard | **F-A** (`pager.merge` under a tty) |
| `:90` Q-162 `git merge --abort` | S6 | none | **F-A** (hooks ran 5×) |
| `:91` `git worktree remove` | S1, S6 | none | **F-A** (`pager.worktree` ran under a tty; post-index-change ran) |
| `:91` `git branch -d` | S3, S6 | none | **F-A** (reference-transaction; forged merge executed). Commit-graph untested |
| `:119-120,151-152` `merge-base --is-ancestor` | S3, S4 | replace refs refused | cleared: worst case is the other reviewed hash (commit-graph untested) |
| `:121,153` Q-163/Q-164 `git merge` | S1–S4, S6 | as Q-162 | **F-A** (`pager.merge`) |
| `:121,153` `git merge --abort` | S6 | none | **F-A** (hooks ran 5×) |
| `:263` Q-169 host `git -C … show` | S1, S3 | `useReplaceRefs=false`, sha256 | cleared (i1 probes r4/r7; no cwd change) |
| `:83` "`git show main:…`" (prose) | S4 | none | F-C |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F-A | Default-dir hooks and `pager.merge`/`pager.worktree` run in the paste after the guard; a forged, look-alike merge lands | Medium | B5, B4 | `questions.md:83,89,90-91,121,153` | High |
| F-B | Exported `GIT_CONFIG` blinds the config check (shell residual, wording) | Informational | B2 | `questions.md:83,89` | High |
| F-C | `git show main:` anchors on an agent-movable ref; where to run it is unstated | Informational | B1, B3 | `questions.md:83` | Medium |
| F-D | Resolved line overstates parity with the state gate; line 83's list under-lists the guard | Informational | Internal | `questions-archive.md:2872`, `questions.md:83` | High |

## Overall Assessment

8ab42eec closes i1's F1 and F3 as claimed. F2 is closed as worded, and F4 partly. The guard is the one i1 tested, shipped byte-identical three times. It refuses every planted class in the brief, plus a tampered pack object, and it runs nothing itself. The full pastes still land one tree in either order. The fix opens nothing new, but it states a property the paste does not have. The guard covers state read by the merge. It does not cover the paste's other git calls, or the merge's pager. A hook in `.git/hooks` or a `pager.merge` key, both planted ahead of time, replaces the reviewed merge with a forged one that has the same message and parents. That beats both the "no agent running" and the "check the log" mitigations, so "So the merged side is the reviewed commit" is false as written.

The fix is two text edits, executed here: hooks off on the trailing calls and the abort arms, and `pager\.` in the regexp. Then line 83 can keep its sentence. F-B to F-D are wording. Endorsement claims are executed and scoped as stated. The guard itself is not endorsed while F-A is open.

## Goal-Alignment Note

- Success criterion (restated verbatim): "a markdown report at the output path you were given, structured per your skill."
- Answered: yes, at `docs/reviews/security-review-2026-10-15-q180-i2.md`, first line `Commit: 8ab42eec`.
- User goal: run Q-162, Q-164 and Q-163 safely. They are safe to run once F-A's two edits land. As shipped, they are strictly safer than main's versions. The F-A route needs a hook or pager planted in advance, which today's `/workspace` does not have: there are no non-sample hooks and no `pager.*` keys (checked read-only).
- Probes: every command ran under `timeout` in the scratch dir; no process is left running (checked with `ps`); no worktree was created in /workspace; this report is the only repo file written.
