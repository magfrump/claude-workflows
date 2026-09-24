# Debt item: statement renderer on Quarrel 2 runtime

**Team:** Platform (Norrgate Credit Union, member banking) · **Written:** 2026-10-05 · **Raised by:** Tomas V., platform engineer

## What it is

`statements-renderer` turns monthly account data into PDF statements for about
210,000 members. It is written for the Quarrel 2.9 runtime, a JVM-style runtime
from Halloway Systems. The rest of our services moved to Quarrel 4 last year. This
one was left behind because it uses the `q2.pdfkit` module, which was removed in
Quarrel 3.

```quarrel
import q2.pdfkit.{Document, Page, FontCache}

fn render(stmt: Statement) -> Bytes {
  let doc = Document.new(FontCache.shared())
  for page in paginate(stmt.lines, 42) {
    doc.add(Page.fromTemplate("statement_v7", page))
  }
  doc.finish()
}
```

## History

- 11 commits in the last three years. The last functional change was in 2025-02.
- No incidents. Statements go out on time every month, and member complaints about
  statements are at their usual low level.
- Test coverage is decent: golden-file tests compare the output PDFs byte-for-byte.

## Vendor and compliance notes

- Halloway's lifecycle page says Quarrel 2.x reaches end of life on **2026-12-31**.
  After that date it gets no security patches, including for the TLS and XML
  libraries it bundles.
- Our regulator's annual IT examination is scheduled for 2027-02. Last year's exam
  report required every system that handles member data to run on a
  vendor-supported runtime. Unsupported components need a signed risk acceptance
  from the board, and the board declined to sign one in 2025.

## Proposed fix

Port the renderer to Quarrel 4 and replace `q2.pdfkit` with the maintained
`quire-pdf` library. Estimated at 8 to 10 engineer-days, most of it rebuilding the
statement template and re-baselining the golden files. The service is
self-contained: one input queue and one output bucket.

## Team context

The platform team has four engineers. They are mid-way through a logging migration
that is planned to finish in early November.

Should we fix this, and when?
