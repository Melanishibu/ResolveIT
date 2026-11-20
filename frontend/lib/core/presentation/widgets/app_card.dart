import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';

/// White card with the token radius and soft shadow (US-28).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;

  /// Defaults to the `xl` spacing token.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: padding ?? EdgeInsets.all(context.spacing.xl),
      child: child,
    ),
  );
}
