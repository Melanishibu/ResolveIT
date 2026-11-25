import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/app_card.dart';
import 'package:resolveit/core/presentation/widgets/feedback_states.dart';
import 'package:resolveit/core/presentation/widgets/page_header.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Empty state for a menu destination whose screen arrives in a later story
/// (built from the US-28 components: PageHeader, AppCard, EmptyState).
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PageHeader(title: title),
      SizedBox(height: context.spacing.l),
      AppCard(
        key: const Key('placeholder-card'),
        child: Center(
          child: EmptyState(
            icon: Icons.construction_outlined,
            message: AppLocalizations.of(context).placeholderComingSoon,
          ),
        ),
      ),
    ],
  );
}
