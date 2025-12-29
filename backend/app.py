from fastapi import FastAPI
import joblib
import json
import numpy as np
import pandas as pd
from pydantic import BaseModel
from functools import lru_cache


RECOMMENDATION_CSV = "data/smartphone_recommendation_clean.csv"

df_reco = pd.read_csv(RECOMMENDATION_CSV)

def price_category_from_idr(price):
    if price <= 2_000_000:
        return "≤ 2 juta"
    elif price <= 4_000_000:
        return "2 – 4 juta"
    elif price <= 6_000_000:
        return "4 – 6 juta"
    else:
        return "≥ 6 juta"

df_reco["price_category"] = df_reco["price_idr"].apply(price_category_from_idr)


app = FastAPI(title="Smartphone Price Predictor")

# Load model
model = joblib.load("data/rf_price_model.pkl")

# Load feature order
with open("feature_columns.json", "r") as f:
    FEATURES = json.load(f)

PRICE_LABELS = {
    0: "Murah (Entry-level)",
    1: "Menengah",
    2: "Menengah Atas",
    3: "Mahal (Flagship)"
}

PRICE_ESTIMATE = {
    0: "≤ 2 juta",
    1: "2 – 4 juta",
    2: "4 – 6 juta",
    3: "≥ 6 juta"
}

PRICE_RANGE_MAP = {
    0: {
        "label": "Murah (Entry-level)",
        "category": "≤ 2 juta",
        "min_price": 0,
        "max_price": 2_000_000
    },
    1: {
        "label": "Menengah",
        "category": "2 – 4 juta",
        "min_price": 2_000_000,
        "max_price": 4_000_000
    },
    2: {
        "label": "Menengah Atas",
        "category": "4 – 6 juta",
        "min_price": 4_000_000,
        "max_price": 6_000_000
    },
    3: {
        "label": "Mahal (Flagship)",
        "category": "≥ 6 juta",
        "min_price": 6_000_000,
        "max_price": None
    }
}

FEATURE_COLS = [
    "ram_gb",
    "battery_mah",
    "rear_camera_mp",
    "front_camera_mp",
    "screen_size_inch",
    "price_idr"
]

class RecommendationRequest(BaseModel):
    price_range: int
    ram_gb: float
    battery_mah: float
    rear_camera_mp: float
    front_camera_mp: float
    screen_size_inch: float

def filter_by_price_range(df, min_price=None, max_price=None):
    result = df.copy()
    if min_price is not None:
        result = result[result["price_idr"] >= min_price]
    if max_price is not None:
        result = result[result["price_idr"] <= max_price]
    return result

def cosine_similarity(a, b):
    if np.linalg.norm(a) == 0 or np.linalg.norm(b) == 0:
        return 0

    a = a / np.linalg.norm(a)
    b = b / np.linalg.norm(b)
    return np.dot(a, b)


def recommend_phones(input_spec, df, top_n=5):
    features = df[FEATURE_COLS].values
    scores = []

    for i, row in enumerate(features):
        score = cosine_similarity(input_spec, row)
        scores.append((i, score))

    scores = sorted(scores, key=lambda x: x[1], reverse=True)
    top_indices = [i for i, _ in scores[:top_n]]

    return df.iloc[top_indices][
        ["brand", "model", "price_idr", "price_category"]
    ]

def price_score(target_price, actual_price):
    return 1 - abs(actual_price - target_price) / max(target_price, actual_price)

def recommend_phones_weighted(input_spec, df, price_anchor, top_n=5):
    features = df[FEATURE_COLS].values
    scores = []

    for i, row in enumerate(features):
        spec_sim = cosine_similarity(input_spec[:-1], row[:-1])
        price_sim = price_score(price_anchor, row[-1])

        final_score = (0.7 * spec_sim) + (0.3 * price_sim)
        scores.append((i, final_score))

    scores = sorted(scores, key=lambda x: x[1], reverse=True)
    top_indices = [i for i, _ in scores[:top_n]]

    return df.iloc[top_indices][
        ["brand", "model", "price_idr", "price_category"]
    ]

def cache_key(req):
    return (
        req.price_range,
        round(req.ram_gb, 1),
        round(req.battery_mah, 0),
        round(req.rear_camera_mp, 0),
        round(req.front_camera_mp, 0),
        round(req.screen_size_inch, 1),
    )

@lru_cache(maxsize=128)
def cached_recommend(key):
    price_range, ram, battery, rear, front, screen = key
    mapping = PRICE_RANGE_MAP[price_range]

    filtered_df = filter_by_price_range(
        df_reco,
        mapping["min_price"],
        mapping["max_price"]
    )

    price_anchor = filtered_df["price_idr"].median()

    input_spec = np.array([
        ram,
        battery,
        rear,
        front,
        screen,
        price_anchor
    ])

    return recommend_phones_weighted(
        input_spec,
        filtered_df,
        price_anchor
    ).to_dict(orient="records")

@app.post("/predict")
def predict_price(spec: dict):
    try:
        # susun input sesuai urutan feature
        input_data = [[spec[f] for f in FEATURES]]
        pred = int(model.predict(input_data)[0])

        return {
            "price_range": pred,
            "label": PRICE_LABELS[pred],
            "price_estimate": PRICE_ESTIMATE[pred]
        }

    except KeyError as e:
        return {
            "error": f"Missing feature: {str(e)}"
        }

@app.post("/recommend")
def recommend(req: RecommendationRequest):
    mapping = PRICE_RANGE_MAP.get(req.price_range)
    if not mapping:
        return {"error": "Invalid price range"}

    filtered_df = filter_by_price_range(
        df_reco,
        min_price=mapping["min_price"],
        max_price=mapping["max_price"]
    )

    price_anchor = filtered_df["price_idr"].median()

    input_spec = np.array([
        req.ram_gb,
        req.battery_mah,
        req.rear_camera_mp,
        req.front_camera_mp,
        req.screen_size_inch,
        price_anchor
    ])

    key = cache_key(req)
    recommendations = cached_recommend(key)

    return {
    "price_label": mapping["label"],
    "price_category": mapping["category"],
    "recommendations": recommendations
    }

@app.post("/predict-and-recommend")
def predict_and_recommend(spec: dict):
    input_data = [[spec[f] for f in FEATURES]]
    prediction = int(model.predict(input_data)[0])

    mapping = PRICE_RANGE_MAP[prediction]

    req = RecommendationRequest(
        price_range=prediction,
        ram_gb=spec["ram"],
        battery_mah=spec["battery_power"],
        rear_camera_mp=spec["pc"],
        front_camera_mp=spec["fc"],
        screen_size_inch=6.5
    )

    recommendations = cached_recommend(cache_key(req))

    return {
        "prediction": prediction,
        "price_label": mapping["label"],
        "price_category": mapping["category"],
        "recommendations": recommendations
    }
