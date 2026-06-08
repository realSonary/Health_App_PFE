import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/smartwatch_provider.dart';

class SmartWatchScreen extends ConsumerStatefulWidget {
  const SmartWatchScreen({super.key});

  @override
  ConsumerState<SmartWatchScreen> createState() => _SmartWatchScreenState();
}

class _SmartWatchScreenState extends ConsumerState<SmartWatchScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  final _hostCtrl = TextEditingController(text: 'localhost');
  final _portCtrl = TextEditingController(text: '8765');

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(watchProvider);
    final notifier = ref.read(watchProvider.notifier);
    final connected = s.status == WatchStatus.connected;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header ─────────────────────────────────────────────────────
            _buildHeader(s.status),

            const SizedBox(height: 20),

            // ── Main card ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: connected && s.metrics != null
                  ? _ConnectedFace(metrics: s.metrics!, pulseCtrl: _pulseCtrl)
                  : _ConnectCard(
                      status: s.status,
                      error: s.errorMessage,
                      hostCtrl: _hostCtrl,
                      portCtrl: _portCtrl,
                      onConnect: () => notifier.connect(
                        host: _hostCtrl.text.trim(),
                        port: int.tryParse(_portCtrl.text.trim()) ?? 8765,
                      ),
                    ),
            ),

            // ── Metrics grid ────────────────────────────────────────────────
            if (connected && s.metrics != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _MetricsGrid(m: s.metrics!),
              ),
              if (s.heartRateHistory.length > 2) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _HrChart(history: s.heartRateHistory),
                ),
              ],
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _BottomActions(
                  autoSync: s.autoSync,
                  onToggle: notifier.toggleAutoSync,
                  onDisconnect: notifier.disconnect,
                ),
              ),
            ],

            const SizedBox(height: 100),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(WatchStatus status) {
    final (label, color) = switch (status) {
      WatchStatus.connected    => ('● Live',        const Color(0xFF4ADE80)),
      WatchStatus.connecting   => ('◌ Connecting…', const Color(0xFFFBBF24)),
      WatchStatus.error        => ('✕ Error',        const Color(0xFFFF4F6A)),
      WatchStatus.disconnected => ('○ Disconnected', Colors.white38),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Smart Watch',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 2),
          const Text('Health & fitness metrics',
              style: TextStyle(fontSize: 11, color: Colors.white38)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: color)),
        ),
      ]),
    );
  }
}

// ─── Connect Card ─────────────────────────────────────────────────────────────

class _ConnectCard extends StatefulWidget {
  final WatchStatus status;
  final String? error;
  final TextEditingController hostCtrl;
  final TextEditingController portCtrl;
  final VoidCallback onConnect;

  const _ConnectCard({
    required this.status,
    required this.error,
    required this.hostCtrl,
    required this.portCtrl,
    required this.onConnect,
  });

  @override
  State<_ConnectCard> createState() => _ConnectCardState();
}

class _ConnectCardState extends State<_ConnectCard> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    final connecting = widget.status == WatchStatus.connecting;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1845), Color(0xFF160D2A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A1845).withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
          child: Column(children: [

            // Watch icon
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.12), width: 1.5),
              ),
              alignment: Alignment.center,
              child: connecting
                  ? const SizedBox(
                      width: 36, height: 36,
                      child: CircularProgressIndicator(
                          color: Colors.white70, strokeWidth: 2.5))
                  : const Text('⌚', style: TextStyle(fontSize: 40)),
            ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.85),

            const SizedBox(height: 22),

            Text('Connect Health Data',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
                textAlign: TextAlign.center),

            const SizedBox(height: 10),

            Text(
              'Pull heart rate, blood pressure, SpO₂, steps, sleep, '
              'and more from your wearable device.',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.55),
                  height: 1.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 26),

            // Connect button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: connecting ? null : widget.onConnect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white60, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: connecting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Connecting…',
                              style: TextStyle(fontSize: 13)),
                        ],
                      )
                    : const Text('Connect Health & Fitness',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),

            if (widget.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Text(widget.error!,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.redAccent),
                    textAlign: TextAlign.center),
              ),
            ],

            const SizedBox(height: 14),

            // Settings toggle
            GestureDetector(
              onTap: () =>
                  setState(() => _showSettings = !_showSettings),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      _showSettings
                          ? Icons.expand_less_rounded
                          : Icons.tune_rounded,
                      color: Colors.white24, size: 14),
                  const SizedBox(width: 4),
                  const Text('Simulator settings',
                      style: TextStyle(
                          fontSize: 11, color: Colors.white24)),
                ],
              ),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _showSettings
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(children: [
                        Expanded(
                            flex: 3,
                            child: _DarkField(
                                ctrl: widget.hostCtrl,
                                label: 'Host / IP')),
                        const SizedBox(width: 8),
                        Expanded(
                            flex: 1,
                            child: _DarkField(
                                ctrl: widget.portCtrl,
                                label: 'Port',
                                numeric: true)),
                      ]),
                    )
                  : const SizedBox.shrink(),
            ),
          ]),
        ),

        // Privacy footer
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Text(
            'Uses Bluetooth LE on mobile, or WebSocket simulator on web/desktop.\n'
            'Only read access — your data stays on your device.',
            style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.28),
                height: 1.6),
            textAlign: TextAlign.center,
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
  }
}

// ─── Connected Face ───────────────────────────────────────────────────────────

class _ConnectedFace extends StatelessWidget {
  final WatchMetrics metrics;
  final AnimationController pulseCtrl;
  const _ConnectedFace({required this.metrics, required this.pulseCtrl});

  String _fmt(int v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1845), Color(0xFF160D2A)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        // Connected badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF4ADE80).withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: const Color(0xFF4ADE80).withOpacity(0.4)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle, size: 7, color: Color(0xFF4ADE80)),
            SizedBox(width: 5),
            Text('Connected · Live',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4ADE80))),
          ]),
        ),

        const SizedBox(height: 20),

        // Pulsing watch face
        AnimatedBuilder(
          animation: pulseCtrl,
          builder: (_, __) => Transform.scale(
            scale: 0.97 + pulseCtrl.value * 0.035,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF3A2260), Color(0xFF160D2A)],
                ),
                border: Border.all(
                    color: const Color(0xFF4ADE80).withOpacity(0.5),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ADE80).withOpacity(0.18),
                    blurRadius: 22,
                    spreadRadius: 3,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text('${metrics.heartRate}',
                    style: GoogleFonts.sourceCodePro(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFF4F6A))),
                const Text('BPM',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.white38,
                        letterSpacing: 2)),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Quick stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _QStat('🚶', _fmt(metrics.steps), 'steps'),
            _QStat('🔥', '${metrics.calories}', 'kcal'),
            _QStat('🫀', '${metrics.spo2}%', 'SpO₂'),
            _QStat('🔋', '${metrics.battery}%', 'bat'),
          ],
        ),
      ]),
    );
  }
}

class _QStat extends StatelessWidget {
  final String emoji, value, label;
  const _QStat(this.emoji, this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 16)),
    const SizedBox(height: 3),
    Text(value,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
    Text(label,
        style: const TextStyle(fontSize: 9, color: Colors.white38)),
  ]);
}

// ─── Metrics Grid ─────────────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  final WatchMetrics m;
  const _MetricsGrid({required this.m});

  String _fmt(int v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';
  String _stress(int v) => v < 30 ? 'Low' : v < 60 ? 'Med' : 'High';
  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.6,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      _MTile('❤️', 'Heart Rate', '${m.heartRate}', 'BPM',
          const Color(0xFFFF4F6A), const Color(0xFF1E0A0E)),
      _MTile('🚶', 'Steps', _fmt(m.steps), 'today',
          const Color(0xFF4ADE80), const Color(0xFF091A0F)),
      _MTile('🔥', 'Calories', '${m.calories}', 'kcal',
          const Color(0xFFFB923C), const Color(0xFF1A0E06)),
      _MTile('🫀', 'SpO₂', '${m.spo2}', '%',
          const Color(0xFF60A5FA), const Color(0xFF060F1A)),
      _MTile('🧠', 'Stress', _stress(m.stress), '${m.stress}/100',
          const Color(0xFFA78BFA), const Color(0xFF100A1A)),
      _MTile('🏃', 'Activity', _cap(m.activity), '',
          const Color(0xFFF59E0B), const Color(0xFF160F02)),
    ],
  );
}

class _MTile extends StatelessWidget {
  final String emoji, label, value, unit;
  final Color color, bg;
  const _MTile(this.emoji, this.label, this.value, this.unit, this.color, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: Colors.white38)),
        ]),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(unit,
                  style: const TextStyle(
                      fontSize: 9, color: Colors.white38)),
            ),
          ],
        ]),
      ],
    ),
  );
}

// ─── HR Chart ─────────────────────────────────────────────────────────────────

class _HrChart extends StatelessWidget {
  final List<int> history;
  const _HrChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final maxV = history.reduce(math.max).toDouble();
    final minV = history.reduce(math.min).toDouble();
    final range = (maxV - minV).clamp(10.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFFF4F6A).withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('❤️  Heart Rate (Live)',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70)),
          Text('${history.last} BPM',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF4F6A))),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: CustomPaint(
            painter: _ChartPainter(
                values: history, maxV: maxV, minV: minV, range: range),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Min ${minV.toInt()} BPM',
              style: const TextStyle(fontSize: 9, color: Colors.white24)),
          Text('Max ${maxV.toInt()} BPM',
              style: const TextStyle(fontSize: 9, color: Colors.white24)),
        ]),
      ]),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<int> values;
  final double maxV, minV, range;
  const _ChartPainter(
      {required this.values,
      required this.maxV,
      required this.minV,
      required this.range});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final linePaint = Paint()
      ..color = const Color(0xFFFF4F6A)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF4F6A).withOpacity(0.25),
          const Color(0xFFFF4F6A).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePath = Path();
    final fillPath = Path();
    final step = size.width / (values.length - 1);

    double y(int v) =>
        size.height - ((v - minV) / range) * size.height * 0.85;

    linePath.moveTo(0, y(values.first));
    fillPath
      ..moveTo(0, size.height)
      ..lineTo(0, y(values.first));

    for (var i = 1; i < values.length; i++) {
      final x = i * step;
      final px = (i - 1) * step;
      linePath.cubicTo(
          px + step * 0.5, y(values[i - 1]),
          x - step * 0.5, y(values[i]),
          x, y(values[i]));
      fillPath.cubicTo(
          px + step * 0.5, y(values[i - 1]),
          x - step * 0.5, y(values[i]),
          x, y(values[i]));
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas
      ..drawPath(fillPath, fillPaint)
      ..drawPath(linePath, linePaint)
      ..drawCircle(
          Offset(size.width, y(values.last)),
          4,
          Paint()..color = const Color(0xFFFF4F6A))
      ..drawCircle(
          Offset(size.width, y(values.last)),
          7,
          Paint()
            ..color = const Color(0xFFFF4F6A).withOpacity(0.2)
            ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.values != values;
}

// ─── Bottom Actions ───────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final bool autoSync;
  final VoidCallback onToggle;
  final VoidCallback onDisconnect;
  const _BottomActions(
      {required this.autoSync,
      required this.onToggle,
      required this.onDisconnect});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: autoSync
                  ? const Color(0xFF4ADE80).withOpacity(0.3)
                  : Colors.white12),
        ),
        child: Row(children: [
          const Text('🔄', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
              child: const Text('Auto-Sync',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70))),
          Switch.adaptive(
            value: autoSync,
            onChanged: (_) => onToggle(),
            activeColor: const Color(0xFF4ADE80),
            inactiveTrackColor: Colors.white12,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ]),
      ),
    ),
    const SizedBox(width: 10),
    GestureDetector(
      onTap: onDisconnect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0008),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFFF4F6A).withOpacity(0.3)),
        ),
        child: const Text('Disconnect',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF4F6A))),
      ),
    ),
  ]);
}

// ─── Dark text field ──────────────────────────────────────────────────────────

class _DarkField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool numeric;
  const _DarkField(
      {required this.ctrl, required this.label, this.numeric = false});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(fontSize: 9, color: Colors.white38)),
      const SizedBox(height: 3),
      TextField(
        controller: ctrl,
        keyboardType:
            numeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 12, color: Colors.white),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 9),
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xFF4ADE80), width: 1.5)),
        ),
      ),
    ],
  );
}
