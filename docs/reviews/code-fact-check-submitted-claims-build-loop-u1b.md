Commit: 2e711a7b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1b (unit `feat/build-loop-u1a...feat/build-loop-u1b`)
**Scope:** Submitted claims only (security-reviewer x2, performance-reviewer x2) about `scripts/build-loop.sh` and the lib functions it calls, at 2e711a7b, review iteration 4 (final confirming pass); no fresh harvesting
**Checked:** 2026-10-05
**Total claims checked:** 4 (Claims 55-58, continuing the merged report's numbering)
**Summary:** 3 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Line numbers are those of `scripts/build-loop.sh` at 2e711a7b (195 lines) and `scripts/lib/dev-cycle-read.sh` at the same commit. The worktree's `scripts/` and `test/` have no uncommitted changes (`git diff --stat HEAD -- scripts test` is empty), so the probes ran the code under review.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`): no verdict here is Incorrect, so the log is not updated.

Executed-probe provenance (shared by all four claims):
- Working directory for every probe: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/`. `env.sh` there sets a hermetic git environment (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, `HOME` in the scratch dir, `LC_ALL=C`, and unsets `GIT_CONFIG_COUNT`, `GIT_CONFIG_PARAMETERS`, `GIT_NO_REPLACE_OBJECTS`), builds throwaway repos (`r55/`, `r56/`, `r57/`, `r57b/`, `r58/`) on branch `main`, and runs the worktree's `scripts/build-loop.sh --settings` through its normal scrub re-exec.
- Commands, each `timeout N bash probeXX.sh > probeXX-out.txt 2>&1`, all exit 0: probe55 (2026-10-05T16:59:35Z), probe56 (17:00:02Z), probe57 (17:00:16Z), probe57b (17:00:24Z), probe58 (17:00:38Z), probe58b (17:00:52Z). Each `*-out.txt` holds a harmless `bash: warning: setlocale` line from the host locale.
- Suite: `cd /workspace/.claude/wt-build-loop-u1b && LC_ALL=C.UTF-8 timeout 300 bats test/scripts/build-loop-read.bats` (17:00:57Z, exit 0, 9/9 ok), output in `bats-out.txt`.
- Tools: git 2.39.5, GNU bash 5.2.15, mawk 1.3.4 20200120, 16 cores, load average ~1.2-1.7. No background processes were started; every probe ran in the foreground under `timeout`.

---

## Submitted Claims

## Claim 55: "With `core.useReplaceRefs=true` in the target repo's `.git/config` and a replace ref on main's `docs/dev-cycle.md`, `--settings` reads main's original blob."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (A16 / C3 closure: the replace-ref guard against repo config)
**Location:** `scripts/build-loop.sh:69-70`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a replace ref on main's settings blob with `core.useReplaceRefs=true` set in the repo's own `.git/config`, and also a caller passing `core.useReplaceRefs=true` through `GIT_CONFIG_COUNT`; confirms by mutation that the GIT_CONFIG_COUNT line is what holds. Does not establish anything for a caller that sets `GIT_CONFIG_PARAMETERS` (the critic's own scoped-out case: it does bypass the guard, reproduced below), for a non-numeric `GIT_CONFIG_COUNT`, or for dev-cycle.sh's lib readers (override row: no guard there, deferred to U3b).

The guard appends a command-line config pair after any the caller passed, and sets the env switch:

```bash
# scripts/build-loop.sh:69-70
cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))
export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1
```

In probe55, main's blob reads `Build-loop policy: review` and a replace object reads `Build-loop policy: self-merge`. On git 2.39.5 the repo config does defeat the env variable alone: `GIT_NO_REPLACE_OBJECTS=1 git cat-file blob main:docs/dev-cycle.md` printed `Build-loop policy: self-merge` once `core.useReplaceRefs true` was set. The real script, with the same config, printed `policy review set: line 1 of docs/dev-cycle.md on the default branch` (the original blob). A mutant copy with line 69 deleted printed `policy self-merge set: line 1 ...`, so line 69 is what holds the guard. With the caller passing `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.useReplaceRefs GIT_CONFIG_VALUE_0=true`, the script still printed `policy review set`, because its pair is index 1 and read later. With `GIT_CONFIG_PARAMETERS="'core.usereplacerefs'='true'"` from the caller, the script printed `policy self-merge set` (git reads that variable after the counted pairs). This matches the critic's scoped-out note and is outside the claim.

**Evidence:** `scripts/build-loop.sh:69-72`, `scripts/build-loop.sh:89`, `test/scripts/build-loop-read.bats:82-84` (T4's replace-ref assertion), `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe55.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe55-out.txt`

---

## Claim 56: "`policy self-merge set` is printed only when an exact policy line and an exact, single, valid never line (`never_ok`) are both present on main's commit; a never line hidden in markup with no exact line gives `policy review unset`."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (Q-112 [1] / A17 closure: self-merge cannot be raised without a valid never line)
**Location:** `scripts/build-loop.sh:151-182`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every assignment to POLICY_LINE in read_settings (`:134-188`, read whole, including the slots branch after `:182` and main_file's failure arm at `:139-143`) and 17 executed file shapes; "single" means single as the letters-only copy count sees it. Does not establish that every hidden copy is detected (a copy in markup that adds letters, such as a task box next to an exact never line, is not counted and the exact line governs: the settled override row for iteration 3's R4), and does not cover how later modes (U1c's --status, U2's gate) consume POLICY.

The only line that prints `policy self-merge set` is the exact-regex branch, and it requires `never_ok` for self-merge:

```bash
# scripts/build-loop.sh:177-181
    elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]; then
      v="${BASH_REMATCH[1]}"
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but there is no valid Self-merge never: line (\"Self-merge never: none\" for an empty list), so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
```

That branch is reached only after the count branches `:175-176` (no line, or more than one), and `never_ok` starts empty (`local ... never_ok=""` at `:135`) and is set only where the never line had one copy, began `Self-merge never: `, used single spaces, was followed by a blank or the end, and every entry passed globform with no repeat (`why` empty):

```bash
# scripts/build-loop.sh:171-173 (excerpt ends :173; the never block opens at :152 and read_settings continues to :188 — read)
      if [[ -n "$why" ]]; then NEVER_LINE="never malformed: line ${first[never]} $why"
      elif [[ "$v" == none ]]; then never_ok=1; NEVER_LINE="never none: line ${first[never]} $where lists none"
      else never_ok=1; NEVER=("${parts[@]}"); NEVER_LINE="never $v set: line ${first[never]} $where"; fi
```

When main_file fails (absent, not a file, odd or unbalanced), `:141` sets `policy review unset` and never reaches `:177`. Executed in probe56: `policy self-merge set` appeared only for an exact policy line plus an exact never line (`none`, a glob list, CRLF endings, and case 13, an exact line beside a task-box copy). Every other shape printed `policy review unset`: no never line; a never line in a task box (`- [x] Self-merge never: b/`, which reads `never none: no line starts ...`), in bold or in an HTML comment (both `never malformed`); two exact never lines; a `../x` entry; a never line continued by `b/`; a never line only inside a fence; a policy line with a trailing space; two policy lines; an exact never line plus a bold copy; and an unread file. A review policy with a malformed never line prints `policy review set`, which is not self-merge and is consistent with the claim.

**Evidence:** `scripts/build-loop.sh:134-188`, `scripts/build-loop.sh:103-118` (SETTINGS_AWK copy count), `test/scripts/build-loop-read.bats:106-149` (T45), `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe56.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe56-out.txt`

---

## Claim 57: "The `--settings` run makes a fixed 6 git process calls, independent of file size and never-list length (GIT_TRACE count)."

**Submitted by:** performance-reviewer
**Legibility-target:** performance-reviewer (fork budget of the settings read, for U2's gate)
**Location:** `scripts/build-loop.sh:62-72`, `scripts/build-loop.sh:78-95`; `scripts/lib/dev-cycle-read.sh:246` (main_by_name), `:258-274` (main_entry), `:389-411` (resolve_main)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the GIT_TRACE count across file size (1.5 KB to 0.93 MB), a 500-entry never list, an absent file and three default-branch shapes; does not establish counts for a repo with no default branch found by name (exits after resolve_main) or for the later modes (--status, the gate) that will call the same lib.

The count does not depend on file size or never-list length: it was 6 for a small file, a 500-entry never list and a 928,947-byte file. The calls were `rev-parse --show-toplevel`, `symbolic-ref ... refs/remotes/origin/HEAD`, `show-ref --verify --hash refs/heads/main`, `rev-parse --verify --quiet '<sha>^{commit}'`, `ls-tree -t --full-tree <sha> -- docs docs/dev-cycle.md` and `cat-file blob <sha>:docs/dev-cycle.md`. "Fixed 6" holds only for a repo whose default branch is `main` and whose file exists, because resolve_main tries one candidate per `show-ref`:

```bash
# scripts/lib/dev-cycle-read.sh:395-401 (excerpt ends :401; resolve_main continues to :411 — read)
  for c in "${candidates[@]}"; do
    [[ "$c" == -* ]] && continue
    # show-ref --verify takes only the exact ref, so a tag named refs/heads/<c>
    # cannot stand in for a missing branch (rev-parse would accept it).
    sha="$(git show-ref --verify --hash "refs/heads/$c" 2>/dev/null || true)"
    [[ -z "$sha" ]] || sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"
    if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; MAIN_BY_NAME=1; break; fi
```

Measured: 5 with no `docs/dev-cycle.md` (no cat-file), 7 with the default branch named `master`, and 8 with origin/HEAD naming a branch that has no local copy. The count is a small constant per repo shape (5-8), not 6 everywhere. The claim's scaling point is correct.

**Evidence:** `scripts/build-loop.sh:62`, `scripts/build-loop.sh:71-72`, `scripts/build-loop.sh:81`, `scripts/build-loop.sh:89`, `scripts/lib/dev-cycle-read.sh:263`, `scripts/lib/dev-cycle-read.sh:389-411`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe57.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe57-out.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe57b.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe57b-out.txt`

---

## Claim 58: "The settings file is read in one awk pass and the run scales linearly with file size (2 KB ≈ 20 ms, 1.27 MB ≈ 39 ms, 5.11 MB ≈ 102 ms)."

**Submitted by:** performance-reviewer
**Legibility-target:** performance-reviewer (cost of the settings read as docs/dev-cycle.md grows)
**Location:** `scripts/build-loop.sh:89`, `scripts/build-loop.sh:103-118`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the number of awk processes per run (PATH shim) and wall time over line-heavy files from 1.5 KB to 17.8 MB plus one 5 MB single line, on this host; the submitted millisecond figures are machine-dependent and were checked for agreement in shape, not exactly. Does not establish the cost of the perl scrub on very long output lines (output is three lines, at most a 4 KB never line per the settled override row) or the quadratic globform cost on one huge never entry (settled override row, ~11 s at 80 KB).

The blob goes through one pipeline, FENCE_AWK and SETTINGS_AWK concatenated into one program:

```bash
# scripts/build-loop.sh:89-90 (excerpt ends :90; main_file continues to :95 — read)
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")" \
    || { FILE_WHY="$f could not be read from the default branch"; return 1; }
```

A PATH shim on `awk` (probe58b) logged exactly one awk process per `--settings` run, with a 2,877-byte program. SETTINGS_AWK's per-line work is one `tolower`, one `gsub` and three `index` calls (`:108-112`), and its END prints at most three lines, so the bash loop at `:145-149` reads at most three records. Median of 7 runs (probe58): 1,536 B 18 ms; 1,110,056 B 34 ms; 4,440,056 B 87 ms; 17,760,056 B 302 ms; a 5,000,057 B file of one long line 97 ms. The marginal cost is 14.4, 15.5 and 16.0 ms/MB across the three larger steps, which is linear, and it agrees with the submitted points (interpolated: about 38 ms at 1.27 MB and 97 ms at 5.11 MB).

**Evidence:** `scripts/build-loop.sh:78-95`, `scripts/build-loop.sh:103-118`, `scripts/build-loop.sh:139-149`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe58.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe58-out.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe58b.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/submitted/probe58b-out.txt`

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 57** (`scripts/build-loop.sh:71-72`, `scripts/lib/dev-cycle-read.sh:389-411`): the git call count is constant per repo shape but not always 6. It is 5 with no settings file, 7 when the default branch is `master` and 8 when origin/HEAD names a missing branch. Restate the claim as "a constant 5-8 calls (6 on `main`), independent of file size and never-list length".

## Goal-Alignment Note

Success criterion: "A report saved at the output path named in your tail, structured per your skill, covering the full unit diff at 2e711a7b." This pass covers the four submitted claims at 2e711a7b and does no fresh harvesting; the Stage 1 report covers the rest of the unit diff. Both security endorsements hold under execution. The repo-config replace-ref bypass (A16) is closed, and line 69 is shown to be what closes it (55). Self-merge cannot be printed without an exact policy line and a valid never line (56), which matches Q-112 [1]. Case 13 shows the settled residual: a hidden never copy beside an exact line leaves the exact line governing. It does not raise the policy or drop an applicable list the reader could see, so it does not meet the re-raise bar. Both performance endorsements hold on scaling. Claim 57's "fixed 6" needs a qualifier, which is wording only and not merge-blocking. One item for the orchestrator to note, outside the claims: a caller-set `GIT_CONFIG_PARAMETERS` still turns replace refs back on. The critic scoped this out as caller environment. If it is not already settled, it belongs with the U3b replace-ref deferral.
