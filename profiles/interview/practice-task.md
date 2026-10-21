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

## Debrief (5 min, after each run)

- Did the first real result land by about minute 15? If not, where did the time go?
- Did any run go over budget, or block the conversation instead of running in the background?
- Is `RESULTS.md` good enough to discuss from without scrolling back?
- Were there permission prompts that interrupted the flow? Add those commands
  to `profiles/interview/settings.json` and re-run `install.sh`.
- Did the agent's step reports read naturally aloud?
