#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-ap-northeast-2}"
APP_NAME="${APP_NAME:-codex-ready}"
BUDGET_NAME="${BUDGET_NAME:-${APP_NAME}-credit-guard}"
BUDGET_AMOUNT="${BUDGET_AMOUNT:-20}"

if ! command -v aws >/dev/null 2>&1; then
  echo "AWS CLI가 필요합니다." >&2
  exit 1
fi

if [[ -z "${BUDGET_EMAIL:-}" ]]; then
  echo "알림 이메일을 지정해 주세요: BUDGET_EMAIL=you@example.com npm run budget:aws" >&2
  exit 1
fi

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

if aws budgets describe-budget \
  --account-id "$ACCOUNT_ID" \
  --budget-name "$BUDGET_NAME" >/dev/null 2>&1; then
  echo "이미 같은 이름의 예산이 있습니다: ${BUDGET_NAME}"
  exit 0
fi

echo "월 ${BUDGET_AMOUNT}달러 예산과 50%, 80%, 100% 알림을 만듭니다."
aws budgets create-budget \
  --account-id "$ACCOUNT_ID" \
  --budget "{\"BudgetName\":\"${BUDGET_NAME}\",\"BudgetLimit\":{\"Amount\":\"${BUDGET_AMOUNT}\",\"Unit\":\"USD\"},\"TimeUnit\":\"MONTHLY\",\"BudgetType\":\"COST\",\"CostTypes\":{\"IncludeCredit\":false,\"IncludeDiscount\":true,\"IncludeOtherSubscription\":true,\"IncludeRecurring\":true,\"IncludeRefund\":false,\"IncludeSubscription\":true,\"IncludeSupport\":true,\"IncludeTax\":true,\"IncludeUpfront\":true,\"UseAmortized\":false,\"UseBlended\":false}}" \
  --notifications-with-subscribers "[{\"Notification\":{\"NotificationType\":\"ACTUAL\",\"ComparisonOperator\":\"GREATER_THAN\",\"Threshold\":50,\"ThresholdType\":\"PERCENTAGE\"},\"Subscribers\":[{\"SubscriptionType\":\"EMAIL\",\"Address\":\"${BUDGET_EMAIL}\"}]},{\"Notification\":{\"NotificationType\":\"ACTUAL\",\"ComparisonOperator\":\"GREATER_THAN\",\"Threshold\":80,\"ThresholdType\":\"PERCENTAGE\"},\"Subscribers\":[{\"SubscriptionType\":\"EMAIL\",\"Address\":\"${BUDGET_EMAIL}\"}]},{\"Notification\":{\"NotificationType\":\"FORECASTED\",\"ComparisonOperator\":\"GREATER_THAN\",\"Threshold\":100,\"ThresholdType\":\"PERCENTAGE\"},\"Subscribers\":[{\"SubscriptionType\":\"EMAIL\",\"Address\":\"${BUDGET_EMAIL}\"}]}]" \
  --region "$AWS_REGION"

echo "예산 알림을 만들었습니다. 비용 데이터와 알림에는 지연이 있을 수 있습니다."
