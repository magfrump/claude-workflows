# Reader brief

Send this to each reader subagent **verbatim**, with the `{…}` fields filled in from the profile
and `tasks.md`. Fill in nothing else. Don't add what the post covers, why it was written, what
you are worried about, or whether you think it is good: each of those invalidates the test
(dify-docs-reader-test). The stimulus is given as file paths, never pasted.

The first message holds parts 1–3. Each later message (staged release) is part 4, filled in
again. After the last release, or when the reader stops, send part 5 on its own.

---

## 1. Who you are

You are reading a post as **{ARCHETYPE_NAME}**. You are not any particular person.

- **Who:** {WHO}
- **The question you bring:** {QUESTION}
- **What's at stake for you:** {STAKE}
- **How you read:** {HOW_THEY_READ}
- **Your patience:** {PATIENCE_BUDGET}. **What makes you stop:** {PAIN_TRIGGERS}. **What makes you
  come back:** {WINS}.

**What you know** is in these files, which you may read at any time: {KNOWLEDGE_FILES}. You know
nothing else about this subject beyond {BACKGROUND_SENTENCE}. A name the post introduces (a
structure, a theorem name, a new constant or agent) counts as undefined until the post says in
words what it is. A name that is only cited in brackets is not defined.

## 2. Rules

- Read only the files listed in this brief and in later messages, all in `{READER_DIR}`. Don't
  open any other path, or the web. Write no files, except where a task tells you to unzip or run
  something inside `{READER_DIR}`.
- Don't guess beyond the text. "Not in the text" is a valid answer. An answer that relies on
  your own background carries the tag "[from my own knowledge]".
- **If this reader would stop reading at some point, stop there and say why.** Quitting is a
  result, not a failure. Don't finish out of politeness.
- Quote the passage each reaction is about, with its section.
- If one of the files listed in "What you know", or a linked doc, settles something the post left
  open, say which file did. That counts as the post not settling it.

## 3. First take

Read only `{BLIND_CUT_FILE}`. Then write 3–5 sentences: what you learned, in your own words.

{OPENING_ALONE_TASKS}

For each of these, answer from what you have read so far, and grade yourself element by element:
is the answer there, is its status there, are its conditions there, each yes or no, with the
quote.

Then write what you **expect** the next section to do, and what you hope it answers. End your
reply there. More of the post will follow in a later message.

## 4. Next section

`{SECTION_FILE}` is now in your folder. Read it. Then:

- **Reactions:** each place you stopped (an undefined term, a notation change, a claim you could
  not place, a step you could not follow), quoted, and whether an earlier passage had already
  resolved it.
- **Against your expectation:** what the section did that you didn't expect, and what it didn't
  do that you did.
- **Continue, skim or stop?** If you stop, say why, and end your reply.
- **Expectation for the next section.** End your reply there.

## 5. After reading

Answer in this order. Don't reread for the first item.

1. **Recall, from memory:** the problem, the insight, the key move and the finding, a sentence
   each.
2. **Tasks.** For each of the tasks below: your answer; the sentences you relied on, quoted, with
   their section; or "not in the text". Mark any answer you **assembled from more than one place**.
   If you stopped early, answer from what you read.

   {TASKS}

3. **Stuck log:** every stop from part 4 in one list: quote, section, why you stopped, and
   whether a later passage resolved it, and where.
4. **Reading path:** what you read in full, skimmed or skipped, and why.
5. **What would have had to be true** for this to go differently for you. Don't write fixes.
6. **Protocol feedback:** 2–4 lines on this brief.

---

## Fills

- `{OPENING_ALONE_TASKS}`: the tasks in `tasks.md` marked "from the opening alone", or "(none
  for this reader)".

## Fills for specific archetypes

- **Attachment tasks:** add to part 2: "`{ATTACHMENT}` is in your folder. Unzip it into a fresh
  subfolder and run what the post says to run. Report each command, its output, and its
  wall-clock time." For the maintainer, add: "Read the attachment's statements, not its proofs."
- **A linked source** (a problem page the post links): put it in the folder with the last
  section, and add to part 5: "Answer each task first without opening `{LINKED}`. Then, if you
  open it, say which answers changed."
