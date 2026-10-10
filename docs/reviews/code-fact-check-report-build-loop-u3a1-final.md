# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u3a1`, branch `feat/build-loop-u3a1`)
**Scope:** full branch `main...HEAD` (base d5736445 .. d10cfba8), docs/reviews excluded: `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, `docs/working/plan-build-loop-handoff.md` step 7 (U3a1 as-built note, U3a2 bullet), and the messages of commits 65007bf8, 83f75281 and d10cfba8. `scripts/lib/dev-cycle-read.sh` was read as context only. Merged from `code-fact-check-report-build-loop-u3a1-final-r1.md` (26 claims), `-r2.md` (38) and `-r3.md` (38), all at d10cfba8 (final confirming pass).
**Commit:** d10cfba8
**Replication:** k=3
**Checked:** 2026-10-10
**Total claims checked:** 56
**Summary:** 48 verified, 5 mostly accurate, 1 stale, 1 incorrect, 1 unverifiable

Merge method: code-review skill, "Merging replicate verdicts (most-severe-wins)". Claims were clustered on (file, line range ±5, substance). Where any replicate verdicted a finer part of a sentence that another verdicted as one compound claim, the merged report emits the finer rows (`Na`/`Nb`/...) and records the compound verdict on each row as `(compound)`; where a compound verdict blames only a sibling part (the replicate's own prose names that part as carrying it) it is recorded as `(compound; carried by <sibling>)` and does not set the verdict (decision 033 rule 2, as the U2a1 merge did). Evidence and reasoning come from the replicate that assigned the winning verdict, named in each claim as "Carried from rN Claim M"; claim numbers inside carried prose are that replicate's own numbering. Log paths are relative to that replicate's run root (see Execution provenance). No claim or evidence was added in the merge.

## Execution provenance (per replicate, as each recorded it)

All roots are under `/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-f/`.

- **r1:** `S=fact-check-r1/`. L1 `$S/logs/L1-bats.log`: targeted bats (12/12 ok), worktree, exit 0, 2026-10-10T19:01:31Z. L2 `$S/logs/L2-status-diff.log`: `$S/bin/probe-status.sh`, main's and HEAD's `scripts/` running `--status` over 10 brief paths, stdout/stderr compared with `cmp`, exit 0, 2026-10-10T19:02:03Z. Probe made and removed its own temp dir; no process left running.
- **r2:** `S=fact-check-r2/`. L1 `logs/bats-targeted.log` (9/9 ok, 19:01:35Z); L2 `logs/probe-status.log` (12 briefs, `cmp` identical, 19:02:05Z); L3 `logs/probe-midx.log`, `logs/probe-midx2.log` (midx with the pack's .idx moved away, read under `core.multiPackIndex=true`/`false`, 19:02:16Z); L4 `logs/probe-mut.log` (M1: pin removed from harden; config-pairs test not ok, second-copy test ok, 19:02:31Z); L5 `logs/probe-mut2.log` (M2: loose listing `find -P`, second-copy test not ok; M3: store_check after the settings reads, A15 not ok, 19:02:52Z); L6 `logs/probe-perf.log` (object count, bytes, re-hash time, duplicate scan of the shared store, 19:03:47Z). Probe repos under `mktemp -d`; every probe under `timeout`; no process left running.
- **r3:** `L=fact-check-r3/logs/`. L1 `$L/bats-targeted.log` (7/7 ok, 19:01:33Z); L2 `$L/bats-read.log` (build-loop-read.bats 20/20 ok, 19:01:58Z); L3 `$L/probe-status.log` (9 briefs, `IDENTICAL`, 19:02:26Z); L4 `$L/probe-midx.log` (midx with an .idx removed, with and without the pin; `--local-env-vars` lists no `GIT_CONFIG_KEY_*`, 19:02:37Z); L5 `$L/probe-skip.log` (git shim tees each `cat-file --batch` stdin, `--check` on two briefs, 19:02:55Z). Static: `git ls-tree -r -t main | wc -l` = 3691, summed blob sizes 67.8534 MB.

All three replicates read `docs/reviews/hallucination-patterns.md` (8 entries) first; none found a matching pattern. r1 and r3 noted settled override rows not re-filed (r1: rows 496/512 and 625 via override rows 643, 645; 638; 646. r3: the 2026-10-10 `feat/build-loop-u3a1` rows, `docs/reviews/override-log.md:638-649`).

## Claims Requiring Attention (summary)

| Claim | Location | Verdict | Replicate verdicts | Gist |
|---|---|---|---|---|
| 2b | `docs/working/plan-build-loop-handoff.md:317` | Stale | r1=Stale (compound) · r2=Mostly accurate (compound) · r3=Mostly accurate | "skipping ids already checked": since d10cfba8 a per-brief call skips only main's ids |
| 4b | `docs/working/plan-build-loop-handoff.md:317` | Mostly accurate | r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate | not-re-hashed list omits check_brief's `git log -G` walk of main's history |
| 10b | `scripts/build-loop.sh:262-263` | Unverifiable | r1=Verified (compound) · r2=Unverifiable · r3=Verified (compound) | midx "second route past store_check's listing" not reproduced on git 2.39.5 |
| 20 | `scripts/build-loop.sh:612-616` | Mostly accurate | r1=— · r2=Verified · r3=Mostly accurate | store_check's "Not checked" list omits the same check_brief walk |
| 25a | `scripts/build-loop.sh:844-850` | Mostly accurate | r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate | "each refusal a refuse state line and exit 2" does not hold for a failed mktemp (exit 1, no line) |
| 34b | `test/scripts/build-loop-check.bats:1900` | Incorrect | r1=Mostly accurate (compound) · r2=Incorrect · r3=Incorrect | title's "and no multi-pack-index route": the body has no midx case and stays green with the pin removed |
| 36c | commit 65007bf8 message | Mostly accurate | r1=— · r2=Verified (compound) · r3=Mostly accurate | cites row 512 for status_fields; row 512 (TIP/TREE/verdict values) moved to U3a2 |
| 36d | commit 65007bf8 message | Mostly accurate | r1=— · r2=Verified (compound) · r3=Mostly accurate | "check_line reads the brief once": status_fields reads the blob twice, own_blob twice more |

---

## Claim 1: "main's commit and every tree and blob of its tree (3,691 objects, 68 MB here: 0.3 s)"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the object count, total size and re-hash time of store_check's batch+perl over main's commit and tree on this machine today. It does not establish the full store_check time including the duplicate scan, or the figures on another host.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not re-time the 0.3 s figure (override row 639 records 0.24 s)"; r3 measured `3691` objects and `67.8534 MB` statically.

Carried from r2 Claim 1. L6 printed `objects: 3693`, `bytes: 67853429` and `rehash seconds: 0.24` for main at d5736445. That is two more objects than the plan's 3,691 because main has moved on, about 68 MB, and under 0.3 s.

**Evidence:** `docs/working/plan-build-loop-handoff.md:317`, `scripts/build-loop.sh:625-636`, `fact-check-r2/logs/probe-perf.log`

---

## Claim 2a: "store_check runs once for main in gate_start (a mismatch is `refuse state objects`, exit 2) and per brief for the tip and the merge's tree"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call sites, how many times each runs, and the exit status and line for main. It does not establish what each call reads (Claim 15) or the skip wording (Claim 2b).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Stale (compound; carried by 2b) · r2=Mostly accurate (compound; carried by 2b) · r3=Verified
**Replicate annotations:** r1: "The call sites and refusal hold" (its Stale names only the skip phrase) · r2: "The call sites match" (its Mostly accurate names only the skip phrase) · r1: "does not establish anything about the race residual (settled row 646)".

Carried from r3 Claim 1.

```bash
# scripts/build-loop.sh:858-859 (inside gate_start)
  store_check "$MAIN_SHA" && mv "$GATE_TMP/call" "$GATE_TMP/main" \
    || { echo "refuse state objects: ..."; exit 2; }
# scripts/build-loop.sh:916 (inside check_line)
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of the tip of $br or of the merge ..."; return; fi
```

L5 logs three `cat-file --batch` calls for a two-brief `--check`: one for main and one for each brief. In L1, the re-hash test passes, with main-side forgeries giving `$OBJS` at status 2.

**Evidence:** `scripts/build-loop.sh:854-861`, `scripts/build-loop.sh:916`, `fact-check-r3/logs/probe-skip.log`, `fact-check-r3/logs/bats-targeted.log`

---

## Claim 2b: "... per brief for the tip and the merge's tree, skipping ids already checked"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two call sites, the startup refusal and the skip set; does not establish anything about the race residual (settled row 646).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale (compound) · r2=Mostly accurate (compound) · r3=Mostly accurate
**Replicate annotations:** r2+r3: precise wording "skipping main's ids, checked at startup" (r3: "which is what d10cfba8's message says") · r3: "does not establish the security effect of the skip, which is settled at override row 646"; L5 executed: per-brief batches hold "main ids in it: 0" · r2: i1 code via `git show 83f75281:scripts/build-loop.sh` (`touch "$GATE_TMP/checked"`, `>> "$GATE_TMP/checked"`).

Carried from r1 Claim 1. The skip set is now main's ids only, not every id already checked: the read filter is `awk 'FILENAME != "-" { seen[$0]; next } !($0 in seen) { seen[$0]; print }' "$GATE_TMP/main" -` (`scripts/build-loop.sh:628`), and each call's ids go to `> "$GATE_TMP/call"` (`:636`), overwritten per call. So brief 2 re-reads ids brief 1 checked. The phrase was accurate at 83f75281, when an appended `$GATE_TMP/checked` file was the skip set (paraphrased — no quote available because that version is replaced; seen in the i2 fact-check report's Claim 1 quote of `:624`, `:630`, `:632`). d10cfba8 (B1) narrowed it; the store_check comment (`:601-602`, "an id in $GATE_TMP/main (main's, ...) is not read again") says so, but the plan note was not updated. Precise wording: "skipping main's ids".

**Evidence:** `scripts/build-loop.sh:618-645`, `scripts/build-loop.sh:858-859`, `scripts/build-loop.sh:916`, `docs/working/plan-build-loop-handoff.md:317`

---

## Claim 3a: "it also refuses an id of main's or of that call with a second copy in the store, listed as git opens them (links, dot-named packs ...), harden switches off the multi-pack-index, and the state gate refuses `objects/info/alternates`"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four mechanisms as present and exercised: the duplicate scan over main's and the call's ids, `find -L` with dot-named packs, the harden pin and the alternates refusal. It does not establish that git 2.39.5 has a midx route the pin closes (Claim 10b).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish coverage of copies reachable only through `GIT_ALTERNATE_OBJECT_DIRECTORIES` in the trusted caller's environment, or git versions other than the one installed" · r3: "does not establish that the scan finds copies another git version could read without an .idx (git 2.39.5 only)".

Carried from r2 Claim 3. The scan judges the ids in `"$GATE_TMP/main" "$GATE_TMP/call"` (`scripts/build-loop.sh:644`). It lists stores with `find -L pack ... -name '*.idx'` and `find -L . -mindepth 2 -maxdepth 2` (`:641`, `:643`). harden carries `core.multiPackIndex=false` (`:273`). state_gate's file loop includes `objects/info/alternates` (`:307`). Executed: L1 test 6 (second pack, loose+packed) and test 7 (a `.hidden` pack and a linked fan-out directory) are ok; L5 M2 (`find -P`) fails test 7; L1 test 2 prints `refuse state objects/info/alternates: present and not an empty file`; the config-pairs test shows the pin on every call.

**Evidence:** `scripts/build-loop.sh:273`, `scripts/build-loop.sh:307`, `scripts/build-loop.sh:641-644`, `fact-check-r2/logs/bats-targeted.log`, `fact-check-r2/logs/probe-mut2.log`

---

## Claim 3b: "One brief's refusal does not carry to the next (i2 architecture 1)."

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the second-copy refusal of one brief's tip blob in a two-brief run, in both orders. It does not establish anything about a refusal of main's objects, which exits the run by design.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

Carried from r2 Claim 4. The per-call output is `> "$GATE_TMP/call"` (`scripts/build-loop.sh:636`), which overwrites the file, and the scan's want-set is `"$GATE_TMP/main" "$GATE_TMP/call"` (`:644`). So a refusing brief's ids are not in the next call's sets. Test 6's last lines (`test/scripts/build-loop-check.bats:1894-1897`) run `chk "$y" "$B"` and `chk "$B" "$y"` and expect `ok $y` in both orders; ok in L1.

**Evidence:** `scripts/build-loop.sh:636`, `scripts/build-loop.sh:644`, `test/scripts/build-loop-check.bats:1894-1897`, `fact-check-r2/logs/bats-targeted.log`

---

## Claim 4a: "Main's objects are re-hashed once per run, so a rewrite of one in place after startup is the race residual."

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which objects store_check reads (REVs main, tip, merge tree and what ls-tree lists under them); does not establish whether the residual matters (settled rows 638, 646).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=—
**Replicate annotations:** none

Carried from r1 Claim 3. store_check reads only `printf '%s\n' "$r" "$r^{tree}"` and `git ls-tree -r -t --full-tree ... "$r"` per REV (`scripts/build-loop.sh:626-627`); its callers pass `"$MAIN_SHA"` (`:858`) and `"$sha" "$tree"` (`:916`). The startup call is the only one passed `"$MAIN_SHA"`.

**Evidence:** `scripts/build-loop.sh:618-628`, `scripts/build-loop.sh:858`, `scripts/build-loop.sh:916`

---

## Claim 4b: "Not re-hashed (Q-103 residual): the tip's parent, the commits check_branch counts, merge bases."

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the history objects a `--check` decision's readers walk. It does not re-open the settled residual (override row 638).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r2: "It does not establish that the list is exhaustive. check_brief's `git log -G'^Status: '` also reads main's history blobs (diffs). Its result (`c`) is discarded by status_fields (`read -r _ _ st _`), so it does not change a verdict." · r1: "does not establish whether the residual matters (settled rows 638, 646)" · r2+r1: the three named reads are real: `scripts/build-loop.sh:493`, `:652`, `scripts/lib/dev-cycle-read.sh:488`.

Carried from r3 Claim 4. The three items listed are real and unchecked. The list leaves out a fourth history reader on the --check path: status_fields runs check_brief, which walks main's first-parent history with `git log -G`:

```bash
# scripts/lib/dev-cycle-read.sh:462-464 (check_brief)
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s --no-textconv --no-show-signature --no-follow -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H --no-show-signature --no-follow "$MAIN_SHA" -- "$a")"
  if [[ -n "$c" && ! "$c" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]]; then echo "skip $a: its Status commit could not be read"; return; fi
```

status_fields discards that commit id (`read -r _ _ st _ <<<"$out"`, `scripts/build-loop.sh:522`), so forged history can only turn a brief into a skip, never into an ok verdict. The list should say "for example" or name check_brief's Status-commit walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:423-466`, `scripts/build-loop.sh:516-558`

---

## Claim 5a: "the branch and brief re-reads went with their refusals, so U3a2's shim reaches only the CAS" / U3a2: "the failed brief re-read row 625 named is gone (U3a1)"

**Location:** `docs/working/plan-build-loop-handoff.md:317-318`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the removal of check_line's `check_branch` re-read, its `brief_fields` re-read and the matching refusals and srules branch. It does not establish what U3a2's shim will do.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: main's version had `out="$(check_branch "$br")"` with "moved or could not be read again" and "the brief could not be read again from the default branch" (from `git show main:scripts/build-loop.sh`).

Carried from r2 Claim 6. check_line now reads `status_fields "$a"` once and takes `STATUS[...]` (`scripts/build-loop.sh:880-885`). The S rules' inputs are `[[ "$pol" != self-merge ]] || read_paths` (`:927`). `grep` finds no `moved or could not be read again` and no `could not be read again from the default branch` in the file (paraphrased — no quote available because the claim covers the absence of code; the diff's removed lines are at the old `:366-369`, `:401-403` and srules' `PATHS_WHY != unread` line).

**Evidence:** `scripts/build-loop.sh:875-939`, `scripts/build-loop.sh:746-759`

---

## Claim 5b: "status_fields (row 496) and gate_start (row 525) as planned ... Row 512's verdict values (TIP, TREE, verdict) moved to U3a2"

**Location:** `docs/working/plan-build-loop-handoff.md:317-318`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of check_line's second check_branch and brief_fields calls and of their refusal texts; does not establish U3a2's future shim design.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r1 Claim 4. check_line now reads only `status_fields "$a"` and STATUS values (`scripts/build-loop.sh:880-886`). No verdict-value function exists in HEAD, consistent with "moved to U3a2" (paraphrased — no quote available because the claim is about absence).

**Evidence:** `scripts/build-loop.sh:875-939`, `docs/working/plan-build-loop-handoff.md:317-318`

---

## Claim 6a: --help: "an info/attributes, info/grafts, shallow or objects/info/alternates (another object store) that is not absent or an empty file"

**Location:** `scripts/build-loop.sh:96-98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the alternates refusal line and its order. It does not establish `GIT_ALTERNATE_OBJECT_DIRECTORIES`, which is the caller's environment.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

Carried from r3 Claim 7. The loop is `for f in info/attributes info/grafts shallow objects/info/alternates; do` with `if [[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]; then echo "refuse state $f: present and not an empty file"` (`scripts/build-loop.sh:307-309`). L1: the state-gate test asserts the exact line `refuse state objects/info/alternates: present and not an empty file`, and passes.

**Evidence:** `scripts/build-loop.sh:296-318`, `test/scripts/build-loop-check.bats:1630-1642`, `fact-check-r3/logs/bats-targeted.log`

---

## Claim 6b: --help: "then the gate's own merge repository not set up ...; then main's commit, or a tree or blob of its tree, that does not hash to its id, has a second copy ... or cannot be read ('refuse state objects: WHY'; every file the gate reads from main is one). Each finding prints 'refuse state WHAT: WHY' and exits 2 before the settings or any brief is read."

**Location:** `scripts/build-loop.sh:102-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order state_gate, then default_gate, then gate_repo, then store_check, then settings and briefs; exit 2 for each finding; and that main's files are read as `MAIN_SHA:PATH` blobs of the checked tree. It does not establish that history blobs are checked (Claim 4b's residue), and does not cover mktemp failure, which is exit 1 with no line and is documented separately at `:220-221`.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish that blobs read from main's history (check_brief's `git log -G`, which feeds no --check decision) are checked" · r3: "does not establish that resolve_main reads no main object, which it does by design (`rev-parse SHA^{commit}`)".

Carried from r2 Claim 7.

```bash
# scripts/build-loop.sh:855-860
  default_gate || exit 2
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
  gate_repo || { echo "refuse state gate: ..."; exit 2; }
  store_check "$MAIN_SHA" && mv "$GATE_TMP/call" "$GATE_TMP/main" \
    || { echo "refuse state objects: ..."; exit 2; }
  reader_settings; read_settings; never_res; open_shared
```

state_gate runs first at top level (`:342`). brief_fields uses `git cat-file blob "$MAIN_SHA:$1"` (`scripts/lib/dev-cycle-read.sh:399`), main_file `git cat-file blob "$MAIN_SHA:$f"` (`:560`), own_blob the same (`scripts/build-loop.sh:670`). Executed: in L5, M3 moved store_check after the settings and open-brief reads and the A15 test failed ("store_check at line 29, first blob read at line 25"); unmutated it passes (L1). Test 6 expects exactly `$OBJS` with exit 2.

**Evidence:** `scripts/build-loop.sh:97-109`, `scripts/build-loop.sh:342`, `scripts/build-loop.sh:854-861`, `scripts/lib/dev-cycle-read.sh:399`, `scripts/lib/dev-cycle-read.sh:560`, `fact-check-r2/logs/bats-targeted.log`, `fact-check-r2/logs/probe-mut2.log`

---

## Claim 7: --help per-brief refusal: "an object of the tip of BRANCH or of the merge does not hash to its id, has a second copy in the object store, or could not be read": the tip's commit, or a tree or blob of its tree or of TREE (gitlinks aside)

**Location:** `scripts/build-loop.sh:126-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal text, what is read, and that the gitlink entries are dropped. It does not establish the order against the blob-presence check, which runs first (`:911-914`), so a missing blob of the merge refuses with that check's text.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish re-reading of ids shared with main per brief: they are skipped (re-hashed at startup), which the help leaves implicit."

Carried from r3 Claim 9 (most specific Scope). `printf '%s\n' "$r" "$r^{tree}"` and `git ls-tree -r -t --full-tree --format='%(objecttype) %(objectname)' "$r" 2>/dev/null | awk '$1 != "commit" { print $2 }' || exit 1` (`scripts/build-loop.sh:626-627`); call `store_check "$sha" "$tree"` (`:916`). L1: the re-hash test asserts this exact refusal for a forged tip blob and a loose second copy, with no path line, and passes.

**Evidence:** `scripts/build-loop.sh:618-645`, `scripts/build-loop.sh:911-916`, `test/scripts/build-loop-check.bats:1887-1892`, `fact-check-r3/logs/bats-targeted.log`

---

## Claim 8a: --help: "After an ok line, a K of N refusal or a checkout refusal, one line per path TREE changes"

**Location:** `scripts/build-loop.sh:165`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_line's final print, where only the verdict line varies. It does not cover the early-return refusals, which print no rows. That matches the help text.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

Carried from r3 Claim 10.

```bash
# scripts/build-loop.sh:937-938
  if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
  printf '%s\n' "${rows[@]}"
```

**Evidence:** `scripts/build-loop.sh:875-939`

---

## Claim 8b: --help: the floor is "not run when the verdict already refuses for the checkout"

**Location:** `scripts/build-loop.sh:192-193`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_line's final print and srules' `$5` guard now that the brief re-read refusal is gone. It does not establish the floor walk's own behaviour.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r2 Claim 9. srules runs the floor only when `[[ -z "$5" ]] && floor ...` (`:749`), and `$5` is `"$co"` (`:934`). `co` is set only by checkout_gate (`:924`).

**Evidence:** `scripts/build-loop.sh:746-759`, `scripts/build-loop.sh:924-938`

---

## Claim 9: Help exit line: "2 any --check verdict line or the state gate not ok ... 1 bad usage, ... a failed mktemp (--check; no line printed)"

**Location:** `scripts/build-loop.sh:216-221`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new `refuse state objects` exit 2 and the per-brief store_check refusal counting as not ok; does not cover the mktemp failure path (not run; `GATE_TMP="$(mktemp -d)"` under set -e at `:856` by reading).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r1 Claim 26. `|| { echo "refuse state objects: ..."; exit 2; }` (`:859`); per-brief refusals reach `[[ "$(head -c 3 "$GATE_TMP/line")" == "ok " ]] || fails=1` and `[[ "$fails" -eq 0 ]] || exit 2` (`:957-959`). Executed: L1's re-hash test asserts `status -eq 2` for both.

**Evidence:** `scripts/build-loop.sh:856-859`, `scripts/build-loop.sh:950-960`, `fact-check-r1/logs/L1-bats.log`

---

## Claim 10a: harden: "Every git call in this process, the lib's included, runs hardened ... no multi-pack-index" (the pair is set for every git call, gate_git's included)

**Location:** `scripts/build-loop.sh:259-277`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pair's presence on every git call --check makes, including gate_git's. It does not establish what the pin prevents (Claim 10b).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish what git does with a multi-pack-index when the pin is absent" · r3: L4 shows `--local-env-vars` holds no `GIT_CONFIG_KEY_*` ("0").

Carried from r2 Claim 10a. `for kv in ... core.commitGraph=false core.multiPackIndex=false; do export "GIT_CONFIG_KEY_$c=..."` (`:273-274`). gate_repo unsets only the names that `git rev-parse --local-env-vars` lists, except `callervar` (`:579`). On git 2.39.5 that list includes GIT_CONFIG_COUNT (kept) but no GIT_CONFIG_KEY_n or GIT_CONFIG_VALUE_n (executed inline), so the pairs reach gate_git. L1: the config-pairs test is ok. L4 M1, with the pin removed: that test fails with "a call without core.multiPackIndex=false".

**Evidence:** `scripts/build-loop.sh:271-278`, `scripts/build-loop.sh:575-585`, `test/scripts/build-loop-check.bats:1685`, `fact-check-r2/logs/bats-targeted.log`, `fact-check-r2/logs/probe-mut.log`

---

## Claim 10b: harden: "(a second route to an object, past store_check's listing)"

**Location:** `scripts/build-loop.sh:262-263`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one candidate route on git 2.39.5: a pack the midx names whose .idx is absent. That route does not exist, because git then cannot read the object under either setting. It does not establish whether another route exists, or exists on other git versions.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Unverifiable · r3=Verified (compound)
**Replicate annotations:** r3: "It does not establish the parenthetical rationale. In L4, a pack whose .idx was removed under a multi-pack-index is unreadable with and without the pin on git 2.39.5, so that route was not reproduced. The pin's practical effect is that real-repo and gate-repo reads agree whatever the repo config says." · r3 (Claims Requiring Attention): "scoped out as rationale, not verdicted" · r1: "does not establish what git does with a multi-pack-index when the pin is absent" · r2+r3 Out of scope: whether any git version reads a midx pack past the .idx listing (see Escalations E2).

Carried from r2 Claim 10b. L3 wrote a midx and moved the pack's .idx away. `cat-file -t` gave `error: packfile ... index unavailable` and `fatal: git cat-file: could not get object info` (rc 128) with `core.multiPackIndex=true`, and the same fatal with `=false`. The i2 fact-check's P4 probe found the same. The pin is harmless and makes every read take the same lookup. However, on this git version no object was found that is reachable only through the midx. Verifying the "second route" would need a midx-only read path on some git version, or a reference in git's source.

**Evidence:** `scripts/build-loop.sh:262-263`, `fact-check-r2/logs/probe-midx.log`, `fact-check-r2/logs/probe-midx2.log`, `docs/reviews/code-fact-check-report-build-loop-u3a1-i2.md:251`

---

## Claim 11: state_gate header: "Files: an info/attributes, info/grafts, shallow or objects/info/alternates that is not absent or an empty regular file (each changes merges, history or the objects read)"

**Location:** `scripts/build-loop.sh:290-292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the alternates entry and its refusal line. It does not establish refusal of `GIT_ALTERNATE_OBJECT_DIRECTORIES` (a caller environment variable; checkout_gate refuses it only for self-merge briefs).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "Covers the four paths and the non-empty/symlink/non-file test" · r3: "does not establish the effect of each file on git".

Carried from r2 Claim 11 (most specific Scope). The loop is `for f in info/attributes info/grafts shallow objects/info/alternates; do` (`:307`). L1 test 2 (`test/scripts/build-loop-check.bats:1633-1640`) is ok, and its expected output includes `refuse state objects/info/alternates: present and not an empty file`.

**Evidence:** `scripts/build-loop.sh:307-310`, `test/scripts/build-loop-check.bats:1633-1640`, `fact-check-r2/logs/bats-targeted.log`

---

## Claim 12: "--check refuses planted state before any git call reads an object (resolve_main does); gate_start runs the rest of its startup." / GATED "a mode that decides" at both top-level sites / "gate_start calls it once main's objects are checked."

**Location:** `scripts/build-loop.sh:339-349`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both GATED sites (state_gate and the reader_settings skip) and reader_settings' place in gate_start. It does not establish anything about U3b's future modes.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish anything about U3a2's future --merge mode setting GATED"; --status still prints its lines (r1 L2) · r3: "does not establish behaviour for modes other than check, which still call reader_settings at top level".

Carried from r2 Claim 12 (L5 mutation evidence). The two sites are `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`:342`) and `[[ -n "$GATED" ]] || reader_settings` (`:349`). gate_start calls `reader_settings` after store_check (`:860`). L1: the A15 test is ok; L5 M3 shows that test catches a reordering.

**Evidence:** `scripts/build-loop.sh:339-349`, `scripts/build-loop.sh:860`, `test/scripts/build-loop-check.bats:1949-1965`, `fact-check-r2/logs/bats-targeted.log`, `fact-check-r2/logs/probe-mut2.log`

---

## Claim 13a: status_fields comment, STATUS shapes: "STATUS[line] is the line --status prints. Only for an 'ok' line does STATUS hold its fields by name ... ('-' for a branch, sha or date there is none of, and an empty reason), and ahead ... (0 when absent); a skip line sets only line."

**Location:** `scripts/build-loop.sh:505-510`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every return of status_fields. It does not establish that check_brief prints only `ok` or `skip`. That was read and holds (`dev-cycle-read.sh:423-466`).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not establish callers beyond check_line and status_line" · r1: "does not establish anything for future callers".

Carried from r3 Claim 14.

```bash
# scripts/build-loop.sh:518, :521, :524, :542, :556-557
  STATUS=(); BRIEF=()
  [[ "$out" == "ok "* ]] || { STATUS[line]="$out"; return; }
    STATUS=([line]="ok $a new review - absent - - 0" [state]=new [policy]=review [branch]=- [loop]=absent [sha]=- [ahead]=0 [date]=- [dispatched]=0 [reason]="")
  sha=- ahead=0 date=- loop=absent
  STATUS=([line]="ok $a $st $pol $br $loop $sha $date $disp${reason:+ $reason}" [state]="$st" ... [reason]="$reason")
```

Every other return sets only `STATUS[line]`, to a `skip` text.

**Evidence:** `scripts/build-loop.sh:505-559`

---

## Claim 13b: status_fields comment, BRIEF: "BRIEF is emptied, then holds what brief_fields read for this brief ... (empty for a new brief or one check_brief skips): check_line takes Paths: from it, so nothing between may call brief_fields."

**Location:** `scripts/build-loop.sh:510-514`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the calls between `status_fields` and `read_paths` in check_line (merge_result, gate_git diff-tree and cat-file, store_check, checkout_gate). It does not cover own_blob's later direct blob reads, which do not touch BRIEF.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

Carried from r3 Claim 15. check_brief runs in `$(...)` (`:520`), so its brief_fields sets only a subshell's BRIEF. The in-shell `brief_fields "$a"` (`:527`) is the source. open_shared declares `local -A count=() BRIEF=()` (`dev-cycle-read.sh:505`), so the caller's BRIEF is untouched. No function called between `:880` and `:927` calls brief_fields (paraphrased — no quote available because this claim is about the absence of calls across several function bodies, `:576-660` and `:777-843`, all read).

**Evidence:** `scripts/build-loop.sh:516-558`, `scripts/build-loop.sh:880-927`, `scripts/lib/dev-cycle-read.sh:390-414`, `scripts/lib/dev-cycle-read.sh:503-518`

---

## Claim 14: `status_line() { status_fields "$1"; echo "${STATUS[line]}"; }` keeps --status output byte-identical to main's

**Location:** `scripts/build-loop.sh:556-559`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 12 briefs across every return path of status_fields: new, absent, working, done at ahead 0, stopped with reason, ready, the skips for a missing Branch:, a bad Dispatched:, a bad marker, a shared branch and not-a-brief. It does not cover the skips for an unlistable OPEN_SHARED or an unreadable count, which are not reachable without a fault shim.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish the skip texts for an unlistable OPEN_SHARED or a shared branch, which were read (identical text) but not run" · r3: "does not cover a stopped marker with an empty reason, which marker_kind's regex rules out (`:502`)"; r3 L2: unchanged build-loop-read.bats 20/20 ok.

Carried from r2 Claim 14 (widest executed set). The reason is now stored bare and printed with `$disp${reason:+ $reason}` (`:556`). Main's code stored `reason=" ${kind#stopped }"`, and marker_kind's stop reason matches `[!-~]...`, so it is never empty. In L2, `cmp` prints `IDENTICAL-stdout` and `IDENTICAL-stderr` for main's script and HEAD's, and both exit 0.

**Evidence:** `scripts/build-loop.sh:541-559`, `scripts/build-loop.sh:502`, `fact-check-r2/logs/probe-status.log`

---

## Claim 15: store_check: "Each REV (a commit or a tree), its root tree, and every tree and blob below it (a gitlink names another repository's commit) are read in one cat-file --batch and re-hashed by one perl, for sha1 or sha256, but an id in $GATE_TMP/main (main's, which gate_start's call leaves there) is not read again."

**Location:** `scripts/build-loop.sh:598-602`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the input list, the skip and the re-hash. Two limits are not covered by "is not read again". The `REV^{tree}` expression is never skipped, so a root tree equal to one of main's is still re-read, as the comment at `:636` says. The re-hash runs no length or type check beyond the header regex.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish REF_DELTA bases outside the checked set, nor the race (named in the comment)" · r2: "does not establish that per-brief objects equal to main's ids are fresh at the time of the per-brief read (the race named in Claim 19)".

Carried from r3 Claim 17 (most specific Scope).

```perl
# scripts/build-loop.sh:631-633
        my ($id, $t, $s) = $h =~ /^([0-9a-f]+) ([a-z]+) ([0-9]+)\n\z/ or exit 1;  # "NAME missing" too
        read(STDIN, my $b, $s) == $s && (getc(STDIN) // "") eq "\n" or exit 1;
        Digest::SHA->new($ENV{ALG})->add("$t $s\0", $b)->hexdigest eq $id or exit 1;
```

L5: the per-brief batches carry the tip id, `TIP^{tree}`, the tip's own blob, the merge tree id and `TREE^{tree}`, with 0 of main's ids. L1: the SHA-256 test passes the packed and second-copy cases.

**Evidence:** `scripts/build-loop.sh:618-636`, `fact-check-r3/logs/probe-skip.log`, `fact-check-r3/logs/bats-targeted.log`

---

## Claim 16: store_check: "Then no id of main's or of this call may have a second copy in the store: in two packs, or loose and packed ... The listing follows links and takes dot-named packs" / "From inside the store ..., with find -L: git opens a linked fan-out directory or pack, and a pack whose name starts with a dot, as it opens any other."

**Location:** `scripts/build-loop.sh:602-611`, `scripts/build-loop.sh:637-640`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `.hidden.idx` pack and a symlinked fan-out directory. It does not establish coverage of other git-readable layouts not tried here.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "does not establish coverage of packs that git versions other than 2.39.5 open".

Carried from r2 Claim 17. The listing is `find -L pack -mindepth 1 -maxdepth 1 -name '*.idx' ! -type d` and `find -L . -mindepth 2 -maxdepth 2 ! -type d -path './[0123456789abcdef][0123456789abcdef]/*'` (`:641`, `:643`). In L1, test 7 (both cases refuse with `$OBJS`) is ok. In L5, M2 (`find -P` for the loose listing) makes test 7 fail.

**Evidence:** `scripts/build-loop.sh:641-643`, `test/scripts/build-loop-check.bats:1900-1912`, `fact-check-r2/logs/bats-targeted.log`, `fact-check-r2/logs/probe-mut2.log`

---

## Claim 17: "git can read either copy of an id, and two reads of one id (cat-file --batch here, cat-file blob MAIN:PATH in brief_fields) took different ones (U3a1 i1 security F1 ...)"

**Location:** `scripts/build-loop.sh:604-607`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the reference: the i1 security report records this divergence. It does not establish the divergence by a fresh reproduction in this pass (no forged-pack probe was run).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** none (r3's "does not reproduce which copy each read takes" is the same residue)

Carried from r2 Claim 16 (quotes the cited report). `docs/reviews/security-reviewer-review-2026-10-10-build-loop-u3a1.md:49` says: "When an object is forged inside a pack under a genuine id ... the tree-path read returns the forged bytes, while `cat-file --batch` by id returns bytes that re-hash to the genuine id". brief_fields' read is `git cat-file blob "$MAIN_SHA:$1"` (`scripts/lib/dev-cycle-read.sh:399`).

**Evidence:** `scripts/build-loop.sh:604-607`, `docs/reviews/security-reviewer-review-2026-10-10-build-loop-u3a1.md:43-61`, `scripts/lib/dev-cycle-read.sh:399`

---

## Claim 18: store_check: "Only one call's ids are judged, so one brief's refusal never carries to the next"

**Location:** `scripts/build-loop.sh:609-611`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the judged set (`$GATE_TMP/main` plus `$GATE_TMP/call`) and the two-brief carry test. "Only one call's ids" means main's plus this call's (the comment's previous sentence says so).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

Carried from r3 Claim 18. The scan is quoted in Claim 3a (`:641-644`). In L1, the re-hash test runs two briefs in both orders (`ok $y` then `refuse $B`, and `refuse $B` then `ok $y`) and passes.

**Evidence:** `scripts/build-loop.sh:637-645`, `test/scripts/build-loop-check.bats:1892-1898`, `fact-check-r3/logs/bats-targeted.log`

---

## Claim 19: "Returns 1 on a mismatch, a missing object, a second copy or a failed read."

**Location:** `scripts/build-loop.sh:611-612`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the non-zero return on each named path. Both callers test only for non-zero. It does not establish that the status is exactly 1 on every failure: a failing loose-object `find` passes its own status through pipefail.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "It does not establish failure on every possible read error. The i2 fact-check executed truncated and unreadable .idx cases, which were not re-run here." · r1: "store_check is only called in conditions (`:858`, `:916`), so set -e is off inside and pipefail makes a failing `find`, `show-index` or `ls-tree` fail the pipeline."

Carried from r3 Claim 19 (atomic, most specific Scope).

```bash
# scripts/build-loop.sh:636 and :644
      exit($n ? 0 : 1)' > "$GATE_TMP/call" || return 1  # REV^{tree} is never skipped, so 0 read is a fault
  } | awk '... END { exit bad }' "$GATE_TMP/main" "$GATE_TMP/call" -
```

L1 covers a mismatch (forged blobs), a missing tree and second copies. All refuse.

**Evidence:** `scripts/build-loop.sh:618-645`, `fact-check-r3/logs/bats-targeted.log`

---

## Claim 20: "Not checked: objects a decision reaches only through history (the tip's parent, read by marker_kind; the commits check_branch counts; the merge bases, whose merge result the rules judge), and a writer racing between a check and a later read (R8's family, Q-103), which for main's objects spans the whole run, as they are re-hashed once."

**Location:** `scripts/build-loop.sh:612-616`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list of history readers and the run-wide race window for main's objects. It does not re-file the settled residual (override rows 638, 646).
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r2: "It does not establish exhaustiveness. check_brief's `git log -G'^Status: '` (`scripts/lib/dev-cycle-read.sh:462`) also reads main's history blobs unchecked, and its result field is discarded by status_fields, so no verdict depends on it."

Carried from r3 Claim 21. The race half holds: main's ids are checked once at gate_start and then skipped (Claim 2b). The history list leaves out check_brief's `git log -G'^Status: ' "$MAIN_SHA"` walk over main's first-parent history (`scripts/lib/dev-cycle-read.sh:462-464`, quoted in Claim 4b). That walk runs on every status_fields call and can only yield a skip. Adding "check_brief's Status commit" to the list would make it complete.

**Evidence:** `scripts/build-loop.sh:612-616`, `scripts/lib/dev-cycle-read.sh:462-464`, `scripts/build-loop.sh:522`

---

## Claim 21: "Reads the real repository's object store, as merge-tree writes into it. Needs GATE_TMP."

**Location:** `scripts/build-loop.sh:616-617`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers store_check's plain `git` calls and the gate repository's object directory. It does not establish anything about alternates from the caller's environment.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r2 Claim 20. store_check calls `git cat-file --batch` and `git ls-tree` without `gate_git` (`:627-628`). The gate repository sets `GIT_OBJECT_DIRECTORY="$v"`, where `v` is the real `--git-path objects` (`:580`, `:584`), so merge-tree's writes land in the real store. store_check writes `$GATE_TMP/main`, `call` and `idx` (`:622`, `:636`, `:641`).

**Evidence:** `scripts/build-loop.sh:576-585`, `scripts/build-loop.sh:618-645`

---

## Claim 22a: "Each object name once, never one of main's ids; git's own error for a missing tree is dropped (the missing object fails the check)."

**Location:** `scripts/build-loop.sh:623-624`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the awk de-duplication by name and the literal `REV^{tree}` name never matching a hex id in `main`; does not establish de-duplication by resolved object (`REV` and `REV^{tree}` can resolve to an id ls-tree also lists; read twice, harmless).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r2 (Scope of its Claim 21, not verdicted): "It does not establish the 'Each object name once' wording at `:623` for objects, because a tree REV is read twice, as `T` and as `T^{tree}`. That is harmless: the call file is a set for the scan."

Carried from r1 Claim 13. `printf '%s\n' "$r" "$r^{tree}"` (`:626`) emits a literal `...^{tree}` name, which the `!($0 in seen)` filter over main's hex ids (`:628`) cannot drop; `git ls-tree ... 2>/dev/null` (`:627`). Executed (L1): the missing-tree case asserts `[ -z "$stderr" ]`.

**Evidence:** `scripts/build-loop.sh:623-636`, `test/scripts/build-loop-check.bats:1881-1884`, `fact-check-r1/logs/L1-bats.log`

---

## Claim 22b: "REV^{tree} is never skipped, so 0 read is a fault"

**Location:** `scripts/build-loop.sh:636`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skip filter's inability to match the literal string `REV^{tree}`. It does not establish the "Each object name once" wording at `:623` for objects, because a tree REV is read twice, as `T` and as `T^{tree}`. That is harmless: the call file is a set for the scan.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** none

Carried from r2 Claim 21. `printf '%s\n' "$r" "$r^{tree}"` (`:626`) feeds a name containing `^{tree}`. The skip compares whole lines against hex ids in `$GATE_TMP/main` (`:628`), so that name always passes. cat-file then prints one object for it, and the perl's `exit($n ? 0 : 1)` (`:636`) fires only if nothing was read.

**Evidence:** `scripts/build-loop.sh:623-636`

---

## Claim 23: own_blob: "main's copy ... the one brief_fields reads (status_fields has read it as 'Status: open')"

**Location:** `scripts/build-loop.sh:661-665`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the only caller path (nrules from check_line after the `st != open` refusal). It does not establish that own_blob's two blob reads see the same copy as the earlier reads; that is covered only by the second-copy scan.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish anything beyond the open-state gate".

Carried from r3 Claim 22 (most specific Scope). `if [[ "$st" != open ]]; then echo "refuse $a: the brief is $st ..."; return; fi` (`scripts/build-loop.sh:883`) comes before any nrules call (`:933`); own_blob is called only from nrules for the brief's own path (r2: `:691`).

**Evidence:** `scripts/build-loop.sh:666-673`, `scripts/build-loop.sh:883`, `scripts/build-loop.sh:933`

---

## Claim 24: srules: "$5 the checkout's refusal, if any ... the floor (only when $5 is empty: it walks the checkout)"

**Location:** `scripts/build-loop.sh:740-741`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the argument and the guard. It does not establish the floor's internals.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** none

Carried from r2 Claim 23. The guard is `if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then` (`:749`). The caller passes `"$co"` (`:934`; r3 quotes `srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"`), which only checkout_gate sets (`:924`).

**Evidence:** `scripts/build-loop.sh:746-759`, `scripts/build-loop.sh:924`, `scripts/build-loop.sh:934`

---

## Claim 25a: gate_start: "... in this order, each refusal a 'refuse state' line and exit 2 before any setting or brief is read: the default branch unambiguous (default_gate); the gate's merge repository (GATE_TMP, removed at exit); main's commit and tree re-hashed ...; then the reader lists ..."

**Location:** `scripts/build-loop.sh:844-850`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers gate_start's order and its three refusal paths. It does not cover the top-level main_by_name failure, which is also outside the comment's list.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "'each refusal a 'refuse state' line and exit 2' holds for gate_start's three refusals; mktemp failure is exit 1 with no line, as the header's exit list says (`:221`)" · r2: "does not establish anything about mktemp failure (exit 1, no line; documented elsewhere)"; order executed via L5 M3.

Carried from r3 Claim 24. The order and the three `refuse state` refusals (default_gate's lines, `refuse state gate:`, `refuse state objects:`) match `:855-860` (quoted in Claim 6b). One startup failure is not a "refuse state" line with exit 2: a failed `GATE_TMP="$(mktemp -d)"` under `set -e` exits 1 with no line, as the header's exit section says (`:221`, "a failed mktemp (--check; no line printed)"). The comment should exclude mktemp's failure.

**Evidence:** `scripts/build-loop.sh:216-223`, `scripts/build-loop.sh:854-861`

---

## Claim 25b: gate_start: "The repository rule: main's files and refs, the branch tips, the checkout and store_check's object reads are in the real repository; the merge computations (merge-base, merge-tree, diff-tree, the blob checks) run through gate_git."

**Location:** `scripts/build-loop.sh:850-853`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every git call in merge_result, check_line, own_blob, store_check, checkout_gate and the lib's readers that were read. It does not cover dev-cycle-read.sh's floor walk internals.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish the lib's internal calls beyond those named".

Carried from r3 Claim 25. merge_result uses `gate_git merge-base`, `gate_git cat-file -e` and `gate_git merge-tree` (`:652-656`). check_line uses `gate_git diff-tree` (`:895`) and `gate_git cat-file --batch-check` (`:911`). own_blob uses `gate_git hash-object` (`:672`). store_check, brief_fields, check_branch and checkout_gate call plain `git`.

**Evidence:** `scripts/build-loop.sh:618-673`, `scripts/build-loop.sh:777-843`, `scripts/build-loop.sh:875-916`

---

## Claim 26: check_line: "or one skip or refuse line (status_fields' STATUS[line], then the gate's own reasons) ... each helper empties its own globals before use (DENY, PATHS and PATHS_WHY, LIST, LIST_WHY and LIST_BAD, STATUS, BRIEF, CHECKOUT_WHY, FLOOR_WHY, TRUTH_WHY)"

**Location:** `scripts/build-loop.sh:862-874`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers STATUS, BRIEF (emptied at `:518`) and the per-call `$GATE_TMP/call` overwrite; does not establish FLOOR_WHY/TRUTH_WHY resets (lib, unchanged by this branch, not re-read).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r2: "The `check_line "$a" > "$GATE_TMP/line"` call (`:956`) is a redirection, not a subshell, so STATUS lives in the run's shell"; "does not re-verify the pre-existing entries" (r3 same).

Carried from r1 Claim 15 (most specific Scope). `[[ "${STATUS[line]}" == "ok "* ]] || { echo "${STATUS[line]}"; return; }` (`:881`). `$GATE_TMP/main` persists across briefs by design (main's ids), and `> "$GATE_TMP/call"` (`:636`) resets the per-call set. Executed (L1): the two-brief run in both orders gives `ok` for brief y whichever order.

**Evidence:** `scripts/build-loop.sh:875-916`, `test/scripts/build-loop-check.bats:1894-1897`, `fact-check-r1/logs/L1-bats.log`

---

## Claim 27: check_line: "The tip's objects and the merge's, re-hashed (main's were, in gate_start)."

**Location:** `scripts/build-loop.sh:915`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against its line. It does not establish main's freshness after startup (the race, Claim 20).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

Carried from r3 Claim 27. `if ! store_check "$sha" "$tree"; then ...` (`:916`).

**Evidence:** `scripts/build-loop.sh:915-916`

---

## Claim 28: check_line: "The S rules' inputs: the brief as status_fields read it from main's commit."

**Location:** `scripts/build-loop.sh:925-927`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers read_paths reading `BRIEF[paths]` left by status_fields; does not establish the S rules themselves (unchanged).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish anything about the floor's own reads after read_paths".

Carried from r1 Claim 16 (atomic). `[[ "$pol" != self-merge ]] || read_paths` (`:927`) and `[[ -n "${BRIEF[paths]+set}" ]] || return 0; list_entries "${BRIEF[paths]}" Paths path pathform` (`:717-718`); BRIEF set by `brief_fields "$a"` in status_fields (`:527`) from `git cat-file blob "$MAIN_SHA:$1"` (lib `:399`).

**Evidence:** `scripts/build-loop.sh:527`, `scripts/build-loop.sh:714-720`, `scripts/build-loop.sh:925-927`

---

## Claim 29: state-gate test: planted `objects/info/alternates` gives "refuse state objects/info/alternates: present and not an empty file" in order

**Location:** `test/scripts/build-loop-check.bats:1633-1640`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's planted file and expected line. It does not cover an alternates symlink or directory form (the code's `-L` and `! -f` branches, `scripts/build-loop.sh:309`).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** none (r3's "does not test a symlinked or non-regular alternates file separately" is the same residue)

Carried from r2 Claim 27. The test plants `echo "$BATS_TEST_TMPDIR/elsewhere" > .git/objects/info/alternates` and expects `refuse state objects/info/alternates: present and not an empty file`, in order between shallow and refs/replace. The order matches the code's loop (`scripts/build-loop.sh:307`). L1 test 2 is ok.

**Evidence:** `test/scripts/build-loop-check.bats:1614-1643`, `fact-check-r2/logs/bats-targeted.log`

---

## Claim 30: config-pairs test: every logged call carries `core.multiPackIndex=false`

**Location:** `test/scripts/build-loop-check.bats:1685`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the list and its sensitivity to the pin. It does not establish the pin's security effect (Claim 10b).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not check pairs given as absolute-path git calls, and none exist".

Carried from r2 Claim 28 (mutation evidence). The test checks `for kv in ... core.commitGraph=false core.multiPackIndex=false G=/dev/null P=none S=1; do ! grep -v -- " $kv" ...`. In L1 it is ok. In L4 (M1) it fails with "a call without core.multiPackIndex=false".

**Evidence:** `test/scripts/build-loop-check.bats:1674-1688`, `fact-check-r2/logs/bats-targeted.log`, `fact-check-r2/logs/probe-mut.log`

---

## Claim 31: "Packed, with a second copy of the brief's blob: store_check reads SHA-256 pack indexes (U3a1)."

**Location:** `test/scripts/build-loop-check.bats:1723-1726`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a fully packed SHA-256 repo passing and a second pack copy refusing. It does not establish SHA-256 loose-file duplicates, which the 62-char name concatenation would handle but this test does not exercise.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not cover a SHA-256 forged-bytes case, which is a sha1 case only".

Carried from r2 Claim 29. The test runs `git repack -adq; chk "$B"; [ "$status" -eq 0 ]`, then `git rev-parse "main:$B" | git pack-objects -q .git/objects/pack/pack` and expects `$OBJS` with status 2. The pack listing calls `git show-index --object-format="$fmt"` (`scripts/build-loop.sh:642`). L1 test 4 is ok.

**Evidence:** `test/scripts/build-loop-check.bats:1717-1727`, `test/scripts/build-loop-check.bats:1866`, `scripts/build-loop.sh:642`, `fact-check-r2/logs/bats-targeted.log`

---

## Claim 32: forge/loose helpers: "forge ID TEXT: rewrite loose object ID's file to hold a blob of TEXT, its id unchanged." / "loose ID: a loose copy of packed blob ID, beside the packed one (git itself writes none for an object it has)."

**Location:** `test/scripts/build-loop-check.bats:1857-1865`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helpers as used in tests 6 and 7. It does not cover the parenthetical about git's own writes, which was not separately probed here (the i2 fact-check's P6 probe found hash-object writes no loose copy).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish git's write-avoidance beyond hash-object/pack-objects (verified in i2's probe P6, not rerun)" (r3 same residue).

Carried from r2 Claim 30. forge writes `printf 'blob %s\0%s' ... | perl -MCompress::Zlib ... > "$f"` to the id's own path. Test 6 asserts that the forged blob reads back: `[ "$(git cat-file blob "$o" | grep Branch)" = "Branch: feat/y" ]`. loose writes the zlib of `"blob " . length . "\0" . content` to the id path. L1 tests 6 and 7 are ok.

**Evidence:** `test/scripts/build-loop-check.bats:1857-1865`, `test/scripts/build-loop-check.bats:1878-1880`, `fact-check-r2/logs/bats-targeted.log`

---

## Claim 33: Test title "--check re-hashes what it reads: a rewritten, missing or second copy of an object of main's tree refuses the state before any brief; of the tip's tree, the brief; a packed store passes (rows 492, 503, U3a1, i1 security F1)" and its case comments

**Location:** `test/scripts/build-loop-check.bats:1867-1898`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each case the title names for main's tree and the rewritten and second-copy cases for the tip; does not establish a missing tip object reaching store_check (a missing tip object fails earlier, at merge_result).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none (r2 and r3 state the same residue: "missing" exercised only for main's tree)

Carried from r1 Claim 17. The forged blob reads back: `[ "$(git cat-file blob "$o" | grep Branch)" = "Branch: feat/y" ]` (`:1879`), then `[ "$output" = "$OBJS" ] && [ -z "$stderr" ]` (`:1880`). Both tip cases compare `$output` exactly to the one refusal line (`:1888-1893`), so "no path line" is asserted for both. Executed: L1 `ok 8`.

**Evidence:** `test/scripts/build-loop-check.bats:1858-1898`, `fact-check-r1/logs/L1-bats.log`

---

## Claim 34a: test title: "--check's second-copy scan lists what git opens: a pack named with a leading dot, a linked fan-out directory"

**Location:** `test/scripts/build-loop-check.bats:1900`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two layouts named and the test's sensitivity to `find -L`. It does not cover the midx part of the title (Claim 34b).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Mostly accurate (compound; carried by 34b) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "Covers the dot-named pack and the linked fan-out cases, which pass" (its Mostly accurate names only the midx phrase) · r3: "does not cover a symlinked `pack/` directory".

Carried from r2 Claim 32a. The test moves a pack to `.git/objects/pack/.hidden.{idx,pack}`, checks `[ "$(git cat-file -t "$o")" = blob ]`, and expects `$OBJS`. It then links a fan-out directory with `ln -s "$BATS_TEST_TMPDIR/fan/${o:0:2}" ".git/objects/${o:0:2}"` and expects `$OBJS` again. It passes in L1 and fails under M2 in L5.

**Evidence:** `test/scripts/build-loop-check.bats:1900-1912`, `fact-check-r2/logs/bats-targeted.log`, `fact-check-r2/logs/probe-mut2.log`

---

## Claim 34b: test title: "... and no multi-pack-index route (U3a1 i2 security F1)"

**Location:** `test/scripts/build-loop-check.bats:1900`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether this test exercises the midx pin. It does not establish whether the pin is tested elsewhere: it is, by the config-pairs test (Claim 30).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r3: fix by dropping "and no multi-pack-index route" from the title or pointing to the config-pairs test (`:1685`) as the pin's coverage · r3: `grep -n -i "multi-pack\|multiPackIndex\|midx" test/scripts/*.bats` matches only `:1685` and `:1900`.

Carried from r2 Claim 32b (executed; r3 Claim 33b ties at Incorrect, static). The test body (`:1901-1912`) contains no `multi-pack-index` command and no midx file (paraphrased — no quote available because the claim covers the absence of code in a 12-line body read whole). In L4 (M1, the pin removed from harden), this test still prints `ok 2 --check's second-copy scan ...`. A reader trusting the title would think this test pins the midx behaviour. It does not, and removing the pin leaves it green. Either the title should drop "and no multi-pack-index route", or the test should add a midx case.

**Evidence:** `test/scripts/build-loop-check.bats:1900-1912`, `fact-check-r2/logs/probe-mut.log`

---

## Claim 35: A15 test: "store_check re-hashes main's objects before any cat-file blob read of main (U3a1 i1 architecture 1)."

**Location:** `test/scripts/build-loop-check.bats:1959-1962`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering between store_check's `cat-file --batch` and the first `cat-file blob` in the shim log, and the check's sensitivity to reordering. It does not cover reads by path through other commands (git grep in open_shared, which is also after store_check per `scripts/build-loop.sh:860`).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not cover main's object reads made in other forms before store_check (resolve_main's `rev-parse SHA^{commit}`, by design)" · r1: "The wording now says 'cat-file blob read', resolving i2's Claim 27."

Carried from r2 Claim 33 (mutation evidence). The check is `c="$(grep -n -m1 -x 'cat-file --batch' ...)"; f="$(grep -n -m1 '^cat-file blob ' ...)"; [ "$c" -lt "$f" ]`. L1 is ok. In L5 M3 it fails at "store_check at line 29, first blob read at line 25".

**Evidence:** `test/scripts/build-loop-check.bats:1949-1965`, `fact-check-r2/logs/bats-targeted.log`, `fact-check-r2/logs/probe-mut2.log`

---

## Claim 36a: Commit 65007bf8: "probed: a forged brief blob read back as naming another branch"

**Location:** commit 65007bf8 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read-back and the call sites at HEAD; row citations in this message are settled (override rows 643, 645) and not re-verdicted.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r1 Claim 25. The test asserts the read-back: `[ "$(git cat-file blob "$o" | grep Branch)" = "Branch: feat/y" ]` (`test/scripts/build-loop-check.bats:1879`), passing in L1.

**Evidence:** `test/scripts/build-loop-check.bats:1877-1880`, `fact-check-r1/logs/L1-bats.log`

---

## Claim 36b: Commit 65007bf8: "store_check re-hashes main's commit and every tree and blob of its tree in gate_start (refuse state objects), and per brief the tip's commit, its tree and the merge's tree"

**Location:** commit 65007bf8 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against HEAD's code. "the merge's tree" means every object of it (Claim 15). It does not establish "untested" for the removed refusals, which is history.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=—
**Replicate annotations:** r1: "row citations in this message are settled (override rows 643, 645) and not re-verdicted".

Carried from r2 Claim 34. The changes are present at HEAD: `store_check "$MAIN_SHA"` in gate_start (`scripts/build-loop.sh:858`) and `store_check "$sha" "$tree"` (`:916`).

**Evidence:** `git log -1 65007bf8`, `scripts/build-loop.sh:858`, `scripts/build-loop.sh:916`

---

## Claim 36c: Commit 65007bf8: "status_fields gives --status's line as values (rows 496, 512)"

**Location:** commit 65007bf8 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row citations. It does not affect the code.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1 (Scope of its Claim 25, not verdicted): "row citations in this message are settled (override rows 643, 645) and not re-verdicted" · r2: "The Notes' 'Verdict values for --merge wait for U3a2' is a plan fact, matched by `docs/working/plan-build-loop-handoff.md:318`."

Carried from r3 Claim 35. Override row 496 is "a `status_fields` array with status_line as its printer" (`docs/reviews/override-log.md:496`). Row 512 is "U3's `--merge` needs TIP, TREE and the verdict as values" (`:512`), which this branch did not do. Commit 83f75281 records "row 512's values moved to U3a2", and so does the plan's as-built note. The citation should be row 496 alone.

**Evidence:** `docs/reviews/override-log.md:496`, `docs/reviews/override-log.md:512`, `docs/reviews/override-log.md:643`

---

## Claim 36d: Commit 65007bf8: "so check_line reads the brief once: the branch and brief re-reads and their two untested refusals go"

**Location:** commit 65007bf8 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how many times check_line reads the brief's blob. It does not reach the second-copy defence, which covers every one of these reads (Claim 16).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r2: "It does not establish 'untested' for the removed refusals, which is history."

Carried from r3 Claim 36. The re-reads after status are gone (Claim 5a). status_fields itself still reads the brief's blob twice: check_brief's brief_fields in `$(...)` (`out="$(check_brief "$a")"`, `scripts/build-loop.sh:520`) and the in-shell `brief_fields "$a"` (`:527`). For the brief's own changed path, own_blob reads it twice more (`git cat-file blob "$MAIN_SHA:$1"`, `:670` and `:672`). Accurate as "no re-read after status"; not as "once".

**Evidence:** `scripts/build-loop.sh:516-527`, `scripts/build-loop.sh:666-673`, `scripts/lib/dev-cycle-read.sh:440`

---

## Claim 36e: Commit 65007bf8: "gate_start holds the gate's startup order and the real-repo vs gate-repo rule in one place"

**Location:** commit 65007bf8 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against HEAD's code. It does not establish "untested" for the removed refusals, which is history.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r2 Claim 34. status_fields (`scripts/build-loop.sh:516`) and gate_start's comment (`:844-853`) are present at HEAD.

**Evidence:** `git log -1 65007bf8`, `scripts/build-loop.sh:516`, `scripts/build-loop.sh:844-861`

---

## Claim 37a: Commit 83f75281: "the per-brief refusal says 'the tip of BRANCH'; status_fields empties BRIEF and states STATUS's shapes; ... the A15 call log pins store_check before the first blob read"

**Location:** commit 83f75281 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these claims as they stand at HEAD; the checked-file skip that commit introduced was replaced by d10cfba8 (its message, not this one, is the current account).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r1 Claim 24. `refuse $a: an object of the tip of $br ...` (`scripts/build-loop.sh:916`); `STATUS=(); BRIEF=()` (`:518`); A15 as Claim 35.

**Evidence:** `scripts/build-loop.sh:505-518`, `scripts/build-loop.sh:916`, `fact-check-r1/logs/L1-bats.log`

---

## Claim 37b: Commit 83f75281: "A2: the NR == FNR filter over an empty checked file read stdin as the first file; FILENAME is tested, and perl fails when it reads no object."

**Location:** commit 83f75281 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the FILENAME filter and the perl `$n` guard at HEAD.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

Carried from r2 Claim 35. Both filters test `FILENAME != "-"` (`scripts/build-loop.sh:628`, `:644`), and perl ends `exit($n ? 0 : 1)` (`:636`).

**Evidence:** `git log -1 83f75281`, `scripts/build-loop.sh:628`, `scripts/build-loop.sh:636`, `scripts/build-loop.sh:644`

---

## Claim 37c: Commit 83f75281 Notes: "a legitimately duplicated object (overlapping packs) now refuses --check; /workspace's 21,742 packed ids have none."

**Location:** commit 83f75281 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "none" for /workspace's store today. It does not re-count the 21,742 figure, and the store has changed since.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=— · single-replicate detection
**Replicate annotations:** r3 (Scope of its Claim 37, not verdicted): "does not re-measure the '21,742 packed ids' figure for /workspace".

Carried from r2 Claim 35. L6 ran store_check's own listing over the shared store and printed `duplicate ids in store: 0`.

**Evidence:** `fact-check-r2/logs/probe-perf.log`

---

## Claim 37d: Commit 83f75281: "the state gate refuses objects/info/alternates" / "git repack -ad clears it"

**Location:** commit 83f75281 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the alternates refusal and the repack-clears case in the tests.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** none

Carried from r3 Claim 37. The re-hash test runs `git repack -adq` after a second copy and then passes (L1); the alternates refusal is in state_gate's loop (`scripts/build-loop.sh:307`).

**Evidence:** `scripts/build-loop.sh:307`, `test/scripts/build-loop-check.bats:1873-1875`, `fact-check-r3/logs/bats-targeted.log`

---

## Claim 38: Commit d10cfba8: "store_check now skips main's ids (kept by gate_start) and judges main's plus this call's ids only; a two-brief test in both orders. B2: packs and loose files are listed with find -L inside the store (dot-named packs, linked fan-out dirs), and harden pins core.multiPackIndex=false. ... GATE renamed GATED."

**Location:** commit d10cfba8 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed change against the code and L1; does not cover "Comments, plan note and test comments corrected", for which Claim 2b shows one plan phrase still out of date.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish the midx route the pin is meant to close (Claim 10b)" · r3: "does not cover the confidence or notes lines, which are judgment".

Carried from r1 Claim 23 (most specific Scope). Quoted in Claims 3a, 10a, 15; `GATED` at `scripts/build-loop.sh:341-349` and no `GATE=` assignment remains (paraphrased — no quote available because the claim covers absence: grep `\bGATE\b=` finds none). Two-brief test at `test/scripts/build-loop-check.bats:1894-1897`.

**Evidence:** `scripts/build-loop.sh:273`, `scripts/build-loop.sh:341-349`, `scripts/build-loop.sh:628-644`, `test/scripts/build-loop-check.bats:1894-1897`, `fact-check-r1/logs/L1-bats.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 34b** (`test/scripts/build-loop-check.bats:1900`): the title says the test covers "no multi-pack-index route", but the body has no midx case and passes with `core.multiPackIndex=false` removed from harden (r2 L4). Drop the phrase or point to the config-pairs test (`:1685`).

### Stale
- **Claim 2b** (`docs/working/plan-build-loop-handoff.md:317`): "skipping ids already checked" is i1's cumulative skip; since d10cfba8 a per-brief call skips only main's ids. Say "skipping main's ids".

### Mostly Accurate
- **Claim 4b** (`docs/working/plan-build-loop-handoff.md:317`): the not-re-hashed list omits check_brief's `git log -G` walk of main's history (can only cause a skip).
- **Claim 20** (`scripts/build-loop.sh:612-616`): the same omission in store_check's "Not checked" list.
- **Claim 25a** (`scripts/build-loop.sh:844-850`): "each refusal a refuse state line and exit 2" does not hold for a failed mktemp (exit 1, no line, header `:221`).
- **Claim 36c** (commit 65007bf8): cites row 512 for status_fields; row 512 is TIP/TREE/verdict values, moved to U3a2.
- **Claim 36d** (commit 65007bf8): "check_line reads the brief once"; status_fields still reads the blob twice and own_blob twice more.

### Unverifiable
- **Claim 10b** (`scripts/build-loop.sh:262-263`): "a second route to an object, past store_check's listing" not reproduced on git 2.39.5 (r2 L3, r3 L4); would need a midx-only read path on some git version.

## Escalations

- **E1:** `scripts/lib/dev-cycle-read.sh:462-464` (also `scripts/build-loop.sh:612-616`, `docs/working/plan-build-loop-handoff.md:317`). Whether check_brief's unchecked `git log -G` history walk needs a row beyond override row 638. r3: "is the security critic's call"; r2: "whether check_brief's unchecked -G history reads matter. No verdict depends on them". Raised by r2 (Out of scope) and r3 (Out of scope). Merged Claims 4b, 20. Addressee: security-reviewer.
- **E2:** `scripts/build-loop.sh:262-263`. Whether any git version reads a multi-pack-index pack past the .idx listing (whether the pin is needed on other git versions). r3: "So is [the security critic's call] whether any git version reads a multi-pack-index pack past the .idx listing (Claim 11). Versions other than git 2.39.5 were not tried." r2: "whether the midx pin is needed on other git versions (Claim 10b)". r1: "Git versions other than the installed one were not tested." Raised by r1, r2 and r3 (Out of scope). Merged Claim 10b. Addressee: security-reviewer.
- **E3:** `scripts/build-loop.sh:612-616`. r1: "whether the race residual and the history residual matter for a decision is for the security critic (settled rows 638, 646)." Raised by r1 (Out of scope). Merged Claims 4a, 20. Addressee: security-reviewer.

All three replicates' `Escalate:` lines are non-blocking: r1 "None blocking. Both findings are wording-only", r2 "None blocking", r3 "None blocking". No claim prose carried a further routing note.

## Verdict stability

- Total clusters: 56. That is 46 multi-replicate clusters plus 10 single-replicate detections (Claims 5b, 8b, 9, 21, 22a, 36a, 36e, 37a, 37c, 37d).
- Clusters where all reporting replicates agreed: 46 of 56. Single-replicate clusters count as agreed trivially. Among the 46 multi-replicate clusters, 36 agreed.
- Disagreeing clusters (10):
  - Claim 2a (plan:317, call sites): r1=Stale (compound; carried by 2b) · r2=Mostly accurate (compound; carried by 2b) · r3=Verified → Verified
  - Claim 2b (plan:317, skip wording): r1=Stale (compound) · r2=Mostly accurate (compound) · r3=Mostly accurate → Stale
  - Claim 4b (plan:317, not-re-hashed list): r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate → Mostly accurate
  - Claim 10b (build-loop.sh:262-263, midx rationale): r1=Verified (compound) · r2=Unverifiable · r3=Verified (compound) → Unverifiable
  - Claim 20 (build-loop.sh:612-616, Not checked): r1=— · r2=Verified · r3=Mostly accurate → Mostly accurate
  - Claim 25a (build-loop.sh:844-850, gate_start order): r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate → Mostly accurate
  - Claim 34a (bats:1900, dot/linked): r1=Mostly accurate (compound; carried by 34b) · r2=Verified · r3=Verified → Verified
  - Claim 34b (bats:1900, midx phrase): r1=Mostly accurate (compound) · r2=Incorrect · r3=Incorrect → Incorrect
  - Claim 36c (65007bf8, rows 496/512): r1=— · r2=Verified (compound) · r3=Mostly accurate → Mostly accurate
  - Claim 36d (65007bf8, reads the brief once): r1=— · r2=Verified (compound) · r3=Mostly accurate → Mostly accurate
- Agreement rate: 46/56 = 82.1% over all clusters, and 36/46 = 78.3% over multi-replicate clusters. Claims 2a and 34a disagree only through a sibling's compound verdict; excluding those two, 36/44 = 81.8% of multi-replicate clusters agreed.
- In 4b, 20, 25a, 36c and 36d the severe verdict is r3's alone, and in each the other reporting replicates' annotations name the same residue (r2 on check_brief's walk; r1/r2 on mktemp) while verdicting Verified. 2b differs on Stale vs Mostly accurate over the same finding; 34b on Incorrect vs Mostly accurate over the same finding.

## Goal-Alignment Note

**Success criterion (restated verbatim):** "one canonical merged report ... the standard code-fact-check format ... one `## Claim N:` section per cluster at the finest granularity any replicate used, each with the seven mandatory fields plus `**Replicate verdicts:**` and `**Replicate annotations:**` (union), a `## Escalations` section, a `## Verdict stability` section."
**Answered:** Yes. 56 clusters: 48 Verified, 5 Mostly accurate, 1 Stale, 1 Incorrect, 1 Unverifiable.
**Out of scope:** re-verifying any claim (mechanical collation only, no new evidence).
**Escalate:** nothing blocking; three non-blocking routing entries in `## Escalations` (E1-E3, all to security-reviewer).
**Decisions made in the merge:** (1) Claims 2a and 34a carry a sibling compound verdict (r1 Stale and r2 Mostly accurate on 2a; r1 Mostly accurate on 34a) whose replicate's own prose names the sibling part as carrying it; recorded as `(compound; carried by …)` and not allowed to set the verdict, per decision 033 rule 2 and the U2a1 merge precedent. A strict most-severe-wins reading would make 2a Stale and 34a Mostly accurate (2 Stale, 6 Mostly accurate, 46 Verified). (2) Where one replicate's compound claim covered parts another replicate did not verdict at all (r1's 4 and 25, r2's 9 and 34, r1/r2/r3's 83f75281 claims), the uncovered parts became their own single-replicate rows (5b, 8b, 36a, 36e, 37a, 37c, 37d). (3) A does-not-establish clause that touches another cluster's subject is recorded in that cluster's annotations, attributed and marked "not verdicted", with that replicate's verdict left `—` (Claims 22a, 36c, 37c).

## Submitted Claims

## Claim 57: "`core.multiPackIndex=false` in harden reaches every git call, gate_git included, and closes the midx route past the .idx listing."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:271-278`
**Type:** Invariant / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git process a `--check` of one brief starts on git 2.39.5 (57 calls, 7 of them gate_git) and the critic's swapped-OOFF midx forgery; does not establish behavior under a caller who passes its own later `-c core.multiPackIndex=true` or a zero-padded GIT_CONFIG_COUNT (the comment at `:268-269` names that as trusted), nor other midx corruptions than an OOFF swap.

harden exports the pair as environment config, which every child git inherits:

```bash
# scripts/build-loop.sh:271-277
harden() {
  local c="${GIT_CONFIG_COUNT:-0}" kv
  for kv in core.useReplaceRefs=false ... core.commitGraph=false core.multiPackIndex=false; do
    export "GIT_CONFIG_KEY_$c=${kv%%=*}" "GIT_CONFIG_VALUE_$c=${kv#*=}"; c=$((c + 1))
  done
  export GIT_CONFIG_COUNT="$c"
}
harden
```

gate_git runs git under `GATE_ENV`, which unsets the repo-local variables except the ones `callervar` keeps, and GIT_CONFIG_COUNT is one of those; the GIT_CONFIG_KEY_n/VALUE_n variables are not in `git rev-parse --local-env-vars`'s list (executed here: it prints GIT_CONFIG_COUNT but no KEY/VALUE names), so they pass through:

```bash
# scripts/build-loop.sh:575-578
callervar() { [[ "$1" == GIT_CONFIG_PARAMETERS || "$1" == GIT_CONFIG_COUNT || "$1" == GIT_NO_REPLACE_OBJECTS ]]; }
gate_repo() {
  local fmt v
  GATE_ENV=(env)
  for v in $(git rev-parse --local-env-vars); do callervar "$v" || GATE_ENV+=(-u "$v"); done
```

Executed (`p1.log`, section "[C59] baseline"): "calls: 57; calls lacking core.multiPackIndex=false: 0" and "gate_git calls (GIT_DIR set) with the pin: 7 of 7". The only git invocations before line 278 are in the sourced lib's top level and `scrub_reexec`, which re-execs the script; the shim log shows none of the logged calls without the pin, so none reaches git unhardened.

The critic's mechanism reproduces: after `git multi-pack-index write` and swapping the OOFF entries of the brief blob G and a same-size forged blob F, each pack `.idx` still lists G once ("pack .idx listings of G: 1"), so store_check's per-`.idx` listing (`:641-644`) sees no second copy; `git -c core.multiPackIndex=true cat-file blob main:B` prints "Branch: feat/y" (forged) and with `=false` prints "Branch: feat/x" (genuine). The d10cfba8 gate on that store returns `ok ... path ... A work-feat-x.txt` with 0 calls lacking the pin, i.e. it read the genuine brief (feat/x). (This differs from the earlier replicates, which deleted a pack's `.idx`; the route needs a midx whose OID-to-offset map disagrees with the `.idx`, not a missing `.idx`.) A mutant with the pin removed from harden refused at startup ("refuse state objects ...", exit 2): without the pin store_check's own `cat-file --batch` also goes through the midx and the re-hash of G's forged bytes fails, so the forgery fails closed either way in this scenario; the pin's effect is that every read takes the `.idx` route the listing inspects.

**Evidence:** `scripts/build-loop.sh:259-278`, `scripts/build-loop.sh:575-594`, `scripts/build-loop.sh:641-644`, `/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-f/stage25/p1.log`, `/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-f/stage25/probes/p1.sh`

---

## Claim 58: "a dot-named forged pack holding a second copy of main's object is refused at startup."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:641-644`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a pack named `.dotcopy.pack`/`.dotcopy.idx` directly in `objects/pack` holding second copies of all of main's objects, refused by gate_start's store_check; does not establish refusal for packs reached by other name shapes (e.g. a newline in the name, the subject of the critic's separate `nl.sh` probe) or for a second copy of a history-only object, which store_check does not check.

The listing takes every `*.idx` in `pack/`, and find's `-name` glob matches a leading dot, then counts each of main's ids across all `.idx` files and loose objects:

```bash
# scripts/build-loop.sh:641-644
  { (cd "$o" && find -L pack -mindepth 1 -maxdepth 1 -name '*.idx' ! -type d) > "$GATE_TMP/idx" || exit 1
    while IFS= read -r r; do git show-index --object-format="$fmt" < "$o/$r" | awk '{ print $2 }' || exit 1; done < "$GATE_TMP/idx"
    ...
  } | awk 'FILENAME != "-" { want[$0]; next } ($0 in want) && n[$0]++ { bad = 1 } END { exit bad }' "$GATE_TMP/main" "$GATE_TMP/call" -
```

gate_start turns a failure into the startup refusal:

```bash
# scripts/build-loop.sh:858-859
  store_check "$MAIN_SHA" && mv "$GATE_TMP/call" "$GATE_TMP/main" \
    || { echo "refuse state objects: the default branch's commit or an object of its tree does not hash to its id, has a second copy in the object store, or could not be read"; exit 2; }
```

Executed (`p1.log`, section "[C58]"): with `.dotcopy.idx`/`.dotcopy.pack` copied from the real pack, `git count-objects -v` reports "packs: 2" (git opens the dot-named pack), and the gate printed the "refuse state objects" line and exited 2; after removing it, the same command printed `ok`. The copy held genuine bytes; the refusal rests on the duplicate count, which does not read the bytes, so a forged copy under the same id is refused by the same line (the critic's `dot.sh` log shows a forged-bytes variant also refused).

**Evidence:** `scripts/build-loop.sh:618-644`, `scripts/build-loop.sh:854-861`, `/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-f/stage25/p1.log`

---

## Claim 59: "check_line now reads the brief once, through status_fields, and takes branch, sha and Paths from STATUS/BRIEF ... removes main's branch and brief re-reads per brief, a small per-brief saving."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:875-927`
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the git reads one non-self-merge brief costs in `--check` at d10cfba8 vs main d5736445 on one fixture, and the self-merge re-read removal by reading; does not establish wall-clock saving, nor the self-merge path executed.

The STATUS/BRIEF part holds: check_line calls status_fields in its own shell and takes its fields from STATUS, and read_paths takes Paths from BRIEF with no new read:

```bash
# scripts/build-loop.sh:880-882
  status_fields "$a"
  [[ "${STATUS[line]}" == "ok "* ]] || { echo "${STATUS[line]}"; return; }
  st="${STATUS[state]}"; pol="${STATUS[policy]}"; br="${STATUS[branch]}"; sha="${STATUS[sha]}"
# scripts/build-loop.sh:927
  [[ "$pol" != self-merge ]] || read_paths
```

Two parts need tightening. (1) "reads the brief once" is not what runs: status_fields reads the brief blob twice, once inside `check_brief` (in a `$(...)`, which calls brief_fields at `scripts/lib/dev-cycle-read.sh:440`) and once in its own brief_fields call:

```bash
# scripts/build-loop.sh:520, 527
  out="$(check_brief "$a")"
  brief_fields "$a" || { STATUS[line]="skip $a: the brief is not read"; return; }
```

Executed: the shim log shows 3 `cat-file blob MAIN:docs/working/briefs/...` calls for one brief at d10cfba8 (open_shared's at startup, then check_brief's and status_fields'), and also 3 on main for the same review-policy brief. (2) The removed brief re-read was per self-merge brief only, not per brief: on main it sat inside `if [[ "$pol" == self-merge ]]; then if brief_fields "$a"; then read_paths; ...` (main `scripts/build-loop.sh`, check_line). The branch re-read was per brief and is gone: the shim logs show `rev-list --count MAIN..TIP` twice on main (status_line's check_branch and check_line's own) and once at d10cfba8. So the per-brief saving is one check_branch (show-ref, rev-parse, rev-list --count, log) for every brief, plus one brief read for a self-merge brief; "a small per-brief saving" is right in size.

**Evidence:** `scripts/build-loop.sh:516-558`, `scripts/build-loop.sh:875-927`, `scripts/lib/dev-cycle-read.sh:423-460`, `scripts/lib/dev-cycle-read.sh:391-421`, `/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-f/stage25/p1.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 59** (`scripts/build-loop.sh:875-927`): status_fields still reads the brief blob twice (check_brief and brief_fields); the removed brief re-read was self-merge only; the removed check_branch is the every-brief saving.
