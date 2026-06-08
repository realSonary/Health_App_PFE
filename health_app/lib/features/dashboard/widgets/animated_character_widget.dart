import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

/// SensiaHealth plant mascot — represents health growth.
/// mood: 'thriving' | 'growing' | 'wilting'
class AnimatedCharacterWidget extends StatefulWidget {
  final double size;
  final String mood;

  const AnimatedCharacterWidget({
    super.key,
    this.size = 100,
    this.mood = 'thriving',
  });

  @override
  State<AnimatedCharacterWidget> createState() =>
      _AnimatedCharacterWidgetState();
}

class _AnimatedCharacterWidgetState extends State<AnimatedCharacterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;
  late Animation<double> _sway;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _sway = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _potColor => switch (widget.mood) {
        'wilting' => const Color(0xFFB5A68A),
        'growing' => const Color(0xFF7DBF9A),
        _ => AppColors.primary,
      };

  Color get _leafColor => switch (widget.mood) {
        'wilting' => const Color(0xFFB0A070),
        'growing' => AppColors.secondary,
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: Transform.rotate(
            angle: widget.mood == 'wilting' ? 0 : _sway.value,
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _PlantPainter(
            mood: widget.mood,
            potColor: _potColor,
            leafColor: _leafColor,
          ),
        ),
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  final String mood;
  final Color potColor;
  final Color leafColor;

  _PlantPainter({required this.mood, required this.potColor, required this.leafColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final potPaint = Paint()..color = potColor;
    final soilPaint = Paint()..color = const Color(0xFF8B6F5E);
    final stemPaint = Paint()
      ..color = const Color(0xFF4A8A5A)
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leafPaint = Paint()..color = leafColor;
    final leafHighlight = Paint()..color = leafColor.withOpacity(0.5);
    final eyePaint = Paint()..color = AppColors.textPrimary;
    final cheekPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.6);
    final smilePaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Pot body
    final potRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.25, h * 0.68, w * 0.5, h * 0.28),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(potRect, potPaint);

    // Pot rim
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.63, w * 0.64, h * 0.1),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(rimRect, potPaint..color = potColor.withOpacity(0.8));

    // Soil
    final soilRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.2, h * 0.63, w * 0.6, h * 0.07),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(soilRect, soilPaint);

    // Stem
    if (mood == 'wilting') {
      final stemPath = Path()
        ..moveTo(w * 0.5, h * 0.63)
        ..quadraticBezierTo(w * 0.35, h * 0.45, w * 0.3, h * 0.3);
      canvas.drawPath(stemPath, stemPaint);
    } else {
      canvas.drawLine(
        Offset(w * 0.5, h * 0.63),
        Offset(w * 0.5, h * 0.28),
        stemPaint,
      );
    }

    // Leaves
    if (mood != 'wilting') {
      // Left leaf
      final leftLeaf = Path()
        ..moveTo(w * 0.5, h * 0.45)
        ..quadraticBezierTo(w * 0.2, h * 0.38, w * 0.18, h * 0.52)
        ..quadraticBezierTo(w * 0.32, h * 0.48, w * 0.5, h * 0.45);
      canvas.drawPath(leftLeaf, leafPaint);

      // Right leaf
      final rightLeaf = Path()
        ..moveTo(w * 0.5, h * 0.37)
        ..quadraticBezierTo(w * 0.8, h * 0.28, w * 0.82, h * 0.44)
        ..quadraticBezierTo(w * 0.68, h * 0.4, w * 0.5, h * 0.37);
      canvas.drawPath(rightLeaf, leafPaint);
    } else {
      // Wilting leaves
      final droop = Path()
        ..moveTo(w * 0.3, h * 0.32)
        ..quadraticBezierTo(w * 0.12, h * 0.28, w * 0.08, h * 0.42)
        ..quadraticBezierTo(w * 0.22, h * 0.36, w * 0.3, h * 0.32);
      canvas.drawPath(droop, leafPaint);
    }

    // Top flower / bud
    final budCenter = mood == 'wilting'
        ? Offset(w * 0.3, h * 0.29)
        : Offset(w * 0.5, h * 0.26);

    if (mood == 'thriving') {
      // Happy flower petals
      for (int i = 0; i < 5; i++) {
        final angle = (i * 2 * math.pi / 5) - math.pi / 2;
        final petalCenter = Offset(
          budCenter.dx + math.cos(angle) * w * 0.1,
          budCenter.dy + math.sin(angle) * w * 0.1,
        );
        canvas.drawCircle(petalCenter, w * 0.075, leafHighlight);
      }
    }
    canvas.drawCircle(budCenter, w * 0.1, leafPaint);

    // Face on the bud
    if (mood == 'thriving') {
      // Happy eyes
      canvas.drawCircle(
          Offset(budCenter.dx - w * 0.04, budCenter.dy - w * 0.02),
          w * 0.018, eyePaint);
      canvas.drawCircle(
          Offset(budCenter.dx + w * 0.04, budCenter.dy - w * 0.02),
          w * 0.018, eyePaint);
      // Cheeks
      canvas.drawCircle(
          Offset(budCenter.dx - w * 0.06, budCenter.dy + w * 0.01),
          w * 0.022, cheekPaint);
      canvas.drawCircle(
          Offset(budCenter.dx + w * 0.06, budCenter.dy + w * 0.01),
          w * 0.022, cheekPaint);
      // Smile
      final smilePath = Path()
        ..moveTo(budCenter.dx - w * 0.04, budCenter.dy + w * 0.025)
        ..quadraticBezierTo(
            budCenter.dx, budCenter.dy + w * 0.06,
            budCenter.dx + w * 0.04, budCenter.dy + w * 0.025);
      canvas.drawPath(smilePath, smilePaint);
    } else if (mood == 'growing') {
      // Neutral eyes (dots)
      canvas.drawCircle(
          Offset(budCenter.dx - w * 0.03, budCenter.dy - w * 0.01),
          w * 0.016, eyePaint);
      canvas.drawCircle(
          Offset(budCenter.dx + w * 0.03, budCenter.dy - w * 0.01),
          w * 0.016, eyePaint);
    } else {
      // Wilting — sad eyes (tilted lines)
      final sad1 = Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = w * 0.022
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
          Offset(budCenter.dx - w * 0.04, budCenter.dy),
          Offset(budCenter.dx - w * 0.01, budCenter.dy - w * 0.02),
          sad1);
      canvas.drawLine(
          Offset(budCenter.dx + w * 0.01, budCenter.dy - w * 0.02),
          Offset(budCenter.dx + w * 0.04, budCenter.dy),
          sad1);
    }
  }

  @override
  bool shouldRepaint(_PlantPainter old) => old.mood != mood;
}

/// Vitality score ring — circular progress with gradient stroke
class HealthScoreRing extends StatelessWidget {
  final double score; // 0–100
  final double size;

  const HealthScoreRing({
    super.key,
    required this.score,
    this.size = 100,
  });

  Color get _trackColor {
    if (score >= 80) return AppColors.primary;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: size * 0.1,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(_trackColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.5,
                ),
              ),
              Text(
                'score',
                style: TextStyle(
                  fontSize: size * 0.10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.forward())
        .scale(
          begin: const Offset(0.75, 0.75),
          duration: 700.ms,
          curve: Curves.elasticOut,
        );
  }
}

/// Mini ring for quick-stat display (water, sleep)
class MiniRing extends StatelessWidget {
  final double value; // 0.0–1.0
  final Color color;
  final double size;
  final Widget child;

  const MiniRing({
    super.key,
    required this.value,
    required this.color,
    required this.child,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value.clamp(0.0, 1.0),
            strokeWidth: size * 0.08,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
          child,
        ],
      ),
    );
  }
}
