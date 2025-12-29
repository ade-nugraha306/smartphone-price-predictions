from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import json
import numpy as np
import pandas as pd
from functools import lru_cache

# ======================================================
# App Init
# ======================================================

app = FastAPI(
    title="Smartphone Price Segment API",
    description="ML-based price segment classification with recommendation system",
    version="1.0.0"
)

# ======================================================
# Load Model & Config
# ======================================================

MODEL_PATH = "data/random_forest_price_segment.pkl"
RECO_CSV_PATH = "data/smartphone_recommendation_clean.csv"
FEATURE_PATH = "feature_columns.json"

model = joblib.load(MODEL_PATH)

with open(FEATURE_PATH, "r") as f:
    FEATURES = json.load(f)

df_reco = pd.read_csv(RECO_CSV_PATH)

# ======================================================
# Price Segment Definition (JUJUR & KONSISTEN)
# ======================================================

PRICE_SEGMENT = {
    0: {
        "label": "Low-end",
        "category": "Entry-level"
    },
    1: {
        "label": "Lower-mid",
        "category": "Menengah"
    },
    2: {
        "label": "Upper-mid",
        "category": "Menengah Atas"
    },
    3: {
        "label": "High-end",
        "category": "Flagship"
    }
}

# ======================================================
# Safety Gate (HARUS ADA)
# ======================================================

def low_end_gate(spec: dict):
    """
    Mengunci smartphone spek sangat rendah agar tidak salah segment.
    Konsisten dengan notebook training.
    """
    if spec["ram"] <= 2048 and spec["pixel_count"] < (720 * 1280):
        return 0
    return None

# ======================================================
# Recommendation Utilities (NON-ML)
# ======================================================

RECO_FEATURES = [
    "ram_gb",
    "battery_mah",
    "rear_camera_mp",
    "front_camera_mp",
    "screen_size_inch",
    "price_idr"
]

def cosine_similarity(a, b):
    if np.linalg.norm(a) == 0 or np.linalg.norm(b) == 0:
        return 0.0
    a = a / np.linalg.norm(a)
    b = b / np.linalg.norm(b)
    return float(np.dot(a, b))

def price_score(target, actual):
    return 1 - abs(actual - target) / max(target, actual)

def recommend_phones_weighted(input_spec, df, price_anchor, top_n=5):
    features = df[RECO_FEATURES].values
    scores = []

    for idx, row in enumerate(features):
        spec_sim = cosine_similarity(input_spec[:-1], row[:-1])
        price_sim = price_score(price_anchor, row[-1])
        final_score = (0.7 * spec_sim) + (0.3 * price_sim)
        scores.append((idx, final_score))

    scores.sort(key=lambda x: x[1], reverse=True)
    top_idx = [i for i, _ in scores[:top_n]]

    return df.iloc[top_idx][
        ["brand", "model", "price_idr"]
    ]

# ======================================================
# Request Models
# ======================================================

class PredictRequest(BaseModel):
    battery_power: float
    blue: int
    dual_sim: int
    fc: float
    four_g: int
    int_memory: float
    m_dep: float
    mobile_wt: float
    pc: float
    ram: float
    sc_h: float
    sc_w: float
    talk_time: float
    three_g: int
    touch_screen: int
    wifi: int
    pixel_count: float

class RecommendRequest(BaseModel):
    price_segment: int
    ram_gb: float
    battery_mah: float
    rear_camera_mp: float
    front_camera_mp: float
    screen_size_inch: float

# ======================================================
# Cache Recommendation
# ======================================================

def cache_key(req: RecommendRequest):
    return (
        req.price_segment,
        round(req.ram_gb, 1),
        round(req.battery_mah, 0),
        round(req.rear_camera_mp, 0),
        round(req.front_camera_mp, 0),
        round(req.screen_size_inch, 1),
    )

@lru_cache(maxsize=128)
def cached_recommend(key):
    segment, ram, battery, rear, front, screen = key

    # filter recommendation dataset by segment (heuristic)
    df = df_reco.copy()

    price_anchor = df["price_idr"].median()

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
        df,
        price_anchor
    ).to_dict(orient="records")

# ======================================================
# API ENDPOINTS
# ======================================================

@app.post("/predict")
def predict_price(req: PredictRequest):
    spec = req.dict()

    forced = low_end_gate(spec)
    if forced is not None:
        pred = forced
    else:
        input_data = [[spec[f] for f in FEATURES]]
        pred = int(model.predict(input_data)[0])

    return {
        "price_segment": pred,
        "label": PRICE_SEGMENT[pred]["label"],
        "category": PRICE_SEGMENT[pred]["category"]
    }

@app.post("/recommend")
def recommend(req: RecommendRequest):
    if req.price_segment not in PRICE_SEGMENT:
        return {"error": "Invalid price segment"}

    key = cache_key(req)
    recommendations = cached_recommend(key)

    return {
        "price_segment": req.price_segment,
        "label": PRICE_SEGMENT[req.price_segment]["label"],
        "recommendations": recommendations
    }

@app.post("/predict-and-recommend")
def predict_and_recommend(req: PredictRequest):
    spec = req.dict()

    forced = low_end_gate(spec)
    if forced is not None:
        pred = forced
    else:
        input_data = [[spec[f] for f in FEATURES]]
        pred = int(model.predict(input_data)[0])

    # normalisasi untuk rekomendasi
    ram_gb = spec["ram"] / 1024
    battery = spec["battery_power"]

    reco_req = RecommendRequest(
        price_segment=pred,
        ram_gb=ram_gb,
        battery_mah=battery,
        rear_camera_mp=spec["pc"],
        front_camera_mp=spec["fc"],
        screen_size_inch=6.5  # asumsi default
    )

    recommendations = cached_recommend(cache_key(reco_req))

    return {
        "price_segment": pred,
        "label": PRICE_SEGMENT[pred]["label"],
        "category": PRICE_SEGMENT[pred]["category"],
        "recommendations": recommendations
    }
