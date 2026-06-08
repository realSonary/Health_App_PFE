import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Knowledge-base models ────────────────────────────────────────────────────

class DiseaseInfo {
  final String key;
  final String name;
  final List<String> symptoms;
  final String description;
  final List<String> precautions;
  final List<String> diet;

  const DiseaseInfo({
    required this.key,
    required this.name,
    required this.symptoms,
    required this.description,
    required this.precautions,
    required this.diet,
  });

  factory DiseaseInfo.fromJson(String key, Map<String, dynamic> j) =>
      DiseaseInfo(
        key: key,
        name: j['name'] as String,
        symptoms: List<String>.from(j['symptoms'] as List),
        description: j['description'] as String? ?? '',
        precautions: List<String>.from(j['precautions'] as List? ?? []),
        diet: List<String>.from(j['diet'] as List? ?? []),
      );
}

class DiseaseKnowledgeBase {
  final Map<String, DiseaseInfo> diseases;
  final List<String> allSymptoms;

  const DiseaseKnowledgeBase({
    required this.diseases,
    required this.allSymptoms,
  });
}

// ─── Match result ─────────────────────────────────────────────────────────────

class DiseaseMatch {
  final DiseaseInfo disease;
  final double score;   // 0–1
  final int matchCount; // how many selected symptoms matched
  final int totalSymptoms;

  const DiseaseMatch({
    required this.disease,
    required this.score,
    required this.matchCount,
    required this.totalSymptoms,
  });

  int get pct => (score * 100).round().clamp(0, 100);
}

// ─── Symptom entry (kept for API compat) ─────────────────────────────────────

class SymptomEntry {
  final String name;
  final int severity;
  const SymptomEntry({required this.name, required this.severity});
  Map<String, dynamic> toJson() => {'name': name, 'severity': severity};
}

// ─── State ────────────────────────────────────────────────────────────────────

class SymptomsState {
  final DiseaseKnowledgeBase? kb;
  final bool kbLoading;

  final Set<String> selected;          // selected symptom keys
  final List<DiseaseMatch> matches;    // detection results (top 5)
  final bool analysed;                 // has user clicked analyse

  final List<Map<String, dynamic>> recentLogs;
  final bool isLogging;
  final String? error;

  const SymptomsState({
    this.kb,
    this.kbLoading = false,
    this.selected = const {},
    this.matches = const [],
    this.analysed = false,
    this.recentLogs = const [],
    this.isLogging = false,
    this.error,
  });

  SymptomsState copyWith({
    DiseaseKnowledgeBase? kb,
    bool? kbLoading,
    Set<String>? selected,
    List<DiseaseMatch>? matches,
    bool? analysed,
    List<Map<String, dynamic>>? recentLogs,
    bool? isLogging,
    String? error,
    bool clearError = false,
  }) =>
      SymptomsState(
        kb: kb ?? this.kb,
        kbLoading: kbLoading ?? this.kbLoading,
        selected: selected ?? this.selected,
        matches: matches ?? this.matches,
        analysed: analysed ?? this.analysed,
        recentLogs: recentLogs ?? this.recentLogs,
        isLogging: isLogging ?? this.isLogging,
        error: clearError ? null : (error ?? this.error),
      );

  List<String> get allSymptoms => kb?.allSymptoms ?? [];
  bool isSelected(String s) => selected.contains(s);
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SymptomsNotifier extends StateNotifier<SymptomsState> {
  final ApiClient _client;

  SymptomsNotifier(this._client) : super(const SymptomsState()) {
    _loadKb();
  }

  // ── Load knowledge base from asset ──────────────────────────────────────
  Future<void> _loadKb() async {
    state = state.copyWith(kbLoading: true);
    try {
      final raw = await rootBundle.loadString('assets/data/disease_kb.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final diseasesJson = json['diseases'] as Map<String, dynamic>;
      final diseases = diseasesJson.map((k, v) =>
          MapEntry(k, DiseaseInfo.fromJson(k, v as Map<String, dynamic>)));

      final allSymptoms =
          List<String>.from(json['all_symptoms'] as List);

      state = state.copyWith(
        kbLoading: false,
        kb: DiseaseKnowledgeBase(diseases: diseases, allSymptoms: allSymptoms),
      );
    } catch (_) {
      // Asset missing or malformed — use a minimal built-in KB so the
      // symptoms screen doesn't show a fatal error.
      state = state.copyWith(
        kbLoading: false,
        kb: DiseaseKnowledgeBase(
          allSymptoms: _builtInSymptoms,
          diseases: _builtInDiseases,
        ),
      );
    }
  }

  // Minimal fallback so the screen works even without the JSON asset file.
  static const _builtInSymptoms = [
    'fever', 'cough', 'headache', 'fatigue', 'nausea',
    'vomiting', 'diarrhea', 'sore throat', 'runny nose',
    'chest pain', 'shortness of breath', 'dizziness', 'rash',
    'back pain', 'abdominal pain', 'muscle pain', 'joint pain',
    'loss of appetite', 'sweating', 'chills',
  ];

  static final _builtInDiseases = <String, DiseaseInfo>{
    'Common Cold': DiseaseInfo.fromJson('Common Cold', {
      'symptoms': ['cough', 'runny nose', 'sore throat', 'fatigue'],
      'description': 'A viral infection of the upper respiratory tract.',
      'recommendation': 'Rest, fluids, and OTC medication.',
    }),
    'Influenza': DiseaseInfo.fromJson('Influenza', {
      'symptoms': ['fever', 'cough', 'muscle pain', 'fatigue', 'headache'],
      'description': 'A contagious respiratory illness caused by flu viruses.',
      'recommendation': 'Rest, fluids. See a doctor if symptoms are severe.',
    }),
    'Gastroenteritis': DiseaseInfo.fromJson('Gastroenteritis', {
      'symptoms': ['nausea', 'vomiting', 'diarrhea', 'abdominal pain'],
      'description': 'Inflammation of the stomach and intestines.',
      'recommendation': 'Stay hydrated. Seek care if symptoms persist.',
    }),
  };

  // ── Toggle symptom selection ─────────────────────────────────────────────
  void toggleSymptom(String name) {
    final next = Set<String>.from(state.selected);
    if (next.contains(name)) {
      next.remove(name);
    } else {
      next.add(name);
    }
    // Reset analysis when selection changes
    state = state.copyWith(selected: next, analysed: false, matches: []);
  }

  void clearAll() {
    state = state.copyWith(
      selected: {},
      matches: [],
      analysed: false,
      clearError: true,
    );
  }

  // ── Run local symptom-matching detection ─────────────────────────────────
  void analyse() {
    final kb = state.kb;
    if (kb == null || state.selected.isEmpty) return;

    final selected = state.selected;
    final results = <DiseaseMatch>[];

    for (final d in kb.diseases.values) {
      if (d.symptoms.isEmpty) continue;

      final dSymSet = d.symptoms.toSet();
      final intersection = selected.intersection(dSymSet);
      if (intersection.isEmpty) continue;

      // Jaccard-like: intersection / union, but weighted toward disease coverage
      // so matching 3/5 disease symptoms is ranked higher than 3/20
      final coverage = intersection.length / d.symptoms.length; // recall
      final precision = intersection.length / selected.length;  // precision
      // F1-like harmonic mean, boosted toward coverage (recall)
      final score = intersection.length >= 1
          ? (2 * precision * coverage / (precision + coverage + 1e-9)).clamp(0.0, 1.0)
          : 0.0;

      results.add(DiseaseMatch(
        disease: d,
        score: score,
        matchCount: intersection.length,
        totalSymptoms: d.symptoms.length,
      ));
    }

    // Sort by score descending, take top 5
    results.sort((a, b) => b.score.compareTo(a.score));
    final top = results.take(5).toList();

    state = state.copyWith(matches: top, analysed: true);
  }

  // ── Log symptoms to backend (kept for history) ───────────────────────────
  Future<bool> logSymptoms() async {
    if (state.selected.isEmpty) return false;
    state = state.copyWith(isLogging: true, clearError: true);
    try {
      await _client.post('/symptoms', data: {
        'symptoms': state.selected
            .map((s) => SymptomEntry(name: s, severity: 5).toJson())
            .toList(),
      });
      state = state.copyWith(isLogging: false);
      return true;
    } catch (_) {
      state = state.copyWith(isLogging: false, error: 'Failed to log symptoms');
      return false;
    }
  }

  Future<void> loadRecentLogs() async {
    try {
      final response =
          await _client.get('/symptoms', queryParameters: {'limit': 10});
      final data = response.data as Map<String, dynamic>;
      state = state.copyWith(
        recentLogs:
            List<Map<String, dynamic>>.from(data['logs'] as List? ?? []),
      );
    } catch (_) {}
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final symptomsProvider =
    StateNotifierProvider<SymptomsNotifier, SymptomsState>((ref) {
  return SymptomsNotifier(ref.watch(apiClientProvider));
});
