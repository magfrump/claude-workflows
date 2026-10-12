Commit: 91659c66

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b1 (branch `feat/build-loop-u3b1`, HEAD 91659c66)
**Scope:** iteration-1 fix range `git diff ec9ba0c7..HEAD`: `scripts/build-loop.sh` (every comment, help line, refusal text, BODY_RULE and the prompt line the range added or edited), `test/scripts/build-loop-orchestrator.bats` (test titles and comments the range changed), the commit message of 8f99a919, the plan's U3b1 as-built note (`docs/working/plan-build-loop-handoff.md:324`) and the 12 override-log rows dated 2026-10-12 (`docs/reviews/override-log.md:700-711`; the rows with a checkable claim about code are verdicted, the rest are dispositions). Commits before ec9ba0c7 were read as context only. The review docs added by f306da6f and 91659c66 (the i1 reports and rubric) were read as context and not re-verdicted.
**Checked:** 2026-10-12
**Commit:** 91659c66
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 24
**Summary:** 19 verified, 2 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). No claim below matches a logged pattern. None of the three Incorrect verdicts is a fabricated symbol, API or option: `utf8::decode` exists and is used correctly, but it is laxer than the claim says (Claim 7b). The log is unchanged.

Execution provenance (every `executed` claim cites these). git 2.39.5, perl 5.36.0, bats, bash 5.2, WSL2. Every probe ran under `set -eu` in its own `mktemp -d /tmp/u3b1fc2-XXXX` directory. Each bats probe refused to run unless TMPDIR and its cwd were under that directory. The probes used the branch's own fixture (`test/lib/build-loop-fixtures.bash`, hermetic env). Mutants and the pre-fix script were `git archive` copies inside the temp dir. No file under the worktree was changed. Every temp dir was removed afterwards (`ls -d /tmp/u3b1fc2-*` finds none). No process was left behind (checked with `ps`). Scripts and captured output are in `/tmp/claude-1000/-workspace/402ec840-a464-40f5-96ae-98af0cc535cf/scratchpad/u3b1/fc2/`, abbreviated `$FC` below.
- **suites:** `TMPDIR=$(mktemp -d /tmp/u3b1fc2-XXXX) timeout 580 bats .../test/scripts/{build-loop-orchestrator,build-loop-check}.bats`, run serially from cwd `/workspace`, 2026-10-12T20:15:44Z to 20:16:53Z, both exit 0: orchestrator 8/8 ok, check 146/146 ok → `$FC/suite-build-loop-orchestrator.log`, `$FC/suite-build-loop-check.log`
- **p1:** `$FC/p1.bats`, run as `TMPDIR=$(mktemp -d /tmp/u3b1fc2-XXXX) timeout 500 bats --show-output-of-passing-tests $FC/p1.bats` from cwd `$FC`, 2026-10-12T20:18:54Z, exit 1 → `$FC/p1.log`. Of its three failures:
  - Tests 1, 2 and 7 failed through probe bugs (fixed and re-run in p2). The tests 1 and 2 shim moved the gate repository's ref; the test 7 value `x` is not a boolean.
  - Test 3's second half failed because a tree at main stops at `main_by_name` (exit 1) before default_gate. That is noted in Claim 14's scope.
  - Tests 4, 5, 6, 8 and 9 are the evidence cited from this log.
- **p2:** `timeout 580 bash $FC/p2.sh`, 2026-10-12T20:19:56Z, exit 0 → `$FC/p2.log`. It ran four things:
  - (a) p1's B4 and HARDEN tests on HEAD's script
  - (b) the same B4 tests on ec9ba0c7's script
  - (c) a mutant that runs caller_gate for `--check` too, against the orchestrator test that pins "only --state"
  - (d) `questions.sh check` on a questions file holding `--marker`'s output for a surrogate body
- **p3:** `timeout 590 bash $FC/p3.sh`, 2026-10-12T20:20:30Z, exit 0 → `$FC/p3.log`. Three mutants of HEAD's script, each run against the orchestrator suite: the quoted FENCE pass removed, the HARDEN key match removed, and the tag check removed.
- **p4:** `timeout 590 bash $FC/p4.sh`, 2026-10-12T20:21:42Z, exit 0 → `$FC/p4.log`. It ran two things:
  - (a) B4 reverted (compare with MAIN_SHA again), against the orchestrator and merge suites
  - (b) `git commit-tree` with a `\377` byte in the message

---

## Claim 1: "`caller_gate` refuses a caller pair by key, whatever its value ... Fail-closed and stated in the header ("whatever the value")"

**Location:** `docs/reviews/override-log.md:702`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers refusal of every HARDEN key, in any case, by both `git -c` and GIT_CONFIG_COUNT, with no value test, and the header wording. It does not establish what U3b3's git_harden will export; that constraint is the row's own deferral.

The loop tests the key only:
```bash
# scripts/build-loop.sh:537-544 (enclosing caller_gate() runs :531-547 — read)
  while IFS=$'\t' read -r v k; do
    [[ "$v" == command ]] || continue
    for kv in "${HARDEN[@]}"; do kv="${kv%%=*}"; [[ "$k" != "${kv,,}" ]] || k+=" "; done  # a trailing blank marks a HARDEN key
    if [[ "$k" == *" " || "$k" =~ $STATE_KEYS_RE ]]; then
      echo "refuse state ${k% }: ...
```
The header says `#             a git -c pair would win over it), whatever the value.` (`scripts/build-loop.sh:134`). In p2(a), all six keys plus two case variants were refused with value `true` through both routes, exit 2. The near-miss keys passed with `ok`: `core.commitGraphs`, `core.commitgraph.x`, `x.core.commitgraph` and `core.multipackindexx` (`$FC/p2.log`).

**Evidence:** `scripts/build-loop.sh:531-547`, `scripts/build-loop.sh:134`, `$FC/p2.log`

---

## Claim 2: "the comment now says "Not covered: anything else such an environment can do (BASH_ENV, PATH)""

**Location:** `docs/reviews/override-log.md:705`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the comment's presence and wording. It does not establish the security disposition (Won't-Fix), which is a judgement.

`# persists in its environment (a loop can write ~/.zshrc) shows there. Not` / `# covered: anything else such an environment can do (BASH_ENV, PATH), and` (`scripts/build-loop.sh:519-520`).

**Evidence:** `scripts/build-loop.sh:517-530`

---

## Claim 3: "`questions.sh` `render_index` (and `check`'s sed range) find `<!-- index:start/end -->` anywhere in a line ... (`scripts/questions.sh:340`) ... `--marker` now refuses any body line holding `<!--`, which closes the loop path"

**Location:** `docs/reviews/override-log.md:707`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the questions.sh matching sites and the `--marker` refusal of a `<!--` line, including ones assembled by the scrub. It does not establish other routes into the questions file (the orchestrator's own text), or that U4 pastes `--marker`'s output verbatim.

questions.sh, unanchored:
```bash
# scripts/questions.sh:339-341 (enclosing render_index continues to :344 — read)
    replace_with "$file" awk -v start="$INDEX_START" -v end="$INDEX_END" -v tbl="$tmp" '
        index($0, start) { print; while ((getline l < tbl) > 0) print l; skip = 1; next }
        index($0, end)   { skip = 0 }
```
The other sites are also unanchored: `sed -n "/$INDEX_START/,/$INDEX_END/p"` (`scripts/questions.sh:294`) and `grep -aqF "$INDEX_START"` (`:312`). The `--marker` rule is `index($l[$i], "<!--") >= 0` (`scripts/build-loop.sh:837`). It runs on lines that have already passed through the lib's scrub (`printf '%s\n' "$body" | scrub | ... perl`, `:830`), so it sees what is printed. p1 test 4 checked two raw commits that the scrub turns into `<!-- index:start -->`, one with a C0 byte between `<!` and `--` and one with a C1 control (`\302\200`) inside `--`. Both were refused at line 2 with the body-rule skip (`$FC/p1.log`).

**Evidence:** `scripts/questions.sh:294,312,339-341`, `scripts/build-loop.sh:830-839`, `scripts/lib/dev-cycle-read.sh:127-144`, `$FC/p1.log`

---

## Claim 4: "`--marker` reads the marker commit a fourth time (marker_kind twice, cat-file -s, then the body) ... Small objects (now capped at 64 KiB)"

**Location:** `docs/reviews/override-log.md:711`
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** The read count is right. The part that carries the verdict is the rationale "small objects (now capped at 64 KiB)": the cap bounds none of the reads it lists. This claim does not establish that the extra reads matter at loop-realistic sizes.

marker_kind reads the whole object twice, with no size test (`git cat-file commit "$1" 2>/dev/null | tr -d '\000'`, `scripts/build-loop.sh:726`; `git cat-file commit "$1" | tr -cd '\000' | wc -c`, `:732`). marker then reads the whole object into `m` before it tests the cap:
```bash
# scripts/build-loop.sh:826-827 (enclosing marker() runs :819-866 — read)
  n="$(git cat-file -s "${STATUS[sha]}")" && m="$(git cat-file commit "${STATUS[sha]}")" || { echo "skip $a: its marker could not be read"; return; }
  [[ "$n" -le "$MARKER_MAX" ]] || { echo "skip $a: its marker is $n bytes, over the $MARKER_MAX-byte cap"; return; }
```
A 16,000,209-byte marker was still read three times in full and skipped in 1.23 s wall at 144,628 KB max child RSS (p1 test 5, `$FC/p1.log`). What the cap bounds is the perl rule pass and the FENCE_AWK passes, not the object reads. Text-only: the disposition rationale is wrong, and the code's decision (skip) is right.

**Evidence:** `scripts/build-loop.sh:718-745`, `scripts/build-loop.sh:819-831`, `$FC/p1.log`

---

## Claim 5: Plan as-built note: "`--state` exits 1 (stderr only) for a non-decimal GIT_CONFIG_COUNT or a GIT_DIR naming no repository, and prints `refuse state gate:` / `refuse state objects:` as `--check` does; ... a caller pair is refused by key whatever its value ... BODY_RULE names the list markers and "in any case". Discharged only in part, re-keyed to U3b3: rows 281, 311, 666"

**Location:** `docs/working/plan-build-loop-handoff.md:324`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the listed parts of the note. Three other parts are verdicted where their code lives:
- "default_gate ... leaves a moved branch to the compare-and-swap": Claim 14
- "a marker commit over 64 KiB (unread)": Claim 15
- "one that is not valid UTF-8": Claim 7b

It does not establish the GIT_WORK_TREE case, which the help adds (Claim 9).

These parts were checked:
- **Exit 1 for GIT_DIR naming no repository.** p1 test 6: `GIT_DIR=<missing>` and `GIT_DIR=<plain dir>` both gave `status=1 out=[] err=[Not inside a git repository]` (`$FC/p1.log`). The cause is `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }` (`scripts/build-loop.sh:570`).
- **Exit 1 for a non-decimal count.** The suite checks it: `for c in 010 08 1x " 1"` (`test/scripts/build-loop-orchestrator.bats:52-55`).
- **`refuse state gate:` / `refuse state objects:`.** These come from state_start (`echo "refuse state gate: ..."`, `echo "refuse state objects: ..."`, `scripts/build-loop.sh:1171-1173`), which the state arm calls (`state) state_start; echo ok`, `:1545-1547`).
- **By key.** Checked in Claim 1.
- **BODY_RULE wording.** BODY_RULE holds `("-", "*", "+", "1." or "1)" and a blank)` and `in any case` (`:805`).
- **Rows 281, 311 and 666.** The re-key matches override row `:709`.

**Evidence:** `scripts/build-loop.sh:570,805,1168-1174,1545-1548`, `test/scripts/build-loop-orchestrator.bats:52-55`, `docs/reviews/override-log.md:709`, `$FC/p1.log`, `$FC/suite-build-loop-orchestrator.log`

---

## Claim 6: "the marker commit is over 64 KiB" (a --marker skip cause)

**Location:** `scripts/build-loop.sh:109-110`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the threshold (object size from `cat-file -s`, `-le 65536` read, above skipped) and the skip text. It does not establish whether the object is read before the skip (it is: Claim 15).

The definition is `BODY_LINES=100; BODY_BYTES=300; MARKER_MAX=65536` (`scripts/build-loop.sh:807`), and the test is `[[ "$n" -le "$MARKER_MAX" ]]` (`:827`). p1 test 5: an object of exactly 65536 bytes printed `ok ...` with a cut note, and one of 16,000,209 bytes printed `skip ...: its marker is 16000209 bytes, over the 65536-byte cap` (`$FC/p1.log`).

**Evidence:** `scripts/build-loop.sh:806-807,826-827`, `$FC/p1.log`

---

## Claim 7a: "holds "<!--" (questions.sh's index markers)" (a --marker skip cause; BODY_RULE `no line holding "<!--"`)

**Location:** `scripts/build-loop.sh:113`, `scripts/build-loop.sh:805`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every body line, including those past the 100-line cap, because the rule loop runs over all of `@l` before the cut. It also covers lines the scrub assembles. It does not establish lines past the scrub's 4096-byte cut, which are dropped before the rule and never printed.

```perl
# scripts/build-loop.sh:834-839 (enclosing marker() runs :819-866 — read)
    for my $i (0 .. $#l) {
      (my $s = $l[$i]) =~ s/^(?:[ \t>]|[-*+][ \t]|[0-9]+[.)][ \t])*//;
      # "<!--" anywhere: questions.sh finds its index markers anywhere in a line (security i1 F1).
      if ($s =~ /^(?:#|\*\*needs:\*\*|\*\*status:\*\*|\*\*answer|q-[0-9])/i || index($l[$i], "<!--") >= 0
        || !utf8::decode(my $u = $l[$i])) { print "rule ", $i + 1, "\n"; exit 0 }
    }
```
The suite case is `'see <!-- index:start --> here'` (`test/scripts/build-loop-orchestrator.bats:86`). The scrub-joined cases are in Claim 3 (`$FC/p1.log`). The p3 suite run stayed green, so every case passes on HEAD.

**Evidence:** `scripts/build-loop.sh:830-844`, `test/scripts/build-loop-orchestrator.bats:84-89`, `$FC/p1.log`

---

## Claim 7b: "or is not valid UTF-8 (the loop prompt's rule)"; BODY_RULE `valid UTF-8`; commit 8f99a919 "one that is not valid UTF-8 (B2, security F2: questions.sh check then refuses the whole file) breaks the body rule"; plan note "and one that is not valid UTF-8"

**Location:** `scripts/build-loop.sh:114`, `scripts/build-loop.sh:805` (also commit 8f99a919 and `docs/working/plan-build-loop-handoff.md:324`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what the check accepts compared with what questions.sh's `check` accepts. It does not establish whether the orchestrator would refuse these bytes elsewhere before writing them (no U4 code exists yet).

The test is `!utf8::decode(my $u = $l[$i])` (`scripts/build-loop.sh:838`). Perl's `utf8::decode` accepts Perl's lax extended UTF-8. questions.sh checks with Python's strict decoder: `python3 -c 'import sys; open(sys.argv[1],"rb").read().decode("utf-8")'` (`scripts/questions.sh:242`). Three line types pass `--marker` and then fail that check:
- a surrogate (`\355\240\200`, U+D800)
- a code point above U+10FFFF (`\364\220\200\200`)
- a 5-byte sequence (`\370\210\200\200\200`)

Each printed `ok BRIEF SHA` with the bytes quoted unchanged, and Python's strict decode of the output failed (p1 test 4, `$FC/p1.log`). End to end, a questions.md holding `> sur \355\240\200 x` makes `questions.sh check` print `✗ questions.md: not valid UTF-8 — later checks cannot be trusted`, rc 1 (p2(d), `$FC/p2.log`). That is security i1 F2's whole-file failure, still reachable. Overlongs (`\300\257`, `\340\200\257`) and stray bytes (`\377`) are refused. Behavioural: B2's refusal is incomplete.

**Evidence:** `scripts/build-loop.sh:805,838`, `scripts/questions.sh:242-243`, `$FC/p1.log`, `$FC/p2.log`

---

## Claim 8: "It checks what this script's own git reads trust, as they run hardened; it does not make a plain git command safe in the caller's shell, and it is a snapshot."

**Location:** `scripts/build-loop.sh:121-123`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the claim that the hardening is process-local and that --state writes nothing persistent. It does not establish what U4's orchestrator does with that (deferred, override row `:704`).

The hardening is exported in the script's own process only: `export "GIT_CONFIG_KEY_$c=${kv%%=*}" ...; export GIT_CONFIG_COUNT="$c"` (`scripts/build-loop.sh:458-461`) and `export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 ...` (`:468`). The state arm only prints: `state_start; echo ok` (`:1546-1547`). Nothing it does persists into the caller's shell (paraphrased — no quote available because the claim covers absence of code: no write to the caller's environment or config in the state path, `:574-585`, `:1168-1174`).

**Evidence:** `scripts/build-loop.sh:454-468`, `scripts/build-loop.sh:574-585`, `scripts/build-loop.sh:1168-1174,1545-1548`

---

## Claim 9: "Exit 1 (stderr only) for a caller's GIT_CONFIG_COUNT that is not plain decimal, or a GIT_DIR or GIT_WORK_TREE naming no repository."

**Location:** `scripts/build-loop.sh:123-125`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the non-decimal count and GIT_DIR (exit 1, "Not inside a git repository"), and GIT_WORK_TREE set to a missing path or to an existing non-repository directory. It does not establish other repo-local variables naming a non-repository (GIT_COMMON_DIR, GIT_OBJECT_DIRECTORY), which were not probed this pass.

p1 test 6 (`$FC/p1.log`) gave three outcomes:
- `GIT_DIR=<missing>` and `GIT_DIR=<plain dir>` exit 1, with `Not inside a git repository` only.
- `GIT_WORK_TREE=<missing>` exits 1, but its stderr is bash's own `build-loop.sh: line 571: cd: ...: No such file or directory`, from `cd "$ROOT"` (`scripts/build-loop.sh:571`), not the script's message.
- `GIT_WORK_TREE=<an existing plain dir>` exits **2** with `refuse state GIT_WORK_TREE: set in the caller's environment, ...` (caller_gate).

The precise version: exit 1 for GIT_DIR naming no repository, or GIT_WORK_TREE naming a missing directory (with a shell `cd` error); a GIT_WORK_TREE that names an existing directory is a `refuse state` line and exit 2. Both outcomes fail closed.

**Evidence:** `scripts/build-loop.sh:570-571`, `scripts/build-loop.sh:531-536`, `$FC/p1.log`

---

## Claim 10: "a git -c pair would win over it" (help); "git applies git -c pairs after harden's, so they win (a GIT_CONFIG_COUNT pair comes before harden's and loses, but is refused too)" (comment)

**Location:** `scripts/build-loop.sh:132-134`, `scripts/build-loop.sh:526-529`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5's precedence between GIT_CONFIG_PARAMETERS and GIT_CONFIG_COUNT, harden's index placement, and the refusal of both routes. It does not establish other git versions.

harden appends after the caller's indices: `local c="$CALLER_COUNT" kv` ... `export "GIT_CONFIG_KEY_$c=..."; c=$((c + 1))` (`scripts/build-loop.sh:456-459`). So a caller COUNT pair has a lower index and loses to harden's. p1 test 9 printed `count-only: count`, `both: param` and `both env: param`, so `git -c` (GIT_CONFIG_PARAMETERS) beats GIT_CONFIG_COUNT (`$FC/p1.log`). Both routes are refused (Claim 1).

**Evidence:** `scripts/build-loop.sh:454-462`, `$FC/p1.log`, `$FC/p2.log`

---

## Claim 11: "harden's keys are one HARDEN array that caller_gate also reads (B8)" (commit 8f99a919); `# a trailing blank marks a HARDEN key`

**Location:** `scripts/build-loop.sh:454`, `scripts/build-loop.sh:539`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers harden and caller_gate reading one array. It also covers the marker-blank technique being correct for every HARDEN key: config keys from `--name-only` never end in a blank, so no non-HARDEN key is marked, and `${k% }` restores the name. It does not establish the help text: `scripts/build-loop.sh:132-133` still lists the six keys as prose, a third copy that can drift.

harden reads it (`for kv in "${HARDEN[@]}"; do`, `:458`), and so does caller_gate (`:539`, quoted in Claim 1). p3's mutant removing `:539` turned orchestrator test 2 red (`$FC/p3.log`). Every key and case variant refused, and near-misses passed (`$FC/p2.log`). The help prose duplicates the list: `#             (core.useReplaceRefs, core.hooksPath, core.fsmonitor,` / `#             core.attributesFile, core.commitGraph, core.multiPackIndex;` (`:132-133`).

**Evidence:** `scripts/build-loop.sh:132-133,454-462,537-544`, `$FC/p2.log`, `$FC/p3.log`

---

## Claim 12: "stray_vars: the repo-local git variables set here, one per line, but the caller's (callervar) and GIT_PREFIX ... checkout_gate and caller_gate refuse them."

**Location:** `scripts/build-loop.sh:513-516`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both call sites and equivalence with the old inline loops. That includes the first-variable choice in checkout_gate and the behaviour under `set -e`. It does not establish gate_repo's separate scan (`:880`), which differs on purpose (it unsets every non-callervar, GIT_PREFIX included).

```bash
# scripts/build-loop.sh:516
stray_vars() { local v; for v in $(git rev-parse --local-env-vars); do [[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" || echo "$v"; done; }
```
caller_gate refuses each one (`for v in $(stray_vars); do echo "refuse state $v: ..."; bad=1`, `:533-535`). checkout_gate takes the first (`x="$(stray_vars)"; v="${x%%$'\n'*}"`, `:1092-1093`). The old loop returned at the first match in the same `--local-env-vars` order, so it is the same variable and reason.

Under `set -e`, a failing `git rev-parse --local-env-vars` in a `for` word list does not trip errexit, either here or in the removed inline loop. The function's last status always comes from an `||` chain that ends true, so `x="$(stray_vars)"` never exits (paraphrased — no quote available because it is bash errexit semantics across the removed and added code; the removed loops are in `git diff ec9ba0c7..HEAD -- scripts/build-loop.sh`). build-loop-check.bats ran 146/146 ok, and orchestrator test 2 ok (`$FC/suite-*.log`).

**Evidence:** `scripts/build-loop.sh:512-516,531-536,1086-1094`, `$FC/suite-build-loop-check.log`, `$FC/suite-build-loop-orchestrator.log`

---

## Claim 13: "GIT_REPLACE_REF_BASE, GIT_SHALLOW_FILE and GIT_ALTERNATE_OBJECT_DIRECTORIES name files the state gate does not read, and GIT_GRAFT_FILE or GIT_OBJECT_DIRECTORY move the ones it does."

**Location:** `scripts/build-loop.sh:522-524`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the paths state_gate reads through `--git-path` under each variable on git 2.39.5. It does not establish what else each variable changes for other git commands.

state_gate resolves `p="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)"` for `info/attributes info/grafts shallow objects/info/alternates` (`scripts/build-loop.sh:497-499`), and it lists `refs/replace/` literally (`:501`). p1 test 9 (`$FC/p1.log`) showed what each variable moves:
- `GIT_GRAFT_FILE=/g/f` moves `info/grafts` to `/g/f`.
- `GIT_OBJECT_DIRECTORY=<od>` moves `objects/info/alternates` to `<od>/info/alternates`.
- `GIT_SHALLOW_FILE=/s/f` leaves `shallow` at `.git/shallow`.

GIT_ALTERNATE_OBJECT_DIRECTORIES and GIT_REPLACE_REF_BASE are read by no state_gate line (paraphrased — no quote available because the claim covers absence of code: no reference in `:484-507`).

**Evidence:** `scripts/build-loop.sh:484-507`, `$FC/p1.log`

---

## Claim 14: "The ref itself, not MAIN_SHA: land's re-run must leave a moved branch to the compare-and-swap's own refusal." (also commit 8f99a919 and plan `:324`: "so land's re-run leaves a moved branch to the compare-and-swap")

**Location:** `scripts/build-loop.sh:559-563`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers land's re-run when main moves between the check and the post-write re-check, on both of land's paths, and the tag refusal in `--check` and `--state`. It does not establish a blob or tree at main: a tree there exits 1 at `main_by_name` (`build-loop.sh needs a default branch found by name ...`) before default_gate runs, as p1 test 3 found (`$FC/p1.log`). It also does not establish any test pinning B4: the revert survives the suites (Claim 23).

```bash
# scripts/build-loop.sh:559-563 (enclosing default_gate() runs :551-569 — read; p is reassigned at :564 for origin/HEAD, after this use)
  # resolve_main peels the ref to its commit, which land's compare-and-swap
  # would then never match (row 656). The ref itself, not MAIN_SHA: land's
  # re-run must leave a moved branch to the compare-and-swap's own refusal.
  p="$(git show-ref --verify --hash "refs/heads/$MAIN" 2>/dev/null)" && [[ "$(git cat-file -t "$p" 2>/dev/null)" == commit ]] \
    || { echo "refuse state default-branch: refs/heads/$MAIN names an object that is not a commit"; bad=1; }
```
A shim moved main in the real repository at land's `commit-tree`, before the re-run at `:1404`. Results by path:
- **No worktree on main (CAS path):** HEAD refuses `the default branch moved after the check, or could not be updated; it was left as it is`, and main stays at the writer's commit. ec9ba0c7 refused `the git state changed after the check (refuse state default-branch: refs/heads/main names an object that is not a commit)` (p2(a) and p2(b), `$FC/p2.log`).
- **Main checked out (W path):** there is no compare-and-swap. HEAD refuses `the fast-forward in the worktree with the default branch checked out failed` (from `merge --ff-only`, `:1413-1414`), which also leaves main where the writer put it.
- **Tag:** an annotated tag at main is still refused by `--check` (p1 test 3) and `--state` (suite test 1).

The precise version: "leaves a moved branch to the move's own refusal (the compare-and-swap, or W's fast-forward)".

**Evidence:** `scripts/build-loop.sh:551-569`, `scripts/build-loop.sh:1402-1420`, `$FC/p1.log`, `$FC/p2.log`, `$FC/suite-build-loop-orchestrator.log`

---

## Claim 15: "The marker commit's size cap in bytes (a larger one is skipped unread)." (also commit 8f99a919 "a marker commit over 64 KiB is skipped unread", plan `:324` "(unread)", test comment `test/scripts/build-loop-orchestrator.bats:119` "A marker commit over the cap is not read")

**Location:** `scripts/build-loop.sh:806`
**Type:** Behavioral / Performance
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether the object is read before the skip. It does not establish that the skip decision or the body output is wrong: both are right (Claim 6). The loop prompt's "is not read" (Claim 17) is a narrower, outcome-level statement.

The size and the whole object are both read before the cap test:
```bash
# scripts/build-loop.sh:826-827 (enclosing marker() runs :819-866 — read)
  n="$(git cat-file -s "${STATUS[sha]}")" && m="$(git cat-file commit "${STATUS[sha]}")" || { ... }
  [[ "$n" -le "$MARKER_MAX" ]] || { echo "skip $a: its marker is $n bytes, over the $MARKER_MAX-byte cap"; return; }
```
`status_fields` → `marker_kind` has already read the whole object twice (`:726`, `:732`). A 16 MB marker: skip in 1.23 s, 144,628 KB max RSS (p1 test 5, `$FC/p1.log`). That is well under i1's 16.7 s and 1.16 GB, so B3's measured cost is mostly closed. The memory is still proportional to the object, not capped. What is "unread" is only the perl rule and FENCE_AWK passes. Text-only (mechanism): moving the `-s` test before `m=` would make the marker() half true, but marker_kind's reads would remain.

**Evidence:** `scripts/build-loop.sh:718-745,806-831`, `test/scripts/build-loop-orchestrator.bats:119-121`, `$FC/p1.log`

---

## Claim 16: "# "<!--" anywhere: questions.sh finds its index markers anywhere in a line (security i1 F1)."

**Location:** `scripts/build-loop.sh:836`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers questions.sh's three unanchored marker matches. It does not establish that `<!--` is the only HTML-comment-shaped text questions.sh treats specially (only the index markers were checked).

These are `index($0, start)` (`scripts/questions.sh:340`), `sed -n "/$INDEX_START/,/$INDEX_END/p"` (`:294`) and `grep -aqF "$INDEX_START"` (`:312`). INDEX_START is defined as `'<!-- index:start -->'` (`:140`).

**Evidence:** `scripts/questions.sh:140-141,294,312,339-341`

---

## Claim 17: "at most $BODY_LINES lines of $BODY_BYTES bytes (longer is cut; a commit over $MARKER_MAX bytes is not read): $BODY_RULE"

**Location:** `scripts/build-loop.sh:1534`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the narrow, loop-facing reading: a longer body is cut with a note, and an over-cap commit is skipped, so its body never reaches the orchestrator. It does not establish that the script does not read the object internally (Claim 15). It does not establish that `$BODY_RULE` is fully enforced either (Claim 7b).

The cut and note are in `marker()` (`:841-850`), the skip at `:827`. Both were exercised: a 65536-byte object printed `> (build-loop.sh --marker cut this body: 1 of 1 lines shown, 1 cut at 300 bytes)`, and the 16 MB one was skipped (p1 test 5, `$FC/p1.log`).

**Evidence:** `scripts/build-loop.sh:827,841-850,1534`, `$FC/p1.log`

---

## Claim 18: `RULE='no line that starts, ... in any case; no line holding "<!--"; valid UTF-8'` (the test's copy of BODY_RULE)

**Location:** `test/scripts/build-loop-orchestrator.bats:21`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers byte-equality of the test's RULE with BODY_RULE, as used by the exact-match skip assertions. It does not establish that BODY_RULE's content is accurate (Claim 7b).

The two strings are textually identical (`test/...:21` and `scripts/build-loop.sh:805`, both quoted in the diff). Test 4 asserts `marker_is "$W 2"` with `$RULE` inside `W` and passes (`$FC/suite-build-loop-orchestrator.log`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:21,82-83`, `scripts/build-loop.sh:805`, `$FC/suite-build-loop-orchestrator.log`

---

## Claim 19: `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=caller state_is ok` (the compressed "a plain caller pair passes" case)

**Location:** `test/scripts/build-loop-orchestrator.bats:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether prefix assignments on a bash function call reach the `bash "$BL"` child that bats' `run` starts, so the case tests what the old `env ...` form tested. It does not establish behaviour under `bash --posix`.

p1 test 8 used the same prefix-assignment form on a `state_is` that runs `run --separate-stderr bash "$BL" --state` (`$FC/p1.log`):
- `GIT_CONFIG_KEY_0=core.hooksPath` gave status 2 with `refuse state core.hookspath: ...`, so the variables reached the child.
- `user.name` gave status 0, `ok`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:15,51`, `$FC/p1.log`

---

## Claim 20: "# Only --state reads the caller's environment: neither --settings nor the gated --check refuses for it."

**Location:** `test/scripts/build-loop-orchestrator.bats:56-60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--settings` and `--check`, and that the test would fail if caller_gate also ran for `--check`. It does not establish the other gated modes (`--merge`, `--start`, `--prompt`); the code's guard covers them (`if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi`, `scripts/build-loop.sh:581`).

The suite passes. p2(c)'s mutant (`if [[ "$MODE" == state || "$MODE" == check ]]; then caller_gate`) turned the test red with `refuse state GIT_REPLACE_REF_BASE: ...` and `refuse state merge.x.driver: ...`, exit 2 (`$FC/p2.log`).

**Evidence:** `scripts/build-loop.sh:579-582`, `test/scripts/build-loop-orchestrator.bats:56-60`, `$FC/p2.log`

---

## Claim 21: "# A byte that is not UTF-8 (git commit-tree re-encodes a message, so the commit is written raw)."

**Location:** `test/scripts/build-loop-orchestrator.bats:90`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5's commit-tree on a `\377` byte under default i18n settings. It does not establish behaviour with `i18n.commitEncoding` set.

p4(b): `printf "x\nbad \377 byte\n" | git commit-tree ...` warned `Warning: commit message did not conform to UTF-8.`, and the stored message holds `b a d 303 277 b y t e` (the Latin-1 byte re-encoded as U+00FF) (`$FC/p4.log`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:90-93`, `$FC/p4.log`

---

## Claim 22: "# Inside a balanced fence the raw pass reads nothing; quoted, the line is a link reference definition."

**Location:** `test/scripts/build-loop-orchestrator.bats:116`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that this case is refused by the quoted pass only. It does not establish which other inputs only one pass refuses.

The passes are `for m in "$(printf '%s\n' "$body" | sed -E 's/^> ?//')" "$body"; do` (`scripts/build-loop.sh:855`). p3's mutant keeping only the raw pass turned orchestrator test 5 red, and every other test stayed green (`$FC/p3.log`). So this case is refused by the quoted pass alone, as the comment says.

**Evidence:** `scripts/build-loop.sh:853-864`, `test/scripts/build-loop-orchestrator.bats:116-118`, `$FC/p3.log`

---

## Claim 23: "Mutation-checked: each of the six new rules removed turns its test red." (commit 8f99a919)

**Location:** commit 8f99a919 (message body; rubric `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b1.md:60` names the six: the `<!--` rule, the UTF-8 rule, the size cap, the quoted FENCE pass, the HARDEN key match, the tag check)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Re-executed for three of the six: the quoted pass, the HARDEN match and the tag check, each red (p3). The other three are covered by dedicated exact-match cases (`:86`, `:90-93`, `:119-121`) and were not re-mutated. It does not establish that B4's behavioural change is pinned. With default_gate reverted to `== "$MAIN_SHA"`, the orchestrator suite (8/8) and the merge suite (12/12) both stay green (p4(a), `$FC/p4.log`), because the merge suite's moved-main case moves main at `update-ref`, after the re-run (`test/scripts/build-loop-merge.bats:57-58`).

p3 recorded which tests each mutant broke (`$FC/p3.log`):
- quoted pass removed: test 5
- HARDEN match removed: test 2
- tag check removed: test 1

**Evidence:** `$FC/p3.log`, `$FC/p4.log`, `test/scripts/build-loop-orchestrator.bats:84-121`, `test/scripts/build-loop-merge.bats:54-58`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`docs/reviews/override-log.md:711`): The "now capped at 64 KiB" rationale does not hold. marker_kind reads the commit twice and marker() reads it once more, all before the cap test, so no read is bounded. Text-only.
- **Claim 7b** (`scripts/build-loop.sh:114`, `:805`, also commit 8f99a919 and the plan note): `utf8::decode` is lax. Surrogates, code points above U+10FFFF and 5-byte sequences pass `--marker`, and `questions.sh check` then refuses the whole file. **Behavioural.** B2 is still reachable.
- **Claim 15** (`scripts/build-loop.sh:806`, also commit 8f99a919, plan `:324` and `test/...:119`): "skipped unread" is wrong. `m="$(git cat-file commit ...)"` runs before the `-le $MARKER_MAX` test, after marker_kind's two full reads. Text-only (mechanism); the skip itself is right.

### Stale
None.

### Mostly Accurate
- **Claim 9** (`scripts/build-loop.sh:123-125`): GIT_WORK_TREE naming an existing non-repository directory exits 2 with a `refuse state` line. A missing one exits 1, but its stderr is bash's `cd` error.
- **Claim 14** (`scripts/build-loop.sh:559-561`, also the commit and the plan note): on the W path a moved main is refused by the fast-forward, not a compare-and-swap. No test pins B4: the revert survives both suites.

### Unverifiable
None.

## Prior Must Address (B1-B8)

- **B1** (`<!--` lines). Resolved: refused anywhere in a line, including lines the scrub assembles (Claims 3, 7a). The questions.sh half is deferred by row `:707`.
- **B2** (non-UTF-8 lines). **Partly open.** Lone and stray bytes and overlongs are refused, but surrogates, code points above U+10FFFF and 5-byte sequences pass and still break `questions.sh check` (Claim 7b).
- **B3** (memory before the cut). Resolved in effect: 16 MB now takes 1.23 s and 145 MB RSS, against 16.7 s and 1.16 GB. Memory still scales with the object, and "unread" is wrong (Claims 4, 15).
- **B4** (moved main reported as a non-commit). Resolved in behaviour (Claim 14, executed against the pre-fix script). The comment overstates the W path, and no test pins the change (Claim 23).
- **B5** (--state help claimed to protect bare git). Resolved (Claim 8).
- **B6** (exit-1 cases undocumented). Resolved for the count and GIT_DIR. The GIT_WORK_TREE wording is imprecise (Claim 9).
- **B7** (plan bullets stale). Resolved by the as-built note (Claim 5). The note repeats Claim 15's "unread" and Claim 7b's "valid UTF-8".
- **B8** (three copies of harden's keys). Resolved for code: one HARDEN array (Claim 11). The help prose still lists the six keys.

## Goal-Alignment Note

The PR's goal: `--state` (the state gate plus a snapshot of the caller's git environment) and `--marker` (a quoted body that cannot steer the questions files' readers). The fix batch meets most of its claims, checked by execution:
- the `<!--` refusal, including scrub-assembled forms
- the size cap's decision
- the HARDEN key match in any case and by either route
- `stray_vars`' equivalence in both gates
- `--check` ignoring the caller's environment, with its test now pinning that
- land's re-run leaving a moved main to the move's own refusal

One behavioural gap bears directly on the goal: the UTF-8 rule (Claim 7b). The body rule exists so that `--marker`'s output can sit in the questions file without breaking its readers. A loop can still write a raw marker commit with a surrogate, and that fails `questions.sh check` for the whole file, which is i1's F2 consequence. Python's strict check is the reference reader, so the fix needs a matching strict check, not a lax decode.

The other two Incorrect verdicts are mechanism text ("unread", "capped"). The code's decisions there are right. One test gap remains: B4's behaviour change has no test, so a revert would pass both suites.
