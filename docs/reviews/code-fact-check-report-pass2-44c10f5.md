Commit: 44c10f5

# Code Fact-Check Report

**Commit:** 44c10f5
**Replication:** k=1 (confirmation pass after fixes)
**Repository:** claude-workflows, worktree `/workspace/.claude/wt-copyinstall`, branch `ans/copy-install`
**Scope:** `712c626..44c10f5`, focused on the 12 fix commits `f84336d..44c10f5`: `devcontainer-config/install.sh` (all 656 lines read), `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `docs/working/plan-copy-install-bare-host.md` (44c10f5's update), `scripts/claude_config_audit.py`, the fix-commit messages, and `test/install-host.bats`, `test/cc-isolated-functions.bats`, `test/hooks/claude-config-audit.bats`
**Checked:** 2026-09-23 (execution timestamps are UTC, 2026-09-24T01:08Z–01:14Z)
**Total claims checked:** 29
**Summary:** 13 verified, 10 mostly accurate, 2 stale, 4 incorrect, 0 unverifiable

Execution provenance. `$CFC` = `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/cfc-final`. Every probe is a script under `$CFC/`, sourced through `$CFC/lib.sh`. That harness pins HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR, TMPDIR and GIT_CONFIG_GLOBAL under `$CFC/run/<probe>/`, unsets CLAUDECODE and CLAUDE_CONFIG_DIR, and runs a copy of the 44c10f5 `install.sh` inside a throwaway git repo whose payload is committed. The y path runs under `script -qec … /dev/null`. No real `~/.claude`, `~/.config` or `~/.local` was touched. Probes were run with `bash $CFC/<probe>.sh`, cwd `/workspace`, and each script exited 0. Raw output is in `$CFC/logs/`. The logs are in the session scratchpad and are not committed. Out-of-scope environment noise: `setlocale: LC_ALL` warnings, filtered from the logs.

The hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read first. No claim in scope matches a logged pattern. No claim below is a fabrication, so no entry was appended.

---

## Claim 1: "Only **committed** content is installed: uncommitted changes under those paths are listed as NOT included, and git-ignored files are never copied."

**Location:** `README.md:23-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the seven claude-home paths ("those paths" = the list at `README.md:17-18`) for both targets' assembled payload. It does not establish the devcontainer target's other PAYLOAD items (see Claim 4). It also does not establish that the staged bytes always equal the commit's blobs (see Claim 7).

`assemble` builds the payload from the archive, not the tree:

```bash
# devcontainer-config/install.sh:133-134
  if ! git -C "$REPO_ROOT" archive --format=tar "$commit" -- "${CLAUDE_HOME_SRC[@]}" \
       | tar -xf - -C "$stage/.extract"; then
```

It lists the dirty paths with `git status --porcelain --untracked-files=all -- "${CLAUDE_HOME_SRC[@]}"` (`install.sh:156`). Executed evidence comes from two runs. First, the suite run: T25 and T26 passed, and so did cc-isolated-functions' "stages committed content only" test. Second, probe D left an uncommitted `skills/a/SKILL.md` edit listed under `NOT included` and absent from the staged payload (`installed claude-home skill: skill a`). Its manifest records `uncommitted_excluded=1`.

**Evidence:** `devcontainer-config/install.sh:107-172`; `test/install-host.bats:430-449`; `$CFC/logs/install-host.log` (`bats test/install-host.bats`, cwd `/workspace/.claude/wt-copyinstall`, exit 0, 2026-09-24T01:08:16Z); `$CFC/logs/pD.log` (2026-09-24T01:11:36Z)

---

## Claim 2: "That stops accidental runs, not a determined agent (a pty wrapper gets past it)"

**Location:** `README.md:25-27`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the skip rules' bypassability. It does not establish that a pty wrapper *alone* is enough from inside a Claude Code session.

Inside a session, `CLAUDECODE` is set, and the skip at `install.sh:386-389` fires whatever the TTY:

```bash
# devcontainer-config/install.sh:386-389
  if [ -n "${CLAUDECODE:-}" ]; then
    echo "Skipped host target (~/.claude): running inside a Claude Code session (CLAUDECODE is set). Run install.sh from your own terminal."
    return 0
  fi
```

Every y-path test and probe in this pass needed both `env -u CLAUDECODE` and `script -qec` (`test/install-host.bats` `run_pty`). `--help` states it precisely: "a pty wrapper and `env -u CLAUDECODE` get past it" (`install.sh:49`). The more precise README wording is "(a pty wrapper and unsetting `CLAUDECODE` get past it)". The conclusion ("not a determined agent") is correct.

**Evidence:** `README.md:25-27`; `devcontainer-config/install.sh:49,386-393`; `test/install-host.bats:109-113`; `$CFC/logs/install-host.log`

---

## Claim 3: "copy this repo's blessed-by-review files ... each after its own review diff and its own y/N" / "Those edits are inert until a human runs this script and approves the diff"

**Location:** `devcontainer-config/install.sh:2-3,14-15`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what the host review shows for entries the destination already has (a diff) and for entries it lacks (names only). It does not establish anything about the devcontainer target, which still diffs new items in full.

Since the A7 fix (5f62713), an entry absent from the destination is listed, not diffed:

```bash
# devcontainer-config/install.sh:481-487
    if [ ! -e "$dest/$name" ]; then
      n="$(find "$stage/$name" -type f | grep -c '' || true)"
      echo "ADD $dest/$name (new, $n file(s)):" | vis
      (cd "$stage" && find "$name" -type f | LC_ALL=C sort) | sed 's/^/    /' | vis
      changed=1
      continue
    fi
```

In probe B, the destination held only `CLAUDE.md`. The review showed a content diff for `CLAUDE.md` and only file names for the six other entries, e.g. `ADD …/.claude/hooks (new, 3 file(s)):` followed by `hooks/h.sh`, `hooks/lib/x.sh`, `hooks/wiring.json`. The human answering y never sees the content of any hook in a new entry. The more precise header wording is "a review (a diff for existing entries; a file list for new ones)". This is the trade-off A7 chose, and it is stated at `install.sh:472-473`. The file header and README `:21-22` ("read the diff") still describe a full content review.

**Evidence:** `devcontainer-config/install.sh:2-3,14-15,472-487`; `README.md:21-22`; `$CFC/logs/pB.log` (2026-09-24T01:11:01Z)

---

## Claim 4: "Both targets install COMMITTED content: uncommitted changes under the payload paths are listed as NOT included."

**Location:** `devcontainer-config/install.sh:43-44`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers target 1's non-assembled PAYLOAD items (`devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh link-claude-home.sh egress`). The claude-home part of both targets is Claim 1.

Target 1 copies its other PAYLOAD items from the working tree:

```bash
# devcontainer-config/install.sh:253-256
  for item in "${PAYLOAD[@]}"; do
    rm -rf "${DEST:?}/$item"
    cp -r "$SRC/$item" "$DEST/$item"
  done
```

The dirty check covers only `CLAUDE_HOME_SRC` (`install.sh:156`). Probe D left `devcontainer-config/devcontainer.json` modified and uncommitted (`git status`: ` M devcontainer-config/devcontainer.json`) and ran `install.sh --yes`. The WARNING listed only `M skills/a/SKILL.md`. The installed `devcontainer.json` ended with `UNCOMMITTED-EDIT`. So target 1 installs uncommitted boundary files (firewall, launcher, egress) and does not list them. A reader of `--help` who relies on "commit to include" is misled. Commit 9e7db08's Notes and plan `:147` state the limit correctly: "The devcontainer target's other PAYLOAD items ... still come from the working tree". `--help` does not. The README, `:23-24`, is correct because it scopes to "those paths".

**Evidence:** `devcontainer-config/install.sh:43-44,66,156,253-256`; `$CFC/logs/pD.log` (`bash $CFC/pD_dctarget.sh`, cwd `/workspace`, exit 0, 2026-09-24T01:11:36Z)

---

## Claim 5: "That stops accidental runs, not a determined agent: a pty wrapper and `env -u CLAUDECODE` get past it. The hard barrier is a sandbox that denies agents write access to ~/.claude."

**Location:** `devcontainer-config/install.sh:46-50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the bypass by pty plus `env -u CLAUDECODE` (executed: every y-path test). It does not establish the sandbox barrier's own effectiveness, which is host config outside this repo.

The three skips are `--yes`, `CLAUDECODE` and `[ ! -t 0 ]` (`install.sh:382-393`). All 40 install-host tests, which install via `env -u CLAUDECODE script -qec`, passed. This closes rubric A1.

**Evidence:** `devcontainer-config/install.sh:382-393`; `test/install-host.bats:109-113,267-280`; `$CFC/logs/install-host.log`

---

## Claim 6: "vis: filter that makes control bytes visible (all but newline and tab)"

**Location:** `devcontainer-config/install.sh:92-93`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every single byte 0x01–0xff (except 0x0a) through `vis`. It does not establish how a given terminal renders raw 8-bit bytes.

```bash
# devcontainer-config/install.sh:94-97
vis() {
  LC_ALL=C sed -e 's/\x1b/^[/g' -e 's/\r/^M/g' \
    -e 's/[\x01-\x08\x0b\x0c\x0e-\x1a\x1c-\x1f\x7f]/?/g' -e 's/\xc2[\x80-\x9f]/?/g'
}
```

Probe E fed each byte through `vis`. Every C0 control and DEL came out visible, and so did the UTF-8-encoded C1 range (`c2 9b` → `?`). The raw single-byte C1 controls 0x80–0x9f passed unchanged (`RAW-PASS 0x80` … `RAW-PASS 0x9f`). Commit 355b135 says exactly what the code does ("C1 controls encoded as UTF-8"). The comment's "all but newline and tab" overstates it. In a UTF-8 terminal, raw 0x80–0x9f are invalid sequences, and most terminals do not act on them, so the practical conclusion is mostly right. The precise comment would be "C0 controls, DEL and UTF-8-encoded C1; raw 8-bit bytes pass".

**Evidence:** `devcontainer-config/install.sh:92-97`; `$CFC/logs/pE.log` (`bash $CFC/pE_vis.sh`, cwd `/workspace`, exit 0, 2026-09-24T01:11:50Z)

---

## Claim 7: "the payload is `git archive HEAD`" / "dirty=no always: the payload is exactly the commit's content."

**Location:** `devcontainer-config/install.sh:103-106,165`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers detached HEAD, shallow clone, submodule, and `export-ignore`/`export-subst` attributes (brief item 1). It does not establish behavior under `$GIT_DIR/info/attributes`, which follows from the same mechanism but was not run separately.

Detached HEAD and shallow clones behave as claimed. Probe G1 staged the detached commit (`commit=4055caa…` = `git rev-parse HEAD`). G2 succeeded in a `--depth 1` clone (`is-shallow-repository: true`, `dirty=no`). Two cases break "exactly the commit's content", with `dirty=no` still written:

- **Attributes.** `git archive` applies `export-ignore` and `export-subst`. In G4, a committed `.gitattributes` with `skills/a/SKILL.md export-ignore` staged `skills/a` empty. `hooks/h.sh export-subst` staged `# b4808db0…` where the commit holds `# $Format:%H$`. `$GIT_DIR/info/attributes` feeds the same mechanism, but it is uncommitted and appears in no `git status` listing (paraphrased — no quote available because this is git-archive behavior, not install.sh code).
- **Submodules.** In G3, a submodule at `skills/subm` staged as an empty directory, with no warning.

The current repo's `.gitattributes` has only `* text=auto eol=lf`, so today's payload is unaffected. The review diff shows the staged bytes, so a removed or rewritten file would still appear as a diff line. The residue is the manifest's `dirty=no` and the "exactly the commit" wording. A precise wording would be "the commit's content as `git archive` exports it".

**Evidence:** `devcontainer-config/install.sh:111,133-141,163-171`; `.gitattributes:1-2`; `$CFC/logs/pG.log` (`bash $CFC/pG_git.sh`, cwd `/workspace`, exit 0, 2026-09-24T01:12:29Z)

---

## Claim 8: "No symlinks (review R1). git archive keeps committed links ... a link to an agent-writable file would review as "(none)" and install as a live link."

**Location:** `devcontainer-config/install.sh:142-152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers symlinks anywhere in the staged payload, refused before either prompt, for both targets (assemble runs first in each). It does not establish refusal of symlinks among target 1's non-assembled items, which were outside R1.

```bash
# devcontainer-config/install.sh:146-152
  links="$(cd "$stage" && find . -type l | sed 's|^\./||' | LC_ALL=C sort)"
  if [ -n "$links" ]; then
    echo "ERROR: the committed payload contains symlinks, which install.sh never installs:" >&2
    printf '%s\n' "$links" | sed 's/^/         /' | vis >&2
    echo "       Replace them with real files and commit. Nothing was installed." >&2
    exit 1
  fi
```

T27 passed at 44c10f5 and failed at d0fdd04 (probe J). R1 is closed.

**Evidence:** `devcontainer-config/install.sh:142-152`; `test/install-host.bats:451-463`; `$CFC/logs/install-host.log`; `$CFC/logs/pJ-oldcode.log`

---

## Claim 9: "Porcelain paths are repo-relative and C-quoted, so control bytes cannot reach the terminal from here."

**Location:** `devcontainer-config/install.sh:153-154`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the WARNING listing under default and `core.quotePath=false` git config. It does not establish how a given terminal acts on U+009B.

The listing is printed without `vis`:

```bash
# devcontainer-config/install.sh:161
    printf '%s\n' "$dirty" | sed 's/^/           /'
```

With default config, git C-quotes a name containing U+009B (`"skills/evil\302\233…"`). With `core.quotePath=false`, a common setting for non-ASCII names, git emits the raw bytes. In probe E, `install.sh --yes` then printed `skills/evil 302 233 31mred.md` raw on stdout. `vis` itself treats that exact sequence (`\xc2[\x80-\x9f]`) as a control to neutralise. C0 controls stay quoted either way. The precise comment would be "C-quoted (under default core.quotePath)". Piping the listing through `vis`, as the symlink listing at `:149` already is, would make the comment true in general.

**Evidence:** `devcontainer-config/install.sh:153-162`; `$CFC/logs/pE.log` (2026-09-24T01:11:50Z)

---

## Claim 10: "vis (A4): a raw \r or CSI sequence in a file could hide `+` lines."

**Location:** `devcontainer-config/install.sh:188-190`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `review_diff`'s stdout and stderr for both targets, and `diff`'s exit status under the pipe. It does not cover the raw 8-bit residue (Claim 6) or the unfiltered dirty listing (Claim 9).

```bash
# devcontainer-config/install.sh:189-190
    rc=0
    diff -ruN "$dest/$item" "$src/$item" 2>&1 | vis || rc=${PIPESTATUS[0]}
```

`PIPESTATUS[0]` keeps diff's status, so the `0`/`1`/`*` dispatch at `:191-197` is unchanged. T34 passed at 44c10f5 and failed at d0fdd04. A4 is closed.

**Evidence:** `devcontainer-config/install.sh:177-200`; `test/install-host.bats:559-566`; `$CFC/logs/install-host.log`; `$CFC/logs/pJ-oldcode.log`

---

## Claim 11a: "`..` drops the last component. So <outside>/nx/../<repo> with nx missing resolves to <repo> (review A3)."

**Location:** `devcontainer-config/install.sh:291-294`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers newline-free paths with `..` in a missing tail and physical resolution of existing dirs. The newline case is Claim 11b.

```bash
# devcontainer-config/install.sh:299-306
  for comp in "${parts[@]}"; do
    case "$comp" in
      ''|.) ;;
      ..) cur="$(dirname "$cur")" ;;
      *) if [ -d "${cur%/}/$comp" ]; then cur="$(cd "${cur%/}/$comp" && pwd -P)"
         else cur="${cur%/}/$comp"; fi ;;
    esac
  done
```

T39 passed and failed on d0fdd04. A3 is closed for the stated form.

**Evidence:** `devcontainer-config/install.sh:295-308`; `test/install-host.bats:621-640`; `$CFC/logs/install-host.log`; `$CFC/logs/pJ-oldcode.log`

---

## Claim 11b: "resolve_phys <path>: where <path> lands once mkdir -p creates it."

**Location:** `devcontainer-config/install.sh:291`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers a destination path containing a newline. It does not establish any exploit beyond the one executed, which was stopped by an unrelated mechanism.

The split reads only the first line:

```bash
# devcontainer-config/install.sh:298
  IFS=/ read -ra parts <<< "$p"
```

Probe C set `CLAUDE_HOME_DIR="$S/out/nl"$'\n'"/../../repo"`. Once `mkdir -p` creates `nl<LF>`, that path lands in the checkout `$S/repo`. `resolve_phys` returned `…/out/nl`, the `inside_repo` guard (`:405`) did not fire, and the run reached the y prompt with the checkout as destination. After y, the lock dir and the `.cw-new.*` copies were created inside the checkout. The run was stopped only because `sha256sum` prefixes `\` to hashes of paths containing a newline. That made `payload_hash` differ, and the run printed the misleading "stage changed after review" and removed the copies (verified: `sha256sum` output `\73cb…` vs `73cb…`). The checkout ended with `git status` clean. The same crafted-path class as A3 remains open for the guard. The only thing that stops it is an accident of R2.

**Evidence:** `devcontainer-config/install.sh:295-315,405-407,321-328`; `$CFC/logs/pC.log` (`bash $CFC/pC_newline.sh`, cwd `/workspace`, exit 0, 2026-09-24T01:11:13Z)

---

## Claim 12: "payload_hash <dir> <prefix>: one hash over the listing (path, type, mode, link target) and the file contents"

**Location:** `devcontainer-config/install.sh:317-320`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every file's bytes and every entry's path, type, mode and link target under the seven names. It does not cover `$stage/.manifest` (Claim 14), and it breaks on paths containing a newline (Claim 11b).

```bash
# devcontainer-config/install.sh:323-327
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    echo "== $name"
    find "$dir/$pfx$name" -printf '%P\t%y\t%m\t%l\n' | LC_ALL=C sort
    find "$dir/$pfx$name" -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum | cut -d' ' -f1
  done | sha256sum | cut -d' ' -f1
```

Probe H2 changed only a file's mode in the stage at the prompt. The run printed "stage changed after review", and the installed mode stayed `644`. T28 covers a content change.

**Evidence:** `devcontainer-config/install.sh:321-328,549-554`; `$CFC/logs/pH.log` (`bash $CFC/pH_hash.sh`, cwd `/workspace`, exit 0, 2026-09-24T01:13:02Z)

---

## Claim 13: "every non-interactive run (scripts, tests, --yes) is unchanged apart from a blank line and the skip line" / decision 037: "every existing non-interactive devcontainer run is unchanged apart from two extra lines"

**Location:** `devcontainer-config/install.sh:376-378`, `docs/decisions/037-bare-host-copy-install.md:33,52`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the host target's contribution (the blank line and the skip line). It does not establish that a non-interactive run is otherwise unchanged. Other fixes on this branch changed target 1 as well.

The host target adds exactly `echo` (`:375`) and one skip line (`:382-393`), which closes A9's wording. The run as a whole also changed through C1 and A4, which the sentence's "every … run is unchanged" does not allow for. With a dirty checkout, `assemble` prints a new four-or-more-line WARNING block on target 1 (probe D, lines 1–4). The claude-home staged for target 1 is now the commit, not the tree. Diff errors now reach stdout through `vis` (commit 355b135 Notes). The precise wording would be "the host target adds two lines; see C1 for target 1's changes".

**Evidence:** `devcontainer-config/install.sh:156-162,190,375-393`; `docs/decisions/037-bare-host-copy-install.md:33,52`; `$CFC/logs/pD.log`

---

## Claim 14: "Hash it before the review; after the y, the copies made under $dest must hash the same." / commit ec2427f: "verify the host copies match the reviewed stage"

**Location:** `devcontainer-config/install.sh:428-431`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what R2's check protects (the seven entries) and what it leaves open (the provenance manifest, and the interval between hashing and display). It does not establish the reachability of `$TMPDIR` for a sandboxed agent, which R2 already left open.

The payload check works: T28 passed and failed on d0fdd04, and probe H2 caught a mode change. Two gaps remain against "match the reviewed stage":

- **The manifest is outside the hash.** It is copied after the swap:

  ```bash
  # devcontainer-config/install.sh:593-594
    rm -f "$dest/.claude-workflows-manifest"
    cp "$stage/.manifest" "$dest/.claude-workflows-manifest"
  ```

  Probe H1 rewrote `commit=` in the stage at the prompt. The install succeeded and wrote `commit=FORGED` into the destination manifest. Health-check and sessions use that stamp to tell which commit's process they run (`:163-164`).
- **The hash is taken before the review is printed.** It is computed at `:431`, and the review reads the stage at `:440-499`. So what is verified is "the stage as hashed just before the review". A same-uid write that lands between `:431` and the diff would make what the human sees differ from what is installed (paraphrased — no quote available because this is an ordering inferred across `:431-499`; not raced in a probe).

Plan `:244` says the TOCTOU is "Closed for the host target". That is true for the seven entries, with the two residues above.

**Evidence:** `devcontainer-config/install.sh:163-171,425-432,440-499,549-554,591-600`; `docs/working/plan-copy-install-bare-host.md:244`; `$CFC/logs/pH.log`

---

## Claim 15: "Match the full hooks/<path>, so hooks/sub/x.sh is not "wired" by hooks/x.sh."

**Location:** `devcontainer-config/install.sh:463-466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stated case, and a foreign link now labelled MOVE with WIRED on the same line (R5). It does not establish freedom from false positives. `grep -F` is a substring match, so `hooks/x.sh` counts as wired by a settings string `hooks/x.sh.bak`, which errs toward warning.

```bash
# devcontainer-config/install.sh:458-466
        if [ -L "$f" ]; then
          line="MOVE link $f -> $(readlink "$f") to backup (not in the repo)"
        else
          line="MOVE to backup (not in the repo): $f"
        fi
        # Match the full hooks/<path>, so hooks/sub/x.sh is not "wired" by hooks/x.sh.
        if [ "$name" = hooks ] && grep -qsF "hooks/$rel" "$dest/settings.json" "$dest/settings.local.json"; then
```

REPLACE is printed only when `[ -e "$stage/$name/$rel" ]` (`:447`). T33 passed and failed on d0fdd04. R5 is closed.

**Evidence:** `devcontainer-config/install.sh:436-471`; `test/install-host.bats:541-557`; `$CFC/logs/install-host.log`; `$CFC/logs/pJ-oldcode.log`

---

## Claim 16: "An entry the destination lacks is listed, not diffed ... An existing entry is diffed as a link-free copy ... so a dangling link cannot abort the review (A8)."

**Location:** `devcontainer-config/install.sh:472-477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the ADD listing and dangling inner links. It does not establish that new entries' content is reviewed; they are not (Claim 3).

```bash
# devcontainer-config/install.sh:488-494
    if ! cp -RH "$dest/$name" "$view/$name"; then
      echo "ERROR: could not read $dest/$name for the review. Nothing was installed." >&2
      exit 1
    fi
    find "$view/$name" -type l -delete
    chmod -R u+w "$view/$name"   # cp keeps a read-only dir's mode; cleanup must remove it
    diffnames+=("$name")
```

T35 and T36 passed and failed on d0fdd04. Probe B shows the ADD format. A7 and A8 are closed.

**Evidence:** `devcontainer-config/install.sh:478-499`; `test/install-host.bats:568-591`; `$CFC/logs/pB.log`; `$CFC/logs/pJ-oldcode.log`

---

## Claim 17: "(none — the destination already matches the repo)" / "A6: nothing to do means no prompt, no swap and no 2.4 MB backup."

**Location:** `devcontainer-config/install.sh:500-509`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers a committed change to file mode only. It does not establish other content-invisible differences beyond the empty-directory case noted below.

`changed` comes from the pre-pass, ADD and `diff -ruN`. `diff` compares content only, and the view is a `cp -RH` copy:

```bash
# devcontainer-config/install.sh:500-509
  if [ "$changed" -eq 0 ]; then
    echo "(none — the destination already matches the repo)"
  fi
  echo "==============================================================================="
  echo
  # A6: nothing to do means no prompt, no swap and no 2.4 MB backup.
  if [ "$changed" -eq 0 ]; then
    echo "Nothing to install into $dest."
    return 0
  fi
```

Probe A installed `hooks/h.sh` committed as 644, then committed `chmod 755` (`hooks/h.sh | 0`) and reran. The review printed "(none — the destination already matches the repo)" and "Nothing to install". The installed file stayed `-rw-r--r--`. Before A6, a y reinstalled the tree and carried the new mode. Now a committed mode fix (e.g. making a hook executable) never reaches `~/.claude`, and the review claims the destination matches. A destination-only empty directory is likewise invisible (paraphrased — no quote available because this follows from `find -type f -o -type l` at `:469` plus `diff -N` on an empty dir; not separately run).

**Evidence:** `devcontainer-config/install.sh:436-509`; `$CFC/logs/pA.log` (`bash $CFC/pA_mode.sh`, cwd `/workspace`, exit 0, 2026-09-24T01:10:49Z)

---

## Claim 18: "One install at a time (R4) ... The lock is released by main's EXIT trap on every path."

**Location:** `devcontainer-config/install.sh:522-534`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers success, error exits, a held lock, and SIGINT. It does not cover SIGKILL or a power loss, where no trap can run. For those, the pre-review check and `lock_msg` ("…or one was killed. If no install.sh is running, remove that directory and rerun.") are the stated recovery.

```bash
# devcontainer-config/install.sh:342-345
host_cleanup() {
  if [ -n "$HOST_TMP" ]; then rm -rf "$HOST_TMP" || true; fi
  if [ -n "$HOST_LOCK" ]; then rmdir "$HOST_LOCK" 2>/dev/null || true; fi
}
```

T31 (held lock refused) and T32 (released after success) passed. Probe F sent SIGINT to the process group during step 1 after y. Afterwards the lock dir was gone and `$TMPDIR` was empty, so bash ran the EXIT trap on SIGINT. A rerun was not refused. Note that T32 also passed on d0fdd04, which had no lock (Claim 25).

**Evidence:** `devcontainer-config/install.sh:336-345,421-423,522-534,648`; `test/install-host.bats:522-539`; `$CFC/logs/pF.log` (`bash $CFC/pF_sigint.sh`, cwd `/workspace`, exit 0, 2026-09-24T01:12:10Z)

---

## Claim 19: "1. Copy every entry beside its target. Any failure: undo and stop before a single live entry is touched."

**Location:** `devcontainer-config/install.sh:536-537`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers a `cp` failure (undo runs) and an interrupt (live entries untouched, no undo). It does not establish the effect of leftover `.cw-new.*` directories on the auditor or on Claude Code.

The undo runs only on `cp` failure (`:544-548`). An interrupt is not undone. In probe F, SIGINT during step 1 left `.cw-new.CLAUDE.md`, `.cw-new.guides`, `.cw-new.hooks`, `.cw-new.patterns`, `.cw-new.skills` and `.cw-new.workflows` in the destination, beside the untouched live `CLAUDE.md`. `host_cleanup` does not remove them, and a declined rerun does not either: removal happens only after a y (`:540`). The "no live entry touched" half holds. A precise comment would add "(an interrupt leaves `.cw-new.*`, removed by the next accepted run)".

**Evidence:** `devcontainer-config/install.sh:536-548,342-345`; `$CFC/logs/pF.log`

---

## Claim 20: "Steps 2-3 are one transaction (R4): any failure runs host_rollback" / host_rollback: "undo a partial swap ... Then report and exit 1."

**Location:** `devcontainer-config/install.sh:556-559`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a move-aside failure (T30) and a swap-in failure (probe I: this is the path commit 60f122a said had no test). It does not establish a partial cross-filesystem `mv` (backup root on another mount), which was not run. The "reappeared" branch reports the reappeared name under "is missing", which is inexact but still exits 1.

```bash
# devcontainer-config/install.sh:351-354
  for n in "${swapped[@]}"; do rm -rf "${dest:?}/$n"; done
  for n in "${moved[@]}"; do
    if [ -e "$dest/$n" ] || [ -L "$dest/$n" ] || ! mv "$backup/$n" "$dest/$n"; then left+=("$n"); fi
  done
```

Probe I used the README's old symlink layout. A `PATH` shim made `mv .cw-new.scripts …` fail on the last swap-in. The run printed "…was rolled back: every entry was moved back from …/20260924T011314Z", exited 1, and left the destination byte- and listing-identical to before (`DEST RESTORED EXACTLY`). No backup dir, lock or `.cw-new.*` remained. Signals are ignored for the span (`:574`, `trap '' INT TERM HUP`) and restored at `:589`. R4 is closed.

**Evidence:** `devcontainer-config/install.sh:347-366,556-589`; `test/install-host.bats:504-520`; `$CFC/logs/pI.log` (`bash $CFC/pI_rollback.sh`, cwd `/workspace`, exit 0, 2026-09-24T01:13:15Z)

---

## Claim 21: "installed_parent is best-effort: under a pty wrapper it names whatever shell the wrapper ran (bash, sh)"

**Location:** `devcontainer-config/install.sh:595-596`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers `script -qec "$INSTALL"` with `SHELL=/bin/bash`. It does not establish every wrapper form.

Under the tests' own form, the value names the wrapper, not a shell. Probe B's manifest reads `installed_parent=script`: bash `-c` with a single command execs it, so the parent is `script`. The earlier fact-check observed `bash`/`sh` under `script -qec "bash -c …"`. So the value can be the wrapper or a shell. The conclusion ("a hint, not evidence of a human") holds, and `installed_by=host-tty` is gone (`grep` finds no `installed_by`). A2 is closed. The precise wording would be "names the wrapper or the shell it ran".

**Evidence:** `devcontainer-config/install.sh:595-600`; `$CFC/run/pB/home/.claude/.claude-workflows-manifest`; `$CFC/logs/pB.log`

---

## Claim 22: "A6: keep the newest 3 stamped backups" / "Previous entries moved to $backup (delete it when satisfied)." / README and `--help`: "the newest 3 backups are kept"

**Location:** `devcontainer-config/install.sh:603-612`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers a backup root that already holds three or more directories whose names sort after the current UTC stamp (a clock set back, WSL clock drift, or any digit-leading name containing `T` and `Z`). Under a monotonic clock with only install-made backups, the three kept are the three newest.

The kept set is "last 3 by name", and the current run's backup is not exempt:

```bash
# devcontainer-config/install.sh:604-612
    echo "Previous entries moved to $backup (delete it when satisfied)."
    # A6: keep the newest 3 stamped backups; nothing else prunes them.
    local old pruned=0
    while IFS= read -r old; do
      if [ -d "$bkroot/$old" ] && [ ! -L "$bkroot/$old" ]; then
        rm -rf "${bkroot:?}/$old"; pruned=$((pruned + 1))
      fi
    done < <(find "$bkroot" -mindepth 1 -maxdepth 1 -name '[0-9]*T*Z*' -printf '%f\n' | LC_ALL=C sort | head -n -3)
```

Probe B pre-created `20990101T000000Z`…`20990103T000000Z` and a user-owned `CLAUDE.md`, then accepted an install. The output was "Previous entries moved to …/20260924T011101Z (delete it when satisfied)." and "(1 older removed)". Afterwards the backup root held only the three 2099 dirs. `grep` for the user's old `CLAUDE.md` found nothing: the only copy of the replaced entries was deleted in the same run that told the user where it was. The data loss is silent and permanent (this is the Q-057 "user's own files" case). The same claim is made at `README.md:37`, `install.sh:40` and `docs/decisions/037-bare-host-copy-install.md:35`.

**Evidence:** `devcontainer-config/install.sh:560-573,603-613`; `README.md:37`; `$CFC/logs/pB.log` (`bash $CFC/pB_prune.sh`, cwd `/workspace`, exit 0, 2026-09-24T01:11:01Z)

---

## Claim 23: "A function body is parsed whole before it runs, and the last line `main "$@"; exit $?` is one line, so nothing after it is ever read."

**Location:** `devcontainer-config/install.sh:622-626`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers an in-place rewrite of install.sh while a prompt waits. It does not cover executables the script calls from the checkout (`$DEST/cc-isolated.sh --bless` runs the *installed* copy).

Top level holds only `set -euo pipefail` (`:25`), the constants `SRC`, `PAYLOAD`, `REPO_ROOT` and `CLAUDE_HOME_SRC` (`:62,66,68,90`), function definitions, and the one call line:

```bash
# devcontainer-config/install.sh:656
main "$@"; exit $?
```

T29 passed and failed on d0fdd04. R3 is closed.

**Evidence:** `devcontainer-config/install.sh:25,60-68,90,622-656`; `test/install-host.bats:478-502`; `$CFC/logs/install-host.log`; `$CFC/logs/pJ-oldcode.log`

---

## Claim 24: "**`installed_parent=`** ... Under a `script` pty wrapper it reads `script` (seen in the tests), which leaves an audit trace for the agent-bypass case the TTY rule cannot stop."

**Location:** `docs/working/plan-copy-install-bare-host.md:128`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the "audit trace" conclusion. The observed value `script` does match Claim 21's probe.

The A2 fix (3fc9c84) retracted the audit-trace reading. The code now says:

```bash
# devcontainer-config/install.sh:595-596
  # installed_parent is best-effort: under a pty wrapper it names whatever shell
  # the wrapper ran (bash, sh), so it is a hint, not evidence of a human (A2).
```

44c10f5 edited the neighbouring line (`:130`) but left this one.

**Evidence:** `docs/working/plan-copy-install-bare-host.md:128`; `devcontainer-config/install.sh:595-596`

---

## Claim 25: "one commit per fix, each test-first (new test failed before, passes after)."

**Location:** `docs/working/plan-copy-install-bare-host.md:134`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every `@test` in the 44c10f5 `test/install-host.bats`, run against d0fdd04's `install.sh` and README. It does not re-run the cc-isolated-functions or claude-config-audit new tests against old code.

Probe J copied the 44c10f5 test file beside d0fdd04's `install.sh` and README. Every new or updated test failed (T10, T23, T25–T31, T33–T40), except T32 ("a successful install releases its lock"), which passed. The old code had no lock to leave behind. Commit 60f122a did not claim T32 failed before, so only the plan's blanket wording is inexact. T9 also fails on old code; it is not one of the fix tests.

**Evidence:** `docs/working/plan-copy-install-bare-host.md:134`; `test/install-host.bats:533-539`; `$CFC/logs/pJ-oldcode.log` (`bash $CFC/pJ_oldcode.sh`, cwd `/workspace`, exit 0 for the script, bats exit 1, 2026-09-24T01:14:09Z)

---

## Claim 26: "install.sh is 656 lines after the review fixes, over the 500 guideline"

**Location:** `docs/working/plan-copy-install-bare-host.md:236`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line count at 44c10f5. It does not establish the split-deferral reasoning.

`wc -l devcontainer-config/install.sh` → `656` (paraphrased — no quote available because the claim is a file line count, not a snippet).

**Evidence:** `devcontainer-config/install.sh:656`

---

## Claim 27: "Non-interactive runs are unchanged except for one extra skip line."

**Location:** `docs/working/plan-copy-install-bare-host.md:239`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the line count only. The broader "unchanged" residue is Claim 13.

A9's fix changed this to "two extra lines (a blank line and the skip line)" in decision 037 `:33,52` and the comment at `install.sh:377-378`. 44c10f5 edited the Risks list around it but left this line as it was.

**Evidence:** `docs/working/plan-copy-install-bare-host.md:239`; `docs/decisions/037-bare-host-copy-install.md:33`; `devcontainer-config/install.sh:376-378`

---

## Claim 28: Test counts: install-host 40/40, cc-isolated-functions 92/92, link-claude-home-wiring 14/14, hooks 145/145

**Location:** `test/install-host.bats:1`, `test/cc-isolated-functions.bats:1`, `test/link-claude-home-wiring.bats:1`, `test/hooks/claude-config-audit.bats:231`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four suites at 44c10f5 in this sandbox. It does not cover `scripts/run-tests.sh --fast`, which was not run this pass.

`$CFC/tests.sh` ran each suite with `TMPDIR` in the scratchpad and CLAUDECODE/CLAUDE_CONFIG_DIR unset. The results were: `1..40` 40 ok; `1..92` 92 ok; `1..14` 14 ok; `test/hooks/*.bats` (6 files) `1..145` 145 ok. There were 0 `not ok` and 0 skips, and every bats exit was 0. The hooks count is 144 + 1, the new "directory walk skips .claude-workflows-backup" test, which runs the real auditor. That auditor's `SKIP_DIRS` now includes `.claude-workflows-backup` and prunes `dirnames` in `os.walk` (`scripts/claude_config_audit.py:127-130,152`).

**Evidence:** `$CFC/logs/tests.summary`, `$CFC/logs/install-host.log`, `$CFC/logs/cc-isolated-functions.log`, `$CFC/logs/link-claude-home-wiring.log`, `$CFC/logs/hooks.log` (`bash $CFC/tests.sh`, cwd `/workspace/.claude/wt-copyinstall`, 2026-09-24T01:08:16Z–01:09:24Z); `scripts/claude_config_audit.py:127-153`

---

## Rubric row status (for the orchestrator)

**Legibility-target:** for-orchestrator-synthesis

| Row | Status at 44c10f5 | Claims |
|---|---|---|
| C1/C2 | Fixed for the seven claude-home paths. `--help` overstates it for target 1 (Incorrect). Attribute and submodule caveats apply. | 1, 4, 7 |
| R1 | Closed | 8 |
| R2 | Closed for the seven entries. Manifest unhashed (forgeable), hash taken before display | 12, 14 |
| R3 | Closed | 23 |
| R4 | Closed (lock, rollback on move-aside and swap-in, SIGINT). Interrupt in step 1 leaves `.cw-new.*` | 18, 19, 20 |
| R5 | Closed | 15 |
| A1 | Closed in `--help`. README omits `CLAUDECODE` from the bypass | 2, 5 |
| A2 | Closed in code. Plan `:128` stale | 21, 24 |
| A3 | Closed for `..`. A newline in the path still bypasses the guard (stopped only by a hash quirk) | 11a, 11b |
| A4 | Closed for the diff. Raw 8-bit C1 and the dirty listing under `core.quotePath=false` pass | 6, 9, 10 |
| A6 | **New defects**: no-op check misses mode-only changes; the prune can delete the current run's backup | 17, 22 |
| A7/A8 | Closed. New entries are reviewed by name only | 3, 16 |
| A5, A9, A10 | Doc text fixed. Plan `:239` stale; "unchanged" still overstated | 13, 27 |

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`devcontainer-config/install.sh:43-44`): "Both targets install COMMITTED content": target 1 installs its non-assembled PAYLOAD items from the working tree, uncommitted and unlisted. Scope the sentence to the seven claude-home paths, or extend the dirty check and `git archive` to PAYLOAD.
- **Claim 11b** (`devcontainer-config/install.sh:291,298`): `resolve_phys` reads only up to the first newline, so a destination with a newline that climbs back into the checkout passes the guard. Only the R2 hash quirk stops the install, with a misleading message.
- **Claim 17** (`devcontainer-config/install.sh:500-509`): "(none — the destination already matches the repo)" and the no-op skip ignore file modes. A committed chmod never installs.
- **Claim 22** (`devcontainer-config/install.sh:603-612`; README `:37`; help `:40`; 037 `:35`): "newest 3 kept" means "last 3 by name". With three later-named dirs (clock skew), the current run's backup, and the user's replaced files in it, is deleted right after being announced.

### Stale
- **Claim 24** (`docs/working/plan-copy-install-bare-host.md:128`): still calls `installed_parent` an audit trace. A2 retracted that.
- **Claim 27** (`docs/working/plan-copy-install-bare-host.md:239`): "one extra skip line" should be two lines (A9).

### Mostly Accurate
- **Claim 2** (`README.md:25-27`): the bypass inside a session needs `env -u CLAUDECODE` as well as a pty.
- **Claim 3** (`devcontainer-config/install.sh:2-3,14-15`): new host entries are reviewed by file name, not content.
- **Claim 6** (`devcontainer-config/install.sh:92-93`): `vis` passes raw 0x80–0x9f; the comment says "all but newline and tab".
- **Claim 7** (`devcontainer-config/install.sh:103-106,165`): "exactly the commit's content" depends on no `export-ignore`/`export-subst` attributes and no submodules.
- **Claim 9** (`devcontainer-config/install.sh:153-154`): the porcelain listing is raw under `core.quotePath=false`; pipe it through `vis`.
- **Claim 13** (`devcontainer-config/install.sh:376-378`; 037 `:33,52`): non-interactive runs also changed through C1 and A4 on target 1.
- **Claim 14** (`devcontainer-config/install.sh:428-431`): `.manifest` is outside the R2 hash (forged `commit=` installed), and the hash precedes the review display.
- **Claim 19** (`devcontainer-config/install.sh:536-537`): an interrupt during step 1 leaves `.cw-new.*` in the destination.
- **Claim 21** (`devcontainer-config/install.sh:595-596`): `installed_parent` can name the wrapper (`script`), not only a shell.
- **Claim 25** (`docs/working/plan-copy-install-bare-host.md:134`): T32 passes on the pre-fix code.

### Unverifiable
- None.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 44c10f5` line."
- **Answered:** all four brief items. (1) C1, including detached HEAD, shallow clone, submodules and attributes. (2) R1–R5 with execution, including the untested swap-in rollback and SIGINT lock release. (3) A1–A10, with two new defects from the A6 fix (Claims 17, 22) and a residual A3 bypass (11b). (4) Test counts and "failed before" re-run against d0fdd04.
- **Out of scope:** `scripts/run-tests.sh --fast`; rendering of raw C1 bytes on real terminals; the reachability of `$TMPDIR` for a sandboxed agent; macOS/BSD behavior.
- **Escalate:** Claim 22 is a silent data-loss path on the user's first live runs (WSL clock drift is a realistic trigger). Claim 17 means a committed hook `chmod +x` never installs. Both were introduced by the A6 fix and should be weighed before plan step 9.
