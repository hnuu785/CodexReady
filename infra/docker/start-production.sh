#!/bin/sh
set -eu

/opt/backend-venv/bin/python -m uvicorn backend.app.main:app \
  --host 127.0.0.1 \
  --port 8000 &
api_pid=$!

stop_api() {
  kill "$api_pid" 2>/dev/null || true
  wait "$api_pid" 2>/dev/null || true
}

trap stop_api EXIT INT TERM
node server.js
