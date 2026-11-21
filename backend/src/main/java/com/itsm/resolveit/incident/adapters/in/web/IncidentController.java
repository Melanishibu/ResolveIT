package com.itsm.resolveit.incident.adapters.in.web;

import com.itsm.resolveit.identity.Actor;
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

    IncidentController(ReportIncidentUseCase reportIncident) {
        this.reportIncident = reportIncident;
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
