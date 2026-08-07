import logging
import traceback
import requests
from fastapi import Request
from backend.config import settings

logger = logging.getLogger("PortfolioAI.n8n")

def report_error_to_n8n(exc: Exception, request: Request = None, context: str = "Unhandled Exception") -> None:
    """
    Sends error details to the configured n8n webhook URL.
    This runs synchronously but is wrapped in a try/except with a low timeout to prevent blocking.
    """
    url = getattr(settings, "N8N_WEBHOOK_URL", None)
    if not url:
        return

    # Extract traceback
    tb_str = "".join(traceback.format_exception(type(exc), exc, exc.__traceback__))

    payload = {
        "event": "error",
        "context": context,
        "error": {
            "type": exc.__class__.__name__,
            "message": str(exc),
            "traceback": tb_str
        }
    }

    if request:
        # Sanitize headers (exclude sensitive auth/cookie headers)
        sanitized_headers = {}
        for k, v in request.headers.items():
            if k.lower() not in ("authorization", "cookie", "set-cookie", "x-api-key"):
                sanitized_headers[k] = v

        # Resolve client IP
        forwarded = request.headers.get("x-forwarded-for")
        client_ip = forwarded.split(",")[0].strip() if forwarded else (request.client.host if request.client else "unknown")

        payload["request"] = {
            "method": request.method,
            "url": str(request.url),
            "headers": sanitized_headers,
            "client_ip": client_ip,
            "query_params": dict(request.query_params)
        }

    try:
        # Send to n8n webhook with a short timeout to prevent hanging the request lifecycle
        response = requests.post(url, json=payload, timeout=2.0)
        response.raise_for_status()
        logger.info("Successfully sent error report to n8n webhook")
    except Exception as n8n_exc:
        logger.error("Failed to send error report to n8n webhook: %s", n8n_exc)
