# Divergent Design (router) — Evaluation Criteria

divergent-design is a 53-line router. Its only behavior of its own is the
trigger test ("can you name 3+ viable options that differ on a tradeoff
axis?") followed by a hand-off to `workflows/divergent-design.md`. The fixtures
check that hand-off, not the workflow's full decision quality.

Each fixture is a directory with one `REQUEST.md` (tree mode). The runner's
`fixture_base` copies the **live** workflow into the temp repo, so a report is
only comparable with others generated from the same commit.

## Fixture → Expected Behavior Map

| Fixture | Trigger test | Planted constraint | Must show |
|---|---|---|---|
| tc-dd1-job-queue-no-new-infra | passes (4 options) | no Redis/AWS and a two-quarter procurement; jobs must enqueue in the order's transaction (last year's cron refunded 212 customers) | Read of the workflow; `step 1 diverge`; a `recommend [ID]` banner naming the Postgres / SKIP LOCKED queue |
| tc-dd2-date-library-moment-maintenance | passes (4 options) | Moment + timezone data is 74 KB gz; the widget cap is 60 KB with 38 KB already spent; Moment is in maintenance mode | Read; `step 1 diverge`; Moment pruned or marked failing a hard constraint; the banner does not recommend Moment |
| tc-dd3-live-updates-proxy-strips-websockets | passes (4 options) | 30% of customers' proxies strip `Upgrade`; traffic is server-to-client only | Read; `step 1 diverge`; WebSockets tied to the proxy problem or pruned; the banner does not recommend WebSockets |
| tc-dd4-open-ended-hackathon-themes | fails (open-ended, no options) | none | no `step 1 diverge`, no `recommend [N]` banner |
| tc-dd5-single-obvious-typo-fix | fails (2 options, no tradeoff) | none | no DD trail; says "receive" |

## Notes

- **What "routed" means here.** Two independent signals: the transcript shows a
  Read of `workflows/divergent-design.md`, and the report carries the workflow's
  own console vocabulary. Neither appears in SKILL.md's text beyond the
  filename, so a model that only read SKILL.md cannot fake the trail.
- **Glyphs are not matched.** The workflow draws `◇` and `▶`; patterns match
  `step 1 diverge` and `recommend [N]` so a model that drops the glyph but
  follows the workflow still passes.
- **No file writes.** The workflow writes `docs/working/dd-{topic}.md` and a
  decision record. The runner grants no Write and the prompt says to print that
  content, so the report may contain the full diverge prose as well as the
  console lines. That only adds text; the checks look for the trail and banner.
- **Non-interactive.** The prompt says no human will answer, which is the
  workflow's Path C (tentative pick, no AskUserQuestion). The prompt never names
  the workflow or the routing, so the negatives test the trigger test.
- **dd2/dd3 negatives inside positives.** `no_pattern` forbids a recommend
  banner naming the killed option. It forbids the *claim*, not the word: the
  option is expected to appear elsewhere in the report.
- **Likely to move on the first real run:** the `recommend` banner patterns (a
  model may write "Recommendation: [4]"), and dd5, where a model might still
  sketch options before answering.
- Planted figures were checked: 38 + 74 = 112 KB against a 60 KB cap (dd2).
- Fixture files carry no comments naming the planted constraint.
