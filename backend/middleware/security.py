import time
import logging
from fastapi import Request, Response, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger("PortfolioAI.Middleware")
logging.basicConfig(level=logging.INFO)

# A simple in-memory rate limiter using client IP
RATE_LIMIT_DURATION = 60  # seconds
MAX_REQUESTS_PER_MINUTE = 60
request_counts = {}  # IP -> List of timestamps

class RateLimitingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        client_ip = request.client.host
        now = time.time()
        
        # Clean up old timestamps
        if client_ip in request_counts:
            request_counts[client_ip] = [t for t in request_counts[client_ip] if now - t < RATE_LIMIT_DURATION]
        else:
            request_counts[client_ip] = []
            
        # Check limit
        if len(request_counts[client_ip]) >= MAX_REQUESTS_PER_MINUTE:
            logger.warning(f"Rate limit exceeded for client: {client_ip}")
            return Response(
                content="Rate limit exceeded. Please try again later.",
                status_code=429
            )
            
        # Add current timestamp
        request_counts[client_ip].append(now)
        
        # Request timing logger
        start_time = time.time()
        try:
            response = await call_next(request)
            duration = time.time() - start_time
            logger.info(f"{request.method} {request.url.path} - {response.status_code} ({duration:.2f}s)")
            return response
        except Exception as e:
            logger.error(f"Unhandled server error: {e}", exc_info=True)
            return Response(
                content="Internal Server Error",
                status_code=500
            )
