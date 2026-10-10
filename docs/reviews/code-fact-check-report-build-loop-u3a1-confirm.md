# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u3a1`, branch `feat/build-loop-u3a1`)
**Scope:** partial, the final pass's fix: `git diff d10cfba8..a27f93b6` without docs/reviews: `scripts/build-loop.sh` (help at :100-131, store_check :596-654, gate_start's and check_line's comments :853-882), `test/scripts/build-loop-check.bats:1900-1914`, `docs/working/plan-build-loop-handoff.md:317`, and commit a27f93b6's message. The rest of the branch was read as context only (already reviewed, iterations 1-3).
**Commit:** a27f93b6
**Replication:** k=1 (confirming pass)
**Checked:** 2026-10-10
**Total claims checked:** 16
**Summary:** 16 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

`docs/reviews/hallucination-patterns.md` (5 entries) was read first; no claim here matches a logged pattern.

## Execution provenance

Root `S=/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-c/fact-check/`. Every probe is a script in `$S/bin/` that starts with `set -eu`, makes its own `mktemp -d` under `$S/tmp`, checks `pwd` is under it before any `git init`, and removes it at the end. Each ran under `timeout`, cwd `$S`, exit 0; no process left running. The scripts and bats ran on `git archive a27f93b6` copies (the old run swaps in `git show d10cfba8:scripts/build-loop.sh`); the worktree was not touched.

- **P1** `$S/bin/p1-names.sh` -> `$S/logs/p1-names.log`, 2026-10-10T19:23:07Z: the new `find ... -name '*.idx' ! -type d -print0` over nine `.idx` names (invalid UTF-8 `\xff\xfe`, a lone `\xc3`, `.idx`, `-x.idx`, a backslash, a tab, a leading space, a newline, a plain name) plus `UP.IDX`, under `LC_ALL=C` and `LC_ALL=C.utf8`: 9 of 9 listed in both, `UP.IDX` not.
- **P2** `$S/bin/p2-test.sh` -> `$S/logs/p2-test.log`, 19:23:19Z: `bats -f "second-copy scan lists what git opens"` with a27f93b6's test, against a27f93b6's script (`ok 1`) and d10cfba8's script (`not ok 1`, line 1913, `status 0`, output `ok docs/working/briefs/2026-10-01-x.md ...`).
- **P3** `$S/bin/p3-store.sh` -> `$S/logs/p3-store.log`, 19:23:43Z: store_check's own text (awk-cut from a27f93b6, signature to closing brace), sourced into a throwaway repo with `GATE_TMP` set: (a) per-brief call, list missing; (b) list empty; (c) `--main` on a clean store; (d) per-brief after `--main`; (e) per-brief after a second pack copy of one of main's blobs; (f) `--main` again with that copy present.
- **P4** `$S/bin/p4-mktemp.sh` -> `$S/logs/p4-mktemp.log`, 19:23:59Z: a scratch bats file (in the archive copy) running `--check` with `TMPDIR=/nonexistent/probe-dir`, then a control run. The test ends in a deliberate `false` so bats prints the values.
- **P5** `$S/bin/p5-bats.sh` -> `$S/logs/p5-bats.log`, 19:24:16Z: `bats -f 'U3a1|config pairs'` on a27f93b6: 3/3 ok.

---

## Claim 1: "store_check runs once for main in gate_start ... and per brief for the tip and the merge's tree, skipping main's ids"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip wording that replaced "skipping ids already checked" (fact-check 2b): a per-brief call skips the ids in `$GATE_TMP/main` and nothing else. Does not establish anything about ids a brief's call shares with an earlier brief's call; those are re-read, which is what the new wording says.
**Legibility-target:** for-orchestrator-synthesis

The batch's input filter drops only names in the main list:

```bash
# scripts/build-loop.sh:634
    done; } | awk 'FILENAME != "-" { seen[$0]; next } !($0 in seen) { seen[$0]; print }' "$GATE_TMP/main" - | git cat-file --batch \
```

`$GATE_TMP/call` is rewritten by each call (`> "$GATE_TMP/call"`, `:642`) and moved into the list only by `--main` (`:653`). In P3 (d), the per-brief call's ids hold none of main's five ids.

**Evidence:** `scripts/build-loop.sh:621-654`, `scripts/build-loop.sh:867`, `scripts/build-loop.sh:925`, `$S/logs/p3-store.log`

---

## Claim 2: "Not re-hashed (Q-103 residual): ... check_brief's `git log -G` walk (it can only skip a brief)"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the `-G` walk's result can change in `--check`: a skip line, or a Status commit that status_fields throws away. Does not establish what check_brief's other git reads (main_entry, brief_fields) do; those read main's tree, which gate_start re-hashed.
**Legibility-target:** for-orchestrator-synthesis

The walk's only product is `c`. A malformed one is a skip, and anything else is printed as the last field of an `ok` line:

```bash
# scripts/lib/dev-cycle-read.sh:457-460
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s --no-textconv --no-show-signature --no-follow -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H --no-show-signature --no-follow "$MAIN_SHA" -- "$a")"
  if [[ -n "$c" && ! "$c" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]]; then echo "skip $a: its Status commit could not be read"; return; fi
  echo "ok $a ${st#Status: } $c"
```

status_fields drops that field: `read -r _ _ st _ <<<"$out"` (`scripts/build-loop.sh:522`). Neither STATUS nor the line it builds (`:551-552`) carries it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:423-461`, `scripts/build-loop.sh:516-553`

---

## Claim 3: "The second-copy listing is NUL-ended (final security F1: a pack name holding a newline hid its index)."

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pack-index listing and the cited finding (security final report F1, `docs/reviews/security-reviewer-review-2026-10-10-build-loop-u3a1-final.md:36-66`). Does not establish the loose-object half of the scan, which is still line-based (see Claim 11).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:649-650
  { (cd "$o" && find -L pack -mindepth 1 -maxdepth 1 -name '*.idx' ! -type d -print0) > "$GATE_TMP/idx" || exit 1
    while IFS= read -r -d '' r; do git show-index --object-format="$fmt" < "$o/$r" | awk '{ print $2 }' || exit 1; done < "$GATE_TMP/idx"
```

P2: the newline case passes on a27f93b6 and fails on d10cfba8.

**Evidence:** `scripts/build-loop.sh:649-650`, `$S/logs/p2-test.log`

---

## Claim 4: "then main's commit, or a tree or blob of its tree (gitlinks aside), that does not hash to its id ..."

**Location:** `scripts/build-loop.sh:103-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the new "(gitlinks aside)" gloss on main's state check: gitlink entries are not read or hashed. Does not establish how a gitlink is judged elsewhere (merge_result, nrules).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:633
      git ls-tree -r -t --full-tree --format='%(objecttype) %(objectname)' "$r" 2>/dev/null | awk '$1 != "commit" { print $2 }' || exit 1
```

A gitlink's objecttype is `commit`, so its id never reaches the batch. gate_start's call is `store_check --main "$MAIN_SHA"` (`:867`), which takes the same path.

**Evidence:** `scripts/build-loop.sh:631-634`, `scripts/build-loop.sh:867`

---

## Claim 5: "(gitlinks aside; a second copy of one of main's objects, made after the state check, is reported here too)"

**Location:** `scripts/build-loop.sh:129-131`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers store_check's per-brief call refusing when one of main's ids gains a second pack copy after `--main` ran, and so the per-brief refusal line (`:925`). Does not establish detection of a copy made after the per-brief scan, or an in-place rewrite of a main object after startup (the documented race residual).
**Legibility-target:** for-orchestrator-synthesis

The duplicate scan's wanted set is main's list plus this call's:

```bash
# scripts/build-loop.sh:652
  } | awk 'FILENAME != "-" { want[$0]; next } ($0 in want) && n[$0]++ { bad = 1 } END { exit bad }' "$GATE_TMP/main" "$GATE_TMP/call" - || return 1
```

P3 (e): after `--main` passed, a second pack holding main's blob `78981922…` was installed. The per-brief call on the feature tip then returned `rc=1`. The `--check` path itself was not raced; the probe calls the function directly.

**Evidence:** `scripts/build-loop.sh:652`, `scripts/build-loop.sh:925`, `$S/logs/p3-store.log`

---

## Claim 6: "store_check [--main] REV...: ... an id in $GATE_TMP/main (main's, which gate_start's --main call leaves there; any other call fails without it) is not read again."

**Location:** `scripts/build-loop.sh:596-604`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both call sites (gate_start's `--main`, check_line's plain call) and the failure when the list is missing or empty. Does not establish a non-empty but wrong list, which only `--main` writes.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:628
  if [[ -n "$main" ]]; then : > "$GATE_TMP/main" || return 1; elif [[ ! -s "$GATE_TMP/main" ]]; then return 1; fi
```

`rg -- "--main|store_check "` finds exactly two callers: `:867` (`store_check --main "$MAIN_SHA"`) and `:925` (`store_check "$sha" "$tree"`). P3: (a) list missing, `rc=1`; (b) list empty, `rc=1`; (c) `--main`, `rc=0` with 5 ids in the list.

**Evidence:** `scripts/build-loop.sh:621-654`, `scripts/build-loop.sh:867`, `scripts/build-loop.sh:925`, `$S/logs/p3-store.log`

---

## Claim 7: "Not checked: ... check_brief's git log -G walk, which can only skip a brief"

**Location:** `scripts/build-loop.sh:615-617`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** The same property as Claim 2, in store_check's comment. Does not establish completeness of the not-checked list beyond the four items it names.
**Legibility-target:** for-orchestrator-synthesis

paraphrased — no quote available because the evidence is Claim 2's quotes (`scripts/lib/dev-cycle-read.sh:457-460`, `scripts/build-loop.sh:522`): the walk's commit id is either a skip or a field status_fields discards.

**Evidence:** `scripts/lib/dev-cycle-read.sh:457-460`, `scripts/build-loop.sh:522`

---

## Claim 8: "--main (gate_start's call) starts the skip list empty and keeps its ids there; any other call needs it, so a second main call cannot skip main."

**Location:** `scripts/build-loop.sh:626-628`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers truncation by `--main`, the need-list rule, and that a repeated `--main` re-reads all of main (it starts from an empty list). Does not establish anything about concurrent runs sharing a GATE_TMP; each run makes its own.
**Legibility-target:** for-orchestrator-synthesis

Quote at `:628` (Claim 6). P3 (f): `--main` run again with a second copy present gave `rc=1 main-lines=0`. The list was truncated, and the failed scan left nothing in it.

**Evidence:** `scripts/build-loop.sh:626-628`, `scripts/build-loop.sh:653`, `$S/logs/p3-store.log`

---

## Claim 9: "NUL-ended: a pack name holding a newline would read as two other names, and its own index would go unread (final security F1)."

**Location:** `scripts/build-loop.sh:647-648`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the d10cfba8 failure mode and the fix (find `-print0`, `read -d ''`). Does not establish the loose listing (Claim 11).
**Legibility-target:** for-orchestrator-synthesis

Quote at `:649-650` (Claim 3). P2: under d10cfba8's script, the test's newline pack with decoys at `objects/pack/x` and `objects/y.idx` printed `ok …` with `status 0`; under a27f93b6 it refuses. P1 lists the newline name as one NUL-ended record.

**Evidence:** `scripts/build-loop.sh:647-650`, `$S/logs/p2-test.log`, `$S/logs/p1-names.log`

---

## Claim 10: "--main moves its ids into the list only after the scan passes" (brief claim 2; code at :652-653)

**Location:** `scripts/build-loop.sh:652-653`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ordering: a failed batch or duplicate scan returns before the `mv`. Does not establish anything after a failed `--main`, where gate_start exits 2 regardless (`:867-868`).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:652-653
  } | awk '...' "$GATE_TMP/main" "$GATE_TMP/call" - || return 1
  [[ -z "$main" ]] || mv "$GATE_TMP/call" "$GATE_TMP/main"
```

(`:652` abridged; full line quoted under Claim 5.) P3 (f): after the failed `--main`, `main-lines=0` and `call=present`, so no move happened.

**Evidence:** `scripts/build-loop.sh:642-653`, `$S/logs/p3-store.log`

---

## Claim 11: Brief question for claim 1: "Any other name shape git opens as a pack that the listing still misses or misreads?" (implicit claim: the listing now takes every name git opens)

**Location:** `scripts/build-loop.sh:643-651`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers names directly in `objects/pack/` ending `.idx`: control bytes, newline, tab, a leading space, a leading dash or dot, a backslash, invalid UTF-8, and a bare `.idx`, all listed whole under `C` and `C.utf8`. The loose half can only add lines (fail-closed). Does not establish git versions other than this sandbox's, or a case-insensitive filesystem (`UP.IDX` is not listed; git on Linux also needs the lowercase suffix). The rule that git takes exactly `pack/*.idx` (no recursion, no other suffix) rests on the security report's reading of git's readdir, not re-read here.
**Legibility-target:** for-orchestrator-synthesis

P1: 9 of 9 `.idx` names were listed NUL-ended under both locales. That matters because gate_start's `--main` call runs before check_line's `local -x LC_ALL=C` (`:886`), so it runs under the caller's locale. `read -r -d ''` with `IFS=` keeps each name byte for byte, and `"$o/$r"` starts with `/`, so a leading dash is harmless. In the loose half, `find ... | awk -F/ '{ print $(NF - 1) $NF }'` (`:651`) is still newline-split. A name git opens there is a hex id, which cannot hold a newline, so a split only adds lines. The security report's own note at `security-reviewer-review-2026-10-10-build-loop-u3a1-final.md:68` reaches the same conclusion. A symlink whose target is missing is listed (it is not `-type d`). Its show-index redirection then fails, and git cannot open it either. No missed or misread shape was found.

**Evidence:** `scripts/build-loop.sh:643-651`, `scripts/build-loop.sh:886`, `docs/reviews/security-reviewer-review-2026-10-10-build-loop-u3a1-final.md:50,68`, `$S/logs/p1-names.log`

---

## Claim 12: "each refusal a "refuse state" line and exit 2 before any setting or brief is read (a failed mktemp exits 1 with no line)"

**Location:** `scripts/build-loop.sh:853-855`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mktemp failing in gate_start under `set -euo pipefail` (`:224`); gate_start is called outside any condition (`:960`). Does not establish other unannounced exits (for example a crash inside default_gate).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:866
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
```

P4: `status=1`, `stdout=[]`, stderr held only mktemp's own message. The control run gave `status=0` and an `ok` line.

**Evidence:** `scripts/build-loop.sh:224`, `scripts/build-loop.sh:863-870`, `scripts/build-loop.sh:960`, `$S/logs/p4-mktemp.log`

---

## Claim 13: "Nothing but its locals, the walk caches it resets and store_check's list of main's ids ($GATE_TMP/main, on purpose) may carry from one brief to the next"

**Location:** `scripts/build-loop.sh:880-881`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the added clause: `$GATE_TMP/main` is written only by `--main` (Claims 6, 10). The other GATE_TMP files store_check uses (`call`, `idx`) are rewritten before each read (`:642`, `:649`). Does not re-verify the pre-existing parts of the sentence (startup globals such as settings and MAIN_SHA, which the sentence leaves out as run-wide, not per-brief), or objects merge-tree writes into the store.
**Legibility-target:** for-orchestrator-synthesis

`rg -n "GATE_TMP/main|GATE_TMP/call"` returns only `:602-603` (comment), `:628`, `:634`, `:642`, `:652` and `:653`. `call` is truncated by the `>` at `:642` before `:652` reads it, and `idx` by the `>` at `:649`.

**Evidence:** `scripts/build-loop.sh:621-654`, `scripts/build-loop.sh:877-882`

---

## Claim 14: test title "--check's second-copy scan lists what git opens: a pack named with a leading dot or holding a newline, and a linked fan-out directory (U3a1 i2 security F1, final security F1; the multi-pack-index pin is in the config-pairs test)"

**Location:** `test/scripts/build-loop-check.bats:1900`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three cases in the body (`.hidden.*` at `:1904-1907`, newline at `:1910-1914`, linked fan-out at `:1915-1918`) and the midx pointer. Does not establish that the config-pairs test fails without the pin; that was shown at d10cfba8 (merged report, r2 L4) and not re-run here.
**Legibility-target:** for-orchestrator-synthesis

The config-pairs test pins the key: `for kv in ... core.multiPackIndex=false ...` (`test/scripts/build-loop-check.bats:1685`). This fixes the earlier Incorrect 34b, since the title no longer claims a midx case. P5: the test passes, along with the config-pairs test.

**Evidence:** `test/scripts/build-loop-check.bats:1674-1685`, `test/scripts/build-loop-check.bats:1900-1919`, `$S/logs/p5-bats.log`

---

## Claim 15: "A name holding a newline, with decoys at the two halves a line-based listing would read: valid indexes of a pack holding only a blob no tree names, so such a listing finds no second copy and fails no read."

**Location:** `test/scripts/build-loop-check.bats:1908-1909`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the decoys' effect on d10cfba8's line-based listing (no read failure, no duplicate found, so `ok`). Does not establish the forged-bytes variant (security F1's probe), since this test uses a genuine second copy.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/scripts/build-loop-check.bats:1910-1912
    for f in "$BATS_TEST_TMPDIR"/p-*; do cp "$f" ".git/objects/pack/x"$'\n'"y.${f##*.}"; done
    echo decoy | git hash-object -w --stdin | git pack-objects -q "$BATS_TEST_TMPDIR/d" >/dev/null
    cp "$BATS_TEST_TMPDIR"/d-*.idx .git/objects/pack/x; cp "$BATS_TEST_TMPDIR"/d-*.idx .git/objects/y.idx
```

P2: under d10cfba8, `:1913` failed with `status 0` and an `ok` line. Read failure and duplicate are the only two ways to refuse, so the listing hit neither. The `mv` to `cp` change at `:1904` keeps `p-*` for this reuse.

**Evidence:** `test/scripts/build-loop-check.bats:1902-1914`, `$S/logs/p2-test.log`

---

## Claim 16: commit a27f93b6: "a pack named x<LF>y.idx read as pack/x and y.idx, so decoy indexes there kept the forged pack's own index out of the second-copy scan and the gate printed ok for a forged brief. The listing is now find -print0 / read -d ''; a test with the newline pack and decoys fails on d10cfba8."

**Location:** commit a27f93b6 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism, the fix and "fails on d10cfba8" (P2). "printed ok for a forged brief" rests on the security report's executed probe (`final.md:52-64`), not re-run here. Does not verify the message's list of corrected review items (architecture 2; api 1, 2; fact-check 2b, 4b, 20, 25a, 34b) beyond Claims 1, 2, 7, 12 and 14, which cover 2b, 4b, 20, 25a and 34b.
**Legibility-target:** for-orchestrator-synthesis

paraphrased — no quote available because the evidence is a run log and another report: P2 shows the new test failing on d10cfba8 at the newline case, and `security-reviewer-review-2026-10-10-build-loop-u3a1-final.md:64` records `ok` for a forged brief with the same pack name and decoys.

**Evidence:** `scripts/build-loop.sh:647-650`, `docs/reviews/security-reviewer-review-2026-10-10-build-loop-u3a1-final.md:36-66`, `$S/logs/p2-test.log`

---

## Claims Requiring Attention

### Incorrect
- none

### Stale
- none

### Mostly Accurate
- none

### Unverifiable
- none

The prior Stale/Mostly-accurate/Incorrect items this fix targeted are resolved: 2b (Claim 1), 4b (Claim 2), 20 (Claim 7), 25a (Claim 12), 34b (Claim 14).

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill.
- Answered: yes; all three brief claims checked, 16 claims, all Verified (13 executed).
- Out of scope: the rest of the branch (reviewed in iterations 1-3); re-running the full check suite (targeted bats only, P2/P5); re-running security F1's forged-bytes probe.
- Escalate: nothing.
- Decisions I made: probed store_check directly (function cut from the script) for Claims 5, 6, 8 and 10, rather than racing a full `--check`; the hallucination-pattern log was not appended (no Incorrect verdicts, and the brief restricts writes to this report).
