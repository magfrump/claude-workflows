Commit: 34edec56

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`)
**Scope:** `git diff main...HEAD` on `feat/build-loop-u2a3` (base 62d366a7, HEAD 34edec56), iteration 2. The claims are re-verdicted where fix commits 4f087967 and 34edec56 changed the code or text: scripts/lib/dev-cycle-read.sh, docs/working/known-issues-dev-cycle.md (A5), docs/working/plan-build-loop-handoff.md (F11, U2a3), test/scripts/build-loop-check.bats (new test 15), both fix commits' messages, and the override-log rows added in 277b2fab. Unchanged claims are carried from iteration 1 (`docs/reviews/code-fact-check-report-build-loop-u2a3.md`) by reference.
**Checked:** 2026-10-06
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 26
**Summary:** 20 verified, 2 mostly accurate, 0 stale, 2 incorrect, 2 unverifiable

The task asked for the fix commits to be checked first, so the claims are ordered by commit and then by file and line: the lib, the docs, the test and the messages of 4f087967 and 34edec56, followed by the override rows.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The logged patterns are mis-quoted measured values (test counts, corpus figures) and unreferenced symbol associations. For that reason the commit's counts (15, 113, 369) were recomputed (Claims 16 and 18), and all three match. The two Incorrect verdicts are behavior mismatches, not fabricated symbols, so nothing was added to the log.

## Execution provenance

All runs used the scratch dir `/tmp/u2a3-cfc-i2-1ek4`, with logs in `logs/`. The worktree was not edited except for this report.

- **E1** (ended 2026-10-06T23:45:44Z), cwd `/workspace/.claude/wt-build-loop-u2a3`. Each suite ran as `TMPDIR=/tmp/u2a3-cfc-i2-1ek4 bats <suite>`: test/scripts/build-loop-check.bats, dev-cycle.bats, build-loop-read.bats, fixture-git-env.bats, and test/fixture-hermeticity.bats. Every suite exited 0. Counts were 15 + 75 + 19 + 2 + 2 = 113 ok, 0 not ok. Logs: `logs/bats-*.txt`.
- **E2** (2026-10-06T23:46:31Z and 23:46:47Z): single-point mutants. Each scratch copy `mut/<name>/` held scripts/lib, test/scripts/build-loop-check.bats and test/lib, and was run with `TMPDIR=… bats test/scripts/build-loop-check.bats` from that copy.
  - `base` (unmutated): rc=0.
  - `drop` (line 598, the `..` check, removed): rc=1, test 15.
  - `noent` (`ent[$p] != 120000` removed from :600): rc=1, test 15.
  - `noL` (`! -L "$p"` removed from :600): rc=0, so it **survives**.
  - Logs: `logs/mutant-{base,drop,noent,noL}.txt`.
- **E3** (2026-10-06T23:47:31Z): `bash /tmp/u2a3-cfc-i2-1ek4/probes.sh`, probes Q1-Q11, rc=0. Each probe builds a repo under `p/` and calls the HEAD lib through `h.sh`'s `imps`, a copy of the bats helper. Log: `logs/probes.txt`.
- **E4** (2026-10-06T23:48:54Z): `bash /tmp/u2a3-cfc-i2-1ek4/probes2.sh`, probes Q12-Q14, rc=0. Log: `logs/probes2.txt`. An earlier run at 23:48:46Z had a confounded Q14: the moved directory stayed in the repo as an untracked symlink start. It was superseded by moving the directory outside the repo.
- **E5** (2026-10-06T23:49:18Z): the new test 15, run against the pre-fix lib (277b2fab's `dev-cycle-read.sh`) in `mut/prefix/`. rc=1, and the first assertion fails with `walk: ok`, `deep/secret.md: -`. Log: `logs/prefix.txt`.
- **E6** (2026-10-06T23:49:31Z): `bash /tmp/u2a3-cfc-i2-1ek4/probes3.sh`, probe Q15 on the pre-fix lib, with and without `ld` in the checkout, rc=0. Log: `logs/probes3.txt`.
- **E7** (2026-10-06T23:50:06Z): `node -e 'path.resolve("/r","ld/../evil.md")'` printed `/r/evil.md`. `claude --version` printed `2.1.292 (Claude Code)`. A grep of the installed binary extracted the `@`-import extractor. Log: `logs/claude-binary.txt`. This is true as of the binary installed at that time.

---

## Claim 1: "symlink text that is ... absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink ... fail the walk" and ":594-595 realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails."

**Location:** `scripts/lib/dev-cycle-read.sh:458-463`, `scripts/lib/dev-cycle-read.sh:594-595`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `..` components of the link text that follow a component which is a symlink on main (`ent` 120000) or a symlink in the checkout (`-L`), and the legitimate shapes that must still pass. It does not establish three things. First, a symlink in the link's own directory `d` is never checked, because the loop starts at `p="$d"` and probes only the text's components (Q14, no fail-open observed). Second, the `-L` probe reaches outside the repo when the text climbs above the root (Q9, fail-closed only). Third, no test exercises the checkout-only half (mutant `noL` survives).
**Legibility-target:** for-orchestrator-synthesis

The loop (complete unit read: `main_imports()` `:545-615`, case arm `:587-603`; the value `out` flows to the read loop at `:607-613`):

```bash
# scripts/lib/dev-cycle-read.sh:596-603
          lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"
          for c in "${parts[@]}"; do
            [[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }
            p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${p:+$p/}$c" 2>/dev/null)" || p=..
            [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
          done
          out="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$out" 2>/dev/null)" || out=..
          [[ "$out" != .. && "$out" != ../* ]] || { IMPORTED_MAIN=error; return 1; } ;;
```

The probe results (E3 to E6) for each shape the task named:

- **A symlink as the first component.** `ld/../evil.md` fails (test 15). On the pre-fix lib the same shape was `walk: ok`, `deep/secret.md: -`, with and without `ld` in the checkout (Q15). That confirms the mechanism the comment names.
- **A deeper symlink.** `a/ld/x/../../evil.md` with `a/ld -> ../deep/inner` printed `walk: failed deep/secret.md: imported` (Q1). `cat` showed that the kernel reads `deep/evil.md`.
- **A `.` component, doubled slashes, and `ld/..` exactly.** `ld/./../evil.md`, `ld//../evil.md` and `ld/..` each failed (Q2, Q3, Q4). An empty or `.` component leaves `p` unchanged, so `lk` stays set.
- **A trailing slash.** `ld/../evil.md/` failed (Q4b). `read -ra` drops the trailing empty field, and the `..` check fires first.
- **Link text that is exactly `..`.** It failed at the top level, where the leaves-the-repo check at `:603` fires, and also under `docs/` (Q5, Q5b). In the `docs/` case the text resolves to `.`, which the `t:` branch refuses because `.` is not plaindir.
- **A symlink only in the checkout.** Main stores `ld/` as a tree and the checkout has `ld -> deep/inner`. The walk failed (Q7), as the comment's "or in the checkout" says. The mutant `noL` survives the suite (E2), so no test pins this half.
- **Legitimate shapes still pass.** `docs/../docs/real.md` (a `..` after a plain directory) and a link whose final component is a symlink chain with no `..` after it both gave `walk: ok`, with the target imported (Q6, test 15 stage 3).
- **A symlink in the link's own directory `d`.** On main, `d` is always made of trees. The paraphrase that follows is tagged: paraphrased — no quote available because the claim is an inference from three sites. `m:` queue items come only from `ent`, which holds only `ls-tree -r` entries, and `ls-tree -r` never lists a path under a symlink (`:552-560`, `:612`). In the checkout `d` can be a symlink, and its `..` is not refused. In Q14 (main stores `sub2/`, the checkout has `sub2 -> deep/inner`) the walk printed `walk: ok evil.md: imported deep/secret.md: imported`. The file the kernel would load there was also reached through its own path on main, so nothing was missed in that probe.
- **Paths outside the repo.** When the text climbs above the root, `p` becomes `..` or `../x`, and `-L "$p"` lstats a path outside the repo. In Q9, `../outlnk/../<root>/evil.md` failed while `$S/p/outlnk` (outside the repo) was a symlink, and printed `walk: ok` once it was removed. The probe reads metadata only and can only set `lk`, so the effect is fail-closed. The comment's "on main or in the checkout" understates this reach.

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-615`, `test/scripts/build-loop-check.bats:268-280`, `/tmp/u2a3-cfc-i2-1ek4/logs/probes.txt` (Q1-Q9), `/tmp/u2a3-cfc-i2-1ek4/logs/probes2.txt` (Q14), `/tmp/u2a3-cfc-i2-1ek4/logs/probes3.txt` (Q15), `/tmp/u2a3-cfc-i2-1ek4/logs/mutant-noL.txt`

---

## Claim 2: "Not covered (known issue A5): start files under a symlinked directory (on main or in the checkout: neither listing enters one) or in a submodule or an untracked nested repo (neither listing enters one either), ..., other names that one file has on a case-insensitive checkout, and absolute imports"

**Location:** `scripts/lib/dev-cycle-read.sh:464-469`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed item being a real gap, including the two added by 4f087967 (submodule and untracked nested repo). It does not establish that the list is complete (see Claim 3), and it does not establish Claude Code's own behavior for submodule instruction files.
**Legibility-target:** for-orchestrator-synthesis

- **Submodule (Q12).** `git ls-tree -r` lists only the gitlink, `160000 commit 90ea8e35… sub`, and not `sub/CLAUDE.md`. That file holds `n @../docs/n.md`, and the walk printed `walk: ok docs/n.md: - sub/CLAUDE.md: -`.
- **Untracked nested repo.** Iteration 1 P5 is carried (iteration-1 Claim 11b): `walk: ok docs/n.md: -`.
- **The other items.** These are carried from iteration-1 Claim 11a (Verified). The wording of the symlinked-directory and case-insensitive items is unchanged.
- **Imports into the submodule.** An `@` import naming a file inside the submodule is still read from the checkout (Q13: `sub/CLAUDE.md: imported docs/n.md: imported`). Only starts are missed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:464-469,552-565`, `/tmp/u2a3-cfc-i2-1ek4/logs/probes2.txt` (Q12, Q13)

---

## Claim 3: "an @ token's path (link text is checked above) through a directory main stores as a symlink when the checkout does not have that link"

**Location:** `scripts/lib/dev-cycle-read.sh:466-468`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parenthetical's implication that link text is not subject to this gap. It does not establish anything about `@` tokens, for which the gap is real and is carried from iteration-1 Claim 11a.
**Legibility-target:** for-author

The check above refuses only a `..` that follows a symlink (Claim 1). Link text that passes through a directory main stores as a symlink, with no `..` in it, falls into the same gap as an `@` token. Its lexical result is not an `ent` key, so it is queued as a checkout read: `if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); else queue+=("t:$p"); fi` (`:612`). When the checkout lacks the link, that read is a silent skip: `else continue; fi` (`:583`).

- **Q10.** Main holds `ld -> deep` and `CLAUDE.md -> ld/evil.md`, and `cat` reads `evil @secret.md`. With `ld` in the checkout the walk printed `walk: failed`. Without it, the walk printed `walk: ok ld/evil.md: imported deep/evil.md: - deep/secret.md: -`.
- **Q11.** A chain behaves the same way: `CLAUDE.md -> ld/l2.md`, with `deep/inner/l2.md -> ../evil.md` on main. Without `ld` in the checkout it gave `walk: ok deep/secret.md: -`.

The accurate version names "an import path, `@` token or link text," as A5 and F11 do (Claims 6 and 7).

**Evidence:** `scripts/lib/dev-cycle-read.sh:579-583,596-603,607-613`, `/tmp/u2a3-cfc-i2-1ek4/logs/probes.txt` (Q10, Q11)

---

## Claim 4: return-1 list: "... a blob or checkout file cannot be read, the lower-cased start list comes back short, symlink text it follows is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink, or a checkout path it would read exists but is not a plain file (a symlink, or under one) or a plain directory"

**Location:** `scripts/lib/dev-cycle-read.sh:532-544`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` in `main_imports()` (`:545-615`) against the list, including the two items 4f087967 added. It does not establish behavior when a mid-loop `lower` fails (`:609`), which does not return 1 and is fixed in U2a3b (stacked).
**Legibility-target:** for-orchestrator-synthesis

The two added items each have a `return 1`:

- The short start list: `[[ ${#low[@]} -eq ${#cand[@]} ]] || return 1` (`:568`).
- A `..` after a symlink: `[[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }` (`:598`). Test 15 pins it (mutant `drop`, E2).

Every other item matches as in iteration-1 Claim 13: `:551,553,556,558,563,565,580,582,586,590-593,603`. Iteration-1 Claim 13's one omission (the short list) is now fixed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:532-615`, `/tmp/u2a3-cfc-i2-1ek4/logs/mutant-drop.txt`

---

## Claim 5: A5 refusal list: "link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an unreadable checkout file, or a checkout symlink the walk would read fail it"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal list against the code (Claims 1 and 4). It does not establish what "leaves the repo" means for text that climbs out and back in (`../<rootname>/evil.md` resolves inside and is followed: Q9 third line).
**Legibility-target:** for-orchestrator-synthesis

The new item is the `..` check, `:598`, exercised in Q1-Q4 and by test 15. The other items are carried from iteration-1 Claim 2a. Q9's third line: an `AGENTS.md -> ../<root>/evil.md` link gave `walk: ok evil.md: imported`. Its lexical result, `evil.md`, is inside the repo, so the walk does not count it as leaving the repo.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:590-603`, `/tmp/u2a3-cfc-i2-1ek4/logs/probes.txt` (Q9)

---

## Claim 6: A5 gap list: "but not start files under a symlinked directory or in a submodule or untracked nested repo (neither `ls-tree -r` nor `ls-files --others` enters one), an import path through a directory main stores as a symlink when the checkout lacks that link, other names one file has on a case-insensitive checkout, or absolute imports into the repo"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers each gap, and the iteration-1 omissions now being listed. "An import path" is read as including link text, which the code calls "one more import" (`:587`); Q10 and Q11 fall under it. It does not establish completeness beyond the probes run (Q1-Q15 here, P1-P14 in iteration 1).
**Legibility-target:** for-orchestrator-synthesis

Both of iteration-1 Claim 2b's omissions are fixed:

- P4 now fails the walk (Claim 1).
- P5 and the submodule case are listed (Claim 2).

The code comment calls link text an import: `# a symlink: its text names the file read, as one more import` (`:587`). Under that reading, Q10 and Q11 are the listed "import path through a directory main stores as a symlink" gap. Confidence is Medium because the lib comment (Claim 3) now reads the same gap more narrowly, so a reader of both could take "import path" to mean `@` tokens only.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:587`, `/tmp/u2a3-cfc-i2-1ek4/logs/probes.txt` (Q10, Q11), `/tmp/u2a3-cfc-i2-1ek4/logs/probes2.txt` (Q12)

---

## Claim 7: F11: "... link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink ... fails the walk ... Gaps: known issue A5 (start files under a symlinked directory or in a submodule or untracked nested repo, an import path through a directory main stores as a symlink that the checkout lacks, case-insensitive names, absolute imports)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal and gap lists, as in Claims 5 and 6. It does not establish "so floor refuses every path", because `floor` does not exist until U2a4.
**Legibility-target:** for-orchestrator-synthesis

The text matches A5 item for item (paraphrased — no quote available because the claim is a line-by-line comparison of two table cells already quoted in Claims 5 and 6). Iteration-1 Claim 3b's two omissions are fixed.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:590-603`

---

## Claim 8: U2a3 bullet: "It refuses the tree and link shapes it does not model (a doubled name, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an unreadable checkout file, a checkout symlink it would read)"

**Location:** `docs/working/plan-build-loop-handoff.md:276`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parenthesized list against the refusals in `:556-603`. It does not establish the infrastructure refusals (listing failures, the short lower-cased list), which the bullet's "tree and link shapes" framing reasonably leaves out.
**Legibility-target:** for-orchestrator-synthesis

Iteration-1 Claim 4's two omissions are now present:

- Leaves the repo: `:603`.
- An unreadable checkout file: `out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; }` (`:580`).

The new `..` item is checked at `:598`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:276`, `scripts/lib/dev-cycle-read.sh:558,580,582,590-603`

---

## Claim 9: test 15's name "main walk fails on symlink text with a .. after a symlink, with or without that link in the checkout; a .. after a plain directory is followed" and its comment "The kernel reads deep/evil.md through ld; realpath -s would read evil.md."

**Location:** `test/scripts/build-loop-check.bats:268-280`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each assertion matching the name. It does not establish coverage of a symlink present only in the checkout: the name's "that link" is main's link, and mutant `noL` survives.
**Legibility-target:** for-orchestrator-synthesis

The test runs in three stages:

1. With `ld` in the checkout, `imps main deep/secret.md; want walk failed; want deep/secret.md imported`.
2. After `rm ld`, the same assertions. The checkout lacks the link, so only `ent` can catch it, and mutant `noent` fails here (E2).
3. After `rm CLAUDE.md && commit_all no-ld`, `AGENTS.md -> docs/../docs/n.md` gives `want walk ok; want hid.md imported; want docs/n.md imported; want deep/secret.md -`. A rule refusing every `..` would fail this stage.

On the pre-fix lib, stage 1 fails with `walk: ok`, `deep/secret.md: -` (E5). The comment's kernel claim matches Q15's `cat: evil @secret.md`.

**Evidence:** `test/scripts/build-loop-check.bats:268-280`, `/tmp/u2a3-cfc-i2-1ek4/logs/prefix.txt`, `/tmp/u2a3-cfc-i2-1ek4/logs/mutant-{drop,noent,noL}.txt`

---

## Claim 10: 4f087967: "symlink text on main was resolved with realpath -s, which reads `ld/..` as nothing without looking at ld, while the kernel follows a symlink ld first. With main holding `ld -> deep/inner` and `CLAUDE.md -> ld/../evil.md`, Claude Code loads deep/evil.md and its imports, but the walk read the top-level evil.md and answered ok, with or without ld in the checkout."

**Location:** commit 4f087967 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix walk's answer with and without `ld`, and the kernel's resolution. It does not establish Claude Code's loader reading CLAUDE.md through the filesystem (inferred from the kernel `cat`, not run under Claude Code).
**Legibility-target:** for-orchestrator-synthesis

Q15 on 277b2fab's lib printed `walk: ok evil.md: imported deep/evil.md: - deep/secret.md: -` twice, once with `ld` in the checkout and once without it. `cat CLAUDE.md` printed `evil @secret.md`.

**Evidence:** `/tmp/u2a3-cfc-i2-1ek4/logs/probes3.txt`, `/tmp/u2a3-cfc-i2-1ek4/logs/prefix.txt`

---

## Claim 11: 4f087967: "The walk now resolves link text a component at a time and fails when a .. follows a symlink on main or in the checkout."

**Location:** commit 4f087967 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mechanism description. The refusal half is Verified in Claim 1. This verdict does not establish the `d`-prefix and outside-repo residues named there.
**Legibility-target:** for-author

The per-component pass is a check. The path that is read is still the whole text resolved lexically: `out="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$out" 2>/dev/null)" || out=..` (`:602`). The per-component `p` is used only for the symlink test at `:600`. The result is equivalent once every `..` after a symlink fails, but "resolves ... a component at a time" overstates the change. A precise version: "checks link text a component at a time and fails when a .. follows a symlink; the target is still resolved lexically."

**Evidence:** `scripts/lib/dev-cycle-read.sh:596-603`

---

## Claim 12a: 4f087967: "Import tokens keep lexical resolution"

**Location:** commit 4f087967 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `import_targets`, which the fix left unchanged. It does not establish how Claude Code resolves a token (Claim 12b).
**Legibility-target:** for-orchestrator-synthesis

`p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)" || continue` (`scripts/lib/dev-cycle-read.sh:499`). `git show 4f087967` does not touch `import_targets`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:491-505`

---

## Claim 12b: 4f087967: "(Node's path.resolve is lexical too)", offered as the reason lexical token resolution matches Claude Code

**Location:** commit 4f087967 message
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** `path.resolve` was executed and is lexical. This does not establish that Claude Code resolves `@` tokens with `path.resolve`, or that it does not later realpath the result.
**Legibility-target:** for-orchestrator-synthesis

`node -e` printed `/r/evil.md` for `path.resolve("/r","ld/../evil.md")` (E7). The installed Claude Code (2.1.292) is a compiled binary. Its import extractor resolves each token with a minified helper, `let Y=Ye(H,FT(n));r.add(Y)` (`logs/claude-binary.txt`). The name `Ye` is defined many times in the bundle, so which definition applies could not be determined. Verifying this needs Claude Code's unminified source, or a runtime probe: a CLAUDE.md importing `@ld/../x.md`, run under Claude Code, observing which file loads.

**Evidence:** `/tmp/u2a3-cfc-i2-1ek4/logs/claude-binary.txt`

---

## Claim 13: 4f087967: "the 'Not covered' list, known issue A5 and plan F11 now name start files in a submodule or untracked nested repo (P5, the U2a2 D8 row's trigger) and qualify the symlinked-directory gap as an import path"

**Location:** commit 4f087967 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the text being present in all three places. Whether "import path" is right for the lib comment is Claim 3, after 34edec56 narrowed it.
**Legibility-target:** for-orchestrator-synthesis

The text is present in all three places:

- Lib: "or in a submodule or an untracked nested repo (neither listing enters one either)" (`scripts/lib/dev-cycle-read.sh:465-466`).
- A5: "or in a submodule or untracked nested repo ... an import path through" (`docs/working/known-issues-dev-cycle.md:18`).
- F11: "or in a submodule or untracked nested repo, an import path through" (`docs/working/plan-build-loop-handoff.md:126`).

At 4f087967 the lib also read "an import path". 34edec56 changed it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:464-469`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`

---

## Claim 14: 4f087967: "the return-1 list names the short lower-cased start list (Claim 13); the plan's U2a3 bullet lists every refusal (Claim 4)"

**Location:** commit 4f087967 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both edits against iteration-1 Claims 13 and 4. "Every refusal" is read as every tree and link shape (Claim 8).
**Legibility-target:** for-orchestrator-synthesis

See Claims 4 and 8. Both cited iteration-1 claim numbers are the right ones (`docs/reviews/code-fact-check-report-build-loop-u2a3.md`, Claims 13 and 4).

**Evidence:** `scripts/lib/dev-cycle-read.sh:536-537`, `docs/working/plan-build-loop-handoff.md:276`

---

## Claim 15: 4f087967: "A mutant dropping the new check fails it."

**Location:** commit 4f087967 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers removing line 598. It does not establish that the checkout half of the symlink test is pinned: mutant `noL` survives.
**Legibility-target:** for-orchestrator-synthesis

Mutant `drop` gave rc=1 with `not ok 15` (E2).

**Evidence:** `/tmp/u2a3-cfc-i2-1ek4/logs/mutant-drop.txt`, `/tmp/u2a3-cfc-i2-1ek4/logs/mutant-noL.txt`

---

## Claim 16: 4f087967: "Tests: one new in build-loop-check.bats (15); 113 across the five suites."

**Location:** commit 4f087967 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at HEAD, which equals 4f087967 for test files because 34edec56 touches only the lib. It does not establish which five suites the author meant (the same five as iteration-1 E1 are assumed).
**Legibility-target:** for-orchestrator-synthesis

The suite counts were 15 + 75 + 19 + 2 + 2 = 113, all ok (E1).

**Evidence:** `/tmp/u2a3-cfc-i2-1ek4/logs/bats-*.txt`

---

## Claim 17: 4f087967 Notes: "the submodule/nested-repo starts are documented, not modelled (override row, Defer to U2b, which names the checkout --check runs in)"

**Location:** commit 4f087967 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the row's existence and the U2b bullet. It does not establish U2b's eventual content.
**Legibility-target:** for-orchestrator-synthesis

The row exists: `| 2026-10-06 | \`feat/build-loop-u2a3\` | An instruction file in a submodule ... | Defer | ... Revisit trigger: U2b, which names the checkout --check runs in` (`docs/reviews/override-log.md:366`). U2b reads: "It names the checkout `--check` runs from" (`docs/working/plan-build-loop-handoff.md:278`). Not modelled: Q12 (`walk: ok`).

**Evidence:** `docs/reviews/override-log.md:366`, `docs/working/plan-build-loop-handoff.md:278`, `/tmp/u2a3-cfc-i2-1ek4/logs/probes2.txt`

---

## Claim 18: 4f087967: "369 changed code lines against main."

**Location:** commit 4f087967 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers insertions plus deletions outside `docs/`, the same convention as iteration-1 Claim 26.
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat main...4f087967 -- . ':!docs'` gives 117/9 (lib), 237/2 (build-loop-check.bats) and 2/2 (dev-cycle.bats), which sum to 369. HEAD gives the same sum (paraphrased — no quote available because the claim is a computed sum over numstat rows).

**Evidence:** `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`

---

## Claim 19: 34edec56 subject: "the not-covered symlinked-directory gap names @ tokens, not link text"

**Location:** commit 34edec56 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the premise that link text is outside this gap. It does not establish anything beyond Claim 3, which is the same finding.
**Legibility-target:** for-author

Link text through a directory main stores as a symlink, with no `..`, walks ok when the checkout lacks the link (Q10, Q11). The gap covers link text as well as `@` tokens. See Claim 3.

**Evidence:** `scripts/lib/dev-cycle-read.sh:583,612`, `/tmp/u2a3-cfc-i2-1ek4/logs/probes.txt` (Q10, Q11)

---

## Claim 20: 34edec56 Notes: "lite-review fix-drift finding 1 (comment ambiguity after the link-text .. check)"

**Location:** commit 34edec56 message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers whether the cited lite-review finding is findable. It is not committed on the branch.
**Legibility-target:** for-orchestrator-synthesis

No lite-review artifact for U2a3 is on the branch: `git diff --name-only main...HEAD -- docs/reviews` lists only the iteration-1 fact-check report, the rubric and override-log.md (paraphrased — no quote available because the claim covers absence of a file). Verifying this needs the orchestrator's lite-review output.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a3.md`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md`

---

## Claim 21: override row: "main_imports checks every tree record in bash ...: 0.4-0.5 s here ..."

**Location:** `docs/reviews/override-log.md:365`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Carried from iteration-1 Claim 1. The fix adds one loop per symlink entry only, not per record. Does not establish timing at 30k entries.
**Legibility-target:** for-orchestrator-synthesis

The per-record loop `:555-561` is unchanged by the fix commits. The new loop at `:596-601` runs only in the `120000` arm (quoted in Claim 1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:555-561,596-601`

---

## Claim 22a: override row: "An instruction file in a submodule ... or an untracked nested repo is not a start file: the walk is ok and its imports answer `-`"; "A submodule's files do not change on a parent merge (F8 refuses gitlinks)"

**Location:** `docs/reviews/override-log.md:366`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's answer and F8's plan text ("gitlinks refuse"). It does not establish F8's enforcement, which arrives in U2b's `--check`.
**Legibility-target:** for-orchestrator-synthesis

Q12 printed `walk: ok docs/n.md: - sub/CLAUDE.md: -`. F8 reads: "Modes ∈ {100644, 100755, absent}: the exec bit is allowed (rev 4); gitlinks refuse" (`docs/working/plan-build-loop-handoff.md:123`).

**Evidence:** `/tmp/u2a3-cfc-i2-1ek4/logs/probes2.txt` (Q12), `docs/working/plan-build-loop-handoff.md:123`

---

## Claim 22b: override row's mechanism: "(gitlink, `*) continue` at `scripts/lib/dev-cycle-read.sh` main_imports' case)"

**Location:** `docs/reviews/override-log.md:366`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers why a submodule's instruction file is not a start. It does not establish anything about the untracked nested-repo half, which `ls-files --others` explains.
**Legibility-target:** for-author

A submodule's files never reach the start list, because `git ls-tree -r` lists only the gitlink: `160000 commit 90ea8e35… sub` (Q12). The case arm `*) continue ;;` (`:604`) handles only a queue item naming the gitlink path itself, and the gitlink `sub` is not a `.md` candidate. A precise version: "`ls-tree -r` does not enter a gitlink."

**Evidence:** `scripts/lib/dev-cycle-read.sh:552-560,585-605`, `/tmp/u2a3-cfc-i2-1ek4/logs/probes2.txt`

---

## Claim 23: override row: Claims 22 and 27 summaries, and "the lib comment and A5 state both cases"

**Location:** `docs/reviews/override-log.md:367`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row against iteration-1 Claims 22 and 27 and the lib and A5 text. It does not re-verdict the commit message itself (carried).
**Legibility-target:** for-orchestrator-synthesis

The row's summary matches iteration-1 Claims 22 and 27 (Mostly accurate). Both cases are stated:

- A symlinked rules directory is not entered: the lib says "start files under a symlinked directory" (`:464`), and A5 says the same.
- An untracked symlink fails the walk: "a checkout path it would read that is a symlink" (`:462`), and A5's "a checkout symlink the walk would read".

**Evidence:** `scripts/lib/dev-cycle-read.sh:462-465`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 24: override row: "The walk refuses a doubled name either way"

**Location:** `docs/reviews/override-log.md:368`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal. It does not establish which copy a checkout keeps (iteration-1 Claim 14b stays Unverifiable).
**Legibility-target:** for-orchestrator-synthesis

`[[ -z "${ent[$f]+set}" && "$f" != *$'\n'* ]] || return 1` (`scripts/lib/dev-cycle-read.sh:558`). The doubled-name mutant was killed in iteration 1 (E3 `dup`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:558`

---

## Carried claims (unchanged by the fix commits)

These are carried by reference from `docs/reviews/code-fact-check-report-build-loop-u2a3.md` and are not counted above:

| Iteration-1 claim | Verdict |
|---|---|
| 2a, 3a | Verified. Superseded in wording by Claims 5 and 7. |
| 2b, 3b | Incorrect. Fixed: see Claims 6 and 7. |
| 4 | Mostly accurate. Fixed: see Claim 8. |
| 5, 6, 7, 8, 9, 10, 12, 14a, 15, 16, 17, 18 | Verified. Code and text unchanged except for the line shift. Claim 18's test claims extend to test 15 via Claim 9. |
| 11a | Verified. Extended by Claim 2. |
| 11b | Incorrect. P4 and P5 are fixed (Claims 1 and 2). The narrowed wording is now Incorrect for a different reason (Claim 3). |
| 13 | Mostly accurate. Fixed: see Claim 4. |
| 14b | Unverifiable. Won't-Fix row, Claim 24. |
| 19, 20, 21, 23, 24, 25, 26, 28 | Verified. These are fbeae280 and 45ad17b0 messages, which are immutable. |
| 22, 27 | Mostly accurate. Accepted-immutable, Claim 23. |
| 1 | Verified. Re-checked as Claim 21. |

## Claims Requiring Attention

### Incorrect
- **Claim 3** (`scripts/lib/dev-cycle-read.sh:466-468`): "(link text is checked above)" is wrong. Only a `..` after a symlink is checked. Link text through a directory main stores as a symlink walks ok when the checkout lacks the link (Q10, Q11). The fix is to say "an import path (an @ token or link text)", as A5 and F11 do.
- **Claim 19** (commit 34edec56): same premise. The commit is immutable, so this belongs in an override row.

### Mostly Accurate
- **Claim 11** (commit 4f087967): link text is *checked* a component at a time. It is still *resolved* lexically as a whole (`:602`).
- **Claim 22b** (`docs/reviews/override-log.md:366`): a submodule's files are not starts because `ls-tree -r` does not enter a gitlink. `*) continue` is not the reason.

### Unverifiable
- **Claim 12b** (commit 4f087967): needs Claude Code's unminified source, or a runtime probe of `@ld/../x.md`, to know whether its token resolution is `path.resolve`.
- **Claim 20** (commit 34edec56): needs the lite-review fix-drift output, which is not on the branch.

## Escalations

- **security-reviewer.** `scripts/lib/dev-cycle-read.sh:583,612` (comment `:466-468`): link text with no `..` that passes through a directory main stores as a symlink is a fail-open when the checkout lacks the link. Q10: `CLAUDE.md -> ld/evil.md`, `ld -> deep` gives `walk: ok deep/secret.md: -`. Q11 shows the same through a chain. A5's "import path" item covers it under the code's own "one more import" reading, but the lib comment now says link text is checked. Assess whether link text through a main symlink, or more generally any `t:` read that is absent while main holds a symlink on its path, should fail the walk as the `..` case now does.
- **test-strategy.** `scripts/lib/dev-cycle-read.sh:600`: the checkout half (`! -L "$p"`) of the new symlink test is unpinned. Mutant `noL` passes all 15 tests. Q7 is a ready fixture: main stores `ld/` as a tree, the checkout makes `ld` a symlink, and `CLAUDE.md -> ld/../evil.md` should fail. The iteration-1 coverage gaps (untracked `.claude/rules` start, a symlink chain, the cache) remain.
- **security-reviewer (informational).** `scripts/lib/dev-cycle-read.sh:599-600`: when link text climbs above the root, `-L "$p"` lstats paths outside the repo (Q9). This reads metadata only and fails closed, but it is outside the stated "main or the checkout".
- **security-reviewer / U2a3b (stacked parser owner), candidate, out of this diff.** The installed Claude Code 2.1.292's extractor regex is `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g`, followed by `H=H.replaceAll("\\ "," ")` (`logs/claude-binary.txt`), so it reads `\ ` as an escaped space inside a token. `IMPORT_RE` ends a token at a backslash (`scripts/lib/dev-cycle-read.sh:479`). So `@docs/my\ file.md` would be read by Claude Code as `docs/my file.md` and by the walk as `docs/my`, a possible under-read in the shared parser. The rest of that extractor needs a full trace before it can be confirmed.
- **architecture-review / security-reviewer (carried).** The cache key at `scripts/lib/dev-cycle-read.sh:549-550` is unchanged (iteration-1 escalation).

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to docs/reviews/code-fact-check-report-build-loop-u2a3-i2.md verdicting every checkable claim in the U2a3 diff's comments, docs and commit messages, with the iteration-1 fix commits checked first.
- Answered:
  - All seven of the task's claim groups were checked: 27 verdicts, fix commits first, and the unchanged iteration-1 claims carried by reference.
  - The new `..` check was probed for every shape named (Q1-Q9, Q14, Q15) and catches each `..` in the link text after a symlink on main or in the checkout, without failing legitimate shapes.
  - The counts 15, 113 and 369 were recomputed and match. The commit's mutant was rerun and killed, and two more mutants were added.
- Out of scope:
  - Claude Code's own loader behavior: token resolution (Claim 12b), submodule instruction files, `\ ` escapes.
  - A case-insensitive checkout.
  - The parser and `lower`-failure behaviors fixed in U2a3b (stacked).
  - Code-quality and performance judgments.
- Escalate:
  - The link-text-through-a-main-symlink fail-open (Q10, Q11) behind the Incorrect "(link text is checked above)", to security-reviewer.
  - The unpinned `-L` half (mutant `noL`), to test-strategy.
  - The `\ ` parser divergence candidate, to security-reviewer and U2a3b.
