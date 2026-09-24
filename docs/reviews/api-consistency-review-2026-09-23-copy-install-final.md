Commit: 9ae6e46

# API Consistency Review — `ans/copy-install`, final confirmation pass (install.sh)

**Scope:** `712c626..9ae6e46`, focused on the fix commits `f84336d..9ae6e46`. Surfaces: install.sh's CLI and exit statuses, env vars, the review output's line labels (REPLACE / MOVE / ADD / MODE / WIRED / WARNING), the manifest and `.install-stamp` keys, the backup, lock and stage names under the destination, and the README, guide and `--help` text.
**Date:** 2026-09-23
**Based on:** my prior report `docs/reviews/api-consistency-review-2026-09-23-copy-install.md` (F1–F11, at d0fdd04) and the pass-2 fact-check `docs/reviews/code-fact-check-report-pass2-44c10f5.md`. I don't re-verify behaviour that report settled (claims 1, 7, 12, 14, 17, 18, 20, 22).
**Execution:** hermetic probe `scratchpad/api-final3/probe.sh`. It sets HOME, TMPDIR, `CLAUDE_HOME_DIR`, `CLAUDE_DEVC_CONFIG_DIR` and `CLAUDE_DEVC_BIN_DIR` under `scratchpad/api-final3/run/`, unsets `CLAUDE_CONFIG_DIR` and `CLAUDECODE`, and uses a throwaway git repo with the payload committed. The pty comes from `script -qec`. The real `~/.claude`, `~/.config` and `~/.local` were never touched. install.sh was read whole (808 lines).

## Prior findings: status at 9ae6e46

| # | Prior finding | Status | Evidence (9ae6e46) |
|---|---|---|---|
| F4 | `REPLACE symlink` printed for links that are only moved | **Resolved.** A per-file link prints REPLACE only when the stage has that path (`install.sh:537`). Otherwise it prints `MOVE link … to backup`, and WIRED can land on that line (`:548-556`). The README names both labels (`README.md:34-35`) | `[ -e "$stage/$name/$rel" ] \|\| continue` |
| F3 | `CLAUDE_HOME_DIR` outranks `CLAUDE_CONFIG_DIR` and is undocumented | **Resolved by documentation (A5).** The precedence and the name are unchanged, but `--help` (`:36-39`) and the README (`README.md:21-22`) now state both, so the contract is explicit. The name still sits outside the `CLAUDE_DEVC_` prefix. That is the author's choice; I'm not re-raising it | `CLAUDE_HOME_DIR is read by install.sh only and outranks CLAUDE_CONFIG_DIR` |
| F10 | Swap failures break the "ERROR: … nothing was replaced" contract | **Resolved.** `host_rollback` (`:443-460`) prints an `ERROR:` block that says whether the state was restored or which entries are left, with the full backup path and the `mv` to run. One wording defect is left (F13 below) | `$dest is missing: ${left[*]}. They are in $backup.` |
| F9 | README and `--help` state the TTY rule as absolute | **Resolved.** `--help` (`:50-54`) and the README (`README.md:26-29`) both say it stops accidental runs, not a determined agent, and name the sandbox backstop | `That stops accidental runs, not a determined agent` |
| F6 | `installed_by=host-tty` overclaims; `installed_at` ≠ backup dir name on a collision | **Half resolved.** `installed_by` was dropped (A2, test `install-host.bats:262-263`). The join gap is still there: the backup dir can be `<stamp>.<pid>` (`:676`) while the manifest records only `installed_at=$stamp` (`:707`), and there is no `backup=` key. Now F6′ below | `if [ -e "$backup" ]; then backup="$backup.$$"; fi` |
| F1 | Host-only install (the README's flow) always exits 1 | **Still stands.** Executed: P1 `n\ny` → `Installed into …`, `RC=1` | `Exit status: 0 no target declined; 1 a target was declined, or an error;` |
| F2 | `--yes` skips target 2 with a stdout-only line and exit 0 | **Still stands.** Executed: P2 `--yes` → RC=0, and the skip is on stdout | `echo "Skipped host target (~/.claude): it never installs with --yes. …"` |
| F5 | Unknown-argument message has no `ERROR:` prefix | **Still stands.** Executed: P3 `-y` → RC=2 (`:767`) | `*) echo "install.sh: unknown argument: $1" >&2; usage >&2; exit 2 ;;` |
| F7 | Skip and abort lines hard-code `~/.claude` | **Still stands, now cheaper to fix.** `HOST_DEST` is resolved in `main` (`:774-777`) before any skip line runs. Executed: P2 with `CLAUDE_CONFIG_DIR=$HOME/other` printed `Skipped host target (~/.claude)` | `:473`, `:477`, `:481`, `:621` |
| F8 | `.cw-new.<name>` vs `.claude-workflows-*` | **Still stands** (Informational). Also extended to `.cw-new.manifest` (`:651`) | `cp -p "$stage/.manifest" "$dest/.cw-new.manifest"` |
| F11 | The two targets' headers are asymmetric | **Still stands, and widened** (Informational). Details under F11′ below | — |

In the first review's rubric, F1, F2, F5, F7, F8 and F11 are C4–C8 (🟢 Consider). None of the 21 fix commits touches them. I list them as still standing, not as regressions.

## Baseline Conventions

These are unchanged from the prior report. The additions below come from the fix commits.

- **Error messages** start with `ERROR:`, go to stderr and end with a state sentence: `Nothing was installed.` (`install.sh:119,142,151,165,788`), `Nothing was installed into the host target.` (`:425`), or `nothing was replaced.` (`:655,661,679`). The new control-character refusal (`:786-789`) and lock refusal (`:512,634`) follow this.
- **Advisories** are `WARNING:` on stdout (`:196`, `:354`, `:545`).
- **Review-line tags** are uppercase verbs that name what y will do to a path: `REPLACE symlink`, `MOVE`, `ADD`, `MODE`, plus the `WIRED in settings` suffix. Each line runs through `vis`.
- **Host dotfiles** are `.claude-workflows-<noun>` (manifest, backup, now lock). Temp stages in `$TMPDIR` are `cw-<target>-stage.XXXXXX` (`:288`, `:515`).
- **Key=value files** use lower_snake keys: manifest `commit`, `dirty`, `uncommitted_excluded`, `assembled_from`, `installed_parent`, `installed_at`; `.install-stamp` holds `installed_epoch`.

## Name-Pattern Audit

These are the new or changed public names since d0fdd04.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `MODE <path>: <old> -> <new>` | review-line tag | `REPLACE symlink <p> -> <t> with a copy`, `MOVE link <p> -> <t> to backup` | `devcontainer-config/install.sh:532,549` | Consistent: uppercase verb, live path, `->`. It appears in both targets. The README doesn't mention it (Informational, F12) |
| `ADD <path> (new, N file(s)):` + `(content not shown: …)` | review-line tag | `REPLACE …`, `MOVE …`, `(none — …)` | `install.sh:532,551,605` | Consistent. The README covers it ("listed file by file … 200 lines or fewer", `README.md:24-25`) |
| `MOVE link <p> -> <t> to backup (not in the repo)` | review-line tag | `MOVE to backup (not in the repo): <p>` | `install.sh:551` | Consistent. Documented in the README |
| `WARNING: the checkout has uncommitted changes …` | advisory | `WARNING: … not on your PATH`, `WARNING: not in the repo …` | `install.sh:354,545` | Consistent prefix and stream. Printed twice per run (F14) |
| `ERROR: a destination contains a newline or other control character` | error | the other `ERROR: … Nothing was installed.` lines | `install.sh:119,142` | Consistent |
| `ERROR: … rolled back` / `… rollback is INCOMPLETE` | error | `ERROR: could not copy …; nothing was replaced.` | `install.sh:655` | Consistent. One wording defect (F13) |
| `.claude-workflows-lock/` | host dotdir | `.claude-workflows-manifest`, `.claude-workflows-backup/` | `install.sh:498,709` | Consistent |
| `.cw-new.manifest` | host temp entry | `.cw-new.<name>` | `install.sh:644` | Consistent with its sibling. F8 still applies to the family |
| `cw-devc-stage.XXXXXX` | `$TMPDIR` stage | `cw-host-stage.XXXXXX` | `install.sh:515` | Consistent |
| `uncommitted_excluded=` | manifest key | `dirty=`, `commit=` | `install.sh:205-206` | Consistent shape. It counts only the seven claude-home paths even in the devcontainer's claude-home manifest (`:194`). That is correct for what the manifest describes |
| `dirty=` (now always `no`) | manifest key, changed value | old `dirty=yes\|no` | `git show 712c626:devcontainer-config/install.sh` | Backward compatible: the key is kept and the value is honest (fact-check claim 7). No in-repo reader of `dirty=` exists (searched `devcontainer-config/`, `scripts/`, `hooks/`) |
| `installed_by=` | manifest key, removed | — | branch-local only (added in 6793b79) | Never shipped on main, so removing it breaks no one |
| `installed_epoch=` in `<backup>/.install-stamp` | key=value file | manifest `installed_at=<YYYYMMDDTHHMMSSZ>` | `install.sh:707` | Minor asymmetry: two time keys in two formats for the same install (F6′) |
| `-h/--help` text: "The backups of the last 3 installs are kept; the current run's is never removed" | help contract | README `:40-41` | `README.md:40-41` | Consistent between the two |

## Findings

#### F15. The review gate fails open on a host without perl: an empty diff reaches `[y/N]`

**Severity:** Breaking (for any host without perl; low likelihood, since perl ships with macOS and Debian/Ubuntu)
**Location:** `devcontainer-config/install.sh:106-113` (vis), `:228`, `:302-303`, `:600-602`
**Move:** 3 (consumer contract: the review-gate promise), 6 (behaviour change from 712c626)
**Confidence:** High (executed: probe P5)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  LC_ALL=C perl -pe '
```
```
    diff -ruN "$dest/$item" "$src/$item" 2>&1 | vis || rc=${PIPESTATUS[0]}
```
```
    mode_diff "$DEST" "$stage" "${PAYLOAD[@]}" || same=0
    review_diff "$DEST" "$stage" "${PAYLOAD[@]}" || same=0
```
P5 output: PATH without perl, a committed change to `egress/base.txt`, and an existing `$DEST`:
```
=== Changes this install would make ===========================================
===============================================================================

Install this config and bless it? [y/N]
```
stderr: `install.sh: line 107: perl: command not found`

Commit 1592d6b moved `vis` from sed to perl, which adds a host dependency that the README, `--help` and decision 037 never name. When perl is missing, `review_diff` takes `rc` from `PIPESTATUS[0]`, which is diff's status (1 = "changed"). perl's 127 is ignored, so the function reports "changed" and prints nothing. Both targets call it (and `mode_diff`) in `||` or `if !` contexts, which switches off `set -e`. The human then sees an empty review box with no `(none — …)` line, followed by the prompt. That breaks the contract the script states at `:222-225` ("a diff that could not be shown must never reach the [y/N] prompt"). At 712c626 there was no `vis`, so the same host saw the full diff. The host target's pre-pass lines (`echo … | vis` outside a conditional) would kill the run under `set -e` before its prompt. The devcontainer target has no such line when the tree is clean, so it reaches the prompt as shown. Where perl exists this never happens.

**Recommendation:** check `command -v perl` once in `main` and refuse with the usual `ERROR: … Nothing was installed.` Also have `review_diff` treat a non-zero `PIPESTATUS[1]` (vis) as trouble (exit 1), like diff status >1. Name perl as a requirement in `--help`.

#### F6′. The manifest still can't be joined to its backup dir on a stamp collision, and the two time keys use different formats

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:675-676`, `:705-708`, `:723`
**Move:** 7 (asymmetry), 8 (field contract)
**Confidence:** High (read)
**Legibility-target:** for-author

Precedent: lower_snake provenance keys `commit=`/`assembled_from=` used in `devcontainer-config/install.sh:204-209`

**Evidence:**
```
    backup="$bkroot/$stamp"
    if [ -e "$backup" ]; then backup="$backup.$$"; fi
```
```
    echo "installed_at=$stamp"
```
```
    printf 'installed_epoch=%s\n' "$(date -u +%s)" > "$backup/.install-stamp"
```

The fix dropped `installed_by`, which was the bigger half of F6. The join problem is still there: in the collision case the backup is `<stamp>.<pid>` but the manifest says `installed_at=<stamp>`. The new `.install-stamp` then adds a second record of the same install in a second format (epoch in the backup, compact ISO in the manifest), and neither file names the other. Decision 037's revisit trigger joins backup to manifest by stamp.

**Recommendation:** write `backup=<full path or none>` into the manifest. Either put `installed_epoch` in the manifest too, or say in a comment why the backup's key is epoch-only (the clock-ahead ordering case).

#### F13. The rollback success message reads "moved back from (no backup was needed)" on a first install

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:450-452`
**Move:** 4 (message consistency)
**Confidence:** Medium (static; forcing a mid-swap failure on a first install was not probed)
**Legibility-target:** for-author

**Evidence:**
```
    echo "ERROR: the install failed part-way and was rolled back: every entry was moved back" >&2
    echo "       from ${backup:-(no backup was needed)}. $dest is as it was before this run." >&2
```

When none of the seven entries existed, `backup` is empty and `moved` is empty. The rollback only deletes the swapped-in copies, yet the message claims entries were "moved back from (no backup was needed)". It isn't wrong about the end state, but it names an action that didn't happen. Every other `ERROR:` state line says exactly what was done.

**Recommendation:** branch on `[ -n "$backup" ]`: "…rolled back: the new copies were removed. $dest is as it was before this run."

#### F14. The uncommitted-changes WARNING is printed twice per run when claude-home paths are dirty

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:195-200` (called from `:290` and `:517`)
**Move:** 7 (asymmetry)
**Confidence:** High (executed: P4, `WARNING count: 2`)
**Legibility-target:** for-author

**Evidence:**
```
    echo "WARNING: the checkout has uncommitted changes under the payload paths. They are"
```

Each target calls `assemble`, so a dirty `skills/` file is listed once above the devcontainer prompt and again above the host prompt. That is defensible, since each prompt gets its own caveat. But the `assemble` comment at `:173-174` says the combined path list exists so the targets get "one warning for all of them". The second copy repeats the same commit id, so it's noise rather than a contradiction.

**Recommendation:** optional. Either fix the comment ("one warning per target"), or make the host target's copy a one-line back-reference.

#### F12. `MODE` is a new review tag that the README's review vocabulary doesn't list

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:256`; `README.md:32-38`
**Move:** 3 (documentation drift)
**Confidence:** High (read)
**Legibility-target:** for-author

Precedent: the README names each review tag a migrating user must read (`REPLACE symlink … with a copy`, `MOVE to backup`, `MOVE link … to backup`, `WIRED in settings`) in `README.md:32-38`

**Evidence:**
```
        echo "MODE $dest/$item${p%/}: ${dm[$p]} -> ${rec%% *}" | vis
```

A `MODE` line means y will change a live file's permission bits, such as a hook gaining `+x` with no content diff. The line shape matches its siblings. The README's migration paragraph, which is the documented list of tags, doesn't mention it.

**Recommendation:** optional. Add half a sentence to the README (`MODE <file>: 644 -> 755` means only the permission bits change).

#### F11′. The target headers still differ, and now the commit id format differs too

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:295-296` vs `:485-486`, `:522`; `:304-315` vs `:604-613`
**Move:** 7 (asymmetry)
**Confidence:** High (executed: P4)
**Legibility-target:** for-author

**Evidence:**
```
  echo "Canonical (repo):  $SRC at commit ${STAGED_COMMIT:0:12} (staged in $stage)"
```
```
  echo "Canonical (repo):  $REPO_ROOT (commit $(sed -n 's/^commit=//p' "$stage/.manifest"))"
```

This carries over F11 (target 1 has no banner or `Destination:` line) and adds two new points. Target 1 prints a 12-character id "at commit …" while target 2 prints the full 40 characters "(commit …)", so the two commit lines of one run look different. Target 2 skips its prompt when nothing changed (`Nothing to install into $dest.`), but target 1 still asks `Install this config and bless it?` under `(none — …)`. Target 1's case is defensible, since re-blessing has value, but the difference is unstated.

**Recommendation:** optional. Use `${STAGED_COMMIT:0:12}` in both lines. Leave the prompt behaviour and note it in 037 if it's deliberate.

## What Looks Good

- **Error contract made uniform.** Every new failure path follows the `ERROR:` + state-sentence convention, including the lock refusal, the control-character refusal (which names all five env sources), the hash mismatch ("Nothing was replaced. Rerun install.sh.") and both rollback outcomes. F10's gap is closed.
- **Review vocabulary now matches the action.** REPLACE only for paths the repo also has, MOVE and MOVE link for the rest, WIRED matched on the full `hooks/<rel>`. The README names every tag except MODE.
- **`--help` and README agree** on the destination precedence (with `CLAUDE_HOME_DIR` now explained), committed-only staging, the skip rule's limits, and the backup retention wording ("last 3 installs … the current run's is never removed").
- **The manifest stays additive and honest.** `dirty=` is kept for readers, and its constant value is truthful. `uncommitted_excluded=` is an additive lower_snake key. `installed_by`'s false claim is gone before it ever shipped.
- **Naming within families.** `.claude-workflows-lock` joins manifest and backup. `cw-devc-stage`/`cw-host-stage` are parallel.
- **A no-op is not a decline.** `Nothing to install into $dest.` returns 0 and leaves `DECLINED` unset, the same as a skip.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F15 | No perl → `vis` fails silently, empty review reaches `[y/N]` (regression from 712c626; undocumented dependency) | Breaking (low likelihood) | `install.sh:106-113,228,302-303` | High (executed) |
| F1 | Host-only install exits 1 (carried, C4) | Minor | `install.sh:59,805` | High (executed) |
| F2 | `--yes` skip is a stdout line with exit 0 (carried, C5) | Minor | `install.sh:472-474` | High (executed) |
| F5 | Unknown-argument message lacks `ERROR:` (carried, C6) | Minor | `install.sh:767` | High (executed) |
| F7 | Skip and abort lines hard-code `~/.claude` (carried, C7) | Minor | `install.sh:473,477,481,621` | High (executed) |
| F6′ | Manifest ↔ backup join fails on `.pid` collision; two time-key formats | Minor | `install.sh:676,707,723` | High |
| F13 | Rollback message "moved back from (no backup was needed)" | Minor | `install.sh:450-452` | Medium |
| F14 | Uncommitted WARNING printed twice; comment says once | Informational | `install.sh:173-174,195-200` | High (executed) |
| F12 | `MODE` tag missing from README's review vocabulary | Informational | `install.sh:256`; `README.md:32-38` | High |
| F11′ | Target headers and commit-id formats asymmetric (carried + widened, C8) | Informational | `install.sh:295,522` | High |
| F8 | `.cw-new.*` vs `.claude-workflows-*` (carried, C8) | Informational | `install.sh:644,651` | Medium |

Resolved since d0fdd04: F3 (by documentation), F4, F9, F10. F6 is half resolved (carried as F6′).
Counts: Breaking 1 · Inconsistent 0 · Minor 6 · Informational 4.

## Overall Assessment

The fixes closed all three Inconsistent findings from the first pass (F3, F4, F10) and the doc-drift finding (F9). The new surfaces they added (the lock, the MODE and ADD lines, the rollback and control-character errors, `uncommitted_excluded`, `.install-stamp`) follow the conventions the script already had: `ERROR:` plus a state sentence, uppercase review tags on live paths, and the `.claude-workflows-*` prefix. One regression came with them. Moving `vis` to perl (1592d6b, for fact-check claim 6) added a host dependency that nothing documents, and without it the review gate fails open. The run prints an empty diff and still asks y/N, which is exactly what the script's own review contract forbids. Likelihood is low on the user's likely hosts, but the fix is small: a `command -v perl` check in `main`, and counting vis's status as diff trouble. The rest are small labelling and consistency items (F1, F2, F5, F7 are the carried C4–C7 Considers). None of them affects what the plan-step-9 migration review shows on a host that has perl.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 9ae6e46` line.
- Answered: yes. Prior F1–F11 are each verdicted against 9ae6e46, the new surfaces are audited, and five findings are new (F15, F13, F14, F12, and F6′/F11′ as extensions).
- Out of scope: whether F15's fail-open matters for security beyond the review contract (security critic); lock staleness after SIGKILL, and rollback correctness itself (fact-check claims 18 and 20 cover these); test-count claims (fact-check claim 28); macOS `find -printf` / `script` portability.
- Escalate: F15. It is a regression of the review gate introduced by this fix round, and the orchestrator should check whether the security critic found it too. Confirm that the user's host has perl before the plan-step-9 run, or land the `command -v perl` refusal first.
