import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  // ─── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get light {
    return _buildTheme(Brightness.light);
  }

  // ─── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Dark mode color overrides
    final bg          = isDark ? const Color(0xFF0D1117) : AppColors.background;
    final surface     = isDark ? const Color(0xFF161B22) : AppColors.surface;
    final surfaceCard = isDark ? const Color(0xFF1C2128) : AppColors.surfaceCard;
    final surfaceMuted= isDark ? const Color(0xFF21262D) : AppColors.surfaceMuted;
    final border      = isDark ? const Color(0xFF30363D) : AppColors.border;
    final borderLight = isDark ? const Color(0xFF21262D) : AppColors.borderLight;
    final textPrimary = isDark ? const Color(0xFFE6EDF3) : AppColors.textPrimary;
    final textSecondary=isDark ? const Color(0xFF8B949E) : AppColors.textSecondary;
    final textMuted   = isDark ? const Color(0xFF6E7681) : AppColors.textMuted;
    final textHint    = isDark ? const Color(0xFF484F58) : AppColors.textHint;
    final navy        = isDark ? const Color(0xFF58A6FF) : AppColors.navy;

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
    );
    final interTextTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: navy,
        onSecondary: Colors.white,
        tertiary: AppColors.teal,
        onTertiary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        outline: border,
        outlineVariant: borderLight,
        surfaceContainerHighest: surfaceMuted,
        onSurfaceVariant: textSecondary,
      ),
      textTheme: interTextTheme.copyWith(
        headlineLarge: GoogleFonts.inter(color: navy, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
        headlineMedium: GoogleFonts.inter(color: navy, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: GoogleFonts.inter(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleMedium: GoogleFonts.inter(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleSmall: GoogleFonts.inter(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 13, height: 1.5, fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.inter(color: textHint, fontSize: 11, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.inter(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: navy,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: isDark ? const Color(0x33000000) : const Color(0x0A0F172A),
        centerTitle: false,
        iconTheme: IconThemeData(color: navy, size: 22),
        actionsIconTheme: IconThemeData(color: navy, size: 22),
        titleTextStyle: GoogleFonts.inter(color: navy, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
        shadowColor: isDark ? Colors.black38 : const Color(0x080F172A),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: const Color(0x332563EB),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF21262D) : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderFocused, width: 1.8)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.8)),
        hintStyle: GoogleFonts.inter(color: textHint, fontSize: 13),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: isDark ? const Color(0xFF1F3A6E) : AppColors.primaryTint,
        elevation: 2,
        shadowColor: isDark ? Colors.black54 : const Color(0x140F172A),
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return IconThemeData(color: textMuted, size: 21);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700);
          }
          return GoogleFonts.inter(color: textMuted, fontSize: 11, fontWeight: FontWeight.w500);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMuted,
        side: BorderSide(color: border),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.primary,
        unselectedLabelColor: textSecondary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: border,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF21262D) : AppColors.navy,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        tileColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        subtitleTextStyle: GoogleFonts.inter(color: textSecondary, fontSize: 12),
      ),
    );
  }
}
