#!/bin/sh
set -e

exec uvicorn backend.main:app \
    --host "${HOST:-0.0.0.0}" \
    --port "${PORT:-8000}" \
    --workers "${WEB_CONCURRENCY:-1}" \
    --proxy-headers \
    --forwarded-allow-ips='*' \
    --log-level "${LOG_LEVEL:-info}"
