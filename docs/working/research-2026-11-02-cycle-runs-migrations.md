# Research: the cycle runs migrations itself and closes a cleared image-lag entry

- **Goal**: The dev cycle runs a pending registry migration's remedy itself and lands it with a `--cycle-diff`/`--land-cycle` migration mode that proves answers and Status lines unchanged, and closes an open `image-lag`/`image-off-main-*` entry itself when step 0.1 finds the image current.
- **Problem framing**: Two restrictions spend owner attention on work that is scripted and cannot forge an answer: every pending migration becomes a `you: terminal` paste, and a cleared image-lag entry waits for an owner answer. Considered and discarded: "the gate's answer rule is too strict in general" (dropping the anti-forgery rule for all entries); the rule guards an in-scope threat (R60/H4: an honest slip writing `[1]` on a merge entry), so only these two shapes are exempted.
- **Project state**: restriction-audit unit 5 · follows units 1-4 (63ba32e9, 242081af, 78dad60b, 3019016a); units 6 and 7 are separate · not blocked (cite: docs/working/research-2026-11-01-restriction-audit.md)
- **Task status**: complete (implemented, tested, reviewed)

## Re-verification against today's code (dispatch commit 9a50c75a)

The audit's line numbers predate units 1-4. At 9a50c75a:

- **R46** [observed]: `skills/dev-cycle/SKILL.md:454` "The cycle does not run the remedy itself: a migration rewrites the questions files' entries or the roadmap's headings, which step 9's `--cycle-diff` refuses without the owner"; `:496` legacy watches close "after the user's one `questions.sh migrate` run"; `:501` legacy agent entries "left for `migrate`"; `:609` the listing "left by the user's `questions.sh migrate`". Still as the audit described. The stated reason is true of the gate: `questions.sh migrate` removes the legacy entries from `questions.md` (moving them to `watching.md` or `roadmap-from-questions.md`), and `QDIFF_AWK` (`scripts/build-loop.sh:1894`) refuses every such entry as "gone" because it reads only the two questions files. So the restriction is real, and the fix has to be in the gate, as the brief says.
- **R70 (a)** [observed]: `cycle_rules` (`:1973`) and `questions_rules` (`:2077`) refuse an entry whose heading, Needs or answer lines changed or are gone, or a new entry filed answered, without `--answered` (`:2106-2107`). KEEP, as the audit says: its threat (an honest slip self-approving a merge) is in scope. The migration mode and the image-lag close are added as two narrow exceptions that write no answer.
- **K105** [observed]: `guides/convention-changes.md:55` "The cycle cannot run the remedy itself"; one `you: terminal` entry per pending migration. Still as described.
- **Contradiction 4** [observed]: the global instructions (`global-instructions/CLAUDE.md:270`, installed `~/.claude/CLAUDE.md:273`) say "Several terminal entries collect into a single paste, never asked one at a time". At 9a50c75a step 1b already collects the paste ("two or more filed this iteration: one paste, in the first, which the others point at") but still files one entry per migration. After this change only migrations the cycle cannot land go to the owner, as one entry with one paste, so the contradiction is gone.
- **Stale message** [observed]: `scripts/dev-cycle.sh:190` `--check-fix` skip says "(use --check-write)"; unit 3 (`2026-11-01-relax-dev-cycle-skill-prose`) dropped that call from the skill, whose Rules now say the cycle writes its own files "with no pre-write check: step 9's `build-loop.sh --cycle-diff` bounds what lands" (SKILL.md:135-136). Reworded to that.

### A restriction the audit missed, kept

The audit's K105 NARROW assumes every remedy is like `questions.sh migrate`. The registry also holds `failure-patterns-out-of-thoughts`, whose remedy is `git mv docs/thoughts/failure-patterns.md docs/failure-patterns.md`: both paths are records `truthrule` refuses in `--cycle-diff` (R70 (i), owner truth; decision log row 78 keeps the library on the self-merge floor). The migration mode does not lift the truth-file rule: a remedy whose PATH is not `docs/working/questions.md` or `docs/roadmap.md` is refused by `--migrated` and stays an owner paste, now one collected entry. The in-scope threat is the same as R70 (i): a later run reads the library as truth, so a cycle commit must not write it.

## What exists

- `scripts/lib/migrations.sh` [observed]: the registry (`mig ID CONVENTION FP PATH ERE REMEDY`), sourced by `dev-cycle.sh` for digest section 7b (pending while PATH holds an ERE match). Two remedies change files: `questions-owner-routes-040` (PATH `docs/working/questions.md`, ERE `^\*\*Needs:\*\* (agent|trigger|deferred)( |$)`, remedy `~/.claude/scripts/questions.sh migrate`) and `failure-patterns-out-of-thoughts`.
- `scripts/questions.sh migrate` [observed, lines 494-566]: moves each non-owner entry, text unchanged, to `watching.md` (watches; ANSWERED ones under `## Closed`) or `docs/working/roadmap-from-questions.md` (agent work), then reindexes. `test/questions-doc.bats` "migrate moves every non-owner entry out without losing text" proves losslessness.
- `scripts/build-loop.sh` `cycle_diff`/`land_cycle` → `cycle_rules BASE SIDE` → `questions_rules`, with `QKEYS_AWK` (key lines per entry: h, n, a) and `QDIFF_AWK` (compares base against side; `--answered` IDs exempt) [observed].
- The D6 block runs `/opt/claude-workflows/scripts/{build-loop,dev-cycle,questions}.sh` and the lib beside them; `build-loop.sh` sources its lib from `SCRIPT_DIR` [observed: build-loop.sh:553-557]. So a registry read from `SCRIPT_DIR/lib/migrations.sh` is the image's copy under D6 (H1), and `questions.sh SUB` through the D6 block is the image's `questions.sh`.
- Step 0.1 (SKILL.md:286-313): image lag; on `diff --quiet` exit 0 it listed open `image-lag`/`image-off-main-*` entries "as cleared, for the user to answer (the orchestrator never answers one: D8)".

## Invariants

- H4/D8: the orchestrator never writes an answer it did not get from the user, except the two shapes below, and the gate checks each from the artifact (an exact line form, an ERE match on the base) [observed: QDIFF_AWK].
- A questions file `--check-answer` refuses whole still refuses (ANSWER_AWK run first, unchanged).
- The truth-file, gate-code and path rules apply to every path, migration or not.
- The registry is append-only and fingerprinted: a change to SKILL.md step 9's record template needs a new `mig` line (`record-1b-ran` added; `bash scripts/lib/migrations.sh check` passes).
- The D6 block is not edited (its test pins it byte for byte).

## Prior art

- `--answered Q-NNN` is the existing exemption mechanism; the watching.md rule (decision 040) already lets the cycle close its own watches without the owner.
- Digest section 7b already reads the same registry beside the script; `mig_rules` follows its pattern (regular file, `bash -n`, `MIG_BAD` empty, else not checked → here, refuse).

## Gotchas

- Failure-pattern grep: FP-021, FP-053
  - FP-021 (agent-writable file baked into the image) is about the image payload, not the cycle rules; it does confirm the gate must read the registry from its own directory (the image), never the checkout. FP-053 (inf/nan accepted as a verified answer) is unrelated numerics.
- mawk has no `{n}` interval expressions: the image-off-main slug is checked by length 27 and a character class.
- QDIFF_AWK's `o[id] != nw[id]` creates `nw[id]` as a side effect, so presence on the side is tracked in its own array (`in2`).
- A watch the migration moves and step 3 closes in the same iteration would change its Status: the skill closes such a watch in the next iteration.
- `roadmap-from-questions.md` is where the gate finds moved agent entries, so step 6 folds it only once it is on main (the iteration after the migration).

## Design decisions (divergent design, seeded with docs/constraints.md and the brief)

### D-A: how the migration mode is selected and what it proves

Options:
1. **`--migrated ID` flag; the gate reads its own registry and checks invariants scoped to the ERE's matches.** ID must be a registry line, PATH the questions file or roadmap, ERE matching on the base (pending) and not on the side (ran); only entries holding a base line the ERE matches may change heading/Needs or move to `watching.md`/`roadmap-from-questions.md`, and their answer lines and Status fields must be unchanged in order.
2. **Replay**: the gate re-runs the remedy on the base's files and requires the side to equal its output byte for byte.
3. **Blanket flag** (`--migration`, no ID): any entry may change heading/Needs or move, answer and Status lines unchanged.
4. **Reuse `--answered`** for every moved ID.
5. **Status quo**, with one collected terminal paste.

Hard lines: H1 (registry and remedy from the image), H2 (unreadable registry refuses), H4 (no answer written; gate keys on re-checkable facts). 4 fails H4: `--answered` exempts answer lines too, and records the moves as the user's answers. 2 fails in practice: the chore commit carries the cycle's other edits to the same files (new entries, archive moves), so byte equality never holds unless the migration gets its own land, which `--land-cycle` (one record per land) does not support without new machinery (S3, S8); it would also make the gate execute a registry string (CLAUDE.md's argv rule). 3 lets an honest slip rename or reroute any entry in the same commit, so it does not prove "the remedy's and nothing else". 5 keeps the S10 cost the brief exists to remove (S5: the motive is real; Q-234's `chore/q234-migrate` branch was such an owner-run remedy). **Option 1 dominates** (Path A): smallest code, every check re-checkable from the base and side blobs, and the remedy's scope is exactly the lines its own ERE names.

### D-B: a `you: fyi` per migration run, or the record and final message

A fyi spends the owner's attention (S10; the global instructions: "keep it rare") on a move that is scripted, lossless (tested), visible under the record's `### Paths landed` and undone by one revert. **Record and final message only.** An open `migrate-ID` entry from before stays for the owner to answer.

### D-C: how the image-lag close is checked

Options: (1) shape only on those slugs: one Status field OPEN→ANSWERED and exactly one line `Q-NNN: met — image C holds the gate code of main M` (own ID, full ids), nothing else changed; (2) the gate also re-runs `git diff --quiet C M -- GATE paths`; (3) a flag `--image-cleared`. (2) adds a gate dependency on the image manifest and a new failure path for no in-scope gain: a wrong close (an honest slip) is self-correcting, since the next step 0.1 exit 1 files a new `image-lag` entry. (3) adds a flag with nothing to select: the slug and line form already pin the change. **Option 1.** Its tests refuse every other shape, including the closing line on a merge entry, an answered image-lag entry and a near-miss slug.

### D-D: migrations the cycle cannot land

Kept with the owner (truth files: see above), as one `you: terminal` entry whose one paste runs them all (resolves contradiction 4).

## Plan (as implemented)

1. `scripts/build-loop.sh`: `--migrated ID` on `--cycle-diff`/`--land-cycle`; `side_blob`, `mig_rules` (registry from `SCRIPT_DIR/lib`, pending/finished checks); `QKEYS_AWK` m marks from the base's ERE matches; `QDIFF_AWK` `keysig` (answer lines and Status fields) and `cleared` (image-lag close); `ROADMAP_AWK` `free` for a roadmap migration; header docs.
2. `scripts/lib/migrations.sh`: header comments; `mig record-1b-ran` for the record template's new `ran ID` form.
3. `scripts/dev-cycle.sh`: `--check-fix` skip message; digest legacy-watch note names step 1b.
4. `skills/dev-cycle/SKILL.md`: steps 0.1, 1b, 3, 6, 9 and the final message.
5. `guides/convention-changes.md`: "What the dev cycle does with it".
6. Tests (`test/scripts/build-loop-orchestrator.bats`): a real `questions.sh migrate` output passing `--cycle-diff` and `--land-cycle --migrated`; refusals for a changed answer or Status, a dropped entry, an unfinished remedy, an unknown/no-file/truth-file ID, a not-pending migration; a roadmap migration from a copied gate with an extra registry line, and an unreadable registry refusing; the image-lag close passing (40 and 64 hex, archive move) and every other shape refusing, the closing line on a merge entry included. Pins updated: the legacy-watch note (two tests) and the `--check-fix` message.
7. Docs: plan D8 and D13 amendments and the script-interface note; decision log row 82.

Test strategy: each new refusal path has a case asserting the refusal text (H2); the pass cases use the real remedy (`scripts/questions.sh migrate`) in the fixture repo, all hermetic (no network, no `claude`; H3).

## Files read

Last verified: 2026-11-02

- docs/working/briefs/2026-11-02-cycle-runs-migrations.md
- docs/working/research-2026-11-01-restriction-audit.md
- docs/constraints.md
- docs/working/plan-build-loop-handoff.md
- docs/decisions/log.md
- docs/failure-patterns.md
- scripts/build-loop.sh
- scripts/lib/migrations.sh
- scripts/lib/dev-cycle-read.sh
- scripts/questions.sh
- scripts/dev-cycle.sh
- scripts/health-check.sh
- skills/dev-cycle/SKILL.md
- guides/convention-changes.md
- global-instructions/CLAUDE.md
- test/scripts/build-loop-orchestrator.bats
- test/scripts/convention-migrations.bats
- test/scripts/dev-cycle.bats
- test/questions-doc.bats
- test/lib/build-loop-fixtures.bash
- workflows/research-plan-implement.md
