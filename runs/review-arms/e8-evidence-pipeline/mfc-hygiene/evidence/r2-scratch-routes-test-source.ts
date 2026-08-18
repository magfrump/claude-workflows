// SCRATCH TEST — code-fact-check replicate r2. Delete after run.
// Route-level redaction checks with callLlm mocked.
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import type { NextRequest } from "next/server";

const callLlmMock = vi.fn();

vi.mock("@/app/lib/llm/callLlm", () => ({
  callLlm: (...a: unknown[]) => callLlmMock(...a),
  OpenRouterError: class OpenRouterError extends Error {
    status: number;
    details: string;
    constructor(status: number, details: string) {
      super(`OpenRouter API error: ${status}`);
      this.status = status;
      this.details = details;
    }
  },
}));
vi.mock("@/app/lib/llm/cache", () => ({ removeCachedResult: vi.fn(async () => {}) }));

const usage = { provider: "openrouter", model: "m", inputTokens: 1, outputTokens: 1, costUsd: 0, latencyMs: 0 };
const NOT_JSON = "NOTJSON_MARKER_" + "x".repeat(600); // 615 chars, not valid JSON

function fakeRequest(body: unknown): NextRequest {
  return { json: async () => body } as unknown as NextRequest;
}

let errorSpy: ReturnType<typeof vi.spyOn>;

beforeEach(() => {
  callLlmMock.mockReset();
  errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe("edit/artifact invalid-JSON redaction (route.ts:77-84)", () => {
  it("logs only the length; response payload echoes a 500-char slice", async () => {
    const { POST } = await import("@/app/api/edit/artifact/route");
    callLlmMock.mockResolvedValue({ text: NOT_JSON, usage });

    const res = await POST(fakeRequest({ content: "{}", instruction: "edit it" }));
    expect(res.status).toBe(502);
    const body = await res.json();
    expect(body.error).toBe("LLM response was not valid JSON");
    expect(body.details).toBe(NOT_JSON.slice(0, 500));
    expect(body.details).toHaveLength(500);

    const logged = errorSpy.mock.calls.map((c) => c.join(" ")).join("\n");
    expect(logged).toContain(`${NOT_JSON.length} chars`);
    expect(logged).not.toContain("NOTJSON_MARKER_");
  });
});

describe("artifactRoute invalid-JSON logging (artifactRoute.ts:106-107) — sibling route coverage", () => {
  it("still logs a 500-char preview of the LLM response content", async () => {
    const { handleArtifactRoute } = await import("@/app/lib/formalization/artifactRoute");
    callLlmMock.mockResolvedValue({ text: NOT_JSON, usage });

    const res = await handleArtifactRoute(fakeRequest({ sourceText: "src" }), {
      endpoint: "artifact-test",
      systemPrompt: "s",
      responseKey: "k",
      mockResponse: () => ({}),
    });
    expect(res.status).toBe(502);

    const logged = errorSpy.mock.calls.map((c) => c.join(" ")).join("\n");
    // This DOES contain response content — refutes any codebase-wide reading of
    // "LLM response text shouldn't end up in server logs".
    expect(logged).toContain("NOTJSON_MARKER_");
  });
});
