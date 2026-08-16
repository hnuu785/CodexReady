# Codex Build Log

Codex가 단순히 코드를 생성한 기록이 아니라, 팀이 어떻게 업무를 위임하고 계획·구현·반복·오류 복구·검증했는지를 보여주는 문서입니다. 프롬프트 전문보다 **결정, 변화, 증거**를 짧게 남깁니다.

## Entry 001 — 배포 가능한 출발점 구성

- 시각: 2026-08-16
- 담당: Developer + Codex
- 목표: 빈 저장소를 AWS 배포 및 선택적 RunPod GPU 연동이 가능한 해커톤 스타터로 만든다.
- Codex에 위임한 내용: 행사 요구사항 해석, 웹/API 구조, 초기 AWS App Runner 배포, 예산 보호, RunPod Serverless 워커, 제출 문서 템플릿 구성. AWS 배포 방식은 Entry 002에서 ECS Express Mode로 교체.
- 계획: 웹 스타터 → 서버 프록시 → AWS → RunPod → 문서 → 빌드 및 컨테이너 검증.
- 구현: Next.js 앱, 상태 API, RunPod 프록시, 초기 App Runner CloudFormation, ECR 배포/정리 스크립트, AWS Budget 스크립트, GPU 확인 워커를 추가.
- 안전 장치: 비밀키 서버 전용 처리, RunPod 상시 워커 0 권장, AWS 서비스 최대 2개 작업 제한, AWS 20달러 예산, 명시적 삭제 확인값.
- 검증: 아래 Verification에 최종 결과를 기록.
- 실패와 복구: 첫 컨테이너 검증에서 Docker daemon이 꺼져 있어 연결에 실패. Docker Desktop을 시작한 뒤 같은 AMD64 빌드를 재실행해 성공했고, 컨테이너 내부 health endpoint까지 확인. 비밀값 패턴 검사에서는 README의 예시 문자열이 처음 탐지되어 문서·예시 파일을 제외한 소스 검사로 범위를 교정했고 실제 비밀값이 없음을 확인.
- 증거: `/api/health`, 첫 화면 RunPod Console, 배포 완료 URL.

### Verification

- [x] `npm test` — 타입 검사와 lint 통과
- [x] `npm run build` — Next.js production build 통과
- [x] 로컬 `/api/health` — HTTP 200, `ok: true`
- [x] 웹 컨테이너 빌드 — `linux/amd64` 빌드 및 컨테이너 health 응답 통과
- [x] 반응형 브라우저 검증 — 데스크톱/375px, 가로 overflow와 console error 없음
- [x] AWS/RunPod 정의 검증 — CloudFormation lint, worker Python 문법, RunPod base image 확인
- [ ] 배포 URL

---

## Entry 002 — AWS ECS Express Mode로 배포 전환

- 시각: 2026-08-16
- 담당: Developer + Codex
- 목표: 신규 AWS 계정에서도 지원되는 관리형 ECS 경로로 웹/API를 한 번에 배포한다.
- Codex에 위임한 내용: ECS Express Mode 공식 사양 확인, CloudFormation 전환, 배포·정리·준비 상태 스크립트와 문서 정합성 수정, 정적 검증.
- 구현: `AWS::ECS::ExpressGatewayService`, 실행 역할과 인프라 역할, `/api/health` 검사, 0.25 vCPU/512 MiB, 최소 1·최대 2개 작업 자동 확장을 구성. 배포 스크립트는 기본 VPC를 선확인하고 ECR 이미지 digest를 사용하며 RunPod 키를 SSM SecureString에서 ECS 작업으로 주입하도록 변경.
- 비용·안전 장치: AWS Budget은 그대로 유지하고, 정리 명령이 ECS 스택·ECR·RunPod SSM 파라미터를 제거하도록 갱신. 실제 AWS 생성은 로그인 후에만 수행.
- 검증: CloudFormation lint, 셸 문법, 앱 테스트와 production build 결과를 아래에 기록.
- 남은 위험: 실제 계정의 IAM/SCP 권한·크레딧·서비스 할당량과 기본 VPC 상태는 첫 배포 때 확인해야 함.

### Verification

- [x] CloudFormation lint — `cfn-lint infra/aws/ecs-express.yml` 통과
- [x] 배포·정리 스크립트 문법 검사 — `bash -n scripts/*.sh` 통과
- [x] `npm test` — 타입 검사와 lint 통과
- [x] `npm run build` — Next.js production build 통과
- [x] AWS용 컨테이너 — `linux/amd64` 빌드 및 `/api/health` HTTP 200 확인
- [ ] 실제 AWS 배포 URL

---

## Entry 003 — Next.js + FastAPI 로컬 우선 구조

- 시각: 2026-08-16
- 담당: Developer + Codex
- 목표/사용자 결과: GPU와 외부 API 키가 없는 팀원도 프론트→백엔드 핵심 흐름을 로컬에서 검증하고, 필요할 때만 PyTorch 또는 RunPod로 전환한다.
- Codex에 위임한 내용: FastAPI 분리, provider 추상화, Next.js BFF 연결, Docker Compose와 비-Docker 실행 경로, 테스트·문서·기존 AWS 배포 정합성 구성.
- 계획: 현재 Next.js/RunPod 경로 확인 → FastAPI 수직 흐름 → 로컬 실행 두 방식 → 제품 컨테이너 → 통합 검증.
- 구현 또는 변경: `/health`와 `/v1/inference` FastAPI, `mock/local/runpod` provider, `/api/inference` Next.js 프록시, Compose의 독립 frontend/backend 컨테이너, FastAPI 테스트 4개, Python 포함 단일 AWS 제품 이미지, CI Python 검증을 추가했다.
- 제품·비용 결정: 로컬에서는 서비스 경계를 분명히 하기 위해 컨테이너를 둘로 나눈다. ECS Express Mode에서는 해커톤 비용과 로드 밸런서 수를 늘리지 않기 위해 Next.js와 FastAPI 프로세스를 같은 제품 컨테이너에 둔다. 독립 확장이 필요해질 때 서비스를 분리한다.
- 실패/예상 밖 결과: 삭제한 `/api/runpod`을 `.next/dev` 생성 타입이 계속 참조해 첫 타입 검사가 실패했다. Compose 통합 확인에서는 기존 로컬 프로세스가 3000번 포트를 점유해 frontend 시작이 실패했다.
- 복구 또는 반복: 오래된 생성 캐시를 별도 임시 위치로 이동한 뒤 타입 생성을 갱신했고, Compose 외부 포트를 환경변수로 바꿀 수 있게 만들어 3100번에서 통합 흐름을 재검증했다. 기존 3000번 프로세스는 변경하지 않았다.
- 남은 위험: 실제 RunPod 자격 증명 호출, 로컬 PyTorch 추가 설치, AWS 계정 배포는 아직 수행하지 않았다.

### Verification

- [x] `npm test` — Next.js 타입·lint와 FastAPI 테스트 4개 통과
- [x] `npm run build` — Next.js 16.3.1 production build 통과
- [x] `docker compose build` — frontend/backend 이미지 빌드 통과
- [x] Compose 통합 — FastAPI `/health`, Next.js `/api/health`, `/api/inference` mock 응답 확인
- [x] 제품 컨테이너 — Next.js와 FastAPI 동시 기동, health와 mock 추론 응답 확인
- [x] Compose·셸·Python 정적 검사 통과
- [ ] 실제 RunPod GPU 응답
- [ ] 실제 AWS 배포 URL

---

## Entry 004 — frontend/backend 최상위 경계 정리

- 시각: 2026-08-16
- 담당: Developer + Codex
- 목표/사용자 결과: 저장소를 처음 여는 팀원이 `frontend/`와 `backend/`만 보고 각 서비스의 소스, 설정, 의존성, 테스트 위치를 구분한다.
- Codex에 위임한 내용: 기존 기능을 유지하면서 Next.js 프로젝트 전체를 `frontend/`로 이동하고 루트 실행 명령, Docker, CI, AWS 빌드, 문서를 새 경로에 맞춘다.
- 구현 또는 변경: Next.js의 `app`, `components`, `lib`, 설정, `package.json`, lockfile, public 자산을 `frontend/`로 이동했다. 루트 `package.json`은 두 서비스를 조율하며 기존 `npm run dev/test/build` 인터페이스를 유지한다. Compose 볼륨, Docker 빌드 컨텍스트, CI 캐시와 설치 경로, readiness 검사, 저장소 맵도 함께 변경했다.
- 실패/예상 밖 결과: 기능 실패는 없었다. Next.js 개발 서버가 생성 파일 `next-env.d.ts`를 개발 타입 경로로 전환하므로 검증 종료 시 제품 타입 경로로 되돌리는 절차를 유지했다.
- 복구 또는 반복: Docker build context에서 이전 루트 캐시와 가상환경이 포함되지 않도록 `.dockerignore` 범위를 보강했다.
- 남은 위험: 로컬 셸의 Node.js는 22.12.0으로 프로젝트 최소 버전 22.13.0보다 낮다. Docker 검증은 고정된 Node.js 22.14.0으로 통과했으며 로컬에서는 `nvm install && nvm use`가 필요하다.

### Verification

- [x] 루트 `npm test` — frontend 타입·lint와 backend 테스트 4개 통과
- [x] 루트 `npm run build` — 이동된 Next.js production build 통과
- [x] Docker Compose — 분리 컨테이너 build와 frontend→backend mock 요청 통과
- [x] AWS용 `linux/amd64` 제품 이미지 — build, `/api/health`, `/api/inference` 통과
- [x] readiness·Compose 설정·diff whitespace 검사 통과

---

## Entry 005 — 서비스 Docker 소유권과 루트 정리

- 시각: 2026-08-16
- 담당: Developer + Codex
- 목표/사용자 결과: 루트에는 공용 조율 파일만 남기고, 각 서비스는 자체 Dockerfile로 독립 빌드되며, AWS 통합 이미지 정의는 인프라 경계에서 관리한다.
- Codex에 위임한 내용: 빈 레거시 폴더 제거, pytest 캐시 제외, frontend/backend Dockerfile 독립화, AWS 제품 Dockerfile 이동, 모든 참조와 문서 갱신.
- 구현 또는 변경: 빈 `app/`, `components/`, `lib/`, `public/`을 제거하고 `/.pytest_cache`를 ignore 처리했다. `frontend/Dockerfile`과 서비스별 `.dockerignore`를 추가하고, backend Docker build context를 자체 폴더로 제한했다. 기존 통합 Dockerfile과 시작 스크립트는 `infra/docker/`로 이동했으며 Compose와 AWS 배포 스크립트를 새 경로에 맞췄다.
- 실패/예상 밖 결과: 없음.
- 남은 위험: AWS에서는 비용 절감을 위해 여전히 통합 이미지를 사용한다. 서비스별 독립 배포는 이미지 준비까지 검증했지만 별도 ECS 서비스 구성은 아직 만들지 않았다.

### Verification

- [x] `npm test`와 `npm run build` 통과
- [x] `frontend/Dockerfile` 제품 이미지 빌드 통과
- [x] `backend/Dockerfile` 제품 이미지 빌드 통과
- [x] Docker Compose 분리 실행과 frontend→backend mock 요청 통과
- [x] `infra/docker/Dockerfile.production` AMD64 빌드·health·추론 요청 통과
- [x] Compose 설정·셸 문법·CloudFormation·diff whitespace 검사 통과

---

## Entry template

### Entry NNN — 제목

- 시각:
- 담당:
- 목표/사용자 결과:
- Codex에 위임한 내용:
- Codex의 계획을 팀이 수정한 부분:
- 구현 또는 변경:
- 실패/예상 밖 결과:
- 복구 또는 반복:
- 검증 명령과 결과:
- 사용자 검증:
- 남은 위험:
- 증거 링크 또는 캡처:
