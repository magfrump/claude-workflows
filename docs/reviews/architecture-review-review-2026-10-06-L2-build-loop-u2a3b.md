Commit: be94c871

# Architecture Review — feat/build-loop-u2a3b (loop 2, iteration 1, full panel)

**Scope:** `git diff main...HEAD -- scripts test docs/working skills` at be94c871 (IMPORT_AWK, import_targets, tree_starts, imported_names, isimported, main_imports' use of the parser; check_fix in scripts/dev-cycle.sh; known issue A5; plan row F11)
**Date:** 2026-10-06
**Based on:** Stage-1 summary `fcL2-summary.md` / `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i1.md` (no escalation addressed to architecture-review; its holes (a)-(d) are used below as fact, not re-verified)

## Dependency Map

- `scripts/dev-cycle.sh` `check_fix` → lib `imported_names` (new direct call, to word a failed walk) → `isimported tree`.
- lib `imported_names` → `tree_starts` (new; `git ls-files`, `untracked_md`, `instruction_names` under pipefail) via `nul_list`; per queued file → `import_targets` → `IMPORT_AWK` (new; replaces `IMPORT_RE` + a bash/realpath loop); per candidate → `-f`, `inrepo_here`.
- lib `main_imports` (U2a3, context) → `import_targets` per blob; per candidate it applies its own checkout-shape rules (lib :674-676). U2a3c (checkout phase) and U2a4 (floor) will consume `IMPORTED_MAIN` and the same candidate stream.
- Path resolution now lives in two places: `IMPORT_AWK`'s `emit` (lexical, dir-relative, awk) and `main_imports`' symlink arm (`realpath -ms`, lib :660, :663).
- Direction is unchanged and sound: the shared parser is the stable leaf; both walks and the CLI depend on it, never the reverse. Security-review cross-reference: the most recent branch security review (`docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a3b.md`, Commit: e48cf0f7 — predates this diff; boundaries may be stale) labels the parser boundary B1/B5 and the superset relation B4. No recommendation below moves a boundary.

## Findings

#### 1. The superset's prefix candidates meet main_imports' fail-on-checkout-shape rule, turning a precision loss into a whole-walk failure; in a linked worktree every `@.g…` token fails the main walk

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:674-676` (consumer) with `:533-538` (every prefix emitted)
**Move:** 7 (coupling surface), 3 (module boundary; sits on B5 from the security review above)
**Confidence:** High
**Legibility-target:** the U2a3b implementer now; the U2a3c and U2b planners (plan line 277, 279)

Evidence: `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }` is applied to every candidate main lacks, and the parser now emits every prefix (`name = name ch; emit(name)`). main_imports' rule was designed for exact names; the parser's contract changed from "names" to "candidate superset" without the consumer's failure policy changing. Probe (scratch `/tmp/u2a3b-archL2-bEIT`): a main commit whose GEMINI.md says `See @.gitignore and @notes/x.md`; in the main checkout the be94c871 main walk is ok (candidates `.g .gi .git .giti …`), in a `git worktree add` checkout it prints `main walk FAILED` (prefix `.git` is a plain file there, main lacks it); main's code passes both. An untracked plain file at any prefix (`notes/x` beside `@notes/x.md`) likewise fails be94c871's main walk and not main's. U2b's plan names "a fresh worktree at MAIN_SHA" as the gate checkout, so a single `@.github/…` or `@.gitignore` in any instruction file on main makes U2a4's floor refuse every path there. Not triggered on /workspace today (main walk ok in this linked worktree). This is not a superset hole (it fails closed); it is a usability regression of the floor that the superset multiplies.

**Recommendation (smallest, tested):** in main_imports, after the `ent` lookup, skip candidates git cannot store: `[[ "$p" != .git && "$p" != .git/* ]] || continue` (mutant `mut2`: the linked-worktree probe passes, 121/121). The general prefix-meets-untracked-file case is U2a3c's to dissolve (it walks such files instead of failing); add one clause to plan line 277 that phase 2's seeds and admission check apply to every superset candidate, so its fail rules must fail only for shapes that matter (a non-plain node), not merely for "the checkout holds a file main lacks".

#### 2. Lexical resolution is dir-relative and gates on a literal ROOT_REAL prefix, so the repo boundary is decided before the path is canonical (the `../<repo>/` re-entry and non-literal absolute holes are one defect)

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:511-527` (`emit`), `:558`
**Move:** 2 (responsibility), 3 (boundary; B4 from the security review above)
**Confidence:** High
**Legibility-target:** the U2a3b implementer; the security reviewer (fact-check holes a, b, c)

Evidence: `if (root == "" || index(c, root "/") != 1) return` then `if (part[i] == "..") { if (k == 0) return; k--; continue }`. `emit` decides "inside the repo?" twice, on raw text: an absolute name is tested against ROOT_REAL as a literal prefix before `.`/`..`/`//` are removed, and a relative name is dropped the moment its walk rises above the repo root, though Node's `path.resolve` (which Claude Code uses) keeps going and may re-enter (`@../../<repo>/docs/x.md` from `sub/`). The awk program is the right home for resolution (forking `realpath` per prefix is not affordable), but the shape should be "canonicalize in absolute space, then project to repo-relative", which is what `realpath -ms --relative-to` did before and what main_imports' symlink arm still does. Separately, `-v dir= -v root=` runs awk's escape processing on both values (POSIX, not mawk-specific), so a root holding a backslash never matches.

**Recommendation (smallest, tested):** make every candidate absolute (`root "/" dir "/" c` for a relative one), normalize with `..` clamping at `/` as path.resolve does, then keep it only when it starts with `root "/"` and is longer than it; pass `dir` and `root` through `ENVIRON` (`IA_DIR="$1" IA_ROOT="$ROOT_REAL" awk 'BEGIN{dir=ENVIRON["IA_DIR"];root=ENVIRON["IA_ROOT"]}'"$IMPORT_AWK"`). Mutant `/tmp/u2a3b-archL2-bEIT/mut`: `@../../<repo>/docs/x.md`, `@//<root>/docs/x.md`, `@/./<root>/…`, `@<root>/../<repo>/…`, `@../../../../../../..<root>/…` and a root `my\repo` all yield `docs/x.md` (be94c871: none, except the literal spelling under a plain root); `~/`, `/`, `/etc/passwd`, the root itself and `../../x` still drop; 121/121; `IMPORTED` and `IMPORTED_MAIN` on /workspace are byte-identical to be94c871 (md5 c7e4ae76…), walk time within noise (1.48-1.76 s vs 1.57-1.67 s for both walks). This also removes the "dir-relative vs repo-relative" question: resolution is absolute, the repo-relative form is only the output projection. (A `..` after a symlinked directory stays the settled row-350 gap; this is still lexical, as path.resolve is.)

#### 3. The superset claim is stated three times, unconditionally in code and with different exceptions in A5 and F11, and nothing executable holds it

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:492-503`; `docs/working/known-issues-dev-cycle.md:18` (A5); `docs/working/plan-build-loop-handoff.md:126` (F11)
**Move:** 3 (public contract of the parser), 8
**Confidence:** High
**Legibility-target:** the next maintainer who upgrades Claude Code; the U2a4 floor author relying on F11

Evidence: code: "They read a superset of what Claude Code 2.1.292 can import"; A5: "The superset does not cover a name Claude Code builds that is not a prefix of one blank-free run after an `@` (for example a Markdown entity it might decode)"; F11: "(U2a3b: every `@`, every prefix to the first blank, absolute paths inside the repo)", and "absolute imports" was removed from F11's and A5's gaps and the main_imports header. The three statements already disagree (only A5 has an exception; the fact-check found its example does not occur and that holes (a)-(d) exist), and the property is the parser's whole contract to its two consumers and to U2a4. It is pinned by examples in build-loop-check.bats; the oracle that would check it (the extracted cc.js/marked.js fuzzer) lives in `/tmp/u2a3b-secf-XcAr`, which will not survive, and its generator never produced `..` re-entry or absolute spellings, which is how holes (a)/(b) went unseen.

**Recommendation:** state the property once, in the code comment, with its known exceptions (after finding 2: none of the path-spelling kind; the 4096-byte name cap; any entity/decoding Claude Code may add), and have A5 and F11 point at it rather than restate it; restore "absolute imports spelled other than with ROOT_REAL as a literal prefix" to the gaps unless finding 2 lands. Pin the counterexample shapes as tests (`../../<repo>/`, `//root`, `/./root`, backslash root). Record where the oracle came from (version, extraction) in A5 so the revisit trigger has a procedure, not just an event; vendoring it is out of scope here.

#### 4. Two path resolvers with opposite leave-the-repo policies

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:521` vs `:660-664`
**Move:** 2, 7
**Confidence:** Medium
**Legibility-target:** U2a3c implementer (phase 2 reads through main's arms)

Evidence: the parser drops a name that leaves the repo (`if (k == 0) return`); main_imports' symlink arm fails the walk (`[[ "$out" != .. && "$out" != ../* ]] || { IMPORTED_MAIN=error; return 1; }`) and resolves with `realpath -ms`. Both policies are defensible (an import leaving the repo names no file the floor guards; a link leaving it is an unmodelled shape), but they are the same canonicalization written twice in two languages, and finding 2 shows the awk copy drifted. No action needed now beyond keeping them in step; if finding 2 lands, note in the IMPORT_AWK comment that it mirrors realpath -ms in absolute space so U2a3c does not add a third.

#### 5. Coupling to mawk is low; tests exercise only the system awk

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:558`, `:512`, `:533`
**Move:** 1
**Confidence:** Medium
**Legibility-target:** whoever moves the lib to a host with gawk or BusyBox awk

Evidence: `env LC_ALL=C awk …`. The program uses only POSIX awk (`substr`, `index`, `split` on a one-character separator, `exit` in a function); under `LC_ALL=C` both mawk and gawk count bytes, so the 4096 cap and the 50,000,000 work bound mean bytes on either. The one portability trap is `-v` escape processing, which is POSIX behaviour common to all awks (finding 2's ENVIRON fix removes it). The work bound's time cost was measured with mawk only; gawk is typically slower, so the bound's wall time would grow, not its result. `[unverified — submitted as claim]` for gawk/BusyBox behaviour; not probed (no gawk installed).

## What Looks Good

- **Over-approximation in one awk program is the right shape.** The prefix explosion makes per-candidate forks unaffordable, so tokenizing, candidate generation and resolution must run in one process; one awk per file keeps the work bound per file and the failure surface to one exit status. Restricting prefixes to "plausible cut points" would re-import the Markdown model the user rejected (marked's text rule cuts mid-word before `https://` and before an email-shaped run), so emitting every prefix is the honest superset.
- The parser stays a leaf with one input (text + dir) and one output (repo-relative lines, deduped); both walks consume it unchanged, so the tree/main asymmetries remain in the walks, where they were.
- Failure is propagated as a return status at every layer (`import_targets` → `imported_names`/`main_imports` → `isimported` answers imported; `check_fix` words it), with the cached-error rule symmetric between the two walks. `tree_starts` gives the start listing one failure point under pipefail.
- Consumers stay membership-only (`*\n$lp\n*`), so a larger candidate set costs U2a4 only lookup size (2020 bytes, 65 lines for IMPORTED_MAIN on /workspace vs 119 bytes at main), not semantics.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Prefix candidates hit main_imports' checkout-shape fail rule: `@.g…` fails the main walk in a linked worktree (the U2b gate checkout); untracked file at a prefix fails it anywhere | Coupling | `scripts/lib/dev-cycle-read.sh:674-676` | High |
| 2 | Resolution decides the repo boundary before canonicalizing (dir-relative `k==0` drop, literal root prefix, `-v` escapes): holes a, b, c are one defect | Coupling | `scripts/lib/dev-cycle-read.sh:511-527, 558` | High |
| 3 | Superset claim stated three ways (code, A5, F11), unconditionally in code, no executable oracle | Minor | lib `:492-503`; known-issues `:18`; plan `:126` | High |
| 4 | Two resolvers (awk lexical, realpath -ms) with opposite leave-repo policies | Informational | lib `:521` vs `:660-664` | Medium |
| 5 | Low mawk coupling; only -v escapes are a real trap; only mawk tested | Informational | lib `:558` | Medium |

## Overall Assessment

The redesign improves the structure: a model of Claude Code's lexer was replaced by a property (superset) that a small awk program can hold, and the parser stays a clean leaf both walks share. Two coupling defects remain, both fixable in place and both tested in scratch: resolution must canonicalize in absolute space before deciding the repo boundary (finding 2, which closes three of the fact-check's four superset holes at no measured cost), and main_imports' fail-on-checkout-shape rule, written for exact names, now fires on prefixes (finding 1), which in the linked worktree U2b plans to use makes the floor refuse everything whenever an instruction file mentions `@.g…`. The most important structural concern is finding 1's interaction with U2a3c: every rule that main_imports or phase 2 applies per candidate now applies to every prefix, so the plan should say that U2a3c's fail rules must be ones a prefix can safely trip.

## Goal-Alignment Note

Success criterion (verbatim): "A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: be94c871` line at the top."

This report is saved at `docs/reviews/architecture-review-review-2026-10-06-L2-build-loop-u2a3b.md` in the worktree, follows the architecture-review structure (Dependency Map, Findings, What Looks Good, Summary Table, Overall Assessment) and opens with `Commit: be94c871`. It answers the brief's questions: the one-awk shape is right (What Looks Good); path resolution belongs in awk but in absolute space, not dir-relative (finding 2); mawk coupling is low (finding 5); U2a3c/U2a4 fit (finding 1, What Looks Good); the superset statement in code, A5 and F11 (finding 3). Probes ran in `/tmp/u2a3b-archL2-bEIT` and `/tmp/u2a3b-archL2-tmp-gNL5`; no worktree file other than this report was written.
