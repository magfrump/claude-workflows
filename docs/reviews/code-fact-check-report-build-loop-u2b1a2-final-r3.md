Commit: 63ea50e7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1a2 (branch `feat/build-loop-u2b1a2`)
**Scope:** `git diff feat/build-loop-u2b1a1...HEAD` (HEAD 63ea50e7): `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, commit 63ea50e7's message, the plan's Script interface and D7 lines (`docs/working/plan-build-loop-handoff.md`, amended in U2b1a1, context) and the rubric `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md`. Final confirming pass, replicate r3 of 3.
**Checked:** 2026-10-08
**Total claims checked:** 39
**Summary:** 30 verified, 5 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The patterns about suite counts in commit messages (lines 28 and 30: "All 85 tests" and "mode1-equiv 33") are the nearest match to Claim 35. I counted those tests and ran the suites: this commit's counts are exact. None of this report's Incorrect verdicts names a symbol, API or option that does not exist, so nothing goes into the log.

Execution provenance (all runs under git 2.39.5, by this replicate, on 2026-10-08):
- Suites: `TMPDIR=$(mktemp -d /tmp/fcu2b1a2-r3-tmp-XXXX) timeout 1500 bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`. cwd: the worktree. Exit 0. Started 2026-10-08T18:58:59Z. Output: `/tmp/fcu2b1a2-r3-logs/suites.log`.
- Probes P1-P10: `timeout 300 bash pN.sh > pN.log`. cwd: `/tmp/fcu2b1a2-r3-probe`. Each script creates its own repo under `/tmp/fcu2b1a2-r3-probe/run-XXXX`, with the fixture's hermetic environment and `TMPDIR` inside it. Every script exited 0. Start times are in `/tmp/fcu2b1a2-r3-probe/pN.ts`: P1-P4 at 19:00:10-12Z, P5 at 19:00:53Z, P6-P7 at 19:01:21Z, P8 at 19:02:25Z, P9 at 19:02:50Z, P10 at 19:03:44Z. Output: `/tmp/fcu2b1a2-r3-probe/pN.log`. Scripts: `/tmp/fcu2b1a2-r3-probe/pN.sh` and `common.sh`.
- Mutants MA-MF: copies of `scripts/` and `test/` from `git archive HEAD` in `/tmp/fcu2b1a2-r3-mut/M?/`, each run with `bats -f <test title>`. MA: merge-tree in the real repository, without `cd "$GATE_TMP/work" && "${GATE_ENV[@]}"`. MB: the state gate moved after `main_by_name`. MC: MB without `GIT_ALLOW_PROTOCOL=none`. MD: MA without `GIT_ALLOW_PROTOCOL=none`. ME: harden without `core.commitGraph=false`. MF: the gate config without its `[extensions] objectformat` lines. Started 2026-10-08T19:02:02Z. Output: `/tmp/fcu2b1a2-r3-mut/mut.log`.
- No process of mine is still running (checked with `ps`).

---

## Claim 1a: R2 "Fixed: merge_result runs in a gate-owned repository (gate_repo, once per run) … The moved gitlink is now a conflict."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code at 63ea50e7. The probe uses a corrected plant whose merge base really holds the gitlink, so both sides move it. Under the real code, merge-tree reports "Failed to merge submodule sub (not checked out)" and nothing is fetched; mutant MD, which runs merge-tree in the real repository without GIT_ALLOW_PROTOCOL, fetches. This does not cover the test the note cites (Claim 1b).
**Legibility-target:** for-orchestrator-synthesis

The code runs merge-tree from the gate directory under GATE_ENV: `out="$(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?` (`scripts/build-loop.sh:463`). In P9, with the base sub1 at gitlink `aaaa…`, the real code printed `refuse …: feat/x conflicts with the default branch` and `fetched: no`. Run directly in the same gate layout, merge-tree printed `Failed to merge submodule sub (not checked out)`. Mutant MD printed `fetched: yes`.

**Evidence:** `scripts/build-loop.sh:448-466`; `/tmp/fcu2b1a2-r3-probe/p9.log`

---

## Claim 1b: R2 "Test: the P1 plant (mutant running merge-tree in the real repo fetches)."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:13`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the submodule test at `test/scripts/build-loop-check.bats:1394-1409`, run against mutants MA and MD. Whether the code fix itself holds is Claim 1a.
**Legibility-target:** for-author

The test at 63ea50e7 passes under mutant MA and under mutant MD. Both run merge-tree in the real repository, and MD also drops GIT_ALLOW_PROTOCOL. So no mutant that runs merge-tree in the real repo fails this test, and in this plant no upload-pack runs. The cause is the plant: `git update-index --add --cacheinfo "160000,$s1,sub"; commit_all sub1` (`test/scripts/build-loop-check.bats:1398`). `commit_all` is `git add -A && git commit …` (`test/lib/build-loop-fixtures.bash`), and `add -A` stages the gitlink's removal because no `sub/` directory exists. In P8 the merge base has no `sub` entry (`git ls-tree <base> sub` printed nothing). The merge is therefore an add/add of two gitlinks, and git stops at "Failed to merge submodule sub (no merge base)" before it opens any submodule repository. The test does not reach the path R2 names.

**Evidence:** `test/scripts/build-loop-check.bats:1394-1409`; `/tmp/fcu2b1a2-r3-mut/mut.log` (MA and MD: `ok 2 --check's merge opens no submodule repository…`); `/tmp/fcu2b1a2-r3-probe/p8.log`

---

## Claim 2: R3, R4, A6, A7, A8 and A9's Fixed notes

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:14-15,22-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what each note says the fix does: the origin/HEAD refusal (R3), GIT_CONFIG_GLOBAL (R4), the shallow refusal and the gate repository having no shallow file (A6), the commit-graph not being read (A7), no repo config in the gate repository (A8), and GIT_ALLOW_PROTOCOL stopping a fetch (A9). It does not establish that a forged commit-graph changes merge bases, which was the security reviewer's probe, and it does not cover the deferred parts (`--settings` and `--status` still follow origin/HEAD; config planted mid-run).
**Legibility-target:** for-orchestrator-synthesis

- R3: in P4, an origin/HEAD symref to refs/heads/feat/x printed `refuse state origin/HEAD: it names a branch other than origin/main or origin/master`, and one to origin/main printed ok.
- R4: in P1, an XDG `git/attributes` with `* merge=union`, plus XDG config and `~/.gitconfig` setting `core.attributesFile`, left the result at `refuse …: conflicts`. Plain merge-tree with the same files exited 0, a union merge.
- A6: the state test plants `.git/shallow`.
- A7: in P5, a garbage commit-graph made plain git print `error: improper chunk offset(s)`, while `--check` printed ok with no error.
- A9: in P3, `GIT_ALLOW_PROTOCOL=none git cat-file -p <missing>` printed `fatal: transport 'file' not allowed`, and the upload-pack mark was not created. The control run without it did create the mark.

**Evidence:** `scripts/build-loop.sh:158-166,192-201`; `/tmp/fcu2b1a2-r3-probe/p1.log`, `p3.log`, `p4.log`, `p5.log`

---

## Claim 3: A13 "Plan's --check interface line now states the duty for U2b1b"; A14 "Plan amended"

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of the plan text (Claims 6 and 7). It does not establish that U2b1b will carry out the duty.
**Legibility-target:** for-orchestrator-synthesis

The plan reads `U2b1b adds per-path lines and must make the exit status "every line ok"` (`docs/working/plan-build-loop-handoff.md:212`) and `` `--state` → `ok`, or `refuse state WHAT: WHY` `` (`:207`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:84,207,212`

---

## Claim 4: C11 "Global and system config apply to the gate repository … Fixed: GIT_CONFIG_GLOBAL for all calls"

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:43`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the global half (fixed) and the system half (still reaches every call, merge-tree included). It does not establish that a loop can write a system config: `/etc` is root-owned here, `/etc/gitconfig` is absent, and `touch /etc/gitconfig` was denied for uid 1000.
**Legibility-target:** for-orchestrator-synthesis

The finding names global and system config, but the fix covers only the global half. The script exports `GIT_CONFIG_GLOBAL=/dev/null` (`scripts/build-loop.sh:166`) and never sets `GIT_CONFIG_NOSYSTEM`. In P6, a system config (`GIT_CONFIG_SYSTEM`) setting `merge.directoryRenames = true` turned a directory-rename conflict into `ok … exit 0`. The same key in the repo config is refused: `refuse state merge.directoryrenames: set in config…`. In P1, a broken system config file stopped the script with `Not inside a git repository`, exit 1. The precise wording is: "Fixed for global config; system config still applies to every call, through a root-owned file or the caller's environment."

**Evidence:** `scripts/build-loop.sh:166`; `/tmp/fcu2b1a2-r3-probe/p6.log`, `p1.log`

---

## Claim 5: iteration-2 tests-and-mutants line "Mutants: merge-tree in the real repo (submodule and union tests fail)"

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:45`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the union-merge test and the submodule test against mutant MA at 63ea50e7. The other mutants on that line are covered as follows: no objectformat (SHA-256 test, mutant MF) fails as stated, no core.commitGraph pair (shim, ME) fails, and the gate moved after resolve_main (MB) fails the partial-clone test. The line's "no GIT_ALLOW_PROTOCOL (shim)" and "no shallow (state test)" mutants were not re-run.
**Legibility-target:** for-author

Under MA, `not ok 1 --check's merge reads no checkout attributes…` but `ok 2 --check's merge opens no submodule repository…`. Only the union test fails. The reason is Claim 1b.

**Evidence:** `/tmp/fcu2b1a2-r3-mut/mut.log`; `test/scripts/build-loop-check.bats:1266-1273,1394-1409`

---

## Claim 6: D7 "with a state gate after `devcontainer-config/install.sh`'s `git_state_gate`"

**Location:** `docs/working/plan-build-loop-handoff.md:84`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the path and the function's existence. It does not compare the two gates' key lists.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/install.sh:209` reads `git_state_gate() {`. There is no root-level `install.sh` (`ls install.sh`: no such file).

**Evidence:** `devcontainer-config/install.sh:209,332`

---

## Claim 7: the Script interface lines for `--state` and `--check`

**Location:** `docs/working/plan-build-loop-handoff.md:207,212`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--check` output grammar (`refuse state WHAT: WHY` lines with exit 2 before any brief, then `ok BRIEF TIP TREE`, `refuse BRIEF: WHY` or `skip BRIEF: WHY`) against the code and the suite. `--state` is U3b's and is not built yet, so only its reference to `state_gate`'s lines is checked.
**Legibility-target:** for-orchestrator-synthesis

Line 212 reads: `` Output (U2b1a): `refuse state WHAT: WHY` lines (exit 2 before any brief), then per brief `ok BRIEF TIP TREE`, `refuse BRIEF: WHY` or `skip BRIEF: WHY` ``. The code prints exactly these forms (`scripts/build-loop.sh:189,477-487`), and the state test pins them.

**Evidence:** `scripts/build-loop.sh:181-203,470-488,499-510`; `/tmp/fcu2b1a2-r3-logs/suites.log`

---

## Claim 8: header --check state-gate list: "a git config key … for a filter, include, config hook, merge or diff setting, core.fsmonitor, core.attributesFile, core.hooksPath, gpg.*, log.showSignature, extensions.partialClone or remote.*.promisor (a partial clone), a non-empty info/attributes or info/grafts, or a replace ref prints 'refuse state WHAT: WHY'"

**Location:** `scripts/build-loop.sh:78-85`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --help list against state_gate's checks. It does not establish completeness against every git setting that can change a read.
**Legibility-target:** for-author

Each item the list names is refused. The list omits two refusals the code makes: a non-empty `shallow` (`for f in info/attributes info/grafts shallow; do`, `:192`) and an origin/HEAD naming anything but origin/main or origin/master (`:198-201`). The state test asserts both lines: `refuse state shallow: present and not empty` and `refuse state origin/HEAD: …` (`test/scripts/build-loop-check.bats:1337-1341`). The commit message and the plan name both of them. The precise list adds "a non-empty shallow, an origin/HEAD naming any branch but origin/main or origin/master".

**Evidence:** `scripts/build-loop.sh:78-85,192-201`; `test/scripts/build-loop-check.bats:1331-1341`

---

## Claim 9: header ok/refuse/skip lines and the per-brief order

**Location:** `scripts/build-loop.sh:85-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line forms, the argument order, the refuse reasons check_line emits, and "As --status skips it". It does not establish that TREE always is the merge of TIP, because a missing object yields ok with another tree (Claim 26).
**Legibility-target:** for-orchestrator-synthesis

The loop is `for a in "${ARGS[@]}"; do out="$(check_line "$a")"; printf '%s\n' "$out"` (`:503-505`). Every refuse text in `check_line` (`:477-487`) matches a listed reason. T18 checks three briefs printed in argument order, and it checks the skip line copied from status_line.

**Evidence:** `scripts/build-loop.sh:470-488,499-510`; `test/scripts/build-loop-check.bats:1295-1313`

---

## Claim 10: "Writes nothing but --check's merge objects (merge-tree writes the merged trees and blobs into the object store) and its own temporary directory, removed at exit."

**Location:** `scripts/build-loop.sh:102-104`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one clean `--check` run in P2. It does not cover a conflicting merge (C9 notes it writes objects as well) or runs killed by a signal that skips the EXIT trap.
**Legibility-target:** for-orchestrator-synthesis

In P2, the run's only new file under `.git` was `.git/objects/53/fa2bb…` (the merged tree), and no existing `.git` file changed after the stamp. `$TMPDIR` was empty afterwards, consistent with `trap 'rm -rf -- "$GATE_TMP"' EXIT` (`:501`).

**Evidence:** `scripts/build-loop.sh:499-510`; `/tmp/fcu2b1a2-r3-probe/p2.log`

---

## Claim 11: "Exit: 0 every line printed (or help), and for --check every line ok; 2 any --check line or the state gate not ok; 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:107-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check`'s exits 0, 2 and 1 (usage) as the suite asserts them, and `gate_repo`'s failure exit (`exit 2`, `:502`). It does not cover U2b1b's per-path lines.
**Legibility-target:** for-orchestrator-synthesis

The code has `[[ "$out" == "ok "* ]] || fails=1` and `[[ "$fails" -eq 0 ]] || exit 2` (`:506-508`), and `state_gate || exit 2` (`:209`). T17 asserts `[ "$status" -eq 1 ]` for each usage error.

**Evidence:** `scripts/build-loop.sh:209,499-510`; `/tmp/fcu2b1a2-r3-logs/suites.log`

---

## Claim 12: "Every git call in this process, the lib's included, runs hardened."

**Location:** `scripts/build-loop.sh:147`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git call a clean `--check` run makes, including the lib's calls and merge-tree under `env` (GATE_ENV keeps `GIT_CONFIG_*`), as logged by the PATH shim. It does not cover `--settings` and `--status` runs (harden runs before the mode split, so they read the same way) or git's internal subprocesses.
**Legibility-target:** for-orchestrator-synthesis

`harden` runs at top level before `ROOT="$(git rev-parse --show-toplevel …)"` (`:165,204`). The outer pre-scrub process exits in `scrub_reexec` before any git call (`scripts/lib/dev-cycle-read.sh:115-120`). A grep of the lib for `env -u`, `GIT_CONFIG` and `GIT_DIR` finds no git call that overrides the environment (paraphrased — no quote available because the claim covers absence of matching grep results). Mutant ME, without `core.commitGraph=false`, fails the shim test with `a call without core.commitGraph=false`.

**Evidence:** `scripts/build-loop.sh:158-166`; `test/scripts/build-loop-check.bats:1371-1383`; `/tmp/fcu2b1a2-r3-mut/mut.log`

---

## Claim 13: "GIT_CONFIG_GLOBAL=/dev/null: a loop can write the user's ~/.gitconfig as easily as .git/config."

**Location:** `scripts/build-loop.sh:151-152`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `~/.gitconfig` and `$XDG_CONFIG_HOME/git/config` being ignored, and XDG attributes being off through the `core.attributesFile=/dev/null` pair. It does not cover the system config (Claim 4).
**Legibility-target:** for-orchestrator-synthesis

In P1, XDG and global files that make plain merge-tree union-merge (exit 0) left `--check` at `refuse …: conflicts`, exit 2.

**Evidence:** `scripts/build-loop.sh:166`; `/tmp/fcu2b1a2-r3-probe/p1.log`

---

## Claim 14: "GIT_ALLOW_PROTOCOL=none: no transport at all, so a lazy fetch (a partial clone's missing object) fails however the config was planted, even after the state gate read it."

**Location:** `scripts/build-loop.sh:152-154`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `file` transport for a superproject promisor (P3) and a submodule promisor (P9, mutant MA). It does not test the ssh, http or ext transports, which the same allowlist blocks.
**Legibility-target:** for-orchestrator-synthesis

P3 printed `fatal: transport 'file' not allowed` and `fetched mark: no`; the control printed `fetched mark: yes`. In P9, mutant MA (merge-tree in the real repo, GIT_ALLOW_PROTOCOL kept) printed `fetched: no`; MD, without it, printed `fetched: yes`.

**Evidence:** `scripts/build-loop.sh:166`; `/tmp/fcu2b1a2-r3-probe/p3.log`, `p9.log`

---

## Claim 15: "no commit-graph (a forged one changes merge bases)"

**Location:** `scripts/build-loop.sh:150-151`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the commit-graph file not being read by any `--check` call. It does not re-run a forged graph that changes a merge base; rubric A7 records the security reviewer's probe of that.
**Legibility-target:** for-orchestrator-synthesis

In P5, a garbage commit-graph made plain `git rev-list` and `merge-tree` print `error: improper chunk offset(s) ffffffffffffffff…`. `--check` printed only `ok … 603f270e…`, exit 0, with stderr merged into the log.

**Evidence:** `scripts/build-loop.sh:160`; `/tmp/fcu2b1a2-r3-probe/p5.log`

---

## Claim 16: "What the rest cannot switch off, --check's state gate refuses."

**Location:** `scripts/build-loop.sh:156-157`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers repo-local config, the git-dir files the gate lists, and global config. It does not cover the system config file, which is neither switched off nor refused, or the object-store files (alternates, multi-pack-index) under deferred F3.
**Legibility-target:** for-orchestrator-synthesis

The system config is outside both mechanisms. No pair or export disables it (`:160,166`), and state_gate reads only `config` and `config.worktree` (`:183`). P6 shows it changing the merge result. It is root-owned here, and the `GIT_CONFIG_SYSTEM` route is the caller's environment, which the comment trusts. A precise version adds "(the system config, root-owned, is trusted like the caller's environment)".

**Evidence:** `scripts/build-loop.sh:156-157,166,183`; `/tmp/fcu2b1a2-r3-probe/p6.log`

---

## Claim 17: state_gate comment: "repo-local git state that can make the gate's git run a command or change what it reads, which harden does not switch off … Keys …: filter, merge and diff drivers (commands), config hooks, includes, core.attributesFile, gpg and log.showSignature …, and a partial clone"

**Location:** `scripts/build-loop.sh:167-175`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment's key list against `STATE_KEYS_RE`. It does not judge whether the regex is complete.
**Legibility-target:** for-author

The regex is broader than "merge and diff drivers": `'^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'` (`:180`) refuses every `merge.*` and `diff.*` key. The test plants `merge.renormalize` and `diff.ignoreSubmodules`, and P6 shows `merge.directoryrenames` refused. The comment's key list omits `core.fsmonitor` and `core.hooksPath`, which the regex refuses. It also says the state is what "harden does not switch off" and then lists `core.attributesFile`, which harden does pair (`core.attributesFile=/dev/null`, `:160`); core.fsmonitor and core.hooksPath are paired as well. A precise version reads "every filter, merge and diff key, …, core.fsmonitor, core.attributesFile, core.hooksPath (refused although harden pairs them)…".

**Evidence:** `scripts/build-loop.sh:160,167-180`; `test/scripts/build-loop-check.bats:1317-1319`

---

## Claim 18: state_gate "reads no object (git config --file --no-includes follows no include; --git-path reads no index)" and "--check refuses planted state before any git call reads an object (resolve_main does)"

**Location:** `scripts/build-loop.sh:169-171,208-209`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the calls state_gate makes (`rev-parse --git-path`, `git config --file`, `for-each-ref refs/replace/`, `symbolic-ref`) and its place before resolve_main. It does not establish that repository setup reads no config: rev-parse and the others read the repo config with includes, as any git call does.
**Legibility-target:** for-orchestrator-synthesis

In P4, with `.git/objects` replaced by an empty store and `info/grafts` planted, `--check` printed exactly `refuse state info/grafts: present and not empty` and exit 2, with no git error. A refs/replace ref naming a missing object is still listed (P10: `refuse state refs/replace: 1 replace ref(s)`). Mutants MB and MC, with the gate after main_by_name, fail the partial-clone test: their output is `build-loop.sh needs a default branch found by name…`, exit 1.

**Evidence:** `scripts/build-loop.sh:181-203,208-212`; `/tmp/fcu2b1a2-r3-probe/p4.log`, `p10.log`; `/tmp/fcu2b1a2-r3-mut/mut.log`

---

## Claim 19: state_gate's files and the origin/HEAD rule ("an origin/HEAD naming any branch but origin/main or origin/master (resolve_main would take the default branch from it)")

**Location:** `scripts/build-loop.sh:175-179,192-201`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed file, the replace refs, and an origin/HEAD symref to origin/main (allowed), to refs/heads/feat/x (refused) and to a remote branch (refused, test). It does not cover a non-symbolic origin/HEAD, which passes (P4: ok); resolve_main ignores that one too, since it reads `git symbolic-ref --quiet --short refs/remotes/origin/HEAD`.
**Legibility-target:** for-orchestrator-synthesis

resolve_main does take the default branch from origin/HEAD: `[[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")` (`scripts/lib/dev-cycle-read.sh:487-488`, read in full to `:506`). The `[[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]` test (`:194`) refuses non-empty files, symlinks and non-files, a superset of "non-empty".

**Evidence:** `scripts/build-loop.sh:192-201`; `scripts/lib/dev-cycle-read.sh:483-506`; `/tmp/fcu2b1a2-r3-probe/p4.log`

---

## Claim 20: state_gate "Prints one 'refuse state WHAT: WHY' line per finding, returns 1 on any"

**Location:** `scripts/build-loop.sh:169-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the finding lines. It does not cover the early `return 1` cases: a path that cannot be resolved, or a missing config, stops after its own line and does not list later findings.
**Legibility-target:** for-orchestrator-synthesis

Each `echo` in the function begins `refuse state ` (`:184-200`). The state test asserts five lines from one run and one line per key.

**Evidence:** `scripts/build-loop.sh:181-203`; `test/scripts/build-loop-check.bats:1315-1342`

---

## Claim 21: gate_repo: "a git dir with no config but the repo's object format, no modules/, info/ or shallow, and an empty directory to run in, so merge-tree reads none of the repo's config (a submodule repository under .git/modules is never opened)"

**Location:** `scripts/build-loop.sh:439-444`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate directory's contents and the submodule case with a correct plant (P9). It does not cover the system config, which merge-tree still reads (Claim 4).
**Legibility-target:** for-orchestrator-synthesis

The code is `mkdir "$GATE_TMP/git" "$GATE_TMP/git/refs" "$GATE_TMP/work"`, then `printf 'ref: refs/heads/none\n' > "$GATE_TMP/git/HEAD"` and a config holding only `repositoryformatversion = 1` and `objectformat = %s` (`:453-455`). Mutant MF, without the objectformat lines, fails the SHA-256 test (`refuse …: the merge of feat/x could not be computed`). P9's direct run in this layout printed `Failed to merge submodule sub (not checked out)`.

**Evidence:** `scripts/build-loop.sh:448-457`; `/tmp/fcu2b1a2-r3-probe/p9.log`; `/tmp/fcu2b1a2-r3-mut/mut.log`

---

## Claim 22: "no checkout's .gitattributes (git 2.39 reads one from the current directory even under --work-tree)"

**Location:** `scripts/build-loop.sh:443-444`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's merge-tree reading `.gitattributes` from the current directory when given `--git-dir` and `--work-tree` elsewhere, and the gate running from an empty directory. It does not establish other git versions' behaviour.
**Legibility-target:** for-orchestrator-synthesis

In P3, run from a directory holding `* merge=union`, `git --git-dir=… --work-tree=<other> merge-tree` exited 0 (a union merge). From an empty directory it exited 1. Mutant MA fails the union-merge test.

**Evidence:** `scripts/build-loop.sh:463`; `/tmp/fcu2b1a2-r3-probe/p3.log`; `/tmp/fcu2b1a2-r3-mut/mut.log`

---

## Claim 23: "and only the repo's object store (GIT_OBJECT_DIRECTORY, where it also writes)"

**Location:** `scripts/build-loop.sh:444-445`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reads and writes of objects. It does not cover rewritten object bytes (deferred F3, override row 2026-10-08).
**Legibility-target:** for-orchestrator-synthesis

merge-tree writes there (P2: the one new file is `.git/objects/53/…`). It also follows the store's `objects/info/alternates`. In P2, a branch whose tree exists only in another repository, named through that file, gave `ok … 53fa2bb…`, a merged tree holding that repository's `alt.txt`. It also reads the store's multi-pack-index: in P7 a garbage `multi-pack-index` made `--check` print `error: improper chunk offset(s)` five times on stderr and still answer ok. Every other gate call reads the same store, so the gate is consistent. Still, "only the repo's object store" reads as excluding other directories, and the alternates file can name any directory. A precise version reads "the repo's object store and any alternates it lists".

**Evidence:** `scripts/build-loop.sh:453,456`; `/tmp/fcu2b1a2-r3-probe/p2.log`, `p7.log`

---

## Claim 24: "GATE_ENV unsets the repo-local variables (GIT_COMMON_DIR and the like) that would point it back."

**Location:** `scripts/build-loop.sh:445-446,451`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the variables `git rev-parse --local-env-vars` lists in git 2.39.5: all of them are unset except `GIT_CONFIG`, `GIT_CONFIG_PARAMETERS`, `GIT_CONFIG_COUNT` and `GIT_NO_REPLACE_OBJECTS`, which are kept on purpose. GIT_DIR and GIT_OBJECT_DIRECTORY are then set again. It does not establish behaviour under an inherited `GIT_CONFIG_PARAMETERS`, the caller's own `git -c`, which the harden comment trusts.
**Legibility-target:** for-orchestrator-synthesis

The code is `for v in $(git rev-parse --local-env-vars); do [[ "$v" == GIT_CONFIG* || "$v" == GIT_NO_REPLACE_OBJECTS ]] || GATE_ENV+=(-u "$v"); done` (`:451`), then `GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")` (`:456`). The list includes GIT_COMMON_DIR, GIT_WORK_TREE, GIT_INDEX_FILE, GIT_GRAFT_FILE, GIT_SHALLOW_FILE and GIT_ALTERNATE_OBJECT_DIRECTORIES.

**Evidence:** `scripts/build-loop.sh:448-457`

---

## Claim 25: merge_result "returns 1 on a conflict (a gitlink both sides moved is one, since no submodule repository is reachable)"

**Location:** `scripts/build-loop.sh:458-460`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a text conflict (T16) and a gitlink both sides moved from a common base (P9). The suite's own submodule test does not reach this case (Claim 33).
**Legibility-target:** for-orchestrator-synthesis

The code is `[[ "$rc" -eq 0 ]] || return 1` after the hex check (`:465`). P9 printed `refuse …: feat/x conflicts with the default branch`.

**Evidence:** `scripts/build-loop.sh:461-467`; `/tmp/fcu2b1a2-r3-probe/p9.log`

---

## Claim 26: merge_result "… 2 when git failed" (and the header's refuse reason "or the merge could not be computed"; "TREE is the merge of TIP into main")

**Location:** `scripts/build-loop.sh:460`, `scripts/build-loop.sh:89-90,96`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a branch tip whose tree object cannot be read. It does not cover rewritten bytes (deferred F3) or how U2b1b's per-path rules would judge the resulting tree.
**Legibility-target:** for-orchestrator-synthesis

merge_result keys failure on git's exit status alone, and stderr is discarded: `… merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?` (`:463`). The next line is `[[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2` (`:464`). When the tip's tree is missing, git 2.39.5's merge-tree prints `error: Could not read 052f6cb…` and still exits 0 with a tree. In P2, `--check` with the alternates file removed printed `ok docs/working/briefs/2026-10-01-x.md 80d9b89… 2795b1c5…`, exit 0. That tree holds only `main.txt`: the branch's side is read as empty, so the brief is deleted. It is not the merge of TIP. status_line never reads the tip's tree (check_branch reads the commit, the count and the date), so nothing earlier refuses it. A same-uid loop can reach this by deleting an object file or writing a commit that names an absent tree.

**Evidence:** `scripts/build-loop.sh:461-467`; `scripts/lib/dev-cycle-read.sh:436-454`; `/tmp/fcu2b1a2-r3-probe/p2.log`. A direct `git merge-tree` reproduction in the P2 repo printed the error with rc 0; it was run at the prompt and its output is quoted above.

---

## Claim 27: check_line "ok BRIEF TIP TREE, or one skip or refuse line (from status_line, then the gate's own reasons)" and its refuse reasons and order

**Location:** `scripts/build-loop.sh:468-488`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order: status_line's non-ok line (always a `skip`), then not open, absent, moved or unreadable, not ahead, `--expect` mismatch, and the merge. It does not establish atomicity between the two check_branch reads.
**Legibility-target:** for-orchestrator-synthesis

The field read `read -r _ _ st _ br loop sha _ <<<"$out"` (`:474`) matches status_line's `echo "ok $a $st $pol $br $loop $sha $date $disp$reason"` (`:435`). Every non-ok line status_line prints begins `skip` (read in full, `:400-436`). T16, T17 and T18 pass.

**Evidence:** `scripts/build-loop.sh:400-436,470-488`; `/tmp/fcu2b1a2-r3-logs/suites.log`

---

## Claim 28: "The full id only: a short id, a branch name or HEAD would let git pick the commit."

**Location:** `scripts/build-loop.sh:134-135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser's acceptance of lower-case 40- or 64-hex only, as T17 asserts. EXPECT is compared as a string (`"$sha" != "$EXPECT"`), never passed to git.
**Legibility-target:** for-orchestrator-synthesis

The check is `[[ "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || usage …` (`:135`).

**Evidence:** `scripts/build-loop.sh:129-141,481`; `test/scripts/build-loop-check.bats:1275-1293`

---

## Claim 29: test "--check's merge reads no checkout attributes: an untracked .gitattributes, or one planted in .git, cannot turn a conflict into a union merge"

**Location:** `test/scripts/build-loop-check.bats:1266-1273`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test failing under mutant MA. It does not separate which of the two plants drives the failure.
**Legibility-target:** for-orchestrator-synthesis

MA printed `not ok 1 --check's merge reads no checkout attributes…`.

**Evidence:** `/tmp/fcu2b1a2-r3-mut/mut.log`

---

## Claim 30: test "--check's state gate refuses each planted git state that can run a command or change the merge, before reading any brief"

**Location:** `test/scripts/build-loop-check.bats:1315-1342`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the 16 keys, config.worktree and the five file or ref plants, each asserted by its exact output. "Before reading any brief" is asserted only as the brief's line being absent.
**Legibility-target:** for-orchestrator-synthesis

The test asserts `[ "${#lines[@]}" -eq 1 ]` for each key and the exact five-line output for the file plants. It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1315-1342`; `/tmp/fcu2b1a2-r3-logs/suites.log`

---

## Claim 31: test "--check refuses a partial clone before any object is read: a promisor remote's upload-pack never runs for a missing object"

**Location:** `test/scripts/build-loop-check.bats:1356-1369`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of the gate: mutants MB and MC fail on the output assertion. Since GIT_ALLOW_PROTOCOL=none, the upload-pack assertion no longer separates the gate's order from the transport block, so the output assertion carries the test.
**Legibility-target:** for-orchestrator-synthesis

MB and MC printed `not ok 1 …` with `1  build-loop.sh needs a default branch found by name…`.

**Evidence:** `/tmp/fcu2b1a2-r3-mut/mut.log`

---

## Claim 32: test "every git call --check makes carries harden's config pairs (core.hooksPath=/dev/null among them), no global config and no transport"

**Location:** `test/scripts/build-loop-check.bats:1371-1383`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shim catching a missing pair (mutant ME). It does not cover git calls that bypass PATH (none found).
**Legibility-target:** for-orchestrator-synthesis

ME printed `# a call without core.commitGraph=false`.

**Evidence:** `/tmp/fcu2b1a2-r3-mut/mut.log`

---

## Claim 33: test "--check's merge opens no submodule repository: a promisor one under .git/modules never fetches, and the moved gitlink is a conflict"

**Location:** `test/scripts/build-loop-check.bats:1394-1409`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the test exercises its title. Whether the code holds is Claims 1a and 25.
**Legibility-target:** for-author

The test does not test what its title says. `commit_all sub1` (`:1398`) runs `git add -A`, which unstages the gitlink, so the merge base has no `sub`. The merge then stops at "(no merge base)" without opening any submodule repository. It passes under mutant MA and under MD, which has no GIT_ALLOW_PROTOCOL either. With the base holding the gitlink (P9: `git add .gitmodules; …; git commit -q -m sub1`), MD fetches. Even with that plant, while GIT_ALLOW_PROTOCOL=none is in place the "never fetches" assertion would not tell gate_repo's isolation from the transport block. Only the merge-tree message ("not checked out") or a mutant run without GIT_ALLOW_PROTOCOL tells them apart.

**Evidence:** `test/scripts/build-loop-check.bats:1394-1409`; `/tmp/fcu2b1a2-r3-probe/p8.log`, `p9.log`; `/tmp/fcu2b1a2-r3-mut/mut.log`

---

## Claim 34: test "--check merges in a SHA-256 repository: TIP and TREE are 64-hex"

**Location:** `test/scripts/build-loop-check.bats:1411-1416`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the object-format line (mutant MF fails). TREE's length is checked through equality with git's own 64-hex output, not by a length test.
**Legibility-target:** for-orchestrator-synthesis

MF printed `refuse …: the merge of feat/x could not be computed`, status 2.

**Evidence:** `/tmp/fcu2b1a2-r3-mut/mut.log`

---

## Claim 35: "Suites: build-loop-check 91, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2."

**Location:** commit 63ea50e7 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and the pass of each suite at 63ea50e7. It does not cover other suites.
**Legibility-target:** for-automated-gate

`grep -c '^@test'` gives 91, 19, 78, 2 and 2. The run printed `ok 192 …` with no `not ok` lines, exit 0. This checks the prior hallucination patterns at lines 28 and 30; here the counts are exact.

**Evidence:** `test/scripts/build-loop-check.bats`; `/tmp/fcu2b1a2-r3-logs/suites.log`

---

## Claim 36: "330 code lines against U2b1a1."

**Location:** commit 63ea50e7 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the given command's numstat, added plus deleted. Counting additions alone gives 316.
**Legibility-target:** for-automated-gate

`git diff --numstat feat/build-loop-u2b1a1...HEAD -- ':(top)' ':(top,exclude)docs/'` prints `165 11 scripts/build-loop.sh` and `151 3 test/scripts/build-loop-check.bats`: 165+11+151+3 = 330.

**Evidence:** command output at the prompt (cwd: the worktree, exit 0)

---

## Claim 37: "Its code, tests and review history are feat/build-loop-u2b1a at c66988b6 (iterations 1-2; rubric …)"

**Location:** commit 63ea50e7 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers scripts/, test/ and docs/reviews/, which are byte-identical. HEAD differs from c66988b6 only in `docs/working/plan-build-loop-handoff.md` (+1) and `docs/working/questions.md`.
**Legibility-target:** for-orchestrator-synthesis

`git diff --stat c66988b6 HEAD -- scripts test` and `-- docs/reviews` print nothing. The whole-tree stat lists only the two docs/working files.

**Evidence:** command output at the prompt (cwd: the worktree, exit 0)

---

## Claim 38: the commit's bullets: harden, state_gate before resolve_main, gate_repo and merge_result ("so no checkout attributes, repo config or submodule repository reach the merge"), check_line, the test list, and "security F3 … deferred with an override row"

**Location:** commit 63ea50e7 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against the code (Claims 12-27) and the override row for F3 (`docs/reviews/override-log.md`, 2026-10-08, "Rewriting a loose object's bytes…", Defer). It does not establish that the listed submodule plant exercises its path (Claim 33).
**Legibility-target:** for-orchestrator-synthesis

The facts are as Claims 12-27 found them. Every named test exists at `test/scripts/build-loop-check.bats:1256-1416`.

**Evidence:** `scripts/build-loop.sh:147-210,439-510`; `docs/reviews/override-log.md:492`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1b** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:13`): R2's "Test: the P1 plant (mutant running merge-tree in the real repo fetches)" is false at 63ea50e7. The submodule test passes under that mutant.
- **Claim 5** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:45`): "merge-tree in the real repo (submodule and union tests fail)" is false. Only the union test fails.
- **Claim 26** (`scripts/build-loop.sh:460,464`): "2 when git failed" is false. merge-tree exits 0 after `error: Could not read <tree>`, and `--check` prints `ok` with a tree that is not the merge of TIP.
- **Claim 33** (`test/scripts/build-loop-check.bats:1394-1409`): the submodule test's `commit_all sub1` unstages the gitlink, so the base has none. The test never reaches a submodule repository, and it passes with merge-tree in the real repo and no GIT_ALLOW_PROTOCOL.

### Stale
- none

### Mostly Accurate
- **Claim 4** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:43`): C11 is "Fixed" for global config only. System config still reaches merge-tree and can change the merge (P6); its file is root-owned.
- **Claim 8** (`scripts/build-loop.sh:78-85`): the --help state-gate list omits the shallow file and origin/HEAD.
- **Claim 16** (`scripts/build-loop.sh:156-157`): the system config is neither switched off nor refused. Name it as trusted.
- **Claim 17** (`scripts/build-loop.sh:167-175`): the comment's key list omits core.fsmonitor and core.hooksPath and narrows merge/diff to "drivers". "Which harden does not switch off" contradicts core.attributesFile, which harden does pair.
- **Claim 23** (`scripts/build-loop.sh:444-445`): "only the repo's object store" leaves out the alternates it follows (P2) and the multi-pack-index (P7).

### Unverifiable
- none

## Escalations

1. **`--check` prints ok for a merge git could not read** (Claim 26). This is executed, not reasoned. With the tip's tree object missing, git 2.39.5's `merge-tree --write-tree` prints `error: Could not read …` to stderr, which merge_result discards, and exits 0. merge_result returns the tree, and check_line prints `ok BRIEF TIP TREE`, exit 0. That TREE treats the branch's side as empty: in P2 it deleted the brief. Nothing earlier reads the tip's tree. This is not deferred F3, which covers rewritten bytes; it is a missing object, which a same-uid loop can produce by deleting a loose object or by writing a commit that names an absent tree. Two ways to close it: run `git cat-file -e "$sha^{tree}"`, or read the trees with `rev-parse --verify`, before merge-tree; or refuse when merge-tree's stderr is non-empty. Under U2b1b the rules will see R's deletions, but the header's "TREE is the merge of TIP" and "refuse … the merge could not be computed" are untrue for this input. The orchestrator should decide whether this is a finding for this unit or an override row next to F3.
2. **The submodule test is a false pass** (Claims 1b, 5, 33). The rubric's R2 "Test:" note and the mutant line both rely on it. The code is correct (P9), but nothing in the suite pins gate_repo's submodule isolation: MA and MD both pass, and only the union-merge test catches MA. A fix needs a base that holds the gitlink, for example `git add .gitmodules` and a plain `git commit` for sub1. It also needs an assertion that tells gate_repo apart from GIT_ALLOW_PROTOCOL, such as running a mutant without that variable, or checking merge-tree's "not checked out" path.
3. **System config reaches every gate call, merge-tree included** (Claims 4, 16; P6: `merge.directoryRenames=true` in the system config turned a conflict into ok). It is root-owned in this container, so it is low risk. Security F8 and architecture 5(b) recommended `GIT_CONFIG_NOSYSTEM=1`, and the rubric marks C11 Fixed without it. The orchestrator should either record it as trusted (comment plus override row) or add the variable.
4. **Doc drift** (Claims 8, 17, 23): the --help list and the state_gate comment lag the code; the regex is broader than both. This is for the author only.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 63ea50e7` line at the top.
- Answered: yes
- Out of scope: code quality and whether the threat model should include system config (security's call); U2b1b's rules; rewritten object bytes (F3, deferred); the "no GIT_ALLOW_PROTOCOL (shim)" and "no shallow (state test)" mutants on the rubric line, which were not re-run.
- Escalate: Escalation 1 (ok on an unreadable tip tree) and Escalation 2 (the submodule test does not exercise its path, so the rubric's R2 test note and mutant line are untrue).
