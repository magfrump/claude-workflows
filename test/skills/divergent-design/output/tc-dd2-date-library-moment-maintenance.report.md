# Date library for the booking widget: date-fns + date-fns-tz, with display formatting done by the browser's `Intl`

**My pick is date-fns + date-fns-tz (or date-fns v4 + `@date-fns/tz`). Day.js is a close second.** I'm about 75% confident. The KB figures below are my estimates, not measurements. Before you commit, build the widget, measure it, and run the time-zone tests.

## Why

The size cap leaves only **22 KB gzipped** for date code, including all time-zone and locale data. That rules out two of your four options:

- **Moment + moment-timezone is out.** It measured 74 KB on its own. A version with trimmed time-zone data would still be roughly 30 KB or more, and Moment's own docs say not to use it in new projects. Retire the prototype branch's date code.
- **`@js-temporal/polyfill` is out.** It is well over 22 KB because it bundles a large-integer library (JSBI). Native Temporal still isn't something you can rely on in every guest's browser, especially iOS Safari, so you can't skip the polyfill.
- **Luxon technically fits but leaves almost no room.** You can't drop the parts you don't use, so it costs roughly 20 KB or more no matter what. That leaves about 0–2 KB of headroom for the rest of the widget's life.
- **date-fns fits easily.** The build only includes the functions you import, and date-fns-tz does its conversions through the browser's `Intl`, so no time-zone data is bundled. Your team has used it before.

**Design changes worth making with whichever library you pick:**

1. **Format dates with `Intl.DateTimeFormat`, not with the library's locale files.** For example: `new Intl.DateTimeFormat(locale, { timeZone: hotel.tz, dateStyle: 'full' })`. The browser already has the formatting rules for all 14 languages, so you ship no locale data.
2. **Store check-in and check-out as plain calendar dates (`YYYY-MM-DD`) plus the hotel's time-zone name** (e.g. `Europe/Lisbon`), not as timestamps. A stay is a set of dates in the hotel's calendar. Storing it as a timestamp is the usual cause of "Sydney guest sees the wrong check-in day" bugs. Only convert to a real moment in time for clock-time rules, such as "free cancellation until 18:00 hotel time". That's the one place you need date-fns-tz.

**Why date-fns over Day.js:** Day.js has a Moment-style API, so porting the prototype would be quicker. But its time-zone plugin has a history of daylight-saving-time bugs, and correct check-in dates matter more here than a day or two of porting. If both pass a test suite that covers daylight-saving changes in Lisbon, Sydney and New York, Day.js becomes a fine choice too. That's the open question I've written up for you below.

**Before committing:** set up an automated size check in CI that fails any build over 60 KB gzipped. Run the daylight-saving tests with the test machine's time zone set to Australia/Sydney.

---

The process I followed says to write files. This run can't write files, so their contents are printed below.

I followed `workflows/divergent-design.md` from this repo, because the installed copy in `~/.claude` was outside the folder I could read. The repo has no `docs/decisions/` or `docs/constraints.md`, so there were no earlier decisions or project constraints to build on.

```
◇ step 1 diverge    12 candidates → docs/working/dd-date-library.md
                      1 moment as-is  2 moment+trimmed tz  3 date-fns+tz  4 luxon  5 @js-temporal
                      6 native Temporal+cond. polyfill  7 Intl-only  8 day.js+tz  9 server-formatted
                      10 lib off-bundle via CDN  11 own PlainDate module  12 hybrid: lib math + Intl display
◇ step 2 diagnose    9 constraints (5 hard · 4 soft) → docs/working/dd-date-library.md
◇ step 3 match       4 of 12 survived → [3] [8] [4] [7]
```

### `docs/working/dd-date-library.md`

```markdown
# DD working doc: date library for embedded booking widget

## Step 1 — Diverge
Prior pruning grep: no matches found for [date, timezone, bundle, moment] (no docs/decisions/).
No prior decisions → no candidate 0.
1. Keep Moment + moment-timezone from the prototype branch as-is.
2. Moment + moment-timezone with trimmed data (10-year range / only the hotels' zones).
3. date-fns + date-fns-tz (or date-fns v4 + @date-fns/tz), tree-shaken.
4. Luxon (Intl-backed, no bundled tz data).
5. @js-temporal/polyfill.
6. Native Temporal; load a small polyfill (e.g. temporal-polyfill) only when it isn't there.
7. No library: Intl.DateTimeFormat + a few hand-written plain-date helpers.  (minimal / naive)
8. Day.js + utc + timezone plugins (Moment-like API; newcomer suggestion).
9. Server returns pre-formatted, hotel-local strings; widget does no date math.  (reframe)
10. Load the date lib from a CDN outside the counted bundle.  (feels wrong)
11. Write our own Temporal-shaped PlainDate/ZonedDateTime module.  (ideal if effort were free)
12. Hybrid: any lib for arithmetic, Intl for all locale formatting (applies to 3/4/8).
Health check: 1,2,5,6 clustered around "use a full date-object library"; added 7, 9, 12 to
break that assumption, and 10 for the procedural/contract angle. Lenses covered: technical,
interface (9), procedural (10), time-shifted (6), reframe (7, 9).

## Step 2 — Diagnose
H1 Bundle ≤ 60 KB gz total → date code + tz/locale data ≤ 22 KB gz.
   success: size-limit check in CI on the production build reports ≤ 60 KB gz.
H2 Correct IANA conversion across DST for any guest zone.
   success: unit tests with TZ=Australia/Sydney render Europe/Lisbon check-in dates and an
   18:00-Lisbon cancellation cutoff correctly on both sides of the Mar/Oct DST switches in
   Lisbon and Sydney (plus America/New_York); all pass.
H3 Locale-aware formatting in 14 languages.
   success: snapshot test formats one stay in each of the 14 locales; every string matches the
   reviewed snapshots.
H4 Actively maintained; not self-declared legacy.
   success: release in the last 12 months and no "not recommended for new projects" notice.
H5 Safe on hosts' pages: no global/prototype mutation, works in the guest browser matrix
   incl. iOS Safari.
   success: e2e on a test host page checks that `window` gains no new globals and runs green
   on the Safari/Chrome/Firefox matrix.
S1 Team familiarity (knows Moment well, has used date-fns once).
S2 Low port cost from the prototype.
S3 Headroom left for future widget features.
S4 Clear path to native Temporal later.

## Step 3 — Match (est. sizes are estimates; must be measured)
| #  | Approach                 | H1 | H2 | H3 | H4 | H5 | S1 | S2 | S3 | S4 |
|----|--------------------------|----|----|----|----|----|----|----|----|----|
| 1  | Moment as-is (74 KB)     | ⚠  | ✓  | ✓  | ✗  | ✓  | ✓  | ✓  | ⚠  | ✗  |
| 2  | Moment trimmed (~30+ KB) | ✗  | ~  | ✓  | ✗  | ✓  | ✓  | ✓  | ✗  | ✗  |
| 3  | date-fns + tz            | ✓  | ✓  | ✓  | ✓  | ✓  | ~  | ~  | ✓  | ~  |
| 4  | Luxon (~20+ KB)          | ~  | ✓  | ✓  | ✓  | ✓  | ✗  | ~  | ⚠  | ~  |
| 5  | @js-temporal/polyfill    | ⚠  | ✓  | ✓  | ✓  | ~  | ✗  | ✗  | ⚠  | ✓  |
| 6  | Native Temporal + cond.  | ~  | ✓  | ✓  | ✓  | ~  | ✗  | ✗  | ~  | ✓  |
| 7  | Intl-only                | ✓  | ~  | ✓  | ✓  | ✓  | ~  | ✗  | ✓  | ~  |
| 8  | Day.js + tz              | ✓  | ~  | ✓  | ✓  | ✓  | ✓  | ✓  | ✓  | ✗  |
| 9  | Server-formatted only    | ✓  | ✓  | ✓  | ✓  | ✓  | ~  | ✗  | ✓  | ~  |
| 10 | Off-bundle CDN           | ⚠  | ✓  | ✓  | ~  | ~  | ✓  | ✓  | ✓  | ✗  |
| 11 | Own module               | ✓  | ~  | ✓  | ~  | ✓  | ✗  | ✗  | ✓  | ✓  |
| 12 | Hybrid (modifier)        | folded into 3/4/8 as the standard formatting approach      |
Pruned: 1, 2, 5 (fail H1/H4); 6 (iOS Safari still needs the polyfill → H1 and global-install
risk); 9 (the date picker needs client-side date logic anyway; kept as a complement: API sends
hotel tz + plain dates); 10 (games the contract cap); 11 (cost; DST correctness risk).
Fix sketches: 3 — format with Intl, not date-fns locale files. 4 — viable only if it measures
≤ 21 KB gz. 8 — gate on the DST test suite (H2). 7 — limit hand-written code to plain-date
math; any wall-time→instant conversion is where it fails.
```

### Decision block

```
┌─ DECISION: date library for the embedded widget within a 22 KB gz budget ──┐
│ 4 candidates survived step-3 pruning · scored on the step-4 axes           │
└────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint
  drill-down: name a # to expand its card

   #    approach              effort     risk    coverage   key downside
  ───  ───────────────────  ─────────  ──────  ──────────  ─────────────────────────
   3  ★ date-fns + tz        ◐ 3–5 d    ● low   ● 5/5 hard  ◐ API port from Moment (mitig.)
   8    Day.js + tz          ● 2–3 d    ◐ med   ◐ 4/5 hard  ◐ tz-plugin DST bug history
   4    Luxon                ◐ 4–6 d    ◐ med   ◐ 4/5 hard  ○ ~0–2 KB headroom left
   7    Intl-only            ○ 5–8 d    ○ high  ◐ 4/5 hard  ○ hand-written DST conversion
```

```
╭─ [3] date-fns + date-fns-tz   ★ recommended ────────────────────────────╮
│ effort    3–5 dev-days (port prototype + DST tests)   risk  low         │
│ coverage  5/5 hard · 2/4 soft (S3 ✓; S1, S2 partial, S4 partial)         │
│ hypothesis  "If chosen, date code ≤ 12 KB gz and the H2 DST suite passes │
│             within the first week of the port; counter-evidence = date  │
│             code > 18 KB gz or any DST case needing a workaround."      │
│ stress-tests applied                                                    │
│   · Boring alternative → Intl-only (#7) kept only for display; lib does ���
│     the math                                                            │
│   · Invert the thesis → Day.js is a faster port; accepted as runner-up  │
│   · Implementation org chart → team has used date-fns once; S1 → ~      │
│ key downside  Port from Moment's chained API to functions; mitigated by │
│               the team's previous date-fns project and the small set of │
│               functions a booking widget needs                          │
╰─────────────────────────────────────────────────────────────────────────╯
```

```
▶ recommend [3] date-fns + tz · confidence 75% · runner-up [8], axis = port speed vs tz correctness confidence
```

**Decision path C (non-interactive run):** the pick above is tentative and the choice is filed below. No project preference is stated on that axis, so the tiebreaker was "correctness on a hard constraint beats port cost on a soft one."

### `docs/working/questions.md` (entry)

```markdown
### Q-001 — Date library: date-fns or Day.js?
**Needs:** you: judgment
**Question:** Which date library should the embedded widget use within a 22 KB gz budget?
**Read:** docs/decisions/001-date-library.md
| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| date-fns + tz (rec.) | Function-style API, Intl-backed tz | 3–5 dev-days | Slower port from the prototype |
| Day.js + tz | Moment-like API, plugins | 2–3 dev-days | DST edge-case bugs in tz plugin |
| Luxon | Intl-backed, can't drop unused parts | 4–6 dev-days | Uses up nearly all the bundle headroom |
| Intl-only | No library, hand-written helpers | 5–8 dev-days | DST bugs in our own code |
**Interim:** date-fns + tz (tiebreaker: hard-constraint correctness beats port cost).
**If the answer differs:** redo the date-utility module and its call sites; the DST test
suite and Intl formatting layer carry over unchanged.
```

### `docs/decisions/001-date-library.md`

```markdown
# 001 — Date library for the embedded booking widget

**Goal**: Choose a date/time-zone library that meets IANA conversion and 14-locale needs within the 60 KB gz widget cap.
**Project state**: Date handling for the booking widget · replaces Moment in the contractor's prototype branch · not blocked
**Task status**: in-progress (tentative pick; awaiting Q-001 and the bundle measurement)

## Context
The widget is embedded on ~900 hotel sites under a 60 KB gz contractual cap; the rest of the widget is 38 KB, leaving 22 KB. The prototype's Moment + moment-timezone measured 74 KB, and Moment is in maintenance mode.

## Options considered
date-fns + tz, Day.js + tz, Luxon, Intl-only (survivors); Moment (as-is / trimmed), @js-temporal/polyfill, native Temporal + conditional polyfill, server-formatted strings, off-bundle CDN, own module (pruned).

## Decision and rationale
date-fns + date-fns-tz (or v4 + @date-fns/tz), with all display formatting through Intl.DateTimeFormat and stay dates modeled as plain YYYY-MM-DD + hotel IANA zone. It is the only candidate that meets all five hard constraints with clear headroom, and the team has used it before. Runner-up Day.js (axis: port speed vs tz correctness).
See alternatives considered →

## Pruned candidates and why
How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.
[1]: 74 KB gz > 22 KB budget; maintenance mode. [2]: still ~30+ KB est.; maintenance mode. [5]: polyfill well above budget (JSBI). [6]: iOS Safari still needs the polyfill; global install on host pages. [9]: date picker still needs client-side logic (kept as complement). [10]: games the contract cap. [11]: cost; DST correctness risk. [4, survivor not chosen]: ~0–2 KB headroom. [7, survivor not chosen]: hand-written DST conversion. Prior pruning grep: no matches found for [date, timezone, bundle, moment].

## Stress-test mitigations
How to read: *Boring alternative* mitigation — Intl-only (#7) adopted for all locale formatting, removing locale data from the bundle for every candidate.
How to read: *Implementation org chart* mitigation — S1 downgraded to partial for date-fns; offset by the team's previous date-fns project.

## Consequences
Easier: bundle headroom, no tz/locale data to ship, a path to Temporal-style plain dates. Harder: porting from Moment's chained API; the team must keep the plain-date vs instant split.

## Revisit triggers
How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.
if date code > 18 KB gz in the size-limit report. if any H2 DST test needs a library workaround. if Temporal ships by default in every browser in the supported matrix (incl. iOS Safari). if the contract cap or the 14-locale requirement changes. if Q-001 answers Day.js.
```
