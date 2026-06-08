// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';   // defaultTargetPlatform, kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

// ─── FIX SUMMARY ─────────────────────────────────────────────────────────────
//
//  1.  Removed `dart:io` — replaced Platform.isIOS with defaultTargetPlatform
//      which works on web, Windows, and all native platforms.
//
//  2.  Removed Health.removeDuplicates() — this static method was removed in
//      health 10.x.  Replaced with a local _deduplicate() helper that filters
//      by (type + dateFrom timestamp) uniqueness — same behaviour.
//
//  3.  Added a desktop/web guard in requestPermissions() and fetchAll() so
//      the notifier returns a safe "unsupported platform" state instead of
//      crashing when called on Windows / macOS / Linux / web.
//
//  4.  Fixed the SpO₂ normalisation: the health package already returns values
//      in [0,1] on some versions and [0,100] on others — the clamp + branch
//      now handles both.
// ─────────────────────────────────────────────────────────────────────────────

// ─── Data model ──────────────────────────────────────────────────────────────

class HealthMetricsState {
  final bool isAuthorized;
  final bool isLoading;
  final String? error;

  final double? heartRate;
  final double? systolicBP;
  final double? diastolicBP;
  final double? bloodOxygen;
  final double? bodyTemperature;
  final double? respiratoryRate;
  final int? steps;
  final double? activeCalories;
  final double? weight;
  final double? height;

  final DateTime? heartRateTime;
  final DateTime? bpTime;
  final DateTime? spo2Time;
  final DateTime? tempTime;
  final DateTime? lastSyncTime;

  final List<MetricPoint> heartRateHistory;
  final List<MetricPoint> spo2History;

  const HealthMetricsState({
    this.isAuthorized = false,
    this.isLoading = false,
    this.error,
    this.heartRate,
    this.systolicBP,
    this.diastolicBP,
    this.bloodOxygen,
    this.bodyTemperature,
    this.respiratoryRate,
    this.steps,
    this.activeCalories,
    this.weight,
    this.height,
    this.heartRateTime,
    this.bpTime,
    this.spo2Time,
    this.tempTime,
    this.lastSyncTime,
    this.heartRateHistory = const [],
    this.spo2History = const [],
  });

  HealthMetricsState copyWith({
    bool? isAuthorized,
    bool? isLoading,
    String? error,
    bool clearError = false,
    double? heartRate,
    double? systolicBP,
    double? diastolicBP,
    double? bloodOxygen,
    double? bodyTemperature,
    double? respiratoryRate,
    int? steps,
    double? activeCalories,
    double? weight,
    double? height,
    DateTime? heartRateTime,
    DateTime? bpTime,
    DateTime? spo2Time,
    DateTime? tempTime,
    DateTime? lastSyncTime,
    List<MetricPoint>? heartRateHistory,
    List<MetricPoint>? spo2History,
  }) =>
      HealthMetricsState(
        isAuthorized: isAuthorized ?? this.isAuthorized,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        heartRate: heartRate ?? this.heartRate,
        systolicBP: systolicBP ?? this.systolicBP,
        diastolicBP: diastolicBP ?? this.diastolicBP,
        bloodOxygen: bloodOxygen ?? this.bloodOxygen,
        bodyTemperature: bodyTemperature ?? this.bodyTemperature,
        respiratoryRate: respiratoryRate ?? this.respiratoryRate,
        steps: steps ?? this.steps,
        activeCalories: activeCalories ?? this.activeCalories,
        weight: weight ?? this.weight,
        height: height ?? this.height,
        heartRateTime: heartRateTime ?? this.heartRateTime,
        bpTime: bpTime ?? this.bpTime,
        spo2Time: spo2Time ?? this.spo2Time,
        tempTime: tempTime ?? this.tempTime,
        lastSyncTime: lastSyncTime ?? this.lastSyncTime,
        heartRateHistory: heartRateHistory ?? this.heartRateHistory,
        spo2History: spo2History ?? this.spo2History,
      );

  bool get hasAnyData =>
      heartRate != null ||
      systolicBP != null ||
      bloodOxygen != null ||
      steps != null ||
      bodyTemperature != null;
}

// Made public so screens can use it in charts
class MetricPoint {
  final DateTime time;
  final double value;
  const MetricPoint(this.time, this.value);
}

// ─── Types we request ────────────────────────────────────────────────────────

const _commonTypes = [
  HealthDataType.HEART_RATE,
  HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
  HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  HealthDataType.BLOOD_OXYGEN,
  HealthDataType.BODY_TEMPERATURE,
  HealthDataType.RESPIRATORY_RATE,
  HealthDataType.STEPS,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.WEIGHT,
  HealthDataType.HEIGHT,
];

// ─── Platform check ───────────────────────────────────────────────────────────

/// True only on Android and iOS — the platforms health package supports.
bool get _isSupportedPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

// ─── FIX 2: Local deduplication replacing removed Health.removeDuplicates() ─

/// Removes duplicate health data points by (type + dateFrom) key.
/// Replacement for `Health.removeDuplicates()` which was removed in
/// health package 10.x.
List<HealthDataPoint> _deduplicate(List<HealthDataPoint> data) {
  final seen = <String>{};
  return data.where((pt) {
    final key = '${pt.type.name}_${pt.dateFrom.millisecondsSinceEpoch}';
    return seen.add(key);
  }).toList();
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class HealthMetricsNotifier extends StateNotifier<HealthMetricsState> {
  HealthMetricsNotifier() : super(const HealthMetricsState());

  final Health _health = Health();

  // FIX 1: was Platform.isIOS (dart:io) — now uses defaultTargetPlatform
  // which compiles on Windows, web, and all other platforms.
  List<HealthDataType> get _types => _commonTypes;

  // ── Request authorisation ─────────────────────────────────────────────────
  Future<bool> requestPermissions() async {
    // FIX 3: graceful unsupported-platform guard
    if (!_isSupportedPlatform) {
      state = state.copyWith(
        error: 'Health data is only available on Android and iOS. '
            'This device (${defaultTargetPlatform.name}) is not supported.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _health.configure();
      final permissions = _types.map((_) => HealthDataAccess.READ).toList();
      final granted =
          await _health.requestAuthorization(_types, permissions: permissions);

      state = state.copyWith(isAuthorized: granted, isLoading: false);
      if (granted) await fetchAll();
      return granted;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Permission error: $e');
      return false;
    }
  }

  // ── Fetch all metrics ─────────────────────────────────────────────────────
  Future<void> fetchAll() async {
    if (!state.isAuthorized) return;

    // FIX 3: guard — don't call health APIs on unsupported platforms
    if (!_isSupportedPlatform) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final raw = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: sevenDaysAgo,
        endTime: now,
      );

      // FIX 2: was Health.removeDuplicates(data) — now uses local helper
      final data = _deduplicate(raw);

      // ── Helper: latest reading for a type ─────────────────────────────
      HealthDataPoint? latest(HealthDataType type) {
        final pts = data.where((d) => d.type == type).toList()
          ..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        return pts.isNotEmpty ? pts.first : null;
      }

      double? numVal(HealthDataPoint? pt) {
        if (pt == null) return null;
        final v = pt.value;
        return v is NumericHealthValue ? v.numericValue.toDouble() : null;
      }

      // ── Heart rate ────────────────────────────────────────────────────
      final hrPt = latest(HealthDataType.HEART_RATE);
      final hrHistory = data
          .where((d) => d.type == HealthDataType.HEART_RATE)
          .map((d) {
            final v = numVal(d);
            return v != null ? MetricPoint(d.dateFrom, v) : null;
          })
          .whereType<MetricPoint>()
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      // ── Blood pressure ────────────────────────────────────────────────
      final sysPt = latest(HealthDataType.BLOOD_PRESSURE_SYSTOLIC);
      final diaPt = latest(HealthDataType.BLOOD_PRESSURE_DIASTOLIC);

      // ── SpO₂ ──────────────────────────────────────────────────────────
      final spo2Pt = latest(HealthDataType.BLOOD_OXYGEN);
      double? spo2Val = numVal(spo2Pt);
      // FIX 4: health package returns 0–1 on some versions, 0–100 on others
      if (spo2Val != null && spo2Val <= 1.0) spo2Val = spo2Val * 100;
      spo2Val = spo2Val?.clamp(0, 100).toDouble();

      final spo2History = data
          .where((d) => d.type == HealthDataType.BLOOD_OXYGEN)
          .map((d) {
            var v = numVal(d);
            if (v != null && v <= 1.0) v = v * 100;
            return v != null ? MetricPoint(d.dateFrom, v.clamp(0, 100)) : null;
          })
          .whereType<MetricPoint>()
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      // ── Steps today ───────────────────────────────────────────────────
      int? stepsToday;
      try {
        stepsToday =
            await _health.getTotalStepsInInterval(startOfDay, now);
      } catch (_) {}

      // ── Active calories today ─────────────────────────────────────────
      final calToday = data
          .where((d) =>
              d.type == HealthDataType.ACTIVE_ENERGY_BURNED &&
              d.dateFrom.isAfter(startOfDay))
          .fold<double>(0.0, (sum, d) => sum + (numVal(d) ?? 0.0));

      // ── Weight & Height ───────────────────────────────────────────────
      final weightPt = latest(HealthDataType.WEIGHT);
      final heightPt = latest(HealthDataType.HEIGHT);
      final heightRaw = numVal(heightPt);
      // Normalise to cm: health package may return metres (< 3) or cm (> 3)
      final heightCm = heightRaw != null
          ? (heightRaw < 3 ? heightRaw * 100 : heightRaw)
          : null;

      state = state.copyWith(
        isLoading: false,
        lastSyncTime: now,
        heartRate: numVal(hrPt),
        heartRateTime: hrPt?.dateFrom,
        heartRateHistory: hrHistory.length > 7
            ? hrHistory.sublist(hrHistory.length - 7)
            : hrHistory,
        systolicBP: numVal(sysPt),
        diastolicBP: numVal(diaPt),
        bpTime: sysPt?.dateFrom,
        bloodOxygen: spo2Val,
        spo2Time: spo2Pt?.dateFrom,
        spo2History: spo2History.length > 7
            ? spo2History.sublist(spo2History.length - 7)
            : spo2History,
        bodyTemperature:
            numVal(latest(HealthDataType.BODY_TEMPERATURE)),
        tempTime:
            latest(HealthDataType.BODY_TEMPERATURE)?.dateFrom,
        respiratoryRate:
            numVal(latest(HealthDataType.RESPIRATORY_RATE)),
        steps: stepsToday,
        activeCalories: calToday > 0 ? calToday : null,
        weight: numVal(weightPt),
        height: heightCm,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch health data: $e',
      );
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final healthMetricsProvider =
    StateNotifierProvider<HealthMetricsNotifier, HealthMetricsState>(
        (ref) => HealthMetricsNotifier());
