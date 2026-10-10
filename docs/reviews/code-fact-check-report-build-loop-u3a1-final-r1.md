# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u3a1`, branch `feat/build-loop-u3a1`)
**Scope:** full branch `main...HEAD` (d5736445..d10cfba8), docs/reviews excluded: `scripts/build-loop.sh` (read whole, post-change), `test/scripts/build-loop-check.bats` (the changed tests), `docs/working/plan-build-loop-handoff.md` step 7 (U3a1 as-built note, U3a2 bullet), and the messages of commits 65007bf8, 83f75281 and d10cfba8. `scripts/lib/dev-cycle-read.sh` (brief_fields, check_brief, check_branch, open_shared, resolve_main, main_file) was read as context only.
**Commit:** d10cfba8
**Replication:** k=3, replicate r1 (final confirming pass)
**Checked:** 2026-10-10
**Total claims checked:** 26
**Summary:** 24 verified, 1 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read first: no entry concerns git object stores, pack indexes, awk or bash associative arrays, and no claim below matches a logged pattern.

Settled rows not re-filed (code unchanged under them): commit 65007bf8 citing rows 496/512 and row 625 (override rows 643, 645); store_check's history residual (row 638); main's ids re-hashed once per run (row 646).

Execution logs (all under `S=/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-f/fact-check-r1/`):

| Log | Command | cwd | Exit | Started (UTC) |
|---|---|---|---|---|
| L1 `$S/logs/L1-bats.log` | `TMPDIR=$S/tmp LC_ALL=C timeout 900 bats -f 're-hashes what it reads\|second-copy scan\|carries harden\|state gate before resolve_main\|planted\|SHA-256\|status' test/scripts/build-loop-check.bats` | worktree | 0 (12/12 ok) | 2026-10-10T19:01:31Z |
| L2 `$S/logs/L2-status-diff.log` | `timeout 300 $S/bin/probe-status.sh` (main's and HEAD's `scripts/` extracted with `git archive`, both run `--status` over 10 brief paths in one throwaway repo: ready, stopped REASON with self-merge and Dispatched: 3, working not-ahead, done absent, bad marker, bad Branch:, bad Dispatched:, two new, a non-brief; stdout and stderr compared with `cmp`) | `$S` (repo under a `mktemp -d` in `$S/tmp`, removed at end) | 0 | 2026-10-10T19:02:03Z |

Probe safety: the probe script starts `set -eu`, makes its temp dir in the same script, refuses to `git init`/`commit` unless `pwd` is under it, and removes it. No process was left running.

---

## Claim 1: "store_check runs once for main in gate_start (a mismatch is `refuse state objects`, exit 2) and per brief for the tip and the merge's tree, skipping ids already checked"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two call sites, the startup refusal and the skip set; does not establish anything about the race residual (settled row 646).
**Legibility-target:** for-author (plan as-built note, read by the U3a2 planner)

The call sites and refusal hold:

```bash
# scripts/build-loop.sh:858-859
  store_check "$MAIN_SHA" && mv "$GATE_TMP/call" "$GATE_TMP/main" \
    || { echo "refuse state objects: ..."; exit 2; }
# scripts/build-loop.sh:916
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of the tip of $br or of the merge ..."; return; fi
```

But the skip set is now main's ids only, not every id already checked: the read filter is `awk 'FILENAME != "-" { seen[$0]; next } !($0 in seen) { seen[$0]; print }' "$GATE_TMP/main" -` (`scripts/build-loop.sh:628`), and each call's ids go to `> "$GATE_TMP/call"` (`:636`), overwritten per call. So brief 2 re-reads ids brief 1 checked. The phrase was accurate at 83f75281, when an appended `$GATE_TMP/checked` file was the skip set (paraphrased — no quote available because that version is replaced; seen in the i2 fact-check report's Claim 1 quote of `:624`, `:630`, `:632`). d10cfba8 (B1) narrowed it; the store_check comment (`:601-602`, "an id in $GATE_TMP/main (main's, ...) is not read again") says so, but the plan note was not updated. Precise wording: "skipping main's ids".

**Evidence:** `scripts/build-loop.sh:618-645`, `scripts/build-loop.sh:858-859`, `scripts/build-loop.sh:916`, `docs/working/plan-build-loop-handoff.md:317`

---

## Claim 2: "it also refuses an id of main's or of that call with a second copy in the store, listed as git opens them (links, dot-named packs ...), harden switches off the multi-pack-index, and the state gate refuses `objects/info/alternates`. One brief's refusal does not carry to the next"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the duplicate scan's want-set (main's plus this call's ids), find -L, dot-named packs, the multiPackIndex pin and the alternates refusal, each run in L1; does not establish coverage of copies reachable only through `GIT_ALTERNATE_OBJECT_DIRECTORIES` in the trusted caller's environment, or git versions other than the one installed.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:641-644
  { (cd "$o" && find -L pack -mindepth 1 -maxdepth 1 -name '*.idx' ! -type d) > "$GATE_TMP/idx" || exit 1
    while IFS= read -r r; do git show-index --object-format="$fmt" < "$o/$r" | awk '{ print $2 }' || exit 1; done < "$GATE_TMP/idx"
    (cd "$o" && find -L . -mindepth 2 -maxdepth 2 ! -type d -path './[0123456789abcdef][0123456789abcdef]/*') | awk -F/ '{ print $(NF - 1) $NF }'
  } | awk 'FILENAME != "-" { want[$0]; next } ($0 in want) && n[$0]++ { bad = 1 } END { exit bad }' "$GATE_TMP/main" "$GATE_TMP/call" -
```

`core.multiPackIndex=false` is in harden's list (`:273`); the alternates check is `for f in info/attributes info/grafts shallow objects/info/alternates` (`:307`). Executed in L1: the dot-named pack and linked fan-out cases (test "second-copy scan"), the config-pairs test, the planted-state test, and the two-brief run in both orders (`test/scripts/build-loop-check.bats:1894-1897`) all pass.

**Evidence:** `scripts/build-loop.sh:271-277`, `scripts/build-loop.sh:307-310`, `scripts/build-loop.sh:637-644`, `test/scripts/build-loop-check.bats:1894-1913`, `$S/logs/L1-bats.log`

---

## Claim 3: "Main's objects are re-hashed once per run, so a rewrite of one in place after startup is the race residual. Not re-hashed (Q-103 residual): the tip's parent, the commits check_branch counts, merge bases."

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which objects store_check reads (REVs main, tip, merge tree and what ls-tree lists under them); does not establish whether the residual matters (settled rows 638, 646).
**Legibility-target:** for-orchestrator-synthesis

store_check reads only `printf '%s\n' "$r" "$r^{tree}"` and `git ls-tree -r -t --full-tree ... "$r"` per REV (`scripts/build-loop.sh:626-627`); its callers pass `"$MAIN_SHA"` (`:858`) and `"$sha" "$tree"` (`:916`). The tip's parent is read by marker_kind's `git rev-parse --verify "${p[1]}^{tree}"` (`:493`), merge bases by `gate_git merge-base --all` (`:652`), and the counted commits by check_branch's `git rev-list --count "$MAIN_SHA..$sha"` (lib, `scripts/lib/dev-cycle-read.sh:488`); none of these is a store_check REV.

**Evidence:** `scripts/build-loop.sh:618-628`, `scripts/build-loop.sh:493`, `scripts/build-loop.sh:652`, `scripts/build-loop.sh:858`, `scripts/build-loop.sh:916`, `scripts/lib/dev-cycle-read.sh:477-501`

---

## Claim 4: "status_fields (row 496) and gate_start (row 525) as planned; the branch and brief re-reads went with their refusals, so U3a2's shim reaches only the CAS. Row 512's verdict values (TIP, TREE, verdict) moved to U3a2" (and the U3a2 bullet: "the failed brief re-read row 625 named is gone (U3a1)")

**Location:** `docs/working/plan-build-loop-handoff.md:317-318`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of check_line's second check_branch and brief_fields calls and of their refusal texts; does not establish U3a2's future shim design.
**Legibility-target:** for-orchestrator-synthesis

check_line now reads only `status_fields "$a"` and STATUS values (`scripts/build-loop.sh:880-886`), then `[[ "$pol" != self-merge ]] || read_paths` (`:927`) from the BRIEF status_fields left. Main's version had `out="$(check_branch "$br")"` with "moved or could not be read again" and `if brief_fields "$a"; then read_paths; else ... "the brief could not be read again from the default branch"` (from `git show main:scripts/build-loop.sh`, check_line). Neither text exists in HEAD (paraphrased — no quote available because the claim is about absence: `grep -n "read again" scripts/build-loop.sh` hits only store_check's comment at `:602`, nothing in check_line). No verdict-value function exists in HEAD, consistent with "moved to U3a2".

**Evidence:** `scripts/build-loop.sh:875-939`, `docs/working/plan-build-loop-handoff.md:317-318`

---

## Claim 5: Help: "then main's commit, or a tree or blob of its tree, that does not hash to its id, has a second copy in the object store (two packs, or loose and packed: git may read either) or cannot be read ("refuse state objects: WHY"; every file the gate reads from main is one). Each finding prints "refuse state WHAT: WHY" and exits 2 before the settings or any brief is read."

**Location:** `scripts/build-loop.sh:102-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order state_gate, resolve_main/main_by_name, default_gate, gate_repo, store_check, then reader_settings/read_settings, and the exit 2 with only the refusal line; does not establish that blobs read from main's history (check_brief's `git log -G`, which feeds no --check decision) are checked.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:342-349
if [[ -n "$GATED" ]]; then state_gate || exit 2; fi
resolve_main || true
main_by_name || { ...; exit 1; }
...
[[ -n "$GATED" ]] || reader_settings
# scripts/build-loop.sh:855-860
  default_gate || exit 2
  ...
  store_check "$MAIN_SHA" && mv "$GATE_TMP/call" "$GATE_TMP/main" \
    || { echo "refuse state objects: ..."; exit 2; }
  reader_settings; read_settings; never_res; open_shared
```

Every main read (main_file, brief_fields, own_blob, import walk) uses `git cat-file blob "$MAIN_SHA:..."` (`scripts/lib/dev-cycle-read.sh:399`, `:560`, `:1774`), i.e. a blob of main's tree. Executed (L1): the re-hash test expects `$output` exactly `$OBJS` with exit 2 for a forged brief blob, a missing tree and two kinds of second copy; the A15 test finds the first `cat-file --batch` call before the first `cat-file blob` call.

**Evidence:** `scripts/build-loop.sh:339-349`, `scripts/build-loop.sh:854-861`, `test/scripts/build-loop-check.bats:1867-1885`, `test/scripts/build-loop-check.bats:1959-1962`, `$S/logs/L1-bats.log`

---

## Claim 6: Help: per brief, "an object of the tip of BRANCH or of the merge does not hash to its id, has a second copy in the object store, or could not be read": the tip's commit, or a tree or blob of its tree or of TREE (gitlinks aside)

**Location:** `scripts/build-loop.sh:126-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal text, the REVs passed and the gitlink filter; does not establish the order of this refusal relative to the others (the help does not claim one; it runs after the missing-blob check, `:911-916`).
**Legibility-target:** for-orchestrator-synthesis

`store_check "$sha" "$tree"` (`scripts/build-loop.sh:916`) with `awk '$1 != "commit" { print $2 }'` over ls-tree's `%(objecttype) %(objectname)` (`:627`) drops gitlinks. Executed (L1): the rewritten and loose-second-copy tip file cases print exactly the one refusal line, exit 2 (`test/scripts/build-loop-check.bats:1886-1893`).

**Evidence:** `scripts/build-loop.sh:627`, `scripts/build-loop.sh:916`, `test/scripts/build-loop-check.bats:1886-1893`, `$S/logs/L1-bats.log`

---

## Claim 7: harden: "Every git call in this process, the lib's included, runs hardened ... no multi-pack-index (a second route to an object, past store_check's listing)"

**Location:** `scripts/build-loop.sh:259-277`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pair being exported and carried by every logged git call, gate_git's included (GATE_ENV keeps GIT_CONFIG_COUNT and the KEY/VALUE variables); does not establish what git does with a multi-pack-index when the pin is absent.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:273
  for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false core.multiPackIndex=false; do
```

gate_repo unsets only `git rev-parse --local-env-vars` names that are not callervar (`:579`, `:575`, which keeps GIT_CONFIG_COUNT). Executed (L1): the config-pairs test logs every git call through a PATH shim (which `env ... git` in gate_git also reaches) and finds none without ` core.multiPackIndex=false`.

**Evidence:** `scripts/build-loop.sh:271-278`, `scripts/build-loop.sh:575-584`, `test/scripts/build-loop-check.bats:1675-1688`, `$S/logs/L1-bats.log`

---

## Claim 8: state_gate header: "Files: an info/attributes, info/grafts, shallow or objects/info/alternates that is not absent or an empty regular file (each changes merges, history or the objects read)"

**Location:** `scripts/build-loop.sh:290-292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four paths and the non-empty/symlink/non-file test; does not establish other alternate sources (GIT_ALTERNATE_OBJECT_DIRECTORIES, trusted caller env).
**Legibility-target:** for-orchestrator-synthesis

`if [[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]` over the four names (`scripts/build-loop.sh:307-310`). Executed (L1): the planted-state test expects `refuse state objects/info/alternates: present and not an empty file` in order (`test/scripts/build-loop-check.bats:1633-1640`).

**Evidence:** `scripts/build-loop.sh:307-310`, `test/scripts/build-loop-check.bats:1626-1643`, `$S/logs/L1-bats.log`

---

## Claim 9: "--check refuses planted state before any git call reads an object (resolve_main does); gate_start runs the rest of its startup." / GATED "a mode that decides" at both top-level sites

**Location:** `scripts/build-loop.sh:339-349`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two GATED sites and their effect for --check vs --status/--settings; does not establish anything about U3a2's future --merge mode setting GATED.
**Legibility-target:** for-orchestrator-synthesis

`GATED=""; [[ "$MODE" != check ]] || GATED=1` (`:341`), used at `:342` (state_gate) and `:349` (`[[ -n "$GATED" ]] || reader_settings`); gate_start calls reader_settings itself (`:860`). Executed (L1): A15's ordering assertion (the refs/replace gate call precedes the first `^{commit}` read) passes; --status still prints its lines (L2).

**Evidence:** `scripts/build-loop.sh:339-349`, `scripts/build-loop.sh:860`, `$S/logs/L1-bats.log`, `$S/logs/L2-status-diff.log`

---

## Claim 10: status_fields comment: "STATUS[line] is the line --status prints. Only for an "ok" line does STATUS hold its fields by name ... '-' for a branch, sha or date there is none of, and an empty reason), and ahead ... (0 when absent); a skip line sets only line. BRIEF is emptied, then holds what brief_fields read for this brief (... empty for a new brief or one check_brief skips): check_line takes Paths: from it, so nothing between may call brief_fields."

**Location:** `scripts/build-loop.sh:505-514`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every return path of status_fields and the calls between it and read_paths in check_line; does not establish anything for future callers.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:518-521
  STATUS=(); BRIEF=()
  open_shared
  out="$(check_brief "$a")"
  [[ "$out" == "ok "* ]] || { STATUS[line]="$out"; return; }
```

The new-brief branch assigns all ten keys with `[branch]=- [loop]=absent [sha]=- [ahead]=0 [date]=- ... [reason]=""` (`:524`); the final assignment sets `sha=- ahead=0 date=- loop=absent` defaults before check_branch (`:542`) and all keys (`:556-557`); every skip sets only `STATUS[line]` after `STATUS=()`. check_brief runs in `$(...)` and open_shared declares `local -A ... BRIEF=()` (lib `:505`), so neither touches the caller's BRIEF. Between `status_fields` (`:880`) and `read_paths` (`:927`), check_line calls merge_result, gate_git, store_check and checkout_gate, none of which calls brief_fields (paraphrased — no quote available because the claim covers absence: grep for `brief_fields` in `scripts/build-loop.sh` hits only `:527` and comments).

**Evidence:** `scripts/build-loop.sh:505-558`, `scripts/build-loop.sh:875-927`, `scripts/lib/dev-cycle-read.sh:503-506`

---

## Claim 11: status_fields keeps --status's output: `status_line() { status_fields "$1"; echo "${STATUS[line]}"; }` prints what main's status_line printed (PR intent: byte-identical)

**Location:** `scripts/build-loop.sh:556-559`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ten brief paths across ok (ready, stopped with REASON, working not-ahead, done/absent, new), skip (bad marker, bad Branch:, bad Dispatched:, non-brief) and self-merge with Dispatched: 3, stdout and stderr; does not establish the skip texts for an unlistable OPEN_SHARED or a shared branch, which were read (identical text) but not run.
**Legibility-target:** for-orchestrator-synthesis

Main's `echo "ok $a $st $pol $br absent - - $disp"` and `echo "ok $a $st $pol $br $loop $sha $date $disp$reason"` with `reason=" ${kind#stopped }"` become `[line]="ok $a $st $pol $br $loop $sha $date $disp${reason:+ $reason}"` with `sha=- date=- loop=absent` for an absent branch (`scripts/build-loop.sh:542`, `:556`). Executed (L2): `cmp` reports stdout and stderr identical between main's and HEAD's script, both exit 0.

**Evidence:** `scripts/build-loop.sh:516-559`, `$S/logs/L2-status-diff.log`

---

## Claim 12: store_check comment: "Each REV (a commit or a tree), its root tree, and every tree and blob below it ... are read in one cat-file --batch and re-hashed by one perl, for sha1 or sha256, but an id in $GATE_TMP/main (main's, which gate_start's call leaves there) is not read again. Then no id of main's or of this call may have a second copy in the store ... Only one call's ids are judged, so one brief's refusal never carries to the next ... Returns 1 on a mismatch, a missing object, a second copy or a failed read."

**Location:** `scripts/build-loop.sh:595-617`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read set, the skip, the hash formula, the want-set and each failure path's return; does not establish REF_DELTA bases outside the checked set, nor the race (named in the comment).
**Legibility-target:** for-orchestrator-synthesis

```perl
# scripts/build-loop.sh:631-636
        my ($id, $t, $s) = $h =~ /^([0-9a-f]+) ([a-z]+) ([0-9]+)\n\z/ or exit 1;  # "NAME missing" too
        read(STDIN, my $b, $s) == $s && (getc(STDIN) // "") eq "\n" or exit 1;
        Digest::SHA->new($ENV{ALG})->add("$t $s\0", $b)->hexdigest eq $id or exit 1;
        print "$id\n"; $n++;
      }
      exit($n ? 0 : 1)' > "$GATE_TMP/call" || return 1
```

store_check is only called in conditions (`:858`, `:916`), so set -e is off inside and pipefail makes a failing `find`, `show-index` or `ls-tree` fail the pipeline. gate_start moves the first call's list to `main` (`:858`). Executed (L1): mismatch, missing tree, second copy (pack, loose, dot-pack, linked dir) and the two-brief order cases.

**Evidence:** `scripts/build-loop.sh:595-645`, `scripts/build-loop.sh:858`, `test/scripts/build-loop-check.bats:1867-1913`, `$S/logs/L1-bats.log`

---

## Claim 13: "Each object name once, never one of main's ids; git's own error for a missing tree is dropped (the missing object fails the check)." / "REV^{tree} is never skipped, so 0 read is a fault"

**Location:** `scripts/build-loop.sh:623-624`, `scripts/build-loop.sh:636`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the awk de-duplication by name and the literal `REV^{tree}` name never matching a hex id in `main`; does not establish de-duplication by resolved object (`REV` and `REV^{tree}` can resolve to an id ls-tree also lists; read twice, harmless).
**Legibility-target:** for-orchestrator-synthesis

`printf '%s\n' "$r" "$r^{tree}"` (`:626`) emits a literal `...^{tree}` name, which the `!($0 in seen)` filter over main's hex ids (`:628`) cannot drop; `git ls-tree ... 2>/dev/null` (`:627`). Executed (L1): the missing-tree case asserts `[ -z "$stderr" ]`.

**Evidence:** `scripts/build-loop.sh:623-636`, `test/scripts/build-loop-check.bats:1881-1884`, `$S/logs/L1-bats.log`

---

## Claim 14: gate_start comment: order default_gate, gate repository, store_check, then the reader lists, settings, never globs and open briefs "(once, in this shell)"; "The repository rule: main's files and refs, the branch tips, the checkout and store_check's object reads are in the real repository; the merge computations (merge-base, merge-tree, diff-tree, the blob checks) run through gate_git."

**Location:** `scripts/build-loop.sh:844-853`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers gate_start's body and every git call site in check_line, merge_result, own_blob and store_check; does not establish the lib's internal calls beyond those named.
**Legibility-target:** for-orchestrator-synthesis

Body quoted in Claim 5. gate_git carries `merge-base --all` and `cat-file -e` (`:652`, `:655`), `merge-tree --write-tree` (`:656`), `diff-tree` (`:895`), `cat-file --batch-check` (`:911`) and own_blob's `hash-object` (`:672`); store_check uses plain `git cat-file --batch` (`:628`), and checkout_gate plain `git status`/`ls-files` (`:801-815`). "each refusal a 'refuse state' line and exit 2" holds for gate_start's three refusals; mktemp failure is exit 1 with no line, as the header's exit list says (`:221`).

**Evidence:** `scripts/build-loop.sh:844-861`, `scripts/build-loop.sh:646-673`, `scripts/build-loop.sh:895-916`

---

## Claim 15: check_line comment: "or one skip or refuse line (status_fields' STATUS[line], then the gate's own reasons) ... each helper empties its own globals before use (DENY, PATHS and PATHS_WHY, LIST, LIST_WHY and LIST_BAD, STATUS, BRIEF, CHECKOUT_WHY, FLOOR_WHY, TRUTH_WHY)" and "The tip's objects and the merge's, re-hashed (main's were, in gate_start)."

**Location:** `scripts/build-loop.sh:862-874`, `scripts/build-loop.sh:915`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers STATUS, BRIEF (emptied at `:518`) and the per-call `$GATE_TMP/call` overwrite; does not establish FLOOR_WHY/TRUTH_WHY resets (lib, unchanged by this branch, not re-read).
**Legibility-target:** for-orchestrator-synthesis

`[[ "${STATUS[line]}" == "ok "* ]] || { echo "${STATUS[line]}"; return; }` (`:881`). `$GATE_TMP/main` persists across briefs by design (main's ids), and `> "$GATE_TMP/call"` (`:636`) resets the per-call set. Executed (L1): the two-brief run in both orders gives `ok` for brief y whichever order.

**Evidence:** `scripts/build-loop.sh:875-916`, `test/scripts/build-loop-check.bats:1894-1897`, `$S/logs/L1-bats.log`

---

## Claim 16: "The S rules' inputs: the brief as status_fields read it from main's commit."

**Location:** `scripts/build-loop.sh:925-927`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers read_paths reading `BRIEF[paths]` left by status_fields; does not establish the S rules themselves (unchanged).
**Legibility-target:** for-orchestrator-synthesis

`[[ "$pol" != self-merge ]] || read_paths` (`:927`) and `[[ -n "${BRIEF[paths]+set}" ]] || return 0; list_entries "${BRIEF[paths]}" Paths path pathform` (`:717-718`); BRIEF set by `brief_fields "$a"` in status_fields (`:527`) from `git cat-file blob "$MAIN_SHA:$1"` (lib `:399`).

**Evidence:** `scripts/build-loop.sh:527`, `scripts/build-loop.sh:714-720`, `scripts/build-loop.sh:925-927`

---

## Claim 17: Test "--check re-hashes what it reads: a rewritten, missing or second copy of an object of main's tree refuses the state before any brief; of the tip's tree, the brief; a packed store passes" and its comments (`git reads the forged bytes ...; the gate refuses before reading it`; "The tip's own file, rewritten, then a second copy of it: that brief refuses, with no path line"; "One brief's refusal does not carry to the next")

**Location:** `test/scripts/build-loop-check.bats:1867-1898`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each case the title names for main's tree and the rewritten and second-copy cases for the tip; does not establish a missing tip object reaching store_check (a missing tip object fails earlier, at merge_result).
**Legibility-target:** for-orchestrator-synthesis

The forged blob reads back: `[ "$(git cat-file blob "$o" | grep Branch)" = "Branch: feat/y" ]` (`:1879`), then `[ "$output" = "$OBJS" ] && [ -z "$stderr" ]` (`:1880`). Both tip cases now compare `$output` exactly to the one refusal line (`:1888-1893`), so "no path line" is asserted for both. Executed: L1 `ok 8`.

**Evidence:** `test/scripts/build-loop-check.bats:1858-1898`, `$S/logs/L1-bats.log`

---

## Claim 18: Test title "--check's second-copy scan lists what git opens: a pack named with a leading dot, a linked fan-out directory, and no multi-pack-index route (U3a1 i2 security F1)"

**Location:** `test/scripts/build-loop-check.bats:1900`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the dot-named pack and the linked fan-out cases, which pass; does not establish the "no multi-pack-index route" part, which this test never sets up.
**Legibility-target:** for-author (test title)

The body builds `.git/objects/pack/.hidden.*` (`:1904`) and a symlinked fan-out directory (`:1909`) and expects `$OBJS` for each. It never runs `git multi-pack-index write` and never checks a midx (paraphrased — no quote available because the claim covers absence: the test body `:1900-1912` has no `multi-pack-index` text). The pin is checked elsewhere, by the config-pairs test's `core.multiPackIndex=false` entry (`:1685`). Precise version: drop "and no multi-pack-index route" from the title or say "(the pin: the config-pairs test)".

**Evidence:** `test/scripts/build-loop-check.bats:1900-1912`, `test/scripts/build-loop-check.bats:1685`, `$S/logs/L1-bats.log`

---

## Claim 19: forge/loose helpers: "forge ID TEXT: rewrite loose object ID's file to hold a blob of TEXT, its id unchanged." / "loose ID: a loose copy of packed blob ID, beside the packed one (git itself writes none for an object it has)."

**Location:** `test/scripts/build-loop-check.bats:1857-1865`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the helpers write; does not establish git's write-avoidance beyond hash-object/pack-objects (verified in i2's probe P6, not rerun).
**Legibility-target:** for-orchestrator-synthesis

`printf 'blob %s\0%s' "${#2}" "$2" | perl -MCompress::Zlib -0777 -ne 'print compress($_)' > "$f"` (`:1860`) writes at the id's path; loose writes `compress("blob " . length($_) . "\0" . $_)` from the packed blob (`:1864`). Executed: the forged read-back assertion and the loose second-copy refusals pass (L1).

**Evidence:** `test/scripts/build-loop-check.bats:1857-1866`, `$S/logs/L1-bats.log`

---

## Claim 20: "Packed, with a second copy of the brief's blob: store_check reads SHA-256 pack indexes (U3a1)."

**Location:** `test/scripts/build-loop-check.bats:1723-1726`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pass after repack and refusal after a second pack in a SHA-256 repo; does not establish loose-file listing for 64-hex names (the awk concatenation is format-agnostic by reading).
**Legibility-target:** for-orchestrator-synthesis

`git repack -adq; chk "$B"; [ "$status" -eq 0 ]` then a second pack and `[ "$output" = "$OBJS" ]` (`:1724-1726`); store_check passes `--object-format="$fmt"` to show-index (`:642`). Executed: L1 `ok 6`.

**Evidence:** `test/scripts/build-loop-check.bats:1716-1727`, `scripts/build-loop.sh:642`, `$S/logs/L1-bats.log`

---

## Claim 21: "store_check re-hashes main's objects before any cat-file blob read of main (U3a1 i1 architecture 1)."

**Location:** `test/scripts/build-loop-check.bats:1959-1962`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call log order of the first exact `cat-file --batch` (store_check's only form; gate_git uses `--batch-check`) against the first `cat-file blob`; does not establish order against git grep's blob reads (open_shared, which gate_start runs after store_check, `:860`).
**Legibility-target:** for-orchestrator-synthesis

`c="$(grep -n -m1 -x 'cat-file --batch' ...)"; f="$(grep -n -m1 '^cat-file blob ' ...)"; [ "$c" -lt "$f" ]` (`:1960-1962`). The wording now says "cat-file blob read", resolving i2's Claim 27. Executed: L1 `ok 10`.

**Evidence:** `test/scripts/build-loop-check.bats:1950-1967`, `$S/logs/L1-bats.log`

---

## Claim 22: Config-pairs test lists `core.multiPackIndex=false`; planted-state test adds `objects/info/alternates`

**Location:** `test/scripts/build-loop-check.bats:1633-1640`, `test/scripts/build-loop-check.bats:1685`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both assertions passing at d10cfba8; does not establish more than Claims 7-8.
**Legibility-target:** for-orchestrator-synthesis

`! grep -v -- " $kv" "$BATS_TEST_TMPDIR/calls"` for each kv including `core.multiPackIndex=false` (`:1685-1686`); `echo "$BATS_TEST_TMPDIR/elsewhere" > .git/objects/info/alternates` and its expected line (`:1633`, `:1640`). Executed: L1 `ok 3`, `ok 4`.

**Evidence:** `test/scripts/build-loop-check.bats:1626-1688`, `$S/logs/L1-bats.log`

---

## Claim 23: Commit d10cfba8: "store_check now skips main's ids (kept by gate_start) and judges main's plus this call's ids only; a two-brief test in both orders. B2: packs and loose files are listed with find -L inside the store (dot-named packs, linked fan-out dirs), and harden pins core.multiPackIndex=false. ... GATE renamed GATED."

**Location:** commit d10cfba8 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed change against the code and L1; does not cover "Comments, plan note and test comments corrected", for which Claim 1 shows one plan phrase still out of date.
**Legibility-target:** for-orchestrator-synthesis

Quoted in Claims 2, 7, 12; `GATED` at `scripts/build-loop.sh:341-349` and no `GATE=` assignment remains (paraphrased — no quote available because the claim covers absence: grep `\bGATE\b=` finds none). Two-brief test at `test/scripts/build-loop-check.bats:1894-1897`.

**Evidence:** `scripts/build-loop.sh:273`, `scripts/build-loop.sh:341-349`, `scripts/build-loop.sh:628-644`, `test/scripts/build-loop-check.bats:1894-1897`, `$S/logs/L1-bats.log`

---

## Claim 24: Commit 83f75281: "the per-brief refusal says 'the tip of BRANCH'; status_fields empties BRIEF and states STATUS's shapes; ... the A15 call log pins store_check before the first blob read"; "perl fails when it reads no object"

**Location:** commit 83f75281 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these claims as they stand at HEAD; the checked-file skip that commit introduced was replaced by d10cfba8 (its message, not this one, is the current account).
**Legibility-target:** for-orchestrator-synthesis

`refuse $a: an object of the tip of $br ...` (`scripts/build-loop.sh:916`); `STATUS=(); BRIEF=()` (`:518`); `exit($n ? 0 : 1)` (`:636`); A15 as Claim 21.

**Evidence:** `scripts/build-loop.sh:505-518`, `scripts/build-loop.sh:636`, `scripts/build-loop.sh:916`, `$S/logs/L1-bats.log`

---

## Claim 25: Commit 65007bf8: "probed: a forged brief blob read back as naming another branch"; "store_check re-hashes main's commit and every tree and blob of its tree in gate_start (refuse state objects), and per brief the tip's commit, its tree and the merge's tree"

**Location:** commit 65007bf8 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read-back and the call sites at HEAD; row citations in this message are settled (override rows 643, 645) and not re-verdicted.
**Legibility-target:** for-orchestrator-synthesis

The test asserts the read-back: `[ "$(git cat-file blob "$o" | grep Branch)" = "Branch: feat/y" ]` (`test/scripts/build-loop-check.bats:1879`), passing in L1. Call sites quoted in Claim 1.

**Evidence:** `test/scripts/build-loop-check.bats:1877-1880`, `scripts/build-loop.sh:858`, `scripts/build-loop.sh:916`, `$S/logs/L1-bats.log`

---

## Claim 26: Help exit line: "2 any --check verdict line or the state gate not ok ... 1 bad usage, ... a failed mktemp (--check; no line printed)"

**Location:** `scripts/build-loop.sh:216-221`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new `refuse state objects` exit 2 and the per-brief store_check refusal counting as not ok; does not cover the mktemp failure path (not run; `GATE_TMP="$(mktemp -d)"` under set -e at `:856` by reading).
**Legibility-target:** for-orchestrator-synthesis

`|| { echo "refuse state objects: ..."; exit 2; }` (`:859`); per-brief refusals reach `[[ "$(head -c 3 "$GATE_TMP/line")" == "ok " ]] || fails=1` and `[[ "$fails" -eq 0 ]] || exit 2` (`:957-959`). Executed: L1's re-hash test asserts `status -eq 2` for both.

**Evidence:** `scripts/build-loop.sh:856-859`, `scripts/build-loop.sh:950-960`, `$S/logs/L1-bats.log`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 1** (`docs/working/plan-build-loop-handoff.md:317`): the as-built note says per-brief store_check runs "skipping ids already checked". Since d10cfba8 it skips only main's ids (`$GATE_TMP/main`), and each brief re-reads ids an earlier brief checked. Say "skipping main's ids".

### Mostly Accurate
- **Claim 18** (`test/scripts/build-loop-check.bats:1900`): the test title says "and no multi-pack-index route", but the test never builds a multi-pack-index. The pin is covered only by the config-pairs test (`:1685`). Drop the phrase or point to that test.

### Unverifiable
- None.

## Goal-Alignment Note

**Success criterion (restated verbatim):** "a markdown report saved at the path your dispatch names, structured per your skill."
**Answered:** Yes. The report is at `docs/reviews/code-fact-check-report-build-loop-u3a1-final-r1.md` with `**Commit:** d10cfba8`. All five brief items are verdicted. (1) store_check's comment and help: Claims 5, 6, 12, 13, with Claim 3 for the not-checked list. (2) gate_start order, GATED and harden reaching gate_git: Claims 7, 9, 14. (3) status_fields: Claims 10, 11 (byte-identical to main, executed), 15, 16. (4) Test titles and comments: Claims 17-22. (5) The plan notes and commit messages: Claims 1-4 and 23-25.
**Out of scope:** whether the race residual and the history residual matter for a decision is for the security critic (settled rows 638, 646). Git versions other than the installed one were not tested.
**Escalate:** None blocking. Both findings are wording-only: Claim 1 is a plan note, Claim 18 a test title. Neither changes code behaviour. Legibility targets: Claims 1 and 18 are for-author. All the others are for-orchestrator-synthesis.
