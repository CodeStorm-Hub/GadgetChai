import 'package:flutter/material.dart';

/// Warm expressive palette for GadgetChai — M3 Expressive "Warm Tech Rental".
abstract final class AppColors {
  // Primary — Marigold Spark (Brutalist Orange-Red)
  static const Color primary = Color(0xFFFF4D1A);
  static const Color primaryContainer = Color(0xFFFFEAE5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFF4D1A);
  static const Color primaryFixed = Color(0xFFFFEAE5);
  static const Color primaryFixedDim = Color(0xFFFFC5B8);

  // Secondary — Electric Mint (High-Vis Green-Teal)
  static const Color secondary = Color(0xFF00E5A3);
  static const Color secondaryContainer = Color(0xFFE0FCF4);
  static const Color onSecondary = Color(0xFF1C1E24);
  static const Color onSecondaryContainer = Color(0xFF00B37E);
  static const Color secondaryFixed = Color(0xFFE0FCF4);
  static const Color secondaryFixedDim = Color(0xFFB3F7E5);

  // Tertiary — Clay Ochre (Earthen Sand)
  static const Color tertiary = Color(0xFFD4A373);
  static const Color tertiaryContainer = Color(0xFFF6ECE1);
  static const Color onTertiary = Color(0xFF1C1E24);
  static const Color onTertiaryContainer = Color(0xFFB18051);
  static const Color tertiaryFixed = Color(0xFFF6ECE1);
  static const Color tertiaryFixedDim = Color(0xFFECCEB2);

  // Warm neutral surfaces (Chai Receipt Paper)
  static const Color background = Color(0xFFF7F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFF7F5F0);
  static const Color surfaceContainerLow = Color(0xFFEFECE5);
  static const Color surfaceContainer = Color(0xFFE5E2DA);
  static const Color surfaceContainerHigh = Color(0xFFDBD8CF);
  static const Color surfaceContainerHighest = Color(0xFFD0CDC3);
  static const Color onSurface = Color(0xFF1C1E24);
  static const Color onSurfaceVariant = Color(0xFF535661);
  static const Color onSurfaceLight = Color(0xFF8A8F9E);

  // Semantic
  static const Color error = Color(0xFFD32F2F);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFFC62828);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color onWarning = Color(0xFF1C1E24);
  static const Color onWarningContainer = Color(0xFFB15C00);
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF1976D2);

  /// bKash brand pink — used only on payment step chrome.
  static const Color bkashPink = Color(0xFFE2136E);

  static const Color accent = tertiary;

  // Legacy aliases
  static const Color scaffoldBg = background;
  static const Color cardBg = surface;
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textMuted = onSurfaceLight;
  static const Color border = Color(0xFFE5E2DA);
  static const Color borderStrong = onSurface;
  static const Color borderLight = border;
}
