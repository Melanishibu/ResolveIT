package com.itsm.resolveit.incident.adapters.in.web;

import com.itsm.resolveit.incident.application.port.in.IncidentDetailsView;
import com.itsm.resolveit.incident.domain.model.Incident;
import com.itsm.resolveit.incident.domain.model.IncidentAction;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

/** One incident as its viewer sees it (RIT-US-10). Assignee and resolution notes are null until US-12/US-14. */
@Schema(description = "Incident details with the actions the caller may take")
record IncidentDetailsResponse(
        String id,
        String ticketNumber,
        String title,
        String description,
        String category,
        String priority,
        String status,
        Person createdBy,
        Person assignee,
        String resolutionNotes,
        @Schema(description = "ISO-8601 UTC") String createdAt,
        @Schema(description = "ISO-8601 UTC") String updatedAt,
        @Schema(description = "ASSIGN, REASSIGN, START, RESOLVE, REOPEN, CLOSE, CHANGE_PRIORITY") List<String> allowedActions) {

    /** A user shown on an incident; name and department are null if the user no longer exists. */
    record Person(String id, String name, String department, boolean active) {
    }

    static IncidentDetailsResponse of(IncidentDetailsView view) {
        Incident incident = view.incident();
        Person creator = view.reporter()
                .map(user -> new Person(user.id().toString(), user.name(), user.department(), user.active()))
                .orElse(new Person(incident.createdBy().toString(), null, null, false));
        List<String> actions = view.allowedActions().stream().sorted().map(IncidentAction::name).toList();
        return new IncidentDetailsResponse(incident.id().toString(), incident.ticketNumber().value(),
                incident.title().value(), incident.description().value(), incident.category().name(),
                incident.priority().name(), incident.status().name(), creator, null, null,
                incident.createdAt().toString(), incident.updatedAt().toString(), actions);
    }
}
