# =============================================================================
# Agency Marketing OS — Render Production Dockerfile
# =============================================================================
#
# Project structure inside the container:
#   /workspace/          ← WORKDIR
#   /workspace/app/      ← FastAPI application package
#   /workspace/app/main.py   ← entry point
#   /workspace/app/core/     ← config, database, security
#
# Internal imports all use:  from app.xxx import yyy
# PYTHONPATH must point to /workspace so Python can find the app/ package.

FROM python:3.11-slim

# System dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq5 curl \
    && rm -rf /var/lib/apt/lists/*

# Python path — critical for all imports
ENV PYTHONPATH=/workspace
ENV PYTHONUNBUFFERED=1

# Non-root user
RUN groupadd -r appuser && useradd -r -g appuser -d /workspace -s /sbin/nologin appuser

WORKDIR /workspace

# Dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Application code
COPY . .

# Ensure proper ownership
RUN mkdir -p /workspace/logs && chown -R appuser:appuser /workspace
USER appuser

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2", "--proxy-headers", "--forwarded-allow-ips", "*", "--timeout-keep-alive", "30"]
