Compare three hosted CI providers for our monorepo.

**Items:** Quarry CI, Ferrous Pipelines, Tidewater Build
**Criteria:** monthly cost, median pipeline time, arm64 runner support

Measured over the same two-week trial on our real pipelines (about 1,800 runs):

- **Quarry CI**: $1,150/month at our volume. Median pipeline 7 min 40 s. Native arm64 runners, same price as x86.
- **Ferrous Pipelines**: $1,900/month. Median pipeline 11 min 5 s. arm64 only through a self-hosted runner we would maintain.
- **Tidewater Build**: $2,400/month. Median pipeline 9 min 20 s. arm64 in beta, at 2x the x86 price, with a waitlist.

Use qualitative scoring.
