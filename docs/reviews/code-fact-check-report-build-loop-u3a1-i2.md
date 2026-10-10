# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u3a1`, branch `feat/build-loop-u3a1`)
**Scope:** partial, iteration 1's fix range `65007bf8..83f75281` (docs/reviews excluded): `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, `docs/working/plan-build-loop-handoff.md` step 7 (U3a1/U3a2 bullets), and commit 83f75281's message. `main...65007bf8` and `scripts/lib/dev-cycle-read.sh` were read as context only.
**Commit:** 83f75281
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-10
**Total claims checked:** 30
**Summary:** 26 verified, 2 mostly accurate, 2 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read first: no entry concerns git object stores, pack indexes or awk, and no claim below matches a logged pattern.

Execution logs (all under `/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-i2/fact-check/`; S below is that directory):

| Log | Command | cwd | Exit | Started (UTC) |
|---|---|---|---|---|
| L1 `logs/bats-existing.log` | `TMPDIR=$S/tmp LC_ALL=C bats -f 're-hashes what it reads\|SHA-256\|refuses planted\|A15\|before any git call\|state gate' test/scripts/build-loop-check.bats` | worktree | 0 (4/4 ok) | 2026-10-10T18:41:03Z |
| L2 `logs/probe-awk-showindex.log` | inline probe: mawk with the store_check filter vs the old `NR==FNR` filter, over a non-empty and an empty `checked` file | `$S/tmp/tmp.2aBCse956R` | 1 (the awk rows are complete; the probe then stopped on a zsh `PIPESTATUS` error in its own harness, rerun as L3) | 2026-10-10T18:41:39Z |
| L3 `logs/probe-showindex.log` | `bash $S/scripts/showindex.sh` (git show-index on full, truncated, empty and unreadable .idx files) | `$S/tmp/tmp.uebyHGh5Kh` | 1 (every show-index row printed; the script's last line, a probe-harness `exit 1` inside `{ }`, ended it) | 2026-10-10T18:41:53Z |
| L4 `logs/probe-bats.log` | `TMPDIR=$S/tmp LC_ALL=C bats --show-output-of-passing-tests $S/bats/probe.bats` (P1 truncated extra .idx, P2 unreadable .idx, P3 unreadable loose fan-out dir, P4 multi-pack-index pack with its .idx removed, P5 git call order) | worktree | 0 | 2026-10-10T18:42:13Z |
| L5 `logs/probe-ws-dups.log` | `LC_ALL=C bash $S/scripts/wsdups.sh $S/logs` (store_check's duplicate scan over /workspace's whole store, read-only) | /workspace | 0 | 2026-10-10T18:43:43Z |
| L6 `logs/probe2-bats.log` | `TMPDIR=$S/tmp LC_ALL=C bats --show-output-of-passing-tests $S/bats/probe2.bats` (P6 repack clears a second copy; hash-object writes no loose copy; P7 the tip's loose second copy prints no path line) | worktree | 0 | 2026-10-10T18:44:06Z |

Probe repositories were built only under `$BATS_TEST_TMPDIR` or a `mktemp -d` under `$S/tmp` (each probe's setup refuses to run outside it). No process was left running.

---

## Claim 1: "store_check runs once for main in gate_start (a mismatch is `refuse state objects`, exit 2) and per brief for the tip and the merge's tree, skipping ids already checked"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two call sites, the startup refusal text and exit 2, and the skip of ids already in `$GATE_TMP/checked`. It does not establish that skipping is safe against a rewrite between gate_start and the per-brief call: an id that main and the merge tree share is re-hashed only at startup, so the race window for those ids now runs from gate_start, not from the per-brief call (the Q-103 residual the comment names, now wider for shared ids).
**Legibility-target:** for-orchestrator-synthesis

The two call sites are quoted from source:

```bash
# scripts/build-loop.sh:854
  store_check "$MAIN_SHA" || { echo "refuse state objects: the default branch's commit or an object of its tree does not hash to its id, has a second copy in the object store, or could not be read"; exit 2; }
# scripts/build-loop.sh:911
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of the tip of $br or of the merge does not hash to its id, has a second copy in the object store, or could not be read"; return; fi
```

The skip is the first awk of the read pipeline, `awk 'FILENAME != "-" { seen[$0]; next } !($0 in seen) { seen[$0]; print }' "$GATE_TMP/checked" -` (`scripts/build-loop.sh:624`), together with perl's `print "$id\n"` appended `>> "$GATE_TMP/checked"` (`:630`, `:632`). Executed: L1's re-hash test checks exit 2 with exactly `$OBJS` for a forged, missing or duplicated main object, and the brief refusal for the tip's objects.

**Evidence:** `scripts/build-loop.sh:614-641`, `scripts/build-loop.sh:850-856`, `scripts/build-loop.sh:911`, L1

---

## Claim 2: "it also refuses an id with a second copy in the store (review i1 security F1: a second pack holding forged bytes under the brief's id was read by brief_fields while the batch read the genuine copy), and the state gate refuses `objects/info/alternates`"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the duplicate refusal (two packs, loose plus packed), the alternates refusal, and the F1 reference against the i1 security report. It does not establish the i1 5/5 reproduction itself, which was not re-run here.
**Legibility-target:** for-orchestrator-synthesis

`state_gate` now loops `for f in info/attributes info/grafts shallow objects/info/alternates; do` (`scripts/build-loop.sh:306`). The i1 security report's summary says store_check "verifies objects by id through `cat-file --batch`, a different git read path than the `cat-file blob MAIN_SHA:PATH` the decisions actually consume, and for a packed object forged under a genuine id the two paths diverge" (`docs/reviews/security-reviewer-review-2026-10-10-build-loop-u3a1.md:169`). Executed: L1's planted-state test prints `refuse state objects/info/alternates: present and not an empty file`, and its re-hash and SHA-256 tests refuse a second pack and a loose copy; L6 P6 shows the same refusal for a second pack.

**Evidence:** `scripts/build-loop.sh:306-309`, `test/scripts/build-loop-check.bats:1633-1640`, `docs/reviews/security-reviewer-review-2026-10-10-build-loop-u3a1.md:169`, L1, L6

---

## Claim 3: "Not re-hashed (Q-103 residual): the tip's parent, the commits check_branch counts, merge bases."

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the two store_check calls feed (`MAIN_SHA`, then `sha` and `tree`, each plus its tree and subtree objects) and that the parent and merge bases are read elsewhere. It does not establish that the list is exhaustive for every reader of history (for example rev-list inside check_branch was not traced object by object).
**Legibility-target:** for-orchestrator-synthesis

store_check reads only `"$r" "$r^{tree}"` and `ls-tree -r -t` below each REV (`scripts/build-loop.sh:622-623`). marker_kind reads the parent's tree: `if [[ "$(git rev-parse --verify "$1^{tree}")" != "$(git rev-parse --verify "${p[1]}^{tree}")" ]]` (`scripts/build-loop.sh:492`). merge_result reads the merge bases: `for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done` (`scripts/build-loop.sh:651`). None of these ids is passed to store_check.

**Evidence:** `scripts/build-loop.sh:476-495`, `scripts/build-loop.sh:646-656`, `scripts/build-loop.sh:614-641`

---

## Claim 4: "the branch and brief re-reads went with their refusals, so U3a2's shim reaches only the CAS"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_line at HEAD (no second status read, no second brief_fields) and the lines `main...65007bf8` removed. It does not establish U3a2's shim design, which is not built yet (and see Claim 5 for the U3a2 bullet that still says the opposite).
**Legibility-target:** for-orchestrator-synthesis

check_line reads the brief once, `status_fields "$a"` (`scripts/build-loop.sh:875`), and then takes `Paths:` from it: `# The S rules' inputs: the brief as status_fields read it from main's commit.` (`scripts/build-loop.sh:920`). The removed lines in `git diff main...65007bf8` include `if [[ "$out" != "ok $br $sha "* ... ]]; then echo "refuse $a: its branch $br moved or could not be read again"` and `if brief_fields "$a"; then read_paths; else ... the brief could not be read again from the default branch}"; fi` (paraphrased, no quote available because the lines exist only in the diff output, not in any file at HEAD).

**Evidence:** `scripts/build-loop.sh:870-925`, `git diff main...65007bf8 -- scripts/build-loop.sh`

---

## Claim 5: "A fault-injection shim for the CAS race (G17) also reaches the failed brief re-read (row 625)."

**Location:** `docs/working/plan-build-loop-handoff.md:318`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the U3a2 bullet's sentence against HEAD's check_line and the U3a1 as-built note one line above it. It does not establish what U3a2 will build.
**Legibility-target:** for-author

The fix range edited this bullet (it added "row 512's verdict values, from U3a1") but kept the sentence. HEAD has no brief re-read for a shim to reach (Claim 4), and the as-built note one line above says so: "the branch and brief re-reads went with their refusals, so U3a2's shim reaches only the CAS" (`docs/working/plan-build-loop-handoff.md:317`). The two bullets contradict each other. Precise version: drop "also reaches the failed brief re-read (row 625)" from U3a2, or say row 625 closed with the re-read's removal in U3a1.

**Evidence:** `docs/working/plan-build-loop-handoff.md:317-318`, `scripts/build-loop.sh:870-925`

---

## Claim 6: "Row 512's verdict values (TIP, TREE, verdict) moved to U3a2, their first reader." / U3a2: "row 512's verdict values, from U3a1"

**Location:** `docs/working/plan-build-loop-handoff.md:317-318`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the agreement between the two bullets and the absence of verdict values in check_line. It does not establish that U3a2 is in fact their first reader.
**Legibility-target:** for-orchestrator-synthesis

check_line still prints its verdict and sets no TIP, TREE or verdict global: `if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else ...` (`scripts/build-loop.sh:930`). The status_fields comment now cites only "(row 496)" (`scripts/build-loop.sh:504`), consistent with 512 moving.

**Evidence:** `scripts/build-loop.sh:504`, `scripts/build-loop.sh:870-932`

---

## Claim 7: Help text: the state gate refuses "an info/attributes, info/grafts, shallow or objects/info/alternates (another object store) that is not absent or an empty file"

**Location:** `scripts/build-loop.sh:96-98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the planted non-empty alternates file and the condition used. It does not establish that `GIT_ALTERNATE_OBJECT_DIRECTORIES` in the caller's environment is refused (the caller's environment is trusted by the header's own statement at `:259-260`).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:306-309
  for f in info/attributes info/grafts shallow objects/info/alternates; do
    p="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { echo "refuse state $f: its path could not be read"; return 1; }
    if [[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]; then echo "refuse state $f: present and not an empty file"; bad=1; fi
  done
```

L1 test 1 passes with the exact line `refuse state objects/info/alternates: present and not an empty file`.

**Evidence:** `scripts/build-loop.sh:306-309`, `test/scripts/build-loop-check.bats:1633-1640`, L1

---

## Claim 8: Help text: "main's commit, or a tree or blob of its tree, that does not hash to its id, has a second copy in the object store (two packs, or loose and packed: git may read either) or cannot be read ('refuse state objects: WHY'...)"

**Location:** `scripts/build-loop.sh:102-107`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four causes (mismatch, second pack, loose plus packed, missing tree, plus unreadable .idx or fan-out dir) and the exit 2. It does not establish the stderr contents: on an unreadable index git or bash still print to stderr (L4 P1 "fatal: unable to read index", P2 "Permission denied", P3 "find: './d7': Permission denied"); the help does not claim a silent stderr.
**Legibility-target:** for-orchestrator-synthesis

The refusal string at `scripts/build-loop.sh:854` (quoted in Claim 1) matches. Executed: L1 re-hash test (forged blob, missing tree, second pack, loose copy) and L4 P1-P3 all end `status 2` with that line.

**Evidence:** `scripts/build-loop.sh:850-856`, L1, L4

---

## Claim 9: Help text: per brief, "an object of the tip of BRANCH or of the merge does not hash to its id, has a second copy in the object store, or could not be read": the tip's commit, or a tree or blob of its tree or of TREE (gitlinks aside)

**Location:** `scripts/build-loop.sh:126-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the wording against `:911` and the gitlink exclusion (`$1 != "commit"`). It does not establish a test for an object only in TREE (not in the tip), since every test's merged objects also come from the tip or main.
**Legibility-target:** for-orchestrator-synthesis

`git ls-tree ... "$r" 2>/dev/null | awk '$1 != "commit" { print $2 }'` (`scripts/build-loop.sh:623`) drops gitlinks. The message at `:911` is quoted in Claim 1. L1's re-hash test asserts it exactly for the forged tip blob. L6 P7 shows it for a loose second copy.

**Evidence:** `scripts/build-loop.sh:622-623`, `scripts/build-loop.sh:911`, L1, L6

---

## Claim 10: state_gate header: "Files: an info/attributes, info/grafts or shallow that is not absent or an empty regular file (each changes merges or history)"

**Location:** `scripts/build-loop.sh:289-291`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the function's own header list against its loop. It does not establish anything about the help text, which was updated (Claim 7).
**Legibility-target:** for-author

The fix range added `objects/info/alternates` to the loop (`scripts/build-loop.sh:306`, quoted in Claim 7) and to the help text, but state_gate's own header still lists three files: `# GIT_ALLOW_PROTOCOL already stops its fetch). Files: an info/attributes,` / `# info/grafts or shallow that is not absent or an empty regular file (each` (`scripts/build-loop.sh:289-290`). Precise version: add "or objects/info/alternates (another object store)".

**Evidence:** `scripts/build-loop.sh:284-309`

---

## Claim 11: status_fields comment: "Only for an 'ok' line does STATUS hold its fields by name, each the bare value as printed (... '-' for a branch, sha or date there is none of, and an empty reason), and ahead ... (0 when absent); a skip line sets only line. BRIEF is emptied, then holds what brief_fields read for this brief (whole lines, as brief_fields keeps them; empty for a new brief or one check_brief skips)"

**Location:** `scripts/build-loop.sh:504-513`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every return path of status_fields and BRIEF's state at each. It does not establish BRIEF's contents when brief_fields fails part-way (that path sets STATUS[line] to a skip, and brief_fields empties BRIEF itself on its odd/unbalanced path).
**Legibility-target:** for-orchestrator-synthesis

`STATUS=(); BRIEF=()` (`scripts/build-loop.sh:517`) starts each call. Every skip branch is `{ STATUS[line]="skip ..."; return; }` (for example `:520`, `:526`). The new-brief branch sets `[branch]=- [loop]=absent [sha]=- [ahead]=0 [date]=-` and returns before brief_fields (`:522-524`). check_brief runs in `$(check_brief "$a")` (`:519`), a subshell, so it cannot fill the caller's BRIEF. brief_fields stores `BRIEF["${l%%$'\t'*}"]="${l#*$'\t'}"`, the whole line minus a trailing CR (`scripts/lib/dev-cycle-read.sh:400-413`).

**Evidence:** `scripts/build-loop.sh:515-557`, `scripts/lib/dev-cycle-read.sh:390-415`

---

## Claim 12: store_check: "each verified id is appended to $GATE_TMP/checked, and an id already there (main's, from gate_start) is not read again"

**Location:** `scripts/build-loop.sh:600-602`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the append (perl prints only after a hash matches) and the mawk filter's skip, including over an empty `checked` file. It does not establish that ids printed before a later mismatch in the same call are harmless to later briefs. They are, because those ids did verify, but the file then holds ids from a call that returned 1.
**Legibility-target:** for-orchestrator-synthesis

```perl
# scripts/build-loop.sh:629-631
        Digest::SHA->new($ENV{ALG})->add("$t $s\0", $b)->hexdigest eq $id or exit 1;
        print "$id\n"; $n++;
      }
```

(excerpt ends :631; the enclosing store_check continues to :641, read.) Executed L2: with `checked` holding `aaa`, input `aaa bbb aaa^{tree} bbb` gives `bbb` and `aaa^{tree}`. With an empty `checked`, input `aaa bbb` gives both. The old `NR==FNR` filter over an empty file prints nothing.

**Evidence:** `scripts/build-loop.sh:614-641`, L2

---

## Claim 13: store_check: "Then no checked id may have a second copy: in two packs, or loose and packed. git can read either copy of an id, and two reads of one id ... took different ones (U3a1 i1 security F1 ...). With one copy every read gets the bytes checked here."

**Location:** `scripts/build-loop.sh:602-607`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the duplicate refusal for two packs, loose plus packed and a SHA-256 store, and three hiding attempts that all fail closed: a truncated extra .idx, an unreadable .idx, and a pack covered by a multi-pack-index with its .idx removed (git 2.39.5 then reports "index unavailable", and the check refuses). It does not establish the one-copy-means-one-read property for a writer acting between the scan and a later read (named in the comment), for delta bases outside the checked set (a REF_DELTA base is resolved in its own pack, by reading git's design, not executed), or for git versions other than 2.39.5.
**Legibility-target:** for-orchestrator-synthesis

The scan is quoted in Claim 18. Executed: L1 (second pack and loose copy refused, sha1 and sha256). L4 P4: after `git multi-pack-index write` and removing the second pack's .idx, git logs `error: packfile ... index unavailable` and `multi-pack-index verify` fails, and the check ends `status 2` with `$OBJS`. L4 P1 and P2: an extra pack with a truncated or unreadable .idx refuses. L6 P6: a second pack refuses, and `repack -ad` then passes.

**Evidence:** `scripts/build-loop.sh:602-607`, `scripts/build-loop.sh:633-640`, L1, L4, L6

---

## Claim 14: "Returns 1 on a mismatch, a missing object, a second copy or a failed read."

**Location:** `scripts/build-loop.sh:607-608`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hash mismatch, missing tree, second copy, truncated or unreadable .idx (show-index exit 128 or redirect failure) and failed find on an unreadable fan-out dir. All are observed by the caller's `||`/`if !` under the script's `set -euo pipefail` (`:223`). It does not establish behaviour if `pipefail` were off: the scan's `|| exit 1` and find's status reach the caller only through pipefail.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:634-637
  { for p in "$o"/pack/*.idx; do
      [[ -e "$p" ]] || continue
      git show-index --object-format="$fmt" < "$p" | awk '{ print $2 }' || exit 1
    done
```

(excerpt ends :637; the brace group continues to :640 with the find and the final awk, read.) L3: show-index exits 128 on a half-truncated, table-truncated, offset-truncated or empty .idx. It exits 0 only when just the trailing checksums are cut, and then every id still prints. The redirect fails on an unreadable file. L4 P1-P3 each end `status 2`.

**Evidence:** `scripts/build-loop.sh:223`, `scripts/build-loop.sh:614-641`, L3, L4

---

## Claim 15: "Not checked: objects a decision reaches only through history (the tip's parent, read by marker_kind; the commits check_branch counts; the merge bases ...), and a writer racing ... Reads the real repository's object store, as merge-tree writes into it. Needs GATE_TMP."

**Location:** `scripts/build-loop.sh:608-613`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the residual list (as Claim 3), plain `git` (the real repository) in store_check, gate_repo's `GIT_OBJECT_DIRECTORY` pointing at the real store, and the `$GATE_TMP/checked` dependency. It does not establish that merge-tree's TREE is always written loose rather than packed (immaterial: both are scanned).
**Legibility-target:** for-orchestrator-synthesis

`GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")`, where `v` is the real `--git-path objects` (`scripts/build-loop.sh:580-583`). store_check calls plain `git` and `touch "$GATE_TMP/checked" || return 1` (`:618`).

**Evidence:** `scripts/build-loop.sh:575-584`, `scripts/build-loop.sh:614-641`, `scripts/build-loop.sh:476-495`

---

## Claim 16: "Each object name once, never an id already checked; git's own error for a missing tree is dropped (the missing object fails the check)."

**Location:** `scripts/build-loop.sh:619-620`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ls-tree's stderr being dropped and the failure still reaching the caller (through `|| exit 1` and pipefail, and cat-file's `missing` line failing perl's header regex). It does not establish silent stderr for the other failure modes (Claim 8's scope).
**Legibility-target:** for-orchestrator-synthesis

`git ls-tree -r -t --full-tree --format='%(objecttype) %(objectname)' "$r" 2>/dev/null | awk '$1 != "commit" { print $2 }' || exit 1` (`scripts/build-loop.sh:623`), and perl's `=~ /^([0-9a-f]+) ([a-z]+) ([0-9]+)\n\z/ or exit 1;  # "NAME missing" too` (`:627`). L1's re-hash test removes main's subtree `d` and asserts `$OBJS` with `[ -z "$stderr" ]`.

**Evidence:** `scripts/build-loop.sh:619-632`, `test/scripts/build-loop-check.bats:1882-1885`, L1

---

## Claim 17: "REV^{tree} is never skipped, so 0 read is a fault"

**Location:** `scripts/build-loop.sh:632`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal `REV^{tree}` name passing the skip filter (it is never a bare hex id, so it is never in `checked`), and therefore at least one object read per REV. It does not establish that the skip leaves no unread object a decision needs. Only already-verified ids are skipped (Claim 1's race note).
**Legibility-target:** for-orchestrator-synthesis

`printf '%s\n' "$r" "$r^{tree}"` (`scripts/build-loop.sh:622`) feeds the name with its suffix. L2: with `aaa` in `checked`, `aaa^{tree}` still passes the filter. perl ends `exit($n ? 0 : 1)` (`:632`).

**Evidence:** `scripts/build-loop.sh:622-632`, L2

---

## Claim 18: "Every copy in the store: each pack index's ids, then each loose object file." / "From inside the store: a -path pattern would read glob characters in its path."

**Location:** `scripts/build-loop.sh:633-641`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers every copy git 2.39.5 can read in this store layout: .idx-backed packs, loose files, and a multi-pack-index pack without its .idx, which git cannot read (L4 P4). Alternates are refused by the state gate. It does not establish coverage of copies that another git version could read without an .idx, or of `GIT_ALTERNATE_OBJECT_DIRECTORIES` from the trusted caller's environment.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:639-641
    (cd "$o" && find . -mindepth 2 -maxdepth 2 ! -type d -path './[0123456789abcdef][0123456789abcdef]/*') | awk -F/ '{ print $(NF - 1) $NF }'
  } | awk 'FILENAME != "-" { want[$0]; next } ($0 in want) && n[$0]++ { bad = 1 } END { exit bad }' "$GATE_TMP/checked" -
}
```

The pack loop is quoted in Claim 14. Running find from inside `$o` keeps `$o`'s own characters out of the `-path` pattern. L5 ran the same scan over /workspace: 4 packs, 21,742 packed ids, all distinct, and 21 loose files, none also packed.

**Evidence:** `scripts/build-loop.sh:633-641`, L4, L5

---

## Claim 19: own_blob: "main's copy with its first Status: line outside a fence, the one brief_fields reads (status_fields has read it as 'Status: open')"

**Location:** `scripts/build-loop.sh:657-659`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rename from status_line and check_line's open-only gate before own_blob runs. It does not establish own_blob's callers beyond check_line's rules.
**Legibility-target:** for-orchestrator-synthesis

`status_line` is now a wrapper, `status_line() { status_fields "$1"; echo "${STATUS[line]}"; }` (`scripts/build-loop.sh:558`). check_line refuses anything but open after `status_fields "$a"`: `if [[ "$st" != open ]]; then echo "refuse $a: the brief is $st ..."` (`:878`).

**Evidence:** `scripts/build-loop.sh:558`, `scripts/build-loop.sh:657-669`, `scripts/build-loop.sh:875-878`

---

## Claim 20: gate_start: "main's commit and tree re-hashed, each object with one copy (store_check); then the reader lists ... The repository rule: main's files and refs, the branch tips, the checkout and store_check's object reads are in the real repository; the merge computations ... run through gate_git."

**Location:** `scripts/build-loop.sh:840-849`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order inside gate_start and, in an executed call log, that the only object reads before `cat-file --batch` are resolve_main's `rev-parse ^{commit}` and store_check's own `ls-tree`. It does not establish the order with a settings file or constraints doc on main (the probe fixture has neither).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:850-856
gate_start() {
  default_gate || exit 2
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
  gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
  store_check "$MAIN_SHA" || { echo "refuse state objects: ..."; exit 2; }
  reader_settings; read_settings; never_res; open_shared
}
```

(the store_check line is shortened at its message; it is quoted in full in Claim 1.) L4 P5 lists the git calls: state gate calls, then `rev-parse --verify --quiet ...^{commit}`, `show-ref`, `rev-parse --local-env-vars`, `ls-tree -r -t ...`, `cat-file --batch`. After those come `ls-tree -- docs docs/dev-cycle.md`, `grep ... -- docs/working/briefs/` and the first `cat-file blob`.

**Evidence:** `scripts/build-loop.sh:840-856`, L4

---

## Claim 21: check_line: "or one skip or refuse line (status_fields' STATUS[line], then the gate's own reasons)"

**Location:** `scripts/build-loop.sh:861-862`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the first non-ok exit of check_line. It does not establish the full set of the gate's own refusal lines (help text, checked in iteration 1).
**Legibility-target:** for-orchestrator-synthesis

`[[ "${STATUS[line]}" == "ok "* ]] || { echo "${STATUS[line]}"; return; }` (`scripts/build-loop.sh:876`), followed by the gate's own `refuse` lines (`:878-911`).

**Evidence:** `scripts/build-loop.sh:870-911`

---

## Claim 22: Planted-state test adds `objects/info/alternates` and expects its refusal line in order

**Location:** `test/scripts/build-loop-check.bats:1633-1640`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a non-empty alternates file. It does not establish the symlink or directory forms of the condition (`-L`, `! -f`) for this file (they are shared with the other three files).
**Legibility-target:** for-orchestrator-synthesis

`echo "$BATS_TEST_TMPDIR/elsewhere" > .git/objects/info/alternates` (`:1633`), with the expected output line `refuse state objects/info/alternates: present and not an empty file` (`:1640`). Passes in L1.

**Evidence:** `test/scripts/build-loop-check.bats:1626-1643`, L1

---

## Claim 23: "Packed, with a second copy of the brief's blob: store_check reads SHA-256 pack indexes (U3a1)."

**Location:** `test/scripts/build-loop-check.bats:1723`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the packed pass (which proves `show-index --object-format=sha256` reads the index, since a failed read refuses) and the second-pack refusal. It does not establish a loose-plus-packed duplicate in SHA-256.
**Legibility-target:** for-orchestrator-synthesis

`git repack -adq; chk "$B"; [ "$status" -eq 0 ]` and then `chk "$B"; [ "$status" -eq 2 ] && [ "$output" = "$OBJS" ]` (`:1724-1726`). Passes in L1.

**Evidence:** `test/scripts/build-loop-check.bats:1716-1727`, L1

---

## Claim 24: "loose ID: a loose copy of packed blob ID, beside the packed one (git itself writes none for an object it has)."

**Location:** `test/scripts/build-loop-check.bats:1862`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git hash-object -w` on a packed blob's bytes in git 2.39.5. It does not establish other writers (fast-import, unpack-objects).
**Legibility-target:** for-orchestrator-synthesis

L6 P6: after `git repack -adq`, `git cat-file blob "$o" | git hash-object -w --stdin` leaves `.git/objects/${o:0:2}/${o:2}` absent ("hash-object -w wrote no loose copy").

**Evidence:** `test/scripts/build-loop-check.bats:1862-1865`, L6

---

## Claim 25: Test title: "--check re-hashes what it reads: a rewritten, missing or second copy of an object of main's tree refuses the state before any brief; of the tip's tree, the brief; a packed store passes (rows 492, 503, U3a1, i1 security F1)"

**Location:** `test/scripts/build-loop-check.bats:1867`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each case the title names: a packed pass, a second pack and a loose copy of main's brief blob, a forged main blob, a missing main subtree, a forged tip blob, and a loose copy of a tip blob. It does not establish "a missing object of the tip's tree" (not named).
**Legibility-target:** for-orchestrator-synthesis

Each case is a `chk "$B"` with its assertion (`:1868-1891`), for example `o="$(git rev-parse "main:$B")"; echo "$o" | git pack-objects -q .git/objects/pack/pack >/dev/null` then `[ "$output" = "$OBJS" ] && [ -z "$stderr" ]` (`:1873-1874`). Passes in L1.

**Evidence:** `test/scripts/build-loop-check.bats:1867-1892`, L1

---

## Claim 26: "The tip's own file, rewritten, then a second copy of it: that brief refuses, with no path line."

**Location:** `test/scripts/build-loop-check.bats:1886-1891`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code's behaviour (both cases print one line and no path line) and what the test asserts. It does not establish anything beyond the tip-blob cases.
**Legibility-target:** for-author

The rewritten case asserts the whole output with `=` (`:1888`), which pins "no path line". The second-copy case asserts only a prefix: `[[ "$output" == "refuse $B: an object of the tip of feat/x or of the merge "* ]]` (`:1891`). A path line after it would still pass. Executed L6 P7: the code prints one line (`lines 1`), so the behaviour holds but this case's assertion does not test it. Precise version: compare the whole output with `=` in the loose case too, or narrow the comment to the rewritten case.

**Evidence:** `test/scripts/build-loop-check.bats:1886-1891`, L6

---

## Claim 27: "store_check re-hashes main's objects before the first blob of main is read (the settings: U3a1 i1 architecture 1)."

**Location:** `test/scripts/build-loop-check.bats:1941-1944`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertion (first `cat-file --batch` line before the first `^cat-file blob ` line) and the real call order in this fixture. It does not establish ordering against blob readers other than `cat-file blob` (for example `git grep`), which the assertion does not match.
**Legibility-target:** for-author

The assertion greps only `'^cat-file blob '` (`:1943`). In L4 P5's call log (same fixture shape: `gated feat/x`, no settings file), the first blob reader after `cat-file --batch` is `grep --no-color -l -E ^Status: open?$ MAIN -- docs/working/briefs/` (open_shared), and the first `cat-file blob` is the brief, not the settings. The order the comment promises holds, but the parenthetical "the settings" names a read this fixture does not make, and a blob read by `git grep` or `ls-tree` before store_check would not fail the test. Precise version: "before the first `cat-file blob` of main (here the brief)".

**Evidence:** `test/scripts/build-loop-check.bats:1931-1949`, L1, L4

---

## Claim 28: Commit 83f75281: "A2: the NR == FNR filter over an empty checked file read stdin as the first file; FILENAME is tested, and perl fails when it reads no object."

**Location:** commit `83f75281` message, paragraph 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk's behaviour for both filters and perl's zero-object exit. It does not establish that "perl fails when it reads no object" is new in this commit: `exit($n ? 0 : 1)` was already at 65007bf8 (the diff changes only the redirect on that line), and that guard is why the A2 bug failed closed rather than passing.
**Legibility-target:** for-orchestrator-synthesis

L2 shows the old idiom over an empty file printing nothing, and the new filter printing every input name. `exit($n ? 0 : 1)' >> "$GATE_TMP/checked" || return 1` (`scripts/build-loop.sh:632`).

**Evidence:** `scripts/build-loop.sh:624-632`, L2

---

## Claim 29: Commit 83f75281 Notes: "/workspace's 21,742 packed ids have none."

**Location:** commit `83f75281` message, Notes
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace's store as of 2026-10-10T18:43:43Z (a time-varying input: a repack or a fetch changes it), over all ids, not only main's. It does not establish the state at commit time.
**Legibility-target:** for-orchestrator-synthesis

L5: `packed ids: 21742`, `distinct: 21742`, `loose: 21`, `loose also packed: 0`. True as of the store at 18:43:43Z.

**Evidence:** L5

---

## Claim 30: Commit 83f75281 Notes: "a legitimately duplicated object (overlapping packs) now refuses --check ... git repack -ad clears it."

**Location:** commit `83f75281` message, Notes
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a genuine (same-bytes) second pack refusing and `git repack -adq` restoring `ok`. It does not establish a loose duplicate, which `repack -ad` also packs; that path appears in the re-hash test only together with `loose`.
**Legibility-target:** for-orchestrator-synthesis

L6 P6: a second pack of the brief's genuine blob gives `status 2` with `$OBJS`. After `git repack -adq` (one pack left), the check gives `status 0` with `ok ...`.

**Evidence:** L6

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 5** (`docs/working/plan-build-loop-handoff.md:318`): the U3a2 bullet still says its shim "also reaches the failed brief re-read (row 625)". U3a1 removed that re-read, and the as-built note on `:317` says the shim reaches only the CAS.
- **Claim 10** (`scripts/build-loop.sh:289-291`): state_gate's header lists only info/attributes, info/grafts and shallow. The loop at `:306` and the help text now include objects/info/alternates.

### Mostly Accurate
- **Claim 26** (`test/scripts/build-loop-check.bats:1886-1891`): "with no path line" is asserted only for the rewritten case. The loose second-copy case uses a prefix glob (the code does print one line, per L6 P7).
- **Claim 27** (`test/scripts/build-loop-check.bats:1941`): the call-log check matches only `cat-file blob`. In this fixture the first such read is the brief, not "the settings", and an earlier `git grep` blob read would not be caught.

### Unverifiable
- None.

## Goal-Alignment Note

**Success criterion (restated verbatim):** "a markdown report saved at the path your dispatch names, structured per your skill."
**Answered:** Yes. The report is saved at `docs/reviews/code-fact-check-report-build-loop-u3a1-i2.md` with `**Commit:** 83f75281` and `**Replication:** k=1 (loop pass, decision 031)`. All three brief items are verdicted: A1 sufficiency and fail-closed paths (Claims 2, 8, 13, 14, 18, 30; executed probes for a truncated or unreadable .idx, an unreadable fan-out dir, a multi-pack-index pack without .idx, and /workspace's store), A2 and the skip (Claims 1, 12, 17, 28), and comments, help, plan and tests (Claims 3-11, 15-16, 19-27).
**Out of scope:** whether the widened race window for ids that main and the merge share (verified once at gate_start, then skipped per brief: Claim 1's scope) matters for a decision is the security critic's call. So are REF_DELTA bases outside the checked set (Claim 13's scope, by reading only) and git versions other than 2.39.5.
**Escalate:** None blocking. Legibility targets: Claims 5, 10, 26, 27 are for-author. Claims 1-4, 6-9, 11-25 and 28-30 are for-orchestrator-synthesis.
