import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/app_colors.dart';
import 'package:resolveit/app/theme/app_spacing.dart';

export 'package:resolveit/app/theme/app_colors.dart';
export 'package:resolveit/app/theme/app_spacing.dart';

/// Token access for widgets: `context.appColors`, `context.spacing`, `context.radii`, `context.textTheme`.
extension AppThemeContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  AppSpacing get spacing => Theme.of(this).extension<AppSpacing>()!;
  AppRadii get radii => Theme.of(this).extension<AppRadii>()!;
  TextTheme get textTheme => Theme.of(this).textTheme;
}
