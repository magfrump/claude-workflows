Commit: 98e3b1df

# Security Review — feat/build-loop-u2a3b (loop 2, iteration 2: the fixes for iteration 1)

**Scope:** `git diff be94c871..98e3b1df -- . ':!docs/reviews'` (dd51e9a7, 98e3b1df), reviewed from `git archive 98e3b1df` and `git archive be94c871` copies in `/tmp/u2a3bsecL2i2-bFas/{src,old}`. I read `IMPORT_AWK` (emit, scan, splice, BEGIN) and `import_targets` in full (`scripts/lib/dev-cycle-read.sh:493-581`), along with `imported_names` (`:596-624`), `main_imports` (`:638-710`), `blocker`/`inrepo_here` (`:112-129`) and `need_root` (`:96-100`). The rest of the branch (`main...98e3b1df`) was context only.
**Date:** 2026-10-07
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i2.md` (Stage 1: 42 claims; Incorrect: 9, 31b, 36b), the "Loop 2, iteration 1 of 3" triage in `code-review-rubric-2026-10-06-feat-build-loop-u2a3b.md`, the iteration-1 report `security-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md`, and override-log rows 350 and 403-424.

**Threat model (from the brief).** `import_targets` has to read a superset of the names Claude Code 2.1.292 can import. A fail-open is a file Claude Code loads as instructions that a walk does not list: `--check-fix` then prints `ok` (tree walk), or the U2a4 floor passes it (main walk). Over-reading only over-refuses.

**Method.**
- **Oracle.** I reused the prior harness `/tmp/u2a3bsecL2r-KlOU` (its extracted `marked.js` lexer and the `reo` transcription `cc.js`). Its transcription skips `~/` names (`if(n.startsWith('~/')||n==='~')continue`), so I wrote `cc2.js`. It replaces that skip with the shipped resolver `Ye` (binary offset 205304326): `if(n==="~")return Hn(c());if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)))`, where `c` is `os.homedir`, `b` is `path.join`, and `Hn` is the identity on this build (`function Hn(t){return t}`, offset 203416965). It then applies the include walk's in-project test. That test is `AD(Pe)`, i.e. `Pd(e, originalCwd)`, a lexical containment check with case folding on by default (offset 208012798). The harness takes cwd to be the repo root.
- **Generator.** `gen3.js` adds 13 fragments for `~/` and HOME-relative spellings: `~/<home→root>/name`, `~//`, `~/./`, `~/x/../`, `~/../`, `~/…#frag`, `@\ ~/`, a trailing `\ `, `~`, `~x/` and `./~/`. They are mixed with blanks, code spans, comments, NBSP, `\xff` and indentation. The prior `gen2.js` (84 fragments) was re-run on HEAD as a regression check.
- **Scenarios.** Root `/tmp/u2a3bsecL2i2-bFas/home/u/proj`, with HOME set to an ancestor of the root, the root itself, `/`, a directory inside the root, empty, unset, relative, and a symlinked alias of the ancestor.
- **End to end.** I built `git init` fixtures with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` and ran `main_imports`, `imported_names` and `isimported` through the lib exactly as `imps` in `build-loop-check.bats` does.
- **Candidate patch.** I applied it to a full-tree copy (`fixrepo/`) and ran `build-loop-check.bats` and `dev-cycle.bats` with `TMPDIR=/tmp/u2a3bsecL2i2T-K4PX`. All 110 of 110 passed.
- **Cleanup.** Everything ran under `timeout`, and no process of mine is left running. The bats processes under `/tmp/u2a3btsL2i2-*` belong to another agent. I left them alone.

## Trust Boundary Map

```
B1: [instruction / imported file bytes in the checkout (S1)] → [head -c 4194305 → import_targets: sed blanks → python3 -I U+FFFD copy → IMPORT_AWK scan/splice/emit] → [IMPORTED → --check-fix]
B2: [main's blobs (S2)]                                     → [git cat-file | import_targets (shared)]                                                         → [IMPORTED_MAIN → U2a4 floor]
B3: [Claude Code 2.1.292 loader (S5): UTF-8 decode → marked → reo → Ye (~/ joined to os.homedir) → AD/EF]  ⊆? [candidate set from B1/B2]                 → [fail-open iff not a superset]
B4: [HOME / ROOT_REAL / importer dir (S3)]                  → [env IT_DIR IT_ROOT → awk ENVIRON] (moved: was awk -v)                                           → [emit's absolute resolution and root test]
B5: [checkout files main lacks, incl. $GIT_DIR contents (S4)] → [main_imports' per-candidate checkout test; .git skip (new)]                                   → [walk ok vs walk failed]
```

| Label | Source | Mutability | Trust, by sink class |
|---|---|---|---|
| S1 | Bytes of every instruction file and imported file in the checkout | runtime-mutable (any commit, or any same-uid process writing an untracked file) | UNTRUSTED toward the imported/not-imported decision, toward which files the walk reads, and toward path lookups |
| S2 | main's committed blobs | runtime-mutable at every merge | As S1 (reviewed once, but "an @ anywhere" counts, so prose a reviewer passes is still parsed) |
| S3 | `HOME`, `ROOT_REAL`, the importer's directory | process environment / the repo's location (deploy-time per session) | Trusted toward exec (they reach no exec). Toward the superset decision, HOME is the gate's value, which **need not equal the Claude Code session's** HOME |
| S4 | Files in the gate checkout that main lacks, including everything under `.git/` | runtime-mutable (any same-uid process; `.git/` is never reviewed) | UNTRUSTED: content no review has seen, read by Claude Code if imported |
| S5 | Claude Code 2.1.292's loader | external, version-dependent | The reference, transcribed from the shipped bytes (node in place of Bun) |

The fixes move B4 from `awk -v` to ENVIRON (cleared below). They add a decode stage to B1 (cleared) and a `.git` exemption to B5's fail-closed test (Finding 2). The superset claim is still missing one whole spelling class at B3, `~/` (Finding 1).

## Findings

#### 1. `@~/<path into the repo>` is a Claude Code import that both walks drop, whatever HOME is. The single statement of the superset claim does not list it as an exception.

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:526` (emit), `:510` (the statement), `:450` (imported_names' header)
**Boundary:** B3, B1→B5, B2
**Move:** 11 (enumerate bypasses for the guardrail), 1 (S3 classification)
**Confidence:** High for the mechanism (executed against the transcription). Medium for exposure: /workspace is not under HOME=/home/node, so it is not live in this deployment.
**Legibility-target:** for-author
**Executed vs reasoned:** executed (fuzz, end-to-end probe of the candidate patch). That Bun's `os.homedir()` reads HOME as Node's does is reasoned.

Evidence (verbatim):

```awk
  sub(/^ +/, "", c); sub(/ +$/, "", c)  # Claude Code trims the name (an escaped space can lead it)
  if (c == "" || substr(c, 1, 2) == "~/") return
```
(excerpt from emit, `:525-526`; emit continues to `:538`, all read). Claude Code's `reo` admits `H.startsWith("~/")`, and `Ye` returns `path.join(os.homedir(), rest)` (offset 205304326). The include loop keeps the result when `AD(Pe)` puts it inside the session's cwd: `for(let Pe of Ce){if(!AD(Pe)&&!z)continue; … EF(Pe,…)}`.

I fuzzed 300 to 600 documents per scenario with `gen3.js` at HEAD. With HOME an ancestor of the root, Claude Code resolves 328 names, and the parser misses 325 of them in 239 documents. Every miss is a `~/` spelling. The results were the same with HOME equal to the root, HOME = `/` (where `~/tmp/…/proj/docs/a.md` is the spelling) and HOME inside the root (`~/../docs/a.md`). With HOME empty, Node's `homedir()` returns `""` (executed), so `join("", "docs/x.md")` is the relative `docs/x.md`, and Claude Code resolves it against its cwd. That case also missed every name. So the hole does not depend on how HOME relates to ROOT_REAL. The parser never reads a `~/` name. The fact-check (Claim 9) found the same with one probe. The fuzz extends it to every HOME placement.

How to exploit it: in any repo under its user's home (the common layout, `~/code/proj`), an instruction file holds `See @~/code/proj/docs/ops.md`. Claude Code loads docs/ops.md and everything it imports as instructions. `--check-fix` prints `ok` for docs/ops.md, and the main walk does not list it. The line passes review as ordinary prose. The statement at `:510` reads "~/ names are dropped. Known exceptions: …" as if dropping them lost nothing.

**Recommendation:** resolve `~/` instead of dropping it. A tested candidate patch is in the Appendix: fuzz 0 misses in every scenario, 110/110 suites. Bound it this way:
- **HOME set and absolute.** Join it lexically (the existing `..` clamp is Node's `join` normalization), then apply the existing ROOT_REAL test. This covers HOME = `/`, HOME a path prefix of ROOT_REAL, HOME = ROOT_REAL, HOME below ROOT_REAL and string-prefix look-alikes (`/home/u/pro` against `/home/u/proj`), all fuzzed at 0 misses.
- **The real HOME too.** Also emit the `realpath -m` spelling of HOME. ROOT_REAL is a real path and HOME may be a symlinked alias of an ancestor; the alias probe found nothing without it and docs/a.md with it. This only over-reads: whether Claude Code reads that spelling depends on whether `originalCwd` is logical, and AD is lexical.
- **HOME unset.** Use the passwd entry (`getent passwd "$(id -u)"`), as Node does (executed: `/home/node`).
- **HOME empty or relative.** Claude Code then resolves against its own cwd, which the gate cannot know, so fail closed (`exit 4`, so `return 1`), and only when a `~/` candidate actually appears.
- **Once per walk.** Compute HOME and its real path once per walk, not per file. The patch does it per call, which adds a `realpath` fork per file.

The residue to state in the comment is that the walk resolves against the **gate's** HOME. A Claude Code session started with a different HOME is not covered. If the gate and the sessions run as different users or in different containers, the comment should name that as an exception, or the walk should fail closed on any `~/` name.

#### 2. main_imports' `.git` exemption covers every `.git/*` path, not just the `.git` prefix candidate L2-A6 was about, which re-opens a fail-closed check. A file under `$GIT_DIR` that main's instruction file imports is no longer followed, and its imports drop out of the gate's list.

**Severity:** Medium (floor rule: a named mechanism, reachable when the gate runs in a checkout whose `.git` is a directory)
**Location:** `scripts/lib/dev-cycle-read.sh:702-703` (introduced by dd51e9a7). The header at `:466-469` still states the rule the skip waives.
**Boundary:** B5, B2
**Move:** 3 (error path), 11 (bypass of a guardrail), fix-drift on L2-A6
**Confidence:** High for the mechanism (executed at HEAD and at be94c871). Low for exposure today: U2a4's floor has not landed, A5 says the gate should run in a fresh worktree (whose `.git` is a file, where this cannot trigger), and a developer checkout already fails the walk on its ignored instruction files.
**Legibility-target:** for-author
**Executed vs reasoned:** executed. That Claude Code loads a `.md` under `.git/` is reasoned from the transcription: `AD(Pe)` and `EF` have no `.git` rule, and `f8n` passes `.md`.

Evidence (verbatim, `:701-706`; the enclosing read loop ends at `:707`):

```bash
      if [[ -n "${ent[$p]+set}" ]]; then queue+=("$p"); continue; fi
      # git stores nothing at .git, so a prefix candidate there (from @.gitignore) names no file main has.
      [[ "$p" != .git && "$p" != .git/* ]] || continue
      # Main lacks p: under a link or gitlink main stores, or in the checkout as anything but a plain directory, fail.
      c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }; done
      [[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }
```

Every `p` that reaches the skip is already a path main lacks (the `ent` line above it `continue`s otherwise). So "names no file main has" is true of every path the following check guards and does not tell `.git` apart. That check exists because the walk cannot follow checkout files. A file main lacks that the checkout holds fails the walk, so the floor refuses everything (header `:466-469`: "or that the checkout holds as anything but a plain directory … fail the walk").

Reproduction (`/tmp/u2a3bsecL2i2-bFas/gitfx`): main's CLAUDE.md holds `Team notes: @.git/notes.md`, docs/t.md is tracked, and the untracked `.git/notes.md` holds `Also read @../docs/t.md and @docs/t.md`. Claude Code resolves `@../docs/t.md` from `.git/` to `<root>/docs/t.md` (executed with `path.resolve`).

| lib | `main_imports` | `isimported main docs/t.md` |
|---|---|---|
| be94c871 | walk: failed | imported (refuses) |
| 98e3b1df | walk: ok | **-** (passes) |
| 98e3b1df with only `.git` exempt | walk: failed | imported |

The tree walk still lists docs/t.md, so `--check-fix` refuses. The hole is in the gate only. A normalised spelling reaches it too: `@sub/../.git/info/n.md`, with `.git/info/n.md` holding `@../../docs/t.md`, also gives walk ok and `docs/t.md: -` at HEAD. `$GIT_DIR` is the least-reviewed place in a checkout. Any same-uid process can write `.git/info/*` or `.git/*.md`, and no diff ever shows it.

**Recommendation:** exempt only the exact prefix candidate: `[[ "$p" != .git ]] || continue`. In a linked worktree `.git` is a file, so `.git` alone is what failed (L2-A6). `.git/x` there gives ENOTDIR and already passes `! -e`. In a primary checkout `.git` is a plain directory and passes the `-d` arm. With this change the gitfx fixture fails closed again, and the linked-worktree test ("a .git prefix candidate is skipped") still passes, along with all 110 tests in both suites. Reword the comment to say why only the exact name is safe: a linked worktree's `.git` is a gitdir pointer file, not instructions.

#### 3. The single statement of the superset claim also leaves out row 350's other residue and Claude Code's external-includes mode.

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:510-513`
**Boundary:** B3
**Move:** 2 (implicit assumption), 11
**Confidence:** Medium (read from the binary; not run in Claude Code)
**Legibility-target:** for-orchestrator-synthesis
**Executed vs reasoned:** reasoned (binary read). Not re-raised as a defect. Row 350 waived these shapes, and this only notes that L2-C3's "one statement" no longer points to them.

`:510-513` reads: "Known exceptions: a .. after a symlinked directory, which the kernel follows through the link while both Claude Code and this walk resolve it lexically (row 350), and any further decoding Claude Code may add (an entity, a percent escape)." Two classes the comment calls "the one statement" do not appear:
- **Case-insensitive checkouts.** Claude Code's containment test is case-folded (`Pd(e,n,{caseFold:r,…}={caseFold:!0})`, offset 208012798). On a case-insensitive filesystem, `@/WORKSPACE/docs/x.md` is in-project and readable, while emit's case-sensitive `index(out, pre)` drops it. A5 lists this. The statement does not.
- **External includes.** With `hasClaudeMdExternalIncludesApproved` (per-project, default `!1`; not set in `/home/node/.claude.json`), `z` bypasses both `AD` checks. Claude Code then follows imports out of the repo, and through symlinked aliases of it (`ro` realpaths, and `iH` accepts canonical links). Those outside files can import back into the repo, and the walk never reads them.

**Recommendation:** add both to the exceptions sentence, or point it to A5's "Not covered" list. Otherwise a reader of the one statement takes the claim as unconditional.

## Checked and cleared (no finding)

- **U+FFFD decode path (98e3b1df, `:569-576`).**
  - *Regression fuzz.* `gen2.js` seeds 11-13 (1,050 documents, 42 of them with Claude Code names holding `EF BF BD`) give 0 misses at HEAD. Iteration 1's F1 is fixed.
  - *Ordering.* sed blanks NUL and UNI_SPACES before python3 decodes. Claude Code decodes first and then matches `\s`. These agree because every UNI_SPACES lead byte (C2, E1, E2, E3, EF) is a non-continuation byte. A replacement never absorbs it, and decoding never creates a space byte sequence. The fuzz corpus puts `\xc2\xa0` and `\xe2\x80\x80` beside `\xff`, `\xc3` and `\xe2\x80`.
  - *Alignment.* The decoded copy is appended after a newline (`toks+=$'\n'"$d"`). awk reads one record per line, and a replacement never consumes `\n` (0x0A is not a continuation byte). So no candidate spans the join, and the per-line splice still sees each line whole.
  - *Skip conditions.* The copy is skipped only when no byte above 0x7f is present (nothing to decode) or when decoding changed nothing. The fact-check verified the `LC_ALL=C` byte test (Claim 16).
  - *Failures.* A missing or failing python3 returns 1 (Claim 12). `-I` drops PYTHON* variables, user site-packages and the script directory, so the only python3 trust is the same PATH trust as sed and awk.
  - *Big files.* A 4,194,304-byte file with `\xff` and `@docs/z.md` at its last bytes yields docs/z.md through the cap and the decoded copy (`cap.sh`, executed).
  - *Bun's decoder.* Still untested (below).
- **ENVIRON passing (`:580`).** `env` splits each argument at its first `=`, and ENVIRON does no escape processing. Executed: the directories `a=b`, `-x`, `a\nb` (literal backslash), `IT_ROOT=/` and a TAB each resolve as written. A caller-exported `IT_ROOT=/evil IT_DIR=evil` is overridden.
- **IMPORT_OUT_MAX (`:485`, `:618`, `:694`).** It fails closed: `IMPORTED=error` or `IMPORTED_MAIN=error` is set before any partial list is used, and `isimported` answers imported on error. It is a lib constant, not read from the environment, so the arithmetic context never evaluates caller text. One nit: `${#out}` counts characters in the caller's locale, not the bytes the comment says, so the bound is at most 4× looser under UTF-8. It is still a bound and still fails closed.
- **4 MiB + 1 head cap (`:616`).** It only over-reads. A file of up to `nH` = 4,194,304 bytes is read whole (executed at exactly 4,194,304). A larger file is one Claude Code skips entirely (`s.totalBytes>nH`, `teo`). `head` failing fails the pipeline under the walk's `pipefail`. The main walk still has no cap (L2-C5, deferred; availability only).
- **The trim (`:525`).** Never a miss. `Ye` always trims, and JS `trim()` only removes `\s`, which already ends the token, or the spaces of a trailing `\ `, whose untrimmed prefix the scan emits anyway. A leading escaped space is an over-read only (fact-check Claim 31b, `reo`'s filter rejects it).
- **Absolute resolution and `..` clamp (dd51e9a7).** No non-`~/` miss in 1,050 `gen2.js` documents, nor in the non-`~/` fragments of the `gen3.js` corpora.

## Untested bypass candidates

- **Bun's own UTF-8 decoder.** Python matches Node on 20,000 random strings (fact-check Claim 15). If Bun replaced per byte rather than by maximal subpart, the U+FFFD count would differ and the name would be missed. Bun could not be run (`BUN_BE_BUN=1` starts Claude Code).
- **A Claude Code session whose HOME differs from the gate's** (residue of Finding 1 after the patch).
- **User-level memory as a start.** `~/.claude/CLAUDE.md` (type User) may import absolute repo paths. The walks start only at repo files. Out of scope for the repo gate, but not stated.
- **Case-insensitive checkouts and external includes** (Finding 3), not executed here (ext4).

## Endorsement Claims

- **Claim:** At 98e3b1df, for every name the transcribed Claude Code 2.1.292 lexer, `reo` and `Ye` resolve inside the root in 1,050 `gen2.js` documents (seeds 11-13, 42 with U+FFFD names), `import_targets` lists the name.
  **Location:** `scripts/lib/dev-cycle-read.sh:521-581`
  **Evidence:** executed
  **Verified:** `run.sh G11/G12/G13` (`comm -23 cc-G* pa-G*` empty), HOME=/home/node, docs in a subdirectory of the root.
  **Not verified:** shapes outside both fragment alphabets, Bun's decoder, and `~/` spellings (Finding 1).
  **route: code-fact-check**
- **Claim:** With the Appendix patch, the `gen3.js` corpora (seeds 7-10, 1,274 Claude Code names, HOME an ancestor of, equal to, `/` above, or inside the root) give 0 misses. A symlinked-alias HOME is found through its real spelling. An empty or relative HOME with a `~/` name returns 1. `build-loop-check.bats` and `dev-cycle.bats` pass 110/110, and the gitfx `.git` fixture fails closed.
  **Location:** the Appendix diff
  **Evidence:** executed
  **Verified:** `run.sh F1-F4`, `hp.sh`, `bats-fix.log`, and the gitfx run with `fixrepo/`.
  **Not verified:** the extra fork's cost per file (performance), and a Claude Code session whose HOME differs from the gate's.
  **route: code-fact-check**

## Primitive sweep

Primitive: path construction and lookup from untrusted text (as in iteration 1; rows changed by the fixes only)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `IMPORT_AWK` emit `:524-537` | S1, S2, S3 (dir/root via ENVIRON) | trim, `~/` dropped, absolute join, `..` clamp, `pre` test | Finding 1 (`~/`); otherwise cleared (fuzz) |
| `import_targets` python3 `:574` | S1/S2 bytes | `-I`, `\|\| return 1` | Cleared |
| `imported_names` `head -c 4194305 -- "$f"` `:616` | S4 (queued paths) | `-f`, `inrepo_here`, pipefail | Cleared (TOCTOU swap to a FIFO pre-existing, iteration 1) |
| `main_imports` checkout test `:703-706` | S4 | `.git` / `.git/*` skip, then link/gitlink and plain-dir tests | Finding 2 |
| `(( used += ${#out} ))` `:618`, `:694` | derived count | constant bound | Cleared |

No exec, eval, deserialization or network primitive is in scope. Candidate names still reach only test operators, `realpath --`, quoted patterns, assoc keys and `printf '%s'`.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `@~/<path into the repo>` is imported by Claude Code but dropped by both walks for every HOME placement; the superset statement omits it | Medium | B3, B1→B5, B2 | `scripts/lib/dev-cycle-read.sh:526`, `:510` | High (mechanism); Medium (not live: /workspace is outside HOME) |
| 2 | The `.git` skip covers `.git/*`, so a `$GIT_DIR` file main's instruction imports is neither followed nor failed on; its imports leave the gate's list (regression from be94c871's walk failure) | Medium | B5, B2 | `scripts/lib/dev-cycle-read.sh:702-703` | High (mechanism); Low (exposure today) |
| 3 | The one statement also omits row 350's case-insensitive residue and Claude Code's external-includes mode | Informational | B3 | `scripts/lib/dev-cycle-read.sh:510-513` | Medium |

## Overall Assessment

Iteration 1's fixes hold where they apply. The U+FFFD copy closes F1 with no misalignment I could construct, and 1,050 fuzzed documents give 0 misses. ENVIRON, IMPORT_OUT_MAX and the 4 MiB cap either fail closed or only over-read. The superset claim is still not true as stated, for two reasons. First, one whole spelling class, `~/`, is dropped, and in any repo under its user's home that is a one-line, review-proof way to load a doc that `--check-fix` and the floor pass (Finding 1). Second, the L2-A6 fix is broader than its finding, and in a primary checkout it turns a fail-closed walk into a fail-open one for anything imported through `$GIT_DIR` (Finding 2). Both fixes are small and tested (Appendix: `~/` joined to HOME and its real path, failing closed on an empty or relative HOME; the skip narrowed to `.git` alone). Neither points to an architectural problem. The most important is Finding 2, because it regresses a check that used to refuse. Finding 1 matters more for users whose repos live under HOME.

## Appendix: candidate patch (tested in `/tmp/u2a3bsecL2i2-bFas/fixrepo`, not applied)

```diff
@@ -523,7 +523,12 @@
 function emit(c,   n, i, k, part, st, out) {
   work += length(c); if (work > 50000000) exit 3
   sub(/^ +/, "", c); sub(/ +$/, "", c)  # Claude Code trims the name (an escaped space can lead it)
-  if (c == "" || substr(c, 1, 2) == "~/") return
+  if (c == "") return
+  # ~/ is joined to the home directory (Claude Code: path.join(os.homedir(), rest)).
+  if (substr(c, 1, 2) == "~/") { if (substr(home, 1, 1) != "/") exit 4; if (homer != home) put(homer "/" substr(c, 3)); c = home "/" substr(c, 3) }
+  put(c)
+}
+function put(c,   n, i, k, part, st, out) {
   if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
@@ -558,7 +563,7 @@
-BEGIN { dir = ENVIRON["IT_DIR"]; root = ENVIRON["IT_ROOT"]; pre = (root == "/") ? "/" : root "/"; if (root == "") exit 2 }
+BEGIN { dir = ENVIRON["IT_DIR"]; root = ENVIRON["IT_ROOT"]; home = ENVIRON["IT_HOME"]; homer = ENVIRON["IT_HOMER"]; pre = (root == "/") ? "/" : root "/"; if (root == "") exit 2 }
@@ -577,7 +582,10 @@
-  printf '%s\n' "$toks" | env LC_ALL=C IT_DIR="$1" IT_ROOT="$ROOT_REAL" awk "$IMPORT_AWK" || return 1
+  # HOME as Node's os.homedir reads it (unset: the passwd entry), and its real path, since ROOT_REAL is real.
+  local h="${HOME-$(getent passwd "$(id -u)" | cut -d: -f6)}" hr=""
+  [[ "$h" != /* ]] || hr="$(realpath -m -- "$h")" || return 1
+  printf '%s\n' "$toks" | env LC_ALL=C IT_DIR="$1" IT_ROOT="$ROOT_REAL" IT_HOME="$h" IT_HOMER="${hr:-$h}" awk "$IMPORT_AWK" || return 1
@@ -700,7 +708,7 @@
-      [[ "$p" != .git && "$p" != .git/* ]] || continue
+      [[ "$p" != .git ]] || continue
```

When landing it: hoist the HOME lookup to once per walk. Update the statement (`:510`) and imported_names' header (`:450`, "drops ~/") to say that `~/` is resolved against the gate's HOME. Add tests: the gitfx fixture (`@.git/notes.md` → walk failed), and `@~/<rel>/docs/x.md` with HOME set to the fixture's parent in both walks.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 98e3b1df` line at the top.
- **Answered:**
  - *Fail-open shapes left after the fixes.* Two: Findings 1 and 2. Finding 3 is documentation of waived residue.
  - *Claim 9's `~/` case and how to bound a fix.* Covered in Finding 1 and the Appendix: an unset HOME uses the passwd entry, an empty or relative HOME fails closed, HOME = `/` and HOME as a prefix of, equal to or below ROOT_REAL are all handled lexically, and a symlinked HOME is handled by also emitting its real spelling. The residue is that the parser uses the gate's HOME.
  - *The U+FFFD path.* Cleared, including the ordering, the combined toks string, skip conditions and failure modes.
  - *ENVIRON, IMPORT_OUT_MAX and the head cap.* Cleared (fail-closed or over-read).
  - *The .git skip.* Yes, a name can hide behind it, though not by crafting the name: any `.git/*` import escapes the checkout test (Finding 2).
  - *Harness.* Reused and extended (`cc2.js` with `Ye`'s `~` handling, `gen3.js` with 13 HOME-relative fragments).
- **Out of scope:**
  - Claim 31b and Claim 36b. 31b is test labelling, and the over-read is harmless. 36b is performance.
  - The cost of the python3 fork.
  - The nested-`.git` rule routed to U2a3c.
- **Escalate:** none at HALT level. Finding 2 regresses a fail-closed check that be94c871 had, so the orchestrator should not mark L2-A6 "Fixed" as it stands.
- **Questions I would have asked:**
  - Do the gate and the Claude Code sessions it protects always share a HOME? If not, Finding 1's fix should fail closed on every `~/` name rather than resolve it.
- **Decisions I made:**
  - I rated Finding 2 Medium under the floor rule, with exposure carried in Confidence.
  - I treated case-insensitive checkouts and external includes as waived (row 350) and noted only that the statement omits them.
  - I used node in place of Bun.
  - I kept scratch output in `/tmp/u2a3bsecL2i2-bFas` and bats temp files in `/tmp/u2a3bsecL2i2T-K4PX`. No worktree file other than this report was written.
