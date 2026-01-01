# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),  
and this project adheres to semantic versioning principles.

---

## [1.01-pre-release] - 2025-12-29
### Added
- Hybrid **price segment classification API** using Random Forest
- **Safety gate** for low-end devices to prevent misclassification
- **Soft gate (mid-cap gate)** to stabilize mid-range predictions
- Segment-aware **recommendation system** with price-range filtering
- Flutter UI updated to display **price segment & category** instead of raw price
- Disclaimer to clarify that estimation is **indicative, not market price**
- Cleaned and aligned feature schema between ML model, backend, and Flutter

### Changed
- Prediction output changed from price estimation to **segment-based classification**
- Recommendation logic updated to respect predicted price segment
- Backend decision flow clarified:
  1. Low-end hard gate  
  2. ML prediction  
  3. Mid-cap soft gate  
  4. Recommendation filtering
- Flutter wording adjusted to avoid misleading ML claims

### Removed
- CPU-related inputs (`clock_speed`, `n_cores`) from prediction pipeline
- Assumption that ML model predicts price in rupiah
- Unfiltered recommendations across all price segments

---

## [1.0.9] - 2025-12-29
### Added
- Initial Random Forest model for smartphone price range classification
- Basic FastAPI backend with `/predict` endpoint
- Initial Flutter UI for input and prediction
- CSV-based dataset preprocessing

### Known Issues
- Mid-range devices could be misclassified as flagship
- Recommendation system not yet segment-aware

---

## [1.0.7] - 2025-12-29
### Added
- Project initialization
- Dataset exploration and feature engineering
- Baseline ML experiments

---

## [Unreleased] (Next Update)
### Planned
- **About Screen (Flutter)**
  - Creator / author information
  - Project description
  - License information
- Improved documentation:
  - Project architecture overview
  - ML pipeline explanation
- Minor UI polish:
  - Segment badges (color-coded)
  - Improved readability for recommendation cards
- Optional:
  - Docker support for backend deployment
  - Environment configuration example

---

## License
License will be added in a future release.
