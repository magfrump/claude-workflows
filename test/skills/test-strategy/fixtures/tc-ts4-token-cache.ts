// Caches the OAuth access token for calls to the Larkspur inventory API.

export interface Token {
  value: string;
  expiresAt: number; // epoch ms
}

export type FetchToken = () => Promise<Token>;

const SKEW_MS = 30_000;

export class TokenCache {
  private current: Token | null = null;
  private refreshing: Promise<Token> | null = null;

  constructor(
    private readonly fetchToken: FetchToken,
    private readonly now: () => number = Date.now,
  ) {}

  private isFresh(t: Token | null): t is Token {
    return t !== null && t.expiresAt - SKEW_MS > this.now();
  }

  async get(): Promise<string> {
    if (this.isFresh(this.current)) {
      return this.current.value;
    }
    if (this.refreshing === null) {
      this.refreshing = this.fetchToken()
        .then((t) => {
          this.current = t;
          return t;
        })
        .finally(() => {
          this.refreshing = null;
        });
    }
    const t = await this.refreshing;
    return t.value;
  }

  invalidate(): void {
    this.current = null;
  }
}

// --- tests (tokenCache.test.ts) ---

import { describe, it, expect, vi } from "vitest";

describe("TokenCache", () => {
  it("fetches a token on first use", async () => {
    const fetchToken = vi.fn().mockResolvedValue({ value: "a", expiresAt: 1_000_000 });
    const cache = new TokenCache(fetchToken, () => 0);
    expect(await cache.get()).toBe("a");
    expect(fetchToken).toHaveBeenCalledTimes(1);
  });

  it("reuses a fresh token", async () => {
    const fetchToken = vi.fn().mockResolvedValue({ value: "a", expiresAt: 1_000_000 });
    const cache = new TokenCache(fetchToken, () => 0);
    await cache.get();
    await cache.get();
    expect(fetchToken).toHaveBeenCalledTimes(1);
  });

  it("refreshes inside the expiry skew window", async () => {
    let clock = 0;
    const fetchToken = vi
      .fn()
      .mockResolvedValueOnce({ value: "a", expiresAt: 100_000 })
      .mockResolvedValueOnce({ value: "b", expiresAt: 500_000 });
    const cache = new TokenCache(fetchToken, () => clock);
    expect(await cache.get()).toBe("a");
    clock = 75_000;
    expect(await cache.get()).toBe("b");
  });

  it("invalidate forces a refetch", async () => {
    const fetchToken = vi.fn().mockResolvedValue({ value: "a", expiresAt: 1_000_000 });
    const cache = new TokenCache(fetchToken, () => 0);
    await cache.get();
    cache.invalidate();
    await cache.get();
    expect(fetchToken).toHaveBeenCalledTimes(2);
  });
});
