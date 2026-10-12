Commit: 5e816c5b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b1 (branch `feat/build-loop-u3b1`)
**Scope:** full branch `main...HEAD` (HEAD 5e816c5b): `scripts/build-loop.sh`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-merge.bats`, `docs/working/plan-build-loop-handoff.md:324`, override-log rows dated 2026-10-12, and the commit bodies of ec9ba0c7, 8f99a919 and 8367359f. Final confirming pass, replicate r1 (k=3).
**Checked:** 2026-10-12
**Total claims checked:** 31
**Summary:** 27 verified, 2 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Legibility target: each claim is written so that a reader who has not seen the code can act on the verdict. Each one says what the code does in plain terms, quotes the lines behind it, and states in its Scope line what the verdict does not cover.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) was read. No claim below matches a logged pattern. No symbol, flag or API named in the branch's text was missing.

**Execution provenance (shared by every `executed` claim).** All probes ran on 2026-10-12 between 20:34Z and 20:40Z, using git 2.39.5. Each probe script was started from `/tmp/claude-1000/-workspace/402ec840-a464-40f5-96ae-98af0cc535cf/scratchpad/u3b1f1/` (the "scratchpad" below) and created its own repository under `/tmp/u3b1f1-*`. The worktree was never written. The captured output files are in that scratchpad:
- `orch.log`: `TMPDIR=$(mktemp -d /tmp/u3b1f1-XXXX) bats test/scripts/build-loop-orchestrator.bats`, run in the worktree. Exit 0, 8/8 ok.
- `merge.log`: the same for `build-loop-merge.bats`. Exit 0, 12/12 ok.
- `dispatch.log`: the same for `build-loop-dispatch.bats`. Exit 0, 4/4 ok.
- `p1.log` (`bash p1.sh`, exit 0): git's config precedence, how the count is parsed, how --state exits under each caller environment, and default_gate.
- `p2.log` and the gpgsig rerun `p2b.sh` (exit 0): how --marker extracts the body, the cut, the rules and the exit codes.
- `p3.log` (`bash p3.sh`, exit 0): three mutants built on copies of `scripts/` and `test/` under /tmp/u3b1f1-p3-*.
- `p4.log` (`bash p4.sh`, exit 128 at its last probe line, after the needed output): git's reading of 010, and GIT_GRAFT_FILE.
- `p5.log` (`python3 -I p5.py`, exit 0): the strict-UTF-8 regex against Python's decode.
- `p6.log` (`bash p6.sh`, exit 0): the cost of a 16 MB marker.
- `p7.log` (`bash p7.sh`, exit 0): update-ref with a tag, and commit-tree with bytes that are not UTF-8.

Every temp directory and process was removed or stopped before this report was written.

---

## Claim 1: "`--marker` reads the marker commit a fourth time ... The 64 KiB cap bounds only the body's processing: marker_kind (in status_fields) has read the commit twice before it ...; a 16 MB marker costs ~1.2 s and ~145 MB there."

**Location:** `docs/reviews/override-log.md:711`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read order (marker_kind's two full reads come before the cap test) and the elapsed time for a 16 MB marker. Does not establish the ~145 MB RSS figure, because no `/usr/bin/time` is available in the sandbox and RSS was not measured.

marker_kind reads the commit in full twice:

```bash
# scripts/build-loop.sh:728
if ! p="$(git rev-list --parents -n 1 "$1" 2>/dev/null)" || ! msg="$(git cat-file commit "$1" 2>/dev/null | tr -d '\000')"; then
```

```bash
# scripts/build-loop.sh:734
if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"; return; fi
```

marker() tests the cap before its own read:

```bash
# scripts/build-loop.sh:829-831
n="$(git cat-file -s "${STATUS[sha]}")" || { echo "skip $a: its marker could not be read"; return; }
[[ "$n" -le "$MARKER_MAX" ]] || { echo "skip $a: its marker is $n bytes, over the $MARKER_MAX-byte cap"; return; }
m="$(git cat-file commit "${STATUS[sha]}")" || { echo "skip $a: its marker could not be read"; return; }
```

(excerpt ends :831; enclosing marker() continues to :870 — read)

Executed: a 16,000,181-byte marker printed `skip ...: its marker is 16000181 bytes, over the 65536-byte cap` after `elapsed 0.970 s`, with a load average of 0.89.

**Evidence:** `scripts/build-loop.sh:721-748`, `scripts/build-loop.sh:821-870`, scratchpad `p6.log`

---

## Claim 2: "`--state` exits 1 (stderr only) for a non-decimal GIT_CONFIG_COUNT or a GIT_DIR naming no repository"

**Location:** `docs/working/plan-build-loop-handoff.md:324`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named causes and four further caller-environment causes, each of which exits 1 with stderr only. Does not establish any exit-1 path outside the caller's environment, such as a failed mktemp.

Both named causes exit 1 with stderr only. Run in `p1.log`: `count[010] exit 1`, `count[1x]`, `count[+1]` and `count[-1]` each printed `build-loop.sh: GIT_CONFIG_COUNT is not a plain decimal count`. `GIT_DIR=/nonexistent` printed `Not inside a git repository`, exit 1.

The list is not complete. Four other caller-environment settings also exit 1 with stderr only, through the same `rev-parse` or `cd` line:

```bash
# scripts/build-loop.sh:572-573
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
```

- A decimal GIT_CONFIG_COUNT that names a missing GIT_CONFIG_KEY_n: `GIT_CONFIG_COUNT=2` with only KEY_0 set printed `Not inside a git repository`, exit 1.
- A malformed GIT_CONFIG_PARAMETERS (`'broken`): the same message, exit 1.
- `GIT_WORK_TREE=/nonexistent`: bash printed `line 573: cd: /nonexistent: No such file or directory`, exit 1.

An existing GIT_WORK_TREE that is not a repository, or a GIT_DIR naming another repository, gives `refuse state GIT_WORK_TREE: ...` or `refuse state GIT_DIR: ...` with exit 2, as documented.

The precise version: "exits 1 (stderr only) when the caller's git environment stops git from opening the repository (a GIT_CONFIG_COUNT that is not plain decimal, a count naming a missing key, a malformed GIT_CONFIG_PARAMETERS, a GIT_DIR naming no repository, a missing GIT_WORK_TREE)". The message for the two config-pair cases is "Not inside a git repository".

**Evidence:** `scripts/build-loop.sh:456-463`, `scripts/build-loop.sh:572-573`, scratchpad `p1.log` (P1d–P1g)

---

## Claim 3: "default_gate checks the ref's own object type (not MAIN_SHA), so land's re-run leaves a moved branch to the compare-and-swap ... or W's fast-forward"

**Location:** `docs/working/plan-build-loop-handoff.md:324` (same claim at `scripts/build-loop.sh:560-563` and in commit 8367359f)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the compare-and-swap path, which is executed and pinned by a test that kills a mutant. Does not establish the W fast-forward path by execution here; it was read statically, and the i2 report executed it.

```bash
# scripts/build-loop.sh:564-565
p="$(git show-ref --verify --hash "refs/heads/$MAIN" 2>/dev/null)" && [[ "$(git cat-file -t "$p" 2>/dev/null)" == commit ]] \
  || { echo "refuse state default-branch: refs/heads/$MAIN names an object that is not a commit"; bad=1; }
```

(excerpt ends :565; enclosing default_gate() continues to :571 — read)

Land re-runs the gate, then does the compare-and-swap against MAIN_SHA:

```bash
# scripts/build-loop.sh:1408
{ state_gate && default_gate && { [[ -z "$w" ]] || (cd "$w" && state_gate); }; } > "$GATE_TMP/state" \
```

```bash
# scripts/build-loop.sh:1411
git update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA" 2>/dev/null \
```

Executed (`p3.log`): the mutant restoring `[[ "$(git show-ref ...)" == "$MAIN_SHA" ]]` turned `build-loop-merge.bats` test 2 red, and every other merge test stayed green.

**Evidence:** `scripts/build-loop.sh:552-571`, `scripts/build-loop.sh:1400-1415`, `test/scripts/build-loop-merge.bats:60-63`, scratchpad `p3.log`

---

## Claim 4: "`--marker` also skips ... one that is not strict UTF-8 (no surrogate or code point past U+10FFFF, as questions.sh check's Python decode reads it)"

**Location:** `docs/working/plan-build-loop-handoff.md:324` (also `scripts/build-loop.sh:113-115`, BODY_RULE `:807`, commit 8367359f)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-line equivalence of the Perl regex with Python's `bytes.decode("utf-8")` on 232,768 inputs: random 1–5-byte strings, plus every lead byte paired with every continuation byte in 2-, 3- and 4-byte frames. Does not establish equivalence on an input the scrub changes, because the rule reads scrubbed lines (Claim 22).

```perl
# scripts/build-loop.sh:841-842
if ($s =~ /^(?:#|\*\*needs:\*\*|\*\*status:\*\*|\*\*answer|q-[0-9])/i || index($l[$i], "<!--") >= 0
  || $l[$i] !~ /\A(?:[\x00-\x7F]|[\xC2-\xDF][\x80-\xBF]|\xE0[\xA0-\xBF][\x80-\xBF]|[\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}|\xED[\x80-\x9F][\x80-\xBF]|\xF0[\x90-\xBF][\x80-\xBF]{2}|[\xF1-\xF3][\x80-\xBF]{3}|\xF4[\x80-\x8F][\x80-\xBF]{2})*\z/) { print "rule ", $i + 1, "\n"; exit 0 }
```

questions.sh check uses `python3 -c '... .read().decode("utf-8")'` (`scripts/questions.sh:242`). `p5.log`: `cases 232768 mismatches 0`.

**Evidence:** `scripts/build-loop.sh:836-853`, `scripts/questions.sh:242`, scratchpad `p5.py`, `p5.log`

---

## Claim 5: "Discharged only in part, re-keyed to U3b3: rows 281 (one lib function), 311 (a GIT_NO_REPLACE_OBJECTS test), 666 (GLOBIGNORE, submodule.recurse, autocrlf)."

**Location:** `docs/working/plan-build-loop-handoff.md:324` (with `docs/reviews/override-log.md:709`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the claim that the named keys pass `--state` and that no test sets GIT_NO_REPLACE_OBJECTS. Does not establish whether the rest of each row is discharged.

`submodule.recurse` and `core.autocrlf` match neither the state-gate pattern nor HARDEN:

```bash
# scripts/build-loop.sh:484
STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'
```

```bash
# scripts/build-loop.sh:454
HARDEN=(core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false core.multiPackIndex=false)
```

GLOBIGNORE is a shell variable, and caller_gate reads only git variables (paraphrased — no quote available because the claim covers absence of code: no `GLOBIGNORE` match in `scripts/build-loop.sh`). No orchestrator test sets GIT_NO_REPLACE_OBJECTS (paraphrased — no quote available because the claim covers absence of code: no match in `test/scripts/build-loop-orchestrator.bats`).

**Evidence:** `scripts/build-loop.sh:454`, `scripts/build-loop.sh:484`, `scripts/build-loop.sh:532-545`, `docs/reviews/override-log.md:709`

---

## Claim 6: "--marker ... ok BRIEF SHA ... SHA: the marker (the branch tip, as --status reads it). Then the body (the message after the subject and the blank line below it, trailing blank lines dropped), scrubbed ..., each line prefixed "> " (an empty one ">"); at most 100 lines of 300 bytes (a character is never split), with a last line ... when cut. A stopped marker's body may be empty."

**Location:** `scripts/build-loop.sh:96-106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output shape, the 2-, 3- and 4-byte cut boundaries, the 101-line cut and an empty stopped body. Does not establish behaviour for a message whose blank separator line is a lone `\r`, because marker_kind refuses that marker earlier (Claim 21).

```perl
# scripts/build-loop.sh:845-851
my ($k, $cut) = (@l > $ENV{N} ? $ENV{N} : scalar @l, 0);
for my $s (@l[0 .. $k - 1]) {
  if (length($s) > $ENV{B}) {
    $s = substr($s, 0, $ENV{B}); $cut++;
    # A lead byte whose sequence the cut left short goes with its tail.
    if ($s =~ /([\xC0-\xF7][\x80-\xBF]*)\z/) { my $b = ord($1); $s = substr($s, 0, -length($1)) if length($1) < ($b >= 0xF0 ? 4 : $b >= 0xE0 ? 3 : 2) }
  }
```

(excerpt ends :851; the perl program continues to :853 — read)

Executed (`p2.log`):
- 298 bytes of `x` followed by a 4-byte emoji came out as `> ` plus 298 bytes (300 in all).
- 299 bytes of `x` followed by a 3-byte `€` came out as `> ` plus 299 bytes (301 in all).
- The note read `3 of 3 lines shown, 2 cut at 300 bytes`.
- Two blank lines after the subject kept the second as a leading `>`, which matches "the blank line below it" (one line only).

The suite's tests 3 and 6 (`orch.log`) cover the empty-`>` lines, the stopped bodies and the 101-line note.

**Evidence:** `scripts/build-loop.sh:821-870`, `test/scripts/build-loop-orchestrator.bats:62-77`, `test/scripts/build-loop-orchestrator.bats:121-138`, scratchpad `p2.log`, `orch.log`

---

## Claim 7: "skip BRIEF: WHY — As --status skips it; the tip is no blocked or stopped marker ...; the marker commit is over 64 KiB (its body is not processed); a body line [breaks the rule] ...; a line of the body, as written or as quoted, that FENCE_AWK refuses, or a fence it leaves open; a blocked marker with no body; or a read that fails." with Exit "0 every line printed (... a --marker skip is a line)"

**Location:** `scripts/build-loop.sh:107-118`, `scripts/build-loop.sh:375`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each skip cause and exit 0 for each skip that was run. Does not establish that the "read that fails" branches can actually be reached; they were read only.

```bash
# scripts/build-loop.sh:823-826
status_fields "$a"
[[ "${STATUS[line]}" == "ok "* ]] || { echo "${STATUS[line]}"; return; }
[[ "${STATUS[loop]}" == blocked || "${STATUS[loop]}" == stopped ]] \
  || { echo "skip $a: the tip of ${STATUS[branch]} is not a blocked or stopped marker (${STATUS[loop]})"; return; }
```

(excerpt ends :826; enclosing marker() continues to :870 — read)

Executed (`p2.log`): the non-marker, empty-blocked, cap, `<!--`, grammar and missing-brief cases all printed one `skip` line and `exit 0`. Suite tests 4, 5 and 7 cover the FENCE_AWK and status skips.

Side observation (pre-existing --status behaviour, not a claim of this diff): a brief absent from main prints `skip ...: the tip of - is not a blocked or stopped marker (absent)`, because status_fields reports a new brief with branch `-` (`scripts/build-loop.sh:768`).

**Evidence:** `scripts/build-loop.sh:821-870`, `scripts/build-loop.sh:375-384`, scratchpad `p2.log`, `orch.log`

---

## Claim 8: "--state ... ok, or --check's "refuse state WHAT: WHY" lines and exit 2. It checks what this script's own git reads trust, as they run hardened; it does not make a plain git command safe in the caller's shell, and it is a snapshot."

**Location:** `scripts/build-loop.sh:119-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output and exit contract and the claim that the run uses the same gate functions as --check. Does not establish what the orchestrator's own bare git does; the text disclaims that.

```bash
# scripts/build-loop.sh:1546-1553
case "$MODE" in
  marker)
    read_settings
    marker "${ARGS[0]}"
    ;;
  state)
    state_start
    echo ok
    ;;
```

(excerpt ends :1553; the dispatch case continues past it — read)

state_start is the gate's state half, with `refuse state gate:` and `refuse state objects:` (`scripts/build-loop.sh:1172-1179`). Suite test 1 (`orch.log`) shows `ok` and the refusals, each with exit 2.

**Evidence:** `scripts/build-loop.sh:582-585`, `scripts/build-loop.sh:1170-1183`, scratchpad `orch.log`

---

## Claim 9: "Exit 1 (stderr only) for a caller's GIT_CONFIG_COUNT that is not plain decimal, or a GIT_DIR naming no repository."

**Location:** `scripts/build-loop.sh:124-126`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same finding as Claim 2, in the help text. Does not establish other exit-1 paths outside the caller's environment.

Both named causes exit 1. Four more caller-environment causes do too, through `scripts/build-loop.sh:572-573` (quoted in Claim 2): a count naming a missing key, a malformed GIT_CONFIG_PARAMETERS, and a missing GIT_WORK_TREE (bash's `cd` error). This is a missing qualifier, not a wrong mechanism. The general Exit section (`:381-384`) does list "not a git repo".

**Evidence:** `scripts/build-loop.sh:572-573`, scratchpad `p1.log` (P1e–P1g)

---

## Claim 10: "First, read only here, the caller's environment: a repo-local git variable set (...; the caller's config pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX aside), or a caller pair (git -c, GIT_CONFIG_COUNT) setting a key the state gate refuses or one this script's own hardening sets (...; a git -c pair would win over it), whatever the value."

**Location:** `scripts/build-loop.sh:126-135`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the following:
- --state alone runs caller_gate, and runs it before the state gate.
- A key is refused whatever its value.
- Keys from either route are refused.

Does not establish that the ROOT `rev-parse` and `cd` (`:572-573`) run after it: they run before caller_gate. That ordering is harmless for a GIT_DIR naming another repository (Claim 17).

```bash
# scripts/build-loop.sh:582-584
# The caller's environment first: it can point the state gate's own reads elsewhere.
if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi
if [[ -n "$GATED" ]]; then state_gate || exit 2; fi
```

Executed: `GIT_CONFIG_PARAMETERS="'core.hooksPath'='/dev/null'"`, which is harden's own value, still gave `refuse state core.hookspath: ...`, exit 2 (`p1.log` P1c). A mutant running caller_gate in every mode turned the suite's caller-environment test red at `:57` (`--settings` exit 2; `p3.log`).

**Evidence:** `scripts/build-loop.sh:532-545`, `scripts/build-loop.sh:578-585`, scratchpad `p1.log`, `p3.log`

---

## Claim 11: "the default branch a symbolic ref or naming an object that is not a commit (an annotated tag)"

**Location:** `scripts/build-loop.sh:147-149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a branch ref holding an annotated tag in every gated mode, which refuse with exit 2. Does not cover a ref holding a tree, a blob or a missing object. Those never reach default_gate: resolve_main finds no main, and the run exits 1 with "needs a default branch found by name".

Executed (`p1.log` P1i):
- tag in the ref: `--check` printed `refuse state default-branch: refs/heads/main names an object that is not a commit`, exit 2. `--settings` (ungated) went on.
- tree in the ref: `build-loop.sh needs a default branch found by name ...`, exit 1.
- missing object: the same exit 1.
- packed refs: `ok`.

The behaviour change for every gated mode (--check, --merge, --start, --prompt, --state) is intended (row 656). resolve_main peels the ref:

```bash
# scripts/lib/dev-cycle-read.sh:539-540
sha="$(git show-ref --verify --hash "refs/heads/$c" 2>/dev/null || true)"
[[ -z "$sha" ]] || sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"
```

(excerpt ends :540; enclosing resolve_main() continues past :543 — read)

**Evidence:** `scripts/build-loop.sh:552-571`, `scripts/lib/dev-cycle-read.sh:529-550`, scratchpad `p1.log`

---

## Claim 12: "Exit: 0 every line printed (or help; a --marker skip is a line), for --state ok, ...; 2 ... or the state gate (--state's included) not ok. ... 1 bad usage, a GIT_CONFIG_COUNT that is not plain decimal, not a git repo, no perl ..., a failed mktemp (--state, --check, --merge, --start, --prompt; no line printed), or no default branch found by name."

**Location:** `scripts/build-loop.sh:375-384`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit codes for --state and --marker that were run, including bad usage. Does not establish the failed-mktemp path, which was read only: `GATE_TMP="$(mktemp -d)"` at `:1174` under `set -e`.

Executed: --state ok gave 0, a refusal gave 2, a bad count gave 1 and an unfound main gave 1 (`p1.log`). Every --marker skip gave 0 (`p2.log`). `--marker` with no brief or with two briefs gave 1 (suite test 7).

**Evidence:** `scripts/build-loop.sh:398-405`, `scripts/build-loop.sh:1172-1179`, scratchpad `p1.log`, `p2.log`, `orch.log`

---

## Claim 13: "The caller's own environment is trusted: its `git -c` pairs can still win, so --state reads them (caller_gate); a GIT_CONFIG_COUNT that is not plain decimal (010 reads as 8 here and as 10 to git) stops every mode."

**Location:** `scripts/build-loop.sh:450-453`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's order for the two sources of config pairs, bash's and git's readings of `010`, and the claim that the refusal comes before any git call in every mode after argument parsing. Does not cover `--help` or a usage error, which exit before harden runs; they make no git call.

```bash
# scripts/build-loop.sh:455-458
harden() {
  local c="$CALLER_COUNT" kv
  [[ "$c" =~ ^(0|[123456789][0123456789]*)$ ]] || { echo "build-loop.sh: GIT_CONFIG_COUNT is not a plain decimal count" >&2; exit 1; }
  for kv in "${HARDEN[@]}"; do
```

(excerpt ends :458; enclosing harden() continues to :463 — read; called at :464)

Executed:
- In bash, `c=010; $((c + 1))` printed `9`, so 010 reads as 8.
- git with `GIT_CONFIG_COUNT=010` and KEY_0..8 set failed with `missing config key GIT_CONFIG_KEY_9`, so it reads 10. With count 9 it read the value (`p4.log`).
- A COUNT pair `a.x=count` plus PARAMETERS `a.x=param` gave `--get-all` = `count`, then `param`: PARAMETERS (`git -c`) is applied last and wins (`p1.log` P1a).

Before line 464 the script runs no git: the lib only defines functions at top level, and scrub_reexec runs bash (paraphrased — no quote available because the claim covers absence of code: no top-level `git` call in `scripts/lib/dev-cycle-read.sh` or in `scripts/build-loop.sh:385-449`).

**Evidence:** `scripts/build-loop.sh:385-464`, `scripts/lib/dev-cycle-read.sh:155-160`, scratchpad `p1.log`, `p4.log`

---

## Claim 14: "stray_vars: the repo-local git variables set here, one per line, but the caller's (callervar) and GIT_PREFIX ... checkout_gate and caller_gate refuse them."

**Location:** `scripts/build-loop.sh:514-517`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both callers and the filter. Does not establish the "GIT_PREFIX only names a subdirectory" rationale beyond reading it.

```bash
# scripts/build-loop.sh:517
stray_vars() { local v; for v in $(git rev-parse --local-env-vars); do [[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" || echo "$v"; done; }
```

```bash
# scripts/build-loop.sh:1096-1097
x="$(stray_vars)"; v="${x%%$'\n'*}"
[[ -z "$v" ]] || { CHECKOUT_WHY="$v is set, so git can read another work tree, index, object store or config file"; return 1; }
```

caller_gate loops `for v in $(stray_vars)` at `:534`.

**Evidence:** `scripts/build-loop.sh:508-517`, `scripts/build-loop.sh:532-537`, `scripts/build-loop.sh:1092-1098`

---

## Claim 15: "GIT_GRAFT_FILE or GIT_OBJECT_DIRECTORY move the ones it does. A caller pair (...; read with the caller's count, so harden's own pairs are not listed) ...: git applies git -c pairs after harden's, so they win (a GIT_CONFIG_COUNT pair comes before harden's and loses, but is refused too)."

**Location:** `scripts/build-loop.sh:518-531`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GIT_GRAFT_FILE redirecting `--git-path info/grafts`, the listing of pairs at the caller's count, and git's order. Does not establish the redirection of GIT_OBJECT_DIRECTORY by execution: the probe with a missing directory stopped git.

```bash
# scripts/build-loop.sh:537-538
x="$(GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list --show-scope --name-only)" || { echo "refuse state caller-config: the caller's config pairs could not be read"; return 1; }
while IFS=$'\t' read -r v k; do
```

(excerpt ends :538; enclosing caller_gate() continues to :546 — read)

Executed:
- `GIT_GRAFT_FILE=$T/g git rev-parse --git-path info/grafts` printed `$T/g` (`p4.log`).
- With count 1 and a harden-like KEY_1 exported, the listing showed only `command	user.name` (`p1.log`).
- A clean `--state` with count 0 or empty printed `ok`. Harden's six keys would otherwise be refused (`p1.log` P1d).
- Order as in Claim 13.

**Evidence:** `scripts/build-loop.sh:518-546`, scratchpad `p1.log`, `p4.log`

---

## Claim 16: "resolve_main peels the ref to its commit, which land's compare-and-swap would then never match (row 656). The ref itself, not MAIN_SHA: land's re-run must leave a moved branch to its own refusal (the compare-and-swap, or the fast-forward in W)."

**Location:** `scripts/build-loop.sh:560-563`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the peel (`dev-cycle-read.sh:540`), the old-value compare-and-swap against MAIN_SHA (`:1411`) and the moved-main test's mutant. Does not establish the W path by execution (see Claim 3).

Quotes and execution are as in Claims 3 and 11. `git update-ref ... "$NEW" "$MAIN_SHA"` cannot match a ref that holds a tag's id when MAIN_SHA is the peeled commit.

**Evidence:** `scripts/build-loop.sh:560-565`, `scripts/build-loop.sh:1411`, `scripts/lib/dev-cycle-read.sh:539-540`, scratchpad `p3.log`

---

## Claim 17: "The caller's environment first: it can point the state gate's own reads elsewhere."

**Location:** `scripts/build-loop.sh:582`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of caller_gate before state_gate, and GIT_DIR or GIT_WORK_TREE naming another place being reported rather than gated. Does not establish anything about the ROOT `rev-parse` and `cd`, which run before caller_gate under the caller's variables. That is harmless: no object is read there.

Executed (`p1.log` P1g): `GIT_DIR=<another repo>` gave `refuse state GIT_DIR: set in the caller's environment, ...`, exit 2. An existing non-repository GIT_WORK_TREE gave `refuse state GIT_WORK_TREE: ...`, exit 2. The state gate's reads follow GIT_GRAFT_FILE (Claim 15).

**Evidence:** `scripts/build-loop.sh:572-585`, scratchpad `p1.log`, `p4.log`

---

## Claim 18: "A blocked marker's body rule (D3, D11), as the loop prompt states it and --marker enforces it (row 689: one string)" — BODY_RULE `no line that starts, after blanks, ">" and list markers ("-", "*", "+", "1." or "1)" and a blank), with "#", **Needs:**, **Status:**, **Answer, or Q- and a digit, in any case; no line holding "<!--"; strict UTF-8`

**Location:** `scripts/build-loop.sh:805-807`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the following:
- The one string feeds both the prompt (`:1538`) and the skip message (`:855`).
- The regex matches the wording: a list marker needs a blank after it, case is ignored, `>` needs no blank, and `1)` is caught.
- The wording matches D11 (`plan:92`), with additions.

Does not establish that the orchestrator model reads the body safely (row `:706`, deferred).

```perl
# scripts/build-loop.sh:839
(my $s = $l[$i]) =~ s/^(?:[ \t>]|[-*+][ \t]|[0-9]+[.)][ \t])*//;
```

Executed (`p2.log`):
- `\t- \t> 2) Q-5 x`, `**ANSWERED** x` and `## two` each give a skip.
- `-Q-5 x` and `1.Q-5 x` (a marker with no blank after it) are quoted, as the wording says.
- A grammar line at line 101, past the cut, still gives a skip: the rule reads all lines.

**Evidence:** `scripts/build-loop.sh:805-810`, `scripts/build-loop.sh:836-855`, `scripts/build-loop.sh:1538`, `docs/working/plan-build-loop-handoff.md:92`, scratchpad `p2.log`

---

## Claim 19: "The marker commit's size cap in bytes: over it, the body is not processed (marker_kind has still read the commit, in --status' own reads)."

**Location:** `scripts/build-loop.sh:808-810`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cap test coming before marker()'s own read, and `MARKER_MAX=65536`. Does not establish anything about memory bounds for marker_kind's reads; the text disclaims them.

The quotes are as in Claim 1 (`:829-831`). Suite test 5 (70,000 bytes) and `p6.log` (16 MB) printed the cap skip.

**Evidence:** `scripts/build-loop.sh:808-831`, scratchpad `orch.log`, `p6.log`

---

## Claim 20: "The orchestrator files the body inside an entry it heads itself: the questions readers anchor at column 0, so a quoted line is never read as a heading, a Needs line or an answer (E2, E3)."

**Location:** `scripts/build-loop.sh:816-818`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the following readers:
- ANSWER_AWK's heading, Needs and answer rules.
- questions.sh's parse_entries, extract_entry and archive patterns.
- The `### Q-` grep in check.

Does not cover two things. questions.sh's index markers are matched anywhere in a line; the `<!--` rule handles that (row `:707`). The orchestrator model's own reading is deferred (row `:706`).

```awk
# scripts/lib/dev-cycle-read.sh:2046
!header && /^\*\*Needs:\*\*/ {
```

```awk
# scripts/lib/dev-cycle-read.sh:2053-2054
line = $0; sub(/^- /, "", line)
if (index(line, id ":") == 1) { result = option(substr(line, length(id) + 2)); done = 1; next }
```

The only prefix ANSWER_AWK strips is `- `, never `>`. questions.sh uses `/^### Q-[0-9]+ /` and `/^\*\*Needs:\*\*/` (`scripts/questions.sh:161`, `:171`, `:223`, `:364`) and `grep -a '^### Q-'` (`:254`). Suite test 8 (T34 E2) executes both readers on a quoted body.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2021-2070`, `scripts/questions.sh:150-200`, `scripts/questions.sh:222-254`, `scripts/questions.sh:339-341`, `scripts/questions.sh:363-370`, scratchpad `orch.log`

---

## Claim 21: "marker_kind has refused a NUL and a second subject line; the headers end at the first empty line."

**Location:** `scripts/build-loop.sh:828`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers commits with `encoding`, a multi-line `mergetag` and a multi-line `gpgsig` header (each continuation line starts with a space, so none is empty), a subject followed straight by text, and a CRLF subject. Does not cover objects git would not parse.

```bash
# scripts/build-loop.sh:832
body=""; m="${m#*$'\n\n'}"; [[ "$m" != *$'\n'* ]] || body="${m#*$'\n'}"; body="${body#$'\n'}"
```

Executed (`p2.log`, `p2b.sh`):
- A raw commit with `encoding`, `mergetag` (with an inner ` ` line) and `gpgsig` (with an inner ` ` line) headers printed `> body one`.
- `handoff: blocked\nno blank` gave a skip: "its subject runs onto a second line".
- `handoff: blocked\r\n...` and `handoff: blocked\n\r\n...` gave the same skip.

**Evidence:** `scripts/build-loop.sh:721-748`, `scripts/build-loop.sh:826-832`, scratchpad `p2.log`

---

## Claim 22: "Scrubbed first, so the rules, the caps and FENCE_AWK read what is printed."

**Location:** `scripts/build-loop.sh:833`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pipeline order (scrub, then perl for rules and cut, then FENCE_AWK over perl's output) and lines that the scrub assembles or exposes. Does not establish anything about the scrub's own character set.

```bash
# scripts/build-loop.sh:836
body="$(printf '%s\n' "$body" | scrub | env LC_ALL=C N="$BODY_LINES" B="$BODY_BYTES" perl -e '
```

(excerpt ends :836; the perl program continues to :853 — read)

Executed (`p2.log`):
- `\001<\001!-- x`, which the scrub joins into `<!--`, gave a skip.
- A U+202E bidi character before `# hidden heading` gave a skip, because the scrub removes it and the line then starts with `#`.

**Evidence:** `scripts/build-loop.sh:833-870`, scratchpad `p2.log`

---

## Claim 23: "FENCE_AWK over the body as written, then as quoted; line N is the body's line N either way." (and at `:819-821`, "the questions file is read whole by FENCE_AWK: one refused line there would stop every answer in it")

**Location:** `scripts/build-loop.sh:857`, `scripts/build-loop.sh:819-821`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the following:
- Line numbering: one quoted line per body line, with the cut note after the last.
- The raw pass, which is the cut body with the quote removed, and the quoted pass.
- ANSWER_AWK printing `odd` for any id once a refused line exists.

Does not cover lines past the 100-line cut, which FENCE_AWK never sees. An unclosed fence at line 102 printed `ok` with 100 lines (`p2.log`). This is consistent with "read what is printed".

```bash
# scripts/build-loop.sh:859-861
for m in "$(printf '%s\n' "$body" | sed -E 's/^> ?//')" "$body"; do
  [[ -n "$body" ]] || break
  r="$(printf '%s\n' "$m" | env LC_ALL=C awk "$FENCE_AWK"'fence($0) { next } END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline }')" \
```

(excerpt ends :861; the loop continues to :867 — read)

ANSWER_AWK's `END { if (odd) print "odd " odd " " oddwhy` (`dev-cycle-read.sh:2067`) runs whatever the id. Suite test 5 reports `line 2` for a link definition found only by the quoted pass inside a balanced fence.

**Evidence:** `scripts/build-loop.sh:856-870`, `scripts/lib/dev-cycle-read.sh:2066-2070`, scratchpad `orch.log`, `p2.log`

---

## Claim 24: "- "handoff: blocked", with the question after a blank line as plain prose and an options table, at most $BODY_LINES lines of $BODY_BYTES bytes (longer is cut; a commit over $MARKER_MAX bytes is skipped): $BODY_RULE;"

**Location:** `scripts/build-loop.sh:1538`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the substitution: loop_prompt's heredoc is unquoted, and the three values are set at top level before dispatch calls it. Does not establish the exact rendered text by execution; the dispatch suite passes but does not pin this line.

```bash
# scripts/build-loop.sh:1533
  cat <<PROMPT
```

`BODY_LINES=100; BODY_BYTES=300; MARKER_MAX=65536` (`:810`). The values match what marker() enforces (Claims 6, 19).

**Evidence:** `scripts/build-loop.sh:807-810`, `scripts/build-loop.sh:1522-1543`, scratchpad `dispatch.log`

---

## Claim 25: "# Moved before land's default_gate re-run: still the compare-and-swap's refusal, not a non-commit (U3b1 B4)."

**Location:** `test/scripts/build-loop-merge.bats:60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that the case pins B4: the MAIN_SHA-compare mutant turns it red. Does not establish the W path.

```bash
# test/scripts/build-loop-merge.bats:61-62
shim commit-tree "\"\$REAL\" --git-dir='$R/.git' update-ref refs/heads/main $o"
PATH="$SHIM:$PATH" mrg "$B" --expect "$T"; M="$o" refused "the default branch moved after the check, or could not be updated; it was left as it is"
```

`p3.log`: with the mutant, `not ok 2 --merge leaves main where another writer moved it ...`. Unmutated, `merge.log` is 12/12 ok.

**Evidence:** `test/scripts/build-loop-merge.bats:55-66`, scratchpad `p3.log`, `merge.log`

---

## Claim 26: "# git's update-ref refuses a branch at a non-commit: write the ref file."

**Location:** `test/scripts/build-loop-orchestrator.bats:33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5. Does not cover other git versions.

`p7.log`: `fatal: ... trying to write non-commit object 92afade7... to branch 'refs/heads/main'`, exit 128.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:33-35`, scratchpad `p7.log`

---

## Claim 27: "# Only --state reads the caller's environment: neither --settings nor the gated --check refuses for it."

**Location:** `test/scripts/build-loop-orchestrator.bats:56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --settings and --check, and a mutant running caller_gate in every mode, which the test kills. Does not run --merge, --start or --prompt with a caller variable. They share the same single `MODE == state` guard (`:583`), but checkout_gate still refuses a stray variable for a self-merge (commit ec9ba0c7's Notes say so).

```bash
# test/scripts/build-loop-orchestrator.bats:57-60
run --separate-stderr env GIT_REPLACE_REF_BASE=refs/x/ bash "$BL" --settings; [ "$status" -eq 0 ] || { show; return 1; }
brief x "Status: open" "Branch: feat/x"; work feat/x
run --separate-stderr env GIT_REPLACE_REF_BASE=refs/x/ GIT_CONFIG_PARAMETERS="'merge.x.driver'='true'" bash "$BL" --check "$B"
[ "$status" -eq 0 ] && [[ "$output" == "ok $B "* ]] || { show; return 1; }
```

`p3.log`: with the mutant, `not ok 1 ... (line 57) ... status 2 refuse state GIT_REPLACE_REF_BASE`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:41-61`, `scripts/build-loop.sh:583`, scratchpad `p3.log`

---

## Claim 28: "# Not strict UTF-8 as questions.sh check (Python) reads it: a stray byte, a surrogate Perl's own decoder takes, past U+10FFFF (i2 fact-check 7b). Written raw: git commit-tree re-encodes a message."

**Location:** `test/scripts/build-loop-orchestrator.bats:88-89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers commit-tree rewriting the bytes, and the claim that the test kills the old-decoder mutant. Does not cover 5-byte sequences: the test has no such case, though the fuzz in Claim 4 covers them.

`p7.log`: commit-tree printed `Warning: commit message did not conform to UTF-8.` and stored `\355\240\200` as `303 255 302 240 302 200`, which is Latin-1 re-encoded as UTF-8. `p3.log`: the `utf8::decode` mutant printed `not ok 1 --marker skips a body line in entry grammar ...`, failing at the bytes loop with `ok ... > first`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:88-93`, scratchpad `p7.log`, `p3.log`

---

## Claim 29: Commit 8367359f: "the old decoder as a mutant turns the test red"; "the old MAIN_SHA compare as a mutant turns it red"; "399 changed code lines"

**Location:** commit 8367359f (body)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both mutants (Claims 25, 28) and the line count, taken as insertions plus deletions in `scripts/` and `test/` for `main...HEAD`. Does not establish the count under any other counting rule.

`git diff --numstat main...HEAD -- scripts test`: `204 31 scripts/build-loop.sh`, `4 0 test/scripts/build-loop-merge.bats`, `160 0 test/scripts/build-loop-orchestrator.bats`, which sum to 399 (paraphrased — no quote available because the claim is about a diff statistic, not a source line).

**Evidence:** `scripts/build-loop.sh`, `test/scripts/build-loop-merge.bats`, `test/scripts/build-loop-orchestrator.bats`, scratchpad `p3.log`

---

## Claim 30: Commit bodies: ec9ba0c7 "(GIT_REPLACE_REF_BASE, GIT_GRAFT_FILE and the object directories name files the state gate never reads)"; 8f99a919 "one that is not valid UTF-8" and "a marker commit over 64 KiB is skipped unread"

**Location:** commits ec9ba0c7 and 8f99a919 (bodies)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the code at HEAD does for each phrase. Does not establish whether the merge message will correct them. The rubric lists 8f99a919's two phrases as owed. **ec9ba0c7's "never reads" is not on that list.**

The verdict is text-only: the code at HEAD is right, and the bodies describe earlier wording.
- **ec9ba0c7.** GIT_GRAFT_FILE redirects the file the state gate reads: `git rev-parse --git-path info/grafts` printed the GIT_GRAFT_FILE path (`p4.log`). state_gate reads that path:

  ```bash
  # scripts/build-loop.sh:496-497
  for f in info/attributes info/grafts shallow objects/info/alternates; do
    p="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { echo "refuse state $f: its path could not be read"; return 1; }
  ```

  (excerpt ends :497; enclosing state_gate() continues to :507 — read)

  The code comment at `:523-525` was corrected in 8f99a919. The commit body was not.
- **8f99a919, "valid UTF-8".** Superseded by 8367359f's strict regex (Claim 4).
- **8f99a919, "skipped unread".** marker_kind reads the commit first (Claim 1).

**Evidence:** `scripts/build-loop.sh:494-500`, `scripts/build-loop.sh:518-531`, `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b1.md` ("Commit-body corrections owed"), scratchpad `p4.log`

---

## Claim 31: ec9ba0c7 "Rows 493, 494 and 517 close on the flow: the orchestrator's iteration starts with --state"; `scripts/build-loop.sh:579-580` "the orchestrator's --state at the start of its iteration covers both (row 690)"

**Location:** commit ec9ba0c7 (body), `scripts/build-loop.sh:579-580`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the claim that no orchestrator skill or workflow in the branch runs `build-loop.sh --state` yet. Does not establish U4's future flow.

No file under `skills/` or `workflows/` invokes `build-loop.sh` (paraphrased — no quote available because the claim covers absence of code: `grep -rn "build-loop.sh" skills workflows` is empty). The plan note (`plan:324`) was narrowed to "once U4's SKILL.md starts each iteration with `--state`". The commit body and the GATED comment state the flow in the present tense. Verifying either needs U4's SKILL.md.

**Evidence:** `scripts/build-loop.sh:578-581`, `docs/working/plan-build-loop-handoff.md:324`

---

## Claims Requiring Attention

### Incorrect
- **Claim 30** (commits ec9ba0c7 and 8f99a919): text-only. ec9ba0c7 says GIT_GRAFT_FILE and the object directories "name files the state gate never reads", but GIT_GRAFT_FILE redirects `info/grafts`, which state_gate reads. Add this phrase to the merge message's owed corrections, beside 8f99a919's "valid UTF-8" and "skipped unread", which are already listed.

### Stale
None.

### Mostly Accurate
- **Claim 2** (`docs/working/plan-build-loop-handoff.md:324`) and **Claim 9** (`scripts/build-loop.sh:124-126`): --state's exit-1 list names two caller causes. A GIT_CONFIG_COUNT naming a missing key, a malformed GIT_CONFIG_PARAMETERS and a missing GIT_WORK_TREE also exit 1 with stderr only. The two config cases print "Not inside a git repository". Say "e.g." or list them.

### Unverifiable
- **Claim 31** (commit ec9ba0c7; `scripts/build-loop.sh:579-580`): "the orchestrator's iteration starts with --state" needs U4's SKILL.md.

## Goal-Alignment Note

The PR has two goals:
- `--state`: the state gate alone, plus one read of the caller's git environment.
- `--marker`: a quoted marker body that no questions reader can take as a heading, a Needs or Status line, or an answer.

At HEAD both hold in behaviour, checked by execution:
- caller_gate runs only in `--state`, before the state gate, and refuses keys from either config route whatever the value.
- git applies `git -c` after GIT_CONFIG_COUNT pairs, as the comment says.
- A non-decimal count stops every mode before any git call.
- default_gate refuses a tag-named main and leaves a moved main to the compare-and-swap.
- The strict-UTF-8 regex agrees with Python's decode on 232,768 inputs, which closes i2's C1.
- The body extraction survives gpgsig and mergetag headers.
- The cut never splits a character.
- Scrubbing comes before every rule.
- All three claimed mutants are killed.

No behavioural Incorrect remains. The one Incorrect is commit-body text, which can be fixed in the merge message. The two Mostly-accurate verdicts are one incomplete exit-1 list, stated in two places. Neither changes a decision the script makes.
