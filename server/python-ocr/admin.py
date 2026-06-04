# =============================================================================
# ARCHIVED — No longer active in production.
# Receipt verification is now handled by the Groq Vision pipeline in
# server/routes/collabRoutes.js (verifyReceiptWithVision).
# This file is kept for academic reference only.
# =============================================================================

from fastapi import FastAPI
from pydantic import BaseModel
from ocr_engine import run_ocr
from normalizer import normalize_receipt
from scorer import score_name, score_amount, score_date

app = FastAPI()

class OCRVerifyRequest(BaseModel):
    image_url: str
    sender_name: str
    receiver_name: str
    amount: float
    date: str  # ISO format

@app.post("/ocr/verify")
async def ocr_verify(data: OCRVerifyRequest):
    raw_text = run_ocr(data.image_url)
    extracted = normalize_receipt(raw_text)

    scores = {
        "sender": score_name(extracted["sender"], data.sender_name),
        "receiver": score_name(extracted["receiver"], data.receiver_name),
        "amount": score_amount(extracted["amount"], data.amount),
        "date": score_date(extracted["date"], data.date),
    }

    total = sum(scores.values())

    return {
        "extracted": extracted,
        "scores": scores,
        "totalScore": total,
        "verified": total >= 70
    }
