import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/water_provider.dart';

class WaterTrackerWidget extends ConsumerWidget {
  const WaterTrackerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(waterProvider);
    final percent =
        (state.totalMl / AppConstants.dailyWaterGoalMl).clamp(0.0, 1.0);

    return Container(
      decoration: cardDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded,
                  color: Color(0xFF1E88E5), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Water Intake',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${state.totalMl} / ${AppConstants.dailyWaterGoalMl} ml',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CircularPercentIndicator(
            radius: 70,
            lineWidth: 12,
            percent: percent,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(percent * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'of goal',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            progressColor: const Color(0xFF1E88E5),
            backgroundColor: const Color(0xFFE3F2FD),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 800,
          ),
          const SizedBox(height: 24),
          // Quick add buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: AppConstants.waterAmounts.map((ml) {
              return GestureDetector(
                onTap: () =>
                    ref.read(waterProvider.notifier).addWater(ml),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF1E88E5).withOpacity(0.3)),
                  ),
                  child: Text(
                    '+${ml}ml',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
