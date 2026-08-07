# syntax=docker/dockerfile:1

# ---- Build stage: install Python dependencies ----
FROM python:3.11-slim AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- Runtime stage: minimal production image ----
FROM python:3.11-slim AS runtime

WORKDIR /app

# System libraries required by Pillow and ReportLab
RUN apt-get update && apt-get install -y --no-install-recommends \
    libjpeg62-turbo \
    zlib1g \
    libfreetype6 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system appgroup \
    && useradd --system --gid appgroup --create-home appuser

COPY --from=builder /install /usr/local
COPY backend ./backend
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && mkdir -p \
        /app/backend/storage/resumes \
        /app/backend/storage/portfolios \
        /app/backend/storage/templates \
        /app/backend/storage/profiles \
    && chmod -R u+rwX /app/backend/storage \
    && chown -R appuser:appgroup /app

ENV PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HOST=0.0.0.0 \
    PORT=8000

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD python -c "import os, urllib.request; urllib.request.urlopen(f'http://127.0.0.1:{os.environ.get(\"PORT\", \"8000\")}/health')" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
