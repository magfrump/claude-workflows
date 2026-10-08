Commit: 63ea50e7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1a2 (branch feat/build-loop-u2b1a2)
**Scope:** `git diff feat/build-loop-u2b1a1...HEAD` (HEAD 63ea50e7): scripts/build-loop.sh, test/scripts/build-loop-check.bats, commit 63ea50e7's message, the rubric docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md (Fixed notes), and the plan's amended lines (docs/working/plan-build-loop-handoff.md:84, :207, :212). Final confirming pass, replicate r1 of 3.
**Checked:** 2026-10-08
**Total claims checked:** 43
**Summary:** 34 verified, 3 mostly accurate, 2 stale, 4 incorrect, 0 unverifiable

Hallucination-pattern log read before starting (`docs/reviews/hallucination-patterns.md`). Claims 1b and 10a resemble the logged class "a specific measured value / test outcome quoted from an artifact set that does not contain it" (first seen 2026-08-18). Per the shared brief (write only your own report), I did not append to that log. The orchestrator can decide whether to add an entry (see Escalations).

**Execution provenance (applies to every `executed` claim below).** git 2.39.5, bats, bash. Suites ran from cwd `/workspace/.claude/wt-build-loop-u2b1a2` starting 2026-10-08T18:57:39Z with `TMPDIR=$(mktemp -d /tmp/fcu2b1a2-r1-XXXX)`. Probes ran in fresh `mktemp -d /tmp/fcu2b1a2-r1-XXXX` repos built by `/tmp/fcu2b1a2-r1-scripts/common.sh`, which mirrors `bl_setup`, between 18:58Z and 19:10Z. Mutants ran on copies in `/tmp/fcu2b1a2-r1-mut{,root}`, with m1 at 19:03:34Z. The brief allows only this report file in the repo, so captured outputs live outside it, in `/tmp/fcu2b1a2-r1-logs/`:
- suites: `build-loop-check.bats.txt`, `build-loop-read.bats.txt`, `dev-cycle.bats.txt`, `fixture-git-env.bats.txt`, `fixture-hermeticity.bats.txt` (each exit 0)
- probes: `p1-alternates.txt`, `p2-protocol.txt`, `p3-submodule.txt`, `p4-submodule-base.txt`, `p4d-gaterepo-no-protocol.txt`, `p5-r1-mutations.txt`, `p6-noobj.txt`, `p7-misc.txt`, `p8-cgraph.txt`, `p9-replace.txt`, `p10-attrs.txt`, `p11-writes.txt`, `p12-sysconf.txt`
- mutants: `m1-realrepo-mergetree.txt`, `m2-no-objectformat.txt`

Probe scripts are in `/tmp/fcu2b1a2-r1-scripts/`. Each probe ran as `timeout 120 bash /tmp/fcu2b1a2-r1-scripts/<probe>.sh <tmpdir>`.

---

## Claim 1a: R2 "merge_result runs in a gate-owned repository ... The moved gitlink is now a conflict."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code half of R2's Fixed note: merge-tree no longer opens `.git/modules/<name>`, and a gitlink both sides moved from a shared base refuses as a conflict. It does not establish the test half of the note (Claim 1b).
**Legibility-target:** for-orchestrator-synthesis

The fixture is p4: the merge base has `sub` at aaaa…, main moves it to cccc…, and feat/x moves it to bbbb…. A promisor repository sits under `.git/modules/sm`. Run unprotected in the real repo, merge-tree fetched (`exit 1 fetched=yes`). The script refused with `refuse …: feat/x conflicts with the default branch` and `fetched=no`. A mutant without `GIT_ALLOW_PROTOCOL=none`, with the gate repository kept, also gave `fetched=no` (p4d). So gate_repo alone keeps the submodule repository closed.

**Evidence:** `scripts/build-loop.sh:448-456` (`GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")`); /tmp/fcu2b1a2-r1-logs/p4-submodule-base.txt; /tmp/fcu2b1a2-r1-logs/p4d-gaterepo-no-protocol.txt

---

## Claim 1b: R2 "Test: the P1 plant (mutant running merge-tree in the real repo fetches)."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:16`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test at build-loop-check.bats:1394 as committed at 63ea50e7, which is byte-identical to c66988b6. It does not establish what fixture the author's own mutant run used.
**Legibility-target:** for-orchestrator-synthesis

The test's merge base holds no gitlink, so git never reaches the submodule code path the plant targets. The fixture stages `sub` with `git update-index --add --cacheinfo "160000,$s1,sub"; commit_all sub1`, and `commit_all` is `git add -A && git commit …` (`test/lib/build-loop-fixtures.bash:28`). With no `sub` directory in the worktree, `add -A` stages the gitlink's removal. `git ls-tree $(git merge-base main feat/x)` lists only `.gitmodules` and `docs` (p3). Unprotected merge-tree in that fixture prints `Failed to merge submodule sub (no merge base)` and does not fetch (p3: `exit 1 fetched=no`). Mutant m1 runs merge-tree in the real repo, with no GATE_ENV and no cd. Under m1 the submodule test still passes: `ok 2 --check's merge opens no submodule repository…`.

**Evidence:** `test/scripts/build-loop-check.bats:1394-1408`; `test/lib/build-loop-fixtures.bash:28`; /tmp/fcu2b1a2-r1-logs/p3-submodule.txt; /tmp/fcu2b1a2-r1-logs/m1-realrepo-mergetree.txt

---

## Claim 2: R3 "Fixed for --check: The state gate refuses an origin/HEAD naming anything but origin/main or origin/master (tested)."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers state_gate's origin/HEAD rule and its test. It does not establish anything about `--settings`/`--status`, which still follow origin/HEAD by design (row 493).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:198-201
  rc=0; p="$(git symbolic-ref -q refs/remotes/origin/HEAD)" || rc=$?
  if [[ "$rc" -gt 1 ]] || [[ -n "$p" && "$p" != refs/remotes/origin/main && "$p" != refs/remotes/origin/master ]]; then
    echo "refuse state origin/HEAD: it names a branch other than origin/main or origin/master"; bad=1
  fi
```
The test at :1315 plants `git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/feat/x` and expects that line. The suite passed, and p6 prints the same line.

**Evidence:** `scripts/build-loop.sh:198-201`; `test/scripts/build-loop-check.bats:1336-1342`; /tmp/fcu2b1a2-r1-logs/build-loop-check.bats.txt; /tmp/fcu2b1a2-r1-logs/p6-noobj.txt

---

## Claim 3: R4 "`GIT_CONFIG_GLOBAL=/dev/null` for every call (shim test)."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the export and its runtime presence on every PATH-resolved git call. It does not cover the system config (Claim 9).
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:166` exports `GIT_CONFIG_GLOBAL=/dev/null`. The shim test (:1371) requires ` G=/dev/null` on every logged call, and it passed. GATE_ENV unsets only `--local-env-vars` names, and GIT_CONFIG_GLOBAL is not among them (p7 lists them).

**Evidence:** `scripts/build-loop.sh:166`, `test/scripts/build-loop-check.bats:1371-1383`; /tmp/fcu2b1a2-r1-logs/p7-misc.txt

---

## Claim 4: A6 "The state gate refuses a non-empty shallow file (tested); the gate repository has none either."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file check and gate_repo's layout. It does not cover a `GIT_SHALLOW_FILE` in the caller's environment, which GATE_ENV unsets and which the caller is trusted with anyway.
**Legibility-target:** for-orchestrator-synthesis

`for f in info/attributes info/grafts shallow; do` (`scripts/build-loop.sh:192`). The state test expects `refuse state shallow: present and not empty`. gate_repo creates only `git`, `git/refs` and `work`, writes `HEAD` and `config`, and makes no `shallow` (`scripts/build-loop.sh:453-455`).

**Evidence:** `scripts/build-loop.sh:192-195`, `:453-455`; `test/scripts/build-loop-check.bats:1331-1342`

---

## Claim 5: A7 "`core.commitGraph=false` pair (shim test)."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the pair being set on every call and git ignoring the graph's parent data under it. It does not establish that my forged graph changed a merge base. Two forgeries that rewired parents and generation did not move `merge-base` in my probe, so that effect rests on security F5's probe, not mine.
**Legibility-target:** for-orchestrator-synthesis

`for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false; do` (`scripts/build-loop.sh:160`). The shim test requires ` core.commitGraph=false` on every call. In p8 a forged commit-graph changed main's parent as `git log` reported it: graph on gave `… d649542…`, graph off gave `… ffc5358…`. So git reads parents from the graph when it is enabled, and the pair turns that off.

**Evidence:** `scripts/build-loop.sh:158-164`; `test/scripts/build-loop-check.bats:1380`; /tmp/fcu2b1a2-r1-logs/p8-cgraph.txt

---

## Claim 6: A8 "The gate repository reads no repo config."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-tree's config sources inside GATE_ENV. It does not cover system config (Claim 9) or the caller's GIT_CONFIG_* environment, which GATE_ENV keeps on purpose.
**Legibility-target:** for-orchestrator-synthesis

`printf '[core]\n\trepositoryformatversion = 1\n[extensions]\n\tobjectformat = %s\n' "$fmt" > "$GATE_TMP/git/config"` (`scripts/build-loop.sh:455`). GIT_DIR is the gate dir, and GIT_COMMON_DIR is unset (p7 lists it in `--local-env-vars`). That leaves no path to the repo's `config` or `config.worktree`.

**Evidence:** `scripts/build-loop.sh:448-456`; /tmp/fcu2b1a2-r1-logs/p7-misc.txt

---

## Claim 7: A14 "Plan amended" (`--state` grammar and D7's install.sh)

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:33`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two plan lines named in the finding (see Claims 12, 13). It does not cover other plan lines that still describe the iteration-1 design (see Escalations).
**Legibility-target:** for-orchestrator-synthesis

The amendment landed in ae08688c (U2b1a1). The plan now reads `` `refuse state WHAT: WHY` `` (:207) and `` `devcontainer-config/install.sh`'s `git_state_gate` `` (:84).

**Evidence:** `docs/working/plan-build-loop-handoff.md:84`, `:207`

---

## Claim 8: C4 "Fixed (a separate variable)."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two "its path could not be read" lines. It does not cover WHAT holding `: ` (C5, Won't-Fix).
**Legibility-target:** for-author

`p="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { echo "refuse state $f: its path could not be read"; return 1; }` (`scripts/build-loop.sh:184`, the same at :193). `$f` is the loop word, set before the substitution.

**Evidence:** `scripts/build-loop.sh:183-184`, `:192-193`

---

## Claim 9: C11 "Global and system config apply to the gate repository ... Fixed: GIT_CONFIG_GLOBAL for all calls; GATE_ENV unsets the repo-local variables."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:46`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the global and GIT_COMMON_DIR halves, which are fixed, and the system half, which is not. It does not establish that system config is reachable by a loop: `/etc/gitconfig` is absent here, and `/etc` is not writable by uid 1000.
**Legibility-target:** for-orchestrator-synthesis

The global config and GIT_COMMON_DIR halves hold (Claims 3 and 6). System config still reaches the gate's merge, because nothing sets `GIT_CONFIG_NOSYSTEM`. In p12, main renames `a/` to `b/` and feat/x adds `a/new`. That merge refuses as a conflict, but with `GIT_CONFIG_SYSTEM` holding `merge.directoryRenames = true` (standing in for `/etc/gitconfig`), `--check` printed `ok … cc5ae46…` and exited 0. The precise note: global fixed; system config still applies and is out of a loop's reach (root-owned).

**Evidence:** `scripts/build-loop.sh:166`; /tmp/fcu2b1a2-r1-logs/p12-sysconf.txt

---

## Claim 10a: "Mutants: merge-tree in the real repo (submodule and union tests fail)"

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:48`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the submodule half of this mutant claim at 63ea50e7. It does not cover the union half, which holds (the union test fails under m1).
**Legibility-target:** for-orchestrator-synthesis

Mutant m1 rewrites merge_result to `out="$(git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?`, with no GATE_ENV and no cd. Under m1, `bats -f 'submodule|union|SHA-256'` gave `not ok 1 --check's merge reads no checkout attributes…` and `ok 2 --check's merge opens no submodule repository…`. So the submodule test does not fail; the reason is Claim 1b.

**Evidence:** `test/scripts/build-loop-check.bats:1394-1408`; /tmp/fcu2b1a2-r1-logs/m1-realrepo-mergetree.txt

---

## Claim 10b: "no objectformat (SHA-256 test) ... Suites 91/19/78/2/2."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the objectformat mutant and the suite counts. The no-GIT_ALLOW_PROTOCOL and no-shallow mutants are checked only by reading: the shim greps ` P=none` and the state test expects the shallow line. They were not executed.
**Legibility-target:** for-orchestrator-synthesis

Mutant m2 dropped `[extensions] objectformat`, and the result was `not ok 1 --check merges in a SHA-256 repository…`. The suites passed with 91, 19, 78, 2 and 2 tests (exit 0 each).

**Evidence:** /tmp/fcu2b1a2-r1-logs/m2-no-objectformat.txt; /tmp/fcu2b1a2-r1-logs/*.bats.txt

---

## Claim 11: R1 "mutants without the keys, or with the gate after resolve_main, both let upload-pack run."

**Location:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:60`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both mutants against the code at 63ea50e7. It does not establish what they did at 9e5d92df; the claim was plausibly true before iteration 2 added `GIT_ALLOW_PROTOCOL=none`.
**Legibility-target:** for-orchestrator-synthesis

At 63ea50e7, neither mutant lets upload-pack run, because `GIT_ALLOW_PROTOCOL=none` blocks the fetch.
- **Gate after resolve_main (mutant a):** exit 2, the two refusal lines, `fetched=no`. The R1 test passes under it, because resolve_main falls back to HEAD's sha and the gate still refuses (Claim 32b).
- **Keys removed (mutant c):** `build-loop.sh needs a default branch found by name…`, exit 1, `fetched=no`. The test fails here on its status assertion, not on the mark.
- **Gate moved and GIT_ALLOW_PROTOCOL also dropped (mutant b):** `fetched=yes`. This is the only combination that makes upload-pack run.

**Evidence:** `test/scripts/build-loop-check.bats:1356-1369`; /tmp/fcu2b1a2-r1-logs/p5-r1-mutations.txt

---

## Claim 12: D7 "All git calls are hardened, with a state gate after `devcontainer-config/install.sh`'s `git_state_gate`."

**Location:** `docs/working/plan-build-loop-handoff.md:84`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the path and function name. It does not compare the two gates' key lists.
**Legibility-target:** for-author

`devcontainer-config/install.sh` is tracked, and it defines `git_state_gate() {` at :209 and calls it at :332 (`git_state_gate   # before any other git call on the checkout (review R1)`).

**Evidence:** `devcontainer-config/install.sh:209`, `:332`

---

## Claim 13: "`--state` → `ok`, or `refuse state WHAT: WHY` for each planted `.git` state the gate refuses (exit 2), as `--check` prints them (U2b1a's `state_gate`)."

**Location:** `docs/working/plan-build-loop-handoff.md:207`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line grammar matching state_gate's output. `--state` itself is U3b's and does not exist yet; the line is a plan, not a claim about current code.
**Legibility-target:** for-author

Every state_gate output line starts `refuse state ` and has a `: ` separator, for example `echo "refuse state $f: present and not empty"` (`scripts/build-loop.sh:194`). On any finding `--check` exits 2: `if [[ "$MODE" == check ]]; then state_gate || exit 2; fi` (:209).

**Evidence:** `scripts/build-loop.sh:181-203`, `:209`

---

## Claim 14: "Output (U2b1a): `refuse state WHAT: WHY` lines (exit 2 before any brief), then per brief `ok BRIEF TIP TREE`, `refuse BRIEF: WHY` or `skip BRIEF: WHY`; U2b1b adds per-path lines and must make the exit status 'every line ok'."

**Location:** `docs/working/plan-build-loop-handoff.md:212`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the current line kinds and the exit-before-briefs ordering. It does not cover U2b1b's future lines.
**Legibility-target:** for-author

The state gate runs at :209, before `resolve_main` and `read_settings`. check_line prints only `ok $a $sha $tree`, `refuse $a: …`, or status_line's non-ok line, which is always a `skip` (check_brief emits only `ok`/`skip` lines, 9 `echo "skip` sites). The current exit test is `[[ "$out" == "ok "* ]] || fails=1` (:507). That tests the first line of out, and today out is one line.

**Evidence:** `scripts/build-loop.sh:209`, `:470-488`, `:499-510`; `scripts/lib/dev-cycle-read.sh` check_brief

---

## Claim 15: --check help state gate list: "a git config key ... for a filter, include, config hook, merge or diff setting, core.fsmonitor, core.attributesFile, core.hooksPath, gpg.*, log.showSignature, extensions.partialClone or remote.*.promisor (a partial clone), a non-empty info/attributes or info/grafts, or a replace ref prints 'refuse state WHAT: WHY' per finding and exits 2 before any brief is read."

**Location:** `scripts/build-loop.sh:78-85`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header's list against state_gate's checks. It does not cover the state_gate comment at :167-179, which is complete (Claim 25).
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:78-85 (header excerpt; the --check entry continues to :99 — read)
#   --check   the gate (D7), advisory when a loop runs it. First a state gate:
#             a git config key (common config or config.worktree, includes not
#             followed) for a filter, include, config hook, merge or diff
#             setting, core.fsmonitor, core.attributesFile, core.hooksPath,
#             gpg.*, log.showSignature, extensions.partialClone or
#             remote.*.promisor (a partial clone), a non-empty info/attributes or
#             info/grafts, or a replace ref prints "refuse state WHAT: WHY"
#             per finding and exits 2 before any brief is read. Then one line
```
The code also refuses a non-empty `shallow` (`for f in info/attributes info/grafts shallow; do`, :192) and a foreign origin/HEAD (:198-201). Iteration 2 (c66988b6) added both checks and rewrote the state_gate comment, but did not touch this header. The header should list "a non-empty info/attributes, info/grafts or shallow, a replace ref, or an origin/HEAD naming a branch other than origin/main or origin/master". The header is what `--help` prints.

**Evidence:** `scripts/build-loop.sh:78-85`, `:192`, `:198-201`; `git show c66988b6 -- scripts/build-loop.sh` (no header hunk)

---

## Claim 16: --check help line formats "ok BRIEF TIP TREE ... refuse BRIEF: WHY ... skip BRIEF: WHY As --status skips it."

**Location:** `scripts/build-loop.sh:86-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three line kinds and every listed refuse reason against check_line. It does not cover reason order: the header lists "not ahead" before "moved", while the code checks moved first; the header states no order.
**Legibility-target:** for-author

Each listed reason maps to a check_line branch:
- **done, dropped or new:** `the brief is $st on the default branch` (:474).
- **branch absent:** `its branch $br does not exist` (:475).
- **moved or could not be read again:** `moved or could not be read again` (:478).
- **not ahead:** `has no commit the default branch lacks` (:479).
- **TIP is not SHA:** `the tip of $br is $sha, not the expected $EXPECT` (:480).
- **conflict:** `conflicts with the default branch` (:484).
- **merge not computed:** `could not be computed` (:485).

Skips come from status_line, which check_line echoes unchanged when it is not ok: `[[ "$out" == "ok "* ]] || { echo "$out"; return; }` (:472).

**Evidence:** `scripts/build-loop.sh:86-99`, `:470-488`

---

## Claim 17: "Writes nothing but --check's merge objects (merge-tree writes the merged trees and blobs into the object store) and its own temporary directory, removed at exit."

**Location:** `scripts/build-loop.sh:102-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one clean-merge run: the repo's non-object files, `.git` included, and the TMPDIR afterwards. It does not cover runs killed by a signal.
**Legibility-target:** for-author

p11 snapshotted every path under the repo except `.git/objects` (name, size, mtime, inode) before and after `--check`. Result: `non-object changes: none`, `new object files: 1`, `left in TMPDIR: 0`.

**Evidence:** `scripts/build-loop.sh:500-502` (`GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT`); /tmp/fcu2b1a2-r1-logs/p11-writes.txt

---

## Claim 18: "Exit: 0 every line printed (or help), and for --check every line ok; 2 any --check line or the state gate not ok; 1 bad usage, not a git repo, ..."

**Location:** `scripts/build-loop.sh:107-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --check exit codes the suite exercises: 0 for ok, 2 for a refuse, a skip or the state gate, 1 for usage. It does not separately exercise the gate_repo setup failure, which also exits 2 (:503).
**Legibility-target:** for-author

The tests at :1256 (0 and 2), :1275 (1 for usage), :1295 (2 for a skip) and :1315 (2 for the state gate) all pass.

**Evidence:** `scripts/build-loop.sh:503-509`; /tmp/fcu2b1a2-r1-logs/build-loop-check.bats.txt

---

## Claim 19: "Every git call in this process, the lib's included, runs hardened."

**Location:** `scripts/build-loop.sh:147`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every PATH-resolved git call of a --check run, the env-wrapped merge-tree included, and the absence of git calls before `harden`. It does not cover git's own exec-path subprocesses, which inherit the environment but are not logged by the shim, or the caller's own `git -c` (trusted, as stated).
**Legibility-target:** for-orchestrator-synthesis

Before `harden` (:165) the script runs only `perl` and `cd`/`pwd`, sources the lib, and calls `scrub_reexec`. The lib's top level and `scrub` (perl) run no git. The child re-exec runs the same file, so it hardens before its first git call. GATE_ENV keeps `GIT_CONFIG*` (`[[ "$v" == GIT_CONFIG* || "$v" == GIT_NO_REPLACE_OBJECTS ]] || GATE_ENV+=(-u "$v")`, :451). It does not touch GIT_CONFIG_GLOBAL or GIT_ALLOW_PROTOCOL, which are not local-env-vars. The shim test passed with more than 10 calls, each carrying all five pairs, `G=/dev/null` and `P=none`.

**Evidence:** `scripts/build-loop.sh:111-122`, `:158-166`, `:451`; `test/scripts/build-loop-check.bats:1371-1383`; /tmp/fcu2b1a2-r1-logs/build-loop-check.bats.txt

---

## Claim 20: "core.useReplaceRefs in the repo's config would override GIT_NO_REPLACE_OBJECTS"

**Location:** `scripts/build-loop.sh:148-150`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's precedence. It does not cover later git versions.
**Legibility-target:** for-author

p9 replaced blob `a` with `b` and set `core.useReplaceRefs true` in the repo. `GIT_NO_REPLACE_OBJECTS=1` alone printed `b`; with the config pair added it printed `a`.

**Evidence:** `scripts/build-loop.sh:160`; /tmp/fcu2b1a2-r1-logs/p9-replace.txt

---

## Claim 21: "no commit-graph (a forged one changes merge bases)"

**Location:** `scripts/build-loop.sh:151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the pair disabling git's use of the graph's commit data, both in the repo and in the gate repo, which shares the object directory holding `info/commit-graph`. It does not cover the merge-base effect, which my two forgeries did not reproduce (see Claim 5).
**Legibility-target:** for-author

Under a forged graph, `git -c core.commitGraph=true log --format='%H %P' -1 main` printed the forged parent; with `=false` it printed the real one (p8). The pair is kept inside GATE_ENV (:451).

**Evidence:** `scripts/build-loop.sh:160`, `:451`; /tmp/fcu2b1a2-r1-logs/p8-cgraph.txt

---

## Claim 22: "GIT_CONFIG_GLOBAL=/dev/null: a loop can write the user's ~/.gitconfig as easily as .git/config."

**Location:** `scripts/build-loop.sh:151-152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the export reaching every call and blocking `~/.gitconfig` and `$XDG_CONFIG_HOME/git/config`. The XDG and HOME attributes files are blocked by the `core.attributesFile=/dev/null` pair (p7). It does not cover system config (Claim 9).
**Legibility-target:** for-author

p7 planted `* merge=union` in `$XDG_CONFIG_HOME/git/attributes` and `$HOME/.config/git/attributes`. A plain merge-tree applied it (`control exit 0 (0 = union applied)`), but `--check` still refused the conflict.

**Evidence:** `scripts/build-loop.sh:166`; /tmp/fcu2b1a2-r1-logs/p7-misc.txt

---

## Claim 23: "GIT_ALLOW_PROTOCOL=none: no transport at all, so a lazy fetch (a partial clone's missing object) fails however the config was planted, even after the state gate read it."

**Location:** `scripts/build-loop.sh:152-154`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a lazy fetch through a local-path (file) promisor remote, with `protocol.allow=always` and `protocol.file.allow=always` set in the repo. It does not separately exercise ssh or ext transports, which the same whitelist check gates.
**Legibility-target:** for-orchestrator-synthesis

In p2, with `GIT_ALLOW_PROTOCOL=none`, `git cat-file -p <missing>` failed with `fatal: transport 'file' not allowed` and `fetched=no`. The control run without the variable ran upload-pack and gave `fetched=yes`.

**Evidence:** `scripts/build-loop.sh:166`; /tmp/fcu2b1a2-r1-logs/p2-protocol.txt

---

## Claim 24: state_gate "reads no object (git config --file --no-includes follows no include; --git-path reads no index)" and "runs before any object read"

**Location:** `scripts/build-loop.sh:169-171`, `:208-209`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers state_gate's own calls and its placement before resolve_main. It does not cover `git rev-parse --show-toplevel` (:204), which runs earlier and also reads no object. No test pins the ordering (Claim 32b).
**Legibility-target:** for-orchestrator-synthesis

p6 moved `.git/objects` away entirely, with a replace ref, a foreign origin/HEAD and `merge.y.driver` planted. state_gate ran `config`, `for-each-ref`, 6 `rev-parse` and `symbolic-ref`, then printed all three refusal lines, the replace ref counted, and exited 2. No call failed.

**Evidence:** `scripts/build-loop.sh:181-203`, `:208-210`; /tmp/fcu2b1a2-r1-logs/p6-noobj.txt

---

## Claim 25: state_gate's key, file and origin/HEAD lists, "(resolve_main would take the default branch from it)", and its line formats

**Location:** `scripts/build-loop.sh:171-179`, `:180`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every key class the comment names against STATE_KEYS_RE and the test's 16 keys, plus config.worktree, the three files, refs/replace and origin/HEAD. The comment's key list leaves out core.fsmonitor and core.hooksPath, which the regex refuses; that is consistent with "which harden does not switch off", since harden pairs both. It does not cover keys outside the list (see Escalations).
**Legibility-target:** for-author

resolve_main takes `origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD …)"` and tries `refs/heads/${origin_head#origin/}` first (`scripts/lib/dev-cycle-read.sh:486-495`). A symref to `refs/remotes/origin/feat/x` therefore makes local `feat/x` the default branch. The state test (:1315) and p6 printed the line formats as quoted at :189, :194, :197 and :200.

**Evidence:** `scripts/build-loop.sh:180-201`; `scripts/lib/dev-cycle-read.sh:483-505`; `test/scripts/build-loop-check.bats:1315-1342`

---

## Claim 26: "a non-empty info/attributes, info/grafts or shallow" / "refuse state $f: present and not empty"

**Location:** `scripts/build-loop.sh:194`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the condition against its message. It does not establish any effect of the extra refusals.
**Legibility-target:** for-author

`if [[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]; then echo "refuse state $f: present and not empty"; bad=1; fi`. The code also refuses an empty symlink or a directory at the path, with the same "not empty" message. The precise version: non-empty, a symlink, or not a regular file.

**Evidence:** `scripts/build-loop.sh:194`

---

## Claim 27a: gate_repo/merge_result "merge-tree reads none of the repo's config (a submodule repository under .git/modules is never opened), no checkout's .gitattributes (git 2.39 reads one from the current directory even under --work-tree) ... GATE_ENV unsets the repo-local variables (GIT_COMMON_DIR and the like)"; object format kept

**Location:** `scripts/build-loop.sh:439-447`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers repo config, the submodule repository, checkout attributes (cwd and `--work-tree`), the unset list, and SHA-256. It does not cover system config (Claim 9) or alternates (Claim 27b).
**Legibility-target:** for-orchestrator-synthesis

The comment's claims check out:
- **Checkout attributes (p10):** from the root, git 2.39.5 applied an untracked `.gitattributes` `* merge=union` both plain and with `--git-dir=.git --work-tree=$empty` (both `exit 0`). `--check` refused the conflict.
- **Submodule repository (p4d):** the gate repo alone kept the submodule repository closed.
- **Repo-local variables (p7):** `--local-env-vars` lists GIT_COMMON_DIR, GIT_ALTERNATE_OBJECT_DIRECTORIES, GIT_GRAFT_FILE, GIT_SHALLOW_FILE and the rest. All are unset except GIT_CONFIG* and GIT_NO_REPLACE_OBJECTS.
- **Object format:** the SHA-256 test passes, and mutant m2 (no objectformat) fails it.

**Evidence:** `scripts/build-loop.sh:448-456`; /tmp/fcu2b1a2-r1-logs/p10-attrs.txt, p4d-gaterepo-no-protocol.txt, p7-misc.txt, m2-no-objectformat.txt

---

## Claim 27b: "and only the repo's object store (GIT_OBJECT_DIRECTORY, where it also writes)"

**Location:** `scripts/build-loop.sh:444-445`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which object directories merge-tree reads. It does not establish that alternates can change an object's bytes. They only add objects git lacks locally; the same-id-different-bytes issue is security F3, deferred in row 492.
**Legibility-target:** for-orchestrator-synthesis

GATE_ENV unsets GIT_ALTERNATE_OBJECT_DIRECTORIES, but git still follows `objects/info/alternates` inside GIT_OBJECT_DIRECTORY. In p1, `.git/objects/info/alternates` pointed at another repository's store, and feat/x's tip existed only there (`objects alt-only? not-local`). `--check` printed `ok … b3895f8… 4f26876…` and exited 0. The state gate does not check that file. Precise version: the repo's object store and any alternates it lists; writes go to GIT_OBJECT_DIRECTORY.

**Evidence:** `scripts/build-loop.sh:451-456`; /tmp/fcu2b1a2-r1-logs/p1-alternates.txt

---

## Claim 28: merge_result "returns 1 on a conflict (a gitlink both sides moved is one, since no submodule repository is reachable), 2 when git failed"

**Location:** `scripts/build-loop.sh:458-467`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a gitlink moved by both sides from a shared base (p4). It does not cover the rc-2 path, which no test exercises.
**Legibility-target:** for-author

```bash
# scripts/build-loop.sh:463-466
  out="$(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?
  [[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2
  [[ "$rc" -eq 0 ]] || return 1
  echo "${out%%$'\n'*}"
```
In p4 and p4d the script printed the conflict refusal.

**Evidence:** `scripts/build-loop.sh:461-467`; /tmp/fcu2b1a2-r1-logs/p4-submodule-base.txt

---

## Claim 29: check_line "ok BRIEF TIP TREE, or one skip or refuse line (from status_line, then the gate's own reasons)" and its field parsing

**Location:** `scripts/build-loop.sh:468-488`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the field positions against status_line's and check_branch's printed formats, and the check order. It does not cover brief paths holding blanks, which check_brief governs.
**Legibility-target:** for-author

status_line prints `"ok $a $st $pol $br $loop $sha $date $disp$reason"` (:435), and check_line reads `read -r _ _ st _ br loop sha _`, which gives fields 3, 5, 6 and 7. check_branch prints `"ok $a $sha $n $d"` (lib :447), and check_line reads `read -r _ _ _ n _`, which gives field 4. The order is state, absent, moved/unreadable, not ahead, --expect, then merge.

**Evidence:** `scripts/build-loop.sh:400-436`, `:470-488`; `scripts/lib/dev-cycle-read.sh:436-450`

---

## Claim 30: test "--check's merge reads no checkout attributes: an untracked .gitattributes, or one planted in .git, cannot turn a conflict into a union merge"

**Location:** `test/scripts/build-loop-check.bats:1266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the untracked root `.gitattributes`, which is a live plant (mutant m1 fails the test). It does not establish that `.git/.gitattributes` alone is live; that file is a plant for the iteration-1 design, which ran from `.git`.
**Legibility-target:** for-author

Under m1: `not ok 1 --check's merge reads no checkout attributes…`, `status 0`, `ok …`.

**Evidence:** `test/scripts/build-loop-check.bats:1266-1273`; /tmp/fcu2b1a2-r1-logs/m1-realrepo-mergetree.txt

---

## Claim 31: test "--check's state gate refuses each planted git state that can run a command or change the merge, before reading any brief"

**Location:** `test/scripts/build-loop-check.bats:1315`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 16 keys one at a time (one output line each), config.worktree, the three files, a replace ref and origin/HEAD. "Before reading any brief" is checked only by the output being state lines alone (C1).
**Legibility-target:** for-author

Each key is set, run, required to produce exactly one `refuse state …: set in config…` line, then unset. The test then plants config.worktree, followed by the file and ref plants together with an exact five-line expectation. It passed.

**Evidence:** `test/scripts/build-loop-check.bats:1315-1342`; /tmp/fcu2b1a2-r1-logs/build-loop-check.bats.txt

---

## Claim 32a: test "--check refuses a partial clone ... a promisor remote's upload-pack never runs for a missing object"

**Location:** `test/scripts/build-loop-check.bats:1356`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal (both key lines, exit 2) and the no-fetch mark. The mark fails only when both the gate ordering and GIT_ALLOW_PROTOCOL are broken (mutant b: `fetched=yes`).
**Legibility-target:** for-author

The plant is live: mutant b, with the gate after resolve_main and no protocol block, ran upload-pack.

**Evidence:** `test/scripts/build-loop-check.bats:1356-1369`; /tmp/fcu2b1a2-r1-logs/p5-r1-mutations.txt

---

## Claim 32b: same test title, "... before any object is read"

**Location:** `test/scripts/build-loop-check.bats:1356`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the test pins the gate-before-resolve_main ordering. It does not question the ordering in the code, which is correct (Claim 24).
**Legibility-target:** for-author

Mutant a moves `state_gate` after `resolve_main || true` and keeps GIT_ALLOW_PROTOCOL. Under it the test's exact assertions still hold: exit 2, the two refusal lines, `fetched=no`. resolve_main's read of the deleted commit fails without fetching, and it falls back to HEAD (`MAIN_SHA` set, `MAIN_BY_NAME` empty). The gate then refuses as before. The test cannot tell the gate ran before the first object read.

**Evidence:** `scripts/lib/dev-cycle-read.sh:496-503`; /tmp/fcu2b1a2-r1-logs/p5-r1-mutations.txt (block `/tmp/fcu2b1a2-r1-mut/a`)

---

## Claim 33: test "every git call --check makes carries harden's config pairs (core.hooksPath=/dev/null among them), no global config and no transport"

**Location:** `test/scripts/build-loop-check.bats:1371`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers PATH-resolved git calls, the env-wrapped merge-tree included. It does not cover git's internal exec-path subprocesses.
**Legibility-target:** for-author

`! grep -v -- " $kv" "$BATS_TEST_TMPDIR/calls" || { echo "a call without $kv"; return 1; }` fails if any logged line lacks a pair. That covers all five pairs, `G=/dev/null` and `P=none`. It also requires more than 10 calls. It passed.

**Evidence:** `test/scripts/build-loop-check.bats:1371-1383`

---

## Claim 34: test "--check's merge opens no submodule repository: a promisor one under .git/modules never fetches, and the moved gitlink is a conflict"

**Location:** `test/scripts/build-loop-check.bats:1394`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test exercises at 63ea50e7. It does not question the code's behavior, which is right (Claims 1a, 28).
**Legibility-target:** for-author

```bash
# test/scripts/build-loop-check.bats:1397-1398 (excerpt ends :1398; the test continues to :1408 — read)
    printf '[submodule "sm"]\n\tpath = sub\n\turl = ./nowhere\n' > .gitmodules
    git update-index --add --cacheinfo "160000,$s1,sub"; commit_all sub1
```
`commit_all` runs `git add -A`, which drops the gitlink because there is no `sub` path in the worktree. So the merge base has no `sub`, and both sides add a different gitlink. merge-ort reports `Failed to merge submodule sub (no merge base)` without opening any submodule repository, and an unprotected merge-tree in the real repo does not fetch (p3). The test passes under mutant m1. So the test checks neither "opens no submodule repository" nor a "moved" gitlink. It needs a base that keeps the gitlink, for example `git add .gitmodules; git update-index …; git commit` as in p4, where unprotected merge-tree fetches.

**Evidence:** `test/scripts/build-loop-check.bats:1394-1408`; `test/lib/build-loop-fixtures.bash:28`; /tmp/fcu2b1a2-r1-logs/p3-submodule.txt, p4-submodule-base.txt, m1-realrepo-mergetree.txt

---

## Claim 35: test "--check merges in a SHA-256 repository: TIP and TREE are 64-hex"

**Location:** `test/scripts/build-loop-check.bats:1411`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers TIP's length explicitly, and TREE through equality with sha256 `git merge-tree` output. TREE's length is not asserted separately.
**Legibility-target:** for-author

The test passes, and mutant m2 fails it.

**Evidence:** `test/scripts/build-loop-check.bats:1411-1416`; /tmp/fcu2b1a2-r1-logs/m2-no-objectformat.txt

---

## Claim 36: commit 63ea50e7 "Suites: build-loop-check 91, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2."

**Location:** commit 63ea50e7 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and passing at 63ea50e7 under git 2.39.5. It does not cover other suites.
**Legibility-target:** for-orchestrator-synthesis

`bats --count` gave 91, 19, 78, 2 and 2 (fixture-hermeticity is `test/fixture-hermeticity.bats`). All suites ran to exit 0, with last lines `ok 91 …`, `ok 19 …`, `ok 78 …`, `ok 2 …` and `ok 2 …`.

**Evidence:** /tmp/fcu2b1a2-r1-logs/{build-loop-check,build-loop-read,dev-cycle,fixture-git-env,fixture-hermeticity}.bats.txt

---

## Claim 37: commit 63ea50e7 "330 code lines against U2b1a1."

**Location:** commit 63ea50e7 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers added plus deleted lines (the convention the command implies). Added lines alone are 316.
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat feat/build-loop-u2b1a1...HEAD -- ':(top)' ':(top,exclude)docs/'` gives `165 11 scripts/build-loop.sh` and `151 3 test/scripts/build-loop-check.bats`. 165+11+151+3 = 330.

**Evidence:** command output (run in the worktree, 2026-10-08)

---

## Claim 38: commit 63ea50e7 "Its code, tests and review history are feat/build-loop-u2b1a at c66988b6"

**Location:** commit 63ea50e7 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tree identity outside docs/. It does not establish ancestry: c66988b6 is not an ancestor of U2b1a1, since the units are a re-split.
**Legibility-target:** for-orchestrator-synthesis

`git rev-parse feat/build-loop-u2b1a` gives `c66988b6…`. `git diff --stat c66988b6 HEAD -- ':(exclude)docs/'` is empty. The whole diff touches only `docs/working/plan-build-loop-handoff.md` (+1) and `docs/working/questions.md`.

**Evidence:** command output (run in the worktree, 2026-10-08)

---

## Claim 39: commit 63ea50e7's bullets (harden, state_gate, gate_repo "so no checkout attributes, repo config or submodule repository reach the merge", check_line, tests) and "security F3 ... is deferred with an override row"

**Location:** commit 63ea50e7 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against the code and tests (Claims 19-35) and the F3 row. The "no repo config" wording does not extend to system config or alternates (Claims 9, 27b).
**Legibility-target:** for-orchestrator-synthesis

The state_gate bullet's list matches the code, shallow and origin/HEAD included. The tests named are all present. Override row 492 (2026-10-08, `feat/build-loop-u2b1a`) records F3 as deferred.

**Evidence:** `scripts/build-loop.sh:158-210`, `:439-510`; `docs/reviews/override-log.md:492`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1b** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:16`): R2's test note is false of the committed test. The submodule test's mutant (merge-tree in the real repo) does not fetch, because the fixture's merge base has no gitlink.
- **Claim 10a** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:48`): "merge-tree in the real repo (submodule … tests fail)". The submodule test passes under that mutant; only the union test fails.
- **Claim 32b** (`test/scripts/build-loop-check.bats:1356`): the title's "before any object is read" is not pinned. With the gate moved after resolve_main the test still passes, because GIT_ALLOW_PROTOCOL blocks the fetch and resolve_main falls back to HEAD.
- **Claim 34** (`test/scripts/build-loop-check.bats:1394`): `commit_all`'s `add -A` drops the base gitlink, so git never opens a submodule repository, and the test passes with merge-tree in the real repo. Build the base without `add -A`, as in p4.

### Stale
- **Claim 11** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:60`): R1's "both mutants let upload-pack run" was true before GIT_ALLOW_PROTOCOL. At 63ea50e7 neither mutant fetches.
- **Claim 15** (`scripts/build-loop.sh:78-85`): the `--check` help's state gate list omits the shallow and origin/HEAD refusals added in iteration 2.

### Mostly Accurate
- **Claim 9** (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:46`): C11 is fixed for global config and GIT_COMMON_DIR only. System config still reaches the gate merge (p12), though it is root-owned here.
- **Claim 26** (`scripts/build-loop.sh:194`): "present and not empty" is also printed for an empty symlink or a non-regular file.
- **Claim 27b** (`scripts/build-loop.sh:444-445`): "only the repo's object store" leaves out `objects/info/alternates`, which merge-tree follows and which the state gate does not check (p1).

### Unverifiable
- none

## Escalations

1. **The submodule test (Claim 34) is vacuous, and the rubric's R2 and mutant notes (Claims 1b, 10a) rest on it.** The code is right, but nothing in the suite pins gate_repo's submodule isolation. A regression to merge-tree in the real repo would pass every test except the union one. This contradicts the rubric's Fixed note, so it matters for the merge decision. Legibility-target: for-orchestrator-synthesis.
2. **The gate-before-object-read ordering is unpinned (Claim 32b).** R1's iteration-1 mutant claim is stale (Claim 11). Since iteration 2, GIT_ALLOW_PROTOCOL masks the ordering mutant. Legibility-target: for-orchestrator-synthesis.
3. **What still reaches merge-tree (from the brief's probe list):**
   - **objects/info/alternates:** reaches merge-tree and is not refused (p1, Claim 27b). It can only add objects; the bytes-rewrite risk is row 492 (F3).
   - **System config:** reaches merge-tree (p12, Claim 9). `/etc/gitconfig` is not writable by the loop uid here.
   - **XDG/HOME attributes:** blocked (p7).
   - **Packs and multi-pack-index:** read as usual. A forged pack or midx is the same class as F3 (row 492); not probed.
   - **Commit-graph:** off (Claim 21).

   Legibility-target: for-orchestrator-synthesis.
4. **Hallucination log not updated.** The brief limits writes to this report. Claims 1b and 10a are a "test outcome claimed for an artifact that does not show it" pattern, the same class as the logged "All 85 tests" entry. The orchestrator may append one line to `docs/reviews/hallucination-patterns.md`. Legibility-target: for-orchestrator-synthesis.
5. **Out of this unit's diff, but stale.** `docs/working/plan-build-loop-handoff.md:281` (U2b1a bullet, from U2b1a1's commit) still describes "merge-tree run from a fresh empty directory against the common git dir" and a state gate without the partial clone, shallow or origin/HEAD. This is history in a split note; the reader may want it marked as superseded. Legibility-target: for-author.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 63ea50e7` line at the top.
- Answered: yes
- Out of scope: security F3 (rewritten object bytes; row 492); keys outside STATE_KEYS_RE that could change reads (e.g. `i18n.logOutputEncoding`) are a security-reviewer question, not a claim in the comments; the hallucination-log append (brief forbids writes beyond this report).
- Escalate: Escalations 1 and 2. The rubric's R2 Fixed note and mutant line (Claims 1b, 10a) are false of the committed submodule test, and that test plus the partial-clone test's ordering half pin nothing the code's fixes depend on.
