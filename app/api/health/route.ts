import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET() {
  return NextResponse.json({
    ok: true,
    service: "codex-seoul-starter",
    runpodConfigured: Boolean(
      process.env.RUNPOD_API_KEY?.trim() && process.env.RUNPOD_ENDPOINT_ID?.trim()
    ),
    timestamp: new Date().toISOString()
  });
}
