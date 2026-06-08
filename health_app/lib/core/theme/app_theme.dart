import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Soft Summer Palette — No Blue ──────────────────────────────────────────

class AppColors {
  AppColors._();

  // Plum scale — Primary, AI/ML, dark backgrounds
  static const Color plum900 = Color(0xFF2A1A32);
  static const Color plum800 = Color(0xFF3D2645);
  static const Color plum700 = Color(0xFF52305C);
  static const Color plum600 = Color(0xFF6B4070);
  static const Color plum500 = Color(0xFF845088);
  static const Color plum400 = Color(0xFFA070A8);
  static const Color plum300 = Color(0xFFC4A0CC);
  static const Color plum200 = Color(0xFFDEC8E4);
  static const Color plum100 = Color(0xFFF0E6F4);
  static const Color plum50  = Color(0xFFF8F3FA);

  // Sage scale — Success, health, tips
  static const Color sage800 = Color(0xFF2C5252);
  static const Color sage700 = Color(0xFF3A6464);
  static const Color sage600 = Color(0xFF4E7878);
  static const Color sage500 = Color(0xFF608888);
  static const Color sage400 = Color(0xFF7AA0A0);
  static const Color sage300 = Color(0xFF9CBCBC);
  static const Color sage200 = Color(0xFFBED4D4);
  static const Color sage100 = Color(0xFFDFF0F0);
  static const Color sage50  = Color(0xFFF0F7F7);

  // Rose scale — Alerts, warnings
  static const Color rose800 = Color(0xFF6A2840);
  static const Color rose700 = Color(0xFF7A3550);
  static const Color rose600 = Color(0xFF924560);
  static const Color rose500 = Color(0xFFAA5878);
  static const Color rose400 = Color(0xFFC07090);
  static const Color rose300 = Color(0xFFD498AC);
  static const Color rose200 = Color(0xFFE8C4D0);
  static const Color rose100 = Color(0xFFF5E4EA);
  static const Color rose50  = Color(0xFFFBF3F6);

  // Warm neutrals — Text, surfaces
  static const Color neutral900 = Color(0xFF1E1A1A);
  static const Color neutral800 = Color(0xFF2E2828);
  static const Color neutral700 = Color(0xFF443C3C);
  static const Color neutral600 = Color(0xFF5E5555);
  static const Color neutral500 = Color(0xFF7A7070);
  static const Color neutral400 = Color(0xFF9E9292);
  static const Color neutral300 = Color(0xFFC4BCBC);
  static const Color neutral200 = Color(0xFFDDD6D6);
  static const Color neutral100 = Color(0xFFEDE8E8);
  static const Color neutral50  = Color(0xFFF8F5F5);

  // Semantic surfaces
  static const Color background = Color(0xFFF0EBE6);
  static const Color surface    = Color(0xFFFAF7F5);
  static const Color card       = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE0D8D4);

  // Shadows
  static const Color shadowPlum = Color(0x476B4070);
  static const Color shadowSage = Color(0x404E7878);
  static const Color shadowDark = Color(0x1A2A1A32);

  // Legacy aliases for existing code
  static const Color primary        = plum700;
  static const Color primaryDark    = plum900;
  static const Color secondary      = sage600;
  static const Color accent         = rose500;
  static const Color error          = rose600;
  static const Color success        = sage600;
  static const Color textPrimary    = neutral800;
  static const Color textSecondary  = neutral500;
  static const Color textHint       = neutral400;
  static const Color divider        = border;
  static const Color light          = plum100;
  static const Color muted          = plum200;
  static const Color cardSurface    = card;
  static const Color transparent    = Color(0x00000000);

  // Sleep/meds chip colours (used by legacy sleep_screen)
  static const Color sleepBg = sage100;
  static const Color sleepFg = sage700;
  static const Color medsBg  = rose100;
  static const Color medsFg  = rose700;

  // Warning — amber-ish fallback mapped to rose (no blue palette)
  static const Color warning = rose500;
}

// ─── Typography Helpers ──────────────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.playfairDisplay(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        color: AppColors.plum900,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle get h2 => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.plum900,
        letterSpacing: -0.3,
      );

  static TextStyle get h3 => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.plum900,
      );

  static TextStyle get cardTitle => GoogleFonts.playfairDisplay(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.plum900,
      );

  // FIX: added missing sectionTitle used in dashboard quick-actions grid
  static TextStyle get sectionTitle => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.neutral700,
        letterSpacing: 0.1,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.neutral600,
        height: 1.65,
      );

  static TextStyle get bodySemiBold => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.plum900,
      );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.neutral400,
        letterSpacing: 0.3,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.neutral400,
        letterSpacing: 0.4,
      );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );

  static TextStyle get num => GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.plum900,
      );
}

// ─── Theme ───────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      textTheme: base,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.plum700,
        onPrimary: Colors.white,
        secondary: AppColors.sage600,
        onSecondary: Colors.white,
        error: AppColors.rose600,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.neutral800,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: false,
        foregroundColor: AppColors.neutral800,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.plum900,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.plum700,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
          minimumSize: const Size(44, 52),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.plum700,
          side: const BorderSide(color: AppColors.plum700, width: 1.5),
          shape: const StadiumBorder(),
          minimumSize: const Size(44, 52),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.sage600,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.plum700, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.rose600, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.rose600, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.neutral400,
          fontSize: 13,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.neutral500,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.plum700,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.plum700,
        overlayColor: AppColors.plum700.withOpacity(0.12),
        valueIndicatorColor: AppColors.plum700,
        trackHeight: 6,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.plum700,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.neutral600,
        ),
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.border, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
    );
  }
}

// ─── Decoration Helpers ───────────────────────────────────────────────────────

BoxDecoration cardDecoration({
  Color? color,
  double radius = 20,
  bool withShadow = true,
  bool withBorder = true,
}) {
  return BoxDecoration(
    color: color ?? AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: withBorder
        ? Border.all(color: AppColors.border, width: 1)
        : null,
    boxShadow: withShadow
        ? [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ]
        : null,
  );
}

BoxDecoration gradientPlumDecoration({double radius = 0}) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.plum900, AppColors.plum700],
      ),
      borderRadius: BorderRadius.circular(radius),
    );

BoxDecoration gradientSageDecoration({double radius = 0}) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.sage500, AppColors.sage700],
      ),
      borderRadius: BorderRadius.circular(radius),
    );
