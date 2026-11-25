package com.itsm.resolveit.incident.application.port.out;

import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import java.util.List;

/** The append-only incident audit history: entries can only be added. */
public interface IncidentAuditLog {

    void append(IncidentAuditEntry entry);

    default List<IncidentAuditEntry> findByIncidentId(IncidentId incidentId) {
        return List.of();
    }
}
