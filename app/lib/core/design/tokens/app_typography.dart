import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Plus Jakarta Sans with M3 Expressive emphasized weight hierarchy.
abstract final class AppTypography {
  static TextTheme buildTextTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    final headingFont = GoogleFonts.syne();

    TextStyle? emphasized(TextStyle? style, {FontWeight weight = FontWeight.w800}) {
      return style?.copyWith(fontWeight: weight);
    }

    return base.copyWith(
      displayLarge: headingFont.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
        height: 1.1,
        color: colorScheme.onSurface,
      ),
      displayMedium: headingFont.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: colorScheme.onSurface,
      ),
      displaySmall: headingFont.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: colorScheme.onSurface,
      ),
      headlineLarge: headingFont.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: colorScheme.onSurface,
      ),
      headlineMedium: headingFont.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: colorScheme.onSurface,
      ),
      headlineSmall: headingFont.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: colorScheme.onSurface,
      ),
      titleLarge: headingFont.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: colorScheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.4,
        color: colorScheme.onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: colorScheme.onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
        color: colorScheme.onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: colorScheme.onSurfaceVariant,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.5,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: emphasized(
        base.labelLarge?.copyWith(
          fontSize: 14,
          letterSpacing: 0.5,
          height: 1.4,
          color: colorScheme.onSurface,
        ),
        weight: FontWeight.w600,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: colorScheme.onSurfaceVariant,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Typewriter style font for pricing, numbers, carbon stats, and technical values.
  static TextStyle getMonospaceStyle({
    required BuildContext context,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
}
