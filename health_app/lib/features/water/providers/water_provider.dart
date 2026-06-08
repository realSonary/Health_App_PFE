import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class WaterState {
  final int totalMl;
  final List<Map<String, dynamic>> logs;
  final bool isLoading;

  const WaterState({
    this.totalMl = 0,
    this.logs = const [],
    this.isLoading = false,
  });

  WaterState copyWith({int? totalMl, List<Map<String, dynamic>>? logs, bool? isLoading}) {
    return WaterState(
      totalMl: totalMl ?? this.totalMl,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // ── Compute list of glass fill fractions from totalMl ─────────────────────
  // Each glass holds 250 ml max. Returns a list of fill fractions (0.0–1.0).
  List<double> get glasses {
    if (totalMl <= 0) return [0.0];
    final result = <double>[];
    int remaining = totalMl;
    while (remaining > 0) {
      final fill = remaining.clamp(0, 250);
      result.add(fill / 250.0);
      remaining -= fill;
    }
    return result;
  }

  // Number of fully filled glasses
  int get fullGlasses => totalMl ~/ 250;

  // ml in the current (partial) glass
  int get currentGlassMl => totalMl % 250;
}

class WaterNotifier extends StateNotifier<WaterState> {
  final ApiClient _client;

  WaterNotifier(this._client) : super(const WaterState()) {
    loadToday();
  }

  Future<void> loadToday() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _client.get(
        '/water',
        queryParameters: {
          'date': DateTime.now().toIso8601String().split('T').first,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final logs = List<Map<String, dynamic>>.from(data['logs'] as List? ?? []);
      final total = (data['total_ml'] as num?)?.toInt() ?? 0;
      state = WaterState(totalMl: total, logs: logs);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Add water. Automatically fills the current glass to 250 ml and
  /// opens a new glass for the remainder.
  Future<void> addWater(int amountMl) async {
    if (amountMl <= 0) return;
    final original = state.totalMl;          // ← capture BEFORE update
    final newTotal = original + amountMl;
    state = state.copyWith(totalMl: newTotal);
    try {
      await _client.post('/water', data: {'amount_ml': amountMl});
    } catch (_) {
      state = state.copyWith(totalMl: original); // ← restore to captured value
    }
  }

  /// Remove water. Updates local state immediately and does not roll back
  /// if the API call fails — the user's action is always honoured locally.
  Future<void> removeWater(int amountMl) async {
    if (amountMl <= 0) return;
    final newTotal = (state.totalMl - amountMl).clamp(0, 99999);
    // Update UI immediately — no rollback on failure
    state = state.copyWith(totalMl: newTotal);
    try {
      // Try the standard endpoint first with a negative amount
      await _client.post('/water', data: {'amount_ml': -amountMl});
    } catch (_) {
      // Also try a dedicated remove endpoint some backends expose
      try {
        await _client.post('/water/remove', data: {'amount_ml': amountMl});
      } catch (_) {
        // If both fail (e.g. no network), keep the local change anyway.
        // The user explicitly removed water; we don't snap it back.
      }
    }
  }

  /// Reset today's water intake to zero.
  void reset() {
    state = const WaterState();
  }
}

final waterProvider =
    StateNotifierProvider<WaterNotifier, WaterState>((ref) {
  return WaterNotifier(ref.watch(apiClientProvider));
});
