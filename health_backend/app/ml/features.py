"""
Feature engineering for the disease prediction model.
Maps raw symptom names to integer indices and builds feature vectors.
"""

# All symptoms the model knows about (order matters - defines feature indices)
SYMPTOM_LIST = [
    "fever", "cough", "fatigue", "headache", "nausea", "vomiting",
    "diarrhea", "chest_pain", "shortness_of_breath", "joint_pain",
    "rash", "sore_throat", "runny_nose", "loss_of_appetite", "back_pain",
    "dizziness", "sweating", "chills", "muscle_pain", "abdominal_pain",
]

# Normalize symptom names: lowercase + replace spaces with underscores
def normalize_symptom(name: str) -> str:
    return name.lower().strip().replace(" ", "_")


# Disease labels
DISEASE_LABELS = [
    "Common Cold",
    "Influenza",
    "COVID-19",
    "Pneumonia",
    "Gastroenteritis",
    "Hypertension",
    "Diabetes",
    "Anxiety Disorder",
    "Migraine",
    "Asthma",
]

# Suggested actions per disease
DISEASE_ACTIONS: dict[str, list[str]] = {
    "Common Cold": [
        "Rest and stay hydrated",
        "Take OTC decongestants if needed",
        "Consult a doctor if symptoms worsen after 7 days",
    ],
    "Influenza": [
        "Rest and drink plenty of fluids",
        "Consider antiviral medications (consult doctor)",
        "Monitor for complications like pneumonia",
        "Isolate to prevent spreading",
    ],
    "COVID-19": [
        "Isolate immediately and get tested",
        "Monitor oxygen levels",
        "Contact healthcare provider for guidance",
        "Follow local public health guidelines",
    ],
    "Pneumonia": [
        "Seek immediate medical attention",
        "Antibiotics or antivirals may be needed",
        "Monitor breathing and oxygen levels closely",
    ],
    "Gastroenteritis": [
        "Stay hydrated with oral rehydration solutions",
        "Avoid solid food for a few hours",
        "Eat bland foods (BRAT diet) when improving",
        "Wash hands frequently",
    ],
    "Hypertension": [
        "Monitor blood pressure regularly",
        "Reduce sodium intake",
        "Exercise regularly and maintain a healthy weight",
        "Consult a doctor for medication evaluation",
    ],
    "Diabetes": [
        "Monitor blood glucose levels",
        "Follow a balanced, low-sugar diet",
        "Stay physically active",
        "Consult a doctor for medication management",
    ],
    "Anxiety Disorder": [
        "Practice deep breathing and mindfulness",
        "Limit caffeine and alcohol",
        "Consider speaking with a mental health professional",
        "Establish a regular sleep schedule",
    ],
    "Migraine": [
        "Rest in a quiet, dark room",
        "Apply cold or warm compress to head",
        "Stay hydrated",
        "Consult a doctor for prescription migraine medication",
    ],
    "Asthma": [
        "Use prescribed inhaler as directed",
        "Avoid known triggers",
        "Monitor peak flow readings",
        "Seek emergency care if breathing is severely impaired",
    ],
}

# Health tips by symptom patterns
HEALTH_TIPS = [
    "Drink at least 8 glasses of water daily.",
    "Aim for 7–9 hours of sleep per night.",
    "Wash your hands regularly to prevent infections.",
    "Exercise for at least 30 minutes, 5 days a week.",
    "Maintain a balanced diet rich in fruits and vegetables.",
    "Avoid smoking and limit alcohol consumption.",
    "Manage stress through meditation, yoga, or deep breathing.",
    "Schedule regular check-ups with your healthcare provider.",
]


def build_feature_vector(
    symptoms: list[dict],
    age: int | None,
    gender: str | None,
    medical_history: list[str],
) -> list[float]:
    """
    Builds a fixed-length feature vector:
    - 20 symptom severity features (0 if absent, 1–10 if present)
    - 1 age feature (normalized 0–1, 0 if unknown)
    - 2 gender one-hot features [is_male, is_female]
    - 1 has_chronic_condition feature
    Total: 24 features
    """
    # Symptom features
    symptom_map: dict[str, float] = {}
    for s in symptoms:
        key = normalize_symptom(s.get("name", ""))
        severity = float(s.get("severity", 5))
        symptom_map[key] = severity / 10.0  # normalize to [0, 1]

    features: list[float] = [symptom_map.get(sym, 0.0) for sym in SYMPTOM_LIST]

    # Age feature (normalize: 0=0, 100=1)
    features.append(min(float(age or 35), 100.0) / 100.0)

    # Gender one-hot
    gender_lower = (gender or "").lower()
    features.append(1.0 if gender_lower == "male" else 0.0)
    features.append(1.0 if gender_lower == "female" else 0.0)

    # Has chronic condition
    chronic = ["diabetes", "hypertension", "asthma", "heart disease", "kidney disease"]
    has_chronic = any(
        any(c in (m or "").lower() for c in chronic)
        for m in medical_history
    )
    features.append(1.0 if has_chronic else 0.0)

    return features
