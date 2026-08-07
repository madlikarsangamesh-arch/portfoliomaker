import logging
import time

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from backend.utils.n8n import report_error_to_n8n

logger = logging.getLogger("PortfolioAI.Middleware")

# A simple in-memory rate limiter using client IP
RATE_LIMIT_DURATION = 60  # seconds
MAX_REQUESTS_PER_MINUTE = 60
request_counts = {}  # IP -> List of timestamps


def _client_ip(request: Request) -> str:
    """Resolve client IP, honoring Railway/proxy X-Forwarded-For headers."""
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    if request.client:
        return request.client.host
    return "unknown"


class RateLimitingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        client_ip = _client_ip(request)
        now = time.time()

        # Clean up old timestamps
        if client_ip in request_counts:
            request_counts[client_ip] = [
                t for t in request_counts[client_ip] if now - t < RATE_LIMIT_DURATION
            ]
        else:
            request_counts[client_ip] = []

        # Check limit
        if len(request_counts[client_ip]) >= MAX_REQUESTS_PER_MINUTE:
            logger.warning(
                "Rate limit exceeded | ip=%s | %s %s",
                client_ip,
                request.method,
                request.url.path,
            )
            return Response(
                content="Rate limit exceeded. Please try again later.",
                status_code=429,
            )

        request_counts[client_ip].append(now)

        logger.info(
            "Incoming request | ip=%s | %s %s",
            client_ip,
            request.method,
            request.url.path,
        )

        start_time = time.time()
        try:
            response = await call_next(request)
            duration = time.time() - start_time
            logger.info(
                "Completed request | ip=%s | %s %s | status=%s | duration=%.2fs",
                client_ip,
                request.method,
                request.url.path,
                response.status_code,
                duration,
            )
            return response
        except Exception as exc:
            duration = time.time() - start_time
            logger.error(
                "Request failed | ip=%s | %s %s | duration=%.2fs | error=%s",
                client_ip,
                request.method,
                request.url.path,
                duration,
                exc,
                exc_info=True,
            )
            try:
                report_error_to_n8n(exc, request=request, context="Middleware Request Failure")
            except Exception as n8n_err:
                logger.error("Failed executing n8n reporting block: %s", n8n_err)
            return Response(content="Internal Server Error", status_code=500)
