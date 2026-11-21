package com.itsm.resolveit.incident.application.port.in;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.application.port.out.UserDirectory.UserSummary;
import com.itsm.resolveit.incident.domain.model.CommentText;
import com.itsm.resolveit.incident.domain.model.IncidentComment;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import java.util.List;
import java.util.Optional;

/** Add and list the comments of an incident the caller may see (RIT-US-20). */
public interface IncidentCommentsUseCase {

    CommentView add(Actor actor, IncidentId incidentId, CommentText text);

    CommentPage list(Actor actor, IncidentId incidentId, int page, int size);

    /** A comment with its author as known to the identity context (empty if that user no longer exists). */
    record CommentView(IncidentComment comment, Optional<UserSummary> author) {
    }

    record CommentPage(List<CommentView> items, int page, int size, long totalItems) {

        public int totalPages() {
            return (int) ((totalItems + size - 1) / size);
        }
    }
}
