"""
Train the disease prediction Random Forest model.

Usage:
    python -m app.ml.train

Saves model to: app/ml/model.joblib
"""
import os
import random
import numpy as np
import joblib
from pathlib import Path
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report

from .features import SYMPTOM_LIST, DISEASE_LABELS, build_feature_vector

# ── Seed ──────────────────────────────────────────────────────────────────────
random.seed(42)
np.random.seed(42)

MODEL_PATH = Path(__file__).parent / "model.joblib"
LABEL_ENCODER_PATH = Path(__file__).parent / "label_encoder.joblib"

# ── Synthetic symptom-disease profiles ────────────────────────────────────────
# Each profile defines (disease_label, primary_symptoms, optional_symptoms)
DISEASE_PROFILES = {
    "Common Cold": {
        "primary": ["runny_nose", "sore_throat", "cough"],
        "secondary": ["fatigue", "headache", "sneezing"],
        "severity_range": (2, 5),
    },
    "Influenza": {
        "primary": ["fever", "fatigue", "muscle_pain", "chills"],
        "secondary": ["headache", "cough", "loss_of_appetite"],
        "severity_range": (5, 9),
    },
    "COVID-19": {
        "primary": ["fever", "cough", "fatigue", "loss_of_appetite"],
        "secondary": ["shortness_of_breath", "headache", "muscle_pain", "diarrhea"],
        "severity_range": (4, 9),
    },
    "Pneumonia": {
        "primary": ["fever", "cough", "shortness_of_breath", "chest_pain"],
        "secondary": ["fatigue", "chills", "sweating"],
        "severity_range": (6, 10),
    },
    "Gastroenteritis": {
        "primary": ["nausea", "vomiting", "diarrhea", "abdominal_pain"],
        "secondary": ["fatigue", "loss_of_appetite", "fever"],
        "severity_range": (4, 8),
    },
    "Hypertension": {
        "primary": ["headache", "dizziness"],
        "secondary": ["chest_pain", "fatigue"],
        "severity_range": (3, 7),
    },
    "Diabetes": {
        "primary": ["fatigue", "loss_of_appetite"],
        "secondary": ["dizziness", "headache"],
        "severity_range": (3, 6),
    },
    "Anxiety Disorder": {
        "primary": ["chest_pain", "shortness_of_breath", "headache", "fatigue"],
        "secondary": ["dizziness", "nausea", "sweating"],
        "severity_range": (4, 8),
    },
    "Migraine": {
        "primary": ["headache"],
        "secondary": ["nausea", "vomiting", "dizziness", "fatigue"],
        "severity_range": (6, 10),
    },
    "Asthma": {
        "primary": ["shortness_of_breath", "cough", "chest_pain"],
        "secondary": ["fatigue", "wheezing"],
        "severity_range": (5, 9),
    },
}


def generate_sample(disease: str, profile: dict) -> tuple[list[float], str]:
    primary = profile["primary"]
    secondary = profile.get("secondary", [])
    lo, hi = profile["severity_range"]

    # Always include primary symptoms (1–2 may be absent with low prob)
    symptoms = []
    for s in primary:
        if s in SYMPTOM_LIST:
            if random.random() > 0.1:  # 90% chance to include
                sev = random.randint(lo, hi)
                symptoms.append({"name": s, "severity": sev})

    # Include random subset of secondary symptoms
    for s in secondary:
        if s in SYMPTOM_LIST:
            if random.random() > 0.5:
                sev = random.randint(max(1, lo - 2), hi)
                symptoms.append({"name": s, "severity": sev})

    # Add noise symptoms (1–2 random irrelevant symptoms)
    noise_candidates = [s for s in SYMPTOM_LIST if s not in primary + secondary]
    for s in random.sample(noise_candidates, min(2, len(noise_candidates))):
        if random.random() > 0.7:
            symptoms.append({"name": s, "severity": random.randint(1, 3)})

    age = random.randint(18, 80)
    gender = random.choice(["male", "female"])
    has_chronic = disease in ["Hypertension", "Diabetes", "Asthma"]
    medical_history = ["Diabetes"] if has_chronic and random.random() > 0.5 else []

    features = build_feature_vector(
        symptoms=symptoms,
        age=age,
        gender=gender,
        medical_history=medical_history,
    )
    return features, disease


def generate_dataset(samples_per_disease: int = 500):
    X, y = [], []
    for disease, profile in DISEASE_PROFILES.items():
        for _ in range(samples_per_disease):
            features, label = generate_sample(disease, profile)
            X.append(features)
            y.append(label)
    return np.array(X), np.array(y)


def train():
    print("Generating synthetic training data...")
    X, y = generate_dataset(samples_per_disease=600)
    print(f"Dataset: {X.shape[0]} samples, {X.shape[1]} features, {len(set(y))} classes")

    le = LabelEncoder()
    y_enc = le.fit_transform(y)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y_enc, test_size=0.2, random_state=42, stratify=y_enc
    )

    print("Training Gradient Boosting Classifier...")
    model = GradientBoostingClassifier(
        n_estimators=200,
        max_depth=5,
        learning_rate=0.1,
        subsample=0.8,
        random_state=42,
        verbose=0,
    )
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=le.classes_))

    print(f"\nSaving model to {MODEL_PATH}...")
    joblib.dump(model, MODEL_PATH)
    joblib.dump(le, LABEL_ENCODER_PATH)
    print("Done!")


if __name__ == "__main__":
    train()
