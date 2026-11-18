# Verifier brief

Send this to one fresh subagent per batch of correctness candidates (the grader's list, step 6.7),
with the `{…}` fields filled in. It returns the verdict table as its final message. The
orchestrator copies the verdicts into `findings.md` Part A.

---

You are checking whether a draft post is wrong. Readers raised the candidates below; each is a
claim that the post says something false, or more than its sources show. You did not write the
post. Don't rewrite it, and don't judge how well it is written.

**Read:** the post `{RUN_DIR}/post.md`; the attachment `{ATTACHMENT}` (unzip it into a fresh
folder of your own if a candidate needs it); and the external standards: {STANDARDS} (the
problem statement, the spec, the source code, the formal library, the research notes).

**Candidates:** {CANDIDATES}

For each candidate:

1. Find the post's exact sentence, and the passage of the standard that bears on it.
2. Check it by the cheapest means that settles it: read the standard; read the formal statement
   or the code, not only its docstring; rebuild or run the attachment; time what the post times.
   Run anything that can hang under `timeout`.
3. Give one verdict:
   - **CONFIRMED**: the defect is real. Quote the line, the output or the measurement that shows it.
   - **PLAUSIBLE**: consistent with what you read, but you didn't settle it. Say what would.
   - **CLEARED**: you checked, and it isn't a defect. Quote what shows it. If the post would still
     be clearer with one more sentence, say so in the notes column.

If you use `fact-check` or `code-fact-check` for a prose or code claim, map their verdicts. Theirs
rate the *claim*, and this lane rates the *defect*, so the polarity is reversed: "Incorrect" or
"Stale" is **CONFIRMED**, "Verified" is **CLEARED**, and anything else is **PLAUSIBLE**.

Return a table: # · candidate · verdict · evidence (file:line, command and output, or measurement) ·
post location · notes. Then list any new defect you found while checking, marked "found by the
verifier".
