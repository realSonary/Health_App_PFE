import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class _InfoState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMsg;

  final int userId;
  final String fullName;
  final String gender;
  final String dateOfBirth;
  final String weight;
  final String height;
  // ── NEW fields ──────────────────────────────────────────────────
  final String activityLevel;   // 'low' | 'moderate' | 'high'
  final List<String> chronicConditions;
  final List<String> healthConditions;
  final String bloodType;

  const _InfoState({
    this.isLoading = true,
    this.isSaving = false,
    this.error,
    this.successMsg,
    this.userId = 0,
    this.fullName = '',
    this.gender = '',
    this.dateOfBirth = '',
    this.weight = '',
    this.height = '',
    this.activityLevel = 'moderate',
    this.chronicConditions = const [],
    this.healthConditions = const [],
    this.bloodType = '',
  });

  _InfoState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMsg,
    int? userId,
    String? fullName,
    String? gender,
    String? dateOfBirth,
    String? weight,
    String? height,
    String? activityLevel,
    List<String>? chronicConditions,
    List<String>? healthConditions,
    String? bloodType,
  }) =>
      _InfoState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: error,
        successMsg: successMsg,
        userId: userId ?? this.userId,
        fullName: fullName ?? this.fullName,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        weight: weight ?? this.weight,
        height: height ?? this.height,
        activityLevel: activityLevel ?? this.activityLevel,
        chronicConditions: chronicConditions ?? this.chronicConditions,
        healthConditions: healthConditions ?? this.healthConditions,
        bloodType: bloodType ?? this.bloodType,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class _InfoNotifier extends StateNotifier<_InfoState> {
  _InfoNotifier(this._authService) : super(const _InfoState()) {
    _load();
  }

  final AuthService _authService;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final profile = await _authService.getProfile();
      state = state.copyWith(
        isLoading: false,
        userId: profile.userId,
        fullName: profile.fullName ?? '',
        gender: profile.gender ?? '',
        dateOfBirth: profile.dateOfBirth != null
            ? '${profile.dateOfBirth!.year}-'
                '${profile.dateOfBirth!.month.toString().padLeft(2, '0')}-'
                '${profile.dateOfBirth!.day.toString().padLeft(2, '0')}'
            : '',
        weight: profile.weightKg?.toString() ?? '',
        height: profile.heightCm?.toString() ?? '',
        activityLevel: profile.activityLevel ?? 'moderate',
        chronicConditions:
            List<String>.from(profile.chronicConditions ?? []),
        healthConditions:
            List<String>.from(profile.healthConditions ?? []),
        bloodType: profile.bloodType ?? '',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFullName(String v) => state = state.copyWith(fullName: v);
  void setGender(String v) => state = state.copyWith(gender: v);
  void setDateOfBirth(String v) => state = state.copyWith(dateOfBirth: v);
  void setWeight(String v) => state = state.copyWith(weight: v);
  void setHeight(String v) => state = state.copyWith(height: v);
  void setActivityLevel(String v) => state = state.copyWith(activityLevel: v);
  void setBloodType(String v) => state = state.copyWith(bloodType: v);

  void addChronicCondition(String v) {
    if (v.isEmpty || state.chronicConditions.contains(v)) return;
    state = state.copyWith(
        chronicConditions: [...state.chronicConditions, v]);
  }

  void removeChronicCondition(String v) {
    state = state.copyWith(
        chronicConditions:
            state.chronicConditions.where((e) => e != v).toList());
  }

  void toggleHealthCondition(String v) {
    final current = state.healthConditions;
    final updated = current.contains(v)
        ? current.where((e) => e != v).toList()
        : [...current, v];
    state = state.copyWith(healthConditions: updated);
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true);
    try {
      final profile = ProfileModel(
        userId: state.userId,
        fullName: state.fullName.isNotEmpty ? state.fullName : null,
        gender: state.gender.isNotEmpty ? state.gender : null,
        dateOfBirth: state.dateOfBirth.isNotEmpty
            ? DateTime.tryParse(state.dateOfBirth)
            : null,
        weightKg:
            state.weight.isNotEmpty ? double.tryParse(state.weight) : null,
        heightCm:
            state.height.isNotEmpty ? double.tryParse(state.height) : null,
        activityLevel:
            state.activityLevel.isNotEmpty ? state.activityLevel : null,
        chronicConditions: state.chronicConditions,
        healthConditions: state.healthConditions,
        bloodType: state.bloodType.isNotEmpty ? state.bloodType : null,
      );
      await _authService.updateProfile(profile);
      state =
          state.copyWith(isSaving: false, successMsg: 'Profile updated successfully');
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Save failed: $e');
    }
  }
}

final _infoProvider =
    StateNotifierProvider.autoDispose<_InfoNotifier, _InfoState>((ref) {
  return _InfoNotifier(ref.read(authServiceProvider));
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() =>
      _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  bool _controllersPopulated = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _conditionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_infoProvider);
    final notifier = ref.read(_infoProvider.notifier);

    // Populate controllers once data has loaded
    if (!_controllersPopulated && !s.isLoading) {
      _nameCtrl.text = s.fullName;
      _dobCtrl.text = s.dateOfBirth;
      _weightCtrl.text = s.weight;
      _heightCtrl.text = s.height;
      _controllersPopulated = true;
    }

    // Show snackbar on success or error — and sync profileProvider globally
    ref.listen(_infoProvider, (_, next) {
      if (next.successMsg != null) {
        // ── KEY FIX: Refresh the global profileProvider so dashboard,
        //    profile screen, and drawer all reflect the updated name/data.
        ref.read(profileProvider.notifier).loadProfile();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.successMsg!),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Personal Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: s.isSaving ? null : notifier.save,
            child: s.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.secondary))
                : const Text('Save'),
          ),
        ],
      ),
      body: s.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Basic Info ───────────────────────────────────────
                  _SectionHeader(emoji: '👤', title: 'Basic Information'),
                  const SizedBox(height: 10),

                  _InfoField(
                    label: 'Full Name',
                    controller: _nameCtrl,
                    onChanged: notifier.setFullName,
                    hint: 'Your full name',
                  ),
                  const SizedBox(height: 12),

                  // Gender selector
                  _FieldLabel(label: 'Gender'),
                  const SizedBox(height: 6),
                  Row(
                    children: ['male', 'female', 'other'].map((g) {
                      final isSelected = s.gender == g;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => notifier.setGender(g),
                          child: Container(
                            margin:
                                EdgeInsets.only(right: g != 'other' ? 8 : 0),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.plum700
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.plum700
                                    : AppColors.border,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              g[0].toUpperCase() + g.substring(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.neutral500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  _InfoField(
                    label: 'Date of Birth (YYYY-MM-DD)',
                    controller: _dobCtrl,
                    onChanged: notifier.setDateOfBirth,
                    hint: '1995-06-15',
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 20),

                  // ── Physical Stats ───────────────────────────────────
                  _SectionHeader(emoji: '⚖️', title: 'Physical Stats'),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _InfoField(
                          label: 'Weight (kg)',
                          controller: _weightCtrl,
                          onChanged: notifier.setWeight,
                          hint: '68.0',
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoField(
                          label: 'Height (cm)',
                          controller: _heightCtrl,
                          onChanged: notifier.setHeight,
                          hint: '170',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Blood type picker
                  _FieldLabel(label: 'Blood Type'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                        .map((bt) {
                      final isSelected = s.bloodType == bt;
                      return GestureDetector(
                        onTap: () => notifier.setBloodType(bt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.rose500
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.rose500
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            bt,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.neutral500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Activity Level ───────────────────────────────────
                  _SectionHeader(emoji: '🏃', title: 'Activity Level'),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      ('low', '🧘', 'Low', 'Light walking,\nstretching'),
                      ('moderate', '🚶', 'Moderate', '30–60 min\nexercise'),
                      ('high', '🏋️', 'High', 'Intense daily\nworkouts'),
                    ].map((item) {
                      final (value, emoji, label, sub) = item;
                      final isSelected = s.activityLevel == value;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => notifier.setActivityLevel(value),
                          child: Container(
                            margin: EdgeInsets.only(
                                right: value != 'high' ? 8 : 0),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.sage100
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.sage400
                                    : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(emoji,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.sage700
                                          : AppColors.neutral600,
                                    )),
                                Text(sub,
                                    style:
                                        AppTextStyles.caption.copyWith(fontSize: 9),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // ── Chronic Conditions ───────────────────────────────
                  _SectionHeader(emoji: '🏥', title: 'Chronic Conditions'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: cardDecoration(),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.chronicConditions.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: s.chronicConditions
                                .map((c) => Chip(
                                      label: Text(c,
                                          style:
                                              const TextStyle(fontSize: 11)),
                                      deleteIcon: const Icon(Icons.close, size: 14),
                                      onDeleted: () =>
                                          notifier.removeChronicCondition(c),
                                      backgroundColor: AppColors.plum100,
                                      deleteIconColor: AppColors.plum700,
                                    ))
                                .toList(),
                          ),
                        if (s.chronicConditions.isNotEmpty)
                          const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _conditionCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Diabetes, Hypertension',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  isDense: true,
                                ),
                                onSubmitted: (v) {
                                  notifier.addChronicCondition(v.trim());
                                  _conditionCtrl.clear();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                notifier
                                    .addChronicCondition(_conditionCtrl.text.trim());
                                _conditionCtrl.clear();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.plum700,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 11),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('+'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: ['Diabetes', 'Hypertension', 'Asthma',
                            'Arthritis', 'Heart Disease', 'Hypothyroidism']
                              .where((c) => !s.chronicConditions.contains(c))
                              .map((c) => GestureDetector(
                                    onTap: () =>
                                        notifier.addChronicCondition(c),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.neutral100,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                            color: AppColors.border),
                                      ),
                                      child: Text(c,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.neutral600)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Health Conditions (onboarding-style) ─────────────
                  _SectionHeader(emoji: '💊', title: 'Health Conditions'),
                  const SizedBox(height: 6),
                  Text(
                    'Select all that apply to you',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.neutral400),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      '🤧 Allergies', '😴 Sleep Apnea', '💊 High Cholesterol',
                      '🧠 Mental Health', '🦴 Osteoporosis', '🫁 COPD',
                      '🫀 Atrial Fibrillation', '🩺 Kidney Disease', '🏃 Obesity',
                      '👁️ Glaucoma', '🦷 Gum Disease', '🍺 Liver Disease',
                    ].map((item) {
                      final isSelected = s.healthConditions.contains(item);
                      return GestureDetector(
                        onTap: () => notifier.toggleHealthCondition(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.plum100
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.plum400
                                  : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.plum800
                                  : AppColors.neutral500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  const _SectionHeader({required this.emoji, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(title,
            style: AppTextStyles.bodySemiBold.copyWith(fontSize: 15)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.label);
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final TextInputType keyboardType;

  const _InfoField({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
