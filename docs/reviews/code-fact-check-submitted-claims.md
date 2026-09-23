Commit: d0fdd04

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-copyinstall`, branch `ans/copy-install`)
**Scope:** Submitted-claims intake only (Stage 2.5): six critic endorsements about `devcontainer-config/install.sh` at d0fdd04. No claims were harvested from the diff.
**Checked:** 2026-09-23
**Total claims checked:** 6
**Summary:** 4 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Every run was hermetic. Each probe built a throwaway git repo holding a copy of the d0fdd04 `install.sh` plus stub or real payload sources, and set `HOME`, `CLAUDE_HOME_DIR`, `CLAUDE_DEVC_CONFIG_DIR`, `CLAUDE_DEVC_BIN_DIR` and `TMPDIR` under `scratchpad/sub-copy/w/`, with `CLAUDE_CONFIG_DIR` unset. `CLAUDECODE` was unset for the child. The pty came from `script -qec … /dev/null`. `cc-isolated.sh` was an echo stub. The probe scripts are `lib.sh`, `p38_41.sh`, `p39.sh`, `p40.sh`, `p42_43.sh` and `p43only.sh` in `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/sub-copy/`. The real `~/.claude` was never touched. I read `install_claude_home()` whole (`:279-459`), along with `assemble` (`:97-128`), `review_diff` (`:133-155`) and the top-level driver (`:461-464`).

---

## Submitted Claims

## Claim 38: "With the README's old install (top-level entries and per-file hook links into the checkout), a y moves each old link into `.claude-workflows-backup/<stamp>/` as a link, and no checkout file's bytes or listing change."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/install.sh:408-437`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the README symlink layout reproduced from `test/install-host.bats` `symlink_install`: CLAUDE.md plus five top-level dir links, a per-file `hooks/h.sh` link, and a copied `hooks/guard.py`. The run answered `n` for the devcontainer target and `y` for the host target, on a single local filesystem. It does not cover a checkout reached through a bind mount (the critic's own caveat) or a top-level `hooks` link. The repo snapshot leaves out `devcontainer-config/claude-home/`, the gitignored staging dir that `install_devcontainer` rebuilds on every run (`:172`), even when that target is declined.

Probe `p38_41.sh` printed `REPO UNCHANGED`: the listing (with link targets) and the sha256 of every file under the fake checkout matched before and after. The backup dir `.claude-workflows-backup/20260923T235539Z/` held `CLAUDE.md l`, `guides l`, `patterns l`, `scripts l`, `skills l` and `workflows l`, each still pointing into the repo. It also held `hooks d`, containing `hooks/h.sh l` (still a link) and `hooks/guard.py f`. The live entries were all regular files or directories afterwards, and `hooks/h.sh` was a regular file. The move is a plain `mv` with no trailing slash:

```bash
# devcontainer-config/install.sh:423-427
    for name in "${CLAUDE_HOME_NAMES[@]}"; do
      if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
        mv "$dest/$name" "$backup/$name"
      fi
    done
```

**Evidence:** `devcontainer-config/install.sh:423-427`, `:431-437`; probe output `REPO UNCHANGED` plus the backup listing above.

---

## Claim 39: "The `resolves inside the repo checkout` destination guard refuses a checkout path given as: trailing slash, relative non-existent path, dot segments, and a symlinked ancestor — each run prints the ERROR and exits before staging, leaving the repo unchanged."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/install.sh:255-271`, `:316-318`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** The four named forms were each run with `n\ny` answers in a pty. The claim is true for dot segments that pass only through **existing** directories. It is false for a dot segment that passes through a **non-existent** component.

**Refused as claimed.** All six variants below printed `ERROR: … resolves inside the repo checkout`, exited 1 and left the repo unchanged:
- `$ROOT/`
- `nonexist/sub` with cwd = `$ROOT`
- `$ROOT/skills/../x`
- `$S/outside/../repo`
- `$S/lnk/claude` and `$S/lnk`, where `lnk -> $ROOT`

**Counterexample.** With `CLAUDE_HOME_DIR=$S/nx/../repo`, where `nx` does not exist, the guard passed. The run printed the host `Canonical (repo):` line and asked the y/N question. On `y` it printed `Installed into $S/nx/../repo.`, and the repo snapshot changed. The repo's own `guides/`, `hooks/`, `patterns/` and the other entries were moved into `$ROOT/.claude-workflows-backup/<stamp>/`, and copies were swapped in. `$S/nx/../repo/sub` behaved the same way, writing a full install into `$ROOT/sub/`.

The cause is in `resolve_phys`. It walks up with `basename`/`dirname` until it reaches a directory that exists, then appends the `..`-bearing tail literally. The resulting string starts with `$S/`, not the repo root, so `inside_repo` returns false. Later, `mkdir -p "$dest"` (`:395`) creates `nx`, and the kernel resolves `..` into the checkout:

```bash
# devcontainer-config/install.sh:257-264
resolve_phys() {
  local p="$1" tail=""
  while [ ! -d "$p" ]; do
    tail="/$(basename "$p")$tail"
    p="$(dirname "$p")"
  done
  echo "$(cd "$p" && pwd -P)$tail"
}
```

The trigger needs `CLAUDE_HOME_DIR` or `CLAUDE_CONFIG_DIR` set to a hand-crafted path. The default `~/.claude` is not affected. The review still shows the destination string, but the string does not name the checkout. Possible fixes: reject any `..` segment left in `tail`, or re-run the guard after `mkdir -p "$dest"` on the now-existing path.

**Evidence:** `devcontainer-config/install.sh:257-264`, `:266-271`, `:316-318`, `:395`; `p39.sh` output (`dot-thru-missing`, `dot-thru-missing-sub`: `repo CHANGED`).

---

## Claim 40: "The skip rules run before `mktemp`/`assemble`, so a `--yes`, no-TTY or CLAUDECODE run creates no stage and writes nothing under the host destination."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/install.sh:279-305`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers four modes, each with the host destination either absent or holding the README symlink layout:
- `--yes` under a pty
- piped `n\ny`
- `</dev/null`
- `CLAUDECODE=1` under a pty

This is about the host target only. The devcontainer target's `assemble "$SRC/claude-home"` (`:172`) still runs first and writes the gitignored staging dir inside the checkout, as it did before this branch.

In each probe, `TMPDIR` pointed at a path that does not exist. Any `mktemp` would therefore have failed under `set -e` before the skip line could print. All 8 runs printed the expected `Skipped host target …` line and never printed `=== Host target:`. The destination snapshot was unchanged in all 8, `TMPDIR` was never created, and the exit status matched the devcontainer answer: 0 for `--yes`, 1 where `n` or EOF declined it. The three `return 0`s (`:293-304`) come before the guards (`:310`) and the `mktemp` (`:333`).

**Evidence:** `devcontainer-config/install.sh:293-304`, `:333-335`; `p40.sh` output (8/8 `dest UNCHANGED`, no TMPDIR created).

---

## Claim 41: "A y leaves `settings.json`, `settings.local.json`, `projects/`, `memory/`, `logs/` and `.credentials.json` in the destination byte-identical."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/install.sh:392-447`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a successful `y` from the README symlink layout. Checked: sha256 of the three files, listing and sha256 of every file under `projects/`, `memory/` and `logs/`, plus mode and mtime of the three files. Not covered: runs after a step-2 or step-3 failure (the critic's caveat). Statically, those steps only ever `mv` or `rm -rf` the seven `CLAUDE_HOME_NAMES` and `.cw-new.*`.

Probe `p38_41.sh` printed `HOST STATE UNCHANGED`. The only writes outside the seven names and `.cw-new.*` are the backup dir and the manifest. The manifest write is `rm -f` followed by `cp` and `>>` on `.claude-workflows-manifest` (`:441-447`). `settings*.json` is only read, by `grep -qsF` (`:362`).

**Evidence:** `devcontainer-config/install.sh:362`, `:397-399`, `:423-427`, `:441-447`; probe output `HOST STATE UNCHANGED`.

---

## Claim 42: "The backup is a `mv` into a directory under `$dest`, so on a single-filesystem `~/.claude` it is one rename per entry, not a second full copy; only the staging copy (`cp -R` into `.cw-new.*`) costs payload-size I/O."

**Submitted by:** performance-reviewer
**Location:** `devcontainer-config/install.sh:408-437`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** The rename half was confirmed with inode and device numbers. `strace` is not installed, so syscalls were not traced. The "only" half is checked against the whole `install_claude_home` function, not just `:408-437`.

**Rename: confirmed.** After a first install, a second `y` moved the real `CLAUDE.md`, `skills` and `hooks` into the backup with the same inode and device numbers (e.g. `skills ino=434125 dev=136` before and `backup skills ino=434125 dev=136` after). That is a rename, not a copy.

**"Only the staging copy": overstated.** There are two payload-size copies per host run, not one:
1. `assemble "$stage"` (`:335`) runs `cp -r` on every source from the checkout into `$TMPDIR/cw-host-stage.*`, whatever the answer.
2. `cp -R "$stage/$name" "$dest/.cw-new.$name"` (`:399`) runs on `y`.

`review_diff` also reads both trees in full. Each `y` also leaves a new payload-size backup dir, even with no changes: 5 no-change `y` runs left 5 backup dirs totalling 12M for a 2.1 MB payload. Retained disk grows per install until the user deletes backups, though no copy I/O is spent on them.

**Evidence:** `devcontainer-config/install.sh:333-335`, `:397-399`, `:423-427`; `p42_43.sh` inode output; backup count `5`, `du` `12M`.

---

## Claim 43: "The whole interactive two-target run with no changes costs about 0.27 s wall on a ~108-file payload."

**Submitted by:** performance-reviewer
**Location:** `devcontainer-config/install.sh` (whole script)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** The payload was copied from this worktree's real seven sources: 109 files, 2,140,471 bytes. Timing is on this WSL2 machine, under `script` with piped answers, after a first install so both reviews print `(none …)`. The devcontainer `--bless` is an echo stub; a real `cc-isolated.sh --bless` is not measured. This is one machine, as the claim says.

Wall times (5 runs each):
- `y\ny`: 0.276–0.279 s
- `n\nn`: 0.273–0.277 s, with one outlier at 1.840 s

Both reviews printed `(none …)` in every run. The order of magnitude and the ~0.27 s figure hold.

**Evidence:** `p43only.sh` output (`none-lines=2` on every run).

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 39** (`devcontainer-config/install.sh:257-264`): the inside-checkout guard is bypassed by a `..` segment through a non-existent component (`CLAUDE_HOME_DIR=<outside>/nx/../<repo>`). A `y` then moves the checkout's own entries into a backup inside the checkout. Fix: reject a `..` left in `resolve_phys`'s tail, or re-run the guard after `mkdir -p "$dest"`.
- **Claim 42** (`devcontainer-config/install.sh:335`, `:399`): the backup is a rename, but there are two payload-size copies (`assemble` into `$TMPDIR` plus `.cw-new.*`), and every `y` adds a full-payload backup dir, even with no changes.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: d0fdd04` line.
- Answered: yes. All six submitted claims have verdicts, each from a hermetic execution.
- Out of scope: freshly harvested claims from the diff (intake was limited to submitted claims); bind-mounted checkouts; a real `cc-isolated --bless`.
- Escalate: Claim 39's guard bypass. It is minor, since it needs a hand-crafted `CLAUDE_HOME_DIR`, but a `y` can then rewrite the checkout.
