// SCRATCH TEST — code-fact-check replicate r2. Delete after run.
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

const constructorCalls: Array<{ apiKey: string }> = [];

vi.mock("@anthropic-ai/sdk", () => {
  return {
    default: class MockAnthropic {
      messages = {
        create: vi.fn(async () => ({
          content: [{ type: "text", text: "ok" }],
          usage: { input_tokens: 1, output_tokens: 1 },
        })),
        stream: vi.fn(() => {
          const handlers: Record<string, (t: string) => void> = {};
          return {
            on(event: string, cb: (t: string) => void) {
              handlers[event] = cb;
              return this;
            },
            async finalMessage() {
              handlers["text"]?.("hi");
              return { usage: { input_tokens: 1, output_tokens: 1 } };
            },
          };
        }),
      };
      constructor(opts: { apiKey: string }) {
        constructorCalls.push({ apiKey: opts.apiKey });
      }
    },
  };
});

const getCachedResult = vi.fn(async () => null as unknown);
vi.mock("./cache", () => ({
  computeHash: vi.fn(() => "hash"),
  getCachedResult: (...a: unknown[]) => getCachedResult(...a),
  setCachedResult: vi.fn(async () => {}),
  removeCachedResult: vi.fn(async () => {}),
}));
vi.mock("@/app/lib/analytics/persist", () => ({ appendAnalyticsEntry: vi.fn() }));
vi.mock("./costs", () => ({ computeCost: vi.fn(() => 0) }));

async function readStreamToString(stream: ReadableStream<Uint8Array>): Promise<string> {
  const reader = stream.getReader();
  const decoder = new TextDecoder();
  let out = "";
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    out += decoder.decode(value, { stream: true });
  }
  return out;
}

function parseSseEvents(raw: string): Array<{ event: string; data: unknown }> {
  return raw
    .split("\n\n")
    .filter((b) => b.trim())
    .map((block) => {
      const event = /event: (.*)/.exec(block)?.[1] ?? "";
      const data = JSON.parse(/data: (.*)/.exec(block)?.[1] ?? "null");
      return { event, data };
    });
}

let errorSpy: ReturnType<typeof vi.spyOn>;

beforeEach(() => {
  constructorCalls.length = 0;
  getCachedResult.mockReset();
  getCachedResult.mockResolvedValue(null);
  delete process.env.ANTHROPIC_API_KEY;
  delete process.env.OPENROUTER_API_KEY;
  delete process.env.SIMULATE_STREAM_FROM_CACHE;
  errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
  vi.spyOn(console, "log").mockImplementation(() => {});
  vi.spyOn(console, "warn").mockImplementation(() => {});
});

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe("streamLlm catch block redaction (streamLlm.ts:156-165)", () => {
  it("SSE error event carries only { error }, no details key, body never logged or forwarded", async () => {
    const { streamLlm } = await import("./streamLlm");
    process.env.OPENROUTER_API_KEY = "or-key";
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({ ok: false, status: 500, text: async () => "SECRET_PROVIDER_BODY" })),
    );

    const raw = await readStreamToString(
      streamLlm({ endpoint: "t", systemPrompt: "s", userContent: "u", maxTokens: 10, openRouterModel: "m" }),
    );

    const events = parseSseEvents(raw);
    expect(events).toHaveLength(1);
    expect(events[0].event).toBe("error");
    expect(events[0].data).toEqual({ error: "OpenRouter API error: 500" });
    expect(Object.keys(events[0].data as object)).toEqual(["error"]);
    expect(raw).not.toContain("SECRET_PROVIDER_BODY");

    const logged = errorSpy.mock.calls.map((c) => c.join(" ")).join("\n");
    expect(logged).toContain("Stream error");
    expect(logged).not.toContain("SECRET_PROVIDER_BODY");
  });

  it("cache hit emits a single done event (JSDoc streamLlm.ts:74)", async () => {
    const { streamLlm } = await import("./streamLlm");
    getCachedResult.mockResolvedValue({
      text: "cached-text",
      usage: { provider: "cache", model: "m", inputTokens: 0, outputTokens: 0, costUsd: 0, latencyMs: 0 },
    });
    const raw = await readStreamToString(
      streamLlm({ endpoint: "t", systemPrompt: "s", userContent: "u", maxTokens: 10 }),
    );
    const events = parseSseEvents(raw);
    expect(events).toHaveLength(1);
    expect(events[0].event).toBe("done");
  });
});

describe("streamAnthropic per-call client construction (streamLlm.ts:207)", () => {
  it("constructs a fresh client with the env-current key on each stream", async () => {
    const { streamLlm } = await import("./streamLlm");

    process.env.ANTHROPIC_API_KEY = "stream-key-A";
    await readStreamToString(
      streamLlm({ endpoint: "t1", systemPrompt: "s", userContent: "u", maxTokens: 10 }),
    );
    process.env.ANTHROPIC_API_KEY = "stream-key-B";
    await readStreamToString(
      streamLlm({ endpoint: "t2", systemPrompt: "s", userContent: "u", maxTokens: 10 }),
    );

    expect(constructorCalls).toEqual([{ apiKey: "stream-key-A" }, { apiKey: "stream-key-B" }]);
  });
});

describe("callLlm OpenRouter error handling (callLlm.ts:180-188)", () => {
  it("logs status only; body rides on OpenRouterError.details", async () => {
    const { callLlm, OpenRouterError } = await import("./callLlm");
    process.env.OPENROUTER_API_KEY = "or-key";
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({ ok: false, status: 429, text: async () => "SECRET_PROVIDER_BODY" })),
    );

    let thrown: unknown;
    try {
      await callLlm({ endpoint: "t", systemPrompt: "s", userContent: "u", maxTokens: 10, openRouterModel: "m" });
    } catch (e) {
      thrown = e;
    }

    expect(thrown).toBeInstanceOf(OpenRouterError);
    expect((thrown as InstanceType<typeof OpenRouterError>).status).toBe(429);
    expect((thrown as InstanceType<typeof OpenRouterError>).details).toBe("SECRET_PROVIDER_BODY");

    const logged = errorSpy.mock.calls.map((c) => c.join(" ")).join("\n");
    expect(logged).toContain("status=429");
    expect(logged).not.toContain("SECRET_PROVIDER_BODY");
  });
});
