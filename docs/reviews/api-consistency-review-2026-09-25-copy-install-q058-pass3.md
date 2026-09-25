# API Consistency Review: copy-install Q-058, pass 3 (fix commits `f8d3f78..516124d`)

Commit: 516124d
**Scope:** the 7 fix commits `f8d3f78..516124d` on `skill-fixtures` (99656a2, 21bf405, fa25f13, b58d671, e61408f, d71715f, 767f421, 516124d). The surface is install.sh's CLI (messages, exit codes, `--help`) and the docs contract (README, `guides/bare-host-hook-wiring.md`, decision 037, the plan). Code read at 516124d in `/workspace/.claude/wt-q058p2`. Earlier history is context only.
**Date:** 2026-09-25
**Based on:** the pass-2 API review `docs/reviews/api-consistency-review-2026-09-25-copy-install-q058-pass2.md` (F1–F9) and the "Pass 2" section of `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md` (P2-A3, P2-A4, P2-A5).

> ⚠️ **No code fact-check report provided.** API documentation claims have not been independently verified against implementation. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

To make up for that, I ran every claim these findings depend on. The probes reuse the `install-host.bats` harness: the helpers were extracted with the `@test` blocks dropped, and the stubbed pgrep and docker, `run_pty` and `stub_cp_then` were kept. They ran against install.sh at 516124d. Probe file: `scratchpad/p3api/test/p.bats` (probes A–G). Each result cited below comes from those runs.

## Baseline Conventions

This is the pass-2 baseline, rechecked at 516124d.

- **Refusal shape.** `ERROR: <what>` goes to stderr. Continuation lines are indented 7 spaces, and lists 9. The message ends with a trailer and exits 1. Untrusted text goes through `vis_or_die`.
- **Trailers by phase:**
  - At startup: `Nothing was staged or installed.`
  - Shared and devcontainer steps: `Nothing was installed.`
  - Host target, before any prompt: `Nothing was installed into the host target.` (`host_refuse`, `install.sh:675-679`).
  - Host copy and swap errors: `; nothing was replaced.` (`:828`, `:976`) or `Nothing was replaced.` (post-y hash, `:958`).
- **Exit status** (`--help`): 0 no target declined; 1 a target was declined, or an error; 2 bad arguments.
- **`--help` lists every refusal condition** a user can hit. README `:25-45` summarises the same list, and decision 037 carries the full contract. T56 pins some of the wording.
- **Helpers.** Names are snake_case. Hash-site helpers take `<dir> <prefix> <name...>` joined as `$dir/$pfx$name` (`tree_hash`, `payload_hash`). Target-scoped names carry `host_`/`HOST_` or `DC_`.
- **Transient names under the destination** use a `.cw-` prefix (`.cw-new.<name>`). Durable ones use `.claude-workflows-` (`-lock`, `-backup`, `-manifest`).
- **Hardened git.** The repo already wraps git with `-c core.hooksPath=/dev/null -c core.fsmonitor=…` in `archive/benchmark/scripts/crb-audit-clone.sh:55`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `repo_git` | function | `head_commit`, `extract_commit`, `git_state_gate`; the hardened `git()` wrapper | `devcontainer-config/install.sh:174,198,245`; `archive/benchmark/scripts/crb-audit-clone.sh:55` | Consistent. It is snake_case, its flag set matches the repo's earlier hardened wrapper, and it is an explicit name rather than a shadowed `git` |
| `links_in <dir> <prefix> <name...>` | function | `tree_hash <dir> <prefix> <name...>`, `payload_hash <dir> <prefix> <manifest>` | `devcontainer-config/install.sh:636,660` | The signature is consistent: the same `<dir> <prefix>` shape, which is what pass-2 F7 asked new helpers to follow. Its error behaviour is not (F1) |
| `dc_unwind <reason> [<list>]` | function | `host_rollback`, `host_refuse`, `host_cleanup`; the `DC_TMP` global | `devcontainer-config/install.sh:675,688,701,1184` | Consistent. The `dc_` prefix matches `DC_TMP`. "unwind" rather than "rollback" fits, because it removes the old state instead of restoring it |
| `.cw-stage.XXXXXX` | on-disk name | `.cw-new.<name>`, `cw-host-stage.XXXXXX` (removed), `cw-devc-stage.XXXXXX` | `devcontainer-config/install.sh:808,818,471` | The name is consistent: the transient `.cw-` prefix, hidden under the destination. A leftover link is handled differently from a `.cw-new.*` one (F3) |
| `ERROR: could not create <dest>/.claude-workflows-lock (is <dest> writable?) … nothing was replaced.` | refusal message | `host_refuse` (the lock-held branch right beside it), `could not copy the new files into $dest; nothing was replaced.` | `devcontainer-config/install.sh:675-679,798,828` | Inconsistent trailer. It is a pre-prompt host refusal but uses the copy step's trailer, and T16 depends on that (F2) |
| `could not create a staging directory in $dest.` | refusal message | other `host_refuse` calls | `devcontainer-config/install.sh:752-774` | Consistent: it goes through `host_refuse` |
| `symlinks appeared in the staged devcontainer config after its link check:` / `symlinks appeared in the copies to install after the payload's link check:` / `symlinks landed in $DEST, which install.sh never installs:` | refusal messages | `the committed payload contains symlinks, which install.sh never installs:` | `devcontainer-config/install.sh:281-284` | Consistent. They share the ERROR, 9-space list, "never installs a link" shape and the target's own trailer |
| `dc_unwind` body: `The copied items were removed again (the previous config with them) …` | message | the pre-fix A1 mismatch text | `f8d3f78:devcontainer-config/install.sh` (A1 block) | Consistent. It keeps the old wording and adds the previous-config clause (pass-2 F9, closed). The mismatch reason is one unwrapped line of about 150 characters (F5) |
| `head_commit` remedy `` `git -C <repo> rev-parse HEAD` `` | message | the same message's old `git status` remedy | `f8d3f78:devcontainer-config/install.sh` (`head_commit`) | Consistent, and safe. The command runs no hook (probe D: `fatal: ambiguous argument 'HEAD'`, rc=128) |
| git-state remedy `git config --file <the file named above> --unset-all <key>` | message | the old `git config --local --unset <key>` | `f8d3f78:devcontainer-config/install.sh` (`git_state_gate`) | Consistent. It works for every entry kind (probe A); README overstates it (F4) |
| `tmpdir_writer`, `stub_cp_then` | test helpers | `stub_pgrep`, `stub_docker`, `stub_pgrep_table`, `plant_marker_cmd` | `test/install-host.bats:45-53,276,288` | Consistent |
| `T75`–`T83` | test IDs | `T1`–`T74` | `test/install-host.bats` | Consistent. The numbering continues with no reuse |

## Findings

#### F1. `links_in` leaks `find`'s exit status. When the last named item is missing, install.sh exits 1 with no ERROR line, and on the devcontainer `$DEST` site that skips `dc_unwind`, so an altered `cc-isolated.sh` stays live

**Severity:** Inconsistent
**Location:** `devcontainer-config/install.sh:650-654` (`links_in`); call sites `:494` (devcontainer stage), `:563` (`$DEST` after the copy), `:833` (host copies); `docs/decisions/037-bare-host-copy-install.md:68`
**Move:** 4 (error consistency) and 3 (the documented contract no longer holds)
**Confidence:** High (executed, probes F and G)
**Legibility-target:** the user at the terminal after a failed devcontainer install; a decision 037 reader; the security critic

Evidence:
```
install.sh:653    for name in "$@"; do find "$dir/$pfx$name" -type l; done
install.sh:563    links="$(links_in "$DEST" "" "${PAYLOAD[@]}")"
037:68            A copy that fails part-way takes the same path (P2-A2, T83), so an altered
                  `cc-isolated.sh` copied before the failure never stays live.
21bf405 Notes:    explicit checks were chosen over making tree_hash fail. It runs inside $(...),
                  where a failure would exit silently through set -e.
```
- **The mechanism.** The `for` loop's status is that of its last `find`. `links="$(…)"` is a plain assignment, so `set -e` exits on it. A missing *last* item (`claude-home` for PAYLOAD, `manifest` on the host) ends the script with only `find: '…': No such file or directory`: no ERROR line and no trailer. That is the silent `set -e` exit that `vis_or_die` (C3) was added to remove, and the one 21bf405's Notes say that commit avoided for `tree_hash`. A missing *earlier* item is harmless: probe F removed `$DEST/egress`, `find` failed mid-loop, and `tree_hash` then caught the mismatch and ran `dc_unwind` as intended.
- **The `$DEST` site.** Probe G used `stub_cp_then`, in the style of A1b and T83. It appended `echo TAMPERED-LAUNCHER` to `cc-isolated.sh` as it landed and removed `$DEST/claude-home` after its copy. The result:
  ```
  status=1
  find: '…/claude-devcontainer/claude-home': No such file or directory
  launcher: echo TAMPERED-LAUNCHER mode=755
  bin link: …/claude-devcontainer/cc-isolated.sh
  ```
  The altered launcher is left in `$DEST`, executable, and `~/.local/bin/cc-isolated` still points at it. Nothing was blessed. But the launcher itself is the code that would check the bless, which is the case P2-A2 (b58d671) was written to close. Before 21bf405, `tree_hash` tolerated the missing item, reported a mismatch, and the items were removed with a message. So this path is a regression that 21bf405 introduced. It is not new exposure from before.
- **The other two sites fail closed.** The EXIT trap removes the host copies, and the devcontainer stage exits before the review. Both still exit silently.

The writer this needs is the same one A1b, T83 and T79 assume: one acting in `$DEST` during the copy.

**Recommendation:**
- End `links_in` with `return 0`, or use `find … -type l 2>/dev/null || true` per item. A missing item then falls through to the `tree_hash` comparison, which already routes to `dc_unwind` on the devcontainer and "changed after review" on the host.
- Add a T83 variant that removes `$DEST/claude-home` after the copy and asserts `removed again` and no `TAMPERED-LAUNCHER`.
- Hand this to the security critic for pass 3.

#### F2. The unwritable-destination refusal uses the copy step's trailer, not `host_refuse`'s. That is what keeps T16 green, and T16 no longer reaches the copy failure its name describes

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:794-803` (the lock branch), `:826-830` (the copy failure); `test/install-host.bats:378-390` (T16)
**Move:** 4 (error consistency) and 3 (test drift)
**Confidence:** High (executed, probe B; grep)
**Legibility-target:** the user who hits the refusal; the next maintainer who reads T16

Precedent: the pre-prompt host refusals end `Nothing was installed into the host target.` via `host_refuse`, used in `devcontainer-config/install.sh:752-774,798,810`

Evidence:
```
install.sh:797  elif [ -e "$dest/.claude-workflows-lock" ]; then
install.sh:798    host_refuse "$(lock_msg "$dest")"
install.sh:800    echo "ERROR: could not create $dest/.claude-workflows-lock (is $dest writable?)." >&2
install.sh:802    echo "       access there even when nothing would change; nothing was replaced." >&2
T16:378  @test "T16 a copy failure swaps nothing and leaves no backup" {
T16:386    [[ "$output" == *'nothing was replaced'* ]]   # the copy step failed safely (before the review, since R2)
```
- **The trailer.** The branch right above uses `host_refuse` for the lock-held case, and so does the new `mktemp` failure two lines down. The unwritable case fires at the same point, before any stage or prompt, but uses `; nothing was replaced.`, the copy and swap trailer. Pass-2 F3 recommended the host trailer for this message.
- **The test.** T16 (`chmod a-w` on the destination) now fails at the lock, not the copy. Its assertion still passes only because this message reused `nothing was replaced`. The copy-failure message at `:828` is no longer asserted by any test (`grep 'could not copy the new files' test/*.bats`: no match).
- **The hint.** When the destination doesn't exist and its parent is read-only, the message asks about a directory that isn't there. Probe B: `(is …/ro/new writable?)`, where `ro/new` doesn't exist and `ro` is the read-only one.

**Recommendation:**
- Route the message through `host_refuse`, for example: `host_refuse "could not create $dest/.claude-workflows-lock: $dest (or its parent) is not writable. install.sh stages and reviews under the destination, so it needs write access even when nothing would change."`
- Rename T16 to the unwritable-destination case and assert the new text.
- Add a copy-failure test for `:828`, for example `stub_cp_then '*/.cw-new.skills' 'exit 1'`.

#### F3. A killed run leaves `.cw-stage.*` (and `.cw-new.*`) in the destination. `lock_msg` names only the lock, and a leftover `.cw-stage` link is removed silently where a leftover `.cw-new` link is refused

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:681-683` (`lock_msg`), `:767-772` (the `.cw-new` link refusal), `:805-807` (the `.cw-stage` clear); plan `:63`
**Move:** 3 (undocumented residue) and 7 (asymmetry)
**Confidence:** High (executed, probe C)
**Legibility-target:** a user recovering from a killed or crashed install; the next maintainer

Evidence:
```
probe C, after kill -9 at the prompt:
  left: .claude-workflows-lock .cw-new.CLAUDE.md … .cw-new.workflows .cw-stage.Mbv0RJ
rerun:  ERROR: another install holds …/.claude-workflows-lock, or one was killed. If no install.sh
        is running, remove that directory and rerun.
after rmdir of the lock, rerun: installed; left: .claude-workflows-manifest CLAUDE.md guides hooks …
install.sh:770  host_refuse "$dest/.cw-new.$name is a symlink left from elsewhere; remove it and rerun."
install.sh:807  rm -rf "$dest"/.cw-stage.*
```
- **Recovery works.** The one action `lock_msg` asks for (remove the lock) is enough, and the next locked run clears the stage and the copies.
- **None of the docs say so.** `--help`, README and 037 don't say that a killed run leaves a staged payload tree under `~/.claude`. The fix only described it in a commit body and a comment. The focus item's premise, "left after a killed run", is true until the next run.
- **Two leftover conventions.** A link at `.cw-new.<name>` is refused with a remove-and-rerun message, and the plan (`:63`) lists that refusal. A link at `.cw-stage.*` is removed without comment (T82). Both are safe: `rm` without a trailing slash never follows. But the rules for leftovers are now split.

**Recommendation:** Optional. Append "(its `.cw-stage.*` and `.cw-new.*` directories are cleared by the next run)" to `lock_msg` or to 037's host bullet. Or record in 037 why `.cw-new.*` links are refused and `.cw-stage.*` links aren't, so the difference reads as deliberate.

#### F4. README says each git-state entry "is named with the … `--unset-all` command that removes it". The output lists the entries, then gives one template command, and a multi-valued key is listed once per value

**Severity:** Informational
**Location:** `README.md:34-38`; `devcontainer-config/install.sh:228-239`
**Move:** 3 (documentation drift)
**Confidence:** High (executed, probe A)
**Legibility-target:** a README reader with a local LFS or include setup

Evidence:
```
README:36  entry is named with the `git config --file … --unset-all` command that removes
           it.
probe A output:
         …/.git/config: include.path /x1
         …/.git/config: include.path /x2
         …/.git/config: includeif.gitdir:/Foo/.path /x3
         …/.git/config.worktree: core.fsmonitor /bin/true
       … Check each one and remove it, with
         git config --file <the file named above> --unset-all <key>
remedy per listed line: rc=0 for every entry except the second include.path (rc=5: already removed);
after the remedy the install proceeds (status=0).
```
**P2-A4 is fixed.** The new remedy works for a `config.worktree` key, a multi-valued `include.path` and an `includeIf` key, even in the lower-cased form `--get-regexp` prints it in. With it applied, the install proceeds. The README sentence reads as though each entry gets its own command. A user who runs the template once per listed line gets a silent exit 5 on the second value of a multi-valued key. That is harmless, because the first call removed both values, but it looks like a failure.

**Recommendation:** Change README to "each entry is named, followed by the `git config --file … --unset-all` command that removes it". Optionally add "(`--unset-all` removes every value of a key at once)" to the refusal.

#### F5. Two cosmetic leftovers: an unwrapped `dc_unwind` reason, and a revisit trigger that leaves out `claude.exe`

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:568`; `docs/decisions/037-bare-host-copy-install.md:93` (compare `:75`)
**Move:** 4 (message consistency) and 3 (documentation drift)
**Confidence:** High
**Legibility-target:** the user at the terminal; a decision 037 reader

Evidence:
```
install.sh:568  dc_unwind "the devcontainer config copied into $DEST differs from what the review showed (the stage changed after review, during the copy)."
037:75   … a token that is `claude` (or `claude.exe`) or ends in `/claude` …
037:93   if Claude Code's process shape changes (no token claude or .../claude, and none of the … paths CLAUDE_PROC_RE matches)
```
- **The reason line.** It prints as one ERROR line of about 150 characters plus the path (probe E). Every other ERROR in the file wraps at about 80 columns with 7-space continuations, and so did this message before b58d671.
- **The revisit trigger.** P2-A3's rewrite of the trigger lists the package paths but not the `claude.exe` token that `:75` names.

**Recommendation:** Pass the mismatch reason as two lines, since `dc_unwind`'s `<list>` argument already indents them, or shorten it to "the copies in $DEST differ from what the review showed." Add "(or claude.exe)" to the trigger.

## What Looks Good

- **P2-A3 is fixed everywhere.** Each of its six bullets was checked at 516124d:
  - 037:78 now counts "one per check (one to four per run, depending on the answers)".
  - The `vis_or_die` comment is accurate: `mode_diff` runs under `||`/`if !` at `:512` and `:924`, so errexit is off there.
  - 037's host bullet says "`~/.claude` by default" and adds the `denyWrite` caveat for a non-default destination.
  - plan:139 marks the lock timing as superseded.
  - The revisit trigger names the three package paths (apart from F5's `claude.exe`).
  - 037:33 and plan:252 count the progress line.
  I found no new drift from these edits.
- **P2-A4 is fixed, with no new drift.**
  - `--help` and README describe the refusal and its reach (both targets, before anything is staged; `git_state_gate` is the first call in `assemble`, `:320`).
  - The remedy works in every case probed (probe A).
  - The LFS warning is there.
  - `--help`'s "hooks and submodules are not refused; install.sh's git calls never run them" matches `repo_git` and T75/T76.
- **P2-A5 is documented consistently.** `--help` ("not writable is refused before the review, with exit 1, even when nothing would change"), README and 037's host bullet say the same thing, and T56 pins `--help` and README. The behaviour matches (probe B: exit 1 before the review). Only the message's trailer is off (F2).
- **The focus-2 user-visible changes:**
  - **Writable destination needed to review:** documented in all three places.
  - **`.cw-stage.*` after a killed run:** cleared by the next run, but undocumented (F3).
  - **`rev-parse HEAD` remedy:** consistent with the ERROR/trailer shape, runs no hook or fsmonitor, and still tells the user why (`unknown revision`), though less plainly than `git status`'s "No commits yet".
  - **P2-A2 message:** now says the previous config is gone. The wording is the same in `dc_unwind` and 037:68, and all three reasons (cp failure, link, mismatch) go through one function with one trailer. That closes pass-2 F9, apart from F1's path that bypasses it.
- **The link refusals share one vocabulary** across `extract_commit` and the three new sites. Each keeps its target's trailer.
- **`links_in` adopts the `<dir> <prefix> <name...>` shape** that pass-2 F7 recommended.
- **`repo_git` gathers the hardening in one place.** Every git call on the checkout goes through it, and its flags match the repo's earlier hardened wrapper.
- **Exit codes are unchanged.** Every new refusal exits 1.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `links_in` returns the last `find`'s status: a missing last item exits 1 silently; on `$DEST` this skips `dc_unwind` and leaves an altered `cc-isolated.sh` live (executed) | Inconsistent | `install.sh:650-654,563`; `037:68` | High |
| F2 | Unwritable-destination refusal uses the copy trailer, not `host_refuse`; T16 passes only because of it and no longer tests a copy failure; `:828` untested | Minor | `install.sh:794-803,828`; T16 | High |
| F3 | Killed run leaves `.cw-stage.*`/`.cw-new.*`; undocumented; `.cw-stage` links removed silently, `.cw-new` links refused | Informational | `install.sh:681,767-772,807` | High |
| F4 | README overstates "each entry is named with the command"; per-line remedy exits 5 on a repeated multi-valued key | Informational | `README.md:34-38` | High |
| F5 | `dc_unwind` mismatch reason is an unwrapped ~150-char line; revisit trigger drops `claude.exe` | Informational | `install.sh:568`; `037:93` | High |

## Overall Assessment

The pass-3 fixes close P2-A3, P2-A4 and P2-A5, and they keep install.sh's CLI conventions:
- The new names follow their neighbours.
- The link refusals share one shape.
- The P2-A2 message now tells the truth about the previous config.
- The new remedy command works for every entry kind the refusal lists.
- The writable-destination precondition is stated the same way in `--help`, README and 037.

The one merge-relevant item is F1. `links_in`, added by P2-R2, leaks `find`'s exit status through `set -e`, so a missing last item ends the run with no message. On the devcontainer `$DEST` site, that also skips the unwind that P2-A2 put in place: an altered launcher stays live, which contradicts 037:68. The fix is one line (`return 0`), and a test variant is cheap. F2 is a trailer and test-drift cleanup. F3–F5 are documentation polish.

## Goal-Alignment Note
- **Success criterion (restated):** "a markdown report saved to /workspace/docs/reviews/api-consistency-review-2026-09-25-copy-install-q058-pass3.md, per the skill."
- **What this report answers:** an API-consistency review of `f8d3f78..516124d`. Every finding carries Severity, Location, verbatim Evidence, Confidence and Legibility-target.
  - **Focus 1:** P2-A3, P2-A4 and P2-A5 are fixed in every doc. The remedy command was run (probe A). The only new drift is README's overstatement (F4).
  - **Focus 2:** the writable destination is documented (the trailer is off, F2). The killed-run leftover is undocumented (F3). The `rev-parse HEAD` remedy is fine. The P2-A2 message is fine, except for F1's bypass.
  - **Focus 3:** 12 audit rows, all consistent in naming. Two rows are inconsistent in behaviour or trailer (`links_in`, F1; the unwritable message, F2).
- **Out of scope:**
  - Whether `repo_git`'s flags and the git-state key list are enough as security controls.
  - The reach of F1's writer beyond the A1b model.
  - Test adequacy beyond T16 and the missing `:828` test.
  - Performance.
- **Escalate:**
  - **F1** should go to the security critic and be fixed before merge. Probe G shows the P2-A2 guarantee failing open in its own threat model, through a check P2-R2 added.
  - **F2** is Minor, but T16 now guards something different from what its name says.
  - No fact-check report was supplied for this pass. The claims above were run directly (probes A–G), but the other doc claims were not checked independently.
