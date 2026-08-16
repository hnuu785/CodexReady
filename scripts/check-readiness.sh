#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0

if [[ -f "$ROOT_DIR/.env.local" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env.local"
  set +a
fi

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "✓ $1"
  else
    echo "✗ $1 설치 필요"
    FAILED=1
  fi
}

check_file() {
  if [[ -f "$ROOT_DIR/$1" ]]; then
    echo "✓ $1"
  else
    echo "✗ $1 없음"
    FAILED=1
  fi
}

echo "로컬 도구"
check_command node
check_command npm
check_command git
check_command python3
check_command docker

echo ""
echo "AWS 배포 도구"
check_command aws

echo ""
echo "핵심 파일"
check_file package.json
check_file frontend/package.json
check_file frontend/package-lock.json
check_file frontend/next.config.ts
check_file frontend/app/page.tsx
check_file compose.yml
check_file frontend/Dockerfile
check_file backend/Dockerfile
check_file backend/app/main.py
check_file infra/docker/Dockerfile.production
check_file infra/docker/start-production.sh
check_file infra/aws/ecs-express.yml
check_file infra/runpod/Dockerfile
check_file docs/CODEX_BUILD_LOG.md

echo ""
if [[ "${INFERENCE_MODE:-mock}" != "runpod" ]]; then
  echo "✓ 추론 모드: ${INFERENCE_MODE:-mock} (RunPod 설정 불필요)"
elif [[ -n "${RUNPOD_API_KEY:-}" && -n "${RUNPOD_ENDPOINT_ID:-}" ]]; then
  echo "✓ RunPod 환경 변수"
else
  echo "✗ runpod 모드에 RUNPOD_API_KEY와 RUNPOD_ENDPOINT_ID 필요"
  FAILED=1
fi

if [[ "$FAILED" -eq 0 ]]; then
  echo ""
  echo "준비 상태: 통과"
else
  echo ""
  echo "준비 상태: 위 항목을 확인하세요."
fi

exit "$FAILED"
