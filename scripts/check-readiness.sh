#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0

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
check_command docker

echo ""
echo "AWS 배포 도구"
check_command aws

echo ""
echo "핵심 파일"
check_file package.json
check_file Dockerfile
check_file infra/aws/ecs-express.yml
check_file infra/runpod/Dockerfile
check_file docs/CODEX_BUILD_LOG.md

echo ""
if [[ -n "${RUNPOD_API_KEY:-}" && -n "${RUNPOD_ENDPOINT_ID:-}" ]]; then
  echo "✓ RunPod 환경 변수"
else
  echo "△ RunPod 환경 변수 미설정 (GPU를 쓰지 않으면 정상)"
fi

if [[ "$FAILED" -eq 0 ]]; then
  echo ""
  echo "준비 상태: 통과"
else
  echo ""
  echo "준비 상태: 위 항목을 확인하세요."
fi

exit "$FAILED"
