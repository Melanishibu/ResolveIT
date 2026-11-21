import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_list.dart';

/// Contract: the incidents the signed-in user may see (`GET /tickets`, RIT-US-11).
abstract interface class IncidentListRepository {
  Future<Result<IncidentPage>> list(IncidentListFilter filter);
}
