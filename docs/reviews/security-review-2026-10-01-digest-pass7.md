Commit: 47c9a8e (A) / d6e1f24 (B)

# Security Review — dev-cycle loop pass 7 (digest fixes A + skill/docs fixes B)

**Scope:** A: `git diff 28c6178..47c9a8e -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest; commits ef0471c, 47c9a8e). B: `git diff c079e8c..d6e1f24 -- skills/dev-cycle/SKILL.md docs/decisions/log.md guides/skill-creation.md docs/dev-cycle.md docs/dev-cycle-sources.md workflows/codebase-onboarding.md docs/working/questions.md` (wt-devcycle; commits 5e8bfd9, d6e1f24), plus the A↔B contract. Partial scope: the two fix rounds only; everything else is context.
**Date:** 2026-10-01
**Based on:** Stage-1 context `docs/reviews/code-fact-check-report-digest-pass6.md` (its Incorrect / Mostly-accurate claims, checked against round two); prior security review `docs/reviews/security-review-2026-10-01-digest-final5.md` (F1–F7, checked for fix status).
**Goal anchor:** pinned upstream by the orchestrator's goal preamble.

Probes ran under `timeout`. Throwaway repos went in a `mktemp -d` dir under `scratchpad/sec7/`, and that dir was removed afterwards. Nothing was written to either worktree except this file. `bats test/scripts/dev-cycle.bats` passed 20/20 at the wt-digest HEAD; `scripts/dev-cycle.sh` there is unchanged since 47c9a8e.

## Status of the final-pass-5 security findings

| Prior | Status at 47c9a8e / d6e1f24 | Basis |
|---|---|---|
| F1 PERLIO disables scrub | Fixed: `-u PERLIO` plus `binmode STDIN; binmode STDOUT` | executed (bats test 5 env loop covers `PERLIO=:utf8`, `:raw:utf8`; passes) |
| F2 sources file picks read/write paths | Partly fixed. The write side is now fixed at `docs/working/idea-log.md`. The read side carries a prose "inside the repo" rule. A symlink variant remains on both sides (Finding 2) | read-static + executed digest probe |
| F3 no human between repo text and autonomous merge under /away | Addressed by design. The brief now explicitly "stands in for RPI's plan approval", a minimum stop-condition set is defined, and the per-project policy defaults to `review`. The `autonomous` policy is an informed opt-in. The residual is Finding 1 | read-static |
| F4 brief not pinned | Fixed (`SKILL.md:246-248`) | read-static |
| F5 no worktree isolation | Worktree isolation fixed (`SKILL.md:246`). The branch re-check before cycle commits was not added (carryover Low, not re-filed) | read-static |
| F6 residual scrub gaps | "Not covered" list completed. One parenthetical overreaches (Finding 5) | executed |
| F7 quoted names drop out of section 7 | Fixed (`core.quotePath=false` plus `"?` in the patterns; test 20 adds `skills/café`) | executed (bats 20) |

## Trust Boundary Map

```
B1: [repo text: commit subjects, file names, decision records, log rows, roadmap, idea log] → [scrub(), A:37-54, via self re-exec A:63-66] → [digest → terminal and the cycle agent's context]
B2: [process environment: PERLIO, PERL_UNICODE, PERL5OPT, DEV_CYCLE_SCRUBBED]               → [env -u … / LC_ALL=C / -C0 / binmode, A:39-40]  → [scrub's byte semantics]
B3: [committed paths, possibly symlinks]   → [inrepo() realpath check, A:89; now also the cycle-record glob, A:116] → [file reads printed into the digest]
B4: (moved) [committed paths the *agent* reads/writes: idea log, idea sources, roadmap, briefs, records] → [prose rule "Only paths inside the repo count", B SKILL.md:43-44; no realpath check] → [agent Read/Write/append]
B5: (new) [docs/dev-cycle.md "Build-loop policy:" line (repo text)] → [interim/missing ⇒ `review`, B SKILL.md:44-45] → [6b loop end state: self-merge vs stop for review]
B6: (moved) [roadmap Now items → build brief, pinned at the landed commit] → [step 6 queue (/active confirm), stop-condition minimum, B SKILL.md:203-211,245-258] → [autonomous RPI loop in its own worktree with commit (and, under `autonomous`, merge) authority]
B7: [Q-103 entry text] → [user's judgment] → [this repo's policy value]
```

Input-source classification:

```
S1: commit subjects / merge messages / file names — runtime-mutable — UNTRUSTED for terminal and instruction sinks; trusted for counting
S2: committed file contents (records, log, roadmap, idea log, idea-source files) — runtime-mutable — UNTRUSTED for instruction sinks; trusted as data to weigh
S3: committed symlinks / path strings — runtime-mutable (any committer, any 6b loop, any cloned repo) — UNTRUSTED for path-construction (read and write) sinks
S4: process env (PERLIO etc., DEV_CYCLE_SCRUBBED) — deploy-time (user's shell) — trusted against attackers; out of the repo-text threat model
S5: docs/dev-cycle.md policy line — runtime-mutable (any merge to the default branch; any 6b loop on its own branch) — UNTRUSTED as an authorization source for self-merge
S6: build brief at the landed commit — runtime-mutable before landing, pinned after — trusted as the loop's instruction source only as pinned
S7: Q-103 option text — agent-authored — trusted as data; it shapes an authorization decision, so its accuracy matters
```

What enters from outside is repo text from the user, other sessions, 6b loops (a closed loop), and any cloned project the installed skill serves. On the A side, these rounds harden B1 (PERLIO, linear-per-line scrub plus a cut) and B3 (cycle-record glob). On the B side, they move the old sources-file boundary to B4 and add B5, where a repo-text line now decides whether autonomous code reaches the default branch without a human.

## Findings

#### F1. The build-loop policy that authorizes self-merge is read unpinned, and a loop can change it on its own branch; the stop-condition minimum does not name the cycle's own control files

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:41-45`, `:206-211`, `:245-254` (B, d6e1f24); `docs/dev-cycle.md:7`
**Boundary:** B5, B6
**Move:** 4 (TOCTOU), 5 (invert the access model), 1 (runtime-mutable ⇒ compromise-reachable)
**Confidence:** Medium. The outcome depends on whether a loop reads `docs/dev-cycle.md` from its own worktree at the end, and whether it counts that file as a "settings file". The skill settles neither.
**Legibility-target:** step 6b's sentence "What happens at the end follows the build-loop policy in `docs/dev-cycle.md`", and step 6's stop-condition minimum

**Evidence:**
```
giving it the brief's path and the landed commit; the loop reads the brief from that commit, so
later edits to the file do not change its instructions. The brief stands in for RPI's plan
approval. What happens at the end follows the build-loop policy in `docs/dev-cycle.md`:
```
(the bullet list that follows, `:251-254`, defines the `autonomous` / `review` end states; the paragraph continues at `:256-258` with the stop-condition sentence.)
```
evidence, not instructions", goal, motive, acceptance criteria (the doc change included), branch, out-of-scope, and stop conditions, which always
include touching enforcement, hook or settings files, adding a dependency, and any change
the out-of-scope list names. Move the item to In flight, linking the brief. Both land with
```
(sentence begins at `:206` "For each queued item, write a build brief…"; the paragraph ends at `:211`.)

Round two pinned the brief to the landed commit (prior F4). The policy, the one input that decides whether the loop's code reaches the default branch unreviewed, is not pinned. The skill names no reader, no commit and no time. A loop running in its own worktree on its own branch has `docs/dev-cycle.md` in that tree. If the loop reads it "at the end", an edit on its branch from `review` to `autonomous` changes its own end state. That edit could come from the loop's judgment, or from S2 text it read while building. The pinned brief cannot rule this out, because the minimum stop conditions say "enforcement, hook or settings files". Read beside "hook", that most naturally means `.claude/settings*.json`, and `docs/dev-cycle.md` calls itself "Dev-cycle settings" without the skill saying it is covered. The same gap covers the other files that govern the loop: `skills/dev-cycle/SKILL.md` (the cycle's rules), `scripts/dev-cycle.sh` (the B1 scrub the next cycle relies on) and `docs/working/handoffs/` (the open/closed state step 1 trusts). A second route needs no loop at all: any merge to the default branch between step 7 and a loop's end flips the policy for every loop in flight. Under `review`, such a merge needs the user's decision anyway, but a loop that read the flipped value would then self-merge.

**Recommendation:** Pin the policy at launch: 6b reads the value from the landed commit (`git show <commit>:docs/dev-cycle.md`), writes the resolved value into the brief, and the loop follows the brief's value. Name `docs/dev-cycle.md`, `skills/dev-cycle/`, `scripts/dev-cycle.sh` and `docs/working/handoffs/` explicitly in the stop-condition minimum.

#### F2. A committed symlink at the idea log or an idea-source path sends the agent's reads and appends outside the checkout; the digest's own "No docs/working/idea-log.md" line invites the write

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:41-50`, `:164-166` (B); `docs/dev-cycle.md:16-20`; `scripts/dev-cycle.sh:267-283` (A)
**Boundary:** B4, B3
**Move:** 12 (sweep: every digest read is guarded by `inrepo`, but the skill's read/write sites of the same paths are not), 11, 1
**Confidence:** Medium on the mechanism (the digest part was executed). Whether the write lands depends on the agent's tool: a shell `>>` or an Edit that follows the link writes outside the repo, while a harness that resolves paths and prompts for out-of-tree writes would stop it, and under /away that prompt is the only barrier.
**Legibility-target:** the "Seeding is always on" paragraph ("create it with a `# Idea log` heading") and the settings paragraph's "Only paths inside the repo count"

**Evidence:**
```
**Seeding is always on.** Any step that notices an idea appends one line to
`docs/working/idea-log.md` (create it with a `# Idea log` heading), shaped
`- <idea> (signal: <what prompted it>)`, with no ranking. Only lines of that shape count as
seeds.
```
```
step 13 asks the user to set, and the **idea sources** step 5 reads, kept by hand. Only paths inside the repo count; ignore any
entry that points outside it. No file, no policy line, or a value marked `(interim)`: use `review`, and
```
(paragraph begins at `:41` "**Project settings.**" and ends at `:45` "…file one asking the user to set it.")
```
| Feature ideas | docs/working/feature-ideas*.md | the self-improvement loop's idea files |
```

Executed: in a throwaway repo, `docs/working/idea-log.md` and `docs/working/feature-ideas-x.md` were committed as symlinks to a file outside the checkout. The digest's `inrepo` treats the log as absent and prints `- No docs/working/idea-log.md: no ideas seeded, no brainstorm recorded`. The skill then tells the agent to append to, or create, exactly that path. Writing there follows the link and appends S1/S2-derived `signal:` text to the outside target, for example `~/.claude/CLAUDE.md` or another always-loaded instructions file. That reopens prior F2's write concern through a symlink instead of the deleted sources file. On the read side, the default glob `docs/working/feature-ideas*.md` matches the in-repo symlink, which passes the lexical "inside the repo" test, so step 5 reads outside content, and surviving ideas derived from it are committed to `docs/roadmap.md`. That discloses it into history. Any committer can plant these links, and so can a cloned third-party repo that the installed skill serves. The same unguarded write pattern applies to `docs/roadmap.md`, cycle records and briefs, although for those the digest's "No docs/roadmap.md yet — create it" line is the only explicit invitation.

**Recommendation:** State the rule as the digest enforces it: "a path counts only if it is a regular file, or does not exist, and its real path (`realpath -e`, or `realpath -m` for a new file) is inside the repo root; never write through a symlink". Apply it to the idea log, the idea sources, the roadmap, records and briefs. Optionally, have the digest print "docs/working/idea-log.md is a symlink out of the repo — do not write it" instead of "No …".

#### F3. Q-103's option [2] misstates how a bad autonomous change is caught, on the line the user decides from

**Severity:** Low
**Location:** `docs/working/questions.md` (Q-103 options table, d6e1f24)
**Boundary:** B7, B5
**Move:** 5
**Confidence:** High (read-static against `SKILL.md:126-134` and the digest's `--sample` default of 2, `scripts/dev-cycle.sh:69`)
**Legibility-target:** the `[2] autonomous` row's "If it's wrong" cell

**Evidence:**
```
| **[2] autonomous** | Each loop lands its branch through pr-prep's local merge on its own | None per item; you read results in the next cycle's digest | A bad change lands on main and is caught only by the next cycle's spot-check |
```

"Caught only by the next cycle's spot-check" is wrong in both directions. Before the merge, pr-prep's review-fix loop, which includes code-review and security-reviewer, runs on every autonomous branch. After the merge, step 4 samples `--sample` merges (default 2) plus the code-without-docs list, so most autonomous merges are never spot-checked. The cell implies one guaranteed post-merge check. In fact there is a guaranteed pre-merge automated review and a probabilistic post-merge one. This is the authorization decision for B5, so the text the user decides from should state the real gates. It is not exploitable, so it is rated Low.

**Recommendation:** Reword: "A bad change lands on main after passing only pr-prep's automated review; the next cycle spot-checks a sample (default 2 merges), so it may never be looked at by you."

#### F4. The interim marker in the file does not match the skill's literal marker, and unrecognized policy values have no default

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:44-45`; `docs/dev-cycle.md:7`
**Boundary:** B5
**Move:** 5 (enumerate the cases the check does not cover), 11
**Confidence:** Medium. It fails safe today because the interim value is `review`.
**Legibility-target:** the settings paragraph's "a value marked `(interim)`"

**Evidence:**
```
entry that points outside it. No file, no policy line, or a value marked `(interim)`: use `review`, and
unless an open `you: judgment` entry already asks for it, file one asking the user to set it.
```
```
Build-loop policy: review (interim; Q-103)
```

The file carries `(interim; Q-103)`, not `(interim)`. A literal reader does not see this repo's value as interim, so it would not apply the "file an entry" branch. Q-103 already exists, so the result is the same today. Cases the rule does not cover, traced by reading: (a) `autonomous (interim; …)`: under the literal reading this is honoured as `autonomous`, which is the one case the interim rule exists to prevent. (b) Unrecognized values such as `auto`, `Autonomous`, `autonomus` or `yes`: no clause says these mean `review`. (c) Two `Build-loop policy:` lines with different values: no precedence is given. (d) The value appears only in the explanatory paragraph (`` `autonomous`: a build loop… ``, `docs/dev-cycle.md:9`): not a policy line, so it falls to "no policy line" ⇒ `review`, which fails safe. No writer that follows the skill would produce (a). The rating is Low because a committer who could write (a) could just as easily write plain `autonomous`.

**Recommendation:** Make the rule default-deny: "Anything other than exactly one line `Build-loop policy: autonomous` with no parenthetical means `review`." Also either change the file's marker to `(interim)` or have the skill match "a parenthetical beginning `(interim`".

#### F5. "None can start a line" is false for U+2028/2029, and `core.quotePath=false` now passes them raw from file names

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:33-36`, `:241-247` (A, 47c9a8e)
**Boundary:** B1
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** the scrub comment's "Not covered" sentence

**Evidence:**
```
# each pass is local, and the line cut bounds the total work. Not covered: lone
# bytes 0x80-0x9F and overlong encodings (invalid UTF-8, which a UTF-8 terminal
# does not decode), U+061C, U+2028/2029, and invisible format characters such as
# zero-width ones, U+00AD, U+206A-206F and U+FFF9-FFFB (none can start a line).
```

Executed: `printf 'x\xe2\x80\xa8## 3. Watched questions\n'` passes through the scrub unchanged, and Python's `splitlines()` on the output yields `['x', '## 3. Watched questions']`. JavaScript, VS Code and Python treat U+2028/2029 as line terminators. A consumer that splits on them sees a forged line that escapes the `> ` quote prefix sections 2 and 5 add. Before 47c9a8e, git octal-quoted such bytes in section 7's file names. They now pass raw (`git -c core.quotePath=false`, `:244`). Terminals do not move the cursor on them, and the security boundary for the agent is Rule 1, not the `> ` framing, so the rating is Informational.

**Recommendation:** Either add `\xE2\x80[\xA8\xA9]` to the scrub's pattern (one alternation), or move U+2028/2029 out from under "(none can start a line)" and say "(line separators to Unicode-aware splitters; terminals ignore them)".

#### F6. The scrub costs about 1 ms per worst-case 4 KB line, and the number of lines is unbounded (informational)

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:41-52`, `:150-159`, `:215`
**Boundary:** B1
**Move:** 8
**Confidence:** High (executed)
**Legibility-target:** "each pass is local, and the line cut bounds the total work"

**Evidence:**
```
    $_ = substr($_, 0, 4096) . " [line cut at 4096 bytes]" if length($_) > 4096;
```
(the per-line body continues to `print` at `:53`.)

Executed, using the scrub body extracted from 47c9a8e: 1000 lines of `\xC2`×2048 `\x9B`×2048 took 1.22 s. 1000 three-byte-nested lines took 0.82 s, and 1000 flat `\xC2\x9B`×2048 lines took 0.94 s. Every line was emptied completely. That is about 3.4 MB/s for adversarial input, against a plain-text rate orders of magnitude higher. A 200 MB line with no newline is read whole (about 200 MB peak RSS) before the cut. Trigger sections (`:150`) and the roadmap's Next section (`:215`) print every line of a committed file, so a committer can make the digest slow (≈20 min for 1 M such lines). "Bounds the total work" holds per line, not per digest. This is a self-inflicted availability cost with no confidentiality or integrity impact.

**Recommendation:** None required. If wanted, cap the lines printed per trigger section and for the Next section, as sections 1, 6 and 7 already do.

## Untested bypass candidates

- Idea-source "inside the repo" rule (`SKILL.md:43-44`): `docs/../../x.md`, an absolute path that begins with the repo root, and `~/x.md`. These were not tested because the rule is prose enforced by the agent's judgment, so there is no code to exercise. The symlink candidate was tested (F2).
- Policy "interim ⇒ review" rule: candidates (a)–(c) of F4 were traced by reading only. No agent run was made.
- Scrub env surface beyond the three removed variables (`PERL5LIB`, `BASH_ENV` for the re-exec'd child): not tested. These are S4 (host-controlled), outside the repo-text threat model.

## Endorsement Claims

- **Claim:** On 300,000 random 1–14-byte inputs over the scrub's relevant byte alphabet, the resume-3-bytes-back loop gives byte-identical output to the fixed-point reference (`tr` then `1 while s///g`), and no output contains a matching sequence.
  **Location:** `scripts/dev-cycle.sh:44-52`
  **Evidence:** executed
  **Verified:** `scratchpad/sec7/fuzz.pl`, with the loop copied from 47c9a8e: `n=300000 mismatch=0 residual=0`
  **Not verified:** inputs longer than 14 bytes that contain C0 bytes between the halves of a 4-byte tag sequence nested more than two deep (covered for one shape by bats test 5, not fuzzed)
  **route: code-fact-check**
- **Claim:** The cut keeps a 4096-byte line whole, terminated or not, and cuts a 4097-byte one. A multibyte sequence split by the cut leaves only an inert prefix such as `e2 80` or `c2` followed by the ASCII marker.
  **Location:** `scripts/dev-cycle.sh:41-43`
  **Evidence:** executed
  **Verified:** six boundary lines through the extracted body (4094+`e2 80 ae`, 4095+`c2 9b`, 4096 terminated and unterminated, 4100 C0 + payload, 4093+`e2 80 c2 9b ae`)
  **Not verified:** a line exactly 4096 bytes long whose last byte is `\r` (C0 deletion runs after the cut)
  **route: code-fact-check**
- **Claim:** The digest's scrub removes C1, bidi and tag sequences under `PERLIO=:utf8` and `PERLIO=:raw:utf8`, as well as under `PERL_UNICODE=SDA` and `PERL5OPT=-CSD`.
  **Location:** `scripts/dev-cycle.sh:39-40`; `test/scripts/dev-cycle.bats:100-103`
  **Evidence:** executed
  **Verified:** `bats test/scripts/dev-cycle.bats` 20/20 at HEAD, test 5's env loop
  **Not verified:** other PERLIO layer stacks (`:unix:utf8`, `:utf8:crlf`) through the full script; the `binmode` plus `-u PERLIO` pair makes them reach the same code
  **route: code-fact-check**
- **Claim:** The cycle-record glob now skips a record whose real path leaves the repo. Only the file name is used, so the change affects the window start only.
  **Location:** `scripts/dev-cycle.sh:115-119`
  **Evidence:** read-static
  **Verified:** `inrepo` at `:89` and its use at `:116`
  **Not verified:** a bats case with a symlinked cycle record (test 7's symlink cases cover decisions and roadmap, `test/scripts/dev-cycle.bats:121-122`)
- **Claim:** A loop that stopped on a stop condition is not re-queued while its `you: judgment` entry is open. Rule 3 requires that entry to name the roadmap item, and the step-6 queue excludes items an open judgment names.
  **Location:** `skills/dev-cycle/SKILL.md:32-33`, `:192-194`, `:203-204`, `:256-257`
  **Evidence:** read-static
  **Verified:** the four passages read together
  **Not verified:** that the 6b loop's entry is written with the item's name (that loop's prompt is not in scope), and the 7-day-idle path, which files no entry and can re-queue
  **route: code-fact-check**
- **Claim:** The In flight rules no longer overlap. A finished item waiting on an open PR or `merge <branch>?` entry "stays, however long", and the 7-day rule applies to items "still building".
  **Location:** `skills/dev-cycle/SKILL.md:190-194`
  **Evidence:** read-static
  **Verified:** the bullet as written (pass 6 Claim 35's overlap is resolved)
  **Not verified:** two states with no rule: a PR closed unmerged, and a `merge <branch>?` entry answered "no". The item stays In flight with `Status: open`, so step 1 keeps skipping its branch.

## Primitive sweep

```
Primitive: file read/write via committed path (path traversal / symlink)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:116` cycle-record glob | S3 | inrepo (new) | cleared — name only |
| `scripts/dev-cycle.sh:152-159` decision records | S3/S2 | inrepo | cleared |
| `scripts/dev-cycle.sh:161-171` decisions/log.md | S3/S2 | inrepo | cleared |
| `scripts/dev-cycle.sh:178` questions.md (read by questions.sh) | S3 | inrepo on the path; questions.sh reads it itself | cleared — out of delta |
| `scripts/dev-cycle.sh:211-215,259-261` roadmap | S3/S2 | inrepo | cleared |
| `scripts/dev-cycle.sh:268-274` idea log | S3/S2 | inrepo | cleared — but its "No …" output feeds F2 |
| `SKILL.md:47-50` seeding append/create idea log | S3 | none | F2 |
| `SKILL.md:164-166` step 5 reads idea log + idea sources | S3/S5 | prose lexical rule | F2 |
| `SKILL.md:173` roadmap write | S3 | none | F2 (same pattern) |
| `SKILL.md:206-207` brief write | S3 | none | F2 (same pattern) |
| `SKILL.md:215` cycle-record write | S3 | none | F2 (same pattern) |
| `SKILL.md:41-45,249` docs/dev-cycle.md read | S5 | none; unpinned | F1 |

Primitive: process exec
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:39` perl | code constant | env -u ×3, LC_ALL=C | cleared |
| `scripts/dev-cycle.sh:64` bash re-exec of BASH_SOURCE | code constant | — | cleared |
| `scripts/dev-cycle.sh:180` questions.sh | SCRIPT_DIR / $HOME (S4) | — | cleared — out of delta |
| `SKILL.md:245-247` 6b launches RPI loop with the pinned brief | S6 | landed commit, stop-condition minimum | F1 (policy unpinned) |
```

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Policy that authorizes self-merge is unpinned; stop conditions omit the cycle's own control files | Medium | B5, B6 | `skills/dev-cycle/SKILL.md:41-45,206-211,245-254` | Medium |
| 2 | Committed symlink at idea log / idea source redirects agent reads and appends out of the checkout | Medium | B4, B3 | `skills/dev-cycle/SKILL.md:41-50,164-166` | Medium |
| 3 | Q-103 [2] misstates how a bad autonomous change is caught | Low | B7, B5 | `docs/working/questions.md` Q-103 | High |
| 4 | Interim marker mismatch; no default for unrecognized policy values | Low | B5 | `skills/dev-cycle/SKILL.md:44-45`; `docs/dev-cycle.md:7` | Medium |
| 5 | U+2028/2029 "cannot start a line" is false; quotePath=false passes them raw | Informational | B1 | `scripts/dev-cycle.sh:33-36,244` | High |
| 6 | Scrub cost ≈1 ms per adversarial 4 KB line; line count unbounded | Informational | B1 | `scripts/dev-cycle.sh:41-52` | High |

## Overall Assessment

The A side of these rounds is solid. The PERLIO bypass is closed by two independent mechanisms. The rewritten deletion loop matched the fixed-point reference on 300k fuzzed inputs. The cut behaves exactly at its boundary, and quoted or non-ASCII names now reach section 7. What remains on A is informational (F5, F6). The B side closed prior F4 (brief pinning) and F5 (worktrees), and turned F3 into an explicit, default-`review` policy. That also creates a new authorization input. The single most important fix is F1: resolve the policy from the landed commit at launch, carry it in the brief, and name `docs/dev-cycle.md` and the cycle's own control files in the stop-condition minimum. Otherwise a `review` loop can become `autonomous` through a file it can edit. F2 is the skill-level twin of the digest's `inrepo` and needs one sentence of real-path rule. Both are fixable in place with prose edits, and neither indicates an architectural problem. No findings within the code paths read beyond those listed; endorsement claims marked `route: code-fact-check` are pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-01-digest-pass7.md`, with the first line `Commit: 47c9a8e (A) / d6e1f24 (B)`. It follows security-reviewer's structure: header, Trust Boundary Map with S-table, Findings (each carrying Severity, Location, Evidence verbatim, Confidence and Legibility-target), Untested bypass candidates, Endorsement Claims routed to code-fact-check, Primitive sweep, Summary Table and Overall Assessment. Nothing was committed.
