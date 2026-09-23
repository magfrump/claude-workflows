Commit: d0fdd04

# Code Review Rubric

**Scope:** `ans/copy-install` `712c626..d0fdd04`, product files only (install.sh, README, guides, decisions 035/037, test/install-host.bats, test/link-claude-home-wiring.bats; 1,293 diff lines). Working docs were context only. | **Reviewed:** 2026-09-23 | **Status: 🔴 DOES NOT PASS** — 5 red item(s) unresolved

Pipeline:
- Fact-check k=3 (opus), merged most-severe-wins: 37 claims, agreement 77.8%.
- Stage 2.5: 6 submitted endorsement claims, claims 38–43.
- Critics (opus): security, performance, api-consistency; architecture-review; tech-debt-triage (advisory).
- Delivery: agents self-read a pre-assembled diff file (`self-read`), a deviation from inline-prefix delivery. Content is identical.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | Symlinks in the checkout pass the review as "(none)" and are installed into live `~/.claude` **as symlinks**. `assemble` uses `cp -r`, `review_diff` diffs through the link, and the install uses `cp -R`, which keeps links. A checkout `hooks/guard.sh` replaced by an absolute link to an agent-writable file (same bytes) reviewed as "(none — the destination already matches the repo)". The live hook then followed that file, so later edits changed it with no install run. This recreates the hazard decision 037 removes, and `denyWrite ~/.claude` does not stop it. Fix: fail `assemble` when `find "$stage" -type l` finds anything; today's payload has no links. | Security | High (executed) | security-reviewer #1 | `devcontainer-config/install.sh:110,145,399` — "cp -r \"$REPO_ROOT/$item\" \"$stage/$(basename \"$item\")\"" | for-author | — | 🔴 Unresolved |
| R2 | The staged snapshot is not re-checked after the review. A same-uid write to `$TMPDIR/cw-host-stage.*/payload` while `[y/N]` waits installs content the human never saw (probe run). Reachability for a sandboxed agent depends on whether the sandbox can write the human's `/tmp`, which was not established. Fix: stage under `$dest` (behind `denyWrite ~/.claude`), or hash the stage at review time and compare it after the prompt. | Security | High (reachability Medium) | security-reviewer #2 | `install.sh:333-335,386,399` — "HOST_TMP=\"$(mktemp -d \"${TMPDIR:-/tmp}/cw-host-stage.XXXXXX\")\"" | for-author | — | 🔴 Unresolved |
| R3 | `install.sh` can be rewritten in place while it waits at a prompt, and bash runs the new bytes. In the probe, the injected command ran after the human answered n to both targets, and git showed nothing because the file was reverted. This gets around decision 035's commit-time gate. The mechanism predates the branch, but the branch adds a second, longer prompt window. Fix: wrap the body in `main()` and end with `main "$@"; exit $?`. | Security | High (executed) | security-reviewer #3 | `install.sh:461-464` — "install_devcontainer\ninstall_claude_home\nexit \"$DECLINED\"" | for-author | — | 🔴 Unresolved |
| R4 | A failure, or a concurrent run, between move-aside and swap-in leaves live `~/.claude` without `hooks/`, `CLAUDE.md`, `skills` and the other entries. `.cw-new.*` copies are left beside them. The only output is mv's own error: no backup path, no recovery steps, and the target's "nothing was replaced" contract is broken. With `hooks/` gone, the wired guard hooks fail open (a missing wired hook is a non-blocking error). Two runs at the same time left `~/.claude` with none of the seven entries. The user's first real run is plan step 9, on the live `~/.claude`. Fix: one owner for the transaction, a lock, rollback from the backup on failure, and a message naming the backup dir. **Escalated 🟡→🔴**: convergence of security #5 and api-consistency F10, with executed corroboration (security probe; fact-check r1 and r2 reproduced it). | Reliability / Security | Medium (security), Inconsistent (api) | security-reviewer #5 + api-consistency F10 (+ tech-debt #1, architecture #2, fact-check escalations E2/E7) | `install.sh:423-437` — "mv \"$dest/$name\" \"$backup/$name\"" | for-author | — | 🔴 Unresolved |
| R5 | The review prints `REPLACE symlink … with a copy` for foreign per-file hook links that are only **moved** and get no copy. The README makes that line the migration contract, and the `WIRED in settings` warning lands only on the separate MOVE line for the same path. The WIRED check also matches only `hooks/<basename>`. The human reads a wrong description of what y will do. | Correctness (review output) | Incorrect (high), behavioral | Fact-check Claim 16 (k=3), security #7, api-consistency F4 (Convergence: fact-check + security + api) | `install.sh:349-353` | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | README (`:21-22`) and `--help` (`install.sh:42-43`) say the `~/.claude` target "only installs for a human at a terminal". `env -u CLAUDECODE script -qec … /dev/null` gets an agent past both checks, and the branch's own tests install this way. The code comment and decision 037 say it correctly ("stops accidents, not intent"). | Docs / Security | Incorrect (high), doc-only | Fact-check Claim 2; security #6; api F9; architecture #4 (the CLI contract is stated in three places that have drifted) | for-author | — | 🟡 Open | — |
| A2 | Commit 6793b79 says `installed_parent` records "script" under a pty wrapper. `script -qec "bash -c …"` records `bash`, and `SHELL=/bin/sh` records `sh`. `installed_by=host-tty` records a property the code doesn't establish. The audit trace decision 037 leans on can be evaded. | Docs / Audit | Incorrect (high), doc-only | Fact-check Claim 22; security #6; api F6; architecture #6 | for-author | — | 🟡 Open | — |
| A3 | The destination guard can be bypassed. `CLAUDE_HOME_DIR=<outside>/nx/../<repo>` (with `nx` nonexistent) passes because `resolve_phys` keeps the `..` in the unresolved tail. A y then moves the checkout's own entries into a backup inside the checkout. It needs a hand-crafted path; the default `~/.claude` is safe. | Security | Mostly Accurate (executed) | Stage-2.5 submitted Claim 39 (security endorsement, narrowed by fact-check) | for-author | — | 🟡 Open | — |
| A4 | The review diff passes raw control bytes from the checkout to the terminal, so a `\r` or CSI sequence can hide `+` lines from the human. Passthrough was executed; terminal rendering is inferred. Fix: pipe the review through `cat -v` or equivalent. | Security | Medium | security-reviewer #4 | for-author | — | 🟡 Open | — |
| A5 | `CLAUDE_HOME_DIR` is an install-only override that outranks `CLAUDE_CONFIG_DIR`, which link-claude-home and health-check use. The README doesn't mention it. | API consistency | Inconsistent | api-consistency F3 | for-author | — | 🟡 Open | — |
| A6 | Every accepted install moves a full ~2.4 MB copy of the old tree into `.claude-workflows-backup/<stamp>/`, even when the review said "(none)", and nothing prunes the copies. `scripts/claude_config_audit.py` walks `~/.claude` and treats `.md` there as policy files, so it re-scans every backup: after 5 installs, 77 → 457 files, 1.13 s → 6.80 s, 38 → 228 findings. Fix: return early when nothing changed, cap backups, and add the backup dir to the auditor's `SKIP_DIRS` (a file outside this diff). | Performance | Medium (executed) | performance-reviewer #1 (+ submitted Claim 42) | for-author | — | 🟡 Open | — |
| A7 | A first install into a destination without the entries prints the whole payload as a diff: ~32k lines, 2 MB. The REPLACE, MOVE and WIRED lines scroll out of view before the y/N prompt. The user's own migration is unaffected (258 lines). | Performance / UX | Medium (executed) | performance-reviewer #2 | for-author | — | 🟡 Open | — |
| A8 | A dangling symlink inside an owned dir (e.g. `hooks/`) aborts the whole host review with "could not diff payload item 'hooks' (diff exit 2)", and the error doesn't name the file. The README says the review lists every link and file. | Correctness / Docs | Mostly Accurate | Fact-check Claim 4 | for-author | — | 🟡 Open | — |
| A9 | The descriptions of what changed for existing users are inexact. Commit 1514518 says exit 2 is "the only observable change", but `-h/--help` also changed: it used to run the installer. A comment says the decline line "keeps its old wording", but it gained " (devcontainer config)". Decision 037 says "one extra line" and 6793b79 says "otherwise unchanged", but a blank line and the skip line were added. The comment says "unchanged apart from this one line". | Docs | Mostly Accurate ×5 | Fact-check Claims 8, 9, 13, 24, 33 | for-author | — | 🟡 Open | Commit-message claims (1514518, 6793b79) are immutable history if merged as is; fix the comment and decision text, and the override log gets `Accepted-immutable` rows for the commit messages at merge. |
| A10 | README says "everything replaced is moved to backup" (`.cw-new.*` leftovers and the rebuilt staging dir are exceptions). The content-diff comment's "(the checkout)" is imprecise. | Docs | Mostly Accurate ×2 | Fact-check Claims 5, 17 | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | **Possible shared root — needs adjudication** (composition cross-check, cluster 5). `assemble` stages the raw working tree with `cp -r`: symlinks (R1), git-ignored `__pycache__` (C2) and uncommitted edits (the dirty-checkout warning) all reach `~/.claude`. Staging from committed content (`git archive`/`git ls-files`) would address all three, but it changes what "the repo copy" means for a dirty checkout. That is a design call. | Composition cross-check (fragments: security #1, performance #3) | Composed (inherits High from R1; held at 🟢 as needs-adjudication) | for-author | — | 🟢 Open |
| C2 | Git-ignored `__pycache__` in the checkout is copied into `~/.claude`. Once Python recompiles it, the review never reports "(none)" again. | performance-reviewer #3 | Low | for-author | — | 🟢 Open |
| C3 | A `~/.claude` that is itself a symlink to a dir outside the checkout is written through, and the review doesn't say so. | security-reviewer #8 | Informational | for-author | — | 🟢 Open |
| C4 | A host-only install (decline target 1 per the README flow) always exits 1. | api-consistency F1 | Minor | for-author | — | 🟢 Open |
| C5 | `--yes` now means y for target 1 and skip target 2, and the run still exits 0. The skip message goes only to stdout. | api-consistency F2 | Minor | for-author | — | 🟢 Open |
| C6 | Unknown-argument handling has no `ERROR:` prefix and exits 2, while the sibling `cc-isolated.sh` exits 1. `-y` and trailing args now fail. | api-consistency F5 | Minor | for-author | — | 🟢 Open |
| C7 | Skip and abort lines hard-code `~/.claude` even when the destination is elsewhere. | api-consistency F7 | Minor | for-author | — | 🟢 Open |
| C8 | `.cw-new.<name>` breaks the `.claude-workflows-*` naming; target 1 and target 2 headers are asymmetric. | api-consistency F8, F11 | Informational | for-author | — | 🟢 Open |
| C9 | Shared helpers' abort path says "nothing was installed" when the host target calls it. A global `DECLINED` plus in-target `exit` blocks the third target decision 037 plans for. | architecture-review #1, #3 | Minor | for-author | — | 🟢 Open |
| C10 | Name derivation from `CLAUDE_HOME_SRC` is not pinned by a test (T6 hardcodes the seven names). | architecture-review #5 | Informational | for-author | — | 🟢 Open |
| C11 | install.sh is at 464/500 lines, and the fix wave will cross 500. A split creates a second host-run, agent-writable file, which must come under decision 035's trailer rule. | tech-debt-triage #2 | Defer and monitor | for-author | — | 🟢 Open |
| C12 | Two manifest producers and no reader; `need_script` should check that `script -qec` works so macOS/BSD skips instead of failing. | tech-debt-triage #3, #4 | Carry intentionally | for-author | — | 🟢 Open |
| C13 | The d0fdd04 fast-suite count (864 ok) is Unverifiable only because r3 didn't run it; r1 and r2 both reproduced it. | Fact-check Claim 36 | Unverifiable | for-orchestrator-synthesis | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| With the README's old link layout and the default destination, a y moves each old link into the backup still as a link, and no tracked checkout file's bytes or listing change. | ✅ Confirmed | FC submitted Claim 38 (executed): checkout checksums before and after a pty `n\ny` run; `install.sh:423-426` — "mv \"$dest/$name\" \"$backup/$name\"". Scope: default destination only (see A3 for a crafted one). | security-reviewer → fact-check | for-orchestrator-synthesis |
| `--yes`, piped or `/dev/null` stdin, and `CLAUDECODE` runs skip the host target before `mktemp`/`assemble`: no stage is created and the destination is unchanged. | ✅ Confirmed | FC submitted Claim 40 (executed, 8 runs incl. absent dest, old link layout, missing `TMPDIR`) | security-reviewer → fact-check | for-orchestrator-synthesis |
| After a successful y, `settings.json`, `settings.local.json`, `.credentials.json`, `projects/`, `memory/` and `logs/` are byte-identical. | ✅ Confirmed | FC submitted Claim 41 (executed). Scope: successful install only; not after a step-2/3 failure (R4). | security-reviewer → fact-check | for-orchestrator-synthesis |
| The commit verification numbers reproduce: install-host 24/24, cc-isolated-functions 90/90, link-claude-home-wiring 14/14, hooks 144/144; all 24 new tests fail against the old install.sh. | ✅ Confirmed | FC Claims (k=3, executed) | fact-check | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved. (R1–R4 were spot-grounded by the orchestrator against `install.sh:108-111,143-146,330-336,384-400,420-438,455-464`.)

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `install.sh:392-437` | FC E2/E7, security #5, api F10, tech-debt #1, arch #2 | distinct defects: every fragment already states the root (no rollback, lock or message); convergence recorded on R4 |
| 2 | `install.sh:345-362` | FC 16, security #7, api F4 | distinct defects: same defect stated completely by each; R5 |
| 3 | `README.md:21-22`, `install.sh:40-43` | FC 2, security #6, api F9, arch #4 | distinct defects: stated completely; A1 |
| 4 | `install.sh:410-447` | perf #1, api F6, FC 22, arch #6, tech-debt #3 | distinct defects: backup growth (A6) and manifest accuracy (A2) are separate mechanisms |
| 5 | `install.sh:97-119` (`assemble`) | security #1, perf #3 | needs adjudication → C1 |

---

To pass review, every 🔴 item must be resolved. Every 🟡 item must be fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
