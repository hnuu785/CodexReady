"use client";

import { FormEvent, useState } from "react";

type RequestState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; result: unknown }
  | { status: "error"; message: string };

export function RunpodConsole() {
  const [prompt, setPrompt] = useState("Codex Seoul GPU check");
  const [state, setState] = useState<RequestState>({ status: "idle" });

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!prompt.trim()) return;
    setState({ status: "loading" });

    try {
      const response = await fetch("/api/runpod", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ prompt: prompt.trim() })
      });
      const body = (await response.json()) as { result?: unknown; error?: string };
      if (!response.ok) throw new Error(body.error ?? "RunPod 요청에 실패했습니다.");
      setState({ status: "success", result: body.result });
    } catch (error) {
      setState({
        status: "error",
        message: error instanceof Error ? error.message : "알 수 없는 오류가 발생했습니다."
      });
    }
  }

  return (
    <form className="console" onSubmit={submit}>
      <div className="console-top"><span><b /> RUNPOD CONSOLE</span><small>SERVER-SIDE PROXY</small></div>
      <label htmlFor="prompt">워커에 보낼 입력</label>
      <textarea
        id="prompt"
        value={prompt}
        onChange={(event) => setPrompt(event.target.value)}
        maxLength={2000}
        rows={4}
      />
      <button disabled={state.status === "loading"} type="submit">
        {state.status === "loading" ? "GPU 깨우는 중…" : "테스트 요청 보내기 →"}
      </button>
      <div className={`console-output ${state.status}`} aria-live="polite">
        {state.status === "idle" && "RUNPOD_API_KEY와 ENDPOINT_ID를 설정하면 여기서 바로 테스트할 수 있습니다."}
        {state.status === "loading" && "첫 요청은 콜드 스타트 때문에 잠시 걸릴 수 있습니다."}
        {state.status === "error" && state.message}
        {state.status === "success" && <pre>{JSON.stringify(state.result, null, 2)}</pre>}
      </div>
    </form>
  );
}
