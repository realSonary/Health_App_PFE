import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _darkMode = false;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(profileProvider.notifier).loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final authState = ref.watch(authProvider);
    final name = profile?.fullName ?? 'Fatima Zahra';
    final email = authState is AuthAuthenticated
        ? authState.user.email
        : 'f.benali@hassan2.ma';
    final parts = name.trim().split(' ');
    final initials = parts
        .take(2)
        .map((s) => s.isNotEmpty ? s[0] : '')
        .join()
        .toUpperCase();
    final firstName = parts.first;
    final lastName = parts.skip(1).join(' ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Profile gradient header ─────────────────────────────────
            _ProfileHeader(
              initials: initials,
              firstName: firstName,
              lastName: lastName,
              email: email,
            ).animate().fadeIn(duration: 400.ms),

            // ── Quick chips ───────────────────────────────────────────────
            

            // ── Health Profile group ──────────────────────────────────────
            _MenuGroup(
              label: 'Health Profile',
              items: [
                _MenuItem(
                  iconBg: AppColors.plum100,
                  emoji: '👤',
                  title: 'Personal Information',
                  sub: 'Name, DOB, gender',
                  onTap: () => context.go('/profile/personal-info'),
                ),
                _MenuItem(
                  iconBg: AppColors.sage100,
                  emoji: '🏥',
                  title: 'Medical History',
                  sub: 'Conditions, allergies',
                  onTap: () => context.push('/medical-history'),
                ),
                _MenuItem(
                  iconBg: AppColors.rose100,
                  emoji: '💊',
                  title: 'Track Medications',
                  sub: 'Manage & schedule doses',
                  onTap: () => context.push('/medications'),
                ),
              ],
            ).animate().fadeIn(delay: 120.ms, duration: 350.ms),

            const SizedBox(height: 12),

            // ── Preferences group ─────────────────────────────────────────
            _MenuGroup(
              label: 'Preferences',
              items: [
                _MenuItem(
                  iconBg: AppColors.sage100,
                  emoji: '🔔',
                  title: 'Notifications',
                  sub: 'Manage reminders & alerts',
                  onTap: () => context.push('/notifications'),
                ),
                _MenuItem(
                  iconBg: AppColors.plum100,
                  emoji: '🌙',
                  title: 'Dark Mode',
                  sub: _darkMode ? 'On' : 'Off',
                  trailing: Switch(
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                    activeColor: AppColors.plum700,
                    trackColor: WidgetStateProperty.resolveWith((s) =>
                        s.contains(WidgetState.selected)
                            ? AppColors.plum700
                            : AppColors.border),
                  ),
                ),
                _MenuItem(
                  iconBg: AppColors.rose100,
                  emoji: '🗑️',
                  title: 'Delete Account',
                  sub: 'GDPR — erase all data',
                  titleColor: AppColors.rose700,
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ).animate().fadeIn(delay: 160.ms, duration: 350.ms),

            const SizedBox(height: 20),

            // ── Sign out ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rose600,
                  side: const BorderSide(color: AppColors.rose300, width: 1.5),
                  minimumSize: const Size(double.infinity, 48),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rose600,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 350.ms),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Account',
            style: AppTextStyles.h3.copyWith(color: AppColors.rose700)),
        content: Text(
          'This will permanently erase all your data. This action cannot be undone.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.rose600),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String initials;
  final String firstName;
  final String lastName;
  final String email;

  const _ProfileHeader({
    required this.initials,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.plum900, AppColors.plum600],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.plum500, AppColors.plum300],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials.isEmpty ? 'U' : initials,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowDark,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text('✏️',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Name
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: firstName,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (lastName.isNotEmpty)
                          TextSpan(
                            text: ' $lastName',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ProfileStat(value: '87%', label: 'Health Score'),
                      Container(
                          height: 32,
                          width: 1,
                          color: Colors.white.withOpacity(0.1)),
                      _ProfileStat(value: '22.5', label: 'BMI · Normal'),
                      Container(
                          height: 32,
                          width: 1,
                          color: Colors.white.withOpacity(0.1)),
                      _ProfileStat(value: '58 kg', label: 'Weight'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Chip ───────────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _QuickChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: cardDecoration(),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 5),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.neutral500, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Group ───────────────────────────────────────────────────────────────

class _MenuGroup extends StatelessWidget {
  final String label;
  final List<_MenuItem> items;

  const _MenuGroup({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              color: AppColors.surface,
              width: double.infinity,
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(letterSpacing: 2),
              ),
            ),
            const Divider(height: 1),
            ...items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final Color iconBg;
  final String emoji;
  final String title;
  final String sub;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.iconBg,
    required this.emoji,
    required this.title,
    required this.sub,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySemiBold.copyWith(
                      color: titleColor ?? AppColors.plum900,
                    ),
                  ),
                  Text(sub, style: AppTextStyles.caption),
                ],
              ),
            ),
            trailing ??
                const Text(
                  '›',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.neutral300,
                    height: 1,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
