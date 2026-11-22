package com.itsm.resolveit.incident.adapters.in.web;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.application.port.in.GetIncidentDetailsQuery;
import com.itsm.resolveit.incident.application.port.in.GetIncidentDetailsUseCase;
import com.itsm.resolveit.incident.domain.model.IncidentId;
import com.itsm.resolveit.incident.domain.model.IncidentNotFoundException;
import com.itsm.resolveit.incident.application.port.in.ListIncidentsQuery;
import com.itsm.resolveit.incident.application.port.in.ListIncidentsQuery.SortField;
import com.itsm.resolveit.incident.application.port.in.ListIncidentsUseCase;
import java.util.Map;
import java.util.UUID;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import com.itsm.resolveit.incident.application.port.in.ReportIncidentCommand;
import com.itsm.resolveit.incident.application.port.in.ReportIncidentUseCase;
import com.itsm.resolveit.incident.domain.model.Category;
import com.itsm.resolveit.incident.domain.model.Description;
import com.itsm.resolveit.incident.domain.model.Priority;
import com.itsm.resolveit.incident.domain.model.Title;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.function.Supplier;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Incidents ("tickets" in the API): report (RIT-US-09); list and details follow in RIT-US-10. */
@RestController
@RequestMapping("/api/v1/tickets")
@Tag(name = "Incidents", description = "Employees and Admins report IT incidents")
class IncidentController {

    /** Name of the session-cookie security scheme registered by the identity web adapter. */
    private static final String SESSION_SCHEME = "RIT_SESSION";

    private final ReportIncidentUseCase reportIncident;
    private final GetIncidentDetailsUseCase incidentDetails;

    private final ListIncidentsUseCase listIncidents;

    private final com.itsm.resolveit.incident.application.port.in.AssignIncidentUseCase assignIncident;
    private final com.itsm.resolveit.incident.application.port.in.ChangeIncidentStatusUseCase changeStatus;

    IncidentController(ReportIncidentUseCase reportIncident, GetIncidentDetailsUseCase incidentDetails,
                       ListIncidentsUseCase listIncidents,
                       com.itsm.resolveit.incident.application.port.in.AssignIncidentUseCase assignIncident,
                       com.itsm.resolveit.incident.application.port.in.ChangeIncidentStatusUseCase changeStatus) {
        this.changeStatus = changeStatus;
        this.reportIncident = reportIncident;
        this.incidentDetails = incidentDetails;
        this.listIncidents = listIncidents;
        this.assignIncident = assignIncident;
    }

    private static final Map<String, SortField> SORT_FIELDS = Map.of(
            "createdAt", SortField.CREATED_AT, "updatedAt", SortField.UPDATED_AT, "priority", SortField.PRIORITY,
            "status", SortField.STATUS, "ticketNumber", SortField.TICKET_NUMBER);

    @GetMapping
    @Operation(summary = "List incidents",
            description = "The incidents the caller may see (Admin all, Agent assigned, Employee own), paged."
                    + " sort = createdAt|updatedAt|priority|status|ticketNumber,asc|desc (default createdAt,desc).",
            security = @SecurityRequirement(name = SESSION_SCHEME))
    @ApiResponse(responseCode = "200", description = "OK")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED for page, size or sort",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    IncidentListResponse list(Actor actor, @RequestParam(defaultValue = "0") int page,
                              @RequestParam(defaultValue = "20") int size,
                              @RequestParam(defaultValue = "createdAt,desc") String sort,
                              @RequestParam(name = "status", required = false) java.util.List<String> status,
                              @RequestParam(name = "priority", required = false) java.util.List<String> priority) {
        java.util.Set<com.itsm.resolveit.incident.domain.model.IncidentStatus> statuses = enumSet("status", status,
                com.itsm.resolveit.incident.domain.model.IncidentStatus.class);
        java.util.Set<Priority> priorities = enumSet("priority", priority, Priority.class);
        if (page < 0) {
            throw new InvalidFieldException("page");
        }
        if (size < 1 || size > 100) {
            throw new InvalidFieldException("size");
        }
        String[] parts = sort.split(",", -1);
        SortField field = SORT_FIELDS.get(parts[0]);
        if (field == null || parts.length > 2 || (parts.length == 2 && !parts[1].matches("asc|desc"))) {
            throw new InvalidFieldException("sort");
        }
        boolean ascending = parts.length == 2 && parts[1].equals("asc");
        return IncidentListResponse.of(listIncidents.list(
                new ListIncidentsQuery(actor, page, size, field, ascending, statuses, priorities)));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Open an incident",
            description = "Details plus allowedActions for the caller (RIT-US-10). A malformed id is answered as not found.",
            security = @SecurityRequirement(name = SESSION_SCHEME))
    @ApiResponse(responseCode = "200", description = "OK")
    @ApiResponse(responseCode = "403", description = "INCIDENT_ACCESS_DENIED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "404", description = "INCIDENT_NOT_FOUND",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    IncidentDetailsResponse details(Actor actor, @PathVariable("id") String id) {
        UUID incidentId;
        try {
            incidentId = UUID.fromString(id);
        } catch (IllegalArgumentException malformed) {
            throw new IncidentNotFoundException();
        }
        return IncidentDetailsResponse.of(
                incidentDetails.details(new GetIncidentDetailsQuery(actor, new IncidentId(incidentId))));
    }

    /** Body of {@code PATCH /tickets/{id}/assign}. */
    record AssignRequest(@jakarta.validation.constraints.NotBlank String agentId) {
    }

    @org.springframework.web.bind.annotation.PatchMapping("/{id}/assign")
    @Operation(summary = "Assign or reassign an incident (Admin)",
            description = "OPEN → ASSIGNED, or reassign while ASSIGNED (RIT-US-14). Audited as ASSIGNED or REASSIGNED.",
            security = @SecurityRequirement(name = SESSION_SCHEME))
    @ApiResponse(responseCode = "200", description = "OK: the incident as the Admin now sees it")
    @ApiResponse(responseCode = "403", description = "AUTH_FORBIDDEN (not an Admin)",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "409", description = "INCIDENT_INVALID_TRANSITION",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "422", description = "ASSIGNEE_NOT_ACTIVE_AGENT",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    IncidentDetailsResponse assign(Actor actor, @PathVariable("id") String id,
                                   @Valid @RequestBody AssignRequest request) {
        UUID agentId = field("agentId", () -> UUID.fromString(request.agentId()));
        return IncidentDetailsResponse.of(assignIncident.assign(
                new com.itsm.resolveit.incident.application.port.in.AssignIncidentCommand(actor,
                        new IncidentId(incidentId(id)), agentId)));
    }

    /** Body of {@code PATCH /tickets/{id}/status}. */
    record ChangeStatusRequest(@jakarta.validation.constraints.NotBlank String targetStatus, String resolutionNotes,
                               String reason) {
    }

    @org.springframework.web.bind.annotation.PatchMapping("/{id}/status")
    @Operation(summary = "Change an incident's status",
            description = "One endpoint for all transitions (RIT-US-15). Built so far: start work"
                    + " (ASSIGNED → IN_PROGRESS), audited as STARTED.",
            security = @SecurityRequirement(name = SESSION_SCHEME))
    @ApiResponse(responseCode = "200", description = "OK: the incident as the caller now sees it")
    @ApiResponse(responseCode = "403", description = "INCIDENT_ACCESS_DENIED or AUTH_FORBIDDEN",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "409", description = "INCIDENT_INVALID_TRANSITION",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    IncidentDetailsResponse changeStatus(Actor actor, @PathVariable("id") String id,
                                         @Valid @RequestBody ChangeStatusRequest request) {
        com.itsm.resolveit.incident.domain.model.IncidentStatus target = field("targetStatus",
                () -> com.itsm.resolveit.incident.domain.model.IncidentStatus.valueOf(request.targetStatus()));
        return IncidentDetailsResponse.of(changeStatus.changeStatus(
                new com.itsm.resolveit.incident.application.port.in.ChangeIncidentStatusCommand(actor,
                        new IncidentId(incidentId(id)), target, request.resolutionNotes(), request.reason())));
    }

    /** Repeatable enum query parameter (for example {@code status=OPEN&status=ASSIGNED}); unknown values are 400. */
    private static <E extends Enum<E>> java.util.Set<E> enumSet(String name, java.util.List<String> values,
                                                                Class<E> type) {
        if (values == null) {
            return java.util.Set.of();
        }
        return values.stream()
                .map(value -> field(name, () -> Enum.valueOf(type, value)))
                .collect(java.util.stream.Collectors.toUnmodifiableSet());
    }

    /** A malformed id is answered as not found, like an unknown one. */
    private static UUID incidentId(String id) {
        try {
            return UUID.fromString(id);
        } catch (IllegalArgumentException malformed) {
            throw new IncidentNotFoundException();
        }
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Report an incident",
            description = "Creates an OPEN incident with the caller as creator, a ticket number INC-YYYY-NNNNN"
                    + " (UTC year, counter per year) and a CREATED audit entry.",
            security = @SecurityRequirement(name = SESSION_SCHEME))
    @ApiResponse(responseCode = "201", description = "Created")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED (params.fields names the fields)",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "401", description = "AUTH_UNAUTHENTICATED",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "403", description = "AUTH_FORBIDDEN (Technicians can't report incidents) or AUTH_CSRF_INVALID",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    ReportedIncidentResponse report(Actor actor, @Valid @RequestBody ReportIncidentRequest request) {
        ReportIncidentCommand command = new ReportIncidentCommand(actor,
                field("title", () -> new Title(request.title())),
                field("description", () -> new Description(request.description())),
                Category.valueOf(request.category()),
                Priority.valueOf(request.priority()));
        return ReportedIncidentResponse.of(reportIncident.report(command));
    }

    /** Builds a value object; a value the domain rejects becomes VALIDATION_FAILED for that field. */
    private static <T> T field(String name, Supplier<T> valueObject) {
        try {
            return valueObject.get();
        } catch (IllegalArgumentException invalid) {
            throw new InvalidFieldException(name);
        }
    }
}
