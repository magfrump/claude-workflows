// Archived copy of the scratch test run as app/lib/llm/__r1scratch.redaction.test.ts
// (deleted from the clone after the run; output: r1-redaction-scratch-tests.txt)
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

vi.mock("./cache", () => ({
  computeHash: vi.fn(() => "hash"),
  getCachedResult: vi.fn(async () => null),
  setCachedResult: vi.fn(async () => {}),
}));
vi.mock("@/app/lib/analytics/persist", () => ({
  appendAnalyticsEntry: vi.fn(),
}));
vi.mock("./costs", () => ({
  computeCost: vi.fn(() => 0),
}));

const SECRET = "SECRET_PROVIDER_BODY_XYZ";

let errorSpy: ReturnType<typeof vi.spyOn>;

beforeEach(() => {
  delete process.env.ANTHROPIC_API_KEY;
  process.env.OPENROUTER_API_KEY = "or-key";
  errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => {
  errorSpy.mockRestore();
  vi.unstubAllGlobals();
  delete process.env.OPENROUTER_API_KEY;
});

describe("callLlm OpenRouter error redaction (callLlm.ts:180-188)", () => {
  it("logs only status+endpoint; body rides on OpenRouterError.details", async () => {
    vi.stubGlobal("fetch", vi.fn(async () => ({
      ok: false,
      status: 418,
      text: async () => SECRET,
    })));
    const { callLlm, OpenRouterError } = await import("./callLlm");

    let caught: unknown;
    try {
      await callLlm({
        endpoint: "r1test",
        systemPrompt: "s",
        userContent: "u",
        maxTokens: 10,
        openRouterModel: "some/model",
      });
    } catch (e) {
      caught = e;
    }
    expect(caught).toBeInstanceOf(OpenRouterError);
    expect((caught as InstanceType<typeof OpenRouterError>).details).toBe(SECRET);
    expect((caught as InstanceType<typeof OpenRouterError>).status).toBe(418);

    const logged = errorSpy.mock.calls.map((c) => c.join(" ")).join("\n");
    console.log("CAPTURED-LOG-CALLLM:", JSON.stringify(logged));
    expect(logged).toContain("[r1test] OpenRouter error: status=418");
    expect(logged).not.toContain(SECRET);
  });
});

describe("streamLlm error path (streamLlm.ts:156-165)", () => {
  it("SSE error event carries { error } only — no details key; log has no body", async () => {
    vi.stubGlobal("fetch", vi.fn(async () => ({
      ok: false,
      status: 500,
      text: async () => SECRET,
    })));
    const { streamLlm } = await import("./streamLlm");

    const stream = streamLlm({
      endpoint: "r1stream",
      systemPrompt: "s",
      userContent: "u",
      maxTokens: 10,
      openRouterModel: "some/model",
    });

    const reader = stream.getReader();
    const decoder = new TextDecoder();
    let raw = "";
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      raw += decoder.decode(value);
    }
    console.log("CAPTURED-SSE-RAW:", JSON.stringify(raw));

    const m = raw.match(/event: error\ndata: (.*)\n\n/);
    expect(m).not.toBeNull();
    const payload = JSON.parse(m![1]);
    expect(payload).toEqual({ error: "OpenRouter API error: 500" });
    expect(Object.keys(payload)).not.toContain("details");
    expect(raw).not.toContain(SECRET);

    const logged = errorSpy.mock.calls.map((c) => c.join(" ")).join("\n");
    console.log("CAPTURED-LOG-STREAM:", JSON.stringify(logged));
    expect(logged).toContain("[r1stream] Stream error: OpenRouter API error: 500");
    expect(logged).not.toContain(SECRET);
  });
});
