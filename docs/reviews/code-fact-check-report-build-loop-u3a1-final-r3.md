# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u3a1`, branch `feat/build-loop-u3a1`)
**Scope:** full branch, `main...HEAD` (base d5736445) without docs/reviews: `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, `docs/working/plan-build-loop-handoff.md` step 7 (U3 split note, U3a1 as-built note, U3a2 bullet), and the messages of commits 65007bf8, 83f75281, d10cfba8. `scripts/lib/dev-cycle-read.sh` (check_brief, brief_fields, open_shared, check_branch, resolve_main) was read as context.
**Commit:** d10cfba8
**Replication:** k=3, replicate r3 (final confirming pass)
**Checked:** 2026-10-10
**Total claims checked:** 38
**Summary:** 31 verified, 6 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

The hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read first. None of its entries is about git object stores, pack indexes, bash associative arrays or test titles, and no claim below matches a logged pattern.

Settled rows: the 2026-10-10 `feat/build-loop-u3a1` rows of `docs/reviews/override-log.md` (lines 638-649) were read. Claims 4 and 21 fall in the family of row 638 (history objects not re-hashed). They are verdicted only because the comment's own list of what is not checked leaves out one reader. Nothing is re-filed.

## Execution provenance

Every run used `TMPDIR` under the scratch dir, `LC_ALL=C` and `timeout`. Every probe starts with `set -eu`, makes its own `mktemp -d` and refuses to run git outside it. Logs are under `/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-f/fact-check-r3/logs/` (abbreviated `$L` below).

| Log | Command | cwd | Exit | Time (UTC) |
|---|---|---|---|---|
| L1 `$L/bats-targeted.log` | `bats -f 're-hashes what it reads\|second-copy scan\|SHA-256 repository\|every git call --check makes\|state gate refuses each planted\|before resolve_main reads an object\|partial clone before any object' test/scripts/build-loop-check.bats` (7 tests, all ok) | worktree | 0 | 2026-10-10T19:01:33Z |
| L2 `$L/bats-read.log` | `bats test/scripts/build-loop-read.bats` (20 of 20 ok; this suite is unchanged on the branch and asserts exact --status lines) | worktree | 0 | 2026-10-10T19:01:58Z |
| L3 `$L/probe-status.log` | `bash $D/probe-status.sh`: main's and the branch's build-loop.sh plus lib, `--status` over 9 briefs (new, open with an absent branch, working with Dispatched: 5, ready self-merge, stopped with a reason, done, malformed Branch:, bad marker, not ahead), stdout and stderr compared with cmp | scratch tmp | 0 (both scripts exit 0; `IDENTICAL`) | 2026-10-10T19:02:26Z |
| L4 `$L/probe-midx.log` | `bash $D/probe-midx.sh`: a multi-pack-index with one pack's .idx removed, read with and without `core.multiPackIndex=false`; and whether `git rev-parse --local-env-vars` lists `GIT_CONFIG_KEY_*` | scratch tmp | 0 | 2026-10-10T19:02:37Z |
| L5 `$L/probe-skip.log` | `bash $D/probe-skip.sh`: a git shim tees each `cat-file --batch` stdin, then `--check` on two briefs | scratch tmp | 0 (`--check` exit 0) | 2026-10-10T19:02:55Z |

Static check: `git ls-tree -r -t main | wc -l` gives `3691`, and the summed blob sizes give `67.8534 MB` (worktree, 2026-10-10T19:03Z).

---

## Claim 1: "store_check runs once for main in gate_start (a mismatch is `refuse state objects`, exit 2) and per brief for the tip and the merge's tree"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call sites, how many times each runs, and the exit status and line for main. It does not establish what each call reads (Claim 17) or the skip wording (Claim 2).

```bash
# scripts/build-loop.sh:858-859 (inside gate_start, :854-861 — read)
  store_check "$MAIN_SHA" && mv "$GATE_TMP/call" "$GATE_TMP/main" \
    || { echo "refuse state objects: ..."; exit 2; }
# scripts/build-loop.sh:916 (inside check_line)
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of the tip of $br or of the merge ..."; return; fi
```

L5 logs three `cat-file --batch` calls for a two-brief `--check`: one for main and one for each brief. In L1, the re-hash test passes, with main-side forgeries giving `$OBJS` at status 2.

**Evidence:** `scripts/build-loop.sh:854-861`, `scripts/build-loop.sh:916`, `$L/probe-skip.log`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "per brief for the tip and the merge's tree, skipping ids already checked"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which ids a per-brief call skips. It does not establish the security effect of the skip, which is settled at override row 646.

A per-brief call skips main's ids only. Ids that an earlier brief's call checked are read and re-hashed again, because `$GATE_TMP/call` is rewritten on every call and only `$GATE_TMP/main` feeds the skip filter:

```bash
# scripts/build-loop.sh:628 and :636 (store_check, :618-645 — read)
    done; } | awk 'FILENAME != "-" { seen[$0]; next } !($0 in seen) { seen[$0]; print }' "$GATE_TMP/main" - | git cat-file --batch \
      ...' > "$GATE_TMP/call" || return 1
```

L5: the per-brief batches hold "main ids in it: 0", and main's batch holds 8 of its 9 lines as ids (the ninth is `MAIN^{tree}`). "Ids already checked" reads as if earlier briefs' ids were skipped too. The precise wording is "skipping main's ids, checked at startup", which is what d10cfba8's message says.

**Evidence:** `scripts/build-loop.sh:618-645`, `$L/probe-skip.log`
**Legibility-target:** for-author

---

## Claim 3: "it also refuses an id of main's or of that call with a second copy in the store, listed as git opens them (links, dot-named packs ...), harden switches off the multi-pack-index, and the state gate refuses `objects/info/alternates`. One brief's refusal does not carry to the next"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the second-copy scan's set (main's plus this call's ids), the find -L listing, the config pin, the alternates refusal and the two-brief non-carry. It does not establish that the scan finds copies another git version could read without an .idx (git 2.39.5 only).

```bash
# scripts/build-loop.sh:641-644
  { (cd "$o" && find -L pack -mindepth 1 -maxdepth 1 -name '*.idx' ! -type d) > "$GATE_TMP/idx" || exit 1
    while IFS= read -r r; do git show-index --object-format="$fmt" < "$o/$r" | awk '{ print $2 }' || exit 1; done < "$GATE_TMP/idx"
    (cd "$o" && find -L . -mindepth 2 -maxdepth 2 ! -type d -path './[0123456789abcdef][0123456789abcdef]/*') | awk -F/ '{ print $(NF - 1) $NF }'
  } | awk 'FILENAME != "-" { want[$0]; next } ($0 in want) && n[$0]++ { bad = 1 } END { exit bad }' "$GATE_TMP/main" "$GATE_TMP/call" -
```

`core.multiPackIndex=false` is in harden's list at `scripts/build-loop.sh:273`, and `objects/info/alternates` is in state_gate's file loop at `:307`. In L1, the state-gate, config-pair, re-hash (both two-brief orders) and second-copy scan tests all pass.

**Evidence:** `scripts/build-loop.sh:273`, `:307`, `:618-645`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: "Not re-hashed (Q-103 residual): the tip's parent, the commits check_branch counts, merge bases."

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the history objects a `--check` decision's readers walk. It does not re-open the settled residual (override row 638).

The three items listed are real and unchecked. The list leaves out a fourth history reader on the --check path: status_fields runs check_brief, which walks main's first-parent history with `git log -G`:

```bash
# scripts/lib/dev-cycle-read.sh:462-464 (check_brief, :423-466 — read)
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s --no-textconv --no-show-signature --no-follow -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H --no-show-signature --no-follow "$MAIN_SHA" -- "$a")"
  if [[ -n "$c" && ! "$c" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]]; then echo "skip $a: its Status commit could not be read"; return; fi
```

status_fields discards that commit id (`read -r _ _ st _ <<<"$out"`, `scripts/build-loop.sh:522`), so forged history can only turn a brief into a skip, never into an ok verdict. The list should say "for example" or name check_brief's Status-commit walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:423-466`, `scripts/build-loop.sh:516-558`
**Legibility-target:** for-author

---

## Claim 5: "main's commit and every tree and blob of its tree (3,691 objects, 68 MB here: 0.3 s)"

**Location:** `docs/working/plan-build-loop-handoff.md:317`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the object count and byte size at main d5736445. It does not re-time the 0.3 s figure (override row 639 records 0.24 s).

`git ls-tree -r -t main | wc -l` gives `3691`, and the summed blob sizes give `67.8534 MB`. The run is recorded in the provenance note above.

**Evidence:** `docs/working/plan-build-loop-handoff.md:317`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "the branch and brief re-reads went with their refusals, so U3a2's shim reaches only the CAS" / U3a2: "the failed brief re-read row 625 named is gone (U3a1)"

**Location:** `docs/working/plan-build-loop-handoff.md:317-318`
**Type:** Staleness / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of the re-read code and its refusal texts in the script. It does not establish anything about U3a2's future shim.

paraphrased — no quote available because the claim is about absent code: `grep -n "read again\|PATHS_WHY=unread\|moved or could not"` over `scripts/build-loop.sh` matches only store_check's comment wording "is not read again" (`:602`). check_line now reads `STATUS[...]` (`:880-886`), and srules has no `unread` arm (`:746-759`).

**Evidence:** `scripts/build-loop.sh:746-759`, `:875-939`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: "an info/attributes, info/grafts, shallow or objects/info/alternates (another object store) that is not absent or an empty file"

**Location:** `scripts/build-loop.sh:96-98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the alternates refusal line and its order. It does not establish `GIT_ALTERNATE_OBJECT_DIRECTORIES`, which is the caller's environment.

```bash
# scripts/build-loop.sh:307-309
  for f in info/attributes info/grafts shallow objects/info/alternates; do
    ...
    if [[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]; then echo "refuse state $f: present and not an empty file"; bad=1; fi
```

L1: the T26 state-gate test asserts the exact line `refuse state objects/info/alternates: present and not an empty file`, and it passes.

**Evidence:** `scripts/build-loop.sh:296-318`, `test/scripts/build-loop-check.bats:1630-1642`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "then the gate's own merge repository not set up ...; then main's commit, or a tree or blob of its tree, that does not hash to its id, has a second copy ... or cannot be read ('refuse state objects: WHY'; every file the gate reads from main is one). Each finding prints ... and exits 2 before the settings or any brief is read."

**Location:** `scripts/build-loop.sh:102-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order (default_gate, gate_repo, store_check, then the settings) and that `reader_settings` is not reached in check mode before gate_start's last step. It does not establish that resolve_main reads no main object, which it does by design (`rev-parse SHA^{commit}`).

```bash
# scripts/build-loop.sh:349
[[ -n "$GATED" ]] || reader_settings
# scripts/build-loop.sh:855-860 (gate_start, :854-861 — read)
  default_gate || exit 2
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
  gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
  store_check "$MAIN_SHA" && mv ... || { echo "refuse state objects: ..."; exit 2; }
  reader_settings; read_settings; never_res; open_shared
```

L1 runs the re-hash test, where the main-side cases print exactly `$OBJS` with empty stderr, and the A15 test, where store_check's `cat-file --batch` comes before the first `cat-file blob`. Both pass. Every file the gate reads from main is read as `cat-file blob MAIN:PATH` (brief_fields `dev-cycle-read.sh:399`, own_blob `:670-672`), so each is a blob of main's tree.

**Evidence:** `scripts/build-loop.sh:335-349`, `:854-861`, `:941-961`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "Or 'an object of the tip of BRANCH or of the merge does not hash to its id, has a second copy ..., or could not be read': the tip's commit, or a tree or blob of its tree or of TREE (gitlinks aside), read back and re-hashed"

**Location:** `scripts/build-loop.sh:126-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal text, what is read, and that the gitlink entries are dropped. It does not establish the order against the blob-presence check, which runs first (`:911-914`), so a missing blob of the merge refuses with that check's text.

```bash
# scripts/build-loop.sh:626-627
      printf '%s\n' "$r" "$r^{tree}"
      git ls-tree -r -t --full-tree --format='%(objecttype) %(objectname)' "$r" 2>/dev/null | awk '$1 != "commit" { print $2 }' || exit 1
```

L1: the re-hash test asserts this exact refusal for a forged tip blob and for a loose second copy, with no path line, and passes.

**Evidence:** `scripts/build-loop.sh:618-645`, `:911-916`, `test/scripts/build-loop-check.bats:1887-1892`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "After an ok line, a K of N refusal or a checkout refusal, one line per path TREE changes"

**Location:** `scripts/build-loop.sh:165`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_line's final print, where only the verdict line varies. It does not cover the early-return refusals, which print no rows. That matches the help text.

```bash
# scripts/build-loop.sh:937-938 (check_line's last lines)
  if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
  printf '%s\n' "${rows[@]}"
```

**Evidence:** `scripts/build-loop.sh:875-939`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "Every git call in this process, the lib's included, runs hardened ... no multi-pack-index (a second route to an object, past store_check's listing)"

**Location:** `scripts/build-loop.sh:259-273`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pin being present on every git call, gate_git's included. It does not establish the parenthetical rationale. In L4, a pack whose .idx was removed under a multi-pack-index is unreadable with and without the pin on git 2.39.5, so that route was not reproduced. The pin's practical effect is that real-repo and gate-repo reads agree whatever the repo config says.

```bash
# scripts/build-loop.sh:273
  for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false core.multiPackIndex=false; do
```

gate_git runs `"${GATE_ENV[@]}" git`, where GATE_ENV unsets only the variables `git rev-parse --local-env-vars` lists, apart from callervar's (`:579`). L4 shows that list holds no `GIT_CONFIG_KEY_*` ("0"), so the pairs reach gate_git. In L1, the config-pairs test greps every logged call for ` core.multiPackIndex=false` and passes.

**Evidence:** `scripts/build-loop.sh:271-278`, `:575-594`, `$L/probe-midx.log`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: "Files: an info/attributes, info/grafts, shallow or objects/info/alternates that is not absent or an empty regular file (each changes merges, history or the objects read)"

**Location:** `scripts/build-loop.sh:290-292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file list and test (`-s`, `-L`, non-regular). It does not establish the effect of each file on git.

The `for f in info/attributes info/grafts shallow objects/info/alternates` loop at `scripts/build-loop.sh:307-310` is quoted in Claim 7.

**Evidence:** `scripts/build-loop.sh:307-310`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "--check refuses planted state before any git call reads an object (resolve_main does); gate_start runs the rest of its startup." / GATED at both top-level sites / "gate_start calls it once main's objects are checked."

**Location:** `scripts/build-loop.sh:339-349`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both GATED sites and where reader_settings is deferred. It does not establish behaviour for modes other than check, which still call reader_settings at top level.

```bash
# scripts/build-loop.sh:341-349
GATED=""; [[ "$MODE" != check ]] || GATED=1  # a mode that decides (not the gate repository's GATE_*)
if [[ -n "$GATED" ]]; then state_gate || exit 2; fi
resolve_main || true
main_by_name || { ...; exit 1; }
...
[[ -n "$GATED" ]] || reader_settings
```

gate_start calls `reader_settings` after store_check (`:860`). L1: the A15 test passes.

**Evidence:** `scripts/build-loop.sh:339-349`, `:854-861`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: STATUS shapes: "Only for an 'ok' line does STATUS hold its fields by name ... '-' for a branch, sha or date there is none of, and an empty reason), and ahead ... (0 when absent); a skip line sets only line."

**Location:** `scripts/build-loop.sh:505-510`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every return of status_fields. It does not establish that check_brief prints only `ok` or `skip`. That was read and holds (`dev-cycle-read.sh:423-466`).

```bash
# scripts/build-loop.sh:518, :521, :524, :542, :556-557 (status_fields, :516-558 — read)
  STATUS=(); BRIEF=()
  [[ "$out" == "ok "* ]] || { STATUS[line]="$out"; return; }
    STATUS=([line]="ok $a new review - absent - - 0" [state]=new [policy]=review [branch]=- [loop]=absent [sha]=- [ahead]=0 [date]=- [dispatched]=0 [reason]="")
  sha=- ahead=0 date=- loop=absent
  STATUS=([line]="ok $a $st $pol $br $loop $sha $date $disp${reason:+ $reason}" [state]="$st" ... [reason]="$reason")
```

Every other return sets only `STATUS[line]`, to a `skip` text.

**Evidence:** `scripts/build-loop.sh:505-559`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "BRIEF is emptied, then holds what brief_fields read for this brief ... (empty for a new brief or one check_brief skips): check_line takes Paths: from it, so nothing between may call brief_fields."

**Location:** `scripts/build-loop.sh:510-514`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the calls between `status_fields` and `read_paths` in check_line (merge_result, gate_git diff-tree and cat-file, store_check, checkout_gate). It does not cover own_blob's later direct blob reads, which do not touch BRIEF.

check_brief runs in `$(...)` (`:520`), so its brief_fields sets only a subshell's BRIEF. The in-shell `brief_fields "$a"` (`:527`) is the source. open_shared declares `local -A count=() BRIEF=()` (`dev-cycle-read.sh:505`), so the caller's BRIEF is untouched. No function called between `:880` and `:927` calls brief_fields (paraphrased — no quote available because this claim is about the absence of calls across several function bodies, `:576-660` and `:777-843`, all read).

**Evidence:** `scripts/build-loop.sh:516-558`, `:880-927`, `scripts/lib/dev-cycle-read.sh:390-414`, `:503-518`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: `status_line() { status_fields "$1"; echo "${STATUS[line]}"; }` keeps --status output byte-identical to main's

**Location:** `scripts/build-loop.sh:559`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 9 brief shapes in L3 and the 20 exact-line tests of the unchanged build-loop-read.bats (L2). It does not cover a stopped marker with an empty reason, which marker_kind's regex rules out (`:502`, one or more characters).

The one formatting change is `$disp$reason` with `reason=" X"` becoming `$disp${reason:+ $reason}` with `reason="X"` (`:556`). These are equal for any non-empty reason. In L3, both scripts exit 0 and the outputs compare `IDENTICAL`, including `... stopped <sha> 2026-10-10 0 out of budget`. L2 passes 20 of 20.

**Evidence:** `scripts/build-loop.sh:516-559`, `$L/probe-status.log`, `$L/bats-read.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "Each REV (a commit or a tree), its root tree, and every tree and blob below it (a gitlink names another repository's commit) are read in one cat-file --batch and re-hashed by one perl, for sha1 or sha256, but an id in $GATE_TMP/main ... is not read again."

**Location:** `scripts/build-loop.sh:598-602`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the input list, the skip and the re-hash. Two limits are not covered by "is not read again". The `REV^{tree}` expression is never skipped, so a root tree equal to one of main's is still re-read, as the comment at `:636` says. The re-hash runs no length or type check beyond the header regex.

```perl
# scripts/build-loop.sh:631-633
        my ($id, $t, $s) = $h =~ /^([0-9a-f]+) ([a-z]+) ([0-9]+)\n\z/ or exit 1;  # "NAME missing" too
        read(STDIN, my $b, $s) == $s && (getc(STDIN) // "") eq "\n" or exit 1;
        Digest::SHA->new($ENV{ALG})->add("$t $s\0", $b)->hexdigest eq $id or exit 1;
```

L5: the per-brief batches carry the tip id, `TIP^{tree}`, the tip's own blob, the merge tree id and `TREE^{tree}`, with 0 of main's ids. L1: the SHA-256 test passes the packed and second-copy cases.

**Evidence:** `scripts/build-loop.sh:618-636`, `$L/probe-skip.log`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "Then no id of main's or of this call may have a second copy in the store: in two packs, or loose and packed ... The listing follows links and takes dot-named packs ... Only one call's ids are judged, so one brief's refusal never carries to the next"

**Location:** `scripts/build-loop.sh:602-611`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the judged set (`$GATE_TMP/main` plus `$GATE_TMP/call`) and the listing. It does not establish coverage of packs that git versions other than 2.39.5 open.

The scan is quoted in Claim 3 (`:641-644`). In L1, the re-hash test runs two briefs in both orders (`ok $y` then `refuse $B`, and `refuse $B` then `ok $y`) and the second-copy scan test runs the dot-named pack and linked fan-out cases. Both pass.

**Evidence:** `scripts/build-loop.sh:637-645`, `test/scripts/build-loop-check.bats:1892-1898`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "Returns 1 on a mismatch, a missing object, a second copy or a failed read."

**Location:** `scripts/build-loop.sh:611-612`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the non-zero return on each named path. Both callers test only for non-zero. It does not establish that the status is exactly 1 on every failure: a failing loose-object `find` passes its own status through pipefail.

```bash
# scripts/build-loop.sh:636 and :644
      exit($n ? 0 : 1)' > "$GATE_TMP/call" || return 1  # REV^{tree} is never skipped, so 0 read is a fault
  } | awk '... END { exit bad }' "$GATE_TMP/main" "$GATE_TMP/call" -
```

L1 covers a mismatch (forged blobs), a missing tree and second copies. All refuse.

**Evidence:** `scripts/build-loop.sh:618-645`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: "two reads of one id (cat-file --batch here, cat-file blob MAIN:PATH in brief_fields) took different ones (U3a1 i1 security F1 ...)"

**Location:** `scripts/build-loop.sh:604-607`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the existence of the cited readers and finding. It does not reproduce which copy each read takes.

brief_fields reads `git cat-file blob "$MAIN_SHA:$1"` (`scripts/lib/dev-cycle-read.sh:399`). The i1 security review and override rows for `feat/build-loop-u3a1` exist under `docs/reviews/`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:399`, `docs/reviews/override-log.md:638-649`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: "Not checked: objects a decision reaches only through history (the tip's parent, read by marker_kind; the commits check_branch counts; the merge bases ...), and a writer racing between a check and a later read ..., which for main's objects spans the whole run, as they are re-hashed once."

**Location:** `scripts/build-loop.sh:612-616`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list of history readers and the run-wide race window for main's objects. It does not re-file the settled residual (override rows 638, 646).

The race half holds: main's ids are checked once at gate_start and then skipped (Claim 2). The history list leaves out check_brief's `git log -G'^Status: ' "$MAIN_SHA"` walk over main's first-parent history (`scripts/lib/dev-cycle-read.sh:462-464`, quoted in Claim 4). That walk runs on every status_fields call and can only yield a skip. Adding "check_brief's Status commit" to the list would make it complete.

**Evidence:** `scripts/build-loop.sh:612-616`, `scripts/lib/dev-cycle-read.sh:462-464`, `scripts/build-loop.sh:522`
**Legibility-target:** for-author

---

## Claim 22: "The brief's own file ...: main's copy ... the one brief_fields reads (status_fields has read it as 'Status: open')"

**Location:** `scripts/build-loop.sh:661-665`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the only caller path (nrules from check_line after the `st != open` refusal). It does not establish that own_blob's two blob reads see the same copy as the earlier reads; that is covered only by the second-copy scan.

`if [[ "$st" != open ]]; then echo "refuse $a: the brief is $st ..."; return; fi` (`scripts/build-loop.sh:883`) comes before any nrules call (`:933`).

**Evidence:** `scripts/build-loop.sh:666-673`, `:883`, `:933`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: "$5 the checkout's refusal, if any"

**Location:** `scripts/build-loop.sh:740`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the one caller's fifth argument. It does not cover the floor's internals.

`srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"` (`scripts/build-loop.sh:934`), where `co` is set only by checkout_gate's refusal (`:924`).

**Evidence:** `scripts/build-loop.sh:746-759`, `:924`, `:934`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: gate_start: "... in this order, each refusal a 'refuse state' line and exit 2 before any setting or brief is read: the default branch unambiguous (default_gate); the gate's merge repository (GATE_TMP, removed at exit); main's commit and tree re-hashed ...; then the reader lists ..."

**Location:** `scripts/build-loop.sh:844-850`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers gate_start's order and its three refusal paths. It does not cover the top-level main_by_name failure, which is also outside the comment's list.

The order and the three `refuse state` refusals (default_gate's lines, `refuse state gate:`, `refuse state objects:`) match `:855-860` (quoted in Claim 8). One startup failure is not a "refuse state" line with exit 2: a failed `GATE_TMP="$(mktemp -d)"` under `set -e` exits 1 with no line, as the header's exit section says (`:221`, "a failed mktemp (--check; no line printed)"). The comment should exclude mktemp's failure.

**Evidence:** `scripts/build-loop.sh:216-223`, `:854-861`
**Legibility-target:** for-author

---

## Claim 25: gate_start: "The repository rule: main's files and refs, the branch tips, the checkout and store_check's object reads are in the real repository; the merge computations (merge-base, merge-tree, diff-tree, the blob checks) run through gate_git."

**Location:** `scripts/build-loop.sh:850-853`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every git call in merge_result, check_line, own_blob, store_check, checkout_gate and the lib's readers that were read. It does not cover dev-cycle-read.sh's floor walk internals.

merge_result uses `gate_git merge-base`, `gate_git cat-file -e` and `gate_git merge-tree` (`:652-656`). check_line uses `gate_git diff-tree` (`:895`) and `gate_git cat-file --batch-check` (`:911`). own_blob uses `gate_git hash-object` (`:672`). store_check, brief_fields, check_branch and checkout_gate call plain `git`.

**Evidence:** `scripts/build-loop.sh:618-673`, `:777-843`, `:875-916`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: check_line: "or one skip or refuse line (status_fields' STATUS[line], then the gate's own reasons) ... each helper empties its own globals before use (DENY, PATHS and PATHS_WHY, LIST ..., STATUS, BRIEF, ...)"

**Location:** `scripts/build-loop.sh:866-874`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers STATUS and BRIEF, which this branch adds, and the non-carry of store_check's per-call file. It does not re-check the older globals (unchanged).

`STATUS=(); BRIEF=()` opens status_fields (`:518`), and `> "$GATE_TMP/call"` rewrites store_check's per-call file (`:636`). L1: the two-brief orders pass.

**Evidence:** `scripts/build-loop.sh:516-518`, `:636`, `:880-881`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: "The tip's objects and the merge's, re-hashed (main's were, in gate_start)." / "The S rules' inputs: the brief as status_fields read it from main's commit."

**Location:** `scripts/build-loop.sh:915`, `scripts/build-loop.sh:925`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both comments against their lines. It does not establish main's freshness after startup (the race, Claim 21).

`if ! store_check "$sha" "$tree"; then ...` (`:916`); `[[ "$pol" != self-merge ]] || read_paths` (`:927`), and read_paths reads `BRIEF[paths]` (`:717-718`).

**Evidence:** `scripts/build-loop.sh:715-720`, `:915-927`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 28: state-gate test: planted `objects/info/alternates` gives "refuse state objects/info/alternates: present and not an empty file" in order

**Location:** `test/scripts/build-loop-check.bats:1633-1640`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's exact-output assertion. It does not test a symlinked or non-regular alternates file separately.

`echo "$BATS_TEST_TMPDIR/elsewhere" > .git/objects/info/alternates`. The test passes in L1 (ok 1).

**Evidence:** `test/scripts/build-loop-check.bats:1630-1653`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29: config-pairs test: every logged call carries `core.multiPackIndex=false`

**Location:** `test/scripts/build-loop-check.bats:1685`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git process the shim on PATH sees, gate_git's `env ... git` included. It does not check pairs given as absolute-path git calls, and none exist.

`for kv in ... core.commitGraph=false core.multiPackIndex=false G=/dev/null P=none S=1; do ! grep -v -- " $kv" ...`. The test passes in L1 (ok 3).

**Evidence:** `test/scripts/build-loop-check.bats:1675-1688`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 30: "Packed, with a second copy of the brief's blob: store_check reads SHA-256 pack indexes (U3a1)."

**Location:** `test/scripts/build-loop-check.bats:1723`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the packed pass and the second-pack refusal in a sha256 repo. It does not cover a SHA-256 forged-bytes case, which is a sha1 case only.

`git repack -adq; chk "$B"; [ "$status" -eq 0 ]`, then `git rev-parse "main:$B" | git pack-objects -q .git/objects/pack/pack` and `[ "$output" = "$OBJS" ]`. The test passes in L1 (ok 4).

**Evidence:** `test/scripts/build-loop-check.bats:1716-1727`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 31: forge/loose helpers: "rewrite loose object ID's file to hold a blob of TEXT, its id unchanged" / "a loose copy of packed blob ID, beside the packed one (git itself writes none for an object it has)"

**Location:** `test/scripts/build-loop-check.bats:1857-1865`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers forge's read-back, which the test asserts, and loose's placement. It does not verify git's write-skip parenthetical beyond the passing tests.

The test asserts `[ "$(git cat-file blob "$o" | grep Branch)" = "Branch: feat/y" ]` after forge, and passes in L1 (ok 5).

**Evidence:** `test/scripts/build-loop-check.bats:1857-1890`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 32: re-hash test title: "a rewritten, missing or second copy of an object of main's tree refuses the state before any brief; of the tip's tree, the brief; a packed store passes" (and its case comments)

**Location:** `test/scripts/build-loop-check.bats:1867`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each case's assertion: main's second copy (pack, loose), main's forged blob, main's missing tree with empty stderr, the tip's forged blob and loose second copy, a packed pass, and both two-brief orders. It does not test a missing tip-side object, which the title does not claim.

The test passes in L1 (ok 5). Each case compares the whole output, `$OBJS` or the per-brief refusal, so "before any brief" is shown by the absence of any brief line.

**Evidence:** `test/scripts/build-loop-check.bats:1867-1898`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 33a: second-copy scan test title: "lists what git opens: a pack named with a leading dot, a linked fan-out directory"

**Location:** `test/scripts/build-loop-check.bats:1900`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the dot-named pack case (git reads it, the gate refuses, and removing it passes) and the symlinked fan-out case. It does not cover a symlinked `pack/` directory.

`mv "$f" ".git/objects/pack/.hidden.${f##*.}"` then `[ "$output" = "$OBJS" ]`, and `ln -s "$BATS_TEST_TMPDIR/fan/${o:0:2}" ".git/objects/${o:0:2}"` then `$OBJS`. The test passes in L1 (ok 6).

**Evidence:** `test/scripts/build-loop-check.bats:1900-1912`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 33b: second-copy scan test title: "... and no multi-pack-index route"

**Location:** `test/scripts/build-loop-check.bats:1900`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what this test's body exercises. It does not say whether the pin is tested elsewhere: it is, by the config-pairs test (Claim 29).

The test body never writes a multi-pack-index and never sets or reads `core.multiPackIndex` (paraphrased — no quote available because this is about absent code: `grep -n -i "multi-pack\|multiPackIndex\|midx" test/scripts/*.bats` matches only `:1685`, the config-pairs list, and `:1900`, this title). A reader of the title would take the multi-pack-index route as exercised here. It is not. Fix by dropping that phrase from the title, or by naming the config-pairs test as the pin's coverage.

**Evidence:** `test/scripts/build-loop-check.bats:1900-1912`, `test/scripts/build-loop-check.bats:1685`
**Legibility-target:** for-author

---

## Claim 34: A15 test: "store_check re-hashes main's objects before any cat-file blob read of main (U3a1 i1 architecture 1)."

**Location:** `test/scripts/build-loop-check.bats:1959-1962`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call order of the first `cat-file --batch` and the first `cat-file blob`. It does not cover main's object reads made in other forms before store_check (resolve_main's `rev-parse SHA^{commit}`, by design).

`c="$(grep -n -m1 -x 'cat-file --batch' ...)"; f="$(grep -n -m1 '^cat-file blob ' ...)"; [ "$c" -lt "$f" ]`. The test passes in L1 (ok 7).

**Evidence:** `test/scripts/build-loop-check.bats:1945-1967`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 35: commit 65007bf8: "status_fields gives --status's line as values (rows 496, 512)"

**Location:** commit `65007bf8` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row citations. It does not affect the code.

Override row 496 is "a `status_fields` array with status_line as its printer" (`docs/reviews/override-log.md:496`). Row 512 is "U3's `--merge` needs TIP, TREE and the verdict as values" (`:512`), which this branch did not do. Commit 83f75281 records "row 512's values moved to U3a2", and so does the plan's as-built note. The citation should be row 496 alone.

**Evidence:** `docs/reviews/override-log.md:496`, `docs/reviews/override-log.md:512`, `docs/reviews/override-log.md:643`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 36: commit 65007bf8: "so check_line reads the brief once: the branch and brief re-reads and their two untested refusals go"

**Location:** commit `65007bf8` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how many times check_line reads the brief's blob. It does not reach the second-copy defence, which covers every one of these reads (Claim 18).

The re-reads after status are gone (Claim 6). status_fields itself still reads the brief's blob twice: check_brief's brief_fields in `$(...)` (`out="$(check_brief "$a")"`, `scripts/build-loop.sh:520`) and the in-shell `brief_fields "$a"` (`:527`). For the brief's own changed path, own_blob reads it twice more (`git cat-file blob "$MAIN_SHA:$1"`, `:670` and `:672`). Accurate as "no re-read after status"; not as "once".

**Evidence:** `scripts/build-loop.sh:516-527`, `:666-673`, `scripts/lib/dev-cycle-read.sh:440`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 37: commit 83f75281: "the state gate refuses objects/info/alternates. A2: ... FILENAME is tested, and perl fails when it reads no object ... git repack -ad clears it"

**Location:** commit `83f75281` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the alternates refusal, the FILENAME filter, perl's zero-object exit and the repack-clears case in the tests. It does not re-measure the "21,742 packed ids" figure for /workspace.

`awk 'FILENAME != "-" { seen[$0]; next } ...'` (`scripts/build-loop.sh:628`); `exit($n ? 0 : 1)` (`:636`). The re-hash test runs `git repack -adq` after a second copy and then passes (L1).

**Evidence:** `scripts/build-loop.sh:628-636`, `test/scripts/build-loop-check.bats:1873-1875`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 38: commit d10cfba8: "store_check now skips main's ids (kept by gate_start) and judges main's plus this call's ids only; a two-brief test in both orders. ... packs and loose files are listed with find -L inside the store (dot-named packs, linked fan-out dirs), and harden pins core.multiPackIndex=false. ... GATE renamed GATED."

**Location:** commit `d10cfba8` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed change against the code and tests. It does not cover the confidence or notes lines, which are judgment.

The skip and judged set are quoted in Claims 2 and 3; harden's list is at `scripts/build-loop.sh:273`; `GATED` is at `:341`, `:342` and `:349`, and no `GATE=` assignment remains. L5 shows the skip. L1 shows both orders, the find -L cases and the pin.

**Evidence:** `scripts/build-loop.sh:273`, `:341-349`, `:618-645`, `$L/probe-skip.log`, `$L/bats-targeted.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 33b** (`test/scripts/build-loop-check.bats:1900`): the title says the test shows "no multi-pack-index route", but the body writes no multi-pack-index. Only the config-pairs test (`:1685`) covers the pin. Drop the phrase or point to that test.

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`docs/working/plan-build-loop-handoff.md:317`): "skipping ids already checked" should be "skipping main's ids". An earlier brief's ids are re-read.
- **Claim 4** (`docs/working/plan-build-loop-handoff.md:317`): the not-re-hashed list leaves out check_brief's `git log -G` walk of main's history. That walk can only cause a skip.
- **Claim 21** (`scripts/build-loop.sh:612-616`): the same omission in store_check's "Not checked" list.
- **Claim 24** (`scripts/build-loop.sh:844-850`): "each refusal a refuse state line and exit 2" does not hold for a failed mktemp, which exits 1 with no line, as the header says at `:221`.
- **Claim 35** (commit 65007bf8): cites row 512 for status_fields. Row 512 is TIP/TREE/verdict values, moved to U3a2.
- **Claim 36** (commit 65007bf8): "check_line reads the brief once". The re-read after status is gone, but status_fields still reads the blob twice, and own_blob reads it twice more for the brief's own path.

### Unverifiable
- None. Claim 11's parenthetical rationale ("a second route ... past store_check's listing") was probed and not reproduced on git 2.39.5 (L4). It is scoped out as rationale, not verdicted.

## Goal-Alignment Note

**Success criterion (restated verbatim):** "a markdown report saved at the path your dispatch names, structured per your skill."
**Answered:** Yes. The report is saved at `docs/reviews/code-fact-check-report-build-loop-u3a1-final-r3.md` with `**Commit:** d10cfba8`. All five brief items are verdicted:
- store_check's comment and the help text: Claims 1-4, 8-9, 17-21.
- gate_start's order, GATED and harden's pairs reaching gate_git: Claims 8, 11, 13, 24-25.
- status_fields' byte identity, STATUS shapes, BRIEF and check_line's use: Claims 14-16, 26-27.
- The test titles and cases: Claims 28-34.
- The plan notes and commit messages: Claims 1-6, 35-38.

Behavioural claims rest on 27 bats tests (L1, L2) and three hermetic probes (L3-L5).
**Out of scope:** whether check_brief's unchecked history walk (Claims 4, 21) needs a row beyond 638 is the security critic's call. So is whether any git version reads a multi-pack-index pack past the .idx listing (Claim 11). Versions other than git 2.39.5 were not tried.
**Escalate:** None blocking. Legibility targets: Claims 2, 4, 21, 24 and 33b are for-author. Claims 1, 3, 5-20, 22-23, 25-32, 33a and 34-38 are for-orchestrator-synthesis.
