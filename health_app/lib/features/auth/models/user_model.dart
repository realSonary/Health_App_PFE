class UserModel {
  final int id;
  final String email;
  final bool isActive;
  final String? fullName;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.email,
    required this.isActive,
    this.fullName,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      isActive: json['is_active'] as bool? ?? true,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'is_active': isActive,
        'full_name': fullName,
        'avatar_url': avatarUrl,
      };

  UserModel copyWith({
    int? id,
    String? email,
    bool? isActive,
    String? fullName,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class TokenResponse {
  final String accessToken;
  final String tokenType;
  final UserModel user;

  const TokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class ProfileModel {
  final int userId;
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? weightKg;
  final double? heightCm;
  final String? bloodType;
  final List<String> medicalConditions;
  final List<String> allergies;
  // ── Extended fields ───────────────────────────────────────────────────────
  final String? activityLevel;      // 'low' | 'moderate' | 'high'
  final List<String> chronicConditions;
  final List<String> healthConditions;

  const ProfileModel({
    required this.userId,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.weightKg,
    this.heightCm,
    this.bloodType,
    this.medicalConditions = const [],
    this.allergies = const [],
    this.activityLevel,
    this.chronicConditions = const [],
    this.healthConditions = const [],
  });

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      bloodType: json['blood_type'] as String?,
      medicalConditions:
          List<String>.from(json['medical_conditions'] as List? ?? []),
      allergies: List<String>.from(json['allergies'] as List? ?? []),
      activityLevel: json['activity_level'] as String?,
      chronicConditions:
          List<String>.from(json['chronic_conditions'] as List? ?? []),
      healthConditions:
          List<String>.from(json['health_conditions'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'full_name': fullName,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'gender': gender,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'blood_type': bloodType,
        'medical_conditions': medicalConditions,
        'allergies': allergies,
        'activity_level': activityLevel,
        'chronic_conditions': chronicConditions,
        'health_conditions': healthConditions,
      };
}
