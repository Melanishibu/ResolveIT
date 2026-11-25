package com.itsm.resolveit.incident.application.service;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.application.port.in.IncidentCommentsUseCase;
import com.itsm.resolveit.incident.application.port.out.IncidentCommentRepository;
import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.application.port.out.UserDirectory;
import com.itsm.resolveit.incident.domain.model.CommentText;
import com.itsm.resolveit.incident.domain.model.Incident;
import com.itsm.resolveit.incident.domain.model.IncidentAccessDeniedException;
import com.itsm.resolveit.incident.domain.model.IncidentComment;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import com.itsm.resolveit.incident.domain.model.IncidentNotFoundException;
import java.time.Clock;
import java.util.Objects;
import java.util.UUID;
import org.springframework.transaction.annotation.Transactional;

/** Comments (RIT-US-20): who may comment follows "see incidents"; CLOSED incidents take none (in the aggregate). */
public class IncidentCommentsService implements IncidentCommentsUseCase {

    private final IncidentRepository incidents;
    private final IncidentCommentRepository comments;
    private final UserDirectory users;
    private final Clock clock;

    public IncidentCommentsService(IncidentRepository incidents, IncidentCommentRepository comments,
                                   UserDirectory users, Clock clock) {
        this.incidents = Objects.requireNonNull(incidents, "incidents");
        this.comments = Objects.requireNonNull(comments, "comments");
        this.users = Objects.requireNonNull(users, "users");
        this.clock = Objects.requireNonNull(clock, "clock");
    }

    @Transactional
    @Override
    public CommentView add(Actor actor, IncidentId incidentId, CommentText text) {
        Incident incident = visibleIncident(actor, incidentId);
        IncidentComment comment = incident.comment(UUID.randomUUID(), actor.userId(), text, clock.instant());
        comments.append(comment);
        return new CommentView(comment, users.find(actor.userId()));
    }

    @Transactional(readOnly = true)
    @Override
    public CommentPage list(Actor actor, IncidentId incidentId, int page, int size) {
        visibleIncident(actor, incidentId);
        IncidentCommentRepository.Page rows = comments.page(incidentId, page, size);
        return new CommentPage(rows.comments().stream()
                .map(comment -> new CommentView(comment, users.find(comment.authorId())))
                .toList(), page, size, rows.totalItems());
    }

    private Incident visibleIncident(Actor actor, IncidentId incidentId) {
        Incident incident = incidents.findById(incidentId).orElseThrow(IncidentNotFoundException::new);
        if (!incident.isVisibleTo(GetIncidentDetailsService.viewerOf(actor))) {
            throw new IncidentAccessDeniedException();
        }
        return incident;
    }
}
