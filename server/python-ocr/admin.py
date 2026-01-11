from fastapi import FastAPI
from pydantic import BaseModel
from ocr_engine import run_ocr
from normalizer import normalize_receipt

app = FastAPI()

class OCRRequest(BaseModel):
    image_url: str

@app.post("/ocr")
async def ocr_endpoint(data: OCRRequest):
    raw_text = run_ocr(data.image_url)
    result = normalize_receipt(raw_text)
    return {"raw_text": result}
