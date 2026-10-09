Commit: c10b972a

# Security Review: feat/build-loop-u2b2 (U2b2, the gate's checkout), iteration 1

**Scope:** `git diff main...HEAD` on feat/build-loop-u2b2: `scripts/build-loop.sh` (new `checkout_gate`, its call at line 726, the refusal in `check_line`), `scripts/lib/dev-cycle-read.sh` header item 3, `test/scripts/build-loop-check.bats` (three new tests). `scripts/build-loop.sh` read whole, and lines 1-200 of the lib (caller contract, `scrub_reexec`, `pathform`).
**Date:** 2026-10-08
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b2.md (k=1: 20 claims, 12 Verified, 8 Mostly accurate, 0 Incorrect)
**Threat model:** Q-133 [3]. A hostile same-uid loop racing the gate is out of scope (Q-103 residual). In scope: honest-path correctness, fail-closed behaviour, and committed content or ordinary checkout state getting a self-merge brief past the gate.

No HALT escalation: no pattern from the escalation list matched.

## Trust Boundary Map

```
B1 (new): [main's tree: path names and modes (committed content)] → [ls-tree -z → bash =~ $re → hash-object --stdin-paths line protocol] → [CHECKOUT_WHY verdict]
B2 (new): [checkout state: working-tree bytes, dir permissions, index flags] → [git status / ls-files -v / ls-files --others / ls -A / hash-object] → [CHECKOUT_WHY verdict]
B3 (new): [caller environment: GIT_* repo-local vars, LC_ALL/LANG] → [--local-env-vars loop; bash regex locale] → [checkout_gate's own reads]
B4 (new): [repo config core.symlinks / core.ignoreCase / core.sparseCheckout] → [git config --type=bool --get] → [CHECKOUT_WHY verdict]
B5: [CHECKOUT_WHY (process global, set once)] → [check_line, pol == self-merge] → [refuse line / merge_result]
```

| Label | Source | Mutability | Trust (per sink class) |
|---|---|---|---|
| S1 | Path names and modes in `$MAIN_SHA`'s tree | committed content. A self-merge can only add pathform-clean names (N rules), but a review merge or older history can hold any byte string. | UNTRUSTED toward parsers (bash regex, git's line-oriented `--stdin-paths`) and toward filesystem lookups (`ls -A`) |
| S2 | Working-tree bytes, file types and directory permissions | runtime-mutable (any same-uid process, the user's own git config conversions) | UNTRUSTED for every read. This is exactly what the gate judges. |
| S3 | `.git/config` core.* keys | runtime-mutable | UNTRUSTED. Read as a value, fail-closed on unreadable. |
| S4 | Caller env: `GIT_CONFIG*`, `GIT_CONFIG_PARAMETERS`, `LC_ALL`/`LANG` | caller / session environment | Trusted as to value per harden's comment ("the caller's own environment is trusted"). The gate still has to be **correct under any locale the caller has**. The user's session sets `LC_ALL=en_US.UTF-8` (observed with `env`). |
| S5 | `MAIN_SHA` | derived by resolve_main after state_gate and default_gate | trusted for every sink |
| S6 | `GATE_TMP` | mktemp -d of this process | trusted (a race on it is the out-of-scope Q-103 residual) |

What crosses: the gate turns S1 (main's names) and S2 (the checkout) into a single boolean, which then lets a self-merge brief proceed. The diff assumes three things. First, every regular file main stores reaches `hash-object` under its own name. Second, every ls-tree record matches `$re`. Third, an `ls -A` failure means "nothing there". Findings 1-3 each break one of these assumptions. All three are fail-open, and all three were reproduced by execution.

## Findings

#### 1. The byte check hashes a different file for names that start with `"` or end with CR

**Severity:** Medium
**Location:** `scripts/build-loop.sh:640-647` (the per-path loop, then `printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths`)
**Boundary:** B1
**Move:** 2 (implicit sanitization assumption), 11 (bypass enumeration)
**Confidence:** High that the mechanism works (executed). Low likelihood: the name has to already be on main, because self-merge's pathform cannot add it, and a conversion source has to apply to it.
**Legibility-target:** code (`checkout_gate`'s name refusals next to the newline one) + a bats case + the `--check` header's refusal list

**Evidence (verbatim):**
```
  while IFS= read -r -d '' r; do
    [[ "$r" =~ $re ]] || continue
    ...
    [[ "${BASH_REMATCH[3]}" != *$'\n'* ]] || { CHECKOUT_WHY="a file on the default branch has a newline in its name"; return 1; }
    ids+=("${BASH_REMATCH[2]}"); ps+=("${BASH_REMATCH[3]}")
  done < "$GATE_TMP/tree"
  [[ ${#ps[@]} -gt 0 ]] || return 0
  # --stdin-paths: one hash-object for every file (one per path cost a process each).
  if ! x="$(printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths 2>/dev/null)" || [[ "$x" != "$(printf '%s\n' "${ids[@]}")" ]]; then
```
`--stdin-paths` C-unquotes a line that begins with `"`, and it strips a trailing CR. The newline refusal covers one of the protocol's three hazards, but not the other two. Executed probe (git 2.39.5, LC_ALL=C). Main stores `"q"` and `q`, both `$Id$\n`, with `.gitattributes` `?q? ident` (the pattern matches only the three-character name). After `git checkout -- '"q"'`, the checkout's `"q"` holds `$Id: 055c8729... $`, `git status` is clean, and `--check` printed `ok docs/working/briefs/2026-10-01-x.md ...` with exit 0. The control (main stores only `"q"`) refused with "a file's checked-out bytes are not the default branch's blob". The same `ok` result came from `x\r` beside `x` with `x? ident`. The checked-out bytes of `"q"` and `x\r` are never compared. The fact-check already flagged this (Claim 4). The probe shows it is a full bypass of item 3 whenever a sibling file with matching bytes exists, and not only a theoretical gap. With ident or eol the impact is small. With a smudge filter from the user's global config (git-lfs is a common one, and harden hides global config from the gate) a session would read arbitrary bytes under that name.

**Recommendation:** Treat these names as the newline case already is: refuse a name that starts with `"` or ends with `\r` ("a file on the default branch has a name hash-object reads as another path"). Prefixing `./` alone is not enough, because it avoids the unquoting but not the CR strip. Add a bats case for each name class.

#### 2. An ls-tree record the regex does not match is skipped, so under a UTF-8 locale every file with a non-UTF-8 name escapes the byte check

**Severity:** Medium
**Location:** `scripts/build-loop.sh:604` (`re=...(.*)$`), `scripts/build-loop.sh:634` (`[[ "$r" =~ $re ]] || continue`)
**Boundary:** B1, B3
**Move:** 3 (error path), 11
**Confidence:** High that the mechanism works (executed). Medium that the environment is reachable: the user's sessions export `LC_ALL=en_US.UTF-8`, which is not installed in this sandbox (setlocale warns and bash falls back to C) but would be on a host that has it.
**Legibility-target:** code (`checkout_gate`: a locale pin plus a fail-closed default) + a bats case run under `C.utf8`

**Evidence (verbatim):**
```
  local v x rc r n ps=() ids=() re=$'^(100644|100755|160000) [a-z]+ ([0123456789abcdef]+)\t(.*)$'
...
    [[ "$r" =~ $re ]] || continue
```
In a UTF-8 locale, bash's ERE `.` does not match an invalid byte. `LC_ALL=C.utf8 bash -c '... [[ $'"'"'100644 blob ab\tdocs/\xff.md'"'"' =~ $re ]]'` printed `nomatch`; under `C` it printed `match`. End to end: main stores `docs/\xff.md` (`$Id$`) with `docs/?.md ident`. Under `LC_ALL=C` `--check` refused it (item 3), but under `LC_ALL=C.utf8` it printed `ok ...` with exit 0, while the checkout's copy held the expanded `$Id: ... $`. build-loop.sh never pins the locale. Contract item 1 asks the walk's caller for `LC_ALL=C`, but `--check` inherits the session's locale, and `checkout_gate` is the only reader here whose failure mode is "skip". The same `|| continue` also silently skips mode `120000`. That is intended (git status covers symlinks), but it means the default for "unrecognised record" is allow.

**Recommendation:** Add `local LC_ALL=C` at the top of `checkout_gate`, or export it for the whole script if contract item 1 is meant to hold for U2c anyway. Also make the default fail closed: match `^([0-7]{6}) ([a-z]+) ([0-9a-f]+)\t(.*)$`, skip only an explicit `120000`, and refuse any record that does not match.

#### 3. A gitlink directory whose listing fails passes as empty, but its files can still be read by name

**Severity:** Medium (floor rule: a named mechanism. A self-merge cannot produce this state. It is ordinary checkout state that some process has to set up.)
**Location:** `scripts/build-loop.sh:635-638`
**Boundary:** B2
**Move:** 3 (error path), 11
**Confidence:** High that the mechanism works (executed). Low that it is in scope: no committed content can set a directory's mode, so it needs a `chmod` on the main checkout, which sits close to the out-of-scope Q-103 actor. On the honest path, a submodule directory owned by another uid would also hit it.
**Legibility-target:** code (gitlink branch) + a bats case

**Evidence (verbatim):**
```
    if [[ "${BASH_REMATCH[1]}" == 160000 ]]; then
      x="$(ls -A -- "${BASH_REMATCH[3]}" 2>/dev/null)" || x=""
      [[ -z "$x" ]] || { CHECKOUT_WHY="a gitlink is checked out with files, whose instruction files the walk does not read"; return 1; }
      continue
    fi
```
`|| x=""` merges "absent" (correct: pass) with "present but unlistable" (wrong: pass). Executed probe: a gitlink `sub` on main and the file `sub/` + the instruction file. `--check` refused it ("a gitlink is checked out with files"). After `chmod 111 sub`, `cat` of that file by name still printed `evil`, and `--check` printed `ok ...` with exit 0. A session that opens files under `sub/` loads the file by path, without needing to list the directory, so the property rows 366/373 rely on fails silently.

**Recommendation:** Refuse when the path exists (`[[ -e p || -L p ]]`) and `ls -A` fails: "a gitlink's directory could not be listed". Only a genuinely absent path should pass.

#### 4. The header and tests do not cover several refusal branches; one test comment overstates

**Severity:** Informational
**Location:** `scripts/build-loop.sh:112-126` (header), `scripts/lib/dev-cycle-read.sh:52-57`, `test/scripts/build-loop-check.bats` (U2b2 tests, "Each index flag hides a change")
**Boundary:** B2, B3
**Move:** 3
**Confidence:** High (fact-check Claims 3a, 11, 18; I re-read the code)
**Legibility-target:** header refusal list + bats

**Evidence (verbatim):** header: `a repo-local GIT_* variable set (GIT_INDEX_FILE, GIT_WORK_TREE...), core.symlinks false, core.ignoreCase or core.sparseCheckout true`. The code also refuses on "or unreadable", newline names, and listing failures, and it exempts `GIT_CONFIG*`/`GIT_NO_REPLACE_OBJECTS`/`GIT_PREFIX`. None of these appear in the header, and no test exercises them, so a regression that turns any of these fail-closed branches into fail-open would pass CI. This is not exploitable today. It is recorded so that the fixes for findings 1-3 add their cases next to these.

**Recommendation:** List the extra refusal reasons and the exemptions in the header. Add bats cases for GIT_WORK_TREE, an unmerged entry, and an unreadable core.* value (for example `core.symlinks = maybe`), alongside the cases from findings 1-3.

## Untested bypass candidates

- **Dangling symlink at a gitlink path.** `ls -A` fails and the gate passes. It is not probed whether `git status --ignore-submodules=none` reports the type change first. Not tested: low value, since a dangling link holds no file.
- **FIFO at a tracked regular-file path.** If git status did not flag it, `hash-object --stdin-paths` would block on open(2) with no timeout. It is likely caught as a typechange by status, but not probed. This is related to row 440, which is still open.
- **Directory holding a `.git` *file* with an invalid gitdir.** It is unclear whether git lists it as `dir/` (refused) or lists its files (allowed, read by the walk as untracked). Not probed.
- **`config.worktree` setting core.symlinks/ignoreCase under `extensions.worktreeConfig`.** `git config --get` reads the same files checkout does, so the result should be consistent. Not probed.
- **Caller-env `GIT_CONFIG` / `GIT_CONFIG_PARAMETERS` switching the three core.* refusals off** (fact-check Claim 6). This is out of scope: harden trusts the caller's environment by design, and git status still catches the core.symlinks effect.

## Endorsement Claims

- **Claim:** With a repo-local `core.worktree` pointing at another directory, `--check` refuses at the state gate before checkout_gate runs ("refuse state config: its path could not be read", exit 2).
  **Location:** `scripts/build-loop.sh:233-234, 269-274`
  **Evidence:** executed
  **Verified:** probe `worktree`: `git config core.worktree <other>`, then `--check` on a self-merge brief printed `refuse state config: its path could not be read` with exit 2.
  **Not verified:** a `core.worktree` that points at a directory which itself holds a `.git` (a second repo's work tree). That case belongs to the reader model (U2b3).
  **route: code-fact-check**
- **Claim:** A nested repository created inside a *tracked* directory (`git -C docs init`) does not hide that directory's untracked files: `git ls-files --others` lists `docs/<instruction file>` as the outer repo's untracked file, so the walk lists it too. The gate's `ok` for this case is consistent with the walk.
  **Location:** `scripts/build-loop.sh:629-631`
  **Evidence:** executed
  **Verified:** probe `nestedtracked`: `git status` showed `?? docs/<file>`, `ls-files --others` listed it, and `--check` printed ok.
  **Not verified:** how the walk itself (U2c's caller of main_imports) treats a path under a directory that holds `.git`. It is not wired in this unit.
- **Claim:** For regular files with ordinary names under LC_ALL=C, an ident or eol conversion that git status does not show is refused by the byte comparison.
  **Location:** `scripts/build-loop.sh:643-647`
  **Evidence:** executed
  **Verified:** probe `quotectl` (an ident-expanded `"q"` with no sibling refused) and probe `badutf` under `LC_ALL=C` (refused), plus the branch's own bats test for `docs/i.md` with ident and eol=crlf.
  **Not verified:** a smudge filter from the user's global config (`filter.<x>.smudge`). It is expected to be caught the same way but was not executed.
  **route: code-fact-check**
- **Claim:** `checkout_gate` runs only when `POLICY == self-merge`, and `check_line` reads `CHECKOUT_WHY` only for `pol == self-merge`, which status_line sets only when `POLICY == self-merge`. So a review brief is not affected, and a self-merge brief never sees an unset verdict.
  **Location:** `scripts/build-loop.sh:482, 668-670, 726`
  **Evidence:** read-static
  **Verified:** read line 482's condition, the call at 726, and the check at 668.
  **Not verified:** whether `checkout_gate`, run under `|| true` (which disables `set -e` in its body), has any unchecked command whose failure leaves `CHECKOUT_WHY` empty. Read: every `[[ ]]` has an explicit refusal, except the two fail-open spots in findings 2 and 3, and the `for v in $(git rev-parse --local-env-vars)` loop, which runs zero times if rev-parse fails. That loop has the same shape as gate_repo's prior art.

## Primitive sweep

Primitive: process exec / filesystem lookup on repo-derived paths (checkout_gate)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:606` `git rev-parse --local-env-vars` | S4 | none needed (output is a fixed list of names) | cleared, though the loop runs zero times on failure (noted in Endorsements) |
| `scripts/build-loop.sh:615` `git config --type=bool --get KEY` | S3 (keys are code constants) | rc ≤ 1 and value check | cleared, fail-closed on unreadable |
| `scripts/build-loop.sh:621` `git ls-files -v -z` pipeline | S2 | pipefail plus `|| n=x` | cleared |
| `scripts/build-loop.sh:623` `git status --porcelain=v1 -z ... 2>&1` | S2 | any output or failure refuses | cleared |
| `scripts/build-loop.sh:629-630` `git ls-files -z --others` to a file, then awk | S2 | written to a file first; listing failure refuses | cleared |
| `scripts/build-loop.sh:632` `git ls-tree -r -z --full-tree $MAIN_SHA` | S5 | failure refuses | cleared |
| `scripts/build-loop.sh:634` bash `=~ $re` on ls-tree records | S1 | `|| continue` | **Finding 2** (locale-dependent skip, fail-open default) |
| `scripts/build-loop.sh:636` `ls -A -- PATH` | S1 path, S2 state | `--` against option injection | **Finding 3** (failure reads as empty) |
| `scripts/build-loop.sh:645` `git hash-object --no-filters --stdin-paths` | S1 paths over a line protocol | newline refusal only | **Finding 1** (leading `"` unquoted, trailing CR stripped) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | hash-object `--stdin-paths` reads `"q"` as `q` and `x\r` as `x`: those files' bytes are never compared | Medium | B1 | `scripts/build-loop.sh:640-647` | High (mechanism), low likelihood |
| 2 | Unmatched ls-tree records skipped; under a UTF-8 locale every non-UTF-8 name escapes the byte check | Medium | B1, B3 | `scripts/build-loop.sh:604, 634` | High (mechanism), Medium (env) |
| 3 | Gitlink dir that `ls -A` cannot list passes as empty; files still readable by name | Medium | B2 | `scripts/build-loop.sh:635-638` | High (mechanism), Low (in scope) |
| 4 | Header/test coverage of the refusal branches; "each index flag hides a change" overstated | Informational | B2, B3 | header 112-126; bats U2b2 tests | High |

## Overall Assessment

The design is sound: item 3 is checked by its effect (hashing the checkout against main's blobs) rather than by predicting attributes, and the probes confirm this catches ident and eol conversions that git status misses. The weaknesses are at the edges of the parsing, not in the architecture. Three spots default to *allow* on input they did not expect: a record the regex does not match, a name the `--stdin-paths` line protocol rewrites, and an `ls` that fails. Each was reproduced end to end with `--check` printing `ok` for a self-merge brief. All three can be fixed in place, a few lines each, and none needs a redesign. The most important fix is Finding 2. Pinning `LC_ALL=C` in `checkout_gate` and making an unmatched record refuse closes a gap that the user's real session locale (`en_US.UTF-8`) can reach on the honest path. Endorsements are scoped as listed, and those marked `route: code-fact-check` await execution verification.

## Goal-Alignment Note

**Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u2b2/docs/reviews/security-reviewer-review-2026-10-08-build-loop-u2b2.md (first line `Commit: c10b972a`), structured per the critic skill."

**Answered:** Security design review, iteration 1, of U2b2's checkout gate, against the Q-133 [3] threat model. There are three Medium fail-open findings, all executed. There is one Informational finding on documentation and test coverage.

**Out of scope:** TOCTOU between checkout_gate and a later walk, and on GATE_TMP (the Q-103 residual). Caller-env `GIT_CONFIG*` overrides (harden trusts the caller). Reader-model questions such as other checkouts, outside-repo starts and core.worktree targets (U2b3; rows 425/431/432/437/477). Row 440 (FIFO start file), which stays open and is only listed as an untested candidate here. The override-log rows named in the brief were not re-raised.

**Escalate:** none.

**Questions/Decisions:** Should build-loop.sh export `LC_ALL=C` for the whole process, so that contract item 1 is enforced rather than asked of the caller? Finding 2's narrow fix works either way, but U2c's walk will need the same guarantee.
