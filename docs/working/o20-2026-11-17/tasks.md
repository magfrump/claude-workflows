# Reader tasks: MAIS-O20 post (pilot, 2026-11-17)

**Stimulus:** `post.md`, which is the text between the cut lines of `docs/working/drafts/mais-o20-new-issue.md`
(sha256 `7618d4b7…`) plus the issue title, and the attachment `mais-o20-bundle.zip` (sha256 `a24831f6…`).
**Profile:** `docs/audiences/mais.md`. **Answer key:** `key.md`, which readers never see.

Every reader starts by giving a **first take**: what they learned from the title and the first three paragraphs,
in their own words, before reading anything else. Then the tasks. For each task the reader records: the answer;
the sentence or sentences relied on, quoted, with their section; and "not in the text" when the text does not say.
Throughout, they keep a **stuck log**: every place they stopped (an undefined term, a notation change, a claim
they could not place), and whether a later passage resolved it.

## Conjecturer (reads the title, the opening and the theorem statements; stops once each part is answered)

- **C1.** Answer each part of the problem as posed, with its status: (a) the conditions on f, g, with explicit
  k̂; (b) whether the certificates bλ ≤* g and f + bλ ≤* g suffice; (c) whether two copies of PB_k cooperate
  above an explicit threshold; (d) the comparison with k̂*.
- **C2.** The problem page asks: "Does the cheaper route give a smaller cooperation threshold?" Answer it in one
  sentence, from the post.
- **C3.** Which of the problem's hypotheses or certificates did the post weaken, strengthen or reject? What did
  it add?
- **C4.** Is the claim that the literal PB_k cooperates conditional? On what?
- **C5.** What follow-up problem does the post leave, and is it stated precisely enough to pose?

For each of C1–C4, also say whether you could answer it **from the opening alone** (title and first three
paragraphs).

## Maintainer (three passes: screen, verify, record)

- **M1 (screen, opening and claim labels only, about ten minutes).** Is it in good faith? Could a mathematician
  follow what is being claimed? Does it bear on the problem as stated on its page? What, if anything, would make
  you reply "needs revision" at this stage?
- **M2.** List every claim and its status label. Name any claim that has no label, or whose label is unclear.
- **M3.** List every assumption Theorem 2 rests on that is not checked, and where each is stated.
- **M4.** Which claims can be checked from the attachment alone, and how? Which cannot?
- **M5.** Does each claim meet the verbatim problem statement's quantifiers and constraints? Name any that do
  not, or that answer a variant.
- **M6 (record).** Write the progress page's three lists: proved, numerical, open. Note anything you had to
  ask or guess.

## Enthusiast (reads line by line)

- **E1.** Explain the result to a mathematician friend outside the field, in two or three sentences.
- **E2.** Do two copies of the literal PB_k actually cooperate when they play each other, for large k?
- **E3.** Why is the gap between the two budgets of order log k? Give the reason, not just the fact.
- **E4.** Pick one symbol in Theorem 1 and say what it means and why it is there.
- **E5.** What human question does this result bear on, and what does it say about it?
- **E6.** What is the first question a reader on the thread is likely to ask, and what is the answer?

## Builder (reads the open questions and the attachment first)

- **B1.** State one open question precisely enough to start work on it.
- **B2.** Pick two named results you could reuse. For each, give its exact hypotheses, from the Lean if the post
  is not enough, and say whether the post's statement matches the Lean.
- **B3.** From a fresh unzip, what do you run, and what output tells you it worked? Run it if you can, and report
  what happened, with timings.
- **B4.** Does the attachment contain everything the post says it does? List any mismatch.
