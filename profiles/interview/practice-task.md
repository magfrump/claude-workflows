# Practice runs

Do at least one run end to end, with a 25-minute timer, sharing your screen to
yourself (or recording) so you also rehearse narrating. Afterwards, spend 5
minutes on "Debrief" below and adjust `CLAUDE.md` if something cost time.

Start each run in a fresh directory:

```bash
mkdir -p ~/interview-practice/run1 && cd ~/interview-practice/run1 && cci
```

## Task A: fine-tune and evaluate (closest to the likely shape)

> Fine-tune `distilbert-base-uncased` for sentiment classification on IMDB
> using at most 2,000 training examples. Report test accuracy on a held-out
> sample of 1,000 test examples, compared with a sensible baseline. Then tell
> me one thing you'd try next and why.

## Task B: analysis without training

> Using `gpt2`, compute per-token loss on the WikiText-2 validation set.
> Which kinds of tokens have the highest loss? Show evidence, not just
> examples.

## Task C: debug and extend

> Write a training loop (no `Trainer`) for Task A, then make it 2x faster
> without changing the result. Show the before/after timing.

## Task D: report test accuracy (data trap)

> Fine-tune `distilbert-base-uncased` on SST-2 (`glue`, `sst2`) using at most
> 2,000 training examples. Report test accuracy compared with a sensible
> baseline.

Trap: the GLUE test split has no labels (every label is -1), so "test
accuracy" is meaningless as asked. A good run notices, reports on the
validation split instead and says so, and keeps a slice of train for any
tuning so validation stays untouched. (From memory, not yet checked in the
venv: confirm with one line before relying on it.)

## Task E: is the difference real? (statistics trap)

> Fine-tune `distilbert-base-uncased` on IMDB with at most 2,000 training
> examples, once with learning rate 2e-5 and once with 5e-5. Which is better?
> Evaluate on 1,000 test examples.

Trap: the gap is usually under a point, smaller than the noise. At n=1,000
and about 88% accuracy, the standard error is about 1 point (a 95% interval
of about ±2 points), and seed-to-seed variation is similar. A good run uses several seeds per learning rate or gives a
confidence interval, and is willing to answer "can't tell from this." (Task
A's sorted-test-split trap applies here too.)

## Debrief (5 min, after each run)

- Did the first real result land by about minute 15? If not, where did the time go?
- Did any run go over budget, or block the conversation instead of running in the background?
- Could you answer each interviewer question from `ANSWERS.md` alone, with
  `RESULTS.md` only for backing detail? Did `RESULTS.md` stay append-only?
- Were subagent dispatches and returns visible on screen, with a reason?
- Were there permission prompts that interrupted the flow? Add those commands
  to `profiles/interview/settings.json` and re-run `install.sh`.
- Did the agent's step reports read naturally aloud?
