import 'package:resolveit/features/incident/domain/entity/incident_category.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The user-facing name of an incident category.
String categoryLabel(AppLocalizations l10n, IncidentCategory category) =>
    switch (category) {
      IncidentCategory.hardware => l10n.categoryHardware,
      IncidentCategory.software => l10n.categorySoftware,
      IncidentCategory.network => l10n.categoryNetwork,
      IncidentCategory.access => l10n.categoryAccess,
      IncidentCategory.other => l10n.categoryOther,
    };
