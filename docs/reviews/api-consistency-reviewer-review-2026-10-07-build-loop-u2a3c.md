Commit: 21b35ebf

# API Consistency Review — feat/build-loop-u2a3c (iteration 2)

**Scope:** `git diff main...HEAD` (main e5d0f838, HEAD 21b35ebf). The public surface is the reader lib's function contracts in `scripts/lib/dev-cycle-read.sh`, plus the caller contract that A5 and the plan's U2b bullet state.
**Date:** 2026-10-07
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3c.md` (Commit 21b35ebf), Claims 1-3, 8, 13-15, 17, 19 and its Escalations. I did not re-verify behaviour the report verified.

## Baseline Conventions

- **Function names** are snake_case. Each is a verb or a noun-of-result: `lower`, `nul_list`, `md_ls`, `checkout_md`, `tree_starts`, `import_targets`, `import_home`. Prefix families mark a subsystem: `import_*` is the parser side, `main_*` reads main's commit, and `check_*` prints answers.
- **Arguments:** functions that write the caller's variables take the variable names first and bind them by `local -n` with a short private prefix: `nul_list NAME CMD...` uses `nl_a`. The signature is written in the comment header as `name ARG ARG...`.
- **Return codes:** 0 means success or true, and nonzero means failure. Callers use `|| return 1` or `if`. Walks return 1 and set their result variable to `error`. `main_checkout` is the only three-valued function, and that is settled in an override row.
- **Budgets:** the lib holds a global `IMPORT_<KIND>_MAX` constant. A walk passes what remains to the parser through an env-style shell variable, `IMPORT_LEFT`. When that variable is unset it defaults to the global, and the comment documents what happens when it is "not a number".
- **Docs contract:** the lib's block comments are the authority. Known-issues A5 and the plan bullets are the copies that the next units (U2a4, U2b) read. Override rows name those copies as their mitigation.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `capped_read` | function | `nul_list`, `md_ls`, `checkout_md` | `scripts/lib/dev-cycle-read.sh:684-710` | Consistent: snake_case, it reads stdin like a filter, and nonzero means failure |
| `lower_all` | function | `lower`, `instruction_names` | `scripts/lib/dev-cycle-read.sh:515,683` | Consistent: the batch form of `lower`, with NUL-terminated output read through `nul_list` like the other NUL lists |
| `import_work OUT TOTAL` | function | `import_targets`, `import_home`, `nul_list NAME CMD` | `scripts/lib/dev-cycle-read.sh:645,638,690` | Consistent: `import_*` family, namerefs first, private prefix `iw_` |
| `main_checkout ENT MEMO PATH` | function (signature changed from `ENT PATH`) | `nul_list NAME …`, `blocker PATH KIND` | `scripts/lib/dev-cycle-read.sh:690,108` | Consistent ordering (namerefs first). The name is settled (override row). The MEMO contract is underdocumented (Finding 3) |
| `IMPORT_WORK_MAX` | global | `IMPORT_OUT_MAX` | `scripts/lib/dev-cycle-read.sh:502` | Consistent: `IMPORT_<KIND>_MAX` |
| `IMPORT_WORK_LEFT` | env input | `IMPORT_LEFT` | `scripts/lib/dev-cycle-read.sh:519-521,667` | The name is consistent with its own MAX (the older `IMPORT_LEFT` is the less regular one; not filed). Its unset and non-numeric semantics are not (Finding 2) |
| `/N` trailer line | output field | none: the parser's output was names only | none — searched `scripts/lib/dev-cycle-read.sh` for in-band output trailers | New convention. It is unambiguous, because names never start with `/` (fact-check 15). It is opt-in on `IMPORT_WORK_LEFT` (Finding 2) |

## Findings

#### 1. The rebase dropped U2a3c's caller contract from A5 and the U2b bullet, where U2a4 and U2b will read it

**Severity:** Inconsistent
**Location:** `docs/working/known-issues-dev-cycle.md:18` (A5), `docs/working/plan-build-loop-handoff.md:279` (U2b bullet); `docs/reviews/override-log.md:439-441`; `scripts/lib/dev-cycle-read.sh:477-492`
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** High
**Legibility-target:** docs

The lib states four obligations on the caller and limits of the walk:

- `# ... so a caller whose checkout may have changed (a file added or edited) sets IMPORTED_MAIN_DONE="" to walk again` (`:487-489`)
- `# or a checkout listing git prints any stderr for, fail the walk` (`:475-476`)
- `Not covered (known issue A5): ... a start that is not a regular file or symlink (git does not list a FIFO).` (`:477-481`)
- `The walk reads the checkout as one snapshot` (`:483-484`)

The two documents the next units read hold none of these. At HEAD, A5 has no `IMPORTED_MAIN_DONE`, `FIFO` or `snapshot` (fact-check Claims 1-3). The U2b bullet now ends its checkout sentence at `It names the checkout --check runs from (the walk reads its untracked, ignored and index-only start files and the imported files main lacks there); U2b is to refuse ...`.

The pre-rebase bullet (`backup/u2a3c-pre-rebase-2b1399ab`) continued: `and owes the walk three things: that checkout final before the walk, or IMPORTED_MAIN_DONE cleared (the cache key ignores the checkout); a git that prints nothing on stderr for ls-files (any stderr fails the walk closed); and the git environment the override log hands the caller (GIT_INDEX_FILE, GIT_WORK_TREE, fsmonitor, sparse checkout, core.ignoreCase, replace refs)`.

Three override rows still give these documents as the mitigation for deferring their findings: 439 says "Comment, A5 and the U2b bullet now say the caller clears IMPORTED_MAIN_DONE…", 440 says "Listed in A5…", and 441 says "…written in the block comment and A5". The lib's `Not covered (known issue A5)` pointer names a row that lacks the FIFO item.

The consumer impact: U2b runs `--check` from a checkout that may change between walks. If it caches the walk without clearing the key, the gate answers from a stale walk. That is the 🟡 Must Address row 439, which was deferred on the strength of this text. If U2b runs git with a config that warns on stderr, every walk fails closed, and nothing in the plan tells it why. The git-environment handoff, from row 387, is now reachable only through the override log.

**Recommendation:** Restore U2a3c's clauses into main's wording. In A5, add the cache-clear sentence and the FIFO and swapped-file not-covered items. In the U2b bullet, restore "owes the walk three things …". Then rows 439-441 are true again. This is a docs-only fix and needs no code change.

#### 2. `IMPORT_WORK_LEFT` does not follow `IMPORT_LEFT`'s defaulting: unset, it switches the output format off and falls back to a literal, not to `IMPORT_WORK_MAX`

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:517-524, 622, 667`
**Move:** 7 (asymmetry), 8 (nullability)
**Confidence:** High
**Legibility-target:** code comment

The sibling input defaults to its global, and its comment covers the bad-value case: `IMPORT_LEFT (what may still be printed; IMPORT_OUT_MAX when unset or empty, and 0 when not a number, so the first name fails it)`. The code is `IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}"`.

The new input does neither. The code is `IT_WORK="${IMPORT_WORK_LEFT:-}"`, and in awk `wmax = 50000000; trail = (ENVIRON["IT_WORK"] != ""); if (trail && ENVIRON["IT_WORK"] + 0 < wmax) wmax = ENVIRON["IT_WORK"] + 0`. When the variable is unset or empty, the per-file bound is a second copy of the literal 50,000,000, independent of `IMPORT_WORK_MAX`. A caller that lowers `IMPORT_WORK_MAX` and calls `import_targets` directly is not bounded by it.

The same variable also decides the output shape (a trailing `/N` line or none). Every other parser input changes only limits, never format. When the value is not a number, it reads as 0 and the first candidate fails, as for `IMPORT_LEFT`, but the comment does not say so.

Today only the two walks set the variable, and both always do, so no current caller breaks. The comment says "set by a walk", and that is accurate. The asymmetry matters to the next caller that uses `import_targets` directly, such as a U2b reader-model probe, or to a test that copies the `IMPORT_LEFT` idiom.

**Recommendation:** Extend the `import_targets` comment to say what happens when the variable is unset or empty (no trailer, per-file bound 50,000,000) and when it is not a number (0). Alternatively, derive the awk literal from `IMPORT_WORK_MAX` so the two numbers cannot drift apart.

#### 3. `main_checkout`'s MEMO contract does not say that a memo hit also skips main's mode check, so a MEMO must be fresh per walk and paired with one ENT

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:711-742`
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** code comment

The header says MEMO holds the ancestors "already passed (a token's prefixes share them, so each directory costs its realpath once per walk)". In the body, a hit skips both the mode test and the checkout test:

```
    [[ -z "${mc_m[$c]+set}" ]] || continue
    [[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1
```

(The excerpt is from the ancestor loop, `:727-729`. The loop continues with the absent, file and directory branches, and the function then tests PATH itself.)

So the answer is sound only when MEMO was filled against the same ENT and the same checkout snapshot. `main_imports` keeps that pairing, because `local -A ... pok=()` is fresh per walk. However, override row 440's revisit trigger already names a second caller: "U2b, which could run main_checkout on the fixed start names directly". A U2b caller that keeps a memo across walks, or across a checkout change (the cache-clear case in Finding 1), would skip a link or gitlink refusal.

The header also says "0 for a plain checkout file to walk". An unreadable plain file returns 1 (`if rawfile "$c"; then [[ -r "$c" ]]; return; fi`). The block comment says "readable plain file" correctly (fact-check Claim 19).

**Recommendation:** Add a clause to the header: "MEMO is the caller's, fresh per walk, filled only by calls with this ENT; a hit skips both checks". Change "plain checkout file" to "readable plain checkout file".

#### 4. The lib-inventory test omits the new public `import_work`

**Severity:** Minor
**Location:** `test/scripts/dev-cycle.bats:1108-1110`
**Move:** 3 (test drift)
**Confidence:** High
**Legibility-target:** test

This diff adds two of its three new functions to the "sourcing the reader lib defines its functions" list (`... md_ls checkout_md main_checkout lower_all capped_read; do`), but not `import_work`. The variable lists also lack `IMPORT_WORK_MAX`. `IMPORT_OUT_MAX` and `import_home` were already missing on main. The pattern is that each unit appends the functions it adds, and this diff follows it for two of three. The fact-check test-strategy escalation also raised this.

**Recommendation:** Append `import_work` to the function list, and `IMPORT_OUT_MAX IMPORT_WORK_MAX` to the `declare -p` list.

#### 5. A5's stderr rule is narrower than the code ("warns about" vs "prints any stderr for")

**Severity:** Minor
**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** docs

At HEAD, A5 says `and a checkout listing git warns about fail it`. The pre-rebase text said `a checkout listing git prints any stderr for`. The code fails on any stderr: `checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }`, and the lib comment says the same (`:476`). A reader of A5 could expect a non-warning stderr line, such as a config deprecation notice or a hook's output, to pass. This is the doc half of the U2b obligation lost in Finding 1.

**Recommendation:** Use the lib's wording, "prints any stderr for", when restoring Finding 1's text.

#### 6. Stale or over-broad statements of the refusal contract outside the lib

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:277`; `docs/working/checkpoint-build-loop-handoff.md:21` (outside the diff)
**Move:** 3
**Confidence:** High
**Legibility-target:** docs

The U2a3c bullet says `(a plain file main lacks is walked, only a non-plain node fails)`. Plain paths also fail when the file is unreadable, when it lies under main's link or gitlink, or when it lies under an unsearchable ancestor (fact-check Claim 8). The same bullet's `an unsearchable checkout directory fails the walk` holds only for a path below it, because a directory named alone answers 2.

The checkpoint row still gives the old signature, `main_checkout ENT PATH`. The checkpoint is a working doc and is refreshed at merge, so this is noted for that refresh.

**Recommendation:** In the plan bullet, use A5's list ("a non-plain node, an unreadable file, or a path under main's link or gitlink or an unsearchable directory"). Update the checkpoint row at merge.

#### 7. `isimported main` changed semantics for `.git` paths, and the lib comment no longer says anything about `.git`

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:461-492`; removed block at main's `:779-785`
**Move:** 6 (versioning: changed behaviour)
**Confidence:** Medium
**Legibility-target:** code comment

On main, a top-level `.git` gitfile holding `@` failed the walk, so every path answered imported, and main's comment explained the special case. At HEAD, `.git` is an ordinary checkout path: a gitfile is parsed, and `.git/…` files that an import names are read. The three tests were inverted on purpose. The plan's carried sentence records the intent ("the main walk's top-level `.git` file is then read as a checkout file"). The lib's block comment, which is the contract text, says nothing either way. The fact-check security escalation (the gate's answer depends on `.git/` internals) is the substantive side and is not mine.

**Recommendation:** Optionally add half a sentence to the block comment, for example "`.git` and paths below it are checkout paths like any other", so the absence of a special case reads as deliberate.

## What Looks Good

- The three new helpers fit the lib's grain. `lower_all` is the batch form of `lower`, read through `nul_list`, which matches how every other NUL list is consumed. `import_work OUT TOTAL` follows `nul_list NAME …`: namerefs first, a private `iw_` prefix, 0 or 1 return. `capped_read` returns nonzero on a failed read, which suits the `|| { IMPORTED_MAIN=error; return 1; }` callers.
- `IMPORT_WORK_MAX` mirrors `IMPORT_OUT_MAX` in name and placement. Its comment carries the same "A caller that changes it clears both caches" obligation.
- The trailer is in-band but unambiguous: names never start with `/`, and `import_work` accepts only a whole last line (fact-check Claim 15). Unset, the parser's output is byte-identical to main's (Claim 13), so existing direct callers and tests of `import_targets` are untouched.
- The order of trailer strip and output budget is correct at all three call sites: `import_work` runs before `used += ${#out}`, so the trailer is never charged to `IMPORT_OUT_MAX` and never recorded as a name.
- The `main_checkout` signature change has no stale caller. Both call sites pass `ent pok`. The iteration-1 fixes A1 (the type check on both namerefs) and the C1 fast return survived the rebase (Claim 23).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Caller contract (cache clear, any-stderr, git env, FIFO, snapshot) dropped from A5 and the U2b bullet; override rows 439-441 cite it | Inconsistent | `known-issues-dev-cycle.md:18`, `plan-build-loop-handoff.md:279` | High |
| 2 | `IMPORT_WORK_LEFT` unset or non-numeric semantics differ from `IMPORT_LEFT` (no default to the MAX, a literal bound, format switch) and are undocumented | Minor | `dev-cycle-read.sh:517-524,622,667` | High |
| 3 | MEMO must be fresh per walk and paired with ENT (a hit skips the mode check), which is undocumented; "plain" should read "readable plain" | Minor | `dev-cycle-read.sh:711-742` | High |
| 4 | Inventory test omits `import_work` and `IMPORT_WORK_MAX` | Minor | `test/scripts/dev-cycle.bats:1108-1110` | High |
| 5 | A5 says "warns about" where the code fails on any stderr | Minor | `known-issues-dev-cycle.md:18` | High |
| 6 | Plan bullet's "only a non-plain node fails" is over-broad; checkpoint has the old signature | Informational | `plan-build-loop-handoff.md:277`, `checkpoint-build-loop-handoff.md:21` | High |
| 7 | `.git` semantics changed; the lib comment is silent | Informational | `dev-cycle-read.sh:461-492` | Medium |

## Overall Assessment

The code surface is consistent with the lib's conventions. The new names, argument order, nameref style, return codes and budget pattern all match their siblings, and the one new output convention (the `/N` trailer) is opt-in and unambiguous. The real problem is in the documents: the rebase resolution kept main's A5 and U2b text and lost the caller contract that U2a3c had written there. Three override rows defer findings on the strength of that lost text, including a 🟡 Must Address. All findings are fixable in place: Findings 1 and 5 are one docs edit, and Findings 2-4 are a comment or a list each.

## Goal-Alignment Note

The goal is to land U2a3c on main once its loop is clean. Nothing here blocks the code: no finding is Breaking, and no current consumer misbehaves. Finding 1 does bear on the goal. Landing with A5 and the U2b bullet as they are would hand U2a4 and U2b a contract that omits the cache-clear and stderr obligations, while the override log says those documents carry them. That makes the deferrals in rows 439-441 rest on text that does not exist. I recommend restoring that text in this iteration, before the merge. It is a docs-only change with no retest cost beyond the health check.
