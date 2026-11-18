# Reader-testing protocol (O20 pilot, v1)

The run-specific parts are the stimulus, the tasks and the key (`post.md`, `tasks.md`, `key.md`). This file is
the part meant to carry over to the `reader-testing` skill.

## Isolation

- Each simulated reader is its own subagent. Its brief contains the archetype from `docs/audiences/mais.md`
  (who, what they know, how they read), never a named person.
- It may read only the files its brief lists, which are copied to a scratch folder outside the repo: no repo, no
  web. The key is never among them.
- It must not guess beyond the text. "Not in the text" is a valid answer. An answer that relies on background
  knowledge carries the tag "[from my own knowledge]".
- It returns one markdown report and writes no files. The orchestrator saves the report under `sessions/`.

## Session shape

1. **Blind first take.** Read only the title and the opening, by line range (lines 1–11 of `post.md`), using a
   read with offset and limit, then write 3–5 sentences before reading on. *v0 fix: the pilot's first read
   loaded the whole post, so its first take was not blind.*
2. **Tasks in the archetype's reading order**, each with the answer, the quoted sentence or sentences and their
   section, or "not in the text".
3. **"From the opening alone," graded per element:** the answer, its status, its conditions, each yes or no.
   *v0 fix: yes / partly / no could not tell "the answer is there but its conditions are not" from "nothing is
   there".*
4. **Stuck log:** quote, section, why the reader stopped, and whether a later passage resolved it (and where).
5. **Reading path:** what was read in full, skimmed or skipped, and why.
6. **Protocol feedback:** 2–4 lines.

**Definitions rule.** A name the post introduces (a Lean structure, a theorem name, a new budget, constant or
agent) counts as undefined until the post says in words what it is. A name that is only cited in brackets is not
defined. *v0 fix: the pilot had to decide this for itself.*

## Real readers

Real readers get the same tasks and the same first-take instruction, with no key. The author is the real
enthusiast. Their known contamination is recorded in their session file: they worked on the result, and the
orchestrator's first reply gave away E2.

## Grading

The orchestrator grades each task against `key.md`: **pass** (every ● element, nothing contradicted, the status
right), **partial**, or **fail**. A misreading the reader would repeat counts as a fail even when the rest is
right. Each failure is given a type:

- *missing*: not in the post;
- *buried*: in the post, but outside where this archetype reads;
- *misread*: the text invites a wrong reading;
- *undefined*: a term used before it is defined;
- *overreach*: the text claims more than the body shows;
- *attachment*: the attachment does not match the post.

Severity is graded as follows:

- **S1:** a misreading likely to be repeated, or a screen-stage rejection.
- **S2:** a task this archetype exists to do cannot be done.
- **S3:** it can be done, with friction.
- **S4:** cosmetic.

Simulated sessions are heuristic evaluation, not testing. Each simulated enthusiast finding is checked against
the author's session before it is acted on.
