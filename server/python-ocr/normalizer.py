# server/python-ocr/normalizer.py
import re
from datetime import datetime

def normalize_receipt(text: str):
    """
    Extracts date, receiver, sender, and amount from OCR text.
    Returns a dictionary with structured data.
    """
    # Initialize result
    data = {
        "date": None,
        "receiver": None,
        "sender": None,
        "amount": None
    }

    # 1️⃣ Extract date (formats: 26 March 2019, 26/03/2019, 03-26-2019)
    date_patterns = [
        r"\b\d{1,2}\s\w+\s\d{4}\b",      # 26 March 2019
        r"\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b"  # 26/03/2019 or 03-26-2019
    ]
    for pattern in date_patterns:
        match = re.search(pattern, text)
        if match:
            data["date"] = match.group()
            break

    # 2️⃣ Extract amount (look for USD, EUR, numbers with commas/points)
    amount_pattern = r"(?:Amount|Total|JUMLAH)\s*([0-9.,]+\s*(?:USD|EUR|₹|INR)?)"
    match = re.search(amount_pattern, text, re.IGNORECASE)
    if match:
        data["amount"] = match.group(1).strip()

    # 3️⃣ Extract receiver (look for "Paid by", "Receiver", "To")
    # Extract receiver
    receiver_pattern = r"(?:Paid by|Receiver|To)\s*\n([A-Za-z0-9 &.-]+)"
    match = re.search(receiver_pattern, text, re.IGNORECASE)
    if match:
        data["receiver"] = match.group(1).strip()


    # 4️⃣ Extract sender (look for "From", "Sender", "Paid from")
    sender_pattern = r"(?:From|Sender|Paid from)\s*\n?([\w\s&@.]+)"
    match = re.search(sender_pattern, text, re.IGNORECASE)
    if match:
        data["sender"] = match.group(1).strip()

    return data
