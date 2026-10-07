Commit: 21b35ebf

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3c (branch `feat/build-loop-u2a3c`)
**Scope:** `git diff main...HEAD` (main e5d0f838, HEAD 21b35ebf) plus the commit messages of main..HEAD (3e58eb9c, cb9723c3, 27364085, 80cc6224, 61e2e734, 21b35ebf). The iteration-1 report files under `docs/reviews/` from cb9723c3 are excluded except the new rows in `docs/reviews/override-log.md`.
**Checked:** 2026-10-07
**Commit:** 21b35ebf
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 34
**Summary:** 25 verified, 2 mostly accurate, 5 stale, 0 incorrect, 2 unverifiable

Execution provenance: every executed command ran on 2026-10-07 between 19:19Z and 19:26Z under bash 5.2.15, mawk (`/usr/bin/mawk`) and git 2.39, uid 1000 (not root, so the `-r`/`-x` probes are meaningful). Raw output is in the scratch directory `/tmp/u2a3c-i2-fc-kkjF/logs/`, because this pass may write no file in the worktree other than this report. Mutants and old trees were built with `git archive <rev> | tar -x` into `/tmp/u2a3c-i2-fc-kkjF/{tree-<rev>,mut-<name>}`, never in the worktree. Bats ran as `TMPDIR=$(mktemp -d /tmp/u2a3c-i2-fc-XXXX) LC_ALL=C timeout 900 bats <suite>`.

Suites at HEAD (cwd `/workspace/.claude/wt-build-loop-u2a3c`, all exit 0): build-loop-check 57/57, build-loop-read 19/19, dev-cycle 78/78, fixture-hermeticity 2/2 (`logs/build-loop-check.txt`, `logs/build-loop-read.txt`, `logs/dev-cycle.txt`, `logs/fixture-hermeticity.txt`). Note: the shared review context says build-loop-check has 60 tests. It has 57 (`grep -c '^@test'` gives 57 at 61e2e734 and at 21b35ebf, and bats prints `1..57`). That brief is not under review here.

Hallucination-pattern log: read. No claim in scope matches a logged pattern. The closest are the logged test-count patterns ("All 85 tests…", "mode1-equiv 33"). This branch's commit-message test counts were re-run and match (Claim 27).

---

## Claim 1: "Comment, A5 and the U2b bullet now say the caller clears IMPORTED_MAIN_DONE after any checkout change."

**Location:** `docs/reviews/override-log.md:439`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether each of the three named documents currently states the cache-clear rule. It does not establish whether any caller actually clears the key: no caller exists until U2a4/U2b.
**Legibility-target:** docs

The lib comment holds the rule:

```
# scripts/lib/dev-cycle-read.sh:486-489
# the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, never the checkout,
# whose files it read, so a caller whose checkout may have changed (a file
# added or edited) sets IMPORTED_MAIN_DONE="" to walk again, and a cached
# error returns 1 again.
```

Known issue A5 and the U2b bullet no longer hold it. `grep -c 'FIFO\|snapshot\|IMPORTED_MAIN_DONE' docs/working/known-issues-dev-cycle.md` gives `0`, and `grep -n IMPORTED_MAIN_DONE docs/working/plan-build-loop-handoff.md` finds nothing. At the pre-rebase tip both had it. A5 at `backup/u2a3c-pre-rebase-2b1399ab` read: `The walk's cache ignores the checkout, so a caller clears \`IMPORTED_MAIN_DONE\` after any checkout change.` Its U2b bullet read: `owes the walk three things: that checkout final before the walk, or \`IMPORTED_MAIN_DONE\` cleared (the cache key ignores the checkout); a git that prints nothing on stderr for \`ls-files\` (any stderr fails the walk closed); and the git environment the override log hands the caller (\`GIT_INDEX_FILE\`, \`GIT_WORK_TREE\`, fsmonitor, sparse checkout, \`core.ignoreCase\`, replace refs)`. The rebase resolution in 3e58eb9c kept main's A5 and U2b text ("Docs: main's A5, F11 and U2b text kept"), and that dropped these clauses. The row's mitigation ("Comment, A5 and the U2b bullet now say…") is therefore two-thirds untrue at HEAD.

**Evidence:** `docs/reviews/override-log.md:439`, `scripts/lib/dev-cycle-read.sh:486-489`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:279`, `git show backup/u2a3c-pre-rebase-2b1399ab:docs/working/known-issues-dev-cycle.md` (row A5), `git show backup/u2a3c-pre-rebase-2b1399ab:docs/working/plan-build-loop-handoff.md` (U2b bullet)

---

## Claim 2: "Listed in A5 and the block comment's not-covered list." (FIFO start unlisted by git)

**Location:** `docs/reviews/override-log.md:440`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether A5 and the lib block comment list the FIFO case. It does not re-test the FIFO behaviour, which is a settled deferral.
**Legibility-target:** docs

The block comment lists it: `# F2; U2a4's shared start predicate), and a start that is not a regular file or` / `# symlink (git does not list a FIFO).` (`scripts/lib/dev-cycle-read.sh:480-481`). A5 does not: `grep -c FIFO docs/working/known-issues-dev-cycle.md` gives 0. Pre-rebase A5 had `a start file that is not a regular file or symlink (git does not list a FIFO)` in its not-covered list. The lib comment also says `Not covered (known issue` / `# A5)` (`scripts/lib/dev-cycle-read.sh:477-478`), and that pointer now names a row that lacks this item.

**Evidence:** `docs/reviews/override-log.md:440`, `scripts/lib/dev-cycle-read.sh:477-484`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 3: "the snapshot assumption is now written in the block comment and A5."

**Location:** `docs/reviews/override-log.md:441`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of the TOCTOU/snapshot text in the two named documents. It does not assess the Won't-Fix rationale.
**Legibility-target:** docs

The block comment has it: `# snapshot: a file swapped between its admission and its read is not seen.` (`scripts/lib/dev-cycle-read.sh:484`). A5 does not: `grep -c snapshot` gives 0. Pre-rebase A5 had `a checkout file swapped between its admission and its read` in its not-covered list. It was lost in the same 3e58eb9c resolution as Claims 1 and 2.

**Evidence:** `docs/reviews/override-log.md:441`, `scripts/lib/dev-cycle-read.sh:483-484`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 4: "The ordering is now commented at the record line."

**Location:** `docs/reviews/override-log.md:446`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether a record-before-seen ordering comment exists at the record line. It does not establish whether the ordering hazard the row describes still exists. It does not: see the text below.
**Legibility-target:** docs

At HEAD the record line is a whole-output record before the per-name loop, and its comment is about cost:

```
# scripts/lib/dev-cycle-read.sh:847-848
    # One lower per file, not per candidate, as in imported_names.
    i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }; IMPORTED_MAIN+="$i"$'\n'
```

Commit 3e58eb9c says U2a3c's per-candidate record and its ordering comment were dropped ("U2a3c's per-candidate record before the seen test is dropped: U2a3b already records the whole output before the loop"). The order the row worries about is now structural, because every name is recorded before any `seen` test. The row's statement about the comment and its revisit trigger ("any change to the drain loop's record/seen order") describe code that no longer exists.

**Evidence:** `docs/reviews/override-log.md:446`, `scripts/lib/dev-cycle-read.sh:845-856`, commit 3e58eb9c message

---

## Claim 5: Closing rows: "the test fails at 3e58eb9c"; "a no-drain mutant fails the test"; "18 realpath calls in the test's walk, against 102 unmemoized and 74 at 3e58eb9c"; "fixed a crash on an empty main tree"; "the put-join cost against its charge … is unchanged, so one bound still costs about 5 s"

**Location:** `docs/reviews/override-log.md:448-451`
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each number and test outcome the four rows cite, re-run against archived trees and mutants. It does not establish the 5 s figure on other hardware: here it measured about 4 s.
**Legibility-target:** docs

The batch-tr test and the 4 MiB test fail on 3e58eb9c's lib. The empty-tree test fails on 27364085's lib with `line 699: mc_e: unbound variable`, status 1. A no-drain mutant (`capped_read() { head -c 4194305; }`) fails the 4 MiB test with `want: walk: ok`. The realpath counts are 18 at HEAD, 102 for a no-memo mutant (`mc_m[$c]=1` replaced by `:`) and 74 at 3e58eb9c. A per-file work-bound mutant passes at 3w − 1 (Claim 33). A token of 3,450 `a/` components (work 47,823,900, just under the bound) took 3.73 s, and 3,600 components hit the bound after 4.04 s.

Commands (cwd `/tmp/u2a3c-i2-fc-kkjF/{tree-3e58eb9c,tree-27364085,mut-*}`): `bats -f '<names>' test/scripts/build-loop-check-head.bats` (HEAD's test file copied in) and `bats -f '4 MiB \+ 1|once per walk|IMPORT_WORK_MAX bounds' test/scripts/build-loop-check.bats`. Exit codes were 1 (old trees and mutants, as expected) and 0 (HEAD). Timestamps were 19:20:10Z to 19:23:28Z.

**Evidence:** `docs/reviews/override-log.md:448-451`; logs `/tmp/u2a3c-i2-fc-kkjF/logs/head-tests-on-3e58eb9c.txt`, `head-tests-on-27364085.txt`, `mut-nodrain.txt`, `mut-nomemo.txt`, `realpath-count-head.txt`, `perfile-bound2.txt`

---

## Claim 6: A5: "Its checkout phase (U2a3c) then walks, and only appends: the checkout's start files main lacks (untracked, ignored, or only in the index) and the imported files main lacks, when each is a plain file there; a checkout path it would walk that lies under a directory main stores as a link or gitlink or under an unsearchable directory, anything but a plain file or directory there (or nothing), an unreadable checkout file, a `..` after a checkout link in link text, and a checkout listing git warns about fail it."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed admission and refusal shape against `main_checkout`, `checkout_md` and the symlink arm, through the HEAD suites and a per-shape probe. It does not establish completeness of A5's not-covered list, which lost three items in the rebase (Claims 1-3).
**Legibility-target:** docs

Phase 2 seeding and admission:

```
# scripts/lib/dev-cycle-read.sh:806-808
      f="${cand[i]:2}"; c=0; [[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f" || c=$?
      [[ $c -ne 1 ]] || return 1; [[ $c -eq 0 ]] || continue
      seen[$f]=1; if [[ -n "${ent[$f]+set}" ]]; then queue+=("$f"); else tq+=("$f"); fi
```

A per-shape probe calls `main_checkout ent pok PATH` with `ent=([gl]=160000 [ml]=120000 [nd2/ml2]=120000 [mf]=100644)` under `set -euo pipefail`. It returns 0 for a plain file and for a file under a readable-or-not but searchable directory. It returns 2 for absent, under absent, under a plain file, a plain dir, and an unsearchable dir at PATH. It returns 1 for a link to a file, a link to a dir, a dangling link, a FIFO, a file under an unsearchable dir, an unreadable file, anything under a checkout dir link, and anything under main's gitlink or link (also below an absent ancestor). The `..`-after-checkout-link rule is the symlink arm's `[[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1` (`scripts/lib/dev-cycle-read.sh:837`). The stderr rule is `checkout_md` (Claim 18).

Command: `/tmp/u2a3c-i2-fc-kkjF/mc-probe.sh <lib> new|old /tmp/u2a3c-i2-fc-kkjF/mcrepo`, cwd the probe repo, exit 0, 19:24Z.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:705-742,806-808,826-840`; log `/tmp/u2a3c-i2-fc-kkjF/logs/main-checkout-shapes.txt`, `logs/build-loop-check.txt`

---

## Claim 7: F11: "U2a3c adds the checkout phase: … one admission check (`main_checkout`) refuses a path under a link or gitlink main stores, under an unsearchable directory, or anything but a plain file or directory, and a checkout listing git warns about fails the walk."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the F11 row's description of the checkout phase. It does not cover the row's gap list beyond what A5 holds.
**Legibility-target:** docs

This is the same mechanism as Claim 6. Both call sites of `main_checkout` are its only admission (`scripts/lib/dev-cycle-read.sh:806` for starts, `:852` for imports). Paraphrased, no quote available because the claim covers absence of code: `rg -n main_checkout` over scripts/skills/test finds no other caller outside the lib and its tests. F11 does not separately name "under a checkout directory link". That shape is refused both as an ancestor and as its own prefix candidate (Claim 32), so F11's "anything but a plain file or directory" covers it in practice.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:806,852`

---

## Claim 8: U2a3c bullet: "Built 2026-10-07 after the rebase onto U2a3b: the fail rules as stated (a plain file main lacks is walked, only a non-plain node fails), `capped_read`, the work bound `IMPORT_WORK_MAX` …, `main_checkout`'s ancestor memo, the `.git` rule, and N1 (`lower_all` under `nul_list`)."

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parenthetical fail rule and the list of items built. It does not establish the earlier, pre-existing parts of the bullet.
**Legibility-target:** docs

Each listed item exists, and its test passes at HEAD. "Only a non-plain node fails" is too narrow, though. Plain nodes also fail the walk in three cases:

- an unreadable plain file: `if rawfile "$c"; then [[ -r "$c" ]]; return; fi` (`scripts/lib/dev-cycle-read.sh:737`)
- a plain file or directory under a directory main stores as a link or gitlink: `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1` (`:729`)
- a plain but unsearchable ancestor directory: `elif plaindir "$c" && [[ -x "$c" ]]; then mc_m[$c]=1` / `else return 1; fi` (`:732-733`)

The probe returned 1 for `ur.md` (mode 000), `ml/x.md` (main 120000, checkout plain) and `us/x.md` (dir mode 644). A precise version: "a plain, readable file main lacks is walked; a non-plain node, an unreadable file, or a path under main's link/gitlink or an unsearchable directory fails". The bullet's earlier phrase "an unsearchable checkout directory fails the walk" holds only when a walked path lies below it. `us` named alone returns 2, and an unsearchable directory holding no `.md` draws no git warning (`logs/unsearchable-listing.txt`: only the mode-000 `u0/` warned).

**Evidence:** `docs/working/plan-build-loop-handoff.md:277`, `scripts/lib/dev-cycle-read.sh:721-742`; logs `/tmp/u2a3c-i2-fc-kkjF/logs/main-checkout-shapes.txt`, `logs/unsearchable-listing.txt`

---

## Claim 9: U2b bullet: "It names the checkout `--check` runs from (the walk reads its untracked, ignored and index-only start files and the imported files main lacks there)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parenthetical, which no longer says "fresh worktree". It does not establish that the bullet still records what the walk owes its caller: that text was dropped (Claim 1).
**Legibility-target:** docs

`checkout_md` lists `--cached --others` (`scripts/lib/dev-cycle-read.sh:710`), and candidates main lacks are tagged `t:` (`:796`). No "until U2a3c" or "fresh worktree" phrasing remains in the U2b bullet, A5 or F11. Paraphrased, no quote available because this is a grep result: `grep -n 'until U2a3c\|fresh worktree'` over these docs hits only historical U2a3 text at `plan…:276`, which describes U2a3 as built, and line 99, which is unrelated.

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `scripts/lib/dev-cycle-read.sh:706-710,796`

---

## Claim 10: Lib header: "main_imports reads main's commit first and then the working tree (the checkout's start files and imported files main lacks, which can only add imports or fail it; it needs resolve_main to have found main by name); imported_names, checkout_md and main_checkout read the working tree at ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:36-39`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers read order, append-only behaviour, and the main_by_name dependency. It does not establish that `main_checkout` alone guards every checkout read: the symlink arm's `-L "$p"` probes read the checkout too.
**Legibility-target:** code comment

`main_by_name || return 1` (`:791`). Phase 2 starts only when `queue` is empty: `[[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }` (`:815`). Paraphrased, no quote available because this is an invariant inferred from the loop body: phase-2 output only appends to `IMPORTED_MAIN` (`:848`), and its only other effect is a failure return.

**Evidence:** `scripts/lib/dev-cycle-read.sh:33-39,786-858`

---

## Claim 11: IMPORTED block comment: the checkout phase, its refusals ("a checkout listing git prints any stderr for"), the not-covered list ("a start that is not a regular file or symlink (git does not list a FIFO)"), "The walk reads the checkout as one snapshot", and the cache text ("never the checkout … sets IMPORTED_MAIN_DONE="" to walk again")

**Location:** `scripts/lib/dev-cycle-read.sh:461-492`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the phase-2 rules, the cache key's exclusion of the checkout, and the stderr refusal. It does not verify that a FIFO is unlisted by git: that is a settled row, and only the comment's presence was checked.
**Legibility-target:** code comment

The cache key is `[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]]` (`:789`), which holds no checkout state. The HEAD cache test shows a checkout edit unseen until the key is cleared: expected output `- - z.sh` (`test/scripts/build-loop-check.bats:338`, passing). The refusal shapes are Claim 6.

**Evidence:** `scripts/lib/dev-cycle-read.sh:461-492,789`, `test/scripts/build-loop-check.bats:330-339`; log `/tmp/u2a3c-i2-fc-kkjF/logs/build-loop-check.txt`

---

## Claim 12: "Each walk also fails once the parser's work (the candidate and comment-splice characters it scans, the unit of its per-file bound of 50,000,000, about 5 s) passes this in all, so N adversarial files cost one bound, not N … /workspace's walks spend about 8,100 each (2026-10-07)."

**Location:** `scripts/lib/dev-cycle-read.sh:503-508`
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the constant, its walk-wide effect, the /workspace work figure and the order of magnitude of the per-bound time. It does not establish the "5 s" exactly (about 4 s measured here), or a bound over the two walks together: each walk has its own bound.
**Legibility-target:** code comment

`IMPORT_WORK_MAX=50000000` (`:508`). Both walks pass `IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - work))` and charge through `import_work out work` (`:760-761,821-824`).

Measured on /workspace with the HEAD lib (`ws-measure.sh`, cwd `/workspace`, main e5d0f838, exit 0, 19:23:03Z): `tree walk: ok work=8110 secs=1.08` and `main walk: ok work=8110 secs=1.31`. The per-file bound took 3.73-4.04 s on an adversarial `a/`-chain token (Claim 5). The "candidate and comment-splice characters" wording leaves out the resolved spellings `put` charges. The comment at `:578-579` states that charge, so this is not a mismatch.

**Evidence:** `scripts/lib/dev-cycle-read.sh:503-508,575-580,760-761,821-824`; logs `/tmp/u2a3c-i2-fc-kkjF/logs/ws-measure-head.txt`, `logs/perfile-bound2.txt`

---

## Claim 13: import_targets reads "IMPORT_WORK_LEFT (set by a walk: what its IMPORT_WORK_MAX has left, which then also caps the per-file work bound, and a last line "/N" reports the work spent; import_work reads it)"; and the parser's output is unchanged when IMPORT_WORK_LEFT is unset

**Location:** `scripts/lib/dev-cycle-read.sh:521-524`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the trailer, the cap and output equality with main's parser on four real files. It does not prove equality for all inputs; the static read of `trail` covers that.
**Legibility-target:** code comment

```
# scripts/lib/dev-cycle-read.sh:622,625
  wmax = 50000000; trail = (ENVIRON["IT_WORK"] != ""); if (trail && ENVIRON["IT_WORK"] + 0 < wmax) wmax = ENVIRON["IT_WORK"] + 0
END { if (trail) print "/" (work + 0) }'
```

`IT_WORK="${IMPORT_WORK_LEFT:-}"` (`:666`), so unset or empty means no trailer and wmax stays 50,000,000. main's lib and HEAD's lib gave identical output md5 (`d04d98ae…`) on AGENTS.md, README.md and two docs/working files. With `IMPORT_WORK_LEFT=5` the parser printed `/42` and returned 1.

Command: `bash /tmp/u2a3c-i2-fc-kkjF/parser-unchanged.sh`, cwd the worktree, exit 0, 19:22:44Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:517-524,618-626,664-667`; log `/tmp/u2a3c-i2-fc-kkjF/logs/parser-unchanged.txt`

---

## Claim 14: awk runs END after `exit 3`, keeping the status (the trailer is printed and the failure still reported)

**Location:** `scripts/lib/dev-cycle-read.sh:625`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk 1.3 (the sandbox's awk). It does not cover gawk or busybox awk. POSIX specifies the same behaviour, but that was not run.
**Legibility-target:** code comment

`echo x | awk '{ work=7; exit 3 } END { print "/" (work+0) }'` printed `/7` with rc=3. `awk 'BEGIN { exit 2 } END { print "/end" }'` printed `/end` with rc=2. A trailer after a failure cannot pass, because `import_targets` returns 1 (`|| return 1`, `:667`) and `&& import_work` is skipped (`:761`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:625,666-667,760-761`; log `/tmp/u2a3c-i2-fc-kkjF/logs/awk-exit-end.txt` (19:22:24Z, cwd scratch)

---

## Claim 15: "import_work OUT TOTAL: strips the parser's work trailer (its last line, "/N", printed when IMPORT_WORK_LEFT is set; a repo-relative name never starts with /) … returns 1 when the trailer is missing or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:669-678`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-leading-slash invariant of the parser's output and import_work's accept and reject rules. It does not cover callers other than the two walks; there are none.
**Legibility-target:** code comment

`put` builds `out` from non-empty components joined by "/", then strips `pre` (root plus "/"): `out = substr(out, length(pre) + 1)` (`:593`). It returns before printing when `length(out) <= length(pre)` (`:592`), so each printed name starts with a non-slash character. The check `[[ "$iw_w" =~ ^[0123456789]+$ && ( "$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w" ) ]] || return 1` (`:675`) then accepts only a whole last line `/N`. The HEAD test "import_work strips…" passes with cases `docs/12` → failed, `a.md\nb/12x` → failed, and budget 30 → failed at 31.

**Evidence:** `scripts/lib/dev-cycle-read.sh:575-596,669-678`, `test/scripts/build-loop-check.bats:855-864`; log `/tmp/u2a3c-i2-fc-kkjF/logs/build-loop-check.txt`

---

## Claim 16: "lower_all … Read it through nul_list: a tr that dies after a partial flush then fails the list rather than truncating its last name and dropping a start (U2a3b final N1)."

**Location:** `scripts/lib/dev-cycle-read.sh:692-696`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main walk's candidate batch (`:797`). It does not cover the per-file `lower` calls, which are not batched.
**Legibility-target:** code comment

`[[ ${#cand[@]} -eq 0 ]] || nul_list low lower_all "${cand[@]}" || return 1` (`:797`). `nul_list` appends `rc=1` when the command fails (`:690`). The test "batch tr dies after a partial flush" passes at HEAD and fails on 3e58eb9c's lib (`want: walk: failed`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:690,692-696,797-798`; logs `/tmp/u2a3c-i2-fc-kkjF/logs/head-tests-on-3e58eb9c.txt` (19:20:10Z, exit 1), `logs/build-loop-check.txt`

---

## Claim 17: "capped_read: the first 4 MiB + 1 bytes of stdin, the one reader both walks parse, for checkout files and main's blobs alike. … From a pipe (git cat-file) it drains the rest, so the writer never dies of SIGPIPE, which pipefail would report as a failed read (U2a3b L2-C5)."

**Location:** `scripts/lib/dev-cycle-read.sh:697-703`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every input the parser reads (`imported_names:760`, `main_imports:821` checkout arm and `:823` blob arm), pipe detection and drain, and head's exact read. It does not cover the symlink arm (`:828-829`), which reads 120000 blobs whole (twice) without a cap. That text is not parsed, so the "parse" wording holds, but the override row closing L2-C5 ("capped_read is the one reader for … main's blobs") is broader than the code.
**Legibility-target:** code comment

```
# scripts/lib/dev-cycle-read.sh:703
capped_read() { head -c 4194305 || return 1; [[ ! -p /dev/stdin ]] || cat > /dev/null; }
```

Probe results (cwd the worktree, 19:21:02Z, exit 0):

- `[[ -p /dev/stdin ]]` is `pipe` inside `$(printf x | f | cat)` and `notpipe` for `f < file`.
- GNU head does not over-read a pipe: `head -c 10000000 /dev/zero | { head -c 5; wc -c; }` gives 9999995.
- capped_read returns 4194305 bytes from both a 6,000,000-byte pipe and a 6,000,000-byte file.
- Under pipefail, a bare `head -c 4194305` after a 6 MB writer exits 141, and `capped_read` exits 0.
- An empty pipe and `/dev/null` both give rc 0.

The no-drain mutant fails the 4 MiB test (Claim 5). Paraphrased, no quote available because this is the symlink-arm residue: `i="$(git cat-file blob "$MAIN_SHA:$f" | tr -cd '\0' | wc -c)"` and `out="$(git cat-file blob "$MAIN_SHA:$f" && printf x)"` (`:828-829`) read the link blob in full.

**Evidence:** `scripts/lib/dev-cycle-read.sh:697-703,760,821-829`; logs `/tmp/u2a3c-i2-fc-kkjF/logs/capped-read-probe.txt`, `logs/mut-nodrain.txt`

---

## Claim 18: "checkout_md: … fails when git exits nonzero or prints anything on stderr, since an unreadable directory goes unlisted with only a warning."

**Location:** `scripts/lib/dev-cycle-read.sh:706-710`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39's warning for a mode-000 directory and the function's status logic. It does not cover a readable but unsearchable (644) directory, which git lists without warning when it holds no `.md`, so checkout_md does not fail on it. main_checkout refuses a walked path below it.
**Legibility-target:** code comment

`checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }`. git printed `warning: could not open directory 'u0/': Permission denied` for the 000 directory and nothing for the 644 directories (`us` empty, `us2` holding a `.txt`). The HEAD test case `hid` (mode 000 holding CLAUDE.md) expects and gets `walk failed`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:706-710`, `test/scripts/build-loop-check.bats:795`; log `/tmp/u2a3c-i2-fc-kkjF/logs/unsearchable-listing.txt` (19:24:14Z, cwd `/tmp/u2a3c-i2-fc-kkjF/usrepo`)

---

## Claim 19: main_checkout return codes: "0 for a plain checkout file to walk, 2 when nothing there loads (absent, below an absent ancestor or a plain file, or a plain directory), 1 to fail the walk: an ancestor main stores as a link or gitlink, an ancestor that is anything else but a plain searchable directory, ENT or MEMO not an associative array, or anything else at PATH."

**Location:** `scripts/lib/dev-cycle-read.sh:711-720`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 25 probed shapes plus the non-associative ENT and MEMO cases. It does not cover concurrency (settled TOCTOU row).
**Legibility-target:** code comment

Every probed shape matches the comment except the unreadable plain file. "0 for a plain checkout file" needs "readable": `if rawfile "$c"; then [[ -r "$c" ]]; return; fi` (`:737`) returns 1 for `ur.md` (mode 000), and a plain file is not naturally "anything else at PATH". The block comment above IMPORTED= says it correctly ("anything but a readable plain file", `:474`). Other results:

- non-associative ENT (`declare -a`) → 1, and non-associative MEMO → 1
- `f.md/x` (under a plain file) → 2, and `nd/x.md` → 2
- `nd2/ml2/x.md` (main link below an absent checkout ancestor) → 1, which confirms main's modes are checked even below an absent ancestor (`:729` precedes `:730`)
- memo keys after the run: `d urd mf .git d/sub`, all plain searchable directories that passed the mode check

**Evidence:** `scripts/lib/dev-cycle-read.sh:711-742`; log `/tmp/u2a3c-i2-fc-kkjF/logs/main-checkout-shapes.txt` (cwd `/tmp/u2a3c-i2-fc-kkjF/mcrepo`, exit 0, 19:24Z)

---

## Claim 20: "${x@a} on an empty array is an unbound-variable error under set -u (an empty main tree, the first call's MEMO); the body reads both through :- and +set." (with `local -; set +u`)

**Location:** `scripts/lib/dev-cycle-read.sh:723-725`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15, through a nameref as used here, and the restoration of `-u` on return. It does not cover bash < 5.0.
**Legibility-target:** code comment

Under `set -u`:

- `declare -A e=(); echo "${e@a}"` → `e: unbound variable`, rc 127
- through a nameref → `r: unbound variable`
- a non-empty array → `[A]`
- with `set +u`, an empty associative array → `[A]`, so the type check works
- `f(){ local -; set +u; }; f` leaves `-u` set in the caller

The body reads `${mc_m[$c]+set}` (`:728`) and `${mc_e[$c]:-}` (`:729`). The probe's call `main_checkout empty empty f.md` under `set -euo pipefail` returned 0. 27364085's version died there (`line 699: mc_e: unbound variable`, Claim 5). The `set +u` is scoped to main_checkout and to `rawfile`/`plaindir`, which it calls and which read `${ROOT_REAL:-}`. Paraphrased, no quote available because this is a scope argument over three functions: nothing else runs under it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:103,106,721-742`; logs `/tmp/u2a3c-i2-fc-kkjF/logs/at-a-probe.txt` (19:21:07Z), `logs/main-checkout-shapes.txt`

---

## Claim 21: main_imports block comment: returns 1 when "the commit's tree or the checkout's .md list (tracked and untracked) cannot be listed whole (nul_list, checkout_md) … the start list's lower_all fails or comes back short, main_checkout refuses a start or an import main lacks, a blob or checkout file cannot be read … or the IMPORT_OUT_MAX or IMPORT_WORK_MAX budget is spent; need_root exits instead."

**Location:** `scripts/lib/dev-cycle-read.sh:772-783`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed failure's return path in `main_imports` (`:786-858`). "untracked" includes ignored files (git's `--others`). It does not cover need_root's exit.
**Legibility-target:** code comment

The paths are `nul_list recs checkout_md || return 1` (`:795`), `nul_list low lower_all … || return 1` and `[[ ${#low[@]} -eq ${#cand[@]} ]] || return 1` (`:797-798`), `[[ $c -ne 1 ]] || return 1` (`:807`, `:853`), the capped reads' `|| { IMPORTED_MAIN=error; return 1; }` (`:821-824`), and `(( (used += ${#out}) <= IMPORT_OUT_MAX ))` with `import_work` (`:845`, `:822`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:772-858`

---

## Claim 22: "Phase 2 begins when queue empties: tq's checkout files then join it, and a path main lacks reads the checkout."

**Location:** `scripts/lib/dev-cycle-read.sh:784-785`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the queue hand-off and arm selection. It does not claim the two phases stay strictly separate: a phase-2 file's import that main stores re-enters `queue` and is read from main before `tq` rejoins. This matches the plan's "reads a path main stores through main's arms".
**Legibility-target:** code comment

`[[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }` (`:815`), with `case "${ent[$f]-checkout}" in` / `checkout) out="$(capped_read < "$f" | …` (`:820-821`), and `if [[ -n "${ent[$p]+set}" ]]; then queue+=("$p"); elif [[ $c -eq 0 ]]; then tq+=("$p"); fi` (`:855`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:813-857`

---

## Claim 23: "main lacks p: admitted before it is marked seen" (and iteration 1's A1-A3 and the C1 fast return still in place after the rebase)

**Location:** `scripts/lib/dev-cycle-read.sh:852`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering at both call sites, A1 (non-associative ENT/MEMO → 1), A2 (start-path check, pinned by the `.claude/rules` link case), A3, and C1 (`[[ -e || -L ]] || return 2` before any fork). It does not establish that C1 holds for ancestors that exist: those fork `plaindir` once each, then hit the memo.
**Legibility-target:** code comment

The imports site is `main_checkout … || c=$?` then `[[ $c -ne 1 ]] || …` then `seen[$p]=1` (`:852-854`). The starts site has the same order (`:806-808`). C1 is `c="$3"; [[ -e "$c" || -L "$c" ]] || return 2` (`:735`), and for ancestors `if [[ ! -e "$c" && ! -L "$c" ]] || rawfile "$c"; then st=2` (`:731`), which tests before forking. A1 was probed (Claim 19). The A2 test ("main stores .claude/rules as a link…", `test/scripts/build-loop-check.bats:788-789`) passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:731,735,806-808,852-855`, `test/scripts/build-loop-check.bats:782-799`; logs `/tmp/u2a3c-i2-fc-kkjF/logs/build-loop-check.txt`, `logs/main-checkout-shapes.txt`

---

## Claim 24: "An untracked start: the tree walk reads it (the main walk fails closed on it until U2a3c)."

**Location:** `test/scripts/build-loop-check.bats:69`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test comment's parenthetical. It does not mean the test is wrong: it does not exercise the main walk on that start.
**Legibility-target:** test comment

U2a3c is this branch, and the main walk now reads untracked starts. The test "upper-case .MD … tracked or untracked" expects `want walk ok; want docs/mine.md imported` for an untracked `docs/AGENTS.MD` (`test/scripts/build-loop-check.bats:259-260`). This is the only remaining "until U2a3c" in the scoped code and docs: `grep -n 'until U2a3c'` over the lib, the bats files, A5 and the plan gives only this line.

**Evidence:** `test/scripts/build-loop-check.bats:69,253-261`

---

## Claim 25: "@a/b/c/d/e/f/g/h/x.md yields about 20 prefix candidates through eight plain directories main lacks … Unmemoized, each candidate re-checks every ancestor (102 calls; 74 at 3e58eb9c); memoized, each directory once, plus each candidate's own check (18)."

**Location:** `test/scripts/build-loop-check.bats:821-825`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three call counts. It does not establish the "about 20 candidates" count separately.
**Legibility-target:** test comment

The realpath shim counted 18 at HEAD (assertion changed to print), 102 with the no-memo mutant, and 74 with 3e58eb9c's lib.

**Evidence:** `test/scripts/build-loop-check.bats:820-833`; logs `/tmp/u2a3c-i2-fc-kkjF/logs/realpath-count-head.txt` (19:20:43Z, exit 0), `logs/mut-nomemo.txt`, `logs/head-tests-on-3e58eb9c.txt`

---

## Claim 26: The .git tests' titles: the walk reads a linked worktree's gitfile and a nested `.git` file "as Claude Code does"

**Location:** `test/scripts/build-loop-check.bats:411,700`
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the Claude Code half only. The walk half is Verified: both tests pass at HEAD, and the probe shows `.git` (dir) → 2 and `.git/config` → 0. This does not establish Claude Code 2.1.293's (installed) or 2.1.292's handling of a gitfile.
**Legibility-target:** test comment

The walk half: `main_checkout` has no `.git` special case. Paraphrased, no quote available because this is an absence result: the removed lines 376-382 of the merge-base version are gone, and `grep -n '"\.git"\|== \.git' scripts/lib/dev-cycle-read.sh` finds none in main_imports. Re-tracing Claude Code's import reader requires extracting the bundled JS from the native binary. That extraction was blocked by this session's permission classifier. The claim rests on U2a3b's L2-confirm security F1 trace.

**Evidence:** `test/scripts/build-loop-check.bats:411-424,700-714`, `scripts/lib/dev-cycle-read.sh:721-742`; log `/tmp/u2a3c-i2-fc-kkjF/logs/main-checkout-shapes.txt`

---

## Claim 27: Commit 3e58eb9c: "Tests: build-loop-check 51/51, build-loop-read 19/19, dev-cycle 78/78, fixture-git-env 2/2."

**Location:** commit 3e58eb9c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four suites at 3e58eb9c's tree. It does not cover other suites.
**Legibility-target:** commit message

The four suites ran in `/tmp/u2a3c-i2-fc-kkjF/tree-3e58eb9c` (git archive), all exit 0, 19:25:23Z to 19:25:49Z: 51 ok, 19 ok, 78 ok and 2 ok, with 0 not ok.

**Evidence:** logs `/tmp/u2a3c-i2-fc-kkjF/logs/at-3e58eb9c-build-loop-check.txt`, `at-3e58eb9c-build-loop-read.txt`, `at-3e58eb9c-dev-cycle.txt`, `at-3e58eb9c-fixture-git-env.txt`

---

## Claim 28: Commit 3e58eb9c resolution bullets: the per-candidate record dropped because U2a3b records the whole output first; main_checkout replaces the inline parent-link loop and plain-directory test; the top-level `.git` special case is gone; "Three U2a3b tests that pinned the interim fail-closed rule for .git paths now expect the walk to read them"; "Docs: main's A5, F11 and U2b text kept …, with the 'until U2a3c … fails closed' sentences replaced by U2a3c's description."

**Location:** commit 3e58eb9c message
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet literally against the diff. It does not establish that keeping main's doc text lost nothing: it dropped U2a3c's cache-clear, FIFO, TOCTOU and "owes the walk" text, which the override rows still cite (Claims 1-3).
**Legibility-target:** commit message

The three inverted tests are at `test/scripts/build-loop-check.bats:411`, `:657` and `:700` (diff hunks `want walk failed` → `want walk ok`). The removed `.git` block is in `git diff main...HEAD` (the lines starting `-      if [[ "$p" == .git ]]; then`). The whole-output record is at `:848`.

**Evidence:** `git diff main...HEAD -- scripts/lib/dev-cycle-read.sh test/scripts/build-loop-check.bats`, `scripts/lib/dev-cycle-read.sh:848`

---

## Claim 29: Commit 3e58eb9c: "a commit-by-commit rebase conflicted twice in the same hunks"; "squash-rebase chosen over a per-commit rebase (same final tree …)"

**Location:** commit 3e58eb9c message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond noting the claim is counterfactual. It does not establish what a per-commit rebase would have produced.
**Legibility-target:** commit message

Paraphrased, no quote available because the claim concerns a rebase run that left no artifact. Checking it would need replaying `cebfed35..2b1399ab` onto 581d41d8 with the same conflict resolutions, which this pass did not do, since it may not write to the shared repository.

**Evidence:** commit 3e58eb9c message; `backup/u2a3c-pre-rebase-2b1399ab`

---

## Claim 30: Commit cb9723c3: reports "From 1fb62779 and 2b1399ab …, unchanged"; "override-log.md: U2a3b's rows and U2a3c's 9 rows both kept (append-only)."

**Location:** commit cb9723c3 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte equality of the eight report files with the backup tip and the count of U2a3c rows. It does not cover whether those rows are still accurate (Claims 1-4).
**Legibility-target:** commit message

`git diff --quiet backup/u2a3c-pre-rebase-2b1399ab cb9723c3 -- <file>` reported `same` for all eight `*u2a3c*` files under docs/reviews. `git diff main cb9723c3 -- docs/reviews/override-log.md | grep '^+|' | wc -l` gives 9. There are 0 U2a3c row differences against the backup tip. Run in the worktree at 19:25Z, exit 0. The output was inline only; the commands are deterministic over fixed commits.

**Evidence:** `docs/reviews/override-log.md:439-447`

---

## Claim 31: Commit 27364085: capped_read for checkout files and main's blobs ("main's blobs were read whole: U2a3b L2-C5"); "a bare head after git cat-file exits 141 under pipefail"; "imported_names reads through it too"; lower_all under nul_list; "both new tests fail on 3e58eb9c's lib; a mutant without the drain fails the 4 MiB test (walk failed)."

**Location:** commit 27364085 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each sentence. "main's blobs" means the blobs parsed (100644/100755); 120000 link blobs are still read whole (Claim 17 residue).
**Legibility-target:** commit message

On main the blob arm was `git cat-file blob "$MAIN_SHA:$f" | IMPORT_LEFT=… import_targets` with no cap (diff `-` line at the old `:751`). The probe got 141 from a bare head. Both new tests fail at 3e58eb9c. The no-drain mutant fails with `want: walk: ok`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:703,760,823`; logs `/tmp/u2a3c-i2-fc-kkjF/logs/capped-read-probe.txt`, `logs/head-tests-on-3e58eb9c.txt`, `logs/mut-nodrain.txt`

---

## Claim 32: Commit 80cc6224: "main_checkout ENT MEMO PATH walks PATH's ancestors top down once …; a plain searchable directory goes into MEMO …, so each costs one realpath per walk. A test's realpath count: 18, against 102 unmemoized and 74 at 3e58eb9c." "${x@a} on an empty associative array is an unbound-variable error under set -u: an empty main tree with an untracked start killed the caller's shell (test added; it fails at 27364085)." Notes: "an ancestor that is a plain file now returns 2 explicitly … same answer."

**Location:** commit 80cc6224 message
**Type:** Reference / Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every sentence, including the plain-file-ancestor equivalence. It does not establish full equivalence with 27364085 for every shape, and the commit does not claim it. One other shape changed: an absent path under a checkout directory symlink (`ldir/nx.md`) returns 1 at HEAD and 2 at 27364085. That change is not observable through the walk, because the link itself (`ldir`) is always a prefix candidate and returns 1 in both versions.
**Legibility-target:** commit message

Shape table, HEAD vs 27364085: 24 of 25 shapes agree, and `ldir/nx.md` gives 1 vs 2. `f.md/x` gives 2 in both. The realpath counts and the empty-tree failure (`mc_e: unbound variable`, status 1, no output: the shell died) are as claimed. A "one realpath" per memoized directory holds because `rawfile` short-circuits on `-f` for a directory before forking (`scripts/lib/dev-cycle-read.sh:103`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:103,106,721-742`; logs `/tmp/u2a3c-i2-fc-kkjF/logs/main-checkout-shapes.txt`, `logs/realpath-count-head.txt`, `logs/mut-nomemo.txt`, `logs/head-tests-on-27364085.txt`

---

## Claim 33: Commit 61e2e734: the walk-wide bound, trailer and import_work; "Without IMPORT_WORK_LEFT the parser's output is unchanged"; "Measured 2026-10-07: /workspace's walks spend about 8,100 each (1.1 s tree, 1.4 s main; the main walk now passes on this developer checkout, which failed closed before U2a3c)"; "a per-file mutant passes at 3w - 1 and fails the test"; "about 6,000x this repo's real work."

**Location:** commit 61e2e734 message
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each figure, re-measured on /workspace at main e5d0f838 (time-varying: true as of 19:23Z). It does not cover other checkouts.
**Legibility-target:** commit message

Results:

- HEAD lib: `tree walk: ok work=8110 secs=1.08` and `main walk: ok work=8110 secs=1.31`.
- main's lib: `main walk: failed`.
- 50,000,000 / 8,110 = 6,165.
- Per-file mutant (each file bounded by IMPORT_WORK_MAX, total still summed so `w` is measured): output `-1 tree ok / -1 main ok / 0 tree ok / 0 main ok`, so the test fails (exit 1, 19:20:37Z).
- Output equality: Claim 13.

**Evidence:** `scripts/lib/dev-cycle-read.sh:503-508,669-678`; logs `/tmp/u2a3c-i2-fc-kkjF/logs/ws-measure-head.txt`, `logs/ws-measure-main.txt`, `logs/mut-perfile.txt`, `logs/parser-unchanged.txt`

---

## Claim 34: Commit 21b35ebf: "close U2a3b's four rows routed to U2a3c (N1, L2-C5, L2-C6, P2); the plan's U2a3c bullet records them built"; "L2-C7 … and P2's put-join cost stay deferred on their rows."

**Location:** commit 21b35ebf message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four closing rows and the plan sentence. It does not cover those rows' own figures (Claim 5).
**Legibility-target:** commit message

The rows are at `docs/reviews/override-log.md:448-451` (`Closes U2a3b's routed N1 row`, `… L2-C5 row`, `Closes the L2-C6 half … (L2-C7 … stays deferred there)`, `Closes U2a3b's routed P2 row … the put-join cost … is unchanged`). The plan sentence `Built 2026-10-07 after the rebase onto U2a3b: …` is at `docs/working/plan-build-loop-handoff.md:277`.

**Evidence:** `docs/reviews/override-log.md:448-451`, `docs/working/plan-build-loop-handoff.md:277`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 1** (`docs/reviews/override-log.md:439`): says A5 and the U2b bullet tell the caller to clear IMPORTED_MAIN_DONE. Since the 3e58eb9c rebase resolution, only the lib comment does. The U2b bullet's "owes the walk three things" (checkout final or key cleared, empty ls-files stderr, the git environment handoff) is gone too.
- **Claim 2** (`docs/reviews/override-log.md:440`): the FIFO start is no longer listed in A5, though the lib's "Not covered (known issue A5)" points there.
- **Claim 3** (`docs/reviews/override-log.md:441`): the snapshot/TOCTOU assumption is no longer in A5.
- **Claim 4** (`docs/reviews/override-log.md:446`): "The ordering is now commented at the record line": the per-candidate record and its comment were dropped in 3e58eb9c, and the record is now whole-output before the loop.
- **Claim 24** (`test/scripts/build-loop-check.bats:69`): "(the main walk fails closed on it until U2a3c)" no longer holds; the main walk reads untracked starts.

### Mostly Accurate
- **Claim 8** (`docs/working/plan-build-loop-handoff.md:277`): "only a non-plain node fails" leaves out the unreadable plain file, plain paths under main's link or gitlink, and plain unsearchable ancestors.
- **Claim 19** (`scripts/lib/dev-cycle-read.sh:711-720`): "0 for a plain checkout file" should say readable; an unreadable plain file returns 1, a case the comment's list does not name.

### Unverifiable
- **Claim 26** (`test/scripts/build-loop-check.bats:411,700`): "as Claude Code does" for gitfiles needs a re-trace of the installed Claude Code (2.1.293) import reader. Binary extraction was blocked in this session.
- **Claim 29** (commit 3e58eb9c): "same final tree" / "conflicted twice" needs a replay of the per-commit rebase.

## Escalations

- **architecture / api-consistency:** The rebase resolution (3e58eb9c) kept main's A5 and U2b text and dropped U2a3c's caller contract. Gone are the cache-clear rule, "a git that prints nothing on stderr for ls-files", the git-environment handoff (`GIT_INDEX_FILE`, `GIT_WORK_TREE`, fsmonitor, sparse checkout, `core.ignoreCase`, replace refs), and the FIFO and TOCTOU not-covered items. Override rows 439-441 still cite those docs as their mitigation. U2a4 and U2b, the first callers, will read A5 and the U2b bullet, not the override log. Compare `git show backup/u2a3c-pre-rebase-2b1399ab:docs/working/plan-build-loop-handoff.md` (U2b bullet) and the same commit's A5 row.
- **performance:** The symlink arm (`scripts/lib/dev-cycle-read.sh:828-829`) still reads a 120000 blob whole, twice, into a bash variable, with no cap. A crafted link blob of many MB costs memory and time before it fails on newline, absolute path or E2BIG. The L2-C5 closing row (override-log:449) says capped_read is the one reader for "main's blobs", which is broader than the code. Separately, IMPORT_WORK_MAX is per walk: a gate that runs both walks spends up to two bounds (about 8 s measured here).
- **security:** Phase 2 now reads any checkout file under `.git/` that an import names (for example `.git/config`, packs, the index; capped at 4 MiB + 1 and work-bounded). Only parsed names leave the walk, so I found no disclosure path, but the gate's answer now depends on `.git/` internals a writer can influence (`.git/info/*.md` and similar). The `ldir/nx.md` shape changed from 2 to 1 (Claim 32): stricter, and masked by the prefix candidate, but untested directly.
- **test-strategy:** `test/scripts/dev-cycle.bats:1110`'s function inventory adds `md_ls checkout_md main_checkout lower_all capped_read` but not `import_work`. The stale comment at `build-loop-check.bats:69` should be fixed. Override row 446's revisit trigger names an order that is now structural; no test covers a main import of a path that is also an untracked start. Optionally, pin the plan's "unsearchable directory named alone answers 2" and the 644-directory no-warning case (Claim 18 scope). Finally, the shared review context's "60 tests" for build-loop-check is wrong: there are 57.
