# Code Fact-Check Report

**Commit:** 516124d
**Replication:** k=1 (loop pass, decision 031)

**Repository:** `/workspace` (branch `skill-fixtures`; code read and run in the worktree `/workspace/.claude/wt-q058p2` at 516124d)
**Scope:** the re-review pass-2 fix commits `f8d3f78..516124d` (99656a2, 21bf405, fa25f13, b58d671, e61408f, d71715f, 767f421, 516124d; the docs-only d7b6120 is excluded). Files: `devcontainer-config/install.sh`, `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `docs/working/plan-copy-install-bare-host.md`, `test/install-host.bats`, and the eight commit messages. They answer the "Pass 2" section of `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md` (P2-R1..R3, P2-A1..A5, P2-C2/C3).
**Checked:** 2026-09-25
**Total claims checked:** 26
**Summary:** 21 verified, 4 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

**Method note.** `install.sh` was read whole (1–1193), including `cc-isolated.sh`'s `--bless` path (`devcontainer-config/cc-isolated.sh:544-576`, which runs no git). Every executed probe is hermetic: temp `HOME` and `TMPDIR`, `GIT_CONFIG_NOSYSTEM=1`, an empty `GIT_CONFIG_GLOBAL`, pgrep and docker stubbed, a throwaway fake repo holding a *copy* of install.sh. The real `~/.claude` and `~/.config` were never touched. Probe scripts and logs are in `docs/reviews/execution-logs/q058p3-fc/`. Every `.sh` there has a shebang and passes `shellcheck -x -e SC1091 -s bash -S warning`. Git here is **2.39.5**. git-lfs is not installed.

**Prior-pattern check.** Compared every claim against `docs/reviews/hallucination-patterns.md`. Four entries are logged, three of them "a specific measured value quoted from a checked-in artifact set that does not contain it". In this scope that shape covers the test counts (175/175), the line counts (1193 and 1104), "17 further keys" and "one to four NOTEs per run". Each was recomputed and matches (Claims 15, 16, 19, 24). No claim matches a logged pattern.

---

## Claim 1: "each entry is named with the `git config --file … --unset-all` command that removes it"

**Location:** `README.md:34-38`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the refusal message prints for config keys and for `info/attributes`. It does not establish anything about the remedy's exit codes (Claim 7).
**Legibility-target:** the user reading the README before a first run. They will expect a ready-to-paste command per entry.

The refusal names each entry once, then prints **one** generic template, not a command per entry:

```bash
# devcontainer-config/install.sh:229-237
    echo "ERROR: the checkout's git state can make git run a command as you during this"
    ...
    printf '%s' "$found"
    ...
    echo "         git config --file <the file named above> --unset-all <key>"
    echo "       or by emptying the attributes file, then rerun. Removing filter.lfs.*"
```

The executed refusal (P6) lists `$S/repo/.git/config: include.path /nonexistent/a` and the other entries, then the single template. For an `info/attributes` entry the remedy is emptying the file, not a `git config` command. Precise version: "each entry is named, followed by the `git config --file <file> --unset-all <key>` command (or emptying the attributes file) that removes it." The refused key list itself (`filter.*`, `core.fsmonitor`, `include*`, non-empty `info/attributes`) matches `GIT_EXEC_KEYS_RE='^(filter\.|core\.fsmonitor|include)'` (`install.sh:197`) and the `-s "$attrs"` test (`install.sh:224`).

**Evidence:** `devcontainer-config/install.sh:197-240`, `README.md:34-38`. Run: `bash probe-p3.sh <wt>/devcontainer-config/install.sh`, cwd `docs/reviews/execution-logs/q058p3-fc`, exit 0, 2026-09-25T08:42:37Z. Output: `docs/reviews/execution-logs/q058p3-fc/probe-p3.log` (section P6).

---

## Claim 2: "an unwritable destination is refused before the review (exit 1), even when nothing would change"

**Location:** `README.md:39-41`; `devcontainer-config/install.sh:80-82` (`--help`); also the fa25f13 and d71715f commit bodies
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an existing destination made read-only after a complete install (so nothing would change), and an absent destination under a read-only parent. It does not establish behaviour when the destination is writable but a later write (mktemp, cp) fails. Those take `host_refuse` and the copy-failure path, which also exit 1.

The lock is taken before any staging, and failure to create it is a hard exit:

```bash
# devcontainer-config/install.sh:794-804
  if mkdir -p "$dest" 2>/dev/null && mkdir "$dest/.claude-workflows-lock" 2>/dev/null; then
    HOST_LOCK="$dest/.claude-workflows-lock"
    HOST_NEW_IN="$dest"   # this run owns $dest/.cw-new.* from here on
  elif [ -e "$dest/.claude-workflows-lock" ]; then
    host_refuse "$(lock_msg "$dest")"
  else
    echo "ERROR: could not create $dest/.claude-workflows-lock (is $dest writable?)." >&2
    ...
    exit 1
  fi
```

P5 (install, `chmod a-w` the destination, rerun): rc=1, the "could not create … (is … writable?)" message, and 0 "Nothing to install" lines. P5b (read-only parent, destination absent): rc=1, same message.

**Evidence:** `devcontainer-config/install.sh:793-804`. `probe-p3.log` sections P5 and P5b (same run as Claim 1).

---

## Claim 3: "Both targets are refused, before anything is staged, when … Hooks (.git/hooks, core.hooksPath) and submodules are not refused; install.sh's git calls never run them."

**Location:** `devcontainer-config/install.sh:73-78` (`--help`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High (on git 2.39.5)
**Verification mode:** executed
**Scope:** Covers the default hooks dir, `core.hooksPath`, and a submodule's own filter and hook, on git 2.39.5, for both targets. It does **not** establish anything for git ≥ 2.54's config-based hooks (`hook.<name>.command` / `hook.<name>.event`), which this git ignores. It is also unverified whether `core.hooksPath=/dev/null` switches those off, or whether the gate should refuse `hook.*`. See the Goal-Alignment Note. "Before anything is staged" means before any content: the empty `mktemp -d` stage directory already exists when `git_state_gate` runs (`install.sh:473-475`, `:808-813`).

- `git_state_gate` is the first statement of `assemble` (`install.sh:320`: `git_state_gate   # before any other git call on the checkout (review R1)`), and both targets call `assemble` (`:475`, `:813`).
- P1a, a planted `.git/hooks/post-index-change` on a stat-dirty index: the install exits 0 and blesses, and `hook-ran=no`. A plain `git status` then gives `hook-ran=yes`, so the setup is live. The same holds for `core.hooksPath` (`hookspath-ran=no`, then `yes` under plain status).
- P1b: the host target (pty, n then y) installs with `hook-ran=no`.
- Rerunning the pass-2 security probes against 516124d, SP3b, SP3c and SP3d no longer reproduce: the markers `hook-ran`, `hookspath-ran` and `sub-clean-ran`/`sub-hook-ran` are all absent. SP3a (filter and fsmonitor refused) still passes.
- P1c: git 2.39.5 did not run a `hook.x.command`/`hook.x.event=post-index-change` pair under a plain status (`cfghook-ran=no`).

**Evidence:** `devcontainer-config/install.sh:73-78,317-334`. `probe-p3.log` (P1a–P1c). `docs/reviews/execution-logs/q058p3-fc/secrev-p2-probes-rerun.log`: `bats ../secrev-q058p2/probe.bats`, cwd `q058p3-fc`, 2026-09-25T08:45:34Z. Each test there asserts the *pass-2 vulnerability*, so "not ok" means it no longer reproduces.

---

## Claim 4: "mode_diff runs where errexit is off, so a vis failure there drops that MODE line silently; review_diff then shows the same items' content (not their MODE lines) and aborts on a vis that keeps failing."

**Location:** `devcontainer-config/install.sh:144-151`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the host target's `if ! mode_diff` call site with a vis that fails only on a MODE line. It does not establish the devcontainer site (`mode_diff … || same=0`, `:512`), which has the same errexit-off shape and was read, not run. The comment does not claim the review is complete when the drop happens, and it is not: see below.

`mode_diff` pipes each MODE line through plain `vis` (`install.sh:409`: `echo "MODE $dest/$item${p%/}: ${dm[$p]} -> ${rec%% *}" | vis`) and is called under `if !` (`:924`) or `||` (`:512`), both of which suspend errexit. P8 used a perl stub that fails only when the input starts with `MODE`, on a repo whose only change is `chmod +x guides/g.md`. The review printed the diff header and the `(diff: …)` line, no MODE line, and no content diff, then reached `Install these files …? [y/N]`. The control run with real perl prints `MODE …/guides/g.md: 644 -> 755`. So the comment is accurate. Note for the critics: in that case the human is prompted with a review that shows no change.

**Evidence:** `devcontainer-config/install.sh:144-159,393-415,923-927`. `docs/reviews/execution-logs/q058p3-fc/probe-p3b.log` (P8): `bash probe-p3b.sh <wt>/devcontainer-config/install.sh`, cwd `q058p3-fc`, exit 0, 2026-09-25T08:43:31Z.

---

## Claim 5: "every git call on the checkout (rev-parse, cat-file, archive, status) now runs as `git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false`… Both status calls add --ignore-submodules=all."

**Location:** `devcontainer-config/install.sh:161-171` (comment and `repo_git`); the 99656a2 commit body
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `git` token in install.sh (grepped) and the `--bless` path of `cc-isolated.sh`. `git_state_gate`'s `git config --file` read is outside the wrapper by design (the commit names it). This verdict does not cover git calls in other host scripts the user runs in the checkout.

```bash
# devcontainer-config/install.sh:169-171
repo_git() {
  git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"
}
```

A grep of executable (non-comment, non-echo) `git ` lines in install.sh finds only `:170` (`repo_git`) and `:209` (`git --no-pager -c core.hooksPath=/dev/null config --file "$f" --no-includes --get-regexp …`). Every other checkout call uses `repo_git`: `:175` rev-parse, `:201`/`:218` rev-parse --git-path, `:255` cat-file, `:267` archive, and `:333-334` status, both with `--ignore-submodules=all`. `cc-isolated.sh --bless` returns at `cc-isolated.sh:573-575` (`bless) bless_manifest; exit 0 ;;`) before `resolve_workspace`, the only function that runs git there. The claim's effect is shown by Claim 3's probes, and by T75/T76, which fail on f8d3f78 and pass on 516124d (Claim 23).

**Evidence:** `devcontainer-config/install.sh:161-171,175,201,209,218,255,267,333-334`, `devcontainer-config/cc-isolated.sh:544-576`. `prefix-bats.log`, `probe-p3.log`.

---

## Claim 6: "The 'no readable HEAD' error now suggests `git rev-parse HEAD`, not `git status`, which would run a planted hook in the user's shell."

**Location:** `devcontainer-config/install.sh:176`; the 99656a2 commit body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message text and that `rev-parse` fires no hook event on 2.39.5. It does not establish that the suggested command is hook-free under git ≥ 2.54 config hooks (no event plausibly applies, but that is unverified).

`install.sh:176`: ``echo "ERROR: no readable HEAD commit in $REPO_ROOT (run \`git -C $REPO_ROOT rev-parse HEAD\`" >&2``. `rev-parse` reads refs and writes no index, so no `post-index-change` can fire. Plain `git status` does fire it, as the P1a control shows (`hook-ran=yes`).

**Evidence:** `devcontainer-config/install.sh:173-180`. `probe-p3.log` (P1a control).

---

## Claim 7: "The refusal's remedy is now `git config --file <the file named above> --unset-all <key>` (rc=0 for both cases above)", where the old `--local --unset` "exits 5 for a config.worktree key and for a multi-valued include.path"

**Location:** `devcontainer-config/install.sh:233-235`; the d71715f commit body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `core.fsmonitor`, a multi-valued `include.path`, `includeIf.gitdir:…path`, `filter.lfs.*`, and a `config.worktree` `filter.WT.clean`, each removed with the file and key exactly as the refusal prints them, and the rerun then passing. It does not cover keys with a `=` or newline in a subsection name.

P6 fed each refusal line's file and key into `git config --file <f> --unset-all <k>`. Every call returned rc=0 except the **second** `include.path` line, which returned rc=5 because the first `--unset-all` had already removed both values. That is harmless, but a user pasting one command per listed line will see it. The rerun after the remedies returned rc=0 and blessed. The old remedy, for comparison: `git config --local --unset include.path` on a two-valued key gives `warning: include.path has multiple values` and rc=5. `--local --unset` of a `config.worktree` key gives rc=5, while `--file …/config.worktree --unset-all` gives rc=0.

**Evidence:** `devcontainer-config/install.sh:228-239`. `probe-p3.log` (P6). `docs/reviews/execution-logs/q058p3-fc/old-remedy-worktree.log`: `bash old-remedy-worktree.sh`, cwd `q058p3-fc`, exit 0, 2026-09-25T08:48:19Z.

---

## Claim 8: "Removing filter.lfs.* disables Git LFS in this clone; set LFS up in your global config instead (`git lfs install`, without --local)."

**Location:** `devcontainer-config/install.sh:235-237`; `README.md:38-39`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only the message text. It does not establish git-lfs's behaviour.

The text is printed as quoted (`install.sh:235-237`). Whether `git lfs install` without `--local` writes the global config, and whether removing the local keys disables LFS, depends on git-lfs. git-lfs is not installed here and the sandbox has no egress, so this was not run. From general knowledge (paraphrased — no quote available because the subject is an external tool absent from the sandbox), `git lfs install` defaults to the global config. The "disables LFS in this clone" half holds only when no global or system `filter.lfs.*` exists. When one does, the local keys were redundant and removing them changes nothing. Needed to verify: git-lfs on the host, then run `git lfs install` in a scratch HOME and inspect `~/.gitconfig`.

**Evidence:** `devcontainer-config/install.sh:235-237`, `README.md:38-39`.

---

## Claim 9: "A copy that fails part-way takes the same path (P2-A2, T83), so an altered `cc-isolated.sh` copied before the failure never stays live." / "A failed rm or cp in the loop, a symlink in $DEST, and a hash mismatch all go through [dc_unwind]"

**Location:** `devcontainer-config/install.sh:430-445,550-569`; `docs/decisions/037-bare-host-copy-install.md:68`; the b58d671 commit body
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a failing `cp` or `rm -rf` in the copy loop, a link in `$DEST`, and a post-copy mismatch. It does **not** cover a failure of the *checks themselves*. When `links_in`'s last `find` (the `claude-home` item) fails, the bare assignment `links="$(links_in …)"` at `:563` exits through `set -e` **before** `dc_unwind`. P9b shows this leaves a tampered `cc-isolated.sh` live behind a resolving `~/.local/bin/cc-isolated`. That run blessed nothing and printed only find's `Permission denied`.

```bash
# devcontainer-config/install.sh:554-569
  local copy_failed=""
  for item in "${PAYLOAD[@]}"; do
    if ! rm -rf "${DEST:?}/$item" || ! cp -Rp "$stage/$item" "$DEST/$item"; then
      copy_failed="$item"; break
    fi
  done
  if [ -n "$copy_failed" ]; then
    dc_unwind "could not copy '$copy_failed' into $DEST."
  fi
  links="$(links_in "$DEST" "" "${PAYLOAD[@]}")"
  if [ -n "$links" ]; then
    dc_unwind "symlinks landed in $DEST, which install.sh never installs:" "$links"
  fi
  if [ "$(tree_hash "$DEST" "" "${PAYLOAD[@]}")" != "$reviewed_hash" ]; then
    dc_unwind "the devcontainer config copied into $DEST differs from what the review showed (the stage changed after review, during the copy)."
  fi
```

`dc_unwind` (`:434-445`) removes every PAYLOAD item and exits 1 before `chmod` (`:571`), the link (`:573`) and the bless (`:577`). T83 passes at 516124d and fails at fa25f13. The rerun A1b probe no longer reproduces: `[ -e "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ]` fails, so the link dangles. P9, with an unreadable dir planted in `egress` (not the last item), still unwinds: `links_in` returns the last iteration's status, which masks the error, and the hash mismatch catches it. P9b, with the same plant in `claude-home`, the last item, exits rc=1 with `cc-isolated.sh left in DEST: yes; TAMPERED lines in it: 1; bin link resolves: yes; blessed: 0`. This is the same fail-open shape A1b had. 21bf405's own note warned about it for `tree_hash` ("It runs inside $(...), where a failure would exit silently through set -e"). Reaching it needs a same-uid writer in `~/.config/claude-devcontainer`, which 037 already says can "edit the installed config and re-bless it without the installer". So it is a residual, not a regression.

**Evidence:** `devcontainer-config/install.sh:430-445,550-577,650-654`. `prefix-bats.log`: `bash prefix-bats.sh /workspace/.claude/wt-q058p2`, cwd `q058p3-fc`, exit 0, 2026-09-25T08:44:17Z. `secrev-p2-probes-rerun.log` (A1, A1b). `probe-p3.log` (P9). `probe-p3b.log` (P9b).

---

## Claim 10: "a symlink is refused wherever a hash is taken (review P2-R2, T77–T79): in the host copies before their hash, in the devcontainer stage before its hash, and in `$DEST` after the copy … Links that appear after a hash change it, so the existing post-y checks catch them."

**Location:** `docs/decisions/037-bare-host-copy-install.md:70`; `devcontainer-config/install.sh:494-502,563-566,646-654,833-842`; the 21bf405 commit body
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three pre-hash `links_in` sites and a post-y link swap on the host copies (identical content, so only the type changes). It does not establish that `links_in` itself cannot fail open (see Claim 9's scope).

`links_in` runs `find "$dir/$pfx$name" -type l` per name (`:653`). It precedes the devcontainer pre-review hash (`:494-503`), `$DEST` after the copy (`:563-566`), and the host copies, manifest included (`:833-843`: `links="$(links_in "$dest" .cw-new. "${CLAUDE_HOME_NAMES[@]}" manifest)"`). The post-y sites (`:538`, `:955`) rely on `tree_hash`, which records type and target: `find … -printf '%P\t%y\t%m\t%l\n'` (`:641`). P2 replaced `.cw-new.hooks/h.sh` with a link to a file holding identical bytes while the host prompt waited. The run printed "the copies to install changed after review" with rc=1, nothing was installed, and no `.cw-new.*` or `.cw-stage.*` was left. T77–T79 fail at 99656a2 and pass at 516124d. The rerun SP1e probe (a race in `$TMPDIR/cw-devc-stage.*`) planted its link (`helper.hits` non-empty) and the install was refused before `$DEST` was created. They are deterministic: each plants the link from a `cp` stub at a fixed call (`test/install-host.bats:724-732`), not from a racing writer.

**Evidence:** `devcontainer-config/install.sh:494-503,538,563-566,636-654,833-843,955`, `test/install-host.bats:724-774`. `probe-p3.log` (P2), `prefix-bats.log`, `secrev-p2-probes-rerun.log` (SP1e).

---

## Claim 11a: "take the lock; extract the stage into $dest/.cw-stage.*; copy it into $dest/.cw-new.*; hash those copies and review them against a view of the current destination, also built in $dest/.cw-stage.*"

**Location:** `devcontainer-config/install.sh:777-792,890-898`; `docs/decisions/037-bare-host-copy-install.md:67`; `docs/working/plan-copy-install-bare-host.md:139` (R4: the lock is "taken before anything is staged and held through the review")
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order and location of the lock, the stage, the copies and the review's old-side view. It does not establish that the destination is agent-proof. That rests on the sandbox's `denyWrite`, which 037 states is needed for a non-default `CLAUDE_HOME_DIR`/`CLAUDE_CONFIG_DIR` and which cannot be exercised here.

The order in `install_claude_home` is: lock (`:794`); clear stale stages (`:807`); `HOST_TMP="$(mktemp -d "$dest/.cw-stage.XXXXXX")"` (`:808`); `local stage="$HOST_TMP/payload"` and `assemble "$stage"` (`:812-813`); copies (`:817-825`); `links_in` and hash (`:833-843`); `local view="$HOST_TMP/installed"` (`:896`). The P4 mktemp log for a host run shows `mktemp -d $S/home/.claude/.cw-stage.XXXXXX`. T80 (old side rewritten) and T81 (stage edited) fail at 21bf405 and pass at 516124d. In both, the `$TMPDIR` writer's `helper.saw` and `helper.hits` stay empty.

**Evidence:** `devcontainer-config/install.sh:777-843,890-898`. `probe-p3.log` (P4), `prefix-bats.log`.

---

## Claim 11b: "Nothing of this target sits in $TMPDIR" / "the host target no longer uses $TMPDIR at all"

**Location:** `devcontainer-config/install.sh:780`; `docs/decisions/037-bare-host-copy-install.md:67`; the fa25f13 commit body
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `mktemp` call during a host run. The remaining `$TMPDIR` file only carries docker's stderr text into a NOTE line. This verdict does not rate that file as a security exposure, and does not cover temp files that git, sort or diff might create internally.

No stage, copy or review input is in `$TMPDIR`. But `agent_gate`, which the host target calls at `:748` and `:953`, still makes a file there when docker is on PATH:

```bash
# devcontainer-config/install.sh:1094
    errf="$(mktemp "${TMPDIR:-/tmp}/cw-docker-err.XXXXXX")"
```

The P4 mktemp log for one `n`/`y` run shows `cw-docker-err.XXXXXX` in `$S/tmp` three times (startup, host pre-stage, host post-y) and one `cw-devc-stage` for the declined devcontainer target. Precise version: "no stage, copy or review input of this target is in `$TMPDIR`; only agent_gate's docker-stderr temp file is."

**Evidence:** `devcontainer-config/install.sh:748,953,1094-1101`. `probe-p3.log` (P4).

---

## Claim 12: "A killed run leaves its stage behind; under the lock no other run uses one. (rm of a name without a trailing slash removes a planted link, not its target.)"

**Location:** `devcontainer-config/install.sh:805-807`; T82 (`test/install-host.bats:610-620`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a stale stage directory, a `.cw-stage.*` link to a directory, and one to a file. It does not establish recovery from a SIGKILLed run's leftover *lock*, which still refuses with `lock_msg` until the user removes it (`:773-775`).

`rm -rf "$dest"/.cw-stage.*` (`:807`) expands to names with no trailing slash. P3a planted `.cw-stage.OLD/payload/sub/f`, `.cw-stage.LD -> $S/elsewhere` and `.cw-stage.LF -> $S/elsefile`. The install completed with 0 `.cw-stage.*` left, `sentinel=keep` and `elsefile=keepf`. T82 passes at 516124d.

**Evidence:** `devcontainer-config/install.sh:805-813`. `probe-p3.log` (P3a), `bats.log`.

---

## Claim 13: "host_cleanup removes the stage on every exit path, as before" / "A decline, 'nothing to install' or any error removes the stage and the copies"

**Location:** `devcontainer-config/install.sh:685-697,786-787`; the fa25f13 commit body
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers decline, nothing-to-install, a git-state refusal after the lock, SIGINT and SIGTERM at the host prompt, a post-y hash refusal, and the unwritable-destination exit. SIGKILL is not covered: no trap can run, and the leftover lock blocks the next run until it is removed.

`host_cleanup` removes `$HOST_TMP` (now `$dest/.cw-stage.*`), the `.cw-new.*` copies, the lock, and a destination the run created (`:689-696`). P3b results for each path:

| Path | `.cw-stage.*` left | `.cw-new.*` left | Lock left |
|---|---|---|---|
| decline | 0 | 0 | no (the first-install destination was also removed) |
| nothing to install | 0 | 0 | no |
| git state planted while the devcontainer prompt waited (refused inside the host `assemble`) | 0 | 0 | no |
| SIGINT (rc=130) | 0 | 0 | no |
| SIGTERM (rc=143) | 0 | 0 | no |

P2 (post-y refusal) and P5 (unwritable destination) also left nothing.

**Evidence:** `devcontainer-config/install.sh:685-697,1184-1185`. `probe-p3.log` (P2, P3b, P5).

---

## Claim 14: "Each check also prints a progress line before it asks docker, and a host without a reachable docker prints a NOTE line at each check."

**Location:** `docs/decisions/037-bare-host-copy-install.md:33`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers docker absent and docker present. The unreachable-docker path (progress line, then NOTE) was read, not run.

The progress line is printed only on the branch that has docker:

```bash
# devcontainer-config/install.sh:1086-1093
  if ! command -v docker >/dev/null 2>&1; then
    echo "NOTE: docker not found: cc-isolated containers not checked, treated as none running."
  else
    ...
    echo "Checking for running cc-isolated containers (docker ps; up to 20 s)..."
```

P7 with docker absent: `progress=0` and NOTEs=1 on a closed-stdin run. With the docker stub and `--yes`: 2 progress lines, 0 NOTEs. "Each check" is literally true only when docker is on PATH. Precise version: "each check that asks docker first prints a progress line; with docker missing it prints only the NOTE."

**Evidence:** `devcontainer-config/install.sh:1084-1103`. `probe-p3.log` (P7).

---

## Claim 15: "a NOTE line says so, one per check (one to four per run, depending on the answers)"

**Location:** `docs/decisions/037-bare-host-copy-install.md:76`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers docker absent across five answer shapes. It does not establish counts on runs that exit early (e.g. the gate refuses).

The four checks are at `install.sh:1182` (startup), `:536` (after the devcontainer y), `:748` (host pre-stage) and `:953` (after the host y). P7 NOTE counts:

| Run | NOTEs |
|---|---|
| closed stdin | 1 |
| `--yes` | 2 |
| pty n,n | 2 |
| pty n,y | 3 |
| pty y,y (installed) | 4 |

**Evidence:** `devcontainer-config/install.sh:536,748,953,1182`. `probe-p3.log` (P7).

---

## Claim 16: The P2-R1 residual paragraph (git runs hooks, including `post-index-change` on an index rewrite, and recurses into submodules; the flags prevent each; "`git archive` never enters one"; "none of 17 further keys probed on git 2.39.5 fired")

**Location:** `docs/decisions/037-bare-host-copy-install.md:80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High (on git 2.39.5)
**Verification mode:** executed
**Scope:** Covers git 2.39.5, the 17 listed keys, hooks and submodules. It does **not** cover git ≥ 2.54's config-based hooks. Those are a new command-running mechanism set by `hook.<name>.command`, a key outside `GIT_EXEC_KEYS_RE`. Web sources (unverified here) say they run alongside hook-directory scripts, so `core.hooksPath=/dev/null` may not switch them off. In install.sh's calls they would still need an event: `--no-optional-locks` removes the only one seen (`post-index-change`).

Rerunning the pass-2 probe `probe-r1-git-exec.sh` against 516124d:

| Case | Marker fired | Install result |
|---|---|---|
| A (`.git/hooks`) | no | proceeds, blessed |
| B (`core.hooksPath`) | no | proceeds, blessed |
| 17 "C" keys | no | proceeds, blessed |
| D–G (refused keys) | no | refused |

The 17 "C" keys are 15 single keys, `url.<ext>.insteadOf`, and `log.showSignature`+`gpg.program`, so "17" matches. The submodule claim holds because T76, whose submodule sits under the archived `skills/`, installs with neither `sub-clean-ran` nor `sub-hook-ran`. "It also recurses into submodules" (pre-fix) is shown by T76 failing at f8d3f78.

**Evidence:** `docs/reviews/execution-logs/q058p3-fc/probe-r1-git-exec-rerun.log`: `bash ../q058p2-fc/probe-r1-git-exec.sh <wt>/devcontainer-config/install.sh`, cwd `q058p3-fc`, exit 0, 2026-09-25T08:39:50Z. `probe-p3.log` (P1c). `prefix-bats.log`. External: [git-hook(1) 2.54](https://git-scm.com/docs/git-hook/2.54.0.html), [Highlights from Git 2.54](https://github.blog/open-source/git/highlights-from-git-2-54/), [Collabora: Git hooks in 2.54](https://www.collabora.com/news-and-blog/news-and-events/git-hooks-upgraded-whats-new-git-254-and-coming-255.html). WebFetch has no egress here, so these are search results only and are unverified.

---

## Claim 17: "(no token claude or .../claude, and none of the /@anthropic-ai/claude-code/, /claude/versions/ or /claude-agent-sdk/ paths CLAUDE_PROC_RE matches)"

**Location:** `docs/decisions/037-bare-host-copy-install.md:93`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the correspondence of the trigger's text to the regex. It does not establish the regex's match behaviour (pass-2 fact-check territory, unchanged here).

`install.sh:1067`: `CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/|/claude/versions/|/claude-agent-sdk/'`. The trigger names every alternative. The `.exe` variant is folded into "token claude".

**Evidence:** `devcontainer-config/install.sh:1056-1067`.

---

## Claim 18: "*(Superseded 2026-09-25, re-review P2-R3: the host stage and the review's view of the destination go into `mktemp -d "$dest/.cw-stage.XXXXXX"`, after the lock is taken.)*"

**Location:** `docs/working/plan-copy-install-bare-host.md:64`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the host target. The devcontainer target still stages in `$TMPDIR` (`install.sh:473`), which the plan line does not claim otherwise.

`install.sh:794` (lock) precedes `:808` (`mktemp -d "$dest/.cw-stage.XXXXXX"`), and `:896` puts the view at `$HOST_TMP/installed`.

**Evidence:** `devcontainer-config/install.sh:794-813,896`.

---

## Claim 19: "install.sh is 1193 lines after … both re-review passes (1104 before pass 2 …)" and the pass-2 fix list with its test numbers

**Location:** `docs/working/plan-copy-install-bare-host.md:249-250`; the 516124d commit body
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line counts at f8d3f78 and 516124d, and that T75–T83 exist with the named subjects. The earlier counts (958, 808) were not rechecked; they belong to prior passes.

`git show <c>:devcontainer-config/install.sh | wc -l` gives f8d3f78 1104 and 516124d 1193. The list maps P2-R1 to T75/T76, P2-R2 to T77–T79, P2-R3/A1 to T80–T82 and P2-A2 to T83, matching the test names in `bats.log`.

**Evidence:** `docs/reviews/execution-logs/q058p3-fc/line-counts.log`, `bats.log`.

---

## Claim 20: "since Q-058 each no-agent check adds a progress line before it asks docker (plus a NOTE when docker is missing or unreachable)"

**Location:** `docs/working/plan-copy-install-bare-host.md:253`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 14.

"Plus" is wrong for missing docker: that branch prints the NOTE *instead of* the progress line (`install.sh:1086-1093`, quoted in Claim 14). P7 recorded `progress=0` with docker absent. It is right for unreachable docker, where the progress line is followed by a NOTE (`:1093-1098`).

**Evidence:** `devcontainer-config/install.sh:1086-1100`. `probe-p3.log` (P7).

---

## Claim 21: "One `ln` per PATH directory and no per-entry test … non-executable entries get linked too, which is harmless … A name an earlier directory already linked makes ln report 'File exists' and go on, so the first on PATH wins"

**Location:** `test/install-host.bats:56-70`; the 767f421 commit body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU ln's continue-on-error behaviour and the first-wins result. The "1.6 s wall" figure is machine-specific. It measured 1.16 s here.

```bash
# test/install-host.bats:67-70
  for dir in $PATH; do
    [ "$dir" = "$STUB" ] || [ ! -d "$dir" ] && continue
    ln -s "$dir"/* "$farm/" 2>/dev/null || true
  done
```

`ln-first-wins.log` shows that with `farm/x` already linked from `a`, `ln -s b/* farm/` reports `File exists` with rc=1, yet links `y` and `z`, and `farm/x` still points into `a`. An empty PATH dir creates a dangling link literally named `*`. That is harmless, and the comment does not mention it. P7 used the same construction to remove docker from PATH successfully. `time bats -f '^T(52|53|57|72) '` took 1.164 s total, with 4/4 ok.

**Evidence:** `test/install-host.bats:56-74`. `docs/reviews/execution-logs/q058p3-fc/ln-first-wins.log` (2026-09-25T08:47:40Z) and `t52-57-72-timing.log` (2026-09-25T08:47:54Z, cwd the worktree).

---

## Claim 22: "T72 no longer sleeps a fixed 1 s + 3 s. The feed touches agent-up as soon as the mirror exists (so after the startup check), and clears it once the pgrep stub's log shows the host target's pre-stage check has run (the second pgrep call)."

**Location:** `test/install-host.bats:1196-1208`; the 767f421 commit body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call order and 5/5 passing runs. It does not establish zero flake probability. `stub_pgrep` logs its argv (`test/install-host.bats:47-50`) *before* evaluating `agent-up`/`agent-down`. So the feed polling every 0.05 s can in principle touch `agent-down` between those two steps, a microsecond window that would make call 2 see no agent.

The startup gate (`install.sh:1182`) runs before `install_devcontainer` builds the mirror, so the mirror existing means pgrep call 1 has finished. With the devcontainer target declined there is no post-y gate, so call 2 is the host pre-stage gate (`:748`). T72 passed 5 of 5 runs at 516124d.

**Evidence:** `test/install-host.bats:45-54,1196-1215`, `devcontainer-config/install.sh:536,748,1182`. `prefix-bats.log` (T72 ×5).

---

## Claim 23: T75–T83 "failed on the pre-fix code" and pass now; T77–T79 are deterministic; T80/T81 "fail on the pre-restructure code, where the writer sees cw-host-stage.*"

**Location:** `test/install-host.bats:561-620,1251-1426`; the 99656a2, 21bf405, fa25f13 and b58d671 commit bodies
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each new test against install.sh from the commit just before its fix, and at 516124d. T80/T81 prove only that nothing of the host target is in `$TMPDIR`. They do not prove a writer cannot do the same under `$dest`, which is the accepted residual (037, C8). T82 also fails pre-fix, trivially, since the code did not yet exist. No commit claims otherwise.

`prefix-bats.sh` copies the 516124d `install-host.bats` beside each older install.sh:

| install.sh at | Tests | Result |
|---|---|---|
| f8d3f78 | T75, T76 | not ok |
| 99656a2 | T77–T79 | not ok |
| 21bf405 | T80–T82 | not ok |
| fa25f13 | T83 | not ok |
| 516124d | all 9 | ok |

T77–T79 plant through `stub_cp_then` at a fixed `cp` destination pattern, with no background writer.

**Evidence:** `docs/reviews/execution-logs/q058p3-fc/prefix-bats.sh`, `prefix-bats.log` (2026-09-25T08:44:17Z–08:45:23Z).

---

## Claim 24: "Suites: 175/175."

**Location:** the b58d671, e61408f, d71715f and 767f421 commit bodies
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `test/install-host.bats` and `test/cc-isolated-functions.bats` at 516124d in this sandbox. The suite does not pin `GIT_CONFIG_GLOBAL`/`GIT_CONFIG_NOSYSTEM`, which is hermetic enough here since `/etc/gitconfig` is absent and HOME is temp.

`bats test/install-host.bats test/cc-isolated-functions.bats`, cwd `/workspace/.claude/wt-q058p2`: `1..175`, 175 `ok`, bats exit 0, 2026-09-25T08:39:43Z–08:41:38Z.

**Evidence:** `docs/reviews/execution-logs/q058p3-fc/bats.log`.

---

## Claim 25: "T56 pins both new --help paragraphs and the README lines. T65 pins the new remedy and the LFS warning."

**Location:** the d71715f commit body; `test/install-host.bats:1018-1022,1285`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence of the assertions and that they pass. They pin substrings, not the accuracy of the sentences (Claims 1, 2, 8).

The T56 additions assert `filter.*, core.fsmonitor or include*` and `not writable is refused before the review, with exit 1` in `--help`, and `--unset-all` and `unwritable destination is refused before the review` in the README. T65 adds `[[ "$output" == *'--unset-all <key>'*'filter.lfs'* ]]`. Both pass in `bats.log`.

**Evidence:** `test/install-host.bats:1018-1022,1285`. `bats.log`.

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 1** (`README.md:34-38`): the refusal prints one generic `git config --file … --unset-all` template after the list, not a command per entry, and attributes entries are removed by emptying the file.
- **Claim 11b** (`devcontainer-config/install.sh:780`; 037:67; fa25f13): "nothing of this target in $TMPDIR" should say "no stage, copy or review input". `agent_gate`'s `cw-docker-err.*` is still made in `$TMPDIR` at the host checks.
- **Claim 14** (037:33): the progress line is printed only when docker is on PATH. With docker missing, each check prints only the NOTE.
- **Claim 20** (plan:253): "plus a NOTE when docker is missing" should be "instead, a NOTE when docker is missing; plus a NOTE when unreachable".

### Unverifiable
- **Claim 8** (`devcontainer-config/install.sh:235-237`; README): the LFS advice depends on git-lfs. It needs git-lfs installed, then `git lfs install` in a scratch HOME. "Disables LFS in this clone" holds only if no global `filter.lfs.*` exists.

---

## Goal-Alignment Note

The goal is to merge the copy-install work to main once review passes, and this is the terminal pass. The fix commits answer every Pass-2 item they cite, and their claims hold:

- **P2-R1:** no hook or submodule command ran in any executed shape, and plain-git controls prove the setups live.
- **P2-R2:** links are refused at each pre-hash site, and a post-y link swap is caught by the hash.
- **P2-R3/A1:** stage, copies and old-side view are all under `$dest`, taken after the lock, with stale stages cleared and every trapped exit path clean.
- **P2-A2:** a failed `cp`/`rm` unwinds.
- **P2-A4/A5:** the remedy exits 0 and the unwritable-destination exit 1 is documented.
- **Test claims:** 175/175, and every new test fails on its pre-fix code.

No claim is Incorrect. The four Mostly-accurate items are doc wording and do not block the merge.

Three findings are for the critics and the user. None is a claim defect.

1. **`links_in` can fail open, the same shape as A1b** (Claim 9 scope; P9b). `links="$(links_in "$DEST" …)"` at `install.sh:563` is a bare assignment, so a `find` failure on the last PAYLOAD item exits through `set -e` before `dc_unwind`. P9b left a tampered `cc-isolated.sh` live behind a resolving `~/.local/bin/cc-isolated`, with no bless and no message beyond find's. The host site (`:833`) has the same shape, but there a failure happens before any swap, so nothing goes live. Reaching the devcontainer case needs a writer in `~/.config/claude-devcontainer`, which 037 already treats as able to re-bless on its own, so this is a residual, not a regression. It is an easy fix if the reviewers want one (`links="$(…)" || dc_unwind …`).
2. **Config-based hooks (git ≥ 2.54)** (Claims 3, 16). Git here is 2.39.5, which ignores `hook.<name>.command`. From 2.54 such hooks are configured in `.git/config` under a key the gate does not refuse, and web sources say they run alongside hook-directory scripts. So `core.hooksPath=/dev/null` is not shown to switch them off. `--no-optional-locks` still removes the one event (`post-index-change`) that install.sh's calls were seen to trigger. The "install.sh's git calls never run them" wording is therefore proven only on 2.39.5. A host with git ≥ 2.54 should rerun `probe-p3.sh` P1c with the install instead of plain status (or 037 should list `hook.*` in the gate or its residuals).
3. **A dropped MODE line gives an empty-looking review** (Claim 4). When vis fails only on a MODE line, the human is prompted to approve a review that shows no change. The comment says exactly this, so it is not a doc defect. It is a fail-open review surface the critics may want to weigh.
