# Harness feedback

Entries on how claude-workflows features work or fail in this project.
Grammar: ~/.claude/guides/harness-feedback.md.

Project: behemoth-arsenal

### F-001 · questions-entries-under-stale-route-heading
**Feature:** questions.sh migrate and dev-cycle filing · **Date:** 2026-11-20 · **Verdict:** fails

- **Context:** the owner reads `docs/working/questions.md` to answer open `you: judgment` entries; the dev cycle files new entries by appending them at the end of the file.
- **Expected:** every open entry an owner must answer reads as one, under a heading that says it is waiting on them (the global instructions' "Running questions document").
- **Observed:** the `questions-owner-routes-040` migration (Q-117, 2026-10-29) moved the `deferred` and `trigger` entries to `watching.md` but left the file's empty `## Deferred to a named event` and `## Watched conditions` headings behind. Every entry filed after it was appended under "Watched conditions", 19 of the 20 open owner questions by 2026-11-20 (Q-059, Q-060, Q-164 to Q-178, Q-184, Q-185), and the owner missed answering several because the heading said they were watches. `questions.sh check` passed throughout: it validates entries, not the section they sit under.
- **Evidence:** `git show b8b7c6d9:docs/working/questions.md` lines 81-83 (the two headings) and 87 onward (the entries below them); fixed on branch `docs/questions-layout` by deleting the stale headings. Two possible harness fixes: `migrate` removes a route heading it empties, and `check` flags a `you:` entry under a heading named for another route (or the cycle files entries into the owner's section rather than at end of file).

### F-002 · answers-file-invisible-to-the-gate
**Feature:** dev-cycle step 7 and `--check-answer` · **Date:** 2026-11-20 · **Verdict:** fails

- **Context:** the owner answers open entries by committing a plain answers file, `docs/human-author/answers-11-20-26-2.txt` (`937ef9cd`, 21 lines of the form `Q-NNN: [N]`), as they have done since September (`answers-9-27-26.txt` and later ones).
- **Expected:** a committed `Q-NNN: [N]` from the owner reaches the entry it answers, so the cycle merges Q-174 and Q-185 and sends Q-184's brief back to its loop.
- **Observed:** `--check-answer` reads only answer lines inside the questions files, so iteration 2026-11-20-2302 read all 21 as `open`, merged nothing, dispatched nothing and stopped the loop. `--main-log` classed the commit `other` (not `answers`), and no step looks inside a new `docs/human-author/` file. The cycle noticed only because the record's agent read the commit by hand. The skill gives no route for it either: the file is repo text, so it can't be taken as an answer, and the owner had to type the same three answers again in session. Earlier batches only got through because a hand session copied each file into the questions files.
- **Evidence:** `docs/working/cycles/cycle-2026-11-20.md`, iteration 2302's `7.` line; the owner's in-session answers `Q-174: [1], Q-184: [1], Q-185: [1]`, landed with `--answered` in iteration 2312. Possible harness fixes: step 0.2 or the digest flags a new `docs/human-author/answers-*` file whose IDs are still open, in the final message and the push notification; or `questions.sh` gains an `apply-answers FILE` that copies the owner's lines into their entries, landed as an `answers` commit; or the owner's answers path is a declared input `--check-answer` reads alongside the questions files.
