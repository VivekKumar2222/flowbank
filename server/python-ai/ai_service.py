from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import pandas as pd
from prophet import Prophet
import numpy as np
from datetime import datetime, timedelta
import warnings
warnings.filterwarnings("ignore")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Models ───────────────────────────────────────────────────────────────────

class Transaction(BaseModel):
    date: str        # ISO date string
    amount: float    # positive = debit (money out), negative = credit (money in)
    category: Optional[str] = "Other"
    name: Optional[str] = "Unknown"

class ForecastRequest(BaseModel):
    transactions: List[Transaction]
    forecastDays: Optional[int] = 30

class HealthRequest(BaseModel):
    transactions: List[Transaction]
    monthlyIncome: Optional[float] = 0
    currentBalance: Optional[float] = 0
    goals: Optional[List[dict]] = []

# ─── Spending Forecast ────────────────────────────────────────────────────────

@app.post("/ai/forecast")
async def spending_forecast(req: ForecastRequest):
    # Only debit (spending) transactions
    debits = [t for t in req.transactions if t.amount > 0]

    if len(debits) < 5:
        return {"error": "Not enough transaction data for forecast", "minRequired": 5}

    # Build daily spending dataframe
    df = pd.DataFrame([{"ds": t.date[:10], "y": t.amount} for t in debits])
    df["ds"] = pd.to_datetime(df["ds"])
    daily = df.groupby("ds")["y"].sum().reset_index()

    # Fill missing days with 0
    date_range = pd.date_range(daily["ds"].min(), daily["ds"].max(), freq="D")
    daily = daily.set_index("ds").reindex(date_range, fill_value=0).reset_index()
    daily.columns = ["ds", "y"]

    # Prophet model
    model = Prophet(
        yearly_seasonality=False,
        weekly_seasonality=True,
        daily_seasonality=False,
        seasonality_mode="additive",
        interval_width=0.80,
    )
    model.fit(daily)

    future = model.make_future_dataframe(periods=req.forecastDays)
    forecast = model.predict(future)

    # Next N days predictions
    future_only = forecast[forecast["ds"] > daily["ds"].max()].head(req.forecastDays)
    predictions = [
        {
            "date": row["ds"].strftime("%Y-%m-%d"),
            "predicted": max(0, round(row["yhat"], 2)),
            "lower": max(0, round(row["yhat_lower"], 2)),
            "upper": max(0, round(row["yhat_upper"], 2)),
        }
        for _, row in future_only.iterrows()
    ]

    # Weekly pattern (0=Mon ... 6=Sun)
    df_debits = pd.DataFrame([{"ds": pd.to_datetime(t.date[:10]), "y": t.amount} for t in debits])
    df_debits["weekday"] = df_debits["ds"].dt.dayofweek
    weekly = df_debits.groupby("weekday")["y"].mean().reset_index()
    day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    weekly_pattern = [
        {"day": day_names[int(r["weekday"])], "avgSpend": round(r["y"], 2)}
        for _, r in weekly.iterrows()
    ]

    # Week of month pattern
    df_debits["weekOfMonth"] = df_debits["ds"].apply(lambda d: (d.day - 1) // 7 + 1)
    week_of_month = df_debits.groupby("weekOfMonth")["y"].mean().reset_index()
    wom_pattern = [
        {"week": f"Week {int(r['weekOfMonth'])}", "avgSpend": round(r["y"], 2)}
        for _, r in week_of_month.iterrows()
    ]

    # Category breakdown
    df_cat = pd.DataFrame([{"category": t.category or "Other", "amount": t.amount} for t in debits])
    cat_breakdown = df_cat.groupby("category")["amount"].sum().reset_index()
    cat_breakdown = cat_breakdown.sort_values("amount", ascending=False)
    total_spent = cat_breakdown["amount"].sum()
    categories = [
        {
            "category": r["category"],
            "total": round(r["amount"], 2),
            "percent": round((r["amount"] / total_spent) * 100, 1) if total_spent > 0 else 0,
        }
        for _, r in cat_breakdown.iterrows()
    ]

    # Summary stats
    avg_daily = round(daily["y"].mean(), 2)
    avg_monthly = round(avg_daily * 30, 2)
    peak_day = weekly_pattern[max(range(len(weekly_pattern)), key=lambda i: weekly_pattern[i]["avgSpend"])]["day"] if weekly_pattern else "N/A"
    forecast_total = round(sum(p["predicted"] for p in predictions), 2)

    return {
        "predictions": predictions,
        "weeklyPattern": weekly_pattern,
        "weekOfMonthPattern": wom_pattern,
        "categoryBreakdown": categories,
        "summary": {
            "avgDailySpend": avg_daily,
            "avgMonthlySpend": avg_monthly,
            "peakSpendingDay": peak_day,
            "forecastedSpendNextDays": forecast_total,
            "forecastDays": req.forecastDays,
        },
    }


# ─── Financial Health ─────────────────────────────────────────────────────────

@app.post("/ai/health")
async def financial_health(req: HealthRequest):
    debits = [t for t in req.transactions if t.amount > 0]
    credits = [t for t in req.transactions if t.amount < 0]

    if len(debits) < 5:
        return {
            "error": "Not enough data",
            "runway": None,
            "savingsRate": None,
            "predictions": [],
        }

    # Monthly spending average (last 3 months)
    df = pd.DataFrame([{"ds": pd.to_datetime(t.date[:10]), "y": t.amount} for t in debits])
    df["month"] = df["ds"].dt.to_period("M")
    monthly = df.groupby("month")["y"].sum().reset_index()
    last3 = monthly.tail(3)
    avg_monthly_spend = float(last3["y"].mean()) if not last3.empty else 0

    # Monthly income (use provided or estimate from credits)
    monthly_income = req.monthlyIncome
    if monthly_income <= 0 and credits:
        df_c = pd.DataFrame([{"ds": pd.to_datetime(t.date[:10]), "y": abs(t.amount)} for t in credits])
        df_c["month"] = df_c["ds"].dt.to_period("M")
        monthly_c = df_c.groupby("month")["y"].sum().reset_index()
        monthly_income = float(monthly_c.tail(3)["y"].mean()) if not monthly_c.empty else 0

    # Savings rate
    savings_rate = ((monthly_income - avg_monthly_spend) / monthly_income * 100) if monthly_income > 0 else 0
    monthly_savings = monthly_income - avg_monthly_spend

    # Runway: how long balance lasts if income stops
    runway_months = (req.currentBalance / avg_monthly_spend) if avg_monthly_spend > 0 else 0

    # Prophet forecast: balance over next 12 months
    balance_series = []
    bal = req.currentBalance
    for i in range(1, 13):
        bal = bal + monthly_income - avg_monthly_spend
        future_date = (datetime.now() + timedelta(days=30 * i)).strftime("%Y-%m-%d")
        balance_series.append({"month": i, "date": future_date, "projectedBalance": round(max(0, bal), 2)})

    # Goal time estimates
    goal_estimates = []
    for goal in (req.goals or []):
        target = float(goal.get("amount", 0))
        current = float(goal.get("currentSpend", 0))
        name = goal.get("goalName", "Goal")
        remaining = max(0, target - current)
        months_needed = (remaining / monthly_savings) if monthly_savings > 0 else None
        goal_estimates.append({
            "name": name,
            "remaining": round(remaining, 2),
            "monthsToAchieve": round(months_needed, 1) if months_needed is not None else None,
            "category": goal.get("category", ""),
        })

    # Health score (0-100)
    score = 50
    if savings_rate > 20: score += 20
    elif savings_rate > 10: score += 10
    elif savings_rate < 0: score -= 20
    if runway_months > 6: score += 20
    elif runway_months > 3: score += 10
    elif runway_months < 1: score -= 10
    if monthly_income > avg_monthly_spend: score += 10
    score = max(0, min(100, score))

    # Merchant frequency analysis — find repetitive spending places
    merchant_counts = {}
    merchant_totals = {}
    for t in debits:
        merchant = (t.name or '').strip()
        if merchant and merchant.lower() not in ('unknown', ''):
            merchant_counts[merchant] = merchant_counts.get(merchant, 0) + 1
            merchant_totals[merchant] = merchant_totals.get(merchant, 0) + t.amount

    repetitive = [
        (name, merchant_counts[name], merchant_totals[name])
        for name in merchant_counts if merchant_counts[name] >= 3
    ]
    repetitive.sort(key=lambda x: x[2], reverse=True)

    cost_cutting = []
    for merchant, visits, total in repetitive[:5]:
        avg_per_visit = total / visits
        cost_cutting.append({
            "merchant": merchant,
            "visits": visits,
            "totalSpent": round(total, 2),
            "avgPerVisit": round(avg_per_visit, 2),
        })

    return {
        "healthScore": round(score),
        "avgMonthlySpend": round(avg_monthly_spend, 2),
        "monthlyIncome": round(monthly_income, 2),
        "monthlySavings": round(monthly_savings, 2),
        "savingsRate": round(savings_rate, 1),
        "runwayMonths": round(runway_months, 1),
        "balanceForecast": balance_series,
        "goalEstimates": goal_estimates,
        "costCuttingSuggestions": cost_cutting,
    }
