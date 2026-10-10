# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u3a1`, branch `feat/build-loop-u3a1`)
**Scope:** full branch, `main...HEAD` (base d5736445) without docs/reviews: `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, `docs/working/plan-build-loop-handoff.md` step 7 (the U3a1 and U3a2 bullets), and the messages of commits 65007bf8, 83f75281 and d10cfba8. `scripts/lib/dev-cycle-read.sh` was read as context only.
**Commit:** d10cfba8
**Replication:** k=3, replicate r2 (final confirming pass)
**Checked:** 2026-10-10
**Total claims checked:** 38
**Summary:** 35 verified, 1 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) first. No entry concerns git object stores, pack indexes, bats titles or awk, and no claim below matches a logged pattern.

Execution logs are all under `/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-f/fact-check-r2/`, called S below. Per the brief, nothing was written in the worktree except this report.

| Log | Command | cwd | Exit | Started (UTC) |
|---|---|---|---|---|
| L1 `logs/bats-targeted.log` | `TMPDIR=$S/tmp LC_ALL=C timeout 900 bats -f 're-hashes what it reads\|second-copy scan\|SHA-256 repository\|state gate before resolve_main\|every git call --check makes\|state gate refuses each planted\|clean merge is ok\|missing object: a missing tip\|self-merge brief unless' test/scripts/build-loop-check.bats` | worktree | 0 (9/9 ok) | 2026-10-10T19:01:35Z |
| L2 `logs/probe-status.log` | `timeout 120 bash $S/probe-status.sh`. It runs `--status` with main's script+lib (from `git show main:`) and HEAD's on one fixture of 12 briefs: absent branch, working ahead with Dispatched and self-merge, done at ahead 0, stopped with reason, ready, no Branch:, bad Dispatched:, bad marker, two sharing a branch, new, not a brief. It then compares stdout and stderr byte for byte (`cmp`) | a `mktemp -d` (the script refuses to run outside it) | 0 | 2026-10-10T19:02:05Z |
| L3 `logs/probe-midx.log`, `logs/probe-midx2.log` | `timeout 60 bash $S/probe-midx.sh`: one pack, `git multi-pack-index write`, the pack's .idx moved away, then `cat-file -t` under `core.multiPackIndex=true` and `=false`. The second log is the same script rerun with full output and rc | a `mktemp -d` | 0 | 2026-10-10T19:02:16Z (rerun right after, not stamped separately) |
| L4 `logs/probe-mut.log` | `timeout 600 bash $S/probe-mut.sh`. Mutation M1 on a copy of scripts/ and test/: `core.multiPackIndex=false` removed from harden. Then `bats -f 'second-copy scan\|every git call --check makes'` | a `mktemp -d` under `$S/tmp` | 0 (config-pairs test: not ok; second-copy test: ok) | 2026-10-10T19:02:31Z |
| L5 `logs/probe-mut2.log` | `timeout 600 bash $S/probe-mut2.sh`. M2: the loose listing's `find -L` becomes `find -P`, then the second-copy test. M3: gate_start's store_check moved after `reader_settings; read_settings; never_res; open_shared`, then the A15 test | a `mktemp -d` under `$S/tmp` | 0 (M2: not ok; M3: not ok, "store_check at line 29, first blob read at line 25") | 2026-10-10T19:02:52Z |
| L6 `logs/probe-perf.log` | `timeout 120 bash $S/probe-perf.sh`. Read-only, on the worktree's main (d5736445): object count and bytes of main's commit+tree, store_check's batch+perl re-hash timed, and the duplicate scan over the whole shared store | worktree | 0 | 2026-10-10T19:03:47Z |

Probe repositories lived only under `$BATS_TEST_TMPDIR` or a `mktemp -d`, and every probe ran under `timeout`. No process was left running.

---

## Claim 1: "main's commit and every tree and blob of its tree (3,691 objects, 68 MB here: 0.3 s)"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the object count, total size and re-hash time of store_check's batch+perl over main's commit and tree on this machine today. It does not establish the full store_check time including the duplicate scan, or the figures on another host.
**Legibility-target:** for-orchestrator-synthesis

L6 printed `objects: 3693`, `bytes: 67853429` and `rehash seconds: 0.24` for main at d5736445. That is two more objects than the plan's 3,691 because main has moved on, about 68 MB, and under 0.3 s. The pipeline is store_check's own (quoted in Claim 15).

**Evidence:** `docs/working/plan-build-loop-handoff.md:317`, `scripts/build-loop.sh:625-636`, `$S/logs/probe-perf.log`

---

## Claim 2: "store_check runs once for main in gate_start (a mismatch is `refuse state objects`, exit 2) and per brief for the tip and the merge's tree, skipping ids already checked"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call sites and which ids the per-brief batch skips. It does not establish anything about the race window (Claim 19).
**Legibility-target:** for-author

The call sites match:

```bash
# scripts/build-loop.sh:858-859
  store_check "$MAIN_SHA" && mv "$GATE_TMP/call" "$GATE_TMP/main" \
    || { echo "refuse state objects: ..."; exit 2; }
# scripts/build-loop.sh:916
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of the tip of $br ..."; return; fi
```

"skipping ids already checked" is the i1 wording. At i1 every call appended to `$GATE_TMP/checked`, so a later brief also skipped the ids an earlier brief had checked. After d10cfba8 the skip set is `$GATE_TMP/main` alone:

```bash
# scripts/build-loop.sh:628
    done; } | awk 'FILENAME != "-" { seen[$0]; next } !($0 in seen) { seen[$0]; print }' "$GATE_TMP/main" - | git cat-file --batch \
```

Each call's output goes to `> "$GATE_TMP/call"` (`:636`), which overwrites the file. So an id that an earlier brief checked is read and re-hashed again. A more precise wording would be "skipping main's ids, checked at startup".

**Evidence:** `docs/working/plan-build-loop-handoff.md:317`, `scripts/build-loop.sh:618-645`, `scripts/build-loop.sh:858-859`, `scripts/build-loop.sh:916`; i1 code via `git show 83f75281:scripts/build-loop.sh` (store_check: `touch "$GATE_TMP/checked"`, `>> "$GATE_TMP/checked"`)

---

## Claim 3: "it also refuses an id of main's or of that call with a second copy in the store, listed as git opens them (links, dot-named packs ...), harden switches off the multi-pack-index, and the state gate refuses `objects/info/alternates`"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four mechanisms as present and exercised: the duplicate scan over main's and the call's ids, `find -L` with dot-named packs, the harden pin and the alternates refusal. It does not establish that git 2.39.5 has a midx route the pin closes (Claim 10b).
**Legibility-target:** for-orchestrator-synthesis

The scan judges the ids in `"$GATE_TMP/main" "$GATE_TMP/call"` (`scripts/build-loop.sh:644`). It lists stores with `find -L pack ... -name '*.idx'` and `find -L . -mindepth 2 -maxdepth 2` (`:641`, `:643`). harden carries `core.multiPackIndex=false` (`:273`). state_gate's file loop includes `objects/info/alternates` (`:307`). Executed results:

- L1: test 6 (second pack, loose+packed) is ok, and so is test 7 (a `.hidden` pack and a linked fan-out directory).
- L5 M2: with `find -P`, test 7 fails.
- L1: test 2 prints `refuse state objects/info/alternates: present and not an empty file`.
- L1: the config-pairs test shows the pin on every call.

**Evidence:** `scripts/build-loop.sh:273`, `scripts/build-loop.sh:307`, `scripts/build-loop.sh:641-644`, `$S/logs/bats-targeted.log`, `$S/logs/probe-mut2.log`

---

## Claim 4: "One brief's refusal does not carry to the next (i2 architecture 1)."

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the second-copy refusal of one brief's tip blob in a two-brief run, in both orders. It does not establish anything about a refusal of main's objects, which exits the run by design.
**Legibility-target:** for-orchestrator-synthesis

The per-call output is `> "$GATE_TMP/call"` (`scripts/build-loop.sh:636`), which overwrites the file, and the scan's want-set is `"$GATE_TMP/main" "$GATE_TMP/call"` (`:644`). So a refusing brief's ids are not in the next call's sets. Test 6's last lines (`test/scripts/build-loop-check.bats:1894-1897`) run `chk "$y" "$B"` and `chk "$B" "$y"` and expect `ok $y` in both orders. In L1 that test is ok.

**Evidence:** `scripts/build-loop.sh:636`, `scripts/build-loop.sh:644`, `test/scripts/build-loop-check.bats:1894-1897`, `$S/logs/bats-targeted.log`

---

## Claim 5: "Main's objects are re-hashed once per run ... Not re-hashed (Q-103 residual): the tip's parent, the commits check_branch counts, merge bases."

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named history reads and the single startup re-hash of main. It does not establish that the list is exhaustive. check_brief's `git log -G'^Status: '` also reads main's history blobs (diffs). Its result (`c`) is discarded by status_fields (`read -r _ _ st _`), so it does not change a verdict.
**Legibility-target:** for-orchestrator-synthesis

The history reads named are all real:

- marker_kind reads the parent's tree: `git rev-parse --verify "${p[1]}^{tree}"` (`scripts/build-loop.sh:493`).
- check_branch counts commits with `git rev-list --count "$MAIN_SHA..$sha"` (`scripts/lib/dev-cycle-read.sh:488`).
- merge_result reads merge bases with `gate_git merge-base --all` (`scripts/build-loop.sh:652`).

None of these ids is passed to store_check, which receives only `"$MAIN_SHA"` and `"$sha" "$tree"`. The startup re-hash happens once, in gate_start.

**Evidence:** `scripts/build-loop.sh:493`, `scripts/build-loop.sh:652`, `scripts/build-loop.sh:858`, `scripts/build-loop.sh:916`, `scripts/lib/dev-cycle-read.sh:462`, `scripts/lib/dev-cycle-read.sh:488`

---

## Claim 6: "the branch and brief re-reads went with their refusals, so U3a2's shim reaches only the CAS" / "the failed brief re-read row 625 named is gone (U3a1)"

**Location:** `docs/working/plan-build-loop-handoff.md:317-318`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the removal of check_line's `check_branch` re-read, its `brief_fields` re-read and the matching refusals and srules branch. It does not establish what U3a2's shim will do.
**Legibility-target:** for-orchestrator-synthesis

check_line now reads `status_fields "$a"` once and takes `STATUS[...]` (`scripts/build-loop.sh:880-885`). The S rules' inputs are `[[ "$pol" != self-merge ]] || read_paths` (`:927`). `grep` finds no `moved or could not be read again` and no `could not be read again from the default branch` in the file (paraphrased — no quote available because the claim covers the absence of code; the diff's removed lines are at the old `:366-369`, `:401-403` and srules' `PATHS_WHY != unread` line).

**Evidence:** `scripts/build-loop.sh:875-939`, `scripts/build-loop.sh:746-759`, `/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-final.diff`

---

## Claim 7: --help: the state gate ... "objects/info/alternates (another object store)" ... "then the gate's own merge repository not set up ... then main's commit, or a tree or blob of its tree, that does not hash to its id, has a second copy ... or cannot be read ('refuse state objects: WHY'; every file the gate reads from main is one). Each finding prints 'refuse state WHAT: WHY' and exits 2 before the settings or any brief is read."

**Location:** `scripts/build-loop.sh:97-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order state_gate, then default_gate, then gate_repo, then store_check, then settings and briefs; exit 2 for each finding; and that main's files are read as `MAIN_SHA:PATH` blobs of the checked tree. It does not establish that history blobs are checked (Claim 5's residue), and does not cover mktemp failure, which is exit 1 with no line and is documented separately at `:220-221`.
**Legibility-target:** for-orchestrator-synthesis

The order is in the code:

```bash
# scripts/build-loop.sh:855-860
  default_gate || exit 2
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
  gate_repo || { echo "refuse state gate: ..."; exit 2; }
  store_check "$MAIN_SHA" && mv "$GATE_TMP/call" "$GATE_TMP/main" \
    || { echo "refuse state objects: ..."; exit 2; }
  reader_settings; read_settings; never_res; open_shared
```

state_gate runs first at top level (`:342`).

Main's files are read through main's tree. brief_fields uses `git cat-file blob "$MAIN_SHA:$1"` (`scripts/lib/dev-cycle-read.sh:399`). main_file uses `git cat-file blob "$MAIN_SHA:$f"` (`:560`). own_blob does the same (`scripts/build-loop.sh:670`).

Executed: in L5, M3 moved store_check after the settings and open-brief reads, and the A15 test failed ("store_check at line 29, first blob read at line 25"). Unmutated, it passes (L1). Test 6 expects exactly `$OBJS` with exit 2, so no brief line is printed.

**Evidence:** `scripts/build-loop.sh:97-109`, `scripts/build-loop.sh:342`, `scripts/build-loop.sh:854-861`, `scripts/lib/dev-cycle-read.sh:399`, `scripts/lib/dev-cycle-read.sh:560`, `$S/logs/bats-targeted.log`, `$S/logs/probe-mut2.log`

---

## Claim 8: --help per-brief refusal: "an object of the tip of BRANCH or of the merge does not hash to its id, has a second copy in the object store, or could not be read": "the tip's commit, or a tree or blob of its tree or of TREE (gitlinks aside), read back and re-hashed"

**Location:** `scripts/build-loop.sh:126-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message text, the REVs passed and the gitlink filter. It does not establish re-reading of ids shared with main per brief: they are skipped (re-hashed at startup), which the help leaves implicit.
**Legibility-target:** for-orchestrator-synthesis

The REVs come from `store_check "$sha" "$tree"` (`:916`). Gitlinks are filtered by `awk '$1 != "commit" { print $2 }'` (`:627`). In L1, test 6's tip cases (a rewritten tip blob, then a loose second copy) both print exactly `refuse $B: an object of the tip of feat/x or of the merge does not hash to its id, has a second copy in the object store, or could not be read`.

**Evidence:** `scripts/build-loop.sh:126-132`, `scripts/build-loop.sh:627`, `scripts/build-loop.sh:916`, `test/scripts/build-loop-check.bats:1886-1892`, `$S/logs/bats-targeted.log`

---

## Claim 9: --help: "After an ok line, a K of N refusal or a checkout refusal, one line per path" and the floor is "not run when the verdict already refuses for the checkout"

**Location:** `scripts/build-loop.sh:165`, `scripts/build-loop.sh:192-193`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_line's final print and srules' `$5` guard now that the brief re-read refusal is gone. It does not establish the floor walk's own behaviour.
**Legibility-target:** for-orchestrator-synthesis

check_line ends with `if [[ -n "$co" ]]; then echo "$co"; elif ... fi` then `printf '%s\n' "${rows[@]}"` (`:937-938`). srules runs the floor only when `[[ -z "$5" ]] && floor ...` (`:749`), and `$5` is `"$co"` (`:934`). `co` is set only by checkout_gate (`:924`).

**Evidence:** `scripts/build-loop.sh:746-759`, `scripts/build-loop.sh:924-938`

---

## Claim 10a: harden: "no multi-pack-index" (the pair is set for every git call, gate_git's included)

**Location:** `scripts/build-loop.sh:262-263`, `scripts/build-loop.sh:273`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pair's presence on every git call --check makes, including gate_git's. It does not establish what the pin prevents (Claim 10b).
**Legibility-target:** for-orchestrator-synthesis

`for kv in ... core.commitGraph=false core.multiPackIndex=false; do export "GIT_CONFIG_KEY_$c=..."` (`:273-274`). gate_repo unsets only the names that `git rev-parse --local-env-vars` lists, except `callervar` (`:579`). On git 2.39.5 that list includes GIT_CONFIG_COUNT (kept) but no GIT_CONFIG_KEY_n or GIT_CONFIG_VALUE_n (executed inline: `git rev-parse --local-env-vars`). So the pairs reach gate_git.

L1: the config-pairs test, whose shim logs every call, is ok. L4 M1, with the pin removed: that test fails with "a call without core.multiPackIndex=false".

**Evidence:** `scripts/build-loop.sh:271-278`, `scripts/build-loop.sh:575-585`, `test/scripts/build-loop-check.bats:1685`, `$S/logs/bats-targeted.log`, `$S/logs/probe-mut.log`

---

## Claim 10b: "(a second route to an object, past store_check's listing)"

**Location:** `scripts/build-loop.sh:262-263`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one candidate route on git 2.39.5: a pack the midx names whose .idx is absent. That route does not exist, because git then cannot read the object under either setting. It does not establish whether another route exists, or exists on other git versions.
**Legibility-target:** for-orchestrator-synthesis

L3 wrote a midx and moved the pack's .idx away. `cat-file -t` gave `error: packfile ... index unavailable` and `fatal: git cat-file: could not get object info` (rc 128) with `core.multiPackIndex=true`, and the same fatal with `=false`. The i2 fact-check's P4 probe found the same. The pin is harmless and makes every read take the same lookup. However, on this git version no object was found that is reachable only through the midx. Verifying the "second route" would need a midx-only read path on some git version, or a reference in git's source.

**Evidence:** `scripts/build-loop.sh:262-263`, `$S/logs/probe-midx.log`, `$S/logs/probe-midx2.log`, `docs/reviews/code-fact-check-report-build-loop-u3a1-i2.md:251`

---

## Claim 11: state_gate: "Files: an info/attributes, info/grafts, shallow or objects/info/alternates that is not absent or an empty regular file (each changes merges, history or the objects read)"

**Location:** `scripts/build-loop.sh:290-292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the alternates entry and its refusal line. It does not establish refusal of `GIT_ALTERNATE_OBJECT_DIRECTORIES` (a caller environment variable; checkout_gate refuses it only for self-merge briefs).
**Legibility-target:** for-orchestrator-synthesis

The loop is `for f in info/attributes info/grafts shallow objects/info/alternates; do` (`:307`). L1 test 2 (`test/scripts/build-loop-check.bats:1633-1640`) is ok, and its expected output includes `refuse state objects/info/alternates: present and not an empty file`.

**Evidence:** `scripts/build-loop.sh:307-310`, `test/scripts/build-loop-check.bats:1633-1640`, `$S/logs/bats-targeted.log`

---

## Claim 12: "--check refuses planted state before any git call reads an object (resolve_main does); gate_start runs the rest of its startup." / "GATED ... a mode that decides" / "gate_start calls it once main's objects are checked."

**Location:** `scripts/build-loop.sh:339-349`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both GATED sites (state_gate and the reader_settings skip) and reader_settings' place in gate_start. It does not establish anything about U3b's future modes.
**Legibility-target:** for-orchestrator-synthesis

The two sites are `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`:342`) and `[[ -n "$GATED" ]] || reader_settings` (`:349`). gate_start calls `reader_settings` after store_check (`:860`).

L1: the A15 test is ok. Its first `^{commit}` read follows the state gate's for-each-ref, and its `cat-file --batch` precedes the first `cat-file blob`. L5 M3 shows that test catches a reordering.

**Evidence:** `scripts/build-loop.sh:339-349`, `scripts/build-loop.sh:860`, `test/scripts/build-loop-check.bats:1949-1965`, `$S/logs/bats-targeted.log`, `$S/logs/probe-mut2.log`

---

## Claim 13: status_fields' comment: "STATUS[line] is the line --status prints. Only for an 'ok' line does STATUS hold its fields by name ... ('-' for a branch, sha or date there is none of, and an empty reason), and ahead ... (0 when absent); a skip line sets only line. BRIEF is emptied, then holds what brief_fields read ... (empty for a new brief or one check_brief skips) ... Call it in the caller's own shell."

**Location:** `scripts/build-loop.sh:505-514`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every return path of status_fields and BRIEF's state on each. It does not establish callers beyond check_line and status_line.
**Legibility-target:** for-orchestrator-synthesis

The function opens with `STATUS=(); BRIEF=()` (`:518`). Every non-ok return sets only `STATUS[line]` (`:521`, `:527-529`, `:533`, `:537-539`, `:546`, `:551`).

check_brief's non-ok lines are all `skip ...` (`scripts/lib/dev-cycle-read.sh:426-450`). Because it runs in `$(...)`, its own brief_fields call does not touch the caller's BRIEF. open_shared declares `local -A ... BRIEF=()` (`:505`).

The new-brief line sets `[branch]=- ... [sha]=- [ahead]=0 [date]=-` (`:524`). The full ok line sets all ten keys (`:556-557`). An absent branch gets `sha=- ahead=0 date=- loop=absent` (`:542`).

**Evidence:** `scripts/build-loop.sh:505-559`, `scripts/lib/dev-cycle-read.sh:423-466`, `scripts/lib/dev-cycle-read.sh:503-518`

---

## Claim 14: --status output is unchanged by the status_line to status_fields rewrite (brief claim 3; `status_line() { status_fields "$1"; echo "${STATUS[line]}"; }`)

**Location:** `scripts/build-loop.sh:556`, `scripts/build-loop.sh:559`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 12 briefs across every return path of status_fields: new, absent, working, done at ahead 0, stopped with reason, ready, the skips for a missing Branch:, a bad Dispatched:, a bad marker, a shared branch and not-a-brief. It does not cover the skips for an unlistable OPEN_SHARED or an unreadable count, which are not reachable without a fault shim.
**Legibility-target:** for-orchestrator-synthesis

The reason is now stored bare and printed with `$disp${reason:+ $reason}` (`:556`). Main's code stored `reason=" ${kind#stopped }"`, and marker_kind's stop reason matches `[!-~]...`, so it is never empty. In L2, `cmp` prints `IDENTICAL-stdout` and `IDENTICAL-stderr` for main's script and HEAD's, and both exit 0.

**Evidence:** `scripts/build-loop.sh:541-559`, `scripts/build-loop.sh:502`, `$S/logs/probe-status.log`, `$S/probe-status.sh`

---

## Claim 15: store_check: "Each REV (a commit or a tree), its root tree, and every tree and blob below it (a gitlink names another repository's commit) are read in one cat-file --batch and re-hashed by one perl, for sha1 or sha256, but an id in $GATE_TMP/main (main's, which gate_start's call leaves there) is not read again."

**Location:** `scripts/build-loop.sh:598-602`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the object set, the single batch and perl, both hash formats and the main-id skip. It does not establish that per-brief objects equal to main's ids are fresh at the time of the per-brief read (the race named in Claim 19).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:621-628
  case "$fmt" in sha1) alg=1 ;; sha256) alg=256 ;; *) return 1 ;; esac
  [[ -e "$GATE_TMP/main" ]] || : > "$GATE_TMP/main" || return 1
  ...
  { for r in "$@"; do
      printf '%s\n' "$r" "$r^{tree}"
      git ls-tree -r -t --full-tree --format='%(objecttype) %(objectname)' "$r" 2>/dev/null | awk '$1 != "commit" { print $2 }' || exit 1
    done; } | awk 'FILENAME != "-" { seen[$0]; next } !($0 in seen) { seen[$0]; print }' "$GATE_TMP/main" - | git cat-file --batch \
```

(excerpt ends :628; enclosing store_check continues to :645 — read). Perl recomputes `Digest::SHA->new($ENV{ALG})->add("$t $s\0", $b)` (`:633`). gate_start does `mv "$GATE_TMP/call" "$GATE_TMP/main"` (`:858`).

Executed in L1: test 6 (sha1 forged, missing and duplicated cases) is ok. The SHA-256 test, packed and with a second copy, is ok.

**Evidence:** `scripts/build-loop.sh:618-645`, `scripts/build-loop.sh:858`, `test/scripts/build-loop-check.bats:1717-1727`, `test/scripts/build-loop-check.bats:1867-1898`, `$S/logs/bats-targeted.log`

---

## Claim 16: "git can read either copy of an id, and two reads of one id (cat-file --batch here, cat-file blob MAIN:PATH in brief_fields) took different ones (U3a1 i1 security F1 ...)"

**Location:** `scripts/build-loop.sh:604-607`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the reference: the i1 security report records this divergence. It does not establish the divergence by a fresh reproduction in this pass (no forged-pack probe was run).
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/security-reviewer-review-2026-10-10-build-loop-u3a1.md:49` says: "When an object is forged inside a pack under a genuine id ... the tree-path read returns the forged bytes, while `cat-file --batch` by id returns bytes that re-hash to the genuine id". brief_fields' read is `git cat-file blob "$MAIN_SHA:$1"` (`scripts/lib/dev-cycle-read.sh:399`).

**Evidence:** `scripts/build-loop.sh:604-607`, `docs/reviews/security-reviewer-review-2026-10-10-build-loop-u3a1.md:43-61`, `scripts/lib/dev-cycle-read.sh:399`

---

## Claim 17: "The listing follows links and takes dot-named packs" / "From inside the store ..., with find -L: git opens a linked fan-out directory or pack, and a pack whose name starts with a dot, as it opens any other."

**Location:** `scripts/build-loop.sh:608-609`, `scripts/build-loop.sh:637-640`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `.hidden.idx` pack and a symlinked fan-out directory. It does not establish coverage of other git-readable layouts not tried here.
**Legibility-target:** for-orchestrator-synthesis

The listing is `find -L pack -mindepth 1 -maxdepth 1 -name '*.idx' ! -type d` and `find -L . -mindepth 2 -maxdepth 2 ! -type d -path './[0123456789abcdef][0123456789abcdef]/*'` (`:641`, `:643`). In L1, test 7 (both cases refuse with `$OBJS`) is ok. In L5, M2 (`find -P` for the loose listing) makes test 7 fail.

**Evidence:** `scripts/build-loop.sh:641-643`, `test/scripts/build-loop-check.bats:1900-1912`, `$S/logs/bats-targeted.log`, `$S/logs/probe-mut2.log`

---

## Claim 18: "Only one call's ids are judged, so one brief's refusal never carries to the next ... Returns 1 on a mismatch, a missing object, a second copy or a failed read."

**Location:** `scripts/build-loop.sh:609-612`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four failure kinds through store_check's return and the two-brief carry test. "Only one call's ids" means main's plus this call's (the comment's previous sentence says so). It does not establish failure on every possible read error. The i2 fact-check executed truncated and unreadable .idx cases, which were not re-run here.
**Legibility-target:** for-orchestrator-synthesis

The four failure kinds map to code as follows:

- Mismatch and missing: the perl regex fails on `NAME missing` and the hexdigest comparison fails (`:631`, `:633`), via `exit 1`, then `|| return 1` (`:636`).
- A missing tree: the ls-tree `|| exit 1` (`:627`) under pipefail.
- Second copy: `n[$0]++ { bad = 1 } END { exit bad }` (`:644`).

L1 test 6 covers mismatch (forge), missing (`rm` of a tree object) and second copy (pack, loose), plus the carry check in both orders.

**Evidence:** `scripts/build-loop.sh:618-645`, `test/scripts/build-loop-check.bats:1867-1898`, `$S/logs/bats-targeted.log`

---

## Claim 19: "Not checked: objects a decision reaches only through history (the tip's parent, read by marker_kind; the commits check_branch counts; the merge bases, whose merge result the rules judge), and a writer racing between a check and a later read (R8's family, Q-103), which for main's objects spans the whole run, as they are re-hashed once."

**Location:** `scripts/build-loop.sh:612-616`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named history reads and the once-per-run re-hash of main. It does not establish exhaustiveness. check_brief's `git log -G'^Status: '` (`scripts/lib/dev-cycle-read.sh:462`) also reads main's history blobs unchecked, and its result field is discarded by status_fields, so no verdict depends on it.
**Legibility-target:** for-orchestrator-synthesis

See Claim 5 for the quoted reads (`scripts/build-loop.sh:493`, `:652`; `scripts/lib/dev-cycle-read.sh:488`). The startup call is the only one passed `"$MAIN_SHA"` (`scripts/build-loop.sh:858`). Per-brief calls skip main's ids (`:628`).

**Evidence:** `scripts/build-loop.sh:493`, `scripts/build-loop.sh:628`, `scripts/build-loop.sh:652`, `scripts/build-loop.sh:858`, `scripts/lib/dev-cycle-read.sh:462`, `scripts/lib/dev-cycle-read.sh:488`

---

## Claim 20: "Reads the real repository's object store, as merge-tree writes into it. Needs GATE_TMP."

**Location:** `scripts/build-loop.sh:616-617`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers store_check's plain `git` calls and the gate repository's object directory. It does not establish anything about alternates from the caller's environment.
**Legibility-target:** for-orchestrator-synthesis

store_check calls `git cat-file --batch` and `git ls-tree` without `gate_git` (`:627-628`). The gate repository sets `GIT_OBJECT_DIRECTORY="$v"`, where `v` is the real `--git-path objects` (`:580`, `:584`), so merge-tree's writes land in the real store. store_check writes `$GATE_TMP/main`, `call` and `idx` (`:622`, `:636`, `:641`).

**Evidence:** `scripts/build-loop.sh:576-585`, `scripts/build-loop.sh:618-645`

---

## Claim 21: "REV^{tree} is never skipped, so 0 read is a fault"

**Location:** `scripts/build-loop.sh:636`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skip filter's inability to match the literal string `REV^{tree}`. It does not establish the "Each object name once" wording at `:623` for objects, because a tree REV is read twice, as `T` and as `T^{tree}`. That is harmless: the call file is a set for the scan.
**Legibility-target:** for-orchestrator-synthesis

`printf '%s\n' "$r" "$r^{tree}"` (`:626`) feeds a name containing `^{tree}`. The skip compares whole lines against hex ids in `$GATE_TMP/main` (`:628`), so that name always passes. cat-file then prints one object for it, and the perl's `exit($n ? 0 : 1)` (`:636`) fires only if nothing was read.

**Evidence:** `scripts/build-loop.sh:623-636`

---

## Claim 22: own_blob: "main's copy ... the one brief_fields reads (status_fields has read it as 'Status: open')"

**Location:** `scripts/build-loop.sh:661-665`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers own_blob's only caller path. It does not establish anything beyond the open-state gate.
**Legibility-target:** for-orchestrator-synthesis

own_blob is called only from nrules for the brief's own path (`:691`). nrules runs in check_line only after `if [[ "$st" != open ]]; then echo "refuse ..."; return; fi` (`:883`), and `st` is `STATUS[state]` from status_fields (`:882`).

**Evidence:** `scripts/build-loop.sh:661-673`, `scripts/build-loop.sh:685-692`, `scripts/build-loop.sh:880-883`

---

## Claim 23: srules: "$5 the checkout's refusal, if any ... the floor (only when $5 is empty: it walks the checkout)"

**Location:** `scripts/build-loop.sh:740-741`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the argument and the guard. It does not establish the floor's internals.
**Legibility-target:** for-orchestrator-synthesis

The guard is `if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then` (`:749`). The caller passes `"$co"` (`:934`), which only checkout_gate sets (`:924`).

**Evidence:** `scripts/build-loop.sh:746-759`, `scripts/build-loop.sh:924`, `scripts/build-loop.sh:934`

---

## Claim 24: gate_start: "in this order, each refusal a 'refuse state' line and exit 2 before any setting or brief is read ... The repository rule: main's files and refs, the branch tips, the checkout and store_check's object reads are in the real repository; the merge computations (merge-base, merge-tree, diff-tree, the blob checks) run through gate_git."

**Location:** `scripts/build-loop.sh:844-853`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order (executed, M3) and the repository of each named git call (static). It does not establish anything about mktemp failure (exit 1, no line; documented elsewhere).
**Legibility-target:** for-orchestrator-synthesis

The order is quoted in Claim 7. gate_git is used for `merge-base` and `merge-tree` (`:652`, `:656`), `diff-tree` (`:895`), `cat-file --batch-check` (`:911`) and own_blob's `hash-object` (`:672`). The real repository is used for main's `cat-file blob` (`:670`), branch tips via check_branch, and checkout_gate's calls (`:783-842`). L5 M3 fails the A15 test.

**Evidence:** `scripts/build-loop.sh:652-672`, `scripts/build-loop.sh:844-861`, `scripts/build-loop.sh:895`, `scripts/build-loop.sh:911`, `$S/logs/probe-mut2.log`

---

## Claim 25: check_line: "or one skip or refuse line (status_fields' STATUS[line], then the gate's own reasons) ... each helper empties its own globals before use (DENY, PATHS and PATHS_WHY, LIST, LIST_WHY and LIST_BAD, STATUS, BRIEF, ...)"

**Location:** `scripts/build-loop.sh:866-874`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers STATUS and BRIEF, the globals added to the list in this diff. It does not re-verify the pre-existing entries.
**Legibility-target:** for-orchestrator-synthesis

status_fields starts `STATUS=(); BRIEF=()` (`:518`), and check_line echoes `"${STATUS[line]}"` for a non-ok line (`:881`). The `check_line "$a" > "$GATE_TMP/line"` call (`:956`) is a redirection, not a subshell, so STATUS lives in the run's shell, as the comment says.

**Evidence:** `scripts/build-loop.sh:516-521`, `scripts/build-loop.sh:875-882`, `scripts/build-loop.sh:956`

---

## Claim 26: "The tip's objects and the merge's, re-hashed (main's were, in gate_start)." / "The S rules' inputs: the brief as status_fields read it from main's commit."

**Location:** `scripts/build-loop.sh:915`, `scripts/build-loop.sh:925`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no brief_fields call sits between status_fields and read_paths. It does not establish anything about the floor's own reads after read_paths.
**Legibility-target:** for-orchestrator-synthesis

Between `:880` and `:927` the calls are merge_result, gate_git, store_check and checkout_gate. None of them calls brief_fields (paraphrased — no quote available because the claim covers the absence of a call across four helpers, read at `:618-660` and `:777-843`). read_paths reads `"${BRIEF[paths]}"` (`:717-718`).

**Evidence:** `scripts/build-loop.sh:715-720`, `scripts/build-loop.sh:880-927`

---

## Claim 27: state-gate test: the alternates line is planted and refused

**Location:** `test/scripts/build-loop-check.bats:1633-1640`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's planted file and expected line. It does not cover an alternates symlink or directory form (the code's `-L` and `! -f` branches, `scripts/build-loop.sh:309`).
**Legibility-target:** for-orchestrator-synthesis

The test plants `echo "$BATS_TEST_TMPDIR/elsewhere" > .git/objects/info/alternates` and expects `refuse state objects/info/alternates: present and not an empty file`, in order between shallow and refs/replace. The order matches the code's loop (`scripts/build-loop.sh:307`). L1 test 2 is ok.

**Evidence:** `test/scripts/build-loop-check.bats:1614-1643`, `$S/logs/bats-targeted.log`

---

## Claim 28: config-pairs test: every call carries `core.multiPackIndex=false`

**Location:** `test/scripts/build-loop-check.bats:1685`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the list and its sensitivity to the pin. It does not establish the pin's security effect (Claim 10b).
**Legibility-target:** for-orchestrator-synthesis

The test checks `for kv in ... core.commitGraph=false core.multiPackIndex=false G=/dev/null P=none S=1; do ! grep -v -- " $kv" ...`. In L1 it is ok. In L4 (M1) it fails with "a call without core.multiPackIndex=false".

**Evidence:** `test/scripts/build-loop-check.bats:1674-1688`, `$S/logs/bats-targeted.log`, `$S/logs/probe-mut.log`

---

## Claim 29: "Packed, with a second copy of the brief's blob: store_check reads SHA-256 pack indexes (U3a1)."

**Location:** `test/scripts/build-loop-check.bats:1723`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a fully packed SHA-256 repo passing and a second pack copy refusing. It does not establish SHA-256 loose-file duplicates, which the 62-char name concatenation would handle but this test does not exercise.
**Legibility-target:** for-orchestrator-synthesis

The test runs `git repack -adq; chk "$B"; [ "$status" -eq 0 ]`, then `git rev-parse "main:$B" | git pack-objects -q .git/objects/pack/pack` and expects `$OBJS` with status 2. The pack listing calls `git show-index --object-format="$fmt"` (`scripts/build-loop.sh:642`). `OBJS` is set at file level (`:1866`), and bats sources the whole file before each test. L1 test 4 is ok.

**Evidence:** `test/scripts/build-loop-check.bats:1717-1727`, `test/scripts/build-loop-check.bats:1866`, `scripts/build-loop.sh:642`, `$S/logs/bats-targeted.log`

---

## Claim 30: "forge ID TEXT: rewrite loose object ID's file to hold a blob of TEXT, its id unchanged." / "loose ID: a loose copy of packed blob ID, beside the packed one (git itself writes none for an object it has)."

**Location:** `test/scripts/build-loop-check.bats:1857-1865`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helpers as used in tests 6 and 7. It does not cover the parenthetical about git's own writes, which was not separately probed here (the i2 fact-check's P6 probe found hash-object writes no loose copy).
**Legibility-target:** for-author

forge writes `printf 'blob %s\0%s' ... | perl -MCompress::Zlib ... > "$f"` to the id's own path. Test 6 asserts that the forged blob reads back: `[ "$(git cat-file blob "$o" | grep Branch)" = "Branch: feat/y" ]`. loose writes the zlib of `"blob " . length . "\0" . content` to the id path. L1 tests 6 and 7 are ok.

**Evidence:** `test/scripts/build-loop-check.bats:1857-1865`, `test/scripts/build-loop-check.bats:1878-1880`, `$S/logs/bats-targeted.log`

---

## Claim 31: test title: "--check re-hashes what it reads: a rewritten, missing or second copy of an object of main's tree refuses the state before any brief; of the tip's tree, the brief; a packed store passes (rows 492, 503, U3a1, i1 security F1)"

**Location:** `test/scripts/build-loop-check.bats:1867`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each case the title names:

- main: second pack, loose+packed, forged blob, missing tree.
- tip: forged blob, loose second copy.
- the packed pass.
- the two-brief carry check.

"Missing" is exercised only for main's tree, not the tip's; a missing tip object is refused earlier by merge_result.
**Legibility-target:** for-orchestrator-synthesis

Each case asserts exit 2 with exactly `$OBJS` (main) or the per-brief refusal (tip). The packed-pass case is `chk "$B"; [ "$status" -eq 0 ] && [ "${lines[0]}" = "ok $B $t ..." ]` after `git repack -adq`. L1 test 6 is ok.

**Evidence:** `test/scripts/build-loop-check.bats:1867-1898`, `$S/logs/bats-targeted.log`

---

## Claim 32a: test title: "--check's second-copy scan lists what git opens: a pack named with a leading dot, a linked fan-out directory"

**Location:** `test/scripts/build-loop-check.bats:1900`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two layouts named and the test's sensitivity to `find -L`. It does not cover the midx part of the title (Claim 32b).
**Legibility-target:** for-orchestrator-synthesis

The test moves a pack to `.git/objects/pack/.hidden.{idx,pack}`, checks `[ "$(git cat-file -t "$o")" = blob ]`, and expects `$OBJS`. It then links a fan-out directory with `ln -s "$BATS_TEST_TMPDIR/fan/${o:0:2}" ".git/objects/${o:0:2}"` and expects `$OBJS` again. It passes in L1 and fails under M2 in L5.

**Evidence:** `test/scripts/build-loop-check.bats:1900-1912`, `$S/logs/bats-targeted.log`, `$S/logs/probe-mut2.log`

---

## Claim 32b: test title: "... and no multi-pack-index route (U3a1 i2 security F1)"

**Location:** `test/scripts/build-loop-check.bats:1900`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether this test exercises the midx pin. It does not establish whether the pin is tested elsewhere: it is, by the config-pairs test (Claim 28).
**Legibility-target:** for-author

The test body (`:1901-1912`) contains no `multi-pack-index` command and no midx file (paraphrased — no quote available because the claim covers the absence of code in a 12-line body read whole). In L4 (M1, the pin removed from harden), this test still prints `ok 2 --check's second-copy scan ...`. A reader trusting the title would think this test pins the midx behaviour. It does not, and removing the pin leaves it green. Either the title should drop "and no multi-pack-index route", or the test should add a midx case.

**Evidence:** `test/scripts/build-loop-check.bats:1900-1912`, `$S/logs/probe-mut.log`

---

## Claim 33: A15 test: "store_check re-hashes main's objects before any cat-file blob read of main (U3a1 i1 architecture 1)."

**Location:** `test/scripts/build-loop-check.bats:1959-1962`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering between store_check's `cat-file --batch` and the first `cat-file blob` in the shim log, and the check's sensitivity to reordering. It does not cover reads by path through other commands (git grep in open_shared, which is also after store_check per `scripts/build-loop.sh:860`).
**Legibility-target:** for-orchestrator-synthesis

The check is `c="$(grep -n -m1 -x 'cat-file --batch' ...)"; f="$(grep -n -m1 '^cat-file blob ' ...)"; [ "$c" -lt "$f" ]`. L1 is ok. In L5 M3 it fails at "store_check at line 29, first blob read at line 25".

**Evidence:** `test/scripts/build-loop-check.bats:1949-1965`, `$S/logs/bats-targeted.log`, `$S/logs/probe-mut2.log`

---

## Claim 34: commit 65007bf8: "store_check re-hashes main's commit and every tree and blob of its tree in gate_start (refuse state objects), and per brief the tip's commit, its tree and the merge's tree ... status_fields gives --status's line as values (rows 496, 512), so check_line reads the brief once: the branch and brief re-reads and their two untested refusals go ... gate_start holds the gate's startup order and the real-repo vs gate-repo rule in one place"

**Location:** commit `65007bf8`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against HEAD's code. "the merge's tree" means every object of it (Claim 15). The Notes' "Verdict values for --merge wait for U3a2" is a plan fact, matched by `docs/working/plan-build-loop-handoff.md:318`. It does not establish "untested" for the removed refusals, which is history.
**Legibility-target:** for-orchestrator-synthesis

The changes are present at HEAD: `store_check "$MAIN_SHA"` in gate_start (`scripts/build-loop.sh:858`), `store_check "$sha" "$tree"` (`:916`), status_fields (`:516`) and gate_start's comment (`:844-853`). The re-reads are gone (Claim 6).

**Evidence:** `git log -1 65007bf8`, `scripts/build-loop.sh:516`, `scripts/build-loop.sh:844-861`, `scripts/build-loop.sh:916`

---

## Claim 35: commit 83f75281: "A2: the NR == FNR filter over an empty checked file read stdin as the first file; FILENAME is tested, and perl fails when it reads no object." Notes: "a legitimately duplicated object (overlapping packs) now refuses --check; /workspace's 21,742 packed ids have none."

**Location:** commit `83f75281`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the FILENAME filter and the perl `$n` guard at HEAD, and "none" for /workspace's store today. It does not re-count the 21,742 figure, and the store has changed since.
**Legibility-target:** for-orchestrator-synthesis

Both filters test `FILENAME != "-"` (`scripts/build-loop.sh:628`, `:644`), and perl ends `exit($n ? 0 : 1)` (`:636`). L6 ran store_check's own listing over the shared store and printed `duplicate ids in store: 0`.

**Evidence:** `git log -1 83f75281`, `scripts/build-loop.sh:628`, `scripts/build-loop.sh:636`, `scripts/build-loop.sh:644`, `$S/logs/probe-perf.log`

---

## Claim 36: commit d10cfba8: "store_check now skips main's ids (kept by gate_start) and judges main's plus this call's ids only; a two-brief test in both orders. B2: packs and loose files are listed with find -L inside the store (dot-named packs, linked fan-out dirs), and harden pins core.multiPackIndex=false ... GATE renamed GATED."

**Location:** commit `d10cfba8`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each code claim in the message. It does not establish the midx route the pin is meant to close (Claim 10b).
**Legibility-target:** for-orchestrator-synthesis

The code matches each claim:

- Skip set and judge set: `"$GATE_TMP/main"` (`scripts/build-loop.sh:628`) and `"$GATE_TMP/main" "$GATE_TMP/call"` (`:644`).
- Listing: `find -L` (`:641`, `:643`).
- Pin: `core.multiPackIndex=false` (`:273`).
- Rename: `GATED=""` (`:341`), and `grep -n '\bGATE\b'` finds no remaining flag use (paraphrased — no quote available because this covers the absence of code).

The two-brief test, `test/scripts/build-loop-check.bats:1894-1897`, is ok in L1.

**Evidence:** `git log -1 d10cfba8`, `scripts/build-loop.sh:273`, `scripts/build-loop.sh:341`, `scripts/build-loop.sh:628-644`, `$S/logs/bats-targeted.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 32b** (`test/scripts/build-loop-check.bats:1900`): the title says the test covers "no multi-pack-index route", but the body has no midx case, and the test passes with `core.multiPackIndex=false` removed from harden (L4). Drop the phrase or add a midx case. The pin itself is guarded by the config-pairs test (line 1685).

### Mostly Accurate
- **Claim 2** (`docs/working/plan-build-loop-handoff.md:317`): "skipping ids already checked" is i1's cumulative skip. Since d10cfba8 a per-brief call skips only main's ids, and ids an earlier brief checked are read again. Should say "skipping main's ids".

### Unverifiable
- **Claim 10b** (`scripts/build-loop.sh:262-263`): "a second route to an object, past store_check's listing". On git 2.39.5, a midx pack without its .idx cannot be read under either setting (L3), so no such route was found. Verifying it would need a midx-only read path on some git version.

## Goal-Alignment Note

**Success criterion (restated verbatim):** "a markdown report saved at the path your dispatch names, structured per your skill."
**Answered:** Yes. The report is at `docs/reviews/code-fact-check-report-build-loop-u3a1-final-r2.md` with `**Commit:** d10cfba8`. All five brief items are verdicted:

1. store_check's comment and help: Claims 3, 5, 7, 8, 15-21.
2. gate_start, GATED and harden's pairs reaching gate_git: Claims 7, 10a, 12, 24.
3. status_fields, with --status executed byte-identical to main's: Claims 13, 14, 25, 26.
4. The tests' titles: Claims 27-33. Mutations M1-M3 show which tests detect which change.
5. The plan notes and commit messages: Claims 1-6, 34-36.

**Out of scope:** whether the midx pin is needed on other git versions (Claim 10b), and whether check_brief's unchecked `-G` history reads matter. No verdict depends on them (Claims 5 and 19 scope).
**Escalate:** None blocking. Legibility targets: Claims 2, 30 and 32b are for-author. Claims 1, 3-29, 31, 32a and 33-36 are for-orchestrator-synthesis.
