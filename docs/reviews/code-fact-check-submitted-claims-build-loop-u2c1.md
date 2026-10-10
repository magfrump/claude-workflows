# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2c1, branch feat/build-loop-u2c1)
**Commit:** 9e7c61c5
**Scope:** Submitted claims only (Stage 2.5): security-reviewer's three `route: code-fact-check` endorsements (docs/reviews/security-review-2026-10-10-u2c1-final.md:92-110) and performance-reviewer's two `[unverified — submitted as claim]` endorsements (docs/reviews/performance-review-2026-10-10-u2c1-final.md:62-63). No fresh harvesting.
**Checked:** 2026-10-10
**Total claims checked:** 5
**Summary:** 4 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Probe provenance (shared by the executed claims). All probes ran in a throwaway copy, `git archive HEAD scripts test` extracted to `/tmp/u2c1-s25-eage` (no git write in /workspace or the review worktree). Artifacts are in the scratch dir `/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-final-s25/`:
- `instrumentation.diff`: the only edits to the copy. Two env-gated lines log a real (non-cached) walk: `echo main >> "$S25_WALKLOG"` after main_imports' cache check, and the same for imported_names. One env-gated switch, `S25_NORESET`, skips check_line's `import_reset`. With those variables unset, the copy behaves exactly like HEAD.
- `s25-probes.bats`: three probe tests appended to the copied `test/scripts/build-loop-check.bats`, so they use its fixtures (`smb`, `brief`, `chk`). Command: `LC_ALL=C TMPDIR=$(mktemp -d /tmp/u2c1-s25-bats-XXXX) S25_OUT=<out> timeout 900 bats -f S25 test/scripts/build-loop-check.bats`, cwd `/tmp/u2c1-s25-eage`, exit 0 (`ok 1..3`), run 2026-10-10 before 11:08Z. Output: `out-fozo/a.txt`, `out-fozo/e.txt`, `out-fozo/d.txt`.
- `harness.sh` + `fuzz.py`: a unit harness. It sources HEAD's lib and the HEAD text of `list_entries`, `globform`, `read_paths`, `never_res` and `srules`, extracted verbatim from scripts/build-loop.sh, with `floor` stubbed to return 1 so that only the never and allowlist arms run. A Python reference implementation of the stated semantics is compared against it on random inputs. Command: `for s in 1 2 3; do python3 -I fuzz.py never $s; python3 -I fuzz.py paths $s; done`, cwd `/tmp/u2c1-s25-eage`, exit 0, timestamp 2026-10-10T11:08:17Z. Output: `fuzz-out.txt`.
- I also ran the branch's own U2c1 tests unchanged: `LC_ALL=C TMPDIR=$(mktemp -d /tmp/u2c1-s25-bats2-XXXX) bats -f U2c1 test/scripts/build-loop-check.bats`, cwd the review worktree, exit 0, 6/6 ok (titles T9, T10 ×2, T45, row 523, walk-once/C-locale).

---

## Submitted Claims

## Claim 55: "A second self-merge brief in one --check does not inherit the first brief's Paths: entries."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:627-632`, `scripts/build-loop.sh:815-818`, `scripts/lib/dev-cycle-read.sh:386-390`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers PATHS/PATHS_WHY/BRIEF reset between briefs in one --check run, for a following brief with no Paths: line, a malformed one, `Paths: none`, and a failed re-read (static only). It does not establish anything about the floor's walk cache, which is covered under Claim 59, or about other globals such as CHECKOUT_WHY.

Every self-merge brief re-reads its fields, and both readers empty their globals first. brief_fields begins:
```bash
# scripts/lib/dev-cycle-read.sh:390
  BRIEF=(); BRIEF_ODD=""
```
read_paths begins `PATHS=(); PATHS_WHY=""` and then sets `PATHS=("${LIST[@]}"); PATHS_WHY="$LIST_WHY"` (`scripts/build-loop.sh:628,631`). The caller's failure arm resets the same state:
```bash
# scripts/build-loop.sh:817
    if brief_fields "$a"; then read_paths; else PATHS=(); PATHS_WHY="could not be read again"; co="${co:-refuse $a: the brief could not be read again from the default branch}"; fi
```
srules runs only for `pol == self-merge` (`scripts/build-loop.sh:833`), and for such a brief line 817 has always run first. A review brief never reads PATHS.

Executed probe `S25a`, from `out-fozo/a.txt`. I ran `chk x y x z x w x`, where x has `Paths: src/`, y has no Paths: line, z has `Paths: src/ src/` and w has `Paths: none`. Each x run gave `ok … path … A src/a`. The others gave:
```
deny docs/working/briefs/2026-10-01-y.md A src/b: neither listed in the brief's Paths: line nor one of its own files
deny docs/working/briefs/2026-10-01-z.md A src/c: the brief's Paths: line lists entry 2 twice, so only its own files land
deny docs/working/briefs/2026-10-01-w.md A src/d: neither listed in the brief's Paths: line nor one of its own files
```
The failed-re-read arm is confirmed static only, from the line-817 quote above. That arm also sets `co`, so the floor is skipped and the verdict refuses.

**Evidence:** `scripts/build-loop.sh:627-632`, `scripts/build-loop.sh:817`, `scripts/build-loop.sh:833`, `scripts/lib/dev-cycle-read.sh:390`, scratch `out-fozo/a.txt`

---

## Claim 56: "A never glob matches case-insensitively, `*`/`?` match within one part, and a glob also matches a directory above the path."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:636-647`, `scripts/build-loop.sh:661-664`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex never_res builds for every globform-admitted glob (letters, digits, `. _ - /`, `*`, `?`) and srules' match of it against the lower-cased path, `**` included. It does not establish that read_settings rejects every malformed `Self-merge never:` line (globform's job, read but not fuzzed), and it does not establish the floor-first ordering, which the floor stub hides.

The construction escapes the only ERE-special character globform admits (`.`), translates `*` and `?` to part-bounded classes, and anchors at the start with a part-boundary end:
```bash
# scripts/build-loop.sh:642-646
    g="$(lower "${g%/}")"; re=""
    for ((i = 0; i < ${#g}; i++)); do
      c="${g:i:1}"
      case "$c" in '*') re+='[^/]*' ;; '?') re+='[^/]' ;; .) re+='\.' ;; *) re+="$c" ;; esac
    done
    NEVER_RES+=("^$re(/|\$)")
```
The other admitted characters (`_`, `-`, `/`, letters and digits) are literal outside a bracket expression in an ERE. srules tests the lower-cased spelling: `[[ ! "$3" =~ ${NEVER_RES[$i]} ]]` (`scripts/build-loop.sh:663`). Its caller passes `${lps[$i]}` from lower_all (`scripts/build-loop.sh:833`).

Executed: `fuzz.py never`, 3 seeds × 4,000 random (glob, path) pairs. Globs were drawn from `aAbB.-_*?/x` and paths from `aAbB.-_/xX`, keeping only globform/pathform-valid ones. The reference model is case-folded, part-by-part fnmatch over the glob's k parts against the path's first k parts. Result: `mismatches 0` for every seed (172–191 matches per seed), per `fuzz-out.txt`. Spot cases: `Docs/A?c` → `^docs/a[^/]c(/|$)` matches `docs/abc/d/e`; `x*y.md` does not match `xa/by.md`; `a.b` does not match `axb`. The branch's T45 test also passes.

One wording note, not a defect: the regex also matches the path equal to the glob, and a trailing `/` does not restrict a glob to directories. The code comment says the same (`a trailing / changes nothing`, `scripts/build-loop.sh:635`).

**Evidence:** `scripts/build-loop.sh:382-389`, `scripts/build-loop.sh:636-647`, `scripts/build-loop.sh:661-664`, `scripts/build-loop.sh:833`, scratch `fuzz-out.txt`, `harness.sh`, `fuzz.py`

---

## Claim 57: "The Paths: allowlist compares entries exactly. A trailing `/` matches at a part boundary, and malformed lines (`//`, `.`, `..`, leading `/`, doubled spaces, bare `Paths:`) land only own files."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:363-379`, `scripts/build-loop.sh:665-670`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers list_entries' grammar as read_paths uses it, and srules' allowlist arm (ownfile first, then PATHS_WHY, then exact or directory-prefix match). It does not establish ownfile's own correctness beyond the working-doc and review names exercised, and it does not cover the never and floor arms that precede the allowlist arm.

The match line quotes `$e` on both sides, so an entry is literal. A prefix match is allowed only when the entry ends in `/`:
```bash
# scripts/build-loop.sh:668
    [[ "$2" != "$e" && ( "$e" != */ || "$2" != "$e"* ) ]] || return 0
```
Own files are tested before the malformed check: `! ownfile "$2" "$1" "$4" || return 0` (`scripts/build-loop.sh:665`). A non-empty PATHS_WHY then denies with `so only its own files land` (`scripts/build-loop.sh:666`). The line shape is enforced by `[[ "$1" != "$2: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]` (`scripts/build-loop.sh:369`). After one trailing `/` is dropped, each entry passes pathform, which refuses empty, `.`, `..` and `.git*` parts and a leading `/` or `-`. Duplicates are caught by `seen[${e%/}]=1` (`scripts/build-loop.sh:376`), so `a` and `a/` collide. For `//`, a doubled slash leaves an empty part after the strip, and pathform refuses it.

Executed: `fuzz.py paths`, 3 seeds × 3,000 cases. The Paths: lines were built from tokens including `a/`, `A/`, `.`, `..`, `/a`, `a//`, `none`, `.git/`, `-a`, the empty token (which yields doubled or trailing spaces), bare `Paths:`, `Paths:a` and an absent line. They were checked against paths including own working docs and reviews, an upper-case own-file spelling, and `ab` vs `a/`. Result: `mismatches 0` (585–623 ok, 643–705 not-listed, 1,710–1,768 malformed per seed), per `fuzz-out.txt`. The branch tests at build-loop-check.bats:1948 and :1967 pass.

**Evidence:** `scripts/build-loop.sh:363-379`, `scripts/build-loop.sh:627-632`, `scripts/build-loop.sh:665-670`, `scripts/lib/dev-cycle-read.sh:213-222`, scratch `fuzz-out.txt`

---

## Claim 58: "Per-path cost is … still linear in changed paths."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:769-838` (check_line), per performance-review-2026-10-10-u2c1-final.md:62
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the linearity of --check's wall time in the number of changed paths for one self-merge brief, on the bats fixture, from 1 to 800 paths. It does not establish the reviewer's comparison with iteration 1 (6.7 vs 6.4 ms per path at 400 paths: different machine and fixture, not reproduced), and it does not cover fixed costs (checkout_gate's hash of main's whole tree, the one walk), which scale with repository size, not with changed paths.

Executed probe `S25d`, from `out-fozo/d.txt`. It ran one self-merge brief with `Paths: src/`, N added files under `src/`, and 2 repetitions:
```
n=1   ms=149/145    n=100 ms=698/684    n=200 ms=1281/1305
n=400 ms=2469/2488  n=800 ms=5131/6446
```
The marginal cost is about 5.8 ms per path from 100 to 200, 5.9 from 200 to 400, and 6.7 from 400 to 800 (rep 1). That is roughly constant, so the time is linear, and the second n=800 run was noisy. In the per-path loop (`scripts/build-loop.sh:830-835`), each path pays the following:
- nrules, whose prefix loop runs once per directory level (`while [[ -z "$DENY" && "$d" == */* ]]`, `scripts/build-loop.sh:616`);
- srules, which runs one regex per never glob and one comparison per Paths: entry (`scripts/build-loop.sh:662-669`);
- floor on the cached walk.

None of these iterates over the other changed paths. The per-path factor therefore grows with path depth, glob count and entry count, not with N.

**Evidence:** `scripts/build-loop.sh:616-619`, `scripts/build-loop.sh:658-670`, `scripts/build-loop.sh:830-835`, scratch `out-fozo/d.txt`

---

## Claim 59: "check_line in the parent shell keeps one walk per self-merge brief: `import_reset` resets it, and the cache serves that brief's paths."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:773`, `scripts/build-loop.sh:855-860`, `scripts/lib/dev-cycle-read.sh:1626-1635`
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parent-shell call, the per-brief reset and the per-brief cache of the main walk, plus the absence of any tree walk. It does not establish need_root's call count, which is covered under the performance review's F1, or walk cost.

check_line is called with a redirect, not inside `$(...)`, so it runs in the caller's shell: `check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"` (`scripts/build-loop.sh:858`). Its first statement after the locals is `import_reset  # caller contract item 4: no walk cache outlives a decision` (`scripts/build-loop.sh:773`). main_imports returns from its cache when the key matches:
```bash
# scripts/lib/dev-cycle-read.sh:1632
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
```

Executed probe `S25e`, from `out-fozo/e.txt`, counting real walks through the instrumentation:
- `reset [x y]`: x has 4 changed paths and y has 3. Result: `main=2 tree=0`. That is one walk per brief, with every other path served from the cache.
- `noreset [x y]`, with import_reset skipped: `main=1`. The cache survived from x into y. That could happen only if check_line ran in the parent shell, and it shows import_reset is what forces y's walk.
- `reset [x q y]`: `main=2`. Brief q is self-merge, but its only path is denied by an N rule, so q walks zero times.
- A self-merge brief whose checkout is refused (`co` set, a staged file): `main=0`.
- A review brief: `main=0`.

The inaccuracy is the word "one" (the dispatch's paraphrase says "exactly one"). A brief walks at most once, and only when at least one of its paths reaches floor's `elif truthwalk main "$lp"` (`scripts/lib/dev-cycle-read.sh:1845`). A self-merge brief whose paths all stop at the N rules, at an earlier floor arm or at a refused checkout gets no walk. That is cheaper, not costlier, so the performance conclusion stands.

**Evidence:** `scripts/build-loop.sh:773`, `scripts/build-loop.sh:833`, `scripts/build-loop.sh:858`, `scripts/lib/dev-cycle-read.sh:792`, `scripts/lib/dev-cycle-read.sh:1632-1635`, `scripts/lib/dev-cycle-read.sh:1845`, scratch `out-fozo/e.txt`, `instrumentation.diff`
