Commit: ec9ba0c7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b1 (branch `feat/build-loop-u3b1`, HEAD ec9ba0c7)
**Scope:** full branch, `git diff main...HEAD`: `scripts/build-loop.sh` (every comment, help line, refusal text and the prompt line the branch added or edited), `test/scripts/build-loop-orchestrator.bats` (test titles and comments), commit messages of 1bf01630 and ec9ba0c7, the plan's U3b1 note and D11 (`docs/working/plan-build-loop-handoff.md:92`, `:324`), and the override-log rows the unit cites (247, 252, 259, 273, 276, 281, 311, 493, 494, 517, 525, 656, 666, 689, 690, 696). Readers named by the diff's claims were read for context (`scripts/lib/dev-cycle-read.sh` FENCE_AWK, ANSWER_AWK, scrub, resolve_main; `scripts/questions.sh` parse_entries, extract_entry, live_without_entry).
**Checked:** 2026-10-12
**Commit:** ec9ba0c7
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 29
**Summary:** 21 verified, 4 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): every logged entry is a measured value or a consumer that does not reference a file. No claim below matches a logged pattern, and no Incorrect verdict here is a fabricated symbol, API or option. The log is unchanged.

Execution provenance (every `executed` claim cites these). git 2.39.5, bats 1.8.2, bash 5.2, WSL2. Every probe ran under `set -eu` in its own `mktemp -d /tmp/u3b1fc1-XXXX` directory. The bats probes ran under `TMPDIR=$(mktemp -d /tmp/u3b1fc1-XXXX)` and refused to run outside it. Each used the branch's own fixture (`test/lib/build-loop-fixtures.bash`, hermetic env), with `BL` pointing at `/workspace/.claude/wt-build-loop-u3b1/scripts/build-loop.sh`. No file under the worktree was copied or changed. Each temp dir was removed afterwards, and no process was left behind (checked with `ps`). Scripts and captured output are in `/tmp/claude-1000/-workspace/402ec840-a464-40f5-96ae-98af0cc535cf/scratchpad/u3b1/fc1/`, abbreviated `$FC` below. The cwd was `$FC` for the probes and `/workspace` for the suite.
- **suite:** `TMPDIR=$(mktemp -d /tmp/u3b1fc1-XXXX) timeout 500 bats /workspace/.claude/wt-build-loop-u3b1/test/scripts/build-loop-orchestrator.bats`, 2026-10-12T19:50:02Z, exit 0, 8/8 ok → `$FC/suite.log`
- **p1:** plain git. Tests whether config pairs from GIT_CONFIG_COUNT or GIT_CONFIG_PARAMETERS take precedence, how git and bash each parse GIT_CONFIG_COUNT, and what a harden-like loop does with `010` → `$FC/p1-git.sh`, `$FC/p1.log`, 2026-10-12T19:45:53Z, exit 0
- **p2:** bats probe that checks several things:
  - `--help`, a bad option and `--marker` with a non-decimal count
  - `--state` under GIT_DIR (other, missing, bare), GIT_WORK_TREE, GIT_COMMON_DIR, GIT_CONFIG, GIT_PREFIX and GIT_NO_REPLACE_OBJECTS
  - caller pairs through `-c` and through COUNT
  - `--check` with GIT_REPLACE_REF_BASE
  - a tag-of-tag main under --state, --check and --status, and a packed main
  - `--marker` against gpgsig, encoding and mergetag headers
  - UTF-8 cuts, leading blank lines, rule variants, a heading at line 150, and a missing brief

  Files: `$FC/p2.bats`, `$FC/p2.log`, 2026-10-12T19:46:34Z, exit 0 (5/5).
- **p3:** a refdef inside a balanced fence (the quoted-only refusal), GLOBIGNORE, `submodule.recurse`/`core.autocrlf` via `-c` → `$FC/p3.bats`, `$FC/p3.log`, 2026-10-12T19:47:42Z. Tests 1 and 2 ran ok. A third test (an `include.path` to a FIFO) hung, as expected of any git config read, and was killed by its `timeout`, so the run's exit was 124. That test bears on no claim below.
- **p4 / p4b:** `git rev-parse --git-path` under GIT_GRAFT_FILE, GIT_SHALLOW_FILE and GIT_OBJECT_DIRECTORY → `$FC/p4-gitpath.sh`, `$FC/p4.log` (19:51:05Z, exit 0), `$FC/p4b.sh`, `$FC/p4b.log` (19:51:12Z, exit 0)
- **p5:** `git update-ref refs/heads/main <annotated tag id>` → `$FC/p5.sh`, `$FC/p5.log`, 2026-10-12T19:51:25Z, exit 0 (the update-ref's own rc 128 is the expected refusal)
- **p6:** `--merge` with no worktree on main, a PATH shim on `commit-tree` that moves main to a new commit before land's re-run of default_gate. It uses the same shim pattern as `test/scripts/build-loop-merge.bats:22-30` → `$FC/p6.bats`, `$FC/p6.log`, 2026-10-12T19:52:07Z, exit 0

---

## Claim 1: "--marker ... ok BRIEF SHA ... Then the body (the message after the subject and the blank line below it, trailing blank lines dropped), scrubbed as all output is, each line prefixed "> " (an empty one ">"); at most 100 lines of 300 bytes ... with a last line "> (build-loop.sh --marker cut this body: K of N lines shown, M cut at 300 bytes)" when cut. A stopped marker's body may be empty."

**Location:** `scripts/build-loop.sh:96-106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what the ok form prints for blocked and stopped markers: the body boundary, trailing-blank drop, prefixes, the 100-line and 300-byte caps and the note. It does not establish the byte cap of the printed line (the `> ` prefix makes it up to 302 bytes) or the scrub's own 4096-byte cut, which comes first and does not matter at a 300-byte cap.

The body extraction and print:
```bash
# scripts/build-loop.sh:807-808
  m="$(git cat-file commit "${STATUS[sha]}")" || { echo "skip $a: its marker could not be read"; return; }
  body=""; m="${m#*$'\n\n'}"; [[ "$m" != *$'\n'* ]] || body="${m#*$'\n'}"; body="${body#$'\n'}"
```
```perl
# scripts/build-loop.sh:813, 818-826 (inside marker(), which continues to :844 — read)
    my @l = map { s/\n\z//r } <STDIN>; pop @l while @l && $l[-1] =~ /^[ \t]*\z/;
    my ($k, $cut) = (@l > $ENV{N} ? $ENV{N} : scalar @l, 0);
    ...
      print $s eq "" ? ">\n" : "> $s\n";
    ...
    print "> (build-loop.sh --marker cut this body: $k of ", scalar @l, " lines shown, $cut cut at $ENV{B} bytes)\n" if $k < @l || $cut')" \
```
The suite's tests 3 and 6 pass and assert these outputs exactly (`$FC/suite.log`). Probe p2 adds two cases. A body after two extra blank lines prints `>`, `>`, `> after two blanks`, so leading blanks are kept. A stopped marker under a mergetag header prints `> reason body` (`$FC/p2.log`).

**Evidence:** `scripts/build-loop.sh:96-106`, `scripts/build-loop.sh:800-844`, `test/scripts/build-loop-orchestrator.bats:71-88,122-139`, `$FC/suite.log`, `$FC/p2.log`

---

## Claim 2: "skip BRIEF: WHY — As --status skips it; the tip is no blocked or stopped marker (WHY names --status' LOOP); a body line starts, after blanks, ">" and list markers ... with "#", "**Needs:**", "**Status:**", "**Answer" or "Q-" and a digit, in any case (the loop prompt's rule); a line of the body, as written or as quoted, that FENCE_AWK refuses, or a fence it leaves open; a blocked marker with no body; or a read that fails."

**Location:** `scripts/build-loop.sh:107-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed skip cause and the case-insensitive rule over every body line, including lines past the 100-line cap. It does not establish that the quoted-form FENCE_AWK pass is pinned by a test (Claim 27), or how a failed `git cat-file` behaves (static only: `:807`).

The rule strips `[ \t>]`, `[-*+][ \t]` and `[0-9]+[.)][ \t]` prefixes, then matches case-insensitively:
```perl
# scripts/build-loop.sh:815-816 (enclosing marker() continues to :844 — read)
      (my $s = $l[$i]) =~ s/^(?:[ \t>]|[-*+][ \t]|[0-9]+[.)][ \t])*//;
      if ($s =~ /^(?:#|\*\*needs:\*\*|\*\*status:\*\*|\*\*answer|q-[0-9])/i) { print "rule ", $i + 1, "\n"; exit 0 }
```
The rule loop runs over all of `@l` before the cap. In p2 a `# late` at body line 150 skipped with "line 150", and `\t# h`, `+ q-7 x` and `1) **ANSWERED** x` each skipped. Two cases skipped with --status' line: a missing brief ("not a build brief") and a subject running onto a second line (marker_kind's "bad"). Every skip in p2 and the suite exited 0 (`$FC/p2.log`, `$FC/suite.log` tests 4, 5 and 7).

**Evidence:** `scripts/build-loop.sh:107-115`, `scripts/build-loop.sh:800-844`, `$FC/p2.log`, `$FC/p3.log`, `$FC/suite.log`

---

## Claim 3: "--state the state gate --check runs first, alone ...: ok, or --check's "refuse state WHAT: WHY" lines and exit 2. ... Then --check's state gate, its default-branch rules and its object check, as listed there."

**Location:** `scripts/build-loop.sh:116-119,127-128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `--state` runs state_gate, default_gate, gate_repo and store_check, and nothing else of gate_start, with exit 0 on ok and 2 on a refusal. It does not establish the D13/F51 orchestrator usage the parenthesis names (that is U3b3's skill flow, Claim 23).

```bash
# scripts/build-loop.sh:563-564 (top level)
if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi
if [[ -n "$GATED" ]]; then state_gate || exit 2; fi
```
```bash
# scripts/build-loop.sh:1149-1159
state_start() {
  default_gate || exit 2
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
  gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
  store_check --main "$MAIN_SHA" \
    || { echo "refuse state objects: ..."; exit 2; }
}
gate_start() {
  state_start
  reader_settings; read_settings; never_res; open_shared
}
```
The `state)` arm is `state_start; echo ok` (`:1527-1529`). Suite test 1 refuses each planted state with exit 2 and prints `ok` on a clean repo (`$FC/suite.log`).

**Evidence:** `scripts/build-loop.sh:116-128`, `scripts/build-loop.sh:563-567`, `scripts/build-loop.sh:1149-1159`, `scripts/build-loop.sh:1527-1529`, `$FC/suite.log`

---

## Claim 4a: "read only here, the caller's environment: a repo-local git variable set (GIT_REPLACE_REF_BASE, GIT_GRAFT_FILE, GIT_SHALLOW_FILE, GIT_DIR, the object directories and the like; the caller's config pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX aside)"

**Location:** `scripts/build-loop.sh:119-123`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which repo-local variables `--state` refuses or passes, and that no other mode runs caller_gate. It does not establish that variables outside `git rev-parse --local-env-vars` are checked: they are not (GLOBIGNORE passes, p3; see Claim 24).

```bash
# scripts/build-loop.sh:517-522 (caller_gate continues to :529 — read)
caller_gate() {
  local v x k bad=0
  for v in $(git rev-parse --local-env-vars); do
    [[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" \
      || { echo "refuse state $v: set in the caller's environment, ..."; bad=1; }
  done
```
The only call site is `if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` (`:563`; grep finds no other). In p2 GIT_DIR (with a work tree), GIT_WORK_TREE, GIT_COMMON_DIR and GIT_CONFIG each refused with exit 2. GIT_PREFIX and an empty GIT_NO_REPLACE_OBJECTS printed `ok`. `--check` under GIT_REPLACE_REF_BASE printed no caller refusal (`$FC/p2.log`). The suite covers the five variables in test 2.

**Evidence:** `scripts/build-loop.sh:504`, `scripts/build-loop.sh:517-529`, `scripts/build-loop.sh:563`, `$FC/p2.log`, `$FC/suite.log`

---

## Claim 4b: "First, read only here, the caller's environment" (and `:562` "The caller's environment first")

**Location:** `scripts/build-loop.sh:119`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that caller_gate runs before state_gate and every gate read. It does not establish "first" against the whole run: harden, `git rev-parse --show-toplevel` and the `cd` come earlier, and a GIT_DIR naming a bare or missing repository exits 1 there, with no refuse line.

```bash
# scripts/build-loop.sh:554-555, 563
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
...
if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi
```
In p2, `GIT_DIR=<bare repo>` and `GIT_DIR=<missing>` each gave `status 1`, `err: Not inside a git repository`, with no caller_gate line (`$FC/p2.log`). Nothing is decided either way, because exit 1 is "not a git repo" in the Exit doc. The precise version is: "first among the gate's checks, after the script finds and enters the top level".

**Evidence:** `scripts/build-loop.sh:119`, `scripts/build-loop.sh:554-564`, `$FC/p2.log`

---

## Claim 5: "a caller pair (git -c, GIT_CONFIG_COUNT) setting a key the state gate refuses or one this script's own hardening sets (...), which would win over it"; refusal text "set by the caller's git -c or GIT_CONFIG_COUNT pairs, it overrides the gate's hardening or a key the state gate refuses"; test title "a config pair the gate's hardening or state gate would lose to"

**Location:** `scripts/build-loop.sh:123-127`, `scripts/build-loop.sh:526`, `test/scripts/build-loop-orchestrator.bats:47,57-58`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "would win / overrides the hardening" mechanism for **GIT_CONFIG_COUNT** pairs that set one of harden's keys. For `git -c` pairs the mechanism is true (Claim 10). It does not establish any change in what is refused: the code refuses these pairs, which is stricter than needed, not looser.

harden appends its pairs **after** the caller's COUNT pairs, at indexes `CALLER_COUNT..`:
```bash
# scripts/build-loop.sh:447-454
harden() {
  local c="$CALLER_COUNT" kv
  [[ "$c" =~ ^(0|[123456789][0123456789]*)$ ]] || { ...; exit 1; }
  for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false core.multiPackIndex=false; do
    export "GIT_CONFIG_KEY_$c=${kv%%=*}" "GIT_CONFIG_VALUE_$c=${kv#*=}"; c=$((c + 1))
  done
  export GIT_CONFIG_COUNT="$c"
}
```
Git applies COUNT pairs in index order, last one wins. p1 case 1c (`KEY_0=core.hooksPath /x`, `KEY_1=core.hooksPath /dev/null`) printed `/dev/null` (`$FC/p1.log`). So a caller COUNT pair for `core.hooksPath`, `core.multiPackIndex` and the rest **loses** to harden. The suite's COUNT case (bats `:57-58`) and p2's `core.multiPackIndex` case are still refused with "it overrides the gate's hardening" (`$FC/p2.log`). Most of those keys (`core.usereplacerefs`, `commitgraph`, `multipackindex`) are not in STATE_KEYS_RE either, so neither half of the "or" holds for them. The precise version is: "a git -c pair for one of harden's keys wins over it; any caller pair (git -c or COUNT) for a key the state gate refuses takes effect". It could also just say that harden's keys are refused from either source as a precaution.

**Evidence:** `scripts/build-loop.sh:123-127`, `scripts/build-loop.sh:447-454`, `scripts/build-loop.sh:523-528`, `test/scripts/build-loop-orchestrator.bats:47,57-58`, `$FC/p1.log`, `$FC/p2.log`

---

## Claim 6: "--check ... the default branch a symbolic ref or naming an object that is not a commit (an annotated tag)"

**Location:** `scripts/build-loop.sh:139-141`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check (and every gate_start mode) refusing a main that holds a tag id, including a tag of a tag. It does not establish the refusal text's accuracy in land's re-run (Claim 13).

```bash
# scripts/build-loop.sh:544-545 (default_gate continues to :551 — read)
  [[ "$(git show-ref --verify --hash "refs/heads/$MAIN" 2>/dev/null)" == "$MAIN_SHA" ]] \
    || { echo "refuse state default-branch: refs/heads/$MAIN names an object that is not a commit"; bad=1; }
```
In p2, a main holding a tag-of-tag id made both `--state` and `--check` refuse with this line and exit 2, while `--status` printed its ok line (ungated). A packed main at the commit gave `ok` (`$FC/p2.log`).

**Evidence:** `scripts/build-loop.sh:139-141`, `scripts/build-loop.sh:535-551`, `$FC/p2.log`

---

## Claim 7: "Exit: 0 every line printed (or help; a --marker skip is a line), for --state ok, ...; 2 ... or the state gate (--state's included) not ok. ... 1 bad usage, a GIT_CONFIG_COUNT that is not plain decimal, not a git repo, ..., a failed mktemp (--state, --check, --merge, --start, --prompt; no line printed), or no default branch found by name."

**Location:** `scripts/build-loop.sh:367-376`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit codes for --marker (0 on ok and on skip), --state (0, 2) and a non-decimal count (1). The failed-mktemp exit was read statically: `set -e` around `GATE_TMP="$(mktemp -d)"` at `:1151`. It does not establish that a non-decimal count stops `--help`: help exits 0 before harden runs (p2: `--help` with `GIT_CONFIG_COUNT=010` gave status 0).

```bash
# scripts/build-loop.sh:449
  [[ "$c" =~ ^(0|[123456789][0123456789]*)$ ]] || { echo "build-loop.sh: GIT_CONFIG_COUNT is not a plain decimal count" >&2; exit 1; }
```
In p2, `--marker` and `--state` under `010`, under `" 1"` and outside a repo each gave status 1 with this stderr. `--bogus` gave the usage error with status 1 (`$FC/p2.log`).

**Evidence:** `scripts/build-loop.sh:367-376`, `scripts/build-loop.sh:446-454`, `scripts/build-loop.sh:1151`, `$FC/p2.log`, `$FC/suite.log`

---

## Claim 8: "The caller's own environment is trusted: its `git -c` pairs can still win, so --state reads them (caller_gate); a GIT_CONFIG_COUNT that is not plain decimal (010 reads as 8 here and as 10 to git) stops every mode."

**Location:** `scripts/build-loop.sh:442-445`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers precedence of `git -c` over harden's pairs, the 8-versus-10 reading, and the stop running before any git call in every mode. It does not establish behaviour for `--help`, which exits before harden (Claim 7's residue).

p1 shows the three halves (`$FC/p1.log`):
- git reads `010` as count 10: "missing config key GIT_CONFIG_KEY_1".
- bash reads `$((010))=8`. A harden-like loop writes `GIT_CONFIG_KEY_010` and then `GIT_CONFIG_KEY_9`.
- `git -c core.hooksPath=/x` beats a COUNT pair `/dev/null` (case 1d).

git also accepts `" 1"` and `"+1"` (p1). The regex refuses both, and p2 confirms `" 1"` stops `--state`. No git call happens before harden. The lib has no top-level git call (a grep for `^git ` or `=$(git` at column 0 in `scripts/lib/dev-cycle-read.sh` found none). The only top-level lines before `:455` are the perl check, the source and scrub_reexec, which re-runs bash.

**Evidence:** `scripts/build-loop.sh:380-389`, `scripts/build-loop.sh:442-455`, `$FC/p1.log`, `$FC/p2.log`

---

## Claim 9: "A repo-local git variable (...) but the caller's config pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX: GIT_REPLACE_REF_BASE, GIT_GRAFT_FILE, GIT_SHALLOW_FILE and the object directories name files the state gate does not read." (commit ec9ba0c7: "GIT_REPLACE_REF_BASE, GIT_GRAFT_FILE and the object directories name files the state gate never reads")

**Location:** `scripts/build-loop.sh:509-512`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated reason for refusing these variables, for GIT_GRAFT_FILE and GIT_OBJECT_DIRECTORY. For GIT_REPLACE_REF_BASE, GIT_SHALLOW_FILE and GIT_ALTERNATE_OBJECT_DIRECTORIES the reason holds. It does not establish any change in what is refused: caller_gate refuses all of them, which is correct and conservative.

state_gate reads its files through `git rev-parse --git-path`:
```bash
# scripts/build-loop.sh:486-489 (state_gate continues to :494 — read)
  for f in info/attributes info/grafts shallow objects/info/alternates; do
    p="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { ...; return 1; }
    if [[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]; then echo "refuse state $f: present and not an empty file"; bad=1; fi
  done
```
git maps those paths through the environment (p4/p4b):
- `GIT_GRAFT_FILE=$T/g` gives `info/grafts -> $T/g`.
- `GIT_OBJECT_DIRECTORY=$T/o` gives `objects/info/alternates -> $T/o/info/alternates`.
- `GIT_SHALLOW_FILE=$T/s` leaves `shallow -> .git/shallow`.

So the state gate does read the graft file GIT_GRAFT_FILE names and the alternates file under GIT_OBJECT_DIRECTORY (`$FC/p4.log`, `$FC/p4b.log`). This agrees with `:562`'s own comment ("it can point the state gate's own reads elsewhere", Claim 15), not with this one. The precise version is: "GIT_REPLACE_REF_BASE, GIT_SHALLOW_FILE and GIT_ALTERNATE_OBJECT_DIRECTORIES name files the state gate does not read; GIT_GRAFT_FILE and GIT_OBJECT_DIRECTORY move the files it does read".

**Evidence:** `scripts/build-loop.sh:509-512`, `scripts/build-loop.sh:486-489`, commit ec9ba0c7 body, `$FC/p4.log`, `$FC/p4b.log`

---

## Claim 10: "A caller pair (git -c, GIT_CONFIG_COUNT; read with the caller's count, so harden's own pairs are not listed) ...: git applies the caller's git -c after harden's pairs, so it wins."

**Location:** `scripts/build-loop.sh:512-515`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listing (only the caller's COUNT pairs plus GIT_CONFIG_PARAMETERS appear in `command` scope) and git applying `-c` after COUNT pairs. It does not establish the COUNT-pair half of the header's "would win" (Claim 5).

```bash
# scripts/build-loop.sh:523
  x="$(GIT_CONFIG_COUNT="$CALLER_COUNT" git config --list --show-scope --name-only)" || { ...; return 1; }
```
Harden's own pairs sit at indexes `>= CALLER_COUNT`, so git never reads them under this count. A clean repo prints `ok`, where it would refuse `core.hookspath` and the other harden keys if they were listed. A caller COUNT pair `user.name` passes (suite test 2). p1 case 1b lists `command x.y=count` before `command x.y=param`, and `git config --get` returns `param` (`$FC/p1.log`).

**Evidence:** `scripts/build-loop.sh:446-454`, `scripts/build-loop.sh:512-529`, `$FC/p1.log`, `$FC/suite.log`

---

## Claim 11: "resolve_main peels the ref to its commit, which land's compare-and-swap would then never match (row 656)."

**Location:** `scripts/build-loop.sh:543`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the peel (`^{commit}`) in resolve_main and the CAS old-value in land. It does not establish whether the CAS failure was ever reachable before this check: git refuses to write a tag id to a branch (p5), so it needs a hand-written ref file.

```bash
# scripts/lib/dev-cycle-read.sh:539-540 (resolve_main continues to :551 — read)
    sha="$(git show-ref --verify --hash "refs/heads/$c" 2>/dev/null || true)"
    [[ -z "$sha" ]] || sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"
```
```bash
# scripts/build-loop.sh:1388
    git update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA" 2>/dev/null \
```
With refs/heads/main holding a tag id, the old-value `MAIN_SHA` (the peeled commit) never equals the ref.

**Evidence:** `scripts/lib/dev-cycle-read.sh:529-551`, `scripts/build-loop.sh:543`, `scripts/build-loop.sh:1388`, `$FC/p5.log`

---

## Claim 12: refusal text "refs/heads/$MAIN names an object that is not a commit" (startup: --state and gate_start)

**Location:** `scripts/build-loop.sh:545`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the call at startup, where resolve_main ran microseconds earlier: a mismatch there is a tag (or tag of tag) id. A packed or loose ref at the commit passes. It does not establish the text in land's later call (Claim 13), or under a writer racing the few calls between resolve_main and default_gate.

Since resolve_main took `MAIN_SHA` from the same `show-ref --verify --hash` peeled by `^{commit}` (Claim 11 quote), the two values differ only when the ref holds a non-commit that peels to a commit, or the ref moved in between. In p2 the tag-of-tag case refused and the packed main printed `ok` (`$FC/p2.log`). A ref to a tree or blob does not peel, so resolve_main skips it (`:540-541`) and this check is never reached for it. Confidence is Medium only because of the race window.

**Evidence:** `scripts/build-loop.sh:544-545`, `scripts/lib/dev-cycle-read.sh:536-542`, `$FC/p2.log`

---

## Claim 13: the same refusal text "names an object that is not a commit" when land re-runs default_gate (`{ state_gate && default_gate && ...; } > "$GATE_TMP/state"`)

**Location:** `scripts/build-loop.sh:545` (reached from `scripts/build-loop.sh:1385`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal reason --merge prints when main moved to another commit between the startup and land's state re-check, with no worktree on main. It does not establish any change in the outcome: the merge is still refused and main is left where the other writer put it.

```bash
# scripts/build-loop.sh:1385-1389 (land continues to :1397 — read)
  { state_gate && default_gate && { [[ -z "$w" ]] || (cd "$w" && state_gate); }; } > "$GATE_TMP/state" \
    || { MERGE_WHY="the git state changed after the check ($(head -n 1 "$GATE_TMP/state"))"; return 1; }
  if [[ -z "$w" ]]; then
    git update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA" 2>/dev/null \
      || { MERGE_WHY="the default branch moved after the check, or could not be updated; it was left as it is"; return 1; }
```
p6 moved main to a new **commit** from a `commit-tree` shim. The output was `refuse ...: the git state changed after the check (refuse state default-branch: refs/heads/main names an object that is not a commit)`, and `git cat-file -t main` gave `commit` (`$FC/p6.log`). Before this diff, the CAS at `:1388` reported this case as "the default branch moved after the check". The existing merge test shims `update-ref` itself, so it still sees that text (`test/scripts/build-loop-merge.bats:54-58`). Now a move that lands before `:1385` is reported as a non-commit. The precise text covers both causes, for example "refs/heads/$MAIN is not at the default branch's commit $MAIN_SHA (an annotated tag, or it moved)". This is printed output, not a comment.

**Evidence:** `scripts/build-loop.sh:544-545`, `scripts/build-loop.sh:1385-1390`, `test/scripts/build-loop-merge.bats:54-58`, `$FC/p6.log`

---

## Claim 14: "Every mode but the read modes decides or writes (a new mode is gated by default). --marker reads one marker as --status reads its tip" (commit: "It is ungated, like --status")

**Location:** `scripts/build-loop.sh:558-561`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers GATED being empty exactly for settings, status and marker, and --marker reading the tip through status_fields. It does not establish the clause "the orchestrator's --state at the start of its iteration covers both", which is flow (Claim 23).

```bash
# scripts/build-loop.sh:561
GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1  # not the gate repository's GATE_*
```
`marker()` calls `status_fields "$a"` and reads `${STATUS[sha]}` (`:802-807`), and the `marker)` arm runs `read_settings; marker ...` with no gate_start (`:1523-1526`).

**Evidence:** `scripts/build-loop.sh:558-561`, `scripts/build-loop.sh:800-807`, `scripts/build-loop.sh:1523-1526`

---

## Claim 15: "The caller's environment first: it can point the state gate's own reads elsewhere."

**Location:** `scripts/build-loop.sh:562`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the redirection: GIT_GRAFT_FILE and GIT_OBJECT_DIRECTORY move state_gate's `--git-path` reads. It does not establish "first" against the top-level `rev-parse`/`cd` (Claim 4b).

p4/p4b: `--git-path info/grafts` follows GIT_GRAFT_FILE and `--git-path objects/info/alternates` follows GIT_OBJECT_DIRECTORY (`$FC/p4.log`, `$FC/p4b.log`). state_gate reads exactly those paths (Claim 9's quote, `:486-489`).

**Evidence:** `scripts/build-loop.sh:562-564`, `scripts/build-loop.sh:486-489`, `$FC/p4.log`, `$FC/p4b.log`

---

## Claim 16: "A blocked marker's body rule (D3, D11), as the loop prompt states it and --marker enforces it (row 689: one string), with BODY_LINES and BODY_BYTES."

**Location:** `scripts/build-loop.sh:785-788`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers one BODY_RULE string used by the prompt and the skip message, and BODY_LINES/BODY_BYTES feeding both the prompt and the perl caps. It does not establish that the perl regex is derived from the string: the regex is a separate encoding of the same rule, held equal by the suite's RULE literal and its rule cases.

```bash
# scripts/build-loop.sh:787-788
BODY_RULE='no line that starts, after blanks, ">" and list markers, with "#", **Needs:**, **Status:**, **Answer, or Q- and a digit'
BODY_LINES=100; BODY_BYTES=300
```
The prompt now reads `... an options table, at most $BODY_LINES lines of $BODY_BYTES bytes: $BODY_RULE;` (`:1515`). main's prompt had the same sentence inline (`git show main:scripts/build-loop.sh`, line 1373, identical text). The skip message interpolates `$BODY_RULE` (`:829`), and perl takes `N="$BODY_LINES" B="$BODY_BYTES"` (`:812`).

**Evidence:** `scripts/build-loop.sh:787-788`, `scripts/build-loop.sh:812`, `scripts/build-loop.sh:829`, `scripts/build-loop.sh:1515`, `test/scripts/build-loop-orchestrator.bats:25`

---

## Claim 17: "The orchestrator files the body inside an entry it heads itself: the questions readers anchor at column 0, so a quoted line is never read as a heading, a Needs line or an answer (E2, E3)." (plan D11: "Both questions readers anchor at column 0")

**Location:** `scripts/build-loop.sh:794-796`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ANSWER_AWK (heading, Needs header, answer line) and questions.sh's parse_entries, extract_entry, live_without_entry and check's heading grep. All are column-0 anchored, so a `> ` line never matches them. It does not establish that a quoted line stays out of questions.sh's index summary: parse_entries takes the first non-`**`, non-`###`, non-`<` prose line after the header as the summary, and a quoted body line can be that line.

```awk
# scripts/lib/dev-cycle-read.sh:2040-2042, 2045, 2052-2055 (ANSWER_AWK continues to :2073 — read)
function heading(l,   h) {
  if (substr(l, 1, 4) != "### ") return 0
...
!header && /^\*\*Needs:\*\*/ {
...
  line = $0; sub(/^- /, "", line)
  if (index(line, id ":") == 1) { result = option(substr(line, length(id) + 2)); done = 1; next }
  low = tolower(line)
  if (low !~ /^\*\*answer(:|ed| \()/) next
```
```awk
# scripts/questions.sh:161, 171, 184
        /^### Q-[0-9]+ / {
        /^\*\*Needs:\*\*/ {
        want_summary && status != "" && /[^[:space:]]/ && !/^\*\*/ && !/^###/ && !/^</ {
```
Suite test 8 places E2's grammar lines quoted under an ANSWERED entry. `--check-answer` reads `drop` (the user's `Q-120: [2]`), and `archive` moves the entry (`$FC/suite.log`).

**Evidence:** `scripts/build-loop.sh:794-796`, `scripts/lib/dev-cycle-read.sh:2020-2073`, `scripts/questions.sh:150-232`, `scripts/questions.sh:362-371`, `docs/working/plan-build-loop-handoff.md:92`, `$FC/suite.log`

---

## Claim 18: "marker_kind has refused a NUL and a second subject line; the headers end at the first empty line."

**Location:** `scripts/build-loop.sh:806`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers gpgsig, mergetag and encoding headers, whose continuation lines start with a space and are never empty, plus marker_kind's two refusals. It does not establish handling of a marker with no message, which marker_kind's subject check already excludes.

```bash
# scripts/build-loop.sh:713, 719-720 (marker_kind continues to :730 — read)
  if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"; return; fi
  rest="${msg#"$subj"}"; rest="${rest#$'\n'}"
  if [[ "$msg" == *$'\n'* && -n "${rest%%$'\n'*}" ]]; then echo "bad its subject runs onto a second line"; return; fi
```
In p2 a hand-built commit with `encoding` and a multi-line `gpgsig` (with a ` ` blank continuation) printed `> Which one?`. A `mergetag` stopped marker printed `> reason body`. `handoff: blocked\nsecond line` skipped as "subject runs onto a second line" (`$FC/p2.log`).

**Evidence:** `scripts/build-loop.sh:701-731`, `scripts/build-loop.sh:806-808`, `$FC/p2.log`

---

## Claim 19: "Scrubbed first, so the rules, the caps and FENCE_AWK read what is printed." / "FENCE_AWK over the body as written, then as quoted; line N is the body's line N either way."

**Location:** `scripts/build-loop.sh:809,831`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order (scrub → rule → caps → FENCE_AWK on the de-quoted and quoted forms) and the line numbering. It does not establish that "as written" means the raw message: it is the scrubbed, capped body with `> ` removed, so lines past 100 and bytes past 300 are not FENCE_AWK-checked (they are not printed either).

```bash
# scripts/build-loop.sh:812, 833-836 (marker continues to :844 — read)
  body="$(printf '%s\n' "$body" | scrub | env LC_ALL=C N="$BODY_LINES" B="$BODY_BYTES" perl -e '
  for m in "$(printf '%s\n' "$body" | sed -E 's/^> ?//')" "$body"; do
    [[ -n "$body" ]] || break
    r="$(printf '%s\n' "$m" | env LC_ALL=C awk "$FENCE_AWK"'fence($0) { next } END { ... }')" \
```
Suite test 6 shows `\001`, U+202E, CR and C1 dropped before the cap. In p3, a refdef on body line 3 inside a balanced fence passes the de-quoted pass and is refused by the quoted pass with "line 3" (`$FC/p3.log`). So the numbering holds and the quoted pass is reachable.

**Evidence:** `scripts/build-loop.sh:809-844`, `$FC/p3.log`, `$FC/suite.log`

---

## Claim 20: "(a character is never split)" / "A lead byte whose sequence the cut left short goes with its tail."

**Location:** `scripts/build-loop.sh:103,791-792,822-823`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 300-byte cut on well-formed UTF-8 for 2-, 3- and 4-byte characters. It does not establish behaviour on malformed sequences (the scrub drops only certain C1/bidi sequences; a stray continuation run is kept as is).

```perl
# scripts/build-loop.sh:820-823 (inside marker(), continues to :844 — read)
      if (length($s) > $ENV{B}) {
        $s = substr($s, 0, $ENV{B}); $cut++;
        # A lead byte whose sequence the cut left short goes with its tail.
        if ($s =~ /([\xC0-\xF7][\x80-\xBF]*)\z/) { my $b = ord($1); $s = substr($s, 0, -length($1)) if length($1) < ($b >= 0xF0 ? 4 : $b >= 0xE0 ? 3 : 2) }
```
p2 printed lines of 300, 299 and 302 bytes (prefix included). In the first two, a 3-byte € at byte 299 and a 4-byte emoji at byte 298 were dropped whole. In the third, a 4-byte emoji ending exactly at byte 300 was kept (`$FC/p2.log`). Suite test 6 covers the 2-byte case.

**Evidence:** `scripts/build-loop.sh:818-826`, `$FC/p2.log`, `$FC/suite.log`

---

## Claim 21: "state_start is its state half (all --state runs once main is found: rows 525, 690)." (commit: "state_start, which gate_start now calls first")

**Location:** `scripts/build-loop.sh:1147-1148`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers gate_start calling state_start first, and --state calling it after main_by_name. It does not establish that row 690's cost concern is discharged: --start and --prompt still run all of gate_start (Claim 24).

Quoted under Claim 3 (`:1149-1159`). The `state)` arm runs after the top-level `main_by_name || { ...; exit 1; }` (`:566`).

**Evidence:** `scripts/build-loop.sh:566`, `scripts/build-loop.sh:1147-1159`, `scripts/build-loop.sh:1527-1529`

---

## Claim 22: "caller_gate runs in --state only, so --check keeps its behaviour for a caller's variables (checkout_gate still refuses them for a self-merge brief)"

**Location:** commit ec9ba0c7 (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check not running caller_gate, and checkout_gate's unchanged variable check. It does not establish --check's behaviour change for an annotated-tag main, which is a separate default_gate change (Claim 6): "keeps its behaviour" is scoped to caller variables.

```bash
# scripts/build-loop.sh:1070-1073 (checkout_gate)
  for v in $(git rev-parse --local-env-vars); do
    # GIT_PREFIX only names a subdirectory for an alias; the script cds to the top level.
    [[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" \
      || { CHECKOUT_WHY="$v is set, so git can read another work tree, index, object store or config file"; return 1; }
```
p2: `--check` under GIT_REPLACE_REF_BASE refused only for the brief's missing branch. `--state` under the same variable refused for it (`$FC/p2.log`).

**Evidence:** `scripts/build-loop.sh:563`, `scripts/build-loop.sh:1068-1074`, `$FC/p2.log`

---

## Claim 23: "Rows 493, 494 and 517 close on the flow: the orchestrator's iteration starts with --state, and --status gains no default_gate." (also `:560` "the orchestrator's --state at the start of its iteration covers both (row 690)")

**Location:** commit ec9ba0c7 (Notes); `docs/working/plan-build-loop-handoff.md:324`; `scripts/build-loop.sh:560`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only "--status gains no default_gate", which is true (`--status` is ungated, `:561`; p2's tag-main `--status` printed ok). It does not establish that the orchestrator runs `--state` at each iteration's start. No code in this diff does that, and the skill flow lands in a later unit (U3b3/U4).

paraphrased — no quote available because the claim concerns the absence of an orchestrator call site in this branch: `rg -n -- '--state' skills/ workflows/` at ec9ba0c7 was not part of this diff's scope, and the diff adds no caller. Verifying needs the dev-cycle skill's iteration step that calls `build-loop.sh --state`.

**Evidence:** `scripts/build-loop.sh:558-561`, `docs/working/plan-build-loop-handoff.md:324`, `$FC/p2.log`

---

## Claim 24: the unit discharges its cited override-log rows (plan `:324`: "rows 247, 252, 259, 273, 276, 281, 311, 493, 494, 517, 525, 656, 666, 689, 690, 696"; commit: "caller_gate; rows 276, 281, 666", "rows 525, 690", "row 656", "row 689")

**Location:** `docs/working/plan-build-loop-handoff.md:324`; commit ec9ba0c7
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Discharged rows:
- 247, 252, 259, 273: the reused state_gate refuses origin/HEAD, replace refs and grafts.
- 276: the decimal-only count, plus git -c pairs in caller_gate.
- 656: default_gate's new check.
- 689: one shared string.
- 696: stays deferred.

Not established:
- 666: its three listed candidates all pass `--state`.
- 311: no test pins GIT_NO_REPLACE_OBJECTS.
- 281: only the GIT_REPLACE_REF_BASE half is done; its "one lib function" half is not.
- 690: only partly; --start and --prompt keep the full gate_start.
- 493, 494, 517: Claim 23.

Row 666 lists "submodule.recurse with a gitlink change, W's autocrlf/eol settings, a caller's GLOBIGNORE". In p3, `GLOBIGNORE='*'` and `-c submodule.recurse=true -c core.autocrlf=true` each gave `--state` `ok` (`$FC/p3.log`). caller_gate refuses only `--local-env-vars` variables and keys matching `STATE_KEYS_RE` or harden's six (`:519-528`). Row 311 asks for a test that fails when `GIT_NO_REPLACE_OBJECTS=1` is dropped. None of the eight new tests sets or depends on it, and `callervar` only keeps it from the caller (`:504`). Row 281's "make the guard one lib function" is unchanged: harden stays in `scripts/build-loop.sh:447`. Row 690's cost (gate_start's store_check for dispatch) is unchanged for `--start`/`--prompt` (`:1563-1564` call gate_start). The commit cites rows 666 and 690 next to code that touches a different part of each row, without saying "closes". Read as "addresses", it overstates them.

**Evidence:** `docs/reviews/override-log.md:247,252,259,273,276,281,311,493,494,517,525,656,666,689,690,696`, `scripts/build-loop.sh:504`, `scripts/build-loop.sh:517-529`, `scripts/build-loop.sh:1563-1564`, `$FC/p3.log`

---

## Claim 25: "git's update-ref refuses a branch at a non-commit: write the ref file."

**Location:** `test/scripts/build-loop-orchestrator.bats:40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's update-ref. It does not establish other git versions.

p5: `fatal: update_ref failed for ref 'refs/heads/main': ... trying to write non-commit object ... to branch 'refs/heads/main'`, rc 128 (`$FC/p5.log`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:40-44`, `$FC/p5.log`

---

## Claim 26: "Only --state reads the caller's environment: --settings is not refused for it."

**Location:** `test/scripts/build-loop-orchestrator.bats:66-68`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the assertion as written (`--settings` exits 0 under GIT_REPLACE_REF_BASE), which is true. It does not establish "Only --state": `--settings` is ungated and never reached caller_gate's position, so the test still passes if caller_gate ran in every gated mode (`--check`, `--merge`, `--start`, `--prompt`).

```bash
# test/scripts/build-loop-orchestrator.bats:66-68
    # Only --state reads the caller's environment: --settings is not refused for it.
    run --separate-stderr env GIT_REPLACE_REF_BASE=refs/x/ bash "$BL" --settings
    [ "$status" -eq 0 ] || { show; return 1; }
```
The precise version would assert it on a gated mode, such as a `--check` line that is not a caller refusal, as p2 did.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:66-68`, `scripts/build-loop.sh:561-564`

---

## Claim 27: test title "--marker skips a body FENCE_AWK refuses, raw or quoted, and an empty blocked body"

**Location:** `test/scripts/build-loop-orchestrator.bats:107`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test's cases skip. It does not establish the "or quoted" half. Every case is refused by the de-quoted pass first: an open fence, a refdef, `<div>` and an open comment. So removing the quoted pass (`"$body"` in `:833`'s list) fails no test. p3 shows a case only the quoted pass refuses: a refdef inside a balanced fence.

```bash
# test/scripts/build-loop-orchestrator.bats:108-115 (test continues to :120 — read)
    marked $'handoff: blocked\n\nplain\n```\ncode'
    ...
    tip feat/x $'handoff: blocked\n\nplain\n[a]: https://example.invalid'
    ...
    tip feat/x $'handoff: blocked\n\n<div>x</div>'
    ...
    tip feat/x $'handoff: blocked\n\nsee <!-- here'
```
**Evidence:** `test/scripts/build-loop-orchestrator.bats:107-120`, `scripts/build-loop.sh:831-841`, `$FC/p3.log`

---

## Claim 28: plan D11: "`--marker` refuses a body line that starts (after blanks, `>` and list markers) with `#`, `**Needs:**`, `**Status:**`, `**Answer` or `Q-` and a digit. It scrubs controls and bidi, caps the body at 100 lines of 300 bytes, and prefixes every line with `> `."

**Location:** `docs/working/plan-build-loop-handoff.md:92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the match between the plan's rule and the code. The code also ignores case, which the commit records as a design call. It does not establish the plan's broader D11 claim that the orchestrator is the only writer of questions.md (flow).

The code's rule is quoted under Claim 2 (`:815-816`), the caps under Claim 1 and the scrub under Claim 19. Suite tests 3-6 pass (`$FC/suite.log`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:92`, `scripts/build-loop.sh:812-826`, `$FC/suite.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`scripts/build-loop.sh:123-127`, `:526`, `test/scripts/build-loop-orchestrator.bats:47`): a caller's **GIT_CONFIG_COUNT** pair for one of harden's keys does not "win over" or "override" the hardening, because harden's later pairs win. Only `git -c` wins. Fix the help text, the refusal text and the test title. Behaviour (refusing these pairs anyway) is fine.
- **Claim 9** (`scripts/build-loop.sh:509-512`, commit ec9ba0c7): GIT_GRAFT_FILE and GIT_OBJECT_DIRECTORY do redirect files state_gate reads (via `--git-path`). The "does not read" reason holds only for GIT_REPLACE_REF_BASE, GIT_SHALLOW_FILE and GIT_ALTERNATE_OBJECT_DIRECTORIES. This is comment and commit text only.
- **Claim 13** (`scripts/build-loop.sh:545` via `:1385`): in --merge's land, a main moved to another commit before the re-check is now reported as "names an object that is not a commit". Before, the CAS reported it as "moved after the check". This is printed output; the refusal outcome is unchanged.

### Stale
- none

### Mostly Accurate
- **Claim 4b** (`scripts/build-loop.sh:119`): "First" means first among the gate's checks. `rev-parse --show-toplevel`/`cd` run before it, and a bare or missing GIT_DIR exits 1 "Not inside a git repository" with no refuse line.
- **Claim 24** (`docs/working/plan-build-loop-handoff.md:324`, commit): rows 666 (GLOBIGNORE, submodule.recurse, autocrlf all pass --state), 311 (no test pins GIT_NO_REPLACE_OBJECTS), 281's lib-function half and 690's dispatch-cost half are not discharged.
- **Claim 26** (`test/scripts/build-loop-orchestrator.bats:66`): "Only --state" is not pinned. Asserting on --settings (ungated) passes even if every gated mode ran caller_gate.
- **Claim 27** (`test/scripts/build-loop-orchestrator.bats:107`): the quoted-form FENCE_AWK pass is reachable (a refdef inside a balanced fence), but no test exercises it.

### Unverifiable
- **Claim 23** (commit ec9ba0c7; `scripts/build-loop.sh:560`): "rows 493/494/517 close on the flow" needs the orchestrator's iteration to call `--state`. That call is not in this diff (U3b3/U4).

## Goal-Alignment Note

The PR's goal: `--state`, a state-gate snapshot plus the caller's environment, and `--marker`, a quoted, rule-checked blocked or stopped body the orchestrator can paste under its own heading without any loop line being read as grammar. The code meets the goal's behavioural core, checked by execution:
- Every `--marker` rule, cap, prefix and skip is as documented. The questions readers are column-0 anchored, so a `> ` line is inert to them.
- `--state` runs the documented gates with the documented exits.
- The non-decimal count stops every mode before any git call (`--help` aside).

None of the three Incorrect verdicts is a defect in what gets refused. Claims 5 and 9 are help, comment, commit and test-title text that state the wrong mechanism. The code refuses those cases anyway, so it is stricter than the text says. Claim 13 is behavioural only in its printed reason: the new default_gate check now catches a main moved before land's re-check and calls it a non-commit. Someone reading that refusal would look for a tag, not a concurrent writer.

Two items bear on the "rows addressed" story more than on the code (Claim 24). First, row 666's three candidates are not caught by the new snapshot. Second, row 311's untested GIT_NO_REPLACE_OBJECTS is untouched. Both may be fine to re-defer, but the commit and plan currently list them beside code that does not touch them.

Test-strength gaps (Claims 26 and 27): the "only --state" and "quoted form" behaviours each pass with their mechanism removed.

Out of scope, recorded for other critics without a verdict: every gated and ungated mode hangs on a repo `include.path` that names a FIFO, because `git rev-parse --show-toplevel` and caller_gate's `git config --list` both follow includes. This predates the diff for the top-level rev-parse (`$FC/p3.log`, test 3, killed by `timeout`).
