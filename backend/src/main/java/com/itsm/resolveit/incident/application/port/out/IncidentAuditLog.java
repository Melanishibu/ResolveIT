package com.itsm.resolveit.incident.application.port.out;

import com.itsm.resolveit.incident.domain.model.IncidentAuditEntry;

/** The append-only incident audit history: entries can only be added. */
public interface IncidentAuditLog {

    void append(IncidentAuditEntry entry);
}
