import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../water/providers/water_provider.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fillController;
  late Animation<double> _fillAnim;
  double _previousFill = 0;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fillAnim = const AlwaysStoppedAnimation(0);
    Future.microtask(() => ref.read(waterProvider.notifier).loadToday());
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _fillAnim = Tween<double>(begin: _previousFill, end: target).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeOutCubic),
    );
    _fillController.forward(from: 0);
    _previousFill = target;
  }

  Future<void> _addWater() async {
    final ml = await _showAmountDialog(context, isAdding: true);
    if (ml != null && ml > 0) {
      await ref.read(waterProvider.notifier).addWater(ml);
      final glasses = ref.read(waterProvider).glasses;
      _animateTo(glasses.last);
    }
  }

  Future<void> _removeWater() async {
    final ml = await _showAmountDialog(context, isAdding: false);
    if (ml != null && ml > 0) {
      await ref.read(waterProvider.notifier).removeWater(ml);
      final glasses = ref.read(waterProvider).glasses;
      _animateTo(glasses.last);
    }
  }

  @override
  Widget build(BuildContext context) {
    final water = ref.watch(waterProvider);
    final glasses = water.glasses;
    final totalPct =
        (water.totalMl / AppConstants.dailyWaterGoalMl).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            _WaterHeader(totalMl: water.totalMl, totalPct: totalPct)
                .animate()
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // ── Daily goal progress bar ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DailyGoalBar(
                totalMl: water.totalMl,
                goalMl: AppConstants.dailyWaterGoalMl,
                pct: totalPct,
              ),
            ).animate().fadeIn(delay: 60.ms, duration: 350.ms),

            const SizedBox(height: 24),

            // ── Glasses row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Today\'s Glasses', style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: glasses.length + 1, // +1 for the "next empty" glass
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  // Empty "next" glass at the end
                  if (i == glasses.length) {
                    return AnimatedWaterGlass(
                      fillFraction: 0.0,
                      mlLabel: '0 ml',
                      isActive: false,
                      isEmpty: true,
                    ).animate().fadeIn(delay: Duration(milliseconds: 80 * i));
                  }
                  final fill = glasses[i];
                  final ml = i < glasses.length - 1
                      ? 250
                      : water.currentGlassMl == 0 && water.totalMl > 0
                          ? 250
                          : water.currentGlassMl;
                  return AnimatedWaterGlass(
                    fillFraction: fill,
                    mlLabel: '${ml} ml',
                    isActive: i == glasses.length - 1,
                    isEmpty: false,
                    fillAnimation: i == glasses.length - 1 ? _fillAnim : null,
                  ).animate().fadeIn(delay: Duration(milliseconds: 80 * i));
                },
              ),
            ),

            const SizedBox(height: 24),

            // ── Action buttons ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _removeWater,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.remove_rounded,
                                color: AppColors.rose500, size: 18),
                            const SizedBox(width: 6),
                            Text('Remove',
                                style: AppTextStyles.bodySemiBold
                                    .copyWith(color: AppColors.rose500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _addWater,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.plum900, AppColors.plum700],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.plum900.withOpacity(0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text('Add Water',
                                style: AppTextStyles.bodySemiBold
                                    .copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 120.ms, duration: 350.ms),

            const SizedBox(height: 20),

            // ── Stats row ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      emoji: '🥛',
                      label: 'Glasses',
                      value: '${water.fullGlasses + (water.currentGlassMl > 0 ? 1 : 0)}',
                      sub: 'of day',
                      bg: AppColors.plum50,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      emoji: '💧',
                      label: 'Total',
                      value:
                          '${(water.totalMl / 1000).toStringAsFixed(2)} L',
                      sub: 'today',
                      bg: AppColors.sage50,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      emoji: '🎯',
                      label: 'Goal',
                      value:
                          '${(AppConstants.dailyWaterGoalMl / 1000).toStringAsFixed(1)} L',
                      sub: 'remaining: ${((AppConstants.dailyWaterGoalMl - water.totalMl).clamp(0, 9999) / 1000).toStringAsFixed(2)} L',
                      bg: AppColors.rose50,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 160.ms, duration: 350.ms),

            // ── Hydration tips ────────────────────────────────────────────
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _HydrationTips(pct: totalPct),
            ).animate().fadeIn(delay: 200.ms, duration: 350.ms),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ─── Amount Input Dialog ──────────────────────────────────────────────────────

Future<int?> _showAmountDialog(BuildContext context,
    {required bool isAdding}) async {
  final ctrl = TextEditingController();
  final presets = [100, 150, 200, 250, 330, 500];

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(builder: (ctx, setS) {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isAdding ? 'How much water? 💧' : 'Remove how much? 💧',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.plum900,
                ),
              ),
              const SizedBox(height: 16),

              // Preset chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets.map((ml) {
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, ml),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isAdding ? AppColors.plum50 : AppColors.rose50,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: isAdding
                                ? AppColors.plum200
                                : AppColors.rose200,
                            width: 1.5),
                      ),
                      child: Text(
                        '$ml ml',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isAdding
                              ? AppColors.plum700
                              : AppColors.rose700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              Text('Or enter custom amount:',
                  style: AppTextStyles.caption),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'e.g. 175',
                        suffixText: 'ml',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final v = int.tryParse(ctrl.text);
                      if (v != null && v > 0) Navigator.pop(ctx, v);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdding
                          ? AppColors.plum700
                          : AppColors.rose500,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    // ← FIX: was always "Add" even in remove mode
                    child: Text(isAdding ? 'Add' : 'Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }),
  );
}
// ─── Water Header ─────────────────────────────────────────────────────────────

class _WaterHeader extends StatelessWidget {
  final int totalMl;
  final double totalPct;
  const _WaterHeader({required this.totalMl, required this.totalPct});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A6B9A), Color(0xFF2196F3)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💧', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hydration',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Today\'s water tracker',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.55)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(totalMl / 1000).toStringAsFixed(2)}',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'L / ${(AppConstants.dailyWaterGoalMl / 1000).toStringAsFixed(1)} L',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(totalPct * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Daily Goal Bar ───────────────────────────────────────────────────────────

class _DailyGoalBar extends StatelessWidget {
  final int totalMl;
  final int goalMl;
  final double pct;

  const _DailyGoalBar(
      {required this.totalMl, required this.goalMl, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Goal Progress', style: AppTextStyles.cardTitle),
              Text(
                '${totalMl} / ${goalMl} ml',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.plum700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct.clamp(0, 1)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: val,
                      minHeight: 12,
                      backgroundColor: AppColors.neutral100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct >= 1.0
                            ? AppColors.sage600
                            : const Color(0xFF2196F3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0 L', style: AppTextStyles.caption),
                      Text(
                        pct >= 1.0
                            ? '🎉 Goal reached!'
                            : '${((1 - pct) * goalMl / 1000).toStringAsFixed(2)} L remaining',
                        style: AppTextStyles.caption.copyWith(
                          color: pct >= 1.0
                              ? AppColors.sage600
                              : AppColors.neutral500,
                          fontWeight: pct >= 1.0 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      Text(
                        '${(goalMl / 1000).toStringAsFixed(1)} L',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Animated Water Glass ─────────────────────────────────────────────────────

class AnimatedWaterGlass extends StatelessWidget {
  final double fillFraction; // 0.0 – 1.0
  final String mlLabel;
  final bool isActive;
  final bool isEmpty;
  final Animation<double>? fillAnimation;

  const AnimatedWaterGlass({
    super.key,
    required this.fillFraction,
    required this.mlLabel,
    required this.isActive,
    required this.isEmpty,
    this.fillAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFill = fillAnimation ?? AlwaysStoppedAnimation(fillFraction);

    return AnimatedBuilder(
      animation: effectiveFill,
      builder: (_, __) {
        final fill = isEmpty ? 0.0 : effectiveFill.value;
        return Column(
          children: [
            // Glass widget
            Container(
              width: 72,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF2196F3)
                      : AppColors.border,
                  width: isActive ? 2.0 : 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Water fill
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        height: 120 * fill,
                        child: CustomPaint(
                          painter: _WaterPainter(
                            fill: fill,
                            color: isEmpty
                                ? Colors.transparent
                                : isActive
                                    ? const Color(0xFF42A5F5)
                                    : const Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ),

                    // Shimmer layer
                    if (fill > 0.1)
                      Positioned(
                        bottom: 0,
                        left: 8,
                        right: 8,
                        child: SizedBox(
                          height: 120 * fill,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Empty label
                    if (isEmpty)
                      Center(
                        child: Text(
                          '+',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w200,
                            color: AppColors.neutral300,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ml label
            Text(
              isEmpty ? 'Next' : mlLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? const Color(0xFF1976D2)
                    : AppColors.neutral400,
              ),
            ),
            if (!isEmpty)
              Text(
                '${(fill * 100).round()}%',
                style: AppTextStyles.caption.copyWith(fontSize: 9),
              ),
          ],
        );
      },
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double fill;
  final Color color;
  const _WaterPainter({required this.fill, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (fill <= 0) return;
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _WaterPainter old) =>
      old.fill != fill || old.color != color;
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String sub;
  final Color bg;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.sub,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(sub,
              style: AppTextStyles.caption.copyWith(fontSize: 9),
              overflow: TextOverflow.ellipsis,
              maxLines: 2),
        ],
      ),
    );
  }
}

// ─── Hydration Tips ───────────────────────────────────────────────────────────

class _HydrationTips extends StatelessWidget {
  final double pct;
  const _HydrationTips({required this.pct});

  @override
  Widget build(BuildContext context) {
    final tips = pct >= 1.0
        ? [
            ('🎉', 'Goal reached!', 'Excellent hydration today.'),
            ('💪', 'Keep it up', 'Stay consistent tomorrow.'),
          ]
        : pct >= 0.5
            ? [
                ('💧', 'Halfway there', 'Drink a glass every hour.'),
                ('⏰', 'Set reminders', 'Regular sips beat large gulps.'),
              ]
            : [
                ('⚠️', 'Low hydration', 'Drink 2–3 glasses now.'),
                ('🥤', 'Quick tip', 'Start with a large glass of water.'),
              ];

    return Container(
      decoration: cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hydration Tips', style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.$2, style: AppTextStyles.bodySemiBold),
                          Text(t.$3,
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
