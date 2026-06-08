"""
Disease prediction inference module.
Loads the trained model and returns ranked predictions with confidence scores.
"""
import random
from pathlib import Path
from typing import Optional

import joblib
import numpy as np

from .features import build_feature_vector, DISEASE_ACTIONS, HEALTH_TIPS

MODEL_PATH = Path(__file__).parent / "model.joblib"
LABEL_ENCODER_PATH = Path(__file__).parent / "label_encoder.joblib"

# Lazy-loaded singletons
_model = None
_label_encoder = None


def _load_model():
    global _model, _label_encoder
    if _model is None:
        if not MODEL_PATH.exists():
            raise FileNotFoundError(
                f"Model not found at {MODEL_PATH}. "
                "Please run: python -m app.ml.train"
            )
        _model = joblib.load(MODEL_PATH)
        _label_encoder = joblib.load(LABEL_ENCODER_PATH)
    return _model, _label_encoder


def predict_diseases(
    symptoms: list[dict],
    age: Optional[int] = None,
    gender: Optional[str] = None,
    medical_history: Optional[list[str]] = None,
    top_n: int = 3,
) -> dict:
    """
    Returns top N disease predictions with confidence scores and actions.

    Returns:
        {
            "predictions": [
                {"disease": "...", "confidence": 0.85, "actions": [...]},
                ...
            ],
            "health_tips": [...],
        }
    """
    try:
        model, le = _load_model()
    except FileNotFoundError:
        # Fallback: rule-based prediction when model isn't trained yet
        return _rule_based_predict(symptoms, top_n)

    features = build_feature_vector(
        symptoms=symptoms,
        age=age,
        gender=gender,
        medical_history=medical_history or [],
    )
    X = np.array([features])
    probabilities = model.predict_proba(X)[0]

    # Get top_n predictions sorted by confidence
    top_indices = np.argsort(probabilities)[::-1][:top_n]
    predictions = []
    for idx in top_indices:
        disease = le.classes_[idx]
        confidence = float(probabilities[idx])
        actions = DISEASE_ACTIONS.get(disease, ["Consult a healthcare professional"])
        predictions.append({
            "disease": disease,
            "confidence": round(confidence, 4),
            "actions": actions,
        })

    # Select relevant health tips
    tips = _select_health_tips(symptoms)

    return {
        "predictions": predictions,
        "health_tips": tips,
    }


def _select_health_tips(symptoms: list[dict]) -> list[str]:
    """Select contextually relevant tips based on symptoms."""
    tip_pool = list(HEALTH_TIPS)
    random.shuffle(tip_pool)
    return tip_pool[:3]


def _rule_based_predict(symptoms: list[dict], top_n: int) -> dict:
    """
    Simple rule-based fallback when ML model isn't available.
    Used during development before training.
    """
    from .features import normalize_symptom, DISEASE_LABELS

    symptom_names = {normalize_symptom(s.get("name", "")) for s in symptoms}
    avg_severity = (
        sum(s.get("severity", 5) for s in symptoms) / len(symptoms) if symptoms else 5
    )

    scores: dict[str, float] = {}

    # Common Cold
    cold_syms = {"runny_nose", "sore_throat", "cough", "sneezing"}
    scores["Common Cold"] = len(symptom_names & cold_syms) / max(len(cold_syms), 1) * 0.8

    # Influenza
    flu_syms = {"fever", "fatigue", "muscle_pain", "chills", "headache"}
    scores["Influenza"] = len(symptom_names & flu_syms) / max(len(flu_syms), 1)

    # COVID-19
    covid_syms = {"fever", "cough", "fatigue", "loss_of_appetite", "shortness_of_breath"}
    scores["COVID-19"] = len(symptom_names & covid_syms) / max(len(covid_syms), 1) * 0.9

    # Gastroenteritis
    gi_syms = {"nausea", "vomiting", "diarrhea", "abdominal_pain"}
    scores["Gastroenteritis"] = len(symptom_names & gi_syms) / max(len(gi_syms), 1)

    # Migraine
    if "headache" in symptom_names:
        scores["Migraine"] = avg_severity / 10.0 * 0.7

    # Asthma
    resp_syms = {"shortness_of_breath", "cough", "chest_pain"}
    scores["Asthma"] = len(symptom_names & resp_syms) / max(len(resp_syms), 1) * 0.6

    # Sort and normalize
    sorted_items = sorted(scores.items(), key=lambda x: x[1], reverse=True)[:top_n]
    total = sum(v for _, v in sorted_items) or 1
    predictions = [
        {
            "disease": disease,
            "confidence": round(score / total, 4),
            "actions": DISEASE_ACTIONS.get(disease, ["Consult a healthcare professional"]),
        }
        for disease, score in sorted_items
        if score > 0
    ]

    if not predictions:
        predictions = [
            {
                "disease": "General Illness",
                "confidence": 1.0,
                "actions": ["Rest and stay hydrated", "Consult a doctor if symptoms persist"],
            }
        ]

    return {
        "predictions": predictions,
        "health_tips": _select_health_tips(symptoms),
    }
