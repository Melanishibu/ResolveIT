package com.itsm.resolveit.incident.adapters.in.web;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.application.port.in.GetIncidentHistoryUseCase;
import com.itsm.resolveit.incident.application.port.in.IncidentHistoryView;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import com.itsm.resolveit.incident.domain.model.IncidentNotFoundException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Incident audit history (RIT-US-13): full history of who changed what and when, newest first. Read-only. */
@RestController
@RequestMapping("/api/v1/tickets/{id}/history")
@Tag(name = "Incident history", description = "Audit trail of actions on an incident")
class IncidentHistoryController {

    private static final String SESSION_SCHEME = "RIT_SESSION";

    private final GetIncidentHistoryUseCase historyUseCase;

    IncidentHistoryController(GetIncidentHistoryUseCase historyUseCase) {
        this.historyUseCase = historyUseCase;
    }

    record IncidentHistoryResponse(
            String action,
            String actor,
            String actorName,
            String oldValue,
            String newValue,
            @Schema(description = "ISO-8601 UTC") String timestamp,
            @Schema(description = "ISO-8601 UTC") String occurredAt
    ) {
        static IncidentHistoryResponse of(IncidentHistoryView view) {
            String timeStr = view.occurredAt().toString();
            return new IncidentHistoryResponse(
                    view.action().name(),
                    view.actorName(),
                    view.actorName(),
                    view.oldValue(),
                    view.newValue(),
                    timeStr,
                    timeStr
            );
        }
    }

    @GetMapping
    @Operation(summary = "Incident history",
            description = "Audit trail of actions on an incident, newest first (RIT-US-13)."
                    + " Same access rule as the incident. Read-only.",
            security = @SecurityRequirement(name = SESSION_SCHEME))
    @ApiResponse(responseCode = "200", description = "OK",
            content = @Content(array = @ArraySchema(schema = @Schema(implementation = IncidentHistoryResponse.class))))
    @ApiResponse(responseCode = "401", description = "AUTH_UNAUTHENTICATED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "403", description = "INCIDENT_ACCESS_DENIED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "404", description = "INCIDENT_NOT_FOUND",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    List<IncidentHistoryResponse> history(Actor actor, @PathVariable("id") String id) {
        UUID incidentId;
        try {
            incidentId = UUID.fromString(id);
        } catch (IllegalArgumentException malformed) {
            throw new IncidentNotFoundException();
        }
        return historyUseCase.history(actor, new IncidentId(incidentId)).stream()
                .map(IncidentHistoryResponse::of)
                .toList();
    }
}
