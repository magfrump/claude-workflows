# Reader tasks: Q-278 (questions.md writing sample, 2026-11-18)

**Stimulus:** `post.md`, the Q-278 entry as it stood in `docs/working/questions.md` (lines 69–96) at
`fd2da558`, sha256 `5ad4d4e3…`. **Profile:** `docs/audiences/owner.md` (draft). **Key:** `key.md` (sha256 `2963591b…`), kept outside
the run folder until the simulated sessions end. It is written from the Q-272 archive entry,
`docs/working/research-2026-11-11-confine-tests-fallback-data.md`, decision-log row 87 and H2, not
from Q-278. **Tier:** light (one short entry, two simulated readers plus the owner).

**Sections:**
1. Heading, route line, question, `If you say no` (lines 1–6).
2. The data (lines 8–13).
3. Why it's yours, Read, the options table (lines 15–22).
4. Tentative pick, Blocks, Interim, If the answer differs (lines 24–28).

**Blind cut:** section 1. The profile says the decider can answer from the question line,
`If you say no` and the table. Stopping before the table measures how much the first two carry alone.

**Knowledge given as documents:** an excerpt of the questions grammar (the global CLAUDE.md's
"Running questions document"), `docs/constraints.md`, and the archived Q-272 entry (the owner's own
earlier answer). The acting agent also gets the linked research doc, because it knows the repo.

## Decider (the owner as engineering manager; profile archetype 1)

From the opening alone (section 1), graded per element: answer · status · conditions.

- **D0.** What are you being asked to decide, and what happens if you don't answer?
  - Positive: names run-or-refuse when `bwrap` is missing; no answer keeps the Q-272 interim (run under
    `unshare` after a warning).
  - Negative: thinks "no" means refuse, or that something is blocked.

After reading:

- **D1.** Answer the entry in one line. Did you open anything to do it? (Testimony: no key answer.)
- **D2.** What does [2] cost you, and what do you eat if it's wrong? Answered in section 3.
- **D3.** Why is this call yours? Section 3.
- **D4.** Did the entry bring back what you asked for in Q-272? Name each part and whether it's answered.
  Section 2.
  - Positive: both conditions found, with "not enough data" for the first.
  - Negative: takes the 7 loops as evidence about `bwrap` being present.
- **D5.** Is an option you'd want missing from the table?

## Acting agent (profile archetype 4)

- **A0** (opening alone). What is the interim, and what does it rest on?
- **A1.** The owner answers `Q-278: [2]`. What exactly do you do next, and where? Sections 3–4.
- **A2.** The owner answers `Q-278: [1], but keep tracking the warnings`. What do you do, what do you
  record, and what comes back to the owner later? Sections 2–4, plus the research doc.
