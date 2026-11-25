package com.itsm.resolveit.incident.application.port.out;

import com.itsm.resolveit.incident.domain.model.IncidentComment;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import java.util.List;

/** Comments of an incident (RIT-US-20): append-only, read oldest first. */
public interface IncidentCommentRepository {

    void append(IncidentComment comment);

    Page page(IncidentId incidentId, int page, int size);

    record Page(List<IncidentComment> comments, long totalItems) {
    }
}
