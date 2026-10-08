Commit: e02d056b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1b (branch `feat/build-loop-u2b1b`, HEAD e02d056b, base main 0e4596ce)
**Scope:** full branch, `git diff main...HEAD` (cc9b69d3, 809df345, a382a3f8, e02d056b). Checked: `scripts/build-loop.sh` (the `--check` help and every comment the branch added or edited), `scripts/lib/dev-cycle-read.sh` (contract item 5, truthrule's comment), the tests added or renamed in `test/scripts/build-loop-check.bats`, the plan's edited lines, override-log rows 494, 497 and 507-520, and the four commit messages. The review reports the branch adds are not checked. Canonical merge of three replicate reports (`code-fact-check-report-build-loop-u2b1b-final-r1.md`, `-r2.md`, `-r3.md`).
**Checked:** 2026-10-08
**Total claims checked:** 71
**Summary:** 55 verified, 9 mostly accurate, 2 stale, 4 incorrect, 1 unverifiable
**Commit:** e02d056b
**Replication:** k=3

Merge method. Claims were clustered across replicates by file, overlapping line range (±5) and assertion. Each cluster is emitted at the finest granularity any replicate used; a replicate that verdicted a compound claim has that verdict recorded on each sub-claim row, marked `(compound)`. The verdict is the most severe any replicate gave (Incorrect > Stale > Mostly accurate > Unverifiable > Verified). The evidence, reasoning, Type, Confidence, Verification mode and Scope are the winning replicate's. Ties among equal verdicts went to the most specific Scope line, which in practice meant a non-compound claim over a compound one, and then to the lowest replicate number. Each replicate's own scratch directory is written `$S1`, `$S2` and `$S3` below, in place of the `$S` each report used.

Execution provenance, by replicate (shared by every `executed` claim that replicate won):
- **r1.** `S1=/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i3/fc-r1`. git 2.39.5, bash 5.2, WSL2.
  - Suites ran at HEAD e02d056b from the worktree (through the `scratchpad/wt` symlink), starting 2026-10-08T22:16:24Z, each as `TMPDIR=$(mktemp -d -p $S1) timeout 900 bats test/scripts/<suite>.bats`. Results: build-loop-check 101 ok, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2, all exit 0. `shellcheck scripts/build-loop.sh` exited 0. Logs: `$S1/logs/<suite>.log`, `$S1/logs/shellcheck.log`.
  - Mutants: each a `git archive e02d056b scripts test` copy in `$S1/<mutant>/`, changed by one perl substitution, run as `TMPDIR=… LC_ALL=C bats -f 'T11|T12|T13|T14|T15|R6, U2b1b|R7, U2b1b|R9, U2b1b|A15, U2b1b|A17\)' test/scripts/build-loop-check.bats` from 2026-10-08T22:17:00Z. Logs: `$S1/logs/mut-<mutant>.log`. Results: `base` 10/10 ok; `mR6both` fails only R6; `mR6err` and `mR6tree` exit 0; `mR7` fails only R7; `mR9` fails only R9; `mA17` fails only the shim test; `mA15` (described as "state_gate moved after resolve_main") fails only A15; `mF2` fails only R6; `mMode` fails only T15; `mA16a` and `mA16b` exit 0; `mA16both` fails only T12; `mNUL` passes the whole suite 101/101 (22:20:21Z).
  - Probes (`set -eu`, own `mktemp -d -p $S1`, logged to `$S1/logs/<probe>.log`, exit 0): probe1 (22:18:29Z, P2), probe2 (22:18:56Z, P1b and P3), probe3 (22:19:09Z, P4 timing), probe4 (22:20:12Z, P5), and an inline NUL-fragment loop at about 22:22Z (`$S1/logs/probe-frag.log`).
- **r2.** `S2=/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i3/fc-r2`. git 2.39.5.
  - Suites from the worktree at e02d056b, started 2026-10-08T22:16:49Z: `TMPDIR=$(mktemp -d -p $S2) bats -j 8 test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats` exited 0 with 124 ok (`$S2/logs/bats.txt`); `bats -j 8 test/scripts/dev-cycle.bats` exited 0 with 78 ok (`$S2/logs/bats-dc.txt`); `shellcheck scripts/build-loop.sh` exited 0.
  - Mutants by `python3 $S2/probes/mutants.py`, cwd `$S2`, from 2026-10-08T22:19Z: each a copy of `scripts/` and `test/` under `$S2/mut/<name>-*/`, one exact substitution asserted to match once, run as `bats -j 8 -f <filter>`. Each log holds command, cwd, timestamp and exit code (`$S2/logs/mut-<name>.txt`).
  - Probes (`set -eu`, own mktemp dir under `$S2`, run as `timeout N bash $S2/probes/<p>.sh > $S2/logs/<p>.txt`): p1-mergetree (22:18:49Z, exit 0, cases A-G), p2-a15 (22:20:17Z, exit 128 from its last diagnostic line, after both runs printed), p3-time (22:20:33Z, exit 0), p4-f8-a17 (22:22:08Z, exit 0).
- **r3.** `S3=/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i3/fc-r3`. git 2.39.5.
  - Suites from the worktree via `scratchpad/wt` at e02d056b: `TMPDIR=$(mktemp -d -p $S3) bats test/scripts/build-loop-check.bats` started 2026-10-08T22:17:03Z, exit 0, 101 ok (`$S3/logs/check.log`). build-loop-read (19), dev-cycle (78), fixture-git-env (2), fixture-hermeticity (2) and `shellcheck scripts/build-loop.sh` all exited 0 (`$S3/logs/others.log`).
  - Mutants: each a `git archive e02d056b scripts test` copy in `$S3/<mutant>/`, one perl edit, run as `bats -f <filter> test/scripts/build-loop-check.bats` from 2026-10-08T22:18:27Z (summary `$S3/logs/mutants.log`, per-mutant `$S3/logs/mut-<name>.log`): mF2, mR6, mR7, mDG, mR9 and mA16b fail their tests (rc 1); mA16a and mA16c pass T12 (rc 0); mA15 (described as "state_gate moved after resolve_main") fails A15 (rc 1); mT14a passes T14, T15 and T11 (rc 0); mT14b fails T14 and T11 (rc 1).
  - Probes (`set -eu`, own `mktemp -d -p $S3`): probe1 (22:19:34Z, exit 0, P1-P4), probe2 (22:19:48Z, exit 0, 1,000 `lower` calls and 5,000-path timing), probe3 (22:21:54Z, exit 0, lib shellcheck, NUL-count edge, cc9b69d3 at 5,000 paths).
- **Hallucination-pattern log.** All three replicates read `docs/reviews/hallucination-patterns.md`. The only nearby pattern is the "test tally" entry; every tally was checked by `grep -c '^@test'` and by suite runs, and all match. No Incorrect verdict is a fabricated symbol.

---

## Claim 1: override row 494 addition: "the gate repository closes merge-tree" holds against state planted before the run, not against a concurrent same-uid writer (R8, row 509)

**Location:** `docs/reviews/override-log.md:494`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the row's cross-reference and the fact that gate_repo writes files a same-uid writer can reach under `$GATE_TMP` (`scripts/build-loop.sh:497-506`). It does not cover a race probe, which this pass did not run.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not cover a race probe, which this pass did not run" · r2+r3: "R8's timing (~40 ms) was not re-measured"

`printf '[core]\n\trepositoryformatversion = 1\n…' > "$GATE_TMP/git/config"` (`scripts/build-loop.sh:504`) is written after `mkdir`, in the caller's `mktemp -d` (`scripts/build-loop.sh:640`). Row 509 holds R8.

**Evidence:** `scripts/build-loop.sh:488-506`, `scripts/build-loop.sh:640`, `docs/reviews/override-log.md:509`

---

## Claim 2: override row 497 addition: "the first line is the verdict line; path and deny lines follow it, and the help says 'every verdict line ok'"

**Location:** `docs/reviews/override-log.md:497`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers check_line's output order and the main loop's exit test. It does not cover `--merge`.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not cover `--merge`" · r2: "does not establish that a caller reading only the first line is safe from a deny line, which the verdict line carries as 'K of N'" · r3: "does not cover a skip or refuse line from status_line, which is a single line with no path lines after it"

```bash
# scripts/build-loop.sh:643-647
    for a in "${ARGS[@]}"; do
      out="$(check_line "$a")"; printf '%s\n' "$out"
      [[ "$out" == "ok "* ]] || fails=1
    done
    [[ "$fails" -eq 0 ]] || exit 2
```
The help reads `# Exit: 0 every line printed (or help), and for --check every verdict line ok;` (`scripts/build-loop.sh:137`). T14 checks `lines[0]` as the verdict, followed by 16 path lines.

**Evidence:** `scripts/build-loop.sh:137-139`, `scripts/build-loop.sh:626-627`, `scripts/build-loop.sh:635-649`, `$S1/logs/build-loop-check.log`

---

## Claim 3: override row 507: "Fixed in cc9b69d3 (U2b1b): gate_git refuses any stderr; the trees of main, the tip and each merge base must exist; the test fails with both guards removed."

**Location:** `docs/reviews/override-log.md:507`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both guards in code and the double mutant. It does not establish that either guard alone is pinned (row 514: neither is).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering rows 507 and 514; does not cover row 514's 'no case found where only stderr catches it' beyond the R6 test's cases" · r2+r3: "does not establish that either guard alone is pinned (row 514)"

`[[ ! -s "$GATE_TMP/err" ]] || return 3` (`scripts/build-loop.sh:513`). `for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done` (`:525`). Mutant `R6-both` removes both, and the R6 test fails (`not ok 1`, `$S2/logs/mut-R6-both.txt`).

**Evidence:** `scripts/build-loop.sh:510-530`, `$S2/logs/mut-R6-both.txt`

---

## Claim 4: override row 508: "Fixed in cc9b69d3: --check refuses both main and master, or origin/HEAD naming a branch other than the one taken (`refuse state default-branch:`)"

**Location:** `docs/reviews/override-log.md:508`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers default_gate's two findings and their prefix under --check. It does not cover --status or --settings, which do not call default_gate (row 517).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering rows 508 and 510; does not cover `--status` (which, as row 517 records, has no default-branch refusal)" · r2: "does not cover --status or --settings, which do not call default_gate (row 517)" · r3: "does not cover `--status` and `--settings`, which still follow origin/HEAD (row 495, deferred)"; r3 also ran mDG (only the origin/HEAD check removed), which fails R7

`echo "refuse state default-branch: both main and master exist"` and `echo "refuse state default-branch: origin/HEAD names ${p#refs/remotes/}, but the default branch taken is $MAIN"` (`scripts/build-loop.sh:245,248`). It is called only as `if [[ "$MODE" == check ]]; then default_gate || exit 2; fi` (`:260`). The R7 test passes, and mutant `R7-off` fails it (`$S2/logs/mut-R7-off.txt`).

**Evidence:** `scripts/build-loop.sh:241-251`, `scripts/build-loop.sh:260`, `test/scripts/build-loop-check.bats:1553-1570`, `$S2/logs/mut-R7-off.txt`

---

## Claim 5: override row 509: R8 decided a Q-103 residual; surface `$GATE_TMP/git/config`, `git/info/`, `work/.gitattributes`, `err`, `diff` ("merge-base, cat-file, diff-tree and hash-object now run there too"); i2: "also holds git/refs/ and git/HEAD; the missing-blob batch-check adds one more gate_git call"

**Location:** `docs/reviews/override-log.md:509`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the list of files gate_repo and gate_git write and the gate_git callers. It does not cover whether the race is exploitable (the threat-scope decision is the reviewers').
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not cover whether the race is exploitable (the threat-scope decision is the reviewers')" (escalation-shaped, see Escalations) · r2: "does not establish that the list is the complete set of files a racing writer could plant (for example `git/objects/info/alternates` is outside GATE_TMP and belongs to row 492)" · r3: "does not cover the decision itself (a judgment) or a measurement of the race"; r3 notes `git/info/` and `work/.gitattributes` are not created by the script but are paths a racer could create

gate_repo makes `"$GATE_TMP/git" "$GATE_TMP/git/refs" "$GATE_TMP/work"` and writes `git/HEAD` and `git/config` (`scripts/build-loop.sh:501-504`). gate_git writes `$GATE_TMP/err` (`:512`), and check_line writes `$GATE_TMP/diff` (`:599`). gate_git callers are merge-base, `cat-file -e`, merge-tree (`:522-526`), diff-tree (`:599`), hash-object (`:542`) and `cat-file --batch-check` (`:614`) (paraphrased — no quote available because the callers span four functions; each line is cited).

**Evidence:** `scripts/build-loop.sh:497-529`, `scripts/build-loop.sh:536-543`, `scripts/build-loop.sh:599`, `scripts/build-loop.sh:614`

---

## Claim 6: override row 510: "Fixed in cc9b69d3 (U2b1b): the old test keeps its base gitlink; a new one merges a gitlink fast-forward that the real repository resolves cleanly; merge-tree in the real repository fails it."

**Location:** `docs/reviews/override-log.md:510`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both tests and the merge-tree mutant. It does not establish the old test's own discrimination under the same mutant, because the mutant was run only with the R9 filter.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering rows 508 and 510" · r2: "does not establish the old test's own discrimination under the same mutant" · r3: "does not cover a gitlink conflict whose submodule repository lives somewhere other than `.git/modules/<name>`"; r3's probe P4 shows `git add -A` drops a dirless gitlink

The old test commits its base gitlink: `git add .gitmodules; git update-index --add --cacheinfo "160000,$s1,sub"; git commit -q -m sub1` (`test/scripts/build-loop-check.bats:1405`). The new test asserts that the real repository merges, with `git merge-tree --write-tree main feat/x > /dev/null || { echo "fixture: the real repository did not merge"; return 1; }` (`:1583`), and then expects a conflict from `--check`. Mutant `R9-realrepo` swaps `gate_git merge-tree` for `git merge-tree`, and R9 fails (`$S2/logs/mut-R9-realrepo.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1400-1416`, `test/scripts/build-loop-check.bats:1572-1586`, `$S2/logs/mut-R9-realrepo.txt`

---

## Claim 7: override row 511: A15 test added; A16 diff-tree in the gate repository with --ignore-submodules=none; A17 GIT_CONFIG_NOSYSTEM=1; "A18 not changed (no new history walk but merge-base --all, one per brief)"; i1: row 492 "does not yet name alternates, packs or the multi-pack-index"

**Location:** `docs/reviews/override-log.md:511`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers each item against code, tests and mutants (mA15 and mA17 fail their tests), plus row 492's text. It does not re-measure A18's quoted merge-base prices (3/50/306 ms), which come from iteration 1's performance report.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "A18 prices (3/50/306 ms) not re-measured" · r2: "does not cover … whether the A15 test discriminates (Claim 54: it does not establish its name)" (see Claim 56 here)

On main, merge_result ran merge-tree alone. At HEAD it adds `bases="$(gate_git merge-base --all "$MAIN_SHA" "$1")"` (`scripts/build-loop.sh:522`), once per check_line call. `grep -ci 'alternates\|multi-pack'` on row 492 returns 0.

**Evidence:** `scripts/build-loop.sh:196-198`, `scripts/build-loop.sh:520-529`, `docs/reviews/override-log.md:492`, `$S1/logs/mut-mA15.log`, `$S1/logs/mut-mA17.log`

---

## Claim 8: override row 512 (i2): "a382a3f8 split check_line into collect, batch-check and judge phases (the seam); nrules takes seven positional arguments and trusts that $7 is lower($6)"

**Location:** `docs/reviews/override-log.md:512`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers check_line's structure at cc9b69d3 against HEAD. It does not cover U3's future interface.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not cover U3's future interface" · r2: "does not establish whether U3 needs exactly these values" · r3: "does not establish that the phases are separate functions (they are not; check_line is still one function)"

At cc9b69d3 one loop parsed and judged each record: `nrules "$a" "$om" "$nm" "$no" "$s" "$p"` sat inside the `while read` loop. At HEAD the loop collects only (`scripts/build-loop.sh:602-607`), the batch-check follows (`:614-617`), and a second loop judges with `nrules "$a" "${oms[$i]}" … "$p" "${lps[$i]}"` (`:622`), which takes seven arguments.

**Evidence:** `scripts/build-loop.sh:579-628`, `git show cc9b69d3:scripts/build-loop.sh` check_line

---

## Claim 9: override row 513: "No test pins check_line's NUL-count completeness check (a mutant removing it passes) … git's own diff-tree -z output never ends mid-record"

**Location:** `docs/reviews/override-log.md:513`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the mutant against the whole build-loop-check suite. It does not cover git versions other than 2.39.5 for "never ends mid-record".
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not cover git versions other than 2.39.5 for 'never ends mid-record'" · r2+r3: "git's diff-tree output guarantee was not probed" · r3: "does not establish that the check catches every malformed tail (see Claim 33)" (Claim 39 here); r3 confidence Medium

`mNUL` (`if false; then echo "refuse $a: the paths the merge of $br changes could not be read"; …`) passed 101/101.

**Evidence:** `scripts/build-loop.sh:608-609`, `$S1/logs/mut-mNUL.log`

---

## Claim 10a: override row 514: "Each R6 guard … passes the R6 test alone … The test pins their union (the double mutant fails)"

**Location:** `docs/reviews/override-log.md:514`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the union pin (mR6) and the parenthetical. It does not cover single-guard mutants, which iteration 2 ran (its claim 26).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Mostly accurate (compound)
**Replicate annotations:** r1: "compound claim covering rows 507 and 514; does not cover row 514's 'no case found where only stderr catches it' beyond the R6 test's cases" · r2: "does not establish the row's parenthetical about merge-tree (Claim 10b)"; r2 ran the single-guard mutants (`R6-stderr-only-removed`, `R6-trees-only-removed`), each passing R6, as did r1 (`mR6err`, `mR6tree`) · r3: compound claim (union pin plus parenthetical); its Mostly accurate is carried by the parenthetical, and it states "The union pin holds"

The union pin holds: mR6 fails the R6 test. The parenthetical "(a missing subtree or blob is fatal, exit 128)" overstates. A missing blob or subtree that merge-tree passes by id is silent. Under mF2 (batch-check off), the R6 test's `mktree --missing` tip prints `ok … path … A new.txt` with status 0. A missing subtree passed by id gets past merge-tree and is caught only by diff-tree (P1: `refuse …: the paths the merge of feat/x changes could not be listed`). a382a3f8's own correction paragraph says this ("fatal only when merge-tree must read it"). The precise wording is "a missing subtree or blob that merge-tree must read is fatal".

**Evidence:** `docs/reviews/override-log.md:514`, `$S3/logs/mut-mF2.log`, `$S3/logs/probe1.log` (P1)

---

## Claim 10b: override row 514: "no case found where only stderr catches it (a missing subtree or blob is fatal, exit 128)"

**Location:** `docs/reviews/override-log.md:514`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-tree's behaviour on a missing subtree or blob passed by id versus one it must read. It does not refute the row's disposition: in the passed-by-id cases neither R6 guard fires, and diff-tree or the batch-check refuses instead.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Incorrect · r3=Mostly accurate (compound)
**Replicate annotations:** r1: its row-514 claim explicitly excluded this part ("does not cover row 514's 'no case found where only stderr catches it' beyond the R6 test's cases"); r1 verdicted the same wording in cc9b69d3's message (Claim 59 here) · r2: "does not refute the row's disposition" · r3: compound claim (union pin plus parenthetical), "The precise wording is 'a missing subtree or blob that merge-tree must read is fatal'"

The mechanism is false for an object merge-tree passes by id. In p1 case A (a missing subtree only the tip changed), merge-tree printed `merge-tree rc=0 stdout=52c0b1f8… stderr=` (empty), and `--check` refused through diff-tree: `the paths the merge of feat/x changes could not be listed`. In case D (a missing blob passed by id), merge-tree also printed `rc=0` with empty stderr, and `--check` refused through the batch-check: `names a blob the object store lacks`. Only case B, where both sides changed the directory, gave `rc=128 stderr=fatal: unable to read tree …` (`$S2/logs/p1.txt`). The branch's own correction paragraphs (a382a3f8, e02d056b) already say it is "fatal only when merge-tree must read it". The precise version: "a missing subtree or blob that merge-tree must read is fatal (exit 128); one passed by id is silent and is refused by diff-tree or the batch-check".

**Evidence:** `docs/reviews/override-log.md:514`, `scripts/build-loop.sh:599-618`, `$S2/logs/p1.txt`

---

## Claim 11: override rows 515-517 (own_blob's race untested; own_blob repeats brief_fields' awk and drift fails closed; informational U2c/--status notes, i2 "U2c also states whether floor runs on a path the N rules already denied")

**Location:** `docs/reviews/override-log.md:515-517`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the code facts the rows rest on. It does not cover the dispositions (Won't-Fix and Defer are review decisions).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: "does not cover the dispositions, which are judgments" · r2: "does not establish the race's reachability"; r2 ran mutant `ownblob-status-ignored`, which passes all nine U2b1b tests (`$S2/logs/mut-ownblob-status-ignored.txt`)

own_blob's awk is `'{ sub(/\r$/, "") } fence($0) { next } !n && /^Status:/ { n = NR } …'` (`scripts/build-loop.sh:540`). brief_fields uses the same prefix with `match($0, /^(Status|…):/)` and keeps the first (`scripts/lib/dev-cycle-read.sh:365-370`). If the two drift, the own brief's blob mismatches and the path is denied (`scripts/build-loop.sh:559-560`). build-loop.sh calls no floor (`grep -c floor` = 0).

**Evidence:** `scripts/build-loop.sh:536-543`, `scripts/build-loop.sh:559-560`, `scripts/lib/dev-cycle-read.sh:357-380`

---

## Claim 12: override row 518: "A16's two guards (diff-tree in the gate repository; --ignore-submodules=none) are pinned only together: either alone passes T12 … T12 fails when both go"

**Location:** `docs/reviews/override-log.md:518`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T12 under three mutants. It does not establish that each guard alone closes A16 in every configuration (only T12's fixture was run).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering row 518 and the T12 test comment at `test/scripts/build-loop-check.bats:1509-1510`; does not cover other configs that could hide a gitlink" · r2: "does not establish that each guard alone closes A16 in every configuration" · r3: "does not cover `.gitmodules` read from a checkout's index in the gate repository (the gate repository has none)"

`A16-realrepo-keepflag` passes T12, `A16-gate-noflag` passes T12, and `A16-realrepo-noflag` fails T12 (`$S2/logs/mut-A16-*.txt`). p4 confirms that the flag alone shows a gitlink under `submodule.gl.ignore=all` in the real repository: `:000000 160000 … A	gl` (`$S2/logs/p4.txt`).

**Evidence:** `$S2/logs/mut-A16-realrepo-keepflag.txt`, `$S2/logs/mut-A16-gate-noflag.txt`, `$S2/logs/mut-A16-realrepo-noflag.txt`, `$S2/logs/p4.txt`

---

## Claim 13: override row 519: "The K-of-N verdict names the merge by TIP while six sibling refusals name it by branch"

**Location:** `docs/reviews/override-log.md:519`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** This covers the count of distinct merge-related refusal texts in check_line that name `$br`. It does not cover the refusals before the merge (branch absent, moved, no commit, tip mismatch), which also name the branch but are not about the merge.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: "does not cover the branch-state refusals (absent, moved, no commit, tip mismatch), which also name the branch but are not about the merge"; both at Medium confidence · r3: "does not cover status_line's skip texts"; r3 at High confidence · r1+r3: "six" counts distinct texts, not sites (seven)

The merge-related texts naming `$br` are: `$br conflicts` (`:592`), `could not be computed` (`:593`), `could not be listed` (`:600`), `could not be read` (`:604`, `:609`, one text), `names a blob` (`:616`) and `could not be lower-cased` (`:620`). That makes six distinct texts. Medium confidence because "six" depends on counting distinct texts, not occurrences (seven).

**Evidence:** `scripts/build-loop.sh:590-626`

---

## Claim 14: override row 520: "--check is linear at about 0.25 ms per path (1,326 ms at 5,000 …)"; "the missing-blob batch-check about 0.1 s per 5,000 new files"; "truthrule … about 0.07 ms per path"

**Location:** `docs/reviews/override-log.md:520`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** This covers the 5,000-path total and the per-path slope on this host. It does not cover the batch-check and truthrule sub-costs, or the 20,000-path extrapolation, none of which I timed separately.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "does not cover the 20,000-path extrapolation or the truthrule and batch-check sub-costs" · r2: timing is machine- and load-dependent (load average 1.0-1.7); measured 1,338 and 1,275 ms · r3: "does not cover … linearity itself (only one size was measured)"; measured 1,341, 1,334 and 1,323 ms (about 0.27 ms per path, load 1.44)

P4: 1,295, 1,312 and 1,309 ms at 5,000 added paths; 98-100 ms at one path. The slope is (1,310 − 99) / 5,000 ≈ 0.24 ms per path. The numbers depend on the environment (load average 2.0 during the run).

**Evidence:** `$S1/probe3.sh`, `$S1/logs/probe3.log`

---

## Claim 15: plan F8: "plumbing `diff-tree` in the gate repository (no repo config, no checkout `.gitmodules`) with `--ignore-submodules=none`: `-c diff.ignoreSubmodules=none` does not override `submodule.<name>.ignore=all` (U2b1a2 A16, probed; U2b1b)"

**Location:** `docs/working/plan-build-loop-handoff.md:123`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's diff-tree with the -c form versus the flag, and the call site. It does not establish behaviour in other git versions.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering commit 809df345's F8 sentence and the plan F8 row" · r1+r2+r3: "does not cover other git versions"

In p4, with `submodule.gl.ignore=all` in .gitmodules and the repo config, plain diff-tree and `git -c diff.ignoreSubmodules=none diff-tree` both print nothing. `--ignore-submodules=none` prints `:000000 160000 … A	gl` (`$S2/logs/p4.txt`). The call site is `gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none` (`scripts/build-loop.sh:599`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:123`, `scripts/build-loop.sh:599`, `$S2/logs/p4.txt`

---

## Claim 16: plan F12: "N-denied via truthrule's cycle and settings words (the lib's `writable()` plus `docs/dev-cycle.md`), and, N-only, anything under `docs/working/briefs/` or `docs/working/cycles/`; `docs/constraints.md` by its user word (F54) (T14; U2b1b)"

**Location:** `docs/working/plan-build-loop-handoff.md:127`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers nrules' mapping. It does not establish floor's (U2c) treatment.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering plan F12 and the `--state` line" · r2: "does not establish floor's (U2c) treatment" · r3: "does not cover the S rules (U2c)"

`cycle|settings) DENY="one of the dev cycle's own files" ;;`, `user) DENY="the user's constraints doc, …" ;;` and `*) [[ ! "$7" =~ ^docs/working/(briefs|cycles)/ ]] || DENY="one of the dev cycle's own files" ;;` (`scripts/build-loop.sh:567-569`).

**Evidence:** `scripts/build-loop.sh:565-570`, `scripts/lib/dev-cycle-read.sh:1094-1096`

---

## Claim 17: plan `--state` line: "U2b1a's `state_gate`, then U2b1b's `default_gate` once main is resolved: both main and master, or origin/HEAD naming another branch than the one taken"

**Location:** `docs/working/plan-build-loop-handoff.md:207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers default_gate's checks and when it runs. It does not establish `--state`, which is not built yet (U3b).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering plan F12 and the `--state` line" · r1+r2+r3: "`--state` is not built (U3b)"

`if [[ "$MODE" == check ]]; then state_gate || exit 2; fi` / `resolve_main || true` / `main_by_name || …` / `if [[ "$MODE" == check ]]; then default_gate || exit 2; fi` (`scripts/build-loop.sh:257-260`).

**Evidence:** `scripts/build-loop.sh:241-260`

---

## Claim 18: plan `--check` line: "U2b1b (built): the verdict line comes first (`ok BRIEF TIP TREE`, or `refuse BRIEF: K of N changed paths refused`), then `path BRIEF S PATH` or `deny BRIEF S PATH: WHY` per changed path; exit 0 only when every verdict line is ok."

**Location:** `docs/working/plan-build-loop-handoff.md:212`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the refusing verdict's spelled format. The order, the path and deny formats, and the exit rule hold (claim 10).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Mostly accurate · r3=Stale
**Replicate annotations:** r1: "the order, the path and deny formats, and the exit rule hold" · r2: "does not cover the refusal text in full: the plan quotes only cc9b69d3's prefix"; r2 notes e02d056b's message says F12 and --state were brought to match the code, and this line was not · r3: "does not cover the rest of the line, which is Verified (order, path and deny forms, exit)"; r3 notes e02d056b updated F12 and `--state` but not this line · r1 Goal-Alignment: the plan is the spec U3 builds `--merge` from, "the :212 line in particular" (see Escalations)

The line was written in 809df345 (`git log -L` on the line names only 809df345). a382a3f8 (api 1) then extended the verdict:
```bash
# scripts/build-loop.sh:626
  if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
```
The plan's `refuse BRIEF: K of N changed paths refused` is now only a prefix. It should read `refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)`, as the help does (`scripts/build-loop.sh:111-112`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:212`, `scripts/build-loop.sh:111-112`, `scripts/build-loop.sh:626`

---

## Claim 19a: plan step 5's U2b1b note: "Built 2026-10-08 (`feat/build-loop-u2b1b`, cc9b69d3, 317 lines): the mode rule is an N rule (both policies), so floor item 5 is already enforced before U2c; the own brief also keeps its mode; plus U2b1a2's carried R6, R7, R9, A15, A17 and A19 (override rows 497, 507-511)."

**Location:** `docs/working/plan-build-loop-handoff.md:283`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the mode rule, the own-brief mode rule (mMode fails T15) and the carried fixes. "317 lines" is cc9b69d3's count, as labelled, not the unit's 382 at HEAD.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not cover the R8 sentence (Claim 19b)" · r3: no separate claim; r3's step-5 claim (its Claim 19, Stale) is scoped to the R8 sentence and states in its Scope that the rest of the note "is Verified" and in prose "The other atoms check out" (317 = 282+35; mode rule under both policies) — recorded here as r3's verdict · r1: its Claim 2 (compound, test and line counts) also verifies "317 lines"

`[[ "$5" == M && "$2" == "$3" ]]` (`scripts/build-loop.sh:559`) keeps the mode. Dropping `"$2" == "$3"` fails T15's chmod case.

**Evidence:** `scripts/build-loop.sh:557-560`, `$S1/logs/mut-mMode.log`

---

## Claim 19b: plan step 5's U2b1b note: "R8 is proposed as a Q-103 residual for its review to decide."

**Location:** `docs/working/plan-build-loop-handoff.md:283`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** This covers R8's status as the branch's own records state it. It does not judge the decision itself.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale
**Replicate annotations:** r2: "It does not affect any code"; "It was true at 809df345" · r3: Type given as Reference; covers the R8 sentence only

Row 509 reads `**Decided at U2b1b iteration 1 (security, architecture concur): Q-103 residual.**` (`docs/reviews/override-log.md:509`), and plan step 13 lists R8 for U5 (`docs/working/plan-build-loop-handoff.md:305`). The note still says it is proposed. It should say R8 was decided a Q-103 residual at iteration 1 (row 509).

**Evidence:** `docs/working/plan-build-loop-handoff.md:283`, `docs/working/plan-build-loop-handoff.md:305`, `docs/reviews/override-log.md:509`

---

## Claim 20: plan step 13: "U2b1a2's R8 (a same-uid writer racing the gate's GATE_TMP: its config, info/, work/.gitattributes, err and diff; override row 509)"

**Location:** `docs/working/plan-build-loop-handoff.md:305`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers the listed surface against gate_repo and row 509. It does not cover the Q-103 re-route itself (U5).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "does not cover the Q-103 re-route itself (U5)" · r2: "does not establish completeness beyond row 509" · r3: "does not cover U5's future content" · r1+r3: the cross-reference to row 509 carries the full list

Row 509's i2 note adds `git/refs/` and `git/HEAD` to the surface, and gate_repo creates both: `mkdir "$GATE_TMP/git" "$GATE_TMP/git/refs" "$GATE_TMP/work"` and `printf 'ref: refs/heads/none\n' > "$GATE_TMP/git/HEAD"` (`scripts/build-loop.sh:502-503`). Step 13's list stops at five files. The cross-reference to row 509 carries the full list, so it is imprecise rather than wrong.

**Evidence:** `scripts/build-loop.sh:497-506`, `docs/reviews/override-log.md:509`

---

## Claim 21: --check help, state gate: the key list, the files "not absent or an empty file", the replace ref, origin/HEAD, "then (once main is found) both main and master present, or origin/HEAD naming another branch than the one taken. Each finding prints 'refuse state WHAT: WHY' and exits 2 before any brief is read"

**Location:** `scripts/build-loop.sh:80-91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers STATE_KEYS_RE, the file checks, the replace-ref and origin/HEAD checks, default_gate, the line format and exit 2 before check_line. It does not cover state_gate's early `return 1` cases (an unreadable path or a missing config), which print one line and stop at the first finding rather than listing every one.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering the state-gate list and the 'refuse state gate' parenthetical; does not cover config keys outside the regex" · r2: "does not cover state_gate's early `return 1` cases" · r3: "does not cover keys written after the gate passes (row 494)"

`STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'` (`scripts/build-loop.sh:212`) is read with `git config --file "$p" --no-includes --name-only --get-regexp` over `config config.worktree` (`:215-218`). The file test is `[[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]` (`:226`). The state-gate tests in the suite pass (`$S2/logs/bats.txt`), including the multi-finding test that expects `refuse state shallow: present and not an empty file` (`test/scripts/build-loop-check.bats:1339-1343`).

**Evidence:** `scripts/build-loop.sh:212-251`, `scripts/build-loop.sh:257-260`, `test/scripts/build-loop-check.bats:1339-1343`, `$S2/logs/bats.txt`

---

## Claim 22: --check help: "exits 2 before any brief is read ("refuse state gate: WHY" when the gate's own merge repository cannot be set up)"

**Location:** `scripts/build-loop.sh:90-92`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when the gate-repository refusal is printed and what happens when its temporary directory cannot be made. It does not affect the state-gate findings themselves (Claim 21).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: compound claim; r1 verified the gate-setup line exists (`gate_repo || { echo "refuse state gate: …"; exit 2; }`, `:641`) and the order of state_gate/default_gate before read_settings, without addressing the parenthetical's timing · r3: "It is accurate if read as 'before any brief's verdict'"; does not cover the mktemp failure · r2: adds that a failed `mktemp -d` exits 1 with no "refuse state gate" line (p1 case G)

Read beside "before any brief is read", the parenthetical suggests the gate-repository refusal also comes before any brief is read. It does not. It is printed after `read_settings` and `open_shared`: `open_shared  # once, in this shell` / `GATE_TMP="$(mktemp -d)"; trap …` / `gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }` (`scripts/build-loop.sh:641-643`). open_shared reads each open brief on main through `brief_fields "$f"` (`scripts/lib/dev-cycle-read.sh:478`). It still comes before any verdict line. Also, if `mktemp -d` itself fails, `set -e` exits 1 with no "refuse state gate" line. p1 case G (`TMPDIR=/nonexistent-dir-xyz`) printed `mktemp: failed to create directory …` and `check rc=1` (`$S2/logs/p1.txt`). The precise version: "before any verdict line ('refuse state gate: WHY' when the gate's merge repository cannot be set up; a failed mktemp exits 1)".

**Evidence:** `scripts/build-loop.sh:639-644`, `scripts/lib/dev-cycle-read.sh:469-484`, `$S2/logs/p1.txt`

---

## Claim 23: --check help, ok line: "--status reads the brief as open and its branch at TIP, at least one commit ahead of main (and TIP equals SHA when --expect is given …); TREE is the merge of TIP into main as merge-tree writes it, run where no repo config or checkout attributes are read; and no changed path is denied."

**Location:** `scripts/build-loop.sh:94-100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ok conditions and the gate repository's config and attributes isolation. It does not cover config the caller supplies through its own environment (`GIT_CONFIG_COUNT` or `GIT_CONFIG_PARAMETERS` survive GATE_ENV by design, `:185-186`), which is not repo config.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering the ok line and the refusal cases (`:94-114`); does not cover a non-blob object type at a regular file's id, which the code would also refuse but no test plants" · r2+r3: "does not cover the caller's own `GIT_CONFIG_*` env pairs, which harden deliberately keeps"

`if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"` (`scripts/build-loop.sh:626`), and an empty diff also prints ok (`:610`). GATE_ENV unsets every local env var except `GIT_CONFIG*` and `GIT_NO_REPLACE_OBJECTS` (`:500`). It points GIT_DIR at a fresh config that holds only `repositoryformatversion` and `objectformat` (`:504-505`) and runs in an empty `$GATE_TMP/work` (`:512`). The suite's ok-path tests pass with path lines appended (`test/scripts/build-loop-check.bats:1260-1261`).

**Evidence:** `scripts/build-loop.sh:497-514`, `scripts/build-loop.sh:579-628`, `$S2/logs/bats.txt`

---

## Claim 24: --check help, refuse line: "… the merge (or its changed paths) could not be computed: git failed, or warned on stderr (a missing tree object), or the tree of main, TIP or a merge base is missing. Or "the merge of BRANCH names a blob the object store lacks": a regular file the merge adds or changes names an object that is absent or not a blob. Or "K of N changed paths refused in the merge of TIP (tree TREE)", when deny lines follow."

**Location:** `scripts/build-loop.sh:101-111`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each refusal case against probes and tests. It does not establish the exact WHY text of the changed-paths failures, which reads "could not be listed/read/lower-cased" rather than "computed". The help groups them by meaning, not by text.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering the ok line and the refusal cases; does not cover a non-blob object type at a regular file's id, which the code would also refuse (`grep -cx blob`) but no test plants" · r2: "does not establish the exact WHY text of the changed-paths failures"; r2's probe case F did plant a tree id at a 100644 entry · r3: "does not cover a missing blob on a path the merge deletes (old side only), which is never checked because it never lands"

The p1 cases:
- C, a missing top-level merge-base tree: merge-tree gave rc=0 with `error: Could not read …` on stderr, and `--check` printed `the merge of feat/x could not be computed`.
- B, a missing subtree merge-tree must read: rc=128, and `--check` printed `could not be computed`.
- D, a missing blob: `names a blob the object store lacks`.
- F, a tree id at a 100644 entry, built with `hash-object -t tree --literally`: `names a blob the object store lacks`.

All are in `$S2/logs/p1.txt`. Code: `echo "refuse $a: the merge of $br names a blob the object store lacks"` (`scripts/build-loop.sh:617`) and the K-of-N line (`:626`). T14 asserts the K-of-N text through `nref` (`test/scripts/build-loop-check.bats:1449`).

**Evidence:** `scripts/build-loop.sh:516-530`, `scripts/build-loop.sh:591-626`, `$S2/logs/p1.txt`, `test/scripts/build-loop-check.bats:1449`

---

## Claim 25: --check help, path lines: "After an ok line or a K of N refusal, one line per path TREE changes against main (diff-tree -r --no-renames, so a rename is its D and A sides), in diff-tree's order; S is its status letter (A, M, D or T) and PATH is "?" unless every character is one pathform allows"

**Location:** `scripts/build-loop.sh:114-120`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the format, order, rename split and display rule. It does not establish anything for statuses other than A/M/D/T, which refuse the brief as "could not be read" (`:603-604`).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "compound claim covering the path lines and the N-rule list (`:113-128`)" · r3: "compound claim covering the path lines and the deny list (`:114-129`); does not cover S rules (U2c)" · r2: "does not establish anything for statuses other than A/M/D/T"

`p="${ps[$i]}"; shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"` (`scripts/build-loop.sh:622`). The display rule tests NAMECHARS only (pathform's character set), so `-x.md` and `.github/w.yml` print by name although pathform refuses them. T13 asserts exactly that (`has "deny $B A -x.md: $NFORM"`, `test/scripts/build-loop-check.bats:1529`). T11 asserts the D and A sides of a rename, and T14 asserts diff-tree order (`lines[1]` is `Docs/Roadmap.md`). Both pass.

**Evidence:** `scripts/build-loop.sh:599-627`, `test/scripts/build-loop-check.bats:1453-1531`, `$S2/logs/bats.txt`

---

## Claim 26: --check help, N rules: "a path pathform refuses (a part starting .git, any case: .github/); a mode other than 100644 or 100755 on either side (a symlink or gitlink); the brief's own file, unless only its first Status: line outside a fence changes, from open to done (mode kept); and, compared lower-cased, the dev cycle's own files (the roadmap, the questions files, the idea log, docs/dev-cycle.md, anything under docs/working/briefs/ or docs/working/cycles/) and docs/constraints.md."

**Location:** `scripts/build-loop.sh:121-129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each rule against nrules and T11-T15. Two things are outside it. "On either side" is read as either side that exists: an absent side (000000) is allowed. Cycle files are recognised by writable()'s exact names; a non-brief name directly under docs/working/ (for example `docs/working/notes.md`) is not a cycle file.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: compound claim; "reads 'a mode … on either side' as excluding an absent side (000000 is allowed, so regular-file adds and deletes pass), as iteration 1 did. It does not cover a case variant of the brief's own path, which is not matched exactly but is denied as a cycle file" · r2: "an absent side (000000) is allowed"; "a non-brief name directly under docs/working/ … is not a cycle file" · r3: compound claim; "does not cover S rules (U2c)"

pathform refuses `"$c" != [.][gG][iI][tT]*` in any case (`scripts/lib/dev-cycle-read.sh:191`). The mode regex admits `000000|100644|100755` on each side (`scripts/build-loop.sh:557`). The own-brief branch compares the new blob to `own_blob` (`:559-560`), which rewrites only line N's `^Status: open(\r?)$` (`:542`). The suite passes T12 (five mode denies), T13, T14 (15 of 16 denied, including `Docs/Roadmap.md` and `docs/CONSTRAINTS.md`) and T15 (fenced line, dropped, extra line, chmod, trailing blank and move all denied; CRLF kept) (`$S2/logs/bats.txt`).

**Evidence:** `scripts/build-loop.sh:536-572`, `scripts/lib/dev-cycle-read.sh:184-207`, `test/scripts/build-loop-check.bats:1453-1531`, `$S2/logs/bats.txt`

---

## Claim 27: help Exit line: "0 every line printed (or help), and for --check every verdict line ok; 2 any --check verdict line or the state gate not ok; 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name"

**Location:** `scripts/build-loop.sh:137-139`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit paths the script codes explicitly. It does not enumerate `set -e` exits.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: "does not separately test 'not a git repo'" · r3: "does not re-check the status and settings exits, which this branch did not change" · r2: "does not enumerate `set -e` exits"; the mktemp-failure path (exit 1 with no line) is the only addition r2 found

The named paths match: `[[ "$fails" -eq 0 ]] || exit 2` (`scripts/build-loop.sh:649`), the state and default gates `exit 2` (`:257`, `:260`), and `exit 1` for usage, not a repo, perl, the lib, or no default branch (`:143`, `:149`, `:154`, `:252`, `:259`). One --check path is missing from the list. A failed `GATE_TMP="$(mktemp -d)"` (`:642`) exits 1 with no line, as p1 case G showed (`check rc=1`, `$S2/logs/p1.txt`), although the help files gate-repository failures under exit 2 ("refuse state gate").

**Evidence:** `scripts/build-loop.sh:137-139`, `scripts/build-loop.sh:642-649`, `$S2/logs/p1.txt`

---

## Claim 28: A17 comment: "GIT_CONFIG_NOSYSTEM: the system config is no more the gate's than the user's (merge.directoryRenames there flipped a conflict: A17)"

**Location:** `scripts/build-loop.sh:196-198`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the export reaching every git call (the shim test, which mA17 fails) and the reference to A17's finding. It does not re-run the system-config conflict flip, which belongs to U2b1a2's iteration 3.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not re-run the system-config conflict flip" · r2+r3: did re-run the flip (r2 p4: `merge.directoryRenames=conflict` rc=1 vs `=true` rc=0; r3 P3: shipped script refuses, copy without the variable prints ok); "does not cover other system keys"

The export includes `GIT_CONFIG_NOSYSTEM=1` (`scripts/build-loop.sh:198`). The U2b1a rubric's A17 reads `System config reaches every gate call (`merge.directoryRenames` flipped a conflict)` (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md:27`).

**Evidence:** `scripts/build-loop.sh:196-198`, `test/scripts/build-loop-check.bats:1375-1389`, `$S1/logs/mut-mA17.log`

---

## Claim 29: state_gate comment: "Keys, in the common config and this worktree's config.worktree: filter drivers, every merge.* and diff.* key (drivers run commands), config hooks, includes, core.fsmonitor, core.attributesFile, core.hooksPath, gpg and log.showSignature …, and a partial clone … Files: an info/attributes, info/grafts or shallow that is not absent or an empty regular file …"

**Location:** `scripts/build-loop.sh:199-211`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against STATE_KEYS_RE and the file test. It does not establish that the key list is exhaustive for every command-running key (a design question).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering the state_gate and default_gate comments; does not cover `--state` (U3b)" · r2: "does not establish that the key list is exhaustive for every command-running key (a design question)" · r3: "does not cover config files outside the common dir and config.worktree"

`merge\.|diff\.` match every key in those sections, `filter\.` every filter key, `hook\.` config hooks, and `include` both include and includeIf (`scripts/build-loop.sh:212`). The file test accepts only an absent path or an empty regular file (`:226`).

**Evidence:** `scripts/build-loop.sh:212-235`

---

## Claim 30: default_gate comment: "the default branch counts only when no other name could claim it. A loop can create a local master beside main (or main beside master) and point origin/HEAD at it, and resolve_main would follow (R7). Prints one line per finding, as state_gate does; returns 1 on any."

**Location:** `scripts/build-loop.sh:236-240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both findings printed together and resolve_main's order. Two things are outside it. For "main beside master", resolve_main takes main even without origin/HEAD, because main comes before master in its candidate list. The comment's "and point origin/HEAD at it" is sufficient but not necessary there.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering the state_gate and default_gate comments" · r2: "'and point origin/HEAD at it' is sufficient but not necessary" for main beside master · r3: "does not cover 'U3b's --state calls both', which is a plan statement"

resolve_main tries `origin_head` first, then `candidates+=(main master)` (`scripts/lib/dev-cycle-read.sh:493-495`). default_gate sets `bad=1` per finding and returns it (`scripts/build-loop.sh:242-250`). The R7 test's third block expects both lines together and passes (`test/scripts/build-loop-check.bats:1562-1565`, `$S2/logs/bats.txt`).

**Evidence:** `scripts/build-loop.sh:241-251`, `scripts/lib/dev-cycle-read.sh:490-512`, `test/scripts/build-loop-check.bats:1553-1570`

---

## Claim 31: gate_git: "git in the gate repository, stdout passed through; returns git's status, or 3 when git wrote anything to stderr (a missing object can warn and still exit 0: R6)."

**Location:** `scripts/build-loop.sh:507-509`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function and R6's warn-and-exit-0 case. It does not cover concurrent writers to the shared err file (R8 residual).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering the gate_git and merge_result comments; does not cover merge-base's exit 1 (no merge base), which merge_result allows through and merge-tree then refuses as unrelated histories" · r2+r3: "does not cover concurrent writes to the shared err file (R8 / row 509)"

`(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@") 2>"$GATE_TMP/err" || rc=$?` / `[[ ! -s "$GATE_TMP/err" ]] || return 3` / `return "$rc"` (`scripts/build-loop.sh:512-514`). In p1 case C, merge-tree exited 0 with `error: Could not read …` on stderr (`$S2/logs/p1.txt`).

**Evidence:** `scripts/build-loop.sh:510-515`, `$S2/logs/p1.txt`

---

## Claim 32: merge_result: "prints the result tree; returns 1 on a conflict (a gitlink both sides moved is one, since no submodule repository is reachable), 2 when git failed or warned, or the tree of main, the tip or a merge base is missing (R6)."

**Location:** `scripts/build-loop.sh:516-519`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each return code against probes and the R9 test. It does not cover a missing blob or subtree passed by id: merge_result returns 0 for those, and check_line refuses them later (Claim 39).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound (gate_git + merge_result); "does not cover merge-base's exit 1 (no merge base), which merge_result allows through and merge-tree then refuses as unrelated histories (exit 2, 'could not be computed')" · r2: "does not cover a missing blob or subtree passed by id: merge_result returns 0 for those, and check_line refuses them later" (r2's Claim 39 is Claim 40 here) · r3: "does not cover a merge-tree that writes to stderr on an otherwise clean conflict (it would read as 2, not 1, which is still a refusal)"

`[[ "$rc" -le 1 ]] || return 2` after merge-base, the tree loop's `|| return 2`, then `[[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^(…)$ ]] || return 2` and `[[ "$rc" -eq 0 ]] || return 1` (`scripts/build-loop.sh:523-528`). In p1 case E (missing tree plus conflict), merge-tree gave rc=1 with stderr, so gate_git returns 3 and merge_result returns 2. In case A (missing subtree passed by id), merge-tree gave rc=0 with no stderr, so merge_result returns 0 (`$S2/logs/p1.txt`). The R9 test (gitlink fast-forward, a conflict in the gate repository) passes.

**Evidence:** `scripts/build-loop.sh:520-530`, `test/scripts/build-loop-check.bats:1572-1586`, `$S2/logs/p1.txt`

---

## Claim 33: own_blob comment: "main's copy with its first Status: line outside a fence, the one brief_fields reads (status_line has read it as 'Status: open'), reading 'Status: done', every other byte kept (a CR at its end too). Returns non-zero when a read fails; the caller checks it"

**Location:** `scripts/build-loop.sh:531-535`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers line selection against brief_fields, the CR case (T15) and the exit-status check in nrules. It does not cover a test of the read-failure path (row 515: a race).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "no test of the failed-read path / race between own_blob's two reads (row 515)"

```bash
# scripts/build-loop.sh:540-542 (own_blob, :536-543 read)
  n="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } !n && /^Status:/ { n = NR } END { print n + 0 }')" || return 1
  [[ "$n" -gt 0 ]] || return 1
  git cat-file blob "$MAIN_SHA:$1" | N="$n" perl -pe 's/^Status: open(\r?)$/Status: done$1/ if $. == $ENV{N}' | gate_git hash-object --no-filters --stdin
```
The caller's `ob="$(own_blob "$1")" &&` is under `set -euo pipefail` (`:140`). T15's fenced, CRLF and trailing-byte cases pass, and mMode fails T15.

**Evidence:** `scripts/build-loop.sh:140`, `scripts/build-loop.sh:536-560`, `scripts/lib/dev-cycle-read.sh:365-371`, `$S1/logs/mut-mMode.log`

---

## Claim 34: nrules comment: "diff-tree's old and new modes $2 $3, new blob $4, status $5, path $6 and its lower-cased spelling $7 … The brief's own file is matched exactly; the cycle's files (truthrule's cycle and settings words: writable() and docs/dev-cycle.md, plus anything under docs/working/briefs/ or docs/working/cycles/) and the constraints doc (its user word) compare lower-cased"

**Location:** `scripts/build-loop.sh:544-551`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the argument order at the single call site and the comparisons. It does not cover other callers (there are none: nrules is called only at `:623`).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering the nrules comment and the inline invariant (`:562-564`); does not cover future truthrule words" · r2: "nrules is called only at `:623`" · r3: "does not cover the S rules"; T14's mixed-case paths are denied

The call is `nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"` (`scripts/build-loop.sh:623`), the own-file test is `[[ "$6" == "$1" ]]` (`:558`), and `truthrule "$7"` runs on the lower-cased path (`:565`).

**Evidence:** `scripts/build-loop.sh:553-572`, `scripts/build-loop.sh:623`

---

## Claim 35: nrules invariant: "$7 is lower-cased, so the case word cannot fire; instr and dot, tested before cycle, match no cycle file, docs/dev-cycle.md or docs/constraints.md today"

**Location:** `scripts/build-loop.sh:562-564`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** This covers today's INSTRUCTION_FILE, PROMPT_DIR, `.claude/rules/` and dot tests against writable()'s patterns and the two docs. It does not cover future words.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: compound (nrules comment + invariant); r1 ran P3 with the lib sourced, mapping each cycle file to `cycle`, dev-cycle.md to `settings`, constraints.md to `user` · r2: compound (invariant + "T14 fails if one ever does"); "For a brief or cycle-log path, an instr or dot match would not be caught by T14, because the briefs/cycles subtree fallback still denies it; that is not a fail-open" · r1+r2+r3: "does not cover future truthrule words"

- **Lower-casing.** `lower_all` maps A-Z to a-z (`scripts/lib/dev-cycle-read.sh:857`). truthrule's case test is `*[ABCDEFGHIJKLMNOPQRSTUVWXYZ]*` (`:1091`), so it cannot fire on lower-cased input.
- **instr.** isstart needs a basename matching `^(claude|agents?|gemini)(\.…)?\.md$|^skill\.md$` or a `.claude/` part (`:516`, `:525`, `:529`). No writable() path has either: writable() covers `docs/roadmap.md`, `docs/working/{questions,questions-archive,idea-log}.md`, `cycles/cycle-DATE.md`, and briefs named `DATE-slug.md` (`:204-207`).
- **dot.** It needs a `/.` part, and none of those paths has one.

**Evidence:** `scripts/lib/dev-cycle-read.sh:198-207`, `scripts/lib/dev-cycle-read.sh:516-529`, `scripts/lib/dev-cycle-read.sh:857`, `scripts/lib/dev-cycle-read.sh:1089-1099`

---

## Claim 36: nrules comment: "(T14 fails if one ever does: truthrule names this third consumer)"

**Location:** `scripts/build-loop.sh:564`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** This covers which shadowing T14 would detect. It does not cover a run of a shadowing mutant.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r2: compound claim (invariant + this parenthetical) verdicted Verified, with the caveat "'T14 fails' holds for the exact names T14 writes … For a brief or cycle-log path, an instr or dot match would not be caught by T14 … that is not a fail-open"; r2's mutant `T14-instr-shadows` fails T14 · r3: ran the shadowing mutants (mT14a passes T14, T15, T11; mT14b fails T14 and T11); "does not cover a dot-word mutant (same structure, not run)"; precise wording "T14 fails if one ever opens a covered path" · r1: "does not cover a run of a shadowing mutant"

T14 lists every top-level cycle file, dev-cycle.md and constraints.md (`test/scripts/build-loop-check.bats:1457-1459`). If instr or dot ever matched one of those, nrules' `*)` arm would let it through and T14 would fail. A word that shadowed a file under `docs/working/briefs/` or `cycles/` would not fail T14: the `*)` arm's subtree regex still denies it with the same reason. So T14 fails exactly where a shadow would open a hole, not "if one ever does" in general. A precise version: "T14 fails if one ever shadows a file outside briefs/ and cycles/, where the subtree rule does not catch it."

**Evidence:** `scripts/build-loop.sh:562-569`, `test/scripts/build-loop-check.bats:1453-1473`

---

## Claim 37: check_line header: ""ok BRIEF TIP TREE" or "refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)", then a "path BRIEF S PATH" or "deny BRIEF S PATH: WHY" line per path …; or one skip or refuse line"

**Location:** `scripts/build-loop.sh:573-578`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_line's outputs. It does not cover the ok case with no changed paths, which prints the verdict alone (`:610`) and is consistent with "per path".
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering the header, the A16 comment, the batch-check comment and the lower-casing comment; does not re-time '1 to 2.5 ms'" · r2: "does not cover the ok case with no changed paths, which prints the verdict alone" · r3: "does not cover the caller's handling"

`rows+=("deny $a ${ss[$i]} $shown: $DENY")` / `rows+=("path $a ${ss[$i]} $shown")` (`scripts/build-loop.sh:624`). Every other exit is a single `echo …; return` (`:582-620`).

**Evidence:** `scripts/build-loop.sh:579-628`

---

## Claim 38: "In the gate repository, so no repo config or checkout .gitmodules hides a moved gitlink (A16); --no-renames, so a rename is judged as both its sides (F6)."

**Location:** `scripts/build-loop.sh:597-598`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the gate repository plus the flag shows the gitlink, and the rename split. It does not establish that the gate repository alone is needed (the flag alone suffices, Claim 12). The comment does not claim it is.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** r1: compound claim (check_line comments); "covers … A16 (claim 18), F6 (T11)" · r2: "does not establish that the gate repository alone is needed (the flag alone suffices)"

`gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree"` (`scripts/build-loop.sh:599`). T12 under `ignore = all` and T11 pass, and mutant `A16-realrepo-noflag` fails T12 (`$S2/logs/mut-A16-realrepo-noflag.txt`).

**Evidence:** `scripts/build-loop.sh:597-601`, `$S2/logs/mut-A16-realrepo-noflag.txt`

---

## Claim 39: check_line comment: "Every record read whole: two NUL-ended fields each."

**Location:** `scripts/build-loop.sh:608-609`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers what the NUL count proves. It does not cover git's own output, which never ends mid-record (row 513), so the gap below is not reachable on the honest path.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r2: static reading only; "A trailing field without a NUL ends the `read -r -d ''` loop … without being added to `ps`. The total NUL count then differs" (r1 and r3 probes found the count does not differ for a tail with no NUL); "does not establish a test (row 513)" · r3: probe3 fed two whole records plus a NUL-less meta field: 2 records, 4 NULs, check passes, fragment dropped; a cut after the meta's NUL leaves an odd count, which the check refuses; "does not cover whether git can produce either (row 513)" · r1+r3: unreachable on the honest path

```bash
# scripts/build-loop.sh:609
  if [[ "$(tr -cd '\000' < "$GATE_TMP/diff" | wc -c)" -ne $((2 * ${#ps[@]})) ]]; then echo "refuse $a: the paths the merge of $br changes could not be read"; return; fi
```
The check proves that every NUL-ended field was consumed as part of a whole record. Trailing bytes after the last NUL are not counted. A loop over `m1\0p1\0frag` with the same `read -r -d ''` pair read 1 record with 2 NULs, so the check would pass and `frag` would be dropped silently (`$S1/logs/probe-frag.log`). A precise version: "every NUL-ended field read as part of a whole record (bytes after the last NUL are not checked)". This is informational: diff-tree's `-z` output ends in NUL, and row 513 already records the check as defensive.

**Evidence:** `scripts/build-loop.sh:602-609`, `$S1/logs/probe-frag.log`, `docs/reviews/override-log.md:513`

---

## Claim 40: "merge-tree passes a side's unchanged blob by id without reading it, so a blob the store lacks would land unseen: every regular file the merge adds or changes must name a blob present in the store (a missing subtree already failed diff-tree)."

**Location:** `scripts/build-loop.sh:611-614`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the passed-by-id blob case, the wrong-type case, the subtree case and the id selection (new mode 100644 or 100755). It does not cover an old-side blob of a deleted or modified path, which is never landed.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound claim (check_line comments); P1b: a missing subtree reached diff-tree and was refused there before the batch-check · r2: "does not cover an old-side blob of a deleted or modified path, which is never landed" · r3: "does not cover a missing blob both sides change, which merge-tree reads and fails on (iteration 2's probe, case E)"

The ids are collected as `[[ "${nms[-1]}" != 100644 && "${nms[-1]}" != 100755 ]] || ids+=("${nos[-1]}")` (`scripts/build-loop.sh:606`) and checked with `gate_git cat-file --batch-check='%(objecttype)'` plus `grep -cx blob` (`:615-616`). p1 results (`$S2/logs/p1.txt`):
- Case D: merge-tree rc=0 with no stderr, and `--check` printed `names a blob the object store lacks`.
- Case F: a wrong-type entry gave the same refusal.
- Case A: a missing subtree gave `the paths the merge of feat/x changes could not be listed`.

Mutant `F2-nobatch` fails the R6 test (`$S2/logs/mut-F2-nobatch.txt`).

**Evidence:** `scripts/build-loop.sh:599-618`, `$S2/logs/p1.txt`, `$S2/logs/mut-F2-nobatch.txt`

---

## Claim 41: "One lower-casing pass for every path (a tr per path cost 1 to 2.5 ms each)."

**Location:** `scripts/build-loop.sh:619`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one lower_all call per brief and the per-tr cost on this machine (low end of the range). It does not establish the 2.5 ms upper figure, which depends on machine and load.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound claim; "does not re-time '1 to 2.5 ms', which is environment-dependent (iteration 1: 2.2-2.6 ms; iteration 2's fact-check: 1.17 ms)" · r2: "does not establish the 2.5 ms upper figure" · r3: measured 1.08 ms each; "does not cover other hosts or load levels"

`nul_list lps lower_all "${ps[@]}"` is one call (`scripts/build-loop.sh:620`). p3 measured `1000 lower in $(): 951 ms` (about 0.95 ms each). The 5,000-path run went from 8,879-8,977 ms at cc9b69d3 (a `lower` per path) to 1,275-1,338 ms at e02d056b, about 1.5 ms saved per path (`$S2/logs/p3-time.txt`).

**Evidence:** `scripts/build-loop.sh:619-620`, `scripts/lib/dev-cycle-read.sh:852-857`, `$S2/logs/p3-time.txt`

---

## Claim 42: lib contract item 5: "Ask floor about each changed path, in this shell, before main_entry … Floor item 5 (symlinks, gitlinks) and the brief's own Status change are the caller's rules; build-loop.sh's N rules apply them, and pathform, under both policies before floor runs, so a path pathform refuses (.github/x.yml) is denied as a path form and floor's dotfile reason serves the dot paths pathform accepts (.envrc)."

**Location:** `scripts/lib/dev-cycle-read.sh:59-65`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers nrules' rules and the pathform/dot split. It does not establish floor's call site, which does not exist yet (U2c), so "before floor runs" describes the planned order.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering contract item 5 and the truthrule comment; 'Before floor runs' holds vacuously: build-loop.sh calls no floor yet (U2c)" · r2+r3: "before floor runs" is U2c's to honor; no floor call exists yet

nrules checks pathform first (`if ! pathform "$6"; then DENY="not an allowed path form …"`, `scripts/build-loop.sh:556`) with no policy test. pathform rejects only `[.][gG][iI][tT]*` parts among dot parts (`scripts/lib/dev-cycle-read.sh:191`), so `.envrc` passes it. truthrule's `[[ "/$1" == */.* ]]` gives `dot` (`:1093`), which nrules' `*)` branch does not deny (`scripts/build-loop.sh:569`). floor maps `dot` to "a dotfile or a path under a dot-directory" (`scripts/lib/dev-cycle-read.sh:1146`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:59-65`, `scripts/lib/dev-cycle-read.sh:184-193`, `scripts/lib/dev-cycle-read.sh:1138-1160`, `scripts/build-loop.sh:553-572`

---

## Claim 43: truthrule comment: "build-loop.sh's N rules read its cycle, settings and user words too, so a word tested before them must never match a file those words cover"

**Location:** `scripts/lib/dev-cycle-read.sh:1076-1079`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the consumer statement and today's order (Claim 35). It does not establish future edits.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound claim (contract item 5 + truthrule comment); "Claim 32 checks the truthrule invariant" (Claim 35 here) · r2: "does not establish future edits" · r3: "does not cover the record word, which nrules ignores"

nrules reads `cycle|settings` and `user` from `TRUTH_WHY` (`scripts/build-loop.sh:566-568`). The words tested before them are `case`, `instr` and `dot` (`scripts/lib/dev-cycle-read.sh:1091-1093`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1076-1099`, `scripts/build-loop.sh:565-570`

---

## Claim 44: shim test name and comment: "every git call --check makes carries harden's config pairs …, no global or system config and no transport (T26, A4, U2b1a i1, i2, A17)"; "The fixture sets GIT_CONFIG_NOSYSTEM; unset, so the script's own setting is what the log shows (A17)."

**Location:** `test/scripts/build-loop-check.bats:1375-1389`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every logged call sees `GIT_CONFIG_NOSYSTEM=1` once the test unsets the fixture's copy. It does not plant a system config file (p4 covers that effect, Claim 28).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering the shim test, the old submodule test's comment and the R9 test's comment; does not cover other git versions' `add -A` handling of a dirless gitlink" · r2: "does not plant a system config file" · r3: "does not cover a git that never consults the variable"; fixture export at `test/lib/build-loop-fixtures.bash:16`

The shim logs `S=$GIT_CONFIG_NOSYSTEM`, the test runs `unset GIT_CONFIG_NOSYSTEM`, and it requires `S=1` on every line (`test/scripts/build-loop-check.bats:1379-1387`). Mutant `A17-off` fails it (`$S2/logs/mut-A17-off.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1375-1389`, `$S2/logs/mut-A17-off.txt`

---

## Claim 45: old submodule test comment: "# Not commit_all: add -A would drop the gitlink, which has no directory (R9)."

**Location:** `test/scripts/build-loop-check.bats:1404`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers git 2.39.5's `add -A` on a cacheinfo gitlink with no directory. It does not cover other versions.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound claim; P5: with the new form the merge base holds `160000 commit aaaaaa…` at `sub`, with `git add -A` after `update-index --cacheinfo` it holds nothing · r2: Medium confidence; "The add -A mechanism was not probed separately" · r3: "does not cover other versions"

`commit_all() { git add -A && … }` (`test/lib/build-loop-fixtures.bash:29`). In P4, `git ls-files -s` lists `160000 … sub` before `git add -A` and lists nothing after it.

**Evidence:** `test/lib/build-loop-fixtures.bash:29`, `$S3/logs/probe1.log` (P4)

---

## Claim 46: T14 name: "--check lists every changed path and refuses the dev cycle's own files, other briefs and the constraints doc in any case; other paths pass (T14, F2, F12, F54, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1453`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 16 named paths (four mixed-case spellings among them), the other open brief, a new brief, a closed/ path, `docs/ok.md` passing, the line count, diff-tree order, and an empty merge printing ok alone. It does not test an upper-case brief path, so "in any case" rests on the roadmap, dev-cycle, questions and constraints spellings.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "compound claim covering every added test name; does not cover T14's 'in any case' for case variants under `briefs/` or `cycles/` (only top-level case variants are planted), or T11, T13 and T14 under a mutant of their own" · r2: "does not test an upper-case brief path" · r3: "does not cover a closed brief with a real `DATE-slug` name" (covered by T15's move into closed/); fails under mT14b

The test expects `[ "${lines[0]}" = "$(nref 15 16)" ] && [ "${#lines[@]}" -eq 17 ]`, then `has "path $B A docs/ok.md"`, then the empty-merge block `[ "${#lines[@]}" -eq 1 ]` (`test/scripts/build-loop-check.bats:1461-1472`). It passes. Mutant `T14-instr-shadows` fails it.

**Evidence:** `test/scripts/build-loop-check.bats:1453-1473`, `$S2/logs/bats.txt`, `$S2/logs/mut-T14-instr-shadows.txt`

---

## Claim 47: T15 name: "--check: the brief's own file may change only its first Status: line outside a fence, open to done (T15, F13, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1475`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the allowed change and five denied variants: fenced line, dropped, extra line, chmod and trailing blank. It also covers a move to closed/ and the CRLF keep. It does not test a second unfenced Status line changing instead of the first, though line 4 (fenced) stands in for "not the first outside a fence".
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound (every added test name); mMode fails T15 · r2: "does not test a second unfenced Status line changing instead of the first" · r3: "does not cover a brief with no Status line (status_line skips it earlier)"

The loop over `'sed -i "4s/open/done/" "$B"' 'sed -i "6s/open/dropped/" "$B"' … chmod +x … echo "" >> "$B"` expects `nref 1 1` and `deny $B M $B: $NBRIEF` (`test/scripts/build-loop-check.bats:1482-1487`). The CRLF block expects `path $c M $c` (`:1491-1495`). It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1475-1496`, `$S2/logs/bats.txt`

---

## Claim 48: T11 name: "--check: a rename is its two sides, so moving a cycle file out refuses its old path (T11, F6, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1498`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one rename of the roadmap. It does not cover a rename into a cycle path, which the same per-side rule denies by its A side.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound (every added test name); T11 not run under a mutant of its own · r2: "does not cover a rename into a cycle path" · r3: "does not cover a rename with content changes (the same `--no-renames` path)"

`has "deny $B D docs/roadmap.md: $NOWN"; has "path $B A docs/x.md"` (`test/scripts/build-loop-check.bats:1504`). It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1498-1505`, `$S2/logs/bats.txt`

---

## Claim 49: T12 name and comment: "--check refuses a symlink or gitlink on either side, though submodule ignore=all is set, and passes an exec bit"; "The gate repository and the flag each suffice, so this pins them together."

**Location:** `test/scripts/build-loop-check.bats:1507-1510`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers new-side links (link, gl), old-side links (was-link, og), a regular file turned into a symlink (g.txt), exec bits on an existing and a new file, and the joint pin. It does not pin each A16 guard alone (row 518).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: two compound claims reach this cluster (every added test name; row 518 with the T12 comment); mA16both fails T12 · r2+r3: "does not pin either A16 guard alone, which the comment itself says"

`for p in "T g.txt" "A gl" "A link" "T og" "T was-link"; do has "deny $B $p: $NMODE"; done` and `has "path $B A scripts/n.sh"; has "path $B M scripts/x.sh"` (`test/scripts/build-loop-check.bats:1520-1521`). Of the A16 mutants, only `A16-realrepo-noflag` fails it (Claim 12).

**Evidence:** `test/scripts/build-loop-check.bats:1507-1522`, `$S2/logs/mut-A16-*.txt`

---

## Claim 50: T13 name: "--check refuses a changed path pathform refuses, and prints only a name in its character set (T13, F17, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1524`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers five paths: space, UTF-8, newline, leading `-` and `.github/`. It does not cover `.gitattributes` or an upper-case `.GIT` part, which pathform's `[.][gG][iI][tT]*` also refuses.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound (every added test name); T13 not run under a mutant of its own · r2: "does not cover `.gitattributes` or an upper-case `.GIT` part" · r3: "does not cover `.`/`..` parts, which git trees cannot hold"

The test expects `nref 5 5`, 6 lines, `deny $B A -x.md`, `deny $B A .github/w.yml`, and three `deny $B A ?:` lines (`test/scripts/build-loop-check.bats:1527-1530`). It passes.

**Evidence:** `test/scripts/build-loop-check.bats:1524-1531`, `$S2/logs/bats.txt`

---

## Claim 51: R6 test name: "--check refuses a merge git warned about or that names a missing object: a missing tip or merge-base tree is not read as empty, a missing blob does not land (R6, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1533`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three cases (tip tree, merge-base tree, missing blob) and their union of guards. It does not pin each R6 guard alone (row 514).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound (every added test name); mR6both and mF2 fail R6 · r2+r3: "does not pin either R6 guard alone (row 514)" · r3: the merge-base tree case is `main~1`, the merge base after `onx` and one main commit

The test passes. Mutant `R6-both` fails it, and so does `F2-nobatch` (the blob case) (`$S2/logs/mut-R6-both.txt`, `$S2/logs/mut-F2-nobatch.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1533-1551`, `$S2/logs/mut-R6-both.txt`, `$S2/logs/mut-F2-nobatch.txt`

---

## Claim 52: R6 test comment: "merge-tree reads a missing top-level tree as empty, warns and exits 0 (a missing subtree or blob is fatal)."

**Location:** `test/scripts/build-loop-check.bats:1540`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-tree on git 2.39.5 for the four missing-object shapes. It does not affect what the test asserts, which is correct.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r2: "It does not affect what the test asserts, which is correct" · r3: "does not cover the main clause, which held under mR6: the tip tree read as empty"; precise wording "(a missing subtree or blob that merge-tree must read is fatal)"; "Row 514 carries the same wording" · r3 Goal-Alignment: the test comment is a one-line edit if the loop wants a clean doc state before merging (see Escalations)

Both halves are unqualified, and the probes contradict each.
- "Exits 0": p1 case E (missing top-level tree plus a conflict) gave `merge-tree rc=1` with `error: Could not read …`.
- "A missing subtree or blob is fatal": case A (subtree passed by id) and case D (blob passed by id) each gave `rc=0` with empty stderr (`$S2/logs/p1.txt`).

The same test's third block says so itself: `# A blob the store lacks, which merge-tree passes by id without reading (security F2).` (`test/scripts/build-loop-check.bats:1545`). The precise version (a382a3f8's correction): "reads a missing top-level tree as empty with a warning, exiting 0 when the merge is otherwise clean; a missing subtree or blob is fatal only when merge-tree must read it".

**Evidence:** `test/scripts/build-loop-check.bats:1540-1550`, `$S2/logs/p1.txt`

---

## Claim 53: R7 test name and comment: "--check refuses an ambiguous default branch: both main and master, or origin/HEAD naming a branch the gate did not take (R7, U2b1b)"; "Both findings at once: a master ref that names no commit is not taken, so origin/HEAD disagrees too."

**Location:** `test/scripts/build-loop-check.bats:1553`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers four states: both branches with and without origin/HEAD, both findings at once, and origin/HEAD at main when master was taken. It does not cover a non-symbolic origin/HEAD.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound (every added test name); mR7 fails R7 · r2: "does not cover a non-symbolic origin/HEAD" · r3: "does not cover only main local with origin/HEAD at origin/master (iteration 1 probed it)"; fails under mR7 and under mDG at `:1565`

It passes, and mutant `R7-off` fails it (`$S2/logs/mut-R7-off.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1553-1570`, `$S2/logs/mut-R7-off.txt`

---

## Claim 54: R9 test name: "--check's merge reads no submodule repository: a gitlink fast-forward the real repository would merge is a conflict (R9, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1572`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-tree's isolation from `.git/modules`. It does not cover diff-tree's isolation (T12 covers that).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound (every added test name); mR9 fails R9 · r2: "does not cover diff-tree's isolation (T12 covers that)" · r3: "does not cover a submodule worktree checked out at `sub/`"

The fixture asserts that the real repository merges cleanly (`test/scripts/build-loop-check.bats:1583`). Mutant `R9-realrepo` fails the test (`$S2/logs/mut-R9-realrepo.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1572-1586`, `$S2/logs/mut-R9-realrepo.txt`

---

## Claim 55: R9 test comment: "The brief first: commit_all's add -A would drop a gitlink that has no directory"

**Location:** `test/scripts/build-loop-check.bats:1575`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the shim test under mA17 and the gitlink-drop claim by direct reproduction of both fixture forms. It does not cover other git versions' `add -A` handling of a dirless gitlink.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: compound claim covering the shim test (Claim 44 here), the old submodule test's comment (Claim 45 here) and this comment; the same add -A mechanism is verified for Claim 45 by r1 and r3

The fixture exports `GIT_CONFIG_NOSYSTEM=1` (`test/lib/build-loop-fixtures.bash:16`), and the test runs `unset GIT_CONFIG_NOSYSTEM` before the shim run. mA17 fails it. P5: with the new form, the merge base of main and feat/x holds `160000 commit aaaaaa…` at `sub`. With `git add -A` after `update-index --cacheinfo` (the old form), the base holds nothing at `sub`.

**Evidence:** `test/lib/build-loop-fixtures.bash:16`, `$S1/logs/mut-mA17.log`, `$S1/probe4.sh`, `$S1/logs/probe4.log`

---

## Claim 56: A15 test name: "--check runs its state gate before resolve_main reads an object: a planted key refuses even with main's commit missing (A15, U2b1b)"

**Location:** `test/scripts/build-loop-check.bats:1588`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test discriminates. What it establishes is that state_gate runs before main_by_name's exit-1 refusal. It does not establish that state_gate runs before resolve_main reads an object. The code does order them that way (`scripts/build-loop.sh:257-258`), so this is a test gap on the honest path, not a code defect.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Incorrect · r3=Verified
**Replicate annotations:** r1: compound (every added test name); r1's provenance describes its mutant `mA15` as "state_gate moved after resolve_main" and reports it fails A15 · r3: its Claim 51 says mA15 "moves `state_gate || exit 2` after `main_by_name`" and the test fails with status 1 ("needs a default branch …"); r3's provenance describes the same mutant as "state_gate moved after resolve_main"; "does not cover the order of state_gate and the earlier `git rev-parse --show-toplevel` (`:252`)" · r2: its mutant `A15-order` places state_gate just after `resolve_main || true` and before `main_by_name`, and the test passes; r2 notes iteration 1's mutant (after main_by_name) does fail. The replicates' mutant descriptions differ in where state_gate lands; recorded as reported · r2 Goal-Alignment: whether the gap is amber for merge is the orchestrator's call (see Escalations)

Mutant `A15-order` moves `if [[ "$MODE" == check ]]; then state_gate || exit 2; fi` from before `resolve_main || true` to just after it (diff in `$S2/logs/p2-a15.txt`). The A15 test still passes (`ok 1`, `$S2/logs/mut-A15-order.txt`). Run by hand on the test's fixture, the real script and the mutant print the same line, `refuse state merge.x.driver: set in config, …`, with `rc=2` (`$S2/logs/p2-a15.txt`). The reason: with main's commit deleted, `git show-ref --verify` fails (`fatal: git show-ref: bad ref refs/heads/main …`, `$S2/logs/p2-a15.txt`). resolve_main then falls back to the current branch (`MAIN="$cur"; MAIN_SHA="$(git rev-parse --verify --quiet HEAD …)"`, `scripts/lib/dev-cycle-read.sh:508`), and state_gate still runs before `main_by_name || … exit 1`. Iteration 1's fact-check (claims 6a and 34) tested a mutant that moved state_gate after main_by_name; that mutant does fail. A test that discriminates would need resolve_main's object read to fail visibly, for example by asserting no git call before state_gate's config reads via the shim, or by making resolve_main's failure exit before the state gate could run.

**Evidence:** `test/scripts/build-loop-check.bats:1588-1594`, `scripts/build-loop.sh:257-260`, `scripts/lib/dev-cycle-read.sh:490-512`, `$S2/logs/mut-A15-order.txt`, `$S2/logs/p2-a15.txt`

---

## Claim 57: commit cc9b69d3: the N rules and output ("path BRIEF S PATH" or "deny BRIEF S PATH: WHY"; verdict "ok BRIEF TIP TREE" only when nothing is denied, else "refuse BRIEF: K of N changed paths refused"; PATH "?" unless pathform's characters; modes in {absent, 100644, 100755}; the own brief's Status line open→done byte for byte, mode kept; cycle files and docs/constraints.md lower-cased), and R7/R9/A15/A17/A19 as described

**Location:** commit cc9b69d3 message; `scripts/build-loop.sh:553-571`, `scripts/build-loop.sh:579-628`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers each listed rule and carried fix against HEAD's code and passing tests. It does not cover the verdict's later " in the merge of TIP (tree TREE)" suffix, which cc9b69d3's own wording ("K of N changed paths refused") predates and a382a3f8 states.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3: "does not cover the K-of-N text, which a382a3f8 later extended" · r2: "does not re-verdict the probe claim or the counts and mutants"; at cc9b69d3 the refusal was `echo "refuse $a: $nd of $i changed paths refused"` (line 592), matching the message · r3: compound claim (description, tests, mutants, lines); "does not cover … the probe parenthetical (52b)"

```bash
# scripts/build-loop.sh:556-558
  if ! pathform "$6"; then DENY="not an allowed path form (...)"
  elif [[ ! "$2 $3" =~ ^(000000|100644|100755)\ (000000|100644|100755)$ ]]; then DENY="a symlink, gitlink ..."
  elif [[ "$6" == "$1" ]]; then
```
(excerpt ends :558; enclosing nrules() continues to :571 — read). r1's claims 1, 30-36 and 38 cover the tests that pin each rule. A19's help and comment items match the main→HEAD diff of the header (`refuse state gate:`, "not an empty file", the verdict-line exit wording, shallow and origin/HEAD in the state list).

**Evidence:** `scripts/build-loop.sh:80-139`, `scripts/build-loop.sh:553-628`, `$S1/logs/build-loop-check.log`

---

## Claim 58a: cc9b69d3: "Mutants: R6 with both guards removed, R7 with the check off, R9 with merge-tree in the real repository each fail their test."

**Location:** commit cc9b69d3 message; `scripts/build-loop.sh:510-529`, `scripts/build-loop.sh:241-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the three named mutants against HEAD's tests: each fails only its own test. It does not cover the same mutants against cc9b69d3's tests, which differ only in the R7 test's middle block and the missing-blob clause added later.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: "does not cover the same mutants against cc9b69d3's tests" · r2: compound (tests, mutants, line count); mutants run on today's code, which keeps those guards · r3: compound; mutants "run at HEAD, where those lines are unchanged"

The guards the mutants removed:
```bash
# scripts/build-loop.sh:512-513 (gate_git, whole body :510-515 read)
  (cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@") 2>"$GATE_TMP/err" || rc=$?
  [[ ! -s "$GATE_TMP/err" ]] || return 3
# scripts/build-loop.sh:525 (merge_result, :520-529 read)
  for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done
```
Results: `mR6both` fails "R6, U2b1b", `mR7` fails "R7, U2b1b" and `mR9` fails "R9, U2b1b". Each other filtered test stayed ok.

**Evidence:** `scripts/build-loop.sh:241-251`, `scripts/build-loop.sh:510-529`, `$S1/logs/mut-mR6both.log`, `$S1/logs/mut-mR7.log`, `$S1/logs/mut-mR9.log`, `$S1/logs/mut-base.log`

---

## Claim 58b: cc9b69d3: "Tests: build-loop-check 101 (92 + 9), build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2; shellcheck clean … 317 changed lines."

**Location:** commit cc9b69d3 message; plan `docs/working/plan-build-loop-handoff.md:283` ("cc9b69d3, 317 lines")
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the suite counts at HEAD (only build-loop-check.bats changes on the branch, so the other counts are the same at each commit) and the `@test` counts and line counts at each commit. It does not re-run the suites at cc9b69d3 or a382a3f8.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: compound claim covering the counts in all three later commit messages (cc9b69d3, a382a3f8, e02d056b) and the plan's "317 lines" · r2: compound (tests, mutants, line count); "matches the 'test tally' hallucination pattern, and the counts check out" · r3: compound; nine `+@test` lines; 282 insertions and 35 deletions · r1+r2+r3: suites not re-run at cc9b69d3 itself

`git show <c>:test/scripts/build-loop-check.bats | grep -c '^@test'` gives main 92, and 101 at cc9b69d3, a382a3f8 and e02d056b. `git diff --numstat main <c> -- scripts test`, adds plus deletes, gives 282+35=317 at cc9b69d3, 328+39=367 at a382a3f8 and 343+39=382 at e02d056b. The suites at HEAD passed 101/19/78/2/2, and shellcheck exited 0 (provenance above).

**Evidence:** `$S1/logs/build-loop-check.log`, `$S1/logs/build-loop-read.log`, `$S1/logs/dev-cycle.log`, `$S1/logs/fixture-git-env.log`, `$S1/logs/fixture-hermeticity.log`, `$S1/logs/shellcheck.log`

---

## Claim 59: cc9b69d3: "R6: … (a missing top-level tree is read as empty with exit 0; a missing subtree or blob is fatal, probed)"

**Location:** commit cc9b69d3 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the parenthetical's subtree half for a subtree the tip passes by id. It does not re-probe the top-level-tree half, which a382a3f8's correction qualifies ("exiting 0 only when that merge is otherwise clean") and iteration 2's fact-check probed.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r1: "The commit message is immutable and the record is complete. Nothing more is needed than the existing corrections" · r2: also refutes the top-level half (case E: a missing top-level tree with a conflict exits 1, not 0); "no further action is needed beyond Claims 10b and 51, where the uncorrected wording survives" (Claims 10b and 52 here) · r3: "a382a3f8 corrects this, and the rubric records it as Accepted-immutable (A4)"

P1b: the tip adds `newdir/`, a tree whose object was then deleted. merge-tree did not fail. merge_result returned 0, and the refusal came from diff-tree:
```
refuse docs/working/briefs/2026-10-01-x.md: the paths the merge of feat/x changes could not be listed
```
So "a missing subtree … is fatal" is false for a subtree passed by id. This is already corrected in a382a3f8's correction paragraph ("fatal only when merge-tree must read it") and in e02d056b's ("refused by diff-tree"). The commit message is immutable and the record is complete. Nothing more is needed than the existing corrections; listed because the claim as written is refuted.

**Evidence:** `$S1/probe2.sh`, `$S1/logs/probe2.log`, `scripts/build-loop.sh:597-600`

---

## Claim 60: cc9b69d3 Notes: "the plan puts it in U2b1b's diff parse, rev 2 marked T12 refuse under both, and D3 makes a symlink a loop stop condition"

**Location:** commit `cc9b69d3` message (Notes)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** This covers the plan text at e02d056b and at 9b292d6f (the revision-2 plan). It does not establish "under both" for rev 2's T12.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Unverifiable · single-replicate detection
**Replicate annotations:** r3: "'Under both' would need the rev-2 test strategy or a policy-qualified row, and neither was found"

- **Diff parse.** Step 5's U2b1b bullet puts "the raw `diff-tree -z` parse of MAIN→TREE with the mode rule" in U2b1b (`docs/working/plan-build-loop-handoff.md:283`).
- **D3.** It lists "a symlink" as a stop condition (`:55`).
- **Rev 2's T12.** At 9b292d6f the row reads `| T12 | Symlink added; file → symlink; exec bit; gitlink | refuse (mode) | integration |`, and F7 has no N/S mark in that table (paraphrased — no quote available because this is about an absent marker: the bypass table at 9b292d6f has no N/S column). "Under both" would need the rev-2 test strategy or a policy-qualified row, and neither was found.

**Evidence:** `docs/working/plan-build-loop-handoff.md:55`, `docs/working/plan-build-loop-handoff.md:283`, `git show 9b292d6f:docs/working/plan-build-loop-handoff.md` (lines 26-37, 169)

---

## Claim 61: commit 809df345: "Plan: F8 names the gate repository and --ignore-submodules=none (the -c diff.ignoreSubmodules=none form does not override a planted submodule.<name>.ignore=all); the --check interface line describes the verdict, path and deny lines; step 5's U2b1b note records what was built. Override log rows 497 and 507-511 gain their U2b1b resolution. R8 is left open with a proposal"

**Location:** `git log -1 809df345`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the doc edits and F8's probe claim (Claim 15). It does not re-check the text of the later edits to those rows.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound claim covering 809df345's F8 sentence and the plan F8 row; "does not cover other git versions" · r2: "does not re-check the text of the later edits to those rows" · r3: "does not cover the later staleness of the step-5 note and the --check line" (Claims 18 and 19b here)

Plan lines 123, 212 and 283 and rows 497 and 507-511 carry the named additions (the diff in this session). p4 confirms the -c form does not override `submodule.<name>.ignore=all` (`$S2/logs/p4.txt`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:123`, `docs/working/plan-build-loop-handoff.md:212`, `docs/working/plan-build-loop-handoff.md:283`, `docs/reviews/override-log.md:497-511`, `$S2/logs/p4.txt`

---

## Claim 62: a382a3f8: the fixed items (security F1 own_blob status; F2 one batch-check, "mutant fails"; performance F1 one lower_all pass; api 1 TIP and TREE in the verdict; api 2/arch 5 default_gate printing every finding; arch 1 nrules reads truthrule's words; arch 2 contract item 5; T14, T12 additions; R8 decided; fact-check 6b row 511 names row 492)

**Location:** commit a382a3f8 message; `scripts/build-loop.sh:536-628`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers each item against HEAD: mF2 fails R6, and T14 includes `docs/working/Questions.md` and `docs/CONSTRAINTS.md`. It does not cover the "13.5 s at 5,000 paths as built" figure (iteration 1's performance report gives 13,460 ms; I did not rebuild cc9b69d3), or the "names a file the object store lacks" wording, which was accurate at a382a3f8 and changed to "a blob" in e02d056b.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not cover the '13.5 s at 5,000 paths as built' figure" (Claim 64 here) · r2: "does not cover the A16 sentence (Claim 60) or the timing (Claim 61)" (Claims 63 and 64 here) · r3: compound claim (fix list, R8 decided and declined rows, tests and 367 lines); "does not cover the A16 mutant sentence (54b) or the 13.5 s figure (54c)"; shellcheck flags lib lines 818, 910, 916, 941, 1016, 1018 and 1023, all outside the branch's lib edits

```bash
# scripts/build-loop.sh:562-566 … :619-620
    truthrule "$7" || true
    case "$TRUTH_WHY" in
      cycle|settings) DENY="one of the dev cycle's own files" ;;
  if ! nul_list lps lower_all "${ps[@]}" || [[ ${#lps[@]} -ne ${#ps[@]} ]]; then
```
(excerpt ends :566; nrules() continues to :571 — read). The verdict prints `refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)` (`scripts/build-loop.sh:626`).

**Evidence:** `scripts/build-loop.sh:536-628`, `test/scripts/build-loop-check.bats:1453-1473`, `$S1/logs/mut-mF2.log`, `docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b1b.md:29`

---

## Claim 63: commit a382a3f8: "A16 is pinned (T12 under submodule ignore=all in .gitmodules and the repo config; the mutant running diff-tree in the real repository fails it)."

**Location:** `git log -1 a382a3f8`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three A16 mutants. It does not change the settled disposition (row 518, Won't-Fix).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "e02d056b's test comment and row 518 already say this" · r3: "does not cover the commit's intent"; immutable commit message, recorded elsewhere (row 518)

Moving diff-tree into the real repository while keeping `--ignore-submodules=none` passes T12. Only the mutant that also drops the flag fails it (`$S2/logs/mut-A16-realrepo-keepflag.txt`, `$S2/logs/mut-A16-realrepo-noflag.txt`). The precise version: "the mutant running diff-tree in the real repository without --ignore-submodules=none fails it". e02d056b's test comment and row 518 already say this.

**Evidence:** `test/scripts/build-loop-check.bats:1508-1510`, `docs/reviews/override-log.md:518`, `$S2/logs/mut-A16-realrepo-keepflag.txt`, `$S2/logs/mut-A16-realrepo-noflag.txt`

---

## Claim 64: commit a382a3f8: "performance F1: one lower_all pass per brief instead of a tr per path (measured 13.5 s at 5,000 paths as built)"

**Location:** commit `a382a3f8` message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** This covers cc9b69d3's `--check` at 5,000 added paths on this host, in one run. It does not reproduce the 13.5 s figure, which depends on the host.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=Mostly accurate
**Replicate annotations:** r1: its a382a3f8 claim explicitly excluded this figure ("iteration 1's performance report gives 13,460 ms; I did not rebuild cc9b69d3") · r2: re-measured 8,977 and 8,879 ms, "about 34% lower"; "It cannot confirm a past measurement taken under different load"; "Verifying the exact figure would need the original machine and load" · r3: re-measured 9,379 ms; the sevenfold gap and mechanism reproduce, the absolute figure does not

In probe3, cc9b69d3's script took 9,379 ms for 5,000 paths, against about 1,330 ms at HEAD (probe2). The roughly sevenfold gap and the mechanism (a `tr` per path, 1.08 ms each) are reproduced, but the absolute figure is not.

**Evidence:** `$S3/logs/probe3.log`, `$S3/logs/probe2.log`

---

## Claim 65: a382a3f8 correction paragraph: "a missing subtree or blob is fatal only when merge-tree must read it (one passed by id is silent, which security F2 now refuses)"

**Location:** commit a382a3f8 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers the passed-by-id behaviour (confirmed for a subtree by P1b) and which check refuses each kind. It does not re-probe a missing blob merge-tree must read.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=—
**Replicate annotations:** r2: compound claim covering a382a3f8's correction and e02d056b's correction "together on git 2.39.5"; "does not cover other git versions" · r1: "e02d056b's correction paragraph says exactly this, so the record is already complete"

"Which security F2 now refuses" holds for blobs. For a missing subtree, merge-tree is silent and diff-tree refuses it ("could not be listed", P1b), not F2's batch-check. e02d056b's correction paragraph says exactly this, so the record is already complete.

**Evidence:** `$S1/logs/probe2.log`, `scripts/build-loop.sh:611-617`

---

## Claim 66: commit a382a3f8: "Tests: build-loop-check 101, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2; shellcheck clean on build-loop.sh … 367 code lines against main."

**Location:** `git log -1 a382a3f8`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at a382a3f8 and the line count (added plus deleted in `scripts` and `test`). It does not re-run the suites at that commit.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: compound (counts across three commits; also "367 lines" inside its fix-list claim) · r3: compound (fix list, tests, 367 lines); "the lib's notes are on untouched lines" checked against shellcheck · r1+r2+r3: suites not re-run at a382a3f8

`grep -c '^@test'` gave `a382a3f8: chk=101 read=19 dc=78 fge=2`, and `--numstat main a382a3f8 -- scripts test` sums to `add 328 del 39 sum 367` (run in this session).

**Evidence:** `test/scripts/build-loop-check.bats`

---

## Claim 67: commit e02d056b: "5,000 paths now about 1.3 s … help says pathform refuses a part starting .git in any case; the missing-object refusal reads "names a blob the object store lacks" … and the help lists it as its own case … the R7 test now shows default_gate printing both findings (a master ref naming a tree) … plan F12 and --state; override rows 509, 512, 517 and three new rows … Tests: build-loop-check 101, …; shellcheck clean. 382 code lines against main. Notes: wording and one test only; no behavior change but the refusal text."

**Location:** `git log -1 e02d056b`
**Type:** Behavioral / Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the timing, the help and refusal text, the R7 block, the counts and line count, and the no-behavior-change claim. It does not check the cited reviewer finding numbers against the iteration-2 reports.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: compound claim (items, Notes and correction paragraph); "does not cover the iteration-2 reviewers' own findings beyond the rubric's summary of them ('no red')" · r2: "does not check the cited reviewer finding numbers against the iteration-2 reports" · r3: "does not cover 'plan F12 and the --state line match the code' beyond those two lines: the --check line beside them is stale (Claim 18)"; mDG fails the new R7 both-findings assertion

The evidence, item by item:
- Timing: p3 measured 1,275-1,338 ms.
- Help: it reads `(a part starting .git, any case: .github/)` (`scripts/build-loop.sh:122`) and lists the blob refusal as its own case (`:107-110`).
- R7 test: it writes `git rev-parse main^{tree} > .git/refs/heads/master` and expects both lines (`test/scripts/build-loop-check.bats:1562-1565`).
- Counts: e02d056b has `chk=101 read=19 dc=78 fge=2`, and the 124 + 78 suite runs passed.
- Line count: `sum 382`.
- No behavior change: in `git diff a382a3f8 e02d056b -- scripts test`, the only non-comment changes are the moved truthrule call (comment removed), the refusal text, and the R7 test block.

**Evidence:** `scripts/build-loop.sh:107-122`, `test/scripts/build-loop-check.bats:1553-1570`, `$S2/logs/p3-time.txt`, `$S2/logs/bats.txt`, `$S2/logs/bats-dc.txt`

---

## Claim 68: commit e02d056b correction: "a missing subtree passed by id is refused by diff-tree ('could not be listed'), not by the missing-blob check, which covers blobs."

**Location:** commit `e02d056b` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** This covers a one-sided addition of a directory whose subtree id is absent. It does not cover a subtree both sides change, which merge-tree reads and fails on.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: compound (e02d056b items, Notes and correction); P1b · r2: compound (a382a3f8 and e02d056b corrections together); "does not cover other git versions" · r3: "does not cover a subtree both sides change, which merge-tree reads and fails on"

P1 prints `refuse docs/working/briefs/2026-10-01-x.md: the paths the merge of feat/x changes could not be listed`, with rc 2. The batch-check only collects ids with a regular-file mode (`scripts/build-loop.sh:606`).

**Evidence:** `scripts/build-loop.sh:599-618`, `$S3/logs/probe1.log` (P1)

---

## Claims Requiring Attention

### Incorrect
- **Claim 10b** (`docs/reviews/override-log.md:514`): the parenthetical "(a missing subtree or blob is fatal, exit 128)" repeats cc9b69d3's uncorrected probe claim. A subtree or blob merge-tree passes by id is silent and is refused by diff-tree or the batch-check. The row's disposition holds.
- **Claim 52** (`test/scripts/build-loop-check.bats:1540`): "exits 0 (a missing subtree or blob is fatal)" is unqualified. It exits 1 on a conflict, and a subtree or blob passed by id is silent, as the same test's third block says. Use a382a3f8's corrected wording.
- **Claim 56** (`test/scripts/build-loop-check.bats:1588`): r2 found the A15 test does not establish its name. A mutant running state_gate after resolve_main (before main_by_name) passes it. The code's order is right; the test pins only "before main_by_name". This is an honest-path test gap. r1 and r3 verdicted Verified on mutants whose descriptions differ (see the claim's annotations).
- **Claim 59** (commit cc9b69d3): "a missing subtree … is fatal" is false for a subtree passed by id. It is already corrected in a382a3f8's and e02d056b's messages, and the message is immutable, so no action is needed.

### Stale
- **Claim 18** (`docs/working/plan-build-loop-handoff.md:212`): the refusing verdict is `refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)` (since a382a3f8). The plan line still shows the pre-a382a3f8 form.
- **Claim 19b** (`docs/working/plan-build-loop-handoff.md:283`): "R8 is proposed as a Q-103 residual for its review to decide". R8 was decided at iteration 1 (row 509).

### Mostly Accurate
- **Claim 10a** (`docs/reviews/override-log.md:514`): the union pin holds, but r3's compound verdict on the row is carried by the overbroad parenthetical (Claim 10b).
- **Claim 20** (`docs/working/plan-build-loop-handoff.md:305`): step 13's R8 surface omits `git/refs/` and `git/HEAD`, which row 509 lists.
- **Claim 22** (`scripts/build-loop.sh:90-92`): "refuse state gate" is printed after open_shared has read main's open briefs, so it comes before any verdict line, not before any brief is read. A failed mktemp exits 1 with no line.
- **Claim 27** (`scripts/build-loop.sh:137-139`): the Exit line does not mention that a failed mktemp exits 1.
- **Claim 36** (`scripts/build-loop.sh:564`): T14 fails only for a shadow outside `briefs/` and `cycles/`. Inside them the subtree rule still denies.
- **Claim 39** (`scripts/build-loop.sh:608`): the NUL count does not catch bytes after the last NUL. git's own output cannot produce that (row 513).
- **Claim 63** (commit a382a3f8): the real-repo diff-tree mutant fails T12 only when the flag is also dropped. Row 518 and the test comment already say this.
- **Claim 64** (commit a382a3f8): "13.5 s at 5,000 paths" was re-measured at 8.9-9.4 s. The magnitude and mechanism reproduce, but the exact figure depends on the host.
- **Claim 65** (commit a382a3f8): F2 refuses missing blobs; diff-tree refuses a missing subtree, not F2. e02d056b says so.

### Unverifiable
- **Claim 60** (commit cc9b69d3 Notes): "rev 2 marked T12 refuse under both". Rev 2's T12 row says "refuse (mode)" with no policy mark, so confirming it would need the rev-2 test strategy.

## Escalations

No replicate's report carries a Goal-Alignment Escalate item, and none has an Out-of-scope bullet naming a critic. The items below are escalation-shaped notes from claim prose and the Goal-Alignment notes.

- **E1.** `test/scripts/build-loop-check.bats:1588` (A15 test name, Claim 56). Raised by r2: "Whether the A15 gap is amber for merge is the orchestrator's call: either rename the test to 'before main_by_name refuses' or strengthen it." Addressee: orchestrator.
- **E2.** `docs/working/plan-build-loop-handoff.md:212`, `:283`, `:305` (Claims 18, 19b, 20), and `test/scripts/build-loop-check.bats:1540` (Claim 52, r3 only). Raised by r1: "These are wording, not reds, and are worth a one-line plan edit before merge, since the plan is the spec U3 builds `--merge` from (the :212 line in particular)". Raised by r3: "The two stale plan lines and the test comment are one-line edits if the loop wants a clean doc state before merging." Addressee: orchestrator.
- **E3.** `docs/reviews/override-log.md:509` (R8 surface, Claim 5). Raised by r1, in its Scope line: "It does not cover whether the race is exploitable (the threat-scope decision is the reviewers')." Addressee: the reviewers (r1's wording, unnamed). Row 509 records that security and architecture concurred on the Q-103 residual.

## Verdict stability

- **Total clusters:** 71
- **Clusters where all reporting replicates agreed:** 59. Two of them are single-replicate detections: Claim 55 (r1 only) and Claim 60 (r3 only).
- **Disagreeing clusters (12):**
  - Claim 10a (row 514, union pin): r1=Verified (compound) · r2=Verified · r3=Mostly accurate (compound)
  - Claim 10b (row 514, parenthetical): r1=— · r2=Incorrect · r3=Mostly accurate (compound)
  - Claim 18 (plan `--check` line): r1=Stale · r2=Mostly accurate · r3=Stale
  - Claim 22 (help, "refuse state gate" timing): r1=Verified (compound) · r2=Mostly accurate · r3=Mostly accurate
  - Claim 27 (help Exit line): r1=Verified · r2=Mostly accurate · r3=Verified
  - Claim 36 ("T14 fails if one ever does"): r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
  - Claim 39 (NUL-count comment): r1=Mostly accurate · r2=Verified · r3=Mostly accurate
  - Claim 52 (R6 test comment): r1=— · r2=Incorrect · r3=Mostly accurate
  - Claim 56 (A15 test name): r1=Verified (compound) · r2=Incorrect · r3=Verified
  - Claim 59 (cc9b69d3 R6 parenthetical): r1=Incorrect · r2=Incorrect · r3=Mostly accurate
  - Claim 64 (a382a3f8 "13.5 s"): r1=— · r2=Unverifiable · r3=Mostly accurate
  - Claim 65 (a382a3f8 correction paragraph): r1=Mostly accurate · r2=Verified (compound) · r3=—
- **Agreement rate:** 59/71 = 83.1%


# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1b (branch feat/build-loop-u2b1b, HEAD e02d056b)
**Scope:** The five endorsement claims marked `route: code-fact-check` in `docs/reviews/security-reviewer-review-2026-10-08-build-loop-u2b1b-final.md:134-169` (submitting critic: security-reviewer). Subject code: `scripts/build-loop.sh`. Nothing else in the diff is verdicted.
**Checked:** 2026-10-08
**Total claims checked:** 6 (five submitted claims; claim 72 split into 72a and 72b on verdict divergence)
**Summary:** 5 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance, common to every `executed` claim below. Probe scripts and their captured output live in the agent's scratch directory, `/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i3/fc-sub/` (written as `fc-sub/` below). Each probe was run as `timeout 300 bash pNN.sh > pNN.log 2>&1` from `fc-sub/`, and every final run exited 0. Each probe sources `fc-sub/lib.bash`, which starts with `set -eu`, creates its own `mktemp -d -p fc-sub` directory, `cd`s into it, refuses `git init` outside it, unsets git's local env variables, and sets `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 HOME=<tmp>/home LC_ALL=C`. Inside each fixture repo the probe runs `bash <worktree>/scripts/build-loop.sh --check BRIEF`. Each run's log records the fixture cwd, a UTC timestamp (2026-10-08T22:39Z to 22:43Z), the command and its exit code. git 2.39.5. The worktree's `test/scripts/build-loop-check.bats` already had uncommitted changes, not made by this agent, before any run here (mtime 22:38:14Z). They change one comment in the R6 test and the A15 test. The bats run cited below used that working copy, but none of the tests it selected (R6, R7, R9, A17, the U2b1a i2 tests and checkout attributes) has a changed assertion. No process outlives its probe: every script ran under `timeout` and none starts a background job. The worktree was not modified.

The hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) was read. No claim below matches a logged pattern.

---

## Submitted Claims

## Claim 72a: "A missing main ... tree ... makes `--check` refuse the brief (exit 2) rather than print ok."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:520-530`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a branch whose main commit's root tree object is deleted from the loose store: `--check` exits 2 and prints no ok line. It does not establish that merge_result's own main-tree test (`:525`) is ever what refuses: in this shape the brief read fails first, and the line is a `skip`, not a `refuse`. It also does not cover a packed-object store or a main tree that is corrupt but present.

The outcome holds: exit 2 and no ok line. The line kind and the code path differ from the claim. Probe 72a (`fc-sub/p72.log`, fixture `.../a`) deleted `main^{tree}` and got:

```
exit 2
fatal: unable to read tree (144083eb8cb629cedc9e891c7db0b24274953ed0)
skip docs/working/briefs/2026-10-01-x.md: the tree of the default branch could not be read
```

That is `status_line`'s skip, which `check_line` passes through before it reaches merge_result:

```bash
# scripts/build-loop.sh:581-582
  out="$(status_line "$a")"
  [[ "$out" == "ok "* ]] || { echo "$out"; return; }
```

The main loop counts any line that is not ok as a failure. It does so here:

```bash
# scripts/build-loop.sh:646-649
      out="$(check_line "$a")"; printf '%s\n' "$out"
      [[ "$out" == "ok "* ]] || fails=1
    done
    [[ "$fails" -eq 0 ]] || exit 2
```

The brief is read from main's tree, so a missing main root tree always fails at that read before merge_result runs. Its `cat-file -e "$MAIN_SHA^{tree}"` at `:525` is therefore defence in depth on this path (paraphrased — no quote available because this is an inference that `check_brief`/`main_entry` in `scripts/lib/dev-cycle-read.sh` must read main's root tree to find the brief, drawn from the probe's `skip ... tree of the default branch could not be read` message). A reader who expects a `refuse` line for this case will see `skip` instead. Exit 2 and the absence of an ok line are as claimed. The lib's `fatal:` stderr line also reaches the output; that is outside this claim.

**Evidence:** `scripts/build-loop.sh:520-530`, `scripts/build-loop.sh:579-582`, `scripts/build-loop.sh:644-649`, fixture `fc-sub/p72.sh`, captured output `fc-sub/p72.log` (case "72a main tree missing")

---

## Claim 72b: "A missing ... tip or merge-base tree, any stderr from a gate git call, or a new regular file whose blob is absent or not a blob makes `--check` refuse the brief (exit 2) rather than print ok."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:510-530`, `scripts/build-loop.sh:599-618`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the following, each executed: a deleted tip tree; a deleted merge-base tree; a stderr line injected into each of the six gate git calls (merge-base `:522`, cat-file -e `:525`, merge-tree `:526`, hash-object `:542`, diff-tree `:599`, cat-file --batch-check `:615`); an added (A) and a changed (M) 100644 entry whose blob is absent; a 100644 entry naming a tree; a 100755 entry naming a commit. Each refuses with exit 2. It does not establish the security-reviewer's own Not-verified case (a corrupt, present blob at an unchanged path), packed-object stores, or that every refusal message names the true cause: stderr from the batch-check reads "names a blob the object store lacks", and stderr from hash-object surfaces as a deny row.

The mechanism, quoted. gate_git turns any stderr into status 3:

```bash
# scripts/build-loop.sh:510-515
gate_git() {
  local rc=0
  (cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@") 2>"$GATE_TMP/err" || rc=$?
  [[ ! -s "$GATE_TMP/err" ]] || return 3
  return "$rc"
}
```

merge_result returns 2 for any of those statuses, and for a missing tree among main, tip and every merge base:

```bash
# scripts/build-loop.sh:522-529 (enclosing merge_result() spans :520-530 — read)
  bases="$(gate_git merge-base --all "$MAIN_SHA" "$1")" || rc=$?
  [[ "$rc" -le 1 ]] || return 2
  for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done
  rc=0; out="$(gate_git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1")" || rc=$?
  [[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2
  [[ "$rc" -eq 0 ]] || return 1
```

`check_line` maps that return to a refuse line (`:591-596`), as it does a diff-tree failure (`:599-601`). Blob presence is checked only for new modes 100644 or 100755:

```bash
# scripts/build-loop.sh:606
    [[ "${nms[-1]}" != 100644 && "${nms[-1]}" != 100755 ]] || ids+=("${nos[-1]}")
# scripts/build-loop.sh:615-618
  if [[ ${#ids[@]} -gt 0 ]] && { ! out="$(printf '%s\n' "${ids[@]}" | gate_git cat-file --batch-check='%(objecttype)')" \
    || [[ "$(printf '%s\n' "$out" | grep -cx blob)" -ne ${#ids[@]} ]]; }; then
    echo "refuse $a: the merge of $br names a blob the object store lacks"; return
  fi
```

(`check_line` spans `:579-628` — read.) Executed results, all exit 2 with no ok line (`fc-sub/p72.log`, plus the first case of `fc-sub/p73.log`):

- tip tree deleted: `refuse ...: the merge of feat/x could not be computed`
- merge-base tree deleted: the same refuse line
- stderr injected (a PATH shim that writes one stderr line only when `GIT_DIR=*/git`):
  - merge-base, cat-file -e, merge-tree: `could not be computed`
  - diff-tree: `the paths the merge of feat/x changes could not be listed`
  - `--batch-check` alone: `names a blob the object store lacks`
  - hash-object: `1 of 1 changed paths refused ... deny ... this brief: ...`
- A entry with absent blob, M entry with absent blob, 100644 naming a tree, 100755 naming a commit (written with `hash-object -t tree --literally`): `refuse ...: the merge of feat/x names a blob the object store lacks`

A control run with no fault prints `ok` and exits 0. A second control, the honest own-brief edit without the shim, also exits 0.

**Evidence:** `scripts/build-loop.sh:510-530`, `scripts/build-loop.sh:579-628`, fixtures `fc-sub/p72.sh`, `fc-sub/p73.sh`, captured output `fc-sub/p72.log`, `fc-sub/p73.log` (case "72d stderr from gate cat-file --batch-check only"); the R6 bats test also passes (`fc-sub/bats.log`, ok 5)

---

## Claim 73: "Under both policies the brief's own file passes only as an `M` record with equal old and new modes whose new blob id equals main's copy with its first unfenced `Status: open` line rewritten to `Status: done` (CR kept)."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:536-543`, `scripts/build-loop.sh:558-560`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the own-brief arm of `nrules`, executed under both review and self-merge policy. It passes: the honest edit (LF, CRLF, and a 100755 brief keeping its mode), and an unchanged brief (no record). It denies: a fenced Status line changed; a second unfenced Status line changed, alone or with the first; open→dropped; "done " with a trailing blank; lower-cased "status: done"; an exec bit added; an exec bit dropped; another line changed; a trailing CR added; a dropped CRLF CR; deletion; replacement by a symlink (denied by the mode rule first). It does not establish behaviour when `brief_fields` and `own_blob` disagree on which line is the first Status line (security-reviewer's Not-verified item). It also does not establish that the brief path diff-tree reports always byte-equals the argument spelling `$1`: a case or `./` variant of the argument was not probed.

The rule, quoted:

```bash
# scripts/build-loop.sh:558-560 (enclosing nrules() spans :553-572 — read)
  elif [[ "$6" == "$1" ]]; then
    { [[ "$5" == M && "$2" == "$3" ]] && ob="$(own_blob "$1")" && [[ "$4" == "$ob" ]]; } \
      || DENY="this brief: only its first Status: line outside a fence may change, from open to done"
```

The pathform and mode arms come first (`:556-557`), so a T record never reaches this arm. own_blob finds the first unfenced `^Status:` line, rewrites only that line number, keeps an optional CR, and hashes the result in the gate repository:

```bash
# scripts/build-loop.sh:540-542 (enclosing own_blob() spans :536-543 — read)
  n="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } !n && /^Status:/ { n = NR } END { print n + 0 }')" || return 1
  [[ "$n" -gt 0 ]] || return 1
  git cat-file blob "$MAIN_SHA:$1" | N="$n" perl -pe 's/^Status: open(\r?)$/Status: done$1/ if $. == $ENV{N}' | gate_git hash-object --no-filters --stdin
```

Executed (`fc-sub/p73.log`). The honest edit gives exit 0 with `path ... M <brief>`. It also passes alongside another file's change, and an unchanged brief passes with only the other path listed. CRLF with the CR kept: exit 0; with the CR dropped: deny. A 100755 brief edited honestly: exit 0; with its mode dropped: deny. Self-merge policy (`--settings` prints `policy self-merge set`): honest edit exit 0; extra line deny. Every other variant listed in Scope prints `deny ... this brief: only its first Status: line outside a fence may change, from open to done`, or, for the symlink, the mode deny, with exit 2.

**Evidence:** `scripts/build-loop.sh:536-543`, `scripts/build-loop.sh:553-572`, fixture `fc-sub/p73.sh`, captured output `fc-sub/p73.log`

---

## Claim 74: "A record with mode other than 000000/100644/100755 on either side (symlink, gitlink, tree-typed entry) is denied, including a gitlink that `submodule.<name>.ignore=all` in repo config and `.gitmodules` would hide from diff-tree in the real repository."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:557`, `scripts/build-loop.sh:599`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these records as diff-tree prints them: symlink added, deleted, symlink→file, file→symlink; gitlink added, moved, and gitlink→file, each with `ignore = all` in both `.gitmodules` and repo config. Each is denied, and a control shows real-repo `git diff-tree` printing nothing for the added and the moved gitlink. It does not establish a denial for a raw non-canonical regular mode such as 100664. git reads that mode as 100644, so no such record ever appears and the path passes (see below). A tree-typed (040000) record cannot appear under `-r` and was not constructed.

The rule and the diff-tree call:

```bash
# scripts/build-loop.sh:557
  elif [[ ! "$2 $3" =~ ^(000000|100644|100755)\ (000000|100644|100755)$ ]]; then DENY="a symlink, gitlink or other non-file entry on one side (only modes 100644 and 100755 land)"
# scripts/build-loop.sh:599
  if ! gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree" > "$GATE_TMP/diff"; then
```

Executed (`fc-sub/p74.log`):

- Each symlink shape is denied: `deny ... A link`, `D was-link`, `T was-link`, `T f.txt`.
- With `ignore = all` set, real-repo `git diff-tree -r --no-renames --raw main <merge>` printed nothing (`(end; exit 0)`), and so did real-repo `git diff-tree -r main feat/x` for the moved gitlink.
- The gate still printed `deny ... A gl`, `deny ... M gl` and `deny ... T gl`, each with exit 2.

The reviewer's Not-verified expectation, that 100664 in main's old tree is "denied by the regex", is wrong, but harmlessly so. With 100664 on main's old side, real-repo `diff-tree` prints `:100644 100644 ... M g.txt` and the gate prints `ok` with `path ... M g.txt`. A branch tree whose raw bytes hold `100664 g.txt` also passes as `A g.txt`, and the gate's TREE stores the entry as `100644 g.txt` (`fc-sub/p74b.log`, raw tree bytes). git canonicalises the mode on read, and merge-tree writes the canonical mode, so no non-file mode lands. This is outside the claim, which is about records, and does not change the verdict.

**Evidence:** `scripts/build-loop.sh:553-572`, `scripts/build-loop.sh:599-606`, fixtures `fc-sub/p74.sh`, `fc-sub/p74b.sh`, captured output `fc-sub/p74.log`, `fc-sub/p74b.log`

---

## Claim 75: "No gate git call (`:522`, `:525`, `:526`, `:542`, `:599`, `:615`) reads the repository's config, config.worktree, info/attributes, checkout `.gitattributes`, `.git/modules/*`, global or system config, absent a writer racing GATE_TMP (R8)."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:188-198`, `scripts/build-loop.sh:497-515`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the gate_git invocations at the six listed sites, each executed under planted values in every named source. Each sees only the gate repository's two-line config plus harden's command-line pairs, and no attribute. A union merge driver planted in every attribute source does not turn a conflict clean, though the real repository merges the same pair cleanly. It does not establish:
- a syscall-level absence of reads (strace is not installed; the evidence is git's own `config --list --show-origin` and `check-attr -a` run in each call's exact environment and cwd, plus the behavioural union test);
- the non-gate git call that shares line `:542` (own_blob's `git cat-file blob`, run in the real repository) or any lib read, which do read repo config, hardened;
- caller-set `GIT_CONFIG_PARAMETERS`/`GIT_ATTR_SOURCE`, alternates/MIDX, or the R8 race (the reviewer's Not-verified items).

The construction, quoted. harden adds the config pairs and `:198` exports `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ATTR_NOSYSTEM=1`. gate_repo unsets every local env variable except `GIT_CONFIG*` and `GIT_NO_REPLACE_OBJECTS`, and points git at a fresh git dir and an empty cwd:

```bash
# scripts/build-loop.sh:500-505 (enclosing gate_repo() spans :497-506 — read)
  for v in $(git rev-parse --local-env-vars); do [[ "$v" == GIT_CONFIG* || "$v" == GIT_NO_REPLACE_OBJECTS ]] || GATE_ENV+=(-u "$v"); done
  v="$(git rev-parse --path-format=absolute --git-path objects)" && fmt="$(git rev-parse --show-object-format)" \
    && [[ "$fmt" == sha1 || "$fmt" == sha256 ]] && mkdir "$GATE_TMP/git" "$GATE_TMP/git/refs" "$GATE_TMP/work" || return 1
  printf 'ref: refs/heads/none\n' > "$GATE_TMP/git/HEAD"
  printf '[core]\n\trepositoryformatversion = 1\n[extensions]\n\tobjectformat = %s\n' "$fmt" > "$GATE_TMP/git/config"
  GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")
```

Executed (`fc-sub/p75.log` conflict run, `fc-sub/p75b.log` clean run). Planted `user.planted` values:

- repo `.git/config`
- `.git/config.worktree`, with `extensions.worktreeConfig=true`
- `~/.gitconfig` and `~/.config/git/config`
- a caller `GIT_CONFIG_SYSTEM` file
- `.git/modules/sm/config`

Planted `*.txt merge=union`:

- `~/.config/git/attributes`
- an untracked checkout `.gitattributes`
- `.git/info/attributes`, written by the shim at the first gate call, after the state gate passed

Controls: real-repo `merge-tree` exits 0 (union applied), and real-repo `config` shows the global, repo and worktree values.

Results:

- 13 gate calls logged across the two runs; together they cover all six sites (merge-base, three `cat-file -e`, merge-tree, diff-tree, `cat-file --batch-check`, hash-object).
- Every call shows `ls GIT_DIR: HEAD config refs`, an empty cwd, `GIT_COMMON_DIR=unset` and `GIT_WORK_TREE=unset`.
- Config origins seen: only `file:/tmp/tmp.*/git/config` and `command line:`. `grep 'planted\|union'` over the call log finds nothing, and `check-attr -a f.txt` is empty at every call.
- The conflict run ends `refuse ...: feat/x conflicts with the default branch` (exit 2). The clean run ends `ok`.

The A17, U2b1a i2 submodule, checkout-attributes and R9 bats tests pass (`fc-sub/bats.log`, ok 1-3, 7). Confidence is Medium because the evidence is git's view of its environment rather than an open() trace.

**Evidence:** `scripts/build-loop.sh:188-198`, `scripts/build-loop.sh:497-515`, `scripts/build-loop.sh:520-543`, `scripts/build-loop.sh:599`, `scripts/build-loop.sh:615`, fixtures `fc-sub/p75.sh`, `fc-sub/p75b.sh`, captured output `fc-sub/p75.log`, `fc-sub/p75b.log`, `fc-sub/bats.log` (bats run 2026-10-08T22:42:35Z, `TMPDIR=$(mktemp -d -p fc-sub) bats -f '...' test/scripts/build-loop-check.bats` from the worktree, exit 0)

---

## Claim 76: "`--check` exits 2 before reading any brief when both `main` and `master` exist or origin/HEAD names a branch other than the one resolve_main took."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:241-251`, `scripts/build-loop.sh:260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these cases, each exiting 2 with only `refuse state default-branch` lines and no git call naming `briefs`:
- main+master with no origin/HEAD, with origin/HEAD→master, and with origin/HEAD→main;
- main only with origin/HEAD→origin/master;
- master only with origin/HEAD→origin/main;
- main plus a `master` ref naming a tree.

Controls that pass: main or master alone, with an agreeing or absent origin/HEAD. It does not establish behaviour for a symbolic `refs/heads/main` (the reviewer's Q-103 residual). It does not cover packed refs or an origin/HEAD naming a third branch; that case is state_gate's, at `:230-233`, not this claim's.

The function and its call position, quoted:

```bash
# scripts/build-loop.sh:241-251
default_gate() {
  local p bad=0
  if git show-ref --verify --quiet refs/heads/main && git show-ref --verify --quiet refs/heads/master; then
    echo "refuse state default-branch: both main and master exist"; bad=1
  fi
  p="$(git symbolic-ref -q refs/remotes/origin/HEAD)" || true
  if [[ -n "$p" && "$p" != "refs/remotes/origin/$MAIN" ]]; then
    echo "refuse state default-branch: origin/HEAD names ${p#refs/remotes/}, but the default branch taken is $MAIN"; bad=1
  fi
  return "$bad"
}
# scripts/build-loop.sh:257-260
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }
if [[ "$MODE" == check ]]; then default_gate || exit 2; fi
```

The first brief read (`read_settings`, `open_shared`, then `check_line`) comes only at `:640-646`, after this exit. Executed with a PATH shim logging every git call (`fc-sub/p76.log`):

- 76a/76b/76b2/76g each print `refuse state default-branch: both main and master exist`, exit 2, 15 git calls, 0 naming briefs.
- 76c prints `refuse state default-branch: origin/HEAD names origin/master, but the default branch taken is main`, exit 2, 0 brief calls.
- 76d prints `... names origin/main, but the default branch taken is master`, exit 2, 0 brief calls.
- The controls 76e/76e2/76f print `ok`, exit 0, with 9 calls naming briefs (for example `cat-file blob <sha>:docs/working/briefs/2026-10-01-x.md`). This shows the shim does catch brief reads.

The R7 bats test passes (`fc-sub/bats.log`, ok 6).

**Evidence:** `scripts/build-loop.sh:241-260`, `scripts/build-loop.sh:639-649`, fixture `fc-sub/p76.sh`, captured output `fc-sub/p76.log`, `fc-sub/bats.log`

---

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- (none)

### Mostly Accurate
- **Claim 72a** (`scripts/build-loop.sh:520-530`): a missing main tree gives exit 2 and no ok line, but as `skip BRIEF: the tree of the default branch could not be read` from status_line, not a `refuse` from merge_result. merge_result's main-tree check is unreachable in that shape. The endorsement should say "skip or refuse (exit 2)".

### Unverifiable
- (none)

Notes for the orchestrator (no verdict change):
- Claim 74: the reviewer's Not-verified expectation for 100664 is wrong. Git reads it as 100644, so it passes rather than being denied, and the gate's TREE stores 100644.
- Claim 72b: two refusal messages name the wrong cause. Stderr from `--batch-check` is reported as "names a blob the object store lacks", and stderr from hash-object as an own-brief deny row. Both still refuse.
