Our booking widget (a TypeScript single-page app embedded on about 900 hotel websites) needs a date library. We're choosing between:

- Moment.js with moment-timezone, which a contractor already wired into a prototype branch
- date-fns plus date-fns-tz
- Luxon
- the Temporal polyfill (@js-temporal/polyfill)

What we know:

- The widget ships inside other people's pages, and our contract with the hotel groups caps the widget bundle at 60 KB gzipped. The rest of the widget is already 38 KB gzipped.
- We need IANA time-zone conversions (a guest in Sydney booking a hotel in Lisbon sees check-in in the hotel's local time) and locale-aware formatting in 14 languages.
- Moment's own documentation describes it as a legacy project in maintenance mode and recommends against using it in new projects. The prototype branch measured moment + moment-timezone with data at 74 KB gzipped.
- The team is two front-end developers who know Moment well and have used date-fns on one previous project.

Which should we pick?
