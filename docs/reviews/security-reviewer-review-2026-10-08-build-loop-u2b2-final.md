Commit: 1f4f7a21

# Security Review: feat/build-loop-u2b2 (U2b2, the gate's checkout), final confirming pass

**Scope:** full branch, `main...1f4f7a21`. Code: `scripts/build-loop.sh`, read whole (header 80-170, `harden`/`state_gate`/`default_gate` 208-291, `callervar` 533, `gate_repo` 534-543, `gate_git` 547-552, `merge_result`, `own_blob`, `nrules`, `checkout_gate` 627-692, `check_line` 699-758, the `check` dispatch 769-780). Also the lib header 1-90 (contract items 1-8) and `docs/working` + `scripts/lib` diffs; tests in `test/scripts/build-loop-check.bats` 1604-1705. Probes were run against the worktree's script in throwaway repos (`/tmp/secfu2b2-*`, since removed).
**Date:** 2026-10-08
**Based on:** final code-fact-check replicates r1-r3 (`docs/reviews/code-fact-check-report-build-loop-u2b2-final-r{1,2,3}.md`), as summarized by the orchestrator. Earlier passes: `security-reviewer-review-2026-10-08-build-loop-u2b2.md` and `-i2.md`.
**Threat model:** Q-133 [3]. A hostile same-uid loop racing the gate is out of scope. In scope: honest-path correctness, fail-closed behaviour, and a loop's committed content or ordinary checkout state getting a self-merge brief past the gate.

No HALT escalation: no pattern from the escalation list matched.

## Trust Boundary Map

```
B1: [main's tree: names and modes (committed content)]       → [ls-tree -z → LC_ALL=C =~ $re, mode case, name refusals → hash-object --stdin-paths] → [CHECKOUT_WHY]
B2: [checkout state: bytes, types, perms, index bits, nested repos] → [ls-files -v / git status / ls-files --others / ls -A / hash-object --no-filters] → [CHECKOUT_WHY]
B3: [caller env: repo-local GIT_* vars, GIT_CONFIG, locale]    → [callervar (shared with gate_repo); local -x LC_ALL=C] → [checkout_gate's git and text tools]
B4: [repo config core.symlinks / ignoreCase / sparseCheckout (config, config.worktree)] → [git config --type=bool --get; rc > 1 refuses] → [CHECKOUT_WHY]
B5: [CHECKOUT_WHY, per self-merge brief inside check_line's subshell] → [co replaces only the verdict line] → [exit 2 / U2c's floor walk gated on co empty]
B6: [global/system git config at checkout time (hidden from the gate by GIT_CONFIG_GLOBAL=/dev/null, GIT_CONFIG_NOSYSTEM=1)] → [judged by effect only: index bits, git status, byte hash] → [CHECKOUT_WHY]
```

| Label | Source | Mutability | Trust (per sink class) |
|---|---|---|---|
| S1 | Names and modes in `$MAIN_SHA`'s tree | committed content (a self-merge adds only pathform names; a review merge or old history can hold any bytes) | UNTRUSTED toward the bash regex, the `--stdin-paths` line protocol, and `ls -A` |
| S2 | Working-tree bytes, file types, permissions, index bits | runtime-mutable (ordinary checkout state) | UNTRUSTED for every read; this is what the gate judges |
| S3 | `.git/config` / `config.worktree` core.* keys | runtime-mutable | UNTRUSTED; read as a value; an unreadable value fails closed |
| S4 | Caller env (`GIT_CONFIG_PARAMETERS`/`COUNT` pairs, other `GIT_*`, locale) | caller session | Config pairs trusted by design (harden, override rows); every other repo-local var refused; locale pinned inside checkout_gate |
| S5 | Global/system git config and attributes the checkout was made under | runtime-mutable, outside the repo | UNTRUSTED; never read by the gate, so judged only by its effect on S2 |
| S6 | `MAIN_SHA`, `GATE_TMP` | derived after the state gates / from mktemp | trusted |

checkout_gate sits on one boundary: ordinary checkout state (S2), plus whatever config produced it (S3, S5), crossing into a self-merge decision. The design does not try to predict conversions. It checks their effect: git status, then the index bits status cannot see, then a raw byte hash of every regular file main stores. Every guard I tried that sits upstream of the byte hash (status, index bits) failed closed whenever it fired.

## Findings

#### 1. An invalid core.* boolean makes `--check` print "Not inside a git repository" and exit 1, not the documented checkout refusal

**Severity:** Informational
**Location:** `scripts/build-loop.sh:124-125` (help: "or one of them unreadable"), `:643-645` (the unreachable `rc > 1` arm), `:283` (where it actually stops), `:167-170` (exit classes)
**Boundary:** B4
**Move:** 3 (error path)
**Confidence:** High (executed)

Evidence (probe `badbool`, `git config core.symlinks maybe`, then the same with `core.sparseCheckout maybe`):

```
Not inside a git repository
exit=1
```

git parses `core.symlinks`, `core.ignoreCase` and `core.sparseCheckout` in its startup config pass and dies on a bad boolean before any command runs. So the first git call (`rev-parse --show-toplevel`, :283) fails, and the script reports a usage-class error. No verdict line prints and nothing reads as `ok`, so this is fail-closed and not exploitable. This confirms fact-check r3's Incorrect item. There are two consequences. The help promises a `refuse BRIEF: ...; core.X could not be read` line that cannot print. And exit 1, which the header reserves for usage / no repo / no lib, now also covers "planted config". The orchestrator (U3) must treat every non-zero exit from `--check` as not-ok, never "1 = retry with other arguments".

**Recommendation:** Drop "or one of them unreadable" from the help (or say it ends the run with exit 1, as any git failure does). Keep the `rc > 1` arm as defence in depth. When U3 consumes `--check`, have it treat any exit but 0 as a refusal.

## Untested bypass candidates

- **Crafted tree with a duplicate entry name** (for example `sub` as both a gitlink and a tree). Carried from i2 and still not probed: it needs a hand-built object that fsck rejects, and it can only reach main through a merge the gate already accepted.
- **`core.untrackedCache=true` with a stale cache hiding an untracked nested repository from `ls-files --others`.** Not probed. Reasoned: `ls-files -o` without `--directory` does not use status's untracked-cache flag set, and a new nested repo changes its parent directory's mtime, which invalidates the cache anyway. Reaching this needs a deliberate mtime rewind, which is not ordinary checkout state.
- **Case-insensitive filesystem whose local `core.ignoreCase` is false** (one file, several names). Carried; open in A5. No such mount was available.
- **`GIT_ATTR_SOURCE` (git 2.40+) in the caller's env.** It is not in 2.39's `--local-env-vars`, so checkout_gate would not refuse it. checkout_gate itself judges attributes by effect, so this does not touch U2b2's check. Any risk is to merge-tree attribute reading (U2b1's gate_repo), and only after a git upgrade. Not probed, because this host runs git 2.39.5.

## Endorsement Claims

- **Claim:** A checkout made under a *global* `core.sparseCheckout=true` (invisible to the gate's `git config`, per fact-check r1's residue) makes `--check` refuse a self-merge brief, through the skip-worktree bit.
  **Location:** `scripts/build-loop.sh:650-652`
  **Evidence:** executed
  **Verified:** probe `gsparse`. A global config with `sparseCheckout = true` and `.git/info/sparse-checkout` excluding `docs/a.md`, then `read-tree -mu HEAD`. `ls-files -v` showed `S docs/a.md`. `--check` printed "the checkout's index marks entries skip-worktree, assume-unchanged or unmerged" plus the path line, exit 2.
  **Not verified:** a global `core.ignoreCase=true` on a case-sensitive filesystem. Reasoned: it changes no bytes and no index bits that the hash and `ls-files -v` would miss, and on a case-insensitive filesystem `git init`/`clone` writes the local `ignorecase = true` that :643 reads. Not executed.
  **route: code-fact-check**
- **Claim:** A repo-local `core.autocrlf=true` checkout that wrote CRLF where main stores LF makes `--check` refuse a self-merge brief, through the byte comparison, while `git status` is clean.
  **Location:** `scripts/build-loop.sh:686-691`
  **Evidence:** executed
  **Verified:** probe `autocrlf`. `docs/a.md` read `a \r \n` on disk, `git status --porcelain` printed nothing, and `--check` printed "a file's checked-out bytes are not the default branch's blob ...", exit 2.
  **Not verified:** `core.eol=crlf` with `text=auto` from `.gitattributes` alone. It goes through the same hash comparison but was not run.
  **route: code-fact-check**
- **Claim:** An `ident` attribute that only a *global* `core.attributesFile` sets (hidden from the gate's git by harden) expands `$Id$` at checkout, and `--check` refuses the self-merge brief.
  **Location:** `scripts/build-loop.sh:654-656, 686-691`
  **Evidence:** executed
  **Verified:** probe `ident_global`. The file read `x $Id: 5692e3a1... $`. `--check` refused (here at the git status rule, which runs without the global attributes and so sees the bytes differ), exit 2.
  **Not verified:** the same case with a stat-clean index, so that only the byte hash catches it. The i2 locale probe and the bats ident test cover the hash arm for a repo-level attribute, not for this global one.
  **route: code-fact-check**
- **Claim:** An intent-to-add index entry (`git add -N`) for a file main lacks makes `--check` refuse a self-merge brief.
  **Location:** `scripts/build-loop.sh:654-656`
  **Evidence:** executed
  **Verified:** probe `ita`. Status showed ` A n.md`, and `--check` printed the git status refusal, exit 2.
  **Not verified:** an intent-to-add entry *at a path main stores*, which git refuses to create in the ordinary flow.
- **Claim:** A `core.worktree` in `.git/config` pointing at a clean copy of main elsewhere does not let a dirty checkout pass. The run stops at the state gate.
  **Location:** `scripts/build-loop.sh:244-248, 283-288`
  **Evidence:** executed
  **Verified:** probe `worktree`. `rev-parse --show-toplevel` from the dirty checkout printed the other directory. The script cd'd there, could not find the git dir, and printed "refuse state config: its path could not be read", exit 2. With the key unset, the dirty checkout was refused by git status.
  **Not verified:** a `core.worktree` whose target directory itself holds a `.git` file pointing back at the repository. Not run.
- **Claim:** Once `co` is set (line 739), every path out of `check_line` prints a first line that does not start `ok`.
  **Location:** `scripts/build-loop.sh:739-757`
  **Evidence:** read-static
  **Verified:** read check_line whole. Line 740 prints `${co:-ok ...}`, which is co when it is set. Line 747 prints the blob refusal. Line 750 prints the lower-casing refusal. Line 756 tests `co` before `nd` and `ok`. Lines 776-777 count any non-`ok` first line as a failure, exit 2.
  **Not verified:** U2c's floor walk, not yet wired. It needs to run inside this subshell after line 739 and only when `co` is empty (plan U2c bullet).
  **route: code-fact-check**

## Primitive sweep

Primitive: process exec / filesystem lookup on repo-derived paths (checkout_gate, and gate_repo's env list)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:634` `git rev-parse --local-env-vars` | S4 | fixed name list; `${!v+set}` treats empty as set | cleared (i2 probe `prefix`) |
| `build-loop.sh:639` `git rev-parse --verify -q HEAD^{commit}` | S2 | compared to S6; failure → "unreadable" refuses | cleared |
| `build-loop.sh:643` `git config --type=bool --get` | S3 (constant keys) | rc > 1 refuses; a bad value ends the run earlier | Finding 1 (fails closed, wrong exit class) |
| `build-loop.sh:650` `ls-files -v -z \| tr \| awk` | S2, S1 names | pipefail; any non-`H ` line refuses | cleared (probe `gsparse`; a newline name refuses here under the index reason, fact-check r1, fail-closed) |
| `build-loop.sh:654` `git status ... 2>err` | S2, S5 effect | output or stderr refuses | cleared (probes `ita`, `ident_global`; i2 fifo, symparent, gsym, gl, smudge) |
| `build-loop.sh:661-662` `ls-files -z --others` to a file, then `tr \| awk` | S2 | failure refuses; `/`-ended entry refuses | cleared (bats nested; i2 `gitfile`); untracked-cache candidate listed |
| `build-loop.sh:664` `ls-tree -r -z --full-tree` | S6 | failure refuses | cleared |
| `build-loop.sh:666` `[[ $r =~ $re ]]` | S1 | LC_ALL=C; no match refuses | cleared (bats `\xff` name under C.utf8) |
| `build-loop.sh:673` `ls -A -- PATH` | S1 + S2 | `--`; `-L` and a failure refuse | cleared (bats chmod 111, symlink) |
| `build-loop.sh:688` `git hash-object --no-filters --stdin-paths` | S1 names, S2 bytes | newline / leading `"` / trailing CR refused first | cleared (bats `"q"`, `r\r`; probe `autocrlf`) |
| `build-loop.sh:537` gate_repo `env -u` list | S4 | `callervar` | cleared (GIT_CONFIG unset there, refused in checkout_gate) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | An invalid core.* boolean exits 1 with "Not inside a git repository", not the documented checkout refusal (fail-closed) | Informational | B4 | `scripts/build-loop.sh:124-125, 643-645, 283` | High |

## Overall Assessment

Across the whole branch I found no way, within the threat model, to get a self-merge brief past checkout_gate. That covers committed content and ordinary checkout state, and it includes checkout state that config the gate never reads (global sparse checkout, global attributes file, repo autocrlf) produced. Every case I probed refused with exit 2, except the invalid-boolean case, which also fails closed but under exit 1 and a misleading message (Finding 1, Informational). The design rests on its effect check: git status, then the index bits status hides, then a raw byte hash of every regular file. That is why the gate does not depend on predicting attributes or config scopes. The fact-check residue about global/system `core.*` settings is cleared for sparse checkout by execution, already cleared for symlinks in i2, and cleared for ignoreCase by reasoning only (see its Not verified line). The green mutants that fact-check r2 lists are benign for security. A non-exported `LC_ALL` still pins bash's own regex locale (bash calls setlocale on assignment), and `tr`/`awk` read only ASCII tags there. `import_reset` has no observable effect until U2c adds a walk. No findings within the code paths read; endorsement claims pending execution verification. The most important item to carry forward is U2c's part, not this branch's: run the floor walk in the same `check_line` subshell, after line 739, only when `co` is empty, under LC_ALL=C, and add the test that makes `import_reset`'s removal go red.

## Goal-Alignment Note

**Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u2b2/docs/reviews/security-reviewer-review-2026-10-08-build-loop-u2b2-final.md (first line `Commit: 1f4f7a21`), structured per the critic skill."

**Answered:** The final confirming security pass over the full U2b2 branch under Q-133 [3]. I read the whole script and the lib's contract header. Six new probes ran: global sparse checkout, repo autocrlf, global ident attribute, intent-to-add, `core.worktree` elsewhere, and invalid booleans. Five failed closed with exit 2, and the invalid booleans failed closed with exit 1. One Informational finding (Finding 1), which confirms fact-check r3's Incorrect item by execution. No new Medium-or-above finding.

**Out of scope:** the same-uid race between the gate and U2c's read (Q-103 residual); harden's trust in the caller's config pairs; the reader model (U2b3); the walk's own FIFO start (row 440); per-brief cost and the unenforced "at most the slot count" wording (performance/API, override row for per-brief cost). I did not re-raise override rows 366/373, 387, 391/392/397, 399, 439, 440, 459/465 or 527-530.

**Escalate:** none.

**Questions/Decisions:** none new. For U2c and U3 (no question entry needed): U3 should treat any non-zero `--check` exit as a refusal (Finding 1). U2c should add the test that pins `import_reset` per decision.
