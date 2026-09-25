# Code Fact-Check Report

**Repository:** claude-workflows, worktree `/workspace/.claude/wt-q058p2`, branch `skill-fixtures` at `feba07d`
**Scope:** fix commits `c7c4e34..feba07d` (9 commits), answering the pass-1 rubric `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md` (R1, R2, A1–A5, C1–C3). Files: `devcontainer-config/install.sh`, `test/install-host.bats`, `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `docs/working/plan-copy-install-bare-host.md`, `guides/bare-host-hook-wiring.md`, and the nine commit messages. Commit-message locations are `log.txt:<line>`, the scratchpad copy of `git log c7c4e34..feba07d` (`.../scratchpad/review2/log.txt`). Earlier branch history was read as context only.
**Checked:** 2026-09-25
**Commit:** feba07d
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 43
**Summary:** 37 verified, 1 mostly accurate, 0 stale, 4 incorrect, 1 unverifiable

Reading discipline. `install.sh` was read whole at `feba07d` (1104 lines), along with the full 72 KB diff and all nine commit messages. Every verdict inside a function rests on a reading of the whole function. Hallucination-pattern log: `docs/reviews/hallucination-patterns.md` was read first. The nearest logged class is "a specific measured value quoted from a checked-in artifact set that does not contain it" (test-count denominators). The 166/166 counts here were re-run and hold (Claim 41). The NOTE-count miss (Claim 24a) was miscounted, not quoted from an artifact. No Incorrect verdict below claims a symbol that does not exist, so nothing new goes into the log.

Execution environment. All probes are hermetic: a temp `HOME` and `TMPDIR` under the session scratchpad, `GIT_CONFIG_NOSYSTEM=1`, stub `pgrep`/`docker` (except where stated), a throwaway fake repo built the same way as `fake_repo` in `test/install-host.bats`, and every destination under the temp dir. Nothing touched the real `~/.claude`, `~/.config` or `/workspace/.git`. The probes and their captured output are in `docs/reviews/execution-logs/q058p2-fc/`. Each `.sh` has a shebang and is shellcheck-clean. Each run's `.ts` file holds its start time, exit code and (for longer runs) end time. Unless a claim says otherwise, probes ran from cwd `/workspace/docs/reviews/execution-logs/q058p2-fc` as `TMPDIR=<scratchpad> bash <probe>.sh /workspace/.claude/wt-q058p2/devcontainer-config/install.sh > <probe>.log`. git is 2.39.5.

---

## Claim 1: "Run from inside a Claude Code session, the whole run exits 1 at startup, because the no-agent check below finds that session; the `CLAUDECODE` skip stays as a backstop"

**Location:** `README.md:28-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the startup exit 1, before any staging, when a Claude Code process of the uid is running (tested from inside this Claude Code session with the real `pgrep`). Does not establish that the process found is the invoking session itself rather than another one, or detection of a session whose command line the pattern misses (Claim 17's residuals).
**Legibility-target:** for-orchestrator-synthesis

`main` runs the gate before anything is staged or the trap is set:

```bash
# devcontainer-config/install.sh:1093-1100
  agent_gate "Nothing was staged or installed."

  HOST_TMP="" HOST_LOCK="" DC_TMP="" STAGED_COMMIT="" HOST_NEW_IN="" HOST_MADE_DEST=""
  trap host_cleanup EXIT

  DECLINED=0
  install_devcontainer
  install_claude_home
```

Execution: `probe-docs.sh` §3 used the real `pgrep`, a stub docker, `env -u CLAUDECODE` and `--yes`, and was started inside this Claude Code session. Result: `exit 1; refused at startup: 1; staged anything: no; blessed: 0`, and the refusal listed "Claude Code processes of uid 1000". The `CLAUDECODE` skip is still in place at `install.sh:663-666` (`if [ -n "${CLAUDECODE:-}" ]; then echo "Skipped host target ..."`).

**Evidence:** `devcontainer-config/install.sh:1093-1100`, `devcontainer-config/install.sh:663-666`; command `bash probe-docs.sh .../install.sh`, cwd `docs/reviews/execution-logs/q058p2-fc`, exit 0, 2026-09-25T07:55:43Z; output `docs/reviews/execution-logs/q058p2-fc/probe-docs.log`

---

## Claim 2: "At startup, again before the `~/.claude` target stages, and after each y, it refuses ... These are checks at those moments, not a lock"

**Location:** `README.md:36-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four `agent_gate` call sites and their order relative to staging and writing. Does not establish what the gate detects (Claims 17 and 27).
**Legibility-target:** for-orchestrator-synthesis

The call sites are `install.sh:1093` (startup), `:481` (target 1, after its y, before `mkdir -p "$DEST"`), `:677` (host target, before `assemble "$stage"` at `:708`) and `:864` (host target, after its y, before the hash check and the swap). No lock spans them. They are point-in-time `pgrep`/`docker ps` calls (paraphrased — no quote available because the claim is about the absence of any lock or watcher across four separate call sites; `agent_gate` at `:982-1032` is a single sample that returns or exits).

**Evidence:** `devcontainer-config/install.sh:481`, `:677`, `:864`, `:982-1032`, `:1093`

---

## Claim 3: "install.sh checks at startup, before the host target stages, and after each y ... without a reachable docker it prints a NOTE line at each check ... Run from inside a Claude Code session, install.sh finds that session and exits 1 at startup, before either target."

**Location:** `devcontainer-config/install.sh:51-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the check moments, one NOTE per check that actually runs, and the in-session startup exit. Does not establish how many checks run per run (that depends on the answers; see Claim 24a).
**Legibility-target:** for-orchestrator-synthesis

The unreachable-docker branch prints exactly one NOTE per `agent_gate` call:

```bash
# devcontainer-config/install.sh:1006-1011 (excerpt ends :1011; enclosing agent_gate() continues to :1032 — read)
    if ! ctrs="$(timeout 20 docker ps --filter label=cc-project \
                   --format '{{.Names}} cc-project={{.Label "cc-project"}}' 2>"$errf")"; then
      err="$(head -n 1 "$errf" 2>/dev/null)"
      echo "NOTE: docker is unreachable ($err): cc-isolated containers not checked, treated as none running." | vis_or_die
      ctrs=""
    fi
```

Execution: `probe-docs.sh` §1 counted one NOTE per check that ran, for every answer pattern. §3 is Claim 1's in-session run.

**Evidence:** `devcontainer-config/install.sh:51-63`, `:997-1014`; `docs/reviews/execution-logs/q058p2-fc/probe-docs.log` (exit 0, 2026-09-25T07:55:43Z)

---

## Claim 4: "docker's own DOCKER_HOST/DOCKER_CONTEXT choose which daemon is asked"

**Location:** `devcontainer-config/install.sh:54-55`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these two variables reaching the `docker ps` call unchanged. Does not establish docker's own resolution order among env, context and config file (docker behaviour, not checked).
**Legibility-target:** for-orchestrator-synthesis

`install.sh` never sets, unsets or reads `DOCKER_HOST` or `DOCKER_CONTEXT` (paraphrased — no quote available because the claim covers absence of code: `rg DOCKER_ devcontainer-config/install.sh` matches only the help text at `:55`). Execution: in `probe-docs.sh` §2 a logging docker stub recorded `DOCKER_HOST=tcp://probe.invalid:2375 DOCKER_CONTEXT=probe-ctx`, the values the probe exported.

**Evidence:** `devcontainer-config/install.sh:55`, `:1006`; `docs/reviews/execution-logs/q058p2-fc/probe-docs.log` (exit 0, 2026-09-25T07:55:43Z)

---

## Claim 5a: "vis_or_die: vis for every line shown outside review_diff ... and mode_diff ... In a pipeline this runs in a subshell: it prints the error, its exit fails the pipeline, and set -e/pipefail then stops the script with exit 1."

**Location:** `devcontainer-config/install.sh:133-137`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `| vis` site in the file (all but `review_diff:346` and `mode_diff:380` now pipe to `vis_or_die`) and the exit-1-with-message path at a host REPLACE line (T74). Does not establish the mode_diff rationale (Claim 5b), or that errexit is live at every call site under future call shapes (today no call site is under `||`, `if` or `!`).
**Legibility-target:** for-orchestrator-synthesis

`rg -n '\| *vis\b|vis_or_die' install.sh` finds `vis_or_die` at `:209, :253, :272, :310, :421, :767, :773, :792, :813, :814, :821, :1009, :1030`, and plain `vis` only at `:346` (review_diff, which checks `PIPESTATUS`) and `:380` (mode_diff). The function:

```bash
# devcontainer-config/install.sh:138-145
vis_or_die() {
  local rc=0
  vis || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "ERROR: could not show output safely (vis exit $rc), so install.sh stopped. Nothing was installed." >&2
    exit 1
  fi
}
```

Execution: T74 passes at `feba07d` and fails at `c7c4e34` (Claim 40).

**Evidence:** `devcontainer-config/install.sh:133-145`, `:346`, `:380`; `docs/reviews/execution-logs/q058p2-fc/bats.log` (T74 ok), `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log` (T74 not ok)

---

## Claim 5b: "and mode_diff (whose lines review_diff re-shows)"

**Location:** `devcontainer-config/install.sh:133-134`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether `review_diff` shows the MODE lines that `mode_diff` prints. Does not establish that a vis failure in mode_diff goes unnoticed: a vis that fails consistently also fails in the `review_diff` that runs right after, which exits with its own message.
**Legibility-target:** for-author

`review_diff` never shows a mode change. It prints `diff -ruNa`, which compares content only, and `mode_diff`'s own header says so:

```bash
# devcontainer-config/install.sh:364-367
# mode_diff <dest> <src-prefix> <item...>: print a MODE line for each regular file
# present in both trees whose permission bits differ. diff compares content
# only, so a committed `chmod +x` alone reviewed as "(none)" and never
# installed (fact-check claim 17). Returns 1 when any mode differs.
```

```bash
# devcontainer-config/install.sh:346 (excerpt; enclosing review_diff() :328-362 — read)
    diff -ruNa "$dest/$item" "$src$item" 2>&1 | vis && st=(0 0) || st=("${PIPESTATUS[@]}")
```

`mode_diff` is always called under `||` or `if !` (`:457`, `:835`), so errexit is off inside it, and a failed `echo "MODE ..." | vis` at `:380` drops that line without a message. The accurate version, which is what the commit message says (`log.txt:204-213`): review_diff re-shows *the same items* (their content), not mode_diff's lines. A MODE line lost this way is not re-shown anywhere. The comment's mechanism is refuted, although its practical conclusion holds for a vis that fails persistently.

**Evidence:** `devcontainer-config/install.sh:133-134`, `:346`, `:364-386`, `:457-458`, `:835-837`

---

## Claim 6: "git_state_gate: exit the script, naming each entry, when the checkout's own git state names a command that git would run as the user during this install"

**Location:** `devcontainer-config/install.sh:156-163`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate against git state that runs a command during install.sh's own git calls: the hooks directory and `core.hooksPath`, plus 17 other command-naming keys. Does not establish behaviour on other git versions (probed on 2.39.5; `post-index-change` exists since git 2.22), or the user's global/system config (out of the gate's stated scope).
**Legibility-target:** for-author

The gate checks only config keys matching `^(filter\.|core\.fsmonitor|include)` and a non-empty `info/attributes` (`install.sh:171`, `:174-200`). It never looks at `.git/hooks/` or `core.hooksPath`. `git status` (`:304-305`) refreshes the index and writes it back when stat data changed, and writing the index runs the `post-index-change` hook. A writer to `.git`, such as a cc-isolated container through its bind mount, can plant that hook. Any tracked file under the payload paths with changed stat data then triggers the write, and the writer can arrange that by touching one.

Execution (`probe-r1-git-exec.sh`, each case a fresh fake repo, `hooks/h.sh` touched first):

```
### A .git/hooks/post-index-change: install.sh exit 0; refused-by-gate: 0; blessed: 1
    markers fired: hook-post-index-change
### B core.hooksPath=<dir with post-index-change>: install.sh exit 0; refused-by-gate: 0; blessed: 1
    markers fired: hookspath-pic
```

So a planted hook runs as the host user, unsandboxed, the gate does not name it, and the install goes on to bless. This is the container-to-host path the comment describes, through state it does not check. None of the other 17 command-naming keys probed (diff.external, core.pager, pager.status/archive, core.sshCommand, gpg.program, uploadpack.packObjectsHook, credential.helper, core.askPass, core.editor, sequence.editor, core.gitProxy, core.alternateRefsCommand, tar.tar.command, diff.x.textconv with committed attributes, url.ext::…insteadOf with protocol.ext.allow, log.showSignature + gpg.program) fired a marker.

**Evidence:** `devcontainer-config/install.sh:156-211`, `:291`, `:304-305`; command `bash probe-r1-git-exec.sh .../install.sh`, cwd `docs/reviews/execution-logs/q058p2-fc`, exit 0, 2026-09-25T07:50:16Z; output `docs/reviews/execution-logs/q058p2-fc/probe-r1-git-exec.log`

---

## Claim 7: "`git archive` runs a `filter.<x>.smudge` that an attributes file assigns, and `git status` runs `core.fsmonitor` and clean filters"

**Location:** `devcontainer-config/install.sh:158-160`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers smudge on `git archive --format=tar` and clean on `git status` for a stat-dirty file, under `info/attributes` plus local filter config. Does not establish the fsmonitor half by direct run (T66's pre-fix failure and the fix's own tests cover it).
**Legibility-target:** for-orchestrator-synthesis

Execution, run in a scratch repo with a temp `HOME`: after `git archive --format=tar HEAD`, the marker `SMUDGE-RAN` existed; after `touch a.md; git -c core.fsmonitor=false status --porcelain`, `CLEAN-RAN` existed (paraphrased — no quote available because the command was an inline one-liner; its full output is the cited log).

**Evidence:** `devcontainer-config/install.sh:158-160`, `:238`, `:304`; `docs/reviews/execution-logs/q058p2-fc/git-filter-mechanism.log` (2026-09-25T07:56:45Z, exit 0)

---

## Claim 8: "Called before any other git command on the checkout (see assemble)."

**Location:** `devcontainer-config/install.sh:162-163`, `:291`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call order: `git_state_gate` is the first git call in both targets, and nothing in `main` calls git before it. The gate's own `rev-parse --git-path` and `git config --file` calls come first but run nothing (Claim 9). Does not establish anything about state written between the gate and the later git calls (the no-agent gate's job).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:288-296 (excerpt ends :296; enclosing assemble() continues to :321 — read)
assemble() {
  local stage="$1" commit dirty home_dirty
  shift
  git_state_gate   # before any other git call on the checkout (review R1)
  rm -rf "$stage"
  mkdir -p "$stage"
  commit="$(head_commit)" || exit 1
  STAGED_COMMIT="$commit"
  extract_commit "$commit" "$stage" "${CLAUDE_HOME_SRC[@]}"
```

Every other git call is at `:149` (head_commit), `:226`, `:238` (extract_commit) and `:304-305` (status), and all are reached only through `assemble` or after it. `install_devcontainer` runs no git before `assemble` at `:429`, and neither does `install_claude_home` before `:708` (paraphrased — no quote available because the claim covers absence of git calls across two whole functions, read in full). Probe cases D–G refused before any marker fired.

**Evidence:** `devcontainer-config/install.sh:149`, `:226`, `:238`, `:288-305`, `:402-429`, `:649-708`; `docs/reviews/execution-logs/q058p2-fc/probe-r1-git-exec.log`

---

## Claim 9: "The reads here run nothing: `git config --file`/`--local` does not follow include.path unless asked (--no-includes makes that explicit) ... --git-path resolves a linked worktree ... to the common dir for info/attributes and config, and to the worktree's own dir for config.worktree."

**Location:** `devcontainer-config/install.sh:165-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate's own `rev-parse --git-path` and `git config --file --no-includes` calls running no command under every planted key and hook in the probe, the `include.path` refusal (T66), and config.worktree resolution for the main and a linked worktree. Does not establish repos where `extensions.worktreeConfig` is off but a config.worktree exists (the gate reads the file anyway, which is stricter than git).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:174-183 (excerpt ends :183; enclosing git_state_gate() continues to :211 — read)
  for f in config config.worktree; do
    f="$(git -C "$REPO_ROOT" rev-parse --git-path "$f")" || f=""
    case "$f" in ''|/*) ;; *) f="$REPO_ROOT/$f" ;; esac
    if [ -z "$f" ] || { [ "${f##*/}" = config ] && [ ! -f "$f" ]; }; then
      echo "ERROR: could not find the git config of $REPO_ROOT. Nothing was installed." >&2
      exit 1
    fi
    [ -f "$f" ] || continue   # config.worktree is optional
    rc=0
    out="$(git --no-pager config --file "$f" --no-includes --get-regexp "$GIT_EXEC_KEYS_RE")" || rc=$?
```

Execution: probe D refused `.git/config.worktree: core.fsmonitor` (main worktree), D2 refused `config.worktree: filter.pwn.smudge`, and E, run from a linked worktree, refused `.git/worktrees/wt/config.worktree: core.fsmonitor`. No marker fired in any case. T66 covers `include.path` and a linked worktree's common-dir attributes.

**Evidence:** `devcontainer-config/install.sh:165-200`; `docs/reviews/execution-logs/q058p2-fc/probe-r1-git-exec.log`; `docs/reviews/execution-logs/q058p2-fc/bats.log` (T66 ok)

---

## Claim 10: "core.fsmonitor=false: status would otherwise run the configured fsmonitor command (... this also covers one set in the user's global config)"

**Location:** `devcontainer-config/install.sh:301-305`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `git status` call in the file (two). Does not establish other commands that status can run (clean filters from a global filter config; the post-index-change hook, Claim 6).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:304-305
  dirty="$(git -C "$REPO_ROOT" -c core.quotePath=true -c core.fsmonitor=false status --porcelain --untracked-files=all -- "${CLAUDE_HOME_SRC[@]}" "$@")"
  home_dirty="$(git -C "$REPO_ROOT" -c core.quotePath=true -c core.fsmonitor=false status --porcelain --untracked-files=all -- "${CLAUDE_HOME_SRC[@]}")"
```

`rg -n '\bgit\b' install.sh` finds no other `status` call. A `-c` value outranks every config file, global included (paraphrased — no quote available because this is git's documented precedence rule, not code in this repo).

**Evidence:** `devcontainer-config/install.sh:301-305`

---

## Claim 11: "A1: ... Hash it before the review; after the y the stage, and then what landed in $DEST, must hash the same, or nothing is blessed ... On a mismatch ... the copied items are removed, so no unreviewed file stays live"

**Location:** `devcontainer-config/install.sh:441-446`, `:499-509`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when the hash is taken (after the mirror rebuild, before the review), both checks, removal of the PAYLOAD items with no `--bless` on a post-copy mismatch, and the resulting state. Does not establish protection against a stage swapped for the review and swapped back before the y (stated as not covered), or edits to `$DEST` after the post-copy check.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:447-448
  local reviewed_hash
  reviewed_hash="$(tree_hash "$stage" "" "${PAYLOAD[@]}")"
```

```bash
# devcontainer-config/install.sh:502-509 (excerpt; enclosing install_devcontainer() :402-531 — read)
  if [ "$(tree_hash "$DEST" "" "${PAYLOAD[@]}")" != "$reviewed_hash" ]; then
    for item in "${PAYLOAD[@]}"; do rm -rf "${DEST:?}/$item"; done
    echo "ERROR: the devcontainer config copied into $DEST differs from what the review" >&2
    ...
    exit 1
  fi
```

The pre-copy check (`:483-487`) runs after `agent_gate` at `:481` and before `mkdir -p "$DEST"`, so a mismatch there leaves `$DEST` untouched. Execution (`probe-r2-a1.sh`, A1-a, a reinstall with a cp stub that alters `devcontainer.json` as it lands): exit 1, no BLESS, the message printed. `$DEST` then holds only `projects/` (registrations kept) and a pre-existing non-PAYLOAD file. The previous config was removed by the copy loop's `rm -rf` (`:496`). `~/.local/bin/cc-isolated` is left as a dangling link, and running it exits 127. A1-b, a first install: `$DEST` holds only `projects/` and no bin link is created. So a mismatch fails closed, with no working config until a clean rerun, as the message says. T69 and T70 pass.

**Evidence:** `devcontainer-config/install.sh:441-531`; `docs/reviews/execution-logs/q058p2-fc/probe-r2-a1.log` (exit 0, 2026-09-25T07:51:56Z); `docs/reviews/execution-logs/q058p2-fc/bats.log` (T69, T70 ok)

---

## Claim 12: "tree_hash ... The same tree hashes the same wherever it sits" / "payload_hash ...: tree_hash of every host entry name, plus the provenance manifest's bytes"

**Location:** `devcontainer-config/install.sh:572-597`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refactor keeping payload_hash's inputs (listing with path, type, mode and link target; per-file sha256; manifest bytes). The digest *values* differ from the old function's because of one extra hashing layer, but none is persisted or compared across versions. Does not establish anything beyond equality comparison within a run.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:576-584
tree_hash() {
  local dir="$1" pfx="$2" name
  shift 2
  for name in "$@"; do
    echo "== $name"
    find "$dir/$pfx$name" -printf '%P\t%y\t%m\t%l\n' | LC_ALL=C sort
    find "$dir/$pfx$name" -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum | cut -d' ' -f1
  done | sha256sum | cut -d' ' -f1
}
```

The loop body is byte-for-byte the removed body of the old `payload_hash` (diff hunk at `@@ -462,21 +569,28 @@`), and `payload_hash` now hashes `tree_hash`'s digest followed by the same `== manifest` line and manifest hash (`:590-597`).

**Evidence:** `devcontainer-config/install.sh:572-597`; `.../scratchpad/review2/diff.patch` (hunk `@@ -462,21 +569,28 @@`)

---

## Claim 13: "host_cleanup: main's EXIT trap. Removes both stages and any unswapped host copies, and releases the lock, if this run took it." / "A destination this run created only to hold the lock and copies."

**Location:** `devcontainer-config/install.sh:615-626`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cleanup on n, SIGTERM, SIGINT (default disposition) and SIGHUP at the host prompt, on a first install and on an existing destination. Does not establish SIGKILL (never trappable), or removal of parent directories that `mkdir -p` created (stated in 6ec64c3 as not removed).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:617-626
host_cleanup() {
  if [ -n "$HOST_TMP" ]; then rm -rf "$HOST_TMP" || true; fi
  if [ -n "$DC_TMP" ]; then rm -rf "$DC_TMP" || true; fi
  ...
  if [ -n "$HOST_NEW_IN" ]; then rm_new_copies "$HOST_NEW_IN"; fi
  if [ -n "$HOST_LOCK" ]; then rmdir "$HOST_LOCK" 2>/dev/null || true; fi
  # A destination this run created only to hold the lock and copies.
  if [ -n "$HOST_MADE_DEST" ]; then rmdir "$HOST_MADE_DEST" 2>/dev/null || true; fi
}
```

Execution: `probe-r2-a1.sh` R2-a (answer n): the destination was gone and nothing was left in TMPDIR. For R2-b TERM and HUP, the eight `.cw-new.*` copies existed at the prompt, and afterwards the process had exited, the destination was gone and TMPDIR was empty. The SIGINT row in that probe is void: a background job inherits SIGINT as ignored. `probe-r2-sigint.sh` redid it with SIGINT at its default (SigIgn mask `0x4`, INT bit clear) and got the same clean result. R2-c (existing destination, TERM): only the original `settings.json` and `CLAUDE.md` remain, and `CLAUDE.md` is unchanged.

**Evidence:** `devcontainer-config/install.sh:599-626`, `:722-734`; `docs/reviews/execution-logs/q058p2-fc/probe-r2-a1.log` (exit 0, 2026-09-25T07:51:56Z); `docs/reviews/execution-logs/q058p2-fc/probe-r2-sigint.log` (exit 0, 2026-09-25T07:53:22Z)

---

## Claim 14: "R2 ... The review reads the copies that get installed, never the stage ... take the lock, copy the stage into $dest/.cw-new.*, hash those copies, review them, and after the y check the hash and swap exactly those copies in."

**Location:** `devcontainer-config/install.sh:710-721`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lock being taken before the review, the hash being taken at `:756` (after the copy, before the first review line at `:762`), every review read going through `$new`, the post-y hash check, and the swap of exactly `.cw-new.<name>`. Does not establish detection of a swap-and-revert of the copies themselves during the review (stated as unchecked, review C8), or protection when `$dest` is not under a `denyWrite` path (Claim 21).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:755-756
  local new="$dest/.cw-new." reviewed_hash
  reviewed_hash="$(payload_hash "$dest" .cw-new. "$dest/.cw-new.manifest")"
```

```bash
# devcontainer-config/install.sh:866-871
  if [ "$(payload_hash "$dest" .cw-new. "$dest/.cw-new.manifest")" != "$reviewed_hash" ]; then
    rm_new_copies "$dest"
    echo "ERROR: the copies to install changed after review: ${new}* differ from the" >&2
    echo "       files the review showed. Nothing was replaced. Rerun install.sh." >&2
    exit 1
  fi
```

After the copy loop (`:742`, `:747`), `install_claude_home` never reads `$stage` again. The pre-pass (`:772`, `:778`), the ADD listing (`:812-815`), `mode_diff`/`review_diff` (`:835-837`), the wiring `cmp` (`:852`) and the swap (`:903`, `mv "$dest/.cw-new.$name" "$dest/$name"`) all use `$new` or `.cw-new.` (paraphrased — no quote available because the claim spans eight sites in one function, read whole). T67 and T68 pass at `feba07d`. At `c7c4e34`, T67 fails at `[[ "$output" == *'+echo MALICIOUS-PAYLOAD'* ]]` (test line 547): the old review read the swapped stage and never showed the payload that was then installed. T67's helper starts its swap once `$HOST_TMP/installed` exists (`:809`), so the swap lands while the content diff is being produced.

**Evidence:** `devcontainer-config/install.sh:706-905`; `docs/reviews/execution-logs/q058p2-fc/bats.log`; `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log` (T67 failure at line 547)

---

## Claim 15: "Q-058, review A2: ... Check again before this target stages."

**Location:** `devcontainer-config/install.sh:675-677`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the placement: after the three skip rules (`:659-670`), before the guards, `mktemp` and `assemble` (`:680-708`). Does not establish detection of an agent that starts after this check.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:672-677
  echo "=== Host target: global Claude Code files ======================================"
  echo "Destination: $dest  (chosen by $label)"

  # Q-058, review A2: the startup check ran before target 1's review and
  # prompt, which can wait for minutes. Check again before this target stages.
  agent_gate "Nothing was installed into the host target."
```

T72 (an agent visible only during target 1's prompt stops the host target; no `~/.claude` and no stage are left) passes at `feba07d` and fails at `c7c4e34`.

**Evidence:** `devcontainer-config/install.sh:649-708`; `docs/reviews/execution-logs/q058p2-fc/bats.log`, `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log`

---

## Claim 16: "The list below is line- and TAB-separated (cut -f2), so a name holding either would be split and mis-pruned (review A3): never a candidate."

**Location:** `devcontainer-config/install.sh:938-940`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers TAB- and newline-named backup directories being skipped, and T73's shape (the TAB name would otherwise sort into the prune and `cut -f2` would name a real, kept backup). Does not establish other odd names (none are split by this pipeline).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:940 (excerpt; enclosing loop :936-946 and install_claude_home() — read)
        case "$d" in *$'\n'*|*$'\t'*) continue ;; esac
```

T73 passes at `feba07d` and fails at `c7c4e34`.

**Evidence:** `devcontainer-config/install.sh:931-947`; `docs/reviews/execution-logs/q058p2-fc/bats.log`, `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log`

---

## Claim 17: "refused ... at startup, before anything is staged, again before the host target stages, and after each y" / "A Claude Code process is ... a token that is `claude` (or `claude.exe`) or ends in `/claude` ... Or ... `/@anthropic-ai/claude-code/` ..., `/claude/versions/` ... or `/claude-agent-sdk/` ... $$ is dropped only as a belt-and-braces guard. A command line with such an argument (`vim ./claude` ...) also matches"

**Location:** `devcontainer-config/install.sh:958-978`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex against the real `pgrep -u <uid> -af` for ten command-line shapes, and the `$$` filter (unchanged). Does not establish shapes outside the ten (renamed or wrapped binaries are stated residuals).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:978
CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/|/claude/versions/|/claude-agent-sdk/'
```

```bash
# devcontainer-config/install.sh:989-994 (excerpt; enclosing agent_gate() :982-1032 — read)
  procs="$(pgrep -u "$(id -u)" -af -- "$CLAUDE_PROC_RE")" || rc=$?
  ...
  procs="$(printf '%s\n' "$procs" | awk -v self="$$" 'NF && $1 != self')"
```

Execution (`probe-a2-pgrep.sh`, throwaway perl processes with `$0` set, real pgrep, only the probe's own PIDs reported). MATCH: `.../share/claude/versions/2.1.3 --resume`, `node .../@anthropic-ai/claude-agent-sdk/cli.js`, `claude --resume`, `node .../@anthropic-ai/claude-code/cli.js`, `claude.exe`, `vim ./claude`. No match: `bash ralph-loop.sh`, `vim notes.md`, `node cli.js`, and `bash /home/u/claude-workflows/devcontainer-config/install.sh`, so install.sh's own command line does not match.

**Evidence:** `devcontainer-config/install.sh:957-994`; `docs/reviews/execution-logs/q058p2-fc/probe-a2-pgrep.log` (exit 0, 2026-09-25T07:53:53Z)

---

## Claim 18: "Review C1: a hung docker is otherwise up to 20 s of silence per check." (progress line before the probe)

**Location:** `devcontainer-config/install.sh:1003-1004`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the progress line being printed before `timeout 20 docker ps`. Does not establish real docker hang timings.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:1004-1006
    echo "Checking for running cc-isolated containers (docker ps; up to 20 s)..."
    errf="$(mktemp "${TMPDIR:-/tmp}/cw-docker-err.XXXXXX")"
    if ! ctrs="$(timeout 20 docker ps --filter label=cc-project \
```

T52 now asserts the line comes before the NOTE, and it passes.

**Evidence:** `devcontainer-config/install.sh:997-1014`; `docs/reviews/execution-logs/q058p2-fc/bats.log` (T52 ok)

---

## Claim 19: "Superseded in part by the Trust model (Q-058) ...: every run now passes the no-agent check first. A run started from inside a Claude Code session ... exits 1 at startup ... A host without a reachable docker also prints a NOTE line at each check. The `CLAUDECODE` skip remains as a backstop"

**Location:** `docs/decisions/037-bare-host-copy-install.md:33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same behaviour as Claims 1 and 3. Does not establish the count of NOTE lines (Claim 24a).
**Legibility-target:** for-orchestrator-synthesis

The same code as Claims 1 and 3 (`install.sh:1093`, `:1006-1011`, `:663-666`). The same executed runs: `probe-docs.log` §1 and §3.

**Evidence:** `devcontainer-config/install.sh:663-666`, `:1006-1011`, `:1093`; `docs/reviews/execution-logs/q058p2-fc/probe-docs.log`

---

## Claim 20: "A cc-isolated container writes the checkout, `.git` included, through its bind mount: its user maps to the user's uid on the host, or it runs as root"

**Location:** `docs/decisions/037-bare-host-copy-install.md:64`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers only the config fact that the container's remote user is `node`. Does not establish the host-side uid mapping, which depends on the devcontainer CLI's UID update and the docker runtime (userns, rootless).
**Legibility-target:** for-orchestrator-synthesis

```json
// devcontainer-config/devcontainer.json:71
  "remoteUser": "node",
```

Whether `node` maps to the host user's uid is decided when the container is created (the devcontainer CLI's remote-user UID update, docker userns). No container runtime is available in the review sandbox. To verify: on the host, `docker exec <cc-isolated container> id` and `stat` a file the container created in the checkout.

**Evidence:** `devcontainer-config/devcontainer.json:71`

---

## Claim 21: "Host target: the review reads the copies that get installed ... The copies sit under `~/.claude`, which the sandbox's `denyWrite` keeps agents out of."

**Location:** `docs/decisions/037-bare-host-copy-install.md:67`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism (Claim 14, T67, T68). The qualifier: the copies sit under `$dest`, which is `~/.claude` only by default. Does not establish that a `denyWrite` exists on any given host (a manual hardening step).
**Legibility-target:** for-author

The mechanism matches Claim 14. The copies go to `$dest/.cw-new.*`, and `$dest` is `$CLAUDE_HOME_DIR`, else `$CLAUDE_CONFIG_DIR`, else `~/.claude`:

```bash
# devcontainer-config/install.sh:1061-1063
  if [ -n "${CLAUDE_HOME_DIR:-}" ]; then HOST_DEST="$CLAUDE_HOME_DIR"; HOST_LABEL='$CLAUDE_HOME_DIR'
  elif [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then HOST_DEST="$CLAUDE_CONFIG_DIR"; HOST_LABEL='$CLAUDE_CONFIG_DIR'
  else HOST_DEST="$HOME/.claude"; HOST_LABEL='the default, ~/.claude'
```

The precise version: "the copies sit under the destination (by default `~/.claude`, which the sandbox's `denyWrite` covers). With `CLAUDE_HOME_DIR`/`CLAUDE_CONFIG_DIR` pointing elsewhere, they are protected only if that path is in `denyWrite` too."

**Evidence:** `devcontainer-config/install.sh:710-756`, `:1061-1063`; `docs/reviews/execution-logs/q058p2-fc/bats.log` (T67, T68 ok)

---

## Claim 22: "Devcontainer target: a hash check, then the gate ... Otherwise they are removed again and nothing is blessed (T69, T70) ... `~/.config/claude-devcontainer` is not in the documented `denyWrite`"

**Location:** `docs/decisions/037-bare-host-copy-install.md:68`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the target-1 mechanism (Claim 11) and the documented `denyWrite` list in the guide. Does not establish any host's actual sandbox settings.
**Legibility-target:** for-orchestrator-synthesis

The mechanism is as in Claim 11. The guide's `denyWrite` list names `~/.claude`, `~/CLAUDE.md` and the auditor script, not `~/.config/claude-devcontainer`:

```
# guides/bare-host-hook-wiring.md:92
  `denyWrite` to `~/.claude`, `~/CLAUDE.md` and the auditor script. The sandbox is
```

**Evidence:** `devcontainer-config/install.sh:441-509`; `guides/bare-host-hook-wiring.md:92`, `:102-104`; `docs/reviews/execution-logs/q058p2-fc/probe-r2-a1.log`

---

## Claim 23: "It checks at four moments: at startup ...; again at the start of the host target, before it stages (review A2); and after each y"

**Location:** `docs/decisions/037-bare-host-copy-install.md:72`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four call sites (Claim 2). Does not establish that all four run on every run: which ones run depends on the answers (Claim 24a).
**Legibility-target:** for-orchestrator-synthesis

Same call sites as Claim 2: `install.sh:1093`, `:481`, `:677`, `:864` (paraphrased — no quote available because the claim is a count of four call sites quoted individually in Claims 1, 2 and 15).

**Evidence:** `devcontainer-config/install.sh:481`, `:677`, `:864`, `:1093`

---

## Claim 24a: "If docker is missing or unreachable, a NOTE line says so at each check (two or three per run)"

**Location:** `docs/decisions/037-bare-host-copy-install.md:74`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the number of NOTE lines per run with docker unreachable, across five answer patterns. Does not establish the missing-docker branch separately (it has the same one-NOTE-per-check shape, `install.sh:997-998`).
**Legibility-target:** for-author

A NOTE comes from every `agent_gate` call that runs, and which calls run depends on the answers. Execution (`probe-docs.sh` §1):

```
   no TTY, no --yes (target 1 declined at EOF, host skipped): exit 1; NOTE lines: 1
   --yes (target 1 installed, host skipped):                  exit 0; NOTE lines: 2
   pty n,y (target 1 declined, host installed):               exit 1; NOTE lines: 3
   pty y,y (both installed):                                  exit 0; NOTE lines: 4
   pty n,n (both declined):                                   exit 1; NOTE lines: 2
```

The count is one to four per run, not "two or three". f946a8b's own note says four for the progress line ("up to four per interactive run", `log.txt:227-228`). The precise version: "a NOTE line at each check (one to four per run, depending on the answers)".

**Evidence:** `devcontainer-config/install.sh:481`, `:677`, `:864`, `:1093`, `:997-1011`; command `bash probe-docs.sh .../install.sh`, cwd `docs/reviews/execution-logs/q058p2-fc`, exit 0, 2026-09-25T07:55:43Z; output `docs/reviews/execution-logs/q058p2-fc/probe-docs.log`

---

## Claim 24b: "docker's own `DOCKER_HOST` and `DOCKER_CONTEXT` (and its config file) choose which daemon is asked. Pointed at an empty daemon, the container check finds nothing and prints no NOTE."

**Location:** `docs/decisions/037-bare-host-copy-install.md:74`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pass-through of the two variables (Claim 4), and that no NOTE is printed when `docker ps` succeeds with empty output. Does not establish docker's config-file resolution.
**Legibility-target:** for-orchestrator-synthesis

A NOTE is printed only on the failure branch (`install.sh:1006-1011`, quoted in Claim 3). A successful empty listing makes `ctrs` empty and the gate returns 0 (`:1013-1015`). This is the default path of the whole bats suite, whose docker stub is `exit 0`.

**Evidence:** `devcontainer-config/install.sh:1006-1015`; `docs/reviews/execution-logs/q058p2-fc/probe-docs.log` §2

---

## Claim 25: "A backup directory whose name holds either is now skipped by the prune, never removed (review A3, T73). Before that fix, a TAB in a name mis-pruned a real backup."

**Location:** `docs/decisions/037-bare-host-copy-install.md:77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the prune behaviour (Claim 16) and T73 failing before the fix. Does not establish the sentence's rationale that `denyWrite` is "the real protection" (sandbox configuration, outside the code).
**Legibility-target:** for-orchestrator-synthesis

The code is at `install.sh:940`, quoted in Claim 16. T73 passes at `feba07d` and fails at `c7c4e34`.

**Evidence:** `devcontainer-config/install.sh:940`; `docs/reviews/execution-logs/q058p2-fc/bats.log`, `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log`

---

## Claim 26: "The checkout's git state (mitigated 2026-09-25, review R1). git runs commands named in the checkout's `.git/config` and `.git/info/attributes` ... What remains: a command-running key outside that list, and the user's own global or system git config."

**Location:** `docs/decisions/037-bare-host-copy-install.md:78`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the residual list's completeness for install.sh's own git calls. Does not establish anything about git commands the user runs by hand (the sentence already scopes those out).
**Legibility-target:** for-author

The residual list names config keys and global config only. The executable that runs is a file, `.git/hooks/post-index-change`, which is neither a key nor global config. `git status` at `install.sh:304-305` runs it whenever it rewrites the index, and it also runs from a directory named by `core.hooksPath`. Probe A: the hook ran, the gate did not refuse, and the install blessed (`exit 0; refused-by-gate: 0; blessed: 1`, marker `hook-post-index-change`). Probe B is the same through `core.hooksPath` (Claim 6). So the container-to-host path this paragraph calls mitigated is still open through `.git/hooks`. The first sentence ("git runs commands named in ... `.git/config` and `.git/info/attributes`") leaves out `.git/hooks` as well. `037:70` ("Neither target catches an agent that rewrites ... the checkout's `.git` ... before the stage is built") does not make up for this: it addresses a *running* agent, while this paragraph is about state that persists after the container stops.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:70`, `:78`; `devcontainer-config/install.sh:171-200`, `:304-305`; `docs/reviews/execution-logs/q058p2-fc/probe-r1-git-exec.log` (exit 0, 2026-09-25T07:50:16Z)

---

## Claim 27: "What the gate does not see (review A2) ... a Claude Code shape the pattern above misses: a renamed or wrapped binary, or `node cli.js` run from inside the package directory"

**Location:** `docs/decisions/037-bare-host-copy-install.md:79-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "not matched" shapes probed (`node cli.js`, `bash ralph-loop.sh`). Does not establish the other listed residuals (other hosts or uids, an unreachable docker), which are true by construction: pgrep is `-u <uid>`, docker is one daemon.
**Legibility-target:** for-orchestrator-synthesis

The pattern is quoted in Claim 17. The probe reports `no     node cli.js` and `no     bash ralph-loop.sh`.

**Evidence:** `devcontainer-config/install.sh:978`, `:989`; `docs/reviews/execution-logs/q058p2-fc/probe-a2-pgrep.log`

---

## Claim 28: "Re-review fixes (2026-09-25 ...): ... (R1; T65, T66); ... (R2, Q-061 interim [1]; T67, T68); ... (A1; T69, T70); ... (A2; T71, T72); ... (A3; T73); ... (C3; T74)."

**Location:** `docs/working/plan-copy-install-bare-host.md:248`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named test existing, passing at `feba07d`, and testing the named fix. Does not establish that the R1 fix is complete (Claims 6 and 26).
**Legibility-target:** for-orchestrator-synthesis

All ten tests are in `test/install-host.bats` and pass at `feba07d` (`bats.log`). All ten fail with `c7c4e34`'s install.sh (`prefix-bats.log`).

**Evidence:** `test/install-host.bats` (T65–T74); `docs/reviews/execution-logs/q058p2-fc/bats.log`, `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log`

---

## Claim 29: "install.sh is 1104 lines after the review, fact-check, Q-058 and re-review fixes (958 before the re-review, 808 before Q-058)"

**Location:** `docs/working/plan-copy-install-bare-host.md:249`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 1104 at `feba07d` and 958 at `c7c4e34`. Does not establish the 808 figure (a pre-Q-058 commit, outside this range, not re-counted).
**Legibility-target:** for-automated-gate

`git show <c>:devcontainer-config/install.sh | wc -l` gives `feba07d 1104` and `c7c4e34 958`. `wc -l` in the worktree gives 1104.

**Evidence:** `devcontainer-config/install.sh:1104`; `docs/reviews/execution-logs/q058p2-fc/line-counts.log` (cwd `/workspace/.claude/wt-q058p2`, exit 0, 2026-09-25T07:57:54Z)

---

## Claim 30: "The installer checks for both at startup, again before the `~/.claude` target stages, and after each y ... The checks are samples, not a lock"

**Location:** `guides/bare-host-hook-wiring.md:17-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 2.
**Legibility-target:** for-orchestrator-synthesis

The call sites are as in Claim 2 (paraphrased — no quote available because the evidence is the four call sites already quoted in Claims 1, 2 and 15).

**Evidence:** `devcontainer-config/install.sh:481`, `:677`, `:864`, `:1093`

---

## Claim 31: "A same-uid helper the gate does not see ...: it swaps the stage's h.sh for the installed one while the review is produced, and restores it 1.5 s later, before the y."

**Location:** `test/install-host.bats:527-529` (T67)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helper's swap happening during the content diff and being restored before the y (`helper.done` asserted, and the FEED_TAMPER sleeps before the y). Does not establish a swap during the pre-pass lines at `:762-796`, which come before `$HOST_TMP/installed` exists. The fixed code is indifferent to either window.
**Legibility-target:** for-orchestrator-synthesis

The helper waits for `compgen -G "$TMPDIR/cw-host-stage.*/installed"`, which `install.sh:809` (`mkdir -p "$view"`) creates just before the content diff. The test passes at `feba07d` and fails at `c7c4e34` at its review assertion (Claim 14).

**Evidence:** `test/install-host.bats:520-548`; `devcontainer-config/install.sh:807-809`; `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log`

---

## Claim 32: "stub_pgrep_table: a pgrep that applies the pattern install.sh passes (its last argument) to the command lines in $S/ps.txt"

**Location:** `test/install-host.bats` (stub_pgrep_table, above T71)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stub using install.sh's exact pattern string (`${*: -1}`) under `grep -E`, and the real `pgrep` giving the same match set on the same shapes. Does not establish `grep -E`/`pgrep` equivalence for patterns beyond this one.
**Legibility-target:** for-orchestrator-synthesis

The stub body is `pat="${*: -1}"` followed by a `grep -qE -- "$pat"` over each line (`test/install-host.bats`, stub_pgrep_table). The real pgrep gives the same MATCH/no split for T71's four agent shapes and three non-agent shapes (Claim 17).

**Evidence:** `test/install-host.bats` (stub_pgrep_table, T71); `docs/reviews/execution-logs/q058p2-fc/probe-a2-pgrep.log`

---

## Claim 33: "Tests: install-host T65 ... and T66 ... Each plants a marker command and checks it never ran. Both failed on the pre-fix code." / "tar.tar.command was checked and is not honoured for --format=tar."

**Location:** `log.txt:19-22`, `log.txt:29` (24ce814)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T65 and T66 failing against `c7c4e34`'s install.sh, and `tar.tar.command` not firing during a full install. Does not establish the intermediate "Suites: 158/158" (not re-run at 24ce814).
**Legibility-target:** for-orchestrator-synthesis

`prefix-bats.log` shows `not ok 13 T65` and `not ok 14 T66`. In `probe-r1-git-exec.log`, `### C tar.tar.command: install.sh exit 0; ... markers fired:` is empty.

**Evidence:** `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log` (cwd `.../scratchpad/prefix-bats`, install.sh from c7c4e34, tests from feba07d, exit 1, 2026-09-25T07:54:26Z); `docs/reviews/execution-logs/q058p2-fc/probe-r1-git-exec.log`

---

## Claim 34: "T28, T67 and T68 failed on the pre-fix code." / "A first-install decline creates and then removes $dest"

**Location:** `log.txt:58-63`, `log.txt:69-70` (6ec64c3)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three failures against `c7c4e34` and the removal of `$dest` on a first-install decline. T68 fails before the fix only because its tampered path (`.cw-new.hooks/h.sh`) did not exist at the prompt then. So it pins the new behaviour; it does not reproduce an old defect.
**Legibility-target:** for-orchestrator-synthesis

`prefix-bats.log` shows T28, T67 and T68 `not ok`. T68's pre-fix output ends `Installed into ...` with no refusal. `probe-r2-a1.log` R2-a: `dest exists: no`.

**Evidence:** `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log`, `docs/reviews/execution-logs/q058p2-fc/probe-r2-a1.log`

---

## Claim 35: "T69 failed on the pre-fix code." / "The removal leaves no working config, which fails closed"

**Location:** `log.txt:92-95`, `log.txt:102-103` (c700270)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T69 (and T70) failing before the fix, and the post-mismatch state (Claim 11). Does not establish anything about running containers built from the previous config.
**Legibility-target:** for-orchestrator-synthesis

`prefix-bats.log` shows `not ok 7 T69` and `not ok 8 T70`. `probe-r2-a1.log` A1-a: the bin link dangles and running it exits 127.

**Evidence:** `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log`, `docs/reviews/execution-logs/q058p2-fc/probe-r2-a1.log`

---

## Claim 36: "Tests: T71 ... and T72 ... Both failed on the pre-fix code."

**Location:** `log.txt:130-135` (ec1e5bd)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both failing against `c7c4e34`. Does not establish the intermediate 164/164.
**Legibility-target:** for-orchestrator-synthesis

`prefix-bats.log` shows `not ok 9 T71` and `not ok 10 T72`.

**Evidence:** `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log`

---

## Claim 37: "Test: T73 ... It failed on the pre-fix code."

**Location:** `log.txt:158-160` (477d77f)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T73 failing against `c7c4e34`. Does not establish the intermediate 165/165.
**Legibility-target:** for-orchestrator-synthesis

`prefix-bats.log` shows `not ok 11 T73`.

**Evidence:** `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log`

---

## Claim 38: "C3: a vis failure at a `| vis` site outside review_diff ... ended the script through set -e with exit 1 and no message ... review_diff (which checks PIPESTATUS itself) and mode_diff (errexit is suppressed there, and review_diff re-shows the same items right after) keep plain vis." / T74 "failed on the pre-fix code"

**Location:** `log.txt:204-213`, `log.txt:221-223` (f946a8b)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old silent exit (T74 fails before the fix), the new message, and the commit's wording about mode_diff, which is accurate ("the same items"; compare Claim 5b's code comment). Does not establish the ERR-trap rationale (design reasoning, not checked).
**Legibility-target:** for-orchestrator-synthesis

`prefix-bats.log` shows `not ok 12 T74`. At `feba07d` it passes (Claim 5a). mode_diff's callers are `:457` (`|| same=0`) and `:835` (`if !`), and `review_diff` follows each on the same items (`:458`, `:837`).

**Evidence:** `devcontainer-config/install.sh:457-458`, `:835-837`; `docs/reviews/execution-logs/q058p2-fc/prefix-bats.log`, `docs/reviews/execution-logs/q058p2-fc/bats.log`

---

## Claim 39: "the progress line adds one stdout line per gate call on hosts with docker (up to four per interactive run)"

**Location:** `log.txt:227-228` (f946a8b)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the maximum of four gate calls (pty y,y). Does not establish runs with docker missing (no progress line is printed then; `install.sh:997-998`).
**Legibility-target:** for-orchestrator-synthesis

The progress line is printed in the same branch as the NOTE (`install.sh:1004`), and the pty y,y run in `probe-docs.log` made four gate calls (four NOTEs).

**Evidence:** `devcontainer-config/install.sh:997-1006`; `docs/reviews/execution-logs/q058p2-fc/probe-docs.log`

---

## Claim 40: "path_without ... links them in one `ln` call. A name an earlier directory already linked fails with 'File exists' and ln goes on, so the first on PATH still wins."

**Location:** `log.txt:235-240` (32247d7); `test/install-host.bats:56-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU ln's continue-on-EEXIST behaviour with several sources, and the first link surviving. Does not establish the "7.1 s -> 4.9 s" timing (machine-specific, not re-measured).
**Legibility-target:** for-orchestrator-synthesis

The scratch run printed `ln: failed to create symbolic link 'farm/x': File exists`, `ln exit 1`, `farm/x -> .../d1/x` (first kept) and `farm/y -> .../d2/y` (later names still linked). `path_without` ignores the exit (`|| true`). T52, T53 and T57 pass.

**Evidence:** `test/install-host.bats:62-77`; `docs/reviews/execution-logs/q058p2-fc/ln-first-wins.log` (2026-09-25T07:56:59Z)

---

## Claim 41: "Suites: 166/166."

**Location:** `log.txt:224` (f946a8b)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `bats test/install-host.bats test/cc-isolated-functions.bats` at `feba07d`: 166 tests (74 + 92), all ok. Does not establish the intermediate counts (158–165) at their own commits. There is no "955/955" claim anywhere in `c7c4e34..feba07d` (`grep 955` over `log.txt` finds nothing), so no such claim was checked.
**Legibility-target:** for-automated-gate

Command: `bats test/install-host.bats test/cc-isolated-functions.bats`, cwd `/workspace/.claude/wt-q058p2`, exit 0, 2026-09-25T07:47:09Z–07:49:02Z. Output: `1..166`, 166 `ok`, 0 `not ok`. `bats --count` gives 74 for `install-host.bats` alone.

**Evidence:** `docs/reviews/execution-logs/q058p2-fc/bats.log`, `docs/reviews/execution-logs/q058p2-fc/bats.ts`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`devcontainer-config/install.sh:133-134`): "mode_diff (whose lines review_diff re-shows)". review_diff never shows MODE lines (diff compares content only). It re-shows the same items' content. Reword to match the commit message.
- **Claim 6** (`devcontainer-config/install.sh:156-163`): git_state_gate claims to refuse git state that names a command git would run during the install, but `.git/hooks/post-index-change` (or one under `core.hooksPath`) runs during `git status` at `:304-305`. Probe A/B: the hook ran, there was no refusal, and the install blessed.
- **Claim 24a** (`docs/decisions/037-bare-host-copy-install.md:74`): "a NOTE line ... at each check (two or three per run)". Measured 1, 2, 3 or 4 per run depending on the answers.
- **Claim 26** (`docs/decisions/037-bare-host-copy-install.md:78`): the R1 residual list ("a command-running key outside that list, and the user's own global or system git config") leaves out `.git/hooks`, which is neither, so the container-to-host path is described as mitigated while a hook still runs.

### Stale
- (none)

### Mostly Accurate
- **Claim 21** (`docs/decisions/037-bare-host-copy-install.md:67`): "The copies sit under `~/.claude`" holds only for the default destination. With `CLAUDE_HOME_DIR`/`CLAUDE_CONFIG_DIR` set elsewhere, they sit wherever that points.

### Unverifiable
- **Claim 20** (`docs/decisions/037-bare-host-copy-install.md:64`): the container user's host uid mapping needs a running cc-isolated container on the host (`docker exec ... id`, `stat` a file it wrote).

---

## Goal-Alignment Note

**Success criterion (restated verbatim):** "a markdown report in the code-fact-check skill format, saved to /workspace/docs/reviews/code-fact-check-report.md, with `**Commit:** feba07d` and `**Replication:** k=1 (loop pass, decision 031)` in the header."

**Answered:**
- R1: the gate runs before every other git call (Claim 8). Its own reads run nothing (Claim 9). `--no-includes`/`--file` hold (Claim 9). config.worktree is handled for main and linked worktrees (Claim 9). `core.fsmonitor=false` is on both status calls (Claim 10). Of the other keys probed (17 of them, including hooksPath-free `diff.external`, pager, ssh, gpg, uploadpack, url/protocol and `tar.tar.command`), none is reachable. The hooks directory and `core.hooksPath` are reachable (Claims 6 and 26, Incorrect).
- R2: the hash is taken at `:756`, after the copies and before the review. The lock is taken before the review. Cleanup holds on n, TERM, INT and HUP. T67 and T68 prove their titles, with T68 pinning new behaviour (Claims 13, 14, 31, 34).
- A1: the checks, the removal and no bless are verified. After a post-copy mismatch, `$DEST` keeps only `projects/` and non-PAYLOAD files, and the bin link dangles (exit 127) on a reinstall or is absent on a first install. tree_hash keeps payload_hash's semantics (Claims 11, 12, 35).
- A2, A3, C1, C3: verified (Claims 15–18, 32, 36–39), except the mode_diff comment (5b).
- Docs: the in-session exit 1 and DOCKER_HOST/CONTEXT are verified. The NOTE count is Incorrect (24a). 037:64 is Unverifiable. 037:66/67 is Mostly accurate, and 037:73/74 is Incorrect on the count. Separately, 037:78 is Incorrect on the hooks residual. The 1104-line count is verified.
- Tests: 166/166 re-run and verified.

**Out of scope:** the 808-line figure, and the intermediate per-commit suite counts, which were not re-run at their own commits. The C2 timing (7.1 s to 4.9 s). Real docker and container behaviour. Whether to fix the hooks gap and how: this report states behaviour only.

**Escalate:**
1. **R1 is not closed.** A planted `.git/hooks/post-index-change` (or `core.hooksPath`) runs as the host user during `git status` in `assemble`, and the install then blesses. This is the same container-to-host path R1 targets, through state the gate does not check. It should be treated as red for the merge decision (Claims 6 and 26; `probe-r1-git-exec.log` cases A and B).
2. **The "955/955" test-count claim in the brief does not exist** in any fix commit (`c7c4e34..feba07d`). Only the "Suites: N/N" counts (158–166) appear, and 166/166 was re-run and holds. If 955 refers to a whole-repo bats run, it is outside these commits and was not checked.
