import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class MedHistoryState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMsg;

  final List<String> chronicConditions;
  final List<String> allergies;
  final List<String> pastSurgeries;
  final String familyHistory;
  final String notes;

  const MedHistoryState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMsg,
    this.chronicConditions = const [],
    this.allergies = const [],
    this.pastSurgeries = const [],
    this.familyHistory = '',
    this.notes = '',
  });

  MedHistoryState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,          // ← explicit flag to null out error
    String? successMsg,
    bool clearSuccess = false,        // ← explicit flag to null out successMsg
    List<String>? chronicConditions,
    List<String>? allergies,
    List<String>? pastSurgeries,
    String? familyHistory,
    String? notes,
  }) =>
      MedHistoryState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        // Only clears when explicitly requested — no silent null-out on every call
        error: clearError ? null : (error ?? this.error),
        successMsg: clearSuccess ? null : (successMsg ?? this.successMsg),
        chronicConditions: chronicConditions ?? this.chronicConditions,
        allergies: allergies ?? this.allergies,
        pastSurgeries: pastSurgeries ?? this.pastSurgeries,
        familyHistory: familyHistory ?? this.familyHistory,
        notes: notes ?? this.notes,
      );
}

class MedHistoryNotifier extends StateNotifier<MedHistoryState> {
  final ApiClient _client;

  MedHistoryNotifier(this._client) : super(const MedHistoryState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _client.get('/profile/medical-history');
      final d = res.data as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        isLoading: false,
        chronicConditions:
            List<String>.from(d['chronic_conditions'] as List? ?? []),
        allergies: List<String>.from(d['allergies'] as List? ?? []),
        pastSurgeries: List<String>.from(d['past_surgeries'] as List? ?? []),
        familyHistory: d['family_history'] as String? ?? '',
        notes: d['notes'] as String? ?? '',
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

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

  void addAllergy(String v) {
    if (v.isEmpty || state.allergies.contains(v)) return;
    state = state.copyWith(allergies: [...state.allergies, v]);
  }

  void removeAllergy(String v) {
    state = state.copyWith(
        allergies: state.allergies.where((e) => e != v).toList());
  }

  void addSurgery(String v) {
    if (v.isEmpty || state.pastSurgeries.contains(v)) return;
    state = state.copyWith(pastSurgeries: [...state.pastSurgeries, v]);
  }

  void removeSurgery(String v) {
    state = state.copyWith(
        pastSurgeries: state.pastSurgeries.where((e) => e != v).toList());
  }

  void setFamilyHistory(String v) =>
      state = state.copyWith(familyHistory: v);
  void setNotes(String v) => state = state.copyWith(notes: v);

  Future<void> save() async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      await _client.put('/profile/medical-history', data: {
        'chronic_conditions': state.chronicConditions,
        'allergies': state.allergies,
        'past_surgeries': state.pastSurgeries,
        'family_history': state.familyHistory,
        'notes': state.notes,
      });
      state = state.copyWith(
          isSaving: false, successMsg: 'Medical history saved!');
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Save failed: $e');
    }
  }
}

final medHistoryProvider =
    StateNotifierProvider.autoDispose<MedHistoryNotifier, MedHistoryState>(
        (ref) {
  return MedHistoryNotifier(ref.watch(apiClientProvider));
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class MedicalHistoryScreen extends ConsumerStatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  ConsumerState<MedicalHistoryScreen> createState() =>
      _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState
    extends ConsumerState<MedicalHistoryScreen> {
  final _familyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _familyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(medHistoryProvider);
    final notifier = ref.read(medHistoryProvider.notifier);

    // Sync controllers once data loads
    if (!_initialized && !s.isLoading) {
      _familyCtrl.text = s.familyHistory;
      _notesCtrl.text = s.notes;
      _initialized = true;
    }

    ref.listen(medHistoryProvider, (_, next) {
      if (next.successMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.successMsg!),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical History'),
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
                  // ── Chronic Conditions ───────────────────────────────
                  _ChipSection(
                    emoji: '🏥',
                    title: 'Chronic Conditions',
                    sub: 'e.g. Diabetes, Hypertension, Asthma',
                    chips: s.chronicConditions,
                    suggestions: const [
                      'Diabetes Type 1', 'Diabetes Type 2', 'Hypertension',
                      'Asthma', 'Arthritis', 'Heart Disease', 'Hypothyroidism',
                      'Depression', 'Anxiety', 'Anemia',
                    ],
                    onAdd: notifier.addChronicCondition,
                    onRemove: notifier.removeChronicCondition,
                  ).animate().fadeIn(duration: 350.ms),

                  const SizedBox(height: 16),

                  // ── Allergies ────────────────────────────────────────
                  _ChipSection(
                    emoji: '⚠️',
                    title: 'Allergies',
                    sub: 'e.g. Penicillin, Pollen, Peanuts',
                    chips: s.allergies,
                    suggestions: const [
                      'Penicillin', 'Aspirin', 'Ibuprofen', 'Pollen',
                      'Peanuts', 'Shellfish', 'Latex', 'Bee stings', 'Dust mites',
                    ],
                    onAdd: notifier.addAllergy,
                    onRemove: notifier.removeAllergy,
                  ).animate().fadeIn(delay: 60.ms, duration: 350.ms),

                  const SizedBox(height: 16),

                  // ── Past Surgeries ───────────────────────────────────
                  _ChipSection(
                    emoji: '🔪',
                    title: 'Past Surgeries / Procedures',
                    sub: 'e.g. Appendectomy 2019',
                    chips: s.pastSurgeries,
                    suggestions: const [
                      'Appendectomy', 'Tonsillectomy', 'Gallbladder removal',
                      'Knee replacement', 'Hip replacement', 'Cesarean section',
                      'Hernia repair', 'Cataract surgery',
                    ],
                    onAdd: notifier.addSurgery,
                    onRemove: notifier.removeSurgery,
                  ).animate().fadeIn(delay: 120.ms, duration: 350.ms),

                  const SizedBox(height: 16),

                  // ── Family History ───────────────────────────────────
                  _SectionCard(
                    emoji: '👨‍👩‍👧',
                    title: 'Family History',
                    child: TextField(
                      controller: _familyCtrl,
                      maxLines: 3,
                      onChanged: notifier.setFamilyHistory,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Father: heart disease, Mother: diabetes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: AppColors.neutral50,
                      ),
                    ),
                  ).animate().fadeIn(delay: 180.ms, duration: 350.ms),

                  const SizedBox(height: 16),

                  // ── Notes ────────────────────────────────────────────
                  _SectionCard(
                    emoji: '📝',
                    title: 'Additional Notes',
                    child: TextField(
                      controller: _notesCtrl,
                      maxLines: 4,
                      onChanged: notifier.setNotes,
                      decoration: InputDecoration(
                        hintText:
                            'Any other relevant medical information...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: AppColors.neutral50,
                      ),
                    ),
                  ).animate().fadeIn(delay: 240.ms, duration: 350.ms),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}

// ─── Chip Section ─────────────────────────────────────────────────────────────

class _ChipSection extends StatefulWidget {
  final String emoji;
  final String title;
  final String sub;
  final List<String> chips;
  final List<String> suggestions;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _ChipSection({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.chips,
    required this.suggestions,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_ChipSection> createState() => _ChipSectionState();
}

class _ChipSectionState extends State<_ChipSection> {
  final _ctrl = TextEditingController();

  // FIX: was missing — leaked the controller and caused assertion errors
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    // FIX: calling _ctrl.clear() immediately after onAdd() triggers
    // "setState() called during build" because onAdd() schedules a provider
    // state update (rebuild) while clear() schedules another setState.
    // Deferring clear() to the next frame eliminates the assertion error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTextStyles.bodySemiBold),
                    Text(widget.sub, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chips
          if (widget.chips.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.chips
                  .map((c) => Chip(
                        label: Text(c,
                            style: const TextStyle(fontSize: 11)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => widget.onRemove(c),
                        backgroundColor: AppColors.plum100,
                        deleteIconColor: AppColors.plum700,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                      ))
                  .toList(),
            ),

          const SizedBox(height: 10),

          // Input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'Type or pick below',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _add,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.plum700,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('+'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Suggestions
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.suggestions
                .where((s) => !widget.chips.contains(s))
                .take(5)
                .map((s) => GestureDetector(
                      onTap: () => widget.onAdd(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.neutral600)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final Widget child;

  const _SectionCard(
      {required this.emoji, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.bodySemiBold),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
