Commit: 809df345

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b1b, branch `feat/build-loop-u2b1b`)
**Scope:** branch diff `main...HEAD` (0e4596ce..809df345): `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, `docs/reviews/override-log.md` rows 497 and 507-511, `docs/working/plan-build-loop-handoff.md` (F8, the `--check` interface line, step 5's U2b1b note), commit messages of cc9b69d3 and 809df345; lib functions read for context: `scripts/lib/dev-cycle-read.sh` (`pathform`, `writable`, `lower`, `FENCE_AWK`, `brief_fields`, `resolve_main`)
**Checked:** 2026-10-08
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 43
**Summary:** 35 verified, 8 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution logs: kept outside the worktree, as the brief requires, in
`/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i1/fc/` (`$FC` below).
Every probe ran under `set -eu` in a `mktemp -d -p $FC` directory, refusing to run unless `pwd` was under `$FC`. Git was 2.39.5, bats 1.8.2.
- `$FC/suite.log`: `TMPDIR=<mktemp> bats test/scripts/build-loop-check.bats`, run in the worktree (via the `scratchpad/wt` symlink) at 2026-10-08T21:25Z. Exit 0, 101/101 ok.
- `$FC/suites2.log`: build-loop-read, fixture-git-env, fixture-hermeticity and dev-cycle, at 2026-10-08T21:32:52Z. Every suite exited 0 (19, 2, 2 and 78 ok).
- `$FC/probe1.log` / `probe2.log` (`bash $FC/probe1.sh` and `probe2.sh`, exit 0, 21:26:29Z and 21:26:59Z): raw `git merge-tree` against missing objects.
- `$FC/probe3.log` (`bash $FC/probe3.sh`, exit 0, 21:28:03Z): `submodule.<name>.ignore=all` against diff-tree, plus a replica of the R9 fixture.
- `$FC/probe4.log` (`bash $FC/probe4.sh`, exit 0, 21:30:19Z): `build-loop.sh --check` against these fixtures: the own brief without a final newline, A16, a missing blob that only the tip holds, and origin/HEAD naming origin/master with only a local main.
- `$FC/probe5.log` (`bash $FC/probe5.sh`, exit 0, 21:31:19Z): a system config setting `merge.directoryRenames=true`, run against HEAD's script and against a copy without `GIT_CONFIG_NOSYSTEM`.
- `$FC/mutants.log` (`bash $FC/mutants.sh`, exit 0, 21:28:44Z) and `$FC/mut2.log` (`bash $FC/mut2.sh`, exit 0, 21:31:34Z): mutants applied to `git archive 809df345 scripts test` copies under `$FC`, each run with `bats --filter`.

Hallucination-pattern log: read. No claim here matches a logged pattern. The closest logged patterns are the test-count ones ("All 85 tests…", "mode1-equiv 33"), and this branch's counts were executed and match (Claim 39). No fabrication was found, so nothing would be appended. The task also forbids writing outside this report.

---

## Claim 1: "U2b1b (cc9b69d3): the first line is the verdict line; path and deny lines follow it, and the help says "every verdict line ok"."

**Location:** `docs/reviews/override-log.md:497`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of check_line's output and the help's exit wording. It does not establish that any caller other than the script's own `case` reads only the first line.
**Legibility-target:** for-orchestrator-synthesis

check_line prints the verdict, then the rows: `if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of $i changed paths refused"; fi` then `[[ "$i" -eq 0 ]] || printf '%s\n' "${rows[@]}"` (`scripts/build-loop.sh:592-593`; this is the end of check_line, `:594`). The exit test is `[[ "$out" == "ok "* ]] || fails=1` (`scripts/build-loop.sh:613`), a prefix test on the whole multi-line output, so in effect on the first line. The help reads `for --check every verdict line ok` (`scripts/build-loop.sh:134`). The T14 test asserts `lines[0]` is the verdict and the paths follow (`test/scripts/build-loop-check.bats:1458,1465`), and it passed in `$FC/suite.log`.

**Evidence:** `scripts/build-loop.sh:134`, `scripts/build-loop.sh:592-594`, `scripts/build-loop.sh:611-615`, `test/scripts/build-loop-check.bats:1451-1471`, `$FC/suite.log`

---

## Claim 2: "Fixed in cc9b69d3 (U2b1b): gate_git refuses any stderr; the trees of main, the tip and each merge base must exist; the test fails with both guards removed."

**Location:** `docs/reviews/override-log.md:507`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both guards and the R6 test failing when both are removed. It does not establish that the test fails with only one guard removed: it does not, because each guard alone is enough for both of its fixtures (see Claim 31).
**Legibility-target:** for-orchestrator-synthesis

The guards are `[[ ! -s "$GATE_TMP/err" ]] || return 3` (`scripts/build-loop.sh:505`) and `for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done` (`scripts/build-loop.sh:517`). Mutant `r6both` removes both, and the R6 test fails: `not ok 1 --check refuses a merge git warned about…` (`$FC/mutants.log`).

**Evidence:** `scripts/build-loop.sh:502-507`, `scripts/build-loop.sh:512-522`, `$FC/mutants.log` (r6both)

---

## Claim 3: "Fixed in cc9b69d3 (U2b1b): --check refuses both main and master, or origin/HEAD naming a branch other than the one taken (`refuse state default-branch:`)."

**Location:** `docs/reviews/override-log.md:508`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both refusals and their output (see Claim 17). It does not establish anything about `--status` or `--settings`: the block runs only under `--check`.
**Legibility-target:** for-orchestrator-synthesis

See Claim 17. The R7 test passes on HEAD and fails with the block off (mutant `r7`, `$FC/mutants.log`).

**Evidence:** `scripts/build-loop.sh:244-252`, `test/scripts/build-loop-check.bats:1540-1551`, `$FC/mutants.log` (r7)

---

## Claim 4: "U2b1b (cc9b69d3): not changed. Proposed: a Q-103 residual (a racing same-uid writer can write any directory the gate creates; mode 700 does not stop the same uid)."

**Location:** `docs/reviews/override-log.md:509`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the GATE_TMP set-up and gate_repo are unchanged on this branch, and the Unix fact that a 0700 directory restricts other uids only. It does not decide R8's disposition, which is left to the review loop.
**Legibility-target:** for-orchestrator-synthesis

The set-up line `GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT` (`scripts/build-loop.sh:608`) and `gate_repo` (`:489-498`) do not appear in the branch diff (paraphrased — no quote available because the claim is about the absence of a change: the `git diff main...HEAD -- scripts/build-loop.sh` hunks touch neither region). `mktemp -d` creates a 0700 directory owned by the caller's uid, which a same-uid process can write.

**Evidence:** `scripts/build-loop.sh:488-498`, `scripts/build-loop.sh:608`

---

## Claim 5: "Fixed in cc9b69d3 (U2b1b): the old test keeps its base gitlink; a new one merges a gitlink fast-forward that the real repository resolves cleanly; merge-tree in the real repository fails it."

**Location:** `docs/reviews/override-log.md:510`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old test's base gitlink, the new fixture's clean real-repository merge (the sub entry fast-forwards to y), and the mutant. It does not establish that the gate repository resolves any other submodule shape (a gitlink only one side moved, say).
**Legibility-target:** for-orchestrator-synthesis

The old test now commits with `git add .gitmodules; git update-index --add --cacheinfo "160000,$s1,sub"; git commit -q -m sub1` (`test/scripts/build-loop-check.bats:1405`), so the base holds the gitlink. The new test asserts `git merge-tree --write-tree main feat/x > /dev/null || { echo "fixture: the real repository did not merge"; …}` (`:1564`). A replica of that fixture gives `rc=0` with `160000 commit 85fedbb… sub` equal to `y=85fedbb…`. With `.git/modules/sm` moved away, the same merge is `rc=1` (`$FC/probe3.log`). Mutant `r9` (merge-tree run in the real repository) fails the new test and passes the old one (`$FC/mutants.log`).

**Evidence:** `test/scripts/build-loop-check.bats:1400-1416`, `test/scripts/build-loop-check.bats:1553-1567`, `$FC/probe3.log`, `$FC/mutants.log` (r9)

---

## Claim 6a: "A15 test added; A16 diff-tree runs in the gate repository with --ignore-submodules=none (plan F8 corrected); A17 GIT_CONFIG_NOSYSTEM=1 … A19 help and comments fixed."

**Location:** `docs/reviews/override-log.md:511`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the A15 test's existence and that it discriminates, the A16 call site, A17's export and its effect, and the A19 text changes. It does not establish a test for A16: no test plants `submodule.<name>.ignore=all` (probe4 case 2 checked it by hand).
**Legibility-target:** for-orchestrator-synthesis

A15 is the test at `test/scripts/build-loop-check.bats:1569-1575`. A mutant that moves `state_gate` after `resolve_main` fails it with `build-loop.sh needs a default branch found by name…` (`$FC/mut2.log`). A16 is `gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree"` (`scripts/build-loop.sh:578`); see Claim 25. A17 is `export … GIT_CONFIG_NOSYSTEM=1 …` (`scripts/build-loop.sh:195`); see Claim 15. A19 is the help and comment diff at `scripts/build-loop.sh:85-108,134-136,202-206,223`.

**Evidence:** `scripts/build-loop.sh:195`, `scripts/build-loop.sh:578`, `test/scripts/build-loop-check.bats:1569-1575`, `$FC/mut2.log`, `$FC/probe4.log`

---

## Claim 6b: "(alternates, packs and the multi-pack-index stay with the F3 row, trigger U3)"

**Location:** `docs/reviews/override-log.md:511`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers which row "the F3 row" can mean and that row's trigger. It does not establish whether Q-103 already lists these object sources (Q-103 was not read).
**Legibility-target:** for-author

The row meant is the U2b1a "iteration 2 security F3" row, which does carry trigger U3: `Revisit trigger: U3's `--merge`, before anything moves main: re-hash each blob a decision reads` (`docs/reviews/override-log.md:492`). That row is about rewriting a loose object's bytes, though. It does not name alternates, packs or the multi-pack-index, so "stay with" describes a row that does not yet record them. The prior rubric made the same point: `Alternates, packs and the multi-pack-index are object sources F3's row does not name` (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:27`). "The F3 row" also reads naturally as the plan's F3 (`| F3 | Policy lowered after a loop started |`, `docs/working/plan-build-loop-handoff.md:118`). A more precise wording: "deferred to row 492's trigger (U3); row 492 to name them".

**Evidence:** `docs/reviews/override-log.md:492`, `docs/reviews/override-log.md:511`, `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:27`, `docs/working/plan-build-loop-handoff.md:118`

---

## Claim 6c: "A18 not changed (no new history walk but merge-base --all, one per brief)"

**Location:** `docs/reviews/override-log.md:511`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the new git calls the branch adds per brief. It does not cover merge-tree's internal merge-base computation, which predates the branch.
**Legibility-target:** for-orchestrator-synthesis

The branch adds `gate_git merge-base --all "$MAIN_SHA" "$1"` (`scripts/build-loop.sh:514`), one per brief, through merge_result. The other new git calls read objects without walking history: `cat-file -e` (`:517`), `diff-tree` (`:578`), `cat-file blob` and `hash-object` (`:531,533`).

**Evidence:** `scripts/build-loop.sh:512-534`, `scripts/build-loop.sh:578`

---

## Claim 7: "plumbing `diff-tree` in the gate repository (no repo config, no checkout `.gitmodules`) with `--ignore-submodules=none`: `-c diff.ignoreSubmodules=none` does not override `submodule.<name>.ignore=all` (U2b1a2 A16, probed; U2b1b)"

**Location:** `docs/working/plan-build-loop-handoff.md:123`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's diff-tree with `submodule.sm.ignore=all` set in both `.git/config` and `.gitmodules`. It does not establish the behaviour of other git versions.
**Legibility-target:** for-orchestrator-synthesis

The probe printed nothing for plain `diff-tree` and nothing for `-c diff.ignoreSubmodules=none`. With `--ignore-submodules=none` it printed `:160000 160000 aaaa… bbbb… M	sub` (`$FC/probe3.log`). The script's call is at `scripts/build-loop.sh:578`.

**Evidence:** `scripts/build-loop.sh:578`, `$FC/probe3.log`

---

## Claim 8: "U2b1b (built): the verdict line comes first (`ok BRIEF TIP TREE`, or `refuse BRIEF: K of N changed paths refused`), then `path BRIEF S PATH` or `deny BRIEF S PATH: WHY` per changed path; exit 0 only when every verdict line is ok."

**Location:** `docs/working/plan-build-loop-handoff.md:212`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output order and formats and the exit rule. It does not cover `--merge`, which is not built.
**Legibility-target:** for-orchestrator-synthesis

Rows are built as `rows+=("deny $a $s $shown: $DENY")` or `rows+=("path $a $s $shown")` (`scripts/build-loop.sh:588`). For the verdict and the exit rule, see Claim 1.

**Evidence:** `scripts/build-loop.sh:588-593`, `scripts/build-loop.sh:611-615`, `$FC/suite.log`

---

## Claim 9: "Built 2026-10-08 (`feat/build-loop-u2b1b`, cc9b69d3, 317 lines): the mode rule is an N rule (both policies), so floor item 5 is already enforced before U2c; the own brief also keeps its mode; plus U2b1a2's carried R6, R7, R9, A15, A17 and A19 (override rows 497, 507-511)."

**Location:** `docs/working/plan-build-loop-handoff.md:283`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count, floor item 5's content, the policy-independence of the mode rule and the mode-kept check. It does not establish that row 497 is a U2b1a2 row: it is a U2b1a row, listed alongside.
**Legibility-target:** for-orchestrator-synthesis

`git show --numstat cc9b69d3` gives 129+25 and 153+10, which is 317. Floor item 5 is `5. symlinks and gitlinks. The executable bit is allowed.` (`docs/working/plan-build-loop-handoff.md:73`). `nrules` never reads `$POLICY` (paraphrased — no quote available because the claim is the absence of a reference across `scripts/build-loop.sh:541-552`). The own brief is checked with `"$2" == "$3"` (`:547`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:73`, `scripts/build-loop.sh:541-552`

---

## Claim 10: help, the state-gate list: config keys (common config or config.worktree, includes not followed) for filter, include, config hook, merge or diff setting, core.fsmonitor, core.attributesFile, core.hooksPath, gpg.*, log.showSignature, extensions.partialClone or remote.*.promisor; an info/attributes, info/grafts or shallow that is not absent or an empty file; a replace ref; an origin/HEAD naming any branch but origin/main or origin/master; then both main and master, or origin/HEAD naming another branch than the one taken. "Each finding prints "refuse state WHAT: WHY" and exits 2 before any brief is read ("refuse state gate: WHY" when the gate's own merge repository cannot be set up)."

**Location:** `scripts/build-loop.sh:80-92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed item against `STATE_KEYS_RE`, state_gate, the R7 block and the gate_repo failure line. It does not establish that "before any brief is read" holds for `refuse state gate:`: `read_settings` and `open_shared` run before gate_repo (`:606-609`), though they read main's files, not the brief arguments.
**Legibility-target:** for-orchestrator-synthesis

The key regex is `STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'` (`:209`), read with `git config --file "$p" --no-includes --name-only --get-regexp` over `config config.worktree` (`:212-215`). The file test is `[[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]` (`:223`). Replace refs are checked at `:225-226`, origin/HEAD at `:227-230`, and the R7 block at `:244-252`. Each of these exits 2 before `check_line` runs. The gate_repo failure prints `refuse state gate: its merge repository could not be set up` and exits 2 (`:609`). State-gate tests pass in `$FC/suite.log`.

**Evidence:** `scripts/build-loop.sh:209-232`, `scripts/build-loop.sh:238`, `scripts/build-loop.sh:244-252`, `scripts/build-loop.sh:605-615`, `$FC/suite.log`

---

## Claim 11: help, the verdict lines: "ok BRIEF TIP TREE … TREE is the merge of TIP into main as merge-tree writes it, run where no repo config or checkout attributes are read; and no changed path is denied." / "refuse … or the merge (or its changed paths) could not be computed: git failed, or warned on stderr (a missing tree object), or the tree of main, TIP or a merge base is missing. Or "K of N changed paths refused", when deny lines follow."

**Location:** `scripts/build-loop.sh:94-110`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ok condition, the new refusal causes and the K of N line. It does not establish that missing blobs or subtrees refuse (the help does not claim they do): merge-tree passes one it never reads by id, and `--check` prints ok (`$FC/probe4.log` case 3).
**Legibility-target:** for-orchestrator-synthesis

check_line prints `"ok $a $sha $tree"` only when `nd` is 0 (`:592`). The listing and parse refusals are at `:578-580`, `:583-584` and `:591`. For merge_result's causes, see Claim 19.

**Evidence:** `scripts/build-loop.sh:512-522`, `scripts/build-loop.sh:558-594`, `$FC/probe4.log`

---

## Claim 12: help: "one line per path TREE changes against main (diff-tree -r --no-renames, so a rename is its D and A sides), in diff-tree's order; S is its status letter (A, M, D or T) and PATH is "?" unless every character is one pathform allows: path BRIEF S PATH / deny BRIEF S PATH: WHY"

**Location:** `scripts/build-loop.sh:111-117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the formats, the order, the status letters and the "?" rule (characters only). It does not establish that every printed PATH passes pathform: `-x.md` and `.github/w.yml` print as written although pathform refuses them, which matches the help's "every character" wording.
**Legibility-target:** for-orchestrator-synthesis

The parse is `^:([01234567]{6})\ ([01234567]{6})\ [0123456789abcdef]+\ ([0123456789abcdef]+)\ ([AMDT])$` (`:583`), and any other letter refuses the brief. The display rule is `shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"` (`:586`). `NAMECHARS` is pathform's own set (`scripts/lib/dev-cycle-read.sh:181,183`). T13 shows three `?` lines (space, non-ASCII, newline), and T11 shows the D and A sides of a rename. Both pass in `$FC/suite.log`.

**Evidence:** `scripts/build-loop.sh:578-589`, `scripts/lib/dev-cycle-read.sh:181-191`, `test/scripts/build-loop-check.bats:1496-1524`, `$FC/suite.log`

---

## Claim 13: help, the N rules: "under either policy: a path pathform refuses (a .git part included); a mode other than 100644 or 100755 on either side (a symlink or gitlink); the brief's own file, unless only its first Status: line outside a fence changes, from open to done (mode kept); and, compared lower-cased, the dev cycle's own files (the roadmap, the questions files, the idea log, docs/dev-cycle.md, anything under docs/working/briefs/ or docs/working/cycles/) and docs/constraints.md."

**Location:** `scripts/build-loop.sh:118-126`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each rule against `nrules` and the lib. It reads "a mode … on either side" as excluding an absent side, which the code allows (`000000`), so adds and deletes of regular files pass. It does not establish case-insensitive matching of the own brief, which is compared exactly; a case variant is still denied as a cycle file.
**Legibility-target:** for-orchestrator-synthesis

The mode test is `[[ ! "$2 $3" =~ ^(000000|100644|100755)\ (000000|100644|100755)$ ]]` (`:545`). The own brief: `[[ "$5" == M && "$2" == "$3" && "$4" == "$(own_blob "$1")" ]]` (`:547`). The cycle files: `writable "$lp" || [[ "$lp" =~ ^docs/(dev-cycle\.md$|working/(briefs|cycles)/) ]]` (`:549`), where `lp="$(lower "$6")"` (`:548`). The constraints doc: `[[ "$lp" == docs/constraints.md ]]` (`:550`). For writable's coverage, see Claim 23.

**Evidence:** `scripts/build-loop.sh:541-552`, `scripts/lib/dev-cycle-read.sh:202-205`, `$FC/suite.log`

---

## Claim 14: "Exit: 0 every line printed (or help), and for --check every verdict line ok; 2 any --check verdict line or the state gate not ok; 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:134-136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new verdict-line wording and exit 2 for state-gate, default-branch and gate-setup refusals. The exit-1 causes were not re-probed and are unchanged on this branch.
**Legibility-target:** for-orchestrator-synthesis

The check loop exits 2 on any non-ok first line (`:611-615`). Deny or path lines never reach this test, because each one follows a verdict. Tests assert exit 2 on a K of N refusal (T11-T15) and exit 0 on ok with path lines (`test/scripts/build-loop-check.bats:1260-1261`). All pass in `$FC/suite.log`.

**Evidence:** `scripts/build-loop.sh:605-616`, `test/scripts/build-loop-check.bats:1256-1264`, `$FC/suite.log`

---

## Claim 15: "GIT_CONFIG_NOSYSTEM: the system config is no more the gate's than the user's (merge.directoryRenames there flipped a conflict: A17)."

**Location:** `scripts/build-loop.sh:193-195`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a system-config `merge.directoryRenames=true` (via `GIT_CONFIG_SYSTEM`) flips a directory-rename conflict to ok without the export, and that HEAD's script refuses it. It also covers gate_repo keeping the variable, since `GIT_CONFIG_NOSYSTEM` is not in `--local-env-vars` and so is never unset. It does not establish behaviour for a root-owned `/etc/gitconfig` specifically.
**Legibility-target:** for-orchestrator-synthesis

With HEAD's script: `refuse …: feat/x conflicts with the default branch`, exit 2. With a copy lacking `GIT_CONFIG_NOSYSTEM=1`: `ok … ` plus `path … A b/new`, exit 0 (`$FC/probe5.log`). The shim test pins `S=1` on every call, and mutant `a17` fails it (`$FC/mutants.log`).

**Evidence:** `scripts/build-loop.sh:195`, `scripts/build-loop.sh:492`, `test/scripts/build-loop-check.bats:1375-1389`, `$FC/probe5.log`, `$FC/mutants.log` (a17)

---

## Claim 16: state_gate's comment: "Keys, in the common config and this worktree's config.worktree: filter, merge and diff drivers (commands), config hooks, includes, core.fsmonitor, core.attributesFile, core.hooksPath, gpg and log.showSignature (gpg.program runs), and a partial clone (extensions.partialClone, remote.*.promisor …). Files: an info/attributes, info/grafts or shallow that is not absent or an empty regular file …"

**Location:** `scripts/build-loop.sh:196-208`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the key list and the file test against the code. It does not establish anything about keys outside the regex (`submodule.*.ignore`, for example, is not refused; A16's flag handles it).
**Legibility-target:** for-author

The file wording matches `[[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]` (`:223`): only an absent path, or an empty non-symlink regular file, passes. The key list understates the regex, though. `merge\.` and `diff\.` refuse every `merge.*` and `diff.*` key, not only drivers (`:209`), and the suite plants `merge.renormalize=true diff.ignoreSubmodules=all` as refused keys (`test/scripts/build-loop-check.bats:1320`). The help already says "merge or diff setting" (`:83`). The precise wording would be "any merge.* or diff.* key (drivers run commands)".

**Evidence:** `scripts/build-loop.sh:83`, `scripts/build-loop.sh:196-232`, `test/scripts/build-loop-check.bats:1320`

---

## Claim 17: "--check takes the default branch only when no other name could claim it: a loop can create a local master beside main (or main beside master) and point origin/HEAD at it, and resolve_main would follow (R7)." Behaviour: "refuse state default-branch: both main and master exist" / "…: origin/HEAD names X, but the default branch taken is MAIN", exit 2.

**Location:** `scripts/build-loop.sh:241-252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers resolve_main following origin/HEAD first, both refusals and their exit status. It also covers a broader case: origin/HEAD naming origin/master while only a local main exists is refused too (probe4 case 4), which is consistent with the help. It does not cover a non-symbolic origin/HEAD, which `symbolic-ref -q` reads as empty and so ignores, as resolve_main does.
**Legibility-target:** for-orchestrator-synthesis

resolve_main puts origin/HEAD's branch first: `[[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")`, then `candidates+=(main master)` (`scripts/lib/dev-cycle-read.sh:492-493`). The block refuses on `git show-ref --verify --quiet refs/heads/main && git show-ref --verify --quiet refs/heads/master`, and on `[[ -n "$p" && "$p" != "refs/remotes/origin/$MAIN" ]]` (`:245-250`). Probe4 case 4 printed `refuse state default-branch: origin/HEAD names origin/master, but the default branch taken is main`, exit 2. The R7 test passes on HEAD and fails under mutant `r7`.

**Evidence:** `scripts/build-loop.sh:239-252`, `scripts/lib/dev-cycle-read.sh:488-510`, `$FC/probe4.log`, `$FC/mutants.log` (r7)

---

## Claim 18: "gate_git ARGS...: git in the gate repository, stdout passed through; returns git's status, or 3 when git wrote anything to stderr (a missing object can warn and still exit 0: R6)."

**Location:** `scripts/build-loop.sh:499-501`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the return codes and git 2.39.5 warning with exit 0 for a missing top-level tree. It does not cover concurrent writers to `$GATE_TMP/err` (R8's class).
**Legibility-target:** for-orchestrator-synthesis

The code: `(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@") 2>"$GATE_TMP/err" || rc=$?; [[ ! -s "$GATE_TMP/err" ]] || return 3; return "$rc"` (`:503-506`; the whole function). Probe1 case A (missing base top-level tree) gave `rc=0 out=be82…` with stderr `error: Could not read d181…`, and case B (missing tip tree) gave `rc=0` with `error: Could not read 5697…` (`$FC/probe1.log`).

**Evidence:** `scripts/build-loop.sh:502-507`, `$FC/probe1.log`

---

## Claim 19: merge_result: "returns 1 on a conflict …, 2 when git failed or warned, or the tree of main, the tip or a merge base is missing (R6)"; plus whether merge-base exit 1 (no base) is handled.

**Location:** `scripts/build-loop.sh:508-511`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each return path and the no-base case. It does not establish refusal of missing subtrees or blobs that merge-tree never reads; the comment does not claim it.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:514-521
bases="$(gate_git merge-base --all "$MAIN_SHA" "$1")" || rc=$?
[[ "$rc" -le 1 ]] || return 2
for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done
rc=0; out="$(gate_git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1")" || rc=$?
[[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2
[[ "$rc" -eq 0 ]] || return 1
echo "${out%%$'\n'*}"
```
(the whole function, `:512-522`.) A missing tree makes `cat-file -e` exit 128 with `fatal: Not a valid object name main~1^{tree}` (`$FC/probe1.log` case A), which returns 2. No base: `merge-base rc=1 out=[]`, then `merge-tree rc=128` with `fatal: refusing to merge unrelated histories` (probe1 case E), so the stderr guard gives rc 3 and merge_result returns 2. The brief is refused as "could not be computed", not passed. Exit 1 from merge-base is accepted only as "no base" (empty output). A merge-base that warns returns 3, which is above 1, so merge_result returns 2.

**Evidence:** `scripts/build-loop.sh:512-522`, `$FC/probe1.log`

---

## Claim 20: own_blob: "main's copy with its first Status: line outside a fence, the one brief_fields reads (status_line has read it as "Status: open"), reading "Status: done", every other byte kept (a CR at its end too)."

**Location:** `scripts/build-loop.sh:523-526`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the same line is selected as brief_fields, CR and missing-final-newline preservation, and that the brief is open at this point. It does not establish behaviour for a brief FENCE_AWK refuses, which is unreachable here because check_brief has already skipped it.
**Legibility-target:** for-orchestrator-synthesis

own_blob's awk is `"$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } !n && /^Status:/ { n = NR } END { print n + 0 }'` (`:531`). brief_fields runs the same prefix, `{ sub(/\r$/, "") } fence($0) { next }`, and keeps the first `match($0, /^(Status|…):/)` per key (`scripts/lib/dev-cycle-read.sh:364-367`), so both pick the same NR. The rewrite is `perl -pe 's/^Status: open(\r?)$/Status: done$1/ if $. == $ENV{N}'` (`:533`). Perl and awk both split on `\n`, so `$.` equals NR. `$` matches before the final `\n`, so a trailing CR is captured and re-emitted, and a last line without a newline still matches. Probe4 case 1 (no final newline on either side) printed `ok …` plus `path … M <brief>`. Case 1b (the branch adds a final newline) printed the NBRIEF deny (`$FC/probe4.log`). The T15 CRLF case passes. check_line refuses any state but open before nrules runs (`:563`).

**Evidence:** `scripts/build-loop.sh:527-534`, `scripts/build-loop.sh:563`, `scripts/lib/dev-cycle-read.sh:355-378`, `test/scripts/build-loop-check.bats:1473-1494`, `$FC/probe4.log`

---

## Claim 21: nrules: "for one changed path of brief $1: diff-tree's old and new modes $2 $3, new blob $4, status $5 and path $6. … Paths compare lower-cased (a case-insensitive checkout reads Docs/Roadmap.md as the roadmap)."

**Location:** `scripts/build-loop.sh:535-539`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the argument mapping and which comparisons lower-case. It does not establish a practical gap: a case variant of the own brief falls to the cycle-file rule and is denied.
**Legibility-target:** for-author

The call `nrules "$a" "$om" "$nm" "$no" "$s" "$p"` (`:587`) passes BASH_REMATCH groups 1-4, which are old mode, new mode, new oid and status (`:583-585`), so the mapping holds. Lower-casing applies only after the pathform, mode and own-brief branches: `elif ! lp="$(lower "$6")"` (`:548`) feeds just the cycle-file and constraints tests (`:549-550`). The own-brief test is the exact `[[ "$6" == "$1" ]]` (`:546`). Precise wording: "the cycle-file and constraints comparisons are lower-cased".

**Evidence:** `scripts/build-loop.sh:541-552`, `scripts/build-loop.sh:583-587`

---

## Claim 22: deny reasons: "not an allowed path form (letters, digits and . _ - / only, no .git part)" and "not a regular file on both sides (only modes 100644 and 100755 land)"

**Location:** `scripts/build-loop.sh:544-545`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both reasons against the conditions that trigger them. It does not cover the other three reasons, which Claim 23 verifies.
**Legibility-target:** for-author

pathform also refuses a leading `/` or `-` and an empty, `.` or `..` component: `[[ "$p" =~ $set && "$p" != /* && "$p" != -* ]]` and `[[ -n "$c" && "$c" != "." && "$c" != ".." && "$c" != [.][gG][iI][tT]* ]]` (`scripts/lib/dev-cycle-read.sh:185,189`). So `-x.md`, whose characters are all allowed and which has no .git part, gets this reason, and the reason does not say why (`has "deny $B A -x.md: $NFORM"`, `test/scripts/build-loop-check.bats:1521`). The mode reason says "on both sides", but an absent side (`000000`) passes (`:545`). It means "neither side is a non-regular entry".

**Evidence:** `scripts/build-loop.sh:544-545`, `scripts/lib/dev-cycle-read.sh:182-191`, `test/scripts/build-loop-check.bats:1517-1524`, `$FC/suite.log`

---

## Claim 23: the cycle-file and constraints rules: "one of the dev cycle's own files" covers the roadmap, the questions files, the idea log, docs/dev-cycle.md and anything under docs/working/briefs/ or cycles/; "the user's constraints doc".

**Location:** `scripts/build-loop.sh:549-550`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the union of `writable()` and the extra regex on the lower-cased path. It does not verify the design claim "which every loop prompt carries" (plan-level).
**Legibility-target:** for-orchestrator-synthesis

writable is `^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$`, or `cycles/cycle-DATE.md`, or `anybrief` (`scripts/lib/dev-cycle-read.sh:202-205`). The extra regex adds `docs/dev-cycle.md` and every path under `working/briefs/` and `working/cycles/` (`:549`). T14 exercises each listed file, including `docs/working/briefs/closed/x` and `docs/working/cycles/notes.md` (`test/scripts/build-loop-check.bats:1455-1462`), and passes.

**Evidence:** `scripts/build-loop.sh:548-551`, `scripts/lib/dev-cycle-read.sh:197-205`, `test/scripts/build-loop-check.bats:1451-1471`, `$FC/suite.log`

---

## Claim 24: check_line: "ok BRIEF TIP TREE" or "refuse BRIEF: K of N changed paths refused", then a path or deny line per path "(diff-tree's status letter S, in its order …)"; "Every record read whole: two NUL-ended fields each."

**Location:** `scripts/build-loop.sh:553-557`, `scripts/build-loop.sh:590-591`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the verdict-first order, diff-tree order (rows appended in read order) and the NUL count catching a record cut after its meta field. It does not establish detection of trailing bytes with no terminating NUL (`read -d ''` stops and the count still equals 2i), which git does not emit. No test pins the NUL check: mutant `nul` removes it and both path tests still pass.
**Legibility-target:** for-orchestrator-synthesis

The loop is `while IFS= read -r -d '' meta && IFS= read -r -d '' p; do i=$((i + 1)) …` (`:581-582`), followed by `[[ "$(tr -cd '\000' < "$GATE_TMP/diff" | wc -c)" -ne $((2 * i)) ]]` (`:591`). A meta read without its path leaves an odd count, 2i+1, which refuses. T14 asserts `lines[1]` and `lines[14]` in diff-tree's byte order (`test/scripts/build-loop-check.bats:1465`). Mutant result: `nul: bats exit 0; 2 ok` (`$FC/mutants.log`).

**Evidence:** `scripts/build-loop.sh:558-594`, `test/scripts/build-loop-check.bats:1465`, `$FC/mutants.log` (nul)

---

## Claim 25: "In the gate repository, so no repo config or checkout .gitmodules hides a moved gitlink (A16); --no-renames, so a rename is judged as both its sides (F6)."

**Location:** `scripts/build-loop.sh:576-577`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a moved gitlink with `submodule.sm.ignore=all` in both `.git/config` and the committed `.gitmodules`, and the rename split. It does not establish a test for A16 (none exists).
**Legibility-target:** for-orchestrator-synthesis

Probe4 case 2 printed `deny <brief> M sub: not a regular file on both sides …`, exit 2 (`$FC/probe4.log`). The rename split is the T11 test (`test/scripts/build-loop-check.bats:1496-1503`), which passes.

**Evidence:** `scripts/build-loop.sh:578`, `$FC/probe4.log`, `test/scripts/build-loop-check.bats:1496-1503`

---

## Claim 26: test name "--check lists every changed path and refuses the dev cycle's own files, other briefs and the constraints doc in any case; other paths pass (T14, F2, F12, F54, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1451`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the fixture plants. It does not establish "in any case" for other briefs or the constraints doc.
**Legibility-target:** for-author

Case variants appear only for the roadmap and dev-cycle.md: `Docs/Roadmap.md docs/Dev-Cycle.md` (`:1456`). `docs/constraints.md` and the other brief `"$o"` appear only in their stored case (`:1455,1457`). The test passes and lists every path (`"${#lines[@]}" -eq 15`, `:1458`).

**Evidence:** `test/scripts/build-loop-check.bats:1451-1471`, `$FC/suite.log`

---

## Claim 27: test name "--check: the brief's own file may change only its first Status: line outside a fence, open to done (T15, F13, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1473`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fenced Status line, dropped, an extra line, a mode change, a trailing blank line, a move to closed/ and CRLF. It does not cover a missing final newline (probe4 case 1 covers it by hand).
**Legibility-target:** for-orchestrator-synthesis

The snippets are at `:1479-1480`. Mutant `own`, which accepts any M of the own brief, fails this test (`$FC/mutants.log`).

**Evidence:** `test/scripts/build-loop-check.bats:1473-1494`, `$FC/mutants.log` (own)

---

## Claim 28: test name "--check: a rename is its two sides, so moving a cycle file out refuses its old path (T11, F6, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1496`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one rename out of `docs/roadmap.md`. It does not cover a rename into a denied path, though the A side would be denied by the same rule.
**Legibility-target:** for-orchestrator-synthesis

The test asserts `has "deny $B D docs/roadmap.md: $NOWN"; has "path $B A docs/x.md"` (`:1502`). It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1496-1503`, `$FC/suite.log`

---

## Claim 29: test name "--check refuses a symlink or gitlink on either side and passes an exec bit (T12, F7, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1505`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a symlink on the new side (`A link`, `T g.txt`), a symlink on the old side (`T was-link`), a new gitlink (`A gl`) and the exec bit. It does not cover a gitlink on the old side (gitlink to file, or a gitlink deleted).
**Legibility-target:** for-author

The test asserts `for p in "T g.txt" "A gl" "A link" "T was-link"; do has "deny $B $p: $NMODE"; done` (`:1513`). The only gitlink is added on the branch (`:1510`). The code is symmetric, so a gitlink on the old side would be denied (`scripts/build-loop.sh:545`), but the name's "either side" is tested only for symlinks.

**Evidence:** `test/scripts/build-loop-check.bats:1505-1515`, `scripts/build-loop.sh:545`, `$FC/suite.log`

---

## Claim 30: test name "--check refuses a changed path pathform refuses, and prints only a name in its character set (T13, F17, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1517`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `.github/`, a space, non-ASCII, a newline and a leading dash. It does not cover `..`, empty components or `.GIT` variants (pathform's lib tests cover those).
**Legibility-target:** for-orchestrator-synthesis

The test asserts `5 of 5` and three `deny $B A ?: $NFORM` lines (`:1520-1523`). It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1517-1524`, `$FC/suite.log`

---

## Claim 31: test name "--check refuses a merge git warned about: a missing tip or merge-base tree is not read as empty (R6, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1526`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers refusal for a missing tip tree and a missing merge-base tree (main~1 is the base after `onx` rebuilds feat/x from main and main moves on). It does not isolate either guard: with only the stderr guard removed, or only the cat-file guard removed, the test still passes.
**Legibility-target:** for-orchestrator-synthesis

Mutant results: `r6err: bats exit 0; 1 ok`, `r6cat: bats exit 0; 1 ok`, `r6both: … 1 not ok` (`$FC/mutants.log`). The "warned about" in the name is accurate to git's behaviour (`error: Could not read`, `$FC/probe1.log`), but either guard alone produces the refusal.

**Evidence:** `test/scripts/build-loop-check.bats:1526-1538`, `$FC/mutants.log`, `$FC/probe1.log`

---

## Claim 32: test name "--check refuses an ambiguous default branch: both main and master, or origin/HEAD naming a branch the gate did not take (R7, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1540`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both-present with and without origin/HEAD, and origin/HEAD naming origin/main with only master local. It does not cover origin/master with only main local (probe4 case 4 covers it).
**Legibility-target:** for-orchestrator-synthesis

The test passes on HEAD and fails under mutant `r7`.

**Evidence:** `test/scripts/build-loop-check.bats:1540-1551`, `$FC/mutants.log` (r7)

---

## Claim 33: test name "--check's merge reads no submodule repository: a gitlink fast-forward the real repository would merge is a conflict (R9, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1553`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the discriminating fixture. Under the mutant the gate still refuses, through the mode rule (sub is 160000); the test catches the mutant only through its exact "conflicts" message.
**Legibility-target:** for-orchestrator-synthesis

See Claim 5. Mutant `r9` fails this test (`$FC/mutants.log`).

**Evidence:** `test/scripts/build-loop-check.bats:1553-1567`, `$FC/probe3.log`, `$FC/mutants.log` (r9)

---

## Claim 34: test name "--check runs its state gate before resolve_main reads an object: a planted key refuses even with main's commit missing (A15, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1569`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of state_gate and resolve_main. It does not cover the ordering of read_settings or open_shared, which run after both.
**Legibility-target:** for-orchestrator-synthesis

A mutant that moves state_gate after main_by_name fails the test with `build-loop.sh needs a default branch found by name …` and `fatal: bad object refs/heads/main` (`$FC/mut2.log`).

**Evidence:** `scripts/build-loop.sh:237-240`, `test/scripts/build-loop-check.bats:1569-1575`, `$FC/mut2.log`

---

## Claim 35: test name "every git call --check makes carries harden's config pairs …, no global or system config and no transport (T26, A4, U2b1a i1, i2, A17)"

**Location:** `test/scripts/build-loop-check.bats:1375`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every logged call sees `GIT_CONFIG_NOSYSTEM=1` after the test unsets the fixture's copy (`:1382`). It does not plant a system config file itself; probe5 does.
**Legibility-target:** for-orchestrator-synthesis

The shim logs `S=$GIT_CONFIG_NOSYSTEM` and the test requires `S=1` on every line (`:1378,1386`). Mutant `a17` fails it.

**Evidence:** `test/scripts/build-loop-check.bats:1375-1389`, `$FC/mutants.log` (a17), `$FC/probe5.log`

---

## Claim 36: commit cc9b69d3 body: path lines "(diff-tree -r --no-renames --raw -z, run in the gate repository with --ignore-submodules=none: A16)"; verdict ok only when nothing is denied; "PATH prints as "?" unless every character is one pathform allows"; the N-rule list; "A17: GIT_CONFIG_NOSYSTEM=1; the shim test pins it"; "A19: help and comments: shallow, origin/HEAD, the default-branch check, "not an empty file", the verdict-line exit wording, "refuse state gate:"".

**Location:** commit `cc9b69d3` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed atom (see Claims 8, 12, 13, 15, 25). It does not cover the Notes' plan-history claims ("rev 2 marked T12 refuse under both"), which would need the rev 2 plan, not read. D3's symlink stop condition is confirmed at `docs/working/plan-build-loop-handoff.md:55`.
**Legibility-target:** for-orchestrator-synthesis

The A19 items are in the help diff: `info/grafts or shallow that is not absent or an empty file` (`:86`), `origin/HEAD naming any branch …` (`:87-89`), `"refuse state gate: WHY"` (`:91`) and `every verdict line ok` (`:134`).

**Evidence:** `scripts/build-loop.sh:80-136`, `scripts/build-loop.sh:195`, `scripts/build-loop.sh:578`, `docs/working/plan-build-loop-handoff.md:55`

---

## Claim 37a: commit cc9b69d3: "a missing top-level tree is read as empty with exit 0 … probed"

**Location:** commit `cc9b69d3` message (R6 bullet)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 merge-tree with a missing top-level tree on each of the three sides. It does not establish other git versions.
**Legibility-target:** for-author

"Read as empty" holds, and git always writes `error: Could not read <id>` to stderr. The exit status is whatever the empty-side merge gives, so it is not always 0. A missing base or tip tree gave `rc=0` (`$FC/probe1.log` A, B). A missing main tree gave `rc=1` with conflict stages for `d/a` (`$FC/probe2.log` H), because an empty main turns shared files into add/add conflicts. Precise wording: "read as empty, with a warning on stderr; exit 0 when that empty-side merge is clean". The fix holds either way: the cat-file guard and the stderr guard both fire.

**Evidence:** `$FC/probe1.log`, `$FC/probe2.log`, `scripts/build-loop.sh:505`, `scripts/build-loop.sh:517`

---

## Claim 37b: commit cc9b69d3: "a missing subtree or blob is fatal, probed"

**Location:** commit `cc9b69d3` message (R6 bullet)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers missing subtrees and blobs that merge-tree must read and ones it passes by id. It does not cover packed-object corruption.
**Legibility-target:** for-author

It is fatal only when merge-tree must open the object. A subtree both sides changed gave `rc=128 fatal: unable to read tree …`, and a content-merged blob gave `rc=128 fatal: unable to read blob object …` (`$FC/probe2.log` F, G). A missing subtree or blob carried through by id is never read. Probe1 cases C, C2, D and D2 gave `rc=0` with no stderr. Run end to end, `--check` printed `ok …` plus `path … A z.txt` for a branch whose only blob was missing (`$FC/probe4.log` case 3). The merged tree is the correct one, and the missing object was already absent on the branch. Precise wording: "a missing subtree or blob merge-tree must read is fatal; one it passes by id is not read".

**Evidence:** `$FC/probe1.log`, `$FC/probe2.log`, `$FC/probe4.log`

---

## Claim 38: commit cc9b69d3: R9 "a new test merges a gitlink fast-forward the real repository resolves cleanly (probed) … Mutant (merge-tree in the real repo) fails it"; "Mutants: R6 with both guards removed, R7 with the check off, R9 with merge-tree in the real repository each fail their test."

**Location:** commit `cc9b69d3` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named mutants. It does not cover single-guard R6 mutants, which survive (Claim 31); the message names only the both-guards one.
**Legibility-target:** for-orchestrator-synthesis

See `$FC/mutants.log`: `r6both … 1 not ok`, `r7 … 1 not ok`, `r9 … 1 ok, 1 not ok` (the new R9 test fails). The real-repository fast-forward is shown in `$FC/probe3.log`.

**Evidence:** `$FC/mutants.log`, `$FC/probe3.log`

---

## Claim 39: commit cc9b69d3: "Tests: build-loop-check 101 (92 + 9), build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2; shellcheck clean. … 317 changed lines."

**Location:** commit `cc9b69d3` message
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts, the pass status, shellcheck on `scripts/build-loop.sh` (the repo's lint covers `.sh`/`.bash`, per `scripts/health-check.sh:34`) and the numstat. The `.bats` file is not shellcheck-clean (63 findings against main's 53), but the repo's lint does not cover `.bats` files.
**Legibility-target:** for-orchestrator-synthesis

The `@test` counts are 101 on HEAD and 92 on main. All suites pass (`$FC/suite.log`, `$FC/suites2.log`). `shellcheck scripts/build-loop.sh` exits 0. The numstat sums to 129+25+153+10 = 317.

**Evidence:** `$FC/suite.log`, `$FC/suites2.log`, `scripts/health-check.sh:34`

---

## Claim 40: commit 809df345: "F8 names the gate repository and --ignore-submodules=none (the -c diff.ignoreSubmodules=none form does not override a planted submodule.<name>.ignore=all); the --check interface line describes the verdict, path and deny lines; step 5's U2b1b note records what was built. Override log rows 497 and 507-511 gain their U2b1b resolution. R8 is left open with a proposal (a Q-103 residual)."

**Location:** commit `809df345` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each sentence against the docs diff and probe3. Claim 6b's wording issue sits inside row 511 and does not contradict this message.
**Legibility-target:** for-orchestrator-synthesis

See Claims 1-9. The docs diff touches exactly rows 497 and 507-511 and plan lines 123, 212 and 283.

**Evidence:** `docs/reviews/override-log.md:497`, `docs/reviews/override-log.md:507-511`, `docs/working/plan-build-loop-handoff.md:123`, `docs/working/plan-build-loop-handoff.md:212`, `docs/working/plan-build-loop-handoff.md:283`, `$FC/probe3.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 6b** (`docs/reviews/override-log.md:511`): "stay with the F3 row" points at row 492, which has trigger U3 but does not name alternates, packs or the multi-pack-index. "F3" is also ambiguous with the plan's F3 row.
- **Claim 16** (`scripts/build-loop.sh:196-208`): the comment says "merge and diff drivers", but the regex refuses every merge.* and diff.* key (the help is right).
- **Claim 21** (`scripts/build-loop.sh:535-539`): "Paths compare lower-cased" is true only for the cycle-file and constraints tests. The own-brief test is exact (no practical gap).
- **Claim 22** (`scripts/build-loop.sh:544-545`): NFORM's parenthetical omits a leading `-` or `/` and empty, `.` or `..` parts (so `-x.md` gets a reason that does not explain it). NMODE's "on both sides" hides that an absent side passes.
- **Claim 26** (`test/scripts/build-loop-check.bats:1451`): "in any case" is exercised only for the roadmap and dev-cycle.md.
- **Claim 29** (`test/scripts/build-loop-check.bats:1505`): "gitlink on either side" is tested only on the new side.
- **Claim 37a** (commit cc9b69d3): a missing top-level tree is read as empty with a stderr warning. Exit 0 only when that merge is clean (a missing main tree gave exit 1).
- **Claim 37b** (commit cc9b69d3): a missing subtree or blob is fatal only when merge-tree reads it. One passed by id is silent, and `--check` prints ok (probe4 case 3).

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, every finding with verbatim Evidence and `path:line`.
- Answered: yes. Every claim on the caller's list was checked, most by execution (suites, probes, 7 mutants).
- Out of scope: R8's disposition (left to the review loop); the rev 2 plan history in cc9b69d3's Notes; hallucination-log append (nothing qualifies, and the task forbids writes outside this report).
- Escalate: no test pins the NUL-count check or A16 (mutant `nul` survives; A16 checked only by probe). Each R6 guard alone passes the R6 test. A merge whose tree references a missing blob prints ok (honest-path impact nil: the merge is correct; worth one line in the help or a Q-103 note).
- Decisions I made: execution logs live in my scratch dir, not `docs/reviews/execution-logs/` (the task says write nothing else in the worktree). Mutants ran on `git archive` copies under the scratch dir, not in the worktree.
