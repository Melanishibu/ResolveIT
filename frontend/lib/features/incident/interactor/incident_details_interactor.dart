import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/usecase/get_incident_details.dart';

/// Coordinates the incident details screen's use case (RIT-US-10).
final class IncidentDetailsInteractor {
  const IncidentDetailsInteractor(this._getDetails);

  final GetIncidentDetails _getDetails;

  Future<Result<IncidentDetails>> load(String id) => _getDetails(id);
}
