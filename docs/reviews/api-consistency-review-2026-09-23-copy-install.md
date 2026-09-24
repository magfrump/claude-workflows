Commit: d0fdd04

# API Consistency Review — `ans/copy-install` (install.sh host `~/.claude` target)

**Scope:** `712c626..d0fdd04`. The consumer surfaces reviewed are install.sh's CLI (flags, exit status, prompts, target order, messages), its env vars, the `.claude-workflows-manifest` keys, the backup layout, and the README and guide instructions.
**Date:** 2026-09-23
**Based on:** `docs/reviews/code-fact-check-report.md` (k=3 merged): Claims Requiring Attention, replicate annotations, and Escalations E1–E10.
**Execution:** a hermetic probe (`$scratchpad/api-rev/run.sh`) ran against a throwaway fake repo with HOME, TMPDIR, `CLAUDE_DEVC_*` and `CLAUDE_HOME_DIR` all under the scratchpad, `CLAUDE_CONFIG_DIR` unset, and `env -u CLAUDECODE script -qec` for the pty. The real `~/.claude` was never touched.

## Baseline Conventions

These are the conventions install.sh's consumers already rely on. Paths are repo-relative at d0fdd04.

- **Env overrides for install.sh's own destinations** use the `CLAUDE_DEVC_` prefix: `CLAUDE_DEVC_CONFIG_DIR` and `CLAUDE_DEVC_BIN_DIR` (`devcontainer-config/install.sh:64-65`). The launcher's payload override is `CC_WORKFLOWS_DIR` (`link-claude-home.sh:35`).
- **The `~/.claude` location** is spelled `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` by every other consumer: `link-claude-home.sh:36`, `scripts/health-check.sh:542,575,585`, and the `{{CLAUDE_DIR}}` substitution in `hooks/wiring.json`. This matches Claude Code's own variable.
- **Unknown-flag handling in sibling scripts** is mixed. The nearest sibling, `devcontainer-config/cc-isolated.sh:563`, prints `ERROR: unknown flag: $1`, then usage to stderr, and exits **1**. `scripts/confine-tests.sh:66-68` prints `confine-tests: unknown flag:` and exits **2**. `-h|--help` → usage and exit 0 is uniform (`cc-isolated.sh:561`, `scripts/run-tests.sh:31`, `scripts/confine-tests.sh:58`).
- **install.sh's own messages** start errors with `ERROR:` and pair them with a "nothing was installed/changed" line (`install.sh:116-118`, `:149-151`). A decline was `Aborted. Nothing was changed.` followed by exit 1 (`git show 712c626:devcontainer-config/install.sh`).
- **Old exit contract (712c626):** 0 means installed, and 1 means declined or error. `ASSUME_YES="${1:-}"` took only the first argument and silently ignored any other value.
- **Manifest format** (`install.sh:123-127`, copied as-is by `link-claude-home.sh:70-71`): `key=value` lines with lower_snake keys: `commit=`, `dirty=`, `assembled_from=`.
- **Host dotfile naming** under `~/.claude`: `.claude-workflows-<noun>` (`.claude-workflows-manifest`). Temp files take a `.link-tmp.$$` suffix (`link-claude-home.sh:132`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `-h`, `--help` | CLI flag | `--help\|-h` in cc-isolated, run-tests, confine-tests | `devcontainer-config/cc-isolated.sh:561`, `scripts/run-tests.sh:31`, `scripts/confine-tests.sh:58` | Consistent |
| unknown argument → `install.sh: unknown argument: X`, exit 2 | CLI error | `ERROR: unknown flag:` exit 1; `confine-tests: unknown flag:` exit 2 | `devcontainer-config/cc-isolated.sh:563`; `scripts/confine-tests.sh:66-68` | Inconsistent with the same-directory sibling and with install.sh's own `ERROR:` prefix (F5) |
| `--yes` (existing name, narrowed meaning) | CLI flag | old `--yes` = answer y to the only prompt | `git show 712c626:devcontainer-config/install.sh` (`ASSUME_YES="${1:-}"`) | Meaning narrowed to "y for target 1, skip target 2" (F2) |
| `CLAUDE_HOME_DIR` | env var | `CLAUDE_DEVC_CONFIG_DIR`, `CLAUDE_DEVC_BIN_DIR`, `CLAUDE_CONFIG_DIR` | `devcontainer-config/install.sh:64-65`; `devcontainer-config/link-claude-home.sh:36`; `scripts/health-check.sh:542` | Inconsistent: an install-only override that outranks the shared variable (F3) |
| `installed_by`, `installed_parent`, `installed_at` | manifest keys | `commit`, `dirty`, `assembled_from` | `devcontainer-config/install.sh:123-127` | Key shape consistent (lower_snake, additive). `installed_by`'s value overclaims (F6) |
| `.claude-workflows-backup/<stamp>[.<pid>]/` | host dir layout | `.claude-workflows-manifest` | `devcontainer-config/link-claude-home.sh:71` | Consistent prefix. `.<pid>` fallback undocumented (F6) |
| `.cw-new.<name>` | host temp entry (named in an error message) | `.claude-workflows-manifest`, `settings.json.link-tmp.$$` | `devcontainer-config/link-claude-home.sh:71,132` | Inconsistent abbreviation (F8, Informational) |
| `cw-host-stage.XXXXXX` | temp dir in `$TMPDIR` | none of its kind | none (searched `devcontainer-config/`, `scripts/` for `mktemp` templates) | New. Internal and cleaned by the EXIT trap. No finding |
| `REPLACE symlink …`, `MOVE to backup …`, `WIRED in settings`, `REMINDER:` | review-output vocabulary (README-documented) | `ERROR:`, `WARNING:`, `(none — …)` | `devcontainer-config/install.sh:116,181,231` | Uppercase-tag style consistent. `REPLACE` is printed for entries that aren't replaced (F4) |
| `Skipped host target (~/.claude): …`, `Aborted. Nothing was changed. (<target>)` | status lines | `Aborted. Nothing was changed.` | `git show 712c626:devcontainer-config/install.sh` | Suffix style fine. Hard-coded `~/.claude` label (F7) |
| `install_devcontainer`, `install_claude_home`, `host_refuse`, `resolve_phys`, `inside_repo` | shell functions | `assemble`, `review_diff`, `confirm` | `devcontainer-config/install.sh:97,133,160` | Internal (not sourced by anyone; grepped `test/`, `scripts/`). Consistent verb_noun. No finding |

## Findings

#### F4. `REPLACE symlink … with a copy` is printed for per-file links that are only moved, and the README makes that line the migration contract

**Severity:** Inconsistent
**Location:** `devcontainer-config/install.sh:349-353`; `README.md:26-28`
**Move:** 3 (consumer contract), 7 (asymmetry between the review line and the action)
**Confidence:** High (fact-check Claim 16, merged Incorrect, executed by r3)
**Legibility-target:** for-author

Precedent: uppercase action tags naming what the install does (`WARNING:`/`ERROR:`/`(none — …)`) used in `devcontainer-config/install.sh:116,181,231`

**Evidence:**
```
    elif [ -d "$dest/$name" ]; then
      while IFS= read -r -d '' link; do
        echo "REPLACE symlink $link -> $(readlink "$link") with a copy"
        changed=1
      done < <(find "$dest/$name" -type l -print0 | sort -z)
```
```
run `install.sh`. Its `~/.claude` review lists every symlink it will replace
(`REPLACE symlink … with a copy`) and every file in those directories that the repo
doesn't have (`MOVE to backup`). Check any line marked `WIRED in settings` before you
```

The README tells the migrating user to read two tags: `REPLACE` for "gets a copy" and `MOVE to backup` for "disappears from the live tree". A per-file symlink whose path the stage lacks goes through the first loop, prints `REPLACE … with a copy`, and gets no copy. It is also caught by the second loop (`-type l`), so the same path prints two contradictory lines. For a hooks link, the `WIRED` marker lands only on the `MOVE` line, so a user scanning `REPLACE` lines as benign can skip the one line that says a wired hook will stop running. The vocabulary exists to show what the copy diff can't, so the pre-pass has to be the more exact of the two outputs.

**Recommendation:** print `REPLACE symlink` only when `$stage/$name/$rel` exists. Otherwise let the link fall through to the `MOVE to backup` line alone. Add a T-case with a foreign per-file link.

#### F3. `CLAUDE_HOME_DIR` is an install-only override that outranks `CLAUDE_CONFIG_DIR`, which every other consumer of `~/.claude` uses

**Severity:** Inconsistent
**Location:** `devcontainer-config/install.sh:35-36`, `:281-284`; `README.md:19`
**Move:** 2 (naming), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Precedent: install.sh's own destination overrides use the `CLAUDE_DEVC_` prefix, in `devcontainer-config/install.sh:64-65`. The `~/.claude` location is spelled `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` in `devcontainer-config/link-claude-home.sh:36` and `scripts/health-check.sh:542`

**Evidence:**
```
  if [ -n "${CLAUDE_HOME_DIR:-}" ]; then dest="$CLAUDE_HOME_DIR"; label='$CLAUDE_HOME_DIR'
  elif [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then dest="$CLAUDE_CONFIG_DIR"; label='$CLAUDE_CONFIG_DIR'
  else dest="$HOME/.claude"; label='the default, ~/.claude'
```
```
    local settings="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
```
```
`~/.claude` (or `$CLAUDE_CONFIG_DIR` if you set it). They are **copies, not
```

The branch adds a third name for "where Claude Code's config lives", and gives it priority over the shared one. A host with `CLAUDE_HOME_DIR` set (a stray export from running the tests by hand, or a user who picks the name up from `--help`) installs to a directory that Claude Code, `health-check.sh`'s wiring check and the guide's `{{CLAUDE_DIR}}` substitution never read. The only visible sign is the `(chosen by $CLAUDE_HOME_DIR)` label. The name also sits in Claude Code's own `CLAUDE_*` namespace without the `CLAUDE_DEVC_` prefix that marks install.sh's private knobs. The README documents `CLAUDE_CONFIG_DIR` only (fact-check r1 annotation on Claim 1), so the README and `--help` disagree on the contract. The only consumer is `test/install-host.bats:26`, which also unsets `CLAUDE_CONFIG_DIR` (`:31`). T24 already shows that `CLAUDE_CONFIG_DIR` alone pins the destination, so the extra variable adds nothing to hermeticity.

**Recommendation:** drop `CLAUDE_HOME_DIR` and have the tests export `CLAUDE_CONFIG_DIR="$HOME/.claude"`, leaving one name for one location. If a distinct install-only override is really wanted, name it `CLAUDE_DEVC_HOME_DIR`, rank it below `CLAUDE_CONFIG_DIR` or refuse when the two disagree, and document it in the README.

#### F10. Failures after the first live move break the target's own error contract ("ERROR: … nothing was replaced") and don't name the backup dir

**Severity:** Inconsistent
**Location:** `devcontainer-config/install.sh:423-437`
**Move:** 4 (error consistency)
**Confidence:** High for the message gap (read). The state residue is the fact-check's E2/E7, executed by r2
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    for name in "${CLAUDE_HOME_NAMES[@]}"; do
      if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
        mv "$dest/$name" "$backup/$name"
      fi
    done
  fi

  # 3. Swap the new copies in.
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
      echo "ERROR: $dest/$name reappeared during the install; the new copy is left at $dest/.cw-new.$name." >&2
      exit 1
    fi
    mv "$dest/.cw-new.$name" "$dest/$name"
  done
```
(Enclosing `install_claude_home` continues to `:459`. The lines after `:437` write the manifest and print the success message. They add no recovery path.)

Every earlier failure branch in the host target ends with a message that tells the consumer what state they're in: `Nothing was installed into the host target.` (`:275`), or `could not copy …; nothing was replaced.` (`:404`, `:420`). The steps that actually change the live tree have none. A failing `mv` at `:425` or `:436` dies under `set -e` with only `mv`'s own stderr. The one custom message (`:433`) names `.cw-new.<name>` but not `$backup`, which by then holds the entries already moved out. The README's promise that "Everything replaced … is moved to `…/.claude-workflows-backup/<UTC stamp>/`" is the user's only recovery map, and the error doesn't say which stamp. That matters most because the stamp can carry a `.<pid>` suffix (`:417`).

**Recommendation:** trap failures in steps 2–3 and print a closing message in the same `ERROR:` style: which entries are live, which are in `$backup` (full path), which are still at `.cw-new.*`, and the command that restores them (`mv "$backup"/* "$dest"/`). The fix for the underlying residue is the security and robustness critics' call. This finding covers only the message contract.

#### F1. Under the README's own recommended flow, a successful host-only install always exits 1

**Severity:** Minor (the plan accepted this as a risk: "no caller depends on it". Worth a conscious re-check now that the README tells host-only users to decline)
**Location:** `devcontainer-config/install.sh:190-198`, `:461-464`, `:48-49`; `README.md:15-17`
**Move:** 3 (consumer contract), 6 (semantics change)
**Confidence:** High (executed: probe A, `n\ny` → `Installed into …` then `RC=1`)
**Legibility-target:** for-author

**Evidence:**
```
      echo "Aborted. Nothing was changed. (devcontainer config)"
      DECLINED=1
      return 0
```
```
DECLINED=0
install_devcontainer
install_claude_home
exit "$DECLINED"
```
```
own `[y/N]`. The first is the `cc-isolated` devcontainer config: decline it if you
don't use the devcontainer. The second copies `global-instructions/CLAUDE.md`,
```

At 712c626, exit 1 meant "this run changed nothing", because a decline ended the run. Now it means "at least one target was declined", and the README tells every user without the devcontainer to decline target 1 on every run. So every correct bare-host install exits 1, exactly like an error (`--help`: "1 a target was declined, or an error"). A wrapper such as `./devcontainer-config/install.sh && echo updated`, or a future `health-check` or SessionStart hook reading the status, can't tell "installed ~/.claude, skipped the devcontainer by choice" from "the copy failed". The plan's risk note is right that no caller exists today. Decision 037's revisit trigger H (a staleness warning) would be the first.

**Recommendation:** either exit 0 when every target the user accepted succeeded (a decline is a choice, not a failure), or give "declined, nothing failed" its own code (e.g. 3) and keep 1 for errors. Update `usage()`. At minimum, have the README say that a host-only run exits 1.

#### F2. `--yes` narrowed from "answer every prompt" to "y for target 1, skip target 2", and the run still exits 0

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:45`, `:293-295`
**Move:** 3 (subtle semantic change), 6
**Confidence:** High (executed: probe B, `--yes` → RC=0, host untouched)
**Legibility-target:** for-author

**Evidence:**
```
  --yes       answer y for target 1 without asking (target 2 is skipped)
```
```
  if [ "$ASSUME_YES" = "--yes" ]; then
    echo "Skipped host target (~/.claude): it never installs with --yes. Run install.sh without --yes at a terminal to review and install it."
    return 0
```

The skip is deliberate (Q-056 [1]) and the help text is honest. The API point is narrower. A flag named `--yes` conventionally means "assume y everywhere", and the old script had exactly one prompt, so existing muscle memory (`install.sh --yes` after a pull) now leaves `~/.claude` stale with a success status and one stdout line. That is the failure 037's own revisit trigger names ("~/.claude going stale again"). The skip line goes to stdout and blends into the devcontainer's `Next steps:` block above it.

**Recommendation:** keep the behavior. Send the skip line to stderr with a `WARNING:` prefix, matching `:231`'s PATH warning, so it survives `>/dev/null` and reads as a caveat, not a status. Consider noting in the usage line that `--yes` covers the devcontainer only (`[--yes]` → `[--yes (devcontainer only)]`).

#### F5. Unknown-argument handling diverges from the same-directory sibling, and `-y` or trailing arguments now fail

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:53-61`
**Move:** 2 (naming/message shape), 3 (subtle breaking change), 4 (error consistency)
**Confidence:** High (executed: probe C, `-y` → RC=2, `--yes extra` → RC=2; at 712c626 both ran, `-y` as a plain prompt run and `--yes extra` as `--yes`)
**Legibility-target:** for-author

Precedent: `ERROR: unknown flag: $1` + usage to stderr + `exit 1` used in `devcontainer-config/cc-isolated.sh:563`; the `ERROR:` prefix for every install.sh failure used in `devcontainer-config/install.sh:116,149,274`

**Evidence:**
```
    *) echo "install.sh: unknown argument: $1" >&2; usage >&2; exit 2 ;;
```
```
      -*)           echo "ERROR: unknown flag: $1" >&2; usage >&2; exit 1 ;;
```

Exit 2 has one repo precedent (`scripts/confine-tests.sh:68`) and is a defensible, documented choice. The message prefix, though, is the only install.sh error without `ERROR:`, and the launcher it installs (`cc-isolated.sh`) exits 1 for the same condition, so the two scripts a user runs side by side disagree. Commit 1514518 says exit 2 "is the only observable change". The fact-check (Claim 8, Mostly accurate) found `-h/--help` and `--yes extra` → 2 as further changes. No in-repo caller passes arguments (grepped `test/`, `scripts/`, `hooks/`, `*.md`), so nothing inside the repo breaks.

**Recommendation:** use `ERROR: unknown argument: $1` for the message. Keep exit 2, since it's documented in `usage()` and the architecture review asked for it. Note the stricter parsing in the commit trail or the 037 Consequences so a user with `-y` aliased knows why it now fails.

#### F6. Manifest: `installed_by=host-tty` records a property the code doesn't establish, and `installed_at` doesn't always name the backup dir

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:411`, `:416-417`, `:443-447`
**Move:** 8 (field contract), 7 (join asymmetry)
**Confidence:** High (executed: probe A under `script` from an agent session wrote `installed_by=host-tty`, `installed_parent=bash`)
**Legibility-target:** for-orchestrator-synthesis

Precedent: `key=value` lower_snake provenance keys (`commit=`, `dirty=`, `assembled_from=`) used in `devcontainer-config/install.sh:123-127`

**Evidence:**
```
  {
    echo "installed_by=host-tty"
    echo "installed_parent=$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d ' ' || echo unknown)"
    echo "installed_at=$stamp"
  } >> "$dest/.claude-workflows-manifest"
```
```
    backup="$bkroot/$stamp"
    if [ -e "$backup" ]; then backup="$backup.$$"; fi
```

The keys are additive and shaped like the existing three, so link-claude-home's producer and any future reader stay compatible (architecture review #5 is honored). The values are the problem. `installed_by` is a constant, and it asserts "a tty on the host", which a pty wrapper gives any process (fact-check Claim 2, Incorrect). `installed_parent` reads `bash`/`sh`, not `script`, under a compound command (fact-check Claim 22, Incorrect, E4). Decision 037's revisit trigger ("backup stamp with no human at the terminal") joins the manifest to a backup dir by stamp, but `installed_at` drops the `.<pid>` suffix when the stamp dir already exists, so the join fails in exactly the collision case. The README describes the layout as `<UTC stamp>/` only.

**Recommendation:** make the values describe what was checked: `stdin_tty=yes`, `claudecode_set=no`, `installed_parent=<comm>`. Add `backup=<full path or none>` so the manifest names its own backup dir instead of making a reader reconstruct it. Mention the possible `.<pid>` suffix wherever the layout is documented.

#### F9. README and `--help` state the TTY rule as an absolute that the code comment and decision 037 disclaim

**Severity:** Minor
**Location:** `README.md:21-22`; `devcontainer-config/install.sh:42-43` vs `:290-292`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check Claim 2, Incorrect, Escalation E1; not re-verified here)
**Legibility-target:** for-author

**Evidence:**
```
target only installs for a human at a terminal. It is skipped with `--yes`, from a
```
```
Claude Code session (CLAUDECODE set). It only installs for a human at a
terminal who read the diff.
```
```
  # Neither check stops an agent that sets out to fake a terminal (`script`
  # gives it a pty; `env -u` drops CLAUDECODE). They stop the accidental run and
```

Two consumer-facing surfaces promise what the implementation's own comment says it doesn't deliver. The architecture review asked for the contract to live in one place (`usage()`) with the README pointing at it. The two now agree with each other but not with the code. A reader who trusts "only for a human" won't add the sandbox `denyWrite ~/.claude` backstop that 037 relies on.

**Recommendation:** reword both to what the code does: "skipped with --yes, without a TTY, or with CLAUDECODE set; this stops accidental runs, not a process that fakes a terminal — see bare-host-hook-wiring §3 for the denyWrite backstop."

#### F7. Host-target status lines hard-code `~/.claude` even when the destination is elsewhere

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:294`, `:298`, `:302`, `:387`
**Move:** 4 (message consistency), 7 (asymmetry with the `Destination:` line)
**Confidence:** High (executed: probe D/E with `CLAUDE_HOME_DIR=$S/other` printed `Skipped host target (~/.claude)` and `Aborted. Nothing was changed. (host ~/.claude)` after `Destination: …/other`)
**Legibility-target:** for-author

**Evidence:**
```
    echo "Skipped host target (~/.claude): it never installs with --yes. Run install.sh without --yes at a terminal to review and install it."
```
```
    echo "Aborted. Nothing was changed. (host ~/.claude)"
```

The skip lines print before `dest` is shown (`:307`), so a user with `CLAUDE_CONFIG_DIR` set is told `~/.claude` was skipped. Nothing in the skipped run's output ever shows the directory that was actually left stale. `dest` is already resolved at `:281-284`, before the skip checks run.

**Recommendation:** interpolate `$dest` in all four lines (e.g. `Skipped host target ($dest): …`), matching the `Destination:` and `Install these files into $dest?` lines.

#### F8. `.cw-new.<name>` breaks the `.claude-workflows-*` naming for host dotfiles, and it is user-visible

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:328-329`, `:398-399`, `:433`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `.claude-workflows-manifest` used in `devcontainer-config/link-claude-home.sh:71` and `devcontainer-config/install.sh:441`; `.claude-workflows-backup/` used in `devcontainer-config/install.sh:319`

**Evidence:**
```
      echo "ERROR: $dest/$name reappeared during the install; the new copy is left at $dest/.cw-new.$name." >&2
```

Every other dotfile the installer owns in `~/.claude` is `.claude-workflows-<noun>`, which tells a user browsing the directory who put it there. `.cw-new.skills` is left behind after a failure and named in an error and a refusal (`:329`), and it doesn't say whose it is.

**Recommendation:** optional. Rename to `.claude-workflows-new.<name>`. The guard at `:327-331` and the cleanup loops change in lockstep.

#### F11. The two targets present themselves asymmetrically

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:174-176` vs `:306-307`, `:336`
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
  echo "Canonical (repo):  $SRC"
  echo "Installed (host):  $DEST"
```
```
  echo "=== Host target: global Claude Code files ======================================"
  echo "Destination: $dest  (chosen by $label)"
```

Target 2 gets a banner and a `Destination:` line naming the variable that chose it. Target 1 keeps its old unbannered `Installed (host):` pair, although `CLAUDE_DEVC_CONFIG_DIR` can redirect it the same way. With two prompts per run, a uniform `=== <target> ===` header with `Destination: … (chosen by …)` on both would let a user answer each y/N knowing which target it belongs to. This is a nicety, and changing target 1's first lines would move 037's "non-interactive output unchanged" line a little further.

**Recommendation:** optional. Add a `=== Devcontainer target ===` banner above `:174`, or leave target 1 as is for output stability and note the choice.

## What Looks Good

- **`-h/--help` and the `usage()` contract.** Both follow the repo-wide `-h|--help` → usage, exit 0 idiom. The help states the target order, the skip rules and exit codes 0/1/2 in one place, as architecture review #4 asked.
- **Additive manifest.** The host target writes link-claude-home's three keys unchanged and appends new lower_snake keys, so a single reader handles both producers. The `rm -f` before `cp` keeps the filename contract without following a planted link.
- **Destination precedence reported, not implied.** `(chosen by $label)` makes the env-var contract observable on every interactive run.
- **Review-diff reuse.** The host target calls the same `review_diff` and `confirm` helpers as the devcontainer target, so abort-on-diff-trouble (exit >1) and EOF-reads-as-no are identical across both. For a human, the prompt semantics are the same at both gates.
- **Decline-line wording** keeps `Aborted. Nothing was changed.` as a prefix, so the existing `cc-isolated-functions.bats:640` substring match still holds.
- **Backup naming** reuses the `.claude-workflows-` prefix, and the README table documents both the manifest and the backup location.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F4 | `REPLACE symlink … with a copy` printed for links that are only moved; README makes it the migration contract | Inconsistent | `install.sh:349-353`; `README.md:26-28` | High |
| F3 | `CLAUDE_HOME_DIR` install-only override outranks the shared `CLAUDE_CONFIG_DIR`; undocumented in README | Inconsistent | `install.sh:281-284`; `README.md:19` | High |
| F10 | Step 2–3 failures break the target's `ERROR: … nothing was replaced` contract and don't name the backup dir | Inconsistent | `install.sh:423-437` | High |
| F1 | Host-only install (README's recommended flow) always exits 1 | Minor | `install.sh:190-198,461-464`; `README.md:15-17` | High |
| F2 | `--yes` narrowed to target 1; skip is stdout-only with exit 0 | Minor | `install.sh:45,293-295` | High |
| F5 | Unknown-arg message lacks `ERROR:` and diverges from `cc-isolated.sh` (exit 1); `-y`/trailing args now fail | Minor | `install.sh:53-61` | High |
| F6 | `installed_by=host-tty` overclaims; `installed_at` ≠ backup dir name on collision | Minor | `install.sh:416-417,443-447` | High |
| F9 | README and `--help` state the TTY rule as absolute | Minor | `README.md:21-22`; `install.sh:42-43` | High |
| F7 | Skip/abort lines hard-code `~/.claude` | Minor | `install.sh:294,298,302,387` | High |
| F8 | `.cw-new.<name>` vs `.claude-workflows-*` | Informational | `install.sh:328-329,398-399,433` | Medium |
| F11 | Target 1 and target 2 headers asymmetric | Informational | `install.sh:174-176,306-307` | Medium |

Counts: Breaking 0 · Inconsistent 3 · Minor 6 · Informational 2.

## Overall Assessment

The new host target is mostly consistent with the surfaces around it. It reuses the devcontainer target's diff and prompt helpers, extends the manifest additively, follows the repo's `--help` idiom, and names its backup dir in the existing `.claude-workflows-*` family. No existing consumer breaks. No in-repo caller passes arguments or reads the exit status. The one changed status line keeps its old prefix. The problems sit where a *new* consumer contract was written without checking the neighbors. A third name for the `~/.claude` location outranks the one every other tool reads (F3). The review vocabulary the README hands migrating users mislabels moved-only links as `REPLACE` (F4). The failure paths that actually touch the live tree drop the "here is your state" message every earlier branch gives (F10). All three can be fixed in place: dropping one env var, one conditional, and a trap message. F4 and F10 matter most before plan step 9, because the user's first host run is a symlink migration, where the review lines and a mid-swap error message are the only guidance. The Minor items are about keeping the exit status, `--yes`, the manifest values and the docs honest about what the code does.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: d0fdd04` line.
- Answered: yes
- Out of scope: whether the step-2/3 residue itself (not its message) and concurrent-run collisions are acceptable (security/robustness critics; fact-check E2/E7); macOS/BSD `script` portability (E8); the sandbox `denyWrite` backstop (Claim 27)
- Escalate: F3 (`CLAUDE_HOME_DIR` outranking `CLAUDE_CONFIG_DIR`) and F4 (`REPLACE` mislabel) should be settled before the user's plan-step-9 host run, since both affect what that first migration review shows and where it writes
