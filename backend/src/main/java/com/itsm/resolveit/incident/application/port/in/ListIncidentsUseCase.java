package com.itsm.resolveit.incident.application.port.in;

/** Lists the incidents the caller may see, paged and sorted (RIT-US-11). */
public interface ListIncidentsUseCase {

    IncidentListPage list(ListIncidentsQuery query);
}
