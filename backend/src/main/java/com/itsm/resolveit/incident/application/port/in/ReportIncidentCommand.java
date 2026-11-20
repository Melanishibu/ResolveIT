package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.domain.model.Category;
import com.itsm.resolveit.incident.domain.model.Description;
import com.itsm.resolveit.incident.domain.model.Priority;
import com.itsm.resolveit.incident.domain.model.Title;
import java.util.Objects;

/** Report an incident; {@code actor} becomes the creator. */
public record ReportIncidentCommand(Actor actor, Title title, Description description, Category category,
                                    Priority priority) {

    public ReportIncidentCommand {
        Objects.requireNonNull(actor, "actor");
        Objects.requireNonNull(title, "title");
        Objects.requireNonNull(description, "description");
        Objects.requireNonNull(category, "category");
        Objects.requireNonNull(priority, "priority");
    }
}
