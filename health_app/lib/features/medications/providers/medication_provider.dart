import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class Medication {
  final int? id;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> scheduleTimes;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;
  final bool isTaken;

  const Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.scheduleTimes = const [],
    required this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
    this.isTaken = false,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as int?,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      scheduleTimes:
          List<String>.from(json['schedule_times'] as List? ?? []),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isTaken: json['is_taken'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'schedule_times': scheduleTimes,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'notes': notes,
        'is_active': isActive,
        'is_taken': isTaken,
      };

  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    String? frequency,
    List<String>? scheduleTimes,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    bool? isActive,
    bool? isTaken,
  }) =>
      Medication(
        id: id ?? this.id,
        name: name ?? this.name,
        dosage: dosage ?? this.dosage,
        frequency: frequency ?? this.frequency,
        scheduleTimes: scheduleTimes ?? this.scheduleTimes,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        notes: notes ?? this.notes,
        isActive: isActive ?? this.isActive,
        isTaken: isTaken ?? this.isTaken,
      );

  String get frequencyLabel {
    return switch (frequency) {
      'once_daily' => 'Once daily',
      'twice_daily' => 'Twice daily',
      'three_times_daily' => '3x daily',
      'four_times_daily' => '4x daily',
      'as_needed' => 'As needed',
      'weekly' => 'Weekly',
      _ => frequency,
    };
  }
}

class MedicationState {
  final List<Medication> medications;
  final bool isLoading;
  final String? error;

  const MedicationState({
    this.medications = const [],
    this.isLoading = false,
    this.error,
  });

  MedicationState copyWith({
    List<Medication>? medications,
    bool? isLoading,
    String? error,
  }) {
    return MedicationState(
      medications: medications ?? this.medications,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MedicationNotifier extends StateNotifier<MedicationState> {
  final ApiClient _client;

  MedicationNotifier(this._client) : super(const MedicationState()) {
    // Auto-load so dashboard and other screens always have data on first render
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _client.get('/medications');
      final data = response.data as Map<String, dynamic>;
      final meds = (data['medications'] as List?)
              ?.map((m) =>
                  Medication.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [];
      state = MedicationState(medications: meds);
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load medications');
    }
  }

  Future<bool> add(Medication medication) async {
    try {
      final response = await _client.post(
        '/medications',
        data: medication.toJson(),
      );
      final newMed = Medication.fromJson(
          response.data as Map<String, dynamic>);
      state = state.copyWith(
          medications: [...state.medications, newMed]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _client.delete('/medications/$id');
      state = state.copyWith(
          medications:
              state.medications.where((m) => m.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markTaken(int medicationId, DateTime scheduledTime) async {
    // Optimistic update — flip isTaken immediately so the UI responds at once
    final idx = state.medications.indexWhere((m) => m.id == medicationId);
    if (idx >= 0) {
      final updated = [...state.medications];
      updated[idx] = updated[idx].copyWith(isTaken: true);
      state = state.copyWith(medications: updated);
    }
    try {
      await _client.post('/medications/$medicationId/log', data: {
        'scheduled_time': scheduledTime.toIso8601String(),
        'status': 'taken',
        'taken_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      // Keep the optimistic update even when the API is unreachable.
      // The user tapped "Mark as Taken" — honour that locally.
      return true;
    }
  }
}

final medicationProvider =
    StateNotifierProvider<MedicationNotifier, MedicationState>((ref) {
  return MedicationNotifier(ref.watch(apiClientProvider));
});

