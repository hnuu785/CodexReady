"use client";

import { FormEvent, useState } from "react";

type RequestState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; result: unknown }
  | { status: "error"; message: string };

export function InferenceConsole() {
  const [prompt, setPrompt] = useState("Codex Seoul local backend check");
  const [state, setState] = useState<RequestState>({ status: "idle" });

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!prompt.trim()) return;
    setState({ status: "loading" });

    try {
      const response = await fetch("/api/inference", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ prompt: prompt.trim() })
      });
      const body = (await response.json()) as { error?: string };
      if (!response.ok) throw new Error(body.error ?? "추론 요청에 실패했습니다.");
      setState({ status: "success", result: body });
    } catch (error) {
      setState({
        status: "error",
        message: error instanceof Error ? error.message : "알 수 없는 오류가 발생했습니다."
      });
    }
  }

  return (
    <form className="console" onSubmit={submit}>
      <div className="console-top">
        <span><b /> FASTAPI CONSOLE</span>
        <small>MOCK · LOCAL · RUNPOD</small>
      </div>
      <label htmlFor="prompt">백엔드에 보낼 입력</label>
      <textarea
        id="prompt"
        value={prompt}
        onChange={(event) => setPrompt(event.target.value)}
        maxLength={2000}
        rows={4}
      />
      <button disabled={state.status === "loading"} type="submit">
        {state.status === "loading" ? "처리하는 중…" : "테스트 요청 보내기 →"}
      </button>
      <div className={`console-output ${state.status}`} aria-live="polite">
        {state.status === "idle" && "기본 mock 모드에서는 GPU나 API 키 없이 전체 요청 흐름을 테스트할 수 있습니다."}
        {state.status === "loading" && "FastAPI가 선택된 추론 provider를 호출하고 있습니다."}
        {state.status === "error" && state.message}
        {state.status === "success" && <pre>{JSON.stringify(state.result, null, 2)}</pre>}
      </div>
    </form>
  );
}
