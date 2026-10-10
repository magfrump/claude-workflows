# Code Fact-Check Report

**Repository:** /workspace (worktree .claude/wt-build-loop-u3a1, branch feat/build-loop-u3a1)
**Scope:** submitted endorsement claims (Stage 2.5) against the committed `scripts/build-loop.sh` and `scripts/lib/dev-cycle-read.sh` at d10cfba8 (extracted with `git archive`; the worktree's uncommitted edits not judged)
**Checked:** 2026-10-10
**Commit:** d10cfba8
**Total claims checked:** 3
**Summary:** 2 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Commit: d10cfba8

Execution provenance (shared by Claims 57-59): command `timeout 300 bash probes/p1.sh > p1.log 2>&1`, cwd `/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-f/stage25`, exit 0, started 2026-10-10T19:17:24Z, git 2.39.5. The probe builds a throwaway repo under its own `mktemp -d`, puts a logging `git` shim first on PATH (it records GIT_DIR, every GIT_CONFIG_KEY_n/VALUE_n pair and the args of each git call, then execs /usr/bin/git), and runs the extracted d10cfba8 script (and, for Claim 59, main d5736445's script on the same fixture). Script: `.../u3a1-f/stage25/probes/p1.sh`; captured output: `.../u3a1-f/stage25/p1.log`; per-call logs: `.../u3a1-f/stage25/run.*/shim-{new,main,midx}.log`.

---

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
