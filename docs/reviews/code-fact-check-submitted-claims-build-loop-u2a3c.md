Commit: 4b7f2357

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3c (feat/build-loop-u2a3c)
**Scope:** Stage 2.5 submitted claims only (10 critic endorsements submitted at 3a35c8b9, verdicted against HEAD 4b7f2357); no harvested claims. Numbering continues the canonical merged report (ends at 64).
**Checked:** 2026-10-07
**Total claims checked:** 11 (10 submitted; claim 67 split into 67a/67b)
**Summary:** 10 verified, 0 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution provenance for every executed claim: scripts and captured output are in the scratch dir `/tmp/u2a3c-i2-sub-pu2e/` (logs under `logs/`; the brief forbids writing anything else in the worktree, so logs were not copied to `docs/reviews/execution-logs/`). Each probe ran against a copy of the worktree at 4b7f2357 (`/tmp/u2a3c-i2-sub-pu2e/repo`), against `git show 21b35ebf:scripts/lib/dev-cycle-read.sh` (`old-lib.sh`; its `main_checkout` extracted and renamed `main_checkout_old` in `old-mc.sh`), and against main's lib at e5d0f838 (`main-lib.sh`). Host: 16 cores, WSL2, 2026-10-07 21:03-21:11 UTC. Timing claims are verdicted on shape (who is faster, by roughly what factor), not exact seconds.

Supporting suite run: `TMPDIR=<mktemp> LC_ALL=C timeout 900 bats test/scripts/build-loop-check.bats`, cwd `/tmp/u2a3c-i2-sub-pu2e/repo`, exit 0, 66/66 ok, log `/tmp/u2a3c-i2-sub-pu2e/logs/bats.log`.

---

## Submitted Claims

## Claim 65: "For every call whose PATH has no entry in ENT, HEAD's main_checkout returns the same code as 21b35ebf's, under any call order on one MEMO."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:735-762`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers random call sequences (each version on its own MEMO, shared random ENT of 8 entries with modes 100644/100755/120000/160000) over checkouts holding absent nodes, plain files, unreadable files, symlinks, FIFOs, searchable and non-searchable directories, PATH depth 1-4 over a 6-letter alphabet; does not establish depths over 4, case-variant names, ENTs that `main_imports`' own tree parse would reject, or a checkout that changes between calls.

The 4b7f2357 guard is a no-op when ENT lacks PATH, since `${mc_e[$3]:-}` is then empty:

```bash
# scripts/lib/dev-cycle-read.sh:743
  [[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1
```

The bottom-up walk stops at the nearest memoized ancestor, then checks each unmemoized ancestor's main mode before its shape (`:746-754`), so a MEMO value of 2 never hides a deeper ancestor's link mode:

```bash
# scripts/lib/dev-cycle-read.sh:746-750
  while [[ "$c" == */* ]]; do c="${c%/*}"; if [[ -n "${mc_m[$c]+set}" ]]; then st="${mc_m[$c]}"; break; fi; anc+=("$c"); done
  for ((i = ${#anc[@]} - 1; i >= 0; i--)); do
    c="${anc[i]}"
    [[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1
    if [[ "$st" == d ]]; then
(excerpt ends :750; enclosing main_checkout continues to :762 — read)
```

Differential run: `for s in 1..120: LC_ALL=C timeout 60 bash diff.sh <HEAD lib> $s 60 s1`, cwd per-seed `mktemp -d`, exit 0, 2026-10-07T21:03Z. 6,602 calls, 0 differences; return codes exercised 0 (222), 1 (3,229), 2 (3,151).

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`, 21b35ebf `scripts/lib/dev-cycle-read.sh:721-740`, `/tmp/u2a3c-i2-sub-pu2e/diff.sh`, `/tmp/u2a3c-i2-sub-pu2e/logs/s1.log`

---

## Claim 66: "main_imports passes main_checkout a path only when `ent` holds no entry for it, at both call sites (start seeds; imports)."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:808-883`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the only two calls of `main_checkout` in scripts/ (the bats suites call it directly as unit tests); does not establish anything about callers outside `scripts/` or future callers (the comment at `:727` states the precondition, and 4b7f2357's PATH guard is what protects them).

Start seeds: only `t:` candidates reach `main_checkout`, and a `t:` candidate is added only when `ent` lacks it:

```bash
# scripts/lib/dev-cycle-read.sh:826
  for f in "${recs[@]}"; do [[ "$f" != *$'\n'* ]] || return 1; [[ -n "${ent[$f]+set}" ]] || cand+=("t:$f"); done
# scripts/lib/dev-cycle-read.sh:832
      f="${cand[i]:2}"; c=0; [[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f" || c=$?
```

`m:` candidates are added only from the `ls-tree` records that just set `ent[$f]` (`:819-821`). Imports:

```bash
# scripts/lib/dev-cycle-read.sh:877
      c=0; [[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p" || c=$?  # main lacks p: admitted before it is marked seen
```

`rg -n 'main_checkout\b' scripts test` finds only these two call sites in `scripts/` (paraphrased — no quote available because the claim covers absence of other callers, a grep result).

**Evidence:** `scripts/lib/dev-cycle-read.sh:816-833`, `scripts/lib/dev-cycle-read.sh:872-882`

---

## Claim 67a: "With the guard now in main_checkout, its return code matches 21b35ebf's for every call, including a PATH ENT holds as a link or gitlink"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:743`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers calls whose PATH ENT holds as 120000 or 160000; does not establish that the change is a defect (it is the documented intent of 4b7f2357), and does not reach main_imports, which never makes such a call (claim 66).

The guard changes the return code for exactly this case. 21b35ebf never looked up PATH's own mode: it checked only ancestors in its loop, then answered by the checkout's shape (`[[ -e "$c" || -L "$c" ]] || return 2`; `rawfile` → `[[ -r ]]`; `plaindir "$c" && return 2`; 21b35ebf `:736-739`). HEAD answers 1 first:

```bash
# scripts/lib/dev-cycle-read.sh:742-743
  # Main's link or gitlink at PATH refuses before a checkout directory there is memoized as d (U2a3c final fact-check 34).
  [[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1
```

Minimal run (`LC_ALL=C bash -c '...'`, cwd a scratch checkout, exit 0, 2026-10-07T21:11Z): `dl ent=120000 21b35ebf=2 HEAD=1`; `fl ent=120000 21b35ebf=0 HEAD=1`; `gd ent=160000 21b35ebf=2 HEAD=1`; `gf ent=160000 21b35ebf=0 HEAD=1`. The random differential (mode s3, 120 seeds, 7,200 calls) found 185 differences, every one at a PATH ENT holds as 120000 or 160000 (old 0 or 2, new 1). The divergence is intended: the comment at `:723` says "main's link or gitlink at PATH answers 1" and 4b7f2357's message says so. The precise claim: HEAD matches 21b35ebf everywhere except a PATH main stores as a link or gitlink, where HEAD answers 1 and 21b35ebf answered by the checkout's shape.

**Evidence:** `scripts/lib/dev-cycle-read.sh:719-743`, 21b35ebf `scripts/lib/dev-cycle-read.sh:721-740`, `/tmp/u2a3c-i2-sub-pu2e/logs/s3-min.log`, `/tmp/u2a3c-i2-sub-pu2e/logs/s3.log`

---

## Claim 67b: "a PATH ENT holds as a blob (100644/100755) still answers by the checkout's shape."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:743-761`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers blob modes at PATH, which match 21b35ebf in every sampled call; does not establish depth over 4 or case variants (as claim 65).

The guard's regex `^1[26]0000$` (`:743`) does not match 100644/100755, so the code falls through to the shape tests at `:756-761` (`rawfile` → `[[ -r "$c" ]]`; `plaindir "$c" || return 1`; `return 2`). Minimal run: `bf ent=100644 21b35ebf=0 HEAD=0`. In the s3 differential none of the 185 differences had a blob mode at PATH.

**Evidence:** `scripts/lib/dev-cycle-read.sh:743`, `scripts/lib/dev-cycle-read.sh:755-761`, `/tmp/u2a3c-i2-sub-pu2e/logs/s3-min.log`, `/tmp/u2a3c-i2-sub-pu2e/logs/s3.log`

---

## Claim 68: "The symlink arm compares the link blob's size against 4096 before either whole read of the blob, and a failed size read fails the walk."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:848-854`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a size over 4096 and a nonzero `git cat-file -s` exit; does not establish clean failure when `cat-file -s` exits 0 but prints a non-number (a git that does so is hypothetical: under the caller's `set -u` the `-le` test then aborts the caller's shell with "unbound variable", rather than returning 1 with IMPORTED_MAIN=error).

```bash
# scripts/lib/dev-cycle-read.sh:849-854
        # Link text past PATH_MAX (4096) names nothing; it fails before the two whole reads below.
        i="$(git cat-file -s "$MAIN_SHA:$f")" && [[ "$i" -le 4096 ]] || { IMPORTED_MAIN=error; return 1; }
        # $(...) drops NULs, so they are counted first; the x keeps trailing
        # newlines, which $(...) would also drop.
        if ! i="$(git cat-file blob "$MAIN_SHA:$f" | tr -cd '\0' | wc -c)" || [[ "$i" -ne 0 ]] \
           || ! out="$(git cat-file blob "$MAIN_SHA:$f" && printf x)"; then IMPORTED_MAIN=error; return 1; fi
(excerpt ends :854; enclosing 120000 arm continues to :866 — read)
```

Probe `bash probe-s.sh <HEAD lib> <scratch>` (cwd scratch repos, exit 0, 2026-10-07T21:03Z), caller `set -eu` without pipefail: control link walk `rc=0`; git shim failing `cat-file -s` → `rc=1 IMPORTED_MAIN=error`, with 0 `cat-file blob` reads of `CLAUDE.md` logged. Garbage-size shim → `line 850: notanumber: unbound variable` (scope residue). The over-4096 case is pinned by bats test 63 ("link text main stores longer than 4096 bytes", ok in `bats.log`), whose shim asserts the blob is never read.

**Evidence:** `scripts/lib/dev-cycle-read.sh:848-866`, `test/scripts/build-loop-check.bats:944-956`, `/tmp/u2a3c-i2-sub-pu2e/probe-s.sh`, `/tmp/u2a3c-i2-sub-pu2e/logs/probe-s.log`, `/tmp/u2a3c-i2-sub-pu2e/logs/bats.log`

---

## Claim 69: "A read failure in either capped_read arm (unopenable checkout file, head failure, git cat-file failure, drain failure) sets IMPORTED_MAIN to error and returns 1, given main_imports' own `set -o pipefail`."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:710`, `scripts/lib/dev-cycle-read.sh:844-847`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_imports' checkout and blob arms with a caller that has no pipefail; does not establish imported_names' arm (`:782-783`, which sets IMPORTED, not IMPORTED_MAIN) or failures of `import_targets` itself.

```bash
# scripts/lib/dev-cycle-read.sh:710
capped_read() { head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null; }
# scripts/lib/dev-cycle-read.sh:809 (excerpt; main_imports continues to :883 — read)
  local - rec f d p i c lk out used=0 work=0 queue=() tq=() recs=() cand=() low=() parts=(); set -o pipefail  # as brief_fields
# scripts/lib/dev-cycle-read.sh:844-847
      checkout) out="$(capped_read < "$f" | IMPORT_LEFT=... import_targets "$d")" \
          && import_work out work || { IMPORTED_MAIN=error; return 1; } ;;
      100644|100755) out="$(git cat-file blob "$MAIN_SHA:$f" | capped_read drain | IMPORT_LEFT=... import_targets "$d")" \
          && import_work out work || { IMPORTED_MAIN=error; return 1; } ;;
```

(`IMPORT_LEFT=...` elides the two budget assignments; paraphrased — no quote available because the full lines exceed a readable width; they are unchanged otherwise.) Probe, caller `set -eu` without pipefail, each with a passing control: checkout file made mode 000 after admission (wrapped `main_checkout`) → `rc=1 IMPORTED_MAIN=error`; `head` shim exiting 1 → `rc=1 IMPORTED_MAIN=error` in both arms; drain shim (`cat` with no args writing to /dev/null exits 1; logged that it fired) → `rc=1 IMPORTED_MAIN=error`; blob object deleted (`git cat-file` fails) → `rc=1 IMPORTED_MAIN=error`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:702-710`, `scripts/lib/dev-cycle-read.sh:808-883`, `/tmp/u2a3c-i2-sub-pu2e/probe-s.sh`, `/tmp/u2a3c-i2-sub-pu2e/logs/probe-s.log`, `/tmp/u2a3c-i2-sub-pu2e/logs/probe-s2.log`

---

## Claim 70: "A deep token whose ancestors the checkout lacks costs time linear in printed bytes: 0.66 s at D=1000 against 10.83 s at 21b35ebf, and 2.49 s at D=1990."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:735-762`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shape on this host (one main walk over a committed `CLAUDE.md` naming `@a/…/x.md`, no `a/` in the checkout); "linear in printed bytes" is quadratic in D, since the parser prints every prefix; does not establish other token shapes.

`bash perf.sh deep <lib> <scratch> <D>` (cwd scratch repo, exit 0, 2026-10-07T21:05Z): HEAD 0.61 s at D=1000, 2.34 s at D=1990; 21b35ebf 10.52 s at D=1000, 59.93 s at D=1990. HEAD is about 17x faster at D=1000; HEAD's 1990/1000 ratio is 3.8, against a printed-bytes ratio of (1990/1000)^2 = 3.96, so linear in printed bytes holds. Mechanism: the bottom-up loop at `:746` stops at the first memoized ancestor (quoted under claim 65).

**Evidence:** `scripts/lib/dev-cycle-read.sh:746-754`, `/tmp/u2a3c-i2-sub-pu2e/perf.sh`, `/tmp/u2a3c-i2-sub-pu2e/logs/p1.log`

---

## Claim 71: "The 4096-byte `git cat-file -s` check fails a 64 MiB link blob in 0.02 s, against 16.34 s at 21b35ebf, before either whole read."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:850`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a 64 MiB all-`a` link blob at `CLAUDE.md` on main; does not establish other blob contents (they cannot matter at HEAD, which stops at the size).

`bash perf.sh biglink <lib> <scratch>` (exit 0, 2026-10-07T21:06Z; time is the walk only): HEAD `failed 0.01s`; 21b35ebf `failed 14.42s`. Both fail, HEAD about 1,000x sooner. "Before either whole read" is from claim 68 (`:850` precedes `:853-854`; bats test 63's shim logs no blob read).

**Evidence:** `scripts/lib/dev-cycle-read.sh:850-854`, `/tmp/u2a3c-i2-sub-pu2e/logs/p2.log`, `/tmp/u2a3c-i2-sub-pu2e/logs/bats.log`

---

## Claim 72: "`capped_read drain` keeps a 512 MiB blob's walk at 0.96 s and passing, where main's lib took over 120 s."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:710`, `scripts/lib/dev-cycle-read.sh:846`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a 512 MiB main blob (`see @r.md` then 512 MiB of `a`, no newline) at `CLAUDE.md`, absent from the checkout; does not establish the cost for blobs whose first 4 MiB are dense with @ tokens (the parser, not the drain, then dominates).

`LC_ALL=C TO=150 bash perf.sh bigblob <lib> <scratch>` (exit 0, 2026-10-07T21:07Z): HEAD `ok 0.98s`; main (e5d0f838) killed by `timeout 150` at 150.36 s. Mechanism: `head -c 4194305` passes only 4 MiB + 1 to the parser and the rest goes to `cat > /dev/null` (`:710`, quoted under claim 69).

**Evidence:** `scripts/lib/dev-cycle-read.sh:710`, `scripts/lib/dev-cycle-read.sh:846-847`, `/tmp/u2a3c-i2-sub-pu2e/logs/p3.log`

---

## Claim 73: "main_checkout's memo cuts the realpath forks of a D=1000 present-directory token from 2,001 (21b35ebf) to 1,001, one per prefix."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:760`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one main walk with `a/`×D present as plain searchable directories and `x.md` absent; the counts include one realpath outside main_checkout (1,001 = 1,000 prefixes + 1), so "one per prefix" is one per prefix plus a constant; does not establish counts for absent or mixed ancestors.

```bash
# scripts/lib/dev-cycle-read.sh:759-761
  plaindir "$c" || return 1
  [[ ! -x "$c" ]] || mc_m[$c]=d  # a prefix candidate's directory, which longer ones pass through
  return 2
```

21b35ebf never memoized PATH, so the next prefix re-ran `plaindir` on it as an ancestor (21b35ebf `:732`). `bash p4.sh <lib> <scratch> <D>` with a logging `realpath` shim on PATH (exit 0, 2026-10-07T21:10Z): HEAD D=10 → 11, D=1000 → 1,001; 21b35ebf D=10 → 21, D=1000 → 2,001.

**Evidence:** `scripts/lib/dev-cycle-read.sh:755-761`, `/tmp/u2a3c-i2-sub-pu2e/p4.sh`, `/tmp/u2a3c-i2-sub-pu2e/logs/p4.log`

---

## Claim 74: "`import_work` is linear in the parser's output: 0.17 s for 5.1 MB."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:678-683`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers an OUT of newline-separated ~20-byte names with a `/N` trailer; does not establish the cost on other output shapes (bash's glob match `*$'\n'"/$iw_w"` and the `%/*` / `##*/` strips are shape-dependent).

```bash
# scripts/lib/dev-cycle-read.sh:678-683
import_work() {
  local -n iw_o="$1" iw_t="$2"; local iw_w="${iw_o##*/}"
  [[ "$iw_w" =~ ^[0123456789]+$ && ( "$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w" ) ]] || return 1
  iw_o="${iw_o%/*}"; iw_o="${iw_o%$'\n'}"
  (( (iw_t += iw_w) <= IMPORT_WORK_MAX ))
}
```

Timing (`LC_ALL=C bash -c 'source <HEAD lib>; …'`, exit 0, 2026-10-07T21:10Z), each with rc=0 and the trailer stripped: 1.3 MB 0.036 s, 2.6 MB 0.074 s, 5.1 MB 0.168 s, 10.2 MB 0.369 s, which is linear.

**Evidence:** `scripts/lib/dev-cycle-read.sh:674-683`, `/tmp/u2a3c-i2-sub-pu2e/logs/p5.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 67a** (`scripts/lib/dev-cycle-read.sh:743`): at a PATH main stores as a link or gitlink, HEAD answers 1 where 21b35ebf answered 0 (plain file) or 2 (directory or absent). The change is the intended effect of 4b7f2357; the endorsement should say "matches everywhere except a link/gitlink at PATH, which now refuses."

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None.
