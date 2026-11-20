import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';

/// Circle with up to two initials (US-28). The initials are computed by the caller
/// (for example `CurrentUser.initials`); [semanticLabel] is the tooltip and screen-reader text.
class AvatarInitials extends StatelessWidget {
  const AvatarInitials({
    super.key,
    required this.initials,
    required this.semanticLabel,
  });

  final String initials;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: semanticLabel,
      child: CircleAvatar(
        radius: context.spacing.avatarRadius,
        backgroundColor: colors.primary,
        child: Text(
          initials,
          style: context.textTheme.labelLarge?.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
