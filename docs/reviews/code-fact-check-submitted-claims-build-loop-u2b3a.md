Commit: 3d2d8c44

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b3a, branch feat/build-loop-u2b3a)
**Scope:** Submitted claims only (Stage 2.5 intake): three security-reviewer endorsements about `scripts/lib/dev-cycle-read.sh` and `test/scripts/build-loop-check.bats` at commit 3d2d8c44. No claims were harvested. Every file was read with `git show 3d2d8c44:<path>`, and everything that ran used a throwaway detached worktree of 3d2d8c44, so the worktree's in-progress edits were never read.
**Checked:** 2026-10-08
**Total claims checked:** 3
**Summary:** 3 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md` at 3d2d8c44): I read it, and none of the three claims matches a logged pattern. Claim 7 is the same kind of claim as the logged test-count entries ("All 85 tests", "mode1-equiv 33"), so I counted the tests by running them rather than taking the number on trust. The run listed `1..8`.

Execution logs (captured outputs; the brief limits writes to this one report file, so the logs are in the session scratchpad, not `docs/reviews/execution-logs/`):
- `/tmp/claude-1000/-workspace/53eaab1e-c162-42ac-afd9-547bb673cbb3/scratchpad/u2b3a3-sub-logs/claim5.txt`
- `/tmp/claude-1000/-workspace/53eaab1e-c162-42ac-afd9-547bb673cbb3/scratchpad/u2b3a3-sub-logs/claim6-v2.txt`
- `/tmp/claude-1000/-workspace/53eaab1e-c162-42ac-afd9-547bb673cbb3/scratchpad/u2b3a3-sub-logs/claim7.txt`
- Probe scripts: `.../scratchpad/u2b3a3-sub-probe.sh` (claims 5 and 7) and `.../scratchpad/u2b3a3-sub-probe6.sh` (claim 6). The first probe's `claim6.txt` has been superseded and is not evidence. Its checker flagged the parser's prefix candidates (`wt`, `wt/f`, ...) as extra output, and its random names rarely fell under a root. The v2 probe fixes both problems.

---

## Submitted Claims

## Claim 5: "A caller root (IMPORT_READER_ROOTS) that is a symlink to `/` makes both walks fail, so every path answers imported."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:891-927`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a caller root that is a symlink to `/`, written either bare or with a trailing `/.`. It establishes that tree and main both fail and that `isimported` answers imported for tracked, untracked and nonexistent paths. It does not establish behaviour for a caller home that is a symlink to `/` (the same check at :913 applies, but I did not run it). It also does not cover a symlink to some other directory, such as `/tmp`, which is accepted as a root by design. Finally, it does not check whether callers other than `isimported`/`truthwalk` read `IMPORTED*` directly, which contract item 6 forbids.

Mechanism. The written-form check accepts the symlink's own path because that path is not `/` alone:

```bash
# scripts/lib/dev-cycle-read.sh:904-908
  for p in "${rs_r[@]}" "${rs_h[@]}"; do
    [[ -n "$p" ]] || continue
    [[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1
    rs_x+=("$p")
  done
```

The batched realpath then resolves the symlink to `/`, and the post-realpath check refuses it:

```bash
# scripts/lib/dev-cycle-read.sh:910-913
  nul_list rs_real realpath -mz -- "${rs_x[@]}" || return 1
  [[ ${#rs_real[@]} -eq ${#rs_x[@]} ]] || return 1
  for i in "${!rs_x[@]}"; do
    [[ -n "${rs_real[i]//\//}" && "${rs_real[i]}" != *$'\n'* ]] || return 1
```

(excerpt ends :913; enclosing `import_readers()` continues to :927, read. `IMPORT_READERS_DONE="$k"` at :926 is set only on success, and :897 clears it first, so a failure leaves no memo and the next call fails again.)

Both walks turn that failure into an error result: `import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }` (`:1049`, imported_names) and `import_readers || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; return 1; }` (`:1099`, main_imports). `isimported` answers imported when a walk fails: `main) main_imports || return 0;` and `tree) imported_names || return 0;` (`:1198-1199`).

Execution confirms it. `realpath -m` of the symlink printed `/`. For both walks, and for both the bare `$T/rootlink` and `$T/rootlink/.`, the output was `walk: failed` and `IMPORT_READERS_DONE empty: yes`, and `docs/a.md`, `docs/other.md` and `no/such/path.md` all answered `imported`. A plain-directory caller root was run as a control. There both walks printed `walk: ok`, `docs/other.md: -` and `no/such/path.md: -`, so the result above comes from the symlink and not from the harness.

Provenance: command `timeout 1500 bash .../scratchpad/u2b3a3-sub-probe.sh .../scratchpad/u2b3a3-sub-logs` (each walk ran inside `timeout 60 env LC_ALL=C bash -c '... source dev-cycle-read.sh; IMPORT_READER_ROOTS=...; resolve_main; ROOT_REAL=$(pwd -P); main_imports|imported_names; isimported ...'`, which mirrors the bats `imps` helper). The working directory was a fixture repo under `/tmp/u2b3a3-sub-0Vr7/repo`, with the lib taken from the detached worktree `/tmp/u2b3a3-sub-0Vr7/wt` at 3d2d8c44. Every sub-run exited 0, and the probe exited 0. Started 2026-10-09T04:41:11Z UTC.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:891-927`, `scripts/lib/dev-cycle-read.sh:1049`, `scripts/lib/dev-cycle-read.sh:1099`, `scripts/lib/dev-cycle-read.sh:1193-1202`, `/tmp/claude-1000/-workspace/53eaab1e-c162-42ac-afd9-547bb673cbb3/scratchpad/u2b3a3-sub-logs/claim5.txt`

---

## Claim 6: "Every spelling the parser's dotnest rule omits has a dot-led component, so truthrule's `dot` word refuses it; the two cite each other."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:747-760` (put's dotnest comment and loop), `scripts/lib/dev-cycle-read.sh:1220` (truthrule's dot line)
**Type:** Invariant / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every spelling that `put` withholds because of `dotnest`. Each one satisfies truthrule's dot test `"/$1" == */.*`, and the two comments do refer to each other. It does not establish that truthrule reports the word `dot` for every such path. Because `isstart` is tested first (:1219), an instruction-file name such as `.claude/wt-x/claude.md` is refused as `instr`, and an unlowered path is refused as `case`. Either way the path is refused, but under a different word. It also does not cover spellings dropped for other reasons (the newline return at :746, `seen` dedup, budgets), and it does not check that every caller sends a walk name through truthrule.

The rule is built in BEGIN. `dotnest[i, j]` is set only when root j is strictly longer than root i, starts with it, and the remainder, with a leading `/`, contains `/.`:

```awk
# scripts/lib/dev-cycle-read.sh:821-823
  for (i = 1; i <= nr; i++) pre[i] = (roots[i] == "/") ? "/" : roots[i] "/"
  for (i = 1; i <= nr; i++) for (j = 1; j <= nr; j++)
    if (length(pre[j]) > length(pre[i]) && index(pre[j], pre[i]) == 1 && index("/" substr(pre[j], length(pre[i]) + 1), "/.")) dotnest[i, j] = 1
```

`put` applies it. Among the roots that hold `out`, the spelling relative to `h[i]` is withheld only when some other holding root `h[j]` has `dotnest[h[i], h[j]]`:

```awk
# scripts/lib/dev-cycle-read.sh:756-760
  nho = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i])) h[++nho] = i
  for (i = 1; i <= nho; i++) {
    for (j = 1; j <= nho; j++) if ((h[i], h[j]) in dotnest) break
    if (j > nho) show(substr(out, length(pre[h[i]]) + 1))
  }
}
```

(excerpt ends at put's closing brace, :761, read in full from :731.) Because `out` starts with `pre[h[j]]`, and `pre[h[j]]` starts with `pre[h[i]]`, the withheld spelling `substr(out, length(pre[h[i]]) + 1)` begins with the remainder that the BEGIN test found to contain `/.`. With a leading `/` added, it therefore contains `/.`, which is truthrule's test (paraphrased — no quote available because this is a derivation from the two quoted predicates, not a line of code). A root spelled with `.`, `..` or `//` never holds anything, because `out` is lexically normalized at :737-743, so such a root cannot cause a withheld spelling.

truthrule's line is `elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"  # the parser's dotnest omits only such paths: keep the two equal` (`:1220`). put's comment says `(the dot word of truthrule: narrowing it means changing this rule too)` (`:751`). So the two do cite each other. truthrule's order is `case` (:1218), then `isstart` → `instr` (:1219), then `dot` (:1220).

Execution supports the derivation. The probe drove `$IMPORT_AWK` at 3d2d8c44 directly over 1500 random root sets. The roots included dot components, `..e`, `.claude`, nested roots and `/`, and each name was drawn under a root. Output: `trials=1500 trials-with-2+-holding-roots=646 holding-spellings=2320 omitted=598 omitted-without-dot-component=0 non-prefix-extras=0`. truthrule returned `.claude/wt-x/docs/a.md -> dot`, `a/.b/c.md -> dot`, `..e/x.md -> dot`, and `.claude/wt-x/claude.md -> instr`. That last result is the word residue named in Scope.

Provenance: command `timeout 600 bash .../scratchpad/u2b3a3-sub-probe6.sh .../scratchpad/u2b3a3-sub-logs`, run in the temp dir `/tmp/u2b3a3-sub-wVMi`, with the lib from the detached worktree at 3d2d8c44c0d3c762d1e333340599feb38b9051d5. Exit 0, run 2026-10-09T04:41:44Z to 04:41:50Z UTC.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `scripts/lib/dev-cycle-read.sh:731-761`, `scripts/lib/dev-cycle-read.sh:815-827`, `scripts/lib/dev-cycle-read.sh:1216-1228`, `/tmp/claude-1000/-workspace/53eaab1e-c162-42ac-afd9-547bb673cbb3/scratchpad/u2b3a3-sub-logs/claim6-v2.txt`

---

## Claim 7: "The 8 U2b3a tests in test/scripts/build-loop-check.bats pass at 3d2d8c44."

**Submitted by:** security-reviewer
**Location:** `test/scripts/build-loop-check.bats:1717-1845`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and the pass status of the `@test`s whose names contain "U2b3a" at 3d2d8c44, run in this sandbox. It does not establish that each test exercises what its name says, or that it would fail on the code it guards; that is shared-brief item 4 and is not part of this claim. It also does not cover the rest of `build-loop-check.bats`, the sourced-definitions test in `test/scripts/dev-cycle.bats`, or runs under another locale (this sandbox has no en_US.UTF-8, so `setlocale` warnings were printed).

There are 8 `@test` lines whose names contain "U2b3a" (`:1717`, `:1728`, `:1741`, `:1756`, `:1782`, `:1801`, `:1815`, `:1824`). The one other "U2b3a" mention in the file is the comment at `:1714` (`# U2b3a, the reader model's roots and homes (plan step 5): ...`), which the filter does not select. The run printed `1..8` and `ok 1` through `ok 8`, with names matching those lines from "both walks read an absolute name into another worktree ..." to "both walk caches key on the reader set ...", and then `exit: 0`.

Provenance: command `TMPDIR=/tmp/u2b3a3-sub-bats-RWd9 timeout 900 bats --filter 'U2b3a' test/scripts/build-loop-check.bats`, run in the detached worktree `/tmp/u2b3a3-sub-0Vr7/wt` at 3d2d8c44. Exit 0, run 2026-10-09T04:41:12Z to 04:41:15Z UTC.

**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `test/scripts/build-loop-check.bats:1714-1845`, `/tmp/claude-1000/-workspace/53eaab1e-c162-42ac-afd9-547bb673cbb3/scratchpad/u2b3a3-sub-logs/claim7.txt`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
(none)

### Unverifiable
(none)

Scope residue for synthesis, not a finding: in claim 6, truthrule refuses every spelling that dotnest withholds, but an instruction-file name is refused under the word `instr` rather than `dot`, because `isstart` is tested first (`scripts/lib/dev-cycle-read.sh:1219`).

No Incorrect verdicts, so `docs/reviews/hallucination-patterns.md` was not changed.

---

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/code-fact-check-submitted-claims-build-loop-u2b3a.md, with `Commit: 3d2d8c44` as its first line and a `## Submitted Claims` section numbering claims from 5.

**Answered:** Claims 5, 6 and 7 are each verdicted against 3d2d8c44 by running the code, and each verdict carries its Verification mode, Scope and Legibility-target lines. All three are Verified.

**Out of scope:** No claims were harvested. Out of scope are: whether the U2b3a tests would have failed on the code they guard, the `dev-cycle.bats` sourced-definitions test, the IMPORT_WORK_MAX figures, and the worktree's uncommitted edits (which were never read).

**Escalate:** Nothing.
