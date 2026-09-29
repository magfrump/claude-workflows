Commit: 5a6d689

# API Consistency Review — `q094-exit-scan-worktree-layout` (review-fix loop pass 1)

**Scope:** `git diff main...HEAD` at 5a6d689: `devcontainer-config/cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats` (plan doc read for intent only)
**Date:** 2026-09-28
**Based on:** Stage 1 code-fact-check (k=1) summary passed by the orchestrator (one Incorrect: the commit-message "-f before every read" claim; Mostly Accurate: `git_exit_scan`'s return-2 doc, config.worktree wording, "files never read")

## Baseline Conventions

- **Launcher exit-status contract.** `cc-isolated.sh` maps `git_exit_scan` 0/1/other to claude's status / 3 / 4 (`devcontainer-config/cc-isolated.sh:746-750`). The contract is documented twice: the `--help` header (`cc-isolated.sh:19-31`, "0 success; after a session: the exit scan found nothing") and the guide's **Exit status** paragraph (`guides/cc-isolated-usage.md:75-80`).
- **User-facing message prefixes.** The devcontainer scripts use upper-case severity tags: `ERROR:` (84 uses), `WARNING:` (16), `NOTE:` (4, e.g. `cc-isolated.sh:619`, `:685`, `install.sh:1231`, `:1242`). Before this branch no lower-case tag existed. The scan's own messages open with `WARNING:` and are hard-wrapped with two-space continuation indents (`cc-exit-scan.sh:924`, `:960`). Every message goes through `scan_vis`.
- **Function naming in `cc-exit-scan.sh`.** Public entry points and reporting helpers use `scan_*` (`scan_git_dirs`, `scan_diff`, `scan_vis`, `scan_interrupted`) or `git_*` (`git_exec_snapshot`, `git_exit_scan`). Snapshot internals that share dynamically scoped `_snap_*` state use `_snap_<noun>` / `_snap_<noun>_<qualifier>` (`_snap_hash`, `_snap_size_ok`, `_snap_inside_ws`, `_snap_first_line`, `_snap_worktree_of`). Predicates end in `_ok` / `_valid` or read as a relation (`_snap_inside_ws`, `gitdir_valid`, `launch_gitdir_ok`).
- **Tunable constants.** `GIT_EXIT_SCAN_<NOUN>` plain assignments next to the code that uses them. Tests override them after sourcing; they are not `${VAR:-default}` env reads (`cc-exit-scan.sh:113`, `:179-180`).
- **Snapshot record format.** Tab-separated, the first field a one-letter type (`F`, `C`), documented in the block at `cc-exit-scan.sh:145-150`. `scan_diff` renders only `F` and `C` records.
- **`/workspace` literal.** Hard-coded in `devcontainer.json:134-135` (`workspaceMount` target, `workspaceFolder`) and in several places in `cc-isolated.sh` (e.g. `:239`, `:460`). There was no named constant and no test tying the copies together.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `scan_std_worktrees` | function (called by `git_exit_scan`) | `scan_git_dirs`, `scan_diff`, `scan_vis` | `devcontainer-config/cc-exit-scan.sh:117`, `:739`, `:746` | Consistent: `scan_*` prefix for a scan-level helper. `std` is a new abbreviation, but the guide spells it out ("git's standard layout") |
| `_snap_wrel` | snapshot helper | `_snap_path`, `_snap_opt`, `_snap_remote` | `cc-exit-scan.sh:259`, `:275`, `:343` | Consistent: it appends to `$_snap`, so the `_snap_` prefix is correct |
| `_snap_hash_str` | helper | `_snap_hash` | `cc-exit-scan.sh:164` | Consistent: the `_str` variant of `_snap_hash`, with the same 16-hex output |
| `_snap_file_is` | predicate helper | `_snap_size_ok`, `_snap_inside_ws`, `_snap_file` | `cc-exit-scan.sh:181`, `:295`, `:219` | Consistent enough. It takes the `_snap_` prefix because it reads `_snap_bytes` through `_snap_size_ok`, which is why `scan_std_worktrees` declares `local _snap_bytes=0`. The name sits close to the recorder `_snap_file` (see Finding 5) |
| `GIT_EXIT_SCAN_CONTAINER_WS` | constant | `GIT_EXIT_SCAN_MAX_FILE_BYTES`, `GIT_EXIT_SCAN_MAX_TOTAL_BYTES`, `GIT_EXIT_SCAN_KEYS_RE` | `cc-exit-scan.sh:113`, `:179-180` | Consistent: same prefix, a plain assignment, declared next to its user. It is a second copy of `/workspace` (Finding 4) |
| `W` record type | snapshot schema | `F`, `C` | `cc-exit-scan.sh:145-150` | Consistent: one letter, tab-separated, documented in the same block. It is ignored by `scan_diff`, as the doc block says |
| `note: exit scan: …` | stderr message tag | `NOTE:`, `WARNING:`, `ERROR:` | `cc-isolated.sh:619`, `:685`; `install.sh:1231`; `cc-exit-scan.sh:960` | Inconsistent: lower case, and the only `note:` in `devcontainer-config/*.sh` (Finding 2) |

## Findings

#### 1. The launcher's `--help` EXIT STATUS header and the guide's Exit status paragraph still say 0 means "found nothing"

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:20-21`; `guides/cc-isolated-usage.md:75-76`
**Move:** 3 (consumer contract, documentation drift)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> `#   0  success; after a session: the exit scan found nothing, and claude's own` (cc-isolated.sh:20)
> `usage; 3 the exit scan found a change; 4 the exit scan could not finish. Two` (cc-isolated-usage.md:76)

The exit-code mapping itself is unchanged (`cc-isolated.sh:746-750`). What changed is what "found a change" means: a session that adds or removes a standard linked worktree now exits with claude's status, not 3. The tripwire paragraph at `cc-isolated-usage.md:65-68` and the new Q-094 section say so. The two places a script author reads the exit contract do not: the `--help` header (the guide's line 27 sends readers to "`cc-isolated --help`, exit status included") and the **Exit status** paragraph. Scripts that branch on 3 are not broken, since 3 still means "a finding". But the documented meaning of 0 ("found nothing") is now wrong for the note case.

**Recommendation:** Add a clause to both, for example "0 … the exit scan found nothing, or only standard linked worktrees (a `note:` line)", and "3 the exit scan found a change (linked worktrees in git's own layout excepted: see Q-094 below)".

#### 2. The new stderr tag is lower-case `note:`; the scripts' convention is `NOTE:`

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:908`
**Move:** 2 (naming against the grain) / 4 (message consistency)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> `  echo "note: exit scan: only linked worktrees in git's standard layout changed (${line% }). They take config and hooks from the checkout's own .git, so this is not a finding."` (cc-exit-scan.sh:908)
> `      echo "NOTE: $ws is unregistered — running with the base egress profile only."` (cc-isolated.sh:619)

Precedent: upper-case `NOTE:` / `WARNING:` / `ERROR:` message tags used in `devcontainer-config/cc-isolated.sh:619`, `:685`, `devcontainer-config/install.sh:1231`, `:1242`, `devcontainer-config/cc-exit-scan.sh:924`, `:960`

In one launcher run, the user can now see `NOTE:` at launch (`cc-isolated.sh:619`/`:685`) and `note:` at exit. `git_exit_scan`'s own sibling messages are `WARNING: the exit scan …`, with no second `exit scan:` tag. The line is also a single ~190-character line, while every other scan message is hard-wrapped with two-space continuation indents. The tests pin the current string (`test/cc-isolated-functions.bats:2234`, `:2391`), so the tag is effectively a contract already, and changing it later costs more.

**Recommendation:** Use `NOTE: the exit scan found only linked worktrees …` (matching `WARNING: the exit scan …`), wrap it like its siblings, and update the two test assertions and the guide's quoted line (`cc-isolated-usage.md:336`).

#### 3. A local-tracking branch (`branch.<b>.remote = .`) leaves a `W` record, so the note never fires in that checkout. The guide's wording does not tell users this

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:352` (with `:401`, `:705`); `guides/cc-isolated-usage.md:348-350`
**Move:** 3 (consumer contract: when does the new 0-with-note path apply)
**Confidence:** Medium (traced by reading the code; not run, because this agent's sandbox refuses `git` outside its worktree)
**Legibility-target:** for-author
**Evidence:**
> `  _snap_wrel remote "$p" "$p"` (cc-exit-scan.sh:352)
> `    [ -z "$f" ] || [ -n "${_snap_rnames["$f"]:-}" ] || _snap_remote "$f" "$g" || rc=1` (cc-exit-scan.sh:705)
> `` `core.attributesFile` (husky's `.husky/_`) or a relative local remote**, which `` (cc-isolated-usage.md:349)

`git branch --track`, or `--set-upstream-to=<local branch>`, writes `branch.<b>.remote = .`. `.` is not a defined remote name, so the snapshot sends it to `_snap_remote`. `.` is not empty, `/…` or `~/…`, so `_snap_wrel` emits `W remote .`, and `scan_std_worktrees` refuses the note whenever the exit snapshot has any `W` record. The result fails safe (a warning, exit 3). But the guide's "a relative local remote" will not make users think of `.`, and those users will get the old exit-3 behaviour with no explanation. Whether `.` really needs to be a `W` is a question for the security review: git resolves `.` against the repository it runs in, so a linked worktree would resolve it to its own tree. This review only flags the documentation.

**Recommendation:** Either name `branch.<b>.remote = .` (local tracking) in the guide's list of what keeps the warning, or, if the security reviewer agrees `.` is safe, exclude it in `_snap_wrel`/`_snap_remote` and pin that with a test.

#### 4. `GIT_EXIT_SCAN_CONTAINER_WS` is a second copy of the `workspaceMount` target, and nothing ties the copies together

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:765-768`
**Move:** 2 (naming) / 1 (baseline)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> `GIT_EXIT_SCAN_CONTAINER_WS=/workspace` (cc-exit-scan.sh:768)
> `  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated",` (devcontainer.json:134)

Precedent: `GIT_EXIT_SCAN_<NOUN>` plain-assignment constants used in `devcontainer-config/cc-exit-scan.sh:113`, `:179-180`

The name and form match their siblings. The comment names `devcontainer.json`'s `workspaceMount` as the source of truth, but no test asserts the two agree. `cc-isolated.sh` hard-codes `/workspace` separately (`:239`, `:460`). If the mount target ever changes, the scan fails safe: the container form no longer matches, the note is refused, and the scan warns. So the drift costs noise, not exposure. This is the first named copy, which makes it a good point to add a cheap guard.

**Recommendation:** Optional: a one-line bats assertion that `devcontainer.json`'s `workspaceMount` target equals `$GIT_EXIT_SCAN_CONTAINER_WS`.

#### 5. `git_exit_scan`'s header comment: the reflow broke the sentence, and the return-2 list is incomplete

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:911-916`, `:955-956`
**Move:** 3 (documentation drift; builds on the fact-check's Mostly Accurate verdict)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> `# anything else did; 2` (cc-exit-scan.sh:914)
> `# when the exit state could not be read. 0 is not "safe": see LIMITS above.` (cc-exit-scan.sh:915)
> `    echo "  the two snapshots differ but the difference could not be shown; treat the checkout as unsafe" >&2` (cc-exit-scan.sh:955)

This comment is the function's contract, and this branch edits it. The edit left a dangling `2` on its own line, and it still omits the pre-existing second return-2 path ("differ but nothing rendered"), which the fact-check flagged. Also, `_snap_file_is` (a predicate) sits one letter away from `_snap_file` (a recorder that appends to `$_snap`). The doc comment makes the difference clear, so no rename is needed, but a reader skimming call sites could confuse the two.

**Recommendation:** Reflow the comment and add "or when they differ but the difference cannot be shown" to the 2 case.

## What Looks Good

- **The launcher-facing contract is untouched.** `git_exit_scan` keeps its 0/1/2 range, and the 0-with-note path reuses the existing `0) exit "$rc"` arm (`cc-isolated.sh:747`). The launcher needed no change, and the note's semantics fail closed: anything unmatched, unreadable or erroring returns 1 from `scan_std_worktrees`, and `git_exit_scan` then takes the old warning path.
- **The note goes through `scan_vis`** like every other scan message (`cc-exit-scan.sh:947`). The worktree names in it are restricted to `[A-Za-z0-9._-]` beforehand.
- **The `W` record extends the schema additively.** It is documented in the record-format block, `scan_diff` ignores it (it renders `F`/`C` only), and it is derived from `C`/`F` data, so it cannot by itself cause the "differ but nothing rendered" return 2. Launch and exit snapshots come from the same sourced code, so there is no cross-version record compatibility to worry about.
- **The naming follows the file's grain:** `scan_*` for the scan-level function, `_snap_*` for helpers that touch `_snap_*` state (and `scan_std_worktrees` correctly scopes `local _snap_bytes=0` for them), and a `GIT_EXIT_SCAN_*` constant beside its user.
- **Suppression is not silent.** The user always sees one line naming what was added or removed, which keeps the tripwire's "never silent about a change" posture.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | `--help` EXIT STATUS header and guide Exit status paragraph still say 0 = "found nothing" | Minor | `cc-isolated.sh:20-21`; `cc-isolated-usage.md:75-76` | High |
| 2 | Lower-case `note:` tag and a one-line message against the `NOTE:`/`WARNING:`, wrapped convention | Minor | `cc-exit-scan.sh:908` | High |
| 3 | `branch.<b>.remote = .` leaves a `W` record, so the note never fires; the guide's "relative local remote" does not signal this | Minor | `cc-exit-scan.sh:352`; `cc-isolated-usage.md:349` | Medium |
| 4 | `GIT_EXIT_SCAN_CONTAINER_WS` duplicates the `workspaceMount` target with no test tying them | Informational | `cc-exit-scan.sh:768` | High |
| 5 | `git_exit_scan` doc comment: broken reflow, and the second return-2 path is missing | Informational | `cc-exit-scan.sh:911-916` | High |

## Overall Assessment

The change fits the scan's existing API. It adds no new exit code, the function-return range and launcher mapping are unchanged, the record-format extension is additive, and the new names follow the file's `scan_*` / `_snap_*` / `GIT_EXIT_SCAN_*` conventions. Nothing breaks: a script that reads the launcher's exit status sees 3 less often, only in the case the change targets, and every doubtful case still returns 3. The findings are documentation and presentation drift, all fixable in place: the two exit-status descriptions consumers read first (`--help` and the guide's Exit status paragraph) were not updated; the message tag breaks the upper-case convention while tests are already pinning it; and one common config (`branch.<b>.remote = .`) quietly opts a checkout out of the new behaviour.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/api-consistency-review-2026-09-28-q094.md (in the worktree), structured per the api-consistency-reviewer skill.
- Answered: yes
- Out of scope: whether `branch.<b>.remote = .` (or any `W` case) is actually safe to allow (security-reviewer's call). The commit-message "checks -f before every read" inaccuracy (fact-check Incorrect; commit prose, not an API surface). The relative `core.hooksPath` in the user's own global config: I checked it and it is covered, because the embedded-repo walk (`cc-exit-scan.sh:685-695`) re-reads host config for the new worktree's tree, and any extra `hooksdir` record makes `scan_std_worktrees` decline. The guide just does not list it as a refusal case.
- Escalate: nothing
