Commit: 55490d15

# Architecture Review — feat/build-loop-u2b3b2a (U2b3b2a, outside chains), iteration 1

**Scope:** `git diff main...HEAD` (one commit, 55490d15): `scripts/lib/dev-cycle-read.sh` (IMPORT_AWK, import_readers, import_targets, new outside_targets and file_targets, import_work's comment, both walks), `test/scripts/build-loop-check.bats`
**Date:** 2026-10-09
**Based on:** the shared brief `u2b3b2a-i1/shared.md` (the fact-check runs in parallel; its results were not available)

> ⚠️ **No code fact-check report provided.** Architectural claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

Trigger categories: module structure no; public APIs **yes** (the parser's output contract gains a second channel, import_targets gains a mode, two new lib functions); data models **yes** (the walk name lists now hold two namespaces); cross-cutting **yes** (the reader shared by both walks). In scope.

## Dependency Map

- **IMPORT_AWK** (the parser) is the one path resolver: `emit` → `put` (lexical resolve, root projection, dotnest exclusion) → `show`. It now prints three kinds of line: a repo-relative name, `//` + an absolute path (below no root), and the `/N` work trailer.
- **import_readers** owns the reader set (IMPORT_ROOTS, IMPORT_HOMES) and now also IMPORT_DOTNEST, an index table over IMPORT_ROOTS that the parser consumes through `IT_DOTNEST`.
- **import_targets** wraps the parser (sed blanking, UTF-8 decode, env plumbing). It now depends on import_readers directly (`import_readers || return 1`) rather than reading its memo, and reads a new ambient mode, `IMPORT_WHOLE`.
- **outside_targets** (new) composes two import_targets calls (the file's text against its own directory; its real path in whole mode), consuming each trailer with import_work and re-emitting one synthetic `/$w`.
- **file_targets** (new) is the dispatch both walks share for file-system reads: absolute FILE → outside_targets, else capped_read | import_targets.
- **imported_names** and **main_imports** consume the parser lines: import_work strips the trailer, `//` lines are admitted inline (`-f && -r`, not seen) and queued (main: into `tq`, phase 2), everything else goes through the existing repo admission.
- Dependency direction is unchanged: walks → file_targets → outside_targets → import_targets → import_readers / IMPORT_AWK. No cycle; the new functions sit at the right layer (between the walks and the parser), and the parser stays the only resolver.

## Findings

#### A1. An ambient `IMPORT_WHOLE` turns every walk's parse into whole-name mode (fail-open through the environment)

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:1088`, `:1107`, `:954`, `:960` (no initialisation beside `:1019`)
**Move:** 7 (coupling surface: control coupling through a global)
**Confidence:** High (probed)
**Evidence:** `[[ -z "${IMPORT_WHOLE:-}" ]] || s=(-e '')  # names, not text: no byte is a blank` and `IT_WHOLE="${IMPORT_WHOLE:-}" ... awk "$IMPORT_AWK"`; in the awk, `if (whole) { emit($0, 1); next }`. The lib initialises its other parser globals at source time (`IMPORT_ROOTS=""; IMPORT_HOMES=""; IMPORT_DOTNEST=""; ...` at :1019) but not IMPORT_WHOLE, and neither walk sets it on its calls (they set IMPORT_LEFT and IMPORT_WORK_LEFT per call, :1237, :1314).
**Probe** (hermetic fixture repo, lib sourced, `ROOT_REAL` set): `printf 'see @docs/x.md\n' | import_targets ""` prints `d … docs/x.md`; with `export IMPORT_WHOLE=1` first, the same call prints only `see @docs/x.md` (the line read as one relative name), so `docs/x.md` is not imported.

The mode that turns the text parser into a path projector is chosen by an ambient variable, not by the caller that wants it. outside_targets sets it for one call (`IMPORT_WHOLE=1 import_targets /`, :1119), which is correct, but any process that inherits an exported IMPORT_WHOLE (a caller's shell, a test, a loop's environment) makes every walk call read every line of every instruction file as one whole name, and the floor then answers "not imported" for imported paths: a false negative, the defect class the walks exist to avoid. It is the only parser mode the walks do not pin per call. The architectural issue is where the mode lives: the walk headers' "fail closed on shapes they do not model" now depends on an environment variable no walk controls.

**Recommendation:** Initialise `IMPORT_WHOLE=""` at source time with the other parser globals (one line, :1019), or, better, make the mode an argument (e.g. a leading `--whole` to import_targets, or a small `project_names` wrapper that sets `IT_WHOLE` itself) so only outside_targets can select it. A test that exports IMPORT_WHOLE=1 and runs a walk would pin it.
**Legibility-target:** a reader of a walk should be able to see every parser mode in force from the walk's own call line.

#### A2. file_targets silently drops DIRS for an absolute FILE, the interface U2b3b2b's outside prompt seeds will go through

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:1125` (and outside_targets' one-argument signature, `:1109-1121`)
**Move:** 3 (module boundary), 8 (extension point)
**Confidence:** High (not reachable today; forward)
**Evidence:** `file_targets() { if [[ "$1" == /* ]]; then outside_targets "$1"; else capped_read < "$1" | import_targets "${@:2}"; fi; }` and the header `# file_targets FILE DIR [DIRS...]: import_targets over FILE as the file system holds it, for both walks: a repo path (DIR and DIRS as import_targets takes them), or an absolute one through outside_targets.`

Both walks call `file_targets "$f" "$d" "${xs[@]}"`, where `xs` comes from `prompt_bases` when `pdir[$f]` is set. Today pdir is set only while seeding repo starts, so an absolute `f` always has empty `xs` and nothing is lost. But U2b3b2b's seeds (plan step 5: "user memory and `rules/` and prompt directories under each reader home's `.claude`") include prompt files such as `/home/node/.claude/commands/x.md`, whose `@` names resolve against the session's directory. `prompt_dir`'s `PROMPT_DIR` regex `(^|/)\.claude/(commands|agents|output-styles|skills)/` matches such an absolute path, and `prompt_bases` would give `("" "/home/node")`; file_targets would then discard both and read the prompt against its own directory only, under-reading the repo names a session would load. The parser already supports exactly the needed mix (emit joins an absolute directory as is and a relative one under each root, :855), so the gap is only in the new interface: it accepts DIRS in its signature and ignores them for one branch, which a later caller cannot see without reading the body.

**Recommendation:** Give outside_targets `FILE [DIRS...]` and pass `"${@:3}"` through to its first import_targets call (`import_targets "${d:-/}" "${@:3}"`), or, if this unit should not decide that, have file_targets return 1 when FILE is absolute and DIRS are given, so U2b3b2b's first prompt seed fails closed rather than under-reading.
**Legibility-target:** U2b3b2b's author, adding an absolute prompt seed, should learn from file_targets' header (or a refusal) that its session bases are either honoured or refused.

#### A3. The `//` admission policy is written inline in each walk; U2b3b2b adds the third site

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1245`, `:1353`
**Move:** 2 (responsibility), 8
**Confidence:** High
**Evidence:** tree walk: `[[ "$p" != //* ]] || { p="${p#/}"; [[ -f "$p" && -r "$p" && "$seen" != *$'\n'"$p"$'\n'* ]] && seen+="$p"$'\n' && queue+=("$p"); continue; }`; main walk: `[[ "$p" != //* ]] || { p="${p#/}"; [[ -z "${seen[$p]+set}" && -f "$p" && -r "$p" ]] && seen[$p]=1 && tq+=("$p"); continue; }`

"Which outside file a session can load" (readable regular file; skip otherwise) is a reader-model decision (brief claim 5 questions it), and it now lives as two one-line copies inside the walks' consumer loops, beside repo admissions that are named functions (inrepo_here, main_checkout). U2b3b2b queues outside seeds "through U2b3b2a's reader" in both walks, so the same test will be written at the seeding sites too: four copies of one policy. If a review decides to change it (fail closed on an unreadable outside name, or refuse /proc), each copy must change in step.

**Recommendation:** Name it once, e.g. `outside_ok PATH` (`[[ -f "$1" && -r "$1" ]]`, with the policy comment), and call it from both walks now so U2b3b2b's seeds reuse it. Cost: a few lines, well under the 400-line cap.
**Legibility-target:** one place to read and change the outside-file admission rule.

#### A4. outside_targets is a second producer of the work trailer and spends each budget up to twice

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1109-1121`
**Move:** 7 (stamp coupling to the parser's output protocol)
**Confidence:** Medium
**Evidence:** `a="$(capped_read < "$1" | import_targets "${d:-/}")" && import_work a w || return 1`; `b="$(printf '%s\n' "$r" | IMPORT_WHOLE=1 import_targets /)" && import_work b w || return 1`; `printf '%s\n' ${a:+"$a"} ${b:+"$b"} "/$w"`. Header: `The two work trailers are summed into one.`

The trailer was produced only by IMPORT_AWK's END; outside_targets now also writes one, so the trailer format is a protocol with two producers and one consumer (import_work). That is acceptable at this size, and summing is right. But both sub-calls inherit the same IMPORT_LEFT and IMPORT_WORK_LEFT, so "IMPORT_LEFT is what may still be printed" holds per sub-call, not for outside_targets as a whole; the walk's own check after the call is what keeps the bound (brief claim 2). The header does not say so, and a third sub-call (a U2b3b2b need, such as a seed directory listing) would widen it again.

**Recommendation:** Either decrement IMPORT_LEFT and IMPORT_WORK_LEFT for the second call by what the first used (so outside_targets honours the parser's budget contract itself), or state in its header that each sub-call gets the full left budgets and the walk's check is the bound.
**Legibility-target:** a reader of outside_targets should know, from its header, which component enforces IMPORT_LEFT.

#### A5. The walk name lists now hold two namespaces, kept apart only by contract item 6

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1242`, `:1349` (IMPORTED / IMPORTED_MAIN append), `:78-79` (contract item 6)
**Move:** 3
**Confidence:** High
**Evidence:** `lp="$(lower "$out")" || { IMPORTED=error; return 1; }; IMPORTED+="$lp"$'\n'` now appends `//`-led absolute names (lower-cased) beside repo names; contract item 6: `Read a walk only through isimported or truthwalk`.

The repo-relative and `//` namespaces cannot collide (a repo name never starts with `/`), and isimported only asks repo paths, so nothing is wrong today. But the lists now carry lower-cased absolute paths that no lookup uses, and the separation rests on the contract item rather than on the data. A future consumer that enumerates the list (a debug print, a U2c report of "imported because") must know to filter `//`.

**Recommendation:** None required; optionally a clause in contract item 6 or the walk header saying the lists also hold `//` names that isimported never matches.
**Legibility-target:** a later reader of IMPORTED should learn the list's two namespaces from its header.

#### A6. The dotnest rule moved into import_readers; its cross-references still place it in the parser, and main_imports' header does not name outside files

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1394`, `:870-882` (put's comment), `:1076-1078`, `:1251-1265` (main_imports header)
**Move:** 2
**Confidence:** High
**Evidence:** truthrule: `elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"  # the parser's dotnest omits only such paths: keep the two equal`; the rule is now computed in bash at :1076-1078 (`[[ ${#t} -le ${#p} || "$t" != "$p"* || "/${t#"$p"}" != *"/."* ]] || IMPORT_DOTNEST+=...`), and the parser only reads pairs (:951). main_imports' header: `# Phase 2 begins when queue empties: tq's checkout files then join it, and a path main lacks reads the checkout.`, and its failure list says `a blob or checkout file cannot be read`, while tq now also holds outside files read from the file system.

The "keep the two equal" coupling between truthrule's dot word and the dotnest exclusion is the kind of cross-module invariant that needs an accurate pointer; it now points at the consumer, not the definition. Likewise the main walk's phase-2 header describes tq as checkout files only.

**Recommendation:** Point truthrule's and put's comments at import_readers' IMPORT_DOTNEST loop; add "and outside files (`//` names)" to the phase-2 sentence and "an outside file" to the read-failure clause.
**Legibility-target:** a reader changing the dot word finds the rule it must stay equal to on the first hop.

## What Looks Good

- **One resolver kept.** Whole mode reuses `emit`/`put`/`show` to project an outside file's real path rather than writing a realpath-to-repo projector in bash; this honours the repo's earlier ruling against a further path resolver and means dotnest, multi-root projection and the second channel apply to real paths for free.
- **The second channel is unambiguous by construction.** `//` + absolute path cannot be a repo name (never `/`-led) and cannot be the trailer (`/` + digits, with import_work requiring the trailer to be the whole last line), which closes U2b3a i1 F5 as routed (override row 534).
- **H5/A1 resolved at the right owner.** import_targets now calls import_readers instead of re-deriving its memo key and refusal encoding, so the reader set and its refusal are one state owned by one function (closing override row 538 and row 554; the U2b3b1 final security review's B5 transition, `import_targets' memo test + IMPORT_READER_WHY check`, is removed rather than duplicated: B5 from `docs/reviews/security-review-2026-10-09-u2b3b1-final.md` (Commit: `f56ba3f5`) — security review predates this diff; boundary may be stale). The new outside-file read is a trust-boundary question for the security critic, not mapped here.
- **H2 placement.** The dotnest table is built where the roots are built and passed alongside them, so the index table and IMPORT_ROOTS cannot drift (one writer for both).
- **file_targets as one seam.** Both walks' file-system reads (the tree walk and the main walk's checkout arm) now go through one function, so the absolute/relative dispatch exists once; main's blob arm stays separate, which is right (main never stores an absolute path).
- **Phase-2 placement serves U2b3b2b.** Absolute items enter only `tq`, never main's arms (`${ent[$f]-checkout}` cannot hit an absolute key), and their repo-name imports re-enter main's arms through the normal admission. Outside seeds can be pushed onto `tq` (main walk) or `queue` (tree walk) at seeding time with no further walk change, except A2's prompt bases and A3's shared admission.
- Size: 158 changed code lines, well inside the 400-line cap.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| A1 | Ambient IMPORT_WHOLE switches every walk's parse to whole-name mode (probed: `@docs/x.md` not imported) | Coupling | `scripts/lib/dev-cycle-read.sh:1088,1107,954,960` | High |
| A2 | file_targets drops DIRS for an absolute FILE; U2b3b2b's outside prompt seeds would lose their session bases | Coupling | `scripts/lib/dev-cycle-read.sh:1125` | High |
| A3 | Outside admission policy inline in both walks; U2b3b2b adds more copies | Minor | `scripts/lib/dev-cycle-read.sh:1245,1353` | High |
| A4 | outside_targets is a second trailer producer; budgets apply per sub-call, unstated | Minor | `scripts/lib/dev-cycle-read.sh:1109-1121` | Medium |
| A5 | Name lists hold two namespaces, separated only by contract item 6 | Informational | `scripts/lib/dev-cycle-read.sh:1242,1349,78` | High |
| A6 | dotnest cross-references and main_imports' phase-2 header stale after the move | Informational | `scripts/lib/dev-cycle-read.sh:1394,870-882,1251-1265` | High |

## Overall Assessment

The unit improves the structure: it closes two routed architecture rows (one state for the reader set; a second output channel that cannot be confused with the trailer), keeps the parser as the only resolver, and puts the new file-system read behind one seam both walks share. Nothing needs restructuring. The most important concern is A1: the parser's new mode is selected by an ambient, uninitialised variable, so the walks' fail-closed property now depends on an environment no walk pins; a one-line initialisation or an explicit argument fixes it. A2 is the one shape issue for the next unit: the seam U2b3b2b will queue its outside seeds through accepts session bases and silently drops them for absolute files, which would under-read the user's prompt files; fix it here (pass them through, or refuse) so U2b3b2b inherits a fail-closed interface. A3 is cheap to do now and saves U2b3b2b from copying the admission policy again.

## Goal-Alignment Note

The goal is to land U2b3b2a so that U2b3b2b can queue outside seeds as absolute items through this unit's reader. The shape serves that goal: `//` names, file_targets/outside_targets, and phase-2 placement are exactly the hooks the seeds need, and the change stays well under the size cap. Two items bear directly on the next unit's success: A2 (absolute prompt seeds lose their session bases at file_targets) and A3 (the admission rule the seeds must share has no name). A1 is a present-tense fail-open in the walks themselves and is the one finding worth fixing before landing.
