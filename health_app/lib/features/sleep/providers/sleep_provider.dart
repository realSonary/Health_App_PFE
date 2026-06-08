import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class SleepState {
  final double lastNightHours;
  final int lastNightQuality; // 1–5
  final List<Map<String, dynamic>> recentLogs;
  final bool isLoading;

  const SleepState({
    this.lastNightHours = 0,
    this.lastNightQuality = 0,
    this.recentLogs = const [],
    this.isLoading = false,
  });

  SleepState copyWith({
    double? lastNightHours,
    int? lastNightQuality,
    List<Map<String, dynamic>>? recentLogs,
    bool? isLoading,
  }) {
    return SleepState(
      lastNightHours: lastNightHours ?? this.lastNightHours,
      lastNightQuality: lastNightQuality ?? this.lastNightQuality,
      recentLogs: recentLogs ?? this.recentLogs,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Weekly hours data for the analytics chart (most-recent-first → reversed for chart)
  List<double> get weeklyHours =>
      recentLogs.take(7).map((l) => safeDuration(l)).toList().reversed.toList();

  /// Labels for the weekly chart
  static List<String> get weekLabels => ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// Average sleep duration over recent logs
  double get averageHours {
    if (recentLogs.isEmpty) return 0;
    final total =
        recentLogs.map((l) => safeDuration(l)).reduce((a, b) => a + b);
    return total / recentLogs.length;
  }

  /// The sleep session whose wake-up time (sleep_end) falls on TODAY.
  /// This is the only entry shown on the Sleep screen main view.
  Map<String, dynamic>? get todayLog {
    final now = DateTime.now();
    for (final log in recentLogs) {
      final endStr = log['sleep_end'] as String?;
      if (endStr == null) continue;
      try {
        final end = DateTime.parse(endStr);
        if (end.year == now.year &&
            end.month == now.month &&
            end.day == now.day) {
          return log;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Every log EXCEPT today's — shown in Reports / Analytics history.
  List<Map<String, dynamic>> get historyLogs {
    final today = todayLog;
    if (today == null) return List.unmodifiable(recentLogs);
    return List.unmodifiable(
      recentLogs.where((l) => l != today).toList(),
    );
  }

  // ── Safely extract duration_hours from a log entry ──────────────────────
  // FIX: The backend may return duration_hours calculated incorrectly
  // (e.g. as sum of hours instead of difference). We always prefer to
  // compute from sleep_start / sleep_end when both are present, falling
  // back to duration_hours only if the computed value would be nonsensical.
  static double safeDuration(Map<String, dynamic> log) {
    final rawHours = (log['duration_hours'] as num?)?.toDouble();

    // Try computing from start/end timestamps first
    final startStr = log['sleep_start'] as String?;
    final endStr = log['sleep_end'] as String?;
    if (startStr != null && endStr != null) {
      try {
        final start = DateTime.parse(startStr);
        final end = DateTime.parse(endStr);
        final computed = end.difference(start).inMinutes / 60.0;
        // If the computed value is reasonable (0–16 h) use it
        if (computed >= 0 && computed <= 16) return computed;
      } catch (_) {}
    }

    // Fallback to server's field, guard against obviously wrong values
    if (rawHours != null && rawHours >= 0 && rawHours <= 16) return rawHours;
    return 0;
  }
}

class SleepNotifier extends StateNotifier<SleepState> {
  final ApiClient _client;

  SleepNotifier(this._client) : super(const SleepState()) {
    loadRecent();
  }

  Future<void> loadRecent() async {
    state = state.copyWith(isLoading: true);
    try {
      final response =
          await _client.get('/sleep', queryParameters: {'limit': 7});
      final data = response.data as Map<String, dynamic>;
      final logs =
          List<Map<String, dynamic>>.from(data['logs'] as List? ?? []);

      double lastHours = 0;
      int lastQuality = 0;
      if (logs.isNotEmpty) {
        lastHours = SleepState.safeDuration(logs.first);
        lastQuality = (logs.first['quality'] as num?)?.toInt() ?? 0;
      }
      state = SleepState(
        lastNightHours: lastHours,
        lastNightQuality: lastQuality,
        recentLogs: logs,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> logSleep({
    required DateTime sleepStart,
    required DateTime sleepEnd,
    required int quality,
    String? notes,
  }) async {
    // ── FIX: Compute duration correctly on the client side ──────────────────
    // This guards against backend bugs where duration_hours is calculated
    // as hour1 + hour2 (which gives ~31) instead of the actual difference.
    final durationHours =
        sleepEnd.difference(sleepStart).inMinutes / 60.0;

    // Sanity check — duration must be positive and ≤ 24 h
    if (durationHours <= 0 || durationHours > 24) return false;

    // Optimistic update so UI reflects correctly even before server responds
    state = state.copyWith(
      lastNightHours: durationHours,
      lastNightQuality: quality,
    );

    try {
      await _client.post('/sleep', data: {
        'sleep_start': sleepStart.toIso8601String(),
        'sleep_end': sleepEnd.toIso8601String(),
        'duration_hours': durationHours, // pass explicitly so backend stores correct value
        'quality': quality,
        'notes': notes,
      });
      await loadRecent();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final sleepProvider =
    StateNotifierProvider<SleepNotifier, SleepState>((ref) {
  return SleepNotifier(ref.watch(apiClientProvider));
});
