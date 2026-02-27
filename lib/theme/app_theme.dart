import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Gradient - Electric Violet to Cobalt Blue
  static const Color primary = Color(0xFF6C3CE1);
  static const Color primaryLight = Color(0xFF9B6DFF);
  static const Color primaryDark = Color(0xFF4A1FBF);

  // Accent - Vivid Coral/Orange
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentOrange = Color(0xFFFF9F43);

  // Success - Emerald
  static const Color success = Color(0xFF26D0CE);
  static const Color successDark = Color(0xFF1A9E9C);

  // Warning
  static const Color warning = Color(0xFFFFD93D);

  // Info - Sky
  static const Color info = Color(0xFF4FACFE);

  // Background
  static const Color background = Color(0xFFF4F6FF);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF0EEFF);

  // Sidebar
  static const Color sidebar = Color(0xFF1A1035);
  static const Color sidebarActive = Color(0xFF6C3CE1);

  // Text
  static const Color textPrimary = Color(0xFF1A1035);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Status
  static const Color statusPresent = Color(0xFF10B981);
  static const Color statusAbsent = Color(0xFFEF4444);
  static const Color statusLate = Color(0xFFF59E0B);
  static const Color statusLeave = Color(0xFF6C3CE1);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C3CE1), Color(0xFF4FACFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF9F43)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF26D0CE), Color(0xFF1A9E9C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1035), Color(0xFF2D1B69)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  // Helpers untuk pakai Google Fonts di level widget
  // (menghindari bug const evaluation di google_fonts + Dart 3.11)
  static TextStyle outfit(double size, FontWeight weight, [Color? color]) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle dmSans(double size,
          [FontWeight weight = FontWeight.normal, Color? color]) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
      );

  static ThemeData get theme {
    // ThemeData menggunakan TextStyle biasa (bukan GoogleFonts) untuk
    // menghindari bug const evaluation FontWeight di Dart 3.11 / Flutter 3.41
    const TextTheme textTheme = TextTheme(
      displayLarge:
          TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      displayMedium:
          TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineLarge:
          TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineMedium:
          TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineSmall:
          TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleLarge:
          TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge:  TextStyle(fontSize: 15, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      bodySmall:  TextStyle(fontSize: 12, color: AppColors.textMuted),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEEEEF5)),
        ),
      ),
    );
  }
}