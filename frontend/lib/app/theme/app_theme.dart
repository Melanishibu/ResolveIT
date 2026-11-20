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
    extensions: [colors, AppSpacing.standard, AppRadii.standard],
  );
}
