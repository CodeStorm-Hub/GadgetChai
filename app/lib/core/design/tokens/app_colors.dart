import 'package:flutter/material.dart';

/// Warm expressive palette for GadgetChai — M3 Expressive "Warm Tech Rental".
abstract final class AppColors {
  // Primary — Deep Coral-Orange
  static const Color primary = Color(0xFFE85D3A);
  static const Color primaryContainer = Color(0xFFFFE4DB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF8C2F14);
  static const Color primaryFixed = Color(0xFFFFE4DB);
  static const Color primaryFixedDim = Color(0xFFFFC9B8);

  // Secondary — Rich Teal
  static const Color secondary = Color(0xFF0D9488);
  static const Color secondaryContainer = Color(0xFFCCFBF1);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF065F56);
  static const Color secondaryFixed = Color(0xFFCCFBF1);
  static const Color secondaryFixedDim = Color(0xFF99F6E4);

  // Tertiary — Golden Amber
  static const Color tertiary = Color(0xFFF59E0B);
  static const Color tertiaryContainer = Color(0xFFFFF3D6);
  static const Color onTertiary = Color(0xFF1C1917);
  static const Color onTertiaryContainer = Color(0xFF92400E);
  static const Color tertiaryFixed = Color(0xFFFFF3D6);
  static const Color tertiaryFixedDim = Color(0xFFFFE4A8);

  // Warm neutral surfaces
  static const Color background = Color(0xFFFFFBF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFBF7);
  static const Color surfaceContainerLow = Color(0xFFFFF5EE);
  static const Color surfaceContainer = Color(0xFFF5EBE3);
  static const Color surfaceContainerHigh = Color(0xFFE8DDD4);
  static const Color surfaceContainerHighest = Color(0xFFD6C9BE);
  static const Color onSurface = Color(0xFF1C1917);
  static const Color onSurfaceVariant = Color(0xFF57534E);
  static const Color onSurfaceLight = Color(0xFFA8A29E);

  // Semantic
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF991B1B);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFFF7ED);
  static const Color onWarning = Color(0xFF1C1917);
  static const Color onWarningContainer = Color(0xFF92400E);
  static const Color success = Color(0xFF0D9488);
  static const Color info = Color(0xFF0284C7);

  /// bKash brand pink — used only on payment step chrome.
  static const Color bkashPink = Color(0xFFE2136E);

  static const Color accent = tertiary;

  // Legacy aliases
  static const Color scaffoldBg = background;
  static const Color cardBg = surface;
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textMuted = onSurfaceLight;
  static const Color border = Color(0xFFE8DDD4);
}
