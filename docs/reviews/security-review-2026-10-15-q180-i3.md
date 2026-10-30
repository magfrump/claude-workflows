Commit: 5983f60e

# Security Review — chore/q180-repin-pastes, iteration 3 (confirming pass over 5983f60e)

**Scope:** `git diff 8ab42eec..5983f60e -- docs/working`. Q-162, Q-163 and Q-164 (`docs/working/questions.md` at 5983f60e) reviewed whole, as they now stand. Q-180's Resolved line (`questions-archive.md:2872`).
**Date:** 2026-10-15
**Based on:** rubric `docs/reviews/code-review-rubric-2026-10-15-chore-q180-repin-pastes.md` (B1–B7), iteration-2 review `security-review-2026-10-15-q180-i2.md` (F-A…F-D). No iteration-3 fact-check report was provided, so the security claims were checked here by execution.
**Probes:** `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/security-q180-i3/`. Git 2.39.5, bash and zsh, each paste run under a pty (`script -qec`). The paste text is taken from `git show 5983f60e:docs/working/questions.md` (`p162.txt`, `p163.txt`, `p164.txt`). The only substitution is `cd /workspace` → `cd "$R"`, a fresh clone of /workspace at b71a4e9e with the twelve `feat/build-loop-u3*/u4*` worktrees recreated.
- `seq3.sh SHELL ORDER VARIANT`: lands 5983f60e first, then runs Q-162, then Q-163 and Q-164 in ORDER.
- `b2.sh`: replace refs and pagers against the prose's `show` and `log` commands.
- `forge.sh`: the G-2 exploit.

## Trust Boundary Map

```
B1: agent session (same uid) → writes /workspace/.git (config, hooks/, info/, objects/, refs/) → the guard's and the paste's git calls read it
B2: agent session            → writes shell startup / exported env               → the shell that runs the paste (named residue)
B3: refs/heads/main          → agent-movable before the paste                    → base of the merge (named residue; the log check is the stated mitigation)
B4 (moved): the prose's pre-checks (`git -c core.useReplaceRefs=false show main:…`, `git --no-replace-objects log …`), typed at a tty → read B1 state (pager.*, core.pager) → the block the user copies and the log the user trusts
B5: the paste's trailing writes (merge --abort, worktree remove, branch -d)       → hooks named by B1 state → main after the reviewed merge
```

```
S1: repo config (incl. pager.<cmd>, core.pager)   — runtime-mutable — UNTRUSTED for exec sinks (pager, drivers, fsmonitor, gpg)
S2: .git/hooks/* (default dir)                     — runtime-mutable — UNTRUSTED for exec sinks
S3: refs/replace/*, info/*, shallow, objects       — runtime-mutable — UNTRUSTED for content/history
S4: refs/heads/main                                — runtime-mutable — UNTRUSTED for the base
S5: positional parameters of the paste's shell ($1) — shell state, normally empty — not attacker-chosen; used as a path
S6: pinned hashes in the paste text                — code-constant once read from a reviewed commit — trusted for the merged side only
```

5983f60e closes B5 (i2 F-A) as worded. It moves the trust anchor for S6 onto the B4 commands, but those commands spawn an S1-named pager before any guard runs (G-2). The B1 text edit also broke the cleanup loop's path argument (G-1).

## Iteration-2 rubric items: closure status

| Item | Status | Evidence (executed unless noted) |
|---|---|---|
| **B1** hooks/pagers after the guard | **Closed** | All 28 hook names were planted in `.git/hooks` as a logging wrapper, and the pastes ran under a pty: 2 shells × 2 orders. Plant log: `none` in every run. Each run landed tree `94d306ae9c566f1db4feac7d1ca9d72841f80252`, equal to `git merge-tree --write-tree 6c841192 <Q-180 landing>`, with 4 first-parent merges, a clean status and main unmoved by anything planted. With `pager.{merge,worktree,branch,config,fsck,for-each-ref,rev-parse,merge-base,log,show}` and `core.pager` also set, each of Q-162/Q-163/Q-164 printed "replace refs, grafts, shallow, attributes, alternates, driver config or a bad object present: stop": rc=1, plant `none`, main unmoved. Abort path (a conflicting override-log row committed on main first, all hooks planted): Q-162 printed `CONFLICT (content): Merge conflict in docs/reviews/override-log.md` and "conflict: merge aborted, nothing deleted", with no `MERGE_HEAD`, a clean status, plant `none`, and Q-163/Q-164 then "Q-162's merge is not on main". Every writing call carries `-c core.hooksPath=/dev/null` (`grep -o` → 5 sites). The guard line is byte-identical at lines 89, 118 and 150 (`uniq -c` → 3). **But** the same edit introduced G-1. |
| **B2** replace refs in the prose's commands | **Closed for replace refs**; G-2 opens a pager route in the same two commands | A replace ref planted on main's `questions.md` blob and another on HEAD: plain `git show` gave sha `2a93358a4d81` (forged), the prose's `git -c core.useReplaceRefs=false show` gave `9d6311580c7a` (real). Plain `git log` printed `FORGED`, the prose's `git --no-replace-objects log` printed `land q180`. Bash and zsh. |
| **B3** Resolved line | Accurate | "three … rebuilt … and `merge/q145-r2` is new": `merge/ready-2026-10-15`, `merge/build-loop-u5-resolved` and `merge/u5-and-q145` exist; no `merge/q145`. "without `log.showsignature`" matches `scripts/build-loop.sh:610` against the paste regexp. "its file checks": the paste refuses the same four files and is stricter (it refuses any existence; the gate allows an empty regular file). The origin/HEAD note is accurate. One omission: G-3. |
| **B4** guard list and order | Accurate | Line 83's list now names `hook.`, pager, attributes file, fsck and partial clone. The regexp matches it (merge and diff are refused as whole namespaces, a superset of "driver"). The config check precedes `fsck` in the `&&` chain. "every git command in the paste that writes runs with hooks off": all five writing calls have it. |
| **B5** shell residue wording | Accurate | "an alias or function …, or an exported `GIT_*` variable such as `GIT_CONFIG` or `GIT_SHALLOW_FILE`". Non-`GIT_*` env (`PATH`, `BASH_ENV`) is covered by "the shell it runs in". |
| **B6** wording | Accurate (read-static) | `63af3551` adds roadmap Next 5 "Re-run decision 015's step 4", and is the parent of 46942678. At b71a4e9e `cc-isolated.sh:749` keeps the last positional (`ws_arg="$1"`), so line 1 on a pre-fix launcher targets `~/code/b`: an error exit if it is absent, a launch if it is a repository, as worded. |

## Findings

#### G-1: Q-162's cleanup loop passes `$1` instead of the worktree path, so it deletes nothing and the paste exits 129 after the merge has landed

**Severity:** Medium
**Location:** `docs/working/questions.md:91`
**Boundary:** B5 (S5)
**Move:** 3 (error path), 12 (sweep every git call)
**Confidence:** High (executed, bash and zsh, 6 runs)
**Legibility-target:** for-author

Evidence (verbatim, line 91): `for u in u3a1 u3a2 u3a3 u3b1 u3b2 u3b3 u3c u3d u4a u4b1 u4b2 u4c; do git -c core.hooksPath=/dev/null worktree remove $1 && git -c core.hooksPath=/dev/null branch -d feat/build-loop-$u; done`. At 8ab42eec it read `worktree remove .claude/wt-build-loop-$u`. The B1 edit replaced the path with `$1`.

In a paste, `$1` is empty, so `git worktree remove` prints `usage: git worktree remove [-f] <worktree>` 12 times and the `&&` skips every `branch -d`. Every run: Q-162 rc=129, `wts=12 brs=12`. The reviewed merge has already landed, so the tree is still right. But the prose's "It then deletes the twelve build-loop branches already merged into main, along with their worktrees" is false, and the paste ends in an error. Security relevance: the user is left to improvise the cleanup, most likely without `-c core.hooksPath=/dev/null`, which reopens B1's route (a default-dir `reference-transaction` hook on `branch -d`, i2 F-A). In a shell where `$1` is set, the loop would act on that path instead.

**Recommendation:** restore `git -c core.hooksPath=/dev/null worktree remove .claude/wt-build-loop-$u`. Executed with that one change (`p162fix.txt`, `seq3.sh … hooksfix`, both shells): rc=0, 12 `Deleted branch …`, `wts=0 brs=0`, plant `none`, same tree `94d306ae…`.

#### G-2: The prose's own pre-checks, typed at a tty, run a planted `pager.show`/`pager.log`/`core.pager` before the guard. The pager can rewrite the block the user copies, or move main after showing an honest log, and then erase itself

**Severity:** Medium
**Location:** `docs/working/questions.md:83` ("take the block from the committed text (in the container shell: `git -c core.useReplaceRefs=false show main:docs/working/questions.md`) … first look over `git --no-replace-objects log --oneline --first-parent b71a4e9e..HEAD`")
**Boundary:** B4 (S1), B3
**Move:** 11 (bypass the guardrail by running before it), 12
**Confidence:** High (executed, bash and zsh)
**Legibility-target:** for-author

Both commands page by default when stdout is a terminal, and the prose tells the user to run them in the container shell before the paste. The guard refuses `pager.`/`core.pager`, but it runs after them.

- **Pager runs.** `b2.sh`: with `core.pager`, `pager.show` or `pager.log` set to a logging script, the commands as worded ran it (`RAN:core.pager` ×4, `RAN:pager.show` ×2, `RAN:pager.log`). With `git --no-pager` on each, none ran.
- **Exploit** (`forge.sh`, both shells). `pager.show` ran `sed` over the shown file: the block the user would copy had `1111111111111111111111111111111111111111` in place of 09a2876f on 3 lines (0 real). Then it unset its key. `pager.log` passed the honest (empty) log through. Once git had exited, it replaced HEAD with a commit carrying the same message and parents plus a `payload` file, then unset its key. Afterwards: 0 pager keys, main moved. Running the shipped Q-162 then passed the guard and printed "Merge made by the 'ort' strategy.", and `git show main:payload` printed `PAYLOAD`.

This needs no running agent. It runs inside the two steps the prose offers as mitigations for a moved main and an edited working tree, and it leaves nothing for the guard to see. It is not inside the named residue. The shell residue covers aliases and env, and "what main itself holds" assumes the log check is honest. The log check has been in this form since 8ab42eec (i2 missed it). The `show` instruction is new in this range.

**Recommendation:** add `--no-pager` to both commands: `git --no-pager -c core.useReplaceRefs=false show main:…` and `git --no-pager --no-replace-objects log …`, or pipe each to `cat`. Executed: neither runs a planted pager. With `diff.x.textconv` and `* diff=x` in `info/attributes`, `log.showSignature` and `gpg.program` planted, the `--no-pager` forms ran nothing either (unsigned commits).

#### G-3: Q-180's Resolved line omits `pager.`/`core.pager` from what the guard adds beyond the state gate

**Severity:** Informational
**Location:** `docs/working/questions-archive.md:2872`
**Boundary:** Internal (wording about B1 coverage)
**Move:** 11
**Confidence:** High (read-static)
**Legibility-target:** for-author

Evidence: "it now refuses the state gate's config keys (…) and its file checks, plus `fsck.` keys and an object `git fsck` rejects". The regexp also refuses `pager\.` and `core\.pager`, which are not in STATE_KEYS_RE. This understates the guard; it does not overclaim.

**Recommendation:** "plus `fsck.` and pager keys and …". Optional.

## Untested bypass candidates

- **Crafted commit-graph or multi-pack-index.** Carried from i2 and rubric C4. Not crafted.
- **Working-tree `.gitattributes` with built-in `merge=union`.** Carried (C4). The pinned merges landed the expected tree, so no evidence either way.
- **`gc.auto` maintenance after the merge.** Hooks are off on every writing call. Whether gc spawns anything config-named on 2.39.5 was not re-probed.
- **A non-empty `$1` in the user's shell (G-1).** Not run. Reasoned only: the loop would act on that path.
- **Shell startup, a concurrent writer, a moved main.** Named residue.

With G-2 executed and the candidates above open, the guard and the pre-checks are not endorsed.

## Endorsement Claims

- **Claim:** With all 28 default-dir hooks planted, under a pty, Q-180 landed first, then Q-162, then Q-163/Q-164 in either order, run nothing planted and land tree `94d306ae…`. That tree is `merge-tree(6c841192, Q-180 landing)`.
  **Location:** `docs/working/questions.md:88-91,117-121,149-153`
  **Evidence:** executed (`seq3.sh` hooks ×4, clean ×2, hooksfix ×2)
  **Verified:** a scratch clone of /workspace at b71a4e9e, bash and zsh
  **Not verified:** a main that has moved past the Q-180 landing; a non-empty `$1`
  **route: code-fact-check**
- **Claim:** With `pager.*` and `core.pager` set, each paste stops at the guard and runs nothing planted. On a forced override-log conflict, Q-162 aborts with hooks off, leaves no `MERGE_HEAD` and a clean tree, and Q-163/Q-164 then stop.
  **Location:** `docs/working/questions.md:89-90,118-121,150-153`
  **Evidence:** executed (`seq3.sh` hookspager, conflict; both shells)
  **Verified:** the stop messages, the plant log, HEAD and status
  **Not verified:** a conflict in Q-163/Q-164's own merge (not forced)
  **route: code-fact-check**
- **Claim:** The prose's `show` and `log` forms ignore a planted replace ref.
  **Location:** `docs/working/questions.md:83`
  **Evidence:** executed (`b2.sh`)
  **Verified:** a replaced blob and a replaced commit
  **Not verified:** that they run no planted code (they do: G-2)

## Primitive sweep

Primitive: a git invocation that reads agent-writable state and can spawn a config- or hooks-dir-named command

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:83` prose `git -c core.useReplaceRefs=false show main:…` | S1, S4 | none (runs before the paste) | **G-2** (pager) |
| `:83` prose `git --no-replace-objects log …` | S1, S4 | none | **G-2** (pager) |
| `:88,117,149` `git branch --show-current` | S1 | none | cleared: in `$(…)`, no tty, no hook (28 hooks planted, plant `none`) |
| `:89,118,150` guard: `for-each-ref`, `config`, `rev-parse`, `fsck` | S1–S3 | — | cleared: same probe, plus pager keys set: refused, plant `none` |
| `:90` Q-162 `merge` | S1–S4 | guard, hooks off, no replace, no commit-graph | cleared (executed) |
| `:90` Q-162 `merge --abort` | S2 | hooks off | cleared (conflict variant) |
| `:91` `worktree remove $1` | S2, S5 | hooks off | **G-1** (wrong argument); hooks cleared |
| `:91` `branch -d` | S2, S3 | hooks off | cleared (hooksfix variant); commit-graph untested |
| `:119-120,151-152` `merge-base --is-ancestor` | S3, S4 | replace refs refused | cleared (selection picked 6c841192 in each order's second merge; commit-graph untested) |
| `:121,153` Q-163/Q-164 `merge`, `merge --abort` | S1–S4, S2 | as Q-162 | cleared for the merge (executed); abort arm read-static (same flags as Q-162's executed arm) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| G-1 | Cleanup loop removes `$1`: nothing deleted, rc=129 after the merge (regression from the B1 edit) | Medium | B5 | `questions.md:91` | High |
| G-2 | Prose pre-checks spawn a planted pager before the guard; it forges the copied block or moves main, then self-erases | Medium | B4, B3 | `questions.md:83` | High |
| G-3 | Resolved line omits pager keys from the guard's additions | Informational | Internal | `questions-archive.md:2872` | High |

## Overall Assessment

B1 is closed. Every writing git call in the three pastes runs with hooks off, the guard refuses pager keys, and under a pty with every hook planted the pastes run nothing planted and land one tree in both orders and both shells. The abort path is clean too. B2 is closed for replace refs, and B3–B6 are accurate. Two text-level defects remain, both fixable in place and both executed with the fix applied:
- **G-1.** The B1 edit turned the cleanup loop's path into `$1`, so Q-162 no longer deletes the worktrees or branches it says it does, and it ends in an error.
- **G-2.** The two commands the prose offers as the trust anchor run before the guard and spawn a repo-configured pager, which can falsify the copied block and the log check together.

The single most important fix is `--no-pager` on the two prose commands (G-2). G-1 is the one that will visibly break the user's run. Neither is an architectural problem. Today's `/workspace` has no `pager.*`/`core.pager` keys and no non-sample hooks (checked read-only), so neither route is armed now.

## Goal-Alignment Note

- Success criterion (restated verbatim): "a markdown report at the output path you were given, structured per your skill."
- Answered: yes, at `docs/reviews/security-review-2026-10-15-q180-i3.md`, first line `Commit: 5983f60e`.
- User goal: run Q-162, Q-164 and Q-163 safely. The pastes land the reviewed tree and run nothing planted (B1 closed). Before the user runs Q-162, fix line 91's `$1` (G-1) and add `--no-pager` to line 83's two commands (G-2). Both are one-token text edits, executed here. G-3 is optional wording.
- Probes: every process ran under `timeout` in the scratch dir. None is left running (`ps` checked). No worktree was added to /workspace. This report is the only repo file written.
