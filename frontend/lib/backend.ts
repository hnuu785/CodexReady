const DEFAULT_BACKEND_URL = "http://127.0.0.1:8000";

export class BackendError extends Error {
  constructor(
    message: string,
    readonly status = 502
  ) {
    super(message);
  }
}

function backendUrl(path: string): string {
  const base = (process.env.BACKEND_URL ?? DEFAULT_BACKEND_URL).replace(/\/$/, "");
  return `${base}${path}`;
}

function timeoutMs(): number {
  const configured = Number(process.env.BACKEND_TIMEOUT_MS ?? 95_000);
  return Number.isFinite(configured)
    ? Math.min(Math.max(configured, 1_000), 305_000)
    : 95_000;
}

async function parseJson(response: Response): Promise<unknown> {
  const contentType = response.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) return null;
  return response.json();
}

export async function requestInference(prompt: string): Promise<unknown> {
  let response: Response;
  try {
    response = await fetch(backendUrl("/v1/inference"), {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ prompt }),
      cache: "no-store",
      signal: AbortSignal.timeout(timeoutMs())
    });
  } catch (error) {
    const message = error instanceof Error && error.name === "TimeoutError"
      ? "FastAPI 요청 시간이 초과되었습니다."
      : "FastAPI 백엔드에 연결할 수 없습니다.";
    throw new BackendError(message);
  }

  const body = await parseJson(response);
  if (!response.ok) {
    const detail =
      typeof body === "object" && body !== null && "detail" in body
        ? (body as { detail?: unknown }).detail
        : undefined;
    const message = typeof detail === "string" ? detail : "FastAPI 요청에 실패했습니다.";
    throw new BackendError(message, response.status);
  }

  return body;
}

export async function getBackendHealth(): Promise<unknown> {
  const response = await fetch(backendUrl("/health"), {
    cache: "no-store",
    signal: AbortSignal.timeout(2_000)
  });
  if (!response.ok) throw new BackendError("FastAPI health check failed.", response.status);
  return parseJson(response);
}
