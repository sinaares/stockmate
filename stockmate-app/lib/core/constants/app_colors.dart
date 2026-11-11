import 'package:flutter/material.dart';

/// StockMate Enterprise Color Palette
/// Designed for a modern, clean, commercial ERP, POS, and warehouse management application.
class AppColors {
  // Brand Primary & Identity
  static const Color navy            = Color(0xFF142D4E); // Deep navy blue - headers, identity
  static const Color primary         = Color(0xFF2563EB); // Electric blue - primary actions, links
  static const Color primaryLight    = Color(0xFF3B82F6);
  static const Color primaryDark     = Color(0xFF1D4ED8);
  static const Color primaryTint     = Color(0xFFEFF6FF); // Soft blue surface tint

  // Brand Secondary & Accents
  static const Color teal            = Color(0xFF0D9488); // Teal accents - health, positive
  static const Color tealLight       = Color(0xFF14B8A6);
  static const Color tealTint        = Color(0xFFF0FDFA);

  // Surfaces & Backgrounds (Clean light commercial canvas)
  static const Color background      = Color(0xFFF5F7FA); // Neutral light gray canvas
  static const Color surface         = Color(0xFFFFFFFF); // Clean white surface
  static const Color surfaceCard     = Color(0xFFFFFFFF); // Clean white card
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceMuted    = Color(0xFFF1F5F9); // Slate-100 muted surface

  // Structural Borders & Dividers
  static const Color border          = Color(0xFFE2E8F0); // Subtle slate-200 border
  static const Color borderLight     = Color(0xFFF1F5F9); // Very light divider
  static const Color borderFocused   = Color(0xFF2563EB); // Focus state border

  // Typography Hierarchy (Slate-based, sharp contrast)
  static const Color textPrimary     = Color(0xFF0F172A); // Slate-900 (High contrast)
  static const Color textSecondary   = Color(0xFF475569); // Slate-600 (Informative)
  static const Color textMuted       = Color(0xFF64748B); // Slate-500
  static const Color textHint        = Color(0xFF94A3B8); // Slate-400 (Placeholders)
  static const Color textOnPrimary   = Color(0xFFFFFFFF); // White text on dark/colored buttons

  // Semantic Status Colors
  static const Color success         = Color(0xFF0D9488); // Teal / Emerald
  static const Color successTint     = Color(0xFFF0FDF4);
  static const Color successBorder   = Color(0xFFA7F3D0);

  static const Color warning         = Color(0xFFF59E0B); // Amber warning
  static const Color warningTint     = Color(0xFFFFFBEB);
  static const Color warningBorder   = Color(0xFFFDE68A);

  static const Color error           = Color(0xFFEF4444); // Crimson red
  static const Color errorTint       = Color(0xFFFEF2F2);
  static const Color errorBorder     = Color(0xFFFECACA);

  static const Color info            = Color(0xFF2563EB); // Electric blue info
  static const Color infoTint        = Color(0xFFEFF6FF);

  static const Color pending         = Color(0xFFF59E0B); // Amber pending

  // Action Semantic Colors
  static const Color sell            = Color(0xFFEF4444); // Sales
  static const Color use             = Color(0xFFF59E0B); // Internal usage
  static const Color restock         = Color(0xFF0D9488); // Inventory restock
  static const Color addProduct      = Color(0xFF2563EB); // Product creation
  static const Color remove          = Color(0xFFEF4444);

  // Backward-compatibility aliases
  static const Color accent          = Color(0xFF2563EB); // maps to primary electric blue
  static const Color accentLight     = Color(0xFF3B82F6);
  static const Color accentDark      = Color(0xFF1D4ED8);
  static const Color accentGlow      = Color(0x1F2563EB);
  static const Color accentGlowSoft  = Color(0x122563EB);

  static const Color secondary       = Color(0xFF142D4E); // maps to deep navy
  static const Color secondaryLight  = Color(0xFF1E3A8A);
  static const Color secondaryGlow   = Color(0x1F142D4E);

  static const Color successGlow     = Color(0x1F0D9488);
  static const Color warningGlow     = Color(0x1FF59E0B);
  static const Color errorGlow       = Color(0x1FEF4444);
  static const Color pink            = Color(0xFFEF4444);
  static const Color pinkLight       = Color(0xFFF87171);
  static const Color pinkGlow        = Color(0x1FEF4444);

  // Gradients for subtle accents & charts
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF142D4E), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> primaryButtonShadow = [
    BoxShadow(
      color: Color(0x332563EB),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];
}
