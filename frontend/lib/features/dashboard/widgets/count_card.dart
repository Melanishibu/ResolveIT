import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/domain/role.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/dashboard/presentation/presenter/dashboard_presenter.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// One count card (RIT-US-21). A tap opens the incident list with the card's filter.
class CountCard extends StatelessWidget {
  const CountCard({
    super.key,
    required this.label,
    required this.count,
    required this.location,
  });

  final String label;
  final int count;

  /// Where a tap goes, for example `/incidents?status=OPEN`.
  final String location;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return SizedBox(
      width: spacing.filterWidth,
      child: InkWell(
        onTap: () => context.go(location),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.textTheme.labelLarge),
              SizedBox(height: spacing.s),
              Text('$count', style: context.textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// The incident list for [role], narrowed to [statuses] and [priorities] (empty = any).
String incidentListLocation(
  Role role, {
  List<String> statuses = const [],
  List<String> priorities = const [],
}) {
  final path = role == Role.admin ? '/incidents' : '/my-incidents';
  final query = [
    for (final status in statuses) 'status=$status',
    for (final priority in priorities) 'priority=$priority',
  ].join('&');
  return query.isEmpty ? path : '$path?$query';
}

/// Total, Open, In Progress and Resolved cards above the incident list (RIT-US-21). Hidden while loading or when
/// the counts can't be loaded, so the list itself always works.
class IncidentCountCards extends ConsumerWidget {
  const IncidentCountCards({super.key, required this.role});

  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final counts = ref.watch(incidentCountsPresenterProvider).value;
    if (counts == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.l),
      child: Wrap(
        key: const Key('incident-count-cards'),
        spacing: spacing.m,
        runSpacing: spacing.m,
        children: [
          CountCard(
            label: l10n.dashboardTotal,
            count: counts.total,
            location: incidentListLocation(role),
          ),
          CountCard(
            label: l10n.statusOpen,
            count: counts.open,
            location: incidentListLocation(role, statuses: ['OPEN']),
          ),
          CountCard(
            label: l10n.statusInProgress,
            count: counts.inProgress,
            location: incidentListLocation(role, statuses: ['IN_PROGRESS']),
          ),
          CountCard(
            label: l10n.statusResolved,
            count: counts.resolved,
            location: incidentListLocation(role, statuses: ['RESOLVED']),
          ),
        ],
      ),
    );
  }
}
