import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/health_card.dart';
import '../providers/sleep_provider.dart';

class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int _quality = 3;
  bool _isSaving = false;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sleepProvider.notifier).loadRecent());
  }

  double _calculateDuration() {
    final bedMinutes = _bedtime.hour * 60 + _bedtime.minute;
    var wakeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;
    if (wakeMinutes <= bedMinutes) wakeMinutes += 24 * 60;
    return (wakeMinutes - bedMinutes) / 60.0;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    // ── FIX: Correct date construction for bedtime / wake time ─────────────
    // Bedtime (e.g. 23:00) is typically the previous calendar day relative
    // to wake time (e.g. 07:00 the next morning).
    // We compute sleepStart as today-at-bedtime, then check:
    //   • if wakeTime > bedTime → they're on the SAME calendar day (e.g. nap)
    //   • if wakeTime ≤ bedTime → sleep crosses midnight, so sleepStart was yesterday
    final now = DateTime.now();
    final bedMinutes = _bedtime.hour * 60 + _bedtime.minute;
    final wakeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;
    final crossesMidnight = wakeMinutes <= bedMinutes;

    final sleepStart = crossesMidnight
        ? DateTime(now.year, now.month, now.day - 1, _bedtime.hour, _bedtime.minute)
        : DateTime(now.year, now.month, now.day, _bedtime.hour, _bedtime.minute);
    final sleepEnd = DateTime(
      now.year,
      now.month,
      now.day,
      _wakeTime.hour,
      _wakeTime.minute,
    );
    final ok = await ref.read(sleepProvider.notifier).logSleep(
          sleepStart: sleepStart,
          sleepEnd: sleepEnd,
          quality: _quality,
        );
    setState(() {
      _isSaving = false;
      _showForm = false;
    });
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sleep logged!'),
            backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sleepProvider);
    final duration = _calculateDuration();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sleep Tracker'),
        // Back button is auto-provided by Navigator when pushed on the stack.
        // When accessed as a tab, there is no back button (correct behavior).
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showForm ? Icons.close_rounded : Icons.add_rounded,
                key: ValueKey(_showForm),
              ),
            ),
            onPressed: () => setState(() => _showForm = !_showForm),
            tooltip: _showForm ? 'Cancel' : 'Log sleep',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Sleep clock dial (hides when the log form is open) ───────
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showForm ? 0.0 : 1.0,
                child: _showForm
                    ? const SizedBox.shrink()
                    : _SleepClockCard(
                        hours: state.lastNightHours,
                        quality: state.lastNightQuality,
                        bedtime: _bedtime,
                        wakeTime: _wakeTime,
                      ),
              ),
            ),

            if (!_showForm) const SizedBox(height: 20),

            // ── Log form ────────────────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _showForm
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: HealthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Log Sleep',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeSelector(
                            label: 'Bedtime',
                            time: _bedtime,
                            icon: Icons.nights_stay_outlined,
                            onChanged: (t) =>
                                setState(() => _bedtime = t),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _TimeSelector(
                            label: 'Wake Time',
                            time: _wakeTime,
                            icon: Icons.wb_sunny_outlined,
                            onChanged: (t) =>
                                setState(() => _wakeTime = t),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time_rounded,
                              color: AppColors.accent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Duration: ${duration.toStringAsFixed(1)} hours',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sleep Quality',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _quality = star),
                          child: Icon(
                            star <= _quality
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: star <= _quality
                                ? Colors.amber
                                : AppColors.divider,
                            size: 36,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'Save Sleep Log',
                      isLoading: _isSaving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── TODAY's sleep only — full history is in Reports tab ────────
            const SectionHeader(title: "Today's Sleep"),
            const SizedBox(height: 14),

            if (state.todayLog != null)
              _TodaySleepCard(log: state.todayLog!)
            else
              HealthCard(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  const Text('💡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No sleep recorded yet today.\n'
                      'Tap + above to log last night\'s sleep.\n'
                      'Full history is in the Reports tab.',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5),
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Today Sleep Card ─────────────────────────────────────────────────────────

class _TodaySleepCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _TodaySleepCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final startStr = log['sleep_start'] as String?;
    final endStr   = log['sleep_end']   as String?;
    final hours    = SleepState.safeDuration(log);
    final quality  = (log['quality'] as num?)?.toInt() ?? 0;

    DateTime? start, end;
    try { if (startStr != null) start = DateTime.parse(startStr); } catch (_) {}
    try { if (endStr   != null) end   = DateTime.parse(endStr);   } catch (_) {}

    final bedStr  = start != null ? TimeOfDay.fromDateTime(start).format(context) : '—';
    final wakeStr = end   != null ? TimeOfDay.fromDateTime(end).format(context)   : '—';

    final Color qColor = hours >= 7
        ? const Color(0xFF16A34A)
        : hours >= 5 ? const Color(0xFFF59E0B) : AppColors.rose500;

    return HealthCard(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.bedtime_rounded,
                color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Last Night',
                  style: TextStyle(fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text('$bedStr → $wakeStr',
                  style: const TextStyle(fontSize: 12,
                      color: AppColors.textSecondary)),
            ],
          )),
          Text('${hours.toStringAsFixed(1)}h',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  color: qColor)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (hours / 8.0).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(qColor),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: List.generate(5, (i) => Icon(
            i < quality ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber, size: 15))),
          Text(
            hours >= 7 ? '✅ Goal met'
                : '${(8 - hours).clamp(0, 8).toStringAsFixed(1)}h short of 8h',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: qColor)),
        ]),
      ]),
    );
  }
}

class _SleepClockCard extends StatelessWidget {
  final double hours;
  final int quality;
  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;

  const _SleepClockCard({
    required this.hours,
    required this.quality,
    required this.bedtime,
    required this.wakeTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Compact dial — fixed 200×200, centred ─────────────────
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: _SleepDialPainter(
                  bedtime: bedtime,
                  wakeTime: wakeTime,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.nights_stay_rounded,
                          color: AppColors.primaryDark, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        '${hours.toStringAsFixed(1)}h',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'Last night',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DialPill(
                  icon: Icons.nights_stay_outlined,
                  label: 'Bedtime',
                  value: bedtime.format(context),
                  bg: AppColors.medsBg,
                  fg: AppColors.medsFg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DialPill(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Wake-up',
                  value: wakeTime.format(context),
                  bg: AppColors.sleepBg,
                  fg: AppColors.sleepFg,
                ),
              ),
            ],
          ),
          if (quality > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < quality
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < quality ? Colors.amber : AppColors.divider,
                    size: 18,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _DialPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  const _DialPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: fg, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepDialPainter extends CustomPainter {
  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;

  _SleepDialPainter({required this.bedtime, required this.wakeTime});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 18;

    // Track
    final track = Paint()
      ..color = AppColors.light
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);

    // Hour ticks
    final tick = Paint()
      ..color = AppColors.textHint.withOpacity(0.4)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * math.pi - math.pi / 2;
      final isMajor = i % 6 == 0;
      final inner = r - (isMajor ? 4 : 2);
      final outer = r + (isMajor ? 4 : 2);
      canvas.drawLine(
        Offset(c.dx + math.cos(angle) * inner,
            c.dy + math.sin(angle) * inner),
        Offset(c.dx + math.cos(angle) * outer,
            c.dy + math.sin(angle) * outer),
        tick,
      );
    }

    // Sleep arc (from bedtime to wakeTime, going clockwise on a 24h dial)
    final bedFrac =
        (bedtime.hour * 60 + bedtime.minute) / (24 * 60);
    final wakeFrac =
        (wakeTime.hour * 60 + wakeTime.minute) / (24 * 60);
    final start = bedFrac * 2 * math.pi - math.pi / 2;
    var sweep = (wakeFrac - bedFrac) * 2 * math.pi;
    if (sweep <= 0) sweep += 2 * math.pi;

    final arc = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF8AD3A8), Color(0xFF6BBE8E)],
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep,
      false,
      arc,
    );

    // Endpoint dots: moon at bedtime, sun at wake
    final bedPos = Offset(
        c.dx + math.cos(start) * r, c.dy + math.sin(start) * r);
    final wakePos = Offset(
        c.dx + math.cos(start + sweep) * r,
        c.dy + math.sin(start + sweep) * r);

    final knob = Paint()..color = Colors.white;
    canvas.drawCircle(bedPos, 9, knob);
    canvas.drawCircle(wakePos, 9, knob);
    final knobBorder = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(bedPos, 9, knobBorder);
    canvas.drawCircle(wakePos, 9, knobBorder);
  }

  @override
  bool shouldRepaint(covariant _SleepDialPainter old) =>
      old.bedtime != bedtime || old.wakeTime != wakeTime;
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final IconData icon;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimeSelector({
    required this.label,
    required this.time,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                  primary: AppColors.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
