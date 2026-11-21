package com.itsm.resolveit.incident.application.port.in;

/** Opens one incident with its details and the actions the viewer may take (RIT-US-10). */
public interface GetIncidentDetailsUseCase {

    /**
     * @throws com.itsm.resolveit.incident.domain.model.IncidentNotFoundException     no incident with this id
     * @throws com.itsm.resolveit.incident.domain.model.IncidentAccessDeniedException the viewer may not see it
     */
    IncidentDetailsView details(GetIncidentDetailsQuery query);
}
