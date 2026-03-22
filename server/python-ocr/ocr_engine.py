import requests
from PIL import Image
from io import BytesIO
import pytesseract

# Set the tesseract executable path
pytesseract.pytesseract.tesseract_cmd = r"C:\Users\syeda\AppData\Local\Programs\Tesseract-OCR\tesseract.exe"


def run_ocr(image_url: str):
    headers = {"User-Agent": "Mozilla/5.0"}
    response = requests.get(image_url, headers=headers, timeout=10)

    if response.status_code != 200:
        raise ValueError("Failed to download image")

    content_type = response.headers.get("Content-Type", "")
    if not content_type.startswith("image/"):
        raise ValueError(f"URL did not return an image. Got: {content_type}")

    # Open image
    try:
        image = Image.open(BytesIO(response.content)).convert("RGB")
    except Exception:
        raise ValueError("Downloaded file is not a valid image")

    # Run OCR
    raw_text = pytesseract.image_to_string(image)

    return raw_text
