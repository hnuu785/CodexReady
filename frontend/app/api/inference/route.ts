import { NextRequest, NextResponse } from "next/server";
import { BackendError, requestInference } from "@/lib/backend";

export const runtime = "nodejs";
export const maxDuration = 300;

export async function POST(request: NextRequest) {
  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return NextResponse.json({ error: "올바른 JSON 요청이 아닙니다." }, { status: 400 });
  }

  const prompt =
    typeof payload === "object" && payload !== null && "prompt" in payload
      ? (payload as { prompt?: unknown }).prompt
      : undefined;

  if (typeof prompt !== "string" || !prompt.trim() || prompt.length > 2000) {
    return NextResponse.json(
      { error: "prompt는 1자 이상 2,000자 이하의 문자열이어야 합니다." },
      { status: 400 }
    );
  }

  try {
    const result = await requestInference(prompt.trim());
    return NextResponse.json(result);
  } catch (error) {
    const status = error instanceof BackendError ? error.status : 502;
    const message = error instanceof Error ? error.message : "추론 요청에 실패했습니다.";
    console.error("FastAPI proxy error", {
      name: error instanceof Error ? error.name : "Unknown",
      status
    });
    return NextResponse.json({ error: message }, { status });
  }
}
