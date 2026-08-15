#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-ap-northeast-2}"
APP_NAME="${APP_NAME:-codex-ready}"
STACK_NAME="${STACK_NAME:-${APP_NAME}-app}"
REPOSITORY_NAME="${REPOSITORY_NAME:-${APP_NAME}}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$ROOT_DIR/.env.local" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env.local"
  set +a
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "필수 도구를 찾을 수 없습니다: $1" >&2
    exit 1
  fi
}

require_command aws
require_command docker

echo "AWS 로그인과 권한을 확인합니다."
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}"

if ! aws ecr describe-repositories \
  --region "$AWS_REGION" \
  --repository-names "$REPOSITORY_NAME" >/dev/null 2>&1; then
  echo "컨테이너 저장소를 생성합니다: ${REPOSITORY_NAME}"
  aws ecr create-repository \
    --region "$AWS_REGION" \
    --repository-name "$REPOSITORY_NAME" \
    --image-scanning-configuration scanOnPush=true \
    --image-tag-mutability IMMUTABLE \
    --tags Key=Project,Value="$APP_NAME" >/dev/null
fi

if GIT_TAG="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null)"; then
  :
else
  GIT_TAG="$(date -u +%Y%m%d%H%M%S)"
fi
IMAGE_TAG="${IMAGE_TAG:-${GIT_TAG}-$(date -u +%H%M%S)}"
IMAGE_IDENTIFIER="${ECR_URI}:${IMAGE_TAG}"

echo "AWS용 컨테이너를 빌드합니다: ${IMAGE_TAG}"
docker build --platform linux/amd64 -t "$IMAGE_IDENTIFIER" "$ROOT_DIR"

echo "컨테이너를 Amazon ECR에 업로드합니다."
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
docker push "$IMAGE_IDENTIFIER"

RUNPOD_PARAMETER_ARN=""
if [[ -n "${RUNPOD_API_KEY:-}" ]]; then
  echo "RunPod API 키를 AWS 암호화 파라미터에 저장합니다."
  PARAMETER_NAME="/${APP_NAME}/runpod-api-key"
  aws ssm put-parameter \
    --region "$AWS_REGION" \
    --name "$PARAMETER_NAME" \
    --type SecureString \
    --value "$RUNPOD_API_KEY" \
    --overwrite >/dev/null
  RUNPOD_PARAMETER_ARN="arn:aws:ssm:${AWS_REGION}:${ACCOUNT_ID}:parameter${PARAMETER_NAME}"
fi

echo "AWS App Runner 서비스를 배포합니다."
aws cloudformation deploy \
  --region "$AWS_REGION" \
  --stack-name "$STACK_NAME" \
  --template-file "$ROOT_DIR/infra/aws/app-runner.yml" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    AppName="$APP_NAME" \
    ImageIdentifier="$IMAGE_IDENTIFIER" \
    RunpodEndpointId="${RUNPOD_ENDPOINT_ID:-}" \
    RunpodApiKeyParameterArn="$RUNPOD_PARAMETER_ARN" \
  --tags Project="$APP_NAME" ManagedBy=codex-ready

SERVICE_URL="$(aws cloudformation describe-stacks \
  --region "$AWS_REGION" \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='ServiceUrl'].OutputValue" \
  --output text)"

echo "배포가 완료되었습니다."
echo "서비스: ${SERVICE_URL}"
echo "상태 확인: ${SERVICE_URL}/api/health"
