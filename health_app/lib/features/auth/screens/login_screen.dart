import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).login(
            _emailCtrl.text.trim(),
            _passCtrl.text,
          );
      if (mounted) {
        final state = ref.read(authProvider);
        if (state is! AuthError) context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Curved plum header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.plum900, AppColors.plum600],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 100),

                    // Logo card
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowDark,
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const _SensiaLogo(size: 30),
                    ).animate().fadeIn(duration: 400.ms).scaleXY(
                        begin: 0.8, end: 1.0),

                    const SizedBox(height: 16),

                    Text(
                      'Welcome back',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.plum900,
                      ),
                    ).animate().fadeIn(delay: 80.ms),

                    const SizedBox(height: 4),

                    Text(
                      'Sign in to your account',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.neutral400),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 28),

                    // Error banner
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.rose50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.rose200),
                        ),
                        child: Row(
                          children: [
                            const Text('⚠️'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.rose700),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Email field
                    _FieldLabel(label: 'Email address'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'yourname@hassan2.ma',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 14, right: 8),
                          child: Text('📧', style: TextStyle(fontSize: 16)),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Email required' : null,
                    ).animate().fadeIn(delay: 140.ms),

                    const SizedBox(height: 14),

                    // Password field
                    _FieldLabel(label: 'Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 14, right: 8),
                          child: Text('🔒', style: TextStyle(fontSize: 16)),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.neutral400,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Password required'
                          : null,
                    ).animate().fadeIn(delay: 160.ms),

                    const SizedBox(height: 8),

                    // ── FIXED: Forgot Password now navigates to /forgot-password ──
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text(
                          'Forgot password?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.sage600,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 180.ms),

                    const SizedBox(height: 8),

                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.plum700,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 18),

                    // Or divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or continue with',
                              style: AppTextStyles.caption),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ).animate().fadeIn(delay: 220.ms),

                    const SizedBox(height: 14),

                    // Google button (placeholder)
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: AppColors.border, width: 1.5),
                          color: AppColors.card,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEA4335),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Continue with Google',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.neutral700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 240.ms),

                    const SizedBox(height: 20),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('No account? ',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.neutral500)),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Text(
                            'Sign up free',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sage600,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 260.ms),

                    const SizedBox(height: 18),

                    // GDPR banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.sage100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sage200),
                      ),
                      child: Row(
                        children: [
                          const Text('🔐', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 9),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.sage700),
                                children: const [
                                  TextSpan(text: 'Encrypted & '),
                                  TextSpan(
                                    text: 'never shared',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                      text:
                                          ' with third parties. GDPR compliant.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 280.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: AppTextStyles.label),
    );
  }
}

class _SensiaLogo extends StatelessWidget {
  final double size;
  const _SensiaLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r1 = size.shortestSide / 2;
    final r2 = r1 * 0.6;
    final r3 = r1 * 0.22;

    final outerPaint = Paint()
      ..color = AppColors.plum300.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final midPaint = Paint()
      ..color = AppColors.plum500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dotPaint = Paint()..color = AppColors.plum500;

    canvas.drawCircle(c, r1, outerPaint);
    canvas.drawCircle(c, r2, midPaint);
    canvas.drawCircle(c, r3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
