import re

def extract_amount(text):
    match = re.search(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)', text)
    if match:
        return float(match.group(1).replace(",", ""))
    return None

def extract_date(text):
    match = re.search(r'\d{2}[/-]\d{2}[/-]\d{4}', text)
    if match:
        return match.group()
    return None

def clean_name(text):
    text = re.sub(r'(paid to|paid by|receiver|sender|from|beneficiary)', '', text, flags=re.I)
    return text.strip()
