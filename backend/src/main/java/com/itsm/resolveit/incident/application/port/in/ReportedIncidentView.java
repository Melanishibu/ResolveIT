package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.incident.domain.model.Incident;

/** The incident as reported. */
public record ReportedIncidentView(Incident incident) {
}
