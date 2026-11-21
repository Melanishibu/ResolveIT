package com.itsm.resolveit.incident.application.service;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.application.port.in.GetIncidentDetailsQuery;
import com.itsm.resolveit.incident.application.port.in.GetIncidentDetailsUseCase;
import com.itsm.resolveit.incident.application.port.in.IncidentDetailsView;
import com.itsm.resolveit.incident.application.port.out.IncidentRepository;
import com.itsm.resolveit.incident.application.port.out.UserDirectory;
import com.itsm.resolveit.incident.domain.model.Incident;
import com.itsm.resolveit.incident.domain.model.IncidentAccessDeniedException;
import com.itsm.resolveit.incident.domain.model.IncidentNotFoundException;
import com.itsm.resolveit.incident.domain.model.Viewer;
import java.util.Objects;
import org.springframework.transaction.annotation.Transactional;

/** Opens one incident: load, check who may see it, add the reporter and the allowed actions (RIT-US-10). */
public class GetIncidentDetailsService implements GetIncidentDetailsUseCase {

    private final IncidentRepository incidents;
    private final UserDirectory users;

    public GetIncidentDetailsService(IncidentRepository incidents, UserDirectory users) {
        this.incidents = Objects.requireNonNull(incidents, "incidents");
        this.users = Objects.requireNonNull(users, "users");
    }

    @Transactional(readOnly = true)
    @Override
    public IncidentDetailsView details(GetIncidentDetailsQuery query) {
        Incident incident = incidents.findById(query.incidentId()).orElseThrow(IncidentNotFoundException::new);
        Viewer viewer = viewerOf(query.actor());
        if (!incident.isVisibleTo(viewer)) {
            throw new IncidentAccessDeniedException();
        }
        return new IncidentDetailsView(incident, users.find(incident.createdBy()), incident.allowedActionsFor(viewer));
    }

    /** Translates the identity context's actor into the incident context's viewer. */
    static Viewer viewerOf(Actor actor) {
        return new Viewer(actor.userId(), Viewer.Role.valueOf(actor.role().name()));
    }
}
