# Pre-Mortem: Lodestone 8 search index rebuild

**Proposal:** Rebuild the product search index on Lodestone 8 (Search team; cutover 9 March, decommission 23 March)
**Date:** 2026-11-19
**Upstream what-if analysis:** none

> ℹ️ **No upstream what-if analysis provided.** These failure narratives come straight from the proposal. They would be sharper with `what-if-analysis` run first and its output supplied, because this skill works best when it starts from assumptions and coupling points that have already been mapped.

> ℹ️ **Prior Art Check skipped.** No repository is available, so `docs/decisions/` and `docs/working/` were not searched. No narrative carries a `[PRIOR CONSIDERATION]` tag.

**Framing note before the narratives.** The proposal says Marguerite's leave "does not affect the cutover week." That is true, but it misses the real exposure. The window in which rollback still works runs to 20 March, and decommission happens on 23 March. Both dates fall inside her leave. Under the plan as written, the only person who understands `catalog-indexer` is gone for the second half of the period in which the migration can still be safely undone. Several of the narratives below follow from that.

---

## 1. The Runbook Nobody Else Had Run

- **Root cause:** Only one person understood the ported `catalog-indexer`, and its runbook was written and reviewed by that same person. Plan §Staffing kept both other engineers on the autocomplete redesign through 13 March. That left nobody to read the runbook cold, and nobody had ever operated the new pipeline before Marguerite's leave began on 16 March.
- **Chain of consequences:**
  1. The cutover week went smoothly. Marguerite handled two small mapping fixes herself on Tuesday and Wednesday and hot-patched them without writing them up. In the runbook they appeared only as "see commit."
  2. On Wednesday 18 March, the price feed from one upstream system started sending a new `promo_end_at` field in a format the new mapping rejected. The indexer logged rejections and skipped those documents rather than failing.
  3. Both remaining engineers were on-call, and neither had touched the indexer. They found the runbook, but it described the happy path and the error-handling section said "check the dead-letter topic," with no explanation of how to replay from it.
  4. They decided to roll back to Lodestone 6, as §Rollback allows. It took two days of debate to reach that decision, because nobody was confident the old indexer on Lodestone 6 had been processing the same feed correctly.
  5. On Friday 20 March, the old indexer was shut off as scheduled. Nobody had connected "old cluster stops receiving updates on the 20th" to "rollback now means serving stale data."
  6. On Monday 23 March, decommission was on the calendar. The team postponed it in a panic and emailed Marguerite on leave.
- **Observable outcome:** About 31,000 products on promotion were missing from search for roughly 60 hours between 18 and 20 March. Category-page revenue for promoted lines fell about 22% against forecast. A Slack thread asking whether anyone could message Marguerite collected 40+ replies. Lodestone 6 kept running past EOL in April with no feed, so it was useless as a fallback.
- **Plausibility:** Likely
- **Severity:** High
- **Mitigation:** Change plan §Staffing so that one of the two autumn-joining engineers pairs on the indexer port from now until 6 March and is named as primary on-call for 16–27 March. That engineer, not Marguerite, reviews the runbook, and must run a full dead-letter replay and the alias rollback in a staging rehearsal before 6 March. Then move the §Plan step 5 "fed until" date and the step 6 decommission date to at least two weeks after a cutover week staffed by someone other than Marguerite. For example, keep Lodestone 6 fed until 3 April and decommission on 6 April, which still beats the April EOL. If the EOL date doesn't allow that, bring the cutover forward instead of shortening the safety window.

---

## 2. Synonyms Lost in Translation

- **Root cause:** Some of the ~60 synonym and ranking rules were mistranslated by hand into the Lodestone 8 format (§Plan step 2). The shadow comparison in §Plan step 4 couldn't see the errors, for two reasons: its 80% top-10 overlap threshold allowed two different results per query, and it sampled 5,000 queries from Sunday traffic, which is dominated by head terms.
- **Chain of consequences:**
  1. In Lodestone 6, the rule mapping `waterproof ↔ hardshell ↔ rain jacket` was a bidirectional equivalence. It was translated as a one-way expansion (`waterproof → hardshell`), which looks almost identical in the new syntax.
  2. A boost rule for in-season items was translated with its decay function on the wrong date field, so it applied a flat boost instead.
  3. The 5,000-query sample was mostly head queries ("tent," "boots," "jacket"). Neither rule mattered much for those. Average overlap was 91%, only 140 queries fell below 80%, and the overnight review cleared most of them as "plausible reordering."
  4. After cutover, "rain jacket" searches stopped returning hardshells. Zero-result rate stayed flat because the queries still returned *something*, just worse results.
  5. Click-through on outerwear queries drifted down about 9% over two weeks. That was in the normal range of week-to-week noise, so nobody tied it to the migration until a merchandiser complained in April.
- **Observable outcome:** No alerts fired. Outerwear search conversion fell about 7% in the cutover's first month. A merchandising escalation showed that 11 of the 60 rules behaved differently. By then Lodestone 6 had been decommissioned, so there was no reference cluster to diff against.
- **Plausibility:** Likely
- **Severity:** Medium
- **Mitigation:** Add a per-rule test to §Plan step 2. For each of the ~60 rules, write at least one targeted query whose result set depends on that rule, such as "rain jacket must return SKU X in the top 5." Run the whole set against both clusters before the 7 March re-index, and block the re-index if any query diverges. In §Plan step 4, split the 5,000-query sample into stratified head, torso, and tail buckets. Report overlap per bucket and per product category rather than as one pooled average.

---

## 3. In Stock, Says Search

- **Root cause:** The Lodestone 8 mapping-syntax port in §Plan step 2 changed how the `stock_status` field was typed. Lodestone 6 had silently coerced the upstream string `"0"` to a numeric zero. The new mapping indexed it as a keyword, so the in-stock filter's `> 0` range query treated `"0"` as truthy and matched it. The §Monitoring indexing-lag alert measured freshness, not correctness, and stayed green throughout.
- **Chain of consequences:**
  1. The full re-index on 7 March ran clean. There were no rejected documents, because a keyword field accepts any string.
  2. Shadow comparison in §Plan step 4 compared top-10 *rankings* and never checked field values. Out-of-stock items ranked about where in-stock items would, so overlap looked normal.
  3. After cutover, the default "hide out-of-stock" filter on search pages stopped hiding about 180,000 out-of-stock SKUs.
  4. Customers clicked through to product pages showing "Out of stock." Those pages read stock from the inventory service directly, not from search.
  5. The indexing-lag panel showed under 2 minutes the whole time.
- **Observable outcome:** Product-page bounce rate from search rose from 34% to 51% within 48 hours. Customer support logged about 600 "search shows things you don't have" contacts in the first week. Merchandising caught it on day 3 from the bounce chart. No alert fired.
- **Plausibility:** Plausible
- **Severity:** High
- **Mitigation:** Add a field-parity step to §Plan step 4 that runs before cutover. For a random sample of 10,000 product IDs, fetch the document from both clusters and diff `stock_status`, `price`, `sale_price`, and every field used in a filter or sort. Block cutover on any systematic mismatch. Also add a correctness signal to §Monitoring next to the lag panel: an hourly job that samples 500 documents from Lodestone 8, compares `stock_status` and `price` against the upstream source of truth, and alerts when mismatch exceeds 0.5%.

---

## 4. The Weekend With No Slack

- **Root cause:** The schedule had no float. The port had to finish by Friday 6 March (§Plan step 2), the 9-hour re-index ran Saturday, shadow traffic ran Sunday, and cutover was Monday. Any slip went straight into either shadow review or cutover. Meanwhile the full re-index built from a point-in-time read, and nothing in the plan described how changes made during the 9-hour build would be caught up.
- **Chain of consequences:**
  1. The rule translation ran long. Marguerite merged the last changes around 22:00 on Friday 6 March.
  2. The Saturday re-index failed at hour 6 because a node ran out of heap on a large nested-variants document. Marguerite raised the heap and restarted. The second build finished around 07:00 on Sunday.
  3. Shadow mirroring began Sunday mid-morning, not at midnight, so the 5,000-query sample came from roughly 10 hours of Sunday traffic. Results with under 80% overlap were reviewed by one tired person late Sunday night.
  4. The rebuilt index reflected upstream state as of Saturday evening. On Monday morning, the incremental feed started from "now" rather than from the build snapshot, so price changes from Sunday's flash-sale prep were never indexed.
  5. Cutover went ahead Monday morning anyway. The autocomplete redesign was due Friday, and nobody wanted to move both dates.
- **Observable outcome:** About 4,200 products showed pre-sale prices in search results and the correct sale price on product pages for the whole of 9 March. That led to a customer-trust complaint on social media and a manual re-index of the affected IDs on Monday evening. Monday's on-call log shows Marguerite had slept about 9 hours total since Friday.
- **Plausibility:** Plausible
- **Severity:** Medium
- **Mitigation:** Change the §Plan dates to add at least one buffer day. Port complete by Wednesday 4 March, re-index Thursday 5 March, shadow traffic Friday 6 March through Sunday 8 March, cutover Monday 9 March. If those dates can't be met, the go/no-go rule in §Plan step 5 is to slip cutover by one week, not to compress shadow. Add a note to §Plan step 3 that the full build records its upstream read high-water mark, and that the incremental indexer starts from that mark rather than from wall-clock time at cutover.

---

## 5. Two Indexers, One Feed

- **Root cause:** After cutover, both the old indexer (feeding Lodestone 6) and the ported `catalog-indexer` (feeding Lodestone 8) pulled from the same three upstream systems (§Plan step 5). The proposal doesn't say how they pull. In this story, one upstream source is a message queue consumed under a shared consumer-group name that was carried over in the ported config, and another is a REST API with a per-client rate limit both indexers share.
- **Chain of consequences:**
  1. When the ported indexer started on Saturday 7 March, it joined the existing consumer group for the stock-change queue. The broker rebalanced partitions, so each indexer received about half of the stock updates.
  2. Lodestone 8 looked healthy: lag was low because it kept up with *its* half. Lodestone 6 also looked healthy for the same reason.
  3. During the full build, the ported indexer called the price service at about 600 req/s, which exhausted the shared 1,000 req/s client quota. The old indexer's price requests were throttled for the full 9 hours.
  4. Each cluster ended up roughly 50% stale on stock and partly stale on price, with errors in different places on each. The shadow comparison couldn't see it, because both sides were wrong.
  5. When Narrative 3's symptoms appeared and the team considered rollback, they found Lodestone 6 was just as stale, so rollback offered nothing.
- **Observable outcome:** Stock accuracy in search, measured afterward against the inventory service, was about 52% on both clusters during 7–20 March. The broker metrics showed two members in the `catalog-indexer-stock` consumer group starting 7 March. The price service's throttle log showed 2.1M `429` responses on 7 March. The rollback path in §Rollback was unusable without anyone having noticed.
- **Plausibility:** Plausible. This depends on how the upstream pulls work, which the proposal doesn't describe. Check it rather than assume it.
- **Severity:** High
- **Mitigation:** Before the 7 March re-index, add a step to §Plan step 2. Confirm that the ported `catalog-indexer` uses its own consumer-group name for every queue-based upstream, for example `catalog-indexer-l8-*`, and its own API credentials or quota allocation for every rate-limited upstream. Run the full build in §Plan step 3 with a client-side rate cap set below the shared quota. Add an upstream-split check to the go/no-go for §Plan step 5: per-upstream message counts received by each indexer over the same hour must match within 1%.

---

## Recommendations

### Must address before proceeding

- **Narrative 1 (The Runbook Nobody Else Had Run): Likely / High.** This is the central risk. Recommend not confirming the 23 March decommission date as written. Instead:
  - Assign a second engineer to the indexer port now, with authority to review the runbook and named on-call for the weeks after 16 March.
  - Extend the Lodestone 6 feed and decommission dates so the rollback window covers at least two weeks of operation without Marguerite, still inside the April EOL.
  - Rehearse the alias rollback and a dead-letter replay in staging, led by the second engineer, before 6 March.
- **Narrative 3 (In Stock, Says Search): Plausible / High.** Ranking overlap can't detect field-level correctness errors, and the only new alert measures lag. Add the field-parity diff to §Plan step 4 and the correctness-sampling alert to §Monitoring.
- **Narrative 5 (Two Indexers, One Feed): Plausible / High.** This one is cheap to rule out. Confirming consumer-group names and API quota allocation takes an hour, and if it is wrong, it silently breaks *both* the new cluster and the rollback path.

### Worth mitigating

- **Narrative 2 (Synonyms Lost in Translation): Likely / Medium.** The per-rule test queries are a modest amount of work and would turn an invisible conversion drift into a visible pre-cutover failure. Stratify the shadow sample. Also add a revisit trigger: alert if search click-through for any top-20 product category drops more than 5% week-over-week during the four weeks after 9 March.
- **Narrative 4 (The Weekend With No Slack): Plausible / Medium.** Add a buffer day and an explicit "slip a week, don't compress shadow" rule. Make the high-water-mark handoff between full build and incremental feed explicit in §Plan step 3.

### Acknowledged risks

- **Monday peak load on the new six-node cluster** is mostly covered by 100% shadow mirroring, though only on Sunday traffic. This is acceptable as long as the team watches p99 latency on the existing dashboard on Monday 9 March and treats alias rollback as the response. That is reasonable while Lodestone 6 is still fed.
- **The autocomplete redesign deadline (13 March) competing for the same week.** This is acceptable *only if* the Narrative 1 staffing change goes ahead. If neither engineer can be moved off autocomplete, that is an argument for moving one of the two deadlines, not for accepting the risk.

**On the decision requested:** the evidence here supports confirming the 9 March cutover, conditional on the Narrative 1, 3, and 5 mitigations. It does not support confirming the 23 March decommission as written.
