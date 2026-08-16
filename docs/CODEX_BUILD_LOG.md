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
