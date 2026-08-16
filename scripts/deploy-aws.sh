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

DEFAULT_VPC_ID="$(aws ec2 describe-vpcs \
  --region "$AWS_REGION" \
  --filters Name=is-default,Values=true \
  --query "Vpcs[0].VpcId" \
  --output text)"
if [[ -z "$DEFAULT_VPC_ID" || "$DEFAULT_VPC_ID" == "None" ]]; then
  echo "ECS Express Mode에 필요한 기본 VPC가 ${AWS_REGION} 리전에 없습니다." >&2
  echo "AWS 콘솔에서 기본 VPC를 생성한 뒤 다시 실행해 주세요." >&2
  exit 1
fi

READY_DEFAULT_SUBNETS="$(aws ec2 describe-subnets \
  --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$DEFAULT_VPC_ID" Name=default-for-az,Values=true \
  --query "length(Subnets[?AvailableIpAddressCount >= \`8\`])" \
  --output text)"
if (( READY_DEFAULT_SUBNETS < 2 )); then
  echo "ECS Express Mode에는 서로 다른 가용 영역의 기본 public subnet이 2개 이상 필요합니다." >&2
  echo "각 subnet에 사용 가능한 IPv4 주소가 8개 이상 있는지 확인해 주세요." >&2
  exit 1
fi

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
TAGGED_IMAGE="${ECR_URI}:${IMAGE_TAG}"

echo "AWS용 컨테이너를 빌드합니다: ${IMAGE_TAG}"
docker build --platform linux/amd64 -t "$TAGGED_IMAGE" "$ROOT_DIR"

echo "컨테이너를 Amazon ECR에 업로드합니다."
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
docker push "$TAGGED_IMAGE"

IMAGE_DIGEST="$(aws ecr describe-images \
  --region "$AWS_REGION" \
  --repository-name "$REPOSITORY_NAME" \
  --image-ids imageTag="$IMAGE_TAG" \
  --query "imageDetails[0].imageDigest" \
  --output text)"
IMAGE_IDENTIFIER="${ECR_URI}@${IMAGE_DIGEST}"

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

echo "Amazon ECS Express Mode 서비스를 배포합니다."
aws cloudformation deploy \
  --region "$AWS_REGION" \
  --stack-name "$STACK_NAME" \
  --template-file "$ROOT_DIR/infra/aws/ecs-express.yml" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    AppName="$APP_NAME" \
    ImageIdentifier="$IMAGE_IDENTIFIER" \
    RunpodEndpointId="${RUNPOD_ENDPOINT_ID:-}" \
    RunpodApiKeyParameterArn="$RUNPOD_PARAMETER_ARN" \
  --tags Project="$APP_NAME" ManagedBy=codex-ready

SERVICE_ENDPOINT="$(aws cloudformation describe-stacks \
  --region "$AWS_REGION" \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='ServiceUrl'].OutputValue" \
  --output text)"

if [[ "$SERVICE_ENDPOINT" == http://* || "$SERVICE_ENDPOINT" == https://* ]]; then
  SERVICE_URL="$SERVICE_ENDPOINT"
else
  SERVICE_URL="https://${SERVICE_ENDPOINT}"
fi

echo "배포가 완료되었습니다."
echo "서비스: ${SERVICE_URL}"
echo "상태 확인: ${SERVICE_URL}/api/health"
