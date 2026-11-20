import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/new_incident.dart';
import 'package:resolveit/features/incident/domain/usecase/report_incident.dart';

/// Coordinates the create-incident screen's use case (RIT-US-09).
final class ReportIncidentInteractor {
  const ReportIncidentInteractor(this._reportIncident);

  final ReportIncident _reportIncident;

  Future<Result<ReportedIncident>> report(NewIncident incident) =>
      _reportIncident(incident);
}
