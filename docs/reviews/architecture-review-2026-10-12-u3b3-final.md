Commit: 5583a2cd

# Architecture Review — feat/build-loop-u3b3 (iteration 3 of 3, final)

**Scope:** branch diff `main...5583a2cd` (docs/reviews/ excluded from the diff; the rubric and the seven new override rows, lines 732-738 of `docs/reviews/override-log.md`, read as part of the change): `scripts/lib/dev-cycle-read.sh` (git_harden, HARDEN, CALLER_COUNT), `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `test/lib/d6-snippet.bash` (the verified reader), `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-check.bats`, the plan's U3b3 as-built note
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3b3-final-r{1,2,3}.md` (k=3; no behavioural Incorrect; one doc Incorrect, one Stale; r1's escalation to security on `d6-snippet.bash:67`)

Scope check: in scope. The diff moves a cross-cutting concern (process-wide git hardening) into the shared lib, which widens the lib's public surface (`git_harden`, `HARDEN`, `CALLER_COUNT`). It also adds a new module, the D6 snippet. The snippet is the orchestrator's only entry point to both scripts and chooses which of two trust roots runs. The i2 rewrite replaced its readers with one embedded perl program.

Trust-boundary cross-reference: the newest security review is `docs/reviews/security-review-2026-10-12-u3b3-i2.md` (Commit: `5d175c0e`). That review predates this diff's head, so its boundaries may be stale. In particular, B2's transition point was `rev-list --max-parents=0 == D6_ROOT`, and the perl reader's `$c ne $root` now does that job. Finding 1 sits on B2.

Probes: `/tmp/u3b3-arch4-XXXX` (removed). P1 extracts the reader's program from the snippet, runs `perl -c` on it, and drives it directly through its git-command argument against a crafted repository. Separately, `bats test/scripts/build-loop-orchestrator.bats` ran 20/20 ok at 5583a2cd.

## Dependency Map

- **Orchestrator (U4, not yet written)** → `bash -s -- SCRIPT ARG... <<'D6'` (the snippet). The snippet sources nothing. It contains the following inline:
  - a git command array `G` that restates the lib's HARDEN pairs and git_harden's environment (`d6-snippet.bash:40`);
  - a subset of build-loop.sh's replace/grafts/default-branch refusals (`:47-54`);
  - the verified reader, a perl program `P` in a single-quoted bash string (`:58-71`), driving one `git cat-file --batch`.

  The reader's three-way answer (`main` / `other` / die) picks the trust root. `main` means the four scripts extracted from main into a mktemp dir. `other` means `/opt/claude-workflows` after `own()` (`:80-86`).
- **build-loop.sh and dev-cycle.sh** → `source lib/dev-cycle-read.sh` → `scrub_reexec` → `git_harden` (`build-loop.sh:442-443, 497`; `dev-cycle.sh:103-104, 131`). The direction is correct: the volatile entry scripts depend on the lib, and the lib depends on no script. No git call runs between `scrub_reexec` and `git_harden` in either script, and the lib makes none at source time (dev-cycle.bats:1106 pins the latter).
- **build-loop.sh `caller_gate`** reads the lib's `HARDEN` and `CALLER_COUNT` (`build-loop.sh:564-567`). This is the one deliberate data back-edge, and the lib's header names it.
- **Two hash-verifiers of one property.** store_check (`build-loop.sh:927-985`, a perl filter over a cat-file stream, for sha1/sha256, plus a second-copy rule) and the snippet's reader (sha1 only, uses only bytes it hashed). They do not share code, because the snippet runs before anything is checked and so cannot source the lib.
- **Tests:** `build-loop-orchestrator.bats:346-361` pins three copies of HARDEN and the environment to each other: the lib's export, the literal oracle `H`/`E`, and the snippet's `G` line. The two "every git call" tests derive their keys from the lib (`build-loop-check.bats:1700`, `build-loop-orchestrator.bats:377`).

## Findings

#### 1. The snippet picks its trust root from data in the repository it is judging, so a non-claude-workflows project can switch itself from the root-owned image copy to its own scripts

**Severity:** Coupling
**Location:** `test/lib/d6-snippet.bash:65-67`, `:77-86`
**Move:** 3 (module boundary), 7 (coupling: control coupling across a trust boundary)
**Confidence:** High (mechanism: r1's executed P6; my P1 shows a second route); severity of the exploit deferred to security
**Legibility-target:** the security reviewer and the user ruling on r1's escalation, and U4's author, who documents what the image copy protects

The snippet has two trust roots: the repository's own main (claude-workflows) and the root-owned `/opt` copy (every other project). The selector between them is a predicate over objects in the untrusted store: "main's first-parent chain ends at D6_ROOT". D6_ROOT is a public commit object, and every claude-workflows checkout on the host holds a copy. So a loop in another project that points main at a history built on a copy of 640cf007 turns the predicate true. The snippet then extracts and runs that project's planted scripts rather than `/opt`'s. r1 executed this (P6). This is control coupling: the module under judgement supplies the flag that chooses its judge.

The reader's commit grammar also differs from git's. It takes any header line starting `parent` as the first parent, while git reads parents only directly after `tree`. P1 built a commit with a `parent` line after `committer`. git reports that commit as its own first-parent root (`git's first-parent root of C: bdcb389d…`, which is C itself). The reader followed the late line to the configured root and went on to the `main` branch (`no scripts in 4b825dc6…`, the scripts lookup). For this predicate, that is a second, git-invisible route to the same answer.

The B2 boundary ("[object-store state that steers the mode] → [snippet root check] → [choice: main's copy vs the /opt image copy]", security review i2, Commit `5d175c0e` — security review predates this diff; boundary may be stale) is exactly this transition. Row 732 settles the claude-workflows case, where main is the trust root by design. The image copy exists so that a project's loop cannot pick its own gate. The selector extends row 732's weaker guarantee to every project that can fabricate the predicate.

Evidence (verbatim):
- `test/lib/d6-snippet.bash:67`: `    if ($c ne $root) { print "other\n"; exit 0 }`
- `test/lib/d6-snippet.bash:65-66`: `    my $tree; while (1) { my ($hd) = split /\n\n/, obj($c, "commit"), 2; $tree //= $hd =~ /\Atree ([0-9a-f]{40})\n/ ? $1 : die "$c has no tree\n";` / `      my ($p) = $hd =~ /^parent ([0-9a-f]{40})$/m; last unless defined $p; $c = $p }` (loop ends at `:66`; `$c` flows to `:67`)
- `docs/reviews/override-log.md:732`: "a same-uid loop that moves main's ref onto its own commit on top of the real history passes every hash check, and the snippet runs that commit's scripts"

**Security implication:** any fix moves B2's transition point, from object-store contents to an input outside the repository. That decision belongs to a combined architecture/security ruling.

**Recommendation:** take the selector's input from outside the repository. Options for security to rule on:
- a root-owned file in the image naming the claude-workflows checkout path(s), compared with the toplevel's real path;
- prefer `/opt` whenever it passes `own()`, except in a repository that file names;
- as a minimum, record the gap in row 732 or a new row, so the image copy's guarantee is not overstated.

Independently, anchor the commit parse to git's grammar (`\Atree X\n(?:parent X\n)*`, first parent the line after `tree`). Then the reader's notion of "first-parent root" cannot differ from `git rev-list`'s.

#### 2. The verified reader is a dense program in a bash string, tested only end to end, though it already has a test seam

**Severity:** Minor
**Location:** `test/lib/d6-snippet.bash:55-71`, `:78`; `test/scripts/build-loop-orchestrator.bats:245-316`
**Move:** 5 (interface: the reader's argument and stdout protocol), 3 (encapsulation)
**Confidence:** High
**Legibility-target:** whoever next edits the reader (U4 pastes it, a later unit changes it)

Embedding the reader is forced: the snippet must be self-contained and cannot source an unchecked file. The cost is that its parsing decisions are fixed in 14 lines of single-quoted string, which no linter reads. Those decisions cover the object-header split, the size and terminator check, the tree-entry regex with `\G` alignment, first-match on duplicate names, mode regexes, and the commit header parse. Every test drives it through the whole snippet: T33's sed tamper, T36's in-place rewrites, the missing commit and the shallow clone. No test names any single parsing rule. So finding 1's late-`parent` divergence, a duplicate tree name, or an `entry` misalignment can change without a red test.

The seam already exists. The reader takes its git command as trailing arguments (`my ($root, $out, $c, @git) = @ARGV`) and answers on stdout. P1 extracted it with one regex, `perl -c` passed, and it ran against a crafted repository with no change to the snippet. A further constraint for future edits: the program cannot contain a single quote.

Evidence (verbatim):
- `test/lib/d6-snippet.bash:58-59`: `  P='use strict; use IPC::Open2; use Digest::SHA qw(sha1_hex);` / `    my ($root, $out, $c, @git) = @ARGV; open2(my $r, my $w, @git, "cat-file", "--batch"); binmode $r; binmode $w; $w->autoflush(1);` (program continues to `:71`, `    print "main\n";'`)
- `test/lib/d6-snippet.bash:64`: `      while ($b =~ /\G([0-7]+) ([^\0]+)\0(.{20})/gs) { my ($md, $nm, $id) = ($1, $2, $3); next unless $nm eq $n; die "$n is not a $m entry\n" unless $md =~ $m; return unpack("H*", $id) } die "no $n in $t\n" }`

**Recommendation:** add one bats test that extracts `P` from the snippet the way P1 did. It should assert `perl -c`, then drive the reader through `@git` against crafted objects: a late `parent` line, a duplicate name, a name that is not an id, an object of the wrong type. Each rule then has a named failure.

#### 3. The store_check ↔ reader cross-reference is one-way; the plan and c9648432 say each names the other

**Severity:** Minor
**Location:** `scripts/build-loop.sh:927-930`; `test/lib/d6-snippet.bash:1-35`, `:55-57`; `docs/working/plan-build-loop-handoff.md:326`
**Move:** 7 (two implementations of one invariant), 3
**Confidence:** High (all three fact-check replicates: Incorrect, doc)
**Legibility-target:** whoever changes either verifier (a SHA-256 move, a new second-copy rule)

i2's B10 asked the two hash-verifiers to point at each other so that a change to one prompts a look at the other. store_check's header now names the snippet. The snippet's header and the reader's comment never mention store_check. The plan's as-built note and c9648432's message claim both directions, so a reader of the snippet alone does not learn about the stricter sibling. This matters most for the divergences that are deliberate today: SHA-256 support, the second-copy rule, and which objects each covers. The pair is forced duplication (the snippet cannot source the lib), and a comment is the only link.

Evidence (verbatim):
- `scripts/build-loop.sh:928-930`: `# and have one copy each (rows 492, 503). (The D6 snippet, test/lib/d6-snippet.bash,` / `# runs a narrower reader before this script: SHA-1 only and no second-copy rule,` / `# since it uses only bytes it has hashed itself.)`
- `test/lib/d6-snippet.bash:55-57`: `  # The verified reader (args: D6_ROOT, the temp dir, main's commit, the git` / `  # command). It prints "main" once the four files are written, "other" when` / `  # the first-parent root is not D6_ROOT; any failure dies (status 255).`
- plan `:326`: "the snippet's reader is narrower, SHA-1 only and needs no second-copy rule since it uses only bytes it hashed; each comment names the other"

**Recommendation:** add one clause to the reader's comment naming build-loop.sh's store_check as the in-script, stricter check. Alternatively, correct the plan note, since the commit message is immutable.

#### 4. The snippet's perl runs in the orchestrator's unscrubbed environment without the lib's perl pins

**Severity:** Informational
**Location:** `test/lib/d6-snippet.bash:78`; convention at `scripts/lib/dev-cycle-read.sh:117-129`
**Move:** 4 (implicit convention across modules)
**Confidence:** Medium
**Legibility-target:** U4's author and the security reviewer (B5, the trusted orchestrator environment)

The lib states a convention for perl: PERL_UNICODE, PERL5OPT and PERLIO are removed and the handles are binmoded. The reader binmodes its own handles, so byte handling is safe. But it runs before any `scrub_reexec`, with `LC_ALL=C` only, so a PERL5OPT or PERL5LIB in the orchestrator's environment shapes the program that decides what runs. Under the lib header's trust model (B5: the caller's environment is trusted), this is not a new exposure; PATH and BASH_ENV for `bash -s` are the same class. It is still an unstated exception to a convention the codebase otherwise follows. store_check's perl (`build-loop.sh:968`) runs after the scrub re-exec, so it is not a counterexample.

Evidence (verbatim):
- `test/lib/d6-snippet.bash:78`: `    x="$(LC_ALL=C perl -e "$P" "$D6_ROOT" "$t" "$sha" "${G[@]}")" || no "$m's first-parent history, the trees above scripts/lib/ or the four files could not be read whole, or an object does not hash to its id"`
- `scripts/lib/dev-cycle-read.sh:129`: `  env -u PERL_UNICODE -u PERL5OPT -u PERLIO LC_ALL=C perl -C0 -ne '`

**Recommendation:** either run the reader as `env -u PERL5OPT -u PERL5LIB -u PERL_UNICODE -u PERLIO LC_ALL=C perl -C0 ...`, or name the environment as trusted in the snippet header, next to its BASH_ENV note.

## What Looks Good

- **One reader that both decides and extracts.** The i2 rewrite fixes the real structural defect behind A1/B1: the check and the use were different processes. The bytes written are now the bytes hashed, and every next id comes from checked bytes. That removes the need for store_check's second-copy rule inside the snippet, and it is the right shape. It is also a cleaner structure than patching each reader.
- **Explicit three-state selector.** `main` / `other` / die, with a fourth "no answer" branch refusing (`:80-86`). Error is no longer folded into "not claude-workflows" (i2 B2; my i2 note). Finding 1 is about the predicate's input, not this shape.
- **git_harden in the lib.** Both entry scripts call it at the same point, after `scrub_reexec` and before the first git call. Its trust model is stated once. The `CALLER_COUNT` sentinel makes a second call a no-op, and the environment test pins that. caller_gate reads HARDEN, so a key added to the list is refused by name with no edit to build-loop.sh.
- **The forced HARDEN duplicate is pinned by an oracle.** The snippet cannot source the lib, so the test holds a literal `H`/`E` and asserts both the lib's export and the snippet's `G` line equal to it (`build-loop-orchestrator.bats:346-361`). Adding a key without updating all three turns the test red. The two call-log tests derive from the lib (B9). This is the right substitute for a shared module. The precedence difference is settled at row 737.
- **Snippet as a script read by bash, not a function pasted into the caller's shell.** This isolates it from zsh and aliases and from the scripts reading the heredoc. It exports no pair, so `--state` passes caller_gate by construction (T33).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Trust-root selector reads the untrusted store; another project can switch from /opt to its own scripts (plus a late-`parent` parse git does not share) | Coupling | `d6-snippet.bash:65-67, 77-86` | High (mechanism) |
| 2 | Verified reader is tested only end to end though it has an argument seam | Minor | `d6-snippet.bash:55-71` | High |
| 3 | store_check ↔ reader cross-reference is one-way; plan/c9648432 say both | Minor | `d6-snippet.bash:55-57`; plan `:326` | High |
| 4 | Reader's perl lacks the lib's PERL* pins (trusted-env class) | Informational | `d6-snippet.bash:78` | Medium |

## Re-flagged settled decisions

- **Row 732 (moved main, Won't-Fix):** finding 1 is adjacent but, in my reading, not covered. The row's text and reason ("on top of the real history"; D13 catches an honest slip, not a forger) concern claude-workflows, where main is the trust root by design. Finding 1 is a project whose trust root is `/opt` choosing main instead. The security reviewer and the user decide whether the row is widened or a new row is opened.
- **Rows 644/648 (store_check stays in build-loop.sh):** not reopened. Finding 3 is about the missing back-reference only.
- **Row 736 (amends 704: git_harden is no orchestrator wrapper):** the decision stands. If U4 takes the "third HARDEN copy" option, the equality test greps only `d6-snippet.bash`, so U4 must extend it to the new copy (the row says "pinned by the equality test").
- **Row 737 (opposite precedence of -c and count pairs):** not re-flagged; the oracle pins lists, not precedence, as the row says.
- **Row 738 (canonical copy in test/lib/):** not re-flagged; U4's.
- **Rows 509/200 (0700 temp-dir race) and 548 (dev-cycle.sh runs no state/default gate):** no structural finding.

## Overall Assessment

The unit improves the structure. Hardening is now one lib function both entry scripts call at the same point. The orchestrator's entry point is a self-contained script whose forced duplicates (HARDEN, the environment) are pinned by an oracle test. The i2 rewrite removed the check-then-use gap rather than patching it. Findings 2-4 can be fixed in place with a test, a comment and an `env -u`.

The one structural concern is finding 1: which trust root runs is decided by repository content, so the image copy's protection holds only while a project's loop cannot fabricate D6_ROOT in its main's history, and it can. Fixing it means moving B2's input outside the repository, which is a joint security/architecture decision. It should be ruled on before U4 writes the image-copy promise into SKILL.md.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/architecture-review-2026-10-12-u3b3-final.md, structured per the architecture-review skill.
- Answered: yes. The reader as an embedded perl program covers readability and testability (finding 2) and the boundary with store_check (finding 3, Dependency Map). git_harden in the lib is covered under What Looks Good and the Dependency Map (no new finding). The snippet's HARDEN duplication under the equality test is covered under What Looks Good and the row 736 note. Structural changes from the i2 rewrite are findings 1 and 4 and the What Looks Good items on the single reader and three-state selector.
- Out of scope: exploitability and severity of finding 1's cross-project switch (security; r1's escalation). Whether PERL5OPT in the orchestrator environment is a real exposure (security, B5).
- Escalate: finding 1 to security and the user. Is r1's cross-project switch covered by row 732 or a new row? Does the selector's input move outside the repository before U4? P1's late-`parent` result is a second route to the same predicate and should accompany the escalation.
- Decisions I made: I filed finding 1 as Coupling rather than Structural. The defect is the selector's input, not the module's placement, and severity is security's to set. I filed it as new rather than under row 732, because that row's evidence and reason name only claude-workflows. I rated finding 3 Minor, not Informational, because two artifacts (plan, commit message) assert a cross-reference that does not exist.
