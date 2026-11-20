import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/app_colors.dart';
import 'package:resolveit/app/theme/app_spacing.dart';

/// The one app theme (D2: Material widgets, styled to the UI mockup).
ThemeData buildAppTheme() {
  final colors = AppColors.light;
  const radii = AppRadii.standard;
  final scheme = ColorScheme.fromSeed(seedColor: colors.primary).copyWith(
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    surface: colors.cardBackground,
    onSurface: colors.textPrimary,
    error: colors.error.foreground,
  );
  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radii.control),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.pageBackground,
    cardTheme: CardThemeData(
      color: colors.cardBackground,
      surfaceTintColor: colors.cardBackground,
      shadowColor: colors.cardShadow,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.card),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: controlShape,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: controlShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        shape: controlShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.primary),
        shape: controlShape,
      ),
    ),
    // US-28 (AB#170): fields, focus and tables of the shared component library.
    focusColor: colors.focusRing,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.control),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.control),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.control),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.control),
        borderSide: BorderSide(color: colors.error.foreground),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.control),
        borderSide: BorderSide(color: colors.error.foreground, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(color: colors.border),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(colors.pageBackground),
      dividerThickness: 1,
    ),
    extensions: [colors, AppSpacing.standard, AppRadii.standard],
  );
}
