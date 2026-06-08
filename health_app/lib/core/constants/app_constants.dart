class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl = 'http://localhost:8000/api/v1';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String hasSeenOnboardingKey = 'has_seen_onboarding';

  // Health defaults
  static const int dailyWaterGoalMl = 2500;
  static const double dailyCalorieGoal = 2000;
  static const double recommendedSleepHours = 8.0;

  // Symptom names
  static const List<String> symptomList = [
    'Fever',
    'Cough',
    'Fatigue',
    'Headache',
    'Nausea',
    'Vomiting',
    'Diarrhea',
    'Chest Pain',
    'Shortness of Breath',
    'Joint Pain',
    'Rash',
    'Sore Throat',
    'Runny Nose',
    'Loss of Appetite',
    'Back Pain',
    'Dizziness',
    'Sweating',
    'Chills',
    'Muscle Pain',
    'Abdominal Pain',
  ];

  // Medical conditions for profile
  static const List<String> medicalConditions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Heart Disease',
    'Arthritis',
    'Depression',
    'Anxiety',
    'Obesity',
    'Thyroid Disorder',
    'Kidney Disease',
    'None',
  ];

  // Water amounts
  static const List<int> waterAmounts = [100, 200, 250, 350, 500, 750];

  // Animation assets
  static const String bunnySleepAnim = 'assets/animations/bunny_sleep.json';
  static const String bunnyActiveAnim = 'assets/animations/bunny_active.json';
  static const String bunnyHappyAnim = 'assets/animations/bunny_happy.json';
  static const String loadingAnim = 'assets/animations/loading.json';
  static const String successAnim = 'assets/animations/success.json';
}
