import { NextResponse } from "next/server";
import { getBackendHealth } from "@/lib/backend";

export const dynamic = "force-dynamic";

export async function GET() {
  let backend: unknown = { ok: false, error: "FastAPI backend is unavailable." };
  try {
    backend = await getBackendHealth();
  } catch {
    // The web liveness endpoint remains available so container health checks can diagnose the API.
  }

  const backendOk =
    typeof backend === "object" && backend !== null && "ok" in backend
      ? (backend as { ok?: unknown }).ok === true
      : false;

  return NextResponse.json(
    {
      ok: backendOk,
      service: "nextjs-frontend",
      backend,
      timestamp: new Date().toISOString()
    },
    { status: backendOk ? 200 : 503 }
  );
}
