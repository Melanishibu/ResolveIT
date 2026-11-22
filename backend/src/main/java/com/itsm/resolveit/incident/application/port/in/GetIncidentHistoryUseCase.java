package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import java.util.List;

/** Read port: full audit history of an incident (RIT-US-13). */
public interface GetIncidentHistoryUseCase {

    List<IncidentHistoryView> history(Actor actor, IncidentId incidentId);
}
