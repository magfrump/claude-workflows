Commit: da700fa5
Loop-pass short-circuit: used at 12fcb61c

# Code Review Rubric

**Scope:** `docs/working/spike-cc-verify-q117.md` and its embedded host script; iteration 1 `22a4bb1f..12fcb61c`, iteration 2 (the final pass) the whole file at 190fa1a4 (fact-check) and 53770142 (critics) | **Reviewed:** 2026-10-15 | **Status: 🟡 CONDITIONAL PASS** — 2 amber item(s) awaiting resolution or justification (A17, A18); review stopped by instruction after the A16 check

## Run history

| Iteration | Commit | Fact-check | Critics | Outcome |
|---|---|---|---|---|
| 1 (`--loop-pass`) | 12fcb61c | k=1, opus: 33 claims, 5 Incorrect (3 behavioral) | security only (short-circuit; required by the brief): 1 Critical, 1 High, 6 Medium | 5 🔴, 9 🟡, fixed in 190fa1a4 |
| 2 (final, k=3) | 190fa1a4 → 53770142 | k=3, opus: 36-37 claims each, 4 Incorrect clusters (3 unanimous), 7 Mostly Accurate; agreement ≈ 89% | at 53770142: security (1 High, 3 Medium, 1 Info), performance (1 Medium, 2 Low, 1 Info), api-consistency (1 High-confidence Inconsistent, 1 Minor, 7 convention gaps) | fact-check findings fixed in 53770142; critic findings fixed in the next commit (see A-cap) |
| A-cap narrow pass | 53770142..2ea3498d | k=1, opus: 24 claims, 4 Incorrect (noclobber misses `>>` and links to FIFOs/devices; `image rm -f` deletes a moved pre-existing tag; commit F2 claim) | security: 1 Medium (append via planted symlink, reproduced), 1 Low, 4 Info | fixed in ccd00518 (xwrite/openlog, fd 3, `mv -T` stage, tag-aware teardown without `-f`, RETAG CHECK, `set +e` trap, `--clean` record check, `export -n SHELLOPTS`, script fingerprint) |
| A-cap pass 2 (one narrow check on the non-trivial fix) | 2ea3498d..ccd00518 | inline claims check: 17 claims, 4 Incorrect | security: 3 Medium (planted `snap-after` → xwrite renames into any dir; stage assembly follows swapped parent dirs, can delete main's config; hard link through xwrite), 1 Low, 4 Info | F1 (after-state in memory), F4, F6, F7 fixed in the next commit (trivial; matrix 25/25); F2/F3 open → A16 |
| A16 structural fix | 5a745059..da700fa5 | — | one narrow security check (opus): 1 Medium (tar writes through a directory it just created once it is swapped for a link; reproduced 4/4, clean pass 2/3 with a swap-back), 1 Low (`path_ok` window is the whole launcher call), 1 Medium/low-confidence (worst case of an in-run stage edit is host code execution; 037's equivalence needs `~/cc-verify` no more writable than the config dir), 1 Info (two matrix cases weak) | no code change (stop instructed); doc claims corrected, residuals recorded → A17, A18 |

Delivery mode: self-read (agents read the doc, the script and the code, and ran a copy of the stub harness). Skill deviations: agents read their SKILL.md from the repo themselves instead of having it pasted in. Iteration 2's critics reviewed 53770142, which included the fixes for that pass's fact-check findings, rather than 190fa1a4, so that the last review saw the final code. The merged fact-check report lists Verified clusters in a table instead of full claim sections.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | `git show … \| grep -qxF` under pipefail: SIGPIPE on install.sh (65,632 B) refused spuriously | Correctness | Incorrect (high), behavioral | FC1 claim 6 | step 2 | for-author | row 507 hint | Fixed (190fa1a4; old form failed 50/50-200/200 in iteration-2 replicates, new 0) |
| R2 | The verdict's `no-rotation` overwrote `fail` | Correctness | Incorrect (high), behavioral | FC1 claim 9a | step 9 | for-author | — | Fixed (190fa1a4) |
| R3 | A planted run record steered `--clean` to other projects' containers, volumes and any image | Security | Incorrect (high) / Medium | FC1 24b, security F4 | teardown | for-author | — | Fixed (190fa1a4 containers and volumes; 53770142 images) |
| R4 | The Dockerfile was not pinned: a base image's `devcontainer.metadata` could grant privileged | Security | Critical | security F1 | step 3 | for-author | — | Fixed (190fa1a4; final security pass: complete) |
| R5 | No pin to the reviewed tree | Security | High | security F2 | step 1 | for-author | row 509 hint | Fixed (190fa1a4 `EXPECT_BR` + five-path rule; final pass: complete) |
| R6 | A `~/cc-verify` writer plants a run record so the refusal lures the user into running a swapped `~/cc-verify/spike-q117.sh` | Security | High | security final F1 | paste / `--clean` fallback | for-author | — | Fixed (next commit: the script is passed to `bash -c` and never written to disk; the fallback is "re-paste with `--clean`"; `denyWrite` for `~/cc-verify` recommended in the doc) |
| R7 | The planted-record image path: the unanchored `*verify-<T8>*` tag rule with `-f` and no guard | Security | Incorrect (high), behavioral | FC2 claims 2-3 (unanimous) | teardown | for-author | — | Fixed (53770142: before-snapshot proof, `vsc-verify-<T8>` prefix, untag by name without `-f`) |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | A stage edit between the gate and the bless gets blessed | Security | Medium | security F3 | for-author | — | Fixed (190fa1a4) | — |
| A2 | `GH_TOKEN`/`OPENROUTER_API_KEY` forwarded into the branch container | Security | Medium | security F6 | for-author | — | Fixed (190fa1a4) | — |
| A3 | Unfiltered terminal output | Security | Medium | security F8, final F3 | for-author | — | Fixed (190fa1a4 relay; 53770142 the remaining three outputs indented; next commit `grep -q` for `initializeCommand`) | — |
| A4 | Verdict attested by the code under test | Security | Medium | security F5 | for-author | — | Acknowledged | Residual in the doc. Revisit trigger: if the spike's verdict is ever used as a merge gate for a branch nobody reviewed. |
| A5 | A leftover `VERIFY` `.git` | Security | Medium | security F7 | for-author | — | Acknowledged | Doc warning plus `--clean`. Revisit trigger: if a teardown is reported incomplete on the host. |
| A6 | The CHECK lines overclaimed the never-writes list | Docs | Incorrect | FC1 claim 3 | for-author | — | Fixed (190fa1a4) | — |
| A7 | Step-4 clone flags | Security | Incorrect | FC1 11b | for-author | — | Fixed (190fa1a4) | — |
| A8 | The zsh trailing comment | Correctness | Mostly accurate | FC1 29 | for-author | — | Fixed (190fa1a4; the paste now runs in bash, zsh, `zsh -i` and `bash -i`) | — |
| A9 | Iteration-1 wording items | Docs | Mostly accurate | FC1 | for-author | — | Fixed (190fa1a4) | — |
| A10 | Premature status line; `claude-home` always differs; the created table, the Not-verified list, "cannot reach ~/cc-verify" | Docs | Incorrect / Mostly accurate | FC2 claims 1, 4, 8-10 | for-author | — | Fixed (53770142) | — |
| A11 | `--clean` after a lost snapshot could remove a pre-existing image | Security | Mostly accurate | FC2 claim 5 | for-author | — | Fixed (53770142: the snapshot is kept after an incomplete teardown; no snapshot means nothing is removed) | — |
| A12 | Log and snapshot paths are predictable and were written through symlinks (executed: victim file overwritten) | Security | Medium | security final F2 | for-author | — | Fixed (next commit: `mkdir run-<RUN>.d`, `set -o noclobber`) | — |
| A13 | Step 8 re-read the stage's devcontainer.json after `check_manifest` | Security | Medium | security final F4 | for-author | — | Fixed (next commit: exec reads main's installed copy) | — |
| A14 | Statuses outside the documented set: a failing tar gave exit 2 ("rerun later") | API / Correctness | Inconsistent (High confidence) | api final F1 | for-author | — | Fixed (next commit: any status other than 0/1/130 or the verdict's 2 becomes 1 with `REFUSED: unexpected failure during step …`) | — |
| A15 | Another session's rebuild fails two CHECKs (false alarm, exit 1) | Performance | Medium | performance final F1 | for-author | — | Fixed (next commit: container and tag disappearances are NOTEs) | — |
| A-cap | The fixes for the final pass's critic findings landed after the final pass, at the 2-iteration cap | Process | — | orchestrator | for-author | — | Partly closed | The A-cap narrow pass (security + k=1 fact-check on 53770142..2ea3498d) reviewed them. Its findings were fixed in ccd00518, and one more narrow check reviewed ccd00518. Of that check's findings, F1, F4, F6 and F7 are fixed (trivial; matrix 25/25); F2 and F3 remain as A16. Not closed clean. |
| A16 | Directory swaps by a same-uid writer of `~/cc-verify` (A-cap pass 2 F2: stage assembly followed swapped `stage-*.raw/…`/`stage-*`, could delete main's config; F3: hard link through xwrite; 12b) | Security | Medium | security A-cap pass 2 | for-author | — | Fixed (da700fa5: fresh mode-700 run directory held as cwd with dev:ino checks, relative paths only, subtree `git archive` into identity-checked `tar -x -U` with no `mv`, O_EXCL + nlink/inode checks, inside-only `rm_inside`; both F2 swaps reproduced on 5a745059 and leave their victims untouched now) | — |
| A17 | `tar -x` follows a directory it just created once a racer swaps it for a link: the rest of that subtree (fixed names and contents from the merged tree) goes into any directory the user can write, `~/.claude` included; a swap-back still yields a clean pass. Same class untested for `git clone` into `src.git`/`VERIFY-*` | Security | Medium | A16 check F1 | for-author | — | 🟡 Open | Qualifying, revisit trigger: closed by `denyWrite ~/cc-verify` (the user's settings; the doc now says to add it or to run only while no agent that can write `~/cc-verify` is running), or by an O_NOFOLLOW-at-every-component extractor (listed for the cc-verify unit). Reopen if `~/cc-verify` is found writable from an agent sandbox. |
| A18 | Worst case of an in-run stage edit (after `check_manifest`, during the image build) is host code execution via `initializeCommand`/privileged `runArgs`; decision 037's equivalent window sits behind its agent gate, which the spike lacks. `path_ok` only proves the path at the moment before each call | Security | Medium (low confidence) | A16 check F2, F3 | for-author | — | 🟡 Open | Qualifying: same trigger and closure as A17 (`denyWrite ~/cc-verify`, or no agent able to write it running during the run); recorded in the doc's Residual risks with that worst case named. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Untested gate bypasses (BuildKit frontends, `RUN --network=host`, upload-pack config, `attr.tree` merge drivers); the Dockerfile pin closes the first two | security iteration 1 | Informational | for-author | — | Deferred (doc residuals) |
| C2 | devcontainer CLI image naming unverifiable here | FC1 claim 5 | Unverifiable | for-author | — | Deferred (host run) |
| C3 | A planted record plus a planted snapshot can untag a `vsc-verify-<8 hex>` image | security final F5 | Informational | for-author | — | Won't-Fix (doc residual; closed by `denyWrite`) |
| C4 | The BuildKit build cache is not cleaned or reported | performance final F2 | Low | for-author | — | Fixed (doc) |
| C5 | TERM to the script waits for the current step | performance final F3 | Low | for-author | — | Fixed (doc) |
| C6 | The second clone copies objects again (~1 s, 30 MB) | performance final F4 | Informational | for-author | — | Won't-Fix |
| C7 | Host-tool conventions: exit codes per row 58, `--help`, `ERROR:` prefixes, both `CLAUDE_DEVC_*` variables, line grammar, a `~/cc-verify` override | api final F2-F6, F9 | Minor | for-author | — | F4 Fixed (next commit), F6 partly (verdict `FAIL` upper-case); the rest Deferred to the `cc-verify` unit (doc section "Toward the cc-verify tool") |
| C8 | Not-verified #1 still described the old tag rule; "what to paste back" omitted the TEARDOWN lines | api final F7, F8 | Minor | for-author | — | Fixed (next commit) |
| C10 | fd 3 and xwrite descriptors are inherited by the launcher and the devcontainer CLI (trusted host code; not passed into containers, by reasoning) | security A-cap pass 2 F5 | Informational | for-author | — | Won't-Fix |
| C12 | Two matrix cases are weak evidence: the F2 raw-source case is vacuous on the new design (no raw dir), and the exported-SHELLOPTS case hits `readonly variable` and so does not set what it names | A16 check F4 | Informational | for-author | — | Acknowledged (doc says so) |
| C11 | "Cannot skip teardown" does not hold for SIGPIPE or a second Ctrl-C after the trap is reset | security A-cap pass 2 F8 | Informational | for-author | — | Deferred (doc says use `--clean` after an interrupted teardown) |
| C9 | The workspace checks out the checkout's HEAD branch unpinned; whether the CLI reads the workspace's `.devcontainer/` is unverified | security final (untested) | Informational | for-author | — | Deferred (host run; the launcher's image-provenance probe refuses a repo Dockerfile build) |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u2b1a2` / 2026-10-08 (row 507) | merge-tree exit status trusted | 🔴 → Defer (Q-133 [3]) | known issue | Hint only; not re-flagged. The spike's clone is complete, and R1 is a different trap. |
| `feat/build-loop-u2b1a2` / 2026-10-08 (row 509) | racing writer plants state in a gate repo | 🔴 → Defer (Q-133 [3]) | known issue | Same class as R5 and the git-config residual; recorded as a doc residual. |

This run appended one `Accepted-immutable` row (2026-10-15) for the commit-message Incorrects in 190fa1a4 and 12fcb61c, corrected in 53770142's body.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Main's launcher, run against the stage, executes no staged file and writes only under the stage (current and pre-Q-089 launcher) | ✅ Confirmed | `cc-isolated.sh:714-718` "CC_ISOLATED_DIR=… readlink -f … BASH_SOURCE"; tripwires in every staged script never fired; `find -newer` found nothing outside `~/cc-verify` (executed, 3 replicates) | FC2 claim 25 | for-orchestrator-synthesis |
| The Q-117 block is verbatim | ✅ Confirmed | `questions-archive.md:2463-2475`, `cmp` identical (executed) | FC1, FC2 | for-orchestrator-synthesis |
| A planted run record cannot reach other projects' containers or volumes | ✅ Confirmed | the project id is recomputed from `$VP/VERIFY-$T8`; planted records naming the harness's id left its container and volume (executed: FC2 r1-r3, security final) | FC2 claim 10, security final | for-orchestrator-synthesis |
| Every file:line citation in the step table lands | ✅ Confirmed | all three iteration-2 replicates | FC2 | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer (iteration 1 only) | loop-pass short-circuit | FC1 claims 6, 9a, 24b |
| api-consistency-reviewer (iteration 1 only) | loop-pass short-circuit | FC1 claims 6, 9a, 24b |

All core critics ran in iteration 2.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | teardown / `--clean` | FC1-24b, security F4, FC2-2/3/5, security final F1/F5 | distinct defects: steering by record (fixed), image tag rule (fixed), script-file lure (fixed), planted snapshot (residual); each states its own mechanism |
| 2 | step 3 / step 1 | security F1, F2 | distinct defects; one tree pin covers both for this branch |
| 3 | `on_exit` status / verdict | FC1-9a, api final F1 | distinct defects: the verdict overwrite (fixed) vs. statuses passing straight through (fixed); both concern exit 2 meaning "rerun later" |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
