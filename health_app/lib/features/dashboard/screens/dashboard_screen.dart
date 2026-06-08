import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/scaffold_tab_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../medications/providers/medication_provider.dart';
import '../../sleep/providers/sleep_provider.dart';
import '../../water/providers/water_provider.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final sleepState  = ref.watch(sleepProvider);
    final waterState  = ref.watch(waterProvider);

    final profile    = profileAsync.valueOrNull;
    final nameParts  = (profile?.fullName ?? '').trim().split(' ');
    final firstName  = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName   = nameParts.length > 1 ? nameParts.last : '';

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning,'
        : hour < 17 ? 'Good afternoon,'
        : 'Good evening,';

    final sleepGoal = 8.0;
    final sleepPct  = (sleepState.lastNightHours / sleepGoal).clamp(0.0, 1.0);
    final waterPct  = (waterState.totalMl / AppConstants.dailyWaterGoalMl).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _GradientHeader(
              greeting: greeting,
              firstName: firstName,
              lastName: lastName,
              sleepPct: sleepPct,
              waterPct: waterPct,
              sleepHours: sleepState.lastNightHours,
              waterMl: waterState.totalMl,
            ),
          ),

          // ── Body cards ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── 1. Quick actions (buttons first as requested) ─────────
                _QuickActionsRow()
                    .animate().fadeIn(delay: 80.ms, duration: 400.ms)
                    .slideY(begin: 0.06, end: 0),

                const SizedBox(height: 14),

                // ── 2. Sleep & Water ring cards ───────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _RingCard(
                        label: 'Sleep',
                        emoji: '🌙',
                        pct: sleepPct,
                        value: sleepState.lastNightHours == 0
                            ? '—'
                            : '${sleepState.lastNightHours.toStringAsFixed(1)}h',
                        sub: 'Goal: ${sleepGoal.toStringAsFixed(0)}h',
                        ringColor: AppColors.sage500,
                        bgColor: AppColors.sage100,
                        onTap: () => context.push('/sleep'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RingCard(
                        label: 'Hydration',
                        emoji: '💧',
                        pct: waterPct,
                        value: '${(waterState.totalMl / 1000).toStringAsFixed(1)}L',
                        sub: 'Goal: ${(AppConstants.dailyWaterGoalMl / 1000).toStringAsFixed(1)}L',
                        ringColor: const Color(0xFF42A5F5),
                        bgColor: const Color(0xFFE3F2FD),
                        onTap: () => ref.read(scaffoldTabProvider.notifier).state = 2,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 160.ms, duration: 400.ms)
                    .slideY(begin: 0.06, end: 0),

                const SizedBox(height: 14),

                // ── 3. Medications ────────────────────────────────────────
                _DynamicMedicationsCard()
                    .animate().fadeIn(delay: 240.ms, duration: 400.ms)
                    .slideY(begin: 0.06, end: 0),

                const SizedBox(height: 14),

                // ── 4. AI Health Insights (second-to-last as requested) ───
                _AiInsightsCard(
                  waterMl: waterState.totalMl,
                  sleepHours: sleepState.lastNightHours,
                  sleepPct: sleepPct,
                  waterPct: waterPct,
                ).animate().fadeIn(delay: 320.ms, duration: 400.ms)
                    .slideY(begin: 0.06, end: 0),

                const SizedBox(height: 14),

                // ── 5. Tip banner (last as requested) ────────────────────
                const _TipBanner()
                    .animate().fadeIn(delay: 400.ms, duration: 400.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gradient Header ──────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final String greeting;
  final String firstName;
  final String lastName;
  final double sleepPct;
  final double waterPct;
  final double sleepHours;
  final int waterMl;

  const _GradientHeader({
    required this.greeting,
    required this.firstName,
    required this.lastName,
    required this.sleepPct,
    required this.waterPct,
    required this.sleepHours,
    required this.waterMl,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.plum900, AppColors.plum700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row (no bell — moved to Notifications screen)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.55),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: firstName,
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3),
                        ),
                        if (lastName.isNotEmpty)
                          TextSpan(
                            text: ' $lastName',
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                                letterSpacing: -0.3),
                          ),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _HeaderStat(
                emoji: '🌙',
                label: 'Sleep',
                value: sleepHours == 0
                    ? 'Not logged'
                    : '${sleepHours.toStringAsFixed(1)}h',
                pct: sleepPct,
                barColor: AppColors.sage400,
              ),
              const SizedBox(width: 10),
              _HeaderStat(
                emoji: '💧',
                label: 'Water',
                value: '${(waterMl / 1000).toStringAsFixed(1)} L',
                pct: waterPct,
                barColor: const Color(0xFF64B5F6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final double pct;
  final Color barColor;

  const _HeaderStat({
    required this.emoji,
    required this.label,
    required this.value,
    required this.pct,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 4,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AI Health Insights Card ──────────────────────────────────────────────────

class _Insight {
  final String emoji;
  final String title;
  final String body;
  final Color color;
  final Color borderColor;

  const _Insight({
    required this.emoji,
    required this.title,
    required this.body,
    required this.color,
    required this.borderColor,
  });
}

class _AiInsightsCard extends StatelessWidget {
  final int waterMl;
  final double sleepHours;
  final double sleepPct;
  final double waterPct;

  const _AiInsightsCard({
    required this.waterMl,
    required this.sleepHours,
    required this.sleepPct,
    required this.waterPct,
  });

  List<_Insight> _buildInsights() {
    final insights = <_Insight>[];

    // Sleep insight
    if (sleepHours == 0) {
      insights.add(const _Insight(
        emoji: '🌙',
        title: 'No sleep logged yet',
        body: 'Log tonight\'s sleep to get personalised rest insights.',
        color: AppColors.plum50,
        borderColor: AppColors.plum200,
      ));
    } else if (sleepHours < 6) {
      insights.add(_Insight(
        emoji: '⚠️',
        title: 'You\'re sleep-deprived',
        body: 'Only ${sleepHours.toStringAsFixed(1)}h recorded. Aim for 7–9 h. Try a screen-free 30-min wind-down.',
        color: AppColors.rose50,
        borderColor: AppColors.rose200,
      ));
    } else if (sleepHours < 7) {
      insights.add(_Insight(
        emoji: '😴',
        title: 'Slightly under target',
        body: '${sleepHours.toStringAsFixed(1)}h is close but a bit short. Try going to bed 30 min earlier tonight.',
        color: AppColors.plum50,
        borderColor: AppColors.plum200,
      ));
    } else {
      insights.add(_Insight(
        emoji: '✅',
        title: 'Great sleep last night!',
        body: '${sleepHours.toStringAsFixed(1)}h is within the healthy range. Keep the same schedule for consistency.',
        color: AppColors.sage50,
        borderColor: AppColors.sage200,
      ));
    }

    // Hydration insight
    if (waterMl == 0) {
      insights.add(const _Insight(
        emoji: '💧',
        title: 'Start hydrating now',
        body: 'You haven\'t logged any water today. Drink a glass to begin!',
        color: Color(0xFFE3F2FD),
        borderColor: Color(0xFF90CAF9),
      ));
    } else if (waterPct < 0.5) {
      insights.add(_Insight(
        emoji: '💦',
        title: 'Hydration below 50%',
        body: '${(waterMl / 1000).toStringAsFixed(2)} L consumed. Drink 2–3 more glasses to stay on track.',
        color: const Color(0xFFE3F2FD),
        borderColor: const Color(0xFF90CAF9),
      ));
    } else if (waterPct < 1.0) {
      insights.add(_Insight(
        emoji: '🥤',
        title: 'Almost at your water goal!',
        body: '${(waterMl / 1000).toStringAsFixed(2)} L done. Keep going — you\'re nearly there!',
        color: const Color(0xFFE3F2FD),
        borderColor: const Color(0xFF90CAF9),
      ));
    } else {
      insights.add(_Insight(
        emoji: '🏆',
        title: 'Hydration goal reached!',
        body: 'You\'ve hit your ${(AppConstants.dailyWaterGoalMl / 1000).toStringAsFixed(1)} L goal today. Excellent work!',
        color: AppColors.sage50,
        borderColor: AppColors.sage200,
      ));
    }

    return insights.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights();
    return Container(
      decoration: cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: AppColors.plum100,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Text('🤖', style: TextStyle(fontSize: 15)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Health Insights', style: AppTextStyles.cardTitle),
                      Text('Personalised to your data today',
                          style: AppTextStyles.caption),
                    ]),
              ),
            ]),
          ),
          const Divider(height: 1),
          ...insights.map((ins) => Container(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ins.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ins.borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ins.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ins.title, style: AppTextStyles.bodySemiBold),
                            const SizedBox(height: 2),
                            Text(ins.body,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.neutral600)),
                          ]),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ─── Ring Card ────────────────────────────────────────────────────────────────

class _RingCard extends StatelessWidget {
  final String label;
  final String emoji;
  final double pct;
  final String value;
  final String sub;
  final Color ringColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _RingCard({
    required this.label,
    required this.emoji,
    required this.pct,
    required this.value,
    required this.sub,
    required this.ringColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: AppTextStyles.caption),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(9)),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 70,
              height: 70,
              child: CustomPaint(
                painter: _RingPainter(pct: pct, color: ringColor),
                child: Center(
                  child: Text(value,
                      style: AppTextStyles.num
                          .copyWith(fontSize: 14, color: AppColors.plum900)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(sub, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double pct;
  final Color color;

  _RingPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 6;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Track
    canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi,
        false,
        Paint()
          ..color = AppColors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round);

    // Progress
    if (pct > 0) {
      canvas.drawArc(
          rect,
          -math.pi / 2,
          2 * math.pi * pct,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.pct != pct || old.color != color;
}

// ─── Dynamic Medications Card ─────────────────────────────────────────────────

class _DynamicMedicationsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicationProvider);
    // Only show medications NOT yet marked as taken today
    final pending    = state.medications.where((m) => !m.isTaken).toList();
    final takenCount = state.medications.where((m) =>  m.isTaken).length;

    return Container(
      decoration: cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: AppColors.rose100,
                        borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: const Text('💊', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Medications', style: AppTextStyles.cardTitle),
                      if (takenCount > 0)
                        Text('$takenCount taken today ✓',
                            style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF16A34A),
                                fontWeight: FontWeight.w600)),
                    ],
                  ),
                ]),
                TextButton(
                  onPressed: () => context.push('/medications'),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else if (state.medications.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('💊', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text('No medications tracked yet',
                    style: AppTextStyles.bodySemiBold),
                const SizedBox(height: 4),
                Text('Add your medications to get reminders',
                    style: AppTextStyles.caption),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.push('/medications'),
                  child: const Text('Track Medications'),
                ),
              ]),
            )
          // All medications taken — show completion state
          else if (pending.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FBF4),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF16A34A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('All done for today! 🎉',
                        style: AppTextStyles.bodySemiBold
                            .copyWith(color: const Color(0xFF16A34A))),
                    Text('${state.medications.length} medication(s) taken ✓',
                        style: AppTextStyles.caption),
                  ],
                )),
              ]),
            )
          else
            // Show only pending medications (not yet taken)
            ...pending.take(3).map((med) => _MedItem(
                  name: med.name,
                  dose: med.dosage ?? '',
                  time: med.frequency ?? '',
                )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _MedItem extends StatelessWidget {
  final String name;
  final String dose;
  final String time;

  const _MedItem({required this.name, required this.dose, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppColors.rose50,
                borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('💊', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodySemiBold),
                Text(dose.isNotEmpty ? '$dose · $time' : time,
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.sage100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('Take', style: AppTextStyles.caption.copyWith(
                color: AppColors.sage700, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Row ────────────────────────────────────────────────────────

class _QuickActionsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void switchTab(int index) =>
        ref.read(scaffoldTabProvider.notifier).state = index;

    return Row(
      children: [
        _QuickAction(
          emoji: '🩺',
          label: 'Log\nSymptoms',
          color: AppColors.rose100,
          onTap: () => switchTab(1), // → Symptoms tab
        ),
        const SizedBox(width: 10),
        _QuickAction(
          emoji: '💧',
          label: 'Add\nWater',
          color: const Color(0xFFE3F2FD),
          onTap: () => switchTab(2), // → Hydration tab
        ),
        const SizedBox(width: 10),
        _QuickAction(
          emoji: '🌙',
          label: 'Log\nSleep',
          color: AppColors.sage100,
          onTap: () => context.push('/sleep'),
        ),
        const SizedBox(width: 10),
        _QuickAction(
          emoji: '💊',
          label: 'Meds',
          color: AppColors.plum100,
          onTap: () => context.push('/medications'),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tip Banner ───────────────────────────────────────────────────────────────

class _TipBanner extends StatelessWidget {
  const _TipBanner();

  static const _tips = [
    ('🚶', 'Move every hour', 'Short walks improve circulation and focus.'),
    ('🥗', 'Eat the rainbow', 'Colourful foods pack more micronutrients.'),
    ('😮‍💨', 'Box breathing', 'Inhale 4s · Hold 4s · Exhale 4s · Hold 4s.'),
    ('☀️', 'Morning sunlight', '10 min of sunlight resets your body clock.'),
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().day % _tips.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.plum800, AppColors.plum700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(tip.$1, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Tip',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white54)),
                const SizedBox(height: 2),
                Text(tip.$2,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(tip.$3,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
