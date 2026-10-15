Commit: 8ab42eec

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-q180, branch `chore/q180-repin-pastes`)
**Scope:** `git diff 46342d66..8ab42eec -- docs/working docs/roadmap.md` (iteration 2, confirming pass over the fix commit), plus the commit message of 8ab42eec. Context checked against `git diff main...8ab42eec`.
**Checked:** 2026-10-15
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 23
**Summary:** 17 verified, 5 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution logs are in the session scratchpad, `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/`. Each is named on the claim that relies on it. All probes ran in that directory. The only reads of `/workspace` were read-only: `git show/log/merge-tree`, the guard (`for-each-ref`, `config`, `rev-parse`, `fsck`), and `questions.sh check`. The guard text under test is line 89 of `git show 8ab42eec:docs/working/questions.md`, taken verbatim (`guard.line`, `guard.sh`). Git 2.39.5, bash 5 and zsh 5.9.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). No claim matches a logged pattern.

---

## Claim 1: Roadmap Now names `merge/ready-2026-10-15-r2` (A11)

**Location:** `docs/roadmap.md:29,42,45`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `merge/ready-2026-10-15` mention in `docs/roadmap.md` at 8ab42eec. It does not cover mentions in other files, which Claim 5 and the questions.md scan cover.
**Legibility-target:** for-orchestrator-synthesis

Quoted (`docs/roadmap.md:29`): `brief below. Reviewed, loop closed; waits on Q-162's paste (`merge/ready-2026-10-15-r2`).` Lines 42 and 45 also read `merge/ready-2026-10-15-r2`. Running `git show 8ab42eec:docs/roadmap.md | grep -n 'merge/ready-2026-10-15' | grep -vc -- '-r2'` prints `0`.

Execution: `git show 8ab42eec:docs/roadmap.md | grep … | grep -vc -- -r2` in cwd `/workspace`, exit 0, 2026-10-15T21:3xZ.

**Evidence:** `docs/roadmap.md:29,42,45`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/static-git-facts.log` (section "A11")

---

## Claim 2: "Q-149..Q-153, Q-155 and Q-103 become the live asks (U5 files Q-154 answered)" (A9)

**Location:** `docs/working/checkpoint-build-loop-handoff.md:48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the status lines of Q-103 and Q-149..Q-156 at the U5 tip 7c91b974 and at `merge/u5-and-q145-r2` 6c841192. It does not decide whether Q-156 (the release paste, also OPEN) counts as a "live ask". The sentence leaves it out, which reads as deliberate.
**Legibility-target:** for-orchestrator-synthesis

At both commits, `questions.md` has Q-103 and Q-149, 150, 151, 152, 153, 155 and 156 as `Status:** OPEN`, and `questions-archive.md` has `### Q-154 … Status:** ANSWERED`.

Execution: `git show <c>:docs/working/questions{,-archive}.md | grep -A1 '^### Q-…'` for c in 7c91b974 and 6c841192, cwd `/workspace`, exit 0, 2026-10-15T21:36Z.

**Evidence:** `docs/working/checkpoint-build-loop-handoff.md:48`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/static-git-facts.log` (section "A9")

---

## Claim 3: "The four merge branches were rebuilt on main b71a4e9e as new `-r2` branches (the old ones kept for you to delete): … 09a2876f, … 7326d715, … 35e13638, … 6c841192"

**Location:** `docs/working/questions-archive.md:2872`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four `-r2` branch tips and which old branches still exist. It does not re-verify the -r2 contents (iteration 1, Claims 9–17).
**Legibility-target:** for-author

The four hashes match the branch tips: `merge/build-loop-u5-resolved-r2 7326d715`, `merge/q145-r2 35e13638`, `merge/ready-2026-10-15-r2 09a2876f`, `merge/u5-and-q145-r2 6c841192`. Only three of them replace an old branch, and those three are kept: `merge/ready-2026-10-15 a760a5e5`, `merge/build-loop-u5-resolved 0f94bb77` and `merge/u5-and-q145 a04d9776`. There is no `merge/q145`, so `merge/q145-r2` is new, not rebuilt. The entry's own work list names three branches to rebuild. A precise wording: "three merge branches were rebuilt and one added".

Execution: `git branch --list 'merge/*'`, cwd `/workspace`, exit 0, 2026-10-15T21:36Z.

**Evidence:** `docs/working/questions-archive.md:2863,2872`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/static-git-facts.log` (section "merge branches")

---

## Claim 4: "it now refuses everything `scripts/build-loop.sh`'s state gate refuses, plus `fsck.` keys and an object `git fsck` rejects"

**Location:** `docs/working/questions-archive.md:2872`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard's config regex and file checks against `STATE_KEYS_RE` and `state_gate()`. It does not cover `caller_gate()`'s environment checks, which are a separate function. Claim 12 shows one of those in effect.
**Legibility-target:** for-author

The state gate's regex (`scripts/build-loop.sh:610`):

```
STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'
```

The guard's regex (`docs/working/questions.md:89`) has no `log\.showsignature`. With `log.showSignature=true` planted, the guard passes (`log-showsignature bash rc=0`, `zsh rc=0`). `state_gate()` also refuses an `origin/HEAD` naming a branch other than main or master (`scripts/build-loop.sh:629-632`, `"refuse state origin/HEAD: it names a branch other than origin/main or origin/master"`), and the guard does not check that. The guard is stricter in one place: it refuses an empty `info/attributes`, grafts, shallow or alternates file, which `state_gate` allows (`[[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]`, `:625`). The security review chose to drop `log.showsignature` because "merge does not log" (`docs/reviews/security-review-2026-10-15-q180.md:54`). So the gap is harmless for the merge, but "everything" is not literal. A precise wording: "everything the state gate's key list refuses except `log.showSignature`, plus `fsck.` keys, …".

Execution: `bash run.sh` (the guard harness), cwd `…/code-fact-check-i2`, exit 0, 2026-10-15T21:27:10Z.

**Evidence:** `scripts/build-loop.sh:610,624-632`; `docs/working/questions.md:89`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/guard-probe.log` (rows `log-showsignature`)

---

## Claim 5: "Every item above is applied; the review is `docs/reviews/code-review-rubric-2026-10-15-chore-q180-repin-pastes.md`. The 'Do not run until Q-180 is done' holds are removed from each Interim."

**Location:** `docs/working/questions-archive.md:2872`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hold sentences (6 on main, 0 at 8ab42eec), the rubric's existence, the questions files' structure and indexes, and each work item: the -r2 re-pins, the grafts/shallow guard, the container wording, Q-167(b) line 3 = `--profile '#' --list`, Q-176's `mkdir ~/q092 &&`, Q-169's pin, "12", "88 of 116", and questions-archive in the conflict list. Residue: the work item "only Q-110, doc drift and Q-160 conflict with each other" was replaced by the A4 wording ("conflict with main's new rows", Claim 13) and not applied as written. The replacement is the more accurate text.
**Legibility-target:** for-orchestrator-synthesis

`git show b71a4e9e:docs/working/questions.md | grep -c "Do not run this entry's paste until Q-180"` gives `6`, and at 8ab42eec it gives `0`. The rubric file exists. Q-176's paste reads `mkdir ~/q092 && mkdir ~/q092/.claude && cd ~/q092 && …` (`questions.md:389`). `~/.claude/scripts/questions.sh check` prints `✓ questions: structure valid, indexes current`.

Execution: the grep above (cwd `/workspace`, exit 0) and `questions.sh check` (cwd `/workspace/.claude/wt-q180`, HEAD 8ab42eec, clean tree, exit 0), 2026-10-15T21:34:25Z.

**Evidence:** `docs/working/questions-archive.md:2863-2872`; `docs/working/questions.md:389`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/questions-check.log`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/static-git-facts.log` (section "holds")

---

## Claim 6: "The container's `/workspace` is a bind mount of your host checkout"

**Location:** `docs/working/questions.md:83`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this container's mount table now. It does not show that every cc-isolated container mounts it the same way, though the launcher's design (`resolve_workspace`, "cc-isolated mounts a repo at /workspace") says so.
**Legibility-target:** for-orchestrator-synthesis

`/proc/self/mountinfo` shows: `1395 1385 8:48 /home/magfrump/claude-workflows /workspace rw,relatime - ext4 /dev/sdd …`. That is a bind of the host directory `/home/magfrump/claude-workflows`.

Execution: `grep -E " /workspace " /proc/self/mountinfo`, cwd `/workspace`, exit 0, 2026-10-15T21:36Z.

**Evidence:** `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/static-git-facts.log` (section "bind mount")

---

## Claim 7: "an agent session can plant hooks and config in `.git`, and they run as whoever runs git there (a host `git status`, or a zsh prompt that runs it on `cd`, runs a planted `core.fsmonitor` on the host)"

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git status` running a planted `core.fsmonitor` in a scratch repo. It does not cover the user's own prompt configuration, i.e. whether their zsh prompt runs `git status`.
**Legibility-target:** for-orchestrator-synthesis

Control probe: with `core.fsmonitor = touch …/m-fsm` planted, `(cd r && git status)` created `m-fsm` (log line `m-fsm` / `(control: git status in the checkout ran the planted fsmonitor)`).

Execution: see the log, cwd `…/code-fact-check-i2/probe-show`, exit 0, 2026-10-15T21:30:43Z.

**Evidence:** `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/q169-show-probe.log`

---

## Claim 8: "On the host this guard refuses anyway, because your global config sets `core.hooksPath`."

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers two things. The guard refuses a key the regex lists when it is set in global config (executed, `core.fsmonitor` in `~/.gitconfig`). The guard also refuses `core.hooksPath` (executed, local). The host's global value comes from a recorded check, not one made here. Not established: the host's config today. It cannot be observed from the container.
**Legibility-target:** for-orchestrator-synthesis

The Q-139 archive note records the host value (`docs/working/questions-archive.md`, Q-139): "The host still reports `core.hooksPath=/home/magfrump/.config/git/hooks`, from the user's global `~/.gitconfig` (checked 2026-10-15 with `--show-scope`)". The guard's `git config --name-only --get-regexp` has no `--file`, so it reads every scope. In the harness, `global-fsmonitor` refused (`rc=1`, both shells) and `hooksPath` refused (`rc=1`, both shells).

Execution: `bash run.sh`, cwd `…/code-fact-check-i2`, exit 0, 2026-10-15T21:27:10Z.

**Evidence:** `docs/working/questions-archive.md` (Q-139 entry, Answered line); `docs/working/questions.md:89`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/guard-probe.log` (rows `global-fsmonitor`, `hooksPath`)

---

## Claim 9: "take the block from the committed text (`git show main:docs/working/questions.md`), not the working tree an agent can edit, and first look over `git log --oneline --first-parent b71a4e9e..HEAD`: it should list only merges you made" (C1, and A2's log check)

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what plain `git show main:<path>` and `git log` print in a repository where a replace ref is planted. It does not judge the practical risk relative to the residue the entry already names (a moved main). It does not cover grafts, which change `log` but not `main:<path>`.
**Legibility-target:** for-author

The sentence says the committed text is out of an agent's reach. An agent that can edit the working tree can also write `.git/refs/replace/` (same uid, same bind mount, Claim 6). Plain `git show` and `git log` follow replace refs. In a scratch repo with one replace ref on the `questions.md` blob:

```
plain git show main:  edited paste without guard
useReplaceRefs=false: reviewed paste with guard
log: 3a5b2dc base
```

So the user copies the agent's text, and the log check shows nothing unusual. The guard inside the copied block would refuse the replace ref, but only if the copied block still contains the guard. Q-169 already reads its block this way: `git -C ~/claude-workflows -c core.useReplaceRefs=false show …` (`questions.md:262`). A precise version: `git -c core.useReplaceRefs=false show main:docs/working/questions.md` and `git --no-replace-objects log --oneline --first-parent b71a4e9e..HEAD`. Even then this holds only while the agent has not moved main in a way the log check misses.

Execution: the probe in the log, cwd `…/code-fact-check-i2/probe-c1/r`, exit 0, 2026-10-15T21:35:49Z.

**Evidence:** `docs/working/questions.md:83,262`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/c1-replace-probe.log`

---

## Claim 10: "The guard refuses replace refs, grafts, shallow, `info/attributes`, alternates, any filter, merge or diff driver, include, fsmonitor, hooks path or gpg setting in your git config, and an object that fails `git fsck`; the merge also ignores replace refs and runs no hooks."

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named class as a planted state in the guard harness, and a hooks-off merge with six planted `.git/hooks` scripts. The prose list is a subset of the guard: the guard also refuses `hook.`, `fsck.`, `core.attributesFile`, `extensions.partialClone` and `remote.*.promisor`, and any `merge.*` key, not only drivers. Not established: a crafted pack with valid checksums or a crafted multi-pack-index (rubric C4). A byte-flipped pack was caught (`fsck … exit=4`).
**Legibility-target:** for-orchestrator-synthesis

Harness results, every row in both bash and zsh: `replace-ref rc=1`; `info_grafts-{content,empty,dangling-symlink} rc=1`; `shallow-{…} rc=1`; `info_attributes-{…} rc=1`; `objects_info_alternates-{…} rc=1`; `filter`, `merge-driver`, `merge-dirrenames`, `diff-textconv`, `include`, `includeIf`, `fsmonitor`, `fsmonitor-mixedcase`, `hooksPath`, `gpg-program` all `rc=1`; `rewritten-loose-blob rc=1` (`hash-path mismatch`). The merge line (`questions.md:90`) is `GIT_NO_REPLACE_OBJECTS=1 git -c core.hooksPath=/dev/null -c core.commitGraph=false merge --no-ff …`. With pre-merge-commit, prepare-commit-msg, commit-msg, post-merge, post-commit and reference-transaction hooks planted, that merge printed `merge exit=0` / `no hook ran`.

Execution: `bash run.sh` (cwd `…/code-fact-check-i2`, exit 0, 2026-10-15T21:27:10Z), and the hooks/pack probe (cwd `…/code-fact-check-i2/probe-hooks`, exit 0, 2026-10-15T21:31:10Z).

**Evidence:** `docs/working/questions.md:83,89-90`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/guard-probe.log`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/hooks-pack-probe.log`

---

## Claim 11: "So the merged side is the reviewed commit."

**Location:** `docs/working/questions.md:83`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the repository-state routes that change what `09a2876f` resolves to: replace refs, grafts, shallow, alternates, commit-graph (off), and loose-object rewrites. All are refused or disabled (Claims 10, 15). Not established, and not stated in the prose: crafted packs or multi-pack-index (untested, rubric C4), and environment variables. `GIT_SHALLOW_FILE` passes the guard (`rc=0`) and cuts history (`rev-list --count` 2→1). That falls under the next sentence's "the shell it runs in" (Claim 12). `GIT_GRAFT_FILE` is caught, because `--git-path info/grafts` follows it (`rc=1`).
**Legibility-target:** for-orchestrator-synthesis

Within the boundary the paragraph draws, the claim holds for every route tested. The residue is named here rather than downgrading the verdict, because the prose qualifies it straight after ("The paste does not check … the shell it runs in").

Execution: the env probe, cwd `…/code-fact-check-i2/probe/clean`, exit 0, 2026-10-15T21:35:19Z.

**Evidence:** `docs/working/questions.md:83`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/env-probe.log`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/guard-probe.log`

---

## Claim 12: "The paste does not check what main itself holds (… hence the log check) or the shell it runs in (an alias for `git` or `test` defeats any guard written into a paste)"; "Run it while no agent session or subagent is working"

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absence of any check on main's content or the shell. The guard's only check on the base is `test "$(git branch --show-current)" = main`. Residue: the example names aliases only. An exported variable (`GIT_SHALLOW_FILE`, executed) is a second shell route of the same kind. The log check itself can be fooled by a replace ref (Claim 9).
**Legibility-target:** for-orchestrator-synthesis

Quoted (`questions.md:88`): `cd /workspace && test "$(git branch --show-current)" = main && \`. Nothing else in the block reads main's history or content (paraphrased: no quote available because the claim covers the absence of a check across the whole block, lines 88–91). `GIT_SHALLOW_FILE guard rc=0` is in `env-probe.log`.

Execution: as in Claim 11.

**Evidence:** `docs/working/questions.md:83,88-91`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/env-probe.log`

---

## Claim 13: "five of those nine merges (Q-110, doc drift, Q-160 and the two docs branches) conflict with main's new rows, each only in the append-only `docs/reviews/override-log.md`" (A4)

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each merge in ready-r2 re-run with `merge-tree` on its own two parents (exactly those five conflict, only in override-log), and each of the five units merged alone onto b71a4e9e (each conflicts in override-log). Not stated, and not misleading: the rebuild-hint and one-workspace tips also conflict with b71a4e9e alone, but they merge cleanly in the branch's order.
**Legibility-target:** for-orchestrator-synthesis

Per-merge results: `t69 rc=0`, `q110 rc=1 override-log`, `doc-drift rc=1 override-log`, `q160 rc=1 override-log`, `q096 rc=0`, `branch-verify rc=1 override-log`, `dd-015 rc=1 override-log`, `rebuild-hint rc=0`, `one-workspace rc=0`. Against main alone, q110, docdrift, q160, branchverify and dd015 are all `rc=1 conflicts: docs/reviews/override-log.md`.

Execution: `git merge-tree --write-tree --name-only …`, cwd `/workspace`, exit 0, 2026-10-15T21:31:34Z.

**Evidence:** `docs/working/questions.md:83`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/merge-tree-units.log`

---

## Claim 14: "Its diff from a760a5e5 adds exactly what main added since then (in the override log, main's new rows sit before a760a5e5's rather than after)" (A5)

**Location:** `docs/working/questions.md:85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sorted +/− lines of every file in `a760a5e5..09a2876f` against `92f3b080..b71a4e9e`, where 92f3b080 is the merge base of a760a5e5 and main. Both sets have the same 19 files and identical sorted line sets. It also covers where the override-log rows sit. It does not cover byte order within the other 18 files, where no reordering was found by the sorted comparison but order was not compared.
**Legibility-target:** for-orchestrator-synthesis

`same file list`, no `DIFFERS` line. Override log: the a760→r2 diff removes 0 lines and adds 15, the same as main's 15. The hunks are `@@ -827,0 +828,15 @@` in both diffs. a760a5e5's own 23 rows were at `+828,23` over the base, so in r2 main's rows are 828–842 and a760a5e5's are 843–865 (865 lines in total).

Execution: the diff comparison in the log, cwd `/workspace`, exit 0, 2026-10-15T21:32Z.

**Evidence:** `docs/working/questions.md:85`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/a5-diff.log`

---

## Claim 15: The guard line (identical in Q-162, Q-163 and Q-164) refuses every planted class, passes on a clean repo and a linked worktree in bash and zsh, runs nothing planted, and cannot pass on a read error

**Location:** `docs/working/questions.md:89,118,150`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 34 planted cases and 2 clean cases, each in bash and zsh, in fresh scratch repos with an isolated HOME, plus a read-only run on the real `/workspace`. Residues:
(a) The guard never reads `git config`'s exit status, because `$(…)` inside `test -z` drops it, so exit 1 and exit >1 are treated alike. A bad config line or an unreadable repo or included config still refuses, but only because the next git command (`rev-parse`) dies on the same file.
(b) An unreadable global `~/.gitconfig` holding `core.fsmonitor` passes (`rc=0`). The marker did not run and git skips that file for the merge too, so the planted key has no effect.
(c) `git fsck` itself runs a planted `core.fsmonitor` (direct probe: `marker_ran=YES`). The guard is safe only because the config check comes before fsck in the `&&` chain. Reordering the chain would break that.
**Legibility-target:** for-orchestrator-synthesis

`grep -F '{ test -z "$(git for-each-ref refs/replace/)"' q.md | sort | uniq -c` gives `3`: the three lines are byte-identical. Results, both shells: `clean rc=0`, `linked-worktree-clean rc=0`. Every planted case in Claim 10 gives `rc=1`. So do `linked-wt-common-grafts`, `linked-wt-common-shallow-empty`, `fsck` (`fsck.missingEmail`), `attributesFile`, `partialClone`, `promisor`, `config.worktree-fsmonitor`, `include-real-file`, `env-GIT_CONFIG_COUNT-fsmonitor` and `env-GIT_CONFIG_PARAMETERS-mergedrv`. `marker_ran=no` on every row. Read errors: `bad-config-line rc=1` (`fatal: bad config line 6`), `unreadable-config rc=1`, `unreadable-include rc=1`, `unreadable-global rc=0`. Direct probes: `direct-fsck-with-fsmonitor marker_ran=YES`; `direct-config/rev-parse/for-each-ref/branch-with-fsmonitor marker_ran=no`. On the real `/workspace`: `bash rc=0 secs=5`, `zsh rc=0 secs=5`.

Execution: `bash run.sh` (cwd `…/code-fact-check-i2`, exit 0, 2026-10-15T21:27:10Z); the guard on `/workspace` (cwd `/workspace`, exit 0, 2026-10-15T21:28:33Z).

**Evidence:** `docs/working/questions.md:89,118,150`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/guard-probe.log`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/guard-workspace.log`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/run.sh`

---

## Claim 16: Q-180's branch landed first, then Q-162, then Q-163 and Q-164 in either order land the same tree (the pastes as written)

**Location:** `docs/working/questions.md:88-91,117-121,149-153`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a scratch clone of `/workspace`: main reset to b71a4e9e, `merge --no-ff 8ab42eec`, then the three paste blocks verbatim with only `cd /workspace` rewritten, in bash and zsh. Not established: Q-162's branch-deletion loop, which fails in a clone without those worktrees (`fatal: '.claude/wt-build-loop-u4b1' is not a working tree`) after the merge has landed.
**Legibility-target:** for-orchestrator-synthesis

Both shells: the Q-180 land is clean (tree `91abdaac…`). Q-162 gives tree `062c5b98…`. Order 163→164 and order 164→163 both end at tree `33a44633bedb72bc96d20582d2887fa2e87c45f9`, `SAME`, with a clean status. Every guard passed in the clone. The landed tree differs from 6c841192 only in the 10 files Q-180's branch changes.

Execution: `bash land.sh bash` and `bash land.sh zsh`, cwd `…/code-fact-check-i2`, exit 0 for both, 2026-10-15T21:29:15Z.

**Evidence:** `docs/working/questions.md:88-91,117-121,149-153`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/land.log`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/land.sh`

---

## Claim 17: Q-164 "with the questions, questions-archive, roadmap and override-log conflicts resolved again" (A6)

**Location:** `docs/working/questions.md:146`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the conflict set of the U5 tip and of e088c7e3 against ready-r2. It does not re-check each resolution's content (iteration 1, Claim 17).
**Legibility-target:** for-orchestrator-synthesis

`merge-tree 09a2876f 7c91b974` and `merge-tree 09a2876f e088c7e3` both list `docs/reviews/override-log.md`, `docs/roadmap.md`, `docs/working/questions-archive.md` and `docs/working/questions.md`. 7326d715's parents are `09a2876f e088c7e3`.

Execution: `git merge-tree --write-tree --name-only …`, cwd `/workspace`, exit 0, 2026-10-15T21:33Z.

**Evidence:** `docs/working/questions.md:146`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/a6-a7.log`

---

## Claim 18: "the decision-015 idea (from the 2026-10-14 cycle commit 46942678, which e088c7e3 carried)" (A7)

**Location:** `docs/working/questions.md:146`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which commit introduced the roadmap idea "Re-run decision 015's step 4 as a divergent design", and which commits carry it. The correction the sentence makes (the idea did not come from U5) holds.
**Legibility-target:** for-author

`git log -S"Re-run decision 015's step 4 as a divergent design" e088c7e3 -- docs/roadmap.md` lists only `63af3551 docs(cycle): dev cycle 2026-10-14, run by hand`. Idea counts: `63af3551^ 0`, `63af3551 1`, `46942678 1`, `7c91b974 0`. 46942678 (`parents=63af3551`) carries the idea but did not add it. A precise wording: "from the 2026-10-14 cycle commit 63af3551, carried into e088c7e3 by its first parent 46942678".

Execution: in the log, cwd `/workspace`, exit 0, 2026-10-15T21:36Z.

**Evidence:** `docs/working/questions.md:146`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/static-git-facts.log` (section "A7 origin")

---

## Claim 19: Q-167(b) "on a launcher older than the fix, the first line does not print the ERROR and the second and third print the project list: … stop at the first line that does not print `exit=2`" (A8)

**Location:** `docs/working/questions.md:219`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers main's (pre-fix) `cc-isolated.sh` argument parser for the three lines. It is static because the launcher needs host tooling (devcontainer CLI, trust manifest) that the sandbox lacks. Not established: the host's actual output.
**Legibility-target:** for-author

Pre-fix parser (`devcontainer-config/cc-isolated.sh` at b71a4e9e, `:749`): `*)            ws_arg="$1"; shift ;;`. The last positional wins, so line 1 targets `~/code/b`. `resolve_workspace` then prints `"ERROR: not a directory: $start"` and `return 1`, and under `set -euo pipefail` (`:66`) the launcher exits 1. So when `~/code/b` is absent, line 1 prints *an* ERROR, not the one-workspace one, and `exit=1`. When `~/code/b` is a git repository, it launches a session there. Lines 2 and 3 reach `list) list_projects; exit 0 ;;`, as stated. The stop rule keys on `exit=2`, so it stops correctly. "Does not print the ERROR" could mislead a reader who scans for the word ERROR. A precise wording: "the first line exits 1 (or, if `~/code/b` is a repository, launches there)".

**Evidence:** b71a4e9e `devcontainer-config/cc-isolated.sh:66,729-751,790-797`; `resolve_workspace()` (same file)

---

## Claim 20: Q-169 `mkdir -p ~/cc-verify && git -C ~/claude-workflows -c core.useReplaceRefs=false show d25254da…:docs/working/spike-cc-verify-q117.md | awk … > ~/cc-verify/q117-spike.txt && sha256sum …` gives hash `032cc9a8…afb7`

**Location:** `docs/working/questions.md:262,265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the extraction with `-C /workspace` (the same repository, bind-mounted) under bash and zsh, and d25254da being an ancestor of ready-r2. It does not cover the host's `~/claude-workflows` path.
**Legibility-target:** for-orchestrator-synthesis

Result: `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7` from the file, from bash and from zsh. `d25254da-in-ready-r2`.

Execution: in the log, cwd `…/code-fact-check-i2`, exit 0, 2026-10-15T21:30:21Z.

**Evidence:** `docs/working/questions.md:262,265`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/q169.log`

---

## Claim 21: "It uses `git -C` rather than `cd`, so a zsh prompt does not run `git status` in the checkout (an agent-planted `core.fsmonitor` would run on the host)."

**Location:** `docs/working/questions.md:265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this: `git -C <repo> -c core.useReplaceRefs=false show <hash>:<path>` with planted `core.fsmonitor`, a smudge filter, `filter.x.textconv` and `diff.x.textconv` (plus a `.gitattributes` routing to them) ran none of them, while `git status` in the checkout ran fsmonitor. Not established: a shell already sitting in the checkout before the paste (its prompt has already run), or prompts that inspect other directories.
**Legibility-target:** for-orchestrator-synthesis

`show exit=0`, `no marker ran`. Control: `m-fsm` created by `git status`.

Execution: in the log, cwd `…/code-fact-check-i2/probe-show`, exit 0, 2026-10-15T21:30:43Z.

**Evidence:** `docs/working/questions.md:265`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/q169-show-probe.log`

---

## Claim 22: Q-170 "88 of 116 `devcontainer-config/` commits carry `Live-verified: no` (the doc says 87; a recount gives 88)" (C2)

**Location:** `docs/working/questions.md:279`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-merge commits touching `devcontainer-config/` since 2026-09-09, reachable from f050b487, and the DD doc's own figure at f050b487. It does not cover commits after f050b487.
**Legibility-target:** for-orchestrator-synthesis

The recount gives `non-merge total=116 live-verified-no=88`, with both date boundaries. The doc (`dd-015-step4-isolation-mechanism.md:34` at f050b487) says: "of the 116 non-merge commits touching `devcontainer-config/`, **87 carry …".

Execution: in the log, cwd `/workspace`, exit 0, 2026-10-15T21:34:39Z.

**Evidence:** `docs/working/questions.md:279`; f050b487 `docs/working/dd-015-step4-isolation-mechanism.md:34`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/c2-count.log`

---

## Claim 23: Commit 8ab42eec: "Executed by the security critic against 19 planted states in bash and zsh; passes on the real /workspace in ~5 s."

**Location:** commit 8ab42eec message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the count against the security review's text, and the 5 s timing (re-run here). It does not re-run the security critic's harness.
**Legibility-target:** for-author

The security review says "21 cases × bash and zsh" (`docs/reviews/security-review-2026-10-15-q180.md:61`) and "executed against 21 planted states" (`:201`). Its refusal list has 18 items plus the `fsck.skipList` probe, which makes 19 planted states and 2 clean passes. That is consistent with 19, but the review itself says 21. The timing holds: `bash rc=0 secs=5`, `zsh rc=0 secs=5` on `/workspace`.

Execution: the guard on `/workspace`, cwd `/workspace`, exit 0, 2026-10-15T21:28:33Z.

**Evidence:** `docs/reviews/security-review-2026-10-15-q180.md:61-77,201`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/code-fact-check-i2/guard-workspace.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9** (`docs/working/questions.md:83`): `git show main:docs/working/questions.md` and the `git log` check both follow replace refs. An agent that can edit the working tree can make both show other text (executed). Use `git -c core.useReplaceRefs=false show main:…` and `git --no-replace-objects log …`, as Q-169 already does.

### Stale
- None.

### Mostly Accurate
- **Claim 3** (`docs/working/questions-archive.md:2872`): "four merge branches were rebuilt … old ones kept". Three were rebuilt and kept; `merge/q145-r2` has no predecessor.
- **Claim 4** (`docs/working/questions-archive.md:2872`): "everything the state gate refuses". The guard omits `log.showSignature` (guard passes, executed) and the `origin/HEAD` check.
- **Claim 18** (`docs/working/questions.md:146`): the decision-015 idea was added by 63af3551; 46942678 only carries it.
- **Claim 19** (`docs/working/questions.md:219`): on a pre-fix launcher line 1 prints a different ERROR and exits 1, or launches into `~/code/b` if that is a repository. The `exit=2` stop rule still works.
- **Claim 23** (commit 8ab42eec): the security review says 21 planted states; 19 matches its refusal list.

### Unverifiable
- None. Claim 8's host value rests on the 2026-10-15 Q-139 record; the container cannot observe the host.

---

## Goal-Alignment Note

The user's goal is to run Q-162, then Q-163 and Q-164, safely. On the evidence here the pastes do what they claim. They land one tree in both orders and both shells with Q-180's branch first (Claim 16). The guard refuses every planted class named in the brief and runs nothing planted (Claims 10, 15). All but one of the wording fixes A4–A9, A11, C1, C2 landed accurately; the exception is C1. The one Incorrect (Claim 9) does not make the pastes less safe than they were. It is a gap in the new advice on where to copy them from: that advice does not protect against the replace-ref route the guard itself refuses, and the fix is two flags. Two load-bearing facts are not stated anywhere in the prose:
- The guard stays safe only while the `git config` check comes before `git fsck`, since fsck runs a planted fsmonitor (Claim 15c).
- An exported `GIT_SHALLOW_FILE` passes the guard (Claims 11–12). It falls under "the shell it runs in", but the example names only aliases.

Neither blocks the pastes.
