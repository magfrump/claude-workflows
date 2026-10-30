Commit: 5983f60e

# Code Fact-Check Report

**Replication:** k=1 (loop pass, decision 031)
**Repository:** /workspace (worktree /workspace/.claude/wt-q180, branch `chore/q180-repin-pastes`)
**Scope:** iteration-3 fix range `git diff 8ab42eec..5983f60e -- docs/working` (`docs/working/questions.md` Q-162, Q-163, Q-164, Q-167(b); `docs/working/questions-archive.md` Q-180's Resolved line), plus commit 5983f60e's message. Pastes read whole at 5983f60e (Q-162 `questions.md:80-106`, Q-163 `:107-133`, Q-164 `:134-165`).
**Checked:** 2026-10-15
**Total claims checked:** 15 (14 numbered, Claim 2 split into 2a/2b)
**Summary:** 11 verified, 1 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Execution setup (shared by the executed claims): a `--no-hardlinks` clone of `/workspace` at main b71a4e9e in `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/fc-q180-i3/clone`; each run re-clones it, creates the twelve `feat/build-loop-u*` branches and their `.claude/wt-build-loop-*` worktrees, lands 5983f60e (Q-180's branch first) with hooks off, then runs the three pastes as extracted byte-for-byte from `git show 5983f60e:docs/working/questions.md`. The only edit is `cd /workspace` becoming `cd "$R"`. Each paste runs under `script -qec` so it has a tty, under `timeout`. Scripts and logs are in that scratch dir (`seq.sh`, `plant.sh`, `abort.sh`, `prepager.sh`, `*.log`). Prior hallucination-pattern log read (8 entries); none matches a claim here.

---

## Claim 1: "It then deletes the twelve build-loop branches already merged into main, along with their worktrees."

**Location:** `docs/working/questions.md:83` (prose), `docs/working/questions.md:91` (the paste line it describes)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the shipped Q-162 cleanup loop at 5983f60e under bash and zsh, run by the full paste in a tty after a clean merge. It does not establish anything about the merge line, which lands correctly (Claim 7).

5983f60e replaced the worktree path with `$1`:

```
# docs/working/questions.md:91 (5983f60e)
for u in u3a1 u3a2 u3a3 u3b1 u3b2 u3b3 u3c u3d u4a u4b1 u4b2 u4c; do git -c core.hooksPath=/dev/null worktree remove $1 && git -c core.hooksPath=/dev/null branch -d feat/build-loop-$u; done
```

At 8ab42eec the same line read `git worktree remove .claude/wt-build-loop-$u && git branch -d feat/build-loop-$u` (from the fix-range diff). A pasted block has no positional parameters, so `$1` is empty and unquoted, and expands to no word in both bash and zsh. Each iteration then runs `git worktree remove` with no argument, which prints usage and exits 129. The `&&` skips `branch -d`. The result: nothing is deleted, twelve usage messages print, and the paste exits 129 after a successful merge.

Command: `./seq.sh {bash,zsh} {163-164,164-163}` (cwd `.../scratchpad/fc-q180-i3`, 2026-10-15T21:44:19Z, harness exit 0). All four runs printed `Q-162 rc=129 ... 12 usage: git worktree remove [-f] <worktree>`, and `build-loop-branches-left=16 worktrees=13` both before and after. Control at 2026-10-15T21:45:55Z: the same run with only `$1` changed back to `.claude/wt-build-loop-$u` (`mkctrl.py`) gave `Q-162 rc=0`, `build-loop-branches-left=4 worktrees=1`, so all twelve branches and worktrees were removed. The defect is a regression introduced by 5983f60e. It is not dangerous: nothing wrong is deleted. But the paste no longer does what the prose says, and its non-zero exit right after a successful merge reads like a failure. Fix: restore `.claude/wt-build-loop-$u`.

**Evidence:** `docs/working/questions.md:91`; `.../scratchpad/fc-q180-i3/seq-clean.log`; `.../scratchpad/fc-q180-i3/seq-control.log`; `.../scratchpad/fc-q180-i3/real162.txt`

---

## Claim 2a: "(in the container shell: `git -c core.useReplaceRefs=false show main:docs/working/questions.md`) … `git --no-replace-objects log --oneline --first-parent b71a4e9e..HEAD` … (plain `git show` and `git log` follow a planted replace ref)"

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the replace-ref atom only: the two commands as written ignore a planted `refs/replace/` entry, and the plain forms follow it. It does not establish that the user sees the committed text or the real log, which a planted pager defeats (Claim 2b), nor anything about `GIT_NO_REPLACE_OBJECTS`/`GIT_REPLACE_REF_BASE` in the environment (named shell residue).

Run in `.../scratchpad/fc-q180-i3/replace` (2026-10-15T21:50:40Z, exit 0). The setup lands 5983f60e, then replaces main's tip with a forged commit that has a different `questions.md` and the subject "only merges you made (forged)". Output (quoted from `b2.log`): `plain show: FORGED PASTE`, `useReplaceRefs=false show: # Running questions`, plain log `71d0a5fc only merges you made (forged)`, `no-replace-objects log: 71d0a5fc land q180`.

**Evidence:** `docs/working/questions.md:83`; `.../scratchpad/fc-q180-i3/b2.log`

---

## Claim 2b: "take the block from the committed text (in the container shell: `git -c core.useReplaceRefs=false show main:…`), not the working tree an agent can edit, and first look over `git --no-replace-objects log …`: it should list only merges you made"

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the implied mechanism that these two commands, typed in the container's terminal, show the user the committed paste text and the real first-parent log. It does not establish severity, which is for the security critic. It also does not cover Q-169's host-side `show`, which is outside this fix range.

Both commands run *before* the guard, in a terminal, so git pipes their output through the configured pager. `core.pager` and `pager.<cmd>` live in the agent-writable `.git/config`. The guard refuses them (`pager\.|core\.pager`, `questions.md:89`), but only after the user has already read and copied the block. Run with `prepager.sh` (cwd `.../scratchpad/fc-q180-i3`, 2026-10-15T21:51:32Z, exit 0). The setup lands 5983f60e, adds a commit "SLIPPED agent commit" on main, and sets `core.pager` to a filter that drops that line and deletes `test -z "$(git for-each-ref refs/replace/)" && ` from the text. Quoted from `prepager.log`:

- the log check as written, in a tty, shows only `1cfb9bf4 land q180`;
- the same command with `--no-pager` shows `3914f197 (HEAD -> main) SLIPPED agent commit` and `1cfb9bf4 land q180`;
- `git -c core.useReplaceRefs=false show main:docs/working/questions.md` in a tty: `displayed copies of 'for-each-ref refs/replace/': 0`, `committed copies: 3`;
- the plant log records `RAN:filterpager` twice.

So an agent that can write `.git/config` can hide a slipped commit from the log check, the stated defence against a moved main. It can also hand the user a paste with its guard edited out. Neither falls inside the stated residue (the shell, a moved main, a running agent): the vector is repository config, the class the guard exists to refuse. `git --no-pager` (or piping into `cat`) on both commands closes this vector, as the control line shows. Checked and negative: a planted `diff.<x>.textconv` with `info/attributes` does not alter `git show <rev>:<path>` (`textconv.log`), and a `~/.config/lesskey` `#env LESSOPEN` did not run under less 590 (`lesskey.log`).

**Evidence:** `docs/working/questions.md:83`, `docs/working/questions.md:89`; `.../scratchpad/fc-q180-i3/prepager.sh`; `.../scratchpad/fc-q180-i3/prepager.log`; `.../scratchpad/fc-q180-i3/textconv.log`

---

## Claim 3: "The guard refuses replace refs, grafts, shallow, `info/attributes`, alternates, any filter, merge or diff driver, include, `hook.` key, pager, fsmonitor, attributes file, hooks path, gpg, fsck or partial-clone setting in your git config, and an object that fails `git fsck`"

**Location:** `docs/working/questions.md:83` (prose), `:89`, `:117`, `:149` (the guard lines)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the match between the prose list and the guard regex/file tests, identical in all three pastes, and the guard refusing `pager.*`/`core.pager` when executed. It does not establish that the list is complete against every agent-plantable state; C4's untested items and Claim 2b's pre-guard window remain.

The regex is quoted from `questions.md:89`: `'^(filter\.|include|hook\.|pager\.|core\.pager|merge\.|diff\.|fsck\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|extensions\.partialclone$|remote\..*\.promisor$)'`. It is followed by `test ! -e`/`test ! -L` on the `--git-path` of `info/grafts`, `shallow`, `info/attributes` and `objects/info/alternates`, `test -z "$(git for-each-ref refs/replace/)"`, and `git -c core.commitGraph=false fsck --no-dangling`. Each prose item maps to one of these. The Q-163 and Q-164 guard lines are byte-identical to Q-162's (paraphrased — no quote available because the claim is a three-way equality, checked by extracting the lines; the fix-range diff shows the same `+` line in all three hunks). Executed with `PLANT_MODE=pager ./seq.sh {bash,zsh} 163-164 pager` (2026-10-15T21:46:38Z): 12 `pager.*` keys and `core.pager` planted; every paste printed `... driver config or a bad object present: stop` with rc=1, main did not move (`firstparent=1`), and no planted pager ran during the pastes.

**Evidence:** `docs/working/questions.md:89`, `:117`, `:149`; `.../scratchpad/fc-q180-i3/seq-pager.log`, `.../scratchpad/fc-q180-i3/seq-hooks2.log`

---

## Claim 4: "(the config check must stay before `fsck`, which would run a planted fsmonitor)"

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers `git fsck` (with the paste's flags) invoking `core.fsmonitor`, on git 2.39.5. It does not establish behaviour on other git versions.

With `core.fsmonitor` set to a logging script, `git -c core.commitGraph=false fsck --no-dangling --no-progress` (cwd `.../scratchpad/fc-q180-i3/prepager`, 2026-10-15T21:51:54Z) exited 0, and the plant log recorded `RAN:fsmonitor 2 …` and `RAN:fsmonitor 1 …`.

**Evidence:** `docs/working/questions.md:83`, `:89`; `.../scratchpad/fc-q180-i3/fsck-fsm.log`

---

## Claim 5: "every git command in the paste that writes runs with hooks off"

**Location:** `docs/working/questions.md:83`; paste lines `:90-91`, `:121`, `:153`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the merge, the `merge --abort` (Q-162's conflict path), and the cleanup loop's `worktree remove`/`branch -d`, with all 28 githooks(5) names planted in `.git/hooks`. The cleanup half was exercised only in the control run with the intended path, because the shipped loop never reaches `worktree remove <path>` (Claim 1). Q-163/Q-164's own `merge --abort` lines were read, not driven to a conflict. It does not establish behaviour of the user's pre-paste commands (Claim 2b) or of a planted pager/env in the shell.

Every writing call carries `-c core.hooksPath=/dev/null`: `git -c core.hooksPath=/dev/null -c core.commitGraph=false merge`, `git -c core.hooksPath=/dev/null merge --abort`, `git -c core.hooksPath=/dev/null worktree remove`, `git -c core.hooksPath=/dev/null branch -d` (quoted from `questions.md:90-91`; the same merge/abort forms are at `:121` and `:153`). Executed runs:

- `./seq.sh {bash,zsh} {163-164,164-163} hooks` (2026-10-15T21:46:38Z and 21:48:27Z): every paste landed with tree 94d306ae, and `plant log after pastes, before harness status: 0 lines`. The single `post-index-change` record comes from the harness's own trailing `git status`, which this confirms is the very class the prose warns about.
- The control run with hooks planted (`seq-hooks-control.log`, 21:49:28Z): the cleanup removed 12 branches and 12 worktrees with 0 plant runs.
- `./abort.sh {bash,zsh}`, which adds a conflicting override-log row on main: Q-162 printed `CONFLICT … conflict: merge aborted, nothing deleted`, `head-unchanged=yes MERGE_HEAD=absent plant-lines=0`, and Q-163/Q-164 printed `Q-162's merge is not on main: run it first`.

**Evidence:** `docs/working/questions.md:90-91`, `:121`, `:153`; `.../scratchpad/fc-q180-i3/seq-hooks.log`, `seq-hooks2.log`, `seq-hooks-control.log`, `abort.log`

---

## Claim 6: "an alias or function for `git` or `test`, or an exported `GIT_*` variable such as `GIT_CONFIG` or `GIT_SHALLOW_FILE`, defeats any guard written into a paste"

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the two named variables evading the guard's checks. It does not establish an exhaustive list of such variables; "such as" makes no such claim. The alias/function half is static, since a shell function shadowing `git` replaces every guard command by construction.

Executed in `.../scratchpad/fc-q180-i3/prepager` (2026-10-15T21:52:08Z), quoted from `env.log`. `git-path shallow under env: .git/shallow`: the guard's `rev-parse --git-path shallow` ignores `GIT_SHALLOW_FILE`. Yet history does change under it: `rev-list count b71a4e9e without env: 2674 with env: 1`. `GIT_CONFIG=/dev/null hides config from git config: 0 entries vs 1`: the guard's `git config --get-regexp` reads only that file.

**Evidence:** `docs/working/questions.md:83`; `.../scratchpad/fc-q180-i3/env.log`

---

## Claim 7: Q-163/Q-164 "stop unless this merge is on main"; landing Q-180's branch, then Q-162, then Q-163/Q-164 in either order lands one tree

**Location:** `docs/working/questions.md:83` (last sentence), `:118-121`, `:150-153`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the clean sequence starting from b71a4e9e plus 5983f60e, both orders, in bash and zsh, with a tty, plus the Q-162-absent stop. It does not establish the outcome from a main that has moved in other ways.

`./seq.sh` (2026-10-15T21:44:19Z) gave, in all four runs, Q-162 `Merge made by the 'ort' strategy.`, Q-163 rc=0, Q-164 rc=0, `tree=94d306ae9c566f1db4feac7d1ca9d72841f80252 status=0 firstparent=4`. When Q-162's merge was aborted (`abort.log`), both later pastes printed `Q-162's merge is not on main: run it first` and exited 1.

**Evidence:** `docs/working/questions.md:118-121`, `:150-153`; `.../scratchpad/fc-q180-i3/seq-clean.log`, `.../scratchpad/fc-q180-i3/abort.log`

---

## Claim 8: "the decision-015 idea (added by the 2026-10-14 cycle commit 63af3551, which e088c7e3 carried) dropped since main's Next 5 holds it"

**Location:** `docs/working/questions.md:146`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the origin and carriage of the idea's text. It does not establish who reworded it: in 63af3551 and 46942678 it is roadmap Next item 5, and e088c7e3's merge resolution moved it into Ideas.

`git log -S"Re-run decision 015's step 4 as a divergent design" --all -- docs/roadmap.md` lists 63af3551 (the add) and 5f0f00d9 (main's removal). 63af3551 is an ancestor of 46942678, which is a parent of e088c7e3. At e088c7e3, `docs/roadmap.md:140` reads `- **Re-run decision 015's step 4 as a divergent design (Q-105 [3]).** Signal: …  Here because Next holds five.`. Main's `docs/roadmap.md:95` (b71a4e9e) reads `5. **Decision 015's re-run: apply the outcome (Q-170).**`, and 7326d715 drops the Ideas bullet (no `Re-run decision 015` line).

**Evidence:** `docs/roadmap.md:140` at e088c7e3; `docs/roadmap.md:95` at b71a4e9e; `docs/roadmap.md:90` at 7326d715

---

## Claim 9: "on a launcher older than the fix, the first line exits 1 with another error (or launches a session if `~/code/b` is a repository)"

**Location:** `docs/working/questions.md:219`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers main's (pre-fix) `devcontainer-config/cc-isolated.sh` given two positional paths. The launch branch is static. It does not establish behaviour on the user's host install.

The pre-fix parser keeps the last positional argument (`*)            ws_arg="$1"; shift ;;`, `cc-isolated.sh:749` at b71a4e9e) under `set -euo pipefail` (`:66`). It reaches `ws="$(resolve_workspace "$ws_arg")"`, which returns 1 on `ERROR: not a directory` or `is not inside a git repository`, and otherwise proceeds to launch. Executed: `HOME=<scratch> bash cc-main.sh <a> <b>` (2026-10-15T21:53:09Z) printed `exit=1` with `ERROR: host-tool check failed …`, another exit-1 error in an unblessed directory.

**Evidence:** `devcontainer-config/cc-isolated.sh:66`, `:733-750`, `:787-789` at b71a4e9e; `.../scratchpad/fc-q180-i3/cc-prefix-line1.log`

---

## Claim 10: "The three merge branches were rebuilt on main b71a4e9e as new `-r2` branches (the old ones kept for you to delete), and `merge/q145-r2` is new: `merge/ready-2026-10-15-r2` 09a2876f, `merge/build-loop-u5-resolved-r2` 7326d715, `merge/q145-r2` 35e13638, `merge/u5-and-q145-r2` 6c841192."

**Location:** `docs/working/questions-archive.md:2872`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the existence and tips of the named refs and the absence of an old `merge/q145`. It does not re-establish the branches' contents (iterations 1–2, Claims 9–17).

`git for-each-ref refs/heads/merge/` lists `merge/build-loop-u5-resolved 0f94bb77`, `-r2 7326d715`, `merge/q145-r2 35e13638`, `merge/ready-2026-10-15 a760a5e5`, `-r2 09a2876f`, `merge/u5-and-q145 a04d9776`, `-r2 6c841192`. There is no `merge/q145`.

**Evidence:** `docs/working/questions-archive.md:2872`

---

## Claim 11: "it now refuses the state gate's config keys (`scripts/build-loop.sh` STATE_KEYS_RE, without `log.showsignature`, which the merge never reads) and its file checks, plus `fsck.` keys and an object `git fsck` rejects"

**Location:** `docs/working/questions-archive.md:2872`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the comparison of the paste regex and file tests with `state_gate`. It does not establish the "merge never reads `log.showsignature`" sub-clause (Claim 13).

`STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'` (`scripts/build-loop.sh:610`). The paste regex (`questions.md:89`) is that list minus `log\.showsignature`, plus `fsck\.`, **and plus `pager\.|core\.pager`**, which this same commit added and the line omits. The file checks match and are stricter. The state gate allows an empty regular file (`if [[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]`, `build-loop.sh:621`), while the paste refuses any `-e` or `-L`. Precise version: "…plus `fsck.`, `pager.` and `core.pager` keys…".

**Evidence:** `scripts/build-loop.sh:610`, `:618-626`; `docs/working/questions.md:89`; `docs/working/questions-archive.md:2872`

---

## Claim 12: "it does not check `origin/HEAD`, which a pinned merge does not read"

**Location:** `docs/working/questions-archive.md:2872`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the pastes merging by full hash with no default-branch resolution. It does not establish anything about `origin/HEAD`'s use by other tooling.

The pastes merge a literal hash (`merge --no-ff 09a2876ff5ea6f7e5b86eea723c2aa0094759145`, `questions.md:90`; `B=<40-hex>`, `:120`, `:152`) and test `git branch --show-current` = `main`. No `origin` name is resolved anywhere in the three blocks (paraphrased — no quote available because the claim covers absence of code: no `origin` token in the extracted pastes).

**Evidence:** `docs/working/questions.md:88-91`, `:116-121`, `:148-153`

---

## Claim 13: "`log.showsignature`, which the merge never reads"

**Location:** `docs/working/questions-archive.md:2872`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers nothing beyond the attempt. Execution is required and was not completed. The practical risk is nil while the guard refuses `gpg.` (no planted `gpg.program`), which is why this does not block.

An attempted execution (merge of a hand-built commit carrying a `gpgsig` header with `log.showSignature=true` and a logging `gpg.program`, `showsig.log`) failed at setup (merge rc=2, and the control `git log` also did not invoke gpg), so it is no evidence either way. Verifying it needs a well-formed signed commit, or a reading of `builtin/merge.c`'s config callback.

**Evidence:** `docs/working/questions-archive.md:2872`; `.../scratchpad/fc-q180-i3/showsig.log`

---

## Claim 14: Commit 5983f60e message: "Every git call in the Q-162/163/164 pastes that writes (worktree remove, branch -d, merge --abort, the merge) runs with core.hooksPath=/dev/null; the guard also refuses pager. and core.pager keys … The committed-text and log checks bypass replace refs … Notes: the iteration-2 security probes (reference-transaction, pager.merge) are fixed as the critic tested them; re-verified in iteration 3."

**Location:** commit 5983f60e message (`git log -1 --format=%B 5983f60e`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the hooks-off flags, the pager refusal and the replace-ref bypass as stated (Claims 2a, 3, 5). It does not establish that the commit left the cleanup loop working (it did not: Claim 1), nor that the "committed-text check" shows committed text under a planted pager (Claim 2b).

See Claims 2a, 3 and 5 for commands and logs. With every hook (reference-transaction included) planted, the pastes ran nothing planted, and `pager.merge` is refused at the guard.

**Evidence:** commit 5983f60e; `.../scratchpad/fc-q180-i3/seq-hooks2.log`, `seq-pager.log`, `b2.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/working/questions.md:91`): 5983f60e turned `worktree remove .claude/wt-build-loop-$u` into `worktree remove $1`. In a paste `$1` is empty, so the loop deletes nothing (12 usage errors, exit 129 after a good merge). Restore the path. Regression from this commit, executed with a control.
- **Claim 2b** (`docs/working/questions.md:83`): the pre-paste `git … show main:…` and `git --no-replace-objects log …` run in a tty through `core.pager`/`pager.*` from agent-writable `.git/config`, before the guard refuses those keys. A planted pager hid a slipped commit from the log check and stripped the replace-ref test from the displayed paste (executed). Add `--no-pager` to both commands.

### Mostly Accurate
- **Claim 11** (`docs/working/questions-archive.md:2872`): the Resolved line's guard summary omits the `pager.`/`core.pager` keys that this commit added.

### Unverifiable
- **Claim 13** (`docs/working/questions-archive.md:2872`): "the merge never reads `log.showsignature`" needs a well-formed signed-commit probe or a source read. It is moot while `gpg.` is refused.

---

## Goal-Alignment Note

The goal is for the user to run Q-162, then Q-164 and Q-163, safely from the container shell. B1 and B2 hold as tested. With every hook name planted, the merge, the abort and (with the intended path) the cleanup ran nothing planted, in bash and zsh, in both orders. The sequence lands one tree, 94d306ae. Pager keys stop the guard. The replace-ref bypass works. Two things block the iteration's "confirming" status:

1. **Claim 1, new in this fix.** Q-162's cleanup is broken by a `$1` typo. It is harmless but visible: rc=129 and twelve usage errors right after the user's merge, with the twelve branches left behind. This is a one-token fix.
2. **Claim 2b.** The prose's own pre-paste checks are open to the same repository-config class (a pager) that the guard refuses, because they run before it. That defeats both the "take the committed text" and the "log check" defences. Adding `--no-pager` closes it without growing the guard.

B3–B6 wording is accurate apart from Claim 11's omission. Probes ran only in scratch clones under `timeout`; the one stray `less` left by a probe was killed by PID.
