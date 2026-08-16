import { InferenceConsole } from "@/components/inference-console";

const phases = [
  { time: "10:10", title: "문제 고정", detail: "대상 사용자 · 가장 아픈 순간 · 성공 기준" },
  { time: "11:00", title: "범위 잠금", detail: "핵심 흐름 1개와 하지 않을 일 합의" },
  { time: "13:00", title: "첫 통합", detail: "화면과 API를 연결해 가장 얇은 데모 완성" },
  { time: "15:00", title: "배포", detail: "AWS 공개 URL에서 핵심 흐름 검증" },
  { time: "16:00", title: "증거 수집", detail: "사용 테스트 · 데모 영상 · Build Log 정리" },
  { time: "17:30", title: "제출", detail: "링크 권한과 새 브라우저 재생까지 확인" }
];

const principles = [
  ["한 사용자", "모두를 위한 제품보다 한 사람의 구체적인 순간을 해결합니다."],
  ["한 흐름", "로그인부터 모든 기능이 아니라, 가치가 드러나는 경로 하나를 완성합니다."],
  ["한 증거", "설명보다 URL, 영상, 테스트 결과로 작동 여부를 증명합니다."]
];

export default function Home() {
  return (
    <main>
      <section className="hero shell">
        <nav>
          <span className="brand"><i /> CODEX SEOUL</span>
          <span className="edition">STUDENT SPRINT KIT · 2026</span>
        </nav>
        <div className="hero-grid">
          <div>
            <p className="eyebrow">BUILD · SHARE · CONNECT</p>
            <h1>처음 만난 팀과,<br /><em>오늘 출시합니다.</em></h1>
            <p className="lede">
              문제 정의부터 실제 배포까지. 이 저장소는 팀이 코드보다 제품에 더 오래
              집중할 수 있도록 준비된 출발점입니다.
            </p>
            <div className="actions">
              <a className="button primary" href="#sprint">스프린트 시작</a>
              <a className="button ghost" href="/api/health">상태 확인</a>
            </div>
          </div>
          <aside className="status-card">
            <span className="live"><b /> STARTER ONLINE</span>
            <div className="metric"><strong>4</strong><span>people<br />one team</span></div>
            <div className="divider" />
            <div className="roles">
              <div><span>BUILD</span><strong>2</strong></div>
              <div><span>INSIGHT</span><strong>2</strong></div>
            </div>
            <p>Next.js · FastAPI · Docker · RunPod 준비 완료</p>
          </aside>
        </div>
      </section>

      <section className="manifesto">
        <div className="shell principle-grid">
          {principles.map(([title, detail], index) => (
            <article key={title}>
              <span>0{index + 1}</span>
              <h2>{title}</h2>
              <p>{detail}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="shell sprint" id="sprint">
        <div className="section-heading">
          <div><p className="eyebrow">THE DAY</p><h2>7시간 20분의 제품 스프린트</h2></div>
          <p>완벽한 설계보다 빠른 통합, 빠른 배포, 실제 검증을 우선합니다.</p>
        </div>
        <div className="timeline">
          {phases.map((phase, index) => (
            <article key={phase.time}>
              <div className="timeline-mark"><span>{index + 1}</span></div>
              <time>{phase.time}</time>
              <h3>{phase.title}</h3>
              <p>{phase.detail}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="gpu-section">
        <div className="shell gpu-grid">
          <div>
            <p className="eyebrow mint">LOCAL-FIRST AI BACKEND</p>
            <h2>로컬에서 검증하고,<br />GPU는 선택하세요.</h2>
            <p>
              Next.js가 FastAPI를 호출하고, FastAPI가 mock·로컬 PyTorch·RunPod 중
              실행 환경에 맞는 추론 방식을 선택합니다.
            </p>
            <ul>
              <li>GPU 없는 로컬 테스트</li>
              <li>독립적인 API 문서와 테스트</li>
              <li>선택형 RunPod GPU</li>
            </ul>
          </div>
          <InferenceConsole />
        </div>
      </section>

      <footer className="shell">
        <span className="brand"><i /> CODEX SEOUL</span>
        <p>Ship the smallest thing that proves the biggest value.</p>
      </footer>
    </main>
  );
}
