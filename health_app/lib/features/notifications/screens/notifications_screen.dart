import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class NotificationsState {
  final bool medicationReminders;
  final bool waterReminders;
  final bool sleepReminders;
  final bool weeklyReports;
  final bool aiInsights;
  final bool emergencyAlerts;

  // Reminder times
  final TimeOfDay waterReminderInterval; // every N hours
  final TimeOfDay sleepReminderTime;

  const NotificationsState({
    this.medicationReminders = true,
    this.waterReminders = true,
    this.sleepReminders = true,
    this.weeklyReports = true,
    this.aiInsights = true,
    this.emergencyAlerts = true,
    this.waterReminderInterval = const TimeOfDay(hour: 2, minute: 0),
    this.sleepReminderTime = const TimeOfDay(hour: 22, minute: 0),
  });

  NotificationsState copyWith({
    bool? medicationReminders,
    bool? waterReminders,
    bool? sleepReminders,
    bool? weeklyReports,
    bool? aiInsights,
    bool? emergencyAlerts,
    TimeOfDay? waterReminderInterval,
    TimeOfDay? sleepReminderTime,
  }) =>
      NotificationsState(
        medicationReminders: medicationReminders ?? this.medicationReminders,
        waterReminders: waterReminders ?? this.waterReminders,
        sleepReminders: sleepReminders ?? this.sleepReminders,
        weeklyReports: weeklyReports ?? this.weeklyReports,
        aiInsights: aiInsights ?? this.aiInsights,
        emergencyAlerts: emergencyAlerts ?? this.emergencyAlerts,
        waterReminderInterval:
            waterReminderInterval ?? this.waterReminderInterval,
        sleepReminderTime: sleepReminderTime ?? this.sleepReminderTime,
      );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState());

  // TODO: persist to SharedPreferences or backend /settings endpoint
  void setMedicationReminders(bool v) =>
      state = state.copyWith(medicationReminders: v);
  void setWaterReminders(bool v) =>
      state = state.copyWith(waterReminders: v);
  void setSleepReminders(bool v) =>
      state = state.copyWith(sleepReminders: v);
  void setWeeklyReports(bool v) =>
      state = state.copyWith(weeklyReports: v);
  void setAiInsights(bool v) =>
      state = state.copyWith(aiInsights: v);
  void setEmergencyAlerts(bool v) =>
      state = state.copyWith(emergencyAlerts: v);
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
        (_) => NotificationsNotifier());

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(notificationsProvider);
    final n = ref.read(notificationsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Reminders group ──────────────────────────────────────
            _GroupHeader(title: 'REMINDERS').animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 10),

            _NotifCard(
              emoji: '💊',
              title: 'Medication Reminders',
              sub: 'Get notified when it\'s time to take your medication',
              value: s.medicationReminders,
              onChanged: n.setMedicationReminders,
              accentColor: AppColors.sage600,
            ).animate().fadeIn(delay: 40.ms, duration: 300.ms),

            _NotifCard(
              emoji: '💧',
              title: 'Water Reminders',
              sub: 'Periodic reminders to drink water throughout the day',
              value: s.waterReminders,
              onChanged: n.setWaterReminders,
              accentColor: const Color(0xFF2196F3),
            ).animate().fadeIn(delay: 80.ms, duration: 300.ms),

            _NotifCard(
              emoji: '🌙',
              title: 'Sleep Reminders',
              sub: 'Wind-down reminder before your target bedtime',
              value: s.sleepReminders,
              onChanged: n.setSleepReminders,
              accentColor: AppColors.plum700,
            ).animate().fadeIn(delay: 120.ms, duration: 300.ms),

            const SizedBox(height: 20),

            // ── Reports & Insights group ─────────────────────────────
            _GroupHeader(title: 'REPORTS & INSIGHTS')
                .animate()
                .fadeIn(delay: 160.ms, duration: 300.ms),
            const SizedBox(height: 10),

            _NotifCard(
              emoji: '📊',
              title: 'Weekly Health Reports',
              sub: 'Summary of your health data every Monday morning',
              value: s.weeklyReports,
              onChanged: n.setWeeklyReports,
              accentColor: AppColors.sage600,
            ).animate().fadeIn(delay: 180.ms, duration: 300.ms),

            _NotifCard(
              emoji: '🤖',
              title: 'AI Health Insights',
              sub:
                  'Personalised recommendations based on your health trends',
              value: s.aiInsights,
              onChanged: n.setAiInsights,
              accentColor: AppColors.plum600,
            ).animate().fadeIn(delay: 220.ms, duration: 300.ms),

            const SizedBox(height: 20),

            // ── Emergency group ──────────────────────────────────────
            _GroupHeader(title: 'EMERGENCY')
                .animate()
                .fadeIn(delay: 260.ms, duration: 300.ms),
            const SizedBox(height: 10),

            _NotifCard(
              emoji: '🚨',
              title: 'Emergency Alerts',
              sub:
                  'Critical health anomaly alerts — cannot be silenced during emergencies',
              value: s.emergencyAlerts,
              onChanged: n.setEmergencyAlerts,
              accentColor: AppColors.rose500,
              isWarning: true,
            ).animate().fadeIn(delay: 280.ms, duration: 300.ms),

            const SizedBox(height: 20),

            // ── Info banner ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.sage50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sage200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Notification preferences are saved locally. For full push notification support, ensure app permissions are enabled in your device settings.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.sage700),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ─── Group Header ─────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String title;
  const _GroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.caption.copyWith(
        letterSpacing: 1.4,
        color: AppColors.neutral400,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ─── Notification Toggle Card ─────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;
  final bool isWarning;

  const _NotifCard({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value && isWarning
              ? AppColors.rose200
              : value
                  ? accentColor.withOpacity(0.2)
                  : AppColors.border,
          width: 1.5,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: value
                  ? accentColor.withOpacity(0.12)
                  : AppColors.neutral100,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySemiBold.copyWith(
                    color: value
                        ? AppColors.textPrimary
                        : AppColors.neutral400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppTextStyles.caption,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Toggle
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
          ),
        ],
      ),
    );
  }
}
