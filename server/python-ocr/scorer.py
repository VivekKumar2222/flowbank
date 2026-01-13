from datetime import datetime
from rapidfuzz import fuzz

def score_name(ocr_name, expected_name):
    if not ocr_name or not expected_name:
        return 0

    score = fuzz.partial_ratio(
        ocr_name.lower(),
        expected_name.lower()
    )

    return 25 if score >= 70 else int((score / 70) * 25)

def score_amount(ocr_amount, expected_amount):
    try:
        ocr = float(ocr_amount.replace(",", "").split()[0])
        expected = float(expected_amount)
    except:
        return 0

    diff = abs(ocr - expected)
    percent_diff = diff / expected

    if percent_diff <= 0.02:
        return 25
    elif percent_diff <= 0.05:
        return 15
    elif percent_diff <= 0.1:
        return 5
    return 0

def score_date(ocr_date, expected_date):
    try:
        ocr = datetime.strptime(ocr_date, "%d/%m/%Y")
        expected = datetime.strptime(expected_date, "%Y-%m-%d")
    except:
        return 0

    days_diff = abs((ocr - expected).days)

    if days_diff == 0:
        return 25
    elif days_diff == 1:
        return 20
    elif days_diff <= 3:
        return 10
    elif days_diff <= 7:
        return 5
    return 0
