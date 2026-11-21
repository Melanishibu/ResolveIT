package com.itsm.resolveit.incident.adapters.in.web;

import com.itsm.resolveit.incident.application.port.in.ReportedIncidentView;
import com.itsm.resolveit.incident.domain.model.Incident;
import io.swagger.v3.oas.annotations.media.Schema;

/** The reported incident: {@code {id, ticketNumber, title, description, category, priority, status, createdBy, createdAt}}. */
@Schema(description = "The reported incident")
record ReportedIncidentResponse(
        String id,
        @Schema(example = "INC-2026-00001", description = "INC-YYYY-NNNNN: UTC year of creation, counter per year")
        String ticketNumber,
        String title,
        String description,
        String category,
        String priority,
        @Schema(example = "OPEN") String status,
        @Schema(description = "Id of the user who reported it") String createdBy,
        @Schema(description = "ISO-8601 UTC", example = "2026-11-20T15:30:00Z") String createdAt) {

    static ReportedIncidentResponse of(ReportedIncidentView view) {
        Incident incident = view.incident();
        return new ReportedIncidentResponse(incident.id().toString(), incident.ticketNumber().value(),
                incident.title().value(), incident.description().value(), incident.category().name(),
                incident.priority().name(), incident.status().name(), incident.createdBy().toString(),
                incident.createdAt().toString());
    }
}
