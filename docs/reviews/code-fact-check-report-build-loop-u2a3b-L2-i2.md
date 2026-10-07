Commit: 98e3b1df

# Code Fact-Check Report

**Commit:** 98e3b1df
**Replication:** k=1 (loop pass, decision 031)
**Repository:** /workspace/.claude/wt-build-loop-u2a3b (branch feat/build-loop-u2a3b)
**Scope:** `git diff be94c871..98e3b1df -- . ':!docs/reviews'` (commits dd51e9a7 and 98e3b1df) and their commit messages: `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`, `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11), `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`. The Claude Code side was checked against the installed 2.1.292 binary (`@anthropic-ai/claude-code/bin/claude.exe`; strings read at offsets 205304326 for `Ye`, 212107518 for `kOe`/`reo`/`nH`).
**Checked:** 2026-10-07
**Total claims checked:** 42
**Summary:** 31 verified, 8 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Execution provenance. Unless a claim says otherwise, the work ran in `/tmp/u2a3bfcL2i2-NgQD` (a `git clone` of the worktree checked out at 98e3b1df: `repo/`; the same clone with be94c871's `scripts/lib/dev-cycle-read.sh` and `scripts/dev-cycle.sh`: `old/`; one mutant per directory, `m-<name>/`, written by `mut.py`). Bats ran with `TMPDIR` set to a fresh `mktemp -d /tmp/u2a3bfcL2i2-tXXXX`. Between 2026-10-07T08:06Z and 08:24Z. Captured output: `suites.log`, `suites-dd.log`, `old-fails.log`, `mutants.log`, `cf.log`, `cfwt.log`, `cfdd.log`, `probes.log` (all in `/tmp/u2a3bfcL2i2-NgQD/`), and `/tmp/u2a3bfcL2i2-dxgr/{py,node}.txt` for the decoder comparison. The review rules forbid writing worktree files other than this report, so these logs live outside `docs/reviews/execution-logs/`. Only read-only `--check-fix` and walk runs touched the worktree and `/workspace`, and `git status --porcelain` was empty before and after. Environment note: `LC_ALL=en_US.UTF-8` is exported here but that locale is not installed (`locale -a`: C, C.utf8, POSIX), so every bash prints a setlocale warning and bash falls back to C.

Hallucination-pattern log: read (`docs/reviews/hallucination-patterns.md`, 5 patterns). The count claims below look like the logged "All 85 tests ... pass" and "mode1-equiv 33" patterns, so I re-counted them by running the suites. They hold (Claims 36a, 38a). This run adds no new fabrication pattern.

Suites (role requirement): `bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats` at 98e3b1df gave **133/133 ok** (exit 0, 08:06:43Z to 08:07:31Z, `suites.log`). The same command at dd51e9a7 gave **130/130** (`suites-dd.log`).

---

## Claim 1: A5 "the claim, its rules and its exceptions are stated once, in the comment above `import_targets` in `scripts/lib/dev-cycle-read.sh`"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that A5 no longer restates the rules and that the pointer target exists. It does not establish that the target comment is complete (see Claim 9).

The diff replaces A5's inline rule list with the pointer. The target says `# The superset claim (the one statement of it; known issue A5 and plan F11` / `# point here)` (`scripts/lib/dev-cycle-read.sh:496-497`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:496-497`

---

## Claim 2: A5 "The oracle it was checked against was Claude Code 2.1.292's import regex and Markdown lexer, extracted from the installed package into a scratch fuzzer by the U2a2 and U2a3b security reviews; that harness is not kept, so a revisit re-extracts it from the new version."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the cited reviews say they built and that no harness is tracked. It does not establish the harnesses' fidelity.

The U2a3b L2 security report says: "I rebuilt it from the installed binary ... The marked lexer sits at the same offsets ... and I ran it in node. I transcribed `reo` verbatim" (`docs/reviews/security-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md:12`). The U2a2 final report says: "`reo` was transcribed around them to make a differential harness" (`docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:13`), and it ran "over 27 lines" (`:123`). Two details are imprecise. The import regex was transcribed, not extracted; only the lexer bytes were extracted. And U2a2's harness was a 27-line differential harness, not a fuzzer. No harness is tracked (paraphrased; no quote available because the claim concerns absence: `git ls-files | grep -i 'fuzz\|harness'` lists only unrelated CRB and arch execution logs).

**Evidence:** `docs/reviews/security-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md:12`, `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md:13,123`

---

## Claim 3: F11 "(U2a3b; the claim and its exceptions are stated once, above `import_targets`)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pointer. It does not establish the target's completeness (Claim 9).

The rule list ("every `@`, every prefix to the first blank, absolute paths inside the repo") was replaced by the pointer. The target exists at `scripts/lib/dev-cycle-read.sh:496-517`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`

---

## Claim 4: --check-fix help "a file an instruction file names after an @, read broadly; compared ignoring case"

**Location:** `scripts/dev-cycle.sh:53-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help's description of the refusal set (every candidate the tree walk lists, lower-cased). It does not establish the transitive case, which the help still omits (known issue C3, fail-safe).

`check_fix` refuses when `isimported tree "$lp"`. The tree walk appends every candidate `import_targets` prints, lower-cased: `lp="$(lower "$out")" ...; IMPORTED+="$lp"$'\n'` (`scripts/lib/dev-cycle-read.sh:620`). Running `--check-fix` over all 942 tracked `docs/**/*.md` and README.md with 98e3b1df's script and with main's (b5eadbd8) gave identical decisions once the wording was normalized. That held in the clone and in the worktree (`cf.sh`, `cfwt.sh`, exit 0, 08:14Z; `cf.log`, `cfwt.log`).

**Evidence:** `scripts/dev-cycle.sh:53-54,184`, `scripts/lib/dev-cycle-read.sh:620`, `/tmp/u2a3bfcL2i2-NgQD/cf.log`, `/tmp/u2a3bfcL2i2-NgQD/cfwt.log`

---

## Claim 5: skip line "an instruction file names it after an @ (directly or through another import), so it may be read as instructions; file it instead"

**Location:** `scripts/dev-cycle.sh:184`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the branch that prints it and its condition. It does not establish wording parity with other refusal lines.

The line prints under `elif isimported tree "$lp"; then` (`scripts/dev-cycle.sh:183`). I ran a temp repo (`mktemp -d /tmp/u2a3bfcL2i2-rXXXX`) with `AGENTS.md` holding `See @../r/docs/notes.md`. main printed `skip docs/notes.md: an instruction file imports it with @ ...`, be94c871 printed `ok docs/notes.md`, and 98e3b1df printed `skip docs/notes.md: an instruction file names it after an @ ...`. "May be read" matches the over-read design.

**Evidence:** `scripts/dev-cycle.sh:181-185`; command output recorded in-session (paraphrased; no quote available because the three one-line outputs were not captured to a file; reproduce with the three scripts under `/tmp/u2a3bfcL2i2-NgQD/{mainsc,old,repo}/scripts/dev-cycle.sh`)

---

## Claim 6: SKILL.md "file an instruction file names after an `@`, read broadly; compared ignoring case"

**Location:** `skills/dev-cycle/SKILL.md:75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers parity with the help text and behaviour in Claim 4. It does not establish the transitive case (C3).

The wording matches `scripts/dev-cycle.sh:54` exactly. The behaviour is as in Claim 4.

**Evidence:** `skills/dev-cycle/SKILL.md:75`, `scripts/dev-cycle.sh:54`

---

## Claim 7: IMPORT_OUT_MAX "Each walk fails once import_targets has printed this many bytes in all: the parser's own bound is per file, while the bash side's cost grows with everything printed (performance L2 F2); /workspace's walks print about 2 KB."

**Location:** `scripts/lib/dev-cycle-read.sh:482-485`
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' accounting and the 2 KB figure. It does not establish the bash-side cost model.

Both walks do `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED=error; return 1; }` (`:618`; `:694` with `IMPORTED_MAIN`). Each sits after `[[ -n "$out" ]] || continue` (`:617`, `:693`), so a walk fails only once the total is **more than** IMPORT_OUT_MAX, not when it reaches it. The test name says "more than" correctly (`test/scripts/build-loop-check.bats:398`). `${#out}` counts characters in bash's current locale (bytes only under C), and `$(...)` strips each file's last newline, so "bytes" is approximate. The per-file bound is `work += length(c); if (work > 50000000) exit 3` (`:524`); `work` is a fresh variable in each awk process, one per file. Measured (`used.sh`, `probes.log`): tree and main walks each printed 2059 bytes in the worktree and in the clone. In the shared `/workspace` checkout the tree walk printed 5676 bytes (its ignored instruction files), and the main walk failed closed there, as A5 predicts. So "about 2 KB" holds for a fresh worktree. The mutants removing either walk's check fail the test (`mutants.log`: m-outtree, m-outmain).

**Evidence:** `scripts/lib/dev-cycle-read.sh:482-485,524,617-618,693-694`, `test/scripts/build-loop-check.bats:398-404`, `/tmp/u2a3bfcL2i2-NgQD/probes.log`, `/tmp/u2a3bfcL2i2-NgQD/mutants.log`

---

## Claim 8: superset comment, candidate rules: "Every @ in a line starts a candidate ... each prefix of the run after it, up to the first blank (a NUL or a UNI_SPACES space counts as one), is a candidate name, with a backslash-escaped space read as a space. A line holding <!-- is also read with its closed HTML comments removed"

**Location:** `scripts/lib/dev-cycle-read.sh:499-504`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers scan/splice and the sed blanking. It does not establish that "blank" includes \v or \f: it does not, because scan breaks only on space, tab and CR, which over-reads relative to JavaScript's `\s`.

```awk
# scripts/lib/dev-cycle-read.sh:541-548
  for (i = 1; i <= L; i++) {
    if (substr(line, i, 1) != "@") continue
    name = ""
    for (j = i + 1; j <= L; j++) {
      ch = substr(line, j, 1)
      if (ch == "\\" && substr(line, j + 1, 1) == " ") { ch = " "; j++ }
      else if (ch == " " || ch == "\t" || ch == "\r") break
      name = name ch; emit(name)
```
(excerpt ends :548; enclosing scan() continues to :551 — read). The 4096-byte cap is gone (`for (j = i + 1; j <= L; j++)`). sed turns NUL and every UNI_SPACES sequence into a space first (`:564-568`). The `{ scan($0); if (index($0, "<!--")) scan(splice($0)) }` main rule (`:562`) applies the splice per line. All of this is exercised by the passing superset tests (`suites.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:539-562,564-568`, `/tmp/u2a3bfcL2i2-NgQD/suites.log`

---

## Claim 9: superset comment, completeness: "these rules read every name Claude Code 2.1.292 can import ... ~/ names are dropped. Known exceptions: a .. after a symlinked directory ... and any further decoding Claude Code may add (an entity, a percent escape)."

**Location:** `scripts/lib/dev-cycle-read.sh:497,510-513`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the `~/` case for a repository under `$HOME`. It does not establish whether `AD()` (the in-project check) passes for every such path, which I read but did not trace to its definition, and it does not cover /workspace itself, which is not under `$HOME`.

The comment is presented as "the one statement" of the superset claim with its exceptions, but it leaves out one known class. Claude Code expands `~/`: its resolver reads `if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)))` with `homedir as c` and `join as b` (binary offset 205304326). Its include walk keeps an import inside the project: `for(let Pe of Ce){if(!AD(Pe)&&!z)continue; ... EF(Pe, ...)` (offset ~212108600). The parser drops every `~/` name: `if (c == "" || substr(c, 1, 2) == "~/") return` (`:526`). Executed (`probes.log`): with `ROOT_REAL=/home/u/proj` and `HOME=/home/u`, `See @~/proj/docs/x.md` yields only `~` and never `docs/x.md`. So for a repository under `$HOME`, an `@~/<repo>/...` import is missed: a superset hole the "Known exceptions" list does not name. The L2-i1 fact-check recorded this residue ("a repo under `$HOME` imported as `@~/<path-to-repo>/docs/x.md` is missed", `code-fact-check-report-build-loop-u2a3b-L2-i1.md:35`). The iteration-1 triage carries no row for it, and the new single statement drops it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:497,510-513,526`, claude.exe offsets 205304326 and ~212108600, `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i1.md:35`, `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 10: superset comment, resolution: "Each candidate is trimmed of spaces, made absolute (ROOT_REAL/$1/name unless it starts with /) and resolved lexically, .. stopping at / as Node's path.resolve does, so a name that leaves the repo and re-enters it is kept; it is kept only when it lies below ROOT_REAL, and printed repo-relative."

**Location:** `scripts/lib/dev-cycle-read.sh:506-510`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers emit's transformation. It does not establish that the trim is needed for the superset (Claim 13).

```awk
# scripts/lib/dev-cycle-read.sh:525-537
  sub(/^ +/, "", c); sub(/ +$/, "", c)  # Claude Code trims the name (an escaped space can lead it)
  if (c == "" || substr(c, 1, 2) == "~/") return
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
  n = split(c, part, "/"); k = 0
  for (i = 1; i <= n; i++) {
    if (part[i] == "" || part[i] == ".") continue
    if (part[i] == "..") { if (k > 0) k--; continue }
    st[++k] = part[i]
  }
  out = ""; for (i = 1; i <= k; i++) out = out "/" st[i]
  if (index(out, pre) != 1 || length(out) <= length(pre)) return
  out = substr(out, length(pre) + 1)
  if (!(out in seen)) { seen[out] = 1; print out }
```
(excerpt ends :537; enclosing emit() continues to :538 — read). Executed (`probes.log`, ROOT_REAL `/r`, dir `sub`): `@/r/sub/../b.md` gives `b.md`, `@../../../r/c.md` gives `c.md` (`..` clamped at `/`, then re-entry), `@/etc/x.md` is dropped, and `@/r`, `@/r/` and `@..` are dropped. Claude Code's resolver is `path.resolve` (`resolve as x` imported from "path"; `return Hn(x(i,o))`, offset 205304326), so "as Node's path.resolve does" is accurate. The five hole tests pass at HEAD and fail at be94c871 (Claim 27).

**Evidence:** `scripts/lib/dev-cycle-read.sh:523-538`, claude.exe offset 205304326, `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 11: superset comment, exception (a): "a .. after a symlinked directory, which the kernel follows through the link while both Claude Code and this walk resolve it lexically (row 350)"

**Location:** `scripts/lib/dev-cycle-read.sh:511-512`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers Claude Code's resolver and the walk's emit. It does not establish runtime behaviour through a real symlinked directory, and I did not run it.

The mechanism is right. Claude Code resolves `path.resolve(dirname(realpath(importer)), name.trim())`: `Ye` at offset 205304326, called as `reo(G,s)` with `s` = the resolved path from `kOe(e,n,he,...)` → `ZMe(h,e,n,r)`. The walk is also lexical (`:531`). But because both sides collapse `..` before any file is opened, the walk lists exactly what Claude Code reads here, so this is not an exception to the superset claim this comment states. The kernel only matters to a resolver that leaves the `..` in place, and neither one does. "Row 350" does not name its file; it is `docs/reviews/override-log.md:350`. The comment's assertion that Claude Code resolves lexically also leaves A5's "Untraced against Claude Code ... whether an `@` token's `..` after a directory link resolves through the link" (`known-issues-dev-cycle.md:18`) out of date. The same binary passage also answers A5's other untraced item: imports resolve from the target's directory.

**Evidence:** `scripts/lib/dev-cycle-read.sh:511-512,531`, claude.exe offsets 205304326 and 212107518, `docs/reviews/override-log.md:350`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 12: superset comment, failure modes: "It returns 1 when sed, python3 or awk fails, when ROOT_REAL is empty, or when the candidates and comment splices run past a work bound"

**Location:** `scripts/lib/dev-cycle-read.sh:515-517`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed cause. It does not establish behaviour when `printf` into the final pipe fails (the status is awk's without pipefail).

`toks="$(env LC_ALL=C sed "${s[@]}")" || return 1` (`:568`), `d="$(... | python3 -I -c ...)" || return 1` (`:574`), and `... awk "$IMPORT_AWK" || return 1` (`:580`). The BEGIN block runs `if (root == "") exit 2` (`:561`). splice charges its copying: `work += length(r); if (work > 50000000) exit 3` (`:555`). Executed (`probes.log`): empty ROOT_REAL gives rc=1; no python3 on PATH gives rc=1 for non-ASCII text; a python3 that exits 3 gives rc=1; six 4200-byte runs give rc=1; 320,000 comments give rc=1 in 0.22 s. The python3 cause applies only to text holding a byte above 0x7f; ASCII text never forks python3 (no-python3 run: rc=0 with the normal candidates).

**Evidence:** `scripts/lib/dev-cycle-read.sh:555,561,568,573-580`, `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 13: emit comment "Claude Code trims the name (an escaped space can lead it)"

**Location:** `scripts/lib/dev-cycle-read.sh:525`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers Claude Code's `Ye` trim and its `reo` filter as transcribed. It does not establish behaviour beyond that transcription (I did not run Bun).

Claude Code does trim, in its resolver: `let n=e.trim()` (offset 205304326). But `reo` filters each name before it reaches the resolver: `H.startsWith("./")||H.startsWith("~/")||H.startsWith("/")&&H!=="/"||!H.startsWith("@")&&!H.match(/^[#%^&*()]+/)&&H.match(/^[a-zA-Z0-9._-]/)` (offset 212107518). A name led by a space (from `@\ docs/x.md`) fails every branch and is never imported. My node transcription of that filter (`reo.js`, `probes.log`) prints `REJECTED:" docs/lead.md"`. A trailing escaped space is trimmed (`@docs/x.md\ ` → `/r/docs/x.md`), but that name is already a prefix the walk emits without the trim. So the trim in emit only adds over-read. The comment's parenthetical suggests a leading escaped space is a case Claude Code reads, and it is not.

**Evidence:** `scripts/lib/dev-cycle-read.sh:525`, claude.exe offsets 205304326 and 212107518, `/tmp/u2a3bfcL2i2-NgQD/reo.js`, `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 14: BEGIN block: a ROOT_REAL of "/" keeps every path, an empty ROOT_REAL fails, and the `pre`/length test drops the root itself

**Location:** `scripts/lib/dev-cycle-read.sh:561,535`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three behaviours. It does not establish that the `length(out) <= length(pre)` conjunct does any work, and it does not: it is dead code (see below).

`BEGIN { dir = ENVIRON["IT_DIR"]; root = ENVIRON["IT_ROOT"]; pre = (root == "/") ? "/" : root "/"; if (root == "") exit 2 }` (`:561`). Executed (`probes.log`): root `/` lists `etc/x.md` and every other path, and drops `@/`; root empty gives rc=1; root `/r` drops `@/r` and `@/r/`. The root itself is dropped by `index(out, pre) != 1` alone. `out` is either "" or "/"-joined non-empty parts with no trailing slash, so it never equals `pre`, and the length conjunct never decides anything.

**Evidence:** `scripts/lib/dev-cycle-read.sh:534-536,561`, `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 15: decode comment "python3's 'replace' decoding matched Claude Code's byte for byte: U2a3b L2 security F1"

**Location:** `scripts/lib/dev-cycle-read.sh:569-572`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers python3's decoder against Node's `Buffer.toString("utf8")`. It does not establish equality with Bun's decoder, which Claude Code actually runs.

Claude Code decodes as UTF-8: `Buffer.from(...).toString("utf8")` in `teo` (offset ~212105900), and per the security report its file read is `readFile(path, {encoding:"utf8"})`. I generated 20,000 random byte strings (overlongs, surrogates, truncated sequences, out-of-range leads). python3's `decode("utf-8","replace").encode()` and node v22's `Buffer.toString("utf8")` were identical on all of them (`cmp` exit 0; `/tmp/u2a3bfcL2i2-dxgr/{py,node}.txt`). The cited critic ran node too: "node standing in for Bun's decoder" and "That Bun's decoder replaces invalid bytes the same way is reasoned, not run" (`security-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md:13,44`). `BUN_BE_BUN=1 claude.exe` starts Claude Code itself here as well, so Bun could not be run. "Matched Claude Code's" therefore means it matched Node's decoder.

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-575`, `docs/reviews/security-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md:13,44`, `/tmp/u2a3bfcL2i2-dxgr/py.txt`, `/tmp/u2a3bfcL2i2-dxgr/node.txt`

---

## Claim 16: "LC_ALL=C above makes the byte range a byte test."

**Location:** `scripts/lib/dev-cycle-read.sh:572` (with `local ... LC_ALL=C` at `:564`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `[[ ... == *[$'\x80'-$'\xff']* ]]` test with and without the local guard under C and C.utf8. It does not cover other installed UTF-8 locales (none are installed here).

A function with `local LC_ALL=C` matched every input holding a byte above 0x7f (`\xff`, é, €, 😀, U+FFFD) and did not match ASCII. The unguarded function matched the same set under C and C.utf8 (`probes.log`, LC_ALL guard section). The guard works, and it is redundant in the locales available here, as the commit says (Claim 38b).

**Evidence:** `scripts/lib/dev-cycle-read.sh:564,572-573`, `/tmp/u2a3bfcL2i2-NgQD/lc.sh`, `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 17: "dir and root go through the environment: awk -v would read backslash escapes in them."

**Location:** `scripts/lib/dev-cycle-read.sh:579`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk (the installed awk, `/usr/bin/mawk`). It does not cover other awks' `-v` handling (POSIX also specifies escape processing).

`env LC_ALL=C IT_DIR="$1" IT_ROOT="$ROOT_REAL" awk "$IMPORT_AWK"` (`:580`). The backslash-directory test (`docs/a\tb`) fails at be94c871, which used `-v` (want `docs/a\tb/z.md: imported`, got `-`; `old-fails.log`), and passes at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:579-580`, `test/scripts/build-loop-check.bats:504-513`, `/tmp/u2a3bfcL2i2-NgQD/old-fails.log`

---

## Claim 18: "Claude Code skips a file over 4 MiB, so reading only its start over-reads at worst, and a huge file a prefix candidate names cannot stall the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:614-616`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk's read and Claude Code's size test. It does not cover the main walk, which still reads blobs whole (the commit says so), or a file that changes size between Claude Code's read and the walk's.

Claude Code: `nH=4194304`; `teo` reads `length:nH+1` and `if(s.totalBytes>nH)return{kind:"skipped",...}`; `kOe` logs `skipping ${e}: not a regular file or exceeds ${nH} byte limit` (offset ~212105900). The limit is in bytes. The walk: `out="$(head -c 4194305 -- "$f" | import_targets "$d")"` (`:616`). head cuts only a file larger than 4194305 bytes, and every such file is over 4194304 bytes, so Claude Code skips it entirely. A file of up to 4 MiB is read whole. The answer to the partial-last-line question is therefore yes, the claim holds. When the cap cuts a line, that line (and any trailing partial UTF-8 sequence, which python3 decodes to U+FFFD) comes from a file Claude Code never loads, so every name it yields is an over-read, never a miss. The stall half: the mutant without `head` times out (status 124) on the sparse 300 MB test, and HEAD passes (`mutants.log`, re-run output in-session).

**Evidence:** `scripts/lib/dev-cycle-read.sh:614-616`, claude.exe offset ~212105900, `test/scripts/build-loop-check.bats:562-569`, `/tmp/u2a3bfcL2i2-NgQD/mutants.log`

---

## Claim 19: "One lower per file, not per candidate, as in imported_names", with IMPORTED_MAIN's contents unchanged by the hoist

**Location:** `scripts/lib/dev-cycle-read.sh:695-696`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the clone at 98e3b1df and reasoning over the loop. It does not cover a lower failure part way through a file, which failed differently before (there is no partial list either way, because the walk fails).

`i="$(lower "$out")" ...; IMPORTED_MAIN+="$i"$'\n'` (`:696`) mirrors `:620`. Before the hoist, each non-empty `p` was lowered and appended, seen or not. awk never prints an empty line, and the symlink arm's `out` is one path, so the concatenation is the same string. Executed: `main_imports` with HEAD's lib and with a de-hoisted copy (`lib-nohoist.sh`) gave the same IMPORTED_MAIN, sha256 `c5670e98...a10c`, 65 lines (`probes.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:693-707`, `/tmp/u2a3bfcL2i2-NgQD/lib-nohoist.sh`, `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 20: "git stores nothing at .git, so a prefix candidate there (from @.gitignore) names no file main has."

**Location:** `scripts/lib/dev-cycle-read.sh:702-703`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the top-level `.git` and `.git/*` candidates. It does not cover a nested `sub/.git` (a submodule's gitfile or a nested repo) reached from `@sub/.gitignore`, which still fails the walk; the general prefix-meets-checkout-file rule is routed to U2a3c.

git refuses to track any path with a `.git` component, so main's tree never holds one (paraphrased; no quote available because this is git's path validation, not repo code). The skip `[[ "$p" != .git && "$p" != .git/* ]] || continue` sits after the `ent` lookup (`:701`), so it only affects names main lacks. The linked-worktree test passes at HEAD, and the mutant without the skip fails (`mutants.log`: m-git).

**Evidence:** `scripts/lib/dev-cycle-read.sh:697-707`, `test/scripts/build-loop-check.bats:389-396`, `/tmp/u2a3bfcL2i2-NgQD/mutants.log`

---

## Claim 21: superset test comment "A name holding _ before a code span, <br> or emphasis is still read (my_notes); two NBSPs on a line both become blanks; an HTML block's comment splices a name (sec+ret); an escaped space and an absolute path inside the repo are imports."

**Location:** `test/scripts/build-loop-check.bats:341-344`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the escaped-space and absolute cases against the `reo` transcription and the walks. It does not re-derive the Markdown-shape cases against the lexer.

Transcription: `See @docs/my\ notes.md` resolves to `/r/docs/my notes.md` (`probes.log`). An absolute in-repo name passes `H.startsWith("/")&&H!=="/"`. The test passes at HEAD. "(my_notes)" names only the code-span instance; `s_g` and `k_l` cover `<br>` and emphasis.

**Evidence:** `test/scripts/build-loop-check.bats:339-363`, `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 22: over-read test comment "Claude Code 2.1.292 reads neither docs/mail.md nor docs/pre.md ... The code-span and fence cases were already read before the decision."

**Location:** `test/scripts/build-loop-check.bats:366-369`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two names against the transcription and the pre-decision parser (47a00c46). It does not establish the lexer's tokenization independently.

The transcribed regex `(?:^|\s)@((?:[^\s\\]|\\ )+)` needs a blank or the start before `@`, so `user@docs/mail.md` gives nothing. The run `@docs/pre.md.bak` gives `/r/docs/pre.md.bak` only (`probes.log`). 47a00c46's lib on the same input lists `docs/span.md` and `docs/fence.md` but not mail or pre; 98e3b1df lists all four (in-session run of `lib-47a.sh`).

**Evidence:** `test/scripts/build-loop-check.bats:365-388`, claude.exe offset 212107518, `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 23: "Seven 4200-byte runs after an @ pass the candidate-work bound (each prefix's length is charged; the sixth run trips it): the parser returns 1."

**Location:** `test/scripts/build-loop-check.bats:381-387`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic and the status. It does not cover the decoded-copy path (the input is ASCII).

Per run, 4200·4201/2 = 8,822,100 is charged. Five runs total 44,110,500 (under 50,000,000) and six total 52,932,600 (python3 arithmetic). Executed: five runs give rc=0, six give rc=1 (`probes.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:524`, `test/scripts/build-loop-check.bats:381-387`, `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 24: test name "the main walk reads a linked worktree whose instruction file names @.gitignore: a .git prefix candidate is skipped"

**Location:** `test/scripts/build-loop-check.bats:389`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the linked-worktree `.git` file case. It does not cover nested `.git` (Claim 20).

The test passes at HEAD and fails on the m-git mutant (`mutants.log`).

**Evidence:** `test/scripts/build-loop-check.bats:389-396`, `/tmp/u2a3bfcL2i2-NgQD/mutants.log`

---

## Claim 25: test name "both walks fail once the parser has printed more than IMPORT_OUT_MAX bytes in all"

**Location:** `test/scripts/build-loop-check.bats:398`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' checks. It does not cover the character-versus-byte difference (Claim 7).

The test passes at HEAD and fails on each single-walk mutant (m-outtree, m-outmain).

**Evidence:** `test/scripts/build-loop-check.bats:398-404`, `/tmp/u2a3bfcL2i2-NgQD/mutants.log`

---

## Claim 26: "The four superset holes the L2 fact-check executed against the Claude Code 2.1.292 harness (Claim 1). Each FAILS at be94c871 and passes once its hole is closed"

**Location:** `test/scripts/build-loop-check.bats:478-480`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four hole tests at be94c871 and HEAD. It does not re-check them against Claude Code.

See Claim 27.

**Evidence:** `test/scripts/build-loop-check.bats:478-524`, `/tmp/u2a3bfcL2i2-NgQD/old-fails.log`

---

## Claim 27: every "(FAILS at be94c871 ...)" test name still fails at be94c871

**Location:** `test/scripts/build-loop-check.bats:481,493,504,515,543`; `test/scripts/dev-cycle.bats:1059`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six tagged tests with HEAD's test files over be94c871's lib and dev-cycle.sh. It does not establish the untagged tests' status at be94c871.

Command: `TMPDIR=$t timeout 600 bats -f 'FAILS at be94c871' test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats` in `/tmp/u2a3bfcL2i2-NgQD/old`, exit 1, 08:08:30Z to 08:08:42Z (`old-fails.log`). All six are `not ok`, each for its behaviour, not for stderr noise. Re-entry, absolute spellings, backslash dir and long name each report `walk: ok` with the target `-`. The comments test reports `rc=124`. dev-cycle.bats prints `ok docs/notes.md` (a real fail-open, not the wording change). All six pass at HEAD (`suites.log`).

**Evidence:** `/tmp/u2a3bfcL2i2-NgQD/old-fails.log`, `/tmp/u2a3bfcL2i2-NgQD/suites.log`

---

## Claim 28: "mawk reads escape sequences in a -v value: dir a\tb became a<TAB>b."

**Location:** `test/scripts/build-loop-check.bats:505`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the installed awk. It does not cover gawk.

`readlink -f "$(command -v awk)"` gives `/usr/bin/mawk`, and the test fails at be94c871 (Claim 27).

**Evidence:** `test/scripts/build-loop-check.bats:504-513`, `/tmp/u2a3bfcL2i2-NgQD/old-fails.log`

---

## Claim 29: "Claude Code 2.1.292 (harness) reads docs/abc.md (HTML block, comments removed), docs/cs.md (text between two code spans) and docs/dot.md; it never reads 'docs/a.md x'."

**Location:** `test/scripts/build-loop-check.bats:527-528`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers reasoning from `reo`'s html branch (`w.replace(/<!--[\s\S]*?-->/g,"")`, offset 212107518) and its `./` filter. It does not run marked's lexer.

Line 1 starts with `<!--`, so it is an HTML block, and removing its comments leaves ` @docs/abc.md`. The `cs` line is a paragraph whose text token holds ` @docs/cs.md `. `@./docs/dot.md` passes `H.startsWith("./")`. In `@docs/a.md x` the run ends at the blank. The test passes at HEAD; at be94c871 it also passes (it is a pin, not tagged FAILS).

**Evidence:** `test/scripts/build-loop-check.bats:526-541`, claude.exe offset 212107518

---

## Claim 30: comments test: "320,000 comments in one 2.24 MB line took 27 s with status 0 at be94c871" and test name "(...; about 10 s)"

**Location:** `test/scripts/build-loop-check.bats:543-545`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both timings on this host. It does not establish them under load.

`bash time.sh` (60 s timeout): be94c871 took 27,702 ms with rc=0, and HEAD took 224 ms with rc=1. The input is 2,240,001 bytes (`probes.log`). The 27 s claim holds. "About 10 s" is the test's runtime at be94c871, where it hits `timeout 10`; at HEAD the parser call takes about 0.2 s. A reader can take the name as the test's normal cost, so it should say "about 10 s at be94c871".

**Evidence:** `test/scripts/build-loop-check.bats:543-550`, `/tmp/u2a3bfcL2i2-NgQD/probes.log`, `/tmp/u2a3bfcL2i2-NgQD/time.sh`

---

## Claim 31a: test name "both walks read a name as Claude Code decodes it: an invalid UTF-8 byte is U+FFFD"

**Location:** `test/scripts/build-loop-check.bats:552`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the U+FFFD half, with Node standing in for Bun (Claim 15).

It passes at HEAD and fails on the no-decode mutant (`mutants.log`: m-decode).

**Evidence:** `test/scripts/build-loop-check.bats:552-560`, `/tmp/u2a3bfcL2i2-NgQD/mutants.log`

---

## Claim 31b: same test name, "...; a leading escaped space is trimmed", framed as what Claude Code reads (`want docs/lead.md imported`)

**Location:** `test/scripts/build-loop-check.bats:552,557`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers Claude Code's `reo` filter as transcribed. It does not establish Bun-run behaviour.

`@\ docs/lead.md` gives the name ` docs/lead.md`, which `reo`'s filter rejects before `Ye` trims anything (Claim 13; `REJECTED:" docs/lead.md"`). Claude Code 2.1.292 does not import docs/lead.md. The test pins an over-read inside a test titled "as Claude Code decodes it", and the trim mutant fails it (`mutants.log`: m-trim). That makes an over-read look like a superset requirement, so a later, more precise parser would be told it broke the superset. The behaviour is fail-safe; only the label is wrong. Compare the over-read test's own convention (`:366-368`), which marks over-reads as deletable on purpose.

**Evidence:** `test/scripts/build-loop-check.bats:552-560`, claude.exe offset 212107518, `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 32: "An untracked sparse 300 MB file at the prefix "big": read whole, the walk stalls."

**Location:** `test/scripts/build-loop-check.bats:564`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-head mutant under the test's 20 s timeout.

The mutant's run printed `124` (timeout) where `ok\nearly` was expected; HEAD passes.

**Evidence:** `test/scripts/build-loop-check.bats:562-569`, `/tmp/u2a3bfcL2i2-NgQD/mutants.log`

---

## Claim 33: dev-cycle.bats "--check-fix refuses a doc imported through the repo's parent directory, as main did"

**Location:** `test/scripts/dev-cycle.bats:1059`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main, be94c871 and HEAD on the parent re-entry case.

main prints `skip ... imports it with @`, be94c871 prints `ok`, HEAD prints `skip ... names it after an @` (Claim 5).

**Evidence:** `test/scripts/dev-cycle.bats:1059-1064`, `/tmp/u2a3bfcL2i2-NgQD/old-fails.log`

---

## Claim 34: dev-cycle.bats "--check-fix refuses a doc imported through a name Claude Code decodes with U+FFFD"

**Location:** `test/scripts/dev-cycle.bats:1066`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk through --check-fix, with Node standing in for Bun.

It passes at HEAD and fails on m-decode (`mutants.log`).

**Evidence:** `test/scripts/dev-cycle.bats:1066-1071`, `/tmp/u2a3bfcL2i2-NgQD/mutants.log`

---

## Claim 35: commit dd51e9a7 "Tests: test-strategy Appendix A (6, failing at be94c871) ... Each new test fails on its mutant."

**Location:** commit dd51e9a7 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Appendix A tests at be94c871 and the mutants I ran (.git skip, both OUT_MAX checks, splice bound). It does not cover a mutant for the ENVIRON change or for the absolute-space rewrite (those are covered by the be94c871 runs instead).

Appendix A has 7 tests (`test-strategy-review-2026-10-06-L2-build-loop-u2a3b.md:57,72,80,88`), and all 7 landed. Six fail at be94c871; the splice-pieces test passes there (`ok 5` in the be94c871 run of the untagged tests). The mutants I ran all fail their tests (`mutants.log`).

**Evidence:** `docs/reviews/test-strategy-review-2026-10-06-L2-build-loop-u2a3b.md:57-90`, `/tmp/u2a3bfcL2i2-NgQD/old-fails.log`, `/tmp/u2a3bfcL2i2-NgQD/mutants.log`

---

## Claim 36a: commit dd51e9a7 counts "130/130", "486 changed code lines against main (350 at be94c871)", "--check-fix over 941 tracked docs/*.md and README.md: identical to main"

**Location:** commit dd51e9a7 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts with pr-prep 1a's command against origin/main (b5eadbd8). It does not cover a different base.

The five suites at dd51e9a7 gave `1..130`, 130 ok (`suites-dd.log`). `git diff --numstat origin/main...<c> -- . ':!docs'` summed to 350 (be94c871), 486 (dd51e9a7) and 525 (98e3b1df). `git ls-tree -r` lists 941 `.md` files under docs plus README.md at dd51e9a7, and the outputs are identical to main (Claim 4).

**Evidence:** `/tmp/u2a3bfcL2i2-NgQD/suites-dd.log`, `/tmp/u2a3bfcL2i2-NgQD/cf.log`

---

## Claim 36b: commit dd51e9a7 "3.4 s against main's 4.0 s"

**Location:** commit dd51e9a7 message
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers three interleaved runs on this host in the worktree. It does not establish the original session's load; timings vary over time.

`cfdd.sh` (read-only, worktree, 942 paths, three interleaved rounds): dd51e9a7 took 2657/2614/2668 ms, main 2573/2470/2487 ms, HEAD (98e3b1df) 3172/3102/3080 ms (`cfdd.log`). Under equal conditions dd51e9a7 is slightly slower than main, not 15% faster. HEAD is about 0.5 s slower again, which matches the python3 decode forks for non-ASCII instruction files (an observation for the performance critic, not a claim in range).

**Evidence:** `/tmp/u2a3bfcL2i2-NgQD/cfdd.sh`, `/tmp/u2a3bfcL2i2-NgQD/cfdd.log`

---

## Claim 37: commit dd51e9a7 "import_targets returns 1, not awk's 3 or 2 ... A root of / keeps every path; an empty root fails"

**Location:** commit dd51e9a7 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claims 12 and 14.

See Claims 12 and 14 (`probes.log`).

**Evidence:** `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 38a: commit 98e3b1df "133/133 ... unit at 525 changed code lines against main, under Q-104 [2]'s ~800 tolerance ... python3 is already a dependency (questions.sh)"

**Location:** commit 98e3b1df message
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts, Q-104's option text and questions.sh's use of python3. It does not establish that every install path provides python3.

133/133 (`suites.log`); 525 (Claim 36a). Q-104 [2] reads "growth up to ~800 lines is tolerated" (questions-archive at b5eadbd8). `scripts/questions.sh:242` runs `python3 -c '... .decode("utf-8")'` in `check`, so python3 is a dependency of that subcommand.

**Evidence:** `/tmp/u2a3bfcL2i2-NgQD/suites.log`, `scripts/questions.sh:242`

---

## Claim 38b: commit 98e3b1df "Each fails on its mutant; the LC_ALL=C guard's mutant survives (defence in depth: bash's range also matches under C.utf8)"

**Location:** commit 98e3b1df message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the decode, trim and head mutants and the guard under C.utf8.

m-decode, m-trim and m-head fail their tests (`mutants.log`). Unguarded matching under C.utf8 equals guarded matching (Claim 16).

**Evidence:** `/tmp/u2a3bfcL2i2-NgQD/mutants.log`, `/tmp/u2a3bfcL2i2-NgQD/probes.log`

---

## Claim 38c: commit 98e3b1df "--check-fix over 941 docs identical to main" and "(the critic matched it byte for byte against Claude Code's decoder)"

**Location:** commit 98e3b1df message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the path count at this commit and the decoder provenance.

This commit adds a report under docs/reviews, so 98e3b1df holds 942 such paths, not 941; the output is identical to main over all 942 (`cf.log`). The critic matched Node's decoder, not Bun's (Claim 15). The message's "a leading escaped space is trimmed" is accurate about emit, but see Claim 31b for what Claude Code does with that name.

**Evidence:** `/tmp/u2a3bfcL2i2-NgQD/cf.log`, `docs/reviews/security-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md:44`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:497,510-513`): the "one statement" of the superset leaves out `@~/<path into the repo>`. Claude Code joins it to homedir and imports it when it lies in the project, but emit drops every `~/` name, so a repo under `$HOME` has an unlisted hole. Name it as a known exception (or resolve `~/` against `$HOME`).
- **Claim 31b** (`test/scripts/build-loop-check.bats:552,557`): `@\ docs/lead.md` is not a Claude Code import (`reo`'s filter rejects a leading space), so the trim case is an over-read pinned under an "as Claude Code decodes it" title. Relabel it as an over-read (or drop the trim, which never widens the superset).
- **Claim 36b** (commit dd51e9a7): "3.4 s against main's 4.0 s" is not reproduced. Interleaved runs show dd51e9a7 ≈2.65 s against main ≈2.5 s, and HEAD ≈3.1 s.

### Mostly Accurate
- **Claim 2** (A5): the regex was transcribed, not extracted, and U2a2's harness was a 27-line differential, not a fuzzer.
- **Claim 7** (`:482-485`): the walk fails past ("more than") the limit, and the count is in characters; about 2 KB holds for a fresh worktree, while /workspace's own tree walk prints 5.7 KB.
- **Claim 11** (`:511-512`): with both resolvers lexical, the `..`-after-a-link case is not a superset exception. "Row 350" does not name override-log, and A5's two "untraced" items are answered by the same binary passage.
- **Claim 13** (`:525`): Claude Code trims only names that already passed its filter, so the parenthetical's leading-space case is never imported.
- **Claim 15** (`:569-572`): python3 matched Node's decoder (20,000 cases), not Bun's.
- **Claim 30** (`build-loop-check.bats:543`): "about 10 s" is the runtime at be94c871; at HEAD the parser takes about 0.2 s.
- **Claim 35** (dd51e9a7): Appendix A has 7 tests, of which 6 fail at be94c871.
- **Claim 38c** (98e3b1df): 942 paths at this commit; the decoder was matched against Node's.

### Unverifiable
- None. (Residue: Bun's own UTF-8 decoder was not run; `BUN_BE_BUN=1` starts Claude Code instead.)

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 98e3b1df` line at the top.
- **Answered:** every brief item 1-9 (Claims 7-20 for the lib comments and walks, 4-6 for the help, skip line and skill, 1-3 for A5 and F11, 21-34 for the tests, 35-38c for the commits). Item 4's partial-line question: the cap only cuts files Claude Code skips, so a partial last line yields over-reads only (Claim 18). Suites: 133/133 at 98e3b1df and 130/130 at dd51e9a7.
- **Fix-drift on iteration-1 dispositions:** L2-R1, A1, A3, A4, A5, A6, C1, C2, C3 and C5 hold as the rubric describes them. Where it applies, each mutant fails its test, and each FAILS test fails at be94c871. L2-A2's premise ("so `@\ docs/x.md` loads docs/x.md") does not hold against the binary's `reo` filter (Claims 13, 31b). The fix is harmless (over-read only) but rests on a wrong premise. L2-C3's single statement omits the `~/` residue (Claim 9).
- **Out of scope:** performance and security judgement of the python3 fork cost (Claim 36b notes ≈0.5 s over dd51e9a7 on 942 paths), and the nested-`.git` rule routed to U2a3c.
- **Escalate:** none blocking. Claim 9 is a stated-invariant gap (Medium confidence) that a for-author fix closes in one comment line or one emit rule.
- **Questions I would have asked:** whether a repo under `$HOME` is in scope for the superset (the gate runs in fresh worktrees whose location the user picks).
- **Decisions I made:** I used the installed claude.exe strings as the oracle (offsets cited) and Node in place of Bun. I kept execution logs in `/tmp/u2a3bfcL2i2-NgQD/` rather than `docs/reviews/execution-logs/`, per the no-other-files rule. No new hallucination-pattern entry: none of the Incorrect verdicts claims a symbol that does not exist.
