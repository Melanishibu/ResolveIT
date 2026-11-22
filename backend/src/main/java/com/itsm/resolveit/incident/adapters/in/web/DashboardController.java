package com.itsm.resolveit.incident.adapters.in.web;

import com.itsm.resolveit.identity.Actor;
import com.itsm.resolveit.incident.application.port.in.DashboardUseCase;
import com.itsm.resolveit.incident.application.port.out.DashboardReadModel.Counts;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Dashboard counts and recent activity for the caller's role scope (RIT-US-21). */
@RestController
@RequestMapping("/api/v1/dashboard")
@Tag(name = "Dashboard", description = "Incident counts and recent activity for the caller's scope")
class DashboardController {

    private static final String SESSION_SCHEME = "RIT_SESSION";

    private final DashboardUseCase dashboard;

    DashboardController(DashboardUseCase dashboard) {
        this.dashboard = dashboard;
    }

    record SummaryResponse(long total, long open, long assigned, long inProgress, long resolved, long critical) {
    }

    record ActivityResponse(String incidentId, String ticketNumber, String action, String actor,
                            @Schema(description = "ISO-8601 UTC") String occurredAt) {
    }

    @GetMapping("/summary")
    @Operation(summary = "Incident counts", description = "Admin all, Technician assigned, Employee own."
            + " critical = CRITICAL and not CLOSED.", security = @SecurityRequirement(name = SESSION_SCHEME))
    SummaryResponse summary(Actor actor) {
        Counts counts = dashboard.summary(actor);
        return new SummaryResponse(counts.total(), counts.open(), counts.assigned(), counts.inProgress(),
                counts.resolved(), counts.critical());
    }

    @GetMapping("/activity")
    @Operation(summary = "Recent activity", description = "Latest incident audit entries in scope, newest first;"
            + " limit 1–50 (default 10).", security = @SecurityRequirement(name = SESSION_SCHEME))
    List<ActivityResponse> activity(Actor actor, @RequestParam(defaultValue = "10") int limit) {
        if (limit < 1 || limit > 50) {
            throw new InvalidFieldException("limit");
        }
        return dashboard.recentActivity(actor, limit).stream()
                .map(entry -> new ActivityResponse(entry.incidentId().toString(), entry.ticketNumber(),
                        entry.action(), entry.actorName(), entry.occurredAt().toString()))
                .toList();
    }
}
