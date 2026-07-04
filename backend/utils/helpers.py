import base64
import re
import urllib.parse

def slugify(text: str) -> str:
    """
    Simplifies text into a URL slug.
    """
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_-]+', '-', text)
    return text

def get_qr_code_url(url: str) -> str:
    """
    Generates a QR code image URL for a given target link.
    """
    encoded_url = urllib.parse.quote_plus(url)
    return f"https://api.qrserver.com/v1/create-qr-code/?size=250x250&data={encoded_url}"

def get_mock_qr_base64() -> str:
    """
    Returns a small base64 pixel representation of a QR code as a placeholder.
    """
    # A tiny 1x1 transparent dot or simple placeholder
    return "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
