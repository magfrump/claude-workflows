# Code Fact-Check Report

**Commit:** f5e3029
**Replication:** k=1 (loop pass, decision 031)

**Repository:** `/workspace` (branch `skill-fixtures`; code read and run in the worktree `/workspace/.claude/wt-q058p2` at f5e3029)
**Scope:** the pass-3 fix commit `516124d..f5e3029` (one commit, 207-line diff). Files: `devcontainer-config/install.sh`, `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `docs/working/plan-copy-install-bare-host.md`, `test/install-host.bats`, and the commit message. It answers P3-A1, P3-A2, P3-A4 and the P3-A3 residual text in the pass-3 section of `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md`. (The rename of the pass-2 report is bookkeeping and holds no claims.)
**Checked:** 2026-09-25
**Total claims checked:** 20
**Summary:** 14 verified, 1 mostly accurate, 1 stale, 2 incorrect, 2 unverifiable

**Method note.** Every function that encloses a changed line was read whole: `repo_git`, `git_state_gate`, `assemble`, `review_diff`, `mode_diff`, `dc_unwind`, `install_devcontainer`, `tree_hash`, `links_in`, `payload_hash`, `rm_new_copies`, `host_cleanup`, `host_rollback`, `install_claude_home` (729–1054), `agent_gate` and `main`. `set -euo pipefail` is at `install.sh:26`. There is no `inherit_errexit`, so errexit is off inside command substitutions. Every executed probe is hermetic: temp `HOME` and `TMPDIR`, `GIT_CONFIG_NOSYSTEM=1`, a temp `GIT_CONFIG_GLOBAL`, pgrep and docker stubbed, and a throwaway fake repo holding a *copy* of install.sh. Writers are simulated by `cp` and `find` stubs that exec the real tool. The real `~/.claude` and `~/.config` were never touched. Scripts and logs are in `docs/reviews/execution-logs/q058p4-fc/`. Every `.sh` there has a shebang and passes `shellcheck -x -e SC1091 -s bash -S warning`. Tools: git **2.39.5**, GNU findutils 4.9.0, shellcheck 0.9.0.

**Prior-pattern check.** Every claim was compared against `docs/reviews/hallucination-patterns.md`. Its "specific measured value quoted from an artifact set" shape covers the test count (177/177) and the line count (1193). The test count was recomputed and matches (Claim 16). The line count was true at 516124d and is now stale (Claim 11): a drift, not a fabrication. No claim matches a logged pattern, and no new pattern was found.

---

## Claim 1: "a local `filter.*`, `core.fsmonitor`, `include*` or `hook.*` key, or a non-empty `info/attributes`), both targets are refused before anything is staged. The refusal lists each entry, then gives the `git config --file <file> --unset-all <key>` command that removes one (an attributes entry is removed by emptying the file)."

**Location:** `README.md:34-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refused key list and the shape of the refusal: the entries, then one generic remedy template, and emptying the file for attributes. It does not re-run the remedy's exit codes, which pass 3 executed (its Claim 7). "Before anything is staged" still allows the empty `mktemp -d` stage directory (pass 3, Claim 3).
**Legibility-target:** a user reading the README before a first install. They expect to be told which keys block the install and how to clear them.

This fixes pass-3 Claim 1, which rated the old "each entry is named with the … command" as Mostly accurate. The code prints the list, then one template:

```bash
# devcontainer-config/install.sh:232-236
    printf '%s' "$found"
    echo "       An agent, or a cc-isolated container through its bind mount, can write"
    echo "       these. Check each one and remove it, with"
    echo "         git config --file <the file named above> --unset-all <key>"
    echo "       or by emptying the attributes file, then rerun. Removing filter.lfs.*"
```

The key list matches `GIT_EXEC_KEYS_RE='^(filter\.|core\.fsmonitor|include|hook\.)'` (`install.sh:197`) and the `-s "$attrs"` test (`install.sh:224`). In A1, the refusal lists six mixed-case entries, one per line, then the template.

**Evidence:** `devcontainer-config/install.sh:197,224-240`. `docs/reviews/execution-logs/q058p4-fc/probe-p4.log` (A1): `bash probe-p4.sh <wt>/devcontainer-config/install.sh`, cwd `q058p4-fc`, exit 0, 2026-09-25T09:04:44Z.

---

## Claim 2: "Both targets are refused, before anything is staged, when the checkout's own .git holds a filter.*, core.fsmonitor, include* or hook.* key (in config or config.worktree)"

**Location:** `devcontainer-config/install.sh:73-75` (`--help`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key list and the two files read. It does not establish that `config.worktree` is read for `hook.*` in particular: that file is read by the same loop and regex, but the loop was run in A1 with `.git/config` only.
**Legibility-target:** a user running `install.sh --help`.

`git_state_gate` runs `--get-regexp "$GIT_EXEC_KEYS_RE"` over each of `config` and `config.worktree`:

```bash
# devcontainer-config/install.sh:200,209
  for f in config config.worktree; do
    out="$(git --no-pager -c core.hooksPath=/dev/null config --file "$f" --no-includes --get-regexp "$GIT_EXEC_KEYS_RE")" || rc=$?
```

T56 pins the new `--help` string (`test/install-host.bats:1019`: `*'filter.*, core.fsmonitor, include* or hook.*'*`), and it passes in the 177-test run.

**Evidence:** `devcontainer-config/install.sh:73-78,198-241`, `test/install-host.bats:1019`. `q058p4-fc/bats.log` (see Claim 16). `q058p4-fc/probe-p4.log` (A1).

---

## Claim 3: "`hook.*` is in GIT_EXEC_KEYS_RE" / "The git-state refusal now covers hook.* keys (T84)", with the new message text "(a filter, core.fsmonitor, an include, a config-based hook, or an attributes file)"

**Location:** `devcontainer-config/install.sh:197,229-231`; commit f5e3029 body
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers matching for `hook.*` in any case of section or key, and in any subsection case, as `git config --get-regexp` prints it on git 2.39.5. It also covers the message text. It does not establish that a git ≥ 2.54 still canonicalizes names this way (very likely, since canonical config names predate hooks, but unrun) or that refusing is needed there (Claim 9).
**Legibility-target:** a reviewer asking whether `Hook.X.command` or `[HOOK "x"]` slips past a case-sensitive regex.

The regex is case-sensitive, but git matches it against the canonical key name. Section and key are lowercased, and the subsection is kept as written. In A1, raw lines written into `.git/config` as `[Hook "MixedSub"] Command=…`, `EVENT=…`, `[HOOK "x"] command=…`, `[Filter "Y"] Smudge`, `[Core] FsMonitor`, `[IncludeIf "gitdir:/nowhere/"] Path` were read back by the gate's own command as:

```
  hook.MixedSub.command /bin/true
  hook.MixedSub.event post-index-change
  hook.x.command /bin/true
  filter.Y.smudge cat
  core.fsmonitor /bin/false
  includeif.gitdir:/nowhere/.path /nonexistent
```

The install exited 1 and listed all six (`probe-p4.log`, A1). A2 is the negative control: a lone `hooks.allowunannotated` (plural, a common hook-script setting) does not match, and the install blesses (`rc=0 blessed=1`). The message reads `install (a filter, core.fsmonitor, an include, a config-based hook, or an` / `attributes file):` (A1 output, matching `install.sh:229-231`).

**Evidence:** `devcontainer-config/install.sh:197,209,229-231`. `q058p4-fc/probe-p4.log` (A1, A2), cwd `q058p4-fc`, exit 0, 2026-09-25T09:04:44Z. T84 is covered in Claim 15.

---

## Claim 4a: "A missing item holds no link and is left to the hash check that follows" — at the `$DEST` site

**Location:** `devcontainer-config/install.sh:653` (applied at `:565-571`)
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a PAYLOAD item missing from `$DEST` after its copy. There, `tree_hash` over `$DEST` differs from the reviewed hash and `dc_unwind` runs. It does not cover the other two call sites (Claim 4b).
**Legibility-target:** a maintainer relying on this comment to know what stops a missing item.

```bash
# devcontainer-config/install.sh:659-662
  for name in "$@"; do
    [ -e "$dir/$pfx$name" ] || [ -L "$dir/$pfx$name" ] || continue
    find "$dir/$pfx$name" -type l || return 1
  done
```

```bash
# devcontainer-config/install.sh:570-571
  if [ "$(tree_hash "$DEST" "" "${PAYLOAD[@]}")" != "$reviewed_hash" ]; then
    dc_unwind "the devcontainer config copied into $DEST differs from what the review showed (the stage changed after review, during the copy)."
```

T85's shape (claude-home removed right after its copy, cc-isolated.sh tampered as it lands): f5e3029 gives `rc=1 ERROR-lines=1 blessed=0 launcher-tampered-live=0 bin-link-resolves=no`, ending in "The copied items were removed again".

**Evidence:** `devcontainer-config/install.sh:435-446,556-572,639-663`. `q058p4-fc/t85-shape-old.log`: `bash t85-shape-old.sh /workspace`, cwd `q058p4-fc`, exit 0, 2026-09-25T09:08:50Z.

---

## Claim 4b: "A missing item holds no link and is left to the hash check that follows" — at the stage and host sites

**Location:** `devcontainer-config/install.sh:653` (applied at `:495-505` and `:842-853`)
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what actually stops an item that is missing at the stage-site and host-site `links_in` calls, on first installs and reinstalls. It does not establish any risk beyond a writer inside the destination (037's C8). Every run that stayed missing ended with nothing installed.
**Legibility-target:** a maintainer who reads "left to the hash check" and assumes the hash would catch a missing (or reappearing) host copy.

At both sites the hash that follows is taken *from* the tree with the item missing. So it records the absence as the reviewed state, and the post-y check compares absence with absence:

```bash
# devcontainer-config/install.sh:853 (host), :505 (stage)
  reviewed_hash="$(payload_hash "$dest" .cw-new. "$dest/.cw-new.manifest")"
  reviewed_hash="$(tree_hash "$stage" "" "${PAYLOAD[@]}")"
```

What catches it, executed:
- **Host, reinstall (C1a):** the review shows the entry as a deletion (`-x` for `guides/g.md`, plus "MOVE to backup (not in the repo)") and reaches `Install these files …? [y/N]`. After the y, the hash check passes. The swap's `mv "$dest/.cw-new.$name" "$dest/$name" || host_rollback` (`:1002`) fails, and the rollback runs ("rolled back: every entry was moved back").
- **Host, first install (C1b):** the ADD listing's `lines="$(find "$new$name" … | wc -l)"` (`:914`) fails under pipefail and set -e. The run exits 1 before the prompt, with only find's message.
- **Stage (C2a, C2b):** the copy fails: "ERROR: could not copy 'egress' into …" (`:558-563`).
- **A missing item that reappears before the hash** is hashed as it reappears, links included, so the post-y check accepts it. M1: `.cw-new.manifest` is missing at `links_in` and comes back as a symlink. The install completes, `.claude-workflows-manifest` is installed as a link, and the append at `:1012-1015` writes through it to the link's target (`link target got the install's append: 1`). On 516124d, M1 was stopped: the last item's `find` failed, and set -e ended the run. M2 does the same with a directory item (a link inside `.cw-new.hooks`), and it installs a live link **on both 516124d and f5e3029**, so M2 is not new.

Only the C1c shape, where the item is removed *after* the hash, is caught by the hash ("the copies to install changed after review").

**Evidence:** `devcontainer-config/install.sh:495-505,826-853,906-936,965-1004`. `q058p4-fc/probe-p4.log` (C1a, C1b, C1c, C2a, C2b). `q058p4-fc/probe-p4b-new.log` and `probe-p4b-old.log` (M1, M2, C1a′): `bash probe-p4b.sh <install.sh>`, cwd `q058p4-fc`, exit 0, 2026-09-25T09:06:29Z (f5e3029) and 09:06:35Z (516124d).

---

## Claim 5: "a find that cannot read a tree fails the call, and every caller turns that into a refusal"

**Location:** `devcontainer-config/install.sh:654-655`; call sites `:495-496`, `:565-566`, `:842-843`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the routing: under `set -e`, a failing `links_in` in `links="$(…)" || links="(…)"` reaches the fallback, and each site then enters its refusal (at `$DEST`, `dc_unwind`). Whether each refusal then prints its message is Claim 14.
**Legibility-target:** the brief's check 1: is the fallback reached under `set -e`, and does the `$DEST` site reach `dc_unwind`?

The assignment is the left operand of `||`, so errexit does not fire on it. `links_in` returns 1 explicitly (`:661`), so its return does not depend on errexit.

```bash
# devcontainer-config/install.sh:565-569
  links="$(links_in "$DEST" "" "${PAYLOAD[@]}")" \
    || links="(the symlink check could not read every item)"
  if [ -n "$links" ]; then
    dc_unwind "symlinks landed in $DEST, which install.sh never installs:" "$links"
  fi
```

Executed, with a mode-000 directory planted by a `cp` stub:
- **Stage (B1):** `rc=1`, then "ERROR: symlinks appeared in the staged devcontainer config after its link check:" / "(the symlink check could not read every item)". Nothing is in `$DEST`.
- **`$DEST` (B2b, and pass-3's P9b re-run):** `dc_unwind` runs, prints "(the symlink check could not read every item)" and "removed again", `blessed: 0`, and the launcher is absent. In **B2a**, `dc_unwind` is also entered: its loop removed the items before `egress` and then failed on `egress` (Claim 14b).
- **Host (B3):** `rc=1`, "ERROR: symlinks appeared in the copies to install after the payload's link check:", `installed: 0`.

**Evidence:** `devcontainer-config/install.sh:435-446,494-504,565-569,656-663,841-852`. `q058p4-fc/probe-p4.log` (B1, B2a, B2b, B3). `q058p4-fc/probe-p4b-new.log` (B1′, full text). `q058p4-fc/probe-p3b-rerun.log`: `bash ../q058p3-fc/probe-p3b.sh <wt>/devcontainer-config/install.sh`, cwd `q058p4-fc`, exit 0, 2026-09-25T09:09:05Z.

---

## Claim 6: "Nothing the review reads or the install copies sits in $TMPDIR (only the gate's docker stderr file does)"

**Location:** `devcontainer-config/install.sh:789-790`; `docs/decisions/037-bare-host-copy-install.md:67` ("Nothing the review reads or the install copies is in `$TMPDIR` (only the gate's docker stderr file is)")
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the host target's `mktemp` calls and its review inputs. It does not cover the devcontainer target, whose stage is in `$TMPDIR` by design (`:474`, and 037:68).
**Legibility-target:** a security critic checking what a same-uid `$TMPDIR` writer can reach during the host review.

`grep -n 'mktemp\|TMPDIR'` finds three `mktemp` calls: `:474` `DC_TMP="$(mktemp -d "${TMPDIR:-/tmp}/cw-devc-stage.XXXXXX")"` (the devcontainer target), `:817` `HOST_TMP="$(mktemp -d "$dest/.cw-stage.XXXXXX")"`, and `:1104` `errf="$(mktemp "${TMPDIR:-/tmp}/cw-docker-err.XXXXXX")"` (in `agent_gate`). This fixes pass-3 Claim 11b. Pass 3's P4 mktemp log recorded the same set at run time. That was not re-run here: the lines between 516124d and f5e3029 changed only in comments.

**Evidence:** `devcontainer-config/install.sh:474,789-790,817,1104`. `docs/reviews/execution-logs/q058p3-fc/probe-p3.log` (P4). `docs/decisions/037-bare-host-copy-install.md:67`.

---

## Claim 7: "A decline, 'nothing to install' or any error removes the stage and the copies (rm_new_copies here, or main's EXIT trap)."

**Location:** `devcontainer-config/install.sh:795-796` (in the comment block this commit edited)
**Type:** Error-handling / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new unreadable-copy refusal path and the next run after it. It does not re-run the decline, nothing-to-install and signal paths (pass 3's P3b, all clean).
**Legibility-target:** a user or maintainer who assumes that a refused run leaves no `.cw-new.*` behind.

Both cleanups are best-effort and silent: `rm_new_copies` does `rm -rf … 2>/dev/null || true` (`:681`), and `host_cleanup` does `rm -rf "$HOST_TMP" || true` (`:698-699`). They cannot remove a mode-000 directory that has contents. B3 (unreadable `.cw-new.guides`) ends with `.cw-new left: 1`. The **next** run (B3b) then stops at `rm -rf "$dest/.cw-new.$name"` (`:827`) under set -e, with `rc=1` and only `rm: cannot remove '…/.cw-new.guides': Permission denied`. No ERROR line names the leftover. It will do the same on every later run until the user fixes the mode. B1 likewise leaves the devcontainer stage in `$TMPDIR` (`stage left in TMPDIR: 1`). A more precise comment: "…removes the stage and the copies, except a copy it cannot read (then the next run stops at the copy step until it is removed)". Reaching this needs a writer in `$dest`.

**Evidence:** `devcontainer-config/install.sh:679-682,697-706,826-852`. `q058p4-fc/probe-p4.log` (B3, B3b). `q058p4-fc/probe-p4b-new.log` (B1′).

---

## Claim 8: "When docker is on PATH, each check prints a progress line before it asks docker; a host without docker prints a NOTE line at each check instead, and one whose docker is unreachable prints the NOTE after the progress line."

**Location:** `docs/decisions/037-bare-host-copy-install.md:33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the devcontainer run's two checks under three docker states. The host target's checks use the same `agent_gate` and were not counted here.
**Legibility-target:** a user who wonders why a plain run prints extra lines.

```bash
# devcontainer-config/install.sh:1096-1109 (excerpt ends :1109; agent_gate continues to :1133 — read)
  if ! command -v docker >/dev/null 2>&1; then
    echo "NOTE: docker not found: cc-isolated containers not checked, treated as none running."
  else
    ...
    echo "Checking for running cc-isolated containers (docker ps; up to 20 s)..."
    ...
      echo "NOTE: docker is unreachable ($err): cc-isolated containers not checked, treated as none running." | vis_or_die
```

D: reachable gives `progress=2 NOTE=0`. Unreachable gives `progress=2 NOTE=2`, each NOTE right after its progress line. Absent gives `progress=0 NOTE=2`. This fixes pass-3 Claim 14.

**Evidence:** `devcontainer-config/install.sh:1081-1133`. `q058p4-fc/probe-p4.log` (D).

---

## Claim 9: "`hook.*` key (config-based hooks, git ≥ 2.54, which `core.hooksPath` is not shown to switch off; refused rather than trusted, and untested here, since this sandbox has git 2.39.5)" / commit: "git 2.54 added config-based hooks (hook.<name>.command)"

**Location:** `docs/decisions/037-bare-host-copy-install.md:80`; commit f5e3029 body
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the sandbox's git version (2.39.5, true) and the fact that this git ignores `hook.<name>.command`. It does not establish which git release added config-based hooks, or whether `-c core.hooksPath=/dev/null` disables them there.
**Legibility-target:** a user on a host with a newer git, deciding whether the refusal is needed or overbroad.

`git --version` gives `git version 2.39.5` (`probe-p4.log` header). Pass 3's P1c showed that this git does not run a `hook.x.command`/`hook.x.event` pair. So nothing here can confirm or refute the 2.54 behaviour, and the doc says so ("untested here"). The only source is a web search that could not be opened (no egress). What would verify it: on a host with git ≥ 2.54, run T84's setup with the `hook.*` refusal removed and see whether a plain `repo_git status` fires the hook. That is the rubric's P3-A2 revisit trigger.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:80`. `q058p4-fc/probe-p4.log` (header). `docs/reviews/execution-logs/q058p3-fc/probe-p3.log` (P1c).

---

## Claim 10a: "a filter driver defined in `~/.gitconfig` and assigned by a *committed* `.gitattributes`, which `git archive` runs (re-review pass 3, P3-1, executed). A cc-isolated container cannot reach the host's `~/.gitconfig`"

**Location:** `docs/decisions/037-bare-host-copy-install.md:80`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the install running a global smudge filter that a committed `.gitattributes` assigns, and the container's mount list in `devcontainer.json`. It does not establish the mounts that `cc-isolated.sh` might add at run time beyond a grep for `--mount`, `-v` and `type=bind`, which found none.
**Legibility-target:** the user weighing the accepted P3-A3 residual.

E: with `filter.g.smudge` in the (temp) global config and a committed `*.md filter=g`, the install ends `rc=0 blessed=1 global-smudge-ran=yes`. The container's mounts are the workspace and two named volumes:

```jsonc
// devcontainer-config/devcontainer.json:77-80
  "mounts": [
    "source=cc-${localEnv:CC_PROJECT_ID}-bashhistory,target=/commandhistory,type=volume",
    "source=cc-${localEnv:CC_PROJECT_ID}-claude-config,target=/home/node/.claude,type=volume"
  ],
```

`workspaceMount` (`:134`) binds only `${localWorkspaceFolder}`. No mount reaches the host's `~/.gitconfig`.

**Evidence:** `devcontainer-config/devcontainer.json:77-80,134`. `q058p4-fc/probe-p4.log` (E).

---

## Claim 10b: "a bare-host agent that can write it already has equivalent persistence through any other file in `$HOME`"

**Location:** `docs/decisions/037-bare-host-copy-install.md:80`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing on the host. The claim depends on the bare host's sandbox policy (which `$HOME` files agents can write), which is outside this repo and sandbox.
**Legibility-target:** the user deciding whether P3-A3 stays accepted.

(paraphrased — no quote available because the claim is about the host's sandbox configuration, which is not in the checkout.) This is the rubric's `you: terminal` item for P3-A3: check whether the bare host's sandboxed Bash can write `~/.gitconfig` while being denied the other `$HOME` rc files.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:80`. `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md:175,203`.

---

## Claim 11: "install.sh is 1193 lines after the review, fact-check, Q-058 and both re-review passes"

**Location:** `docs/working/plan-copy-install-bare-host.md:250`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count at 516124d and at f5e3029.
**Legibility-target:** a tech-debt reader tracking install.sh against the 500-line guideline.

`wc -l` gives 1193 at 516124d and **1203** at f5e3029. This commit added 10 lines and edited the neighbouring line 253, but not this one.

**Evidence:** `q058p4-fc/shellcheck-wc.log` (`wc: 1203 at f5e3029; 1193 at 516124d`), cwd the worktree, 2026-09-25T09:07:12Z.

---

## Claim 12: "each no-agent check adds a progress line before it asks docker when docker is on PATH (a NOTE instead when docker is missing, and a NOTE after it when docker is unreachable)"

**Location:** `docs/working/plan-copy-install-bare-host.md:253`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 8.
**Legibility-target:** a plan reader tallying output changes.

The same D result as Claim 8 (`reachable progress=2 NOTE=0`, `unreachable progress=2 NOTE=2`, `absent progress=0 NOTE=2`). This fixes pass-3 Claim 20.

**Evidence:** `devcontainer-config/install.sh:1096-1111`. `q058p4-fc/probe-p4.log` (D).

---

## Claim 13: "links_in returned its last find's status, so a missing PAYLOAD item after the devcontainer copy ended the run through set -e before dc_unwind. An altered cc-isolated.sh stayed live behind the cc-isolated link, with no ERROR line." / "the hash check that follows catches it as a mismatch, which unwinds (T85)"

**Location:** commit f5e3029 body
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T85's shape (the last item missing at `$DEST`) on both revisions. The "missing item" wording is scoped to the devcontainer site here, so Claim 4b does not apply to it.
**Legibility-target:** a reviewer confirming that P3-A1's failure was real and is gone.

`t85-shape-old.log`:

```
== 516124d: rc=1 ERROR-lines=0 blessed=0 launcher-tampered-live=1 bin-link-resolves=yes
== f5e3029: rc=1 ERROR-lines=1 blessed=0 launcher-tampered-live=0 bin-link-resolves=no
```

**Evidence:** `devcontainer-config/install.sh:556-572,656-663`. `q058p4-fc/t85-shape-old.log`: `bash t85-shape-old.sh /workspace`, cwd `q058p4-fc`, exit 0, 2026-09-25T09:08:50Z.

---

## Claim 14a: "every caller turns that into the existing symlink refusal, with its message" — stage, host, and `$DEST` with an unreadable empty directory

**Location:** commit f5e3029 body; `devcontainer-config/install.sh:495-504,565-569,842-852`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers B1 (stage), B3 (host), and B2b and P9b (`$DEST`, an empty mode-000 directory). It does not cover `$DEST` with an unreadable directory that has contents (14b).
**Legibility-target:** a reviewer checking that the fix closes P3-A1's "no ERROR line".

Each prints its refusal. B1: "ERROR: symlinks appeared in the staged devcontainer config after its link check: / (the symlink check could not read every item) / install.sh never installs a link. Nothing was installed." B3: "ERROR: symlinks appeared in the copies to install after the payload's link check:". P9b re-run: "ERROR: symlinks landed in …, which install.sh never installs: / (the symlink check could not read every item) / The copied items were removed again …", with `cc-isolated.sh left in DEST: no … blessed: 0`.

**Evidence:** `q058p4-fc/probe-p4.log` (B1, B2b, B3). `q058p4-fc/probe-p4b-new.log` (B1′). `q058p4-fc/probe-p3b-rerun.log` (P9b).

---

## Claim 14b: "every caller turns that into the existing symlink refusal, with its message" — `$DEST` with an unreadable directory that has contents

**Location:** commit f5e3029 body; `devcontainer-config/install.sh:435-446` (`dc_unwind`)
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a mode-000, non-empty directory at a `$DEST` PAYLOAD item after the copy. It does not show a live launcher: `cc-isolated.sh` comes before both PAYLOAD directories (`PAYLOAD=(… cc-isolated.sh link-claude-home.sh egress claude-home)`, `:99`), so it is removed before the failing `rm`.
**Legibility-target:** a reviewer who reads "with its message" as "the user is always told the config was removed and must be reinstalled".

`dc_unwind` is entered (Claim 5), but its first action runs under errexit and fails on the same unreadable tree that made `find` fail:

```bash
# devcontainer-config/install.sh:435-437 (excerpt ends :437; dc_unwind continues to :446 — read)
dc_unwind() {
  local item
  for item in "${PAYLOAD[@]}"; do rm -rf "${DEST:?}/$item"; done
```

B2a (`$DEST/egress` made mode 000 after its copy, with `cc-isolated.sh` tampered as it lands): `rc=1`, `ERROR line printed: 0`, `'removed again' printed: 0`. The only output is `find: '…/egress': Permission denied` and `rm: cannot remove '…/egress': Permission denied`. `DEST items left: claude-home egress projects`, `cc-isolated.sh: absent`, `blessed: 0`, and the `cc-isolated` link does not resolve. So the fail-closed result holds, but the message does not. The user sees two tool errors and a half-removed config, with no ERROR line saying that cc-isolated will not run until install.sh completes. That is P3-A1's "no ERROR line" symptom in a narrower shape. An unreadable directory with nothing in it (B2b) is removed, and the message prints.

**Evidence:** `devcontainer-config/install.sh:99,435-446,565-569`. `q058p4-fc/probe-p4.log` (B2a, B2b), cwd `q058p4-fc`, exit 0, 2026-09-25T09:04:44Z.

---

## Claim 15: "Tests: T84 and T85 fail on 516124d and pass here."

**Location:** commit f5e3029 body; `test/install-host.bats:1436-1466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers f5e3029's T84 and T85 run against 516124d's and f5e3029's trees. It does not make T84's `[ ! -e "$S/hook-ran" ]` leg meaningful: git 2.39.5 never runs a config-based hook, so that assertion holds on any code here. Only the refusal legs (`status 1`, `hook.pwn.command` listed, no bless) discriminate.
**Legibility-target:** a reviewer relying on T84 and T85 as regression guards.

```
== install.sh from 516124d, tests from f5e3029
not ok 1 T84 … #   `[ "$status" -eq 1 ]' failed
not ok 2 T85 … #   `[[ "$output" == *'ERROR:'*'removed again'* ]]' failed
== install.sh from f5e3029, tests from f5e3029
ok 1 T84 …
ok 2 T85 …
```

**Evidence:** `test/install-host.bats:1436-1466`. `q058p4-fc/t84-t85-old.log`: `bash t84-t85-old.sh /workspace <scratch>`, cwd `q058p4-fc`, exit 0, 2026-09-25T09:07:00Z.

---

## Claim 16: "Both installer suites pass 177/177. shellcheck is clean."

**Location:** commit f5e3029 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `bats test/install-host.bats test/cc-isolated-functions.bats` at f5e3029, and shellcheck at the project's gate severity (`-S warning`, as `scripts/health-check.sh:448` runs it). At default severity, install.sh has 21 info and style findings (SC2317 and SC2016), the same number as at 516124d.
**Legibility-target:** the orchestrator gating the merge on green tests.

`bats.log`: `ok 1` … `ok 177`, no `not ok`, `exit=0` (2026-09-25T09:03:36Z–09:05:34Z, cwd `/workspace/.claude/wt-q058p2`, HEAD f5e3029). `shellcheck -S warning devcontainer-config/install.sh`: exit 0. `shellcheck -s bash -S warning test/install-host.bats`: exit 0.

**Evidence:** `q058p4-fc/bats.log`. `q058p4-fc/shellcheck-wc.log` (2026-09-25T09:07:12Z and 09:07:22Z). `scripts/health-check.sh:448`.

---

## Claim 17: "The remaining doc sentences the pass-3 fact-check rated Mostly accurate are corrected: the docker progress-line and NOTE wording, the TMPDIR claim …, and README's remedy description."

**Location:** commit f5e3029 body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers pass-3 Claims 1, 11b, 14 and 20, the four it rated Mostly accurate. The old fa25f13 commit body (part of 11b) cannot be edited and is not counted. Pass 3's Unverifiable Claim 8 (LFS) is not claimed as fixed.
**Legibility-target:** the rubric's P3-A4 row.

Each corrected sentence is verified above: README (Claim 1), install.sh:789 and 037:67 (Claim 6), 037:33 (Claim 8), plan:253 (Claim 12).

**Evidence:** `docs/reviews/code-fact-check-report-q058-pass3-516124d.md:531-545`. Claims 1, 6, 8 and 12.

---

## Claims Requiring Attention

### Incorrect
- **Claim 4b** (`devcontainer-config/install.sh:653`): at the stage and host sites, a missing item is not caught by "the hash check that follows", because the hash is taken from the tree with the item missing. The stage copy failure, the host swap's `mv`/rollback, or set -e catch it instead. An item that reappears before the hash is accepted, links included (M1, M2). The comment should name the `$DEST` site only, or say what catches it at each site.
- **Claim 14b** (commit f5e3029; `devcontainer-config/install.sh:437`): at `$DEST`, when an unreadable directory has contents, `dc_unwind`'s own `rm -rf` fails under set -e. The run exits 1 with only find's and rm's errors, no ERROR line, and `egress`/`claude-home` left behind. No bless happens and the launcher is gone.

### Stale
- **Claim 11** (`docs/working/plan-copy-install-bare-host.md:250`): install.sh is now 1203 lines, not 1193.

### Mostly Accurate
- **Claim 7** (`devcontainer-config/install.sh:795-796`): an unreadable `.cw-new.*` copy (or devcontainer stage) survives cleanup. Every later host run then stops at `:827` with only an `rm` error.

### Unverifiable
- **Claim 9** (037:80; commit): git ≥ 2.54 config-based hooks, and whether `core.hooksPath=/dev/null` disables them. Needs a host with git ≥ 2.54 (P3-A2's revisit trigger).
- **Claim 10b** (037:80): "equivalent persistence through any other file in `$HOME`". Needs the bare host's sandbox write policy (P3-A3's `you: terminal` check).

---

## Goal-Alignment Note

The goal is to merge the copy-install work to main once review passes. This is the pass-4 confirmation of f5e3029. The commit does what it set out to do:

- **P3-A1 fixed as reported.** T85's shape now unwinds with its message, and the tampered launcher is gone (Claim 13, run on both revisions). Pass 3's own P9b probe now ends in the `dc_unwind` message.
- **P3-A2 fixed.** `hook.*` is refused in every case form git accepts, because `--get-regexp` matches canonical names (Claim 3).
- **P3-A4 fixed.** All four Mostly-accurate sentences are corrected (Claim 17).
- **P3-A3 residual stated accurately.** It is executed here (Claim 10a).
- **Test claims hold.** 177/177, and T84 and T85 fail on 516124d.

The two Incorrect verdicts are a code comment and one clause of the commit message. Neither lets an unreviewed file stay live in any executed shape. Four findings are for the critics and the user:

1. **`dc_unwind` can die on the tree that triggered it** (Claim 14b). This is the new fail-closed path's message gap: a writer in `~/.config/claude-devcontainer` that leaves an unreadable directory with contents gets a silent partial unwind. PAYLOAD order keeps the launcher out of reach (it is removed first), so this is a message defect, not a live-launcher regression. The writer is already one that 037 treats as able to re-bless.
2. **A host item missing at `links_in` and back before the hash is installed as it came back** (Claim 4b, M1 and M2). M2 (a link inside a directory item) already worked on 516124d. **M1 is new with f5e3029.** A `.cw-new.manifest` swapped for a symlink in that window is installed as a symlink, and the post-swap provenance append (`install.sh:1012-1015`) writes through it to the link's target. Before, the last item's `find` failure stopped the run. Both need a writer inside `$dest` during a microseconds-wide window, which is 037's C8 residual ("a writer that can write the destination can change the installed files directly"). So this is a residual that got wider, not a new trust-boundary break. The critics should decide whether the manifest (the one file item) deserves a `[ -L ]` check right before its hash.
3. **A leftover unreadable `.cw-new.*` blocks every later host run with only an `rm` error** (Claim 7, B3b). It needs the same writer as item 2. It is a usability problem, not a safety one.
4. **T84's "never run" assertion is vacuous on git 2.39.5** (Claim 15). The refusal legs carry the test. P3-A2's revisit trigger (a host with git ≥ 2.54) remains the only way to learn whether the refusal is needed.

Nit, not verdicted: 037:80's test citation for the local-key refusal, "(T65, T66, T75, T76)", does not add T84.
