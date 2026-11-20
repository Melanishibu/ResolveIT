import 'package:flutter/material.dart';

/// Background and text colour of one chip. The text meets WCAG AA (4.5:1) on the background.
@immutable
final class ChipColors {
  const ChipColors({
    required this.hue,
    required this.background,
    required this.foreground,
  });

  /// Builds a chip from its reference hue: a light tint of the hue behind darker text of the same hue.
  factory ChipColors.tinted({required Color hue, required Color foreground}) =>
      ChipColors(
        hue: hue,
        background: Color.alphaBlend(hue.withValues(alpha: _tintAlpha), _white),
        foreground: foreground,
      );

  static const _tintAlpha = 0.14;
  static const _white = Color(0xFFFFFFFF);

  /// The reference colour from the UI mockup.
  final Color hue;
  final Color background;
  final Color foreground;
}

/// Colour tokens of the ResolveIT theme (read from the UI mockup, approved 11/20/2026).
/// Widgets get colours only from here, via `context.appColors`.
@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors._({
    required this.primary,
    required this.onPrimary,
    required this.sidebarBackground,
    required this.sidebarForeground,
    required this.sidebarActiveBackground,
    required this.sidebarActiveForeground,
    required this.pageBackground,
    required this.cardBackground,
    required this.cardShadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.warning,
    required this.error,
    required this.priorityLow,
    required this.priorityMedium,
    required this.priorityHigh,
    required this.priorityCritical,
    required this.statusOpen,
    required this.statusAssigned,
    required this.statusInProgress,
    required this.statusResolved,
    required this.statusClosed,
    required this.border,
    required this.focusRing,
    required this.danger,
    required this.onDanger,
    required this.success,
    required this.roleChip,
    required this.activeChip,
    required this.inactiveChip,
  });

  static const _navy = Color(0xFF132A5E);
  static const _primaryBlue = Color(0xFF2563EB);
  static const _white = Color(0xFFFFFFFF);
  static const _green = Color(0xFF16A34A);
  static const _orange = Color(0xFFEA8C00);
  static const _red = Color(0xFFDC2626);
  static const _darkRed = Color(0xFF991B1B);
  static const _purple = Color(0xFF7C3AED);
  static const _grey = Color(0xFF6B7280);

  static final AppColors light = AppColors._(
    primary: _primaryBlue,
    onPrimary: _white,
    sidebarBackground: _navy,
    sidebarForeground: _white,
    sidebarActiveBackground: _primaryBlue,
    sidebarActiveForeground: _white,
    pageBackground: const Color(0xFFF4F6FA),
    cardBackground: _white,
    cardShadow: const Color(0x1A0F172A),
    textPrimary: const Color(0xFF0F172A),
    textSecondary: const Color(0xFF475569),
    warning: ChipColors.tinted(
      hue: _orange,
      foreground: const Color(0xFF92400E),
    ),
    error: ChipColors.tinted(hue: _red, foreground: const Color(0xFFB91C1C)),
    priorityLow: ChipColors.tinted(
      hue: _green,
      foreground: const Color(0xFF166534),
    ),
    priorityMedium: ChipColors.tinted(
      hue: _orange,
      foreground: const Color(0xFF92400E),
    ),
    priorityHigh: ChipColors.tinted(
      hue: _red,
      foreground: const Color(0xFFB91C1C),
    ),
    priorityCritical: ChipColors.tinted(
      hue: _darkRed,
      foreground: const Color(0xFF7F1D1D),
    ),
    statusOpen: ChipColors.tinted(
      hue: _primaryBlue,
      foreground: const Color(0xFF1D4ED8),
    ),
    statusAssigned: ChipColors.tinted(
      hue: _purple,
      foreground: const Color(0xFF6D28D9),
    ),
    statusInProgress: ChipColors.tinted(
      hue: _orange,
      foreground: const Color(0xFF92400E),
    ),
    statusResolved: ChipColors.tinted(
      hue: _green,
      foreground: const Color(0xFF166534),
    ),
    statusClosed: ChipColors.tinted(
      hue: _grey,
      foreground: const Color(0xFF4B5563),
    ),
    // US-28 (AB#170) component tokens.
    border: const Color(0xFFCBD5E1),
    focusRing: const Color(0x332563EB),
    danger: const Color(0xFFB91C1C),
    onDanger: _white,
    success: ChipColors.tinted(
      hue: _green,
      foreground: const Color(0xFF166534),
    ),
    roleChip: ChipColors.tinted(
      hue: _primaryBlue,
      foreground: const Color(0xFF1D4ED8),
    ),
    activeChip: ChipColors.tinted(
      hue: _green,
      foreground: const Color(0xFF166534),
    ),
    inactiveChip: ChipColors.tinted(
      hue: _red,
      foreground: const Color(0xFFB91C1C),
    ),
  );

  final Color primary;
  final Color onPrimary;
  final Color sidebarBackground;
  final Color sidebarForeground;
  final Color sidebarActiveBackground;
  final Color sidebarActiveForeground;
  final Color pageBackground;
  final Color cardBackground;
  final Color cardShadow;
  final Color textPrimary;
  final Color textSecondary;
  final ChipColors warning;
  final ChipColors error;
  final ChipColors priorityLow;
  final ChipColors priorityMedium;
  final ChipColors priorityHigh;
  final ChipColors priorityCritical;
  final ChipColors statusOpen;
  final ChipColors statusAssigned;
  final ChipColors statusInProgress;
  final ChipColors statusResolved;
  final ChipColors statusClosed;

  /// Field outlines and table dividers.
  final Color border;

  /// Focus highlight for keyboard navigation.
  final Color focusRing;

  /// Danger button background and its text colour.
  final Color danger;
  final Color onDanger;

  /// Success toast.
  final ChipColors success;

  /// Role chip (all roles) and user active/inactive chips.
  final ChipColors roleChip;
  final ChipColors activeChip;
  final ChipColors inactiveChip;

  List<ChipColors> get allChips => [
    priorityLow,
    priorityMedium,
    priorityHigh,
    priorityCritical,
    statusOpen,
    statusAssigned,
    statusInProgress,
    statusResolved,
    statusClosed,
    warning,
    error,
    success,
    roleChip,
    activeChip,
    inactiveChip,
  ];

  // One fixed light palette in PI_01: there is nothing to copy or interpolate.
  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(covariant ThemeExtension<AppColors>? other, double t) => this;
}
