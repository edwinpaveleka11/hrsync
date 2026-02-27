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
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
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
        hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
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