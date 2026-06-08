import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/medications/screens/add_medication_screen.dart';
import '../../features/medications/screens/medications_screen.dart';
import '../../features/onboarding/screens/profile_setup_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/sleep/screens/sleep_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../features/profile/screens/personal_info.dart';
import '../../features/medical_history/screens/medical_history_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

// ─── RouterNotifier ────────────────────────────────────────────────────────
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final isAuth = authState is AuthAuthenticated;
    final isLoading = authState is AuthLoading || authState is AuthInitial;

    if (isLoading) return null;

    // forgot-password is always public (no auth required)
    final publicPaths = ['/login', '/register', '/welcome', '/forgot-password'];
    final isPublic =
        publicPaths.any((p) => state.matchedLocation.startsWith(p));

    if (!isAuth && !isPublic) return '/welcome';
    if (isAuth &&
        (state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/welcome')) {
      return '/dashboard';
    }
    return null;
  }
}

// ─── Router Provider ───────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Auth / Onboarding ────────────────────────────────────────────
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      // ── ADDED: Forgot Password flow ──────────────────────────────────
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ── Main app (bottom nav) ────────────────────────────────────────
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainScaffold(initialIndex: 0),
      ),
      GoRoute(
        path: '/symptoms',
        builder: (context, state) => const MainScaffold(initialIndex: 1),
      ),
      GoRoute(
        path: '/nutrition',
        builder: (context, state) => const MainScaffold(initialIndex: 2),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const MainScaffold(initialIndex: 3),
      ),
      // ── CHANGED: Sleep is now tab index 4 in the nav bar ────────────
      GoRoute(
        path: '/sleep',
        builder: (context, state) => const MainScaffold(initialIndex: 4),
      ),
      // ── ADDED: SmartWatch tab at index 5 ────────────────────────────
      GoRoute(
        path: '/smartwatch',
        builder: (context, state) => const MainScaffold(initialIndex: 5),
      ),
      // ── Profile is now accessed via the side drawer (not nav) ────────
      GoRoute(
        path: '/profile',
        builder: (context, state) => const MainScaffold(initialIndex: 0,
            openDrawer: true),
      ),

      // ── Detail screens ───────────────────────────────────────────────
      GoRoute(
        path: '/medications',
        builder: (context, state) => const MedicationsScreen(),
      ),
      GoRoute(
        path: '/add-medication',
        builder: (context, state) => const AddMedicationScreen(),
      ),
      GoRoute(
        path: '/profile/personal-info',
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/medical-history',
        builder: (context, state) => const MedicalHistoryScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Page not found', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
