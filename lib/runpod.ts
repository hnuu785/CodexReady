const RUNPOD_API_BASE = "https://api.runpod.ai/v2";

export class RunpodConfigurationError extends Error {}

export async function runSync(input: Record<string, unknown>): Promise<unknown> {
  const apiKey = process.env.RUNPOD_API_KEY?.trim();
  const endpointId = process.env.RUNPOD_ENDPOINT_ID?.trim();

  if (!apiKey || !endpointId) {
    throw new RunpodConfigurationError(
      "RunPod이 아직 연결되지 않았습니다. RUNPOD_API_KEY와 RUNPOD_ENDPOINT_ID를 설정해 주세요."
    );
  }

  const configuredTimeout = Number(process.env.RUNPOD_TIMEOUT_MS ?? 90_000);
  const timeoutMs = Number.isFinite(configuredTimeout)
    ? Math.min(Math.max(configuredTimeout, 1_000), 300_000)
    : 90_000;

  const response = await fetch(
    `${RUNPOD_API_BASE}/${encodeURIComponent(endpointId)}/runsync?wait=${timeoutMs}`,
    {
      method: "POST",
      headers: {
        authorization: apiKey,
        "content-type": "application/json"
      },
      body: JSON.stringify({ input }),
      cache: "no-store",
      signal: AbortSignal.timeout(timeoutMs + 5_000)
    }
  );

  const raw = await response.text();
  let body: unknown;
  try {
    body = JSON.parse(raw);
  } catch {
    body = { message: raw.slice(0, 500) };
  }

  if (!response.ok) {
    throw new Error(`RunPod 응답 오류 (${response.status}): ${JSON.stringify(body)}`);
  }

  return body;
}
