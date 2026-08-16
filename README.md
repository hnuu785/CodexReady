# Codex Community Hackathon Seoul — Developer Starter

처음 만난 4인 팀이 당일 바로 제품 개발을 시작하고 공개 URL까지 만들 수 있는 스타터입니다. 기본 웹 앱과 서버 API는 하나의 Next.js 프로젝트에 있고, AWS ECS Express Mode에 컨테이너로 배포합니다. GPU가 필요한 팀은 RunPod Serverless 워커를 선택적으로 연결할 수 있습니다.

## 준비된 것

- 반응형 Next.js 웹 앱과 `/api/health`
- 브라우저에 키를 노출하지 않는 `/api/runpod` 서버 프록시
- AWS ECS Express Mode + ECR 배포 자동화
- AWS 월 사용량 20달러 예산 알림 자동화
- RunPod GPU 확인용 Serverless 워커
- GitHub CI, Codex 작업 규칙, 제출 문서 템플릿
- 배포 종료 후 유료 리소스 정리 명령

## 구조

```text
브라우저
  └─ AWS ECS Express Mode (Next.js 웹 + API)
       ├─ /api/health
       └─ /api/runpod ── 선택 사항 ── RunPod Serverless GPU Worker
```

AWS만 써도 앱은 정상 동작합니다. RunPod는 이미지 생성, 음성 처리, 오픈소스 모델 추론처럼 GPU가 실제로 필요할 때만 연결하세요.

## 1. 로컬에서 시작 — 약 3분

필요한 도구는 Node.js 22.13+, Git, Docker입니다.

```bash
nvm install
nvm use
npm install
cp .env.example .env.local
npm run dev
```

[http://localhost:3000](http://localhost:3000)을 열고 상태 확인은 [http://localhost:3000/api/health](http://localhost:3000/api/health)에서 합니다.

```bash
npm test
npm run build
npm run check
```

`npm run check`에서 AWS CLI만 실패한다면 로컬 개발은 가능합니다. macOS에서는 `brew install awscli`로 설치할 수 있습니다.

## 2. AWS 크레딧 안전장치

1. 행사 안내에 따라 **팀 AWS 계정에 $25 크레딧이 실제 등록됐는지 Billing → Credits에서 먼저 확인**합니다.
2. AWS CLI에 행사 계정으로 로그인합니다. 개인 장기 키보다 `aws configure sso`를 권장하며, 제공 방식이 액세스 키라면 `aws configure`를 사용합니다.
3. 서울 리전(`ap-northeast-2`)이 기본값입니다.
4. 크레딧 전액보다 낮은 20달러 예산을 먼저 만듭니다.

```bash
BUDGET_EMAIL=알림받을주소 npm run budget:aws
```

50%와 80% 실제 사용, 100% 예상 사용 시 이메일을 받습니다. 이 예산은 크레딧·환불을 빼기 전 비용을 추적하도록 설정했습니다. AWS 비용 데이터와 알림에는 지연이 있으므로 예산 알림은 강제 차단 장치가 아닙니다.

## 3. AWS에 배포 — 약 10~15분

Docker Desktop을 켠 뒤 실행합니다. ECS Express Mode는 선택한 리전의 기본 VPC를 사용하므로, 삭제한 적이 있다면 AWS VPC 콘솔에서 기본 VPC를 먼저 다시 생성해야 합니다. 기본 public subnet은 서로 다른 가용 영역에 2개 이상 있어야 하며 각 subnet에 사용 가능한 IPv4 주소가 8개 이상 필요합니다. 배포 명령이 이를 먼저 확인합니다.

```bash
npm run deploy:aws
```

이 명령은 다음을 자동으로 처리합니다.

1. ECR 저장소 생성
2. `linux/amd64` 제품 컨테이너 빌드
3. 이미지 업로드 및 변경되지 않는 이미지 digest 확인
4. ECS Express Mode 서비스, 로드 밸런서, 로그, 자동 확장과 필요한 IAM 역할 생성
5. 공개 HTTPS URL과 상태 확인 URL 출력

업데이트할 때도 같은 명령을 다시 실행하면 새 이미지로 배포됩니다. 기본 크기는 0.25 vCPU/512 MiB이며, 오토스케일은 최소 1개, 최대 2개 작업으로 제한되어 있습니다.

### 배포 종료 후 반드시 정리

ECS Express Mode는 요청이 없어도 최소 작업 1개와 로드 밸런서 비용이 발생할 수 있습니다. 제출 확인이 끝나고 서비스를 유지하지 않을 경우 다음 명령으로 ECS Express Mode 스택, 역할, ECR 이미지와 저장소, AWS에 저장한 RunPod 키를 삭제합니다.

```bash
CONFIRM_DESTROY=codex-ready npm run cleanup:aws
```

비용 확인을 위해 AWS Budget은 남겨 둡니다. 직접 삭제하려면 Billing → Budgets에서 지우면 됩니다.

## 4. RunPod $10 크레딧 연결 — GPU가 필요할 때만

행사에서 받은 등록 링크나 코드를 **RunPod 계정에 먼저 적용하고 Billing에서 잔액을 확인**하세요. 지급 조건과 만료일은 행사 안내가 우선입니다.

### 워커 배포

가장 쉬운 방법은 RunPod의 GitHub 연동입니다.

1. 이 저장소를 팀 GitHub 저장소에 올립니다.
2. RunPod → Settings → Connections에서 GitHub를 연결합니다.
3. Serverless → New Endpoint → Import Git Repository를 선택합니다.
4. Dockerfile 경로를 `infra/runpod/Dockerfile`로 지정합니다.
5. Queue endpoint를 선택하고 아래처럼 시작합니다.

| 설정 | 크레딧 보호 기본값 |
|---|---:|
| Active workers | `0` |
| Max workers | `1` |
| GPUs per worker | `1` |
| Idle timeout | `5s` |
| Execution timeout | `120s` |

처음에는 사용 가능한 저가 GPU 한 종류로 검증한 뒤 품질이나 메모리가 부족할 때만 올리세요. Active workers가 0이면 콜드 스타트가 생기지만 대기 GPU 비용을 줄일 수 있습니다.

### 앱에 연결

RunPod에서 API key와 endpoint ID를 발급한 뒤 `.env.local`을 채웁니다.

```dotenv
RUNPOD_API_KEY=발급받은_키
RUNPOD_ENDPOINT_ID=엔드포인트_ID
RUNPOD_TIMEOUT_MS=90000
```

로컬 서버를 다시 시작하면 첫 화면의 RunPod Console에서 호출할 수 있습니다. AWS 배포 명령도 `.env.local`을 읽어 API 키는 SSM SecureString으로 저장한 뒤 ECS 작업에 비밀값으로 주입하고, endpoint ID는 일반 환경 변수로 전달합니다.

RunPod를 직접 빌드해야 한다면 Apple Silicon에서도 반드시 AMD64로 빌드합니다.

```bash
docker build --platform linux/amd64 -f infra/runpod/Dockerfile -t USER/WORKER:VERSION .
```

`infra/runpod/handler.py`의 `process()`만 팀 모델 추론 코드로 바꾸면 웹 앱의 요청 형식은 유지됩니다.

## 5. 행사 당일 추천 순서

1. `docs/TEAM_KICKOFF.md`로 30분 안에 사용자와 범위를 잠급니다.
2. 한 명이 저장소와 배포를 맡고, 다른 사람은 사용자 흐름·화면·검증을 병렬로 진행합니다.
3. 점심 전에 첫 통합, 오후 3시 전에 AWS 첫 배포를 목표로 합니다.
4. 기능이 완성될 때마다 `docs/CODEX_BUILD_LOG.md`에 Codex 위임과 검증 증거를 남깁니다.
5. 오후 4시부터 새 브라우저와 휴대폰에서 데모를 녹화합니다.
6. `docs/DEMO_CHECKLIST.md`로 제출 링크와 권한을 최종 확인합니다.

## 보안 원칙

- `.env.local`, AWS 키, RunPod 키를 Git에 커밋하지 않습니다.
- `NEXT_PUBLIC_` 변수에 비밀값을 넣지 않습니다.
- 사용자 입력은 길이를 제한하고 서버에서 다시 검사합니다.
- RunPod 호출은 브라우저가 아니라 `/api/runpod`을 통해서만 합니다.
- 팀원이 떠나거나 저장소가 공개되면 발급한 키를 회전합니다.

## 공식 참고 문서

- [Amazon ECS Express Mode 시작하기](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/express-service-getting-started.html)
- [ECS Express Mode CloudFormation 리소스](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-ecs-expressgatewayservice.html)
- [AWS Budget 만들기](https://docs.aws.amazon.com/cost-management/latest/userguide/create-cost-budget.html)
- [RunPod Serverless endpoint](https://docs.runpod.io/serverless/endpoints/overview)
- [RunPod GitHub 배포](https://docs.runpod.io/serverless/workers/github-integration)
- [RunPod 요청 API](https://docs.runpod.io/serverless/endpoints/send-requests)
