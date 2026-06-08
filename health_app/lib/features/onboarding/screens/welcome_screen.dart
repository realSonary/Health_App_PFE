import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _page = 0;

  static const _pages = [
    _PageData(
      emoji: '🧠',
      title: 'Smart AI Analysis',
      body:
          'Our Random Forest model analyses your symptoms and gives instant insights — no guessing.',
    ),
    _PageData(
      emoji: '💊',
      title: 'Medication Tracker',
      body:
          'Never miss a dose. Set reminders and track adherence in one elegant dashboard.',
    ),
    _PageData(
      emoji: '🌿',
      title: 'Holistic Health',
      body:
          'Sleep, hydration, mood and steps — all your vitals in a single soft, calming space.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.plum900, AppColors.plum700, Color(0xFF5A3560)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative orbs
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.plum500.withOpacity(0.35),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: -70,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sage600.withOpacity(0.2),
                ),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // On small windows the rigid Spacer() causes overflow and
                  // pushes the CTA buttons off-screen, making them unreachable.
                  // LayoutBuilder detects the available height and switches to
                  // a scrollable layout when the screen is too short.
                  final isShort = constraints.maxHeight < 620;
                  Widget body = Column(
                    children: [
                      if (!isShort) const Spacer(),
                      if (isShort) const SizedBox(height: 16),

                  // Logo glass card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Column(
                      children: [
                        // Logo
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CustomPaint(
                            painter: _SplashLogoPainter(),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scaleXY(begin: 0.7, end: 1.0),

                        const SizedBox(height: 16),

                        // App name
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Sensia',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              TextSpan(
                                text: 'Health',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.sage300,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 8),

                        Text(
                          'Your smart student\nhealth companion.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.45),
                            height: 1.6,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Onboarding pages
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _OnboardingPage(
                      key: ValueKey(_page),
                      data: _pages[_page],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isActive ? 28 : 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.sage400
                              : Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // CTA Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_page < _pages.length - 1) {
                                setState(() => _page++);
                              } else {
                                context.go('/register');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.sage600,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text(
                              _page < _pages.length - 1
                                  ? 'Next →'
                                  : 'Get Started ✨',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'I already have an account',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // University tag
                  Text(
                    'Université Hassan II · Casablanca',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.2),
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),
                    ],
                  );
                  return isShort
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: body,
                        )
                      : body;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final String emoji;
  final String title;
  final String body;
  const _PageData({
    required this.emoji,
    required this.title,
    required this.body,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  const _OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 36))
              .animate()
              .fadeIn(duration: 300.ms)
              .scaleXY(begin: 0.8, end: 1.0),
          const SizedBox(height: 12),
          Text(
            data.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 10),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.55),
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 140.ms),
        ],
      ),
    );
  }
}

class _SplashLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r1 = size.shortestSide / 2;
    final r2 = r1 * 0.55;
    final r3 = r1 * 0.2;

    canvas.drawCircle(
        c,
        r1,
        Paint()
          ..color = AppColors.plum300.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    canvas.drawCircle(
        c,
        r2,
        Paint()
          ..color = AppColors.plum300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);

    canvas.drawCircle(c, r3, Paint()..color = AppColors.plum300);

    // North/South tick lines
    final tickPaint = Paint()
      ..color = AppColors.plum300.withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx, c.dy - r1),
        Offset(c.dx, c.dy - r2 + 4), tickPaint);
    canvas.drawLine(Offset(c.dx, c.dy + r2 - 4),
        Offset(c.dx, c.dy + r1), tickPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
