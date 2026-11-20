package com.itsm.resolveit.incident.application.port.out;

import com.itsm.resolveit.incident.domain.model.Incident;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import java.util.Optional;

/** Repository of the {@link Incident} aggregate. */
public interface IncidentRepository {

    IncidentId nextId();

    void save(Incident incident);

    Optional<Incident> findById(IncidentId id);
}
