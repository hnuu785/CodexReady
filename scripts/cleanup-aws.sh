#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-ap-northeast-2}"
APP_NAME="${APP_NAME:-codex-ready}"
STACK_NAME="${STACK_NAME:-${APP_NAME}-app}"
REPOSITORY_NAME="${REPOSITORY_NAME:-${APP_NAME}}"

if [[ "${CONFIRM_DESTROY:-}" != "$APP_NAME" ]]; then
  echo "ECS Express 서비스, 배포 역할, ECR 이미지와 RunPod 키 파라미터를 삭제합니다." >&2
  echo "계속하려면 다음처럼 실행하세요:" >&2
  echo "CONFIRM_DESTROY=${APP_NAME} npm run cleanup:aws" >&2
  exit 1
fi

echo "ECS Express Mode 스택과 관리 인프라를 삭제합니다."
if aws cloudformation describe-stacks \
  --region "$AWS_REGION" \
  --stack-name "$STACK_NAME" >/dev/null 2>&1; then
  aws cloudformation delete-stack --region "$AWS_REGION" --stack-name "$STACK_NAME"
  aws cloudformation wait stack-delete-complete --region "$AWS_REGION" --stack-name "$STACK_NAME"
else
  echo "CloudFormation 스택이 없어 건너뜁니다: ${STACK_NAME}"
fi

echo "ECR 저장소와 이미지를 삭제합니다."
aws ecr delete-repository \
  --region "$AWS_REGION" \
  --repository-name "$REPOSITORY_NAME" \
  --force >/dev/null 2>&1 || true

echo "RunPod 키 파라미터를 삭제합니다."
aws ssm delete-parameter \
  --region "$AWS_REGION" \
  --name "/${APP_NAME}/runpod-api-key" >/dev/null 2>&1 || true

echo "정리가 끝났습니다. AWS Budget은 비용 확인을 위해 남겨 두었습니다."
