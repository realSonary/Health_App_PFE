import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum WatchStatus { disconnected, connecting, connected, error }

// ─── Data Models ──────────────────────────────────────────────────────────────

class WatchMetrics {
  final int heartRate;
  final int steps;
  final int calories;
  final int spo2;
  final int battery;
  final int stress;       // 0–100
  final String activity;  // e.g. 'Walking', 'Running', 'Resting'

  const WatchMetrics({
    this.heartRate = 0,
    this.steps = 0,
    this.calories = 0,
    this.spo2 = 0,
    this.battery = 0,
    this.stress = 0,
    this.activity = 'Resting',
  });

  WatchMetrics copyWith({
    int? heartRate,
    int? steps,
    int? calories,
    int? spo2,
    int? battery,
    int? stress,
    String? activity,
  }) {
    return WatchMetrics(
      heartRate: heartRate ?? this.heartRate,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      spo2: spo2 ?? this.spo2,
      battery: battery ?? this.battery,
      stress: stress ?? this.stress,
      activity: activity ?? this.activity,
    );
  }

  factory WatchMetrics.fromJson(Map<String, dynamic> json) {
    return WatchMetrics(
      heartRate: (json['heart_rate'] as num?)?.toInt() ?? 0,
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      spo2: (json['spo2'] as num?)?.toInt() ?? 0,
      battery: (json['battery'] as num?)?.toInt() ?? 0,
      stress: (json['stress'] as num?)?.toInt() ?? 0,
      activity: (json['activity'] as String?) ?? 'Resting',
    );
  }
}

// ─── State ────────────────────────────────────────────────────────────────────

class WatchState {
  final WatchStatus status;
  final WatchMetrics? metrics;
  final String? errorMessage;
  final bool autoSync;
  final List<int> heartRateHistory;

  const WatchState({
    this.status = WatchStatus.disconnected,
    this.metrics,
    this.errorMessage,
    this.autoSync = false,
    this.heartRateHistory = const [],
  });

  WatchState copyWith({
    WatchStatus? status,
    WatchMetrics? metrics,
    String? errorMessage,
    bool clearError = false,
    bool? autoSync,
    List<int>? heartRateHistory,
  }) {
    return WatchState(
      status: status ?? this.status,
      metrics: metrics ?? this.metrics,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      autoSync: autoSync ?? this.autoSync,
      heartRateHistory: heartRateHistory ?? this.heartRateHistory,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class WatchNotifier extends StateNotifier<WatchState> {
  WatchNotifier() : super(const WatchState());

  // WebSocket / polling simulation — replace with real WebSocket logic
  // when a hardware watch is available.
  Timer? _autoSyncTimer;

  // ── Connect ───────────────────────────────────────────────────────────────

  Future<void> connect({required String host, required int port}) async {
    state = state.copyWith(
      status: WatchStatus.connecting,
      errorMessage: '',
      clearError: true,
    );

    // Simulate a connection attempt (≈ 1.5 s)
    await Future.delayed(const Duration(milliseconds: 1500));

    // In a real app you would open a WebSocket here:
    //   _socket = await WebSocket.connect('ws://$host:$port');
    // For now we succeed with simulated metrics.
    try {
      final metrics = _mockMetrics();
      state = state.copyWith(
        status: WatchStatus.connected,
        metrics: metrics,
        heartRateHistory: _initialHistory(metrics.heartRate),
      );
      if (state.autoSync) _startAutoSync();
    } catch (e) {
      state = state.copyWith(
        status: WatchStatus.error,
        errorMessage: 'Could not connect to $host:$port — $e',
      );
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  void disconnect() {
    _stopAutoSync();
    state = const WatchState();
  }

  // ── Auto-sync toggle ──────────────────────────────────────────────────────

  void toggleAutoSync() {
    final next = !state.autoSync;
    state = state.copyWith(autoSync: next);
    if (next && state.status == WatchStatus.connected) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }
  }

  // ── Periodic refresh ──────────────────────────────────────────────────────

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshMetrics(),
    );
  }

  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  void _refreshMetrics() {
    if (state.status != WatchStatus.connected) return;
    final metrics = _mockMetrics(base: state.metrics);
    final history = [
      ...state.heartRateHistory,
      metrics.heartRate,
    ].take(30).toList();
    state = state.copyWith(metrics: metrics, heartRateHistory: history);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static const _activities = ['Resting', 'Walking', 'Running', 'Cycling', 'Workout'];

  WatchMetrics _mockMetrics({WatchMetrics? base}) {
    final rng = math.Random();
    return WatchMetrics(
      heartRate: 60 + rng.nextInt(40),
      steps: (base?.steps ?? 0) + rng.nextInt(50),
      calories: (base?.calories ?? 0) + rng.nextInt(5),
      spo2: 95 + rng.nextInt(5),
      battery: base?.battery ?? (50 + rng.nextInt(50)),
      stress: 10 + rng.nextInt(80),
      activity: base?.activity ?? _activities[rng.nextInt(_activities.length)],
    );
  }

  List<int> _initialHistory(int seed) {
    final rng = math.Random();
    return List.generate(
      20,
      (_) => (seed - 10 + rng.nextInt(20)).clamp(40, 180),
    );
  }

  @override
  void dispose() {
    _stopAutoSync();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final watchProvider = StateNotifierProvider<WatchNotifier, WatchState>(
  (ref) => WatchNotifier(),
);
