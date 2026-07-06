import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'design/app_shapes.dart';
import 'design/app_spacing.dart';
import 'design/expressive_theme.dart';
import 'design/tokens/app_colors.dart';
import 'design/tokens/app_typography.dart';

export 'design/tokens/app_colors.dart';

/// GadgetChai Design System — M3 Expressive "Warm Tech Rental"
///
/// Primary: Coral-Orange | Secondary: Teal | Tertiary: Amber
/// Typography: Plus Jakarta Sans with emphasized hierarchy

extension GadgetChaiTheme on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isWide => MediaQuery.sizeOf(this).width >= 840;
  bool get isExpanded => MediaQuery.sizeOf(this).width >= 1200;
  bool get isMobile => MediaQuery.sizeOf(this).width < 600;
  bool get isTablet => MediaQuery.sizeOf(this).width >= 600 && MediaQuery.sizeOf(this).width < 840;
  bool get isDesktop => MediaQuery.sizeOf(this).width >= 840;
  GcExpressiveTheme get expressive =>
      Theme.of(this).extension<GcExpressiveTheme>() ?? GcExpressiveTheme.light;
}

class AppTheme {
  static ColorScheme _buildLightScheme() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );
    return base.copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.onSurfaceVariant.withValues(alpha: 0.35),
      outlineVariant: AppColors.border,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = _buildLightScheme();
    final textTheme = AppTypography.buildTextTheme(colorScheme);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      extensions: [GcExpressiveTheme.light],
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
        },
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 4,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.primary.withOpacity(0.05),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
      ),

      // Bottom Navigation Bar Theme — M3 Expressive indicator
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 80,
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),

      // Navigation Rail Theme — adaptive expanded/collapsed
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        indicatorColor: colorScheme.secondaryContainer,
        selectedIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 26,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        minWidth: 80,
        minExtendedWidth: 220,
        groupAlignment: -1,
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        shape: AppShapes.chipShape,
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        checkmarkColor: colorScheme.onPrimaryContainer,
        deleteIconColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelPadding: EdgeInsets.zero,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppShapes.input,
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.input,
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.input,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShapes.input,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppShapes.input,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        iconColor: colorScheme.onSurfaceVariant,
      ),

      // Button Themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
          textStyle: textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(48, 48),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppShapes.button),
          textStyle: textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: Size(44, 44),
          shadowColor: colorScheme.shadow,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppShapes.button),
          textStyle: textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: Size(44, 44),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: Size(44, 44),
        ),
      ),

      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          padding: EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tapTargetSize: MaterialTapTargetSize.padded,
          minimumSize: Size(44, 44),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.primary.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: AppShapes.sheet),
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant,
        modalBackgroundColor: colorScheme.scrim,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: AppShapes.input),
        elevation: 4,
        actionTextColor: colorScheme.primary,
        actionBackgroundColor: colorScheme.primaryContainer,
        dismissDirection: DismissDirection.up,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer,
        circularTrackColor: colorScheme.primaryContainer,
        refreshBackgroundColor: colorScheme.surfaceContainerHighest,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHigh,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.2),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimary,
        ),
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
        tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 4),
        inactiveTickMarkColor: colorScheme.surfaceContainerHigh,
      ),

      // Search Bar Theme (M3)
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerLow),
        elevation: WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.lg),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        hintStyle: WidgetStatePropertyAll(
          textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        textStyle: WidgetStatePropertyAll(textTheme.bodyLarge),
      ),

      searchViewTheme: SearchViewThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        headerHintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: colorScheme.primary,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelMedium,
      ),
    );

    return withM3ETheme(base, override: M3ETheme.defaults(colorScheme));
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFFFFB59E),
      onPrimary: const Color(0xFF5C1A08),
      primaryContainer: const Color(0xFF8C2F14),
      onPrimaryContainer: const Color(0xFFFFE4DB),
      secondary: const Color(0xFF5EEAD4),
      onSecondary: const Color(0xFF003731),
      secondaryContainer: const Color(0xFF065F56),
      onSecondaryContainer: const Color(0xFFCCFBF1),
      tertiary: const Color(0xFFFBBF24),
      onTertiary: const Color(0xFF1C1917),
      tertiaryContainer: const Color(0xFF92400E),
      onTertiaryContainer: const Color(0xFFFFF3D6),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: const Color(0xFF1C1917),
      onSurface: const Color(0xFFF5F5F4),
      surfaceContainerHighest: const Color(0xFF44403C),
      onSurfaceVariant: const Color(0xFFA8A29E),
      outline: const Color(0xFF78716C),
      outlineVariant: const Color(0xFF57534E),
      shadow: Colors.black.withValues(alpha: 0.4),
      scrim: Colors.black.withValues(alpha: 0.7),
      inverseSurface: const Color(0xFFF5F5F4),
      onInverseSurface: const Color(0xFF1C1917),
      inversePrimary: AppColors.primary,
      surfaceTint: AppColors.primary.withValues(alpha: 0.15),
    );

    final textTheme = AppTypography.buildTextTheme(colorScheme);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      extensions: [GcExpressiveTheme.dark],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: lightTheme.appBarTheme.copyWith(
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: lightTheme.cardTheme.copyWith(
        color: colorScheme.surfaceContainerHighest,
        surfaceTintColor: colorScheme.primary.withOpacity(0.15),
      ),
      inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
        fillColor: colorScheme.surfaceContainerHighest,
        hintStyle: lightTheme.inputDecorationTheme.hintStyle?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: lightTheme.filledButtonTheme,
      elevatedButtonTheme: lightTheme.elevatedButtonTheme,
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppShapes.button),
          textStyle: textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // Add dark-specific configurations
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        surfaceTintColor: colorScheme.primary.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: AppShapes.sheet),
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant,
        modalBackgroundColor: colorScheme.scrim,
      ),
      snackBarTheme: lightTheme.snackBarTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      navigationBarTheme: lightTheme.navigationBarTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerHigh,
        indicatorColor: colorScheme.primaryContainer,
      ),
      navigationRailTheme: lightTheme.navigationRailTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerLowest,
        indicatorColor: colorScheme.primaryContainer,
      ),
    );

    return withM3ETheme(base, override: M3ETheme.defaults(colorScheme));
  }
}

// ============================================================================
// DECORATION HELPERS
// ============================================================================

/// Tonal surface card — M3 expressive elevation via color, not shadow.
BoxDecoration tonalCardDecoration(BuildContext context, {Color? color}) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: color ?? scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppShapes.md),
    border: Border.all(color: scheme.outlineVariant),
  );
}

/// Soft card with subtle shadow for elevated surfaces
BoxDecoration softCardDecoration(BuildContext context, {Color? color}) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: color ?? scheme.surface,
    borderRadius: BorderRadius.circular(AppShapes.md),
    border: Border.all(color: scheme.outlineVariant),
    boxShadow: [
      BoxShadow(
        color: scheme.shadow.withOpacity(0.1),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  );
}

/// Glass morphism effect for modern UI
BoxDecoration glassDecoration({
  Color? color,
  double? opacity,
  BorderRadiusGeometry? borderRadius,
}) {
  final fill = color ?? AppColors.surface;
  final alpha = opacity ?? 0.8;
  final rad = borderRadius ?? BorderRadius.circular(AppShapes.md);

  return BoxDecoration(
    color: fill.withValues(alpha: alpha),
    borderRadius: rad,
    border: Border.all(color: AppColors.onSurfaceVariant.withValues(alpha: 0.2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  );
}

/// Warm coral-to-teal gradient mesh for marketing surfaces.
BoxDecoration heroMeshDecoration(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary.withValues(alpha: 0.22),
        scheme.surfaceContainerLowest,
        scheme.secondary.withValues(alpha: 0.14),
        scheme.tertiary.withValues(alpha: 0.08),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    ),
  );
}

/// Primary gradient for buttons and highlights
BoxDecoration primaryGradientDecoration(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        scheme.primary,
        scheme.primaryContainer,
      ],
    ),
    borderRadius: AppShapes.button,
  );
}

/// Page padding that respects max content width on large screens.
EdgeInsets pagePadding(BuildContext context) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 840;
  final isExpanded = MediaQuery.sizeOf(context).width >= 1200;

  if (isExpanded) {
    return EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontalDesktop);
  } else if (isDesktop) {
    return EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontalTablet);
  }
  return EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal);
}

/// Content constraint helper
Widget constrainContent(BuildContext context, Widget child) {
  return Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
      child: child,
    ),
  );
}

/// Responsive padding based on screen size
EdgeInsets responsivePadding(BuildContext context, {
  double? horizontal,
  double? vertical,
  double? all,
}) {
  final baseHorizontal = horizontal ?? AppSpacing.pageHorizontal;
  final baseVertical = vertical ?? AppSpacing.lg;
  final baseAll = all;

  if (baseAll != null) {
    return EdgeInsets.all(baseAll);
  }
  return EdgeInsets.symmetric(
    horizontal: baseHorizontal,
    vertical: baseVertical,
  );
}
