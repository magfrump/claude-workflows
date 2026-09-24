Compare three PDF-generation libraries for Brightline Invoicing.

**Items:** Kestrel, Parchment, Folio
**Criteria:** licence compatibility, rendering fidelity, throughput, maintenance health

Context:

- Brightline is a closed-source, multi-tenant SaaS. Customers never receive our code; they use it over the network. Legal's rule: we may not ship anything that would oblige us to publish our own source.
- We render about 400,000 invoices a month, mostly A4 with tables, logos and right-to-left text for our Israeli and Gulf customers.

What we know about each library:

- **Kestrel**: licensed AGPL-3.0; no commercial licence is offered. Best-in-class rendering: full right-to-left support, embedded fonts, pixel-exact tables. About 120 pages/second on our benchmark. Three maintainers, releases every month.
- **Parchment**: MIT. Good rendering, but right-to-left text needs a plugin that has not been updated for a year. About 90 pages/second. One maintainer who has said on the issue tracker that they are looking for a successor.
- **Folio**: Apache-2.0. Right-to-left support built in; tables occasionally mis-align when a cell wraps across a page break (known issue, fix scheduled). About 70 pages/second. Backed by a foundation with twelve active committers.

Use qualitative scoring.
