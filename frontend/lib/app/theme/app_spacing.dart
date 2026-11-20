import 'package:flutter/material.dart';

/// Spacing and size tokens. Widgets never use literal paddings or gaps.
@immutable
final class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing._();

  static const AppSpacing standard = AppSpacing._();

  double get xs => 4;
  double get s => 8;
  double get m => 12;
  double get l => 16;
  double get xl => 24;
  double get xxl => 32;

  double get sidebarWidth => 240;
  double get topBarHeight => 64;
  double get avatarRadius => 18;
  double get dialogMaxWidth => 520;
  double get chipHorizontal => 10;
  double get chipVertical => 4;

  @override
  AppSpacing copyWith() => this;

  @override
  AppSpacing lerp(covariant ThemeExtension<AppSpacing>? other, double t) =>
      this;
}

/// Corner radius tokens.
@immutable
final class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii._();

  static const AppRadii standard = AppRadii._();

  double get card => 12;
  double get control => 8;
  double get chip => 999;

  @override
  AppRadii copyWith() => this;

  @override
  AppRadii lerp(covariant ThemeExtension<AppRadii>? other, double t) => this;
}
