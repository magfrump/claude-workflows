Commit: 3a35c8b9

# API Consistency Review — feat/build-loop-u2a3c, final confirming pass (iteration 3)

**Scope:** `git diff main...HEAD` (HEAD 3a35c8b9). Public surface: the reader lib's function contracts in `scripts/lib/dev-cycle-read.sh` (`capped_read` and its `drain` word, `lower_all`, `import_work`, `main_checkout ENT MEMO PATH`, `checkout_md`, `md_ls`, `IMPORT_WORK_MAX`, `IMPORT_WORK_LEFT`, the parser's `/N` trailer) and the walk's documented caller contract (lib block comment above `IMPORTED=`, `main_imports`' header, known issue A5, plan F11 and the U2a3c/U2b bullets).
**Date:** 2026-10-07
**Based on:** Stage-1 summary `u2a3c-i3-stage1.md` and the `## Escalations` sections of `docs/reviews/code-fact-check-report-build-loop-u2a3c-r{1,2,3}.md`; iteration-2 API review `api-consistency-reviewer-review-2026-10-07-build-loop-u2a3c.md` (findings 1-7) checked for closure.

## Baseline Conventions

- **Namerefs first, then values.** `nul_list NAME CMD...`, `import_work OUT TOTAL`, and `main_checkout ENT MEMO PATH` all follow this order (`scripts/lib/dev-cycle-read.sh:695`, `:677-681`, `:732`).
- **Mode words as positional arguments.** Examples are `blocker PATH file|dir` (`:114`, where an unknown word means the non-special `file` path) and `isimported main|tree PATH` (`:882-890`, where an unknown word answers "imported", the fail-safe answer).
- **Budgets.** A global `*_MAX` sets the bound, a walk passes `*_LEFT` into the parser as a command-prefix environment variable, and any change to the global clears both caches (`IMPORT_OUT_MAX` / `IMPORT_LEFT`, `:497-503`, `:671`).
- **Return codes.** Predicates use 0/1. `main_checkout` is the lib's only three-valued return, and that is settled (override row "three-valued return").
- **Contract placement.** Each public function's contract is a comment directly above it. A5 and F11 point to the lib comment for the parser claim ("stated once, above `import_targets`").

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `capped_read [drain]` | function | `nul_list`, `lower`, `blocker PATH KIND` | `scripts/lib/dev-cycle-read.sh:114,518,695` | Consistent. Verb_noun snake_case, with a trailing mode word as in `blocker`. An unknown word means no drain, the non-special default (as in `blocker`), and an undrained `git cat-file` then fails the read closed under pipefail. |
| `lower_all ARGS...` | function | `lower`, `instruction_names`, `untracked_md` | `scripts/lib/dev-cycle-read.sh:518,691` | Consistent. It is the batch form of `lower`, with NUL output for `nul_list`. |
| `import_work OUT TOTAL` | function | `import_targets`, `import_home`, `nul_list NAME` | `scripts/lib/dev-cycle-read.sh:649`, `import_home` | Consistent. It uses the `import_` prefix and takes namerefs first. It is now in dev-cycle.bats' lib inventory (`test/scripts/dev-cycle.bats:1110`), which closes iteration-2 finding 4. |
| `main_checkout ENT MEMO PATH` | function | `main_imports`, `main_entry`, `blocker PATH KIND` | `scripts/lib/dev-cycle-read.sh:114,801` | The name and the 0/1/2 return are settled. The contract text and the PATH arm disagree (Finding 1). |
| `checkout_md`, `md_ls` | function | `untracked_md`, `tree_starts` | `scripts/lib/dev-cycle-read.sh:691,716` | Consistent with the `*_md` listing helpers (carried from iteration 1). |
| `IMPORT_WORK_MAX` | global | `IMPORT_OUT_MAX` | `scripts/lib/dev-cycle-read.sh:503` | Consistent. It has the same "a caller that changes it clears both caches" rule. |
| `IMPORT_WORK_LEFT` | env input | `IMPORT_LEFT` | `scripts/lib/dev-cycle-read.sh:524,671` | Consistent with its own MAX. Its unset semantics differ from `IMPORT_LEFT`'s on purpose, and that difference is now documented (iteration-2 finding 2 closed). The "not a number" clause shares `IMPORT_LEFT`'s inaccuracy (Finding 4). |
| `IT_WORK` | awk env | `IT_LEFT`, `IT_DIR`, `IT_ROOT` | `scripts/lib/dev-cycle-read.sh:670-671` | Consistent. |
| `/N` trailer line | output field | none | none — searched `scripts/lib/dev-cycle-read.sh` for in-band trailers | New convention. It is opt-in on `IMPORT_WORK_LEFT` and unambiguous, because a repo-relative name never starts with `/`. Its only consumers are the three walk call sites, which strip it with `import_work`. |

## Findings

#### 1. `main_checkout`'s contract omits the precondition that PATH is not a key of ENT, and the comment's MEMO invariant is false for the PATH arm

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:717-723` (contract comment), `:750-754` (PATH arm); `docs/working/plan-build-loop-handoff.md:279` (U2b bullet)
**Move:** 3 (consumer contract), 8 (precondition and nullability of inputs)
**Confidence:** High (executed)
**Legibility-target:** U2b/U2a4 implementer writing a second `main_checkout` caller; a future reviewer of the MEMO invariant.

Evidence. The comment says:

> `# searchable directory, 2 for one absent or a plain file (nothing below it`
> `# loads), set only once its own and every higher ancestor's main mode passed.`
> `# A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT.`

The PATH arm never reads `mc_e[$3]`:

> `  plaindir "$c" || return 1`
> `  [[ ! -x "$c" ]] || mc_m[$c]=d  # a prefix candidate's directory, which longer ones pass through`
> `  return 2`

The U2b bullet (plan `:279`) is the only contract written for another caller:

> `A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too);`

I executed this in a scratch git repo, with `ROOT_REAL` set and `a/` a plain directory holding `a/f.md`:
- `ENT=([a]=120000)`, then `main_checkout E M a` returns `2` with `M[a]=d`, and a later `main_checkout E M a/f.md` returns `0`. With a fresh MEMO, the same call returns `1`.
- The precondition matters beyond the memo. With `ENT=([x.md]=160000)` and a plain `x.md` in the checkout, `main_checkout E M x.md` returns `0` and admits for a checkout read a path that main stores as a gitlink. This is because PATH's own ENT mode is never consulted.

So the function is correct only for PATH ∉ ENT. Both `main_imports` call sites guarantee that (`:825` guards on `cand[i]` starting `m`, which means ENT lacks it, and `:870` guards on `ent[$p]+set`), so no current consumer is affected. This agrees with r1-r3, which found 0 divergences from 21b35ebf on in-contract calls. The documented contract states a stronger invariant than the code keeps, though. The one contract handed to a future caller ("a fresh MEMO per walk and ENT") is satisfied by the failing sequence above. The failure is fail-open: a link or gitlink refusal is skipped. The comment's own convention is "Callers test 1 as a refusal", so a path that main stores is the kind of input the contract implies would refuse.

The three restated contract places say nothing on this point (lib block above `IMPORTED=`, `main_imports`' header, A5). That is correct for them, because they describe the walk, not `main_checkout`'s direct callers. So the gap sits in exactly two places: the comment above `main_checkout` and the U2b bullet.

**Recommendation:** Prefer the code guard. Add `[[ -z "${mc_e[$3]+set}" ]] || return 1` before the PATH tests, so an out-of-contract call refuses, which matches "1 to fail the walk ... anything else at PATH", and the MEMO invariant then holds as written. If you keep the code unchanged instead, add "PATH must not be a key of ENT (main_imports reads those from main)" to both the comment and the U2b clause, and pin it in T1.

#### 2. A5 and F11 point to different homes for the caller contract, and neither home holds all of it

**Severity:** Minor
**Location:** `docs/working/known-issues-dev-cycle.md` row A5; `docs/working/plan-build-loop-handoff.md:126` (F11), `:279` (U2b); `scripts/lib/dev-cycle-read.sh:486-492`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** U2b implementer looking for "what must I do before calling `main_imports`".

Evidence. A5 says:

> `(the lib's block comment above `IMPORTED=` holds the caller contract; the U2b bullet names what U2b owes it)`

F11 says:

> `the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet.`

The lib block above `IMPORTED=` (`:486-492`) holds two caller duties: clear `IMPORTED_MAIN_DONE` after a checkout change, and clear both caches after a HOME change. The `IMPORT_*_MAX` clear duty sits in the comments below it, at `:501-503` and `:508-509`. The stderr rule appears there only as a fail rule ("a checkout listing git prints any stderr for ... fail the walk"), not as a duty. The git environment and `LC_ALL=C` duties appear only in the U2b bullet. The U2b bullet's "three things" (cache clear, empty stderr, git environment) in turn omit the HOME-change clear and the `IMPORT_*_MAX`-change clear, which the lib does state. A reader who follows A5 to the lib misses the git environment and `LC_ALL`. A reader who follows F11 to U2b misses the HOME clear, even though U2b's reader model is the unit that changes which HOME the parser uses ("The parser takes the home from its caller then"). Iteration 2's restoration (finding 1 there) is substantively right. Every duty is written somewhere, and A5's stderr wording now matches the lib ("prints any stderr for", which closes iteration-2 finding 5). The pointer is what still disagrees.

**Recommendation:** Pick one home. The U2b bullet is the natural one, because it already says "owes the walk". Make A5 point there, as F11 does, and add the HOME and `IMPORT_*_MAX` clears to its list. Or have the U2b bullet say "and the lib's cache-clear rules above `IMPORTED=`".

#### 3. F11's fail list omits the unreadable checkout file that A5, the lib and the U2a3c bullet list

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Move:** 7 (asymmetry across the four statements)
**Confidence:** High
**Legibility-target:** reviewer cross-checking F11 against the code.

Evidence. F11 says:

> `one admission check (`main_checkout`) refuses a path under a link or gitlink main stores, under an unsearchable directory, or anything but a plain file or directory`

A5 says "an unreadable checkout file ... fail it". The lib says "anything but a readable plain file". The U2a3c bullet says "an unreadable file ... fails". The code is `if rawfile "$c"; then [[ -r "$c" ]]; return; fi`. F11 is the only one of the four that drops "readable", so a reader of F11 alone would expect an unreadable plain file to be admitted. This matches the Stage-1 "Mostly accurate" note.

**Recommendation:** Change F11's text to "anything but a readable plain file or a plain directory".

#### 4. `IMPORT_WORK_LEFT`'s "not a number: 0" repeats `IMPORT_LEFT`'s overstatement

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:524-527`, `:626`
**Move:** 8
**Confidence:** High (executed)
**Legibility-target:** a caller passing a non-arithmetic value.

Evidence. The comment says `Unset or empty: no trailer and only the per-file bound; not a number: 0, so the first candidate fails it`. The code is `wmax = 50000000; trail = (ENVIRON["IT_WORK"] != ""); if (trail && ENVIRON["IT_WORK"] + 0 < wmax) wmax = ENVIRON["IT_WORK"] + 0`. Running `IT_WORK=12abc awk 'BEGIN{print ENVIRON["IT_WORK"]+0}'` prints `12`, so a string with a leading number reads as that number. The sibling `IMPORT_LEFT` clause has the same wording (pre-existing). Both lib callers pass `$((...))`, so no consumer can hit this. The new text is consistent with its sibling, including the sibling's inaccuracy.

**Recommendation:** If either clause is touched, say "not a number: its leading number, or 0". Otherwise leave it.

## Iteration-2 findings: closure check

- **1 (contract dropped from A5/U2b):** Restored. The cache-clear sentence, FIFO, snapshot, stderr, `.git` and the U2b "three things" clause are back. Override row 452 accurately records this. The remaining pointer disagreement is Finding 2 above.
- **2 (`IMPORT_WORK_LEFT` defaulting):** Documented. Closed.
- **3 (MEMO contract):** The "MEMO hit skips the mode check" clause is now in the comment and in U2b. The PATH-in-ENT hole is new in 2fbd929b's bottom-up rewrite, which memoizes PATH; it is Finding 1 above.
- **4 (`import_work` missing from inventory):** Fixed (`dev-cycle.bats:1110`).
- **5 (A5 stderr wording):** Fixed.
- **6 (stale refusal statements):** `main_imports`' header and the file-top inputs comment now describe the checkout phase. Closed.
- **7 (`.git` semantics undocumented):** Fixed. The lib (`:476-477`) and A5 both say "a linked worktree's .git file ... is read like any checkout file".

## What Looks Good

- The four places that restate the walk's contract (lib block, `main_imports` header, A5, the F11/U2a3c bullets) agree on the fail rules, with only F11's dropped "readable" (Finding 3) as an exception. They agree on the cache key ignoring the checkout, the FIFO gap, the snapshot assumption, and `.git`.
- `import_work`'s strip is strict. It accepts only a whole last line `/digits` and fails on a missing trailer, so a parser that dies before END cannot be read as zero work.
- `capped_read`'s `drain` follows the lib's mode-word convention. Its default fails closed: an undrained `git cat-file` dies of SIGPIPE, and pipefail fails the read.
- `main_checkout` validates both namerefs as associative arrays, and its two call sites test `c` explicitly, never as a boolean, as the comment requires.
- `IMPORT_WORK_MAX` mirrors `IMPORT_OUT_MAX` exactly: a global default, a per-walk budget, and the cache-clear rule on change.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `main_checkout`: PATH ∉ ENT precondition undocumented, MEMO invariant false for the PATH arm, U2b contract insufficient | Inconsistent | `scripts/lib/dev-cycle-read.sh:717-723,750-754`; plan `:279` | High |
| 2 | A5 and F11 name different homes for the caller contract; neither holds all duties | Minor | A5; plan `:126`, `:279`; lib `:486-492` | High |
| 3 | F11 omits "readable" from the plain-file rule | Informational | plan `:126` | High |
| 4 | "not a number: 0" overstates awk's coercion (as `IMPORT_LEFT`'s does) | Informational | lib `:524-527` | High |

## Overall Assessment

The code surface is consistent with the lib's conventions. Every new name, argument order, return convention and budget pattern matches its siblings, and the iteration-2 API findings are closed. The one substantive issue is a contract-versus-code gap that 2fbd929b introduced. `main_checkout` is safe only when PATH is not a key of ENT, but its comment claims a stronger MEMO invariant, and the contract written for the named future caller (U2b) does not state the precondition. A caller that satisfies the written contract can get a link or gitlink admitted. No current consumer can reach it. All findings can be fixed in place: Finding 1 is a one-line guard or two sentences, and Findings 2-4 are text edits.

## Goal-Alignment Note

The goal is to land U2a3c on main once its loop is clean. Nothing here is Breaking, and no live caller misbehaves, so none of these findings blocks the merge on its own. Finding 1 bears on the goal, though. U2a3c's purpose is to hand U2a4 and U2b a walk with a written contract they can rely on, and the one `main_checkout` contract written for them is fail-open as stated. The cheapest close is the one-line `return 1` guard on `mc_e[$3]`, plus a T1 row, before the merge. That keeps the comment's MEMO invariant true and makes the U2b clause sufficient as written. If the loop is at its cap, an override row that names the precondition and has U2b as its revisit trigger would also discharge it. Findings 2-4 can ride along with that edit or be deferred.
