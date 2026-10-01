import 'package:flutter/material.dart';

class AppColors {
  // Primary palette — Deep space dark
  static const Color background    = Color(0xFF0A0A14);
  static const Color surface       = Color(0xFF11111F);
  static const Color surfaceCard   = Color(0xFF18182C);
  static const Color surfaceElevated = Color(0xFF1F1F38);
  static const Color border        = Color(0xFF2A2A4A);
  static const Color borderLight   = Color(0xFF3A3A60);

  // Accent — Vibrant purple/pink gradient
  static const Color accent        = Color(0xFF8B5CF6);   // violet-500
  static const Color accentLight   = Color(0xFFA78BFA);   // violet-400
  static const Color accentDark    = Color(0xFF6D28D9);   // violet-700
  static const Color accentGlow    = Color(0x338B5CF6);
  static const Color accentGlowSoft = Color(0x1A8B5CF6);

  static const Color pink          = Color(0xFFEC4899);   // pink-500
  static const Color pinkLight     = Color(0xFFF472B6);   // pink-400
  static const Color pinkGlow      = Color(0x33EC4899);

  // Gradient colors
  static const Color gradStart     = Color(0xFF8B5CF6);
  static const Color gradMid       = Color(0xFFB45CF6);
  static const Color gradEnd       = Color(0xFFEC4899);

  // Status
  static const Color success       = Color(0xFF34D399);   // emerald-400
  static const Color successGlow   = Color(0x3334D399);
  static const Color warning       = Color(0xFFFBBF24);   // amber-400
  static const Color warningGlow   = Color(0x33FBBF24);
  static const Color error         = Color(0xFFF87171);   // red-400
  static const Color errorGlow     = Color(0x33F87171);
  static const Color pending       = Color(0xFFFBBF24);

  // Text
  static const Color textPrimary   = Color(0xFFF1F0FF);
  static const Color textSecondary = Color(0xFF9490BB);
  static const Color textHint      = Color(0xFF4E4A72);

  // Action colors
  static const Color sell          = Color(0xFFF87171);
  static const Color use           = Color(0xFFFBBF24);
  static const Color restock       = Color(0xFF34D399);
  static const Color addProduct    = Color(0xFF8B5CF6);
  static const Color remove        = Color(0xFFF87171);

  // Gradient helpers
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradStart, gradEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1A35), Color(0xFF18182C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
