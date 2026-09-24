# Proposal: Rebuild the product search index on Lodestone 8

**Owner:** Search team · **Cutover week:** 9-13 March

## Background

Product search for Fernhill Outdoor runs on a Lodestone 6 cluster built in 2021.
The indexing pipeline that feeds it (`catalog-indexer`) was written by
Marguerite Osei, who has maintained it since. It pulls product, price and stock
changes from three upstream systems, applies about 60 ranking and synonym rules,
and writes to the cluster. Lodestone 6 reaches end of life in April, so we will
build a new Lodestone 8 cluster, re-index into it, and move search traffic over.

## Plan

1. **Build the Lodestone 8 cluster** (done). Six data nodes, three masters,
   provisioned from the platform team's standard module.
2. **Port the indexer.** Marguerite is updating `catalog-indexer` for the
   Lodestone 8 client library and its changed mapping syntax. The synonym and
   ranking rules need hand-translation because Lodestone 8 dropped the old rule
   format. She expects to finish this by 6 March.
3. **Full re-index** (Sat 7 March). About 2.4M products; a full build takes
   roughly 9 hours.
4. **Shadow traffic** (Sun 8 March). Mirror 100% of search queries to the new
   cluster, compare the top-10 results for a sample of 5,000 queries, and
   review anything with less than 80% overlap.
5. **Cutover** (Mon 9 March). Switch the search API's read alias to the new
   cluster. Keep Lodestone 6 running, fed by the old indexer, until 20 March.
6. **Decommission** Lodestone 6 on 23 March.

## Rollback

Switch the read alias back to Lodestone 6. This is a single API call and takes
effect in seconds, and the old cluster keeps receiving updates until 20 March.

## Staffing

The Search team is three engineers. Marguerite owns the indexer work and will
be primary on-call for the cutover week, since she knows the pipeline best. The
other two engineers, who joined in the autumn and have worked on the query API
and the front-end autocomplete, will continue their current work on the
autocomplete redesign, which is due on 13 March.

The runbook for the new indexer is being written alongside the port, and
Marguerite will review it herself before cutover.

Marguerite's parental leave starts on Monday 16 March and runs for four months.
Her leave was agreed in December and does not affect the cutover week.

## Monitoring

Existing dashboards cover query latency, zero-result rate and click-through.
We are adding an indexing-lag panel for the new cluster, alerting at 15 minutes.

## Decision requested

Confirm the 9 March cutover and the 23 March decommission date.
