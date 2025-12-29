# Smartphone Price Predictions

---

## What is this?

**Smartphone Price Predict** is an application that predicts the **price range of a smartphone** (not the exact price) by classifying devices into the following categories:

- Cheap (Entry-level)
- Mid-range
- Upper Mid-range
- Expensive (Flagship)

The prediction is performed using a **Random Forest model** trained on the
[Mobile Price Classification dataset](https://www.kaggle.com/datasets/iabhishekofficial/mobile-price-classification).

This application combines:

- **Backend**: FastAPI + Random Forest (Python)
- **Frontend**: Flutter Desktop
- **Automation**: Shell scripts (Unix & Windows)

---

## Why was this app created?

This application was created to answer the following question:

> *“Can we estimate a smartphone’s price range using only its hardware specifications?”*

The main reasons behind this project:

- Smartphone prices are often determined by a **combination of hardware specifications**
- Not everyone understands how factors like **RAM, camera, or CPU** influence pricing
- A **data-driven approach** is needed instead of assumptions or subjective judgment

---

## Purpose of this application

- To implement **machine learning classification** in a real-world application
- To provide **human-readable price predictions** that are easy to understand

---

## How does this app work?

1. The user enters smartphone specifications through the UI
2. Flutter sends the data to FastAPI in JSON format
3. The Random Forest model performs the prediction
4. The backend returns:

   - The price category
   - An estimated price range (e.g., ≥ 6 million IDR)

5. The result is displayed in the UI

---

## How to run the app?

1. Make sure you have installed:
  - Flutter SDK
  - Java JDK 17+
  - Python 3
  - Pip / VENV (VENV will be created automatically if it's not detected)
  - Anaconda (Alternative from VENV if you like global venv on your machine)

2. Run these commands:

```bash
chmod +x quickstart.sh
./quickstart.sh
```

The script will automatically executing python and compile flutter, if one of those (wether Flutter or Python) missing, the script will abort imediately.
