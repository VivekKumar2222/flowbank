# server/python-ocr/normalizer.py
import re

def normalize_receipt(text: str):
    """
    Extracts date, receiver, sender, and amount from OCR text.
    Returns a dictionary with structured data.
    """

    extracted_date = None
    extracted_receiver = None
    extracted_sender = None
    extracted_amount = None

    # 1️⃣ Extract date
    date_patterns = [
        r"\b\d{1,2}\s\w+\s\d{4}\b",            # 26 March 2019
        r"\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b"   # 26/03/2019 or 03-26-2019
    ]

    for pattern in date_patterns:
        match = re.search(pattern, text)
        if match:
            extracted_date = match.group()
            break

    # 2️⃣ Extract amount
    amount_pattern = r"(?:Amount|Total|JUMLAH)\s*([0-9.,]+\s*(?:USD|EUR|₹|INR)?)"
    match = re.search(amount_pattern, text, re.IGNORECASE)
    if match:
        extracted_amount = match.group(1).strip()

    # 3️⃣ Extract receiver
    receiver_pattern = r"(?:Paid by|Receiver|To|Paid to|Sent to)\s*\n?([A-Za-z0-9 &.-]+)"
    match = re.search(receiver_pattern, text, re.IGNORECASE)
    if match:
        extracted_receiver = match.group(1).strip()

    # 4️⃣ Extract sender
    sender_pattern = r"(?:From|Sender|Paid from|Sent by)\s*\n?([A-Za-z0-9 &@.-]+)"
    match = re.search(sender_pattern, text, re.IGNORECASE)
    if match:
        extracted_sender = match.group(1).strip()

    # ✅ FINAL RETURN (THIS IS WHAT YOU WANT)
    return {
        "date": extracted_date,
        "receiver": extracted_receiver,
        "sender": extracted_sender,
        "amount": extracted_amount,
        "raw_text": text
    }
