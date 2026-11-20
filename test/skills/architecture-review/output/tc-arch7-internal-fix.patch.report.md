# Architecture Review: Skipped

**Scope:** subject.patch (commit `dde15a8`, "fix(inventory): stop caching stock levels with a negative TTL")
**Date:** 2026-11-20
**User goal:** Judge whether this change keeps the codebase structurally sound.

**Reason:** The patch doesn't change module structure, public APIs, data models or cross-cutting concerns. Every change is implementation work inside one existing infrastructure adapter, so a full architecture review isn't warranted.

**Files reviewed for scope:**
- `inventory/infrastructure/redis_stock_cache.py`. This is the only file in the patch. The repository holds only `subject.patch`, so I read no surrounding source. The patch's context lines gave me the imports and class declaration.

**Trigger categories evaluated:**
- **Module structure: no.** No modules were added, moved, renamed, split or merged.
- **Public APIs: no.** The only method changed is `_ttl_for`, which is private by its leading underscore. Its signature `(self, level: StockLevel) -> int` is unchanged. The two new constants, `_MIN_TTL_SECONDS` and `_MAX_TTL_SECONDS`, are also private to the module. The `RedisStockCache(StockCache)` class and its constructor are untouched.
- **Data models: no.** `StockLevel` isn't modified, and neither is the cache key format (`stock:{sku}`). Nothing about serialization changes either.
- **Cross-cutting concerns: no.** The Redis client is still passed in through the constructor, and no middleware, configuration loading or composition-root wiring changes. The caching layer's behaviour changes but its structure doesn't: only how expiry is calculated inside one adapter.

**Structural note (no action needed):** The imports in the patch context follow a clean ports-and-adapters layout. The infrastructure adapter depends inward on `inventory.application.ports.StockCache` and `inventory.domain.stock.StockLevel`. The patch adds no imports, and dependencies still point inward. On the user's goal: the change leaves the codebase structurally sound.

**Out of scope, for code-review / correctness:** This patch changes behaviour in two ways that someone should confirm are intended:
1. **Past restock dates:** items whose restock date has passed are now cached for 30 seconds. Before, the negative TTL made Redis reject the write, so these items were never cached.
2. **Far-future restock dates:** these are now capped at 3600 seconds. Before, the TTL could run past an hour.

Neither is an architecture issue.

The skill would normally save this note to `docs/reviews/architecture-review.md`. You asked for stdout, so I only printed it and didn't write the file. If you think a structural review is still needed, run it again with an explicit scope or reason.
