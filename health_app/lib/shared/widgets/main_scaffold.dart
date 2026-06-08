import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/scaffold_tab_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/nutrition/screens/nutrition_screen.dart';
import '../../features/sleep/screens/sleep_screen.dart';
import '../../features/smartwatch/screens/smartwatch_screen.dart';
import '../../features/symptoms/screens/symptoms_screen.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final int initialIndex;
  /// When true, the profile drawer opens on first frame (used by /profile route)
  final bool openDrawer;

  const MainScaffold({
    super.key,
    this.initialIndex = 0,
    this.openDrawer = false,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  late int _selectedIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── 6 tabs: Home, Symptoms, Nutrition, Analytics, Sleep, Watch ────────────
  static const List<Widget> _pages = [
    DashboardScreen(),
    SymptomsScreen(),
    NutritionScreen(),
    AnalyticsScreen(),
    SleepScreen(),
    SmartWatchScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(emoji: '🏠', label: 'Home'),
    _NavItem(emoji: '🩺', label: 'Symptoms'),
    _NavItem(emoji: '💧', label: 'Hydration'),
    _NavItem(emoji: '📊', label: 'Reports'),
    _NavItem(emoji: '🌙', label: 'Sleep'),
    _NavItem(emoji: '⌚', label: 'Watch'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _pages.length - 1);
    if (widget.openDrawer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scaffoldKey.currentState?.openDrawer();
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to external tab-switch requests (e.g. from dashboard quick-action buttons)
    ref.listen<int>(scaffoldTabProvider, (_, next) {
      if (next != _selectedIndex) {
        HapticFeedback.selectionClick();
        setState(() => _selectedIndex = next);
      }
    });
    final profile = ref.watch(profileProvider).valueOrNull;
    final authState = ref.watch(authProvider);

    final name = profile?.fullName ??
        (authState is AuthAuthenticated ? authState.user.fullName : null) ??
        'User';
    final email = authState is AuthAuthenticated ? authState.user.email : '';
    final parts = name.trim().split(' ');
    final initials = parts
        .take(2)
        .map((s) => s.isNotEmpty ? s[0] : '')
        .join()
        .toUpperCase();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      extendBody: true,

      // ── Profile Side Drawer ─────────────────────────────────────────────
      drawer: _ProfileDrawer(
        initials: initials.isEmpty ? 'U' : initials,
        name: name,
        email: email,
        onNavigateToProfile: () {
          Navigator.pop(context); // close drawer
          context.push('/profile/personal-info');
        },
        onNavigateToMedications: () {
          Navigator.pop(context);
          context.push('/medications');
        },
        onSignOut: () async {
          Navigator.pop(context);
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        },
      ),

      body: Stack(
        children: [
          // ── Page content ──────────────────────────────────────────────
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          // ── Floating profile avatar — pinned top-right, always visible ──
          // Using RepaintBoundary to prevent it from being invalidated when
          // the IndexedStack switches children (fixes the left-to-right jump).
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: RepaintBoundary(
              child: GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.plum700, AppColors.plum500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.plum900.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials.isEmpty ? '👤' : initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
          ),
        ],
      ),

      bottomNavigationBar: _FloatingPillNav(
        selectedIndex: _selectedIndex,
        items: _navItems,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ─── Profile Side Drawer ──────────────────────────────────────────────────────

class _ProfileDrawer extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToMedications;
  final VoidCallback onSignOut;

  const _ProfileDrawer({
    required this.initials,
    required this.name,
    required this.email,
    required this.onNavigateToProfile,
    required this.onNavigateToMedications,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // ── Header gradient ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.plum900, AppColors.plum600],
              ),
              borderRadius:
                  BorderRadius.horizontal(right: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.plum500, AppColors.plum300],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email.isEmpty ? 'SensiaHealth' : email,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.55),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Menu items ───────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: Text(
                      'MY ACCOUNT',
                      style: AppTextStyles.caption.copyWith(
                        letterSpacing: 1.5,
                        color: AppColors.neutral400,
                      ),
                    ),
                  ),

                  _DrawerItem(
                    emoji: '👤',
                    label: 'Personal Information',
                    sub: 'Name, DOB, gender',
                    bg: AppColors.plum100,
                    onTap: onNavigateToProfile,
                  ),
                  _DrawerItem(
                    emoji: '💊',
                    label: 'My Medications',
                    sub: 'Track & manage doses',
                    bg: AppColors.sage100,
                    onTap: onNavigateToMedications,
                  ),
                  _DrawerItem(
                    emoji: '🏥',
                    label: 'Medical History',
                    sub: 'Conditions & allergies',
                    bg: AppColors.rose100,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/medical-history');
                    },
                  ),

                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: Text(
                      'APP',
                      style: AppTextStyles.caption.copyWith(
                        letterSpacing: 1.5,
                        color: AppColors.neutral400,
                      ),
                    ),
                  ),

                  _DrawerItem(
                    emoji: '🔔',
                    label: 'Notifications',
                    sub: 'Reminders & alerts',
                    bg: AppColors.sage50,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/notifications');
                    },
                  ),
                  _DrawerItem(
                    emoji: '⌚',
                    label: 'Smart Watch',
                    sub: 'Connect your device',
                    bg: AppColors.plum50,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/smartwatch');
                    },
                  ),

                  const Spacer(),

                  // Sign out
                  GestureDetector(
                    onTap: onSignOut,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.rose50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.rose200),
                      ),
                      child: Row(
                        children: [
                          const Text('🚪',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Text(
                            'Sign Out',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.rose700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String sub;
  final Color bg;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.bodySemiBold),
                    Text(sub, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.neutral300, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item model ───────────────────────────────────────────────────────────

class _NavItem {
  final String emoji;
  final String label;
  const _NavItem({required this.emoji, required this.label});
}

// ─── Floating Plum Pill Navbar ────────────────────────────────────────────────

class _FloatingPillNav extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _FloatingPillNav({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.plum900,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.plum900.withOpacity(0.35),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final isSelected = selectedIndex == i;
              return Expanded(
                child: _NavButton(
                  item: items[i],
                  isSelected: isSelected,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.emoji,
              style: TextStyle(fontSize: isSelected ? 16 : 14),
            ),
            const SizedBox(height: 1),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 7.5,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.40),
                letterSpacing: 0.2,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.sage400,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      )
          .animate(target: isSelected ? 1 : 0)
          .scaleXY(begin: 0.95, end: 1.0, duration: 200.ms),
    );
  }
}
