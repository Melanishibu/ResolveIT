package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.incident.application.port.out.UserDirectory.UserSummary;
import com.itsm.resolveit.incident.domain.model.Incident;
import com.itsm.resolveit.incident.domain.model.IncidentAction;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

/**
 * An incident as its viewer sees it (RIT-US-10): the incident, the reporter as known to the identity context
 * at display time (empty if that user no longer exists) and the actions the viewer may take.
 */
public record IncidentDetailsView(Incident incident, Optional<UserSummary> reporter, Optional<UserSummary> assignee,
                                  Set<IncidentAction> allowedActions) {

    public IncidentDetailsView {
        Objects.requireNonNull(incident, "incident");
        Objects.requireNonNull(reporter, "reporter");
        Objects.requireNonNull(assignee, "assignee");
        allowedActions = Set.copyOf(allowedActions);
    }
}
