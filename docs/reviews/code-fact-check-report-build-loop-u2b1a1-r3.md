Commit: ae08688c

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b1a1 (feat/build-loop-u2b1a1)
**Scope:** `git diff main...HEAD` at ae08688c (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md, docs/working/questions.md) plus commit ae08688c's message; replicate r3 of 3
**Checked:** 2026-10-08
**Total claims checked:** 24
**Summary:** 23 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. Nearest pattern: suite-count claims in commit messages ("All 85 tests ... but the suites hold 97", "mode1-equiv 33 ... holds 25"). Claim 17 below is that kind of claim, and it checks out this time.

Execution environment for every `executed` claim: git 2.39.5, bats at /usr/bin/bats, GIT_CONFIG_GLOBAL=/dev/null in the probes. Probes ran in `mktemp -d /tmp/fcu2b1a1-r3-repo*-XXXX` directories that each script created and removed itself. Captured output is in `/tmp/fcu2b1a1-r3-logs/`. The probe scripts are `/tmp/fcu2b1a1-r3-probe/probe{,2,3}.sh`. No background processes were started.

---

## Claim 1: "anybrief() { isbrief "$1" || isclosed "$1"; }" and its three call sites (row 323)

**Location:** `scripts/lib/dev-cycle-read.sh:201`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that anybrief is the old two-predicate disjunction and that it has exactly three callers (writable, check_brief, open_shared), the same three sites row 323 listed, with build-loop.sh's copy moved into the lib. It does not establish anything about the predicates isbrief and isclosed themselves, which are unchanged.
**Legibility-target:** for-orchestrator-synthesis

Every `isbrief X || isclosed X` site now calls anybrief:

```
scripts/lib/dev-cycle-read.sh:204      || "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]] || anybrief "$1"
scripts/lib/dev-cycle-read.sh:392    if ! anybrief "$a"; then
scripts/lib/dev-cycle-read.sh:471      if ! anybrief "$f" || ! brief_fields "$f"; then continue; fi
```

Row 323 (`docs/reviews/override-log.md:323`) reads: "Three call sites write `isbrief X \|\| isclosed X` themselves (lib writable, check_brief; build-loop.sh shared_branches)". A grep for `anybrief`, `isbrief` and `isclosed` across scripts/ turns up no other open-coded disjunction (paraphrased — no quote available because the claim covers absence of code: no matching grep results).

**Evidence:** `scripts/lib/dev-cycle-read.sh:201`, `:204`, `:392`, `:471`; `docs/reviews/override-log.md:323`

---

## Claim 2: "--no-textconv: -G greps the diff, and a repo-local textconv driver would run."

**Location:** `scripts/lib/dev-cycle-read.sh:421-422`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_brief's one `git log -G` call. Without the flag, a repo-local `diff.x.textconv` driver plus a checkout `*.md diff=x` runs; with the flag, it does not. It does not establish that no other `--status` git call can run a repo-local command (the state gate that would cover this is U2b1a2's).
**Legibility-target:** for-author

```
# scripts/lib/dev-cycle-read.sh:421-422
  # --no-textconv: -G greps the diff, and a repo-local textconv driver would run.
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s --no-textconv -G'^Status: ' "$MAIN_SHA" -- "$a")"
```

(excerpt ends :422; enclosing check_brief() continues to :424, read: `[[ -n "$c" ]] || c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"` and `echo "ok $a ${st#Status: } $c"`. The fallback `git log` has no `-G`, so it computes no diff.)

Probe result: `without: ran=yes` and then `with: ran=no`, with the same commit id printed both times. The suite test at build-loop-check.bats:1261 passes at HEAD and fails ("textconv ran") with main's scripts.

Command: `timeout 120 bash /tmp/fcu2b1a1-r3-probe/probe.sh`, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:02Z. Mutant run: `bats -f 'U2b1a1' test/scripts/build-loop-check.bats` on a copy of the tree with main's scripts/, exit 1, 2026-10-08T19:02:08Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:417-424`; /tmp/fcu2b1a1-r3-logs/probe.log; /tmp/fcu2b1a1-r3-logs/mutant-main-scripts.tap

---

## Claim 3: --no-textconv does not change which commit -G finds for an ordinary brief (brief item 4; implied by the commit's "so a repo-local textconv driver never runs")

**Location:** `scripts/lib/dev-cycle-read.sh:422`
**Type:** Invariant
**Verification mode:** executed
**Verdict:** Verified
**Confidence:** High
**Scope:** Covers ordinary text briefs with no diff driver: the found commit is the same with and without the flag, for all 3 briefs on this repo's main and for the probe's driver-attributed brief. It does not establish equality for a brief that git classifies as binary or that has a textconv driver set, where changing the output is the point of the flag.
**Legibility-target:** for-orchestrator-synthesis

The command ran both ways for every path under `docs/working/briefs/` at main and printed `briefs=3 differing=0`. In the probe, both forms printed `90a6ac089de8ddfe52d5e841b926e7190c32a746`.

Paraphrased — no quote available because this is git's documented behaviour, not repo code: `--no-textconv` only takes effect when a textconv driver is configured for the path, so a path without one is diffed the same way.

Command: a `for f in $(git ls-tree -r --name-only $M -- docs/working/briefs/)` loop comparing the two `git log` forms, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:16Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:422`; /tmp/fcu2b1a1-r3-logs/textconv-compare.log; /tmp/fcu2b1a1-r3-logs/probe.log

---

## Claim 4: "and so is a branch whose count or date cannot be read (a broken log.* config, say: row 307)" plus check_branch's new regex checks

**Location:** `scripts/lib/dev-cycle-read.sh:438-439`, `:449-451`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip when `git log --format=%cs` fails under `log.date bogus`, the `ok` line once the config is fixed, and the digit and date regex guards. It does not establish which other configs break the count read: rev-list was not broken by any log.* key tried (it printed `1`, exit 0).
**Legibility-target:** for-author

```
# scripts/lib/dev-cycle-read.sh:448-451
    if [[ -z "$sha" ]]; then echo "absent $a"
    elif n="$(git rev-list --count "$MAIN_SHA..$sha" 2>/dev/null)" && [[ "$n" =~ ^$DIGIT+$ ]] \
      && d="$(git log -1 --format=%cs "$sha" 2>/dev/null)" && [[ "$d" =~ ^$DIGIT{4}-$DIGIT{2}-$DIGIT{2}$ ]]; then echo "ok $a $sha $n $d"
    else echo "skip $a: its commit count or date could not be read"; fi
```

(excerpt ends :451; enclosing check_branch() continues to :453, read.) `DIGIT='[0123456789]'` (`:198`), so the guards are `^[0123456789]+$` and `^[0-9]{4}-[0-9]{2}-[0-9]{2}$`. A failed read and a malformed value both reach the `skip` arm.

Probe output: under `log.date bogus`, `dev-cycle.sh --check-branch feat/x` prints `skip feat/x: its commit count or date could not be read`. After `git config --unset log.date`, it prints `ok feat/x 0126c045… 1 2026-10-08`. Row 307 asked for "refuse on failure" in --check; here the lib skips and --status passes the skip on. That outcome is settled under row 307, which the brief lists as routed to U2b.

Command: `timeout 120 bash /tmp/fcu2b1a1-r3-probe/probe.sh`, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:02Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:427-453`; /tmp/fcu2b1a1-r3-logs/probe.log

---

## Claim 5: "open_shared computes it once per process, from MAIN_SHA."

**Location:** `scripts/lib/dev-cycle-read.sh:455`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guard and the only call site (status_line, run in the main shell for --status). It does not establish once-per-process for a future caller that runs open_shared first inside a `$(...)`; the comment's "Call it in the caller's shell" (Claim 9) covers that case.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:465
  [[ -z "$OPEN_SHARED" ]] || return 0
# scripts/lib/dev-cycle-read.sh:467
  list="$(git grep --no-color -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?
# scripts/build-loop.sh:351
    for a in "${ARGS[@]}"; do status_line "$a"; done
```

Both the `error` result and the newline-delimited list are non-empty, so either one stops recomputation.

**Evidence:** `scripts/lib/dev-cycle-read.sh:461-477`; `scripts/build-loop.sh:309-311`, `:351`

---

## Claim 6: "brief_fields then reads only those, so every brief is still read through main_entry"

**Location:** `scripts/lib/dev-cycle-read.sh:457-458`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every listed path goes through anybrief and brief_fields, and that brief_fields reads a blob only after main_entry answers `blob`. It does not establish that the git grep list is complete; the comment calls it a superset and "fences are not modelled".
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:471
    if ! anybrief "$f" || ! brief_fields "$f"; then continue; fi
# scripts/lib/dev-cycle-read.sh:360
  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:355-385`, `:471`

---

## Claim 7: "Exit 1 is "none"; any exit above 1, a corrupt object's included, fails closed."

**Location:** `scripts/lib/dev-cycle-read.sh:458-459`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git grep's exit codes on git 2.39.5: 1 when nothing matches, 128 when a loose object is corrupt. It also covers the code mapping any exit above 1 to OPEN_SHARED=error, and status_line skipping every open brief on error. It does not establish exit codes for packed-object corruption.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/lib/dev-cycle-read.sh:467-468
  list="$(git grep --no-color -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?
  if [[ "$rc" -gt 1 ]]; then OPEN_SHARED=error; return; fi
# scripts/build-loop.sh:326
  if [[ "$st" == open && "$OPEN_SHARED" == error ]]; then echo "skip $a: the open briefs on the default branch could not be listed"; return; fi
```

Probe output: `none exit=1` and `corrupt exit=128` ("fatal: loose object … is corrupt").

Command: `timeout 120 bash /tmp/fcu2b1a1-r3-probe/probe.sh`, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:02Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:467-468`; `scripts/build-loop.sh:326`; /tmp/fcu2b1a1-r3-logs/probe.log

---

## Claim 8: "A brief whose object is missing (git grep warns, exits 0 or 1) is not counted (row 293)."

**Location:** `scripts/lib/dev-cycle-read.sh:459-460`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a missing loose blob: git grep prints `error: … unable to read …` and exits 1, so the file is not listed and not counted. It does not establish the exit-0 case, where another brief matches; static reading shows that case also lists only readable matches. Row 293 is the Won't-Fix row for this behaviour.
**Legibility-target:** for-orchestrator-synthesis

Probe output: `error: 'main:docs/working/briefs/2026-10-01-x.md': unable to read 07a167f1…` followed by `missing exit=1`. Row 293 reads "An unreadable open brief is not counted for F31 (iteration 2 C21) | 🟢 Consider | Won't-Fix" (`docs/reviews/override-log.md:293`).

Command: `timeout 120 bash /tmp/fcu2b1a1-r3-probe/probe.sh`, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:02Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:459-460`; `docs/reviews/override-log.md:293`; /tmp/fcu2b1a1-r3-logs/probe.log

---

## Claim 9: "Call it in the caller's shell."

**Location:** `scripts/lib/dev-cycle-read.sh:460`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that open_shared's result is the global OPEN_SHARED, which a subshell call would discard, and that the one caller follows the rule. It does not cover U2b1a2's caller.
**Legibility-target:** for-author

```
# scripts/lib/dev-cycle-read.sh:461, :475
OPEN_SHARED=""
  OPEN_SHARED=$'\n'
# scripts/build-loop.sh:311 (inside status_line, itself called at :351 outside any $(...))
  open_shared
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:461-477`; `scripts/build-loop.sh:309-311`, `:351`

---

## Claim 10: open_shared is main's shared_branches moved into the lib, with --status behaviour unchanged (commit body: "open_shared/OPEN_SHARED, build-loop.sh's shared_branches moved in (row 298)")

**Location:** `scripts/lib/dev-cycle-read.sh:462-477` vs `git show main:scripts/build-loop.sh` (shared_branches)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line-by-line comparison and the unchanged F31 tests in build-loop-read.bats, which pass at HEAD. It does not establish identical behaviour for a lib caller that has not checked main_by_name; for such a caller the new guard is a real change, toward fail-closed.
**Legibility-target:** for-orchestrator-synthesis

The body differs from main's in four ways:
- the once-only guard moved inside the function. Main had `[[ -n "$SHARED_BRANCHES" ]] || shared_branches` in status_line (diff.patch:118); HEAD has `[[ -z "$OPEN_SHARED" ]] || return 0` (`:465`), which is equivalent.
- `local -A n=()` was renamed to `count`.
- `isbrief "$f" || isclosed "$f"` became `anybrief "$f"`.
- `if ! main_by_name; then OPEN_SHARED=error; return; fi` (`:466`) is new.

The new guard cannot fire in build-loop.sh, because the script exits first:

```
# scripts/build-loop.sh:120
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }
```

The git grep line, the loop, the Status/Branch match and the list assembly are byte-identical to main's (diff.patch:105-114 vs :223-232). build-loop-read.bats is untouched by the diff and passes 19/19 at HEAD, including its F31 twin-branch and "could not be listed" tests (`test/scripts/build-loop-read.bats:388-400`, `:484`).

Command: `TMPDIR=$(mktemp -d /tmp/fcu2b1a1-r3-XXXX) timeout 900 bats test/scripts/build-loop-read.bats`, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08 (run window 18:59:00Z to 19:00:26Z).

**Evidence:** `scripts/lib/dev-cycle-read.sh:452-477`; `scripts/build-loop.sh:120`, `:309-311`, `:326-327`; /tmp/fcu2b1a1-r3-logs/build-loop-read.tap

---

## Claim 11: --status help: "its branch name is refused (as --check-branch) or its commit count or date cannot be read"

**Location:** `scripts/build-loop.sh:68-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --status skip line when check_branch skips for an unreadable count or date. It does not establish anything about the rest of the help paragraph, which this diff does not change.
**Legibility-target:** for-author

```
# scripts/build-loop.sh:68-69
#                 malformed, its branch name is refused (as --check-branch)
#                 or its commit count or date cannot be read, on a branch ahead of main the tip's subject (its message's
# scripts/build-loop.sh:333-337 (status_line)
  out="$(check_branch "$br")"
  case "$out" in
    "absent "*) echo "ok $a $st $pol $br absent - - $disp"; return ;;
    "ok "*) read -r _ _ sha ahead date <<<"$out" ;;
    *) echo "skip $a: Branch: ${out#*: }"; return ;;
```

The test at build-loop-check.bats:1254 (`skip $B: Branch: its commit count or date could not be read`) passes at HEAD.

**Evidence:** `scripts/build-loop.sh:64-75`, `:309-345`; /tmp/fcu2b1a1-r3-logs/build-loop-check.tap

---

## Claim 12: marker_kind: "the message is the raw object's text after its first empty line (no header holds one)"

**Location:** `scripts/build-loop.sh:283-284`, `:291`
**Type:** Behavioral
**Verification mode:** executed
**Verdict:** Verified
**Confidence:** High
**Scope:** Covers headers containing a multi-line value. A gpgsig header whose continuation includes a whitespace-only line (` `) and an embedded `handoff: blocked` line reads `ready` from the real message, and a commit with an empty message reads `working`. It does not establish behaviour on objects git itself would reject with fsck.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/build-loop.sh:291-292
  if [[ "$msg" == *$'\n\n'* ]]; then msg="${msg#*$'\n\n'}"; else msg=""; fi
  read -ra p <<<"$p"; subj="${msg%%$'\n'*}"
```

Probe output: the multi-line-header commit `55f7be84…` reads `ready`, and the empty-message commit `03a9493b…` reads `working`.

Command: `timeout 120 bash /tmp/fcu2b1a1-r3-probe/probe.sh`, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:02Z.

**Evidence:** `scripts/build-loop.sh:281-308`; /tmp/fcu2b1a1-r3-logs/probe.log

---

## Claim 13: "read with cat-file so no log.* or i18n.* config can change or break it"

**Location:** `scripts/build-loop.sh:285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers log.date=bogus, i18n.logOutputEncoding=bogus-enc, i18n.commitEncoding=bogus2 and log.showSignature=true with gpg.program=false all set at once: marker_kind's answers are unchanged, and the same config makes `git log` exit 128. It does not establish immunity to configs outside log.* and i18n.* (replace refs, for example; build-loop.sh exports GIT_NO_REPLACE_OBJECTS).
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/build-loop.sh:288
  if ! p="$(git rev-list --parents -n 1 "$1" 2>/dev/null)" || ! msg="$(git cat-file commit "$1" 2>/dev/null | tr -d '\000')"; then
```

Probe output: before and after the config, the three commits answer `bad it changes files`, `bad it holds a NUL byte` and `ready`. Under the config, `git log -1 --format=%B` and `--format=%cs` both print `fatal: unknown date format bogus` and exit 128, while `rev-list --parents` exits 0.

Command: `timeout 120 bash /tmp/fcu2b1a1-r3-probe/probe.sh`, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:02Z.

**Evidence:** `scripts/build-loop.sh:281-292`; /tmp/fcu2b1a1-r3-logs/probe.log

---

## Claim 14: "NULs are dropped here (bash would warn on stderr); the NUL check below reads the raw object."

**Location:** `scripts/build-loop.sh:287`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claims that the NUL-bearing marker commit produces no "ignored null byte" warning on stderr and still answers `bad it holds a NUL byte`, and that the NUL check re-reads the object unfiltered. It does not establish NUL detection for a non-`handoff:` subject; the check sits after the `working` return, and this diff does not change that.
**Legibility-target:** for-author

```
# scripts/build-loop.sh:293-294
  [[ "$subj" == handoff:* ]] || { echo working; return; }
  if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"; return; fi
```

Probe output: `[0e91443a…] -> bad it holds a NUL byte`. Stderr held only the sandbox's setlocale warning.

Command: `timeout 120 bash /tmp/fcu2b1a1-r3-probe/probe.sh`, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:02Z.

**Evidence:** `scripts/build-loop.sh:287-294`; /tmp/fcu2b1a1-r3-logs/probe.log

---

## Claim 15: "A failed read answers bad, never working (row 307)" (commit: "answers bad on a failed read"; pipefail)

**Location:** `scripts/build-loop.sh:285-286`, `:288-290`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a missing commit (rev-list fails) and a cat-file failure on its own, simulated with a `git` shim function that fails cat-file after printing a plausible `handoff: ready` object. Both answer `bad its commit could not be read` under the script's `set -euo pipefail` (`scripts/build-loop.sh:85`). Without pipefail, the cat-file case would answer `ready`. The verdict does not establish the status_line consequence beyond its `bad\ *` arm, which maps to a skip (`:340`).
**Legibility-target:** for-orchestrator-synthesis

Probe 3 output: `cat-file fails, pipefail: bad its commit could not be read`, then `cat-file fails, no pipefail: ready`. Probe 1 output: `[0123…6789] -> bad its commit could not be read`.

Commands:
- `timeout 60 bash /tmp/fcu2b1a1-r3-probe/probe3.sh`, exit 0, 2026-10-08T19:01:25Z
- `timeout 120 bash /tmp/fcu2b1a1-r3-probe/probe.sh`, exit 0, 2026-10-08T19:01:02Z

Both ran in cwd /workspace/.claude/wt-build-loop-u2b1a1.

**Evidence:** `scripts/build-loop.sh:85`, `:288-290`, `:338-343`; /tmp/fcu2b1a1-r3-logs/probe3.log; /tmp/fcu2b1a1-r3-logs/probe.log

---

## Claim 16: dev-cycle.sh help: "or a branch whose count or date cannot be read (a broken log.* config)"

**Location:** `scripts/dev-cycle.sh:47-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check-branch` printing `skip <name>: <reason>` under `log.date bogus` (exit 0). It does not establish that log.* is the only cause; the help gives log.* as its example.
**Legibility-target:** for-author

```
# scripts/dev-cycle.sh:47-48
#             (HEAD, refs/...) or the default branch, or a branch whose count
#             or date cannot be read (a broken log.* config). The commit is
```

Probe output: `skip feat/x: its commit count or date could not be read`, exit=0.

Command: `timeout 120 bash /tmp/fcu2b1a1-r3-probe/probe.sh`, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:01:02Z.

**Evidence:** `scripts/dev-cycle.sh:43-49`, `:200`; /tmp/fcu2b1a1-r3-logs/probe.log

---

## Claim 17: "show: what a failed test prints, the history included (the plan's test spec; row 223)."

**Location:** `test/scripts/build-loop-check.bats:1249-1250`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers show's four commands and row 223's ask. It does not establish that the history prints when a log.* config is broken: in the one new test that sets `log.date bogus`, show's `git log` fails.
**Legibility-target:** for-author

```
# test/scripts/build-loop-check.bats:1250
show() { echo "status $status"; echo "$output"; echo "$stderr"; git log --oneline --graph --all; }
```

Row 223 asks that tests print `git log --oneline --graph --all` on failure, and show does that. In the row-307 test (`:1254-1259`), though, `log.date bogus` is still set when show runs, so the history line fails. When that test ran against main's scripts, the failure output held `fatal: unknown date format bogus` where the graph should be, and the assertion line reported `failed with status 128`. A more precise wording would say the history is included "unless the test's own config breaks git log", or show could run `git -c log.date=default log …`. This is not a code finding.

Command: `bats -f 'U2b1a1' test/scripts/build-loop-check.bats` in a copy of HEAD's tree with main's scripts/ (`git archive HEAD scripts test` then `git archive main scripts`), exit 1, 2026-10-08T19:02:08Z.

**Evidence:** `test/scripts/build-loop-check.bats:1250`, `:1254-1259`; `docs/reviews/override-log.md:223`; /tmp/fcu2b1a1-r3-logs/mutant-main-scripts.tap

---

## Claim 18: "gated BRANCH: brief x, open and naming BRANCH (B is its path), and BRANCH with one commit."

**Location:** `test/scripts/build-loop-check.bats:1251-1252`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers gated's composition of the fixture helpers. It does not cover what the tests then add on top, such as `tip`.
**Legibility-target:** for-author

```
# test/scripts/build-loop-check.bats:1252
gated() { brief x "Status: open" "Branch: $1"; work "$1"; }
# test/lib/build-loop-fixtures.bash:51
    B="docs/working/briefs/2026-10-01-$s.md"
# test/lib/build-loop-fixtures.bash:56-59
# work BRANCH: BRANCH from main with one commit that changes a file.
work() {
    git branch -q "$1" main
    git checkout -q "$1" && echo "$1" > "work-${1//\//-}.txt" && commit_all "work on $1" && git checkout -q main
```

**Evidence:** `test/scripts/build-loop-check.bats:1252`; `test/lib/build-loop-fixtures.bash:49-60`

---

## Claim 19: Test title "under a broken log.* config --status skips the branch instead of reading LOOP or DATE wrong (row 307, U2b1a1)"

**Location:** `test/scripts/build-loop-check.bats:1254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test passing at HEAD, and failing against main's scripts with exactly the misreading the title names (LOOP `working` for a `handoff: ready` tip, DATE empty). It does not establish coverage of the marker_kind cat-file path on its own, because the check_branch skip fires first in this test.
**Legibility-target:** for-orchestrator-synthesis

With main's scripts the test fails, and its output is `ok docs/working/briefs/2026-10-01-x.md open review feat/x working edcd001e…  0`: the tip is "handoff: ready", LOOP reads `working`, and DATE is empty. At HEAD it passes (81/81).

Commands:
- main's scripts: `bats -f 'U2b1a1' …`, exit 1, 2026-10-08T19:02:08Z
- HEAD: the full suite, exit 0, 2026-10-08 (run window 18:59:00Z to 19:00:26Z)

Both ran in cwd /workspace/.claude/wt-build-loop-u2b1a1 or its tree copy.

**Evidence:** `test/scripts/build-loop-check.bats:1254-1259`; /tmp/fcu2b1a1-r3-logs/mutant-main-scripts.tap; /tmp/fcu2b1a1-r3-logs/build-loop-check.tap

---

## Claim 20: Test title "--status runs no repo-local textconv driver while it finds a brief's Status commit (U2b1a1)"

**Location:** `test/scripts/build-loop-check.bats:1261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test passing at HEAD, and failing ("textconv ran") with main's scripts. It does not establish that no other --status git call honours a textconv driver.
**Legibility-target:** for-orchestrator-synthesis

```
# test/scripts/build-loop-check.bats:1263-1267
    git config diff.x.textconv "touch $BATS_TEST_TMPDIR/textconv-ran; cat"
    printf '*.md diff=x\n' > .gitattributes
    run --separate-stderr bash "$BL" --status "$B"
    [ "$status" -eq 0 ] && [[ "$output" == "ok $B open "* ]] || { show; return 1; }
    [ ! -e "$BATS_TEST_TMPDIR/textconv-ran" ] || { echo "textconv ran"; return 1; }
```

**Evidence:** `test/scripts/build-loop-check.bats:1261-1268`; /tmp/fcu2b1a1-r3-logs/mutant-main-scripts.tap

---

## Claim 21: Commit ae08688c: "Suites: build-loop-check 81, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2."

**Location:** commit ae08688c message (body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each suite's count of `ok` lines at ae08688c, all passing with 0 `not ok`. It does not establish other suites (hermeticity-lint was not named and not run).
**Legibility-target:** for-automated-gate

| Suite | ok | not ok |
|---|---|---|
| build-loop-check | 81 | 0 |
| build-loop-read | 19 | 0 |
| dev-cycle | 78 | 0 |
| fixture-git-env | 2 | 0 |
| fixture-hermeticity | 2 | 0 |

Every run exited 0.

Command: `for s in …; do TMPDIR=$(mktemp -d /tmp/fcu2b1a1-r3-XXXX) timeout 900 bats $s; done`, cwd /workspace/.claude/wt-build-loop-u2b1a1, run window 2026-10-08T18:59:00Z to 19:00:26Z. This claim resembles the logged pattern "All 85 tests … but the suites hold 97" (a count claim in a commit message), but the counts hold here.

**Evidence:** /tmp/fcu2b1a1-r3-logs/build-loop-check.tap, build-loop-read.tap, dev-cycle.tap, fixture-git-env.tap, fixture-hermeticity.tap

---

## Claim 22: Commit ae08688c: "115 code lines against main." and "the file contents are those of feat/build-loop-u2b1a at c66988b6 for the lib and dev-cycle.sh, and its --status-side hunks of build-loop.sh"

**Location:** commit ae08688c message (body, Notes)
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the numstat total and the identity checks. It does not establish what "code lines" means beyond "everything outside docs/, tests included", which matches the plan's cap ("tests count toward the cap").
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/'` gives:
- scripts/build-loop.sh: 15 added, 31 removed
- scripts/dev-cycle.sh: 2 added, 1 removed
- scripts/lib/dev-cycle-read.sh: 38 added, 7 removed
- test/scripts/build-loop-check.bats: 21 added, 0 removed

That is 76 + 39 = 115.

`git diff --stat c66988b6 HEAD -- scripts/lib/dev-cycle-read.sh scripts/dev-cycle.sh` is empty. `git diff HEAD c66988b6 -- scripts/build-loop.sh` touches only --check-side text: the --check usage and help, "Writes nothing but --check's merge objects", the exit line, usage(), --check parsing, harden, the extra exports, state_gate, gate_repo, merge_result, check_line and the `check)` case. It has no hunk in marker_kind or status_line, and none in the --status help's skip clause. c66988b6 is the tip of feat/build-loop-u2b1a.

Commands: as quoted, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T18:58Z.

**Evidence:** /tmp/fcu2b1a1-r3-bl-vs-c669.diff; `git diff --numstat` output (paraphrased — no quote available because the output is a git command result, reproduced in full above)

---

## Claim 23: Commit ae08688c's itemized body (anybrief row 323; open_shared row 298; check_branch skip row 307; "--no-textconv ... (iteration 1 C3, pre-existing)"; marker_kind "reads the message with cat-file (NULs dropped in the pipe) and answers bad on a failed read"; dev-cycle.sh help; the two tests and the show and gated helpers)

**Location:** commit ae08688c message (body bullets)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against the diff and the cited rows. The behavioural halves rest on Claims 1, 2, 4, 10 and 13-16. It does not re-verify the iteration 1-2 review content beyond the row and C3 lookups.
**Legibility-target:** for-orchestrator-synthesis

The cited rows are:
- row 298 (`override-log.md:298`): "Revisit trigger: U2, which moves brief enumeration into the lib for --check."
- row 307 (`:307`): "make marker_kind answer bad on a failed read, and test with `log.date bogus`".
- C3 in the U2b1a rubric (`git show feat/build-loop-u2b1a:docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md`, line 78, under "🟢 Consider (iteration 1)"): "`--status` has no state gate: a repo-local `diff.x.textconv` … Pre-existing on main."

All five listed items appear in the diff (diff.patch:54-265).

**Evidence:** `docs/reviews/override-log.md:298`, `:307`, `:323`; diff.patch

---

## Claim 24: Plan step 5's U2b1a split note and the Q-119 update

**Location:** `docs/working/plan-build-loop-handoff.md:282`; `docs/working/questions.md:346`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each factual statement in the two lines against the branches, listed in the body below. It does not establish the U2b1b/U2b2/U2b3 descriptions, which are plans for future units, nor the D7 and `--state`/`--check` plan lines beyond the facts named below.
**Legibility-target:** for-orchestrator-synthesis

The statements checked:
- "439 lines": `git diff --numstat main...feat/build-loop-u2b1a` outside docs/ gives 389 + 50 = 439 at c66988b6 (it was 396 at 9e5d92df, before the iteration-2 fixes).
- U2b1a1's contents: they match this diff.
- "`feat/build-loop-u2b1a2` … on U2b1a1": `git merge-base --is-ancestor HEAD feat/build-loop-u2b1a2` holds, and the branch is one commit (63ea50e7) over ae08688c.
- U2b1a2's functions: `harden`, `state_gate`, `gate_repo`, `merge_result` and `check_line` are each defined once on that branch's build-loop.sh.
- "keeps both units' review history (iterations 1-2, rubric …)": the rubric exists on feat/build-loop-u2b1a with "## Iteration 2 of 3" and a status line naming the split.
- "is not merged": `merge-base --is-ancestor feat/build-loop-u2b1a main` is false.
- Q-119's "commit d0199be6 on `feat/build-loop-u2b1a`": that commit is on that branch and adds the plan's 5-line U2b split note.
- Q-119's "At review iteration 2 U2b1a split again for size (439 lines)": consistent with the first statement.
- Plan D7: `git_state_gate` exists at `devcontainer-config/install.sh:209`.
- Plan `--state`: u2b1a2's state_gate prints `refuse state …` lines (build-loop.sh:184-185 on that branch).

Commands: as named, cwd /workspace/.claude/wt-build-loop-u2b1a1, exit 0, 2026-10-08T19:02Z (git output, not saved to a file; reproduced in the summary above).

**Evidence:** `docs/working/plan-build-loop-handoff.md:281-282`; `docs/working/questions.md:346`; `devcontainer-config/install.sh:209`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 17** (`test/scripts/build-loop-check.bats:1249`): the comment says show prints "the history included", but in the row-307 test (`log.date bogus` still set) show's `git log --oneline --graph --all` fails with "fatal: unknown date format bogus", so a failure there prints no history.

### Unverifiable
(none)

## Escalations

- None blocking. One for-author note (Claim 17): if the history matters in the row-307 test, show's git log needs a config override such as `git -c log.date=default`. Without one, the comment's "history included" does not hold in that test.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: ae08688c` line at the top.
- Answered: yes
- Out of scope: U2b1a2's --check code (harden, state_gate, gate_repo, merge_result, check_line); I read it only to confirm the plan's split note and the "only --check-side hunks differ" claim, and did not verdict its comments.
- Escalate: nothing
