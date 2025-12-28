from fastapi import FastAPI
import joblib
import json
import numpy as np

app = FastAPI(title="Smartphone Price Predictor")

# Load model
model = joblib.load("rf_price_model.pkl")

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